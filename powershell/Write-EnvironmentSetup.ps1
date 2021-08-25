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

param([string]$ScriptPath = "")

Function Get-EnvironmentPathFolders {
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

$root = Resolve-Path -Path "$PSScriptRoot\.."

$environmentVariables = @()
$environmentVariables += "$root"
$environmentVariables += "$root\windows"
$environmentVariables += "$ENV:UserProfile\.local\bin"
$environmentVariables += "C:\Program Files (x86)\GnuPG\bin"
$environmentVariables += "$ENV:UserProfile\scoop\apps\msys2\current\mingw64"
$environmentVariables += "$ENV:UserProfile\scoop\apps\msys2\current\clang64"
$environmentVariables += "$ENV:UserProfile\scoop\apps\msys2\current\usr\bin"
$environmentVariables += "$ENV:UserProfile\scoop\shims"
$environmentVariables += $(Get-EnvironmentPathFolders)

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
        Write-Host "Skipped invalid path: '$environmentPath'"
    }
}

$environmentPaths = $environmentPaths | Select-Object -Unique

Try {
    New-Item -Path "$ENV:UserProfile\.local\bin" -type directory -ErrorAction SilentlyContinue | Out-Null

    $fileStream = [System.IO.File]::CreateText($ScriptPath)

    try {
        $fileStream.WriteLine("@echo off")
        $fileStream.WriteLine("")
        $fileStream.WriteLine("set ""PATH=$($environmentPaths -join ";")""")
        $fileStream.WriteLine("set ""MYCELIO_ROOT=$root""")
        $fileStream.WriteLine("set ""HOME=$ENV:UserProfile""")
        $fileStream.WriteLine("echo Initialized path from generated script.")
        $fileStream.WriteLine("")
        $fileStream.WriteLine("exit /b 0")
    }
    catch [Exception] {
        Write-Host "Failed to write setup script.", $_.Exception.Message
    }
    finally {
        $fileStream.Close()
        $fileStream.Dispose()
    }
}
catch [Exception] {
    Write-Host "Failed to write environent setup script.", $_.Exception.Message
}
