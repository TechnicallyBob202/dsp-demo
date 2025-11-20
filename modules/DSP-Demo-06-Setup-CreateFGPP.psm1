################################################################################
##
## DSP-Demo-06-Setup-CreateFGPP.psm1
##
## Creates Fine-Grained Password Policy (FGPP) objects (msDS-PasswordSettings).
##
## FGPPs Created:
## - SpecialLabUsers_PSO
##   Description: Fine-grained password policy for special lab users
##   Applied to: SpecialLabUsers group
##   Settings: Custom password requirements (more restrictive)
##
## - SpecialAccounts_PSO
##   Description: Fine-grained password policy for service accounts
##   Applied to: Service Accounts group
##   Settings: Custom password requirements for service/automation accounts
##   Note: Left in place for ongoing usage and demonstration
##
## Purpose:
## - Demonstrates FGPP creation and application to groups
## - Shows password policy change tracking in DSP
## - Later phases will modify these policies
##
## All FGPPs created with idempotent logic (create if not exists).
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

# TODO: Create SpecialLabUsers_PSO
# - Object Type: msDS-PasswordSettings
# - Name: SpecialLabUsers_PSO
# - DisplayName: SpecialLabUsers_PSO
# - Description: Fine-grained password policy for special lab users
# - AppliesTo: SpecialLabUsers group (DN)
# - Password Policy Settings:
#   - LockoutThreshold: (as configured)
#   - LockoutDuration: (as configured)
#   - LockoutObservationWindow: (as configured)
#   - MinPasswordAge: (as configured)
#   - MinPasswordLength: (as configured, likely higher than domain default)
#   - PasswordComplexity: Enabled
#   - PasswordHistorySize: (as configured)
#   - MaxPasswordAge: (as configured)
# - Precedence: Appropriate PSO precedence value

# TODO: Create SpecialAccounts_PSO
# - Object Type: msDS-PasswordSettings
# - Name: SpecialAccounts_PSO
# - DisplayName: SpecialAccounts_PSO
# - Description: Fine-grained password policy for service accounts
# - AppliesTo: Service Accounts group (DN)
# - Password Policy Settings:
#   - Configure for service account requirements
#   - May have different settings than SpecialLabUsers_PSO
# - Precedence: Appropriate PSO precedence value
# - Note: This PSO is left in place for ongoing use

# TODO: Implement Invoke-CreateFGPP function
# Parameters:
#   - DomainInfo: Domain information from preflight
#   - Config: Configuration hashtable with FGPP definitions
# Returns: $true on success, $false on failure
# Notes:
#   - Use New-ADFineGrainedPasswordPolicy or New-ADObject with proper schema
#   - FGPPs live in CN=Password Settings Container,CN=System,DC=...
#   - Implement idempotent creation (skip if exists by name)
#   - Handle precedence assignment carefully (lower number = higher precedence)
#   - Include validation that groups exist before applying FGPP
#   - Log which FGPPs were created vs skipped

# TODO: Export function
# Export-ModuleMember -Function Invoke-CreateFGPP
