################################################################################
##
## DSP-Demo-MainScript.ps1
##
## Main orchestration script for DSP demo activity generation
## 
## Linear flow:
## 1. Preflight checks (report results, 10 sec pause)
## 2. Setup phase (load setup config, load modules from setup folder, execute)
## 3. Activity phase (load activity config, load modules from activity folder, execute)
##
## Original Author: Rob Ingenthron (robi@semperis.com)
## Refactored By: Bob Lyons
## Version: 7.1.0-20251202
##
## This is a complete refactor of Rob's original monolithic script
## (Invoke-CreateDspChangeDataForDemos-20251002_0012.ps1) into a modular,
## configuration-driven architecture for improved maintainability and
## operator control.
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory
#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$SetupConfigPath,
    
    [Parameter(Mandatory=$false)]
    [string]$ActivityConfigPath,
    
    [Parameter(Mandatory=$false)]
    [string]$LogPath
)

$ErrorActionPreference = "Continue"

################################################################################
# INITIALIZATION
################################################################################

$Script:ScriptPath = $PSScriptRoot
$Script:ModulesPath = Join-Path $ScriptPath "modules"

# Setup config
$Script:SetupConfigFile = if ($SetupConfigPath) { 
    $SetupConfigPath 
} 
else { 
    $defaultPath = Join-Path $ScriptPath "DSP-Demo-Config-Setup.psd1"
    if (Test-Path $defaultPath) { $defaultPath }
    else { Join-Path $ScriptPath "DSP-Demo-Config-Setup.psd1" }
}

# Activity config
$Script:ActivityConfigFile = if ($ActivityConfigPath) { 
    $ActivityConfigPath 
} 
else { 
    $defaultPath = Join-Path $ScriptPath "DSP-Demo-Config-Activity.psd1"
    if (Test-Path $defaultPath) { $defaultPath }
    else { Join-Path $ScriptPath "DSP-Demo-Config-Activity.psd1" }
}

################################################################################
# COLORS
################################################################################

$Colors = @{
    Header = 'Cyan'
    Section = 'Green'
    Success = 'Green'
    Warning = 'Yellow'
    Error = 'Red'
    Info = 'White'
    Prompt = 'Yellow'
}

################################################################################
# OUTPUT FUNCTIONS
################################################################################

function Write-Status {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Info','Success','Warning','Error')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = $Colors[$Level]
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Write-Header {
    param([Parameter(Mandatory=$true)][string]$Title)
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor $Colors.Header
    Write-Host $Title -ForegroundColor $Colors.Header
    Write-Host ("=" * 80) -ForegroundColor $Colors.Header
    Write-Host ""
}

################################################################################
# CONFIGURATION FUNCTIONS
################################################################################

function Load-Configuration {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ConfigFile
    )
    
    if (-not (Test-Path $ConfigFile)) {
        throw "Configuration file not found: $ConfigFile"
    }
    
    $config = & ([scriptblock]::Create([io.file]::ReadAllText($ConfigFile)))
    return $config
}

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

function Wait-ForConfirmation {
    param(
        [Parameter(Mandatory=$true)]
        [int]$TimeoutSeconds,
        
        [Parameter(Mandatory=$true)]
        [string]$Prompt
    )
    
    Write-Host ""
    Write-Host $Prompt -ForegroundColor $Colors.Prompt
    Write-Host ""
    
    $confirmationTimer = 0
    $proceed = $null
    
    while ($confirmationTimer -lt $TimeoutSeconds) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true).KeyChar
            if ($key -eq 'Y' -or $key -eq 'y') {
                $proceed = $true
                break
            }
            elseif ($key -eq 'N' -or $key -eq 'n') {
                $proceed = $false
                break
            }
        }
        
        $remaining = $TimeoutSeconds - $confirmationTimer
        Write-Host "`rPress Y/N (auto-proceeding in $remaining seconds)..." -ForegroundColor $Colors.Warning -NoNewline
        Start-Sleep -Seconds 1
        $confirmationTimer++
    }
    
    # Default to proceed if timeout reached
    if ($null -eq $proceed) {
        $proceed = $true
    }
    
    Write-Host ""
    return $proceed
}

function Get-ModuleDisplayName {
    param([Parameter(Mandatory=$true)][string]$ModuleName)
    
    # Extract the readable name from module filename
    # DSP-Demo-Setup-01-BuildOUs → BuildOUs
    # DSP-Demo-Activity-01-DirectoryActivity → DirectoryActivity
    $name = $ModuleName -replace "^DSP-Demo-(Setup|Activity)-\d+-", ""
    return $name
}

################################################################################
# MAIN FUNCTION
################################################################################

function Main {
    Write-Header "DSP Demo Activity Generation"
    
    Write-Status "Script path: $Script:ScriptPath" -Level Info
    Write-Status "Setup config: $Script:SetupConfigFile" -Level Info
    Write-Status "Activity config: $Script:ActivityConfigFile" -Level Info
    Write-Host ""
    
    # Create modules directory if needed
    if (-not (Test-Path $Script:ModulesPath)) {
        Write-Status "Creating modules directory..." -Level Info
        New-Item -ItemType Directory -Path $Script:ModulesPath -Force | Out-Null
    }
    
    # Import Preflight module (stays at root level)
    Write-Status "Importing Preflight module..." -Level Info
    $preflightPath = Join-Path $Script:ModulesPath "DSP-Demo-Preflight.psm1"
    
    if (-not (Test-Path $preflightPath)) {
        Write-Status "FATAL: Preflight module not found at $preflightPath" -Level Error
        exit 1
    }
    
    try {
        Import-Module $preflightPath -Force -ErrorAction Stop | Out-Null
        Write-Status "Loaded: DSP-Demo-Preflight" -Level Success
    }
    catch {
        Write-Status "FATAL: Cannot import Preflight module: $_" -Level Error
        exit 1
    }
    
    Write-Host ""
    
    # ========================================================================
    # PHASE 1: PREFLIGHT
    # ========================================================================
    
    Write-Status "Running preflight checks..." -Level Info
    
    # Load setup config for preflight (to access General.DspServer if needed)
    try {
        $setupConfig = Load-Configuration -ConfigFile $Script:SetupConfigFile
        Write-Status "Setup configuration loaded" -Level Success
    }
    catch {
        Write-Status "FATAL: Cannot load setup configuration" -Level Error
        exit 1
    }
    
    Write-Host ""
    
    try {
        $environment = Initialize-PreflightEnvironment -Config $setupConfig
    }
    catch {
        Write-Status "FATAL: Preflight checks failed" -Level Error
        Write-Host ""
        exit 1
    }
    
    Write-Status "Preflight checks completed successfully" -Level Success
    Write-Host ""
    
    # Pause after preflight
    if (-not (Wait-ForConfirmation -TimeoutSeconds 10 -Prompt "Preflight passed. Continue with setup phase?")) {
        Write-Status "User cancelled after preflight" -Level Warning
        exit 0
    }
    
    # Expand placeholders in setup config
    try {
        $setupConfig = Expand-ConfigPlaceholders -Config $setupConfig -DomainInfo $environment.DomainInfo
    }
    catch {
        Write-Status "Failed to expand setup configuration placeholders: $_" -Level Error
    }
    
    Write-Host ""
    
    # ========================================================================
    # PHASE 2: SETUP
    # ========================================================================
    
    Write-Header "Setup Phase"
    
    # Discover setup modules from setup folder
    $setupPath = Join-Path $Script:ModulesPath "setup"
    $setupModules = @()
    
    if (Test-Path $setupPath) {
        $setupModuleFiles = Get-ChildItem -Path $setupPath -Filter "*.psm1" -ErrorAction SilentlyContinue | Sort-Object Name
        $setupModules = $setupModuleFiles
    }
    
    if ($setupModules.Count -eq 0) {
        Write-Status "No setup modules found in $setupPath - skipping setup phase" -Level Warning
        Write-Host ""
    }
    else {
        Write-Status "Found $($setupModules.Count) setup module(s) in $setupPath" -Level Info
        Write-Host ""
        
        # Load setup modules
        $loadedSetupModules = @()
        foreach ($moduleFile in $setupModules) {
            try {
                Import-Module $moduleFile.FullName -Force -ErrorAction Stop | Out-Null
                Write-Status "Loaded: $($moduleFile.BaseName)" -Level Success
                $loadedSetupModules += $moduleFile.BaseName
            }
            catch {
                Write-Status "Failed to load $($moduleFile.BaseName): $_" -Level Error
            }
        }
        
        Write-Host ""
        
        if ($loadedSetupModules.Count -eq 0) {
            Write-Status "No setup modules loaded successfully - skipping setup phase" -Level Warning
            Write-Host ""
        }
        else {
            # Pause before setup execution
            if (-not (Wait-ForConfirmation -TimeoutSeconds 30 -Prompt "Execute setup modules?")) {
                Write-Status "User cancelled after preflight" -Level Warning
                Write-Host ""
                exit 0
            }
            
            # Execute setup modules
            Write-Header "Executing Setup Modules"
            
            $setupCompleted = 0
            $setupFailed = 0
            
            foreach ($moduleName in $loadedSetupModules) {
                $functionName = "Invoke-" + (Get-ModuleDisplayName $moduleName)
                
                if (Get-Command $functionName -ErrorAction SilentlyContinue) {
                    try {
                        Write-Status "Running: $functionName" -Level Info
                        & $functionName -Config $setupConfig -Environment $environment
                        Write-Status "$functionName completed" -Level Success
                        $setupCompleted++
                    }
                    catch {
                        Write-Status "Error in $functionName : $_" -Level Error
                        $setupFailed++
                    }
                }
                else {
                    Write-Status "Function $functionName not found - skipping" -Level Warning
                    $setupFailed++
                }
                
                Write-Host ""
            }
            
            Write-Header "Setup Phase Summary"
            Write-Host "Completed: $setupCompleted" -ForegroundColor $Colors.Success
            if ($setupFailed -gt 0) {
                Write-Host "Failed: $setupFailed" -ForegroundColor $Colors.Error
            }
            Write-Host ""
        }
    }
    
    Write-Host ""
    
    # ========================================================================
    # PHASE 3: ACTIVITY
    # ========================================================================
    
    Write-Header "Activity Phase"
    
    # Load activity config
    try {
        $activityConfig = Load-Configuration -ConfigFile $Script:ActivityConfigFile
        Write-Status "Activity configuration loaded" -Level Success
    }
    catch {
        Write-Status "WARNING: Cannot load activity configuration - skipping activity phase" -Level Warning
        Write-Host ""
        exit 0
    }
    
    # Expand placeholders in activity config
    try {
        $activityConfig = Expand-ConfigPlaceholders -Config $activityConfig -DomainInfo $environment.DomainInfo
    }
    catch {
        Write-Status "Failed to expand activity configuration placeholders: $_" -Level Error
    }
    
    Write-Host ""
    
    # Discover activity modules from activity folder
    $activityPath = Join-Path $Script:ModulesPath "activity"
    $activityModules = @()
    
    if (Test-Path $activityPath) {
        $activityModuleFiles = Get-ChildItem -Path $activityPath -Filter "*.psm1" -ErrorAction SilentlyContinue | Sort-Object Name
        $activityModules = $activityModuleFiles
    }
    
    if ($activityModules.Count -eq 0) {
        Write-Status "No activity modules found in $activityPath - skipping activity phase" -Level Info
        Write-Host ""
    }
    else {
        Write-Status "Found $($activityModules.Count) activity module(s) in $activityPath" -Level Info
        Write-Host ""
        
        # Load activity modules
        $loadedActivityModules = @()
        foreach ($moduleFile in $activityModules) {
            try {
                Import-Module $moduleFile.FullName -Force -ErrorAction Stop | Out-Null
                Write-Status "Loaded: $($moduleFile.BaseName)" -Level Success
                $loadedActivityModules += $moduleFile.BaseName
            }
            catch {
                Write-Status "Failed to load $($moduleFile.BaseName): $_" -Level Error
            }
        }
        
        Write-Host ""
        
        if ($loadedActivityModules.Count -eq 0) {
            Write-Status "No activity modules loaded successfully - skipping activity phase" -Level Warning
            Write-Host ""
        }
        else {
            # Pause before activity execution
            if (-not (Wait-ForConfirmation -TimeoutSeconds 30 -Prompt "Execute activity modules?")) {
                Write-Status "User cancelled activity phase" -Level Warning
                Write-Host ""
                exit 0
            }
            
            # Execute activity modules
            Write-Header "Executing Activity Modules"
            
            $activityCompleted = 0
            $activityFailed = 0
            
            foreach ($moduleName in $loadedActivityModules) {
                $functionName = "Invoke-" + (Get-ModuleDisplayName $moduleName)
                
                if (Get-Command $functionName -ErrorAction SilentlyContinue) {
                    try {
                        Write-Status "Running: $functionName" -Level Info
                        & $functionName -Config $activityConfig -Environment $environment
                        Write-Status "$functionName completed" -Level Success
                        $activityCompleted++
                    }
                    catch {
                        Write-Status "Error in $functionName : $_" -Level Error
                        $activityFailed++
                    }
                }
                else {
                    Write-Status "Function $functionName not found - skipping" -Level Warning
                    $activityFailed++
                }
                
                Write-Host ""
            }
            
            Write-Header "Activity Phase Summary"
            Write-Host "Completed: $activityCompleted" -ForegroundColor $Colors.Success
            if ($activityFailed -gt 0) {
                Write-Host "Failed: $activityFailed" -ForegroundColor $Colors.Error
            }
            Write-Host ""
        }
    }
    
    # ========================================================================
    # COMPLETION
    # ========================================================================
    
    Write-Header "DSP Demo Activity Generation Complete"
    Write-Host "All phases completed successfully" -ForegroundColor $Colors.Success
    Write-Host ""
}

################################################################################
# SCRIPT ENTRY POINT
################################################################################

try {
    Main
}
catch {
    Write-Host ""
    Write-Host "FATAL ERROR: $_" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    Write-Host ""
    exit 1
}

################################################################################
# END OF SCRIPT
################################################################################