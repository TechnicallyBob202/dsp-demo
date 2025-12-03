################################################################################
##
## DSP-Demo-Activity-30-DSPTriggerGroup.psm1
##
## Remove all members from group (triggers DSP undo rule)
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

function Invoke-DSPTriggerGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Host "========== DSP: Trigger Undo Rule - Group Membership ==========" -ForegroundColor Cyan
    Write-Host ""
    
    $ModuleConfig = $Config.Module30_DSPTriggerGroup
    $errorCount = 0
    
    Write-Host "NOTE: This requires an existing DSP auto-undo rule for group membership changes" -ForegroundColor Yellow
    Write-Host ""
    
    try {
        $GroupName = $ModuleConfig.GroupName
        
        Write-Host "Finding group: $GroupName..." -ForegroundColor Yellow
        $GroupObj = Get-ADGroup -LDAPFilter "(&(objectCategory=group)(cn=$GroupName))" -ErrorAction Stop
        
        if (-not $GroupObj) {
            Write-Host "ERROR: Group $GroupName not found" -ForegroundColor Red
            $errorCount++
        }
        else {
            Write-Host "Found: $($GroupObj.DistinguishedName)" -ForegroundColor Green
            Write-Host ""
            
            Write-Host "Retrieving group members..." -ForegroundColor Yellow
            $Members = Get-ADGroupMember -Identity $GroupObj.DistinguishedName -ErrorAction Stop
            
            if ($Members.Count -eq 0) {
                Write-Host "Group is already empty" -ForegroundColor Green
            }
            else {
                Write-Host "Found $($Members.Count) member(s)" -ForegroundColor Cyan
                Write-Host "Removing all members..." -ForegroundColor Yellow
                Write-Host ""
                
                $Members | ForEach-Object {
                    Write-Host "  Removing: $($_.Name)" -ForegroundColor Yellow
                    Remove-ADGroupMember -Identity $GroupObj.DistinguishedName -Member $_ -Confirm:$false -ErrorAction Stop
                }
                
                Write-Host ""
                Write-Host "✓ All members removed" -ForegroundColor Green
                Write-Host "  (This change should trigger DSP auto-undo rule)" -ForegroundColor Cyan
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
        Write-Host "========== DSPTriggerGroup completed successfully ==========" -ForegroundColor Green
    }
    else {
        Write-Host "========== DSPTriggerGroup completed with $errorCount error(s) ==========" -ForegroundColor Yellow
    }
    Write-Host ""
    
    return ($errorCount -eq 0)
}

Export-ModuleMember -Function Invoke-DSPTriggerGroup