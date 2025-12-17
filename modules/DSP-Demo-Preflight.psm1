################################################################################
##
## DSP-Demo-Preflight.psm1
##
## Preflight module for DSP demo activity generation
## Handles environment validation, discovery, and setup
##
## Critical Checks (throw on failure):
## - Administrator privileges
## - PowerShell 5.1+
## - Active Directory module availability
## - Directory Services Protector PowerShell module availability
##
## Environment Discovery (warning on failure, continue):
## - Domain information
## - Domain controllers
## - Forest information
## - DSP server discovery
##
## Author: Bob Lyons
## Version: 2.1.0-20251217
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

################################################################################
# COLORS
################################################################################

$Script:Colors = @{
    Header = 'Cyan'
    Section = 'Green'
    Success = 'Green'
    Warning = 'Yellow'
    Error = 'Red'
    Info = 'White'
}

################################################################################
# OUTPUT FUNCTIONS
################################################################################

function Write-Status {
    param(
        [string]$Message,
        [ValidateSet('Info','Success','Warning','Error')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = $Script:Colors[$Level]
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor $Script:Colors.Header
    Write-Host $Title -ForegroundColor $Script:Colors.Header
    Write-Host ("=" * 80) -ForegroundColor $Script:Colors.Header
    Write-Host ""
}

################################################################################
# CRITICAL CHECKS (MUST PASS)
################################################################################

function Test-AdminRights {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        $message = "This script requires Administrator privileges"
        Write-Status $message -Level Error
        throw $message
    }
    
    Write-Status "Administrator rights verified" -Level Success
}

function Test-PowerShellVersion {
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        $message = "PowerShell 5.1 or higher required (current: $($PSVersionTable.PSVersion))"
        Write-Status $message -Level Error
        throw $message
    }
    
    Write-Status "PowerShell version: $($PSVersionTable.PSVersion)" -Level Success
}

function Test-ActiveDirectoryModule {
    if (-not (Get-Module -ListAvailable ActiveDirectory)) {
        $message = "ActiveDirectory module is required and not available"
        Write-Status $message -Level Error
        throw $message
    }
    
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        Write-Status "ActiveDirectory module imported" -Level Success
    }
    catch {
        $message = "Failed to import ActiveDirectory module: $_"
        Write-Status $message -Level Error
        throw $message
    }
}

function Test-DspPowershellModule {
    if (-not (Get-Module -ListAvailable Semperis.PoSh.DSP)) {
        $message = "Semperis.PoSh.DSP PowerShell module is required and not available"
        Write-Status $message -Level Error
        throw $message
    }
    
    try {
        Import-Module Semperis.PoSh.DSP -ErrorAction Stop
        Write-Status "Semperis.PoSh.DSP module imported" -Level Success
    }
    catch {
        $message = "Failed to import Semperis.PoSh.DSP module: $_"
        Write-Status $message -Level Error
        throw $message
    }
}

################################################################################
# ENVIRONMENT DISCOVERY (WARNINGS ALLOWED, CONTINUES ON FAILURE)
################################################################################

function Get-DomainInfo {
    try {
        $domain = Get-ADDomain -ErrorAction Stop
        
        $result = [PSCustomObject]@{
            FQDN = $domain.Name
            DN = $domain.DistinguishedName
            NetBIOSName = $domain.NetBIOSName
            Forest = $domain.Forest
        }
        
        Write-Status "Domain: $($result.FQDN)" -Level Success
        return $result
    }
    catch {
        $message = "Failed to retrieve domain information: $_"
        Write-Status $message -Level Error
        throw $message
    }
}

function Get-ADDomainControllers {
    try {
        $dcs = Get-ADDomainController -Filter * -ErrorAction SilentlyContinue | Sort-Object Name
        
        if (-not $dcs) {
            $message = "No domain controllers found"
            Write-Status $message -Level Error
            throw $message
        }
        
        $primary = $dcs[0].Name
        $secondary = if ($dcs.Count -gt 1) { $dcs[1].Name } else { $null }
        
        Write-Status "Primary DC: $primary" -Level Success
        if ($secondary) {
            Write-Status "Secondary DC: $secondary" -Level Success
        }
        
        return [PSCustomObject]@{
            Primary = $primary
            Secondary = $secondary
            All = $dcs
        }
    }
    catch {
        $message = "Failed to retrieve domain controller information: $_"
        Write-Status $message -Level Error
        throw $message
    }
}

function Get-ForestInfo {
    try {
        $forest = Get-ADForest -ErrorAction Stop
        
        $result = [PSCustomObject]@{
            Name = $forest.Name
            RootDomain = $forest.RootDomain
            ForestMode = $forest.ForestMode
            DomainCount = $forest.Domains.Count
        }
        
        Write-Status "Forest: $($result.Name) (Mode: $($result.ForestMode))" -Level Success
        return $result
    }
    catch {
        $message = "Failed to retrieve forest information: $_"
        Write-Status $message -Level Error
        throw $message
    }
}

################################################################################
# DSP SERVER DISCOVERY
################################################################################

function Find-DspServer {
    param(
        [Parameter(Mandatory=$true)]
        $DomainInfo,
        
        [Parameter(Mandatory=$false)]
        [string]$ConfigServer = "",
        
        [Parameter(Mandatory=$false)]
        [bool]$SkipDspChecks = $false
    )
    
    # If explicitly skipped, don't attempt discovery
    if ($SkipDspChecks) {
        Write-Status "DSP checks skipped by configuration" -Level Warning
        return $null
    }

    # If config specifies a DSP server, try it first
    if ($ConfigServer -and $ConfigServer -ne "") {
        Write-Status "Testing configured DSP server: $ConfigServer" -Level Info
        try {
            if (Test-Connection -ComputerName $ConfigServer -Count 1 -ErrorAction SilentlyContinue) {
                Write-Status "DSP server is reachable: $ConfigServer" -Level Success
                return $ConfigServer
            }
            else {
                Write-Status "DSP server not reachable: $ConfigServer" -Level Warning
            }
        }
        catch {
            Write-Status "Error testing DSP server: $_" -Level Warning
        }
    }
    
    # Try SCP discovery
    Write-Status "Attempting DSP SCP discovery..." -Level Info
    try {
        $scp = Get-ADObject -SearchBase "CN=Semperis,CN=Services,CN=Configuration,$($DomainInfo.DN)" `
            -Filter { objectClass -eq 'serviceConnectionPoint' } `
            -Properties keywords -ErrorAction SilentlyContinue
        
        if ($scp -and $scp.keywords) {
            $dspServer = $scp.keywords[0]
            Write-Status "DSP server found via SCP: $dspServer" -Level Success
            return $dspServer
        }
    }
    catch {
        Write-Status "SCP discovery failed: $_" -Level Warning
    }
    
    Write-Status "DSP server not found - continuing without DSP integration" -Level Warning
    return $null
}

################################################################################
# MAIN PREFLIGHT FUNCTION
################################################################################

function Initialize-PreflightEnvironment {
    <#
    .SYNOPSIS
        Runs preflight checks and environment discovery
    
    .DESCRIPTION
        Critical checks (admin rights, PowerShell version, AD module, DSP module) must pass.
        Environment discovery warnings are allowed - continues on failure.
    
    .PARAMETER Config
        Configuration hashtable (optional, for DSP server config)
    
    .OUTPUTS
        PSCustomObject with environment information
    
    .THROWS
        On any critical preflight check failure
    #>
    param(
        [Parameter(Mandatory=$false)]
        [hashtable]$Config = @{}
    )
    
    Write-Header "PREFLIGHT CHECKS"
    
    # Run critical checks - any failure throws
    Test-AdminRights
    Test-PowerShellVersion
    Test-ActiveDirectoryModule
    Test-DspPowershellModule
    
    Write-Host ""
    Write-Header "ENVIRONMENT DISCOVERY"
    
    # Get domain/forest info - throws on failure
    $domainInfo = Get-DomainInfo
    $dcInfo = Get-ADDomainControllers
    $forestInfo = Get-ForestInfo
    
    # DSP discovery - respects SkipDspChecks configuration
    Write-Host ""
    Write-Header "DSP SERVER DISCOVERY"

    $skipDsp = $false
    $dspServerFromConfig = ""

    if ($Config.General) {
        $skipDsp = if ($Config.General.ContainsKey('SkipDspChecks')) { 
            $Config.General.SkipDspChecks 
        } else { 
            $false 
        }
        
        $dspServerFromConfig = if ($Config.General.ContainsKey('DspServer')) { 
            $Config.General.DspServer 
        } else { 
            "" 
        }
    }

    $dspServer = Find-DspServer -DomainInfo $domainInfo -ConfigServer $dspServerFromConfig -SkipDspChecks $skipDsp
    $dspAvailable = if ($dspServer) { $true } else { $false }
    
    Write-Host ""
    
    # Return complete environment object
    return [PSCustomObject]@{
        DomainInfo = $domainInfo
        PrimaryDC = $dcInfo.Primary
        SecondaryDC = $dcInfo.Secondary
        ForestInfo = $forestInfo
        DspAvailable = $dspAvailable
        DspServer = $dspServer
        SkipDspChecks = $skipDsp
    }
}

################################################################################
# EXPORTS
################################################################################

Export-ModuleMember -Function @(
    'Write-Status',
    'Write-Header',
    'Test-AdminRights',
    'Test-PowerShellVersion',
    'Test-ActiveDirectoryModule',
    'Test-DspPowershellModule',
    'Get-DomainInfo',
    'Get-ADDomainControllers',
    'Get-ForestInfo',
    'Find-DspServer',
    'Initialize-PreflightEnvironment'
)