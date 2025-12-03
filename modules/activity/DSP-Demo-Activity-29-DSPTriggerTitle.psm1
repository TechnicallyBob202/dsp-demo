################################################################################
##
## DSP-Demo-Activity-29-DSPTriggerTitle.psm1
##
## Trigger DSP undo rule - Title change
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

function Invoke-DSPTriggerTitle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Status "Starting DSPTriggerUndoTitle" -Level Success
    Write-Host ""
    
    $DomainInfo = $Environment.DomainInfo
    $ModuleConfig = $Config.Module29_DSPTriggerTitle
    $domainDN = $DomainInfo.DN
    
    $errorCount = 0
    
    # ============================================================================
    # IMPLEMENTATION
    # ============================================================================
    
    Write-Section "PHASE 1: Trigger DSP undo rule - Title change"
    
    # TODO: Get DemoUser3
# TODO: Change Title attribute
# TODO: Should trigger DSP undo rule
    
    # ============================================================================
    # COMPLETION
    # ============================================================================
    
    Write-Host ""
    if ($errorCount -eq 0) {
        Write-Status "DSPTriggerUndoTitle completed successfully" -Level Success
    }
    else {
        Write-Status "DSPTriggerUndoTitle completed with $errorCount error(s)" -Level Warning
    }
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-DSPTriggerTitle

