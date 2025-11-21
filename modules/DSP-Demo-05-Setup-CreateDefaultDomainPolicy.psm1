################################################################################
##
## DSP-Demo-05-Setup-CreateDefaultDomainPolicy.psm1
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
# MAIN FUNCTION
################################################################################

function Invoke-CreateDefaultDomainPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Environment
    )
    
    Write-ActivityLog "=== Default Domain Policy Configuration ===" -Level Info
    
    try {
        # Extract domain info
        $domainInfo = $Environment.DomainInfo
        $domainDNSRoot = $domainInfo.DNSRoot
        
        # Get current policy settings for reference
        Write-ActivityLog "Retrieving current Default Domain Policy settings..." -Level Info
        $currentPolicy = Get-ADDefaultDomainPasswordPolicy -Identity $domainDNSRoot -ErrorAction Stop
        
        Write-ActivityLog "Current policy settings:" -Level Info
        Write-ActivityLog "  LockoutThreshold: $($currentPolicy.LockoutThreshold)" -Level Info
        Write-ActivityLog "  LockoutDuration: $($currentPolicy.LockoutDuration)" -Level Info
        Write-ActivityLog "  LockoutObservationWindow: $($currentPolicy.LockoutObservationWindow)" -Level Info
        Write-ActivityLog "  MinPasswordAge: $($currentPolicy.MinPasswordAge)" -Level Info
        Write-ActivityLog "  MinPasswordLength: $($currentPolicy.MinPasswordLength)" -Level Info
        Write-ActivityLog "  PasswordComplexity: $($currentPolicy.ComplexityEnabled)" -Level Info
        Write-ActivityLog "  PasswordHistorySize: $($currentPolicy.PasswordHistoryCount)" -Level Info
        Write-ActivityLog "  MaxPasswordAge: $($currentPolicy.MaxPasswordAge)" -Level Info
        
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
                $policySettings.LockoutDuration = $configPolicy.LockoutDuration
            }
            if ($configPolicy.ContainsKey('LockoutObservationWindow')) {
                $policySettings.LockoutObservationWindow = $configPolicy.LockoutObservationWindow
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
        
        # Apply lockout settings
        Write-ActivityLog "Setting LockoutThreshold to $($policySettings.LockoutThreshold)..." -Level Info
        Set-ADDefaultDomainPasswordPolicy -Identity $domainDNSRoot `
            -LockoutThreshold $policySettings.LockoutThreshold `
            -ErrorAction Stop
        
        Write-ActivityLog "Setting LockoutDuration to $($policySettings.LockoutDuration.TotalMinutes) minutes..." -Level Info
        Set-ADDefaultDomainPasswordPolicy -Identity $domainDNSRoot `
            -LockoutDuration $policySettings.LockoutDuration `
            -ErrorAction Stop
        
        Write-ActivityLog "Setting LockoutObservationWindow to $($policySettings.LockoutObservationWindow.TotalMinutes) minutes..." -Level Info
        Set-ADDefaultDomainPasswordPolicy -Identity $domainDNSRoot `
            -LockoutObservationWindow $policySettings.LockoutObservationWindow `
            -ErrorAction Stop
        
        # Apply password age settings
        Write-ActivityLog "Setting MinPasswordAge to $($policySettings.MinPasswordAge) days..." -Level Info
        Set-ADDefaultDomainPasswordPolicy -Identity $domainDNSRoot `
            -MinPasswordAge $policySettings.MinPasswordAge `
            -ErrorAction Stop
        
        Write-ActivityLog "Setting MinPasswordLength to $($policySettings.MinPasswordLength) characters..." -Level Info
        Set-ADDefaultDomainPasswordPolicy -Identity $domainDNSRoot `
            -MinPasswordLength $policySettings.MinPasswordLength `
            -ErrorAction Stop
        
        Write-ActivityLog "Setting PasswordComplexity to $($policySettings.ComplexityEnabled)..." -Level Info
        Set-ADDefaultDomainPasswordPolicy -Identity $domainDNSRoot `
            -ComplexityEnabled $policySettings.ComplexityEnabled `
            -ErrorAction Stop
        
        Write-ActivityLog "Setting PasswordHistoryCount to $($policySettings.PasswordHistoryCount)..." -Level Info
        Set-ADDefaultDomainPasswordPolicy -Identity $domainDNSRoot `
            -PasswordHistoryCount $policySettings.PasswordHistoryCount `
            -ErrorAction Stop
        
        Write-ActivityLog "Setting MaxPasswordAge to $($policySettings.MaxPasswordAge) days..." -Level Info
        Set-ADDefaultDomainPasswordPolicy -Identity $domainDNSRoot `
            -MaxPasswordAge $policySettings.MaxPasswordAge `
            -ErrorAction Stop
        
        Write-Host ""
        
        # Retrieve and display updated policy
        Write-ActivityLog "Verifying applied policy settings..." -Level Info
        $updatedPolicy = Get-ADDefaultDomainPasswordPolicy -Identity $domainDNSRoot -ErrorAction Stop
        
        Write-ActivityLog "Updated policy settings:" -Level Info
        Write-ActivityLog "  LockoutThreshold: $($updatedPolicy.LockoutThreshold)" -Level Success
        Write-ActivityLog "  LockoutDuration: $($updatedPolicy.LockoutDuration)" -Level Success
        Write-ActivityLog "  LockoutObservationWindow: $($updatedPolicy.LockoutObservationWindow)" -Level Success
        Write-ActivityLog "  MinPasswordAge: $($updatedPolicy.MinPasswordAge)" -Level Success
        Write-ActivityLog "  MinPasswordLength: $($updatedPolicy.MinPasswordLength)" -Level Success
        Write-ActivityLog "  PasswordComplexity: $($updatedPolicy.ComplexityEnabled)" -Level Success
        Write-ActivityLog "  PasswordHistorySize: $($updatedPolicy.PasswordHistoryCount)" -Level Success
        Write-ActivityLog "  MaxPasswordAge: $($updatedPolicy.MaxPasswordAge)" -Level Success
        
        Write-Host ""
        
        # Force replication
        Write-ActivityLog "Forcing replication of policy changes..." -Level Info
        & C:\Windows\System32\repadmin.exe /syncall /force $domainInfo.PrimaryDC | Out-Null
        
        Write-ActivityLog "Waiting 5 seconds for replication..." -Level Info
        Start-Sleep -Seconds 5
        
        Write-ActivityLog "=== Default Domain Policy Configuration Complete ===" -Level Success
        return $true
    }
    catch {
        Write-ActivityLog "ERROR: Failed to configure Default Domain Policy: $_" -Level Error
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