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
    catch {
        $IsValid = $false
    }
    finally {
        $ErrorActionPreference = $oldPreference
    }

    return $IsValid
}

Function AddSymbolicLinkPermissions($accountToAdd) {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
        Write-Host "Unable to add symbolic link privileges. Please run as administrator."
    }
    else {
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord | Out-Null
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord | Out-Null

        Write-Host "Checking SymLink permissions.."
        $sidstr = $null
        try {
            $ntprincipal = New-Object System.Security.Principal.NTAccount "$accountToAdd"
            $sid = $ntprincipal.Translate([System.Security.Principal.SecurityIdentifier])
            $sidstr = $sid.Value.ToString()
        }
        catch {
            $sidstr = $null
        }

        Write-Host "Account: $($accountToAdd)" -ForegroundColor DarkCyan
        if ( [string]::IsNullOrEmpty($sidstr) ) {
            Write-Host "Account not found!" -ForegroundColor Red
            exit -1
        }

        Write-Host "Account SID: $($sidstr)" -ForegroundColor DarkCyan
        $tmp = [System.IO.Path]::GetTempFileName()
        Write-Host "Export current Local Security Policy" -ForegroundColor DarkCyan
        C:\Windows\System32\SecEdit.exe /export /cfg "$($tmp)"
        $c = Get-Content -Path $tmp
        $currentSetting = ""
        foreach ($s in $c) {
            if ( $s -like "SECreateSymbolicLinkPrivilege*") {
                $x = $s.split("=", [System.StringSplitOptions]::RemoveEmptyEntries)
                $currentSetting = $x[1].Trim()
            }
        }
        if ( $currentSetting -notlike "*$($sidstr)*" ) {
            Write-Host "Need to add permissions to SymLink" -ForegroundColor Yellow

            Write-Host "Modify Setting ""Create SymLink""" -ForegroundColor DarkCyan

            if ( [string]::IsNullOrEmpty($currentSetting) ) {
                $currentSetting = "*$($sidstr)"
            }
            else {
                $currentSetting = "*$($sidstr),$($currentSetting)"
            }
            Write-Host "$currentSetting"
            $outfile = @"
[Unicode]
Unicode=yes
[Version]
signature="`$CHICAGO`$"
Revision=1
[Privilege Rights]
SECreateSymbolicLinkPrivilege = $($currentSetting)
"@
            $tmp2 = [System.IO.Path]::GetTempFileName()
            Write-Host "Import new settings to Local Security Policy" -ForegroundColor DarkCyan
            $outfile | Set-Content -Path $tmp2 -Encoding Unicode -Force
            Push-Location (Split-Path $tmp2)
            try {
                C:\Windows\System32\SecEdit.exe /configure /db "secedit.sdb" /cfg "$($tmp2)" /areas USER_RIGHTS
            }
            finally {
                Pop-Location
            }
        }
        else {
            Write-Host "NO ACTIONS REQUIRED! Account already in ""Create SymLink""" -ForegroundColor DarkCyan
            Write-Host "Account $accountToAdd already has permissions to SymLink" -ForegroundColor Green
            return $true;
        }
    }
}

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
        $DestinationPath = Join-Path (Get-Item -Path "./" -Verbose).FullName $DestinationPath
    }

    if (![System.IO.Path]::IsPathRooted($Path)) {
        $Path = Join-Path (Get-Item -Path "./" -Verbose).FullName $Path
    }

    $7zip = ""

    if ($IsWindows -or $ENV:OS) {
        $7za920zip = Join-Path -Path "$script:MycelioArchivesDir" -ChildPath "7za920.zip"
        $7za920 = Join-Path -Path "$script:MycelioLocalDir" -ChildPath "7za920"

        # Download 7zip that was stored in a zip file so that we can extract the latest version stored in 7z format
        if (-not(Test-Path -Path "$7za920zip" -PathType Leaf)) {
            Get-File -Url "https://www.7-zip.org/a/7za920.zip" -Filename "$7za920zip"
        }

        # Extract previous version of 7zip first
        if (Test-Path -Path "$7za920zip" -PathType Leaf) {
            if (-not(Test-Path -Path "$7za920/7za.exe" -PathType Leaf)) {
                if ( -not(Test-Path -Path "$7za920") ) {
                    New-Item -ItemType directory -Path "$7za920" | Out-Null
                }

                # We use this approach as it is compatible with PowerShell 2.0 as opposed to
                # Expand-Archive which requires .NET 4
                $shell = New-Object -ComObject Shell.Application
                $zip = $shell.NameSpace("$7za920zip")
                $targetFolder = $shell.Namespace("$7za920")
                foreach ($item in $zip.items()) {
                    $targetFolder.CopyHere($item, 1564)
                }
            }
        }

        # If older vresion is available, download and extract latest
        if (Test-Path -Path "$7za920/7za.exe" -PathType Leaf) {
            $7z2201zip = Join-Path -Path "$script:MycelioArchivesDir" -ChildPath "7z2201-extra.7z"
            $7z2201 = Join-Path -Path "$script:MycelioLocalDir" -ChildPath "7z2201"

            # Download latest version of 7zip
            if (-not(Test-Path -Path "$7z2201zip" -PathType Leaf)) {
                Get-File -Url "https://www.7-zip.org/a/7z2201-extra.7z" -Filename "$7z2201zip"
            }

            # Extract latest vesrion using old version
            if (Test-Path -Path "$7z2201zip" -PathType Leaf) {
                if ( -not(Test-Path -Path "$7z2201") ) {
                    New-Item -ItemType directory -Path "$7z2201" | Out-Null
                }

                if (-not(Test-Path -Path "$7z2201/7za.exe" -PathType Leaf)) {
                    Write-Host "$7za920/7za.exe x $7z2201zip -aoa -o$7z2201 -r -y"
                    & "$7za920/7za.exe" @(
                        "x", "$7z2201zip", "-aoa", "-o$7z2201", "-r", "-y")
                    Write-Host "Extracted archive: '$7z2201'"
                }
            }
        }

        # Specify latest version of 7zip so that we can use it below
        if (Test-Path -Path "$7z2201/x64/7za.exe" -PathType Leaf) {
            $7zip = "$7z2201/x64/7za.exe"
        }
    }
    else {
        $7z2201zip = Join-Path -Path "$script:MycelioArchivesDir" -ChildPath "7z2201-linux-x64.tar.xz"
        $7z2201 = Join-Path -Path "$script:MycelioLocalDir" -ChildPath "7z2201"

        # Download 7zip that was stored in a zip file so that we can extract the latest version stored in 7z format
        if (-not(Test-Path -Path "$7z2201zip" -PathType Leaf)) {
            Get-File -Url "https://www.7-zip.org/a/7z2201-linux-x64.tar.xz" -Filename "$7z2201zip"
        }

        # Extract previous version of 7zipTempDir first
        if (Test-Path -Path "$7z2201zip" -PathType Leaf) {
            if ( -not(Test-Path -Path "$7z2201") ) {
                New-Item -ItemType directory -Path "$7z2201" | Out-Null
            }

            if (-not(Test-Path -Path "$7z2201/7zz" -PathType Leaf)) {
                tar -xvf "$7z2201zip" -C "$7z2201"
            }
        }

        if (Test-Path -Path "$7z2201/7zz" -PathType Leaf) {
            $7zip = "$7z2201/7zz"
        }
    }

    try {
        Write-Host "Extracting archive: '$Path'"
        if ($Path -match '\.sfx\.exe$') {
            & "$Path" @(
                "x", "-o$DestinationPath", "-y")
        }
        elseif (Test-Path -Path "$7zip" -PathType Leaf) {
            & "$7zip" @(
                "x", "$Path", "-aoa", "-o$DestinationPath", "-r", "-y")
        }
        else {
            Write-Host "7-zip not found: '$7zip'"

            $ProgressPreference = 'SilentlyContinue'

            if ($IsWindows -or $ENV:OS) {
                if ( -not(Test-Path -Path "$DestinationPath") ) {
                    New-Item -ItemType directory -Path "$DestinationPath" | Out-Null
                }

                # We use this approach as it is compatible with PowerShell 2.0 as opposed to
                # Expand-Archive which requires .NET 4
                $shell = New-Object -ComObject Shell.Application
                $zip = $shell.NameSpace("$Path")
                $targetFolder = $shell.Namespace("$DestinationPath")
                foreach ($item in $zip.items()) {
                    $targetFolder.CopyHere($item, 1564)
                }
            }
            else {
                Expand-Archive -Path "$Path" -DestinationPath "$DestinationPath" -Force
            }
        }
        Write-Host "Extracted archive to target: '$DestinationPath'"
    }
    catch [Exception] {
        Write-Host $_.Exception.GetType().FullName, $_.Exception.Message
        throw "Failed to extract archive: $Path"
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

    # Convert local/relative path to absolute path
    if (![System.IO.Path]::IsPathRooted($Filename)) {
        $FilePath = Join-Path (Get-Item -Path "./" -Verbose).FullName $Filename
    }
    else {
        $FilePath = $Filename
    }

    $FilePathOut = "$FilePath.out"

    if ($null -eq ($Url -as [System.URI]).AbsoluteURI) {
        throw "⚠ Invalid Url: $Url"
    }
    elseif (Test-Path -Path "$FilePath" -PathType Leaf) {
        Write-Host "File already available: '$FilePath'"
    }
    else {
        Write-Host "Target: '$FilePathOut'"
        $handler = $null
        $webclient = $null

        try {
            $webclient = New-Object System.Net.WebClient
            Write-Host "[web.client] Downloading: $Url"
            $webclient.DownloadFile($Url, "$FilePathOut")
        }
        catch {
            try {
                $handler = New-Object -TypeName System.Net.Http.HttpClientHandler
                $handler = New-Object -TypeName System.Net.Http.HttpClientHandler
                $client = New-Object -TypeName System.Net.Http.HttpClient -ArgumentList $handler
                $client.Timeout = New-Object -TypeName System.TimeSpan -ArgumentList 0, 30, 0
                $cancelTokenSource = New-Object 'System.Threading.CancellationTokenSource' @(-1)
                $responseMsg = $client.GetAsync((New-Object 'System.Uri' @($Url)), $cancelTokenSource.Token)
                $responseMsg.Wait()

                Write-Host "[http.client.handler] Downloading: $Url"

                if (!$responseMsg.IsCanceled) {
                    $response = $responseMsg.Result
                    if ($response.IsSuccessStatusCode) {
                        $downloadedFileStream = New-Object 'System.IO.FileStream' @(
                            $FilePathOut,
                            [System.IO.FileMode]::Create,
                            [System.IO.FileAccess]::Write,
                            [System.IO.FileShare]::None)

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
            catch {
                Write-Host "[web.request] Downloading: $Url"
                $ProgressPreference = 'SilentlyContinue'
                Invoke-WebRequest -UseBasicParsing -Uri "$Url" -OutFile "$FilePathOut"
            }
        }
        finally {
            if (Test-Path -Path "$FilePathOut" -PathType Leaf) {
                Move-Item -Path "$FilePathOut" -Destination "$FilePath" -Force
                Write-Host "Downloaded file: '$FilePath'"
            }
            else {
                throw "Failed to download file: $Url"
            }
        }
    }
}

Function Install-Git {
    # Install git so we can clone repositories
    try {
        $script:MycelioGit = ""

        $gitCommand = (Get-Command -Name "git" -CommandType Application -ErrorAction SilentlyContinue)
        if ($null -ne $gitCommand) {
            $script:MycelioGit = ($gitCommand `
                | Where-Object {
                    $gitPath = $_.Definition
                    try {
                        & "$gitPath" --version | Out-Null
                    }
                    catch [Exception] {
                        Write-Host "Failed to install minimal 'Git' for Windows.", $_.Exception.Message
                    }
                    return $?
                } `
                | Select-Object -First 1).Definition
        }

        $MycelioLocalGitDir = Join-Path -Path "$script:MycelioLocalDir" -ChildPath "git"
        $MycelioLocalGitBinDir = Join-Path -Path "$MycelioLocalGitDir" -ChildPath "cmd"
        $script:MycelioLocalGit = Join-Path -Path "$MycelioLocalGitBinDir" -ChildPath "git.exe"

        if (-Not (Test-Path -Path "$script:MycelioLocalGit" -PathType Leaf)) {
            $gitFilename = "MinGit-2.33.0.2-64-bit.zip"
            $gitArchive = Join-Path -Path "$script:MycelioArchivesDir" -ChildPath "$gitFilename"
            Get-File -Url "https://github.com/git-for-windows/git/releases/download/v2.33.0.windows.2/$gitFilename" -Filename "$gitArchive"
            Expand-File -Path "$gitArchive" -DestinationPath "$MycelioLocalGitDir"
        }

        if (-Not (Test-Path -Path "$script:MycelioGit" -PathType Leaf)) {
            $script:MycelioGit = "$script:MycelioLocalGit"
        }

        $gitDir = [System.IO.Path]::GetDirectoryName("$script:MycelioGit")

        # Make sure this shows up in path first
        $env:Path = "$gitDir;$env:Path"

        Write-Host "Git: '$script:MycelioGit'"
    }
    catch [Exception] {
        Write-Host "Failed to install minimal 'Git' for Windows.", $_.Exception.Message
    }

    try {
        if (-not (Test-Path -Path "$script:MycelioRoot/source/stow/setup.sh" -PathType Leaf)) {
            if (Test-Path -Path "$script:MycelioGit" -PathType Leaf) {
                & "$script:MycelioGit" -C "$script:MycelioRoot" submodule update --init --recursive
            }
        }
    }
    catch {
        Write-Host "Failed to update submodules with 'git' command."
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

Function Write-WindowsSandboxTemplate {
    $sandboxTemplate = Get-Content -Path "$script:MycelioRoot\source\windows\sandbox\sandbox.wsb.template" | Out-String
    $sandbox = $sandboxTemplate -replace '${workspaceFolder}', $script:MycelioRoot
    Set-Content -Path "$script:MycelioArtifactsDir\sandbox.wsb" -Value "$sandbox"
}

Function Initialize-ConsoleFont {
    Write-Host "::group::Initialize Console Font"

    $fontBaseName = "JetBrains Mono"
    $fontBaseFilename = $fontBaseName -replace '\s', ''
    $fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/$fontBaseFilename.zip"
    $fontNameOriginal = "$fontBaseName Regular Nerd Font Complete Windows Compatible"
    $fontName = "$fontBaseFilename NF"
    $tempFontFolder = "$script:MycelioTempDir\fonts"
    $targetTempFontPath = "$tempFontFolder\$fontName.ttf"

    # We save it to system directory with same path it's the name that needs to be short
    $targetFontPath = "C:\Windows\Fonts\$fontNameOriginal.ttf"


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
            Get-File -Url "$fontUrl" -Filename "$zipFile"
            Expand-File -Path "$zipFile" -DestinationPath "$tempFontFolder"

            if (Test-Path -Path "$tempFontFolder\$fontNameOriginal.ttf" -PathType Leaf) {
                Write-Host "Downloaded font: '$tempFontFolder\$fontNameOriginal.ttf'"
                Copy-Item -Path "$tempFontFolder\$fontNameOriginal.ttf" -Destination "$targetTempFontPath"
                Write-Host "Renamed font: '$targetTempFontPath'"
            }
            else {
                Write-Host "Failed to find font: '$tempFontFolder\$fontNameOriginal.ttf'"
            }
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
    #    - C:\Users\username\AppData\Local\Microsoft\Windows\Fonts\JetBrainsMono-BoldItalic.ttf

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
        Import-Module Terminal-Icons -ErrorAction SilentlyContinue >$null
        Set-TerminalIconsTheme -ColorTheme DevBlackOps -IconTheme DevBlackOps

        Write-Host "Updated terminal icons and font."
    }
    catch [Exception] {
        Write-Host "Failed to update console to '$fontName' font.", $_.Exception.Message
    }

    Write-Host "::endgroup::"
}

Function Get-TexLive {
    try {
        Write-Host "::group::Get TexLive"

        if ($IsWindows -or $ENV:OS) {
            Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
        }

        if ( -not(Test-Path -Path "$script:MycelioTempDir") ) {
            New-Item -ItemType directory -Path "$script:MycelioTempDir" | Out-Null
        }

        $tempTexFolder = Join-Path -Path "$script:MycelioLocalDir" -ChildPath "texlive-tmp"
        $tempTexTargetFolder = Join-Path -Path "$script:MycelioLocalDir" -ChildPath "texlive-install"
        $tempTexTargetInstall = Join-Path -Path "$tempTexTargetFolder" -ChildPath "install-tl-windows.bat"
        $tempTexArchive = Join-Path -Path "$script:MycelioArchivesDir" -ChildPath "install-tl.zip"

        if (Test-Path -Path "$tempTexTargetInstall" -PathType Leaf) {
            Write-Host "Installer already available: '$tempTexTargetInstall'"
        }
        else {
            Get-File -Url "https://mirror.ctan.org/systems/texlive/tlnet/install-tl.zip" -Filename "$tempTexArchive"

            # Remove tex folder if it exists
            If (Test-Path "$tempTexFolder" -PathType Any) {
                Remove-Item -Recurse -Force "$tempTexFolder" | Out-Null
            }
            Expand-File -Path "$tempTexArchive" -DestinationPath "$tempTexFolder"

            Get-ChildItem -Path "$tempTexFolder" -Force `
            | Where-Object { $_.PSIsContainer } `
            | Select-Object -First 1 `
            | Move-Item -Destination "$tempTexTargetFolder" -Force
        }

        # Remove tex folder if it exists
        If (Test-Path "$tempTexFolder" -PathType Any) {
            Remove-Item -Recurse -Force "$tempTexFolder" | Out-Null
        }

        $env:TEXLIVE_ROOT = "$tempTexTargetFolder"
        $env:TEXLIVE_INSTALL = "$tempTexTargetInstall"

        $TexLiveInstallRoot = "$script:MycelioLocalDir\texlive"

        $env:TEXDIR = "$TexLiveInstallRoot\latest"
        if ( -not(Test-Path -Path "$env:TEXDIR") ) {
            New-Item -ItemType directory -Path "$env:TEXDIR" | Out-Null
        }

        # https://github.com/TeX-Live/installer/blob/master/install-tl
        $env:TEXLIVE_INSTALL_PREFIX = "$TexLiveInstallRoot"
        $env:TEXLIVE_INSTALL_TEXDIR = "$env:TEXDIR"
        $env:TEXLIVE_INSTALL_TEXMFSYSCONFIG = "$env:TEXDIR\texmf-config"
        $env:TEXLIVE_INSTALL_TEXMFSYSVAR = "$env:TEXDIR\texmf-var"
        $env:TEXLIVE_INSTALL_TEXMFHOME = "$TexLiveInstallRoot\texmf"
        $env:TEXLIVE_INSTALL_TEXMFLOCAL = "$TexLiveInstallRoot\texmf-local"
        $env:TEXLIVE_INSTALL_TEXMFVAR = "$TexLiveInstallRoot\texmf-var"
        $env:TEXLIVE_INSTALL_TEXMFCONFIG = "$TexLiveInstallRoot\texmf-config"

        $env:TEXLIVE_BIN = "$env:TEXLIVE_INSTALL_PREFIX\bin\win32"
        $env:TEXMFSYSCONFIG = "$env:TEXLIVE_INSTALL_TEXMFSYSCONFIG"
        $env:TEXMFSYSVAR = "$env:TEXLIVE_INSTALL_TEXMFSYSVAR"
        $env:TEXMFHOME = "$env:TEXLIVE_INSTALL_TEXMFHOME"
        $env:TEXMFLOCAL = "$env:TEXLIVE_INSTALL_TEXMFLOCAL"
        $env:TEXMFVAR = "$env:TEXLIVE_INSTALL_TEXMFVAR"
        $env:TEXMFCONFIG = "$env:TEXLIVE_INSTALL_TEXMFCONFIG"

        $texLiveProfile = Join-Path -Path "$tempTexTargetFolder" -ChildPath "install-texlive.profile"
        Set-Content -Path "$texLiveProfile" -Value @"
# It will NOT be updated and reflects only the
# installation profile at installation time.

selected_scheme scheme-custom
binary_win32 1
collection-basic 1
collection-wintools 1
collection-binextra 0
collection-formatsextra 0
instopt_adjustpath 0
instopt_adjustrepo 1
#instopt_desktop_integration 0
#instopt_file_assocs 0
instopt_letter 0
instopt_portable 0
instopt_write18_restricted 1
tlpdbopt_autobackup 1
tlpdbopt_backupdir tlpkg/backups
tlpdbopt_create_formats 1
tlpdbopt_desktop_integration 0
tlpdbopt_file_assocs 0
tlpdbopt_generate_updmap 0
tlpdbopt_install_docfiles 0
tlpdbopt_install_srcfiles 0
tlpdbopt_post_code 1
tlpdbopt_sys_bin /usr/local/bin
tlpdbopt_sys_info /usr/local/share/info
tlpdbopt_sys_man /usr/local/share/man
tlpdbopt_w32_multi_user 0
"@

        # Update PATH environment as we need to make sure 'cmd.exe' is available since the TeX Live manager
        # expected it to work.
        $env:Path = "$ENV:SystemRoot\System32\;$env:TEXLIVE_BIN;$env:Path"

        $texExecutable = Join-Path -Path "$env:TEXLIVE_BIN" -ChildPath "tex.exe"
        If (Test-Path "$texExecutable" -PathType Leaf) {
            Write-Host "Skipped install. TeX already exists: '$texExecutable'"
        }
        elseif ($IsWindows -or $ENV:OS) {
            $errorPreference = $ErrorActionPreference
            $ErrorActionPreference = 'SilentlyContinue'

            # We redirect stderr to stdout because of a seemingly unavoidable error that we get during
            # install e.g. 'Use of uninitialized value $deftmflocal in string at C:\...\texlive-install\install-tl line 1364.'
            & "$ENV:SystemRoot\System32\cmd.exe" /d /c ""$env:TEXLIVE_INSTALL" -no-gui -portable -profile "$texLiveProfile"" 2>&1

            $ErrorActionPreference = $errorPreference
        }
        else {
            Write-Host "TeX Live install process only supported on Windows."
        }

        if ($IsWindows -or $ENV:OS) {
            & "$ENV:SystemRoot\System32\cmd.exe" /d /c ""$env:TEXLIVE_BIN\tlmgr.bat" update -all"
        }
    }
    catch [Exception] {
        Write-Host "Failed to download and extract TeX Live.", $_.Exception.Message
    }
    finally {
        Write-Host "::endgroup::"
    }
}

Function Start-Bash() {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function')]
    param()

    Write-Host "[bash] $Args"

    if ($IsWindows -or $ENV:OS) {
        & "$script:MsysTargetDir/usr/bin/bash.exe" @('-lc') + @Args
    }
    else {
        Write-Host "Skipped command. This is only supported on Windows."
    }
}

Function Test-SymbolicLink {
    $errorPreference = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'

    $createdSymbolicLink = $false
    $linkTargetTemp = "$script:MycelioTempDir\link_test.sh"
    $linkSource = "$script:MycelioRoot\setup.sh"

    if (Test-Path $linkTargetTemp) {
        Remove-Item $linkTargetTemp
    }

    # We redirect stderr to stdout because of a seemingly unavoidable error that we get during
    # install e.g. 'Use of uninitialized value $deftmflocal in string at C:\...\texlive-install\install-tl line 1364.'
    & "$ENV:SystemRoot\System32\cmd.exe" /d /c "mklink "$linkTargetTemp" "$linkSource" > nul 2>&1"
    if ($? -and (Test-Path $linkTargetTemp)) {
        $createdSymbolicLink = $true
        Remove-Item $linkTargetTemp
    }

    $ErrorActionPreference = $errorPreference

    return $createdSymbolicLink
}
Function Install-MSYS2 {
    $script:MsysTargetDir = "$script:MycelioLocalDir/msys64"
    $script:MsysInstaller = "msys2-base-x86_64-20221028.sfx.exe"
    $script:MsysArchive = "$script:MycelioArchivesDir/$script:MsysInstaller"
    $script:MsysUrl = "https://github.com/msys2/msys2-installer/releases/download/2022-10-28/$script:MsysInstaller"

    if ( -not(Test-Path -Path "$script:MsysTargetDir/mingw64.exe" -PathType Leaf) ) {
        if ( -not(Test-Path -Path "$script:MsysArchive" -PathType Leaf) ) {
            Write-Host "::group::Download MSYS2"
            Get-File -Url "$script:MsysUrl" -Filename "$script:MsysArchive"
            Write-Host "::endgroup::"
        }

        if ( -not(Test-Path -Path "$script:MsysTargetDir/usr/bin/bash.exe" -PathType Leaf) ) {
            Write-Host "::group::Install MSYS2"
            Expand-File -Path "$script:MsysArchive" -Destination "$script:MycelioLocalDir"
            Write-Host "::endgroup::"
        }
    }

    $postInstallScript = "$script:MsysTargetDir/etc/post-install/09-mycelio.post"
    $initializedFile = "$script:MsysTargetDir/.initialized"

    if (Test-Path -Path "$script:MsysTargetDir/usr/bin/bash.exe" -PathType Leaf) {
        $mycelioRootCygwin = (& "$script:MsysTargetDir/usr/bin/cygpath.exe" "$script:MycelioRoot").TrimEnd("/")

        # Create a file that gets automatically called after installation which will silence the
        # clear that happens during a normal install. This may be useful for users by default but
        # this makes us lose the rest of the console log which is not great for our use case here.
        Set-Content -Path "$postInstallScript" -Value @"
MAYBE_FIRST_START=false

if [ ! -e "/.initialized" ]; then
    [ -f '/usr/bin/update-ca-trust' ] && sh /usr/bin/update-ca-trust

    echo "[mycelio] Starting initialization of MSYS2 package manager."

    if [ -x "`$(command -v pacman)" ] && [ -n "`${MSYSTEM:-}" ]; then
        echo "Mycelio initialized." >"/.initialized"

        if [ ! -f "/etc/passwd" ]; then
            mkpasswd -l -c >"/etc/passwd"
        fi

        if [ ! -f "/etc/group" ]; then
            mkgroup -l -c >"/etc/group"
        fi

        if [ ! -L "/etc/nsswitch.conf" ]; then
            rm -f "/etc/nsswitch.conf"
            ln -s "$mycelioRootCygwin/source/windows/msys/nsswitch.conf" "/etc/nsswitch.conf"
        fi

        # https://github.com/msys2/MSYS2-packages/issues/2343#issuecomment-780121556
        rm -f "/var/lib/pacman/db.lck"

        pacman -Syu --quiet --noconfirm

        if [ -f "/etc/pacman.d/gnupg/" ]; then
            rm -rf "/etc/pacman.d/gnupg/"
        fi

        pacman-key --init
        pacman-key --populate msys2

        # Long version of '-Syuu' gets fresh package databases from server and
        # upgrades the packages while allowing downgrades '-uu' as well if needed.
        echo "[mycelio] Upgrade of all packages."
        pacman --quiet --sync --refresh -uu --noconfirm
    fi

    # Note that if this is the first run on MSYS2 it will likely never get here.
    echo "[mycelio] Initialized package manager. Post-install complete."
fi
"@

        if (($IsWindows -or $ENV:OS) -and [String]::IsNullOrEmpty("$env:MSYSTEM")) {
            $env:MSYS = "winsymlinks:native"

            if (-not (Test-Path -Path "$initializedFile" -PathType Leaf)) {
                $homeOriginal = $env:HOME
                $env:HOME = "$script:MycelioTempDir/home"

                # We run this here to ensure that the first run of msys2 is done before the 'setup.sh' call
                # as the initial upgrade of msys2 results in it shutting down the console.
                Write-Host "::group::Initialize MSYS2 Package Manager"
                Start-Bash "echo 'First run of MSYS2 to trigger post install.'"

                Write-Host "::group::Upgrade MSYS2 Packages"
                # Upgrade all packages
                Start-Bash 'pacman --noconfirm -Syuu'

                # Clean entire package cache
                Start-Bash 'pacman --noconfirm -Scc'
                Write-Host "::endgroup::"

                $env:HOME = "$homeOriginal"
            }

            Write-Host '[mycelio] Finished MSYS2 install.'
        }
        else {
            Write-Host '[mycelio] Extracted MSYS2 but skipped install.'
        }
    }
    else {
        Write-Host '[mycelio] MSYS2 already installed and initialized.'
    }
}

Function Install-Scoop {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingInvokeExpression', '', Scope = 'Function')]
    param()

    try {
        Write-Host "::group::Install Scoop"

        if (-not(Test-CommandValid "scoop")) {
            Write-Host "Installing 'scoop' package manager..."
            Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
        }
    }
    catch [Exception] {
        Write-Host "Exception caught while installing 'scoop' package manager.", $_.Exception.Message
    }
    finally {
        Write-Host "::endgroup::"
    }
}

Function Install-Toolset {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPositionalParameters', '', Scope = 'Function')]
    param()

    Write-Host "::group::Install Toolset"

    Get-TexLive

    # Install Perl which is necessary for 'Mycelio' so that we can run it outside of MSYS2 environment.
    try {
        if (-Not (Test-Path -Path "$script:MycelioLocalDir/perl/portableshell.bat" -PathType Leaf)) {
            $strawberryPerlVersion = "5.32.1.1"
            $strawberyPerlUrl = "https://strawberryperl.com/download/$strawberryPerlVersion/strawberry-perl-$strawberryPerlVersion-64bit-portable.zip"
            Get-File -Url "$strawberyPerlUrl" -Filename "$script:MycelioTempDir\strawberry-perl-$strawberryPerlVersion-64bit-portable.zip"
            Expand-File -Path "$script:MycelioTempDir\strawberry-perl-$strawberryPerlVersion-64bit-portable.zip" -DestinationPath "$script:MycelioLocalDir/perl"
        }
    }
    catch [Exception] {
        Write-Host "Failed to install Strawberry Perl.", $_.Exception.Message
    }

    # Install mutagen so that we can synchronize folders much like 'rclone' but better
    try {
        if (-Not (Test-Path -Path "$script:MycelioLocalDir/mutagen/mutagen.exe" -PathType Leaf)) {
            $mutagenVersion = "v0.11.8"
            $mutagenArchive = "mutagen_windows_amd64_$mutagenVersion.zip"
            $mutagenUrl = "https://github.com/mutagen-io/mutagen/releases/download/$mutagenVersion/$mutagenArchive"
            Get-File -Url "$mutagenUrl" -Filename "$script:MycelioTempDir/$mutagenArchive"
            Expand-File -Path "$script:MycelioTempDir/$mutagenArchive" -DestinationPath "$script:MycelioLocalDir/mutagen"
        }
    }
    catch [Exception] {
        Write-Host "Failed to install mutagen.", $_.Exception.Message
    }

    try {
        if (Test-CommandValid "scoop") {
            $scoopShim = (scoop config shim)
            if ("$scoopShim" -ne "kiennq") {
                scoop config shim kiennq
                scoop reset *
            }

            # Install first as this gives us faster multi-connection downloads
            Install-Tool "aria2"

            # gsudo: Run commands as administrator.
            Install-Tool "gsudo"

            # innounp: Required for unpacking InnoSetup files.
            Install-Tool "innounp"

            # dark: Unpack installers created with the WiX Toolset.
            Install-Tool "dark"

            # Need this for VSCode
            scoop bucket add extras "https://github.com/lukesampson/scoop-extras.git"

            # Need this for 'keepassxc'
            scoop bucket add nonportable "https://github.com/TheRandomLabs/scoop-nonportable.git"

            # Get latest buckets (requires 'git')
            scoop update

            $vscode_installed = $false

            # Install portable version even if it is already installed locally
            if (Test-Path -Path "C:\Program Files\Microsoft VS Code\Code.exe" -PathType Leaf) {
                $vscode_installed = $true
            }
            elseif (Test-Path -Path "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe" -PathType Leaf) {
                $vscode_installed = $true
            }

            if ($vscode_installed) {
                # Already installed nothing to do
            }
            elseif (Test-CommandValid "winget") {
                winget install -e --id Microsoft.VisualStudioCode --silent
            }
            else {
                scoop install vscode-portable
            }

            # Much better than default Windows terminal
            if (-not(Test-CommandValid "wt")) {
                elseif (Test-CommandValid "winget") {
                    winget install -e --id Microsoft.WindowsTerminal --silent
                }
                else {
                    scoop install windows-terminal
                }
            }

            Install-Tool "keepassxc"

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
                gsudo Add-MpPreference -ExclusionPath "$script:MycelioUserProfile\scoop"
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

    Write-Host "::endgroup::"
}

function New-TerminatingErrorRecord {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSUseShouldProcessForStateChangingFunctions', '', Scope = 'Function')]
    param(
        [string] $exception,
        [string] $exceptionMessage,
        [system.management.automation.errorcategory] $errorCategory,
        [string] $targetObject
    )

    $e = New-Object $exception $exceptionMessage
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $e, $errorId, $errorCategory, $targetObject
    return $errorRecord
}

function Test-Compatibility() {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute(
        'PSAvoidUsingWMICmdlet', '', Scope = 'Function')]
    param()

    $returnValue = $true

    $BuildVersion = [System.Environment]::OSVersion.Version

    if ($BuildVersion.Major -ge '10') {
        Write-Warning 'WMF 5.1 is not supported for Windows 10 and above.'
        $returnValue = $false
    }

    ## OS is below Windows Vista
    if ($BuildVersion.Major -lt '6') {
        Write-Warning "WMF 5.1 is not supported on BuildVersion: {0}" -f $BuildVersion.ToString()
        $returnValue = $false
    }

    ## OS is Windows Vista
    if ($BuildVersion.Major -eq '6' -and $BuildVersion.Minor -le '0') {
        Write-Warning "WMF 5.1 is not supported on BuildVersion: {0}" -f $BuildVersion.ToString()
        $returnValue = $false
    }

    ## Check if WMF 3 is installed
    $wmf3 = Get-WmiObject -Query "select * from Win32_QuickFixEngineering where HotFixID = 'KB2506143'"

    if ($wmf3) {
        Write-Warning "WMF 5.1 is not supported when WMF 3.0 is installed."
        $returnValue = $false
    }

    # Check if .Net 4.5 or above is installed

    $release = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\' -Name Release -ErrorAction SilentlyContinue -ErrorVariable evRelease).release
    $installed = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\' -Name Install -ErrorAction SilentlyContinue -ErrorVariable evInstalled).install

    if ($evRelease -or $evInstalled) {
        Write-Warning "WMF 5.1 requires .Net 4.5."
        $returnValue = $false
    }
    elseif (($installed -ne 1) -or ($release -lt 378389)) {
        Write-Warning "WMF 5.1 requires .Net 4.5."
        $returnValue = $false
    }

    return $returnValue
}

<#
Install-WMF5.1.ps1
.VERSION 1.0
.GUID bae78b34-2bd5-42ce-9577-ec348b598570
.AUTHOR Microsoft Corporation
.COMPANYNAME Microsoft Corporation
.DESCRIPTION
 Test the compatibility of current system with WMF 5.1 and install the package if requirements are met.
#>
Function Install-PowerShell {
    param(
        [bool] $AcceptEULA = $false,
        [bool] $AllowRestart = $true
    )

    if ($host.Version.Major -ge 5) {
        Write-Host "Skipped PowerShell install as v5 is already available."
    }
    else {
        $windowsUpdateFilename = "Win7AndW2K8R2-KB3191566-x64.zip"
        $url = "https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/$windowsUpdateFilename"
        $path = Join-Path $script:MycelioArchivesDir $windowsUpdateFilename
        Get-File -Filename $path -Url $url

        $powerShellInstallers = Join-Path $script:MycelioTempDir "powershell_KB3191566"
        Expand-File -Path $path $powerShellInstallers
        $ErrorActionPreference = 'Stop'

        if ($PSBoundParameters.ContainsKey('AllowRestart') -and (-not $PSBoundParameters.ContainsKey('AcceptEULA'))) {
            $errorParameters = @{
                exception        = 'System.Management.Automation.ParameterBindingException';
                exceptionMessage = "AcceptEULA must be specified when AllowRestart is used.";
                errorCategory    = [System.Management.Automation.ErrorCategory]::InvalidArgument;
                targetObject     = ""
            }

            $PSCmdlet.ThrowTerminatingError((New-TerminatingErrorRecord @errorParameters))
        }

        if ($env:PROCESSOR_ARCHITECTURE -eq 'x86') {
            $packageName = 'Win7-KB3191566-x86.msu'
        }
        else {
            $packageName = 'Win7AndW2K8R2-KB3191566-x64.msu'
        }

        $packagePath = Resolve-Path (Join-Path $powerShellInstallers $packageName)

        if ($packagePath -and (Test-Path $packagePath)) {
            if (Test-Compatibility) {
                $wusaExe = "$env:windir\system32\wusa.exe"
                $wusaParameters = @("`"{0}`"" -f $packagePath)

                ##We assume that AcceptEULA is also specified
                if ($AllowRestart) {
                    $wusaParameters += @("/passive")
                }
                ## Here AllowRestart is not specified but AcceptEULA is.
                elseif ($AcceptEULA) {
                    $wusaParameters += @("/quiet", "/promptrestart")
                }

                $wusaParameterString = $wusaParameters -join " "
                Write-Host "Initiating install of PowerShell 5 with Windows Update. This will prompt you to restart the machine."
                Write-Host "##[cmd] $wusaExe $wusaParameterString"
                & $wusaExe $wusaParameterString
            }
            else {
                $errorParameters = @{
                    exception        = 'System.InvalidOperationException';
                    exceptionMessage = "WMF 5.1 cannot be installed as pre-requisites are not met. See Install and Configure WMF 5.1 documentation: https://go.microsoft.com/fwlink/?linkid=839022";
                    errorCategory    = [System.Management.Automation.ErrorCategory]::InvalidOperation;
                    targetObject     = $packagePath
                }

                $PSCmdlet.ThrowTerminatingError((New-TerminatingErrorRecord @errorParameters))
            }
        }
        else {
            $errorParameters = @{
                exception        = 'System.IO.FileNotFoundException';
                exceptionMessage = "Expected WMF 5.1 Package: `"$packageName`" was not found.";
                errorCategory    = [System.Management.Automation.ErrorCategory]::ResourceUnavailable;
                targetObject     = $packagePath
            }

            $PSCmdlet.ThrowTerminatingError((New-TerminatingErrorRecord @errorParameters))
        }
    }
}

Function Initialize-Environment {
    Param(
        [Parameter(Position = 0, mandatory = $true)]
        [string]$ScriptPath
    )

    if ($null -eq $ScriptPath) {
        $ScriptPath = $PSScriptRoot

        if ($null -eq $ScriptPath) {
            $ScriptPath = $pwd
        }
    }
    else {
        $script:ScriptDir = Split-Path $ScriptPath -Parent
    }

    if ([enum]::GetNames([Net.SecurityProtocolType]) -match 'Tls12') {
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }
    else {
        # If you use PowerShell with .Net Framework 2.0 and you want to use TLS1.2, you have
        # to set the value 3072 for the [System.Net.ServicePointManager]::SecurityProtocol
        # property which internally is Tls12.
        [Net.ServicePointManager]::SecurityProtocol = [Enum]::ToObject(
            [System.Net.SecurityProtocolType], 3072);
    }
    Write-Host "PowerShell v$($host.Version)"

    $script:MycelioRoot = Resolve-Path -Path "$script:ScriptDir\..\..\"

    $script:MycelioUserProfile = "$env:UserProfile"
    if ([String]::IsNullOrEmpty("$script:MycelioUserProfile")) {
        $script:MycelioUserProfile = "$env:HOME"
    }

    $script:MycelioTempDir = "$script:MycelioUserProfile\.tmp"
    if ( -not(Test-Path -Path "$script:MycelioTempDir") ) {
        New-Item -ItemType directory -Path "$script:MycelioTempDir" | Out-Null
    }

    $script:MycelioArchivesDir = "$script:MycelioTempDir\archives"
    if ( -not(Test-Path -Path "$script:MycelioArchivesDir") ) {
        New-Item -ItemType directory -Path "$script:MycelioArchivesDir" | Out-Null
    }

    $script:MycelioArtifactsDir = "$script:MycelioRoot\artifacts"
    if ( -not(Test-Path -Path "$script:MycelioArtifactsDir") ) {
        New-Item -ItemType directory -Path "$script:MycelioArtifactsDir" | Out-Null
    }

    $script:MycelioLocalDir = "$script:MycelioUserProfile\.local"
    if ( -not(Test-Path -Path "$script:MycelioLocalDir") ) {
        New-Item -ItemType directory -Path "$script:MycelioLocalDir" | Out-Null
    }

    AddSymbolicLinkPermissions([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

    if (Test-SymbolicLink) {
        Write-Host "System supports creating symbolic links."
    }
    else {
        Write-Host "WARNING: System does not support creating symbolic links."
    }

    # We use our own Git install instead of scoop as sometimes scoop shims stop working and they
    # are generally slower. We care a lot about the performance of Git since it is used everywhere
    # including the prompt.
    Install-Git

    Write-WindowsSandboxTemplate

    Install-MSYS2
    Install-PowerShell

    try {
        $mutagen = "$script:MycelioUserProfile\.local\mutagen\mutagen.exe"
        $rclone = "$script:MycelioUserProfile\scoop\apps\rclone\current\rclone.exe"

        # Useful tool for syncing folders (like rsync) which is sometimes necessary with
        # environments like MSYS which do not work in containerized spaces that mount local
        # volumes as you can get 'Too many levels of symbolic links'
        if (("$Env:Username" -eq "WDAGUtilityAccount") -and (Test-Path -Path "C:\Workspace")) {
            if (Test-Path -Path "$mutagen" -PathType Leaf) {
                & "$mutagen" terminate "dotfiles"
                & "$mutagen" sync create "C:\Workspace\" "$script:MycelioUserProfile\dotfiles" --name "dotfiles" --sync-mode "two-way-resolved" --symlink-mode "portable" --ignore-vcs --ignore "fzf_key_bindings.fish" --ignore "clink_history*" --ignore "_Inline/" --ignore "_build/"
                & "$mutagen" sync flush --all
            }
            else {
                Write-Host "⚠ Missing 'mutagen' tool."

                if (Test-Path -Path "$rclone" -PathType Leaf) {
                    if (("$Env:Username" -eq "WDAGUtilityAccount") -and (Test-Path -Path "C:\Workspace")) {
                        & "$rclone" sync "C:\Workspace" "$script:MycelioUserProfile\dotfiles" --copy-links --exclude ".git/" --exclude "fzf_key_bindings.fish" --exclude "clink_history*"
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

    Initialize-ConsoleFont

    Install-Scoop
    Install-Toolset

    Write-Host "Initialized Mycelio environment for Windows."
}

Initialize-Environment $MyInvocation.MyCommand.Path
