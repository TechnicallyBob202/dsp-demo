################################################################################
##
## DSP-Demo-ModuleTest-Enhanced.ps1
##
## Enhanced version of the module test script with proper validation,
## error handling, and diagnostics.
##
## This version validates that:
## 1. Module files exist at expected paths
## 2. Modules import without errors
## 3. Required functions are exported and available
## 4. Functions can be called successfully
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory
#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ModulePath = $PSScriptRoot,
    
    [Parameter(Mandatory=$false)]
    [switch]$TestDiscoveryOnly,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipAdminCheck,
    
    [Parameter(Mandatory=$false)]
    [switch]$VerboseDiagnostics
)

################################################################################
# CONFIGURATION
################################################################################

$Script:TestConfig = @{
    ModulePath = $ModulePath
    ModulesSubdir = "modules"
    Modules = @(
        @{
            Name = "DSP-Demo-01-Core"
            File = "DSP-Demo-01-Core.psm1"
            RequiredFunctions = @(
                'Write-DspHeader',
                'Write-DspLog',
                'Wait-DspReplication',
                'Test-DspAdminRights'
            )
        }
        @{
            Name = "DSP-Demo-02-AD-Discovery"
            File = "DSP-Demo-02-AD-Discovery.psm1"
            RequiredFunctions = @(
                'Get-DspDomainInfo',
                'Find-DspServer',
                'Test-DspModule',
                'Get-DspEnvironmentInfo'
            )
        }
    )
}

################################################################################
# HELPER FUNCTIONS
################################################################################

function Write-TestHeader {
    <#
    .SYNOPSIS
        Write a formatted test header
    #>
    param([string]$Message)
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor Cyan
    Write-Host ("=" * 80) -ForegroundColor Cyan
    Write-Host ""
}

function Write-TestResult {
    <#
    .SYNOPSIS
        Write a formatted test result
    #>
    param(
        [string]$Name,
        [ValidateSet('OK','FAIL','WARN','INFO','SKIP')]
        [string]$Status = 'INFO',
        [string]$Details = ""
    )
    
    $statusColors = @{
        'OK'   = 'Green'
        'FAIL' = 'Red'
        'WARN' = 'Yellow'
        'INFO' = 'Cyan'
        'SKIP' = 'Yellow'
    }
    
    $color = $statusColors[$Status]
    $message = "[$Status] $Name"
    if ($Details) {
        $message += " - $Details"
    }
    
    Write-Host $message -ForegroundColor $color
}

function Test-ModuleFile {
    <#
    .SYNOPSIS
        Test if a module file exists and is readable
    #>
    param(
        [string]$ModuleName,
        [string]$FilePath
    )
    
    Write-Host "  Checking for module file: $FilePath" -ForegroundColor Gray
    
    if (-not (Test-Path $FilePath)) {
        Write-TestResult "Module File" "FAIL" "File not found: $FilePath"
        return $false
    }
    
    if (-not (Test-Path $FilePath -PathType Leaf)) {
        Write-TestResult "Module File" "FAIL" "Path is not a file: $FilePath"
        return $false
    }
    
    Write-TestResult "Module File" "OK"
    return $true
}

function Import-ModuleWithValidation {
    <#
    .SYNOPSIS
        Import a module and validate that required functions are exported
    #>
    param(
        [string]$ModuleName,
        [string]$ModuleFile,
        [string[]]$RequiredFunctions
    )
    
    Write-Host ""
    Write-Host "Processing: $ModuleName" -ForegroundColor Yellow
    Write-Host "File: $ModuleFile" -ForegroundColor Gray
    
    # Test file exists
    if (-not (Test-ModuleFile $ModuleName $ModuleFile)) {
        return @{
            Success = $false
            Module = $ModuleName
            Error = "Module file not found"
        }
    }
    
    # Import the module
    Write-Host "  Importing module..." -ForegroundColor Gray
    try {
        Import-Module $ModuleFile -Force -ErrorAction Stop
        Write-TestResult "Module Import" "OK"
    }
    catch {
        Write-TestResult "Module Import" "FAIL" $_.Exception.Message
        return @{
            Success = $false
            Module = $ModuleName
            Error = $_.Exception.Message
        }
    }
    
    # Validate required functions are exported
    Write-Host "  Validating exported functions..." -ForegroundColor Gray
    
    $missingFunctions = @()
    $foundFunctions = @()
    
    foreach ($funcName in $RequiredFunctions) {
        if (Get-Command $funcName -ErrorAction SilentlyContinue) {
            Write-Host "    ✓ $funcName" -ForegroundColor Green
            $foundFunctions += $funcName
        }
        else {
            Write-Host "    ✗ $funcName" -ForegroundColor Red
            $missingFunctions += $funcName
        }
    }
    
    # Report results
    Write-Host ""
    if ($missingFunctions.Count -eq 0) {
        Write-TestResult "Function Exports" "OK" "All $($RequiredFunctions.Count) functions exported"
        return @{
            Success = $true
            Module = $ModuleName
            ExportedFunctions = $foundFunctions
        }
    }
    else {
        Write-TestResult "Function Exports" "FAIL" "Missing: $($missingFunctions -join ', ')"
        return @{
            Success = $false
            Module = $ModuleName
            ExportedFunctions = $foundFunctions
            MissingFunctions = $missingFunctions
        }
    }
}

function Show-ModuleDiagnostics {
    <#
    .SYNOPSIS
        Show detailed module diagnostics
    #>
    Write-TestHeader "MODULE DIAGNOSTICS"
    
    Write-Host "PowerShell Information:" -ForegroundColor Cyan
    Write-Host "  Version: $($PSVersionTable.PSVersion)" -ForegroundColor White
    Write-Host "  Edition: $($PSVersionTable.PSEdition)" -ForegroundColor White
    Write-Host ""
    
    Write-Host "Module Search Paths:" -ForegroundColor Cyan
    $env:PSModulePath -split [System.IO.Path]::PathSeparator | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor White
    }
    Write-Host ""
    
    Write-Host "Currently Loaded Modules:" -ForegroundColor Cyan
    Get-Module | Where-Object {$_.Name -like "*DSP*"} | ForEach-Object {
        Write-Host "  - $($_.Name)" -ForegroundColor White
        Write-Host "    Path: $($_.Path)" -ForegroundColor Gray
        Write-Host "    Functions: $($_.ExportedFunctions.Keys -join ', ')" -ForegroundColor Gray
    }
    Write-Host ""
}

################################################################################
# MAIN TEST EXECUTION
################################################################################

Write-TestHeader "DSP DEMO MODULES - ENHANCED TEST SCRIPT"

# Show diagnostics if requested
if ($VerboseDiagnostics) {
    Show-ModuleDiagnostics
}

# Build full module paths
$modulesPath = Join-Path $ModulePath $Script:TestConfig.ModulesSubdir

Write-Host "Configuration:" -ForegroundColor Cyan
Write-Host "  Base Path: $ModulePath" -ForegroundColor White
Write-Host "  Modules Path: $modulesPath" -ForegroundColor White
Write-Host ""

# Test modules directory exists
if (-not (Test-Path $modulesPath)) {
    Write-TestHeader "CRITICAL ERROR"
    Write-TestResult "Modules Directory" "FAIL" "Not found: $modulesPath"
    Write-Host ""
    Write-Host "Create the modules directory and add the .psm1 files:" -ForegroundColor Yellow
    Write-Host "  mkdir $modulesPath" -ForegroundColor White
    exit 1
}

Write-TestResult "Modules Directory" "OK" "Found at $modulesPath"
Write-Host ""

# Import and validate each module
$importResults = @()

foreach ($moduleConfig in $Script:TestConfig.Modules) {
    $moduleFilePath = Join-Path $modulesPath $moduleConfig.File
    
    $result = Import-ModuleWithValidation `
        -ModuleName $moduleConfig.Name `
        -ModuleFile $moduleFilePath `
        -RequiredFunctions $moduleConfig.RequiredFunctions
    
    $importResults += $result
}

################################################################################
# QUICK FUNCTION TESTS
################################################################################

Write-TestHeader "FUNCTION EXECUTION TESTS"

# Try to execute core module functions if available
if (Get-Command Write-DspLog -ErrorAction SilentlyContinue) {
    Write-Host "Testing Write-DspLog function..." -ForegroundColor Yellow
    try {
        Write-DspLog "Test Info message" -Level Info
        Write-DspLog "Test Success message" -Level Success
        Write-DspLog "Test Warning message" -Level Warning
        Write-DspLog "Test Error message" -Level Error
        Write-TestResult "Write-DspLog" "OK" "Function executed successfully"
    }
    catch {
        Write-TestResult "Write-DspLog" "FAIL" $_.Exception.Message
    }
}
else {
    Write-TestResult "Write-DspLog" "SKIP" "Function not exported (see validation results above)"
}

Write-Host ""

if (Get-Command Get-DspDomainInfo -ErrorAction SilentlyContinue) {
    Write-Host "Testing Get-DspDomainInfo function..." -ForegroundColor Yellow
    try {
        $domainInfo = Get-DspDomainInfo
        Write-TestResult "Get-DspDomainInfo" "OK" "Domain: $($domainInfo.FQDN)"
    }
    catch {
        Write-TestResult "Get-DspDomainInfo" "FAIL" $_.Exception.Message
    }
}
else {
    Write-TestResult "Get-DspDomainInfo" "SKIP" "Function not exported"
}

################################################################################
# TEST SUMMARY
################################################################################

Write-TestHeader "TEST SUMMARY"

$successfulImports = @($importResults | Where-Object {$_.Success})
$failedImports = @($importResults | Where-Object {-not $_.Success})

Write-Host "Module Import Results:" -ForegroundColor Cyan
Write-Host "  Successful: $($successfulImports.Count)" -ForegroundColor Green
Write-Host "  Failed: $($failedImports.Count)" -ForegroundColor $(if ($failedImports.Count -gt 0) {'Red'} else {'Green'})
Write-Host ""

if ($failedImports.Count -gt 0) {
    Write-Host "Failed Modules:" -ForegroundColor Red
    foreach ($failed in $failedImports) {
        Write-Host "  - $($failed.Module)" -ForegroundColor Red
        Write-Host "    Error: $($failed.Error)" -ForegroundColor Yellow
        if ($failed.MissingFunctions) {
            Write-Host "    Missing Functions: $($failed.MissingFunctions -join ', ')" -ForegroundColor Yellow
        }
    }
    Write-Host ""
}

# Recommendations
Write-Host "Recommendations:" -ForegroundColor Yellow
if ($failedImports.Count -gt 0) {
    Write-Host "  1. Check that all module files exist in: $modulesPath" -ForegroundColor White
    Write-Host "  2. Verify each .psm1 file ends with Export-ModuleMember statement" -ForegroundColor White
    Write-Host "  3. Run with -VerboseDiagnostics flag for detailed info:" -ForegroundColor White
    Write-Host "     .\DSP-Demo-ModuleTest-Enhanced.ps1 -VerboseDiagnostics" -ForegroundColor Cyan
    Write-Host "  4. Check the module analysis document for detailed troubleshooting" -ForegroundColor White
}
else {
    Write-Host "  1. All modules imported successfully!" -ForegroundColor Green
    Write-Host "  2. Review the configuration file (DSP-Demo-Config.psd1)" -ForegroundColor White
    Write-Host "  3. Proceed with running the main script: DSP-Demo-MainScript.ps1" -ForegroundColor White
}

Write-Host ""
Write-Host ("=" * 80) -ForegroundColor Cyan