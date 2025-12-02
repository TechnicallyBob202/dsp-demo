################################################################################
##
## DSP-Demo-Activity-03-SubnetsModify.psm1
##
## Change subnet descriptions and locations
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

function Invoke-SubnetsModify {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Status "Starting SubnetsModify" -Level Success
    Write-Host ""
    
    $DomainInfo = $Environment.DomainInfo
    $domainDN = $DomainInfo.DN
    
    $errorCount = 0
    
    # ============================================================================
    # IMPLEMENTATION
    # ============================================================================
    
    Write-Section "PHASE 1: Change subnet descriptions and locations"
    
    # TODO: Get subnets from config
# TODO: Modify description
# TODO: Modify location
    
    # ============================================================================
    # COMPLETION
    # ============================================================================
    
    Write-Host ""
    if ($errorCount -eq 0) {
        Write-Status "SubnetsModify completed successfully" -Level Success
    }
    else {
        Write-Status "SubnetsModify completed with $errorCount error(s)" -Level Warning
    }
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-SubnetsModify
