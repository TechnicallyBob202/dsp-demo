################################################################################
##
## DSP-Demo-Activity-21-DNSModifyDelete.psm1
##
## Modify and delete DNS records
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

function Invoke-DNSModifyDelete {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Status "Starting DNSModifyDelete" -Level Success
    Write-Host ""
    
    $DomainInfo = $Environment.DomainInfo
    $domainDN = $DomainInfo.DN
    
    $errorCount = 0
    
    # ============================================================================
    # IMPLEMENTATION
    # ============================================================================
    
    Write-Section "PHASE 1: Modify and delete DNS records"
    
    # TODO: Modify existing records
# TODO: Delete some records
# TODO: Change TTL values
    
    # ============================================================================
    # COMPLETION
    # ============================================================================
    
    Write-Host ""
    if ($errorCount -eq 0) {
        Write-Status "DNSModifyDelete completed successfully" -Level Success
    }
    else {
        Write-Status "DNSModifyDelete completed with $errorCount error(s)" -Level Warning
    }
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-DNSModifyDelete
