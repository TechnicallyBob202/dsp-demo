################################################################################
##
## DSP-Demo-Activity-01-DirectoryMovesPart1.psm1
##
## Move users FROM Dept999 TO Dept101, create generic users in Dept101
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

function Write-Status {
    param([string]$Message, [ValidateSet('Info','Success','Warning','Error')][string]$Level = 'Info')
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colors = @{'Info'='White';'Success'='Green';'Warning'='Yellow';'Error'='Red'}
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colors[$Level]
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host ":: $Title" -ForegroundColor DarkRed -BackgroundColor Yellow
    Write-Host ""
}

function Invoke-Replication {
    param([int]$WaitSeconds = 1)
    try {
        Write-Status "Forcing AD replication (waiting $WaitSeconds seconds)..." -Level Info
        Start-Sleep $WaitSeconds
        $result = & C:\Windows\System32\repadmin.exe /syncall /force
        if ($result -join '-' | Select-String "syncall finished") {
            Write-Status "Replication completed" -Level Success
        }
    }
    catch { Write-Status "Replication warning: $_" -Level Warning }
}

function Invoke-DirectoryMovesPart1 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Status "Starting Directory Moves Part 1" -Level Success
    Write-Host ""
    
    $DomainInfo = $Environment.DomainInfo
    $domainDN = $DomainInfo.DN
    
    # Get config values
    $sourceOU = $Config.ActivitySettings.DirectoryActivity.SourceOU
    $sourceDept = $Config.ActivitySettings.DirectoryActivity.SourceDept
    $targetDept = $Config.ActivitySettings.DirectoryActivity.TargetDept
    
    $sourceDeptDN = "OU=$sourceDept,OU=$sourceOU,$domainDN"
    $targetDeptDN = "OU=$targetDept,OU=$sourceOU,$domainDN"
    
    $movedCount = 0
    $createdCount = 0
    $errorCount = 0
    
    # ============================================================================
    # PHASE 1: MOVE USERS FROM DEPT999 TO DEPT101
    # ============================================================================
    
    Write-Section "PHASE 1: MOVE USERS FROM $sourceDept TO $targetDept"
    
    try {
        $usersToMove = Get-ADUser -Filter "Enabled -eq `$true" -SearchBase $sourceDeptDN -ErrorAction SilentlyContinue
        
        if ($usersToMove.Count -gt 0) {
            Write-Status "Moving $($usersToMove.Count) user(s)..." -Level Info
            
            foreach ($user in $usersToMove) {
                try {
                    Move-ADObject -Identity $user -TargetPath $targetDeptDN -Verbose
                    $movedCount++
                    Start-Sleep -Milliseconds 500
                }
                catch {
                    Write-Status "Error moving $($user.Name): $_" -Level Warning
                    $errorCount++
                }
            }
        }
        else {
            Write-Status "No users found in $sourceDept to move" -Level Info
        }
    }
    catch {
        Write-Status "Error in Phase 1: $_" -Level Error
        $errorCount++
    }
    
    Invoke-Replication -WaitSeconds 5
    
    # ============================================================================
    # PHASE 2: CREATE 15 GENERIC USERS IN DEPT101
    # ============================================================================
    
    Write-Section "PHASE 2: CREATE 15 GENERIC USERS IN $targetDept"
    
    try {
        $userCount = 15
        $prefix = "LabUs3r"
        $skippedCount = 0
        
        Write-Status "Creating up to $userCount generic users..." -Level Info
        
        for ($i = 0; $i -lt $userCount; $i++) {
            $samAccountName = "$prefix-$i"
            
            $existingUser = Get-ADUser -Filter "SamAccountName -eq '$samAccountName'" -ErrorAction SilentlyContinue
            
            if (-not $existingUser) {
                try {
                    $password = ConvertTo-SecureString "P@ssw0rd$(Get-Random -Minimum 1000 -Maximum 9999)" -AsPlainText -Force
                    
                    New-ADUser -SamAccountName $samAccountName `
                               -Name "Lab User $i" `
                               -GivenName "Lab" `
                               -Surname "User $i" `
                               -DisplayName "Lab User $i" `
                               -Path $targetDeptDN `
                               -AccountPassword $password `
                               -Enabled $true `
                               -Verbose
                    
                    $createdCount++
                    Start-Sleep -Milliseconds 100
                }
                catch {
                    Write-Status "Error creating $samAccountName : $_" -Level Warning
                    $errorCount++
                }
            }
            else {
                $skippedCount++
            }
        }
        
        if ($createdCount -gt 0) {
            Write-Status "Created $createdCount user(s)" -Level Success
        }
        if ($skippedCount -gt 0) {
            Write-Status "Skipped $skippedCount existing user(s)" -Level Info
        }
        if ($createdCount -eq 0 -and $skippedCount -eq 0) {
            Write-Status "No users created or found" -Level Warning
        }
    }
    catch {
        Write-Status "Error in Phase 2: $_" -Level Error
        $errorCount++
    }
    
    Invoke-Replication -WaitSeconds 5
    
    # ============================================================================
    # COMPLETION
    # ============================================================================
    
    Write-Host ""
    Write-Status "Moved: $movedCount, Created: $createdCount, Errors: $errorCount" -Level Info
    
    if ($errorCount -eq 0) {
        Write-Status "Directory Moves Part 1 completed successfully" -Level Success
    }
    else {
        Write-Status "Directory Moves Part 1 completed with $errorCount error(s)" -Level Warning
    }
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-DirectoryMovesPart1