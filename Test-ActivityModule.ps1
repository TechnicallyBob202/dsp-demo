################################################################################
##
## Test-ActivityModule.ps1
##
## Test harness for individual activity modules
## Runs preflight checks first, then loads and executes the specified module
##
## Usage: .\Test-ActivityModule.ps1 -ModuleNumber 07
##
## With custom activity config:
## .\Test-ActivityModule.ps1 -ModuleNumber 07 -ActivityConfigPath ".\DSP-Demo-Config-Activity.psd1"
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory
#Requires -RunAsAdministrator

param(
    [Parameter(Mandatory=$true)]
    [string]$ModuleNumber,
    
    [Parameter(Mandatory=$false)]
    [string]$ActivityConfigPath
)

$ErrorActionPreference = "Continue"

################################################################################
# INITIALIZATION
################################################################################

$Script:ScriptPath = $PSScriptRoot
$Script:ModulesPath = Join-Path $ScriptPath "modules"

# Setup and Activity config paths
$Script:SetupConfigFile = Join-Path $ScriptPath "DSP-Demo-Config-Setup.psd1"
$Script:ActivityConfigFile = if ($ActivityConfigPath) { 
    $ActivityConfigPath 
} 
else { 
    Join-Path $ScriptPath "DSP-Demo-Config-Activity.psd1"
}

################################################################################
# LOAD PREFLIGHT MODULE
################################################################################

$preflightPath = Join-Path $Script:ModulesPath "DSP-Demo-Preflight.psm1"

if (-not (Test-Path $preflightPath)) {
    Write-Host "ERROR: Preflight module not found: $preflightPath" -ForegroundColor Red
    exit 1
}

try {
    Import-Module $preflightPath -Force -ErrorAction Stop | Out-Null
    Write-Host "Preflight module loaded" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Failed to load preflight module: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Run preflight environment discovery
try {
    $environment = Initialize-PreflightEnvironment
}
catch {
    Write-Host ""
    Write-Host "ERROR: Preflight initialization failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

################################################################################
# FIND MODULE BY NUMBER
################################################################################

$activityPath = Join-Path $Script:ModulesPath "activity"

if (-not (Test-Path $activityPath)) {
    Write-Host "ERROR: Activity modules folder not found: $activityPath" -ForegroundColor Red
    exit 1
}

# Search for module file matching the number pattern
$moduleFiles = Get-ChildItem -Path $activityPath -Filter "DSP-Demo-Activity-$($ModuleNumber)-*.psm1" -ErrorAction SilentlyContinue

if ($moduleFiles.Count -eq 0) {
    Write-Host "ERROR: No activity module found with number $ModuleNumber" -ForegroundColor Red
    Write-Host ""
    Write-Host "Available activity modules:" -ForegroundColor Yellow
    Get-ChildItem -Path $activityPath -Filter "*.psm1" | ForEach-Object { Write-Host "  $($_.Name)" }
    exit 1
}

$moduleFile = $moduleFiles[0]
$moduleName = $moduleFile.BaseName
$functionName = "Invoke-" + ($moduleName -replace "^DSP-Demo-Activity-\d+-", "")

################################################################################
# LOAD CONFIGURATION & ACTIVITY MODULE
################################################################################

Write-Host "Loading activity configuration..." -ForegroundColor Cyan

if (-not (Test-Path $Script:ActivityConfigFile)) {
    Write-Host "ERROR: Activity config file not found: $Script:ActivityConfigFile" -ForegroundColor Red
    exit 1
}

try {
    $config = Import-PowerShellDataFile -Path $Script:ActivityConfigFile
    Write-Host "Activity config loaded successfully" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Failed to load activity config: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Module file: $($moduleFile.FullName)" -ForegroundColor Cyan
Write-Host "Module name: $moduleName" -ForegroundColor Cyan
Write-Host "Function name: $functionName" -ForegroundColor Cyan
Write-Host ""

try {
    Remove-Module $moduleName -Force -ErrorAction SilentlyContinue
    Import-Module $moduleFile.FullName -Force -ErrorAction Stop | Out-Null
    Write-Host "Module loaded successfully" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Failed to load module: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

if (-not (Get-Command $functionName -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Function $functionName not found in module" -ForegroundColor Red
    exit 1
}

################################################################################
# EXECUTE MODULE
################################################################################

Write-Host "Executing $functionName..." -ForegroundColor Yellow
Write-Host ""

try {
    & $functionName -Config $config -Environment $environment
    Write-Host ""
    Write-Host "Test completed successfully" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "ERROR: Function execution failed: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}