################################################################################
##
## DSP-Demo-MainScript.ps1
##
## Main orchestration script for DSP demo activity generation
## 
## Features:
## - Calls Preflight module for ALL environment discovery and setup
## - Displays configuration summary
## - 30-second confirmation timeout before execution
## - Executes Setup Phase (create baseline infrastructure)
## - Executes Activity Phase (generate changes for DSP to monitor)
## - Comprehensive logging and error handling
##
## Author: Rob Ingenthron (Original), Bob Lyons (Refactor)
## Version: 4.6.0-20251202
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
    
    # ========================================================================
    # LOAD SETUP MODULES
    # ========================================================================
    
    Write-Header "Loading Setup Modules"
    
    $setupModules = @(
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
    
    foreach ($moduleName in $setupModules) {
        if (-not (Import-DemoModule $moduleName)) {
            Write-Status "Warning: Failed to import $moduleName" -Level Warning
        }
    }
    
    Write-Host ""
    
    # ========================================================================
    # LOAD ACTIVITY MODULES
    # ========================================================================
    
    Write-Header "Loading Activity Modules"
    
    $activityModules = @(
        "DSP-Demo-Activity-01-DirectoryActivity"
    )
    
    foreach ($moduleName in $activityModules) {
        if (-not (Import-DemoModule $moduleName)) {
            Write-Status "Warning: Failed to import $moduleName" -Level Warning
        }
    }
    
    Write-Host ""
    
    # ========================================================================
    # DISPLAY CONFIGURATION SUMMARY
    # ========================================================================
    
    Write-Header "Activity Configuration Summary"
    
    # Display what will be created/modified based on config
    if ($config.General) {
        Write-Host "General Settings:" -ForegroundColor $Colors.Section
        Write-Host "  DSP Server: $(if ($environment.DspAvailable) { $environment.DspServer } else { 'Not available' })" -ForegroundColor $Colors.Info
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
        $count = @($config.DemoUsers.Keys).Count
        Write-Host "  - $count named accounts" -ForegroundColor $Colors.Info
        Write-Host ""
    }
    
    # ========================================================================
    # CONFIRMATION PROMPT
    # ========================================================================
    
    Write-Header "Confirmation Required"
    Write-Host "Press " -ForegroundColor $Colors.Prompt -NoNewline
    Write-Host "Y" -ForegroundColor $Colors.MenuHighlight -NoNewline
    Write-Host " to proceed, " -ForegroundColor $Colors.Prompt -NoNewline
    Write-Host "N" -ForegroundColor $Colors.MenuHighlight -NoNewline
    Write-Host " to cancel" -ForegroundColor $Colors.Prompt
    Write-Host "(Automatically proceeding in 30 seconds...)" -ForegroundColor $Colors.Warning
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
    
    # ========================================================================
    # EXECUTE SETUP PHASE
    # ========================================================================
    
    Write-Header "Executing Setup Phase"
    
    $setupCompleted = 0
    $setupFailed = 0
    
    foreach ($moduleName in $setupModules) {
        # Convert module name to function name
        # DSP-Demo-01-Setup-BuildOUs -> Invoke-BuildOUs
        $functionName = "Invoke-" + ($moduleName -replace "^DSP-Demo-\d+-Setup-", "")
        
        if (Get-Command $functionName -ErrorAction SilentlyContinue) {
            Write-Header "Running $moduleName"
            try {
                & $functionName -Config $config -Environment $environment
                Write-Status "Module completed: $moduleName" -Level Success
                $setupCompleted++
            }
            catch {
                Write-Status "Error executing $moduleName : $_" -Level Error
                $setupFailed++
            }
        }
        else {
            Write-Status "Function $functionName not found - skipping $moduleName" -Level Warning
        }
    }
    
    Write-Host ""
    Write-Host ""
    
    # ========================================================================
    # EXECUTE ACTIVITY PHASE
    # ========================================================================
    
    Write-Header "Executing Activity Phase"
    
    $activityCompleted = 0
    $activityFailed = 0
    
    foreach ($moduleName in $activityModules) {
        # Convert module name to function name
        # DSP-Demo-Activity-01-DirectoryActivity -> Invoke-DirectoryActivity
        $functionName = "Invoke-" + ($moduleName -replace "^DSP-Demo-Activity-\d+-", "")
        
        if (Get-Command $functionName -ErrorAction SilentlyContinue) {
            Write-Header "Running $moduleName"
            try {
                & $functionName -Config $config -Environment $environment
                Write-Status "Module completed: $moduleName" -Level Success
                $activityCompleted++
            }
            catch {
                Write-Status "Error executing $moduleName : $_" -Level Error
                $activityFailed++
            }
        }
        else {
            Write-Status "Function $functionName not found - skipping $moduleName" -Level Warning
        }
    }
    
    # ========================================================================
    # EXECUTION SUMMARY
    # ========================================================================
    
    Write-Host ""
    Write-Header "Execution Summary"
    
    Write-Host "Setup Phase:" -ForegroundColor $Colors.Section
    Write-Host "  Completed: $setupCompleted" -ForegroundColor $Colors.Success
    if ($setupFailed -gt 0) {
        Write-Host "  Failed: $setupFailed" -ForegroundColor $Colors.Error
    }
    
    Write-Host ""
    Write-Host "Activity Phase:" -ForegroundColor $Colors.Section
    Write-Host "  Completed: $activityCompleted" -ForegroundColor $Colors.Success
    if ($activityFailed -gt 0) {
        Write-Host "  Failed: $activityFailed" -ForegroundColor $Colors.Error
    }
    
    Write-Host ""
    $totalCompleted = $setupCompleted + $activityCompleted
    $totalFailed = $setupFailed + $activityFailed
    
    Write-Host "Total:" -ForegroundColor $Colors.Section
    Write-Host "  Modules Completed: $totalCompleted" -ForegroundColor $Colors.Success
    if ($totalFailed -gt 0) {
        Write-Host "  Modules Failed: $totalFailed" -ForegroundColor $Colors.Error
    }
    
    Write-Host ""
    Write-Status "Demo activity generation completed" -Level Success
    Write-Host ""
}

# Execute main function
Main