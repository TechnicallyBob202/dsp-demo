################################################################################
##
## DSP-Demo-Activity-01-DirectoryMovesPart1.psm1
##
## Move users FROM Dept999 TO Dept101, create generic users in Dept101
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

################################################################################
# HELPER FUNCTIONS
################################################################################

function Write-ActivityHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host ("+--" + ("-" * 62) + "--+") -ForegroundColor Cyan
    Write-Host ("| " + $Title.PadRight(62) + " |") -ForegroundColor Cyan
    Write-Host ("+--" + ("-" * 62) + "--+") -ForegroundColor Cyan
    Write-Host ""
}

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
# MAIN FUNCTION
################################################################################

function Invoke-DirectoryMovesPart1 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Environment
    )
    
    Write-ActivityHeader "Directory - Move Users Part 1"
    
    $movedCount = 0
    $createdCount = 0
    $skippedCount = 0
    $errorCount = 0
    
    $domainInfo = $Environment.DomainInfo
    $domainDN = $domainInfo.DN
    
    # Get config values
    $sourceOU = $Config.ActivitySettings.DirectoryActivity.SourceOU
    $sourceDept = $Config.ActivitySettings.DirectoryActivity.SourceDept
    $targetDept = $Config.ActivitySettings.DirectoryActivity.TargetDept
    
    $sourceDeptDN = "OU=$sourceDept,OU=$sourceOU,$domainDN"
    $targetDeptDN = "OU=$targetDept,OU=$sourceOU,$domainDN"
    
    # ============================================================================
    # PHASE 1: MOVE USERS FROM SOURCE TO TARGET DEPT
    # ============================================================================
    
    Write-Status "Moving users FROM $sourceDept TO $targetDept" -Level Info
    Write-Host ""
    
    try {
        $usersToMove = Get-ADUser -Filter "Enabled -eq `$true" -SearchBase $sourceDeptDN -ErrorAction SilentlyContinue
        
        if ($usersToMove) {
            if ($usersToMove -isnot [array]) {
                $usersToMove = @($usersToMove)
            }
            
            Write-Status "Found $($usersToMove.Count) user(s) to move" -Level Info
            
            foreach ($user in $usersToMove) {
                try {
                    Move-ADObject -Identity $user -TargetPath $targetDeptDN -ErrorAction Stop
                    Write-Status "Moved: $($user.Name)" -Level Success
                    $movedCount++
                    Start-Sleep -Milliseconds 500
                }
                catch {
                    Write-Status "Error moving $($user.Name): $_" -Level Error
                    $errorCount++
                }
            }
        }
        else {
            Write-Status "No users found in $sourceDept" -Level Info
        }
    }
    catch {
        Write-Status "Error in Phase 1: $_" -Level Error
        $errorCount++
    }
    
    Write-Host ""
    
    # ============================================================================
    # PHASE 2: CREATE 15 GENERIC USERS IN TARGET DEPT
    # ============================================================================
    
    Write-Status "Creating 15 generic users in $targetDept" -Level Info
    Write-Host ""
    
    try {
        $prefix = "LabUs3r"
        
        for ($i = 0; $i -lt 15; $i++) {
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
                               -ErrorAction Stop
                    
                    Write-Status "Created: $samAccountName" -Level Success
                    $createdCount++
                    Start-Sleep -Milliseconds 100
                }
                catch {
                    Write-Status "Error creating $samAccountName: $_" -Level Error
                    $errorCount++
                }
            }
            else {
                Write-Status "Skipped (exists): $samAccountName" -Level Info
                $skippedCount++
            }
        }
    }
    catch {
        Write-Status "Error in Phase 2: $_" -Level Error
        $errorCount++
    }
    
    # Trigger replication
    Write-Host ""
    Write-Status "Triggering replication..." -Level Info
    try {
        $dc = $domainInfo.ReplicationPartners[0]
        if ($dc) {
            Repadmin /syncall $dc /APe | Out-Null
            Start-Sleep -Seconds 5
            Write-Status "Replication triggered" -Level Success
        }
    }
    catch {
        Write-Status "Warning: Could not trigger replication: $_" -Level Warning
    }
    
    # Summary
    Write-Host ""
    Write-Status "Moved: $movedCount, Created: $createdCount, Skipped: $skippedCount, Errors: $errorCount" -Level Info
    
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
