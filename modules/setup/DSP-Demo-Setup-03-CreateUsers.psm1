################################################################################
##
## DSP-Demo-Setup-03-CreateUsers.psm1
##
## Creates user accounts from configuration file.
## Operator-configurable via DSP-Demo-Config-Setup.psd1
##
## Configuration sections consumed:
##  - Users.Tier0Admins, Users.Tier1Admins, Users.Tier2Admins
##  - Users.DemoUsers
##  - Users.OpsAdmins
##  - Users.ServiceAccounts
##  - Users.GenericUsers (bulk numbered accounts)
##
## All users created with idempotent logic (create if not exists).
## Group membership applied as configured.
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

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

function Unlock-UserAccount {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SamAccountName
    )
    
    try {
        $user = Get-ADUser -Identity $SamAccountName -Properties LockedOut -ErrorAction Stop
        
        if ($user.LockedOut) {
            Unlock-ADAccount -Identity $user.DistinguishedName -ErrorAction Stop
            Write-Status "Unlocked account: $SamAccountName" -Level Success
            return $true
        }
        else {
            Write-Status "Account not locked: $SamAccountName" -Level Info
            return $true
        }
    }
    catch {
        Write-Status "Error unlocking account '$SamAccountName': $_" -Level Error
        return $false
    }
}

function Resolve-OUPath {
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

function New-UserAccount {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$UserDef,
        
        [Parameter(Mandatory=$true)]
        [string]$OUPath,
        
        [Parameter(Mandatory=$true)]
        [securestring]$Password,
        
        [Parameter(Mandatory=$true)]
        [string]$DomainFQDN,
        
        [Parameter(Mandatory=$false)]
        [switch]$Quiet
    )
    
    $samAccountName = $UserDef.SamAccountName
    
    # Check if user exists
    try {
        $existingUser = Get-ADUser -Identity $samAccountName -ErrorAction Stop
        
        if (-not $Quiet) {
            Write-Status "User already exists: $samAccountName" -Level Info
        }
        return $existingUser
    }
    catch {
        # User doesn't exist, continue with creation
    }
    
    try {
        $newUserParams = @{
            SamAccountName = $samAccountName
            Name = if ($UserDef.DisplayName) { $UserDef.DisplayName } else { "$($UserDef.GivenName) $($UserDef.Surname)" }
            Path = $OUPath
            Enabled = $true
            AccountPassword = $Password
            ChangePasswordAtLogon = $false
            ErrorAction = 'Stop'
        }
        
        # Add optional attributes
        if ($UserDef.ContainsKey('GivenName')) { $newUserParams['GivenName'] = $UserDef.GivenName }
        if ($UserDef.ContainsKey('Surname')) { $newUserParams['Surname'] = $UserDef.Surname }
        if ($UserDef.ContainsKey('DisplayName')) { $newUserParams['DisplayName'] = $UserDef.DisplayName }
        if ($UserDef.ContainsKey('Description')) { $newUserParams['Description'] = $UserDef.Description }
        if ($UserDef.ContainsKey('UserPrincipalName')) { 
            $upn = $UserDef.UserPrincipalName -replace '{DOMAIN}', $DomainFQDN
            $newUserParams['UserPrincipalName'] = $upn 
        }
        if ($UserDef.ContainsKey('Title')) { $newUserParams['Title'] = $UserDef.Title }
        if ($UserDef.ContainsKey('Department')) { $newUserParams['Department'] = $UserDef.Department }
        if ($UserDef.ContainsKey('Division')) { $newUserParams['Division'] = $UserDef.Division }
        if ($UserDef.ContainsKey('Company')) { $newUserParams['Company'] = $UserDef.Company }
        if ($UserDef.ContainsKey('OfficePhone')) {
            $newUserParams['OfficePhone'] = $UserDef.OfficePhone 
        }
        if ($UserDef.ContainsKey('Fax')) { $newUserParams['Fax'] = $UserDef.Fax }
        if ($UserDef.ContainsKey('City')) { $newUserParams['City'] = $UserDef.City }
        if ($UserDef.ContainsKey('EmployeeID')) { $newUserParams['EmployeeID'] = $UserDef.EmployeeID }
        
        # Handle PasswordNeverExpires
        $user = New-ADUser @newUserParams -PassThru
        
        if ($UserDef.ContainsKey('PasswordNeverExpires') -and $UserDef.PasswordNeverExpires) {
            Set-ADUser -Identity $samAccountName -PasswordNeverExpires $true
        }
        
        if (-not $Quiet) {
            Write-Status "Created user: $samAccountName" -Level Success
        }
        return $user
    }
    catch {
        if (-not $Quiet) {
            Write-Status "Error creating user '$samAccountName': $_" -Level Error
        }
        return $null
    }
}

function Add-UserToGroup {
    param(
        [Parameter(Mandatory=$true)]
        [string]$UserSam,
        
        [Parameter(Mandatory=$true)]
        [string]$GroupName
    )
    
    # Get user by SamAccountName
    $user = Get-ADUser -Filter { SamAccountName -eq $UserSam } -ErrorAction SilentlyContinue
    if (-not $user) {
        Write-Status "User '$UserSam' not found" -Level Warning
        return $false
    }
    
    # Get group by Name
    $group = Get-ADGroup -Filter { Name -eq $GroupName } -ErrorAction SilentlyContinue
    if (-not $group) {
        Write-Status "Group '$GroupName' not found" -Level Warning
        return $false
    }
    
    # Check current membership by getting group members and checking DN match
    # (more reliable than checking SamAccountName from Get-ADGroupMember)
    try {
        $currentMembers = Get-ADGroupMember -Identity $group.DistinguishedName `
            -ErrorAction SilentlyContinue | Select-Object -ExpandProperty DistinguishedName
        
        if ($currentMembers -contains $user.DistinguishedName) {
            Write-Status "Group membership: '$UserSam' already in '$GroupName'" -Level Info
            return $true
        }
    }
    catch {
        # Get-ADGroupMember failed, try alternative check
        Write-Status "  (membership check returned error, attempting add anyway)" -Level Info
    }
    
    # Add user to group
    try {
        Add-ADGroupMember -Identity $group.DistinguishedName -Members $user.DistinguishedName `
            -ErrorAction Stop
        Write-Status "Group membership: Added '$UserSam' to '$GroupName'" -Level Success
        return $true
    }
    catch {
        Write-Status "Failed to add '$UserSam' to '$GroupName': $_" -Level Error
        return $false
    }
}

function Invoke-CreateUsers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        $Environment
    )
    
    $DomainInfo = $Environment.DomainInfo
    $DefaultPassword = if ($Config.General.ContainsKey('DefaultPassword')) { 
        ConvertTo-SecureString -String $Config.General.DefaultPassword -AsPlainText -Force
    } else { 
        ConvertTo-SecureString -String "P@ssw0rd123!" -AsPlainText -Force
    }
    $domainFQDN = $DomainInfo.FQDN
    
    Write-Host ""
    Write-Status "Creating user accounts..." -Level Info
    
    $createdCount = 0
    $skippedCount = 0
    
    # Check if Users section exists
    if (-not $Config.ContainsKey('Users')) {
        Write-Status "No Users section in configuration - skipping" -Level Info
        Write-Host ""
        return $true
    }
    
    $users = $Config.Users
    
    # Process each user type
    foreach ($userType in @('Tier0Admins', 'Tier1Admins', 'Tier2Admins', 'DemoUsers', 'OpsAdmins', 'ServiceAccounts', 'AttackUsers')) {
        if ($users.ContainsKey($userType) -and $users[$userType]) {
            Write-Status "Creating $userType..." -Level Info
            
            $userList = $users[$userType]
            if ($userList -isnot [array]) {
                $userList = @($userList)
            }
            
            foreach ($userDef in $userList) {
                $ouPath = Resolve-OUPath $userDef.OUPath $DomainInfo
                $user = New-UserAccount -UserDef $userDef -OUPath $ouPath -Password $DefaultPassword -DomainFQDN $domainFQDN
                
                if ($user) {
                    $createdCount++
                    
                    # Add to groups if specified
                    if ($userDef.ContainsKey('Groups') -and $userDef.Groups) {
                        foreach ($groupName in $userDef.Groups) {
                            Add-UserToGroup -UserSam $userDef.SamAccountName -GroupName $groupName
                        }
                    }
                }
                else {
                    $skippedCount++
                }
            }
        }
    }
    
    # Process GenericUsers (bulk)
    if ($users.ContainsKey('GenericUsers') -and $users.GenericUsers) {
        $genericConfig = $users.GenericUsers
        $count = $genericConfig.Count
        $prefix = $genericConfig.NamePrefix
        $ouPath = Resolve-OUPath $genericConfig.OUPath $DomainInfo
        
        Write-Host ""
        Write-Status "Creating $count generic users..." -Level Info
        Write-Host ""
        
        for ($i = 1; $i -le $count; $i++) {
            # Update progress bar
            $percentComplete = [math]::Round(($i / $count) * 100)
            Write-Progress -Activity "Creating Generic Users" -Status "User $i of $count" -PercentComplete $percentComplete
            
            $num = $i.ToString("000")
            $sam = "$prefix$num".ToLower()
            
            $userDef = @{
                GivenName = $prefix
                Surname = $num
                DisplayName = "$prefix $num"
                SamAccountName = $sam
                Description = $genericConfig.Description
                UserPrincipalName = "$sam@{DOMAIN}"
                OUPath = $genericConfig.OUPath
            }
            
            $user = New-UserAccount -UserDef $userDef -OUPath $ouPath -Password $DefaultPassword -DomainFQDN $domainFQDN -Quiet
            if ($user) { $createdCount++ } else { $skippedCount++ }
        }
        
        # Complete the progress bar
        Write-Progress -Activity "Creating Generic Users" -Completed
        Write-Host ""
    }
    
    # Unlock any accounts that may have been locked by previous activity runs
    Write-Host ""
    Write-Status "Ensuring demo accounts are unlocked..." -Level Info
    Write-Host ""
    
    $demoUsersToUnlock = @('lskywalker')
    foreach ($sam in $demoUsersToUnlock) {
        Unlock-UserAccount -SamAccountName $sam
    }
    
    Write-Host ""
    Write-Status "User creation completed - Created: $createdCount, Skipped: $skippedCount" -Level Info
    Write-Host ""
    
    return $true
}

Export-ModuleMember -Function Invoke-CreateUsers