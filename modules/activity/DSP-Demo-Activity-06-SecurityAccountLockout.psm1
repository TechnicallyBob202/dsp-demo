################################################################################
##
## DSP-Demo-Activity-06-SecurityAccountLockout.psm1
##
## Trigger account lockout via bad password attempts
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

function Invoke-SecurityAccountLockout {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Environment
    )
    
    Write-ActivityHeader "Security - Account Lockout via Bad Passwords"
    
    $attemptCount = 0
    $errorCount = 0
    
    $domainInfo = $Environment.DomainInfo
    $domainFQDN = $domainInfo.FQDN
    
    # Get config values - REQUIRED
    $targetUser = $Config.Module06_AccountLockout.TargetUser
    if (-not $targetUser) {
        Write-Status "ERROR: TargetUser not configured in Module06_AccountLockout" -Level Error
        Write-Host ""
        return $false
    }
    
    $badPasswordAttempts = $Config.Module06_AccountLockout.BadPasswordAttempts
    if (-not $badPasswordAttempts) {
        Write-Status "ERROR: BadPasswordAttempts not configured in Module06_AccountLockout" -Level Error
        Write-Host ""
        return $false
    }
    
    $badPassword = $Config.Module06_AccountLockout.BadPassword
    if (-not $badPassword) {
        Write-Status "ERROR: BadPassword not configured in Module06_AccountLockout" -Level Error
        Write-Host ""
        return $false
    }
    
    Write-Status "TargetUser: $targetUser" -Level Info
    Write-Status "BadPasswordAttempts: $badPasswordAttempts" -Level Info
    
    Write-Host ""
    
    try {
        # Get target user
        $user = Get-ADUser -Filter { SamAccountName -eq $targetUser } -ErrorAction SilentlyContinue
        
        if (-not $user) {
            Write-Status "User '$targetUser' not found" -Level Warning
            Write-Host ""
            return $true
        }
        
        Write-Status "Found user: $($user.Name)" -Level Success
        Write-Status "Attempting $badPasswordAttempts bad passwords to trigger lockout..." -Level Info
        Write-Host ""
        
        # Generate bad password attempts
        for ($i = 1; $i -le $badPasswordAttempts; $i++) {
            try {
                # Attempt to authenticate with bad password
                $cred = New-Object System.Management.Automation.PSCredential(
                    "$domainFQDN\$targetUser",
                    (ConvertTo-SecureString $badPassword -AsPlainText -Force)
                )
                
                # This will fail, but the failed attempt is logged by AD
                Add-ADGroupMember -Identity "Domain Users" -Members $user -Credential $cred -ErrorAction SilentlyContinue 2>$null
                
                $attemptCount++
                
                if ($i % 10 -eq 0) {
                    Write-Status "Bad password attempt $i of $badPasswordAttempts" -Level Info
                }
            }
            catch {
                # Expected - auth attempt failed
                $attemptCount++
                
                if ($i % 10 -eq 0) {
                    Write-Status "Bad password attempt $i of $badPasswordAttempts" -Level Info
                }
            }
            
            Start-Sleep -Milliseconds 50
        }
        
        Write-Host ""
        Write-Status "Completed $badPasswordAttempts bad password attempts" -Level Success
        Write-Status "$targetUser should now be locked out" -Level Info
        
        # Trigger replication
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
    catch {
        Write-Status "Fatal error: $_" -Level Error
        $errorCount++
    }
    
    # Summary
    Write-Host ""
    Write-Status "Bad password attempts: $attemptCount, Errors: $errorCount" -Level Success
    
    if ($errorCount -eq 0) {
        Write-Status "Account Lockout completed successfully" -Level Success
    }
    else {
        Write-Status "Account Lockout completed with $errorCount error(s)" -Level Error
    }
    
    Write-Host ""
    return ($errorCount -eq 0)
}

Export-ModuleMember -Function Invoke-SecurityAccountLockout