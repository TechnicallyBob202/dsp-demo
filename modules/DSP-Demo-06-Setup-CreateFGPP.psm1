################################################################################
##
## DSP-Demo-06-Setup-CreateFGPP.psm1
##
## Creates Fine-Grained Password Policy (FGPP) objects (msDS-PasswordSettings).
##
## FGPPs Created:
## - DSP-Demo-FGPP
##   Description: Primary fine-grained password policy for demo
##   Applied to: SpecialLabUsers group
##   Settings: Highly restrictive password requirements
##
## - SpecialLabUsers_PSO
##   Description: Fine-grained password policy for special lab users
##   Applied to: SpecialLabUsers group
##   Settings: Custom password requirements (restrictive)
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

################################################################################
# LOGGING FUNCTIONS
################################################################################

function Write-ActivityLog {
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
# INTERNAL HELPER FUNCTIONS
################################################################################

function Get-PSCPaths {
    <#
    .SYNOPSIS
    Gets the Password Settings Container path for the domain.
    
    .DESCRIPTION
    Calculates the DN path to the Password Settings Container in the System 
    container based on domain DN.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$DomainDN
    )
    
    return "CN=Password Settings Container,CN=System,$DomainDN"
}

function New-FGPP {
    <#
    .SYNOPSIS
    Creates a Fine-Grained Password Policy if it doesn't already exist.
    
    .PARAMETER Name
    The name of the FGPP
    
    .PARAMETER DomainDN
    The distinguished name of the domain
    
    .PARAMETER Precedence
    PSO precedence (lower = higher priority)
    
    .PARAMETER MinPasswordLength
    Minimum password length required
    
    .PARAMETER ComplexityEnabled
    Whether complexity requirements are enforced
    
    .PARAMETER LockoutThreshold
    Number of failed attempts before lockout
    
    .PARAMETER MaxPasswordAge
    Maximum password age in days
    
    .PARAMETER MinPasswordAge
    Minimum password age in days
    
    .PARAMETER PasswordHistoryCount
    Number of previous passwords remembered
    
    .PARAMETER ReversibleEncryptionEnabled
    Whether reversible encryption is enabled
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [string]$DomainDN,
        
        [Parameter(Mandatory=$true)]
        [int]$Precedence,
        
        [Parameter(Mandatory=$false)]
        [int]$MinPasswordLength = 8,
        
        [Parameter(Mandatory=$false)]
        [bool]$ComplexityEnabled = $true,
        
        [Parameter(Mandatory=$false)]
        [int]$LockoutThreshold = 5,
        
        [Parameter(Mandatory=$false)]
        [int]$MaxPasswordAge = 42,
        
        [Parameter(Mandatory=$false)]
        [int]$MinPasswordAge = 1,
        
        [Parameter(Mandatory=$false)]
        [int]$PasswordHistoryCount = 24,
        
        [Parameter(Mandatory=$false)]
        [bool]$ReversibleEncryptionEnabled = $false
    )
    
    try {
        # Check if FGPP already exists
        $existing = Get-ADFineGrainedPasswordPolicy -Filter "Name -eq '$Name'" -ErrorAction SilentlyContinue
        
        if ($existing) {
            Write-ActivityLog "FGPP already exists: $Name" -Level Info
            return $existing
        }
        
        # Build parameters for New-ADFineGrainedPasswordPolicy
        $fgppParams = @{
            Name = $Name
            Precedence = $Precedence
            MinPasswordLength = $MinPasswordLength
            ComplexityEnabled = $ComplexityEnabled
            LockoutThreshold = $LockoutThreshold
            LockoutDuration = New-TimeSpan -Minutes 30
            LockoutObservationWindow = New-TimeSpan -Minutes 30
            MaxPasswordAge = New-TimeSpan -Days $MaxPasswordAge
            MinPasswordAge = New-TimeSpan -Days $MinPasswordAge
            PasswordHistoryCount = $PasswordHistoryCount
            ReversibleEncryptionEnabled = $ReversibleEncryptionEnabled
            ErrorAction = 'Stop'
        }
        
        $fgpp = New-ADFineGrainedPasswordPolicy @fgppParams
        Write-ActivityLog "FGPP created: $Name (Precedence: $Precedence)" -Level Success
        return $fgpp
    }
    catch {
        Write-ActivityLog "Failed to create FGPP $Name : $_" -Level Error
        return $null
    }
}

function Add-FGPPToGroup {
    <#
    .SYNOPSIS
    Applies a Fine-Grained Password Policy to a group.
    
    .PARAMETER FGPPName
    The name of the FGPP to apply
    
    .PARAMETER GroupDN
    The distinguished name of the group
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FGPPName,
        
        [Parameter(Mandatory=$true)]
        [string]$GroupDN
    )
    
    try {
        # Get the FGPP
        $fgpp = Get-ADFineGrainedPasswordPolicy -Identity $FGPPName -ErrorAction Stop
        
        # Get the group
        $group = Get-ADGroup -Identity $GroupDN -ErrorAction Stop
        
        # Check if group is already in AppliesTo
        $appliesTo = @($fgpp.AppliesTo)
        if ($appliesTo -contains $group.DistinguishedName) {
            Write-ActivityLog "FGPP '$FGPPName' already applies to group '$($group.Name)'" -Level Info
            return $true
        }
        
        # Add group to AppliesTo
        $appliesTo += $group.DistinguishedName
        Set-ADFineGrainedPasswordPolicy -Identity $FGPPName -AppliesTo $appliesTo -ErrorAction Stop
        
        Write-ActivityLog "FGPP '$FGPPName' applied to group '$($group.Name)'" -Level Success
        return $true
    }
    catch {
        Write-ActivityLog "Failed to apply FGPP to group: $_" -Level Error
        return $false
    }
}

################################################################################
# MAIN FUNCTION
################################################################################

function Invoke-CreateFGPP {
    <#
    .SYNOPSIS
    Creates all Fine-Grained Password Policies for the demo environment.
    
    .PARAMETER Config
    Hashtable containing configuration with FGPPs section
    
    .PARAMETER Environment
    PSCustomObject containing environment information with DomainInfo property
    
    .OUTPUTS
    Boolean - $true on success, $false on failure
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Environment
    )
    
    Write-ActivityLog "=== Starting FGPP Creation ===" -Level Info
    
    if (-not $Environment.DomainInfo) {
        Write-ActivityLog "ERROR: DomainInfo not found in Environment" -Level Error
        return $false
    }
    
    $domainInfo = $Environment.DomainInfo
    
    if (-not $domainInfo.DistinguishedName) {
        Write-ActivityLog "ERROR: DistinguishedName not found in DomainInfo" -Level Error
        return $false
    }
    
    $domainDN = $domainInfo.DistinguishedName
    
    # Check if FGPPs section exists in config
    if (-not $Config.ContainsKey('FGPPs') -or -not $Config['FGPPs']) {
        Write-ActivityLog "No FGPPs defined in configuration" -Level Info
        return $true
    }
    
    $fgppConfigs = $Config['FGPPs']
    if ($fgppConfigs -isnot [array]) {
        $fgppConfigs = @($fgppConfigs)
    }
    
    $successCount = 0
    $failureCount = 0
    
    # Create each FGPP
    foreach ($fgppConfig in $fgppConfigs) {
        if ($fgppConfig -isnot [hashtable]) {
            Write-ActivityLog "Invalid FGPP configuration (not a hashtable)" -Level Warning
            continue
        }
        
        $fgppName = $fgppConfig['Name']
        if (-not $fgppName) {
            Write-ActivityLog "FGPP configuration missing Name property" -Level Warning
            continue
        }
        
        # Validate required properties
        $precedence = $fgppConfig['Precedence']
        if ($null -eq $precedence) {
            Write-ActivityLog "FGPP '$fgppName' missing Precedence - skipping" -Level Warning
            continue
        }
        
        # Extract optional parameters with defaults
        $params = @{
            Name = $fgppName
            DomainDN = $domainDN
            Precedence = $precedence
            MinPasswordLength = if ($fgppConfig.ContainsKey('MinPasswordLength')) { $fgppConfig['MinPasswordLength'] } else { 8 }
            ComplexityEnabled = if ($fgppConfig.ContainsKey('ComplexityEnabled')) { $fgppConfig['ComplexityEnabled'] } else { $true }
            LockoutThreshold = if ($fgppConfig.ContainsKey('LockoutThreshold')) { $fgppConfig['LockoutThreshold'] } else { 5 }
            MaxPasswordAge = if ($fgppConfig.ContainsKey('MaxPasswordAge')) { $fgppConfig['MaxPasswordAge'] } else { 42 }
            MinPasswordAge = if ($fgppConfig.ContainsKey('MinPasswordAge')) { $fgppConfig['MinPasswordAge'] } else { 1 }
            PasswordHistoryCount = if ($fgppConfig.ContainsKey('PasswordHistoryCount')) { $fgppConfig['PasswordHistoryCount'] } else { 24 }
            ReversibleEncryptionEnabled = if ($fgppConfig.ContainsKey('ReversibleEncryptionEnabled')) { $fgppConfig['ReversibleEncryptionEnabled'] } else { $false }
        }
        
        $fgpp = New-FGPP @params
        
        if ($fgpp) {
            $successCount++
        }
        else {
            $failureCount++
        }
    }
    
    Write-ActivityLog "FGPP creation complete: $successCount created/found, $failureCount failed" -Level Info
    
    if ($failureCount -gt 0) {
        Write-ActivityLog "=== FGPP Creation completed with warnings ===" -Level Warning
        return $false
    }
    
    Write-ActivityLog "=== FGPP Creation completed successfully ===" -Level Success
    return $true
}

################################################################################
# EXPORT FUNCTIONS
################################################################################

Export-ModuleMember -Function @(
    'Invoke-CreateFGPP'
)

################################################################################
# END OF MODULE
################################################################################