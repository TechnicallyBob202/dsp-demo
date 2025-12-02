################################################################################
##
## DSP-Demo-Setup-05-CreateDefaultDomainPolicy.psm1
##
## Configures the Default Domain Policy with baseline password and lockout settings.
##
## Policy Settings Applied:
## - LockoutThreshold: 11 (triggers account lockout after 11 bad attempts)
## - LockoutDuration: 3 minutes (account locked for 3 minutes)
## - LockoutObservationWindow: 3 minutes (bad attempts counted within 3 min window)
## - MinPasswordAge: 0 days (passwords can be changed immediately)
## - MinPasswordLength: 8 characters (minimum password complexity)
## - PasswordComplexity: Enabled (passwords must meet complexity requirements)
## - PasswordHistorySize: As configured (prevents reuse of recent passwords)
## - MaxPasswordAge: As configured (password expiration period)
##
## These baseline settings are used for:
## - Demonstrating password policy changes in later phases
## - Enabling lockout demonstrations (password spray attack)
## - Supporting security-focused DSP change tracking
##
## IMPORTANT: Requires Enterprise Admins group membership
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

################################################################################
# LOGGING FUNCTION
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

function Invoke-CreateDefaultDomainPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        $Environment
    )
    
    Write-Status "=== Default Domain Policy Configuration ===" -Level Info
    
    try {
        # Extract domain info
        $domainInfo = $Environment.DomainInfo
        $domainDNSRoot = $domainInfo.FQDN
        
        # Get current policy settings for reference
        Write-Status "Retrieving current Default Domain Policy settings..." -Level Info
        $currentPolicy = Get-ADDefaultDomainPasswordPolicy -Identity $domainDNSRoot -ErrorAction Stop
        
        Write-Status "Current policy settings:" -Level Info
        Write-Status "  LockoutThreshold: $($currentPolicy.LockoutThreshold)" -Level Info
        Write-Status "  LockoutDuration: $($currentPolicy.LockoutDuration)" -Level Info
        Write-Status "  LockoutObservationWindow: $($currentPolicy.LockoutObservationWindow)" -Level Info
        Write-Status "  MinPasswordAge: $($currentPolicy.MinPasswordAge)" -Level Info
        Write-Status "  MinPasswordLength: $($currentPolicy.MinPasswordLength)" -Level Info
        Write-Status "  PasswordComplexity: $($currentPolicy.ComplexityEnabled)" -Level Info
        Write-Status "  PasswordHistorySize: $($currentPolicy.PasswordHistoryCount)" -Level Info
        Write-Status "  MaxPasswordAge: $($currentPolicy.MaxPasswordAge)" -Level Info
        
        Write-Host ""
        
        # Extract policy settings from config or use defaults
        $policySettings = @{
            LockoutThreshold = 11
            LockoutDuration = [timespan]::FromMinutes(3)
            LockoutObservationWindow = [timespan]::FromMinutes(3)
            MinPasswordAge = 0
            MinPasswordLength = 8
            ComplexityEnabled = $true
            PasswordHistoryCount = 24
            MaxPasswordAge = 42
        }
        
        # Override with config values if provided
        if ($Config -and $Config.ContainsKey('DefaultDomainPolicy')) {
            $configPolicy = $Config.DefaultDomainPolicy
            
            if ($configPolicy.ContainsKey('LockoutThreshold')) {
                $policySettings.LockoutThreshold = $configPolicy.LockoutThreshold
            }
            if ($configPolicy.ContainsKey('LockoutDuration')) {
                # Handle both integer (minutes) and TimeSpan formats
                $duration = $configPolicy.LockoutDuration
                if ($duration -is [int]) {
                    $policySettings.LockoutDuration = [timespan]::FromMinutes($duration)
                } elseif ($duration -is [timespan]) {
                    $policySettings.LockoutDuration = $duration
                }
            }
            if ($configPolicy.ContainsKey('LockoutObservationWindow')) {
                # Handle both integer (minutes) and TimeSpan formats
                $window = $configPolicy.LockoutObservationWindow
                if ($window -is [int]) {
                    $policySettings.LockoutObservationWindow = [timespan]::FromMinutes($window)
                } elseif ($window -is [timespan]) {
                    $policySettings.LockoutObservationWindow = $window
                }
            }
            if ($configPolicy.ContainsKey('MinPasswordAge')) {
                $policySettings.MinPasswordAge = $configPolicy.MinPasswordAge
            }
            if ($configPolicy.ContainsKey('MinPasswordLength')) {
                $policySettings.MinPasswordLength = $configPolicy.MinPasswordLength
            }
            if ($configPolicy.ContainsKey('PasswordComplexity')) {
                $policySettings.ComplexityEnabled = $configPolicy.PasswordComplexity
            }
            if ($configPolicy.ContainsKey('PasswordHistoryCount')) {
                $policySettings.PasswordHistoryCount = $configPolicy.PasswordHistoryCount
            }
            if ($configPolicy.ContainsKey('MaxPasswordAge')) {
                $policySettings.MaxPasswordAge = $configPolicy.MaxPasswordAge
            }
        }
        
        # Apply all policy settings in a SINGLE call (not multiple calls)
        Write-Status "Applying password policy settings..." -Level Info
        Set-ADDefaultDomainPasswordPolicy -Identity $domainDNSRoot `
            -LockoutThreshold $policySettings.LockoutThreshold `
            -LockoutDuration $policySettings.LockoutDuration `
            -LockoutObservationWindow $policySettings.LockoutObservationWindow `
            -MinPasswordAge $policySettings.MinPasswordAge `
            -MinPasswordLength $policySettings.MinPasswordLength `
            -ComplexityEnabled $policySettings.ComplexityEnabled `
            -PasswordHistoryCount $policySettings.PasswordHistoryCount `
            -MaxPasswordAge $policySettings.MaxPasswordAge `
            -ErrorAction Stop
        
        Write-Status "Policy settings applied successfully" -Level Success
        Write-Host ""
        
        # Retrieve and display updated policy
        Write-Status "Verifying applied policy settings..." -Level Info
        $updatedPolicy = Get-ADDefaultDomainPasswordPolicy -Identity $domainDNSRoot -ErrorAction Stop
        
        Write-Status "Updated policy settings:" -Level Info
        Write-Status "  LockoutThreshold: $($updatedPolicy.LockoutThreshold)" -Level Success
        Write-Status "  LockoutDuration: $($updatedPolicy.LockoutDuration)" -Level Success
        Write-Status "  LockoutObservationWindow: $($updatedPolicy.LockoutObservationWindow)" -Level Success
        Write-Status "  MinPasswordAge: $($updatedPolicy.MinPasswordAge)" -Level Success
        Write-Status "  MinPasswordLength: $($updatedPolicy.MinPasswordLength)" -Level Success
        Write-Status "  PasswordComplexity: $($updatedPolicy.ComplexityEnabled)" -Level Success
        Write-Status "  PasswordHistorySize: $($updatedPolicy.PasswordHistoryCount)" -Level Success
        Write-Status "  MaxPasswordAge: $($updatedPolicy.MaxPasswordAge)" -Level Success
        
        Write-Host ""
        
        # Force replication
        Write-Status "Forcing replication of policy changes..." -Level Info
        & C:\Windows\System32\repadmin.exe /syncall /force $($Environment.PrimaryDC) | Out-Null
        
        Write-Status "Waiting 5 seconds for replication..." -Level Info
        Start-Sleep -Seconds 5
        
        Write-Status "=== Default Domain Policy Configuration Complete ===" -Level Success
        return $true
    }
    catch {
        Write-Status "ERROR: Failed to configure Default Domain Policy: $_" -Level Error
        return $false
    }
}

################################################################################
# EXPORT
################################################################################

Export-ModuleMember -Function @(
    'Invoke-CreateDefaultDomainPolicy'
)

################################################################################
# END OF MODULE
################################################################################