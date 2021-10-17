##############################################################################
##
## Invoke-CmdScript
##
## From Windows PowerShell Cookbook (O'Reilly)
## by Lee Holmes (http://www.leeholmes.com/guide)
##
##############################################################################

<#

.SYNOPSIS

Invoke the specified batch file (and parameters), but also propigate any
environment variable changes back to the PowerShell environment that
called it.

.EXAMPLE

PS >type foo-that-sets-the-FOO-env-variable.cmd
@set FOO=%*
echo FOO set to %FOO%.

PS >$env:FOO
PS >Invoke-CmdScript "foo-that-sets-the-FOO-env-variable.cmd" Test

C:\Temp>echo FOO set to Test.
FOO set to Test.

PS > $env:FOO
Test

#>

param(
    ## The path to the script to run.
    [Parameter(Mandatory = $true)]
    [string] $Path,

    ## The arguments to pass to the script.
    [string] $ArgumentList,

    ## If set, start script inside current environment and then update current environment
    ## with results from executing the script.
    [bool] $SetEnvironment
)

Set-StrictMode -Version Latest

if (Test-Path -Path $Path -PathType Leaf) {
    ## Store the output of cmd.exe.  We also ask cmd.exe to output
    ## the environment table after the batch file completes
    if ($SetEnvironment) {
        $tempFile = [IO.Path]::GetTempFileName()

        Start-Process -Wait -FilePath "$env:windir\system32\cmd.exe" -NoNewWindow -ArgumentList @(
            "/c", "$Path $argumentList && set > $tempFile")

        ## Go through the environment variables in the temp file.
        ## For each of them, set the variable in our local environment.
        Get-Content $tempFile | ForEach-Object {
            if ($_ -match "^(.*?)=(.*)$") {
                Set-Content "env:\$($matches[1])" $matches[2]
            }
        }

        Remove-Item $tempFile

        Write-Host "Finished execution: $Path"
    }
    else {
        Start-Process -Wait -FilePath "$env:windir\system32\cmd.exe" -NoNewWindow -UseNewEnvironment -ArgumentList @(
            "/c", "`"$Path`" $argumentList")
        Write-Host "Finished execution: $Path"
    }
}
else {
    Write-Host "ERROR: Script not found: '$Path'"
}
