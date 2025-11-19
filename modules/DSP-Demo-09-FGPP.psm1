################################################################################
##
## DSP-Demo-09-FGPP.psm1
##
## Fine-Grained Password Policy management
##
## Functions:
##   - New-DspFGPP
##   - Update-DspFGPP
##   - Add-DspFGPPPrincipal
##   - Remove-DspFGPP
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

function New-DspFGPP {
    <#
    .SYNOPSIS
        Create a Fine-Grained Password Policy (msDS-PasswordSettings object)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [int]$Precedence,
        
        [Parameter(Mandatory=$false)]
        [int]$MinPasswordLength = 12,
        
        [Parameter(Mandatory=$false)]
        [int]$PasswordHistoryCount = 5,
        
        [Parameter(Mandatory=$false)]
        [int]$MaxPasswordAge = 42,
        
        [Parameter(Mandatory=$false)]
        [int]$MinPasswordAge = 1,
        
        [Parameter(Mandatory=$false)]
        [int]$LockoutThreshold = 3,
        
        [Parameter(Mandatory=$false)]
        [int]$LockoutDurationMinutes = 30,
        
        [Parameter(Mandatory=$false)]
        [int]$LockoutObservationWindowMinutes = 30,
        
        [Parameter(Mandatory=$false)]
        [string]$Server
    )
    
    # TODO: Implement New-ADFineGrainedPasswordPolicy logic
    # Or direct AD object creation
    
    Write-Host "PLACEHOLDER: Creating FGPP '$Name' with precedence $Precedence"
    
    return $null
}

function Update-DspFGPP {
    <#
    .SYNOPSIS
        Update an existing FGPP
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Identity,
        
        [Parameter(Mandatory=$false)]
        [hashtable]$Properties,
        
        [Parameter(Mandatory=$false)]
        [string]$Server
    )
    
    # TODO: Implement Set-ADFineGrainedPasswordPolicy logic
    
    Write-Host "PLACEHOLDER: Updating FGPP '$Identity'"
    
    return $null
}

function Add-DspFGPPPrincipal {
    <#
    .SYNOPSIS
        Add a user or group to an FGPP
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$FGPPIdentity,
        
        [Parameter(Mandatory=$true)]
        [string[]]$Principals,
        
        [Parameter(Mandatory=$false)]
        [string]$Server
    )
    
    # TODO: Implement logic to add principals to FGPP
    # This applies the policy to user/group
    
    Write-Host "PLACEHOLDER: Adding $($Principals.Count) principals to FGPP '$FGPPIdentity'"
    
    return $null
}

function Remove-DspFGPP {
    <#
    .SYNOPSIS
        Remove an FGPP
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Identity,
        
        [Parameter(Mandatory=$false)]
        [string]$Server
    )
    
    # TODO: Implement Remove-ADFineGrainedPasswordPolicy logic
    
    Write-Host "PLACEHOLDER: Removing FGPP '$Identity'"
    
    return $null
}

################################################################################
# EXPORT PUBLIC FUNCTIONS
################################################################################

Export-ModuleMember -Function @(
    'New-DspFGPP',
    'Update-DspFGPP',
    'Add-DspFGPPPrincipal',
    'Remove-DspFGPP'
)

