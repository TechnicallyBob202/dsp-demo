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
## Version: 4.5.1-20251120
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

function Run-ActivityModule {
    param(
        [string]$ModuleName,
        [hashtable]$Config,
        [PSCustomObject]$Environment
    )
    
    Write-Header "Running $ModuleName Module"
    
    try {
        $functionMap = @{
            "Directory" = "Invoke-DirectoryActivity"
            "DNS" = "Invoke-DNSActivity"
            "GPOs" = "Invoke-GPOActivity"
            "Sites" = "Invoke-SitesActivity"
            "SecurityEvents" = "Invoke-SecurityEventsActivity"
        }
        
        $functionName = $functionMap[$ModuleName]
        
        if (Get-Command $functionName -ErrorAction SilentlyContinue) {
            & $functionName -Config $Config -Environment $Environment
            Write-Status "Module completed: $ModuleName" -Level Success
        }
        else {
            Write-Status "Function $functionName not found in module" -Level Error
            return $false
        }
    }
    catch {
        Write-Status "Error executing $ModuleName : $_" -Level Error
        return $false
    }
    
    return $true
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
    
    Write-Header "Loading Activity Modules"
    
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
    
    Write-Header "Confirmation Required"
    Write-Host "Press " -ForegroundColor $Colors.Prompt -NoNewline
    Write-Host "Y" -ForegroundColor $Colors.MenuHighlight -NoNewline
    Write-Host " to proceed, " -ForegroundColor $Colors.Prompt -NoNewline
    Write-Host "N" -ForegroundColor $Colors.MenuHighlight -NoNewline
    Write-Host " to cancel" -ForegroundColor $Colors.Prompt
    Write-Host "(Automatically proceeding in 15 seconds...)" -ForegroundColor $Colors.Warning
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