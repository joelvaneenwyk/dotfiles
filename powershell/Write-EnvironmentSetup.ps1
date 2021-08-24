
Function Get-EnvironmentPathFolders {
    #.Synopsis Split $env:Path into an array
    #.Notes
    #  - Handle
    #       1) Folders ending in a backslash
    #       2) Double-quoted folders
    #       3) Folders with semicolons
    #       4) Folders with spaces
    #       5) Double-semicolons I.e. blanks
    #  - Example path:
    #       - 'C:WINDOWS;"C:Path with semicolon; in the middle";"E:Path with semicolon at the end;";;C:Program Files;'
    #  - 2018/01/30 by Chad.Simmons@CatapultSystems.com - Created
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
$environmentVariables += "C:\Program Files (x86)\GnuPG\bin"
$environmentVariables += "$root"
$environmentVariables += "$root\windows"
$environmentVariables += "$root\.tmp"
$environmentVariables += "$ENV:UserProfile\scoop\apps\perl\current\perl\bin"
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
    $scriptFilename = "$root\.tmp\setupEnvironment.bat"

    $fileStream = [System.IO.File]::CreateText($scriptFilename)

    try {
        $fileStream.WriteLine("@echo off")
        $fileStream.WriteLine("")
        $fileStream.WriteLine("set ""PATH=$($environmentPaths -join ";")""")
        $fileStream.WriteLine("set ""MYCELIO_ROOT=$root""")
        $fileStream.WriteLine("echo Initialized path from generated script.")
        $fileStream.WriteLine("")
        $fileStream.WriteLine("exit /b 0")
    }
    catch {
        Write-Host "Failed to write setup script: '$scriptFilename'"
    }
    finally {
        $fileStream.Close()
        $fileStream.Dispose()
    }
}
Catch {
    Write-Host "Failed to write environent setup script."
}
