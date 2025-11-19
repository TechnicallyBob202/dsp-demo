################################################################################
##
## DSP-Demo-Diagnostic-Tool.ps1
##
## Comprehensive diagnostic tool to identify module configuration issues
## Run this to get detailed information about what's wrong and how to fix it
##
################################################################################

#Requires -Version 5.1
#Requires -RunAsAdministrator

[CmdletBinding()]
param()

$ErrorActionPreference = "Continue"

################################################################################
# COLOR AND FORMATTING
################################################################################

$Colors = @{
    Header = 'Cyan'
    Section = 'Green'
    Success = 'Green'
    Warning = 'Yellow'
    Error = 'Red'
    Info = 'White'
    Debug = 'Gray'
}

function Write-DiagHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host "=" * 80 -ForegroundColor $Colors.Header
    Write-Host $Title -ForegroundColor $Colors.Header
    Write-Host "=" * 80 -ForegroundColor $Colors.Header
    Write-Host ""
}

function Write-DiagSection {
    param([string]$Title)
    Write-Host ""
    Write-Host ">> $Title" -ForegroundColor $Colors.Section
    Write-Host "-" * 80 -ForegroundColor $Colors.Section
}

function Write-DiagResult {
    param(
        [string]$Test,
        [string]$Result,
        [string]$Color,
        [string]$Details = ""
    )
    
    $message = "  [$Result] $Test"
    if ($Details) {
        $message += " - $Details"
    }
    
    Write-Host $message -ForegroundColor $Color
}

################################################################################
# DIAGNOSTIC FUNCTIONS
################################################################################

function Test-DSPEnvironment {
    Write-DiagSection "Environment Checks"
    
    # Check PowerShell version
    Write-Host "  PowerShell: $($PSVersionTable.PSVersion)" -ForegroundColor $Colors.Info
    Write-Host "  Edition: $($PSVersionTable.PSEdition)" -ForegroundColor $Colors.Info
    Write-Host "  OS: $([System.Runtime.InteropServices.RuntimeInformation]::OSDescription)" -ForegroundColor $Colors.Info
    Write-Host ""
    
    # Check admin rights
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if ($isAdmin) {
        Write-DiagResult "Administrator Rights" "OK" $Colors.Success
    }
    else {
        Write-DiagResult "Administrator Rights" "FAIL" $Colors.Error "Script requires admin rights"
    }
}

function Test-DSPModulePaths {
    Write-DiagSection "Module Path Configuration"
    
    Write-Host "  PSModulePath entries:" -ForegroundColor $Colors.Info
    $env:PSModulePath -split [System.IO.Path]::PathSeparator | ForEach-Object {
        Write-Host "    - $_" -ForegroundColor $Colors.Debug
    }
    Write-Host ""
}

function Test-DSPDirectories {
    Write-DiagSection "Directory Structure"
    
    $baseDir = "C:\Semperis\Scripts\DSP-Demo"
    $modulesDir = Join-Path $baseDir "modules"
    
    Write-Host "  Base Directory: $baseDir" -ForegroundColor $Colors.Info
    
    if (Test-Path $baseDir) {
        Write-DiagResult "Base Directory" "EXISTS" $Colors.Success
    }
    else {
        Write-DiagResult "Base Directory" "MISSING" $Colors.Error
        Write-Host "    Expected at: $baseDir" -ForegroundColor $Colors.Error
    }
    
    Write-Host ""
    Write-Host "  Modules Directory: $modulesDir" -ForegroundColor $Colors.Info
    
    if (Test-Path $modulesDir) {
        Write-DiagResult "Modules Directory" "EXISTS" $Colors.Success
        
        # List module files
        Write-Host ""
        Write-Host "    Contents:" -ForegroundColor $Colors.Debug
        Get-ChildItem $modulesDir -Filter "*.psm1" | ForEach-Object {
            Write-Host "      - $($_.Name) ($($_.Length) bytes)" -ForegroundColor $Colors.Debug
        }
    }
    else {
        Write-DiagResult "Modules Directory" "MISSING" $Colors.Error
        Write-Host "    Expected at: $modulesDir" -ForegroundColor $Colors.Error
        Write-Host "    Create it with: mkdir $modulesDir" -ForegroundColor $Colors.Warning
    }
    
    Write-Host ""
}

function Test-DSPModuleFiles {
    Write-DiagSection "Module File Analysis"
    
    $modulesDir = "C:\Semperis\Scripts\DSP-Demo\modules"
    
    if (-not (Test-Path $modulesDir)) {
        Write-DiagResult "Modules Directory" "SKIP" $Colors.Warning "Directory not found"
        return
    }
    
    $psm1Files = @(
        "DSP-Demo-01-Core.psm1",
        "DSP-Demo-02-AD-Discovery.psm1"
    )
    
    foreach ($file in $psm1Files) {
        $filePath = Join-Path $modulesDir $file
        
        Write-Host ""
        Write-Host "  File: $file" -ForegroundColor $Colors.Info
        
        if (-not (Test-Path $filePath)) {
            Write-DiagResult "File Exists" "MISSING" $Colors.Error
            continue
        }
        
        Write-DiagResult "File Exists" "OK" $Colors.Success
        
        # Check file size
        $fileInfo = Get-Item $filePath
        Write-Host "    Size: $($fileInfo.Length) bytes" -ForegroundColor $Colors.Debug
        Write-Host "    Modified: $($fileInfo.LastWriteTime)" -ForegroundColor $Colors.Debug
        
        # Check for syntax errors
        Write-Host ""
        Write-Host "    Checking syntax..." -ForegroundColor $Colors.Debug
        
        try {
            $ast = $null
            $tokens = $null
            $parseErrors = $null
            
            [System.Management.Automation.Language.Parser]::ParseFile(
                $filePath,
                [ref]$tokens,
                [ref]$parseErrors
            ) > $null
            
            if ($parseErrors.Count -gt 0) {
                Write-DiagResult "Syntax" "ERROR" $Colors.Error "Parse errors found"
                $parseErrors | ForEach-Object {
                    Write-Host "      Line $($_.Extent.StartLineNumber): $($_.Message)" -ForegroundColor $Colors.Error
                }
            }
            else {
                Write-DiagResult "Syntax" "OK" $Colors.Success "No parse errors"
            }
        }
        catch {
            Write-DiagResult "Syntax Check" "FAIL" $Colors.Error $_.Exception.Message
        }
        
        # Check for Export-ModuleMember
        Write-Host ""
        Write-Host "    Checking exports..." -ForegroundColor $Colors.Debug
        
        $content = Get-Content $filePath -Raw
        
        if ($content -match "Export-ModuleMember") {
            Write-DiagResult "Export-ModuleMember" "FOUND" $Colors.Success
            
            # Extract export line
            $exportMatch = $content -match "Export-ModuleMember[^`n]*"
            if ($exportMatch) {
                Write-Host "      Statement: $($matches[0].Substring(0, [Math]::Min(70, $matches[0].Length)))..." -ForegroundColor $Colors.Debug
            }
        }
        else {
            Write-DiagResult "Export-ModuleMember" "MISSING" $Colors.Error "Functions may not be exported!"
        }
        
        # Check for function definitions
        Write-Host ""
        Write-Host "    Checking function definitions..." -ForegroundColor $Colors.Debug
        
        $functionMatches = $content | Select-String -Pattern "^\s*function\s+(\w+)" -AllMatches | 
            ForEach-Object { $_.Matches.Groups[1].Value }
        
        if ($functionMatches.Count -gt 0) {
            Write-Host "      Functions defined: $($functionMatches.Count)" -ForegroundColor $Colors.Success
            $functionMatches | ForEach-Object {
                Write-Host "        - $_" -ForegroundColor $Colors.Debug
            }
        }
        else {
            Write-Host "      No function definitions found" -ForegroundColor $Colors.Warning
        }
    }
}

function Test-DSPModuleImport {
    Write-DiagSection "Module Import Test"
    
    $modulesDir = "C:\Semperis\Scripts\DSP-Demo\modules"
    
    if (-not (Test-Path $modulesDir)) {
        Write-DiagResult "Modules Directory" "SKIP" $Colors.Warning "Directory not found"
        return
    }
    
    # Clean up any existing imports
    Remove-Module DSP-Demo* -ErrorAction SilentlyContinue
    
    $coreModulePath = Join-Path $modulesDir "DSP-Demo-01-Core.psm1"
    
    if (-not (Test-Path $coreModulePath)) {
        Write-DiagResult "Core Module File" "SKIP" $Colors.Warning "File not found"
        return
    }
    
    Write-Host "  Attempting to import: DSP-Demo-01-Core.psm1" -ForegroundColor $Colors.Info
    
    try {
        Import-Module $coreModulePath -Force -ErrorAction Stop
        Write-DiagResult "Module Import" "SUCCESS" $Colors.Success
        
        # Check what was exported
        Write-Host ""
        Write-Host "  Exported Functions:" -ForegroundColor $Colors.Info
        
        $module = Get-Module | Where-Object {$_.Name -eq "DSP-Demo-01-Core"}
        
        if ($module.ExportedFunctions.Count -eq 0) {
            Write-DiagResult "Exports" "NONE" $Colors.Error "No functions exported!"
        }
        else {
            Write-DiagResult "Exports" "COUNT" $Colors.Success "$($module.ExportedFunctions.Count) functions"
            
            $module.ExportedFunctions.Keys | ForEach-Object {
                $cmd = Get-Command $_ -ErrorAction SilentlyContinue
                if ($cmd) {
                    Write-Host "    ✓ $_" -ForegroundColor $Colors.Success
                }
                else {
                    Write-Host "    ✗ $_ (not callable)" -ForegroundColor $Colors.Error
                }
            }
        }
        
        # Test function execution
        Write-Host ""
        Write-Host "  Function Execution Test:" -ForegroundColor $Colors.Info
        
        if (Get-Command Write-DspLog -ErrorAction SilentlyContinue) {
            try {
                Write-DspLog "Test message" -Level Success
                Write-DiagResult "Write-DspLog" "OK" $Colors.Success "Function executed"
            }
            catch {
                Write-DiagResult "Write-DspLog" "ERROR" $Colors.Error $_.Exception.Message
            }
        }
        else {
            Write-DiagResult "Write-DspLog" "NOTFOUND" $Colors.Error "Function not exported"
        }
    }
    catch {
        Write-DiagResult "Module Import" "FAILED" $Colors.Error $_.Exception.Message
    }
}

################################################################################
# RECOMMENDATIONS
################################################################################

function Show-Recommendations {
    Write-DiagSection "Recommendations"
    
    $modulesDir = "C:\Semperis\Scripts\DSP-Demo\modules"
    $coreModulePath = Join-Path $modulesDir "DSP-Demo-01-Core.psm1"
    
    # Gather all issues
    $issues = @()
    
    if (-not (Test-Path $modulesDir)) {
        $issues += "Modules directory missing"
    }
    
    if (-not (Test-Path $coreModulePath)) {
        $issues += "Core module file missing"
    }
    elseif (Test-Path $coreModulePath) {
        $content = Get-Content $coreModulePath -Raw
        if ($content -notmatch "Export-ModuleMember") {
            $issues += "Core module missing Export-ModuleMember"
        }
    }
    
    if ($issues.Count -eq 0) {
        Write-Host "✓ No issues detected!" -ForegroundColor $Colors.Success
        Write-Host ""
        Write-Host "Your DSP Demo environment appears to be properly configured." -ForegroundColor $Colors.Success
    }
    else {
        Write-Host "Issues Found:" -ForegroundColor $Colors.Error
        Write-Host ""
        
        $issues | ForEach-Object {
            Write-Host "  ✗ $_" -ForegroundColor $Colors.Error
        }
        
        Write-Host ""
        Write-Host "Steps to Fix:" -ForegroundColor $Colors.Warning
        
        if ($issues -contains "Modules directory missing") {
            Write-Host ""
            Write-Host "  1. Create modules directory:" -ForegroundColor $Colors.Warning
            Write-Host "     New-Item -ItemType Directory -Path 'C:\Semperis\Scripts\DSP-Demo\modules' -Force" -ForegroundColor $Colors.Info
        }
        
        if ($issues -contains "Core module missing Export-ModuleMember") {
            Write-Host ""
            Write-Host "  2. Add Export-ModuleMember to Core module:" -ForegroundColor $Colors.Warning
            Write-Host "     Open: $coreModulePath" -ForegroundColor $Colors.Info
            Write-Host "     Add to END of file:" -ForegroundColor $Colors.Info
            Write-Host "     Export-ModuleMember -Function @('Write-DspHeader','Write-DspLog',...)" -ForegroundColor $Colors.Info
        }
        
        Write-Host ""
        Write-Host "  See the troubleshooting guide for detailed steps." -ForegroundColor $Colors.Warning
    }
}

################################################################################
# MAIN EXECUTION
################################################################################

Write-DiagHeader "DSP DEMO DIAGNOSTIC TOOL"

Write-Host "This tool will diagnose issues with your DSP Demo module setup." -ForegroundColor $Colors.Info
Write-Host "Run time: $(Get-Date)" -ForegroundColor $Colors.Info
Write-Host ""

Test-DSPEnvironment
Test-DSPModulePaths
Test-DSPDirectories
Test-DSPModuleFiles
Test-DSPModuleImport

Show-Recommendations

Write-DiagHeader "DIAGNOSTIC COMPLETE"
Write-Host "Review the results above and the troubleshooting guide for next steps." -ForegroundColor $Colors.Info
Write-Host ""