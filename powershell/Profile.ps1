#
# Author: Joel Van Eenwyk
# Installation: Copy to default documents profile for user e.g.
#
#   - C:\Users\jovaneen\Documents\PowerShell\Profile.ps1
#   - C:\Users\jovaneen\OneDrive - Microsoft\Documents\PowerShell\Profile.ps1
#

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
    Set-PoshPrompt -Theme stelbent.minimal
}
catch {
    Write-Host "Failed to setup 'oh-my-posh' prompt."
}

try {
    $fontName = "JetBrainsMono NF"
    Import-Module WindowsConsoleFonts >$null
    Import-Module Terminal-Icons >$null

    $currentFont = Get-ConsoleFont
    if (($null -ne $currentFont) -and ($currentFont.Name -ne $fontName)) {
        Set-ConsoleFont "$fontName" >$null
    }

    Set-TerminalIconsTheme -ColorTheme DevBlackOps -IconTheme DevBlackOps
}
catch [Exception] {
    Write-Host "Failed to set console font and theme.", $_.Exception.Message
}

#
# NOTE: This script is called in each sub-shell as well so reduce noise by not calling anything
# that may write to the console host.
#
