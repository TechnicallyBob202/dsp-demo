################################################################################
##
## DSP-Demo-Activity-05-GroupRemoveMember.psm1
##
## Remove member from Special Lab Users group
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

function Invoke-GroupMembership {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Environment
    )
    
    Write-ActivityHeader "Group - Remove Member"
    
    $removedCount = 0
    $errorCount = 0
    
    $DomainInfo = $Environment.DomainInfo
    $ModuleConfig = $Config.Module5_GroupMembership
    
    # Get config values - REQUIRED
    $groupName = $Config.Module05_GroupMembership.GroupName
    if (-not $groupName) {
        Write-Status "ERROR: GroupName not configured in Module05_GroupMembership" -Level Error
        Write-Host ""
        return $false
    }
    
    $membersToRemove = $Config.Module05_GroupMembership.RemoveMembers
    if (-not $membersToRemove -or $membersToRemove.Count -eq 0) {
        Write-Status "ERROR: RemoveMembers not configured in Module05_GroupMembership" -Level Error
        Write-Host ""
        return $false
    }
    
    Write-Status "GroupName: $groupName" -Level Info
    Write-Status "MembersToRemove: $($membersToRemove -join ', ')" -Level Info
    
    Write-Host ""
    
    try {
        # Get group
        $group = Get-ADGroup -Filter { Name -eq $groupName } -ErrorAction SilentlyContinue
        
        if (-not $group) {
            Write-Status "Group '$groupName' not found" -Level Warning
            Write-Host ""
            return $true
        }
        
        Write-Status "Found group: $($group.Name)" -Level Success
        Write-Host ""
        
        # Remove each member
        foreach ($memberName in $membersToRemove) {
            try {
                $member = Get-ADUser -Filter { Name -eq $memberName } -ErrorAction SilentlyContinue
                
                if (-not $member) {
                    Write-Status "User '$memberName' not found" -Level Warning
                    continue
                }
                
                # Check if member exists in group
                $isMember = Get-ADGroupMember -Identity $group -ErrorAction SilentlyContinue | Where-Object { $_.DistinguishedName -eq $member.DistinguishedName }
                
                if ($isMember) {
                    Remove-ADGroupMember -Identity $group -Members $member -Confirm:$false -ErrorAction Stop
                    Write-Status "Removed '$memberName' from '$groupName'" -Level Success
                    $removedCount++
                    Start-Sleep -Milliseconds 500
                }
                else {
                    Write-Status "'$memberName' is not a member of '$groupName'" -Level Info
                }
            }
            catch {
                Write-Status "Error removing $memberName : $_" -Level Error
                $errorCount++
            }
        }
        
        # Trigger replication if members were removed
        if ($removedCount -gt 0) {
            Write-Status "Triggering replication..." -Level Info
            try {
                if ($domainInfo.ReplicationPartners -and $domainInfo.ReplicationPartners.Count -gt 0) {
                    Repadmin /syncall $domainInfo.ReplicationPartners[0] /APe | Out-Null
                    Start-Sleep -Seconds 3
                    Write-Status "Replication triggered" -Level Success
                }
            }
            catch {
                Write-Status "Warning: Could not trigger replication: $_" -Level Warning
            }
        }
    }
    catch {
        Write-Status "Fatal error: $_" -Level Error
        $errorCount++
    }
    
    # Summary
    Write-Host ""
    Write-Status "Group Remove Member - Removed: $removedCount, Errors: $errorCount" -Level Success
    
    if ($errorCount -eq 0) {
        Write-Status "Group Remove Member completed successfully" -Level Success
    }
    else {
        Write-Status "Group Remove Member completed with $errorCount error(s)" -Level Error
    }
    
    Write-Host ""
    return ($errorCount -eq 0)
}

Export-ModuleMember -Function Invoke-GroupMembership
