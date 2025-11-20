################################################################################
##
## DSP-Demo-03-Setup-CreateUsers.psm1
##
## Creates user accounts from configuration file.
## Operator-configurable via DSP-Demo-Config.psd1
##
## Configuration sections consumed:
##  - Tier0Admins, Tier1Admins, Tier2Admins
##  - DemoUsers
##  - ServiceAccounts
##  - BulkUsers (generates numbered accounts)
##  - DeleteMeUsers (generates numbered accounts)
##
## All users created with idempotent logic (create if not exists).
## Group membership applied as configured.
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

################################################################################
# LOGGING
################################################################################

function Write-Status {
    param(
        [string]$Message,
        [ValidateSet('Info','Success','Warning','Error')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colors = @{
        'Info'    = 'White'
        'Success' = 'Green'
        'Warning' = 'Yellow'
        'Error'   = 'Red'
    }
    
    $color = $colors[$Level]
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

################################################################################
# HELPER FUNCTIONS
################################################################################

function Resolve-OUPath {
    <#
    .SYNOPSIS
    Converts logical OU path (e.g. "LabAdmins/Tier0") to Distinguished Name
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogicalPath,
        
        [Parameter(Mandatory=$true)]
        $DomainInfo
    )
    
    $domainDN = $DomainInfo.DN
    
    if ([string]::IsNullOrWhiteSpace($LogicalPath) -or $LogicalPath -eq "Root") {
        return $domainDN
    }
    
    # Split path and build DN from right to left
    $parts = $LogicalPath -split '/'
    $dn = ""
    
    for ($i = $parts.Count - 1; $i -ge 0; $i--) {
        $part = $parts[$i]
        if ($part -and $part -ne "Root") {
            $dn = "OU=$part" + $(if ($dn) { ",$dn" })
        }
    }
    
    # Append domain DN
    if ($dn) {
        $dn = "$dn,$domainDN"
    } else {
        $dn = $domainDN
    }
    
    return $dn
}

function New-UserAccount {
    <#
    .SYNOPSIS
    Creates a user account with idempotent logic. Returns user object.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$UserDef,
        
        [Parameter(Mandatory=$true)]
        [string]$OUPath
    )
    
    $sam = $UserDef.SamAccountName
    
    # Check if user exists
    $existing = Get-ADUser -Filter { SamAccountName -eq $sam } -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Status "User '$sam' already exists - skipping" -Level Info
        return $existing
    }
    
    # Build params for New-ADUser
    $newUserParams = @{
        SamAccountName = $sam
        Name = $UserDef.Name
        Path = $OUPath
        AccountPassword = ConvertTo-SecureString $UserDef.Password -AsPlainText -Force
        Enabled = $UserDef.Enabled
        PasswordNeverExpires = $UserDef.PasswordNeverExpires
        ErrorAction = 'Stop'
    }
    
    # Add optional attributes if present
    @('GivenName', 'Surname', 'DisplayName', 'Title', 'Department', 
      'Company', 'Mail', 'TelephoneNumber', 'MobilePhone', 'Fax', 
      'Description', 'Office', 'StreetAddress', 'City', 'State', 
      'PostalCode', 'Country') | ForEach-Object {
        if ($UserDef.ContainsKey($_)) {
            $newUserParams[$_] = $UserDef[$_]
        }
    }
    
    try {
        $user = New-ADUser @newUserParams -PassThru
        Write-Status "Created user '$sam'" -Level Success
        return $user
    }
    catch {
        Write-Status "Failed to create user '$sam': $_" -Level Error
        return $null
    }
}

function Add-UserToGroup {
    <#
    .SYNOPSIS
    Adds user to group if not already member. Returns $true on success.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$UserSam,
        
        [Parameter(Mandatory=$true)]
        [string]$GroupName
    )
    
    $user = Get-ADUser -Filter { SamAccountName -eq $UserSam } -ErrorAction SilentlyContinue
    if (-not $user) {
        Write-Status "User '$UserSam' not found - cannot add to group" -Level Error
        return $false
    }
    
    $group = Get-ADGroup -Filter { Name -eq $GroupName } -ErrorAction SilentlyContinue
    if (-not $group) {
        Write-Status "Group '$GroupName' not found - skipping membership" -Level Warning
        return $false
    }
    
    $isMember = Get-ADGroupMember -Identity $group -ErrorAction SilentlyContinue | 
        Where-Object { $_.SamAccountName -eq $UserSam }
    
    if ($isMember) {
        Write-Status "User '$UserSam' already member of '$GroupName'" -Level Info
        return $true
    }
    
    try {
        Add-ADGroupMember -Identity $group -Members $user -ErrorAction Stop
        Write-Status "Added '$UserSam' to '$GroupName'" -Level Success
        return $true
    }
    catch {
        Write-Status "Failed to add '$UserSam' to '$GroupName': $_" -Level Error
        return $false
    }
}

################################################################################
# PUBLIC FUNCTION
################################################################################

function Invoke-CreateUsers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        $Environment
    )
    
    $DomainInfo = $Environment.DomainInfo
    
    Write-Host ""
    Write-Status "Creating user accounts..." -Level Info
    
    $createdCount = 0
    $skippedCount = 0
    
    # Process Tier 0 Admins
    if ($Config.ContainsKey('Users') -and $Config.Users.ContainsKey('Tier0Admins')) {
        Write-Status "Creating Tier 0 admin accounts..." -Level Info
        foreach ($userDef in $Config.Users.Tier0Admins) {
            $ouPath = Resolve-OUPath $userDef.OUPath $DomainInfo
            $user = New-UserAccount $userDef $ouPath
            if ($user) { $createdCount++ } else { $skippedCount++ }
            
            if ($userDef.ContainsKey('Groups')) {
                foreach ($groupName in $userDef.Groups) {
                    Add-UserToGroup $userDef.SamAccountName $groupName
                }
            }
        }
    }
    
    # Process Tier 1 Admins
    if ($Config.ContainsKey('Users') -and $Config.Users.ContainsKey('Tier1Admins')) {
        Write-Status "Creating Tier 1 admin accounts..." -Level Info
        foreach ($userDef in $Config.Users.Tier1Admins) {
            $ouPath = Resolve-OUPath $userDef.OUPath $DomainInfo
            $user = New-UserAccount $userDef $ouPath
            if ($user) { $createdCount++ } else { $skippedCount++ }
            
            if ($userDef.ContainsKey('Groups')) {
                foreach ($groupName in $userDef.Groups) {
                    Add-UserToGroup $userDef.SamAccountName $groupName
                }
            }
        }
    }
    
    # Process Tier 2 Admins
    if ($Config.ContainsKey('Users') -and $Config.Users.ContainsKey('Tier2Admins')) {
        Write-Status "Creating Tier 2 admin accounts..." -Level Info
        foreach ($userDef in $Config.Users.Tier2Admins) {
            $ouPath = Resolve-OUPath $userDef.OUPath $DomainInfo
            $user = New-UserAccount $userDef $ouPath
            if ($user) { $createdCount++ } else { $skippedCount++ }
            
            if ($userDef.ContainsKey('Groups')) {
                foreach ($groupName in $userDef.Groups) {
                    Add-UserToGroup $userDef.SamAccountName $groupName
                }
            }
        }
    }
    
    # Process Demo Users
    if ($Config.ContainsKey('Users') -and $Config.Users.ContainsKey('DemoUsers')) {
        Write-Status "Creating demo user accounts..." -Level Info
        foreach ($userDef in $Config.Users.DemoUsers) {
            $ouPath = Resolve-OUPath $userDef.OUPath $DomainInfo
            $user = New-UserAccount $userDef $ouPath
            if ($user) { $createdCount++ } else { $skippedCount++ }
            
            if ($userDef.ContainsKey('Groups')) {
                foreach ($groupName in $userDef.Groups) {
                    Add-UserToGroup $userDef.SamAccountName $groupName
                }
            }
        }
    }
    
    # Process Service Accounts
    if ($Config.ContainsKey('Users') -and $Config.Users.ContainsKey('ServiceAccounts')) {
        Write-Status "Creating service accounts..." -Level Info
        foreach ($userDef in $Config.Users.ServiceAccounts) {
            $ouPath = Resolve-OUPath $userDef.OUPath $DomainInfo
            $user = New-UserAccount $userDef $ouPath
            if ($user) { $createdCount++ } else { $skippedCount++ }
            
            if ($userDef.ContainsKey('Groups')) {
                foreach ($groupName in $userDef.Groups) {
                    Add-UserToGroup $userDef.SamAccountName $groupName
                }
            }
        }
    }
    
    # Process Bulk Users (numbered generation)
    if ($Config.ContainsKey('Users') -and $Config.Users.ContainsKey('BulkUsers')) {
        $bulkConfig = $Config.Users.BulkUsers
        $count = if ($bulkConfig.ContainsKey('Count')) { $bulkConfig.Count } else { 250 }
        
        Write-Status "Creating $count bulk user accounts..." -Level Info
        $ouPath = Resolve-OUPath $bulkConfig.OUPath $DomainInfo
        $namePattern = if ($bulkConfig.ContainsKey('NamePattern')) { $bulkConfig.NamePattern } else { "GdAct0r-{0:D6}" }
        $basePassword = if ($bulkConfig.ContainsKey('Password')) { $bulkConfig.Password } else { $Config.General.DefaultPassword }
        
        for ($i = 0; $i -lt $count; $i++) {
            $samName = [string]::Format($namePattern, $i)
            $userDef = @{
                SamAccountName = $samName
                Name = $samName
                Password = $basePassword
                Enabled = $true
                PasswordNeverExpires = $false
            }
            
            $user = New-UserAccount $userDef $ouPath
            if ($user) { $createdCount++ } else { $skippedCount++ }
        }
    }
    
    # Process DeleteMe Users (numbered generation)
    if ($Config.ContainsKey('Users') -and $Config.Users.ContainsKey('DeleteMeUsers')) {
        $deleteConfig = $Config.Users.DeleteMeUsers
        $count = if ($deleteConfig.ContainsKey('Count')) { $deleteConfig.Count } else { 10 }
        
        Write-Status "Creating $count DeleteMe user accounts..." -Level Info
        $ouPath = Resolve-OUPath $deleteConfig.OUPath $DomainInfo
        $namePattern = if ($deleteConfig.ContainsKey('NamePattern')) { $deleteConfig.NamePattern } else { "GenericAct0r-{0:D6}" }
        $basePassword = if ($deleteConfig.ContainsKey('Password')) { $deleteConfig.Password } else { $Config.General.DefaultPassword }
        
        for ($i = 0; $i -lt $count; $i++) {
            $samName = [string]::Format($namePattern, $i)
            $userDef = @{
                SamAccountName = $samName
                Name = $samName
                Password = $basePassword
                Enabled = $true
                PasswordNeverExpires = $false
            }
            
            $user = New-UserAccount $userDef $ouPath
            if ($user) { $createdCount++ } else { $skippedCount++ }
        }
    }
    
    Write-Host ""
    Write-Status "User creation completed - Created: $createdCount, Skipped: $skippedCount" -Level Success
    Write-Host ""
    
    return $true
}

Export-ModuleMember -Function Invoke-CreateUsers