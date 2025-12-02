################################################################################
##
## DSP-Demo-Activity-23-OUDeleteMe.psm1
##
## Delete DeleteMe OU structure
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

function Invoke-OUDeleteMe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Status "Starting OUDeleteMe" -Level Success
    Write-Host ""
    
    $DomainInfo = $Environment.DomainInfo
    $domainDN = $DomainInfo.DN
    
    $errorCount = 0
    
    # ============================================================================
    # IMPLEMENTATION
    # ============================================================================
    
    Write-Section "PHASE 1: Delete DeleteMe OU structure"
    
    # TODO: Disable protection on DeleteMe OU
# TODO: Delete OU structure
    
    # ============================================================================
    # COMPLETION
    # ============================================================================
    
    Write-Host ""
    if ($errorCount -eq 0) {
        Write-Status "OUDeleteMe completed successfully" -Level Success
    }
    else {
        Write-Status "OUDeleteMe completed with $errorCount error(s)" -Level Warning
    }
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-OUDeleteMe
