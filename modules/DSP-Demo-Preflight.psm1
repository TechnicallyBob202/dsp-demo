################################################################################
##
## DSP-Demo-Preflight.psm1
##
## Preflight module for DSP demo activity generation
## Handles environment discovery, logging, AD discovery, and DSP connectivity
##
## Author: Rob Ingenthron (Original), Bob Lyons (Refactor)
## Version: 1.0.1-20251119
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

################################################################################
# LOGGING & OUTPUT FUNCTIONS
################################################################################

function Write-ScriptLog {
    <#
    .SYNOPSIS
        Write a timestamped log message to console and optionally to file.
    
    .PARAMETER Message
        The message to log
    
    .PARAMETER Level
        Log level: Info, Success, Warning, Error
    
    .PARAMETER LogFile
        Optional log file path
    
    .EXAMPLE
        Write-ScriptLog "Domain discovered" -Level Success
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Info','Success','Warning','Error')]
        [string]$Level = 'Info',
        
        [Parameter(Mandatory=$false)]
        [string]$LogFile
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $colors = @{
        'Info'    = 'White'
        'Success' = 'Green'
        'Warning' = 'Yellow'
        'Error'   = 'Red'
    }
    
    $color = $colors[$Level]
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
    
    if ($LogFile -and (Test-Path (Split-Path $LogFile))) {
        Add-Content -Path $LogFile -Value "[$timestamp] [$Level] $Message"
    }
}

function Write-LogHeader {
    <#
    .SYNOPSIS
        Write a formatted section header to console.
    
    .PARAMETER Title
        The header title
    
    .EXAMPLE
        Write-LogHeader "Discovering Active Directory"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title
    )
    
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host ""
}

################################################################################
# ADMIN & ENVIRONMENT CHECKS
################################################################################

function Test-AdminRights {
    <#
    .SYNOPSIS
        Test if script is running with administrator privileges.
    
    .OUTPUTS
        [bool] - $true if admin, $false otherwise
    #>
    [CmdletBinding()]
    param()
    
    try {
        $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
        $isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
        
        if ($isAdmin) {
            Write-ScriptLog "Running with administrator privileges" -Level Success
        }
        else {
            Write-ScriptLog "NOT running with administrator privileges" -Level Error
        }
        
        return $isAdmin
    }
    catch {
        Write-ScriptLog "Failed to check admin rights: $_" -Level Error
        return $false
    }
}

function Test-ModuleAvailable {
    <#
    .SYNOPSIS
        Test if a PowerShell module is available.
    
    .PARAMETER ModuleName
        Name of module to check
    
    .EXAMPLE
        if (Test-ModuleAvailable "ActiveDirectory") { ... }
    
    .OUTPUTS
        [bool] - $true if module available, $false otherwise
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ModuleName
    )
    
    $module = Get-Module -ListAvailable -Name $ModuleName -ErrorAction SilentlyContinue
    return ($null -ne $module)
}

################################################################################
# AD DISCOVERY FUNCTIONS
################################################################################

function Get-DomainInfo {
    <#
    .SYNOPSIS
        Discover current domain information.
    
    .EXAMPLE
        $domain = Get-DomainInfo
        Write-Host "Domain: $($domain.Name)"
    
    .OUTPUTS
        PSCustomObject with domain information
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-ScriptLog "Discovering domain information..." -Level Info
        
        $adDomain = Get-ADDomain -Current LocalComputer -ErrorAction Stop
        
        $domainInfo = [PSCustomObject]@{
            Name = $adDomain.Name
            DNSRoot = $adDomain.DNSRoot
            DistinguishedName = $adDomain.DistinguishedName
            NetBIOSName = $adDomain.NetBIOSName
            DomainMode = $adDomain.DomainMode
            DomainControllers = @($adDomain.ReplicaDirectoryServers)
        }
        
        Write-ScriptLog "Domain: $($domainInfo.Name) - DNSRoot: $($domainInfo.DNSRoot)" -Level Success
        
        return $domainInfo
    }
    catch {
        Write-ScriptLog "Failed to discover domain information: $_" -Level Error
        throw
    }
}

function Get-ADDomainControllers {
    <#
    .SYNOPSIS
        Get list of domain controllers in current domain.
    
    .EXAMPLE
        $dcs = Get-ADDomainControllers
        foreach ($dc in $dcs) { Write-Host $dc.HostName }
    
    .OUTPUTS
        Array of PSCustomObject with DC information
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-ScriptLog "Discovering domain controllers..." -Level Info
        
        $dcs = @(Get-ADDomainController -Discover -ErrorAction Stop | Sort-Object -Property HostName)
        
        if ($dcs.Count -gt 0) {
            Write-ScriptLog "Found $($dcs.Count) domain controller(s)" -Level Success
            foreach ($dc in $dcs) {
                Write-ScriptLog "  - $($dc.HostName)" -Level Info
            }
            return $dcs
        }
        else {
            Write-ScriptLog "No domain controllers found" -Level Error
            throw "No domain controllers discovered"
        }
    }
    catch {
        Write-ScriptLog "Failed to discover domain controllers: $_" -Level Error
        throw
    }
}

function Get-ForestInfo {
    <#
    .SYNOPSIS
        Discover current forest information.
    
    .EXAMPLE
        $forest = Get-ForestInfo
        Write-Host "Forest: $($forest.Name)"
    
    .OUTPUTS
        PSCustomObject with forest information
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-ScriptLog "Discovering forest information..." -Level Info
        
        $adForest = Get-ADForest -Current LocalComputer -ErrorAction Stop
        
        $forestInfo = [PSCustomObject]@{
            Name = $adForest.Name
            RootDomain = $adForest.RootDomain
            Domains = @($adForest.Domains)
            DomainCount = $adForest.Domains.Count
            ForestMode = $adForest.ForestMode
        }
        
        Write-ScriptLog "Forest: $($forestInfo.Name) (Root: $($forestInfo.RootDomain))" -Level Success
        
        return $forestInfo
    }
    catch {
        Write-ScriptLog "Failed to discover forest information: $_" -Level Error
        throw
    }
}

################################################################################
# DSP CONNECTIVITY FUNCTIONS
################################################################################

function Find-DspServer {
    <#
    .SYNOPSIS
        Find DSP Management Server via config, SCP, or manual discovery.
    
    .PARAMETER DomainInfo
        Domain information object from Get-DomainInfo
    
    .PARAMETER ConfigServer
        DSP server from config file (optional, takes priority)
    
    .EXAMPLE
        $dspServer = Find-DspServer -DomainInfo $domainInfo -ConfigServer "dsp.domain.com"
        if ($dspServer) { Write-Host "DSP Server: $dspServer" }
    
    .OUTPUTS
        [string] - FQDN of DSP server, or $null if not found
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$DomainInfo,
        
        [Parameter(Mandatory=$false)]
        [string]$ConfigServer
    )
    
    # If DSP server is set in config, use it first
    if ($ConfigServer) {
        Write-ScriptLog "Using DSP server from configuration: $ConfigServer" -Level Info
        return $ConfigServer
    }
    
    # Otherwise, search for DSP SCP
    try {
        Write-ScriptLog "Searching for DSP Service Connection Point..." -Level Info
        
        $dn = $DomainInfo.DistinguishedName
        $searchBase = "CN=Services,CN=Configuration,$dn"
        
        # Search for DSP SCP
        $scp = Get-ADObject -SearchBase $searchBase `
                           -Filter "(objectClass=serviceConnectionPoint) -and (cn=*Semperis.Dsp.Management*)" `
                           -Properties serviceBindingInformation `
                           -ErrorAction SilentlyContinue
        
        if ($scp) {
            $dspServer = $scp.serviceBindingInformation[0]
            Write-ScriptLog "Found DSP server via SCP: $dspServer" -Level Success
            return $dspServer
        }
        else {
            Write-ScriptLog "DSP Service Connection Point not found" -Level Warning
            return $null
        }
    }
    catch {
        Write-ScriptLog "Failed to search for DSP server: $_" -Level Warning
        return $null
    }
}

function Test-DspModule {
    <#
    .SYNOPSIS
        Test if DSP PowerShell module is installed.
    
    .OUTPUTS
        [bool] - $true if module available, $false otherwise
    #>
    [CmdletBinding()]
    param()
    
    try {
        $module = Get-Module -ListAvailable -Name "Semperis.PoSh.DSP" -ErrorAction SilentlyContinue
        
        if ($module) {
            Write-ScriptLog "DSP PowerShell module is available" -Level Info
            return $true
        }
        else {
            Write-ScriptLog "DSP PowerShell module not found" -Level Warning
            return $false
        }
    }
    catch {
        Write-ScriptLog "Failed to check for DSP module: $_" -Level Warning
        return $false
    }
}

function Connect-DspManagementServer {
    <#
    .SYNOPSIS
        Connect to DSP Management Server with retry logic.
    
    .PARAMETER DspServer
        FQDN of DSP server
    
    .PARAMETER MaxRetries
        Maximum number of connection attempts (default: 3)
    
    .EXAMPLE
        $connection = Connect-DspManagementServer -DspServer "dsp.domain.com"
    
    .OUTPUTS
        [PSCustomObject] - Connection object, or $null on failure
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$DspServer,
        
        [Parameter(Mandatory=$false)]
        [int]$MaxRetries = 3
    )
    
    try {
        Write-ScriptLog "Attempting to connect to DSP server: $DspServer" -Level Info
        
        $retryCount = 0
        $connected = $false
        
        while ($retryCount -lt $MaxRetries -and -not $connected) {
            try {
                $retryCount++
                Write-ScriptLog "Connection attempt $retryCount of $MaxRetries..." -Level Info
                
                # Attempt connection
                $connection = Connect-DspManagement -ServerName $DspServer -ErrorAction Stop
                
                Write-ScriptLog "Connected to DSP server: $DspServer" -Level Success
                return $connection
            }
            catch {
                if ($retryCount -lt $MaxRetries) {
                    Write-ScriptLog "Connection failed, retrying in 5 seconds..." -Level Warning
                    Start-Sleep -Seconds 5
                }
            }
        }
        
        Write-ScriptLog "Failed to connect to DSP server after $MaxRetries attempts" -Level Warning
        return $null
    }
    catch {
        Write-ScriptLog "Error during DSP connection attempt: $_" -Level Warning
        return $null
    }
}

################################################################################
# EXPORT FUNCTIONS
################################################################################

Export-ModuleMember -Function @(
    'Write-ScriptLog',
    'Write-LogHeader',
    'Test-AdminRights',
    'Test-ModuleAvailable',
    'Get-DomainInfo',
    'Get-ADDomainControllers',
    'Get-ForestInfo',
    'Find-DspServer',
    'Test-DspModule',
    'Connect-DspManagementServer'
)