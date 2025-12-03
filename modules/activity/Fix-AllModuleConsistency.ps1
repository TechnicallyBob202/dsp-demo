################################################################################
##
## Fix-AllModuleConsistency.ps1
##
## Fixes all activity modules to have consistent:
## 1. Function names matching config
## 2. Config key references in code
## 3. Header comments
##
## Run from activity folder: .\Fix-AllModuleConsistency.ps1
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

# Fix each file
$fixedCount = 0
$activityFiles = Get-ChildItem -Path $ActivityModulesPath -Filter "DSP-Demo-Activity-*.psm1" | Sort-Object Name

foreach ($file in $activityFiles) {
    if ($file.BaseName -match 'DSP-Demo-Activity-(\d+)-(.+)$') {
        $moduleNum = [int]$matches[1]
        
        if (-not $moduleMap.ContainsKey($moduleNum)) {
            Write-Host "[$moduleNum] Skipping - not in config" -ForegroundColor Yellow
            continue
        }
        
        $expectedName = $moduleMap[$moduleNum]
        $expectedFunc = "Invoke-$expectedName"
        $configKey = "Module${moduleNum}_$expectedName"
        
        Write-Host "[$moduleNum] Processing: $($file.Name)" -ForegroundColor Cyan
        
        $content = Get-Content $file.FullName -Raw
        $originalContent = $content
        $changed = $false
        
        # 1. Find old function name and replace
        $funcMatch = $content | Select-String 'function\s+(Invoke-\S+)\s*\{'
        if ($funcMatch) {
            $oldFunc = $funcMatch.Matches[0].Groups[1].Value
            if ($oldFunc -ne $expectedFunc) {
                Write-Host "     Replacing function: $oldFunc → $expectedFunc" -ForegroundColor Yellow
                $content = $content -replace "function\s+$([regex]::Escape($oldFunc))\s*\{", "function $expectedFunc {"
                
                # Also replace in Export-ModuleMember
                $content = $content -replace "Export-ModuleMember\s+-Function\s+$([regex]::Escape($oldFunc))", "Export-ModuleMember -Function $expectedFunc"
                $changed = $true
            }
        }
        
        # 2. Add config key reference if missing
        if ($content -notmatch "\`$ModuleConfig\s*=\s*\`$Config\.$configKey") {
            # Find the line with $DomainInfo assignment and add after it
            if ($content -match '\$DomainInfo\s*=\s*\$Environment\.DomainInfo') {
                Write-Host "     Adding config key reference" -ForegroundColor Yellow
                $content = $content -replace '(\$DomainInfo\s*=\s*\$Environment\.DomainInfo)', "`$DomainInfo = `$Environment.DomainInfo`n    `$ModuleConfig = `$Config.$configKey"
                $changed = $true
            }
        }
        
        # 3. Update header comment if it has wrong module name
        $content = $content -replace "## DSP-Demo-Activity-$moduleNum-\S+\.psm1", "## DSP-Demo-Activity-$moduleNum-$expectedName.psm1"
        
        if ($content -ne $originalContent) {
            Write-Host "     ✓ Saving changes" -ForegroundColor Green
            Set-Content -Path $file.FullName -Value $content
            $fixedCount++
        }
        else {
            Write-Host "     No changes needed" -ForegroundColor Green
        }
    }
    
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Fixed $fixedCount modules" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan