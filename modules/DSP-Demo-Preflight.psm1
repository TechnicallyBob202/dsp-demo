################################################################################
##
## DSP-Demo-Preflight.psm1
##
## Preflight module for DSP demo activity generation
## Handles environment discovery, logging, AD discovery, and DSP connectivity
##
## Author: Rob Ingenthron (Original), Bob Lyons (Refactor)
## Version: 1.0.2-20251120
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
        PSCustomObject with domain information including FQDN, DN, NetBIOS
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-ScriptLog "Discovering domain information..." -Level Info
        
        $adDomain = Get-ADDomain -Current LocalComputer -ErrorAction Stop
        
        $domainInfo = [PSCustomObject]@{
            Name = $adDomain.Name
            FQDN = $adDomain.DNSRoot
            DNSRoot = $adDomain.DNSRoot
            DistinguishedName = $adDomain.DistinguishedName
            NetBIOSName = $adDomain.NetBIOSName
            DomainMode = $adDomain.DomainMode
            DomainControllers = @($adDomain.ReplicaDirectoryServers)
        }
        
        Write-ScriptLog "Domain: $($domainInfo.Name) - FQDN: $($domainInfo.FQDN)" -Level Success
        
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

function Get-DNSServer {
    <#
    .SYNOPSIS
        Get primary DNS server FQDN from domain.
    
    .PARAMETER DomainControllerName
        Optional DC name to query (default: uses current domain)
    
    .EXAMPLE
        $dnsServer = Get-DNSServer
        Write-Host "DNS Server: $dnsServer"
    
    .OUTPUTS
        [string] - FQDN of primary DNS server
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$DomainControllerName
    )
    
    try {
        Write-ScriptLog "Discovering DNS server..." -Level Info
        
        if (-not $DomainControllerName) {
            $dc = Get-ADDomainController -Discover -ErrorAction Stop
            $DomainControllerName = $dc.HostName
        }
        
        Write-ScriptLog "Using DNS server: $DomainControllerName" -Level Success
        return $DomainControllerName
    }
    catch {
        Write-ScriptLog "Failed to discover DNS server: $_" -Level Error
        throw
    }
}

function Expand-ConfigPlaceholders {
    <#
    .SYNOPSIS
        Replace placeholder tokens in configuration with actual domain values.
    
    .PARAMETER Config
        Configuration hashtable with {PLACEHOLDER} values
    
    .PARAMETER DomainInfo
        Domain information object from Get-DomainInfo
    
    .EXAMPLE
        $expandedConfig = Expand-ConfigPlaceholders -Config $config -DomainInfo $domainInfo
    
    .OUTPUTS
        [hashtable] - Configuration with all placeholders expanded
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$DomainInfo
    )
    
    $replacements = @{
        '{DOMAIN_DN}'     = $DomainInfo.DistinguishedName
        '{DOMAIN}'        = $DomainInfo.FQDN
        '{NETBIOS}'       = $DomainInfo.NetBIOSName
        '{PASSWORD}'      = if ($Config.General.DefaultPassword) { $Config.General.DefaultPassword } else { "P@ssw0rd123!" }
        '{COMPANY}'       = if ($Config.General.Company) { $Config.General.Company } else { "Semperis" }
    }
    
    function Expand-Object {
        param([object]$Obj)
        
        if ($Obj -is [string]) {
            $result = $Obj
            foreach ($key in $replacements.Keys) {
                $result = $result -replace [regex]::Escape($key), $replacements[$key]
            }
            return $result
        }
        elseif ($Obj -is [hashtable]) {
            $newHash = @{}
            foreach ($hkey in $Obj.Keys) {
                $newHash[$hkey] = Expand-Object $Obj[$hkey]
            }
            return $newHash
        }
        elseif ($Obj -is [array]) {
            return @($Obj | ForEach-Object { Expand-Object $_ })
        }
        else {
            return $Obj
        }
    }
    
    return Expand-Object $Config
}

function Test-ConfigSection {
    <#
    .SYNOPSIS
        Test if a configuration section exists and has content.
    
    .PARAMETER Config
        Configuration hashtable
    
    .PARAMETER SectionPath
        Dot-separated path to section (e.g., "General.DspServer")
    
    .EXAMPLE
        if (Test-ConfigSection -Config $config -SectionPath "General.DspServer") {
            $dspServer = $config.General.DspServer
        }
    
    .OUTPUTS
        [bool] - $true if section exists and contains value, $false otherwise
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [string]$SectionPath
    )
    
    $parts = $SectionPath -split '\.'
    $current = $Config
    
    foreach ($part in $parts) {
        if ($current -is [hashtable] -and $current.ContainsKey($part)) {
            $current = $current[$part]
        }
        else {
            return $false
        }
    }
    
    return ($null -ne $current)
}

################################################################################
# DSP CONNECTIVITY FUNCTIONS
################################################################################

function Find-DspServer {
    <#
    .SYNOPSIS
        Find DSP Management Server via config, SCP, or manual discovery.
    
    .PARAMETER DomainInfo
        Domain information object
    
    .PARAMETER ConfigServer
        Optional DSP server FQDN from config
    
    .EXAMPLE
        $dspServer = Find-DspServer -DomainInfo $domainInfo -ConfigServer "dsp.domain.com"
    
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
    
    try {
        # If configured, use that server
        if ($ConfigServer -and $ConfigServer -ne "") {
            Write-ScriptLog "Using configured DSP server: $ConfigServer" -Level Info
            return $ConfigServer
        }
        
        # Otherwise, attempt SCP discovery
        Write-ScriptLog "Attempting to discover DSP server via SCP..." -Level Info
        
        $scpPath = "LDAP://CN=Semperis DSP,CN=Services,CN=Configuration," + $DomainInfo.DistinguishedName
        $scp = Get-ADObject -LDAPFilter "(cn=Semperis DSP)" -SearchBase "CN=Services,CN=Configuration,$($DomainInfo.DistinguishedName)" -ErrorAction SilentlyContinue
        
        if ($scp) {
            Write-ScriptLog "DSP service connection point found" -Level Success
            return $scp.Name
        }
        else {
            Write-ScriptLog "DSP service connection point not found" -Level Warning
            return $null
        }
    }
    catch {
        Write-ScriptLog "Error during DSP discovery: $_" -Level Warning
        return $null
    }
}

function Connect-DspServer {
    <#
    .SYNOPSIS
        Connect to DSP Server via PowerShell module.
    
    .PARAMETER DspServer
        FQDN of DSP server
    
    .PARAMETER MaxRetries
        Maximum number of connection attempts (default: 3)
    
    .EXAMPLE
        $connection = Connect-DspServer -DspServer "dsp.domain.com"
    
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
        
        # Check if DSP module is available
        if (-not (Test-ModuleAvailable "DspModule")) {
            Write-ScriptLog "DSP PowerShell module not available" -Level Warning
            return $null
        }
        
        $retryCount = 0
        
        while ($retryCount -lt $MaxRetries) {
            try {
                $retryCount++
                Write-ScriptLog "Connection attempt $retryCount of $MaxRetries..." -Level Info
                
                # Attempt connection
                $connection = Connect-DspServer -ComputerName $DspServer -ErrorAction Stop
                
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
    'Get-DNSServer',
    'Expand-ConfigPlaceholders',
    'Test-ConfigSection',
    'Find-DspServer',
    'Connect-DspServer'
)