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
Function Initialize-Environment {
    Write-Host "PowerShell v$($host.Version)"

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

    $root = Resolve-Path -Path "$PSScriptRoot\.."
    $tempFolder = "$root\.tmp"

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

    try {
        if (-not(Test-CommandExists "scoop")) {
            Write-Host "Initializing 'scoop' package manager..."
            Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
        }

        try {
            scoop update

            if (-not(Test-CommandExists "git")) {
                scoop install "git"
            }

            if (-not(Test-CommandExists "sudo")) {
                scoop install "sudo"
            }

            if (-not(Test-CommandExists "nuget")) {
                scoop install "nuget"
            }

            if (-not(Test-CommandExists "msys2")) {
                scoop install "msys2"
            }

            # https://github.com/chrisant996/clink
            if (-not(Test-CommandExists "clink")) {
                scoop install "clink"
            }

            # https://micro-editor.github.io/
            if (-not(Test-CommandExists "micro")) {
                scoop install "micro"
            }

            if (-not(Test-CommandExists "perl")) {
                scoop install "perl"
            }
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
            if ($null -eq (Get-InstalledModule -Name "WindowsConsoleFonts" -ErrorAction SilentlyContinue)) {
                Install-Module -Name WindowsConsoleFonts -Scope CurrentUser -Force -SkipPublisherCheck
                Write-Host "Installed 'WindowsConsoleFonts' module."
            }

            # This can fail in containers as 'GetCurrentConsoleFont' will fail during build
            # so we just ignore the error here and continue.
            Import-Module WindowsConsoleFonts -ErrorAction SilentlyContinue | Out-Null

            # Try to remove the old font if we can
            if (Test-Path -Path "$targetTempFontPath" -PathType Leaf) {
                Remove-Font "$targetTempFontPath" -ErrorAction SilentlyContinue | Out-Null
            }
        }
        catch [Exception] {
            Write-Host "Failed to install WindowsConsoleFonts.", $_.Exception.Message
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
            if ($null -eq (Get-InstalledModule -Name "Terminal-Icons" -ErrorAction SilentlyContinue)) {
                Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck -Repository PSGallery
                Write-Host "Installed 'Terminal-Icons' module."
            }
        }
        catch [Exception] {
            Write-Host "Failed to install 'Terminal-Icons' module.", $_.Exception.Message
        }

        try {
            Import-Module WindowsConsoleFonts

            # We do NOT want to add the temporary font because it makes it impossible to remove
            # Add-Font "$targetTempFontPath"

            Set-ConsoleFont "$fontName" | Out-Null
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

        try {
            if ($null -eq (Get-InstalledModule -Name "PSReadLine" -ErrorAction SilentlyContinue)) {
                Write-Host "Installing 'PSReadLine' module..."
                Install-Module -Name PSReadLine -Scope CurrentUser -Force -SkipPublisherCheck
            }
        }
        catch {
            Write-Host "Failed to install 'PSReadLine' module.", $_.Exception.Message
        }

        # https://ohmyposh.dev/
        try {
            if ($null -eq (Get-InstalledModule -Name "oh-my-posh" -ErrorAction SilentlyContinue)) {
                Install-Module oh-my-posh -Scope CurrentUser -Force -AllowPrerelease -SkipPublisherCheck >$null
                Write-Host "Installed 'oh-my-posh' module."
            }
        }
        catch [Exception] {
            Write-Host "Failed to install 'oh-my-posh' module.", $_.Exception.Message
        }

        try {
            if ($null -eq (Get-InstalledModule -Name "posh-git" -ErrorAction SilentlyContinue)) {
                Install-Module posh-git -Scope CurrentUser -Force -SkipPublisherCheck
                Write-Host "Installed 'posh-git' module."
            }
        }
        catch [Exception] {
            Write-Host "Failed to install 'posh-git' module.", $_.Exception.Message
        }

        try {
            if ($null -eq (Get-InstalledModule -Name "PSDotFiles" -ErrorAction SilentlyContinue)) {
                Install-Module -Name PSDotFiles -Scope CurrentUser -Force -SkipPublisherCheck
                Write-Host "Installed 'PSDotFiles' module."
            }

            Install-DotFiles -Path "$root" | Out-Null
            Write-Host "Installed 'DotFiles' from: '$root'"
        }
        catch [Exception] {
            Write-Host "Failed to install 'PSDotFiles' module.", $_.Exception.Message
        }

        Write-Host "Initialized PowerShell environment."
    }
}

Initialize-Environment
