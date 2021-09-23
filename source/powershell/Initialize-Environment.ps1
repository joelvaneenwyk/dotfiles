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

using namespace System.Net.Http;

<#
.SYNOPSIS
    Returns true if the given command can be executed from the shell.
.INPUTS
    Command name which does not need to be a full path.
.OUTPUTS
    Whether or not the command exists and can be executed.
#>
Function Test-CommandValid {
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
} #end function Test-CommandValid

Function Expand-File {
    <#
.SYNOPSIS
    Extract an archive using 7zip if available otherwise use built-in utilities.
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
        [string]$DestinationPath,
        [string]$Path = ''
    )

    if (![System.IO.Path]::IsPathRooted($DestinationPath)) {
        $DestinationPath = Join-Path (Get-Item -Path ".\" -Verbose).FullName $DestinationPath
    }

    if (![System.IO.Path]::IsPathRooted($Path)) {
        $Path = Join-Path (Get-Item -Path ".\" -Verbose).FullName $Path
    }

    $7zip = "$Env:UserProfile\scoop\apps\7zip\current\7z.exe"

    try {
        Write-Host "Extracting archive: '$Path'"
        if (Test-Path -Path "$7zip" -PathType Leaf) {
            & "$7zip" x "$Path" -aoa -o"$DestinationPath" -r -y
        }
        else {
            $ProgressPreference = 'SilentlyContinue'
            Expand-Archive -Path "$Path" -DestinationPath "$DestinationPath" -Force
        }
        Write-Host "Extracted archive to target: '$DestinationPath'"
    }
    catch {
        throw "⚠ Failed to extract archive: $Path"
    }
}

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

    $FilePath = $Filename

    # Make absolute local path
    if (![System.IO.Path]::IsPathRooted($Filename)) {
        $FilePath = Join-Path (Get-Item -Path ".\" -Verbose).FullName $Filename
    }


    $handler = $null
    try {
        $handler = New-Object -TypeName System.Net.Http.HttpClientHandler
        Write-Host "Downloading with invoke web request: $Url"
    }
    catch {
        Write-Host "Downloading: $Url"
    }

    if ($null -ne ($Url -as [System.URI]).AbsoluteURI) {
        if ($null -eq $handler) {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-WebRequest -UseBasicParsing -Uri "$Url" -OutFile "$Filename"
        }
        else {
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
        }

        Write-Host "Downloaded file: '$Filename'"
    }
    else {
        throw "⚠ Failed to download file: $Url"
    }
}

Function Install-Tool {
    <#
.SYNOPSIS
    Installs a tool with 'scoop' if it does not exist.
.DESCRIPTION
    Installs a tool with 'scoop' if it does not exist.
.PARAMETER Tool
    Tool to install and also the command name
.EXAMPLE
    C:\PS> Install-Tool sudo
#>

    Param(
        [Parameter(Position = 0, mandatory = $true)]
        [string]$Tool
    )

    if (-not(Test-CommandValid "$Tool")) {
        scoop install "$Tool"
    }
}

Function msys() {
    & "$Env:UserProfile\.local\msys64\usr\bin\bash.exe" @('-lc') + @Args
}

Function Initialize-Environment {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPositionalParameters', '', Scope = 'Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '', Scope = 'Function')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '', Scope = 'Function')]
    param()

    $MycelioRoot = Resolve-Path -Path "$PSScriptRoot\..\..\"

    $MycelioTempDir = "$ENV:UserProfile\.tmp"
    if ( -not(Test-Path -Path "$MycelioTempDir") ) {
        New-Item -ItemType directory -Path "$MycelioTempDir" | Out-Null
    }

    $MycelioArtifactsDir = "$MycelioRoot\artifacts\"
    if ( -not(Test-Path -Path "$MycelioArtifactsDir") ) {
        New-Item -ItemType directory -Path "$MycelioArtifactsDir" | Out-Null
    }

    $MycelioLocalDir = "$Env:UserProfile\.local\"
    if ( -not(Test-Path -Path "$MycelioLocalDir") ) {
        New-Item -ItemType directory -Path "$MycelioLocalDir" | Out-Null
    }

    $sandboxTemplate = Get-Content -Path "$MycelioRoot\source\windows\sandbox\sandbox.wsb.template" -Raw
    $sandbox = $sandboxTemplate -replace '${workspaceFolder}', $MycelioRoot
    Set-Content -Path "$MycelioArtifactsDir\sandbox.wsb" -Value "$sandbox"

    $fontBaseName = "JetBrains Mono"
    $fontBaseFilename = $fontBaseName -replace '\s', ''
    $fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/$fontBaseFilename.zip"
    $fontNameOriginal = "$fontBaseName Regular Nerd Font Complete Windows Compatible"
    $fontName = "$fontBaseFilename NF"
    $tempFontFolder = "$MycelioTempDir\fonts"
    $targetTempFontPath = "$tempFontFolder\$fontName.ttf"

    # We save it to system directory with same path it's the name that needs to be short
    $targetFontPath = "C:\Windows\Fonts\$fontNameOriginal.ttf"

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    if ( -not(Test-Path -Path "$Env:UserProfile\.local\msys64\mingw64.exe" -PathType Leaf) ) {
        $msysInstaller = "https://github.com/msys2/msys2-installer/releases/download/2021-07-25/msys2-base-x86_64-20210725.sfx.exe"

        if ( -not(Test-Path -Path "$MycelioTempDir\msys2.exe" -PathType Leaf) ) {
            Write-Host "Downloading MSYS2..."
            Get-File -Url "$msysInstaller" -Filename "$MycelioTempDir\msys2.exe"
        }

        $msysDir = "$Env:UserProfile\.local\msys64"

        if ( -not(Test-Path -Path "$msysDir\msys2.exe" -PathType Leaf) ) {
            & "$MycelioTempDir\msys2.exe" -y -o"$Env:UserProfile\.local"

            Set-Content -Path "$msysDir\etc\post-install\09-dotfiles.post" -Value @"
MAYBE_FIRST_START=false
[ -f '/usr/bin/update-ca-trust' ] && sh /usr/bin/update-ca-trust
echo '[mycelio] Post-install complete.'
"@

            # We run this here to ensure that the first run of msys2 is done before the 'setup.sh' call
            # as the initial upgrade of msys2 results in it shutting down the console.
            & cmd /s /c "$Env:UserProfile\.local\msys64\msys2_shell.cmd -mingw64 -defterm -no-start -where $MycelioRoot -shell bash -c ./source/shell/initialize-package-manager.sh"

            # Upgrade all packages
            msys 'pacman --noconfirm -Syuu'

            # Clean entire package cache
            msys 'pacman --noconfirm -Scc'

            Write-Host '[mycelio] Finished MSYS2 install.'
        }
    }

    try {
        if (-not(Test-CommandValid "scoop")) {
            Write-Host "Installing 'scoop' package manager..."
            Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
        }
    }
    catch {
        Write-Host "Exception caught while installing `scoop` package manager."
    }
    finally {
        try {
            if (Test-CommandValid "scoop") {
                # Make sure git is installed first as scoop uses git to update itself
                Install-Tool "git"

                Install-Tool "7zip"

                # Install Perl which is necessary for 'stow' so that we can run it outside of msys
                # environment. We install it after 7zip since it extracts much faster than built-in
                # PowerShell utilities.
                try {
                    if (-Not (Test-Path -Path "$MycelioLocalDir\perl\portableshell.bat" -PathType Leaf)) {
                        $strawberryPerlVersion = "5.32.1.1"
                        $strawberyPerlUrl = "https://strawberryperl.com/download/$strawberryPerlVersion/strawberry-perl-$strawberryPerlVersion-64bit-portable.zip"
                        Get-File -Url "$strawberyPerlUrl" -Filename "$MycelioTempDir\strawberry-perl-$strawberryPerlVersion-64bit-portable.zip"
                        Expand-File -Path "$MycelioTempDir\strawberry-perl-$strawberryPerlVersion-64bit-portable.zip" -DestinationPath "$MycelioLocalDir\perl"
                    }
                }
                catch [Exception] {
                    Write-Host "Failed to install Strawberry Perl.", $_.Exception.Message
                }

                # Install mutagen so that we can synchronize folders much like 'rclone' but better
                try {
                    if (-Not (Test-Path -Path "$MycelioLocalDir\mutagen\mutagen.exe" -PathType Leaf)) {
                        $mutagenVersion = "v0.11.8"
                        $mutagenUrl = "https://github.com/mutagen-io/mutagen/releases/download/$mutagenVersion/mutagen_windows_amd64_$mutagenVersion.zip"
                        Get-File -Url "$mutagenUrl" -Filename "$MycelioTempDir\mutagen_windows_amd64_$mutagenVersion.zip"
                        Expand-File -Path "$MycelioTempDir\mutagen_windows_amd64_$mutagenVersion.zip" -DestinationPath "$MycelioLocalDir\mutagen"
                    }
                }
                catch [Exception] {
                    Write-Host "Failed to install mutagen.", $_.Exception.Message
                }

                # gsudo: Run commands as administrator.
                Install-Tool "gsudo"

                # innounp: Required for unpacking InnoSetup files.
                Install-Tool "innounp"

                # dark: Unpack installers created with the WiX Toolset.
                Install-Tool "dark"

                # Need this for VSCode
                scoop bucket add extras "https://github.com/lukesampson/scoop-extras.git"

                # Get latest buckets (requires 'git')
                scoop update

                # Install portable version even if it is already installed locally
                scoop install vscode-portable

                # Much better than default Windows terminal
                scoop install windows-terminal

                # Useful tool for syncing folders (like rsync) which is sometimes necessary with
                # environments like MSYS which do not work in containerized spaces that mount local
                # volumes as you can get 'Too many levels of symbolic links'
                Install-Tool "rclone"

                # 'gsudo' is more robust than 'sudo' package and not just a PowerShell
                # script, see https://github.com/gerardog/gsudo
                Install-Tool "gsudo"

                Install-Tool "nuget"

                # https://github.com/chrisant996/clink
                Install-Tool "clink"

                Write-Host "Verified that dependencies were installed with 'scoop' package manager."
            }
        }
        catch {
            Write-Host "Failed to install packages with 'scoop' manager."
        }

        try {
            if (Test-CommandValid "scoop") {
                $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
                if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
                    # Add SSH client, see https://stackoverflow.com/a/58029292
                    Add-WindowsCapability -Online -Name "OpenSSH.Client~~~~0.0.1.0"

                    # Windows Defender may slow down or disrupt installs with realtime scanning.
                    Import-Module Defender
                    gsudo Add-MpPreference -ExclusionPath "$Env:UserProfile\scoop"
                    gsudo Add-MpPreference -ExclusionPath "C:\ProgramData\scoop"

                    Write-Host "Initialized administrator settings for 'scoop' package manager."
                }
                else {
                    Write-Host "Skipped initialization of administrator settings."
                }

            }
        }
        catch {
            Write-Host "Failed to setup administrator settings for 'scoop' package manager."
        }

        try {
            $mutagen = "$Env:UserProfile\.local\mutagen\mutagen.exe"
            $rclone = "$Env:UserProfile\scoop\apps\rclone\current\rclone.exe"

            # Useful tool for syncing folders (like rsync) which is sometimes necessary with
            # environments like MSYS which do not work in containerized spaces that mount local
            # volumes as you can get 'Too many levels of symbolic links'
            if (("$Env:Username" -eq "WDAGUtilityAccount") -and (Test-Path -Path "C:\Workspace")) {
                if (Test-Path -Path "$mutagen" -PathType Leaf) {
                    & "$mutagen" terminate "dotfiles"
                    & "$mutagen" sync create "C:\Workspace\" "$Env:UserProfile\dotfiles" --name "dotfiles" --sync-mode "two-way-safe" --symlink-mode "portable" --ignore-vcs --ignore "fzf_key_bindings.fish" --ignore "clink_history*" --ignore "_Inline/" --ignore "_build/"
                    & "$mutagen" sync flush --all
                }
                else {
                    Write-Host "⚠ Missing 'mutagen' tool."

                    if (Test-Path -Path "$rclone" -PathType Leaf) {
                        if (("$Env:Username" -eq "WDAGUtilityAccount") -and (Test-Path -Path "C:\Workspace")) {
                            & "$rclone" sync "C:\Workspace" "$Env:UserProfile\dotfiles" --copy-links --exclude ".git/" --exclude "fzf_key_bindings.fish" --exclude "clink_history*"
                        }
                        else {
                            Write-Host "Skipped 'dotfiles' sync since we are not in container."
                        }
                    }
                    else {
                        Write-Host "⚠ Missing 'rclone' tool."
                    }
                }
            }
            else {
                Write-Host "Skipped 'dotfiles' sync since we are not in container."
            }
        }
        catch [Exception] {
            Write-Host "Failed to sync dotfiles to user profile.", $_.Exception.Message
        }

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
                Expand-File -Path "$zipFile" -DestinationPath "$tempFontFolder"

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
