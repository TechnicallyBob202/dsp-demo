################################################################################
##
## DSP-Demo-MainScript.ps1
##
## Main orchestration script for DSP demo activity generation
## 
## Features:
## - Calls Preflight module for ALL environment discovery and setup
## - Displays configuration summary
## - 15-second confirmation timeout before execution
## - Executes all configured activities
## - Comprehensive logging and error handling
##
## Author: Rob Ingenthron (Original), Bob Lyons (Refactor)
## Version: 4.5.2-20251120 (Updated summaries)
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

function Expand-ConfigPlaceholders {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$DomainInfo
    )
    
    $placeholders = @{
        '{DOMAIN_DN}' = $DomainInfo.DN
        '{DOMAIN}' = $DomainInfo.FQDN
        '{PASSWORD}' = if ($Config.General.DefaultPassword) { $Config.General.DefaultPassword } else { "P@ssw0rd123!" }
        '{COMPANY}' = if ($Config.General.Company) { $Config.General.Company } else { "Semperis" }
    }
    
    foreach ($key in $placeholders.Keys) {
        foreach ($section in @($Config.Keys)) {
            if ($Config[$section] -is [hashtable]) {
                foreach ($prop in @($Config[$section].Keys)) {
                    if ($Config[$section][$prop] -is [string]) {
                        $Config[$section][$prop] = $Config[$section][$prop] -replace [regex]::Escape($key), $placeholders[$key]
                    }
                }
            }
        }
    }
    
    return $Config
}

################################################################################
# MAIN FUNCTION
################################################################################

function Main {
    Write-Header "DSP Demo Activity Generation Suite"
    
    Write-Status "Script path: $Script:ScriptPath" -Level Info
    Write-Status "Config file: $Script:ConfigFile" -Level Info
    
    if (-not (Test-Path $Script:ModulesPath)) {
        Write-Status "Creating modules directory..." -Level Info
        New-Item -ItemType Directory -Path $Script:ModulesPath -Force | Out-Null
    }
    
    # Load configuration
    Write-Status "Loading configuration..." -Level Info
    $config = Load-Configuration -ConfigFile $Script:ConfigFile
    Write-Status "Configuration loaded" -Level Success
    
    Write-Host ""
    
    # Import Preflight module
    if (-not (Import-DemoModule "DSP-Demo-Preflight")) {
        Write-Status "FATAL: Failed to import Preflight module" -Level Error
        exit 1
    }
    
    Write-Host ""
    
    # RUN ALL PREFLIGHT CHECKS AND ENVIRONMENT DISCOVERY IN ONE CALL
    $environment = Initialize-PreflightEnvironment -Config $config
    
    Write-Host ""
    
    # Expand placeholders in config using discovered environment
    $config = Expand-ConfigPlaceholders -Config $config -DomainInfo $environment.DomainInfo
    
    Write-Header "Loading Setup Modules"
    
    $modulesToImport = @(
        "DSP-Demo-01-Setup-BuildOUs",
        "DSP-Demo-02-Setup-CreateGroups",
        "DSP-Demo-03-Setup-CreateUsers",
        "DSP-Demo-04-Setup-CreateComputers",
        "DSP-Demo-05-Setup-CreateDefaultDomainPolicy",
        "DSP-Demo-06-Setup-CreateFGPP",
        "DSP-Demo-07-Setup-CreateADSitesAndSubnets",
        "DSP-Demo-08-Setup-CreateDNSZones",
        "DSP-Demo-09-Setup-CreateGPOs"
    )
    
    foreach ($moduleName in $modulesToImport) {
        if (-not (Import-DemoModule $moduleName)) {
            Write-Status "Warning: Failed to import $moduleName" -Level Warning
        }
    }
    
    Write-Host ""
    
    Write-Header "Loading Activity Modules"
    Write-Host "(Placeholder for future activity modules)" -ForegroundColor $Colors.Info
    Write-Host ""
    
    Write-Header "Active Directory Baseline Configuration Summary"
    
    # Display what will be created/modified based on config
    if ($config.General) {
        Write-Host "General Settings:" -ForegroundColor $Colors.Section
        Write-Host "  DSP Server: $(if ($environment.DspAvailable) { $environment.DspServer } else { 'Not available' })" -ForegroundColor $Colors.Info
        Write-Host "  Loop Count: $($config.General.LoopCount)" -ForegroundColor $Colors.Info
        Write-Host "  Generic Test Users: $($config.General.GenericUserCount)" -ForegroundColor $Colors.Info
        Write-Host "  Company: $($config.General.Company)" -ForegroundColor $Colors.Info
        Write-Host ""
    }
    
    # OUs Section
    if ($config.ContainsKey('OUs') -and $config.OUs) {
        Write-Host "Organizational Units to Create:" -ForegroundColor $Colors.Section
        foreach ($ouKey in $config.OUs.Keys) {
            $ou = $config.OUs[$ouKey]
            $description = if ($ou.ContainsKey('Description')) { " - $($ou.Description)" } else { "" }
            Write-Host "  - $($ou.Name)$description" -ForegroundColor $Colors.Info
        }
        Write-Host ""
    }
    
    # Groups Section
    if ($config.ContainsKey('Groups') -and $config.Groups) {
        Write-Host "Security Groups to Create:" -ForegroundColor $Colors.Section
        $labUserGroupCount = if ($config.Groups.ContainsKey('LabUserGroups')) { @($config.Groups.LabUserGroups).Count } else { 0 }
        $adminGroupCount = if ($config.Groups.ContainsKey('AdminGroups')) { @($config.Groups.AdminGroups).Count } else { 0 }
        $deleteMeGroupCount = if ($config.Groups.ContainsKey('DeleteMeOUGroups')) { @($config.Groups.DeleteMeOUGroups).Count } else { 0 }
        $totalGroups = $labUserGroupCount + $adminGroupCount + $deleteMeGroupCount
        
        Write-Host "  Lab User Groups: $labUserGroupCount" -ForegroundColor $Colors.Info
        Write-Host "  Admin Groups: $adminGroupCount" -ForegroundColor $Colors.Info
        Write-Host "  DeleteMe OU Groups: $deleteMeGroupCount" -ForegroundColor $Colors.Info
        Write-Host "  Total Groups: $totalGroups" -ForegroundColor $Colors.Info
        Write-Host ""
    }
    
    # Users Section
    if ($config.ContainsKey('Users') -and $config.Users) {
        Write-Host "User Accounts to Create:" -ForegroundColor $Colors.Section
        $tier0Count = if ($config.Users.ContainsKey('Tier0Admins')) { @($config.Users.Tier0Admins).Count } else { 0 }
        $tier1Count = if ($config.Users.ContainsKey('Tier1Admins')) { @($config.Users.Tier1Admins).Count } else { 0 }
        $tier2Count = if ($config.Users.ContainsKey('Tier2Admins')) { @($config.Users.Tier2Admins).Count } else { 0 }
        $demoUserCount = if ($config.Users.ContainsKey('DemoUsers')) { @($config.Users.DemoUsers).Count } else { 0 }
        $genericUserCount = $config.General.GenericUserCount
        $totalUsers = $tier0Count + $tier1Count + $tier2Count + $demoUserCount + $genericUserCount
        
        Write-Host "  Tier 0 Admins: $tier0Count" -ForegroundColor $Colors.Info
        Write-Host "  Tier 1 Admins: $tier1Count" -ForegroundColor $Colors.Info
        Write-Host "  Tier 2 Admins: $tier2Count" -ForegroundColor $Colors.Info
        Write-Host "  Demo Users: $demoUserCount" -ForegroundColor $Colors.Info
        Write-Host "  Generic Bulk Users: $genericUserCount" -ForegroundColor $Colors.Info
        Write-Host "  Total Users: $totalUsers" -ForegroundColor $Colors.Info
        Write-Host ""
    }
    
    # Computers Section
    if ($config.ContainsKey('Computers') -and $config.Computers) {
        Write-Host "Computer Objects to Create:" -ForegroundColor $Colors.Section
        foreach ($computer in $config.Computers) {
            Write-Host "  - $($computer.Name)" -ForegroundColor $Colors.Info
        }
        Write-Host ""
    }
    
    # Default Domain Policy Section
    if ($config.ContainsKey('DefaultDomainPolicy') -and $config.DefaultDomainPolicy) {
        Write-Host "Default Domain Policy Settings:" -ForegroundColor $Colors.Section
        $policy = $config.DefaultDomainPolicy
        Write-Host "  Min Password Length: $($policy.MinPasswordLength) characters" -ForegroundColor $Colors.Info
        Write-Host "  Password Complexity: $($policy.PasswordComplexity)" -ForegroundColor $Colors.Info
        Write-Host "  Password History Count: $($policy.PasswordHistoryCount)" -ForegroundColor $Colors.Info
        Write-Host "  Max Password Age: $($policy.MaxPasswordAge) days" -ForegroundColor $Colors.Info
        Write-Host "  Min Password Age: $($policy.MinPasswordAge) days" -ForegroundColor $Colors.Info
        Write-Host "  Lockout Threshold: $($policy.LockoutThreshold) attempts" -ForegroundColor $Colors.Info
        Write-Host "  Lockout Duration: $($policy.LockoutDuration) minutes" -ForegroundColor $Colors.Info
        Write-Host "  Lockout Observation Window: $($policy.LockoutObservationWindow) minutes" -ForegroundColor $Colors.Info
        Write-Host "  Reversible Encryption: $($policy.ReversibleEncryption)" -ForegroundColor $Colors.Info
        Write-Host ""
    }
    
    # FGPPs Section
    if ($config.ContainsKey('FGPPs') -and $config.FGPPs) {
        Write-Host "Fine-Grained Password Policies to Create:" -ForegroundColor $Colors.Section
        foreach ($fgpp in $config.FGPPs) {
            Write-Host "  - $($fgpp.Name) (Precedence: $($fgpp.Precedence))" -ForegroundColor $Colors.Info
        }
        Write-Host ""
    }
    
    # AD Sites and Subnets Section
    if ($config.ContainsKey('AdSites') -and $config.AdSites) {
        Write-Host "Active Directory Sites to Create:" -ForegroundColor $Colors.Section
        foreach ($siteName in $config.AdSites.Keys) {
            $site = $config.AdSites[$siteName]
            Write-Host "  - ${siteName}: $($site.Description)" -ForegroundColor $Colors.Info
        }
        Write-Host ""
    }
    
    if ($config.ContainsKey('AdSubnets') -and $config.AdSubnets) {
        Write-Host "Network Subnets to Create:" -ForegroundColor $Colors.Section
        foreach ($subnetName in $config.AdSubnets.Keys) {
            $subnet = $config.AdSubnets[$subnetName]
            Write-Host "  - $subnetName ($($subnet.Description))" -ForegroundColor $Colors.Info
        }
        Write-Host ""
    }
    
    # DNS Zones Section
    if ($config.ContainsKey('DnsForwardZones') -and $config.DnsForwardZones) {
        Write-Host "DNS Forward Zones to Create:" -ForegroundColor $Colors.Section
        foreach ($zoneName in $config.DnsForwardZones.Keys) {
            $zone = $config.DnsForwardZones[$zoneName]
            Write-Host "  - ${zoneName}: $($zone.Description)" -ForegroundColor $Colors.Info
        }
        Write-Host ""
    }
    
    if ($config.ContainsKey('DnsReverseZones') -and $config.DnsReverseZones) {
        Write-Host "DNS Reverse Zones to Create:" -ForegroundColor $Colors.Section
        foreach ($zoneName in $config.DnsReverseZones.Keys) {
            $zone = $config.DnsReverseZones[$zoneName]
            Write-Host "  - ${zoneName}: $($zone.Description)" -ForegroundColor $Colors.Info
        }
        Write-Host ""
    }
    
    # GPOs Section
    if ($config.ContainsKey('GPOs') -and $config.GPOs) {
        Write-Host "Group Policy Objects to Create:" -ForegroundColor $Colors.Section
        foreach ($gpoName in $config.GPOs.Keys) {
            $gpo = $config.GPOs[$gpoName]
            Write-Host "  - ${gpoName}: $($gpo.Comment)" -ForegroundColor $Colors.Info
        }
        Write-Host ""
    }
    
    Write-Header "Confirmation Required"
    Write-Host "Running this script will create/update all of the objects listed in the Setup section above," -ForegroundColor $Colors.Info
    Write-Host "and then create all of the activity listed in the Activity section." -ForegroundColor $Colors.Info
    Write-Host ""
    Write-Host "Press " -ForegroundColor $Colors.Prompt -NoNewline
    Write-Host "Y" -ForegroundColor $Colors.MenuHighlight -NoNewline
    Write-Host " to proceed, " -ForegroundColor $Colors.Prompt -NoNewline
    Write-Host "N" -ForegroundColor $Colors.MenuHighlight -NoNewline
    Write-Host " to cancel" -ForegroundColor $Colors.Prompt
    Write-Host "(Proceeding automatically in 30 seconds - scroll up to review, or press N to cancel)" -ForegroundColor $Colors.Warning
    Write-Host ""
    
    $confirmationTimer = 0
    $timeoutSeconds = 30
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
        
        Start-Sleep -Seconds 1
        $confirmationTimer++
    }
    
    # If timeout was reached, proceed = $true
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
    
    # Execute all imported modules in sequence
    $completedModules = 0
    $failedModules = 0
    
    foreach ($moduleName in $modulesToImport) {
        # Convert module name to function name
        # DSP-Demo-01-Setup-BuildOUs -> Invoke-BuildOUs
        $functionName = "Invoke-" + ($moduleName -replace "^DSP-Demo-\d+-Setup-", "")
        
        if (Get-Command $functionName -ErrorAction SilentlyContinue) {
            Write-Header "Running $moduleName"
            try {
                & $functionName -Config $config -Environment $environment
                Write-Status "Module completed: $moduleName" -Level Success
                $completedModules++
            }
            catch {
                Write-Status "Error executing $moduleName : $_" -Level Error
                $failedModules++
            }
        }
        else {
            Write-Status "Function $functionName not found - skipping $moduleName" -Level Warning
        }
    }
    
    Write-Host ""
    Write-Header "Execution Summary"
    Write-Host "Modules Completed: $completedModules" -ForegroundColor $Colors.Success
    if ($failedModules -gt 0) {
        Write-Host "Modules Failed: $failedModules" -ForegroundColor $Colors.Error
    }
    
    Write-Status "Demo activity generation completed" -Level Success
    Write-Host ""
}

# Execute main function
Main