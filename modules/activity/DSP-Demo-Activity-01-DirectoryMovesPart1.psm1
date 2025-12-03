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
            if ($usersToMove -is [array]) {
                Write-Status "Found $($usersToMove.Count) users to move" -Level Info
            }
            else {
                Write-Status "Found 1 user to move" -Level Info
                $usersToMove = @($usersToMove)
            }
            
            foreach ($user in $usersToMove) {
                try {
                    Move-ADObject -Identity $user.DistinguishedName -TargetPath $targetDeptDN -ErrorAction Stop
                    Write-Status "Moved: $($user.SamAccountName)" -Level Success
                    $movedCount++
                    Start-Sleep -Milliseconds 100
                }
                catch {
                    Write-Status "Error moving $($user.SamAccountName) : $_" -Level Error
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
    
    # ============================================================================
    # PHASE 2: CREATE NEW GENERIC USERS IN TARGET
    # ============================================================================
    
    Write-Status "Creating $newUsersToCreate new generic users in target OU" -Level Info
    Write-Host ""
    
    $defaultPassword = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force
    
    try {
        for ($i = 1; $i -le $newUsersToCreate; $i++) {
            $samAccountName = "GdAct0r-{0:D2}" -f $i
            $displayName = "Lab User $i"
            
            # Check if user already exists anywhere in AD
            $existingUser = Get-ADUser -Filter "SamAccountName -eq '$samAccountName'" -ErrorAction SilentlyContinue
            
            if ($existingUser) {
                Write-Status "Skipped (exists): $samAccountName" -Level Info
                $skippedCount++
            }
            else {
                try {
                    $password = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force
                    New-ADUser -Name $displayName `
                               -SamAccountName $samAccountName `
                               -GivenName "Lab" `
                               -Surname "User" `
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
        $dc = (Get-ADDomainController -Discover -ErrorAction SilentlyContinue).HostName
        if ($dc) {
            Repadmin /syncall $dc /APe | Out-Null
            Start-Sleep -Seconds 5
            Write-Status "Replication complete" -Level Success
        }
        else {
            Write-Status "No DC available for replication" -Level Warning
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