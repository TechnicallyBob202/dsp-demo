################################################################################
##
## DSP-Demo-MainScript.ps1
##
## Main orchestration script for DSP demo activity generation
## 
## Features:
## - Runs Preflight module for environment discovery and setup
## - Displays configuration summary (what will be created/modified)
## - 15-second confirmation timeout before execution
## - Executes all configured activities
## - Comprehensive logging and error handling
##
## Author: Rob Ingenthron (Original), Bob Lyons (Refactor)
## Version: 4.5.0-20251120
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
$Script:ConfigFile = if ($ConfigPath) { $ConfigPath } else { Join-Path $ScriptPath "DSP-Demo-Config.psd1" }

################################################################################
# COLORS AND FORMATTING
################################################################################

$Colors = @{
    Header = 'Cyan'
    Section = 'Green'
    Success = 'Green'
    Warning = 'Yellow'
    Error = 'Red'
    Info = 'White'
    Menu = 'Cyan'
    MenuHighlight = 'Yellow'
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
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ConfigFile
    )
    
    if (-not (Test-Path $ConfigFile)) {
        Write-Status "Configuration file not found: $ConfigFile" -Level Error
        throw "Missing configuration file"
    }
    
    $config = Import-PowerShellDataFile -Path $ConfigFile
    return $config
}

function Import-DemoModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ModuleName
    )
    
    $modulePath = Join-Path $Script:ModulesPath "$ModuleName.psm1"
    
    if (-not (Test-Path $modulePath)) {
        Write-Status "Module not found: $modulePath" -Level Error
        return $false
    }
    
    try {
        Import-Module -Name $modulePath -Force -ErrorAction Stop | Out-Null
        Write-Status "Imported: $ModuleName" -Level Success
        return $true
    }
    catch {
        Write-Status "Failed to import $ModuleName : $_" -Level Error
        return $false
    }
}

function Get-DomainInfo {
    [CmdletBinding()]
    param()
    
    try {
        $domain = Get-ADDomain -ErrorAction Stop
        
        return [PSCustomObject]@{
            FQDN = $domain.DNSRoot
            DNSRoot = $domain.DNSRoot
            DistinguishedName = $domain.DistinguishedName
            NetBIOSName = $domain.NetBIOSName
            DomainSID = $domain.DomainSID
            Forest = $domain.Forest
        }
    }
    catch {
        Write-Status "Failed to get domain info: $_" -Level Error
        throw $_
    }
}

function Get-ADDomainControllers {
    [CmdletBinding()]
    param()
    
    try {
        $dcs = Get-ADDomainController -Filter * -ErrorAction Stop
        return $dcs
    }
    catch {
        Write-Status "Failed to get domain controllers: $_" -Level Error
        throw $_
    }
}

function Get-ForestInfo {
    [CmdletBinding()]
    param()
    
    try {
        $forest = Get-ADForest -ErrorAction Stop
        
        return [PSCustomObject]@{
            RootDomain = $forest.RootDomain
            ForestMode = $forest.ForestMode
            Domains = $forest.Domains
            DomainCount = $forest.Domains.Count
        }
    }
    catch {
        Write-Status "Failed to get forest info: $_" -Level Error
        throw $_
    }
}

function Expand-ConfigPlaceholders {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$DomainInfo
    )
    
    Write-Status "Expanding config placeholders..." -Level Info
    
    $replacements = @{
        '{DOMAIN_DN}'        = $DomainInfo.DistinguishedName
        '{DOMAIN}'           = if ($DomainInfo.FQDN) { $DomainInfo.FQDN } else { $DomainInfo.DNSRoot }
        '{DOMAIN_NETBIOS}'   = $DomainInfo.NetBIOSName
        '{NETBIOS}'          = $DomainInfo.NetBIOSName
        '{PASSWORD}'         = if ($Config.General -and $Config.General.DefaultPassword) { $Config.General.DefaultPassword } else { "P@ssw0rd123!" }
        '{COMPANY}'          = if ($Config.General -and $Config.General.Company) { $Config.General.Company } else { "Semperis" }
    }
    
    function Expand-Placeholders {
        param($Object)
        
        if ($Object -is [hashtable]) {
            $result = @{}
            foreach ($key in $Object.Keys) {
                $result[$key] = Expand-Placeholders $Object[$key]
            }
            return $result
        }
        elseif ($Object -is [array]) {
            return @($Object | ForEach-Object { Expand-Placeholders $_ })
        }
        elseif ($Object -is [string]) {
            $expanded = $Object
            foreach ($placeholder in $replacements.Keys) {
                $expanded = $expanded -replace [regex]::Escape($placeholder), $replacements[$placeholder]
            }
            return $expanded
        }
        else {
            return $Object
        }
    }
    
    $expanded = Expand-Placeholders $Config
    Write-Status "Placeholder expansion complete" -Level Success
    return $expanded
}

function Run-ActivityModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ModuleName,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$DomainInfo
    )
    
    Write-Status "Executing: $ModuleName" -Level Info
    
    try {
        if (Get-Command Invoke-DemoActivity -ErrorAction SilentlyContinue) {
            Invoke-DemoActivity -Config $Config -DomainInfo $DomainInfo
            Write-Status "$ModuleName completed successfully" -Level Success
            return $true
        }
        else {
            Write-Status "Module function not found: Invoke-DemoActivity" -Level Error
            return $false
        }
    }
    catch {
        Write-Status "Error in $ModuleName : $_" -Level Error
        return $false
    }
}

################################################################################
# MAIN FUNCTION
################################################################################

function Main {
    Write-Header "DSP Demo Activity Generation Suite"
    
    # Load configuration
    Write-Status "Loading configuration..." -Level Info
    $config = Load-Configuration -ConfigFile $Script:ConfigFile
    Write-Status "Configuration loaded" -Level Success
    
    # Import and run Preflight module
    if (-not (Import-DemoModule "DSP-Demo-Preflight")) {
        Write-Status "FATAL: Failed to import Preflight module" -Level Error
        exit 1
    }
    
    Write-Host ""
    
    Write-Header "Discovering Environment"
    
    try {
        $Script:DomainInfo = Get-DomainInfo
        $dcs = Get-ADDomainControllers
        
        if ($dcs -is [array]) {
            $Script:PrimaryDC = $dcs[0].HostName
            $Script:SecondaryDC = if ($dcs.Count -gt 1) { $dcs[1].HostName } else { $null }
        }
        else {
            $Script:PrimaryDC = $dcs.HostName
            $Script:SecondaryDC = $null
        }
        
        $Script:ForestInfo = Get-ForestInfo
        
        Write-Status "Primary DC: $($Script:PrimaryDC)" -Level Info
        if ($Script:SecondaryDC) {
            Write-Status "Secondary DC: $($Script:SecondaryDC)" -Level Info
        }
    }
    catch {
        Write-Status "FATAL: Failed to discover environment: $_" -Level Error
        exit 1
    }
    
    Write-Header "DSP Server Discovery"
    
    $dspServerFromConfig = if ($config -and $config.General -and $config.General.DspServer) { $config.General.DspServer } else { "" }
    
    $Script:DspAvailable = $false
    $Script:DspConnection = $null
    
    Write-Status "Checking for DSP server..." -Level Info
    try {
        if (Get-Command Find-DspServer -ErrorAction SilentlyContinue) {
            $dspServer = Find-DspServer -DomainInfo $Script:DomainInfo -ConfigServer $dspServerFromConfig -ErrorAction SilentlyContinue
            
            if ($dspServer) {
                $Script:DspAvailable = $true
                Write-Status "DSP Server found: $dspServer" -Level Success
            }
            else {
                Write-Status "DSP Server not found, continuing without DSP integration" -Level Warning
            }
        }
        else {
            Write-Status "DSP module not available, continuing without DSP integration" -Level Warning
        }
    }
    catch {
        Write-Status "DSP discovery failed, continuing without DSP integration" -Level Warning
    }
    
    Write-Host ""
    
    # Expand placeholders in config
    $config = Expand-ConfigPlaceholders -Config $config -DomainInfo $Script:DomainInfo
    
    Write-Header "Loading Activity Modules"
    
    $modulesToImport = @(
        "DSP-Demo-01-Directory"
    )
    
    foreach ($moduleName in $modulesToImport) {
        if (-not (Import-DemoModule $moduleName)) {
            Write-Status "Warning: Failed to import $moduleName" -Level Warning
        }
    }
    
    Write-Host ""
    
    Write-Header "Activity Configuration Summary"
    
    # Display what will be created/modified based on config
    if ($config.General) {
        Write-Host "General Settings:" -ForegroundColor $Colors.Section
        Write-Host "  DSP Server: $(if ($config.General.DspServer) { $config.General.DspServer } else { 'Auto-discover' })" -ForegroundColor $Colors.Info
        Write-Host "  Loop Count: $($config.General.LoopCount)" -ForegroundColor $Colors.Info
        Write-Host "  Generic Test Users: $($config.General.GenericUserCount)" -ForegroundColor $Colors.Info
        Write-Host "  Company: $($config.General.Company)" -ForegroundColor $Colors.Info
        Write-Host ""
    }
    
    if ($config.OUs) {
        Write-Host "Organizational Units to Create:" -ForegroundColor $Colors.Section
        foreach ($ou in $config.OUs.Keys) {
            Write-Host "  - $($config.OUs[$ou].Name)" -ForegroundColor $Colors.Info
        }
        Write-Host ""
    }
    
    if ($config.DemoUsers) {
        Write-Host "Demo User Accounts to Create:" -ForegroundColor $Colors.Section
        foreach ($user in $config.DemoUsers.Keys) {
            Write-Host "  - $($config.DemoUsers[$user].Name) ($($config.DemoUsers[$user].SamAccountName))" -ForegroundColor $Colors.Info
        }
        Write-Host ""
    }
    
    if ($config.DNS) {
        Write-Host "DNS Configuration:" -ForegroundColor $Colors.Section
        Write-Host "  - Zone: $($config.DNS.ForwardZone.Name)" -ForegroundColor $Colors.Info
        Write-Host "  - Records to Create: $($config.DNS.ForwardZone.Records.Count)" -ForegroundColor $Colors.Info
        Write-Host ""
    }
    
    if ($config.GPOs) {
        Write-Host "Group Policy Objects:" -ForegroundColor $Colors.Section
        foreach ($gpo in $config.GPOs.Keys) {
            if ($gpo -ne "DefaultDomainPolicy") {
                Write-Host "  - $($config.GPOs[$gpo].Name)" -ForegroundColor $Colors.Info
            }
        }
        if ($config.GPOs.DefaultDomainPolicy) {
            Write-Host "  - Default Domain Policy (modifications)" -ForegroundColor $Colors.Info
        }
        Write-Host ""
    }
    
    if ($config.Sites) {
        Write-Host "AD Sites and Services:" -ForegroundColor $Colors.Section
        foreach ($site in $config.Sites.Keys) {
            Write-Host "  - $($config.Sites[$site].Name)" -ForegroundColor $Colors.Info
        }
        Write-Host ""
    }
    
    if ($config.FGPPs) {
        Write-Host "Fine-Grained Password Policies:" -ForegroundColor $Colors.Section
        foreach ($fgpp in $config.FGPPs.Keys) {
            Write-Host "  - $($config.FGPPs[$fgpp].Name)" -ForegroundColor $Colors.Info
        }
        Write-Host ""
    }
    
    if ($config.WMIFilters) {
        Write-Host "WMI Filters:" -ForegroundColor $Colors.Section
        Write-Host "  - Count: $($config.WMIFilters.Count)" -ForegroundColor $Colors.Info
        Write-Host ""
    }
    
    # 15-second confirmation timeout
    Write-Header "Confirmation Required"
    Write-Host "Press " -ForegroundColor $Colors.Prompt -NoNewline
    Write-Host "Y" -ForegroundColor $Colors.MenuHighlight -NoNewline
    Write-Host " to proceed, " -ForegroundColor $Colors.Prompt -NoNewline
    Write-Host "N" -ForegroundColor $Colors.MenuHighlight -NoNewline
    Write-Host " to cancel" -ForegroundColor $Colors.Prompt
    Write-Host "(Automatically proceeding in 15 seconds...)" -ForegroundColor $Colors.Warning
    Write-Host ""
    
    $confirmationTimer = 0
    $timeoutSeconds = 15
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
        Write-Host "`rProceeding automatically in $remaining seconds..." -ForegroundColor $Colors.Warning -NoNewline
        Start-Sleep -Seconds 1
        $confirmationTimer++
    }
    
    # If timeout was reached, proceed = $true (already confirmed by display message)
    if ($null -eq $proceed) {
        $proceed = $true
    }
    
    if (-not $proceed) {
        Write-Host ""
        Write-Status "Execution cancelled by user" -Level Warning
        exit 0
    }
    
    Write-Host ""
    Write-Host ""
    
    Write-Header "Executing Activity Generation"
    
    # Execute all configured activities
    if (-not (Run-ActivityModule -ModuleName "DSP-Demo-01-Directory" -Config $config -DomainInfo $Script:DomainInfo)) {
        Write-Status "Activity generation completed with errors" -Level Warning
    }
    else {
        Write-Status "Demo activity generation completed successfully" -Level Success
    }
    
    Write-Host ""
}

# Execute main function
Main################################################################################
##
## DSP-Demo-Config.psd1
##
## Configuration file for DSP Demo script suite
## This centralizes all the hardcoded values from the original script
##
## Supports placeholder expansion in DSP-Demo-MainScript.ps1:
##   {DOMAIN_DN}  - Replaced with actual domain DN
##   {DOMAIN}     - Replaced with domain FQDN
##   {COMPANY}    - Replaced with company name
##   {PASSWORD}   - Replaced with DefaultPassword
##
################################################################################

@{
    #---------------------------------------------------------------------------
    # GENERAL SETTINGS
    #---------------------------------------------------------------------------
    General = @{
        # Set this to your DSP server FQDN if you want to use a specific server
        # Leave empty string "" to auto-discover via SCP
        # Example: "dsp.contoso.com" or ""
        DspServer = "dsp.d3.lab"

        # Number of times to loop the entire script (default: 1)
        LoopCount = 1
        
        # Number of generic test users to create in OU=TEST
        GenericUserCount = 250
        
        # Default password for demo accounts
        # This is used for all user accounts created and replaces {PASSWORD} placeholder
        DefaultPassword = "P@ssw0rd123!"
        
        # Company name (replaces {COMPANY} placeholder)
        Company = "Semperis"
        
        # Logging settings
        LogPath = "C:\Logs\DSP-Demo"
        VerboseLogging = $true
    }
    
    #---------------------------------------------------------------------------
    # DEMO USER ACCOUNTS
    #
    # These are the named demo users that get specific attributes and changes
    # throughout the script to generate interesting DSP change data.
    #
    # Original script context:
    # - DemoUser1 (Axl Rose): Primary demo user, gets many attribute changes
    # - DemoUser2 (Slash Hudson): Used for account lockout demos
    # - DemoUser3 (Duff McKagan): Used for auto-undo rule testing (Title attribute)
    # - DemoUser4 (Paul McCartney): Additional demo user for variety
    #---------------------------------------------------------------------------
    DemoUsers = @{
        DemoUser1 = @{
            Name = "Axl Rose"
            GivenName = "Axl"
            Surname = "Rose"
            SamAccountName = "arose"
            UserPrincipalName = "arose@{DOMAIN}"
            DisplayName = "Axl Rose"
            Description = "Demo user #1 for DSP testing - Primary demo account"
            Department = "Music"
            Title = "Lead Singer"
            Company = "Guns N Roses"
            Office = "Los Angeles"
            StreetAddress = "123 Sunset Blvd"
            City = "Los Angeles"
            State = "CA"
            PostalCode = "90028"
            Country = "US"
            TelephoneNumber = "555-0101"
            MobilePhone = "555-0102"
            Fax = "555-0103"
            EmployeeID = "100001"
            EmployeeNumber = "EMP-001"
            Manager = $null
            Enabled = $true
            PasswordNeverExpires = $false
            Path = "OU=Lab Users,{DOMAIN_DN}"
            Password = "{PASSWORD}"
        }
        
        DemoUser2 = @{
            Name = "Slash Hudson"
            GivenName = "Slash"
            Surname = "Hudson"
            SamAccountName = "shudson"
            UserPrincipalName = "shudson@{DOMAIN}"
            DisplayName = "Slash Hudson"
            Description = "Demo user #2 for DSP testing - Account lockout demonstrations"
            Department = "Music"
            Title = "Lead Guitarist"
            Company = "Guns N Roses"
            Office = "Los Angeles"
            City = "Los Angeles"
            EmployeeID = "100002"
            TelephoneNumber = "555-0104"
            Fax = "555-0105"
            Enabled = $true
            PasswordNeverExpires = $false
            Path = "OU=Lab Users,{DOMAIN_DN}"
            Password = "{PASSWORD}"
        }
        
        DemoUser3 = @{
            Name = "Duff McKagan"
            GivenName = "Duff"
            Surname = "McKagan"
            SamAccountName = "dmckagan"
            UserPrincipalName = "dmckagan@{DOMAIN}"
            DisplayName = "Duff McKagan"
            Description = "Demo user #3 for DSP testing - Auto-undo rule trigger"
            Department = "Music"
            Title = "Bass Player"
            Company = "Guns N Roses"
            City = "Los Angeles"
            EmployeeID = "100003"
            TelephoneNumber = "555-0106"
            Fax = "555-0107"
            Enabled = $true
            PasswordNeverExpires = $false
            Path = "OU=Lab Users,{DOMAIN_DN}"
            Password = "{PASSWORD}"
        }
        
        DemoUser4 = @{
            Name = "Paul McCartney"
            GivenName = "Paul"
            Surname = "McCartney"
            SamAccountName = "pmccartney"
            UserPrincipalName = "pmccartney@{DOMAIN}"
            DisplayName = "Paul McCartney"
            Description = "Demo user #4 for DSP testing - Additional variety"
            Department = "Music"
            Title = "Bassist"
            Company = "The Beatles"
            City = "Liverpool"
            EmployeeID = "100004"
            TelephoneNumber = "555-0108"
            Enabled = $true
            PasswordNeverExpires = $false
            Path = "OU=Lab Users,{DOMAIN_DN}"
            Password = "{PASSWORD}"
        }
    }
    
    #---------------------------------------------------------------------------
    # ADMINISTRATIVE ACCOUNTS
    #
    # Special administrative accounts used for different scenarios
    #---------------------------------------------------------------------------
    AdminUsers = @{
        # Tier 2 Administrator
        # Used for general admin operations and group membership changes
        Tier2Admin = @{
            Name = "T2 Admin Demo"
            GivenName = "T2"
            Surname = "Admin"
            SamAccountName = "t2admin"
            UserPrincipalName = "t2admin@{DOMAIN}"
            DisplayName = "T2 Admin Demo"
            Description = "Tier 2 administrator for DSP demos"
            Department = "IT Operations"
            Title = "Tier 2 Administrator"
            Company = "{COMPANY}"
            EmployeeID = "200001"
            TelephoneNumber = "555-0201"
            Enabled = $true
            PasswordNeverExpires = $true
            MemberOf = @("Domain Admins")
            Path = "OU=Lab Admins,{DOMAIN_DN}"
            Password = "{PASSWORD}"
        }
        
        # Operations Admin
        # Used with Credential Manager to make changes as a different user
        # This demonstrates "who made the change" scenarios in DSP
        OpsAdmin1 = @{
            Name = "Ops Admin Tier 1"
            GivenName = "Ops"
            Surname = "Admin"
            SamAccountName = "opsadmin1"
            UserPrincipalName = "opsadmin1@{DOMAIN}"
            DisplayName = "Operations Admin - Tier 1"
            Description = "Tier 1 operations administrator - Used for alternative credential demos"
            Department = "IT Operations"
            Title = "Operations Administrator"
            EmployeeID = "200002"
            TelephoneNumber = "555-0202"
            Enabled = $true
            PasswordNeverExpires = $true
            MemberOf = @("Account Operators")
            Path = "OU=Lab Admins,{DOMAIN_DN}"
            Password = "{PASSWORD}"
        }
        
        # Unprivileged DSP Admin
        # Used for DSP operations without full Domain Admin rights
        DspAdmin = @{
            Name = "DSP Admin Demo"
            GivenName = "DSP"
            Surname = "Admin"
            SamAccountName = "dspadmin"
            UserPrincipalName = "dspadmin@{DOMAIN}"
            DisplayName = "DSP Administrator (Unprivileged)"
            Description = "Unprivileged DSP administrator for demonstrations"
            Department = "IT Security"
            Title = "DSP Administrator"
            EmployeeID = "200003"
            TelephoneNumber = "555-0203"
            Enabled = $true
            PasswordNeverExpires = $true
            Path = "OU=Lab Admins,{DOMAIN_DN}"
            Password = "{PASSWORD}"
        }
    }
    
#---------------------------------------------------------------------------
    # SECURITY GROUPS - PHASE 1 (ORIGINAL CREATION)
    #
    # These groups are created in Phase 1 with their original attributes.
    # Phase 5 will modify some of these (change category, scope, move to different OU)
    # For now, only Phase 1 creation - use the ORIGINAL attributes from the script.
    #
    # Path placeholders will be expanded at runtime with actual domain DN
    #---------------------------------------------------------------------------
    SecurityGroups = @{
        # Special Lab Users - ORIGINAL: Security/Global in Lab Users OU
        # (Phase 5 will change to Distribution/Universal and move to Lab Admins)
        SpecialLabUsers = @{
            Name = "Special Lab Users"
            SamAccountName = "SpecialLabUsers"
            DisplayName = "Special Lab Users"
            Description = "Members of this lab group are special"
            GroupCategory = "Security"
            GroupScope = "Global"
            Path = "OU=Lab Users,{DOMAIN_DN}"
            Members = @()
        }
        
        # Special Lab Admins - ORIGINAL: Security/Global in Lab Admins
        SpecialLabAdmins = @{
            Name = "Special Lab Admins"
            SamAccountName = "SpecialLabAdmins"
            DisplayName = "Special Lab Admins"
            Description = "Members of this lab group are admins"
            GroupCategory = "Security"
            GroupScope = "Global"
            Path = "OU=Lab Admins,{DOMAIN_DN}"
            Members = @()
        }
        
        # Pizza Party Group - ORIGINAL: Distribution/Global in Lab Users
        PizzaPartyGroup = @{
            Name = "Pizza Party Group"
            SamAccountName = "PizzaPartyGroup"
            DisplayName = "Pizza Party Group"
            Description = "Members of this lab group get info about pizza parties"
            GroupCategory = "Distribution"
            GroupScope = "Global"
            Path = "OU=Lab Users,{DOMAIN_DN}"
            Members = @()
        }
        
        # Party Planners Group - ORIGINAL: Distribution/Global in Lab Users
        PartyPlannersGroup = @{
            Name = "Party Planners Group"
            SamAccountName = "PartyPlannersGroup"
            DisplayName = "Party Planners Group"
            Description = "Members of this lab group do party planning"
            GroupCategory = "Distribution"
            GroupScope = "Global"
            Path = "OU=Lab Users,{DOMAIN_DN}"
            Members = @()
        }
        
        # Helpdesk Ops - ORIGINAL: Security/Global in Lab Users
        HelpdeskOps = @{
            Name = "Helpdesk Ops"
            SamAccountName = "HelpdeskOps"
            DisplayName = "Helpdesk Ops"
            Description = "Members of this lab group are Helpdesk operators"
            GroupCategory = "Security"
            GroupScope = "Global"
            Path = "OU=Lab Users,{DOMAIN_DN}"
            Members = @()
        }
        
        # Special Accounts - ORIGINAL: Security/Universal in Lab Admins
        SpecialAccounts = @{
            Name = "Special Accounts"
            SamAccountName = "SpecialAccounts"
            DisplayName = "Special Accounts"
            Description = "Members of this lab group are special accts and service accts"
            GroupCategory = "Security"
            GroupScope = "Universal"
            Path = "OU=Lab Admins,{DOMAIN_DN}"
            Members = @()
        }
        
        # DeleteMe OU Groups - created for deletion and recovery demos
        ServerAdminsUS = @{
            Name = "Server Admins - US"
            SamAccountName = "ServerAdmins-US"
            DisplayName = "Server Admins - US"
            Description = "Resource Administrators for special Lab"
            GroupCategory = "Security"
            GroupScope = "Global"
            Path = "OU=Servers,OU=DELETEME OU,{DOMAIN_DN}"
            Members = @()
        }
        
        ServerAdminsAPAC = @{
            Name = "Server Admins - APAC"
            SamAccountName = "ServerAdmins-APAC"
            DisplayName = "Server Admins - APAC"
            Description = "Resource Administrators for special Lab"
            GroupCategory = "Security"
            GroupScope = "Global"
            Path = "OU=Servers,OU=DELETEME OU,{DOMAIN_DN}"
            Members = @()
        }
        
        ResourceAdmins = @{
            Name = "Resource Admins"
            SamAccountName = "ResourceAdmins"
            DisplayName = "Resource Admins"
            Description = "Resource Administrators for special Lab"
            GroupCategory = "Security"
            GroupScope = "Global"
            Path = "OU=Resources,OU=DeleteMe-OU,{DOMAIN_DN}"
            Members = @()
        }
        
        SpecialAccessDatacenter = @{
            Name = "Special Access - Datacenter"
            SamAccountName = "SpecialAccessDatacenter"
            DisplayName = "Special Access - Datacenter"
            Description = "Resource Administrators for special Lab"
            GroupCategory = "Security"
            GroupScope = "Global"
            Path = "OU=Corp Special OU,OU=DeleteMe-OU,{DOMAIN_DN}"
            Members = @()
        }
    }
    
    #---------------------------------------------------------------------------
    # ORGANIZATIONAL UNIT STRUCTURE
    #---------------------------------------------------------------------------
    OUs = @{
        # Root OU for all demo objects
        DemoRoot = @{
            Name = "DSP-Demo-Objects"
            Description = "Root OU for all DSP demonstration objects"
            Path = "{DOMAIN_DN}"
            ProtectFromAccidentalDeletion = $true
        }
        
        # Users OU under demo root
        DemoUsers = @{
            Name = "Users"
            Description = "Demo user accounts"
            ParentOU = "DSP-Demo-Objects"
            ProtectFromAccidentalDeletion = $true
        }
        
        # Groups OU under demo root
        DemoGroups = @{
            Name = "Groups"
            Description = "Demo group objects"
            ParentOU = "DSP-Demo-Objects"
            ProtectFromAccidentalDeletion = $true
        }
        
        # Computers OU under demo root
        DemoComputers = @{
            Name = "Computers"
            Description = "Demo computer objects"
            ParentOU = "DSP-Demo-Objects"
            ProtectFromAccidentalDeletion = $true
        }
        
        # Generic test users OU (at domain root)
        TestOU = @{
            Name = "TEST"
            Description = "Generic test user accounts (bulk created)"
            Path = "{DOMAIN_DN}"
            ProtectFromAccidentalDeletion = $false
        }
        
        # OU that gets deleted for recovery demos
        ToBeDeleted = @{
            Name = "DeleteMe-OU"
            Description = "OU for deletion and recovery demonstrations - Will be deleted!"
            Path = "{DOMAIN_DN}"
            ProtectFromAccidentalDeletion = $false
            PopulateWithUsers = $true
            UserCount = 5
            DeleteAfterCreation = $true
        }
        
        # Highly restricted Tier 0 OU
        TierZero = @{
            Name = "Tier-0-Assets"
            Description = "Tier 0 assets - Highly restricted access"
            Path = "{DOMAIN_DN}"
            ProtectFromAccidentalDeletion = $true
            RestrictedAccess = $true
            AllowedAdminGroup = "Tier-0-Admins"
        }
    }
    
    #---------------------------------------------------------------------------
    # DNS CONFIGURATION
    #---------------------------------------------------------------------------
    DNS = @{
        # Forward lookup zone configuration
        ForwardZone = @{
            Name = "{DOMAIN}"
            CreateZone = $false
            Records = @(
                @{Name = "demo-server1"; Type = "A"; IPv4Address = "192.168.100.10"}
                @{Name = "demo-server2"; Type = "A"; IPv4Address = "192.168.100.11"}
                @{Name = "demo-server3"; Type = "A"; IPv4Address = "192.168.100.12"}
                @{Name = "demo-alias"; Type = "CNAME"; HostNameAlias = "demo-server1.{DOMAIN}"}
                @{Name = "demo-web"; Type = "CNAME"; HostNameAlias = "demo-server2.{DOMAIN}"}
            )
        }
        
        # Reverse lookup zone configuration
        ReverseZone = @{
            Name = "100.168.192.in-addr.arpa"
            NetworkID = "192.168.100.0/24"
            CreateZone = $true
            Records = @(
                @{Name = "10"; Type = "PTR"; PtrDomainName = "demo-server1.{DOMAIN}"}
                @{Name = "11"; Type = "PTR"; PtrDomainName = "demo-server2.{DOMAIN}"}
                @{Name = "12"; Type = "PTR"; PtrDomainName = "demo-server3.{DOMAIN}"}
            )
        }
    }
    
    #---------------------------------------------------------------------------
    # GPO CONFIGURATION
    #---------------------------------------------------------------------------
    GPOs = @{
        # Demo GPO with various settings
        DemoGPO = @{
            Name = "DSP-Demo-GPO"
            Comment = "Demo GPO for DSP change tracking demonstrations"
            LinkedTo = "OU=DSP-Demo-Objects,{DOMAIN_DN}"
            Settings = @{}
        }
        
        # SMB Client Policy GPO
        SMBClientGPO = @{
            Name = "Lab-SMB-Client-Policy"
            Comment = "SMB client security policy for lab"
            LinkedTo = "OU=DSP-Demo-Objects,{DOMAIN_DN}"
            Settings = @{}
        }
        
        # Default Domain Policy modifications
        DefaultDomainPolicy = @{
            ModifyMinPasswordLength = $true
            NewMinPasswordLength = 8
            ModifyAccountLockoutThreshold = $true
            NewAccountLockoutThreshold = 11
        }
    }
    
    #---------------------------------------------------------------------------
    # AD SITES AND SERVICES
    #---------------------------------------------------------------------------
    Sites = @{
        DemoSite = @{
            Name = "SemperisLabs"
            Description = "AD site for Semperis Labs"
            Location = "USA-TX-Labs"
            Subnets = @(
                @{
                    Name = "10.3.22.0/24"
                    Description = "AD subnet for Semperis Labs"
                    Location = "USA-TX-Labs"
                }
            )
            SiteLink = "DefaultIPSiteLink"
        }
    }
    
    # Subnet modifications
    Subnets = @{
        DemoSubnets = @(
            @{Name = "192.168.200.0/24"; Site = "Default-First-Site-Name"; Description = "Demo Subnet 1"; Location = "Lab"}
            @{Name = "192.168.201.0/24"; Site = "Default-First-Site-Name"; Description = "Demo Subnet 2"; Location = "Lab"}
            @{Name = "192.168.202.0/24"; Site = "Default-First-Site-Name"; Description = "Demo Subnet 3"; Location = "Lab"}
        )
    }
    
    #---------------------------------------------------------------------------
    # FINE-GRAINED PASSWORD POLICIES (FGPP)
    #---------------------------------------------------------------------------
    FGPPs = @{
        SpecialLabUsersFGPP = @{
            Name = "SpecialLabUsers_PSO"
            Precedence = 100
            ComplexityEnabled = $true
            LockoutDuration = "00:30:00"
            LockoutObservationWindow = "00:30:00"
            LockoutThreshold = 5
            MaxPasswordAge = "42.00:00:00"
            MinPasswordAge = "1.00:00:00"
            MinPasswordLength = 12
            PasswordHistoryCount = 24
            ReversibleEncryptionEnabled = $false
            AppliesTo = "CN=DSP-LAB-Special-Users,OU=Groups,OU=DSP-Demo-Objects,{DOMAIN_DN}"
        }
        
        DemoFGPP = @{
            Name = "DSP-Demo-FGPP"
            Precedence = 200
            ComplexityEnabled = $true
            LockoutThreshold = 3
            MinPasswordLength = 14
            PasswordHistoryCount = 12
            DeleteAfterCreation = $true
        }
    }
    
    #---------------------------------------------------------------------------
    # WMI FILTERS
    #---------------------------------------------------------------------------
    WMIFilters = @{
        Filter1 = @{
            Name = "WMI-Filter-Windows-10"
            Description = "Windows 10 operating systems"
            Query = "SELECT * FROM Win32_OperatingSystem WHERE Caption LIKE '%Windows 10%'"
        }
        Filter2 = @{
            Name = "WMI-Filter-Windows-Server"
            Description = "Windows Server operating systems"
            Query = "SELECT * FROM Win32_OperatingSystem WHERE Caption LIKE '%Server%'"
        }
        Filter3 = @{
            Name = "WMI-Filter-Domain-Controllers"
            Description = "Domain Controller systems"
            Query = "SELECT * FROM Win32_OperatingSystem WHERE ProductType = '2'"
        }
    }
}

################################################################################
# END OF CONFIGURATION
################################################################################