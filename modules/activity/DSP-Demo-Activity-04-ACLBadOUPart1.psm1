################################################################################
##
## DSP-Demo-Activity-04-ACLBadOUPart1.psm1
##
## Modify ACL permissions on "Bad OU"
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

################################################################################
# HELPER FUNCTIONS
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

function Invoke-ACLBadOUPart1 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Environment
    )
    
    Write-ActivityHeader "ACL - Modify Bad OU Permissions (Part 1)"
    
    $modifiedCount = 0
    $errorCount = 0
    
    $domainInfo = $Environment.DomainInfo
    $domainDN = $domainInfo.DN
    
    try {
        # Get Bad OU
        $badOUName = "Bad"
        $badOU = Get-ADOrganizationalUnit -Filter { Name -eq $badOUName } -SearchBase $domainDN -ErrorAction Stop
        
        if (-not $badOU) {
            Write-Status "Bad OU not found" -Level Warning
            Write-Host ""
            return $true
        }
        
        Write-Status "Found Bad OU: $($badOU.DistinguishedName)" -Level Info
        
        # Get the AD path for ACL operations
        $ouPath = "AD:" + $badOU.DistinguishedName
        
        try {
            # Get current ACL
            $acl = Get-Acl -Path $ouPath -ErrorAction Stop
            Write-Status "Retrieved current ACL on Bad OU" -Level Info
            
            # Get current user/admin identity for adding permissions
            $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
            $currentUserName = $currentUser.Name
            
            # Create ACE - grant full control to current user
            $sid = New-Object System.Security.Principal.NTAccount($currentUserName)
            $adRights = [System.DirectoryServices.ActiveDirectoryRights]::GenericAll
            $accessType = [System.Security.AccessControl.AccessControlType]::Allow
            $inheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance]::All
            
            $ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule($sid, $adRights, $accessType, $inheritanceType)
            
            # Add the ACE to the ACL
            $acl.AddAccessRule($ace)
            
            # Set the modified ACL
            Set-Acl -Path $ouPath -AclObject $acl -ErrorAction Stop
            
            Write-Status "Added permission rule for $currentUserName on Bad OU" -Level Success
            $modifiedCount++
            
            Start-Sleep -Milliseconds 500
        }
        catch {
            Write-Status "Error modifying ACL: $_" -Level Error
            $errorCount++
        }
        
        # Trigger replication
        if ($modifiedCount -gt 0) {
            Write-Status "Triggering replication..." -Level Info
            try {
                $dc = $domainInfo.ReplicationPartners[0]
                if ($dc) {
                    Repadmin /syncall $dc /APe | Out-Null
                    Start-Sleep -Seconds 3
                    Write-Status "Replication triggered" -Level Success
                }
            }
            catch {
                Write-Status "Warning: Could not trigger replication: $_" -Level Warning
            }
        }
    }
    catch {
        Write-Status "Fatal error in ACL modification: $_" -Level Error
        $errorCount++
    }
    
    # Summary
    Write-Host ""
    Write-Status "Modified: $modifiedCount, Errors: $errorCount" -Level Info
    
    if ($errorCount -eq 0) {
        Write-Status "ACL Bad OU Part 1 completed successfully" -Level Success
    }
    else {
        Write-Status "ACL Bad OU Part 1 completed with $errorCount error(s)" -Level Warning
    }
    
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-ACLBadOUPart1