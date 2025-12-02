################################################################################
##
## DSP-Demo-Activity-16-DNSCreate.psm1
##
## Create DNS zones and records
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

function Invoke-DNSCreate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Status "Starting DNSCreate" -Level Success
    Write-Host ""
    
    $DomainInfo = $Environment.DomainInfo
    $domainDN = $DomainInfo.DN
    
    $errorCount = 0
    
    # ============================================================================
    # IMPLEMENTATION
    # ============================================================================
    
    Write-Section "PHASE 1: Create DNS zones and records"
    
    # TODO: Create reverse zones (10, 172, 168.192)
# TODO: Create forward zone specialsite.lab
# TODO: Set Notify properties
# TODO: Create 8 A records (mylabhost01-08)
# TODO: Create PTR records
# TODO: Create CNAME
    
    # ============================================================================
    # COMPLETION
    # ============================================================================
    
    Write-Host ""
    if ($errorCount -eq 0) {
        Write-Status "DNSCreate completed successfully" -Level Success
    }
    else {
        Write-Status "DNSCreate completed with $errorCount error(s)" -Level Warning
    }
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-DNSCreate
