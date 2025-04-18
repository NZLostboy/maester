﻿function Test-MtConnection {
    <#
    .SYNOPSIS
    Checks if the current session is connected to the specified service. Use -Verbose to see the connection status for each service.

    .DESCRIPTION
    Tests the connection for each service and returns $true if the session is connected to the specified service.

    .EXAMPLE
    Test-MtConnection

    Checks if the current session is connected to Microsoft Graph.

    .EXAMPLE
    Test-MtConnection -Service All

    Checks if the current session is connected to all services including Azure, Microsoft Graph, Exchange Online, Exchange Online Protection (via IPPSSession), and Microsoft Teams.

    .LINK
    https://maester.dev/docs/commands/Test-MtConnection
#>
    [CmdletBinding()]
    param(
        # Checks if the current session is connected to the specified service
        [ValidateSet('All', 'Azure', 'ExchangeOnline', 'Graph', 'SecurityCompliance', 'Teams')]
        [Parameter(Position = 0, Mandatory = $false)]
        [string[]]$Service = 'All'
    )

    $ConnectionState = $true

    if ($Service -contains 'Azure' -or $Service -contains 'All') {
        $IsConnected = $false
        try {
            $IsConnected = $null -ne (Get-AzContext -ErrorAction SilentlyContinue)
            # Validate that the credentials are still valid
            if($IsConnected) {
                Invoke-AzRestMethod -Method GET -Path 'subscriptions?api-version=2022-12-01' | Out-Null
            }
        } catch {
            $IsConnected = $false
            Write-Debug "Azure: $false"
        }
        Write-Verbose "Azure: $IsConnected"
        if (!$IsConnected) { $ConnectionState = $false }
    }

    if ($Service -contains 'Graph' -or $Service -contains 'All') {
        $IsConnected = $false
        try {
            $IsConnected = $null -ne (Get-MgContext -ErrorAction SilentlyContinue)
        } catch {
            Write-Debug "Graph: $false"
        }
        Write-Verbose "Graph: $IsConnected"
        if (!$IsConnected) { $ConnectionState = $false }
    }

    if ($Service -contains 'ExchangeOnline' -or $Service -contains 'All') {
        $IsConnected = $false
        try {
            $IsConnected = $null -ne ((Get-ConnectionInformation | Where-Object { $_.Name -match 'ExchangeOnline' -and $_.state -eq 'Connected' }))
        } catch {
            Write-Debug "Exchange Online: $false"
        }
        Write-Verbose "Exchange Online: $IsConnected"
        if (!$IsConnected) { $ConnectionState = $false }
    }

    if ($Service -contains 'SecurityCompliance' -or $Service -contains 'All') {
        $IsConnected = $false
        try {
            $IsConnected = $null -ne ((Get-ConnectionInformation | Where-Object { $_.Name -match 'ExchangeOnline' -and $_.state -eq 'Connected' -and $_.IsEopSession }))
        } catch {
            Write-Debug "Security & Compliance: $false"
        }
        Write-Verbose "Security & Compliance: $IsConnected"
        if (!$IsConnected) { $ConnectionState = $false }
    }

    if ($Service -contains 'Teams' -or $Service -contains 'All') {
        $IsConnected = $false
        try {
            $IsConnected = $null -ne (Get-CsTenant -ErrorAction SilentlyContinue)
        } catch {
            Write-Debug "Teams: $false"
        }
        Write-Verbose "Teams: $IsConnected"
        if (!$IsConnected) { $ConnectionState = $false }
    }

    Write-Output $ConnectionState
}
