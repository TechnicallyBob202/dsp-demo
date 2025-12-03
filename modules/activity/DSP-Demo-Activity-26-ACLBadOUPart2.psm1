################################################################################
##
## DSP-Demo-Activity-26-ACLBadOUPart2.psm1
##
## Add DeleteChild,DeleteTree permissions to Bad OU for Everyone
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

function Invoke-ACLBadOUPart2 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Host "========== ACL: Bad OU Part 2 ==========" -ForegroundColor Cyan
    Write-Host ""
    
    $ModuleConfig = $Config.Module26_ACLBadOUPart2
    $errorCount = 0
    
    try {
        $BadOU = Get-ADOrganizationalUnit -LDAPFilter "(&(objectClass=OrganizationalUnit)(name=$($ModuleConfig.OU)))" -ErrorAction Stop
        
        Write-Host "Found OU: $($BadOU.DistinguishedName)" -ForegroundColor Green
        
        # Get current ACL
        $objACL = Get-ACL "AD:\$($BadOU.DistinguishedName)"
        
        # Create access rule for Everyone to allow DeleteChild and DeleteTree
        $GroupSID = [System.Security.Principal.SecurityIdentifier]'S-1-1-0'
        $objACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
            $GroupSID,
            "DeleteChild,DeleteTree",
            "Allow",
            'None',
            [guid]'00000000-0000-0000-0000-000000000000'
        )
        
        Write-Host "Adding DeleteChild,DeleteTree permissions for Everyone..." -ForegroundColor Yellow
        $objACL.AddAccessRule($objACE)
        Set-ACL -AclObject $objACL "AD:\$($BadOU.DistinguishedName)" -ErrorAction Stop
        
        Write-Host "ACL updated successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        $errorCount++
    }
    
    Write-Host ""
    if ($errorCount -eq 0) {
        Write-Host "========== ACLBadOUPart2 completed successfully ==========" -ForegroundColor Green
    }
    else {
        Write-Host "========== ACLBadOUPart2 completed with $errorCount error(s) ==========" -ForegroundColor Yellow
    }
    Write-Host ""
    
    return ($errorCount -eq 0)
}

Export-ModuleMember -Function Invoke-ACLBadOUPart2