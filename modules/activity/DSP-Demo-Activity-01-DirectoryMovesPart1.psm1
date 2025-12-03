################################################################################
##
## DSP-Demo-Activity-01-DirectoryMovesPart1.psm1
##
## Move users FROM source OU TO target OU, create generic users in target
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
    
    # Get config values - REQUIRED
    $sourceOU = $Config.Module01_UserMovesP1.SourceOU
    if (-not $sourceOU) {
        Write-Status "ERROR: SourceOU not configured in Module01_UserMovesP1" -Level Error
        Write-Host ""
        return $false
    }
    
    $targetOU = $Config.Module01_UserMovesP1.TargetOU
    if (-not $targetOU) {
        Write-Status "ERROR: TargetOU not configured in Module01_UserMovesP1" -Level Error
        Write-Host ""
        return $false
    }
    
    $newUsersToCreate = $Config.Module01_UserMovesP1.NewUsersToCreate
    if (-not $newUsersToCreate) {
        $newUsersToCreate = 15
        Write-Status "NewUsersToCreate not in config, using default: $newUsersToCreate" -Level Info
    }
    
    Write-Status "SourceOU: $sourceOU" -Level Info
    Write-Status "TargetOU: $targetOU" -Level Info
    Write-Host ""
    
    # Parse OU paths (e.g., "Lab Users/Dept999" → "OU=Dept999,OU=Lab Users,DC=d3,DC=lab")
    function Resolve-OUPathToDN {
        param([string]$LogicalPath, [string]$DomainDN)
        $parts = $LogicalPath -split '/'
        $dn = @()
        # Add parts in reverse order (rightmost part becomes leftmost in DN)
        for ($i = $parts.Count - 1; $i -ge 0; $i--) {
            $dn += "OU=$($parts[$i])"
        }
        return ($dn -join ',') + ',' + $DomainDN
    }
    
    $sourceDeptDN = Resolve-OUPathToDN $sourceOU $domainDN
    $targetDeptDN = Resolve-OUPathToDN $targetOU $domainDN
    
    Write-Status "Source DN: $sourceDeptDN" -Level Info
    Write-Status "Target DN: $targetDeptDN" -Level Info
    
    # ============================================================================
    # PHASE 1: MOVE USERS FROM SOURCE TO TARGET
    # ============================================================================
    
    Write-Status "Moving users FROM $sourceOU TO $targetOU" -Level Info
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
                    Write-Status "Error moving $($user.Name) : $_" -Level Error
                    $errorCount++
                }
            }
        }
        else {
            Write-Status "No users found in source OU" -Level Info
        }
    }
    catch {
        Write-Status "Error in Phase 1: $_" -Level Error
        $errorCount++
    }
    
    Write-Host ""
    
    # ============================================================================
    # PHASE 2: CREATE NEW GENERIC USERS IN TARGET
    # ============================================================================
    
    Write-Status "Creating $newUsersToCreate generic users in $targetOU" -Level Info
    Write-Host ""
    
    try {
        $prefix = "LabUs3r"
        
        for ($i = 0; $i -lt $newUsersToCreate; $i++) {
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
                    Write-Status "Error creating $samAccountName : $_" -Level Error
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
        if ($domainInfo.ReplicationPartners -and $domainInfo.ReplicationPartners.Count -gt 0) {
            $dc = $domainInfo.ReplicationPartners[0]
            Repadmin /syncall $dc /APe | Out-Null
            Start-Sleep -Seconds 5
            Write-Status "Replication triggered" -Level Success
        }
        else {
            Write-Status "No replication partners available" -Level Warning
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
        Write-Status "Directory Moves Part 1 completed with $errorCount error(s)" -Level Error
    }
    
    Write-Host ""
    return ($errorCount -eq 0)
}

Export-ModuleMember -Function Invoke-DirectoryMovesPart1