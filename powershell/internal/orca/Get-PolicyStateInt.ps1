# Generated on 04/16/2025 21:38:23 by .\build\orca\Update-OrcaTests.ps1

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '')]
param()

Function Get-PolicyStateInt
{
    <#
    .SYNOPSIS
        Called by Get-PolicyStates to process a policy
    #>

    Param(
        $Policies,
        $Rules,
        $ProtectionPolicyRules,
        $BuiltInProtectionRule,
        [PolicyType]$Type
    )

    $ReturnPolicies = @{}

    # Used for marking the default policy at the end as not applies, if there is an applied preset policy
    $TypeHasAppliedPresetPolicy = $False

    foreach($Policy in $Policies)
    {

        $Applies = $false
        $Disabled = $false
        $Default = $false
        $Preset = $false
        $DoesNotApply = $false
        $PresetPolicyLevel = [PresetPolicyLevel]::None
        $BuiltIn = ($Policy.Identity -eq $BuiltInProtectionRule.SafeAttachmentPolicy -or $Policy.Identity -eq $BuiltInProtectionRule.SafeLinksPolicy)
        $Name = $Policy.Name

        # Determine preset
        if($Policy.RecommendedPolicyType -eq "Standard" -or $Policy.RecommendedPolicyType -eq "Strict")
        {
            $Name = "$($Policy.RecommendedPolicyType) Preset Security Policy"
            $Preset = $True;

            if($($Policy.RecommendedPolicyType) -eq "Standard")
            {
                $PresetPolicyLevel = ([PresetPolicyLevel]::Standard)
            }

            if($($Policy.RecommendedPolicyType) -eq "Strict")
            {
                $PresetPolicyLevel = ([PresetPolicyLevel]::Strict)
            }
        }

        # Built in rules always apply
        if($BuiltIn)
        {
            $Applies = $True
        }

        # Checks for default policies EOP
        if(
            $Policy.DistinguishedName.StartsWith("CN=Default,CN=Malware Filter,CN=Transport Settings") -or
            $Policy.DistinguishedName.StartsWith("CN=Default,CN=Hosted Content Filter,CN=Transport Settings") -or
            $Policy.DistinguishedName.StartsWith("CN=Default,CN=Outbound Spam Filter,CN=Transport Settings"))
        {
            $Default = $True
            $Disabled = $False
            $Applies = $True
        }

        # Check for default policies MDO
        if ($Policy.DistinguishedName.StartsWith("CN=Office365 AntiPhish Default,CN=AntiPhish,CN=Transport Settings,CN=Configuration"))
        {
            $Default = $True

            # Policy will apply based on Enabled state
            $Disabled = !$Policy.Enabled
            $Applies = $Policy.Enabled
        }

        # If not applying - check rules for application
        if(!$Applies)
        {

            $PolicyRules = @();

            # If Preset, rules to check is the protection policy rules (MDO or EOP protection policy rules), if not, the policy rules.
            if($Preset)
            {

                # When preset - we need to match the rule using
                # HostedContentFilterPolicy, AntiPhishPolicy, MalwareFilterPolicy attributes [EOP]
                # SafeAttachmentPolicy, SafeLinksPolicy [MDO]
                # instead of the name.

                # The name of a preset policy doesn't always match the id in the rule.

                if($Type -eq [PolicyType]::Spam)
                {
                    $PolicyRules = @($ProtectionPolicyRules | Where-Object {$_.HostedContentFilterPolicy -eq $Policy.Identity})
                }

                if($Type -eq [PolicyType]::Antiphish)
                {
                    $PolicyRules = @($ProtectionPolicyRules | Where-Object {$_.AntiPhishPolicy -eq $Policy.Identity})
                }

                if($Type -eq [PolicyType]::Malware)
                {
                    $PolicyRules = @($ProtectionPolicyRules | Where-Object {$_.MalwareFilterPolicy -eq $Policy.Identity})
                }

                if($Type -eq [PolicyType]::SafeAttachments)
                {
                    $PolicyRules = @($ProtectionPolicyRules | Where-Object {$_.SafeAttachmentPolicy -eq $Policy.Identity})
                }

                if($Type -eq [PolicyType]::SafeLinks)
                {
                    $PolicyRules = @($ProtectionPolicyRules | Where-Object {$_.SafeLinksPolicy -eq $Policy.Identity})
                }

            } else {
                $PolicyRules = @($Rules | Where-Object {$_.Name -eq $Policy.Name})
            }

            foreach($Rule in $PolicyRules)
            {
                if($Rule.State -eq "Enabled")
                {

                    # Need to use a different mechanism for detecting application if it's a preset or a custom policy
                    # custom requires a condition to apply
                    # preset doesn't require a condition to apply, in fact mark it as not applicable if there is a condition

                    if(!$Preset)
                    {
                        if($Rule.SentTo.Count -gt 0 -or $Rule.SentToMemberOf.Count -gt 0 -or $Rule.RecipientDomainIs.Count -gt 0)
                        {
                            $Applies = $true
                        }

                        # Outbound spam uses From, FromMemberOf and SenderDomainIs conditions
                        if($Type -eq [PolicyType]::OutboundSpam)
                        {
                            if($Rule.From.Count -gt 0 -or $Rule.FromMemberOf.Count -gt 0 -or $Rule.SenderDomainIs.Count -gt 0)
                            {
                                $Applies = $true
                            }
                        }
                    }

                    # Need to use a different mechanism for detecting application if it's a preset or a custom policy
                    # custom requires a condition to apply
                    # preset doesn't require a condition to apply, in fact mark it as not applicable if there is a condition

                    if($Preset)
                    {
                        if($Policy.Conditions.Count -eq 0)
                        {
                            $Applies = $true
                        }
                    }

                }
            }
        }

        # Mark policy type has preset to true if preset applies, this is used to disable the default policy in the report.
        if($Preset -eq $true -and $Applies -eq $True)
        {
            $TypeHasAppliedPresetPolicy = $True
        }

        $ReturnPolicies[$Policy.Guid.ToString()] = New-Object -TypeName PolicyInfo -Property @{
            Applies=$Applies
            Disabled=$Disabled
            Preset=$Preset
            PresetLevel=($PresetPolicyLevel)
            BuiltIn=$BuiltIn
            Default=$Default
            Name=$Name
            Type=$Type
        }
    }

    # Disable default and BIP in-case of preset code
    if($TypeHasAppliedPresetPolicy)
    {
        foreach($Key in $ReturnPolicies.Keys)
        {
            if($ReturnPolicies[$Key].Default -eq $True)
            {
                $ReturnPolicies[$Key].Applies = $False
            }

            if($ReturnPolicies[$Key].BuiltIn -eq $True)
            {
                $ReturnPolicies[$Key].Applies = $False
            }
        }
    }

    return $ReturnPolicies
}
