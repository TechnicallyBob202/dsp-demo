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
##  - GenericUsers (bulk numbered accounts with progress bar)
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
    Converts logical OU path (e.g. "Lab Admins/Tier 0") to Distinguished Name
    Example: "Lab Admins/Tier 0" with domain DC=d3,DC=lab becomes:
             OU=Tier 0,OU=Lab Admins,DC=d3,DC=lab
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
    
    $parts = $LogicalPath -split '/'
    $dnParts = @()
    
    for ($i = $parts.Count - 1; $i -ge 0; $i--) {
        $part = $parts[$i]
        if ($part -and $part -ne "Root") {
            $dnParts += "OU=$part"
        }
    }
    
    $dn = ($dnParts -join ",") + "," + $domainDN
    return $dn
}

function Update-UserAccount {
    <#
    .SYNOPSIS
    Updates existing user account to ensure UPN is set and account is enabled.
    Does NOT change password.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SamAccountName,
        
        [Parameter(Mandatory=$true)]
        [string]$DomainFQDN
    )
    
    $user = Get-ADUser -Filter { SamAccountName -eq $SamAccountName } -ErrorAction SilentlyContinue
    if (-not $user) {
        return $null
    }
    
    $needsUpdate = $false
    $updateParams = @{ Identity = $user }
    
    # Check if UPN is missing or wrong
    $expectedUPN = "$SamAccountName@$DomainFQDN"
    if ($user.UserPrincipalName -ne $expectedUPN) {
        $updateParams['UserPrincipalName'] = $expectedUPN
        $needsUpdate = $true
    }
    
    # Check if disabled
    if ($user.Enabled -eq $false) {
        $updateParams['Enabled'] = $true
        $needsUpdate = $true
    }
    
    if ($needsUpdate) {
        try {
            Set-ADUser @updateParams -ErrorAction Stop
            Write-Status "Updated user '$SamAccountName'" -Level Success
            return $true
        }
        catch {
            Write-Status "Failed to update user '$SamAccountName': $_" -Level Error
            return $false
        }
    }
    
    return $true
}

function New-UserAccount {
    <#
    .SYNOPSIS
    Creates a user account with idempotent logic. Returns user object.
    Maps config keys to New-ADUser parameter names.
    Uses DefaultPassword if user definition doesn't specify one.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$UserDef,
        
        [Parameter(Mandatory=$true)]
        [string]$OUPath,
        
        [Parameter(Mandatory=$false)]
        [string]$DefaultPassword,
        
        [Parameter(Mandatory=$false)]
        [string]$DomainFQDN
    )
    
    $sam = $UserDef.SamAccountName
    
    $existing = Get-ADUser -Filter { SamAccountName -eq $sam } -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Status "User '$sam' already exists - skipping" -Level Info
        return $existing
    }
    
    $paramMap = @{
        'GivenName' = 'GivenName'
        'Surname' = 'Surname'
        'DisplayName' = 'DisplayName'
        'Title' = 'Title'
        'Department' = 'Department'
        'Company' = 'Company'
        'Mail' = 'EmailAddress'
        'TelephoneNumber' = 'OfficePhone'
        'MobilePhone' = 'MobilePhone'
        'Fax' = 'Fax'
        'Description' = 'Description'
        'Office' = 'Office'
        'StreetAddress' = 'StreetAddress'
        'City' = 'City'
        'State' = 'State'
        'PostalCode' = 'PostalCode'
        'Country' = 'Country'
    }
    
    $passwordToUse = $UserDef.Password
    if ([string]::IsNullOrWhiteSpace($passwordToUse)) {
        $passwordToUse = $DefaultPassword
    }
    
    # Handle {PASSWORD} placeholder - same fix as bulk users
    if ([string]::IsNullOrWhiteSpace($passwordToUse) -or $passwordToUse -eq "{PASSWORD}") {
        $passwordToUse = $DefaultPassword
    }
    
    if ([string]::IsNullOrWhiteSpace($passwordToUse)) {
        Write-Status "Failed to create user '$sam': No password specified and no default available" -Level Error
        return $null
    }
    
    $newUserParams = @{
        SamAccountName = $sam
        Name = $UserDef.Name
        Path = $OUPath
        AccountPassword = ConvertTo-SecureString $passwordToUse -AsPlainText -Force
        Enabled = $UserDef.Enabled
        PasswordNeverExpires = $UserDef.PasswordNeverExpires
        ErrorAction = 'Stop'
    }
    
    if ($DomainFQDN) {
        $newUserParams['UserPrincipalName'] = "$sam@$DomainFQDN"
    }
    
    foreach ($configKey in $paramMap.Keys) {
        if ($UserDef.ContainsKey($configKey) -and -not [string]::IsNullOrWhiteSpace($UserDef[$configKey])) {
            $paramKey = $paramMap[$configKey]
            $newUserParams[$paramKey] = $UserDef[$configKey]
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
    Adds user to group if not already member.
    Returns $true on success.
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
    $DefaultPassword = if ($Config.General.ContainsKey('DefaultPassword')) { $Config.General.DefaultPassword } else { $null }
    $domainFQDN = $DomainInfo.FQDN
    
    Write-Host ""
    Write-Status "Creating user accounts..." -Level Info
    
    $createdCount = 0
    $skippedCount = 0
    
    # Process Tier 0 Admins
    if ($Config.ContainsKey('Users') -and $Config.Users.ContainsKey('Tier0Admins')) {
        Write-Status "Creating Tier 0 admin accounts..." -Level Info
        foreach ($userDef in $Config.Users.Tier0Admins) {
            $ouPath = Resolve-OUPath $userDef.OUPath $DomainInfo
            $user = New-UserAccount $userDef $ouPath $DefaultPassword $domainFQDN
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
            $user = New-UserAccount $userDef $ouPath $DefaultPassword $domainFQDN
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
            $user = New-UserAccount $userDef $ouPath $DefaultPassword $domainFQDN
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
            $user = New-UserAccount $userDef $ouPath $DefaultPassword $domainFQDN
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
            $user = New-UserAccount $userDef $ouPath $DefaultPassword $domainFQDN
            if ($user) { $createdCount++ } else { $skippedCount++ }
            
            if ($userDef.ContainsKey('Groups')) {
                foreach ($groupName in $userDef.Groups) {
                    Add-UserToGroup $userDef.SamAccountName $groupName
                }
            }
        }
    }
    
    # Process Generic Bulk Users with progress bar
    if ($Config.ContainsKey('Users') -and $Config.Users.ContainsKey('GenericUsers')) {
        foreach ($bulkConfig in $Config.Users.GenericUsers) {
            $prefix = if ($bulkConfig.ContainsKey('SamAccountNamePrefix')) { $bulkConfig.SamAccountNamePrefix } else { "GdAct0r" }
            $count = if ($bulkConfig.ContainsKey('Count')) { $bulkConfig.Count } else { 250 }
            $ouPath = Resolve-OUPath $bulkConfig.OUPath $DomainInfo
            
            # Handle {PASSWORD} placeholder
            $rawPassword = if ($bulkConfig.ContainsKey('Password')) { $bulkConfig.Password } else { $DefaultPassword }
            $bulkPassword = if ([string]::IsNullOrWhiteSpace($rawPassword) -or $rawPassword -eq "{PASSWORD}") { $DefaultPassword } else { $rawPassword }
            
            $bulkDescription = if ($bulkConfig.ContainsKey('Description')) { $bulkConfig.Description } else { "Generic bulk user account" }
            $bulkCompany = if ($bulkConfig.ContainsKey('Company')) { $bulkConfig.Company } else { "" }
            
            Write-Status "Creating $count generic user accounts (prefix: $prefix) in $($bulkConfig.OUPath)..." -Level Info
            
            for ($i = 0; $i -lt $count; $i++) {
                $samName = "$prefix-{0:D6}" -f $i
                
                $existing = Get-ADUser -Filter { SamAccountName -eq $samName } -ErrorAction SilentlyContinue
                if (-not $existing) {
                    try {
                        $newUserParams = @{
                            SamAccountName = $samName
                            Name = $samName
                            UserPrincipalName = "$samName@$domainFQDN"
                            Path = $ouPath
                            AccountPassword = ConvertTo-SecureString $bulkPassword -AsPlainText -Force
                            Enabled = $true
                            PasswordNeverExpires = $false
                            ErrorAction = 'Stop'
                        }
                        if ($bulkDescription) { $newUserParams['Description'] = $bulkDescription }
                        if ($bulkCompany) { $newUserParams['Company'] = $bulkCompany }
                        
                        New-ADUser @newUserParams | Out-Null
                        $createdCount++
                    }
                    catch {
                        $skippedCount++
                    }
                }
                else {
                    $skippedCount++
                }
                
                # Progress bar update
                $percentComplete = [math]::Round((($i + 1) / $count) * 100)
                Write-Progress -Activity "Creating bulk users ($prefix)" -Status "$($i + 1) of $count" -PercentComplete $percentComplete
            }
            Write-Progress -Activity "Creating bulk users ($prefix)" -Completed
        }
    }
    
    Write-Host ""
    Write-Status "User creation completed - Created: $createdCount, Skipped: $skippedCount" -Level Success
    Write-Host ""
    
    return $true
}

Export-ModuleMember -Function Invoke-CreateUsers