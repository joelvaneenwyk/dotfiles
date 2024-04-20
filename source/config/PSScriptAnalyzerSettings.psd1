@{
    # Use Severity when you want to limit the generated diagnostic records to a
    # subset of: Error, Warning and Information.
    # Uncomment the following line if you only want Errors and Warnings but
    # not Information diagnostic records.
    Severity     = @('Error', 'Warning', 'Information')

    # Use ExcludeRules when you want to run most of the default set of rules except
    # for a few rules you wish to "exclude".  Note: if a rule is in both IncludeRules
    # and ExcludeRules, the rule will be excluded.
    ExcludeRules = @(
        'PSAvoidUsingWriteHost',
        'PSMissingModuleManifestField'
    )

    # You can use the following entry to supply parameters to rules that take parameters.
    # For instance, the PSAvoidUsingCmdletAliases rule takes a whitelist for aliases you
    # want to allow.
    Rules        = @{
        #    Do not flag 'cd' alias.
        #    PSAvoidUsingCmdletAliases = @{Whitelist = @('cd')}
        PSUseCompatibleSyntax  = @{
            # This turns the rule on (setting it to false will turn it off)
            Enable         = $true

            # List the targeted versions of PowerShell here
            TargetVersions = @(
                '2.0',
                '3.0',
                '5.1',
                '6.2',
                '7.0',
                '8.0'
            )
        }

        #    Check if your script uses cmdlets that are compatible on PowerShell Core,
        #    version 6.0.0-alpha, on Linux.
        PSUseCompatibleCmdlets = @{Compatibility = @("core-6.0.0-alpha-linux") }
    }
}
