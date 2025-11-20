################################################################################
##
## DSP-Demo-MainScript.ps1
##
## Main orchestration script for DSP demo activity generation
## 
## Features:
## - Runs Preflight module for environment discovery and setup
## - Displays configuration summary (what will be created/modified)
## - 15-second confirmation timeout before execution
## - Executes all configured activities
## - Comprehensive logging and error handling
##
## Author: Rob Ingenthron (Original), Bob Lyons (Refactor)
## Version: 4.5.0-20251120
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory
#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath,
    
    [Parameter(Mandatory=$false)]
    [string]$LogPath
)

$ErrorActionPreference = "Continue"

################################################################################
# INITIALIZATION
################################################################################

$Script:ScriptPath = $PSScriptRoot
$Script:ModulesPath = Join-Path $ScriptPath "modules"
$Script:ConfigFile = if ($ConfigPath) { 
    $ConfigPath 
} 
else { 
    $defaultPath = Join-Path $ScriptPath "DSP-Demo-Config.psd1"
    if (Test-Path $defaultPath) { $defaultPath }
    else { Join-Path $ScriptPath "DSP-Demo-Config.psd1" }
}

################################################################################
# COLORS AND FORMATTING
################################################################################

$Colors = @{
    Header = 'Cyan'
    Section = 'Green'
    Success = 'Green'
    Warning = 'Yellow'
    Error = 'Red'
    Info = 'White'
    Menu = 'Cyan'
    MenuHighlight = 'Yellow'
    Prompt = 'Magenta'
}

################################################################################
# HELPER FUNCTIONS
################################################################################

function Write-Status {
    param(
        [string]$Message,
        [ValidateSet('Info','Success','Warning','Error')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = $Colors[$Level]
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor $Colors.Header
    Write-Host $Title -ForegroundColor $Colors.Header
    Write-Host ("=" * 80) -ForegroundColor $Colors.Header
    Write-Host ""
}

function Load-Configuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ConfigFile
    )
    
    if (-not (Test-Path $ConfigFile)) {
        Write-Status "Configuration file not found: $ConfigFile" -Level Error
        throw "Missing configuration file"
    }
    
    $config = Import-PowerShellDataFile -Path $ConfigFile
    return $config
}

function Import-DemoModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ModuleName
    )
    
    $modulePath = Join-Path $Script:ModulesPath "$ModuleName.psm1"
    
    if (-not (Test-Path $modulePath)) {
        Write-Status "Module not found: $modulePath" -Level Error
        return $false
    }
    
    try {
        Import-Module -Name $modulePath -Force -ErrorAction Stop | Out-Null
        Write-Status "Imported: $ModuleName" -Level Success
        return $true
    }
    catch {
        Write-Status "Failed to import $ModuleName : $_" -Level Error
        return $false
    }
}

function Get-DomainInfo {
    [CmdletBinding()]
    param()
    
    try {
        $domain = Get-ADDomain -ErrorAction Stop
        
        return [PSCustomObject]@{
            FQDN = $domain.DNSRoot
            DNSRoot = $domain.DNSRoot
            DistinguishedName = $domain.DistinguishedName
            NetBIOSName = $domain.NetBIOSName
            DomainSID = $domain.DomainSID
            Forest = $domain.Forest
        }
    }
    catch {
        Write-Status "Failed to get domain info: $_" -Level Error
        throw $_
    }
}

function Get-ADDomainControllers {
    [CmdletBinding()]
    param()
    
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
    [CmdletBinding()]
    param()
    
    try {
        $forest = Get-ADForest -ErrorAction Stop
        
        return [PSCustomObject]@{
            RootDomain = $forest.RootDomain
            ForestMode = $forest.ForestMode
            Domains = $forest.Domains
            DomainCount = $forest.Domains.Count
        }
    }
    catch {
        Write-Status "Failed to get forest info: $_" -Level Error
        throw $_
    }
}

function Expand-ConfigPlaceholders {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$DomainInfo
    )
    
    Write-Status "Expanding config placeholders..." -Level Info
    
    $replacements = @{
        '{DOMAIN_DN}'        = $DomainInfo.DistinguishedName
        '{DOMAIN}'           = if ($DomainInfo.FQDN) { $DomainInfo.FQDN } else { $DomainInfo.DNSRoot }
        '{DOMAIN_NETBIOS}'   = $DomainInfo.NetBIOSName
        '{NETBIOS}'          = $DomainInfo.NetBIOSName
        '{PASSWORD}'         = if ($Config.General -and $Config.General.DefaultPassword) { $Config.General.DefaultPassword } else { "P@ssw0rd123!" }
        '{COMPANY}'          = if ($Config.General -and $Config.General.Company) { $Config.General.Company } else { "Semperis" }
    }
    
    function Expand-Placeholders {
        param($Object)
        
        if ($Object -is [hashtable]) {
            $result = @{}
            foreach ($key in $Object.Keys) {
                $result[$key] = Expand-Placeholders $Object[$key]
            }
            return $result
        }
        elseif ($Object -is [array]) {
            return @($Object | ForEach-Object { Expand-Placeholders $_ })
        }
        elseif ($Object -is [string]) {
            $expanded = $Object
            foreach ($placeholder in $replacements.Keys) {
                $expanded = $expanded -replace [regex]::Escape($placeholder), $replacements[$placeholder]
            }
            return $expanded
        }
        else {
            return $Object
        }
    }
    
    $expanded = Expand-Placeholders $Config
    Write-Status "Placeholder expansion complete" -Level Success
    return $expanded
}

function Run-ActivityModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ModuleName,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$DomainInfo
    )
    
    Write-Status "Executing: $ModuleName" -Level Info
    
    try {
        if (Get-Command Invoke-DemoActivity -ErrorAction SilentlyContinue) {
            Invoke-DemoActivity -Config $Config -DomainInfo $DomainInfo
            Write-Status "$ModuleName completed successfully" -Level Success
            return $true
        }
        else {
            Write-Status "Module function not found: Invoke-DemoActivity" -Level Error
            return $false
        }
    }
    catch {
        Write-Status "Error in $ModuleName : $_" -Level Error
        return $false
    }
}

################################################################################
# MAIN FUNCTION
################################################################################

function Main {
    Write-Header "DSP Demo Activity Generation Suite"
    
    # Load configuration
    Write-Status "Loading configuration..." -Level Info
    $config = Load-Configuration -ConfigFile $Script:ConfigFile
    Write-Status "Configuration loaded" -Level Success
    
    Write-Host ""
    
    Write-Header "Discovering Environment"
    
    try {
        $Script:DomainInfo = Get-DomainInfo
        $dcs = Get-ADDomainControllers
        
        if ($dcs -is [array]) {
            $Script:PrimaryDC = $dcs[0].HostName
            $Script:SecondaryDC = if ($dcs.Count -gt 1) { $dcs[1].HostName } else { $null }
        }
        else {
            $Script:PrimaryDC = $dcs.HostName
            $Script:SecondaryDC = $null
        }
        
        $Script:ForestInfo = Get-ForestInfo
        
        Write-Status "Primary DC: $($Script:PrimaryDC)" -Level Info
        if ($Script:SecondaryDC) {
            Write-Status "Secondary DC: $($Script:SecondaryDC)" -Level Info
        }
    }
    catch {
        Write-Status "FATAL: Failed to discover environment: $_" -Level Error
        exit 1
    }
    
    Write-Header "DSP Server Discovery"
    
    $dspServerFromConfig = if ($config -and $config.General -and $config.General.DspServer) { $config.General.DspServer } else { "" }
    
    $Script:DspAvailable = $false
    $Script:DspConnection = $null
    
    Write-Status "Checking for DSP server..." -Level Info
    try {
        if (Get-Command Find-DspServer -ErrorAction SilentlyContinue) {
            $dspServer = Find-DspServer -DomainInfo $Script:DomainInfo -ConfigServer $dspServerFromConfig -ErrorAction SilentlyContinue
            
            if ($dspServer) {
                $Script:DspAvailable = $true
                Write-Status "DSP Server found: $dspServer" -Level Success
            }
            else {
                Write-Status "DSP Server not found, continuing without DSP integration" -Level Warning
            }
        }
        else {
            Write-Status "DSP module not available, continuing without DSP integration" -Level Warning
        }
    }
    catch {
        Write-Status "DSP discovery failed, continuing without DSP integration" -Level Warning
    }
    
    Write-Host ""
    
    # Expand placeholders in config
    $config = Expand-ConfigPlaceholders -Config $config -DomainInfo $Script:DomainInfo
    
    Write-Header "Loading Activity Modules"
    
    $modulesToImport = @(
        "DSP-Demo-01-Directory"
    )
    
    foreach ($moduleName in $modulesToImport) {
        if (-not (Import-DemoModule $moduleName)) {
            Write-Status "Warning: Failed to import $moduleName" -Level Warning
        }
    }
    
    Write-Host ""
    
    Write-Header "Activity Configuration Summary"
    
    # Display what will be created/modified based on config
    if ($config.General) {
        Write-Host "General Settings:" -ForegroundColor $Colors.Section
        Write-Host "  DSP Server: $(if ($config.General.DspServer) { $config.General.DspServer } else { 'Auto-discover' })" -ForegroundColor $Colors.Info
        Write-Host "  Loop Count: $($config.General.LoopCount)" -ForegroundColor $Colors.Info
        Write-Host "  Generic Test Users: $($config.General.GenericUserCount)" -ForegroundColor $Colors.Info
        Write-Host "  Company: $($config.General.Company)" -ForegroundColor $Colors.Info
        Write-Host ""
    }
    
    if ($config.OUs) {
        Write-Host "Organizational Units to Create:" -ForegroundColor $Colors.Section
        foreach ($ou in $config.OUs.Keys) {
            Write-Host "  - $($config.OUs[$ou].Name)" -ForegroundColor $Colors.Info
        }
        Write-Host ""
    }
    
    if ($config.DemoUsers) {
        Write-Host "Demo User Accounts to Create:" -ForegroundColor $Colors.Section
        foreach ($user in $config.DemoUsers.Keys) {
            Write-Host "  - $($config.DemoUsers[$user].Name) ($($config.DemoUsers[$user].SamAccountName))" -ForegroundColor $Colors.Info
        }
        Write-Host ""
    }
    
    if ($config.DNS) {
        Write-Host "DNS Configuration:" -ForegroundColor $Colors.Section
        Write-Host "  - Zone: $($config.DNS.ForwardZone.Name)" -ForegroundColor $Colors.Info
        Write-Host "  - Records to Create: $($config.DNS.ForwardZone.Records.Count)" -ForegroundColor $Colors.Info
        Write-Host ""
    }
    
    if ($config.GPOs) {
        Write-Host "Group Policy Objects:" -ForegroundColor $Colors.Section
        foreach ($gpo in $config.GPOs.Keys) {
            if ($gpo -ne "DefaultDomainPolicy") {
                Write-Host "  - $($config.GPOs[$gpo].Name)" -ForegroundColor $Colors.Info
            }
        }
        if ($config.GPOs.DefaultDomainPolicy) {
            Write-Host "  - Default Domain Policy (modifications)" -ForegroundColor $Colors.Info
        }
        Write-Host ""
    }
    
    if ($config.Sites) {
        Write-Host "AD Sites and Services:" -ForegroundColor $Colors.Section
        foreach ($site in $config.Sites.Keys) {
            Write-Host "  - $($config.Sites[$site].Name)" -ForegroundColor $Colors.Info
        }
        Write-Host ""
    }
    
    if ($config.FGPPs) {
        Write-Host "Fine-Grained Password Policies:" -ForegroundColor $Colors.Section
        foreach ($fgpp in $config.FGPPs.Keys) {
            Write-Host "  - $($config.FGPPs[$fgpp].Name)" -ForegroundColor $Colors.Info
        }
        Write-Host ""
    }
    
    if ($config.WMIFilters) {
        Write-Host "WMI Filters:" -ForegroundColor $Colors.Section
        Write-Host "  - Count: $($config.WMIFilters.Count)" -ForegroundColor $Colors.Info
        Write-Host ""
    }
    
    # 15-second confirmation timeout
    Write-Header "Confirmation Required"
    Write-Host "Press " -ForegroundColor $Colors.Prompt -NoNewline
    Write-Host "Y" -ForegroundColor $Colors.MenuHighlight -NoNewline
    Write-Host " to proceed, " -ForegroundColor $Colors.Prompt -NoNewline
    Write-Host "N" -ForegroundColor $Colors.MenuHighlight -NoNewline
    Write-Host " to cancel" -ForegroundColor $Colors.Prompt
    Write-Host "(Automatically proceeding in 15 seconds...)" -ForegroundColor $Colors.Warning
    Write-Host ""
    
    $confirmationTimer = 0
    $timeoutSeconds = 15
    $proceed = $null
    
    while ($confirmationTimer -lt $timeoutSeconds) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true).KeyChar
            if ($key -eq 'Y' -or $key -eq 'y') {
                $proceed = $true
                break
            }
            elseif ($key -eq 'N' -or $key -eq 'n') {
                $proceed = $false
                break
            }
        }
        
        $remaining = $timeoutSeconds - $confirmationTimer
        Write-Host "`rProceeding automatically in $remaining seconds..." -ForegroundColor $Colors.Warning -NoNewline
        Start-Sleep -Seconds 1
        $confirmationTimer++
    }
    
    # If timeout was reached, proceed = $true (already confirmed by display message)
    if ($null -eq $proceed) {
        $proceed = $true
    }
    
    if (-not $proceed) {
        Write-Host ""
        Write-Status "Execution cancelled by user" -Level Warning
        exit 0
    }
    
    Write-Host ""
    Write-Host ""
    
    Write-Header "Executing Activity Generation"
    
    # Execute all configured activities
    if (-not (Run-ActivityModule -ModuleName "DSP-Demo-01-Directory" -Config $config -DomainInfo $Script:DomainInfo)) {
        Write-Status "Activity generation completed with errors" -Level Warning
    }
    else {
        Write-Status "Demo activity generation completed successfully" -Level Success
    }
    
    Write-Host ""
}

# Execute main function
Main