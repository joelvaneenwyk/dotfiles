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
Function Initialize-PowerShell {
    Write-Host "PowerShell v$($host.Version)"

    $root = Resolve-Path -Path "$PSScriptRoot\.."
    $tempFolder = "$root\.tmp"

    if ( -not(Test-Path -Path "$tempFolder") ) {
        New-Item -ItemType directory -Path "$tempFolder" | Out-Null
    }

    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    try {
        # Now install the NuGet package provider if possible.
        $NugetPackage = Get-PackageProvider -Name "NuGet" -ForceBootstrap >$null
        if ($?) {
            Write-Host "Installed NuGet package provider."
        }
        else {
            Write-Host "Failed to install NuGet package source. $NugetPackage"
        }

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

        Import-Module PowerShellGet

        #
        # Import specific version of package management to avoid import errors, see https://stackoverflow.com/a/63235779
        #
        # Error it is attempting to mitigate: "The term 'PackageManagement\Get-PackageSource' is not recognized as the name
        # of a cmdlet, function, script file, or operable program."
        #
        Import-Module PackageManagement
    }
    catch [Exception] {
        Write-Host "Failed to install NuGet package provider", $_.Exception.Message
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
            Write-Host "Registered 'PSGallery' repository."
        }
        else {
            Write-Host "Already registered 'PSGallery' repository."
        }
    }
    catch [Exception] {
        Write-Host "Failed to add repository.", $_.Exception.Message
    }

    try {
        if ($null -eq (Get-InstalledModule -Name "WindowsConsoleFonts" -ErrorAction SilentlyContinue)) {
            Install-Module -Name WindowsConsoleFonts -Scope CurrentUser -Force -ErrorAction SilentlyContinue >$null
            if ($?) {
                Write-Host "Installed 'WindowsConsoleFonts' module."
            }
        }
    }
    catch [Exception] {
        Write-Host "Failed to install WindowsConsoleFonts.", $_.Exception.Message
    }

    try {
        if ($null -eq (Get-InstalledModule -Name "Terminal-Icons" -ErrorAction SilentlyContinue)) {
            Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck -Repository PSGallery
            Write-Host "Installed 'Terminal-Icons' module."
        }
    }
    catch [Exception] {
        Write-Host "Failed to install 'Terminal-Icons' module.", $_.Exception.Message
    }

    try {
        if ($null -eq (Get-InstalledModule -Name "PSReadLine" -ErrorAction SilentlyContinue)) {
            Install-Module -Name PSReadLine -Scope CurrentUser -ErrorAction SilentlyContinue -Force -SkipPublisherCheck >$null
            if ($?) {
                Write-Host "Installed 'PSReadLine' module."
            }
        }
    }
    catch {
        Write-Host "Failed to install 'PSReadLine' module.", $_.Exception.Message
    }

    # https://ohmyposh.dev/
    try {
        if ($null -eq (Get-InstalledModule -Name "oh-my-posh" -ErrorAction SilentlyContinue)) {
            Install-Module -Name oh-my-posh -Scope CurrentUser -Force -SkipPublisherCheck >$null
            if ($?) {
                Write-Host "Installed 'oh-my-posh' module."
            }
        }
    }
    catch [Exception] {
        Write-Host "Failed to install 'oh-my-posh' module.", $_.Exception.Message
    }

    try {
        if ($null -eq (Get-InstalledModule -Name "posh-git" -ErrorAction SilentlyContinue)) {
            Install-Module -Name posh-git -Scope CurrentUser -Force -SkipPublisherCheck
            if ($?) {
                Write-Host "Installed 'posh-git' module."
            }
        }
    }
    catch [Exception] {
        Write-Host "Failed to install 'posh-git' module.", $_.Exception.Message
    }

    Write-Host "Initialized PowerShell environment."
}

Initialize-PowerShell
