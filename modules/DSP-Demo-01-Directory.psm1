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
        [string]$Level = 'Info',
        
        [Parameter(Mandatory=$false)]
        [string]$LogFile
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
    
    # Always log to file if provided
    if ($LogFile) {
        Add-Content -Path $LogFile -Value "[$timestamp] [$Level] $Message" -ErrorAction SilentlyContinue
    }
}

function Write-DetailToLog {
    param(
        [string]$Detail,
        [Parameter(Mandatory=$false)]
        [string]$LogFile
    )
    
    if ($LogFile) {
        Add-Content -Path $LogFile -Value $Detail -ErrorAction SilentlyContinue
    }
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
    
    .PARAMETER LogFile
        Optional log file path for detailed output
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
        [bool]$ProtectFromAccidentalDeletion = $true,
        
        [Parameter(Mandatory=$false)]
        [string]$LogFile
    )
    
    try {
        # Check if OU already exists
        $existingOU = Get-ADOrganizationalUnit -Filter "Name -eq '$Name'" -SearchBase $Path -ErrorAction SilentlyContinue
        
        if ($existingOU) {
            Write-ActivityLog "OU already exists: $Name (using existing)" -Level Info -LogFile $LogFile
            Write-DetailToLog "  Path: $($existingOU.DistinguishedName)" -LogFile $LogFile
            return $existingOU
        }
        
        Write-ActivityLog "Creating OU: $Name" -Level Info -LogFile $LogFile
        
        $newOU = New-ADOrganizationalUnit -Name $Name `
                                         -Path $Path `
                                         -Description $Description `
                                         -ProtectedFromAccidentalDeletion $ProtectFromAccidentalDeletion `
                                         -ErrorAction Stop
        
        Write-ActivityLog "OU created: $Name" -Level Success -LogFile $LogFile
        Write-DetailToLog "  Path: $($newOU.DistinguishedName)" -LogFile $LogFile
        Write-DetailToLog "  Description: $Description" -LogFile $LogFile
        Write-DetailToLog "  Protected: $ProtectFromAccidentalDeletion" -LogFile $LogFile
        
        return $newOU
    }
    catch {
        Write-ActivityLog "Failed to create OU $Name : $_" -Level Error -LogFile $LogFile
        Write-DetailToLog "  Error Details: $($_.Exception.Message)" -LogFile $LogFile
        return $null
    }
}

function New-DirectoryStructure {
    <#
    .SYNOPSIS
        Create the standard directory structure for DSP demo
    
    .PARAMETER DomainDN
        Domain Distinguished Name
    
    .PARAMETER LogFile
        Optional log file path
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$DomainDN,
        
        [Parameter(Mandatory=$false)]
        [string]$LogFile
    )
    
    Write-ActivityLog "Creating directory structure in $DomainDN" -Level Info -LogFile $LogFile
    
    # Define OU hierarchy
    $ouStructure = @(
        @{ Name = 'Lab Admins'; Parent = $DomainDN; Description = 'Lab administrative accounts' }
        @{ Name = 'Tier 0'; Parent = "OU=Lab Admins,$DomainDN"; Description = 'Tier 0 administrative users' }
        @{ Name = 'Tier 1'; Parent = "OU=Lab Admins,$DomainDN"; Description = 'Tier 1 administrative users' }
        @{ Name = 'Tier 2'; Parent = "OU=Lab Admins,$DomainDN"; Description = 'Tier 2 administrative users' }
        @{ Name = 'Lab Users'; Parent = $DomainDN; Description = 'Lab user accounts' }
        @{ Name = 'Lab Users 01'; Parent = "OU=Lab Users,$DomainDN"; Description = 'Lab users group 1' }
        @{ Name = 'Lab Users 02'; Parent = "OU=Lab Users,$DomainDN"; Description = 'Lab users group 2' }
        @{ Name = 'Bad OU'; Parent = $DomainDN; Description = 'OU for testing recovery' }
        @{ Name = 'DeleteMe OU'; Parent = $DomainDN; Description = 'OU for deletion testing' }
        @{ Name = 'Servers'; Parent = $DomainDN; Description = 'Server objects' }
        @{ Name = 'Tier-0-Special-Assets'; Parent = $DomainDN; Description = 'Tier 0 special assets' }
        @{ Name = 'TEST'; Parent = $DomainDN; Description = 'Test user container' }
    )
    
    $structure = @{}
    
    foreach ($ou in $ouStructure) {
        $newOU = New-OU -Name $ou.Name -Path $ou.Parent -Description $ou.Description -LogFile $LogFile
        
        if ($newOU) {
            $structure[$ou.Name] = $newOU
        }
    }
    
    Write-ActivityLog "Directory structure created successfully" -Level Success -LogFile $LogFile
    return $structure
}

################################################################################
# USER FUNCTIONS
################################################################################

function New-User {
    <#
    .SYNOPSIS
        Create a new user account
    
    .PARAMETER SamAccountName
        User login name
    
    .PARAMETER Name
        User display name
    
    .PARAMETER GivenName
        User first name
    
    .PARAMETER Surname
        User last name
    
    .PARAMETER DisplayName
        User display name
    
    .PARAMETER Title
        User title/job title
    
    .PARAMETER Department
        User department
    
    .PARAMETER Mail
        User email
    
    .PARAMETER TelephoneNumber
        User phone number
    
    .PARAMETER Description
        User description
    
    .PARAMETER Path
        Target OU distinguished name
    
    .PARAMETER Password
        User password (SecureString)
    
    .PARAMETER PasswordNeverExpires
        Password expiration setting
    
    .PARAMETER Manager
        User's manager SamAccountName
    
    .PARAMETER LogFile
        Optional log file path
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SamAccountName,
        
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$false)]
        [string]$GivenName,
        
        [Parameter(Mandatory=$false)]
        [string]$Surname,
        
        [Parameter(Mandatory=$false)]
        [string]$DisplayName,
        
        [Parameter(Mandatory=$false)]
        [string]$Title,
        
        [Parameter(Mandatory=$false)]
        [string]$Department,
        
        [Parameter(Mandatory=$false)]
        [string]$Mail,
        
        [Parameter(Mandatory=$false)]
        [string]$TelephoneNumber,
        
        [Parameter(Mandatory=$false)]
        [string]$Description,
        
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$true)]
        [securestring]$Password,
        
        [Parameter(Mandatory=$false)]
        [bool]$PasswordNeverExpires = $false,
        
        [Parameter(Mandatory=$false)]
        [string]$Manager,
        
        [Parameter(Mandatory=$false)]
        [string]$LogFile
    )
    
    try {
        # Check if user already exists
        $existingUser = Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -ErrorAction SilentlyContinue
        
        if ($existingUser) {
            Write-ActivityLog "User already exists: $SamAccountName" -Level Info -LogFile $LogFile
            Write-DetailToLog "  Display Name: $($existingUser.DisplayName)" -LogFile $LogFile
            Write-DetailToLog "  Path: $($existingUser.DistinguishedName)" -LogFile $LogFile
            return $existingUser
        }
        
        Write-ActivityLog "Creating user: $SamAccountName" -Level Info -LogFile $LogFile
        
        $userParams = @{
            SamAccountName = $SamAccountName
            Name = $Name
            Path = $Path
            AccountPassword = $Password
            Enabled = $true
            CannotChangePassword = $true
            PasswordNeverExpires = $PasswordNeverExpires
            ChangePasswordAtLogon = $false
            ErrorAction = 'Stop'
        }
        
        if ($GivenName) { $userParams['GivenName'] = $GivenName }
        if ($Surname) { $userParams['Surname'] = $Surname }
        if ($DisplayName) { $userParams['DisplayName'] = $DisplayName }
        if ($Description) { $userParams['Description'] = $Description }
        
        $otherAttrs = @{}
        if ($Title) { $otherAttrs['title'] = $Title }
        if ($Department) { $otherAttrs['department'] = $Department }
        if ($Mail) { $otherAttrs['mail'] = $Mail }
        if ($TelephoneNumber) { $otherAttrs['telephoneNumber'] = $TelephoneNumber }
        
        if ($otherAttrs.Count -gt 0) {
            $userParams['OtherAttributes'] = $otherAttrs
        }
        
        $user = New-ADUser @userParams
        
        # Set manager if provided
        if ($Manager) {
            try {
                Set-ADUser -Identity $user.SamAccountName -Manager $Manager -ErrorAction Stop
                Write-ActivityLog "User created: $SamAccountName" -Level Success -LogFile $LogFile
                Write-DetailToLog "  Display Name: $DisplayName" -LogFile $LogFile
                Write-DetailToLog "  Path: $Path" -LogFile $LogFile
                Write-DetailToLog "  Title: $Title" -LogFile $LogFile
                Write-DetailToLog "  Department: $Department" -LogFile $LogFile
                Write-DetailToLog "  Email: $Mail" -LogFile $LogFile
                Write-DetailToLog "  Phone: $TelephoneNumber" -LogFile $LogFile
                Write-DetailToLog "  Manager: $Manager" -LogFile $LogFile
            }
            catch {
                Write-ActivityLog "User created (but manager assignment failed): $SamAccountName" -Level Warning -LogFile $LogFile
                Write-DetailToLog "  Error setting manager: $_" -LogFile $LogFile
            }
        }
        else {
            Write-ActivityLog "User created: $SamAccountName" -Level Success -LogFile $LogFile
            Write-DetailToLog "  Display Name: $DisplayName" -LogFile $LogFile
            Write-DetailToLog "  Path: $Path" -LogFile $LogFile
            Write-DetailToLog "  Title: $Title" -LogFile $LogFile
            Write-DetailToLog "  Department: $Department" -LogFile $LogFile
            Write-DetailToLog "  Email: $Mail" -LogFile $LogFile
            Write-DetailToLog "  Phone: $TelephoneNumber" -LogFile $LogFile
        }
        
        return $user
    }
    catch {
        Write-ActivityLog "Failed to create user $SamAccountName : $_" -Level Error -LogFile $LogFile
        Write-DetailToLog "  Error Details: $($_.Exception.Message)" -LogFile $LogFile
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
    
    .PARAMETER LogFile
        Optional log file path
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
        [string[]]$Members = @(),
        
        [Parameter(Mandatory=$false)]
        [string]$LogFile
    )
    
    try {
        # Check if group already exists
        $existingGroup = Get-ADGroup -Filter "Name -eq '$Name'" -ErrorAction SilentlyContinue
        
        if ($existingGroup) {
            Write-ActivityLog "Group already exists: $Name" -Level Info -LogFile $LogFile
            Write-DetailToLog "  Scope: $($existingGroup.GroupScope)" -LogFile $LogFile
            Write-DetailToLog "  Path: $($existingGroup.DistinguishedName)" -LogFile $LogFile
            return $existingGroup
        }
        
        Write-ActivityLog "Creating group: $Name" -Level Info -LogFile $LogFile
        
        $group = New-ADGroup -Name $Name `
                            -Path $Path `
                            -GroupScope $GroupScope `
                            -GroupCategory $GroupCategory `
                            -Description $Description `
                            -ErrorAction Stop
        
        Write-DetailToLog "  Scope: $GroupScope" -LogFile $LogFile
        Write-DetailToLog "  Category: $GroupCategory" -LogFile $LogFile
        
        # Add members if provided
        if ($Members.Count -gt 0) {
            $addedCount = 0
            $failedMembers = @()
            
            foreach ($member in $Members) {
                try {
                    $user = Get-ADUser -Filter "SamAccountName -eq '$member'" -ErrorAction SilentlyContinue
                    if ($user) {
                        Add-ADGroupMember -Identity $group.SamAccountName -Members $user -ErrorAction Stop
                        $addedCount++
                        Write-DetailToLog "    Added member: $member" -LogFile $LogFile
                    }
                    else {
                        $failedMembers += $member
                    }
                }
                catch {
                    $failedMembers += $member
                    Write-DetailToLog "    Failed to add: $member - $_" -LogFile $LogFile
                }
            }
            
            if ($addedCount -gt 0) {
                Write-ActivityLog "Group created with $addedCount members: $Name" -Level Success -LogFile $LogFile
            }
            if ($failedMembers.Count -gt 0) {
                Write-ActivityLog "Group created with $($failedMembers.Count) member failures: $Name" -Level Warning -LogFile $LogFile
            }
        }
        else {
            Write-ActivityLog "Group created: $Name" -Level Success -LogFile $LogFile
        }
        
        return $group
    }
    catch {
        Write-ActivityLog "Failed to create group $Name : $_" -Level Error -LogFile $LogFile
        Write-DetailToLog "  Error Details: $($_.Exception.Message)" -LogFile $LogFile
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
    
    .PARAMETER LogFile
        Optional log file path
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
        [string]$LogFile
    )
    
    try {
        # Check if computer already exists
        $existingComputer = Get-ADComputer -Filter "Name -eq '$Name'" -ErrorAction SilentlyContinue
        
        if ($existingComputer) {
            Write-ActivityLog "Computer already exists: $Name" -Level Info -LogFile $LogFile
            Write-DetailToLog "  Path: $($existingComputer.DistinguishedName)" -LogFile $LogFile
            return $existingComputer
        }
        
        Write-ActivityLog "Creating computer: $Name" -Level Info -LogFile $LogFile
        
        $computer = New-ADComputer -Name $Name `
                                  -Path $Path `
                                  -Description $Description `
                                  -ErrorAction Stop
        
        Write-ActivityLog "Computer created: $Name" -Level Success -LogFile $LogFile
        Write-DetailToLog "  Path: $Path" -LogFile $LogFile
        Write-DetailToLog "  Description: $Description" -LogFile $LogFile
        
        return $computer
    }
    catch {
        Write-ActivityLog "Failed to create computer $Name : $_" -Level Error -LogFile $LogFile
        Write-DetailToLog "  Error Details: $($_.Exception.Message)" -LogFile $LogFile
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
        FGPP precedence
    
    .PARAMETER MinPasswordLength
        Minimum password length
    
    .PARAMETER LockoutThreshold
        Lockout threshold (failed attempts)
    
    .PARAMETER PasswordHistoryCount
        Password history count
    
    .PARAMETER LogFile
        Optional log file path
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
        [int]$LockoutThreshold = 10,
        
        [Parameter(Mandatory=$false)]
        [int]$PasswordHistoryCount = 3,
        
        [Parameter(Mandatory=$false)]
        [int]$MaxPasswordAge = 0,
        
        [Parameter(Mandatory=$false)]
        [string]$LogFile
    )
    
    try {
        # Check if FGPP already exists
        $existingFGPP = Get-ADFineGrainedPasswordPolicy -Filter "Name -eq '$Name'" -ErrorAction SilentlyContinue
        
        if ($existingFGPP) {
            Write-ActivityLog "FGPP already exists: $Name" -Level Info -LogFile $LogFile
            Write-DetailToLog "  Precedence: $($existingFGPP.Precedence)" -LogFile $LogFile
            return $existingFGPP
        }
        
        Write-ActivityLog "Creating FGPP: $Name (Precedence: $Precedence)" -Level Info -LogFile $LogFile
        
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
        
        Write-ActivityLog "FGPP created: $Name" -Level Success -LogFile $LogFile
        Write-DetailToLog "  Precedence: $Precedence" -LogFile $LogFile
        Write-DetailToLog "  Min Length: $MinPasswordLength" -LogFile $LogFile
        Write-DetailToLog "  Lockout Threshold: $LockoutThreshold" -LogFile $LogFile
        Write-DetailToLog "  History Count: $PasswordHistoryCount" -LogFile $LogFile
        
        return $fgpp
    }
    catch {
        Write-ActivityLog "Failed to create FGPP $Name : $_" -Level Error -LogFile $LogFile
        Write-DetailToLog "  Error Details: $($_.Exception.Message)" -LogFile $LogFile
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
    
    .PARAMETER LogFile
        Optional log file path
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$OU,
        
        [Parameter(Mandatory=$false)]
        [int]$Count = 250,
        
        [Parameter(Mandatory=$false)]
        [string]$Prefix = "GdAct0r",
        
        [Parameter(Mandatory=$false)]
        [string]$LogFile
    )
    
    Write-ActivityLog "Creating $Count bulk generic users in TEST OU" -Level Info -LogFile $LogFile
    
    $password = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force
    $createdCount = 0
    $skippedCount = 0
    
    for ($i = 1; $i -le $Count; $i++) {
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
                
                # Show progress every 50 users
                if ($createdCount % 50 -eq 0) {
                    Write-ActivityLog "Created $createdCount of $Count users..." -Level Info -LogFile $LogFile
                }
            }
            catch {
                Write-DetailToLog "  Failed to create user $samAccountName : $_" -LogFile $LogFile
            }
        }
        else {
            $skippedCount++
        }
    }
    
    Write-ActivityLog "Bulk user creation completed: $createdCount created, $skippedCount skipped" -Level Success -LogFile $LogFile
    Write-DetailToLog "  Total processed: $Count" -LogFile $LogFile
    Write-DetailToLog "  Created: $createdCount" -LogFile $LogFile
    Write-DetailToLog "  Skipped (existing): $skippedCount" -LogFile $LogFile
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
    
    .PARAMETER LogFile
        Path to log file
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$DomainInfo,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$false)]
        [string]$LogFile
    )
    
    Write-ActivityLog "=== Starting Directory Activity Module ===" -Level Info -LogFile $LogFile
    
    $domainDN = $DomainInfo.DistinguishedName
    
    # Step 1: Create directory structure
    Write-ActivityLog "Step 1: Creating OU hierarchy..." -Level Info -LogFile $LogFile
    $structure = New-DirectoryStructure -DomainDN $domainDN -LogFile $LogFile
    
    if (-not $structure) {
        Write-ActivityLog "Failed to create directory structure - aborting" -Level Error -LogFile $LogFile
        return $false
    }
    
    # Step 2: Create admin users (Tier 0, 1, 2)
    if ($Config -and $Config.ContainsKey('AdminUsers') -and $Config.AdminUsers) {
        Write-ActivityLog "Step 2: Creating admin user accounts..." -Level Info -LogFile $LogFile
        
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
                         -PasswordNeverExpires $true `
                         -LogFile $LogFile
            }
        }
    } else {
        Write-ActivityLog "Step 2: Skipping admin users (not in config)" -Level Info -LogFile $LogFile
    }
    
    # Step 3: Create demo users
    if ($Config -and $Config.ContainsKey('DemoUsers') -and $Config.DemoUsers) {
        Write-ActivityLog "Step 3: Creating demo user accounts..." -Level Info -LogFile $LogFile
        
        foreach ($demoConfig in $Config.DemoUsers.Values) {
            if ($demoConfig -is [hashtable]) {
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
                         -Path $demoConfig.Path `
                         -Password $password `
                         -PasswordNeverExpires $false `
                         -LogFile $LogFile
            }
        }
    } else {
        Write-ActivityLog "Step 3: Skipping demo users (not in config)" -Level Info -LogFile $LogFile
    }
    
    # Step 4: Create computers
    if ($Config -and $Config.ContainsKey('Computers') -and $Config.Computers) {
        Write-ActivityLog "Step 4: Creating computer objects..." -Level Info -LogFile $LogFile
        
        foreach ($computerConfig in $Config.Computers.Values) {
            if ($computerConfig -is [hashtable]) {
                New-Computer -Name $computerConfig.Name `
                            -Path $computerConfig.Path `
                            -Description $computerConfig.Description `
                            -LogFile $LogFile
            }
        }
    } else {
        Write-ActivityLog "Step 4: Skipping computers (not in config)" -Level Info -LogFile $LogFile
    }
    
    # Step 5: Create groups
    if ($Config -and $Config.SecurityGroups) {
        Write-ActivityLog "Step 5: Creating security groups..." -Level Info
        
        foreach ($groupConfig in $Config.SecurityGroups.Values) {
            if ($groupConfig -is [hashtable]) {
                New-Group -Name $groupConfig.Name `
                        -Path $groupConfig.Path `
                        -GroupScope $groupConfig.GroupScope `
                        -GroupCategory $groupConfig.GroupCategory `
                        -Description $groupConfig.Description `
                        -Members $groupConfig.Members
            }
        }
    } else {
        Write-ActivityLog "Step 5: Skipping groups (not in config)" -Level Info
    }
    
    # Step 6: Create FGPPs
    if ($Config -and $Config.ContainsKey('FGPPs') -and $Config.FGPPs) {
        Write-ActivityLog "Step 6: Creating Fine-Grained Password Policies..." -Level Info -LogFile $LogFile
        
        foreach ($fgppConfig in $Config.FGPPs.Values) {
            if ($fgppConfig -is [hashtable]) {
                New-FGPP -Name $fgppConfig.Name `
                        -Precedence $fgppConfig.Precedence `
                        -MinPasswordLength $fgppConfig.MinPasswordLength `
                        -LockoutThreshold $fgppConfig.LockoutThreshold `
                        -PasswordHistoryCount $fgppConfig.PasswordHistoryCount `
                        -LogFile $LogFile
            }
        }
    } else {
        Write-ActivityLog "Step 6: Skipping FGPPs (not in config)" -Level Info -LogFile $LogFile
    }
    
    # Step 7: Create bulk generic users in TEST OU
    Write-ActivityLog "Step 7: Creating bulk generic test users..." -Level Info -LogFile $LogFile
    if ($Config -and $Config.General -and $Config.General.GenericUserCount) {
        $testOU = "OU=TEST,$domainDN"
        New-BulkGenericUsers -OU $testOU -Count $Config.General.GenericUserCount -LogFile $LogFile
    }
    
    Write-ActivityLog "=== Directory Activity Module completed successfully ===" -Level Success -LogFile $LogFile
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
    'Invoke-DirectoryActivity',
    'Write-ActivityLog'
)

################################################################################
# END OF MODULE
################################################################################