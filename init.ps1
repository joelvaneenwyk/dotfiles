#$global:GitPromptSettings.AnsiConsole = $false
#$global:DotFilesPath = "$PSScriptRoot"

Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

try {
    Write-Host "Initializing 'scoop' package manager..."
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
}
catch {
    Write-Host "Exception caught while installing `scoop` package manager."
}
finally {
    # https://github.com/ryanoasis/nerd-fonts/blob/master/patched-fonts/install.ps1
    try {
        $url = 'https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/CascadiaCode.zip'

        $fontNameOriginal = "Caskaydia Cove Nerd Font Complete Windows Compatible"
        $fontName = "CaskaydiaCove NF"
        $targetFontPath = "C:\Windows\Fonts\$fontName.ttf"
        $targetTempFontPath = "$PSScriptRoot\.tmp\$fontName.ttf"

        if ( -not(Test-Path -Path "$targetTempFontPath" -PathType Leaf) ) {
            Remove-Item -Recurse -Force "$PSScriptRoot\.tmp" | Out-Null
            New-Item -ItemType directory -Path "$PSScriptRoot\.tmp" | Out-Null
            $zipFile = "$PSScriptRoot\.tmp\font.zip"
            $zipDir = "$PSScriptRoot\.tmp"

            # Download the font
            Start-BitsTransfer -Source $url -Destination $zipFile
            Expand-Archive "$zipFile" -DestinationPath "$zipDir" -Force

            Rename-Item -Path "$PSScriptRoot\.tmp\$fontNameOriginal.ttf" -NewName "$targetTempFontPath"
        }

        $Install = $true

        # UnInstall Font
        If (Test-Path "$targetFontPath" -PathType Any) {
            Remove-Item "$targetFontPath" -Recurse -Force
        }

        # Must use Namespace part or will not install properly
        $FontsFolder = (New-Object -ComObject Shell.Application).Namespace(0x14)
        If ((-not(Test-Path "$targetFontPath" -PathType Container)) -and ($Install -eq $true)) {
            # Following action performs the install, requires user to click on yes
            $FontsFolder.CopyHere("$targetFontPath", 16)
        }

        # Need to set this for console
        $key = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Console\TrueTypeFont'
        try {
            Set-ItemProperty -Path $key -Name '000' -Value "$fontName"
        }
        catch {
            Write-Host "Failed to update font registry."
        }

        # Always need this, required for all Modules
        try {
            Install-PackageProvider -Name NuGet -MinimumVersion 5.10.0 -Force
        }
        catch {
            Write-Host "Failed to install NuGet."
        }

        # Set Microsoft PowerShell Gallery to 'Trusted'
        try {
            Write-Host "Installing 'Terminal-Icons' module..."
            Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
            Install-Module Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck
        }
        catch {
            Write-Host "Failed to install Terminal-Icons."
        }

        try {
            Write-Host "Installing 'WindowsConsoleFonts' module..."
            Install-Module WindowsConsoleFonts -Scope CurrentUser -Force -SkipPublisherCheck
        }
        catch {
            Write-Host "Failed to install WindowsConsoleFonts."
        }

        try {
            Import-Module Terminal-Icons
            Set-ConsoleFont "$fontName"

            # After the above are setup, can add this to Profile to always loads
            Set-TerminalIconsTheme -Name DevBlackOps
        }
        catch {
            Write-Host "Failed to update console to '$fontName' font."
        }
    }
    catch [Exception] {
        Write-Host $_.Exception.GetType().FullName, $_.Exception.Message
    }

    try {
        Write-Host "Installing 'PSDotFiles' module..."
        Install-Module -Name PSDotFiles -Scope CurrentUser -Force -SkipPublisherCheck
        Install-DotFiles
    }
    catch {
        Write-Host "Failed to install dotfiles as you need administrator privileges."
    }

    try {
        Write-Host "Installing 'posh-git' module..."
        Install-Module posh-git -Scope CurrentUser -Force -SkipPublisherCheck
    }
    catch {

    }

    try {
        Write-Host "Installing 'oh-my-posh' module..."
        Install-Module oh-my-posh -Scope CurrentUser -Force -SkipPublisherCheck
        Get-PoshThemes
    }
    catch {

    }

    try {
        Write-Host "Installing 'PSReadLine' module..."
        Install-Module -Name PSReadLine -AllowPrerelease -Scope CurrentUser -Force -SkipPublisherCheck
    }
    catch {

    }

    Write-Host "Initialized PowerShell environment."
}
