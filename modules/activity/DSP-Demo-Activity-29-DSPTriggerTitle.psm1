################################################################################
##
## DSP-Demo-Activity-29-DSPTriggerTitle.psm1
##
## Change Title attribute on target user (triggers DSP undo rule)
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

function Invoke-DSPTriggerTitle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Host "========== DSP: Trigger Undo Rule - Title Change ==========" -ForegroundColor Cyan
    Write-Host ""
    
    $ModuleConfig = $Config.Module29_DSPTriggerTitle
    $errorCount = 0
    
    Write-Host "NOTE: This requires an existing DSP auto-undo rule for Title changes" -ForegroundColor Yellow
    Write-Host ""
    
    try {
        $TargetUser = $ModuleConfig.TargetUser
        $NewTitle = $ModuleConfig.NewValue
        
        Write-Host "Finding user: $TargetUser..." -ForegroundColor Yellow
        $UserObj = Get-ADUser -LDAPFilter "(&(objectCategory=person)(samaccountname=$TargetUser))" -Properties Title -ErrorAction Stop
        
        if (-not $UserObj) {
            Write-Host "ERROR: User $TargetUser not found" -ForegroundColor Red
            $errorCount++
        }
        else {
            Write-Host "Found: $($UserObj.DistinguishedName)" -ForegroundColor Green
            $CurrentTitle = $UserObj.Title
            Write-Host "Current Title: $CurrentTitle" -ForegroundColor Cyan
            Write-Host ""
            
            # Only change if different (avoids DSP bug with same value writes)
            if ($CurrentTitle -ne $NewTitle) {
                Write-Host "Changing Title to: $NewTitle" -ForegroundColor Yellow
                Set-ADUser -Identity $UserObj.DistinguishedName -Title $NewTitle -ErrorAction Stop
                Write-Host "OK: Title updated successfully" -ForegroundColor Green
                Write-Host "  (This change should trigger DSP auto-undo rule)" -ForegroundColor Cyan
            }
            else {
                Write-Host "Title is already set to: $NewTitle" -ForegroundColor Green
                Write-Host "  (No change needed)" -ForegroundColor Cyan
            }
            
            Write-Host ""
            Write-Host "Waiting 20 seconds for auto-undo to trigger..." -ForegroundColor Yellow
            Start-Sleep -Seconds 20
        }
    }
    catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        $errorCount++
    }
    
    Write-Host ""
    if ($errorCount -eq 0) {
        Write-Host "========== DSPTriggerTitle completed successfully ==========" -ForegroundColor Green
    }
    else {
        Write-Host "========== DSPTriggerTitle completed with $errorCount error(s) ==========" -ForegroundColor Yellow
    }
    Write-Host ""
    
    return ($errorCount -eq 0)
}

Export-ModuleMember -Function Invoke-DSPTriggerTitle