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

# TODO: Validate caller has Enterprise Admins privileges
# - Check group membership or domain object modification capability
# - Return error if insufficient privileges

# TODO: Retrieve current Default Domain Policy settings
# - Get-ADDefaultDomainPasswordPolicy -Identity <DomainDNSRoot>
# - Log current values for reference

# TODO: Set LockoutThreshold to 11
# - Set-ADDefaultDomainPasswordPolicy -LockoutThreshold 11

# TODO: Set LockoutDuration to 3 minutes (0.00:03:00.0)
# - Format: Days.Hours:Minutes:Seconds.Milliseconds
# - Set-ADDefaultDomainPasswordPolicy -LockoutDuration 0.00:03:00.0

# TODO: Set LockoutObservationWindow to 3 minutes (0.00:03:00.0)
# - Set-ADDefaultDomainPasswordPolicy -LockoutObservationWindow 0.00:03:00.0

# TODO: Set MinPasswordAge to 0 days
# - Set-ADDefaultDomainPasswordPolicy -MinPasswordAge 0

# TODO: Set MinPasswordLength to 8
# - Set-ADDefaultDomainPasswordPolicy -MinPasswordLength 8

# TODO: Set PasswordComplexity to Enabled (if not already set)
# - Note: Usually enabled by default, but verify

# TODO: Log all applied settings
# - Display before/after values
# - Confirm successful application

# TODO: Force replication to ensure policy changes propagate
# - Wait-ADReplication or repadmin /syncall /force
# - Include appropriate delay (5-10 seconds)

# TODO: Implement Invoke-CreateDefaultDomainPolicy function
# Parameters:
#   - DomainInfo: Domain information from preflight
#   - Config: Configuration hashtable with policy settings (optional)
# Returns: $true on success, $false on failure
# Notes:
#   - All settings have sensible defaults matching original script
#   - Config can override defaults if provided
#   - Include validation of TimeSpan format for duration settings
#   - Handle case where policy settings are already correct (idempotent)

# TODO: Export function
# Export-ModuleMember -Function Invoke-CreateDefaultDomainPolicy
