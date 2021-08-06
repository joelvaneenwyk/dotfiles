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
        Write-Host "$command does not exist"
    }
    Finally {
        $ErrorActionPreference = $oldPreference
    }

    return $IsValid
} #end function test-CommandExists

Function Initialize-Environment {
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

    try {
        if (-not(Test-CommandExists "scoop")) {
            Write-Host "Initializing 'scoop' package manager..."
            Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
        }
    }
    catch {
        Write-Host "Exception caught while installing `scoop` package manager."
    }
    finally {
        try {
            if (-not(Test-CommandExists "sudo")) {
                scoop install "sudo"
            }

            if (-not(Test-CommandExists "nuget")) {
                scoop install "nuget"
            }
        }
        catch {
            Write-Host "Failed to install packages with 'scoop' manager."
        }

        $tempFolder = "$PSScriptRoot\.tmp"
        if ( -not(Test-Path -Path "$tempFolder") ) {
            New-Item -ItemType directory -Path "$tempFolder" | Out-Null
        }

        try {
            $tempTexTargetFolder = "$tempFolder\texlive-install"
            if ( -not(Test-Path -Path "$tempTexTargetFolder\install-tl-windows.bat" -PathType Leaf) ) {
                $tempTexFolder = "$tempFolder\texlive-tmp"
                $tempTexArchive = "$tempFolder\install-tl.zip"

                if ( -not(Test-Path -Path "$tempTexArchive" -PathType Leaf) ) {
                    $url = 'https://mirror.ctan.org/systems/texlive/tlnet/install-tl.zip'
                    Start-BitsTransfer -Source $url -Destination $tempTexArchive
                }

                # Remove tex folder if it exists
                If (Test-Path "$tempTexFolder" -PathType Any) {
                    Remove-Item -Recurse -Force "$tempTexFolder" | Out-Null
                }
                Expand-Archive "$tempTexArchive" -DestinationPath "$tempTexFolder" -Force

                $tempTexVersionFolder = Get-ChildItem -Path "$tempTexFolder" -Force -Directory | Select-Object -First 1
                Move-Item -Path "$tempTexVersionFolder" -Destination "$tempFolder\texlive"

                Remove-Item -Recurse -Force "$tempTexFolder" | Out-Null
                Remove-Item -Recurse -Force "$tempTexArchive" | Out-Null
            }
        }
        catch [Exception] {
            Write-Host "Failed to download and extra TeX Live.", $_.Exception.Message
        }

        # https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/install.ps1
        try {
            $fontNameOriginal = "Caskaydia Cove Nerd Font Complete Windows Compatible"
            $fontName = "CaskaydiaCove NF"
            $tempFontFolder = "$tempFolder\fonts"
            $targetFontPath = "C:\Windows\Fonts\$fontName.ttf"
            $targetTempFontPath = "$tempFontFolder\$fontName.ttf"

            if ( -not(Test-Path -Path "$targetTempFontPath" -PathType Leaf) ) {
                if (Test-Path -Path "$targetTempFontPath" -PathType Any) {
                    Remove-Item -Recurse -Force "$tempFontFolder" | Out-Null
                }

                New-Item -ItemType directory -Path "$tempFontFolder" | Out-Null
                $zipFile = "$tempFontFolder\font.zip"
                $zipDir = "$tempFontFolder"

                # Download the font
                $url = 'https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/CascadiaCode.zip'
                Start-BitsTransfer -Source $url -Destination $zipFile
                Expand-Archive "$zipFile" -DestinationPath "$zipDir" -Force
                Remove-Item -Recurse -Force "$zipFile" | Out-Null

                Rename-Item -Path "$tempFontFolder\$fontNameOriginal.ttf" -NewName "$targetTempFontPath"
            }

            # Remove the existing font first
            If (Test-Path "$targetFontPath" -PathType Any) {
                Remove-Item "$targetFontPath" -Recurse -Force
            }

            # Must use Namespace part or will not install properly
            $FontsFolder = (New-Object -ComObject Shell.Application).Namespace(0x14)
            If (-not(Test-Path "$targetFontPath" -PathType Container)) {
                # Following action performs the install, requires user to click on yes
                $FontsFolder.CopyHere("$targetFontPath", 16)
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

        # Set Microsoft PowerShell Gallery to 'Trusted'
        try {
            $repo = Get-PSRepository -Name "PSGallery" -ErrorAction Ignore;
            if ($null -eq $repo) {
                Write-Host "Adding 'PSGallery' repository..."
                Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
            }
        }
        catch [Exception] {
            Write-Host "Failed to add repository.", $_.Exception.Message
        }

        try {
            if (-not(Get-Module -ListAvailable -Name "Terminal-Icons")) {
                Write-Host "Installing 'Terminal-Icons' module..."
                Install-Module Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck -Repository PSGallery
            }
        }
        catch [Exception] {
            Write-Host "Failed to install Terminal-Icons.", $_.Exception.Message
        }

        try {
            if (-not(Get-Module -ListAvailable -Name "WindowsConsoleFonts")) {
                Write-Host "Installing 'WindowsConsoleFonts' module..."
                Install-Module WindowsConsoleFonts -Scope CurrentUser -Force -SkipPublisherCheck
            }
        }
        catch [Exception] {
            Write-Host "Failed to install WindowsConsoleFonts.", $_.Exception.Message
        }

        try {
            Import-Module WindowsConsoleFonts
            Set-ConsoleFont "$fontName" | Out-Null

            # After the above are setup, can add this to Profile to always loads
            Import-Module Terminal-Icons
            Set-TerminalIconsTheme -ColorTheme DevBlackOps -IconTheme DevBlackOps

            Write-Host "Updated terminal icons and font."
        }
        catch [Exception] {
            Write-Host "Failed to update console to '$fontName' font.", $_.Exception.Message
        }

        try {
            if (-not(Get-Module -ListAvailable -Name "PSDotFiles")) {
                Write-Host "Installing 'PSDotFiles' module..."
                Install-Module -Name PSDotFiles -Scope CurrentUser -Force -SkipPublisherCheck
            }

            Install-DotFiles -Path "$PSScriptRoot" | Out-Null
            Write-Host "Installed 'DotFiles' from: '$PSScriptRoot'"
        }
        catch [Exception] {
            Write-Host "Failed to install 'PSDotFiles' module.", $_.Exception.Message
        }

        try {
            if (-not(Get-Module -ListAvailable -Name "posh-git")) {
                Write-Host "Installing 'posh-git' module..."
                Install-Module posh-git -Scope CurrentUser -Force -SkipPublisherCheck
            }
        }
        catch [Exception] {
            Write-Host "Failed to install 'posh-git' module.", $_.Exception.Message
        }

        try {
            if (-not(Get-Module -ListAvailable -Name "oh-my-posh")) {
                Write-Host "Installing 'oh-my-posh' module..."
                Install-Module oh-my-posh -Scope CurrentUser -Force -SkipPublisherCheck
                Get-PoshThemes
            }
        }
        catch [Exception] {
            Write-Host "Failed to install 'oh-my-posh' module.", $_.Exception.Message
        }

        try {
            if (-not(Get-Module -ListAvailable -Name "PSReadLine")) {
                Write-Host "Installing 'PSReadLine' module..."
                Install-Module -Name PSReadLine -Scope CurrentUser -Force -SkipPublisherCheck
            }
        }
        catch {
            Write-Host "Failed to install 'PSReadLine' module.", $_.Exception.Message
        }

        Write-Host "Initialized PowerShell environment."
    }
}

Initialize-Environment
