<#
.NOTES
    ===========================================================================
    Created on:   August 2021
    Created by:   Joel Van Eenwyk
    Filename:     Initialize-PowerShell.ps1
    ===========================================================================

.DESCRIPTION
    Provision the PowerShell environment with modules needed for us to be able
    to initialize the rest of the environment with 'Initialize-Environment.ps1' script.

.NOTES
    We intentionally hide a lot of error output while installing PowerShell modules
    because depending on the version of PowerShell and current state of the environment
    you can easily get false warnings/errors. See any of the following for more details
    on existing or past issues:

        - https://github.com/PowerShell/PowerShell/issues/12777
        - https://stackoverflow.com/q/66305351
        - https://stackoverflow.com/a/67531193
        - https://github.com/PowerShell/PowerShellGetv2/issues/599
        - https://docs.microsoft.com/en-us/powershell/scripting/gallery/installing-psget
        - https://github.com/OneGet/oneget/issues/344
        - https://office365itpros.com/2020/05/04/onedrive-known-folders-powershell-module-installations/
#>

Function Initialize-PowerShell {
    Write-Host "PowerShell v$($host.Version)"

    $tempFolder = "$ENV:UserProfile\.tmp"

    if ( -not(Test-Path -Path "$tempFolder") ) {
        New-Item -ItemType directory -Path "$tempFolder" | Out-Null
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    try {
        Import-Module PowerShellGet
        Write-Host "✔ PowerShellGet module already installed."
    }
    catch {
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
    }

    try {
        #
        # Import specific version of package management to avoid import errors, see https://stackoverflow.com/a/63235779
        #
        # Error it is attempting to mitigate: "The term 'PackageManagement\Get-PackageSource' is not recognized as the name
        # of a cmdlet, function, script file, or operable program."
        #
        Import-Module PackageManagement

        # Now install the NuGet package provider if possible.
        $nuget = Get-PackageProvider -Name NuGet
        if ($null -eq $nuget) {
            Install-PackageProvider -Name NuGet -RequiredVersion 2.8.5.201 -Force -ErrorAction SilentlyContinue >$null
            if ($?) {
                Write-Host "✔ Installed 'NuGet' package provider."
            }
            else {
                Write-Host "❌ Failed to install 'NuGet' package source. $NugetPackage"
            }
        }
        else {
            Write-Host "✔ 'NuGet' package provider already installed."
        }

    }
    catch [Exception] {
        Write-Host "❌ Failed to import PowerShell package management.", $_.Exception.Message
    }

    # Set Microsoft PowerShell Gallery to 'Trusted' as this is needed for packages
    # like 'WindowsConsoleFonts' and 'PSReadLine' installed below.
    try {
        $psGallery = Get-PSRepository -Name "*PSGallery*"
        if ($null -eq $psGallery) {
            if ($host.Version.Major -ge 5) {
                Register-PSRepository -Default -InstallationPolicy Trusted
            }
            else {
                Register-PSRepository -Name PSGallery -SourceLocation "https://www.powershellgallery.com/api/v2/" -InstallationPolicy Trusted
            }
            Write-Host "✔ Registered 'PSGallery' repository."
        }
        else {
            Write-Host "✔ Already registered 'PSGallery' repository."
        }
    }
    catch [Exception] {
        Write-Host "❌ Failed to add repository.", $_.Exception.Message
    }

    try {
        if ($null -eq (Get-InstalledModule -Name "WindowsConsoleFonts" -ErrorAction SilentlyContinue)) {
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

    try {
        if ($null -eq (Get-InstalledModule -Name "Terminal-Icons" -ErrorAction SilentlyContinue)) {
            Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck -Repository PSGallery
            Write-Host "✔ Installed 'Terminal-Icons' module."
        }
        else {
            Write-Host "✔ 'Terminal-Icons' module already installed."
        }
    }
    catch [Exception] {
        Write-Host "❌ Failed to install 'Terminal-Icons' module.", $_.Exception.Message
    }

    try {
        Import-Module PSReadLine
        Write-Host "✔ 'PSReadLine' module already installed."
    }
    catch {
        try {
            Install-Module -Name PSReadLine -Scope CurrentUser -Force -SkipPublisherCheck >$null
            Write-Host "✔ Installed 'PSReadLine' module."
        }
        catch {
            Write-Host "❌ Failed to install 'PSReadLine' module.", $_.Exception.Message
        }
    }

    # https://ohmyposh.dev/
    try {
        if ($null -eq (Get-InstalledModule -Name "oh-my-posh" -ErrorAction SilentlyContinue)) {
            Install-Module -Name oh-my-posh -Scope CurrentUser -Force -SkipPublisherCheck >$null
            if ($?) {
                Write-Host "✔ Installed 'oh-my-posh' module."
            }
        }
        else {
            Write-Host "✔ 'oh-my-posh' module already installed."
        }
    }
    catch [Exception] {
        Write-Host "❌ Failed to install 'oh-my-posh' module.", $_.Exception.Message
    }

    try {
        if ($null -eq (Get-InstalledModule -Name "posh-git" -ErrorAction SilentlyContinue)) {
            Install-Module -Name posh-git -Scope CurrentUser -Force -SkipPublisherCheck
            if ($?) {
                Write-Host "✔ Installed 'posh-git' module."
            }
            else {
                Write-Host "✔ 'posh-git' module already installed."
            }
        }
    }
    catch [Exception] {
        Write-Host "❌ Failed to install 'posh-git' module.", $_.Exception.Message
    }

    Write-Host "✔ Initialized PowerShell environment."
}

Initialize-PowerShell
