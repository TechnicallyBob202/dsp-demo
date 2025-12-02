################################################################################
##
## DSP-Demo-Activity-05-GroupRemoveMember.psm1
##
## Remove "App Admin III" from Special Lab Users group
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

################################################################################
# HELPER FUNCTIONS
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

################################################################################
# MAIN FUNCTION
################################################################################

function Invoke-GroupRemoveMember {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Environment
    )
    
    Write-ActivityHeader "Group - Remove Member from Special Lab Users"
    
    $removedCount = 0
    $errorCount = 0
    
    $domainInfo = $Environment.DomainInfo
    $domainDN = $domainInfo.DN
    
    try {
        # Get Special Lab Users group
        $groupName = "Special Lab Users"
        $group = Get-ADGroup -Filter { Name -eq $groupName } -ErrorAction Stop
        
        if (-not $group) {
            Write-Status "Group '$groupName' not found" -Level Warning
            Write-Host ""
            return $true
        }
        
        Write-Status "Found group: $($group.Name)" -Level Info
        
        # Get App Admin III user
        $memberName = "App Admin III"
        $member = Get-ADUser -Filter { Name -eq $memberName } -ErrorAction Stop
        
        if (-not $member) {
            Write-Status "User '$memberName' not found" -Level Warning
            Write-Host ""
            return $true
        }
        
        Write-Status "Found user: $($member.Name)" -Level Info
        
        try {
            # Check if member exists in group
            $isMember = Get-ADGroupMember -Identity $group -ErrorAction Stop | Where-Object { $_.DistinguishedName -eq $member.DistinguishedName }
            
            if ($isMember) {
                # Remove member from group
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
            Write-Status "Error removing member: $_" -Level Error
            $errorCount++
        }
        
        # Trigger replication
        if ($removedCount -gt 0) {
            Write-Status "Triggering replication..." -Level Info
            try {
                $dc = $domainInfo.ReplicationPartners[0]
                if ($dc) {
                    Repadmin /syncall $dc /APe | Out-Null
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
    Write-Status "Removed: $removedCount, Errors: $errorCount" -Level Info
    
    if ($errorCount -eq 0) {
        Write-Status "Group Remove Member completed successfully" -Level Success
    }
    else {
        Write-Status "Group Remove Member completed with $errorCount error(s)" -Level Warning
    }
    
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-GroupRemoveMember