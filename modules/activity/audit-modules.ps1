################################################################################
##
## Audit-ModuleConsistency.ps1
##
## Audits all activity modules for consistency between:
## 1. Filename: DSP-Demo-Activity-##-NAME.psm1
## 2. Config key: Module##_NAME
## 3. Function name: Invoke-NAME
## 4. Module header comment
##
## Run from activity folder: .\Audit-ModuleConsistency.ps1
##
################################################################################

#Requires -Version 5.1

param(
    [Parameter(Mandatory=$false)]
    [string]$ActivityModulesPath = ".",
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigActivityFile = "..\..\DSP-Demo-Config-Activity.psd1"
)

# Resolve paths
$ActivityModulesPath = Resolve-Path -Path $ActivityModulesPath
$ConfigActivityFile = Resolve-Path -Path $ConfigActivityFile

Write-Host "Activity modules path: $ActivityModulesPath" -ForegroundColor Cyan
Write-Host "Config file: $ConfigActivityFile" -ForegroundColor Cyan
Write-Host ""

# Load config
if (-not (Test-Path $ConfigActivityFile)) {
    Write-Host "ERROR: Config file not found" -ForegroundColor Red
    exit 1
}

$config = Import-PowerShellDataFile -Path $ConfigActivityFile

# Extract config keys
$moduleMap = @{}
foreach ($key in $config.Keys) {
    if ($key -match '^Module(\d+)_(.+)$') {
        $moduleNum = [int]$matches[1]
        $moduleName = $matches[2]
        $moduleMap[$moduleNum] = $moduleName
    }
}

Write-Host "Found $($moduleMap.Count) module definitions in config" -ForegroundColor Green
Write-Host ""

# Audit each file
$issues = @()
$activityFiles = Get-ChildItem -Path $ActivityModulesPath -Filter "DSP-Demo-Activity-*.psm1" | Sort-Object Name

foreach ($file in $activityFiles) {
    if ($file.BaseName -match 'DSP-Demo-Activity-(\d+)-(.+)$') {
        $moduleNum = [int]$matches[1]
        $fileName = $matches[2]
        
        if (-not $moduleMap.ContainsKey($moduleNum)) {
            Write-Host "[$moduleNum] ❌ NOT IN CONFIG" -ForegroundColor Red
            $issues += "Module $moduleNum not in config"
            continue
        }
        
        $expectedName = $moduleMap[$moduleNum]
        
        # Check filename
        if ($fileName -ne $expectedName) {
            Write-Host "[$moduleNum] ❌ FILENAME MISMATCH" -ForegroundColor Red
            Write-Host "     Expected: DSP-Demo-Activity-$moduleNum-$expectedName.psm1" -ForegroundColor Yellow
            Write-Host "     Got:      $($file.Name)" -ForegroundColor Yellow
            $issues += "Module $moduleNum filename mismatch"
        }
        else {
            Write-Host "[$moduleNum] ✓ Filename OK" -ForegroundColor Green
        }
        
        # Extract function name from file
        $content = Get-Content $file.FullName -Raw
        $funcMatch = $content | Select-String 'function\s+(Invoke-\S+)\s*\{'
        
        if ($funcMatch) {
            $actualFunc = $funcMatch.Matches[0].Groups[1].Value
            $expectedFunc = "Invoke-$expectedName"
            
            if ($actualFunc -ne $expectedFunc) {
                Write-Host "     ❌ FUNCTION MISMATCH" -ForegroundColor Red
                Write-Host "        Expected: $expectedFunc" -ForegroundColor Yellow
                Write-Host "        Got:      $actualFunc" -ForegroundColor Yellow
                $issues += "Module $moduleNum function mismatch"
            }
            else {
                Write-Host "     ✓ Function OK" -ForegroundColor Green
            }
        }
        else {
            Write-Host "     ❌ NO FUNCTION FOUND" -ForegroundColor Red
            $issues += "Module $moduleNum no function found"
        }
        
        # Check config key reference
        $configKeyMatch = $content | Select-String "Module$moduleNum" -SimpleMatch
        if ($configKeyMatch) {
            Write-Host "     ✓ Config key referenced" -ForegroundColor Green
        }
        else {
            Write-Host "     ⚠️  NO CONFIG KEY REFERENCE" -ForegroundColor Yellow
            $issues += "Module $moduleNum missing config key reference"
        }
    }
    
    Write-Host ""
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
if ($issues.Count -eq 0) {
    Write-Host "All modules are consistent! ✓" -ForegroundColor Green
}
else {
    Write-Host "$($issues.Count) issue(s) found:" -ForegroundColor Red
    foreach ($issue in $issues) {
        Write-Host "  - $issue" -ForegroundColor Red
    }
}
Write-Host "========================================" -ForegroundColor Cyan