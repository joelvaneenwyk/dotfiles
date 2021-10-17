<#
.NOTES
    ===========================================================================
    Created on:   August 2021
    Created by:   Joel Van Eenwyk
    Filename:     Initialize-Environment.ps1
    ===========================================================================

.DESCRIPTION
    Provision the environment with basic set of tools and utilities for common use
    including 'git', 'perl', 'gsudo', 'micro', etc. These are mostly installed with
    the 'scoop' package manager.
#>

Function Initialize-Sandbox {
    $mycelioRoot = Resolve-Path -Path "$PSScriptRoot\..\..\"

    $tempFolder = "$ENV:UserProfile\.tmp"
    if ( -not(Test-Path -Path "$tempFolder") ) {
        New-Item -ItemType directory -Path "$tempFolder" | Out-Null
    }

    $mycelioArtifacts = Resolve-Path -Path "$mycelioRoot\artifacts\"
    if ( -not(Test-Path -Path "$mycelioArtifacts") ) {
        New-Item -ItemType directory -Path "$mycelioArtifacts" | Out-Null
    }

    $sandboxTemplate = Get-Content -Path "$mycelioRoot\source\windows\sandbox\sandbox.wsb.template" -Raw
    $sandbox = $sandboxTemplate -replace '\${workspaceFolder}', $mycelioRoot
    Set-Content -Path "$mycelioArtifacts\sandbox.wsb" -Value "$sandbox"
}

Initialize-Sandbox
