################################################################################
##
## DSP-Demo-01-Directory.psm1
##
## Directory (Stage 1) activity module for DSP demo
## Creates users, groups, OUs, computers, and FGPP objects
## Uses configuration file to populate demo environment
##
## Functions:
##   - New-DirectoryStructure
##   - New-OU
##   - New-User
##   - New-Group
##   - New-Computer
##   - New-FGPP
##   - New-BulkGenericUsers
##   - Invoke-DirectoryActivity
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

################################################################################
# LOGGING FUNCTIONS
################################################################################

function Write-ActivityLog {
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
# OU FUNCTIONS
################################################################################

function New-OU {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$false)]
        [string]$Description = "",
        
        [Parameter(Mandatory=$false)]
        [bool]$ProtectFromAccidentalDeletion = $true
    )
    
    try {
        # Build the expected DN for this OU
        $expectedDN = "OU=$Name,$Path"
        
        # Check if this exact OU already exists
        $existingOU = Get-ADOrganizationalUnit -Identity $expectedDN -ErrorAction SilentlyContinue
        
        if ($existingOU) {
            Write-ActivityLog "OU already exists: $Name (using existing)" -Level Info
            return $existingOU
        }
        
        # Verify the Path exists before creating
        $parentPath = Get-ADOrganizationalUnit -Identity $Path -ErrorAction SilentlyContinue
        if (-not $parentPath) {
            Write-ActivityLog "Parent path does not exist: $Path" -Level Error
            return $null
        }
        
        $ouParams = @{
            Name = $Name
            Path = $Path
            Description = $Description
            ProtectedFromAccidentalDeletion = $ProtectFromAccidentalDeletion
            ErrorAction = 'Stop'
        }
        
        $newOU = New-ADOrganizationalUnit @ouParams
        Write-ActivityLog "OU created: $Name" -Level Success
        return $newOU
    }
    catch {
        Write-ActivityLog "Failed to create OU $Name : $_" -Level Error
        return $null
    }
}

function New-DirectoryStructure {
    param(
        [Parameter(Mandatory=$true)]
        [string]$DomainDN
    )
    
    try {
        Write-ActivityLog "Creating directory structure in $DomainDN" -Level Info
        
        # Root OUs
        $labAdminsOU = New-OU -Name "Lab Admins" -Path $DomainDN -Description "Lab administrative accounts and groups"
        $labUsersOU = New-OU -Name "Lab Users" -Path $DomainDN -Description "Lab user accounts"
        $badOU = New-OU -Name "Bad OU" -Path $DomainDN -Description "OU for testing bad configurations"
        $deleteOU = New-OU -Name "DeleteMe OU" -Path $DomainDN -Description "OU for deletion and recovery demonstrations"
        $serversOU = New-OU -Name "Servers" -Path $DomainDN -Description "Server computer objects"
        $tier0OU = New-OU -Name "Tier-0-Special-Assets" -Path $DomainDN -Description "Tier 0 special assets with restricted access"
        $testOU = New-OU -Name "TEST" -Path $DomainDN -Description "Generic test user accounts (bulk created)" -ProtectFromAccidentalDeletion $false
        
        # Sub-OUs under Lab Admins
        $tier0AdminsOU = New-OU -Name "Tier 0" -Path $labAdminsOU.DistinguishedName -Description "Tier 0 administrators"
        $tier1AdminsOU = New-OU -Name "Tier 1" -Path $labAdminsOU.DistinguishedName -Description "Tier 1 administrators"
        $tier2AdminsOU = New-OU -Name "Tier 2" -Path $labAdminsOU.DistinguishedName -Description "Tier 2 administrators"
        
        # Sub-OUs under Lab Users
        $labUsers01OU = New-OU -Name "Lab Users 01" -Path $labUsersOU.DistinguishedName -Description "Lab users group 1"
        $labUsers02OU = New-OU -Name "Lab Users 02" -Path $labUsersOU.DistinguishedName -Description "Lab users group 2"
        
        # Sub-OUs under DeleteMe OU (for deletion demos)
        $resourcesOU = New-OU -Name "Resources" -Path $deleteOU.DistinguishedName -Description "Resources sub-OU" -ProtectFromAccidentalDeletion $false
        $corpSpecialOU = New-OU -Name "Corp Special OU" -Path $deleteOU.DistinguishedName -Description "Corporate special OU" -ProtectFromAccidentalDeletion $false
        
        Write-ActivityLog "Directory structure created successfully" -Level Success
        
        return @{
            LabAdminsOU = $labAdminsOU
            Tier0AdminsOU = $tier0AdminsOU
            Tier1AdminsOU = $tier1AdminsOU
            Tier2AdminsOU = $tier2AdminsOU
            LabUsersOU = $labUsersOU
            LabUsers01OU = $labUsers01OU
            LabUsers02OU = $labUsers02OU
            BadOU = $badOU
            DeleteOU = $deleteOU
            ResourcesOU = $resourcesOU
            CorpSpecialOU = $corpSpecialOU
            ServersOU = $serversOU
            Tier0OU = $tier0OU
            TestOU = $testOU
        }
    }
    catch {
        Write-ActivityLog "Failed to create directory structure: $_" -Level Error
        return $null
    }
}

################################################################################
# USER FUNCTIONS
################################################################################

function New-User {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SamAccountName,
        
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$false)]
        [string]$GivenName = "",
        
        [Parameter(Mandatory=$false)]
        [string]$Surname = "",
        
        [Parameter(Mandatory=$false)]
        [string]$Description = "",
        
        [Parameter(Mandatory=$false)]
        [string]$Title = "",
        
        [Parameter(Mandatory=$false)]
        [string]$Department = "",
        
        [Parameter(Mandatory=$false)]
        [string]$Mail = "",
        
        [Parameter(Mandatory=$false)]
        [string]$TelephoneNumber = "",
        
        [Parameter(Mandatory=$false)]
        [string]$DisplayName = "",
        
        [Parameter(Mandatory=$false)]
        [securestring]$Password,
        
        [Parameter(Mandatory=$false)]
        [bool]$PasswordNeverExpires = $true
    )
    
    try {
        # Check if user already exists
        $existingUser = Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -ErrorAction SilentlyContinue
        
        if ($existingUser) {
            Write-ActivityLog "User already exists: $SamAccountName" -Level Info
            return $existingUser
        }
        
        $userParams = @{
            SamAccountName = $SamAccountName
            Name = $Name
            Path = $Path
            Enabled = $true
            ChangePasswordAtLogon = $false
            PasswordNeverExpires = $PasswordNeverExpires
            ErrorAction = 'Stop'
        }
        
        if ($GivenName) { $userParams['GivenName'] = $GivenName }
        if ($Surname) { $userParams['Surname'] = $Surname }
        if ($DisplayName) { $userParams['DisplayName'] = $DisplayName }
        if ($Description) { $userParams['Description'] = $Description }
        if ($Title) { $userParams['Title'] = $Title }
        if ($Department) { $userParams['Department'] = $Department }
        if ($Mail) { $userParams['Mail'] = $Mail }
        if ($TelephoneNumber) { $userParams['OfficePhone'] = $TelephoneNumber }
        if ($Password) { $userParams['AccountPassword'] = $Password }
        
        $user = New-ADUser @userParams
        Write-ActivityLog "User created successfully: $SamAccountName" -Level Success
        return $user
    }
    catch {
        Write-ActivityLog "Failed to create user $SamAccountName : $_" -Level Error
        return $null
    }
}

################################################################################
# GROUP FUNCTIONS
################################################################################

function New-Group {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('DomainLocal','Global','Universal')]
        [string]$GroupScope = 'Global',
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Distribution','Security')]
        [string]$GroupCategory = 'Security',
        
        [Parameter(Mandatory=$false)]
        [string]$Description = "",
        
        [Parameter(Mandatory=$false)]
        [string[]]$Members = @()
    )
    
    try {
        # Check if group already exists
        $existingGroup = Get-ADGroup -Filter "Name -eq '$Name'" -ErrorAction SilentlyContinue
        
        if ($existingGroup) {
            Write-ActivityLog "Group already exists: $Name" -Level Info
            return $existingGroup
        }
        
        $groupParams = @{
            Name = $Name
            Path = $Path
            GroupScope = $GroupScope
            GroupCategory = $GroupCategory
            ErrorAction = 'Stop'
        }
        
        if ($Description) { $groupParams['Description'] = $Description }
        
        $group = New-ADGroup @groupParams
        Write-ActivityLog "Group created: $Name" -Level Success
        
        # Add members if provided
        if ($Members.Count -gt 0) {
            foreach ($member in $Members) {
                try {
                    $memberObj = Get-ADUser -Filter "SamAccountName -eq '$member'" -ErrorAction SilentlyContinue
                    if ($memberObj) {
                        Add-ADGroupMember -Identity $group.DistinguishedName -Members $memberObj.DistinguishedName -ErrorAction Stop
                        Write-ActivityLog "Added member $member to group $Name" -Level Info
                    }
                }
                catch {
                    Write-ActivityLog "Failed to add member $member to group $Name : $_" -Level Warning
                }
            }
        }
        
        return $group
    }
    catch {
        Write-ActivityLog "Failed to create group $Name : $_" -Level Error
        return $null
    }
}

################################################################################
# COMPUTER FUNCTIONS
################################################################################

function New-Computer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$false)]
        [string]$Description = ""
    )
    
    try {
        $existingComputer = Get-ADComputer -Filter "Name -eq '$Name'" -ErrorAction SilentlyContinue
        
        if ($existingComputer) {
            Write-ActivityLog "Computer already exists: $Name" -Level Info
            return $existingComputer
        }
        
        $computerParams = @{
            Name = $Name
            Path = $Path
            SAMAccountName = $Name
            ErrorAction = 'Stop'
        }
        
        if ($Description) { $computerParams['Description'] = $Description }
        
        $computer = New-ADComputer @computerParams
        Write-ActivityLog "Computer created: $Name" -Level Success
        return $computer
    }
    catch {
        Write-ActivityLog "Failed to create computer $Name : $_" -Level Error
        return $null
    }
}

################################################################################
# FGPP FUNCTIONS
################################################################################

function New-FGPP {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [int]$Precedence,
        
        [Parameter(Mandatory=$false)]
        [int]$MinPasswordLength = 12,
        
        [Parameter(Mandatory=$false)]
        [int]$LockoutThreshold = 5,
        
        [Parameter(Mandatory=$false)]
        [int]$PasswordHistoryCount = 24
    )
    
    try {
        $existingFGPP = Get-ADFineGrainedPasswordPolicy -Filter "Name -eq '$Name'" -ErrorAction SilentlyContinue
        
        if ($existingFGPP) {
            Write-ActivityLog "FGPP already exists: $Name" -Level Info
            return $existingFGPP
        }
        
        $fgppParams = @{
            Name = $Name
            Precedence = $Precedence
            MinPasswordLength = $MinPasswordLength
            LockoutThreshold = $LockoutThreshold
            PasswordHistoryCount = $PasswordHistoryCount
            ComplexityEnabled = $true
            LockoutDuration = (New-TimeSpan -Minutes 30)
            LockoutObservationWindow = (New-TimeSpan -Minutes 30)
            MaxPasswordAge = (New-TimeSpan -Days 42)
            MinPasswordAge = (New-TimeSpan -Days 1)
            ReversibleEncryptionEnabled = $false
            ErrorAction = 'Stop'
        }
        
        $fgpp = New-ADFineGrainedPasswordPolicy @fgppParams
        Write-ActivityLog "FGPP created: $Name" -Level Success
        return $fgpp
    }
    catch {
        Write-ActivityLog "Failed to create FGPP $Name : $_" -Level Error
        return $null
    }
}

################################################################################
# BULK USER FUNCTIONS
################################################################################

function New-BulkGenericUsers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$OU,
        
        [Parameter(Mandatory=$true)]
        [int]$Count,
        
        [Parameter(Mandatory=$false)]
        [string]$Prefix = "GdAct0r",
        
        [Parameter(Mandatory=$false)]
        [securestring]$Password
    )
    
    if (-not $Password) {
        $Password = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force
    }
    
    $createdCount = 0
    $skippedCount = 0
    
    for ($i = 0; $i -lt $Count; $i++) {
        # Pad the number with leading zeros (6 digits)
        $index = $i.ToString().PadLeft(6, '0')
        $samAccountName = "$Prefix-$index"
        $displayName = "Generic Act0r $index"
        
        # Check if user exists first
        $existingUser = Get-ADUser -Filter "SamAccountName -eq '$samAccountName'" -ErrorAction SilentlyContinue
        
        if (-not $existingUser) {
            try {
                New-ADUser -SamAccountName $samAccountName `
                          -Name $displayName `
                          -DisplayName $displayName `
                          -GivenName "Generic" `
                          -Surname "Act0r $index" `
                          -Path $OU `
                          -AccountPassword $Password `
                          -Enabled $true `
                          -ChangePasswordAtLogon $false `
                          -CannotChangePassword $true `
                          -PasswordNeverExpires $true `
                          -ErrorAction Stop | Out-Null
                
                $createdCount++
            }
            catch {
                Write-ActivityLog "Failed to create user $samAccountName : $_" -Level Warning
            }
        }
        else {
            $skippedCount++
        }
        
        # Show progress every 50 users
        if (($i + 1) % 50 -eq 0) {
            Write-ActivityLog "Progress: $($i + 1) of $Count users processed..." -Level Info
        }
    }
    
    Write-ActivityLog "Bulk user creation completed: $createdCount created, $skippedCount skipped" -Level Success
}

################################################################################
# MAIN MODULE EXECUTION
################################################################################

function Invoke-DirectoryActivity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$DomainInfo,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Config
    )
    
    Write-ActivityLog "=== Starting Directory Activity Module ===" -Level Info
    
    $domainDN = $DomainInfo.DistinguishedName
    
    # Step 1: Create directory structure
    Write-ActivityLog "Step 1: Creating OU hierarchy..." -Level Info
    $structure = New-DirectoryStructure -DomainDN $domainDN
    
    if (-not $structure) {
        Write-ActivityLog "Failed to create directory structure - aborting" -Level Error
        return $false
    }
    
    # Step 2: Create admin users (Tier 0, 1, 2)
    if ($Config -and $Config.ContainsKey('AdminUsers') -and $Config.AdminUsers) {
        Write-ActivityLog "Step 2: Creating admin user accounts..." -Level Info
        
        foreach ($adminConfig in $Config.AdminUsers.Values) {
            if ($adminConfig -is [hashtable]) {
                $password = ConvertTo-SecureString $adminConfig.Password -AsPlainText -Force
                
                # Determine which OU based on Title or hardcoded defaults
                $targetOU = $structure.Tier2AdminsOU.DistinguishedName
                if ($adminConfig.ContainsKey('Path') -and $adminConfig.Path) {
                    $targetOU = $adminConfig.Path
                }
                
                New-User -SamAccountName $adminConfig.SamAccountName `
                         -Name $adminConfig.Name `
                         -GivenName $adminConfig.GivenName `
                         -Surname $adminConfig.Surname `
                         -DisplayName $adminConfig.DisplayName `
                         -Title $adminConfig.Title `
                         -Department $adminConfig.Department `
                         -Mail $adminConfig.Mail `
                         -TelephoneNumber $adminConfig.TelephoneNumber `
                         -Description $adminConfig.Description `
                         -Path $targetOU `
                         -Password $password `
                         -PasswordNeverExpires $true
            }
        }
    } else {
        Write-ActivityLog "Step 2: Skipping admin users (not in config)" -Level Info
    }
    
    # Step 3: Create demo users
    if ($Config -and $Config.ContainsKey('DemoUsers') -and $Config.DemoUsers) {
        Write-ActivityLog "Step 3: Creating demo user accounts..." -Level Info
        
        foreach ($userConfig in $Config.DemoUsers.Values) {
            if ($userConfig -is [hashtable]) {
                $password = ConvertTo-SecureString $userConfig.Password -AsPlainText -Force
                
                $targetOU = $structure.LabUsers01OU.DistinguishedName
                if ($userConfig.ContainsKey('Path') -and $userConfig.Path) {
                    $targetOU = $userConfig.Path
                }
                
                New-User -SamAccountName $userConfig.SamAccountName `
                         -Name $userConfig.Name `
                         -GivenName $userConfig.GivenName `
                         -Surname $userConfig.Surname `
                         -DisplayName $userConfig.DisplayName `
                         -Title $userConfig.Title `
                         -Department $userConfig.Department `
                         -Mail $userConfig.Mail `
                         -TelephoneNumber $userConfig.TelephoneNumber `
                         -Description $userConfig.Description `
                         -Path $targetOU `
                         -Password $password `
                         -PasswordNeverExpires $true
            }
        }
    } else {
        Write-ActivityLog "Step 3: Skipping demo users (not in config)" -Level Info
    }
    
    # Step 4: Create computers
    if ($Config -and $Config.ContainsKey('Computers') -and $Config.Computers) {
        Write-ActivityLog "Step 4: Creating computer objects..." -Level Info
        
        foreach ($computerConfig in $Config.Computers.Values) {
            if ($computerConfig -is [hashtable]) {
                New-Computer -Name $computerConfig.Name `
                            -Path $structure.ServersOU.DistinguishedName `
                            -Description $computerConfig.Description
            }
        }
    } else {
        Write-ActivityLog "Step 4: Skipping computers (not in config)" -Level Info
    }
    
    # Step 5: Create security groups
    if ($Config -and $Config.ContainsKey('Groups') -and $Config.Groups) {
        Write-ActivityLog "Step 5: Creating security groups..." -Level Info
        
        foreach ($groupConfig in $Config.Groups.Values) {
            if ($groupConfig -is [hashtable]) {
                # Determine group path from config or use default
                $groupPath = $structure.LabAdminsOU.DistinguishedName
                
                if ($groupConfig.ContainsKey('Path') -and $groupConfig.Path) {
                    $groupPath = $groupConfig.Path
                } else {
                    # For backward compatibility, check if group belongs in a special OU
                    if ($groupConfig.Name -eq "Resource Admins") {
                        $groupPath = $structure.ResourcesOU.DistinguishedName
                    }
                    elseif ($groupConfig.Name -eq "Special Access - Datacenter") {
                        $groupPath = $structure.CorpSpecialOU.DistinguishedName
                    }
                }
                
                New-Group -Name $groupConfig.Name `
                         -Path $groupPath `
                         -GroupScope $groupConfig.GroupScope `
                         -GroupCategory $groupConfig.GroupCategory `
                         -Description $groupConfig.Description `
                         -Members $groupConfig.Members
            }
        }
    } else {
        Write-ActivityLog "Step 5: Skipping groups (not in config)" -Level Info
    }
    
    # Step 6: Create Fine-Grained Password Policies
    if ($Config -and $Config.ContainsKey('FGPPs') -and $Config.FGPPs) {
        Write-ActivityLog "Step 6: Creating Fine-Grained Password Policies..." -Level Info
        
        foreach ($fgppConfig in $Config.FGPPs.Values) {
            if ($fgppConfig -is [hashtable]) {
                New-FGPP -Name $fgppConfig.Name `
                        -Precedence $fgppConfig.Precedence `
                        -MinPasswordLength $fgppConfig.MinPasswordLength `
                        -LockoutThreshold $fgppConfig.LockoutThreshold `
                        -PasswordHistoryCount $fgppConfig.PasswordHistoryCount
            }
        }
    } else {
        Write-ActivityLog "Step 6: Skipping FGPPs (not in config)" -Level Info
    }
    
    # Step 7: Create bulk generic test users
    if ($Config -and $Config.ContainsKey('General') -and $Config.General.ContainsKey('GenericUserCount') -and $Config.General.GenericUserCount -gt 0) {
        Write-ActivityLog "Step 7: Creating bulk generic test users..." -Level Info
        Write-ActivityLog "Creating $($Config.General.GenericUserCount) bulk generic users in TEST OU" -Level Info
        
        $bulkPassword = ConvertTo-SecureString $Config.General.DefaultPassword -AsPlainText -Force
        
        New-BulkGenericUsers -OU $structure.TestOU.DistinguishedName `
                            -Count $Config.General.GenericUserCount `
                            -Prefix "GdAct0r" `
                            -Password $bulkPassword
    } else {
        Write-ActivityLog "Step 7: Skipping bulk generic users (not in config)" -Level Info
    }
    
    Write-ActivityLog "=== Directory Activity Module completed successfully ===" -Level Success
    return $true
}

################################################################################
# EXPORT FUNCTIONS
################################################################################

Export-ModuleMember -Function @(
    'New-DirectoryStructure',
    'New-OU',
    'New-User',
    'New-Group',
    'New-Computer',
    'New-FGPP',
    'New-BulkGenericUsers',
    'Invoke-DirectoryActivity'
)

################################################################################
# END OF MODULE
################################################################################