#
# Author: Joel Van Eenwyk
# Instalation: Copy to default documents profile for user e.g.
#
#   - C:\Users\jovaneen\Documents\PowerShell\Profile.ps1
#   - C:\Users\jovaneen\OneDrive - Microsoft\Documents\PowerShell\Profile.ps1
#

#
# WARNING: You appear to have an unsupported Git distribution; setting
# $GitPromptSettings.AnsiConsole = $false. posh-git recommends Git for Windows.
#
# See https://github.com/dahlbyk/posh-git/issues/860
$Env:POSHGIT_CYGWIN_WARNING = 'off'

Import-Module posh-git
Import-Module oh-my-posh

Set-PoshPrompt -Theme stelbent.minimal

Write-Host "Initialized global PowerShell profile."
