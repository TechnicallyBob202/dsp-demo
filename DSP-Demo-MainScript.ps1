################################################################################
##
## DSP-Demo-MainScript.ps1
##
## Main orchestration script for DSP demo activity generation
## 
## Linear flow:
## 1. Preflight checks (report results, 10 sec pause)
## 2. Setup phase (load modules, list them, 30 sec pause, execute)
## 3. Activity phase (load modules, list them, 30 sec pause, execute)
##
## Author: Bob Lyons
## Version: 6.0.0-20251202
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory
#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath,
    
    [Parameter(Mandatory=$false)]
    [string]$LogPath
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
    $defaultPath = Join-Path $ScriptPath "DSP-Demo-Config.psd1"
    if (Test-Path $defaultPath) { $defaultPath }
    else { Join-Path $ScriptPath "DSP-Demo-Config.psd1" }
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
    Prompt = 'Magenta'
}

################################################################################
# HELPER FUNCTIONS
################################################################################

function Write-Status {
    param(
        [string]$Message,
        [ValidateSet('Info','Success','Warning','Error')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = $Colors[$Level]
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Write-Header {
    param([string]$Title)
    Write-Host ""
    Write-Host ("=" * 80) -ForegroundColor $Colors.Header
    Write-Host $Title -ForegroundColor $Colors.Header
    Write-Host ("=" * 80) -ForegroundColor $Colors.Header
    Write-Host ""
}

function Load-Configuration {
    param([Parameter(Mandatory=$true)][string]$ConfigFile)
    
    if (-not (Test-Path $ConfigFile)) {
        Write-Status "Configuration file not found: $ConfigFile" -Level Error
        throw "Configuration file not found: $ConfigFile"
    }
    
    try {
        $config = Import-PowerShellDataFile $ConfigFile -ErrorAction Stop
        return $config
    }
    catch {
        Write-Status "Failed to load configuration: $_" -Level Error
        throw $_
    }
}

function Expand-ConfigPlaceholders {
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)][PSCustomObject]$DomainInfo
    )
    
    $placeholders = @{
        '{DOMAIN_DN}' = $DomainInfo.DN
        '{DOMAIN_FQDN}' = $DomainInfo.FQDN
        '{DOMAIN_NETBIOS}' = $DomainInfo.NetBIOSName
    }
    
    foreach ($key in $placeholders.Keys) {
        foreach ($section in @($Config.Keys)) {
            if ($Config[$section] -is [hashtable]) {
                foreach ($prop in @($Config[$section].Keys)) {
                    if ($Config[$section][$prop] -is [string]) {
                        $Config[$section][$prop] = $Config[$section][$prop] -replace [regex]::Escape($key), $placeholders[$key]
                    }
                }
            }
        }
    }
    
    return $Config
}

function Import-DemoModule {
    param([Parameter(Mandatory=$true)][string]$ModuleName)
    
    $modulePath = Join-Path $Script:ModulesPath "$ModuleName.psm1"
    
    if (-not (Test-Path $modulePath)) {
        Write-Status "Module not found: $modulePath" -Level Error
        return $false
    }
    
    try {
        Import-Module $modulePath -Force -ErrorAction Stop | Out-Null
        Write-Status "Loaded: $ModuleName" -Level Success
        return $true
    }
    catch {
        Write-Status "Failed to load $ModuleName : $_" -Level Error
        return $false
    }
}

function Wait-ForConfirmation {
    param(
        [Parameter(Mandatory=$true)][int]$TimeoutSeconds,
        [Parameter(Mandatory=$false)][string]$Prompt = "Continue?"
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
    Write-Status "Config file: $Script:ConfigFile" -Level Info
    Write-Host ""
    
    # Create modules directory if needed
    if (-not (Test-Path $Script:ModulesPath)) {
        Write-Status "Creating modules directory..." -Level Info
        New-Item -ItemType Directory -Path $Script:ModulesPath -Force | Out-Null
    }
    
    # Load configuration
    Write-Status "Loading configuration..." -Level Info
    try {
        $config = Load-Configuration -ConfigFile $Script:ConfigFile
        Write-Status "Configuration loaded" -Level Success
    }
    catch {
        Write-Status "FATAL: Cannot proceed without configuration" -Level Error
        exit 1
    }
    
    Write-Host ""
    
    # Import Preflight module
    Write-Status "Importing Preflight module..." -Level Info
    if (-not (Import-DemoModule "DSP-Demo-Preflight")) {
        Write-Status "FATAL: Cannot import Preflight module" -Level Error
        exit 1
    }
    
    Write-Host ""
    
    # ========================================================================
    # PHASE 1: PREFLIGHT
    # ========================================================================
    
    Write-Status "Running preflight checks..." -Level Info
    try {
        $environment = Initialize-PreflightEnvironment -Config $config
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
    
    # Expand placeholders
    try {
        $config = Expand-ConfigPlaceholders -Config $config -DomainInfo $environment.DomainInfo
    }
    catch {
        Write-Status "Failed to expand configuration placeholders: $_" -Level Error
    }
    
    Write-Host ""
    
    # ========================================================================
    # PHASE 2: SETUP
    # ========================================================================
    
    Write-Header "Setup Phase"
    
    # Discover setup modules
    $setupModules = @()
    if (Test-Path $Script:ModulesPath) {
        $setupModuleFiles = Get-ChildItem -Path $Script:ModulesPath -Filter "DSP-Demo-Setup-*.psm1" -ErrorAction SilentlyContinue | Sort-Object Name
        $setupModules = $setupModuleFiles | ForEach-Object { $_.BaseName }
    }
    
    if ($setupModules.Count -eq 0) {
        Write-Status "No setup modules found - skipping setup phase" -Level Warning
        Write-Host ""
    }
    else {
        Write-Status "Found $($setupModules.Count) setup module(s):" -Level Info
        Write-Host ""
        
        # Load setup modules
        $loadedSetupModules = @()
        foreach ($moduleName in $setupModules) {
            if (Import-DemoModule $moduleName) {
                $loadedSetupModules += $moduleName
            }
        }
        
        Write-Host ""
        
        if ($loadedSetupModules.Count -eq 0) {
            Write-Status "No setup modules loaded successfully - skipping setup phase" -Level Warning
            Write-Host ""
        }
        else {
            # Display what's about to run
            Write-Header "Setup Modules Ready to Execute"
            
            foreach ($moduleName in $loadedSetupModules) {
                $displayName = Get-ModuleDisplayName $moduleName
                Write-Host "  • $displayName" -ForegroundColor $Colors.Section
            }
            
            # Pause before setup execution
            if (-not (Wait-ForConfirmation -TimeoutSeconds 30 -Prompt "Execute setup modules?")) {
                Write-Status "User cancelled setup phase" -Level Warning
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
                        & $functionName -Config $config -Environment $environment
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
            
            # Pause after setup
            if (-not (Wait-ForConfirmation -TimeoutSeconds 10 -Prompt "Setup complete. Continue with activity phase?")) {
                Write-Status "User cancelled after setup" -Level Warning
                exit 0
            }
        }
    }
    
    Write-Host ""
    
    # ========================================================================
    # PHASE 3: ACTIVITY
    # ========================================================================
    
    Write-Header "Activity Phase"
    
    # Discover activity modules
    $activityModules = @()
    if (Test-Path $Script:ModulesPath) {
        $activityModuleFiles = Get-ChildItem -Path $Script:ModulesPath -Filter "DSP-Demo-Activity-*.psm1" -ErrorAction SilentlyContinue | Sort-Object Name
        $activityModules = $activityModuleFiles | ForEach-Object { $_.BaseName }
    }
    
    if ($activityModules.Count -eq 0) {
        Write-Status "No activity modules found - skipping activity phase" -Level Info
        Write-Host ""
    }
    else {
        Write-Status "Found $($activityModules.Count) activity module(s):" -Level Info
        Write-Host ""
        
        # Load activity modules
        $loadedActivityModules = @()
        foreach ($moduleName in $activityModules) {
            if (Import-DemoModule $moduleName) {
                $loadedActivityModules += $moduleName
            }
        }
        
        Write-Host ""
        
        if ($loadedActivityModules.Count -eq 0) {
            Write-Status "No activity modules loaded successfully - skipping activity phase" -Level Warning
            Write-Host ""
        }
        else {
            # Display what's about to run
            Write-Header "Activity Modules Ready to Execute"
            
            foreach ($moduleName in $loadedActivityModules) {
                $displayName = Get-ModuleDisplayName $moduleName
                Write-Host "  • $displayName" -ForegroundColor $Colors.Section
            }
            
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
                        & $functionName -Config $config -Environment $environment
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
    
    Write-Header "Execution Complete"
    Write-Status "All phases completed" -Level Success
    Write-Host ""
}

# Execute
Main