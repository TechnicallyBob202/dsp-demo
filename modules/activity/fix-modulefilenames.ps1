################################################################################
##
## Fix-ModuleFileNames.ps1
##
## Renames activity module files to match the config-activity file naming
## Reads Module##_ConfigKey from config and renames files accordingly
##
## Usage from activity folder:
##   .\Fix-ModuleFileNames.ps1
##
## Or specify paths:
##   .\Fix-ModuleFileNames.ps1 -ActivityModulesPath "." -ConfigActivityFile "..\..\DSP-Demo-Config-Activity.psd1"
##
################################################################################

#Requires -Version 5.1

param(
    [Parameter(Mandatory=$false)]
    [string]$ActivityModulesPath = ".",
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigActivityFile = "..\..\DSP-Demo-Config-Activity.psd1"
)

# Resolve to absolute paths
$ActivityModulesPath = Resolve-Path -Path $ActivityModulesPath
$ConfigActivityFile = Resolve-Path -Path $ConfigActivityFile

Write-Host "Activity modules path: $ActivityModulesPath" -ForegroundColor Cyan
Write-Host "Config file: $ConfigActivityFile" -ForegroundColor Cyan
Write-Host ""

# Load config
if (-not (Test-Path $ConfigActivityFile)) {
    Write-Host "ERROR: Config file not found at $ConfigActivityFile" -ForegroundColor Red
    exit 1
}

Write-Host "Loading config..." -ForegroundColor Cyan
$config = Import-PowerShellDataFile -Path $ConfigActivityFile

# Extract module naming mappings from config keys
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

# Process each activity module file
$activityFiles = Get-ChildItem -Path $ActivityModulesPath -Filter "DSP-Demo-Activity-*.psm1" | Sort-Object Name

if ($activityFiles.Count -eq 0) {
    Write-Host "No activity module files found in $ActivityModulesPath" -ForegroundColor Yellow
    exit 1
}

Write-Host "Processing $($activityFiles.Count) module file(s)..." -ForegroundColor Cyan
Write-Host ""

foreach ($file in $activityFiles) {
    # Extract module number from filename
    if ($file.BaseName -match 'DSP-Demo-Activity-(\d+)-') {
        $moduleNum = [int]$matches[1]
        
        if ($moduleMap.ContainsKey($moduleNum)) {
            $newName = "DSP-Demo-Activity-$('{0:D2}' -f $moduleNum)-$($moduleMap[$moduleNum]).psm1"
            
            if ($file.Name -ne $newName) {
                Write-Host "Renaming module ${moduleNum}:" -ForegroundColor Yellow
                Write-Host "  Old: $($file.Name)" -ForegroundColor Red
                Write-Host "  New: $newName" -ForegroundColor Green
                
                try {
                    Rename-Item -Path $file.FullName -NewName $newName -ErrorAction Stop
                    Write-Host "  ✓ Success" -ForegroundColor Green
                }
                catch {
                    Write-Host "  ✗ Error: $_" -ForegroundColor Red
                }
            }
            else {
                Write-Host "Module ${moduleNum} already has correct name: $($file.Name)" -ForegroundColor Green
            }
        }
        else {
            Write-Host "Module $moduleNum not found in config - skipping" -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "Could not extract module number from: $($file.Name)" -ForegroundColor Yellow
    }
    
    Write-Host ""
}

Write-Host "Done!" -ForegroundColor Cyan