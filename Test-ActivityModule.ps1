################################################################################
##
## Test-ActivityModule.ps1
##
## Test harness for individual activity modules
## Usage: .\Test-ActivityModule.ps1 -ModuleNumber 01
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory
#Requires -RunAsAdministrator

param(
    [Parameter(Mandatory=$true)]
    [string]$ModuleNumber,
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath
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
    Join-Path $ScriptPath "DSP-Demo-Config.psd1"
}

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
    Get-ChildItem -Path $activityPath -Filter "*.psm1" | ForEach-Object { Write-Host "  $_" }
    exit 1
}

$moduleFile = $moduleFiles[0]
$moduleName = $moduleFile.BaseName
$functionName = "Invoke-" + ($moduleName -replace "^DSP-Demo-Activity-\d+-", "")

################################################################################
# LOAD CONFIGURATION & ENVIRONMENT
################################################################################

Write-Host ""
Write-Host "Loading configuration..." -ForegroundColor Cyan

if (-not (Test-Path $Script:ConfigFile)) {
    Write-Host "ERROR: Config file not found: $Script:ConfigFile" -ForegroundColor Red
    exit 1
}

try {
    $config = Import-PowerShellDataFile -Path $Script:ConfigFile
    Write-Host "Config loaded successfully" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Failed to load config: $_" -ForegroundColor Red
    exit 1
}

# Setup environment variable with basic domain info (borrowed from main script pattern)
$environment = @{
    DomainInfo = @{
        Name = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().DomainName
        DN = ([ADSI]"LDAP://RootDSE").defaultNamingContext.Value
    }
}

Write-Host "Domain: $($environment.DomainInfo.Name)" -ForegroundColor Green
Write-Host "Domain DN: $($environment.DomainInfo.DN)" -ForegroundColor Green
Write-Host ""

################################################################################
# LOAD AND TEST MODULE
################################################################################

Write-Host "Module file: $($moduleFile.FullName)" -ForegroundColor Cyan
Write-Host "Module name: $moduleName" -ForegroundColor Cyan
Write-Host "Function name: $functionName" -ForegroundColor Cyan
Write-Host ""

try {
    Remove-Module $moduleName -Force -ErrorAction SilentlyContinue
    Import-Module $moduleFile.FullName -Force -ErrorAction Stop
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