################################################################################
##
## Test-ActivityModule.ps1
##
## Test harness for individual activity modules
## Runs preflight checks first, optionally runs ALL Setup modules, 
## and finally executes the specified Activity module.
##
## Usage: 
## 1. Just test activity module 07:
##    .\Test-ActivityModule.ps1 -ModuleNumber 07
##
## 2. Run all Setup modules first, then test activity module 07:
##    .\Test-ActivityModule.ps1 -ModuleNumber 07 -IncludeSetup
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory
#Requires -RunAsAdministrator

param(
    [Parameter(Mandatory=$true)]
    [string]$ModuleNumber,
    
    [Parameter(Mandatory=$false)]
    [string]$ActivityConfigPath,

    [Parameter(Mandatory=$false)]
    [switch]$IncludeSetup
)

$ErrorActionPreference = "Continue"

################################################################################
# HELPER FUNCTIONS (Ported from Main Script)
################################################################################

function Expand-ConfigPlaceholders {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        $DomainInfo
    )
    
    $domainName = $DomainInfo.FQDN
    $domainDN = $DomainInfo.DN
    
    $expandedConfig = @{}
    
    foreach ($key in $Config.Keys) {
        $value = $Config[$key]
        
        if ($value -is [string]) {
            $value = $value -replace '\{DOMAIN\}', $domainName
            $value = $value -replace '\{DOMAIN_DN\}', $domainDN
        }
        elseif ($value -is [hashtable]) {
            $value = Expand-ConfigPlaceholders -Config $value -DomainInfo $DomainInfo
        }
        
        $expandedConfig[$key] = $value
    }
    
    return $expandedConfig
}

function Get-ModuleDisplayName {
    param([Parameter(Mandatory=$true)][string]$ModuleName)
    # Extract the readable name from module filename
    $name = $ModuleName -replace "^DSP-Demo-(Setup|Activity)-\d+-", ""
    return $name
}

################################################################################
# INITIALIZATION
################################################################################

$Script:ScriptPath = $PSScriptRoot
$Script:ModulesPath = Join-Path $ScriptPath "modules"

# Setup config path
$Script:SetupConfigFile = Join-Path $ScriptPath "DSP-Demo-Config-Setup.psd1"

# Activity config path
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
    # Note: passing $null for config here as we just want environment info first
    $environment = Initialize-PreflightEnvironment
    Write-Host "Preflight checks passed." -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "ERROR: Preflight initialization failed: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""

################################################################################
# PHASE: SETUP (Optional)
################################################################################

if ($IncludeSetup) {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Running Setup Modules" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # 1. Load Setup Config
    if (Test-Path $Script:SetupConfigFile) {
        try {
            $rawSetupConfig = Import-PowerShellDataFile -Path $Script:SetupConfigFile
            # Expand placeholders
            $setupConfig = Expand-ConfigPlaceholders -Config $rawSetupConfig -DomainInfo $environment.DomainInfo
            Write-Host "Setup configuration loaded and expanded." -ForegroundColor Green
        }
        catch {
            Write-Host "ERROR: Failed to load setup config: $_" -ForegroundColor Red
            exit 1
        }
    }
    else {
        Write-Host "ERROR: Setup config not found at $Script:SetupConfigFile" -ForegroundColor Red
        exit 1
    }

    # 2. Find and Run Setup Modules
    $setupPath = Join-Path $Script:ModulesPath "setup"
    if (Test-Path $setupPath) {
        $setupModules = Get-ChildItem -Path $setupPath -Filter "*.psm1" -ErrorAction SilentlyContinue | Sort-Object Name
        
        foreach ($moduleFile in $setupModules) {
            $moduleName = $moduleFile.BaseName
            $functionName = "Invoke-" + (Get-ModuleDisplayName $moduleName)

            try {
                Import-Module $moduleFile.FullName -Force -ErrorAction Stop | Out-Null
                Write-Host "Loaded: $moduleName" -ForegroundColor Cyan
                
                if (Get-Command $functionName -ErrorAction SilentlyContinue) {
                    Write-Host "Executing $functionName..." -ForegroundColor Yellow
                    & $functionName -Config $setupConfig -Environment $environment
                    Write-Host "Success" -ForegroundColor Green
                }
                else {
                    Write-Host "WARNING: Function $functionName not found" -ForegroundColor Yellow
                }
            }
            catch {
                Write-Host "ERROR in $moduleName : $_" -ForegroundColor Red
            }
            Write-Host ""
        }
    }
    else {
        Write-Host "WARNING: Setup modules folder not found." -