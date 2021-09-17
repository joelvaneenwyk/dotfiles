<#
.NOTES
    ===========================================================================
    Created on:   August 2021
    Created by:   Joel Van Eenwyk
    Filename:     Initialize-Environment.ps1
    ===========================================================================

.DESCRIPTION
    Provision the environment with basic set of tools and utilities for common use
    including 'git', 'perl', 'gsudo', 'micro', etc. These are mostly installed with
    the 'scoop' package manager.
#>

<#
.SYNOPSIS
    Returns true if the given command can be executed from the shell.
.INPUTS
    Command name which does not need to be a full path.
.OUTPUTS
    Whether or not the command exists and can be executed.
#>
Function Test-CommandExists {
    Param ($command)

    $oldPreference = $ErrorActionPreference

    $ErrorActionPreference = 'stop'
    $IsValid = $false

    try {
        if (Get-Command $command) {
            $IsValid = $true
        }
    }
    Catch {
        Write-Host "Command '$command' does not exist."
    }
    Finally {
        $ErrorActionPreference = $oldPreference
    }

    return $IsValid
} #end function test-CommandExists

Function Get-File {
    <#
.SYNOPSIS
    Downloads a file
.DESCRIPTION
    Downloads a file
.PARAMETER Url
    URL to file/resource to download
.PARAMETER Filename
    file to save it as locally
.EXAMPLE
    C:\PS> Get-File -Name "mynuget.exe" -Url https://dist.nuget.org/win-x86-commandline/latest/nuget.exe
#>

    Param(
        [Parameter(Position = 0, mandatory = $true)]
        [string]$Url,
        [string]$Filename = ''
    )

    # Get filename
    if (!$Filename) {
        $Filename = [System.IO.Path]::GetFileName($Url)
    }

    Write-Host "Downloading file from source: $Url"
    Write-Host "Target file: '$Filename'"

    $FilePath = $Filename

    # Make absolute local path
    if (![System.IO.Path]::IsPathRooted($Filename)) {
        $FilePath = Join-Path (Get-Item -Path ".\" -Verbose).FullName $Filename
    }

    if ($null -ne ($Url -as [System.URI]).AbsoluteURI) {
        $handler = New-Object -TypeName System.Net.Http.HttpClientHandler
        $client = New-Object -TypeName System.Net.Http.HttpClient -ArgumentList $handler
        $client.Timeout = New-Object -TypeName System.TimeSpan -ArgumentList 0, 30, 0
        $cancelTokenSource = [System.Threading.CancellationTokenSource]::new(-1)
        $responseMsg = $client.GetAsync([System.Uri]::new($Url), $cancelTokenSource.Token)
        $responseMsg.Wait()
        if (!$responseMsg.IsCanceled) {
            $response = $responseMsg.Result
            if ($response.IsSuccessStatusCode) {
                $downloadedFileStream = [System.IO.FileStream]::new(
                    $FilePath, [System.IO.FileMode]::Create, [System.IO.FileAccess]::Write, [System.IO.FileShare]::None)

                $copyStreamOp = $response.Content.CopyToAsync($downloadedFileStream)

                Write-Host "Download started..."
                $copyStreamOp.Wait()

                $downloadedFileStream.Close()
                if ($null -ne $copyStreamOp.Exception) {
                    throw $copyStreamOp.Exception
                }
            }
        }

        Write-Host "Downloaded file: '$Filename'"
    }
    else {
        throw "Cannot download from $Url"
    }
}

function msys() {
    & "$Env:UserProfile\.local\msys64\usr\bin\bash.exe" @('-lc') + @Args
}

Function Initialize-Environment {
    $tempFolder = "$ENV:UserProfile\.tmp"
    $mycelioRoot = Resolve-Path -Path "$PSScriptRoot\..\..\"

    $fontBaseName = "JetBrains Mono"
    $fontBaseFilename = $fontBaseName -replace '\s', ''

    $fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/$fontBaseFilename.zip"
    $fontNameOriginal = "$fontBaseName Regular Nerd Font Complete Windows Compatible"
    $fontName = "$fontBaseFilename NF"
    $tempFontFolder = "$tempFolder\fonts"
    $targetTempFontPath = "$tempFontFolder\$fontName.ttf"

    # We save it to system directory with same path it's the name that needs to be short
    $targetFontPath = "C:\Windows\Fonts\$fontNameOriginal.ttf"

    if ( -not(Test-Path -Path "$tempFolder") ) {
        New-Item -ItemType directory -Path "$tempFolder" | Out-Null
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    if ( -not(Test-Path -Path "$Env:UserProfile\.local\msys64\mingw64.exe" -PathType Leaf) ) {
        if ( -not(Test-Path -Path "$Env:UserProfile\.local") ) {
            New-Item -ItemType directory -Path "$Env:UserProfile\.local" | Out-Null
        }

        $msysInstaller = "https://github.com/msys2/msys2-installer/releases/download/nightly-x86_64/msys2-base-x86_64-latest.sfx.exe"

        if ( -not(Test-Path -Path "$tempFolder\msys2.exe" -PathType Leaf) ) {
            Invoke-WebRequest -UseBasicParsing -Uri "$msysInstaller" -OutFile "$tempFolder\msys2.exe"
        }

        if ( -not(Test-Path -Path "$Env:UserProfile\.local\msys64\msys2.exe" -PathType Leaf) ) {
            & "$tempFolder\msys2.exe" -y -o"$Env:UserProfile\.local"

            Set-Content -Path '$Env:UserProfile\.local\msys64\etc\post-install\09-dotfiles.post' -Value @"
MAYBE_FIRST_START=false
[ -f '/usr/bin/update-ca-trust' ] && sh /usr/bin/update-ca-trust
echo 'Post-install complete.'
"@

            msys ' '
            msys 'pacman --noconfirm -Syuu'
            msys 'pacman --noconfirm -Syuu'
            msys 'pacman --noconfirm -Scc'
            Write-Host 'Finished MSYS2 install.'
        }

        # We run this here to ensure that the first run of msys2 is done before the 'setup.sh' call
        # as the initial upgrade of msys2 results in it shutting down the console.
        & cmd /s /c "$Env:UserProfile\.local\msys64\msys2_shell.cmd" \
        -mingw64 -defterm -no-start -where "$mycelioRoot" \
        -shell bash -c "./source/shell/upgrade-package-manager.sh"
    }

    try {
        if (-not(Test-CommandExists "scoop")) {
            Write-Host "Installing 'scoop' package manager..."
            Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')

            # gsudo: Run commands as administrator.
            # innounp: Required for unpacking InnoSetup files.
            # dark: Unpack installers created with the WiX Toolset.
            scoop install "gsudo"
            scoop install "innounp"
            scoop install "dark"

            $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
            if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
                # Add SSH client, see https://stackoverflow.com/a/58029292
                Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

                # Windows Defender may slow down or disrupt installs with realtime scanning.
                Import-Module Defender
                gsudo Add-MpPreference -ExclusionPath "C:\Users\$env:USERNAME\scoop"
                gsudo Add-MpPreference -ExclusionPath "C:\ProgramData\scoop"
            }
        }

        try {
            # Make sure git is installed first as scoop uses git to update itself
            if (-not(Test-CommandExists "git")) {
                scoop install "git"
            }

            scoop update

            # More robust than 'sudo' above and not just a PowerShell script, see https://github.com/gerardog/gsudo
            if (-not(Test-CommandExists "gsudo")) {
                scoop install "gsudo"
            }

            if (-not(Test-CommandExists "nuget")) {
                scoop install "nuget"
            }

            # https://github.com/chrisant996/clink
            if (-not(Test-CommandExists "clink")) {
                scoop install "clink"
            }

            # Static site builder.
            if (-not(Test-CommandExists "hugo")) {
                scoop install hugo-extended
            }

            # Necessary for 'stow' so that we can run it outside of msys environment.
            if (-not(Test-CommandExists "perl")) {
                scoop install "perl"
            }

            Write-Host "Verified that dependencies were installed with 'scoop' package manager."
        }
        catch {
            Write-Host "Failed to install packages with 'scoop' manager."
        }
    }
    catch {
        Write-Host "Exception caught while installing `scoop` package manager."
    }
    finally {
        try {
            # This can fail in containers as 'GetCurrentConsoleFont' will fail during build
            # so we just ignore the error here and continue.
            Import-Module WindowsConsoleFonts -ErrorAction SilentlyContinue >$null
            if ($? -and (Test-Path -Path "$targetTempFontPath" -PathType Leaf)) {
                # Try to remove the old font if we can
                Remove-Font "$targetTempFontPath" -ErrorAction SilentlyContinue >$null
                Write-Host "Removed previously installed font: '$targetTempFontPath'"
            }
        }
        catch [Exception] {
            Write-Host "Failed to remove old font.", $_.Exception.Message
        }

        # https://www.hanselman.com/blog/how-to-make-a-pretty-prompt-in-windows-terminal-with-powerline-nerd-fonts-cascadia-code-wsl-and-ohmyposh
        # https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/install.ps1
        try {
            if ( -not(Test-Path -Path "$targetTempFontPath" -PathType Leaf) ) {
                if (Test-Path -Path "$tempFontFolder") {
                    Remove-Item -Recurse -Force "$tempFontFolder" | Out-Null
                }

                if ( -not(Test-Path -Path "$tempFontFolder") ) {
                    New-Item -ItemType directory -Path "$tempFontFolder" | Out-Null
                }

                $zipFile = "$tempFontFolder\font.zip"

                # Download the font
                Get-File -Url $fontUrl -Filename $zipFile
                Expand-Archive -Path "$zipFile" -DestinationPath "$tempFontFolder" -Force

                Remove-Item -Recurse -Force "$zipFile" | Out-Null
                Write-Host "Removed intermediate archive: '$zipFile'"

                Write-Host "Downloaded font: '$tempFontFolder\$fontNameOriginal.ttf'"
                Write-Host "Renamed font: '$targetTempFontPath'"

                Copy-Item -Path "$tempFontFolder\$fontNameOriginal.ttf" -Destination "$targetTempFontPath"
            }

            # Remove the existing font first
            If (Test-Path "$targetFontPath" -PathType Any) {
                # Very likely for this to fail so do not print errors
                Remove-Item "$targetFontPath" -Recurse -Force -ErrorAction SilentlyContinue >$null
            }

            # By using a 'special folder' namespace here we can get around the need to run
            # as administrator to install files. Related:
            #
            #    - https://richardspowershellblog.wordpress.com/2008/03/20/special-folders/
            #    - https://gist.github.com/anthonyeden/0088b07de8951403a643a8485af2709b
            $fontsFolder = (New-Object -ComObject Shell.Application).Namespace(0x14)
            If (-not(Test-Path "$targetFontPath" -PathType Container)) {
                # Following action performs the install and hides confirmation
                #    - FOF_SILENT            0x0004
                #    - FOF_NOCONFIRMATION    0x0010
                #    - FOF_NOERRORUI         0x0400
                $fontsFolder.CopyHere("$targetFontPath", 0x0004 -bor 0x0010 -bor 0x0400)
                Write-Host "Copied font to system: '$targetFontPath'"
            }
            else {
                Write-Host "Skipped font copy since font path is container type: '$targetFontPath'"
            }
        }
        catch [Exception] {
            Write-Host "Failed to download and install font.", $_.Exception.Message
        }

        # Need to set this for console
        $key = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont'
        try {
            Set-ItemProperty -Path $key -Name '000' -Value "$fontName" -ErrorAction SilentlyContinue
        }
        catch {
            Write-Host "Failed to update font registry. Requires administrator access."
        }

        # TODO Add to local local data
        #    - Computer\HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts
        #    - JetBrains Mono ExtraLight (TrueType)
        #    - C:\Users\jovaneen\AppData\Local\Microsoft\Windows\Fonts\JetBrainsMono-BoldItalic.ttf

        try {
            Import-Module WindowsConsoleFonts -ErrorAction SilentlyContinue >$null
            if ($?) {
                # We do NOT want to add the temporary font because it makes it impossible to remove
                # Add-Font "$targetTempFontPath"

                Set-ConsoleFont "$fontName" | Out-Null

                Write-Host "Updated current console font: '$fontName'"
            }
        }
        catch [Exception] {
            Write-Host "Failed to install WindowsConsoleFonts.", $_.Exception.Message
        }

        try {
            # After the above are setup, can add this to Profile to always loads
            Import-Module Terminal-Icons
            Set-TerminalIconsTheme -ColorTheme DevBlackOps -IconTheme DevBlackOps

            Write-Host "Updated terminal icons and font."
        }
        catch [Exception] {
            Write-Host "Failed to update console to '$fontName' font.", $_.Exception.Message
        }

        Write-Host "Initialized Mycelio environment for Windows."
    }
}

Initialize-Environment
