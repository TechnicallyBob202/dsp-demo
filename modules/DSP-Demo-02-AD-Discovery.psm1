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

function Get-DspDomainInfo {
    <#
    .SYNOPSIS
        Discovers and returns comprehensive domain information.
    
    .DESCRIPTION
        Gathers all relevant domain information needed throughout the DSP demo script.
        This replaces the scattered domain information gathering in the original script.
        
        Original code reference: Lines ~2508-2532
    
    .EXAMPLE
        $domainInfo = Get-DspDomainInfo
        Write-Host "Domain: $($domainInfo.FQDN)"
    
    .OUTPUTS
        PSCustomObject with domain information
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-DspLog ":: Discovering Active Directory domain information..." -Level Info
        
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
        Write-DspLog ":: Discovering domain controllers..." -Level Verbose
        
        $dcInfo = Get-ADDomainController -DomainName $domainInfo.FQDN -Discover
        $domainInfo.RWDC = $dcInfo.HostName[0]
        
        # Get all DCs in domain
        $allDCs = Get-ADDomainController -Filter * -Server $domainInfo.FQDN
        $domainInfo.AllDCs = $allDCs | ForEach-Object { $_.HostName }
        
        Write-DspLog ":: Domain discovery complete" -Level Success
        Write-DspLog "::   Domain FQDN: $($domainInfo.FQDN)" -Level Info
        Write-DspLog "::   NetBIOS Name: $($domainInfo.NetBIOSName)" -Level Info
        Write-DspLog "::   Primary DC: $($domainInfo.RWDC)" -Level Info
        Write-DspLog "::   Total DCs: $($domainInfo.AllDCs.Count)" -Level Info
        
        return $domainInfo
    }
    catch {
        Write-DspLog ":: ERROR: Failed to discover domain information - $_" -Level Error
        throw
    }
}

function Find-DspServer {
    <#
    .SYNOPSIS
        Discovers the DSP server via Service Connection Point (SCP).
    
    .DESCRIPTION
        Searches Active Directory for the DSP Service Connection Point to automatically
        discover the DSP server. This is critical for automating DSP operations.
        
        Original code had extensive SCP discovery logic - this consolidates and improves it.
        
        From the original script:
        "IMPORTANT: Need to somehow discover the DSP server to remove the hard-coding. 
         Can search for the SCP (service connection point)."
    
    .PARAMETER DomainInfo
        Domain information object from Get-DspDomainInfo
    
    .PARAMETER TimeoutSeconds
        Timeout for DSP server search (default: 30)
    
    .EXAMPLE
        $dspServer = Find-DspServer -DomainInfo $domainInfo
        if ($dspServer) {
            Write-Host "Found DSP server: $($dspServer.ServerName)"
        }
    
    .OUTPUTS
        PSCustomObject with DSP server information
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$DomainInfo,
        
        [Parameter(Mandatory=$false)]
        [int]$TimeoutSeconds = 30
    )
    
    try {
        Write-DspLog ":: Searching for DSP server via Service Connection Point..." -Level Info
        
        # DSP registers itself in AD via SCP
        # Search for the DSP service connection point
        $searchBase = "CN=Configuration,$($DomainInfo.Forest.ConfigurationNC)"
        
        Write-DspLog ":: Searching in: $searchBase" -Level Verbose
        
        # Multiple possible SCP locations - try them all
        $scpFilters = @(
            "(keywords=DSP)",
            "(serviceDNSName=*dsp*)",
            "(serviceClassName=DSP)",
            "(cn=*DSP*)"
        )
        
        $dspSCP = $null
        
        foreach ($filter in $scpFilters) {
            try {
                Write-DspLog ":: Trying filter: $filter" -Level Verbose
                
                $scpResults = Get-ADObject -SearchBase $searchBase -LDAPFilter "(objectClass=serviceConnectionPoint)($filter)" -Properties * -ErrorAction SilentlyContinue
                
                if ($scpResults) {
                    $dspSCP = $scpResults | Select-Object -First 1
                    Write-DspLog ":: Found SCP with filter: $filter" -Level Success
                    break
                }
            }
            catch {
                Write-DspLog ":: Filter $filter failed: $_" -Level Verbose
                continue
            }
        }
        
        if (-not $dspSCP) {
            Write-DspLog ":: WARNING: Could not find DSP Service Connection Point in AD" -Level Warning
            Write-DspLog ":: DSP operations will not be available" -Level Warning
            return $null
        }
        
        # Extract DSP server information from SCP
        $dspServerName = $null
        $dspPort = 7031  # Default DSP port
        
        # Try to get server name from various SCP attributes
        if ($dspSCP.serviceDNSName) {
            $dspServerName = $dspSCP.serviceDNSName
        }
        elseif ($dspSCP.serviceBindingInformation) {
            # Format might be like: "https://dspserver:7031"
            $bindingInfo = $dspSCP.serviceBindingInformation
            if ($bindingInfo -match '://([^:]+):?(\d+)?') {
                $dspServerName = $matches[1]
                if ($matches[2]) {
                    $dspPort = [int]$matches[2]
                }
            }
        }
        
        if (-not $dspServerName) {
            Write-DspLog ":: WARNING: Found SCP but could not determine DSP server name" -Level Warning
            return $null
        }
        
        # Verify server is reachable
        Write-DspLog ":: Verifying DSP server connectivity: $dspServerName" -Level Info
        
        $reachable = Test-Connection -ComputerName $dspServerName -Count 1 -Quiet -ErrorAction SilentlyContinue
        
        if (-not $reachable) {
            Write-DspLog ":: WARNING: DSP server $dspServerName is not reachable" -Level Warning
        }
        
        $dspInfo = [PSCustomObject]@{
            ServerName = $dspServerName
            Port = $dspPort
            FQDN = if ($dspServerName -notlike "*.*") { "$dspServerName.$($DomainInfo.FQDN)" } else { $dspServerName }
            Reachable = $reachable
            SCP = $dspSCP
            ConnectionString = "https://${dspServerName}:${dspPort}"
        }
        
        Write-DspLog ":: DSP server discovered successfully" -Level Success
        Write-DspLog "::   Server: $($dspInfo.ServerName)" -Level Info
        Write-DspLog "::   Port: $($dspInfo.Port)" -Level Info
        Write-DspLog "::   Connection: $($dspInfo.ConnectionString)" -Level Info
        
        return $dspInfo
    }
    catch {
        Write-DspLog ":: ERROR: Failed to discover DSP server - $_" -Level Error
        return $null
    }
}

function Test-DspModule {
    <#
    .SYNOPSIS
        Tests if the DSP PowerShell module is installed and functional.
    
    .DESCRIPTION
        Checks for the presence of the Semperis DSP PowerShell module.
        
        From original script:
        "Every time the script is run, it checks for the DSP PoSh module. 
         If the module appears to be missing, the script prompts the user
         to obtain the module installer and add it to the scripts folder."
    
    .PARAMETER AttemptLoad
        Attempt to load the module if found
    
    .EXAMPLE
        if (Test-DspModule -AttemptLoad) {
            Write-Host "DSP module is ready"
        }
    
    .OUTPUTS
        Boolean - $true if module is available and loaded
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$AttemptLoad
    )
    
    try {
        Write-DspLog ":: Checking for DSP PowerShell module..." -Level Info
        
        # Check if module is already loaded
        $loadedModule = Get-Module -Name "Semperis.PoSh.DSP" -ErrorAction SilentlyContinue
        
        if ($loadedModule) {
            Write-DspLog ":: DSP PowerShell module is already loaded" -Level Success
            return $true
        }
        
        # Check if module is available
        $availableModule = Get-Module -Name "Semperis.PoSh.DSP" -ListAvailable -ErrorAction SilentlyContinue
        
        if (-not $availableModule) {
            Write-DspLog ":: WARNING: DSP PowerShell module is NOT installed" -Level Warning
            Write-DspLog ":: " -Level Warning
            Write-DspLog ":: The tasks using DSP automation will not work, but other activities will be unaffected." -Level Warning
            Write-DspLog ":: " -Level Warning
            Write-DspLog ":: To install the DSP PowerShell module:" -Level Warning
            Write-DspLog "::   1. Download the DSP PowerShell installer from the DSP console" -Level Warning
            Write-DspLog "::   2. Run the installer on this machine" -Level Warning
            Write-DspLog "::   3. Re-run this script" -Level Warning
            Write-DspLog ":: " -Level Warning
            
            return $false
        }
        
        Write-DspLog ":: DSP PowerShell module is installed" -Level Success
        
        if ($AttemptLoad) {
            Write-DspLog ":: Loading DSP PowerShell module..." -Level Info
            
            Import-Module "Semperis.PoSh.DSP" -ErrorAction Stop
            
            Write-DspLog ":: DSP PowerShell module loaded successfully" -Level Success
            return $true
        }
        
        return $true
    }
    catch {
        Write-DspLog ":: ERROR: Failed to load DSP PowerShell module - $_" -Level Error
        return $false
    }
}

function Get-DspEnvironmentInfo {
    <#
    .SYNOPSIS
        Gets all environment information needed for DSP demo operations.
    
    .DESCRIPTION
        Comprehensive function that gathers domain, forest, and DSP server information.
        This is a convenience function that calls all discovery functions.
    
    .PARAMETER SkipDspDiscovery
        Skip DSP server discovery
    
    .EXAMPLE
        $env = Get-DspEnvironmentInfo
        Write-Host "Domain: $($env.Domain.FQDN)"
        Write-Host "DSP Server: $($env.DSP.ServerName)"
    
    .OUTPUTS
        PSCustomObject with comprehensive environment information
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [switch]$SkipDspDiscovery
    )
    
    try {
        Write-DspHeader "ENVIRONMENT DISCOVERY"
        
        # Get domain information
        $domainInfo = Get-DspDomainInfo
        
        # Get DSP server information
        $dspInfo = $null
        $dspModuleAvailable = $false
        
        if (-not $SkipDspDiscovery) {
            $dspInfo = Find-DspServer -DomainInfo $domainInfo
            $dspModuleAvailable = Test-DspModule
        }
        
        # Build comprehensive environment object
        $envInfo = [PSCustomObject]@{
            Domain = $domainInfo
            DSP = $dspInfo
            DSPModuleAvailable = $dspModuleAvailable
            ScriptPath = $PSScriptRoot
            DiscoveryTime = Get-Date
        }
        
        Write-DspLog "" -Level Info
        Write-DspLog ":: Environment discovery complete!" -Level Success
        Write-DspLog "" -Level Info
        
        return $envInfo
    }
    catch {
        Write-DspLog ":: FATAL ERROR: Failed to discover environment - $_" -Level Error
        throw
    }
}

################################################################################
# EXPORT MODULE MEMBERS
################################################################################

# Export discovery functions + core functions for downstream use
Export-ModuleMember -Function @(
    'Get-DspDomainInfo',
    'Find-DspServer',
    'Test-DspModule',
    'Get-DspEnvironmentInfo',
    'Write-DspLog',
    'Write-DspHeader',
    'Wait-DspReplication',
    'Test-DspAdminRights',
    'Get-DspTimestamp',
    'Invoke-DspCommand'
)