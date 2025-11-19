################################################################################
##
## DSP-Demo-Test-Simple.ps1
##
## Simple module test script - No syntax errors
## CHANGE TO PUSH
################################################################################

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ModulePath = $PSScriptRoot
)

$sep = "=" * 80

# Setup
Write-Host ""
Write-Host $sep -ForegroundColor Cyan
Write-Host "DSP DEMO MODULES - SIMPLE TEST" -ForegroundColor Cyan
Write-Host $sep -ForegroundColor Cyan
Write-Host ""

# Import modules
Write-Host "Importing modules..." -ForegroundColor Yellow

$modulesPath = Join-Path $ModulePath "modules"

# Test Core Module
try {
    $coreModulePath = Join-Path $modulesPath "DSP-Demo-01-Core.psm1"
    if (Test-Path $coreModulePath) {
        Import-Module $coreModulePath -Force -ErrorAction Stop
        Write-Host "  [OK] DSP-Demo-01-Core.psm1" -ForegroundColor Green
    }
    else {
        Write-Host "  [MISSING] DSP-Demo-01-Core.psm1 - File not found" -ForegroundColor Red
    }
}
catch {
    Write-Host "  [ERROR] DSP-Demo-01-Core.psm1" -ForegroundColor Red
    Write-Host "    $_" -ForegroundColor Red
}

# Test AD Discovery Module
try {
    $adModulePath = Join-Path $modulesPath "DSP-Demo-02-AD-Discovery.psm1"
    if (Test-Path $adModulePath) {
        Import-Module $adModulePath -Force -ErrorAction Stop
        Write-Host "  [OK] DSP-Demo-02-AD-Discovery.psm1" -ForegroundColor Green
    }
    else {
        Write-Host "  [MISSING] DSP-Demo-02-AD-Discovery.psm1 - File not found" -ForegroundColor Red
    }
}
catch {
    Write-Host "  [ERROR] DSP-Demo-02-AD-Discovery.psm1" -ForegroundColor Red
    Write-Host "    $_" -ForegroundColor Red
}

Write-Host ""

# Test functions
Write-Host "Testing Core Module Functions:" -ForegroundColor Cyan
Write-Host "-" * 80 -ForegroundColor Cyan

# Test Write-DspLog
if (Get-Command Write-DspLog -ErrorAction SilentlyContinue) {
    Write-Host "  Testing Write-DspLog..." -ForegroundColor Yellow
    try {
        Write-DspLog "Test Info message" -Level Info
        Write-DspLog "Test Success message" -Level Success
        Write-Host "  [OK] Write-DspLog works" -ForegroundColor Green
    }
    catch {
        Write-Host "  [FAIL] Write-DspLog error: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "  [NOTFOUND] Write-DspLog function not exported" -ForegroundColor Red
}

Write-Host ""

# Test AD Discovery functions
Write-Host "Testing AD Discovery Module Functions:" -ForegroundColor Cyan
Write-Host "-" * 80 -ForegroundColor Cyan

if (Get-Command Get-DspDomainInfo -ErrorAction SilentlyContinue) {
    Write-Host "  Testing Get-DspDomainInfo..." -ForegroundColor Yellow
    try {
        $domain = Get-DspDomainInfo
        Write-Host "  [OK] Get-DspDomainInfo - Domain: $($domain.FQDN)" -ForegroundColor Green
    }
    catch {
        Write-Host "  [FAIL] Get-DspDomainInfo error: $_" -ForegroundColor Red
    }
}
else {
    Write-Host "  [NOTFOUND] Get-DspDomainInfo function not exported" -ForegroundColor Red
}

Write-Host ""
Write-Host $sep -ForegroundColor Cyan
Write-Host "TEST COMPLETE" -ForegroundColor Cyan
Write-Host $sep -ForegroundColor Cyan