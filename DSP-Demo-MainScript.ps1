################################################################################
##
## DSP-Demo-MainScript.ps1
##
## Main orchestration script for DSP demo activity generation
## 
## Features:
## - Calls Preflight module for environment validation
## - Any preflight check failure = hard stop
## - Pause after preflight passes for operator confirmation
## - Loads and executes setup modules
## - Non-critical failures (module import, etc) = warnings, continues
##
## Author: Bob Lyons
## Version: 5.0.0-20251202
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
        Write-Status "Loaded module: $ModuleName" -Level Success
        return $true
    }
    catch {
        Write-Status "Failed to load module $ModuleName : $_" -Level Error
        return $false
    }
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
        Write-Status "Configuration loaded successfully" -Level Success
    }
    catch {
        Write-Status "FATAL: Cannot proceed without configuration" -Level Error
        exit 1
    }
    
    Write-Host ""
    
    # Import Preflight module - failure to import is fatal
    Write-Status "Importing Preflight module..." -Level Info
    if (-not (Import-DemoModule "DSP-Demo-Preflight")) {
        Write-Status "FATAL: Cannot import Preflight module" -Level Error
        exit 1
    }
    
    Write-Host ""
    
    # Run preflight checks - ANY FAILURE IS FATAL
    Write-Status "Running preflight checks..." -Level Info
    try {
        $environment = Initialize-PreflightEnvironment -Config $config
    }
    catch {
        Write-Status "FATAL: Preflight checks failed - cannot proceed" -Level Error
        Write-Host ""
        exit 1
    }
    
    Write-Host ""
    Write-Status "All preflight checks passed" -Level Success
    Write-Host ""
    Write-Host "Environment is ready. Review the information above." -ForegroundColor $Colors.Info
    Write-Host "Press Enter to continue..." -ForegroundColor $Colors.Prompt
    Read-Host | Out-Null
    Write-Host ""
    
    # Expand configuration placeholders
    try {
        $config = Expand-ConfigPlaceholders -Config $config -DomainInfo $environment.DomainInfo
    }
    catch {
        Write-Status "Failed to expand configuration placeholders: $_" -Level Error
    }
    
    # Load setup modules - non-fatal failures
    Write-Header "Loading Setup Modules"
    
    $setupModules = @(
        "DSP-Demo-01-Setup-BuildOUs",
        "DSP-Demo-02-Setup-CreateGroups",
        "DSP-Demo-03-Setup-CreateUsers",
        "DSP-Demo-04-Setup-CreateComputers",
        "DSP-Demo-05-Setup-CreateDefaultDomainPolicy",
        "DSP-Demo-06-Setup-CreateFGPP",
        "DSP-Demo-07-Setup-CreateADSitesAndSubnets",
        "DSP-Demo-08-Setup-CreateDNSZones",
        "DSP-Demo-09-Setup-CreateGPOs"
    )
    
    $loadedModules = 0
    $failedModules = 0
    
    foreach ($moduleName in $setupModules) {
        if (Import-DemoModule $moduleName) {
            $loadedModules++
        }
        else {
            Write-Status "Warning: Failed to load $moduleName - will be skipped" -Level Warning
            $failedModules++
        }
    }
    
    Write-Host ""
    Write-Status "Module loading complete: $loadedModules loaded, $failedModules failed" -Level Info
    Write-Host ""
    
    # Display setup configuration summary
    Write-Header "Setup Configuration Summary"
    
    if ($config.General) {
        Write-Host "General Settings:" -ForegroundColor $Colors.Section
        if ($config.General.LoopCount) {
            Write-Host "  Loop Count: $($config.General.LoopCount)" -ForegroundColor $Colors.Info
        }
        if ($config.General.GenericUserCount) {
            Write-Host "  Generic Test Users: $($config.General.GenericUserCount)" -ForegroundColor $Colors.Info
        }
        if ($config.General.Company) {
            Write-Host "  Company: $($config.General.Company)" -ForegroundColor $Colors.Info
        }
        Write-Host ""
    }
    
    if ($config.OUs) {
        Write-Host "Organizational Units: $(@($config.OUs.Keys).Count) to create" -ForegroundColor $Colors.Section
        Write-Host ""
    }
    
    if ($config.DemoUsers) {
        Write-Host "Demo User Accounts: $(@($config.DemoUsers.Keys).Count) to create" -ForegroundColor $Colors.Section
        Write-Host ""
    }
    
    if ($config.Groups) {
        Write-Host "Security Groups: $(@($config.Groups.Keys).Count) to create" -ForegroundColor $Colors.Section
        Write-Host ""
    }
    
    # Confirmation prompt
    Write-Header "Ready to Execute Setup"
    Write-Host "This will create the initial AD objects required for DSP demonstration." -ForegroundColor $Colors.Info
    Write-Host ""
    Write-Host "Continue with setup?" -ForegroundColor $Colors.Prompt
    Write-Host ""
    
    # Yes/No prompt with timeout
    $confirmationTimer = 0
    $timeoutSeconds = 30
    $proceed = $null
    
    while ($confirmationTimer -lt $timeoutSeconds) {
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
        
        $remaining = $timeoutSeconds - $confirmationTimer
        Write-Host "`rPress Y/N (auto-proceeding in $remaining seconds)..." -ForegroundColor $Colors.Warning -NoNewline
        Start-Sleep -Seconds 1
        $confirmationTimer++
    }
    
    # If timeout reached, default to proceed
    if ($null -eq $proceed) {
        $proceed = $true
    }
    
    Write-Host ""
    
    if (-not $proceed) {
        Write-Status "Setup cancelled by user" -Level Warning
        Write-Host ""
        exit 0
    }
    
    # Execute setup modules
    Write-Header "Executing Setup"
    
    $completedModules = 0
    $skippedModules = 0
    $failedExecution = 0
    
    foreach ($moduleName in $setupModules) {
        $functionName = "Invoke-" + ($moduleName -replace "^DSP-Demo-\d+-Setup-", "")
        
        if (Get-Command $functionName -ErrorAction SilentlyContinue) {
            try {
                Write-Status "Executing $moduleName..." -Level Info
                & $functionName -Config $config -Environment $environment
                Write-Status "$moduleName completed successfully" -Level Success
                $completedModules++
            }
            catch {
                Write-Status "Error executing $moduleName : $_" -Level Error
                $failedExecution++
            }
        }
        else {
            Write-Status "Function $functionName not found - skipping $moduleName" -Level Warning
            $skippedModules++
        }
    }
    
    # Execution summary
    Write-Host ""
    Write-Header "Setup Execution Summary"
    Write-Host "Modules Completed: $completedModules" -ForegroundColor $Colors.Success
    if ($skippedModules -gt 0) {
        Write-Host "Modules Skipped: $skippedModules" -ForegroundColor $Colors.Warning
    }
    if ($failedExecution -gt 0) {
        Write-Host "Modules Failed: $failedExecution" -ForegroundColor $Colors.Error
    }
    
    Write-Status "Setup generation completed" -Level Success
    Write-Host ""
}

# Execute
Main