param(
    [string] $ArgumentList
)

$Path = Resolve-Path "$PSScriptRoot\..\..\setup.bat"

if (Test-Path -Path $Path -PathType Leaf) {
    Write-Host "##[cmd] $PSScriptRoot\Invoke-CmdScript.ps1 $Path $ArgumentList"
    & "$PSScriptRoot\Invoke-CmdScript.ps1" "$Path" $ArgumentList
}
else {
    Write-Host "Initialization script not found: '$Path'"
}
