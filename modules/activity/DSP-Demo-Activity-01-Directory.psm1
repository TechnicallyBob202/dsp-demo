################################################################################
##
## DSP-Demo-Activity-01-DirectoryActivity.psm1
##
## Directory activity generation module for DSP demo
## Generates realistic directory changes: user moves between OUs, attribute
## modifications, and group membership changes
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

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host ":: $Title" -ForegroundColor DarkRed -BackgroundColor Yellow
    Write-Host ""
}

################################################################################
# PRIVATE HELPERS
################################################################################

function Invoke-Replication {
    <#
    .SYNOPSIS
    Forces AD replication on the current domain
    #>
    param(
        [Parameter(Mandatory=$false)]
        [int]$WaitSeconds = 1
    )
    
    try {
        Write-Status "Forcing AD replication (waiting $WaitSeconds seconds first)..." -Level Info
        Start-Sleep $WaitSeconds
        
        $result = & C:\Windows\System32\repadmin.exe /syncall /force
        if ($result -join '-' | Select-String "syncall finished") {
            Write-Status "Replication completed successfully" -Level Success
        }
    }
    catch {
        Write-Status "Replication warning: $_" -Level Warning
    }
}

################################################################################
# MAIN ACTIVITY FUNCTION
################################################################################

function Invoke-DirectoryActivity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        $Environment
    )
    
    Write-Host ""
    Write-Status "Starting Directory Activity (activity-01)" -Level Success
    Write-Host ""
    
    $DomainInfo = $Environment.DomainInfo
    $domainDN = $DomainInfo.DN
    
    # Build OU DNs from known structure created in setup-01
    $labUsersOUName = "Lab Users"
    $labUsersOU = "OU=$labUsersOUName,$domainDN"
    
    $dept101Name = "Dept101"
    $dept999Name = "Dept999"
    
    $dept101DN = "OU=$dept101Name,$labUsersOU"
    $dept999DN = "OU=$dept999Name,$labUsersOU"
    
    # Verify OUs exist
    try {
        $ou101 = Get-ADOrganizationalUnit -Identity $dept101DN -ErrorAction Stop
        $ou999 = Get-ADOrganizationalUnit -Identity $dept999DN -ErrorAction Stop
    }
    catch {
        Write-Status "Required OUs not found: $dept101DN or $dept999DN" -Level Error
        return $false
    }
    
    $createdCount = 0
    $errorCount = 0
    
    # ============================================================================
    # PHASE 1: MOVE USERS FROM DEPT999 TO DEPT101
    # ============================================================================
    
    Write-Section "PHASE 1: MOVE USERS FROM $dept999Name TO $dept101Name"
    
    try {
        $usersInDept999 = Get-ADUser -Filter "Enabled -eq `$true" -SearchBase $dept999DN -ErrorAction SilentlyContinue
        
        if ($usersInDept999.Count -gt 0) {
            Write-Status "Moving $($usersInDept999.Count) user(s) from $dept999Name to $dept101Name..." -Level Info
            
            foreach ($user in $usersInDept999) {
                try {
                    Move-ADObject -Identity $user -TargetPath $dept101DN -Verbose
                    $createdCount++
                    Start-Sleep -Milliseconds 500
                }
                catch {
                    Write-Status "Error moving user $($user.Name): $_" -Level Warning
                    $errorCount++
                }
            }
            
            Write-Status "Moved $createdCount user(s), $errorCount error(s)" -Level Success
        }
        else {
            Write-Status "No users in $dept999Name to move" -Level Info
        }
    }
    catch {
        Write-Status "Error in Phase 1: $_" -Level Error
        $errorCount++
    }
    
    # Force replication
    Invoke-Replication -WaitSeconds 5
    
    # ============================================================================
    # PHASE 2: CREATE GENERIC LAB USERS IN DEPT101
    # ============================================================================
    
    Write-Section "PHASE 2: CREATE GENERIC LAB USERS IN $dept101Name"
    
    try {
        $userCount = 15
        $prefix = "LabUs3r"
        $created = 0
        $skipped = 0
        
        Write-Status "Creating up to $userCount generic lab users..." -Level Info
        
        for ($i = 0; $i -lt $userCount; $i++) {
            $samAccountName = "$prefix-$i"
            
            # Check if user exists
            $existingUser = Get-ADUser -Filter "SamAccountName -eq '$samAccountName'" -ErrorAction SilentlyContinue
            
            if ($existingUser) {
                $skipped++
                Write-Status "User $samAccountName already exists (skipping)" -Level Info
            }
            else {
                try {
                    $password = ConvertTo-SecureString "P@ssw0rd$(Get-Random -Minimum 1000 -Maximum 9999)" -AsPlainText -Force
                    
                    New-ADUser -SamAccountName $samAccountName `
                               -Name "Lab User $i" `
                               -GivenName "Lab" `
                               -Surname "User $i" `
                               -DisplayName "Lab User $i" `
                               -Path $dept101DN `
                               -AccountPassword $password `
                               -Enabled $true `
                               -Verbose
                    
                    $created++
                    Write-Status "Created user: $samAccountName" -Level Success
                    Start-Sleep -Milliseconds 100
                }
                catch {
                    Write-Status "Error creating user $samAccountName : $_" -Level Warning
                    $errorCount++
                }
            }
        }
        
        Write-Status "User creation complete - Created: $created, Skipped: $skipped" -Level Success
    }
    catch {
        Write-Status "Error in Phase 2: $_" -Level Error
        $errorCount++
    }
    
    # Force replication
    Invoke-Replication -WaitSeconds 5
    
    # ============================================================================
    # PHASE 3: ADD USERS TO SPECIAL LAB USERS GROUP
    # ============================================================================
    
    Write-Section "PHASE 3: ADD USERS TO SPECIAL LAB USERS GROUP"
    
    try {
        $labUsersGroupName = "Special Lab Users"
        
        try {
            $labUsersGroup = Get-ADGroup -Filter "Name -eq '$labUsersGroupName'" -ErrorAction Stop
        }
        catch {
            Write-Status "Group '$labUsersGroupName' not found - skipping phase 3" -Level Warning
        }
        
        if ($labUsersGroup) {
            $deptUsers = Get-ADUser -Filter "Enabled -eq `$true" -SearchBase $dept101DN -ErrorAction SilentlyContinue
            
            if ($deptUsers.Count -gt 0) {
                Write-Status "Adding $($deptUsers.Count) users to '$labUsersGroupName'..." -Level Info
                
                $addedCount = 0
                foreach ($user in $deptUsers) {
                    try {
                        Add-ADGroupMember -Identity $labUsersGroup -Members $user -ErrorAction SilentlyContinue -Verbose
                        $addedCount++
                        Start-Sleep -Milliseconds 100
                    }
                    catch {
                        # User may already be a member; this is OK
                    }
                }
                
                Write-Status "Added $addedCount user(s) to group" -Level Success
            }
        }
    }
    catch {
        Write-Status "Error in Phase 3: $_" -Level Error
        $errorCount++
    }
    
    # Force replication
    Invoke-Replication -WaitSeconds 5
    
    # ============================================================================
    # PHASE 4: MOVE USERS FROM DEPT101 TO DEPT999
    # ============================================================================
    
    Write-Section "PHASE 4: MOVE USERS FROM $dept101Name TO $dept999Name"
    
    Write-Status "Waiting 10 seconds before initiating moves..." -Level Info
    Start-Sleep -Seconds 10
    
    try {
        $usersInDept101 = Get-ADUser -Filter "Enabled -eq `$true" -SearchBase $dept101DN -ErrorAction SilentlyContinue
        
        if ($usersInDept101.Count -gt 0) {
            Write-Status "Moving $($usersInDept101.Count) user(s) from $dept101Name to $dept999Name..." -Level Info
            
            $moveCount = 0
            foreach ($user in $usersInDept101) {
                try {
                    Move-ADObject -Identity $user -TargetPath $dept999DN -Verbose
                    $moveCount++
                    Start-Sleep -Milliseconds 500
                }
                catch {
                    Write-Status "Error moving user $($user.Name): $_" -Level Warning
                    $errorCount++
                }
            }
            
            Write-Host ""
            Write-Host ":: User objects moved from OU=$dept101Name to OU=$dept999Name!!!" -ForegroundColor Yellow -BackgroundColor DarkGray
            Write-Host ":: Total moved: $moveCount" -ForegroundColor Yellow
            Write-Host ""
        }
        else {
            Write-Status "No users in $dept101Name to move" -Level Warning
        }
    }
    catch {
        Write-Status "Error in Phase 4: $_" -Level Error
        $errorCount++
    }
    
    # Force replication
    Invoke-Replication -WaitSeconds 5
    
    # ============================================================================
    # PHASE 5: MODIFY USER ATTRIBUTES
    # ============================================================================
    
    Write-Section "PHASE 5: MODIFY USER ATTRIBUTES"
    
    try {
        # Get sample users to modify
        $usersToModify = Get-ADUser -Filter "Enabled -eq `$true" -SearchBase $dept999DN -ErrorAction SilentlyContinue | Select-Object -First 3
        
        if ($usersToModify.Count -gt 0) {
            Write-Status "Modifying attributes on $($usersToModify.Count) user(s)..." -Level Info
            
            foreach ($user in $usersToModify) {
                try {
                    # Modify Fax
                    Write-Status "Setting FAX on $($user.Name)..." -Level Info
                    Set-ADUser -Identity $user -Fax "+1-555-0123" -Verbose
                    Start-Sleep -Seconds 3
                    
                    # Modify Department
                    Write-Status "Setting Department on $($user.Name)..." -Level Info
                    Set-ADUser -Identity $user -Department "Engineering" -Verbose
                    Start-Sleep -Seconds 3
                }
                catch {
                    Write-Status "Error modifying user $($user.Name): $_" -Level Warning
                    $errorCount++
                }
            }
            
            Write-Status "User attribute modifications complete" -Level Success
        }
    }
    catch {
        Write-Status "Error in Phase 5: $_" -Level Error
        $errorCount++
    }
    
    # Final replication
    Invoke-Replication -WaitSeconds 10
    
    # ============================================================================
    # COMPLETION
    # ============================================================================
    
    Write-Host ""
    
    if ($errorCount -eq 0) {
        Write-Status "Directory Activity completed successfully" -Level Success
        Write-Host ""
        return $true
    }
    else {
        Write-Status "Directory Activity completed with $errorCount error(s)" -Level Warning
        Write-Host ""
        return $true
    }
}

################################################################################
# EXPORTS
################################################################################

Export-ModuleMember -Function Invoke-DirectoryActivity

################################################################################
# END OF MODULE
################################################################################