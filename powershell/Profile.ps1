<#
.NOTES
    ===========================================================================
    Created on:   August 2021
    Created by:   Joel Van Eenwyk
    Filename:     Profile.ps1
    ===========================================================================
.DESCRIPTION
    Set the font and theme. This file should have been been linked to the
    following paths:

        - C:\Users\jovaneen\Documents\PowerShell\Profile.ps1
        - C:\Users\jovaneen\OneDrive - Microsoft\Documents\PowerShell\Profile.ps1
#>

Function Get-RealScriptPath() {
    $ScriptPath = $PSCommandPath

    # Attempt to extract link target from script pathname
    $link_target = Get-Item $ScriptPath | Select-Object -ExpandProperty Target

    # If the script is not a link just return the script path as is
    If (-Not($link_target)) {
        return $ScriptPath
    }

    # Check if the path is rooted / absolute. If so return that.
    $is_absolute = [System.IO.Path]::IsPathRooted($link_target)
    if ($is_absolute) {
        return $link_target
    }

    # We now know that the script was launched from a link and the link target is
    # probably relative depending on how accurate IsPathRooted() is. Try to make an
    # absolute path by merging the script directory and the link target and then
    # normalize it through Resolve-Path.
    $joined = Join-Path $PSScriptRoot $link_target
    $resolved = Resolve-Path -Path $joined

    return $resolved
}

Function Get-ScriptDirectory() {
    $ScriptPath = Get-RealScriptPath
    $ScriptDir = Split-Path -Parent $ScriptPath
    return $ScriptDir
}

Function global:init() {
    param(
        [string] $ArgumentList
    )

    $ScriptPath = Get-ScriptDirectory
    $Path = Resolve-Path "$ScriptPath\Invoke-Init.ps1"
    Write-Host "##[cmd] $Path $ArgumentList"
    & $Path $ArgumentList
}

try {
    # WARNING: You appear to have an unsupported Git distribution; setting
    # $GitPromptSettings.AnsiConsole = $false. posh-git recommends Git for Windows.
    #
    # See https://github.com/dahlbyk/posh-git/issues/860
    $Env:POSHGIT_CYGWIN_WARNING = 'off'

    try {
        Import-Module posh-git -ErrorAction SilentlyContinue >$null
    }
    catch {
        Write-Host "Failed to import 'posh-git' module."
    }

    try {
        Import-Module oh-my-posh -ErrorAction SilentlyContinue >$null
        Set-PoshPrompt -ErrorAction SilentlyContinue -Theme stelbent.minimal
    }
    catch {
        Write-Host "Failed to set 'oh-my-posh' prompt."
    }

    try {
        $fontName = "JetBrainsMono NF"
        Import-Module WindowsConsoleFonts -ErrorAction SilentlyContinue >$null
        if ($?) {
            $currentFont = Get-ConsoleFont -ErrorAction SilentlyContinue
            if (($null -ne $currentFont) -and ($currentFont.Name -ne $fontName)) {
                Set-ConsoleFont "$fontName" >$null
                Write-Host "Previous font: '$currentFont.Name'"
                Write-Host "Updated font: '$fontName'"
            }
        }

        Import-Module Terminal-Icons -ErrorAction SilentlyContinue >$null
        if ($?) {
            Set-TerminalIconsTheme -ColorTheme DevBlackOps -ErrorAction SilentlyContinue -IconTheme DevBlackOps
        }
    }
    catch [Exception] {
        Write-Host "Failed to set console font and theme.", $_.Exception.Message
    }
}
catch {
    # Ignore any exceptions
}

#
# NOTE: This script is called in each sub-shell as well so reduce noise by not calling anything
# that may write to the console host.
#
