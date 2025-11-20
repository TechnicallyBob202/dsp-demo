################################################################################
################################################################################
##
## DSP-Demo-MainScript.ps1
##
## Main orchestration script for DSP demo activity generation
## 
## Features:
## - Runs Preflight module for environment discovery and setup
## - Interactive menu for selecting activity modules to run
## - Run individual activity modules or all modules
## - Configuration-driven approach
## - Comprehensive logging and error handling
##
## Author: Rob Ingenthron (Original), Bob Lyons (Refactor)
## Version: 4.2.0-20251119
##
################################################################################
################################################################################

<#
.SYNOPSIS
    DSP Demo Activity Generation Script - Main Orchestrator

.DESCRIPTION
    Automatically generates AD activities such as users, groups, DNS, GPOs, 
    and changes to objects and ACLs. This script uses a modular approach:
    - Preflight module runs first (environment discovery, DSP connectivity)
    - Activity modules run based on user selection from interactive menu

.PARAMETER SkipMenu
    Skip the interactive menu and run all activity modules automatically

.PARAMETER Module
    Specific activity module to run (can be used to skip menu)
    Valid values: DirectoryObjects, DNS, GPOs, Sites, IOCs, All

.PARAMETER ConfigPath
    Path to external configuration file (optional)

.PARAMETER LogPath
    Custom log file path

.EXAMPLE
    .\DSP-Demo-MainScript.ps1
    # Runs Preflight, then opens interactive menu to select activities

.EXAMPLE
    .\DSP-Demo-MainScript.ps1 -Module DirectoryObjects
    # Runs Preflight, then runs only DirectoryObjects activity

.EXAMPLE
    .\DSP-Demo-MainScript.ps1 -SkipMenu
    # Runs Preflight, then runs all activity modules without menu

.NOTES
    Author     : Rob Ingenthron (Original), Bob Lyons (Refactor)
    Version    : 4.2.0-20251119
#>

#Requires -Version 5.1
#Requires -Modules ActiveDirectory
#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$SkipMenu,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('DirectoryObjects','DNS','GPOs','Sites','IOCs','All')]
    [string]$Module,
    
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

function Test-ModuleFile {
    param([string]$ModuleName)
    
    $modulePath = Join-Path $ModulesPath "$ModuleName.psm1"
    return (Test-Path $modulePath -PathType Leaf)
}

function Import-DemoModule {
    param([string]$ModuleName)
    
    try {
        $modulePath = Join-Path $ModulesPath "$ModuleName.psm1"
        
        if (-not (Test-Path $modulePath)) {
            Write-Status "Module file not found: $modulePath" -Level Error
            return $false
        }
        
        Import-Module $modulePath -Force -ErrorAction Stop
        Write-Status "Module imported successfully: $ModuleName" -Level Success
        return $true
    }
    catch {
        Write-Status "Failed to import $ModuleName : $_" -Level Error
        return $false
    }
}

function Show-ActivityMenu {
    Write-Header "DSP DEMO - SELECT ACTIVITY MODULES"
    
    Write-Host "Available Activity Modules:" -ForegroundColor $Colors.Menu
    Write-Host ""
    Write-Host "   1. DirectoryObjects - Create users, groups, OUs, computers, FGPP" -ForegroundColor $Colors.Menu
    Write-Host "   2. DNS             - Create DNS zones and records" -ForegroundColor $Colors.Menu
    Write-Host "   3. GPOs            - Create and modify Group Policy Objects" -ForegroundColor $Colors.Menu
    Write-Host "   4. Sites           - Create AD sites and subnets" -ForegroundColor $Colors.Menu
    Write-Host "   5. IOCs            - Generate security events and changes" -ForegroundColor $Colors.Menu
    Write-Host "   6. All             - Run all activity modules" -ForegroundColor $Colors.MenuHighlight
    Write-Host "   0. Exit            - Exit without running activities" -ForegroundColor $Colors.Warning
    Write-Host ""
}

function Get-ActivitySelection {
    do {
        Write-Host "Enter selection (0-6, comma-separated for multiple): " -ForegroundColor $Colors.MenuHighlight -NoNewline
        $selection = Read-Host
        
        if ($selection -eq "0") {
            return $null
        }
        
        if ($selection -eq "6") {
            return @('DirectoryObjects', 'DNS', 'GPOs', 'Sites', 'IOCs')
        }
        
        # Parse comma-separated selections
        $selections = $selection -split ',' | ForEach-Object { $_.Trim() }
        $moduleMap = @{
            '1' = 'DirectoryObjects'
            '2' = 'DNS'
            '3' = 'GPOs'
            '4' = 'Sites'
            '5' = 'IOCs'
        }
        
        $validSelections = @()
        $allValid = $true
        
        foreach ($sel in $selections) {
            if ($moduleMap.ContainsKey($sel)) {
                $validSelections += $moduleMap[$sel]
            }
            else {
                Write-Status "Invalid selection: $sel" -Level Warning
                $allValid = $false
            }
        }
        
        if ($allValid -and $validSelections.Count -gt 0) {
            return $validSelections
        }
        
    } while ($true)
}

function Show-ExecutionSummary {
    param(
        [array]$ExecutedModules,
        [array]$FailedModules,
        [timespan]$ExecutionTime
    )
    
    Write-Header "EXECUTION SUMMARY"
    
    if ($ExecutedModules.Count -gt 0) {
        Write-Status "Successfully executed: $($ExecutedModules -join ', ')" -Level Success
    }
    
    if ($FailedModules.Count -gt 0) {
        Write-Status "Failed modules: $($FailedModules -join ', ')" -Level Warning
    }
    
    Write-Status "Total execution time: $($ExecutionTime.TotalSeconds) seconds" -Level Info
    Write-Host ""
}

################################################################################
# MAIN SCRIPT
################################################################################

try {
    Write-Header "DSP Demo Script - Preflight Initialization"
    
    # Check if modules directory exists
    if (-not (Test-Path $ModulesPath -PathType Container)) {
        Write-Status "Modules directory not found: $ModulesPath" -Level Warning
        Write-Status "Creating modules directory..." -Level Info
        New-Item -ItemType Directory -Path $ModulesPath -Force | Out-Null
    }
    
    # Import and run Preflight module (mandatory)
    Write-Status "Importing Preflight module..." -Level Info
    
    if (-not (Import-DemoModule "DSP-Demo-Preflight")) {
        Write-Status "FATAL: Failed to import Preflight module" -Level Error
        exit 1
    }
    
    Write-Host ""
    
    # Run Preflight discovery functions
    Write-LogHeader "Discovering Environment"
    
    try {
        $domainInfo = Get-DomainInfo
        $dcs = Get-ADDomainControllers
        $primaryDC = $dcs[0].HostName
        $secondaryDC = if ($dcs.Count -gt 1) { $dcs[1].HostName } else { $null }
        $forestInfo = Get-ForestInfo
        
        Write-ScriptLog "Primary DC: $primaryDC" -Level Info
        if ($secondaryDC) {
            Write-ScriptLog "Secondary DC: $secondaryDC" -Level Info
        }
    }
    catch {
        Write-ScriptLog "FATAL: Failed to discover environment: $_" -Level Error
        exit 1
    }
    
    # Attempt DSP connectivity (optional)
    Write-LogHeader "DSP Server Discovery"
    
    $dspServer = Find-DspServer -DomainInfo $domainInfo
    $dspAvailable = $false
    $dspConnection = $null
    
    if ($dspServer) {
        if (Test-DspModule) {
            $dspAvailable = $true
            $dspConnection = Connect-DspManagementServer -DspServer $dspServer
            
            if ($dspConnection) {
                Write-ScriptLog "DSP connectivity established" -Level Success
            }
            else {
                Write-ScriptLog "DSP module available but connection failed - continuing without DSP" -Level Warning
                $dspAvailable = $false
            }
        }
        else {
            Write-ScriptLog "DSP server found but module not installed - continuing without DSP" -Level Warning
            $dspAvailable = $false
        }
    }
    else {
        Write-ScriptLog "DSP server not found - continuing without DSP" -Level Warning
        $dspAvailable = $false
    }
    
    Write-Host ""
    
    # Determine which activity modules to run
    $activityModules = @()
    
    if ($Module) {
        if ($Module -eq 'All') {
            $activityModules = @('DirectoryObjects', 'DNS', 'GPOs', 'Sites', 'IOCs')
        }
        else {
            $activityModules = @($Module)
        }
    }
    elseif (-not $SkipMenu) {
        Show-ActivityMenu
        $activityModules = Get-ActivitySelection
        
        if (-not $activityModules) {
            Write-Status "No activity modules selected - exiting" -Level Info
            exit 0
        }
    }
    else {
        $activityModules = @('DirectoryObjects', 'DNS', 'GPOs', 'Sites', 'IOCs')
    }
    
    Write-Header "RUNNING ACTIVITY MODULES"
    
    $executionStart = Get-Date
    $executedModules = @()
    $failedModules = @()
    
    foreach ($activityName in $activityModules) {
        Write-Host ""
        Write-Status "Processing activity module: $activityName" -Level Info
        
        $moduleFile = "DSP-Demo-01-$activityName"
        
        if (Test-ModuleFile $moduleFile) {
            if (Import-DemoModule $moduleFile) {
                $executedModules += $activityName
                Write-Status "Activity $activityName completed" -Level Success
            }
            else {
                $failedModules += $activityName
                Write-Status "Activity $activityName failed to execute" -Level Error
            }
        }
        else {
            Write-Status "Activity module file not found: $moduleFile.psm1" -Level Warning
            $failedModules += $activityName
        }
    }
    
    $executionEnd = Get-Date
    $executionTime = $executionEnd - $executionStart
    
    Show-ExecutionSummary -ExecutedModules $executedModules -FailedModules $failedModules -ExecutionTime $executionTime
}
catch {
    Write-Header "FATAL ERROR"
    Write-Status "Script failed: $_" -Level Error
    exit 1
}

################################################################################
# END OF SCRIPT
################################################################################