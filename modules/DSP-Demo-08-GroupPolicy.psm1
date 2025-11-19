################################################################################
##
## DSP-Demo-08-GroupPolicy.psm1
##
## Group Policy Object creation and management
##
## Functions:
##   - New-DspGPO
##   - Set-DspGPORegistryValue
##   - New-DspGPOLink
##   - Remove-DspGPOLink
##   - Update-DspDefaultDomainPolicy
##
################################################################################

#Requires -Version 5.1
#Requires -Module GroupPolicy

function New-DspGPO {
    <#
    .SYNOPSIS
        Create a new Group Policy Object
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$false)]
        [string]$Comment,
        
        [Parameter(Mandatory=$false)]
        [string]$Server
    )
    
    # TODO: Implement New-GPO or Get-GPO + logic
    
    Write-Host "PLACEHOLDER: Creating GPO '$Name'"
    
    return $null
}

function Set-DspGPORegistryValue {
    <#
    .SYNOPSIS
        Set a registry value in a GPO
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$GPOName,
        
        [Parameter(Mandatory=$true)]
        [string]$Key,
        
        [Parameter(Mandatory=$true)]
        [string]$ValueName,
        
        [Parameter(Mandatory=$true)]
        [object]$Value,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet('DWord','String','Binary')]
        [string]$Type = 'DWord'
    )
    
    # TODO: Implement Set-GPRegistryValue
    
    Write-Host "PLACEHOLDER: Setting registry value $ValueName in GPO '$GPOName'"
    
    return $null
}

function New-DspGPOLink {
    <#
    .SYNOPSIS
        Link a GPO to an OU
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$GPOName,
        
        [Parameter(Mandatory=$true)]
        [string]$Target,
        
        [Parameter(Mandatory=$false)]
        [int]$LinkEnabled = 1
    )
    
    # TODO: Implement New-GPLink or Set-GPLink
    
    Write-Host "PLACEHOLDER: Linking GPO '$GPOName' to '$Target'"
    
    return $null
}

function Remove-DspGPOLink {
    <#
    .SYNOPSIS
        Remove a GPO link from an OU
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$GPOName,
        
        [Parameter(Mandatory=$true)]
        [string]$Target
    )
    
    # TODO: Implement Remove-GPLink
    
    Write-Host "PLACEHOLDER: Unlinking GPO '$GPOName' from '$Target'"
    
    return $null
}

function Update-DspDefaultDomainPolicy {
    <#
    .SYNOPSIS
        Update Default Domain Policy password settings
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$DomainName,
        
        [Parameter(Mandatory=$false)]
        [int]$LockoutThreshold,
        
        [Parameter(Mandatory=$false)]
        [int]$MaxPasswordAge,
        
        [Parameter(Mandatory=$false)]
        [string]$Server
    )
    
    # TODO: Implement Set-ADDefaultDomainPasswordPolicy
    
    Write-Host "PLACEHOLDER: Updating Default Domain Policy for $DomainName"
    
    return $null
}

################################################################################
# EXPORT PUBLIC FUNCTIONS
################################################################################

Export-ModuleMember -Function @(
    'New-DspGPO',
    'Set-DspGPORegistryValue',
    'New-DspGPOLink',
    'Remove-DspGPOLink',
    'Update-DspDefaultDomainPolicy'
)

