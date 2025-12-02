################################################################################
##
## DSP-Demo-Activity-15-UserAttributesAlternateCreds.psm1
##
## DemoUser1 changes with alternate credentials
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

function Invoke-UserAttributesAlternateCreds {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Status "Starting UserAttributesAlternateCreds" -Level Success
    Write-Host ""
    
    $DomainInfo = $Environment.DomainInfo
    $domainDN = $DomainInfo.DN
    
    $errorCount = 0
    
    # ============================================================================
    # IMPLEMENTATION
    # ============================================================================
    
    Write-Section "PHASE 1: DemoUser1 changes with alternate credentials"
    
    # TODO: Get OpsAdmin1 credentials
# TODO: Change telephoneNumber (as OpsAdmin1)
# TODO: Set info attribute (as OpsAdmin1)
# TODO: Replicate 15 sec
# TODO: Change telephoneNumber again
# TODO: Set city, division, employeeID
# TODO: Set initials, company, FAX (as current admin)
# TODO: Set info attribute again (as OpsAdmin1)
# TODO: Clear info attribute
    
    # ============================================================================
    # COMPLETION
    # ============================================================================
    
    Write-Host ""
    if ($errorCount -eq 0) {
        Write-Status "UserAttributesAlternateCreds completed successfully" -Level Success
    }
    else {
        Write-Status "UserAttributesAlternateCreds completed with $errorCount error(s)" -Level Warning
    }
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-UserAttributesAlternateCreds
