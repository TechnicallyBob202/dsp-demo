################################################################################
##
## DSP-Demo-AD-Discovery.psm1
##
## Active Directory discovery module for domain, forest, and DSP server detection.
## This module handles all the AD environment discovery that was in the original script.
##
## Author: Rob Ingenthron (Original), Bob Lyons (Refactor)
## Version: 1.0.0
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

# Import core module
Import-Module (Join-Path $PSScriptRoot "DSP-Demo-01-Core.psm1") -Force

################################################################################
# AD DISCOVERY FUNCTIONS
################################################################################

function Get-DomainInfo {
    <#
    .SYNOPSIS
        Discovers and returns comprehensive domain information.
    
    .DESCRIPTION
        Gathers all relevant domain information needed throughout the DSP demo script.
        This replaces the scattered domain information gathering in the original script.
        
        Original code reference: Lines ~2508-2532
    
    .EXAMPLE
        $domainInfo = Get-DomainInfo
        Write-Host "Domain: $($domainInfo.FQDN)"
    
    .OUTPUTS
        PSCustomObject with domain information
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-ScriptLog ":: Discovering Active Directory domain information..." -Level Info
        
        $adDomain = Get-ADDomain -Current LocalComputer
        $adForest = Get-ADForest -Current LocalComputer
        $adForestRootDomain = Get-ADDomain $adForest.RootDomain
        
        # Build comprehensive domain information object
        $domainInfo = [PSCustomObject]@{
            # Current Domain Information
            DistinguishedName = $adDomain.DistinguishedName
            FQDN = $adDomain.DNSRoot
            NetBIOSName = $adDomain.NetBIOSName
            DomainSID = $adDomain.DomainSID.Value
            PDCEmulator = $adDomain.PDCEmulator
            DeletedObjectsContainer = $adDomain.DeletedObjectsContainer
            DomainControllersContainer = $adDomain.DomainControllersContainer
            
            # Domain Controllers
            RWDC = $null  # Will be populated below
            AllDCs = @()  # Will be populated below
            
            # Forest Information
            Forest = @{
                RootDomainFQDN = $adForest.RootDomain
                RootDomainNetBIOS = $adForestRootDomain.NetBIOSName
                RootDomainSID = $adForestRootDomain.DomainSID.Value
                SchemaMaster = $adForest.SchemaMaster
                DomainNamingMaster = $adForest.DomainNamingMaster
                PartitionsContainer = $adForest.PartitionsContainer
                ConfigurationNC = $null  # Will be calculated below
                SchemaNC = $null  # Will be calculated below
            }
            
            # Commonly Used Paths
            Paths = @{
                TestOU = "OU=TEST,$($adDomain.DistinguishedName)"
                DemoOU = "OU=DSP-Demo-Objects,$($adDomain.DistinguishedName)"
            }
        }
        
        # Calculate Configuration and Schema NC
        $domainInfo.Forest.ConfigurationNC = $domainInfo.Forest.PartitionsContainer.Replace("CN=Partitions,","")
        $domainInfo.Forest.SchemaNC = "CN=Schema," + $domainInfo.Forest.ConfigurationNC
        
        # Discover domain controllers
        Write-ScriptLog ":: Discovering domain controllers..." -Level Verbose
        
        $dcInfo = Get-DomainController -DomainName $domainInfo.FQDN -Discover
        $domainInfo.RWDC = $dcInfo.HostName[0]
        
        # Get all DCs in domain
        $allDCs = Get-DomainController -Filter * -Server $domainInfo.FQDN
        $domainInfo.AllDCs = $allDCs | ForEach-Object { $_.HostName }
        
        Write-ScriptLog ":: Domain discovery complete" -Level Success
        Write-ScriptLog "::   Domain FQDN: $($domainInfo.FQDN)" -Level Info
        Write-ScriptLog "::   NetBIOS Name: $($domainInfo.NetBIOSName)" -Level Info
        Write-ScriptLog "::   Primary DC: $($domainInfo.RWDC)" -Level Info
        Write-ScriptLog "::   Total DCs: $($domainInfo.AllDCs.Count)" -Level Info
        
        return $domainInfo
    }
    catch {
        Write-ScriptLog ":: ERROR: Failed to discover domain information - $_" -Level Error
        throw
    }
}

################################################################################
# EXPORT MODULE MEMBERS
################################################################################

# Export discovery functions + core functions for downstream use
Export-ModuleMember -Function @(
    'Get-DomainInfo',
    'Write-ScriptLog',
    'Write-LogHeader',
    'Wait-ADReplication',
    'Test-AdminRights',
    'Get-Timestamp',
    'Invoke-DspCommand'
)