<#
.SYNOPSIS
    Create batch script for Mycelio environment.
.DESCRIPTION
    Outputs key value pairs for Windows environment that includes necessary environment
    variables to operate utilities provided by the scripts. It primarily needs to set
    an absolute directory for 'MYCELIO_ROOT' but it also adds some critical directories
    the 'PATH' variable and removes duplicates.
.EXAMPLE
    CMD C:\> pwsh -NoLogo -NoProfile -File "powershell\Write-EnvironmentSetup.ps1" -ScriptPath "setupEnv.bat"
    CMD C:\> call setupEnv.bat

    After running the above, the environment will be setup such that you can now run Mycelio
    specific commands e.g., "gpgtest"
#>
param(
    [string]$ScriptPath = "",
    [switch]$Verbose = $false
)

Function Get-CurrentEnvironment {
    <#
    .SYNOPSIS
        Split $env:Path into an array.
    .DESCRIPTION
        Handles the following stretch cases:

            1) Folders ending in a backslash
            2) Double-quoted folders
            3) Folders with semicolons
            4) Folders with spaces
            5) Double-semicolons I.e. blanks
    .EXAMPLE
        PATH=C:WINDOWS;"C:Path with semicolon; in the middle";"E:Path with semicolon at the end;";;C:Program Files;'

        Will be converted to an array:

            - C:\Windows
            - C:\Path with semicolon; in the middle
            - C:\C:Program Files
    .NOTES
        Originally created on 2018/01/30 by Chad.Simmons@CatapultSystems.com
    #>

    $PathArray = @()
    $PathString = ""

    if ($null -ne $env:Path) {
        $PathString = $env:Path.ToString().TrimEnd(';')
    }

    # Remove a trailing semicolon from the path then split it into an array using a double-quote
    # as the delimiter keeping the delimiter
    $PathString -split '(?=["])' | ForEach-Object {
        If ($_ -eq '";') {
            # throw away a blank line
        }
        ElseIf ($_.ToString().StartsWith('";')) {
            # if line starts with "; remove the "; and any trailing backslash
            $PathArray += ($_.ToString().TrimStart('";')).TrimEnd('')
        }
        ElseIf ($_.ToString().StartsWith('"')) {
            # if line starts with " remove the " and any trailing backslash
            $PathArray += ($_.ToString().TrimStart('"')).TrimEnd('') #$_ + '"'
        }
        Else {
            # split by semicolon and remove any trailing backslash
            $_.ToString().Split(';') | ForEach-Object {
                If ($_.Length -gt 0) {
                    $PathArray += $_.TrimEnd('')
                }
            }
        }
    }

    Return $PathArray
}

Function Initialize-Environment {
    Param(
        [Parameter(Position = 0, mandatory = $true)]
        [string]$ScriptPath
    )

    $script:ScriptDir = Split-Path $ScriptPath -Parent

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
}

Function Get-Environment {
    if ("$Env:Username" -eq "WDAGUtilityAccount") {
        if (Test-Path -Path "$Env:UserProfile\dotfiles\setup.bat" -PathType Leaf) {
            $script:MycelioRoot = Resolve-Path -Path "$Env:UserProfile\dotfiles"
        }
    }

    $environmentVariables = @()

    # We put this here because we want the global install to take precedence even if
    # there is a 'scoop' portable version installed.
    $environmentVariables += "C:\Program Files\Microsoft VS Code\bin"

    $environmentVariables += "$ENV:UserProfile\scoop\shims"

    $environmentVariables += "$script:MycelioRoot"
    $environmentVariables += "$script:MycelioRoot\source\windows\bin"

    $environmentVariables += "$ENV:UserProfile\.local\texlive\bin\win32"
    $environmentVariables += "$ENV:UserProfile\.local\git\mingw64\bin"
    $environmentVariables += "$ENV:UserProfile\.local\bin"
    $environmentVariables += "$ENV:UserProfile\.local\msys64"
    $environmentVariables += "$ENV:UserProfile\.local\mutagen"
    $environmentVariables += "$ENV:UserProfile\.local\go\bin"
    $environmentVariables += "$ENV:UserProfile\.local\perl\c\bin"
    $environmentVariables += "$ENV:UserProfile\.local\perl\perl\bin"

    # Expected to contain 'cpan' and other related utilities
    $environmentVariables += "$ENV:UserProfile\.local\perl\perl\site\bin"

    # If installed, will give you access to 'gpg' and 'gpgconf' as well as 'Kleopatra'
    $environmentVariables += "C:\Program Files (x86)\GnuPG\bin"
    $environmentVariables += "C:\Program Files (x86)\Gpg4win\bin"

    $environmentVariables += "C:\Program Files\Docker"

    # Initially seemed like a good idea to include these tools in the environment, but there are a
    # lot of dependencies between these tools from dynamic libraries to just include folders that
    # end up resulting in a lot of conflict and some tools just "not working" in some cases for
    # seemingly strange reasons with even stranger error messages. It gets worse if you have multiple
    # versions of MSYS2 installed (or Cygwin) and then the installations become overlapped resulting
    # in even more obscure errors.
    $includeUnixTools = $false

    if ($includeUnixTools) {
        # Home to tools like 'gcc' and 'make'
        $environmentVariables += "$ENV:UserProfile\.local\msys64\mingw64\bin"

        # This is intentionally at the very end as we want to pick non-MSYS2 (or Cygwin) style
        # versions if at all possible. This is mainly required for tools like 'make' which are
        # only available in the 'usr/bin' folder.
        $environmentVariables += "$ENV:UserProfile\.local\msys64\usr\bin"
    }

    # This also contains 'bash' and other utilities so put this near the end
    $environmentVariables += "C:\Program Files\Git\bin"

    $environmentVariables += $(Get-CurrentEnvironment)

    # Gather all valid paths into one array which we will output at the end.
    $environmentPaths = @()
    $environmentVariables | ForEach-Object {
        $environmentPath = "$_"
        try {
            $resolvedPath = Resolve-Path -ErrorAction SilentlyContinue -Path "$_"
            if ($null -ne $resolvedPath) {
                $path = $resolvedPath.Path
                $path = $path.TrimEnd("\\")
                $path = $path.TrimEnd("/")
                $environmentPaths += $path
            }
        }
        catch {
            Write-Host "[mycelio] Skipped invalid path: '$environmentPath'"
        }
    }

    return $environmentPaths | Select-Object -Unique
}

Function Save-Environment {
    param(
        [string]$ScriptPath = "",
        [switch]$Verbose = $false
    )

    if ([String]::IsNullOrEmpty("$ScriptPath")) {
        $ScriptPath = "$ENV:UserProfile/.local/bin/use_mycelio_environment.bat"
    }

    $environmentPaths = Get-Environment

    Try {
        New-Item -Path "$ENV:UserProfile/.local/bin" -type directory -ErrorAction SilentlyContinue | Out-Null

        $fileStream = [System.IO.File]::CreateText($ScriptPath)

        try {
            $fileStream.WriteLine("@echo off")
            $fileStream.WriteLine("")

            $fileStream.WriteLine("set ""PATH=$($environmentPaths -join ";")""")
            $fileStream.WriteLine("set ""MYCELIO_ROOT=$script:MycelioRoot""")
            $fileStream.WriteLine("set ""HOME=$ENV:UserProfile""")
            $fileStream.WriteLine("set ""PERL=$ENV:UserProfile\.local\perl\perl\bin\perl.exe""")
            $fileStream.WriteLine("set ""MSYS=winsymlinks:native""")
            $fileStream.WriteLine("set ""MSYS_SHELL=%USERPROFILE%\.local\msys64\msys2_shell.cmd""")
            $fileStream.WriteLine("set ""MSYS2_PATH_TYPE=minimal""")

            # We intentionally do not output anything in this script as we want to be able to
            # run this in subshells if needed which means we can't have the output cluttered.
            if ($Verbose) {
                $fileStream.WriteLine("echo [mycelio] Initialized environment from generated script. Root: '%MYCELIO_ROOT%'")
            }

            $fileStream.WriteLine("")
            $fileStream.WriteLine("exit /b 0")
        }
        catch [Exception] {
            Write-Host "[mycelio] Failed to write setup script.", $_.Exception.Message
        }
        finally {
            $fileStream.Close()
            $fileStream.Dispose()
        }
    }
    catch [Exception] {
        Write-Host "[mycelio] Failed to write environent setup script.", $_.Exception.Message
    }
}

Initialize-Environment $MyInvocation.MyCommand.Path
Save-Environment -ScriptPath "$ScriptPath" -Verbose $Verbose
