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
    
    # Get config values - paths like "Lab Users/Dept999"
    $sourceOUPath = $Config.Module01_UserMovesP1.SourceOU
    $targetOUPath = $Config.Module01_UserMovesP1.TargetOU
    
    # Convert path format "Lab Users/Dept999" to DN format (reverse order for DN)
    # "Lab Users/Dept999" becomes "OU=Dept999,OU=Lab Users,DC=..."
    $sourceOUParts = $sourceOUPath -split '/' | Where-Object { $_ }
    $sourceDNParts = @()
    for ($i = $sourceOUParts.Count - 1; $i -ge 0; $i--) {
        $sourceDNParts += "OU=$($sourceOUParts[$i])"
    }
    $sourceDeptDN = ($sourceDNParts -join ',') + ",$domainDN"
    
    $targetOUParts = $targetOUPath -split '/' | Where-Object { $_ }
    $targetDNParts = @()
    for ($i = $targetOUParts.Count - 1; $i -ge 0; $i--) {
        $targetDNParts += "OU=$($targetOUParts[$i])"
    }
    $targetDeptDN = ($targetDNParts -join ',') + ",$domainDN"
    
    # ============================================================================
    # PHASE 1: MOVE USERS FROM SOURCE TO TARGET DEPT
    # ============================================================================
    
    Write-Status "Moving users FROM $sourceOUPath TO $targetOUPath" -Level Info
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
            Write-Status "No users found in $sourceOUPath" -Level Warning
        }
    }
    catch {
        Write-Status "Error in Phase 1: $_" -Level Error
        $errorCount++
    }
    
    # ============================================================================
    # PHASE 2: CREATE GENERIC USERS IN TARGET DEPT
    # ============================================================================
    
    Write-Host ""
    Write-Status "Creating generic users in $targetOUPath" -Level Info
    Write-Host ""
    
    $userCount = $Config.Module01_UserMovesP1.NewUsersToCreate
    
    try {
        for ($i = 1; $i -le $userCount; $i++) {
            $samAccountName = "GenericUser$($i.ToString('000'))"
            $userExists = Get-ADUser -Filter "SamAccountName -eq '$samAccountName'" -ErrorAction SilentlyContinue
            
            if (-not $userExists) {
                try {
                    $newUser = New-ADUser `
                        -SamAccountName $samAccountName `
                        -Name "Generic User $i" `
                        -GivenName "Generic" `
                        -Surname "User$i" `
                        -Enabled $true `
                        -Path $targetDeptDN `
                        -AccountPassword (ConvertTo-SecureString -AsPlainText $Config.General.DefaultPassword -Force) `
                        -ErrorAction Stop -PassThru
                    
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
        $domainInfo = $Environment.DomainInfo
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
        Write-Status "Directory Moves Part 1 completed with $errorCount error(s)" -Level Warning
    }
    
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-DirectoryMovesPart1