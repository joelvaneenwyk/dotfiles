param(
    [string] $ArgumentList
)

$Path = Resolve-Path "$PSScriptRoot\..\init.bat"
Write-Host "##[cmd] $PSScriptRoot\Invoke-CmdScript.ps1 $Path $ArgumentList"

& "$PSScriptRoot\Invoke-CmdScript.ps1" "$Path" $ArgumentList
