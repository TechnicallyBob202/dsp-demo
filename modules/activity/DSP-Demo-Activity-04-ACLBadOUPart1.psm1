################################################################################
##
## DSP-Demo-Activity-04-ACLBadOUPart1.psm1
##
## Modify ACL permissions on Bad OU (Part 1)
## Adds DENY permission for 'Everyone' on DeleteChild and DeleteTree
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

function Write-Status {
    param(
        [string]$Message,
        [ValidateSet('Info','Success','Warning','Error')]
        [string]$Level = 'Info'
    )
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

function Invoke-ACLBadOUPart1 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        $Environment
    )
    
    Write-Host ""
    Write-Status "Starting ACLBadOUPart1" -Level Success
    Write-Host ""
    
    $DomainInfo = $Environment.DomainInfo
    $domainDN = $DomainInfo.DN
    
    $errorCount = 0
    $changedCount = 0
    
    # ============================================================================
    # PHASE 1: Get Bad OU from config and verify it exists
    # ============================================================================
    
    Write-Section "PHASE 1: Deny Everyone DeleteChild and DeleteTree on Bad OU"
    
    try {
        $badOUName = $Config.ActivitySettings.AclActivity.BadOUName
        
        if (-not $badOUName) {
            Write-Status "BadOUName not configured in ActivitySettings.AclActivity" -Level Warning
            Write-Host ""
            return $true
        }
        
        $badOU = Get-ADOrganizationalUnit -Filter "Name -eq '$badOUName'" -SearchBase $domainDN -ErrorAction SilentlyContinue
        
        if (-not $badOU) {
            Write-Status "Bad OU '$badOUName' not found" -Level Warning
            Write-Host ""
            return $true
        }
        
        Write-Status "Found Bad OU: $($badOU.DistinguishedName)" -Level Success
    }
    catch {
        Write-Status "Error finding Bad OU: $_" -Level Error
        $errorCount++
        Write-Host ""
        return $false
    }
    
    # ============================================================================
    # PHASE 2: Add DENY ACE for Everyone on DeleteChild and DeleteTree
    # ============================================================================
    
    Write-Section "PHASE 2: Setting DENY permissions for Everyone"
    
    try {
        $ouPath = "AD:\$($badOU.DistinguishedName)"
        $ouACL = Get-Acl -Path $ouPath -ErrorAction Stop
        
        # Everyone SID
        $everyoneSID = [System.Security.Principal.SecurityIdentifier]'S-1-1-0'
        
        # Create DENY ACE for DeleteChild and DeleteTree
        $denyACE = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
            $everyoneSID,
            [System.DirectoryServices.ActiveDirectoryRights]"DeleteChild,DeleteTree",
            [System.Security.AccessControl.AccessControlType]"Deny",
            [System.DirectoryServices.ActiveDirectorySecurityInheritance]"None",
            [guid]'00000000-0000-0000-0000-000000000000'
        )
        
        $ouACL.AddAccessRule($denyACE)
        Set-Acl -Path $ouPath -AclObject $ouACL -ErrorAction Stop
        
        Write-Status "Added DENY ACE: Everyone cannot DeleteChild or DeleteTree" -Level Success
        $changedCount++
        
        Start-Sleep -Seconds 2
    }
    catch {
        Write-Status "Error setting DENY ACE: $_" -Level Error
        $errorCount++
    }
    
    # ============================================================================
    # COMPLETION
    # ============================================================================
    
    Write-Host ""
    Write-Status "ACLBadOUPart1 - Changed: $changedCount" -Level Success
    
    if ($errorCount -eq 0) {
        Write-Status "ACLBadOUPart1 completed successfully" -Level Success
    }
    else {
        Write-Status "ACLBadOUPart1 completed with $errorCount error(s)" -Level Warning
    }
    
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-ACLBadOUPart1