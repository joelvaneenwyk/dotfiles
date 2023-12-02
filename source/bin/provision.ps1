#!/usr/bin/env pwsh
#Requires -Version 5
<#
.NOTES
    ===========================================================================
    Created on:   September 2021
    Created by:   Joel Van Eenwyk
    Filename:     Provision.ps1
    URL:          https://gist.github.com/joelvaneenwyk/83d48a63cc1c25fd62fb18a5ba49ff9d
    ===========================================================================

.EXAMPLE


`Set-ExecutionPolicy RemoteSigned -scope CurrentUser; iwr -useb git.io/mycelio.ps1 | iex`
`Set-ExecutionPolicy RemoteSigned -scope CurrentUser; iwr -useb https://gist.github.com/joelvaneenwyk/83d48a63cc1c25fd62fb18a5ba49ff9d/raw/6c42aad839c8bdf0ef8a1a9a5fcb9f21a4a933c7/mycelio.ps1 | iex`  # DevSkim: ignore DS1004456,DS113853,DS104456

.DESCRIPTION
    Provision the environment with basic set of tools and utilities for common use
    including 'git', 'perl', 'sudo', 'micro', etc. These are mostly installed with
    the 'scoop' package manager.

    Use the following to update the short URL:

        - curl -i https://git.io -F "url=https://gist.githubusercontent.com/joelvaneenwyk/83d48a63cc1c25fd62fb18a5ba49ff9d/raw" -F "code=mycelio.ps1"
#>

using namespace System.Net.Http

Function Initialize-PowerShell {
    Write-Host "PowerShell v$($host.Version)"

    $tempFolder = "$HOME/.tmp"

    if ( -not(Test-Path -Path "$tempFolder") ) {
        New-Item -ItemType directory -Path "$tempFolder" | Out-Null
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12  # DevSkim: ignore DS440020,DS440000

    #
    # Import specific version of package management to avoid import errors, see https://stackoverflow.com/a/63235779
    #
    # Error it is attempting to mitigate: "The term 'PackageManagement\Get-PackageSource' is not recognized as the name
    # of a cmdlet, function, script file, or operable program."
    #
    Write-Host 'Importing package management module and validating NuGet package provider.'
    Import-Module PackageManagement -ErrorAction SilentlyContinue >$null
    if (-not $?) {
        Install-Module -Name PackageManagement -Scope CurrentUser -Force -AllowClobber -ErrorAction SilentlyContinue >$null
        Write-Host "✔ Installed 'PackageManagement' module."
    }

    Import-Module PackageManagement -ErrorAction SilentlyContinue >$null
    if ($?) {
        Write-Host "✔ Imported 'PackageManagement' module."

        Install-PackageProvider -Name NuGet -RequiredVersion 2.8.5.201 -Force -ErrorAction SilentlyContinue >$null
        if ($?) {
            Write-Host "✔ Installed 'NuGet' package provider."
        }
        else {
            Write-Host "❌ Failed to install 'NuGet' package source. $NugetPackage"
        }
    }
    else {
        Write-Host '❌ Failed to import PowerShell package management.', $_.Exception.Message
    }

    Import-Module PowerShellGet -ErrorAction SilentlyContinue >$null
    if ($?) {
        Write-Host '✔ PowerShellGet module already installed.'
    }
    else {
        # We do not check if module is installed because 'Get-Package' may not exist yet.
        Install-Module -Name PowerShellGet -Scope CurrentUser -Force -AllowClobber -ErrorAction SilentlyContinue >$null
        if ($?) {
            Write-Host "Installed 'PowerShellGet' module."

            Update-Module -Name PowerShellGet -Force -ErrorAction SilentlyContinue >$null
            Write-Host "Updated 'PowerShellGet' module to latest version."
        }
        else {
            Write-Host "Failed to install and update 'PowerShellGet' module."
        }

        Import-Module PowerShellGet -ErrorAction SilentlyContinue >$null
        if (-not $?) {
            Write-Host "Failed to import required 'PowerShellGet' module. Exiting initialization."
            return 1
        }
    }

    # Set Microsoft PowerShell Gallery to 'Trusted' as this is needed for packages
    # like 'WindowsConsoleFonts' and 'PSReadLine' installed below.
    try {
        $psGallery = Get-PSRepository -Name '*PSGallery*' -ErrorAction SilentlyContinue
        if ($null -eq $psGallery) {
            if ($host.Version.Major -ge 5) {
                Register-PSRepository -Default -InstallationPolicy Trusted
            }
            else {
                Register-PSRepository -Name PSGallery -SourceLocation 'https://www.powershellgallery.com/api/v2/' -InstallationPolicy Trusted
            }
            Write-Host "✔ Registered 'PSGallery' repository."
        }
        else {
            Write-Host "✔ Already registered 'PSGallery' repository."
        }
    }
    catch [Exception] {
        Write-Host '❌ Failed to add repository.', $_.Exception.Message
    }

    try {
        if ($null -eq (Get-InstalledModule -Name 'WindowsConsoleFonts' -ErrorAction SilentlyContinue)) {
            Install-Module -Name WindowsConsoleFonts -Scope CurrentUser -Force -ErrorAction SilentlyContinue >$null
            if ($?) {
                Write-Host "✔ Installed 'WindowsConsoleFonts' module."
            }
        }
        else {
            Write-Host "✔ 'WindowsConsoleFonts' module already installed."
        }
    }
    catch [Exception] {
        Write-Host "❌ Failed to install 'WindowsConsoleFonts' module.", $_.Exception.Message
    }

    Write-Host '✔ Initialized PowerShell environment.'
}

<#
.SYNOPSIS
    Returns true if the given command can be executed from the shell.
.INPUTS
    Command name which does not need to be a full path.
.OUTPUTS
    Whether or not the command exists and can be executed.
#>
Function Test-IsValidCommand {
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
        $FilePath = Join-Path (Get-Item -Path '.\' -Verbose).FullName $Filename
    }


    $handler = $null
    try {
        $handler = New-Object -TypeName System.Net.Http.HttpClientHandler
    }
    catch {
        Write-Host 'HttpClientHandler not available, using Invoke-WebRequest instead.'
    }

    if ($null -ne ($Url -as [System.URI]).AbsoluteURI) {
        Write-Host "Downloading file: $Url"

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

                    Write-Host 'Download started...'
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
        throw "Failed to download file: $Url"
    }
}

Function Initialize-Environment {
    try {

        $fontBaseName = 'JetBrains Mono'
        $fontBaseFilename = $fontBaseName -replace '\s', ''

        $fontUrl = "https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/$fontBaseFilename.zip"
        $fontNameOriginal = "$fontBaseName Regular Nerd Font Complete Windows Compatible"
        $fontName = "$fontBaseFilename NF"
        $tempFolder = "$HOME/.tmp"
        $tempFontFolder = "$tempFolder/fonts"
        $targetTempFontPath = "$tempFontFolder/$fontName.ttf"

        # We save it to system directory with same path it's the name that needs to be short
        if (Test-Path -Path 'C:/Windows/Fonts') {
            $targetFontPath = "C:/Windows/Fonts/$fontNameOriginal.ttf"
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
            Write-Host 'Failed to remove old font.', $_.Exception.Message
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

                Write-Host "Downloaded font: '$tempFontFolder/$fontNameOriginal.ttf'"
                Write-Host "Renamed font: '$targetTempFontPath'"

                Copy-Item -Path "$tempFontFolder/$fontNameOriginal.ttf" -Destination "$targetTempFontPath"
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
            Write-Host 'Failed to download and install font.', $_.Exception.Message
        }

        # Need to set this for console
        $key = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont'
        try {
            Set-ItemProperty -Path $key -Name '000' -Value "$fontName" -ErrorAction SilentlyContinue
        }
        catch {
            Write-Host 'Failed to update font registry. Requires administrator access.'
        }

        try {
            Import-Module WindowsConsoleFonts -ErrorAction SilentlyContinue >$null
            if ($?) {
                Set-ConsoleFont "$fontName" | Out-Null
                Write-Host "Updated current console font: '$fontName'"
            }
        }
        catch [Exception] {
            Write-Host 'Failed to install WindowsConsoleFonts.', $_.Exception.Message
        }
    }
    catch {
        Write-Host 'Failed to initialize terminal.'
    }

    try {
        if (!(Test-Path Variable:\IsWindows) -or $IsWindows) {
            if (-not(Test-IsValidCommand 'scoop')) {
                Write-Host "Installing 'scoop' package manager..."
                Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')  # DevSkim: ignore DS104456,DS440020
            }

            try {
                $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
                if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
                    # Add SSH client, see https://stackoverflow.com/a/58029292
                    Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

                    # Windows Defender may slow down or disrupt installs with realtime scanning.
                    Import-Module Defender
                    sudo Add-MpPreference -ExclusionPath "C:/Users/$env:USERNAME/scoop"
                    sudo Add-MpPreference -ExclusionPath 'C:/ProgramData/scoop'
                }
            }
            catch {
                Write-Host 'WARNING: Failed to set administrator settings.'
            }

            try {
                # Make sure git is installed first as scoop uses git to update itself
                if (-not(Test-IsValidCommand 'git')) {
                    scoop install 'git'
                }

                Write-Host "Verified that dependencies were installed with 'scoop' package manager."

                if (Test-Path -Path "$HOME/dotfiles/.git") {
                    git -C "$HOME/dotfiles" pull
                }
                else {
                    git -C "$HOME" -c core.symlinks=true clone --recursive 'https://github.com/joelvaneenwyk/dotfiles.git'
                }
            }
            catch {
                Write-Host "Failed to install packages with 'scoop' manager."
            }
        }

        if (!(Test-Path Variable:\IsWindows) -or $IsWindows) {
            Start-Process -Wait -NoNewWindow 'cmd.exe' -ArgumentList @('/d', '/c', "$HOME\dotfiles\setup.bat")
        }
        else {
            Start-Process -Wait -NoNewWindow 'bash' -ArgumentList @('-c', "$HOME/dotfiles/setup.sh")
        }
    }
    catch [Exception] {
        Write-Host 'Exception caught while initializing environment.', $_.Exception.Message
    }
}

try {
    if ($null -eq $HOME) {
        Remove-Variable -Name "HOME" -Force
        Set-Variable HOME "$Env:UserProfile"
    }

    $old_erroractionpreference = $erroractionpreference

    # Quit if anything goes wrong
    $erroractionpreference = 'stop'

    if (($PSVersionTable.PSVersion.Major) -lt 5) {
        Write-Output 'PowerShell 5 or later is required to run Mycelio setup.'
        Write-Output 'Upgrade PowerShell: https://docs.microsoft.com/en-us/powershell/scripting/setup/installing-windows-powershell'
        break
    }

    # show notification to change execution policy:
    $allowedExecutionPolicy = @('Unrestricted', 'RemoteSigned', 'ByPass')
    if ((Get-ExecutionPolicy).ToString() -notin $allowedExecutionPolicy) {
        Write-Output "PowerShell requires an execution policy in [$($allowedExecutionPolicy -join ', ')] to run Scoop."
        Write-Output "For example, to set the execution policy to 'RemoteSigned' please run :"
        Write-Output "'Set-ExecutionPolicy RemoteSigned -scope CurrentUser'"  # DevSkim: ignore DS113853
        break
    }

    if ([System.Enum]::GetNames([System.Net.SecurityProtocolType]) -notcontains 'Tls12') {  # DevSkim: ignore DS440020,DS440000
        Write-Output "Scoop requires at least .NET Framework 4.5"
        Write-Output "Please download and install it first:"
        Write-Output "https://www.microsoft.com/net/download"
        break
    }

    $PSDefaultParameterValues['Out-File:Encoding'] = 'utf8'

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12  # DevSkim: ignore DS440020,DS440000

    Initialize-PowerShell
    Initialize-Environment
}
finally {
    # Reset $erroractionpreference to original value
    $erroractionpreference = $old_erroractionpreference

    Write-Host "Initialized Mycelio standalone provisioning environment."
}
