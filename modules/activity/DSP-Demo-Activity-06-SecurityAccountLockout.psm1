################################################################################
##
## DSP-Demo-Activity-06-SecurityAccountLockout.psm1
##
## Trigger account lockout on DemoUser2 via 50 bad password attempts
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
    
    try {
        # Get DemoUser2
        $userName = "DemoUser2"
        $user = Get-ADUser -Filter { SamAccountName -eq $userName } -ErrorAction Stop
        
        if (-not $user) {
            Write-Status "User '$userName' not found" -Level Warning
            Write-Host ""
            return $true
        }
        
        Write-Status "Found user: $($user.Name)" -Level Info
        Write-Status "Attempting 50 bad passwords to trigger lockout..." -Level Info
        Write-Host ""
        
        # Generate 50 bad password attempts
        $badPassword = "BadPassword_DoesNotExist_12345!"
        
        for ($i = 1; $i -le 50; $i++) {
            try {
                # Attempt to authenticate with bad password
                $cred = New-Object System.Management.Automation.PSCredential(
                    "$domainFQDN\$userName",
                    (ConvertTo-SecureString $badPassword -AsPlainText -Force)
                )
                
                # This will fail, but the failed attempt is logged by AD
                Add-ADGroupMember -Identity "Domain Users" -Members $user -Credential $cred -ErrorAction SilentlyContinue 2>$null
                
                $attemptCount++
                
                if ($i % 10 -eq 0) {
                    Write-Status "Bad password attempt $i of 50" -Level Info
                }
            }
            catch {
                # Expected - auth attempt failed
                $attemptCount++
                
                if ($i % 10 -eq 0) {
                    Write-Status "Bad password attempt $i of 50" -Level Info
                }
            }
            
            Start-Sleep -Milliseconds 50
        }
        
        Write-Host ""
        Write-Status "Completed 50 bad password attempts" -Level Success
        Write-Status "DemoUser2 should now be locked out" -Level Info
        
        # Trigger replication
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

Export-ModuleMember -Function Invoke-SecurityAccountLockout