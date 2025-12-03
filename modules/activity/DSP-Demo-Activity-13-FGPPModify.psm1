################################################################################
##
## DSP-Demo-Activity-13-FGPPModify.psm1
##
## Modify existing FGPP settings to demonstrate changes
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

function Invoke-FGPPModify {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Status "Starting FGPPModify" -Level Success
    Write-Host ""
    
    $errorCount = 0
    
    # ============================================================================
    # IMPLEMENTATION
    # ============================================================================
    
    Write-Section "PHASE 1: Modify SpecialAccounts_PSO FGPP settings"
    
    $psoName = 'SpecialAccounts_PSO'
    
    try {
        # Get the existing FGPP
        $fgppObj = Get-ADFineGrainedPasswordPolicy -Filter "Name -eq '$psoName'" -ErrorAction Stop
        
        if ($fgppObj) {
            Write-Status "Found FGPP: $psoName" -Level Info
            Write-Host ""
            
            # First modification: Disable complexity
            Write-Status "Modification 1: Setting ComplexityEnabled to False" -Level Info
            Set-ADFineGrainedPasswordPolicy -Identity $fgppObj -ComplexityEnabled $false -ErrorAction Stop
            Write-Status "Modification 1 complete" -Level Success
            
            Write-Host ""
            Write-Status "Waiting 15 seconds before next modification..." -Level Info
            Start-Sleep 15
            
            # Second modification: Re-enable complexity and change description
            Write-Status "Modification 2: Setting ComplexityEnabled to True and updating description" -Level Info
            Set-ADFineGrainedPasswordPolicy -Identity $fgppObj `
                -ComplexityEnabled $true `
                -Description 'FGPP with modified FGPP Values' `
                -ErrorAction Stop
            Write-Status "Modification 2 complete" -Level Success
            
            Write-Host ""
            Write-Status "Waiting 15 seconds before final modification..." -Level Info
            Start-Sleep 15
            
            # Third modification: Restore original description
            Write-Status "Modification 3: Restoring original description" -Level Info
            Set-ADFineGrainedPasswordPolicy -Identity $fgppObj `
                -ComplexityEnabled $true `
                -Description 'Account Lockout policy for special accounts' `
                -ErrorAction Stop
            Write-Status "Modification 3 complete" -Level Success
        }
        else {
            Write-Status "ERROR: FGPP '$psoName' not found" -Level Error
            $errorCount++
        }
    }
    catch {
        Write-Status "Error modifying FGPP: $_" -Level Error
        $errorCount++
    }
    
    # ============================================================================
    # COMPLETION
    # ============================================================================
    
    Write-Host ""
    if ($errorCount -eq 0) {
        Write-Status "FGPPModify completed successfully" -Level Success
    }
    else {
        Write-Status "FGPPModify completed with $errorCount error(s)" -Level Warning
    }
    Write-Host ""
    return ($errorCount -eq 0)
}

Export-ModuleMember -Function Invoke-FGPPModify