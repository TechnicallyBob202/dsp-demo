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
        # Bad OU name - REQUIRED from config
        $badOUName = $Config.Module04_ACLBadOUPart1.OU
        
        if (-not $badOUName) {
            Write-Status "ERROR: OU not configured in Module04_ACLBadOUPart1" -Level Error
            Write-Host ""
            return $false
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
    # PHASE 2: Add/Remove ACL entries from config
    # ============================================================================
    
    Write-Section "PHASE 2: Setting ACL permissions from config"
    
    # Get modifications from config - REQUIRED
    $modifications = $Config.Module04_ACLBadOUPart1.Modifications
    if (-not $modifications -or $modifications.Count -eq 0) {
        Write-Status "ERROR: Modifications not configured in Module04_ACLBadOUPart1" -Level Error
        Write-Host ""
        return $false
    }
    
    try {
        $ouPath = "AD:\$($badOU.DistinguishedName)"
        $ouACL = Get-Acl -Path $ouPath -ErrorAction Stop
        
        foreach ($mod in $modifications) {
            $principal = $mod.Identity
            $action = $mod.Action
            $rights = $mod.Rights
            
            Write-Status "Processing: Principal=$principal, Action=$action, Rights=$rights" -Level Info
            
            # Convert principal name to SID
            try {
                $ntAccount = New-Object System.Security.Principal.NTAccount($principal)
                $sid = $ntAccount.Translate([System.Security.Principal.SecurityIdentifier])
            }
            catch {
                Write-Status "Error translating principal $principal : $_" -Level Error
                $errorCount++
                continue
            }
            
            # Create ACE based on action
            $aceAction = if ($action -eq "Add") { "Allow" } else { "Deny" }
            
            $ace = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
                $sid,
                [System.DirectoryServices.ActiveDirectoryRights]$rights,
                [System.Security.AccessControl.AccessControlType]$aceAction,
                [System.DirectoryServices.ActiveDirectorySecurityInheritance]"None",
                [guid]'00000000-0000-0000-0000-000000000000'
            )
            
            $ouACL.AddAccessRule($ace)
            Write-Status "Added ACE: $principal - $rights ($aceAction)" -Level Success
            $changedCount++
        }
        
        Set-Acl -Path $ouPath -AclObject $ouACL -ErrorAction Stop
        Start-Sleep -Seconds 2
    }
    catch {
        Write-Status "Error setting ACL: $_" -Level Error
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