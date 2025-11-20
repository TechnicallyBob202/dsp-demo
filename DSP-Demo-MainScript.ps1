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
## - Confirmation before executing selected modules
## - Configuration-driven approach
## - Comprehensive logging and error handling
##
## Author: Rob Ingenthron (Original), Bob Lyons (Refactor)
## Version: 4.4.0-20251120
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory
#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$SkipConfirmation,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('Directory','DNS','GPOs','Sites','SecurityEvents','All')]
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
    param(
        [string]$ConfigFile
    )
    
    if (Test-Path $ConfigFile) {
        Write-Status "Loading configuration from: $ConfigFile" -Level Info
        try {
            $config = Import-PowerShellDataFile -Path $ConfigFile -ErrorAction Stop
            return $config
        }
        catch {
            Write-Status "FATAL: Failed to load configuration: $_" -Level Error
            exit 1
        }
    }
    else {
        Write-Status "Configuration file not found: $ConfigFile" -Level Warning
        Write-Status "Continuing with minimal configuration..." -Level Info
        return @{}
    }
}

function Import-DemoModule {
    param(
        [string]$ModuleName
    )
    
    $modulePath = Join-Path $ModulesPath "$ModuleName.psm1"
    
    if (-not (Test-Path $modulePath)) {
        Write-Status "Module not found: $modulePath" -Level Error
        return $false
    }
    
    try {
        Import-Module -Name $modulePath -Force -ErrorAction Stop
        Write-Status "Imported module: $ModuleName" -Level Success
        return $true
    }
    catch {
        Write-Status "Failed to import module $ModuleName : $_" -Level Error
        return $false
    }
}

function Show-MainMenu {
    Write-Host ""
    Write-Host "Available Activity Modules:" -ForegroundColor $Colors.Menu
    Write-Host ""
    Write-Host "  1. Directory Objects (Users, Groups, OUs)" -ForegroundColor $Colors.Info
    Write-Host "  2. DNS Records" -ForegroundColor $Colors.Info
    Write-Host "  3. Group Policy Objects (GPOs)" -ForegroundColor $Colors.Info
    Write-Host "  4. Sites and Subnets" -ForegroundColor $Colors.Info
    Write-Host "  5. Security Events" -ForegroundColor $Colors.Info
    Write-Host "  6. Run All Modules" -ForegroundColor $Colors.MenuHighlight
    Write-Host "  7. Exit" -ForegroundColor $Colors.Warning
    Write-Host ""
}

function Get-MenuSelection {
    Write-Host "Select modules to run (comma-separated for multiple, e.g. '1,3,5'):" -ForegroundColor $Colors.Prompt
    Write-Host -NoNewline "Enter selection: " -ForegroundColor $Colors.Prompt
    $selection = Read-Host
    return $selection
}

function Parse-MenuSelection {
    param([string]$Selection)
    
    $selected = @()
    
    if ($Selection -eq "6") {
        $selected = @("Directory","DNS","GPOs","Sites","SecurityEvents")
    }
    else {
        $choices = $Selection -split "," | ForEach-Object { $_.Trim() }
        
        $moduleMap = @{
            "1" = "Directory"
            "2" = "DNS"
            "3" = "GPOs"
            "4" = "Sites"
            "5" = "SecurityEvents"
        }
        
        foreach ($choice in $choices) {
            if ($moduleMap.ContainsKey($choice)) {
                $selected += $moduleMap[$choice]
            }
            else {
                Write-Status "Invalid selection: $choice" -Level Warning
            }
        }
    }
    
    return $selected
}

function Show-ConfirmationPrompt {
    param([array]$SelectedModules)
    
    Write-Header "Confirm Module Execution"
    
    Write-Host "You have selected the following modules to execute:" -ForegroundColor $Colors.Info
    Write-Host ""
    
    $SelectedModules | ForEach-Object {
        Write-Host "  [+] $_" -ForegroundColor $Colors.Success
    }
    
    Write-Host ""
    Write-Host "Configuration:" -ForegroundColor $Colors.Section
    Write-Host "  Domain:     $($Script:DomainInfo.Name)" -ForegroundColor $Colors.Info
    Write-Host "  Primary DC: $($Script:PrimaryDC)" -ForegroundColor $Colors.Info
    if ($Script:SecondaryDC) {
        Write-Host "  Secondary DC: $($Script:SecondaryDC)" -ForegroundColor $Colors.Info
    }
    Write-Host ""
    
    Write-Host "Continue with execution?" -ForegroundColor $Colors.Prompt
    Write-Host -NoNewline "[Y]es or [N]o: " -ForegroundColor $Colors.Prompt
    $confirm = Read-Host
    
    return ($confirm -eq "Y" -or $confirm -eq "Yes")
}

function Run-ActivityModule {
    param(
        [string]$ModuleName,
        [hashtable]$Config,
        [hashtable]$Environment
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
            & $functionName
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
# MAIN EXECUTION
################################################################################

function Main {
    Write-Header "DSP DEMO ACTIVITY GENERATION SUITE v4.4.0"
    
    Write-Status "Script path: $ScriptPath" -Level Info
    Write-Status "Config file: $ConfigFile" -Level Info
    
    if (-not (Test-Path $ModulesPath)) {
        Write-Status "Creating modules directory..." -Level Info
        New-Item -ItemType Directory -Path $ModulesPath -Force | Out-Null
    }
    
    Write-Status "Loading configuration..." -Level Info
    $config = Load-Configuration -ConfigFile $ConfigFile
    Write-Status "Configuration loaded" -Level Success
    
    Write-Status "Importing Preflight module..." -Level Info
    
    if (-not (Import-DemoModule "DSP-Demo-Preflight")) {
        Write-Status "FATAL: Failed to import Preflight module" -Level Error
        exit 1
    }
    
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
                if (Get-Command Test-DspModule -ErrorAction SilentlyContinue) {
                    if (Test-DspModule) {
                        $Script:DspAvailable = $true
                        Write-Status "DSP server found: $dspServer" -Level Success
                    }
                    else {
                        Write-Status "DSP module not available, DSP operations will be skipped" -Level Warning
                    }
                }
            }
        }
    }
    catch {
        Write-Status "DSP discovery failed (continuing without DSP): $_" -Level Warning
    }
    
    if (-not $Script:DspAvailable) {
        Write-Status "DSP not available, AD activity generation will continue" -Level Info
    }
    
    Write-Host ""
    
    $selectedModules = @()
    
    if ($Module) {
        if ($Module -eq "All") {
            $selectedModules = @("Directory","DNS","GPOs","Sites","SecurityEvents")
        }
        else {
            $selectedModules = @($Module)
        }
    }
    elseif ($SkipConfirmation) {
        Write-Status "Running all modules (skip confirmation flag set)" -Level Info
        $selectedModules = @("Directory","DNS","GPOs","Sites","SecurityEvents")
    }
    else {
        do {
            Show-MainMenu
            $selection = Get-MenuSelection
            
            if ($selection -eq "7") {
                Write-Status "Exiting..." -Level Info
                exit 0
            }
            
            $selectedModules = Parse-MenuSelection -Selection $selection
            
            if ($selectedModules.Count -eq 0) {
                Write-Status "No valid modules selected, please try again" -Level Warning
                continue
            }
            
            if (Show-ConfirmationPrompt -SelectedModules $selectedModules) {
                break
            }
            else {
                Write-Status "Execution cancelled by user" -Level Warning
                Write-Host ""
            }
        }
        while ($true)
    }
    
    $environment = @{
        DomainInfo = $Script:DomainInfo
        PrimaryDC = $Script:PrimaryDC
        SecondaryDC = $Script:SecondaryDC
        ForestInfo = $Script:ForestInfo
        DspAvailable = $Script:DspAvailable
        DspConnection = $Script:DspConnection
    }
    
    Write-Header "Loading Activity Modules"
    
    $modulesToImport = @(
        "DSP-Demo-01-Directory",
        "DSP-Demo-02-DNS",
        "DSP-Demo-03-GPOs",
        "DSP-Demo-04-Sites",
        "DSP-Demo-05-SecurityEvents"
    )
    
    foreach ($moduleName in $modulesToImport) {
        if (-not (Import-DemoModule $moduleName)) {
            Write-Status "Warning: Failed to import $moduleName" -Level Warning
        }
    }
    
    Write-Host ""
    
    Write-Header "Executing Selected Modules"
    
    $completedModules = 0
    $failedModules = 0
    
    foreach ($moduleName in $selectedModules) {
        if (Run-ActivityModule -ModuleName $moduleName -Config $config) {
            $completedModules++
        }
        else {
            $failedModules++
        }
        Write-Host ""
    }
    
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