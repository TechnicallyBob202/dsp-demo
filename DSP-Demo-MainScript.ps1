################################################################################
##
## DSP-Demo-MainScript.ps1
##
## Main orchestration script for DSP demo activity generation
## 
## Features:
## - Loads configuration from config file
## - Runs Preflight module for environment discovery and setup
## - Interactive menu for selecting activity modules to run
## - Run individual activity modules or all modules
## - Configuration-driven approach
## - Comprehensive logging and error handling
##
## Author: Rob Ingenthron (Original), Bob Lyons (Refactor)
## Version: 4.3.0-20251119
##
################################################################################

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
$Script:ConfigFile = if ($ConfigPath) { $ConfigPath } else { Join-Path $ScriptPath "DSP-Demo-Config.psd1" }

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
    param(
        [string]$ConfigFile
    )
    
    if (Test-Path $ConfigFile) {
        Write-Status "Loading configuration from: $ConfigFile" -Level Info
        try {
            $config = Import-PowerShellDataFile -Path $ConfigFile -ErrorAction Stop
            Write-Status "Configuration loaded successfully" -Level Success
            return $config
        }
        catch {
            Write-Status "Failed to load configuration: $_" -Level Warning
            Write-Status "Continuing with defaults..." -Level Info
            return @{}
        }
    }
    else {
        Write-Status "Configuration file not found: $ConfigFile" -Level Warning
        Write-Status "Continuing with defaults..." -Level Info
        return @{}
    }
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
    Write-Host "   5. IOCs            - Create Indicators of Compromise" -ForegroundColor $Colors.Menu
    Write-Host "   6. All             - Run all activity modules" -ForegroundColor $Colors.Menu
    Write-Host "   0. Exit            - Exit without running activities" -ForegroundColor $Colors.Menu
    Write-Host ""
}

function Get-ActivitySelection {
    while ($true) {
        $choice = Read-Host "Select an option (0-6)"
        
        switch ($choice) {
            '1' { return @('DirectoryObjects') }
            '2' { return @('DNS') }
            '3' { return @('GPOs') }
            '4' { return @('Sites') }
            '5' { return @('IOCs') }
            '6' { return @('DirectoryObjects', 'DNS', 'GPOs', 'Sites', 'IOCs') }
            '0' { return @() }
            default { Write-Status "Invalid selection, please try again" -Level Warning }
        }
    }
}

function Show-ExecutionSummary {
    param(
        [array]$ExecutedModules,
        [array]$FailedModules,
        [timespan]$ExecutionTime
    )
    
    Write-Header "EXECUTION SUMMARY"
    
    if ($ExecutedModules.Count -gt 0) {
        Write-Status "Successfully executed modules: $($ExecutedModules -join ', ')" -Level Success
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
    
    # Load configuration
    $config = Load-Configuration -ConfigFile $Script:ConfigFile
    
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
    
    # Get DSP server from config, or leave empty for auto-discovery
    $dspServerFromConfig = $config.DspServer
    
    $dspServer = Find-DspServer -DomainInfo $domainInfo -ConfigServer $dspServerFromConfig
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