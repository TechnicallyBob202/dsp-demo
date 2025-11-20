################################################################################
##
## DSP-Demo-Preflight.psm1
##
## Preflight module for DSP demo activity generation
## Handles ALL environment discovery, validation, and setup
##
## Author: Rob Ingenthron (Original), Bob Lyons (Refactor)
## Version: 1.1.0-20251120
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
# LOGGING & OUTPUT FUNCTIONS
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
# ADMIN & VERSION CHECKS
################################################################################

function Test-AdminRights {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Status "Script requires Administrator privileges" -Level Error
        exit 1
    }
    
    Write-Status "Administrator rights verified" -Level Success
}

function Test-PowerShellVersion {
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        Write-Status "PowerShell 5.1 or higher required" -Level Error
        exit 1
    }
    
    Write-Status "PowerShell version: $($PSVersionTable.PSVersion)" -Level Success
}

function Test-ActiveDirectoryModule {
    if (-not (Get-Module -ListAvailable ActiveDirectory)) {
        Write-Status "ActiveDirectory module is required" -Level Error
        exit 1
    }
    
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        Write-Status "ActiveDirectory module imported" -Level Success
    }
    catch {
        Write-Status "Failed to import ActiveDirectory module: $_" -Level Error
        exit 1
    }
}

################################################################################
# ACTIVE DIRECTORY DISCOVERY
################################################################################

function Get-DomainInfo {
    try {
        $domain = Get-ADDomain -ErrorAction Stop
        
        return [PSCustomObject]@{
            FQDN = $domain.Name
            DN = $domain.DistinguishedName
            NetBIOSName = $domain.NetBIOSName
            Forest = $domain.Forest
        }
    }
    catch {
        Write-Status "Failed to get domain info: $_" -Level Error
        throw $_
    }
}

function Get-ADDomainControllers {
    try {
        $dcs = Get-ADDomainController -Filter * -ErrorAction Stop
        return $dcs
    }
    catch {
        Write-Status "Failed to get domain controllers: $_" -Level Error
        throw $_
    }
}

function Get-ForestInfo {
    try {
        $forest = Get-ADForest -ErrorAction Stop
        
        return [PSCustomObject]@{
            Name = $forest.Name
            RootDomain = $forest.RootDomain
            Domains = $forest.Domains
        }
    }
    catch {
        Write-Status "Failed to get forest info: $_" -Level Error
        throw $_
    }
}

################################################################################
# DSP DISCOVERY
################################################################################

function Find-DspServer {
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$DomainInfo,
        
        [Parameter(Mandatory=$false)]
        [string]$ConfigServer = ""
    )
    
    # If config specifies a DSP server, try it first
    if ($ConfigServer -and $ConfigServer -ne "") {
        Write-Status "Attempting to contact configured DSP server: $ConfigServer" -Level Info
        try {
            # Simple connectivity check
            if (Test-Connection -ComputerName $ConfigServer -Count 1 -ErrorAction SilentlyContinue) {
                Write-Status "DSP server is reachable: $ConfigServer" -Level Success
                return $ConfigServer
            }
            else {
                Write-Status "DSP server is not reachable: $ConfigServer" -Level Warning
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
        Runs all preflight checks and returns environment information
    
    .PARAMETER Config
        Configuration hashtable (optional, for DSP server config)
    
    .OUTPUTS
        PSCustomObject with all environment information
    #>
    param(
        [Parameter(Mandatory=$false)]
        [hashtable]$Config = @{}
    )
    
    Write-Header "PREFLIGHT CHECKS"
    
    # Run checks
    Test-AdminRights
    Test-PowerShellVersion
    Test-ActiveDirectoryModule
    
    Write-Host ""
    Write-Header "ENVIRONMENT DISCOVERY"
    
    # Get domain/forest info
    $domainInfo = Get-DomainInfo
    Write-Status "Domain: $($domainInfo.FQDN)" -Level Success
    Write-Status "Domain DN: $($domainInfo.DN)" -Level Info
    
    # Get DCs
    $dcs = Get-ADDomainControllers
    if ($dcs -is [array]) {
        $primaryDC = $dcs[0].HostName
        $secondaryDC = if ($dcs.Count -gt 1) { $dcs[1].HostName } else { $null }
    }
    else {
        $primaryDC = $dcs.HostName
        $secondaryDC = $null
    }
    
    Write-Status "Primary DC: $primaryDC" -Level Success
    if ($secondaryDC) {
        Write-Status "Secondary DC: $secondaryDC" -Level Info
    }
    
    # Get forest info
    $forestInfo = Get-ForestInfo
    Write-Status "Forest: $($forestInfo.Name)" -Level Success
    
    # DSP discovery
    Write-Host ""
    Write-Header "DSP DISCOVERY"
    
    $dspServerFromConfig = if ($Config.General -and $Config.General.DspServer) { 
        $Config.General.DspServer 
    } else { 
        "" 
    }
    
    $dspServer = Find-DspServer -DomainInfo $domainInfo -ConfigServer $dspServerFromConfig
    $dspAvailable = if ($dspServer) { $true } else { $false }
    
    Write-Host ""
    
    # Return environment object
    return [PSCustomObject]@{
        DomainInfo = $domainInfo
        PrimaryDC = $primaryDC
        SecondaryDC = $secondaryDC
        ForestInfo = $forestInfo
        DspAvailable = $dspAvailable
        DspServer = $dspServer
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
    'Get-DomainInfo',
    'Get-ADDomainControllers',
    'Get-ForestInfo',
    'Find-DspServer',
    'Initialize-PreflightEnvironment'
)