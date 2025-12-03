################################################################################
##
## DSP-Demo-Activity-06-AccountLockout.psm1
##
## Trigger account lockout via bad password attempts using net use
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

function Invoke-AccountLockout {
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
    
    $DomainInfo = $Environment.DomainInfo    
    $domainFQDN = $domainInfo.FQDN
    $primaryDC = $Environment.PrimaryDC
    
    # Get config values
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
    
    Write-Status "Target user: $targetUser" -Level Info
    Write-Status "Bad password attempts: $badPasswordAttempts" -Level Info
    Write-Status "Primary DC: $primaryDC" -Level Info
    Write-Host ""
    
    try {
        # Verify user exists
        $user = Get-ADUser -Filter { SamAccountName -eq $targetUser } -ErrorAction SilentlyContinue
        
        if (-not $user) {
            Write-Status "User '$targetUser' not found" -Level Warning
            Write-Host ""
            return $true
        }
        
        Write-Status "Found user: $($user.Name)" -Level Success
        Write-Status "Attempting $badPasswordAttempts bad password attempts to trigger lockout..." -Level Info
        Write-Host ""
        
        # Generate bad password attempts using net use
        for ($i = 1; $i -le $badPasswordAttempts; $i++) {
            try {
                # Use net use with explicit domain\user and a bad password
                # This triggers real authentication failure events in the security log
                & net use "\\$primaryDC\netlogon" /user:"$domainFQDN\$targetUser" "BadPassword123!" > $null 2>&1
                
                $attemptCount++
                
                # Progress indicator every 10 attempts
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
            
            # Small delay between attempts
            Start-Sleep -Milliseconds 100
        }
        
        Write-Host ""
        Write-Status "Completed $badPasswordAttempts bad password attempts" -Level Success
        Write-Status "User '$targetUser' should now be locked out" -Level Info
        
        # Wait for events to be written
        Write-Status "Waiting 5 seconds for security events to be written..." -Level Info
        Start-Sleep -Seconds 5
        
        # Trigger replication
        Write-Status "Triggering replication..." -Level Info
        try {
            $dc = $Environment.PrimaryDC
            if ($dc) {
                $repOutput = & C:\Windows\System32\repadmin.exe /syncall /force $dc
                if ($repOutput -join '-' -match 'syncall finished') {
                    Write-Status "Replication completed successfully" -Level Success
                }
                else {
                    Write-Status "Replication executed" -Level Info
                }
                
                # Also replicate secondary DC if available
                if ($Environment.SecondaryDC) {
                    & C:\Windows\System32\repadmin.exe /syncall /force $Environment.SecondaryDC | Out-Null
                }
                
                Start-Sleep -Seconds 3
            }
            else {
                Write-Status "No primary DC available for replication" -Level Warning
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
    Write-Status "Bad password attempts: $attemptCount, Errors: $errorCount" -Level Info
    
    if ($errorCount -eq 0) {
        Write-Status "Account Lockout completed successfully" -Level Success
    }
    else {
        Write-Status "Account Lockout completed with $errorCount error(s)" -Level Warning
    }
    
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-AccountLockout

