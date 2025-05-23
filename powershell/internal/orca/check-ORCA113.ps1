# Generated on 04/16/2025 21:38:23 by .\build\orca\Update-OrcaTests.ps1

using module ".\orcaClass.psm1"

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSPossibleIncorrectComparisonWithNull', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
param()




class ORCA113 : ORCACheck
{
    <#
    
        Check if AllowClickThrough is disabled in the organisation wide SafeLinks policy and if AllowClickThrough is True in SafeLink policies
    
    #>

    ORCA113()
    {
        $this.Control="ORCA-113"
        $this.Services=[ORCAService]::MDO
        $this.Area="Microsoft Defender for Office 365 Policies"
        $this.Name="Do not let users click through safe links"
        $this.PassText="AllowClickThrough is disabled in Safe Links policies"
        $this.FailRecommendation="Do not let users click through safe links to original URL"
        $this.Importance="Microsoft Defender for Office 365 Safe Links can help protect your organization by providing time-of-click verification of  web addresses (URLs) in email messages and Office documents. It is possible to allow users click through Safe Links to the original URL. It is recommended to configure Safe Links policies to not let users click through safe links. "
        $this.ExpandResults=$True
        $this.CheckType=[CheckType]::ObjectPropertyValue
        $this.ObjectType="Policy"
        $this.ItemName="Setting"
        $this.DataType="Current Value"
        $this.ChiValue=[ORCACHI]::High
        $this.Links= @{
            "Microsoft 365 Defender Portal - Safe links"="https://security.microsoft.com/safelinksv2"
            "Microsoft Defender for Office 365 Safe Links policies"="https://aka.ms/orca-atpp-docs-11"
            "Recommended settings for EOP and Office 365 Microsoft Defender for Office 365 security"="https://aka.ms/orca-atpp-docs-8"
        }
    
    }

    <#
    
        RESULTS
    
    #>

    GetResults($Config)
    {
        $PolicyCount = 0
       
        ForEach($Policy in $Config["SafeLinksPolicy"]) 
        {    
            # Built-in policy is ignored for this check

            if(!$Config["PolicyStates"][$Policy.Guid.ToString()].IsBuiltIn)
            {
                $IsPolicyDisabled = !$Config["PolicyStates"][$Policy.Guid.ToString()].Applies
                $AllowClickThrough = $($Policy.AllowClickThrough)

                # If not disabled, increment policy count
                if(!$IsPolicyDisabled)
                {
                    $PolicyCount++
                }

                # Check objects
                $ConfigObject = [ORCACheckConfig]::new()
                $ConfigObject.Object=$Config["PolicyStates"][$Policy.Guid.ToString()].Name
                $ConfigObject.ConfigItem="AllowClickThrough"
                $ConfigObject.ConfigData=$AllowClickThrough
                $ConfigObject.ConfigDisabled = $Config["PolicyStates"][$Policy.Guid.ToString()].Disabled
                $ConfigObject.ConfigWontApply = !$Config["PolicyStates"][$Policy.Guid.ToString()].Applies
                $ConfigObject.ConfigReadonly=$Policy.IsPreset
                $ConfigObject.ConfigPolicyGuid=$Policy.Guid.ToString()

                # Determine if AllowClickThrough is True in safelinks policies
                If($Policy.AllowClickThrough -eq $false)
                {
                    $ConfigObject.SetResult([ORCAConfigLevel]::Standard,"Pass")
                }
                Else 
                {
                    $ConfigObject.SetResult([ORCAConfigLevel]::Standard,"Fail")                 
                }

                # Add config to check
                $this.AddConfig($ConfigObject)
            }
        }

        if($PolicyCount -eq 0)
        {
                # Check objects
                $ConfigObject = [ORCACheckConfig]::new()
                $ConfigObject.Object="All non-built in policies"
                $ConfigObject.ConfigItem="AllowClickThrough"
                $ConfigObject.ConfigData="Disabled"
                $ConfigObject.SetResult([ORCAConfigLevel]::Standard,"Fail")
                $this.AddConfig($ConfigObject)
        }

    }

}
