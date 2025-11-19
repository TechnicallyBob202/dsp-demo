################################################################################
##
## DSP-Demo-05-Groups.psm1
##
## Group creation and membership management
##
## Functions:
##   - New-DspGroup
##   - Add-DspGroupMember
##   - Remove-DspGroupMember
##   - Update-DspGroupMembership
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

function New-DspGroup {
    <#
    .SYNOPSIS
        Create a security group
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [string]$SamAccountName,
        
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$false)]
        [string]$Description,
        
        [Parameter(Mandatory=$false)]
        [string]$DisplayName,
        
        [Parameter(Mandatory=$false)]
        [string]$Server
    )
    
    # TODO: Implement New-ADGroup or Get-ADGroup + Set-ADGroup logic
    
    Write-Host "PLACEHOLDER: Creating group $Name in $Path"
    
    return $null
}

function Add-DspGroupMember {
    <#
    .SYNOPSIS
        Add a member to a group
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$GroupIdentity,
        
        [Parameter(Mandatory=$true)]
        [string[]]$Members,
        
        [Parameter(Mandatory=$false)]
        [string]$Server
    )
    
    # TODO: Implement Add-ADGroupMember logic
    
    Write-Host "PLACEHOLDER: Adding $($Members.Count) members to $GroupIdentity"
    
    return $null
}

function Remove-DspGroupMember {
    <#
    .SYNOPSIS
        Remove all members from a group (for demo purposes)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$GroupIdentity,
        
        [Parameter(Mandatory=$false)]
        [string]$Server
    )
    
    # TODO: Implement Get-ADGroupMember + Remove-ADGroupMember logic
    # Get all members then remove each one
    
    Write-Host "PLACEHOLDER: Removing all members from $GroupIdentity"
    
    return $null
}

function Update-DspGroupMembership {
    <#
    .SYNOPSIS
        Update group membership (add/remove)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$GroupIdentity,
        
        [Parameter(Mandatory=$false)]
        [string[]]$AddMembers,
        
        [Parameter(Mandatory=$false)]
        [string[]]$RemoveMembers,
        
        [Parameter(Mandatory=$false)]
        [string]$Server
    )
    
    # TODO: Implement logic for both add and remove in one call
    
    Write-Host "PLACEHOLDER: Updating membership for $GroupIdentity"
    
    return $null
}

################################################################################
# EXPORT PUBLIC FUNCTIONS
################################################################################

Export-ModuleMember -Function @(
    'New-DspGroup',
    'Add-DspGroupMember',
    'Remove-DspGroupMember',
    'Update-DspGroupMembership'
)

