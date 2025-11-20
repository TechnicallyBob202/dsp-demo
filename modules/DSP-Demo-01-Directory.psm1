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
    <#
    .SYNOPSIS
        Create a new organizational unit with optional protection
    
    .PARAMETER Name
        Name of the OU
    
    .PARAMETER Path
        Distinguished name of parent container
    
    .PARAMETER Description
        OU description
    
    .PARAMETER ProtectFromAccidentalDeletion
        Enable accidental deletion protection (default: $true)
    #>
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
        # Check if OU already exists
        $existingOU = Get-ADOrganizationalUnit -Filter "Name -eq '$Name' -and DistinguishedName -like '*$Path'" -ErrorAction SilentlyContinue
        
        if ($existingOU) {
            Write-ActivityLog "OU already exists: $Name" -Level Warning
            return $existingOU
        }
        
        Write-ActivityLog "Creating OU: $Name in $Path" -Level Info
        
        $ou = New-ADOrganizationalUnit -Name $Name `
                                       -Path $Path `
                                       -Description $Description `
                                       -ProtectedFromAccidentalDeletion $ProtectFromAccidentalDeletion `
                                       -ErrorAction Stop
        
        Write-ActivityLog "OU created successfully: $Name" -Level Success
        return $ou
    }
    catch {
        Write-ActivityLog "Failed to create OU $Name : $_" -Level Error
        return $null
    }
}

function New-DirectoryStructure {
    <#
    .SYNOPSIS
        Create the complete OU hierarchy matching original script structure
    
    .PARAMETER DomainDN
        Domain distinguished name (e.g., DC=contoso,DC=com)
    
    .DESCRIPTION
        Creates the entire OU structure including:
        - Lab Admins (parent)
          - Tier 0
          - Tier 1
          - Tier 2
        - Lab Users (parent)
          - Lab Users 01
          - Lab Users 02
        - Bad OU (for modification demos)
        - DeleteMe OU (for recovery demos)
        - Tier 0 Special Assets OU (restricted)
        - TEST OU (for generic bulk users)
    
    .EXAMPLE
        $structure = New-DirectoryStructure -DomainDN "DC=contoso,DC=com"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$DomainDN
    )
    
    try {
        Write-ActivityLog "Creating directory structure in $DomainDN" -Level Info
        
        # Create Lab Admins structure (parent OU)
        $labAdminsOU = New-OU -Name "Lab Admins" `
                              -Path $DomainDN `
                              -Description "OU for all lab admins" `
                              -ProtectFromAccidentalDeletion $true
        
        if ($labAdminsOU) {
            # Create Tier OUs under Lab Admins
            $tier0OU = New-OU -Name "Tier 0" `
                              -Path $labAdminsOU.DistinguishedName `
                              -Description "OU for Tier 0 (highest privilege) lab admins" `
                              -ProtectFromAccidentalDeletion $true
            
            $tier1OU = New-OU -Name "Tier 1" `
                              -Path $labAdminsOU.DistinguishedName `
                              -Description "OU for Tier 1 lab admins" `
                              -ProtectFromAccidentalDeletion $true
            
            $tier2OU = New-OU -Name "Tier 2" `
                              -Path $labAdminsOU.DistinguishedName `
                              -Description "OU for Tier 2 lab admins" `
                              -ProtectFromAccidentalDeletion $true
        }
        
        # Create Lab Users structure (parent OU)
        $labUsersOU = New-OU -Name "Lab Users" `
                             -Path $DomainDN `
                             -Description "OU for all lab users" `
                             -ProtectFromAccidentalDeletion $true
        
        if ($labUsersOU) {
            # Create Lab Users sub-OUs for movement demos
            $labUsers01OU = New-OU -Name "Lab Users 01" `
                                   -Path $labUsersOU.DistinguishedName `
                                   -Description "OU for users in Lab Users 01 (user movement demos)" `
                                   -ProtectFromAccidentalDeletion $true
            
            $labUsers02OU = New-OU -Name "Lab Users 02" `
                                   -Path $labUsersOU.DistinguishedName `
                                   -Description "OU for users in Lab Users 02 (user movement demos)" `
                                   -ProtectFromAccidentalDeletion $true
        }
        
        # Create Bad OU (for ACL modification demos)
        $badOU = New-OU -Name "Bad OU" `
                        -Path $DomainDN `
                        -Description "OU that gets modified (ACL demos)" `
                        -ProtectFromAccidentalDeletion $true
        
        # Create DeleteMe OU (for recovery demos) - no protection for deletion demo
        $deleteOU = New-OU -Name "DeleteMe OU" `
                           -Path $DomainDN `
                           -Description "OU for deletion and recovery demonstrations" `
                           -ProtectFromAccidentalDeletion $false
        
        # Create nested structure in DeleteMe OU
        if ($deleteOU) {
            $deleteSubOU = New-OU -Name "Servers" `
                                  -Path $deleteOU.DistinguishedName `
                                  -Description "Sub-OU in DeleteMe OU (for recovery demo)" `
                                  -ProtectFromAccidentalDeletion $false
        }
        
        # Create Tier 0 Special Assets OU (highly restricted)
        $tier0AssetsOU = New-OU -Name "Tier-0-Special-Assets" `
                                -Path $DomainDN `
                                -Description "Tier 0 special assets - Highly restricted access" `
                                -ProtectFromAccidentalDeletion $true
        
        # Create TEST OU (for bulk generic users)
        $testOU = New-OU -Name "TEST" `
                         -Path $DomainDN `
                         -Description "Generic test user accounts (bulk created)" `
                         -ProtectFromAccidentalDeletion $false
        
        Write-ActivityLog "Directory structure created successfully" -Level Success
        
        # Return structure info
        return [PSCustomObject]@{
            LabAdminsOU = $labAdminsOU
            Tier0OU = $tier0OU
            Tier1OU = $tier1OU
            Tier2OU = $tier2OU
            LabUsersOU = $labUsersOU
            LabUsers01OU = $labUsers01OU
            LabUsers02OU = $labUsers02OU
            BadOU = $badOU
            DeleteOU = $deleteOU
            Tier0AssetsOU = $tier0AssetsOU
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
    <#
    .SYNOPSIS
        Create a new user account with rich attributes
    
    .PARAMETER SamAccountName
        User login name
    
    .PARAMETER Name
        User display name
    
    .PARAMETER Path
        Distinguished name of target OU
    
    .PARAMETER GivenName
        User first name
    
    .PARAMETER Surname
        User last name
    
    .PARAMETER Description
        User description
    
    .PARAMETER Title
        User job title
    
    .PARAMETER Department
        User department
    
    .PARAMETER Mail
        User email address
    
    .PARAMETER TelephoneNumber
        User phone number
    
    .PARAMETER Manager
        Manager's DN
    
    .PARAMETER Password
        User password (uses secure string)
    
    .PARAMETER PasswordNeverExpires
        Set password to never expire (default: $true)
    #>
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
        [string]$Manager = "",
        
        [Parameter(Mandatory=$false)]
        [securestring]$Password,
        
        [Parameter(Mandatory=$false)]
        [bool]$PasswordNeverExpires = $true
    )
    
    try {
        # Check if user already exists
        $existingUser = Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -ErrorAction SilentlyContinue
        
        if ($existingUser) {
            Write-ActivityLog "User already exists: $SamAccountName" -Level Warning
            return $existingUser
        }
        
        Write-ActivityLog "Creating user: $SamAccountName ($Name)" -Level Info
        
        $userParams = @{
            SamAccountName = $SamAccountName
            Name = $Name
            Path = $Path
            GivenName = $GivenName
            Surname = $Surname
            DisplayName = $Name
            Description = $Description
            Enabled = $true
            ChangePasswordAtLogon = $false
            CannotChangePassword = $true
            PasswordNeverExpires = $PasswordNeverExpires
            ErrorAction = 'Stop'
        }
        
        # Add optional attributes if provided
        $otherAttrs = @{}
        if ($Title) { $otherAttrs['title'] = $Title }
        if ($Department) { $otherAttrs['department'] = $Department }
        if ($Mail) { $otherAttrs['mail'] = $Mail }
        if ($TelephoneNumber) { $otherAttrs['telephoneNumber'] = $TelephoneNumber }
        
        if ($otherAttrs.Count -gt 0) {
            $userParams['OtherAttributes'] = $otherAttrs
        }
        
        if ($Password) {
            $userParams['AccountPassword'] = $Password
        } else {
            # Use default password if none provided
            $userParams['AccountPassword'] = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force
        }
        
        $user = New-ADUser @userParams
        
        # Set manager if provided
        if ($Manager) {
            try {
                Set-ADUser -Identity $user.SamAccountName -Manager $Manager -ErrorAction Stop
                Write-ActivityLog "Set manager for user: $SamAccountName" -Level Info
            }
            catch {
                Write-ActivityLog "Failed to set manager for $SamAccountName : $_" -Level Warning
            }
        }
        
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
    <#
    .SYNOPSIS
        Create a new group
    
    .PARAMETER Name
        Group name
    
    .PARAMETER Path
        Distinguished name of target OU
    
    .PARAMETER GroupScope
        Group scope (DomainLocal, Global, Universal)
    
    .PARAMETER GroupCategory
        Group category (Distribution, Security)
    
    .PARAMETER Description
        Group description
    
    .PARAMETER Members
        Array of user SamAccountNames to add to group
    #>
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
            Write-ActivityLog "Group already exists: $Name" -Level Warning
            return $existingGroup
        }
        
        Write-ActivityLog "Creating group: $Name" -Level Info
        
        $group = New-ADGroup -Name $Name `
                            -Path $Path `
                            -GroupScope $GroupScope `
                            -GroupCategory $GroupCategory `
                            -Description $Description `
                            -ErrorAction Stop
        
        # Add members if provided
        if ($Members.Count -gt 0) {
            foreach ($member in $Members) {
                try {
                    $user = Get-ADUser -Filter "SamAccountName -eq '$member'" -ErrorAction SilentlyContinue
                    if ($user) {
                        Add-ADGroupMember -Identity $group.SamAccountName -Members $user -ErrorAction Stop
                        Write-ActivityLog "Added $member to group $Name" -Level Info
                    }
                }
                catch {
                    Write-ActivityLog "Failed to add $member to group $Name : $_" -Level Warning
                }
            }
        }
        
        Write-ActivityLog "Group created successfully: $Name" -Level Success
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
    <#
    .SYNOPSIS
        Create a new computer object
    
    .PARAMETER Name
        Computer name
    
    .PARAMETER Path
        Distinguished name of target OU
    
    .PARAMETER Description
        Computer description
    #>
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
        # Check if computer already exists
        $existingComputer = Get-ADComputer -Filter "Name -eq '$Name'" -ErrorAction SilentlyContinue
        
        if ($existingComputer) {
            Write-ActivityLog "Computer already exists: $Name" -Level Warning
            return $existingComputer
        }
        
        Write-ActivityLog "Creating computer: $Name" -Level Info
        
        $computer = New-ADComputer -Name $Name `
                                  -Path $Path `
                                  -Description $Description `
                                  -ErrorAction Stop
        
        Write-ActivityLog "Computer created successfully: $Name" -Level Success
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
    <#
    .SYNOPSIS
        Create a Fine-Grained Password Policy
    
    .PARAMETER Name
        FGPP name
    
    .PARAMETER Precedence
        Policy precedence (lower = higher priority)
    
    .PARAMETER MinPasswordLength
        Minimum password length
    
    .PARAMETER LockoutThreshold
        Account lockout threshold
    
    .PARAMETER PasswordHistoryCount
        Password history count
    
    .PARAMETER MaxPasswordAge
        Maximum password age (in days, 0 = never)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [int]$Precedence,
        
        [Parameter(Mandatory=$false)]
        [int]$MinPasswordLength = 8,
        
        [Parameter(Mandatory=$false)]
        [int]$LockoutThreshold = 0,
        
        [Parameter(Mandatory=$false)]
        [int]$PasswordHistoryCount = 24,
        
        [Parameter(Mandatory=$false)]
        [int]$MaxPasswordAge = 0
    )
    
    try {
        # Check if FGPP already exists
        $existingFGPP = Get-ADFineGrainedPasswordPolicy -Filter "Name -eq '$Name'" -ErrorAction SilentlyContinue
        
        if ($existingFGPP) {
            Write-ActivityLog "FGPP already exists: $Name" -Level Warning
            return $existingFGPP
        }
        
        Write-ActivityLog "Creating FGPP: $Name (Precedence: $Precedence)" -Level Info
        
        $fgppParams = @{
            Name = $Name
            Precedence = $Precedence
            MinPasswordLength = $MinPasswordLength
            LockoutThreshold = $LockoutThreshold
            PasswordHistoryCount = $PasswordHistoryCount
            ComplexityEnabled = $true
            ErrorAction = 'Stop'
        }
        
        if ($MaxPasswordAge -gt 0) {
            $fgppParams['MaxPasswordAge'] = (New-TimeSpan -Days $MaxPasswordAge)
        }
        
        $fgpp = New-ADFineGrainedPasswordPolicy @fgppParams
        
        Write-ActivityLog "FGPP created successfully: $Name" -Level Success
        return $fgpp
    }
    catch {
        Write-ActivityLog "Failed to create FGPP $Name : $_" -Level Error
        return $null
    }
}

################################################################################
# BULK USER CREATION
################################################################################

function New-BulkGenericUsers {
    <#
    .SYNOPSIS
        Create bulk generic test users
    
    .PARAMETER OU
        Target OU DN
    
    .PARAMETER Count
        Number of users to create
    
    .PARAMETER Prefix
        User name prefix (default: "GdAct0r")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$OU,
        
        [Parameter(Mandatory=$false)]
        [int]$Count = 250,
        
        [Parameter(Mandatory=$false)]
        [string]$Prefix = "GdAct0r"
    )
    
    Write-ActivityLog "Creating $Count bulk generic users in $OU" -Level Info
    
    $password = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force
    $createdCount = 0
    
    for ($i = 0; $i -lt $Count; $i++) {
        # Pad the number with leading zeros
        $index = $i.ToString().PadLeft(6, '0')
        $samAccountName = "$Prefix-$index"
        $displayName = "Generic Actor $index"
        
        # Check if user exists first
        $existingUser = Get-ADUser -Filter "SamAccountName -eq '$samAccountName'" -ErrorAction SilentlyContinue
        
        if (-not $existingUser) {
            try {
                New-ADUser -SamAccountName $samAccountName `
                          -Name $displayName `
                          -DisplayName $displayName `
                          -GivenName "Generic" `
                          -Surname "Actor $index" `
                          -Path $OU `
                          -AccountPassword $password `
                          -Enabled $true `
                          -ChangePasswordAtLogon $false `
                          -CannotChangePassword $true `
                          -PasswordNeverExpires $true `
                          -ErrorAction Stop | Out-Null
                
                $createdCount++
                
                # Show progress every 25 users
                if (($i + 1) % 25 -eq 0) {
                    Write-ActivityLog "Created $($i + 1) of $Count users..." -Level Info
                }
            }
            catch {
                Write-ActivityLog "Failed to create user $samAccountName : $_" -Level Warning
            }
        }
    }
    
    Write-ActivityLog "Bulk user creation completed: $createdCount users created" -Level Success
}

################################################################################
# MAIN MODULE EXECUTION
################################################################################

function Invoke-DirectoryActivity {
    <#
    .SYNOPSIS
        Execute all directory activities from config
    
    .PARAMETER DomainInfo
        Domain information from preflight
    
    .PARAMETER Config
        Configuration hashtable
    #>
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
    if ($Config.AdminUsers) {
        Write-ActivityLog "Step 2: Creating admin user accounts..." -Level Info
        
        foreach ($adminConfig in $Config.AdminUsers.Values) {
            if ($adminConfig -is [hashtable]) {
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
                         -Path $adminConfig.Path `
                         -Password $password `
                         -PasswordNeverExpires $true
            }
        }
    }
    
    # Step 3: Create demo users
    if ($Config.DemoUsers) {
        Write-ActivityLog "Step 3: Creating demo user accounts..." -Level Info
        
        foreach ($userConfig in $Config.DemoUsers.Values) {
            if ($userConfig -is [hashtable]) {
                $password = ConvertTo-SecureString $userConfig.Password -AsPlainText -Force
                
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
                         -Path $userConfig.Path `
                         -Password $password `
                         -PasswordNeverExpires $true
            }
        }
    }
    
    # Step 4: Create bulk generic users
    if ($Config.General.GenericUserCount -gt 0) {
        Write-ActivityLog "Step 4: Creating bulk generic users..." -Level Info
        New-BulkGenericUsers -OU $structure.TestOU.DistinguishedName `
                            -Count $Config.General.GenericUserCount
    }
    
    # Step 5: Create groups
    if ($Config.Groups) {
        Write-ActivityLog "Step 5: Creating groups..." -Level Info
        
        foreach ($groupConfig in $Config.Groups.Values) {
            if ($groupConfig -is [hashtable]) {
                New-Group -Name $groupConfig.Name `
                         -Path $structure.LabAdminsOU.DistinguishedName `
                         -GroupScope $groupConfig.GroupScope `
                         -GroupCategory $groupConfig.GroupCategory `
                         -Description $groupConfig.Description `
                         -Members $groupConfig.Members
            }
        }
    }
    
    # Step 6: Create FGPPs
    if ($Config.FGPPs) {
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
    }
    
    # Step 7: Create computers in DeleteMe OU
    Write-ActivityLog "Step 7: Creating sample computers in DeleteMe OU..." -Level Info
    New-Computer -Name "srv-demo-01" `
                -Path "$($structure.DeleteOU.DistinguishedName)" `
                -Description "Demo server for deletion recovery"
    
    New-Computer -Name "srv-demo-02" `
                -Path "$($structure.DeleteOU.DistinguishedName)" `
                -Description "Demo server for deletion recovery"
    
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