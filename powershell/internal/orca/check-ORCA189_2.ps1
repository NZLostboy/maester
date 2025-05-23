# Generated on 04/16/2025 21:38:23 by .\build\orca\Update-OrcaTests.ps1

using module ".\orcaClass.psm1"

[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseDeclaredVarsMoreThanAssignments', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSPossibleIncorrectComparisonWithNull', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidGlobalVars', '')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingCmdletAliases', '')]
param()


<#

    189-2
    
    Checks to determine if SafeLinks is being bypassed by injecting X-MS-Exchange-Organization-SkipSafeLinksProcessing
    header in to emails using a mail flow rule.

#>



class ORCA189_2 : ORCACheck
{
    <#
    
        CONSTRUCTOR with Check Header Data
    
    #>

    ORCA189_2()
    {
        $this.Control="189-2"
        $this.Services=[ORCAService]::MDO
        $this.Area="Microsoft Defender for Office 365 Policies"
        $this.Name="Safe Links Allow Listing"
        $this.PassText="Safe Links is not bypassed"
        $this.FailRecommendation="Remove mail flow rules which bypass Safe Links"
        $this.Importance="Microsoft Defender for Office 365 Safe Links can help protect against phishing attacks by providing time-of-click verification of web addresses (URLs) in email messages and Office documents. The protection can be bypassed using mail flow rules which set the X-MS-Exchange-Organization-SkipSafeLinksProcessing header for email messages."
        $this.ExpandResults=$True
        $this.ObjectType="Transport Rule"
        $this.ItemName="Setting"
        $this.DataType="Current Value"
        $this.CheckType = [CheckType]::ObjectPropertyValue
        $this.ChiValue=[ORCACHI]::High
        $this.Links= @{
            "Exchange admin center in Exchange Online"="https://outlook.office365.com/ecp/"
        }
    }

    <#
    
        RESULTS
    
    #>

    GetResults($Config)
    {

        $BypassRules = @($Config["TransportRules"] | Where-Object {$_.SetHeaderName -eq "X-MS-Exchange-Organization-SkipSafeLinksProcessing"})
        
        If($BypassRules.Count -gt 0) 
        {
            # Rules exist to bypass
            ForEach($Rule in $BypassRules) 
            {
                # Check objects
                $ConfigObject = [ORCACheckConfig]::new()
                $ConfigObject.Object=$($Rule.Name)
                $ConfigObject.ConfigItem=$($Rule.SetHeaderName)
                $ConfigObject.ConfigData=$($Rule.SetHeaderValue)
                $ConfigObject.ConfigDisabled=$($Rule.State -eq "Disabled")
                $ConfigObject.SetResult([ORCAConfigLevel]::Standard,"Fail")
                $this.AddConfig($ConfigObject)  

            }
        }   

    }

}
