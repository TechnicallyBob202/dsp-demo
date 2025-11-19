################################################################################
################################################################################
##
## DSP-Demo-MainScript.ps1
##
## Main orchestration script for DSP demo activity generation
## 
## Features:
## - Interactive menu for selecting modules to run
## - Run individual modules or all modules
## - Configuration-driven approach
## - Comprehensive logging and error handling
##
## Author: Rob Ingenthron (Original), Bob Lyons (Refactor)
## Version: 4.1.0-20251119
##
################################################################################
################################################################################

<#
.SYNOPSIS
    DSP Demo Activity Generation Script - Main Orchestrator

.DESCRIPTION
    Automatically generates AD activities such as users, groups, DNS, GPOs, FGPP, 
    and changes to objects and ACLs. This refactored version uses a modular approach
    allowing you to run individual modules or all modules at once.

.PARAMETER SkipMenu
    Skip the interactive menu and run all modules automatically

.PARAMETER ConfigPath
    Path to external configuration file (optional)

.PARAMETER LogPath
    Custom log file path

.PARAMETER Module
    Specific module to run (can be used to skip menu)

.EXAMPLE
    .\DSP-Demo-MainScript.ps1
    # Opens interactive menu to select modules

.EXAMPLE
    .\DSP-Demo-MainScript.ps1 -Module Users
    # Runs only the Users module

.EXAMPLE
    .\DSP-Demo-MainScript.ps1 -SkipMenu
    # Runs all modules without showing menu

.NOTES
    Author     : Rob Ingenthron (Original), Bob Lyons (Refactor)
    Version    : 4.1.0-20251119
    
    Available Modules:
    - Core (environment discovery, logging setup)
    - Users (create/modify demo users)
    - Groups (create/modify demo groups)
    - OUs (create organizational units)
    - DNS (create/modify DNS records)
    - GPOs (create/modify group policies)
    - Sites (create/modify AD sites)
    - Security (ACLs, permissions)
    - Changes (generate various AD changes)
    - Cleanup (remove demo objects)
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$SkipMenu,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('Core','Users','Groups','OUs','DNS','GPOs','Sites','Security','Changes','Cleanup','All')]
    [string]$Module,
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath,
    
    [Parameter(Mandatory=$false)]
    [string]$LogPath
)

#Requires -Version 5.1
#Requires -Modules ActiveDirectory
#Requires -RunAsAdministrator

$ErrorActionPreference = "Continue"

################################################################################
# INITIALIZATION
################################################################################

$Script:ScriptVersion = "4.1.0-20251119"
$Script:ScriptPath = $PSScriptRoot
$Script:ModulesPath = Join-Path $ScriptPath "modules"
$Script:ConfigFile = if ($ConfigPath) { $ConfigPath } else { Join-Path $ScriptPath "DSP-Demo-Config.psd1" }

################################################################################
# COLOR AND FORMATTING
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
}

################################################################################
# HELPER FUNCTIONS
################################################################################

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor $Colors.Header
    Write-Host $Title -ForegroundColor $Colors.Header
    Write-Host ("=" * 80) -ForegroundColor $Colors.Header
    Write-Host ""
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host ">> $Title" -ForegroundColor $Colors.Section
    Write-Host ("-" * 80) -ForegroundColor $Colors.Section
}

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

function Test-ModuleAvailable {
    param([string]$ModuleName)
    
    $modulePath = Join-Path $ModulesPath "$ModuleName.psm1"
    return (Test-Path $modulePath -PathType Leaf)
}

function Import-RequiredModule {
    param([string]$ModuleName)
    
    try {
        $modulePath = Join-Path $ModulesPath "$ModuleName.psm1"
        
        if (-not (Test-Path $modulePath)) {
            Write-Status "Module file not found: $modulePath" -Level Error
            return $false
        }
        
        Import-Module $modulePath -Force -ErrorAction Stop
        Write-Status "Module imported: $ModuleName" -Level Success
        return $true
    }
    catch {
        Write-Status "Failed to import module $ModuleName : $_" -Level Error
        return $false
    }
}

function Show-MainMenu {
    Write-Header "DSP DEMO - MODULE SELECTION"
    
    Write-Host "Available Modules:" -ForegroundColor $Colors.Menu
    Write-Host ""
    Write-Host "  1. [Core]      - Environment discovery, setup, and logging" -ForegroundColor $Colors.Menu
    Write-Host "  2. [Users]     - Create and modify demo user accounts" -ForegroundColor $Colors.Menu
    Write-Host "  3. [Groups]    - Create and manage demo groups" -ForegroundColor $Colors.Menu
    Write-Host "  4. [OUs]       - Create organizational units" -ForegroundColor $Colors.Menu
    Write-Host "  5. [DNS]       - Create and modify DNS records" -ForegroundColor $Colors.Menu
    Write-Host "  6. [GPOs]      - Create and modify group policies" -ForegroundColor $Colors.Menu
    Write-Host "  7. [Sites]     - Create AD sites and subnets" -ForegroundColor $Colors.Menu
    Write-Host "  8. [Security]  - Configure ACLs and permissions" -ForegroundColor $Colors.Menu
    Write-Host "  9. [Changes]   - Generate various AD changes for DSP tracking" -ForegroundColor $Colors.Menu
    Write-Host " 10. [Cleanup]   - Remove all demo objects" -ForegroundColor $Colors.Menu
    Write-Host " 11. [All]      - Run all modules in sequence" -ForegroundColor $Colors.MenuHighlight
    Write-Host " 12. [Exit]     - Exit without running any modules" -ForegroundColor $Colors.Warning
    Write-Host ""
}

function Get-MenuSelection {
    do {
        Write-Host "Select modules to run (comma-separated, e.g. 1,3,5 or 11 for all): " -ForegroundColor $Colors.MenuHighlight -NoNewline
        $selection = Read-Host
        
        if ($selection -eq "12") {
            return $null
        }
        
        if ($selection -eq "11") {
            return @("Core", "Users", "Groups", "OUs", "DNS", "GPOs", "Sites", "Security", "Changes")
        }
        
        $validSelection = $true
        $selectedModules = @()
        
        $moduleMap = @{
            "1" = "Core"
            "2" = "Users"
            "3" = "Groups"
            "4" = "OUs"
            "5" = "DNS"
            "6" = "GPOs"
            "7" = "Sites"
            "8" = "Security"
            "9" = "Changes"
            "10" = "Cleanup"
        }
        
        foreach ($item in $selection -split ',') {
            $item = $item.Trim()
            if ($moduleMap.ContainsKey($item)) {
                $selectedModules += $moduleMap[$item]
            }
            elseif ($item) {
                Write-Status "Invalid selection: $item" -Level Warning
                $validSelection = $false
                break
            }
        }
        
        if ($validSelection -and $selectedModules.Count -gt 0) {
            return $selectedModules
        }
        else {
            Write-Status "Please enter valid selections" -Level Warning
            Write-Host ""
        }
    } while ($true)
}

function Execute-Module {
    param(
        [string]$ModuleName,
        [hashtable]$Config
    )
    
    Write-Header "EXECUTING MODULE: $ModuleName"
    
    # Check if module-specific function exists
    $functionName = "Invoke-$ModuleName`Activity"
    
    if (Get-Command $functionName -ErrorAction SilentlyContinue) {
        try {
            Write-Status "Starting $ModuleName module..." -Level Info
            & $functionName -Config $Config
            Write-Status "$ModuleName module completed successfully" -Level Success
            return $true
        }
        catch {
            Write-Status "Error in $ModuleName module: $_" -Level Error
            return $false
        }
    }
    else {
        Write-Status "Module function not found: $functionName" -Level Warning
        Write-Status "Ensure the $ModuleName module exports this function" -Level Info
        return $false
    }
}

function Show-ExecutionSummary {
    param(
        [string[]]$ExecutedModules,
        [string[]]$FailedModules,
        [timespan]$ExecutionTime
    )
    
    Write-Header "EXECUTION SUMMARY"
    
    Write-Host "Executed Modules:" -ForegroundColor $Colors.Info
    foreach ($module in $ExecutedModules) {
        Write-Host "  ✓ $module" -ForegroundColor $Colors.Success
    }
    
    if ($FailedModules.Count -gt 0) {
        Write-Host ""
        Write-Host "Failed Modules:" -ForegroundColor $Colors.Error
        foreach ($module in $FailedModules) {
            Write-Host "  ✗ $module" -ForegroundColor $Colors.Error
        }
    }
    
    Write-Host ""
    Write-Host "Total Execution Time: $($ExecutionTime.ToString('hh\:mm\:ss'))" -ForegroundColor $Colors.Info
    Write-Host ""
}

################################################################################
# MAIN EXECUTION
################################################################################

try {
    # Display banner
    Write-Header "DSP DEMO ACTIVITY GENERATION - MAIN SCRIPT"
    Write-Host "Version: $Script:ScriptVersion" -ForegroundColor $Colors.Info
    Write-Host "Script Path: $Script:ScriptPath" -ForegroundColor $Colors.Info
    Write-Host "Modules Path: $Script:ModulesPath" -ForegroundColor $Colors.Info
    Write-Host ""
    
    # Load configuration
    Write-Section "Loading Configuration"
    if (Test-Path $Script:ConfigFile) {
        Write-Status "Config file found: $Script:ConfigFile" -Level Success
        $config = Import-PowerShellDataFile $Script:ConfigFile
        Write-Status "Configuration loaded successfully" -Level Success
    }
    else {
        Write-Status "Config file not found: $Script:ConfigFile" -Level Warning
        Write-Status "Using default configuration" -Level Info
        $config = @{}
    }
    Write-Host ""
    
    # Import core module first (always needed)
    Write-Section "Initializing Core Module"
    if (-not (Import-RequiredModule "DSP-Demo-01-Core")) {
        throw "Failed to load core module - cannot continue"
    }
    Write-Host ""
    
    # Discover AD environment
    Write-Section "Discovering AD Environment"
    if (-not (Import-RequiredModule "DSP-Demo-02-AD-Discovery")) {
        Write-Status "AD Discovery module not available - some features may be limited" -Level Warning
    }
    else {
        try {
            $envInfo = Get-DspEnvironmentInfo
            Write-Status "Environment discovery complete" -Level Success
            Write-Status "Domain: $($envInfo.Domain.FQDN)" -Level Info
            Write-Status "Primary DC: $($envInfo.Domain.RWDC)" -Level Info
        }
        catch {
            Write-Status "Failed to discover environment: $_" -Level Warning
        }
    }
    Write-Host ""
    
    # Determine which modules to run
    if ($Module) {
        # Module specified via parameter
        if ($Module -eq "All") {
            $modulesToRun = @("Users", "Groups", "OUs", "DNS", "GPOs", "Sites", "Security", "Changes")
        }
        else {
            $modulesToRun = @($Module)
        }
    }
    elseif ($SkipMenu) {
        # Run all modules
        $modulesToRun = @("Users", "Groups", "OUs", "DNS", "GPOs", "Sites", "Security", "Changes")
    }
    else {
        # Show interactive menu
        $modulesToRun = Get-MenuSelection
        
        if (-not $modulesToRun) {
            Write-Status "No modules selected - exiting" -Level Info
            exit 0
        }
    }
    
    # Execute selected modules
    Write-Header "RUNNING SELECTED MODULES"
    
    $executionStart = Get-Date
    $executedModules = @()
    $failedModules = @()
    
    foreach ($moduleName in $modulesToRun) {
        Write-Host ""
        Write-Status "Checking module availability: $moduleName" -Level Info
        
        if (Test-ModuleAvailable "DSP-Demo-Module-$moduleName") {
            Write-Status "Module found, importing..." -Level Info
            if (Import-RequiredModule "DSP-Demo-Module-$moduleName") {
                if (Execute-Module $moduleName $config) {
                    $executedModules += $moduleName
                }
                else {
                    $failedModules += $moduleName
                }
            }
            else {
                $failedModules += $moduleName
            }
        }
        else {
            Write-Status "Module file not found: DSP-Demo-Module-$moduleName.psm1" -Level Warning
            Write-Status "Skipping $moduleName module" -Level Info
            $failedModules += $moduleName
        }
    }
    
    $executionEnd = Get-Date
    $executionTime = $executionEnd - $executionStart
    
    # Show summary
    Show-ExecutionSummary -ExecutedModules $executedModules -FailedModules $failedModules -ExecutionTime $executionTime
    
    Write-Status "Main script execution complete" -Level Success
}
catch {
    Write-Header "FATAL ERROR"
    Write-Status "Script failed with error: $_" -Level Error
    exit 1
}

################################################################################
# END OF SCRIPT
################################################################################