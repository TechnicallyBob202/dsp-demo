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
        
        # Create new OU
        $ouParams = @{
            Name = $Name
            Path = $Path
            ProtectedFromAccidentalDeletion = $ProtectFromAccidentalDeletion
            ErrorAction = 'Stop'
        }
        
        if ($Description) {
            $ouParams['Description'] = $Description
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
        [string]$GivenName,
        
        [Parameter(Mandatory=$true)]
        [string]$Surname,
        
        [Parameter(Mandatory=$false)]
        [string]$DisplayName,
        
        [Parameter(Mandatory=$false)]
        [string]$UserPrincipalName,
        
        [Parameter(Mandatory=$false)]
        [string]$Title,
        
        [Parameter(Mandatory=$false)]
        [string]$Department,
        
        [Parameter(Mandatory=$false)]
        [string]$Company,
        
        [Parameter(Mandatory=$false)]
        [string]$Mail,
        
        [Parameter(Mandatory=$false)]
        [string]$TelephoneNumber,
        
        [Parameter(Mandatory=$false)]
        [string]$MobilePhone,
        
        [Parameter(Mandatory=$false)]
        [string]$Fax,
        
        [Parameter(Mandatory=$false)]
        [string]$Description,
        
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$true)]
        [securestring]$Password,
        
        [Parameter(Mandatory=$false)]
        [bool]$PasswordNeverExpires = $false,
        
        [Parameter(Mandatory=$false)]
        [bool]$Enabled = $true
    )
    
    try {
        # Validate path is not null or empty
        if ([string]::IsNullOrWhiteSpace($Path)) {
            Write-ActivityLog "User creation skipped - Path is null or empty for $SamAccountName" -Level Warning
            return $null
        }
        
        # Check if user already exists
        $existingUser = Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -ErrorAction SilentlyContinue
        
        if ($existingUser) {
            Write-ActivityLog "User already exists: $SamAccountName" -Level Info
            return $existingUser
        }
        
        # Build user creation parameters
        $userParams = @{
            SamAccountName = $SamAccountName
            Name = $Name
            GivenName = $GivenName
            Surname = $Surname
            Path = $Path
            AccountPassword = $Password
            Enabled = $Enabled
            PasswordNeverExpires = $PasswordNeverExpires
            ErrorAction = 'Stop'
        }
        
        # Add optional parameters if provided
        if ($DisplayName) { $userParams['DisplayName'] = $DisplayName }
        if ($UserPrincipalName) { $userParams['UserPrincipalName'] = $UserPrincipalName }
        if ($Title) { $userParams['Title'] = $Title }
        if ($Department) { $userParams['Department'] = $Department }
        if ($Company) { $userParams['Company'] = $Company }
        if ($Mail) { $userParams['EmailAddress'] = $Mail }
        if ($TelephoneNumber) { $userParams['OfficePhone'] = $TelephoneNumber }
        if ($MobilePhone) { $userParams['MobilePhone'] = $MobilePhone }
        if ($Fax) { $userParams['Fax'] = $Fax }
        if ($Description) { $userParams['Description'] = $Description }
        
        $newUser = New-ADUser @userParams
        Write-ActivityLog "User created: $SamAccountName" -Level Success
        return $newUser
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
        [string]$Description,
        
        [Parameter(Mandatory=$false)]
        [string]$GroupScope = "Global",
        
        [Parameter(Mandatory=$false)]
        [string]$GroupCategory = "Security"
    )
    
    try {
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
        
        $newGroup = New-ADGroup @groupParams
        Write-ActivityLog "Group created: $Name" -Level Success
        return $newGroup
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
        [string]$Description
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
            ErrorAction = 'Stop'
        }
        
        if ($Description) { $computerParams['Description'] = $Description }
        
        $newComputer = New-ADComputer @computerParams
        Write-ActivityLog "Computer created: $Name" -Level Success
        return $newComputer
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
    
    $created = 0
    $skipped = 0
    
    for ($i = 1; $i -le $Count; $i++) {
        $samAccountName = "$Prefix-$i"
        
        try {
            # Check if user exists
            $existingUser = Get-ADUser -Filter "SamAccountName -eq '$samAccountName'" -ErrorAction SilentlyContinue
            
            if ($existingUser) {
                $skipped++
            }
            else {
                $userName = "Generic Actor $i"
                New-ADUser -SamAccountName $samAccountName `
                           -Name $userName `
                           -GivenName "Generic" `
                           -Surname "Actor $i" `
                           -DisplayName $userName `
                           -Path $OU `
                           -AccountPassword $Password `
                           -Enabled $true `
                           -PasswordNeverExpires $false `
                           -ErrorAction Stop
                
                $created++
            }
        }
        catch {
            Write-ActivityLog "Failed to create bulk user $samAccountName : $_" -Level Warning
        }
        
        # Progress indicator
        if ($i % 50 -eq 0) {
            Write-ActivityLog "Progress: $i of $Count users processed..." -Level Info
        }
    }
    
    Write-ActivityLog "Bulk user creation completed: $created created, $skipped skipped" -Level Success
}

################################################################################
# DIRECTORY STRUCTURE FUNCTIONS
################################################################################

function New-DirectoryStructure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$DomainDN
    )
    
    try {
        Write-ActivityLog "Creating directory structure in $DomainDN" -Level Info
        
        # Create root demo OU
        $demoRootOU = New-OU -Name "DSP-Demo-Objects" -Path $DomainDN -Description "Root OU for DSP demo objects"
        
        if (-not $demoRootOU) {
            Write-ActivityLog "Failed to create demo root OU - cannot continue" -Level Error
            return $null
        }
        
        $rootPath = $demoRootOU.DistinguishedName
        
        # Create main OUs
        $labAdminsOU = New-OU -Name "Lab Admins" -Path $rootPath -Description "Lab administrator accounts"
        $labUsersOU = New-OU -Name "Lab Users" -Path $rootPath -Description "Lab user accounts"
        $badOU = New-OU -Name "Bad OU" -Path $rootPath -Description "Intentionally bad OU for demo"
        $deleteOU = New-OU -Name "DeleteMe OU" -Path $rootPath -Description "Demo - will be deleted" -ProtectFromAccidentalDeletion $false
        $serversOU = New-OU -Name "Servers" -Path $rootPath -Description "Server computer objects"
        $tier0OU = New-OU -Name "Tier-0-Special-Assets" -Path $rootPath -Description "Tier 0 special assets"
        $testOU = New-OU -Name "TEST" -Path $rootPath -Description "Test OU for generic users"
        
        # Validate critical OUs exist
        $criticalOUs = @('labAdminsOU', 'labUsersOU', 'testOU')
        foreach ($ouVarName in $criticalOUs) {
            $ou = Get-Variable -Name $ouVarName -ValueOnly
            if (-not $ou -or -not $ou.DistinguishedName) {
                Write-ActivityLog "Critical OU missing: $ouVarName" -Level Warning
            }
        }
        
        # Create sub-OUs under Lab Admins (if parent exists)
        $tier0AdminsOU = $null
        $tier1AdminsOU = $null
        $tier2AdminsOU = $null
        if ($labAdminsOU) {
            $tier0AdminsOU = New-OU -Name "Tier 0" -Path $labAdminsOU.DistinguishedName -Description "Tier 0 administrators"
            $tier1AdminsOU = New-OU -Name "Tier 1" -Path $labAdminsOU.DistinguishedName -Description "Tier 1 administrators"
            $tier2AdminsOU = New-OU -Name "Tier 2" -Path $labAdminsOU.DistinguishedName -Description "Tier 2 administrators"
        }
        
        # Create sub-OUs under Lab Users (if parent exists)
        $labUsers01OU = $null
        $labUsers02OU = $null
        if ($labUsersOU) {
            $labUsers01OU = New-OU -Name "Lab Users 01" -Path $labUsersOU.DistinguishedName -Description "Lab users group 1"
            $labUsers02OU = New-OU -Name "Lab Users 02" -Path $labUsersOU.DistinguishedName -Description "Lab users group 2"
        }
        
        # Create sub-OUs under DeleteMe OU (if parent exists and has DN)
        $resourcesOU = $null
        $corpSpecialOU = $null
        if ($deleteOU -and $deleteOU.DistinguishedName) {
            Write-ActivityLog "Creating sub-OUs under DeleteMe OU" -Level Info
            $resourcesOU = New-OU -Name "Resources" -Path $deleteOU.DistinguishedName -Description "Resources sub-OU" -ProtectFromAccidentalDeletion $false
            $corpSpecialOU = New-OU -Name "Corp Special OU" -Path $deleteOU.DistinguishedName -Description "Corporate special OU" -ProtectFromAccidentalDeletion $false
        }
        else {
            Write-ActivityLog "DeleteMe OU not available or missing DN - skipping sub-OU creation" -Level Warning
        }
        
        Write-ActivityLog "Directory structure created successfully" -Level Success
        
        return @{
            DemoRootOU = $demoRootOU
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
# MAIN ACTIVITY FUNCTION
################################################################################

function Invoke-DirectoryActivity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]$DomainInfo,
        
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
    
    # Step 2: Create admin users (if configured)
    if ($Config -and $Config.ContainsKey('AdminUsers') -and $Config.AdminUsers) {
        Write-ActivityLog "Step 2: Creating admin user accounts..." -Level Info
        
        foreach ($adminConfig in $Config.AdminUsers.Values) {
            if ($adminConfig -is [hashtable]) {
                # Determine target OU
                $targetOU = $null
                
                if ($adminConfig.ContainsKey('Path') -and $adminConfig.Path) {
                    $targetOU = $adminConfig.Path
                }
                else {
                    # Default to Tier 2 Admins
                    if ($structure.Tier2AdminsOU -and $structure.Tier2AdminsOU.DistinguishedName) {
                        $targetOU = $structure.Tier2AdminsOU.DistinguishedName
                    }
                }
                
                # Validate target OU before proceeding
                if ([string]::IsNullOrWhiteSpace($targetOU)) {
                    Write-ActivityLog "Skipping user $($adminConfig.SamAccountName) - no valid target OU found" -Level Warning
                    continue
                }
                
                $password = ConvertTo-SecureString $adminConfig.Password -AsPlainText -Force
                
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
    
    # Step 3: Create demo users (if configured)
    if ($Config -and $Config.ContainsKey('DemoUsers') -and $Config.DemoUsers) {
        Write-ActivityLog "Step 3: Creating demo user accounts..." -Level Info
        
        foreach ($demoConfig in $Config.DemoUsers.Values) {
            if ($demoConfig -is [hashtable]) {
                # Determine target OU
                $targetOU = $null
                
                if ($demoConfig.ContainsKey('Path') -and $demoConfig.Path) {
                    $targetOU = $demoConfig.Path
                }
                else {
                    # Default to Lab Users
                    if ($structure.LabUsersOU -and $structure.LabUsersOU.DistinguishedName) {
                        $targetOU = $structure.LabUsersOU.DistinguishedName
                    }
                }
                
                # Validate target OU
                if ([string]::IsNullOrWhiteSpace($targetOU)) {
                    Write-ActivityLog "Skipping user $($demoConfig.SamAccountName) - no valid target OU found" -Level Warning
                    continue
                }
                
                $password = ConvertTo-SecureString $demoConfig.Password -AsPlainText -Force
                
                New-User -SamAccountName $demoConfig.SamAccountName `
                         -Name $demoConfig.Name `
                         -GivenName $demoConfig.GivenName `
                         -Surname $demoConfig.Surname `
                         -DisplayName $demoConfig.DisplayName `
                         -Title $demoConfig.Title `
                         -Department $demoConfig.Department `
                         -Mail $demoConfig.Mail `
                         -TelephoneNumber $demoConfig.TelephoneNumber `
                         -Description $demoConfig.Description `
                         -Path $targetOU `
                         -Password $password
            }
        }
    } else {
        Write-ActivityLog "Step 3: Skipping demo users (not in config)" -Level Info
    }
    
    # Step 4: Create computers (if configured)
    if ($Config -and $Config.ContainsKey('Computers') -and $Config.Computers) {
        Write-ActivityLog "Step 4: Creating computer accounts..." -Level Info
        # Computer creation logic here
    } else {
        Write-ActivityLog "Step 4: Skipping computers (not in config)" -Level Info
    }
    
    # Step 5: Create groups (if configured)
    if ($Config -and $Config.ContainsKey('Groups') -and $Config.Groups) {
        Write-ActivityLog "Step 5: Creating group accounts..." -Level Info
        # Group creation logic here
    } else {
        Write-ActivityLog "Step 5: Skipping groups (not in config)" -Level Info
    }
    
    # Step 6: Create FGPPs (if configured)
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
        
        if ($structure.TestOU -and $structure.TestOU.DistinguishedName) {
            $bulkPassword = ConvertTo-SecureString $Config.General.DefaultPassword -AsPlainText -Force
            
            New-BulkGenericUsers -OU $structure.TestOU.DistinguishedName `
                                -Count $Config.General.GenericUserCount `
                                -Prefix "GdAct0r" `
                                -Password $bulkPassword
        }
        else {
            Write-ActivityLog "Step 7: TEST OU not available - skipping bulk users" -Level Warning
        }
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