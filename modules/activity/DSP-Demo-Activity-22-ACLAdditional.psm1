################################################################################
##
## DSP-Demo-Activity-22-ACLAdditional.psm1
##
## Additional ACL modifications on Bad OU
##
## Original Author: Rob Ingenthron (robi@semperis.com)
## Refactored By: Bob Lyons
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

function Write-Status {
    param([string]$Message, [ValidateSet('Info','Success','Warning','Error')][string]$Level = 'Info')
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colors = @{'Info'='White';'Success'='Green';'Warning'='Yellow';'Error'='Red'}
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $colors[$Level]
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host ":: $Title" -ForegroundColor DarkRed -BackgroundColor Yellow
    Write-Host ""
}

function Invoke-ACLAdditional {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Status "Starting Additional ACL Modifications" -Level Success
    Write-Host ""
    
    $PrimaryDC = $Environment.PrimaryDC
    $ModuleConfig = $Config.Module22_ACLAdditional
    
    $errorCount = 0
    
    Write-Section "ACL Modifications on $($ModuleConfig.OU)"
    
    try {
        $OU = Get-ADOrganizationalUnit -LDAPFilter "(&(objectClass=OrganizationalUnit)(OU=$($ModuleConfig.OU)))" -ErrorAction Stop
        Write-Status "Found OU: $($OU.DistinguishedName)" -Level Info
        
        $EveryoneSID = [System.Security.Principal.SecurityIdentifier]'S-1-1-0'
        
        # Add Deny ACE for DeleteChild and DeleteTree
        Write-Host "  Adding Deny ACE for DeleteChild,DeleteTree..." -ForegroundColor Cyan
        $objACL = Get-ACL "AD:\$($OU.DistinguishedName)"
        $objACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
            $EveryoneSID,
            "DeleteChild,DeleteTree",
            "Deny",
            'None',
            [guid]'00000000-0000-0000-0000-000000000000'
        )
        $objACL.AddAccessRule($objACE)
        Set-Acl -AclObject $objACL "AD:\$($OU.DistinguishedName)"
        Start-Sleep -Seconds 5
        Write-Status "Added Deny ACE" -Level Success
        
        # Remove the Deny ACE
        Write-Host "  Removing Deny ACE for DeleteChild,DeleteTree..." -ForegroundColor Cyan
        $objACL = Get-ACL "AD:\$($OU.DistinguishedName)"
        $objACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
            $EveryoneSID,
            "DeleteChild,DeleteTree",
            "Deny",
            'None',
            [guid]'00000000-0000-0000-0000-000000000000'
        )
        $objACL.RemoveAccessRule($objACE)
        Set-Acl -AclObject $objACL "AD:\$($OU.DistinguishedName)"
        Start-Sleep -Seconds 5
        Write-Status "Removed Deny ACE" -Level Success
        
        # Add Allow ACE for DeleteChild and DeleteTree
        Write-Host "  Adding Allow ACE for DeleteChild,DeleteTree..." -ForegroundColor Cyan
        $objACL = Get-ACL "AD:\$($OU.DistinguishedName)"
        $objACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
            $EveryoneSID,
            "DeleteChild,DeleteTree",
            "Allow",
            'None',
            [guid]'00000000-0000-0000-0000-000000000000'
        )
        $objACL.AddAccessRule($objACE)
        Set-Acl -AclObject $objACL "AD:\$($OU.DistinguishedName)"
        Start-Sleep -Seconds 5
        Write-Status "Added Allow ACE" -Level Success
        
        # Force replication
        Write-Host "  Forcing replication..." -ForegroundColor Yellow
        repadmin.exe /syncall /force $PrimaryDC | Out-Null
        Start-Sleep -Seconds 1
        
        # Remove Allow DeleteTree
        Write-Host "  Removing Allow ACE for DeleteTree..." -ForegroundColor Cyan
        $objACL = Get-ACL "AD:\$($OU.DistinguishedName)"
        $objACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
            $EveryoneSID,
            "DeleteTree",
            "Allow",
            'None',
            [guid]'00000000-0000-0000-0000-000000000000'
        )
        $objACL.RemoveAccessRule($objACE)
        Set-Acl -AclObject $objACL "AD:\$($OU.DistinguishedName)"
        Start-Sleep -Seconds 5
        Write-Status "Removed Allow DeleteTree" -Level Success
        
        # Remove Allow DeleteChild
        Write-Host "  Removing Allow ACE for DeleteChild..." -ForegroundColor Cyan
        $objACL = Get-ACL "AD:\$($OU.DistinguishedName)"
        $objACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
            $EveryoneSID,
            "DeleteChild",
            "Allow",
            'None',
            [guid]'00000000-0000-0000-0000-000000000000'
        )
        $objACL.RemoveAccessRule($objACE)
        Set-Acl -AclObject $objACL "AD:\$($OU.DistinguishedName)"
        Start-Sleep -Seconds 2
        Write-Status "Removed Allow DeleteChild" -Level Success
    }
    catch {
        Write-Status "Error: $_" -Level Error
        $errorCount++
    }
    
    Write-Host ""
    if ($errorCount -eq 0) {
        Write-Status "Additional ACL Modifications completed successfully" -Level Success
    }
    else {
        Write-Status "Additional ACL Modifications completed with $errorCount error(s)" -Level Warning
    }
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-ACLAdditional