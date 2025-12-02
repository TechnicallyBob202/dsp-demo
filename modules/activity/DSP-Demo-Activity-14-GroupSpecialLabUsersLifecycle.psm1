################################################################################
##
## DSP-Demo-Activity-14-GroupSpecialLabUsersLifecycle.psm1
##
## 6-step group lifecycle: DELETE/CREATE/MODIFY/MOVE
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

function Invoke-GroupSpecialLabUsersLifecycle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Status "Starting GroupSpecialLabUsersLifecycle" -Level Success
    Write-Host ""
    
    $DomainInfo = $Environment.DomainInfo
    $domainDN = $DomainInfo.DN
    
    $errorCount = 0
    
    # ============================================================================
    # IMPLEMENTATION
    # ============================================================================
    
    Write-Section "PHASE 1: 6-step group lifecycle: DELETE/CREATE/MODIFY/MOVE"
    
    # TODO: DELETE Special Lab Users group
# TODO: Replicate + wait
# TODO: CREATE in Lab Users OU (Security/Global)
# TODO: Replicate + wait
# TODO: CHANGE category Security->Distribution
# TODO: Wait
# TODO: CHANGE scope Global->Universal
# TODO: Wait
# TODO: MOVE from Lab Users to Lab Admins OU
# TODO: Wait + replicate
# TODO: ADD member App Admin III
    
    # ============================================================================
    # COMPLETION
    # ============================================================================
    
    Write-Host ""
    if ($errorCount -eq 0) {
        Write-Status "GroupSpecialLabUsersLifecycle completed successfully" -Level Success
    }
    else {
        Write-Status "GroupSpecialLabUsersLifecycle completed with $errorCount error(s)" -Level Warning
    }
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-GroupSpecialLabUsersLifecycle
