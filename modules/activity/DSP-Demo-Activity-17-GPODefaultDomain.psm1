################################################################################
##
## DSP-Demo-Activity-17-GPODefaultDomain.psm1
##
## Modify Default Domain Policy settings
##
## Original code from Rob Ingenthron's Invoke-CreateDspChangeDataForDemos.ps1
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory, GroupPolicy

function Invoke-GPODefaultDomain {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Host "========== GPO: Modify Default Domain Policy ==========" -ForegroundColor Cyan
    Write-Host ""
    
    $DomainInfo = $Environment.DomainInfo    
    $domainDNS = $DomainInfo.FQDN
    
    $errorCount = 0
    $changeCount = 0
    
    try {
        Write-Host "Getting current Default Domain Password Policy..." -ForegroundColor Yellow
        $currentPolicy = Get-ADDefaultDomainPasswordPolicy -Identity $domainDNS `
            -ErrorAction Stop
        
        Write-Host "  Current LockoutThreshold: $($currentPolicy.LockoutThreshold)" -ForegroundColor White
        Write-Host ""
        
        Write-Host "Setting LockoutThreshold to 888..." -ForegroundColor Yellow
        Set-ADDefaultDomainPasswordPolicy -Identity $domainDNS `
            -LockoutThreshold 888 `
            -ErrorAction Stop
        
        Write-Host "  - updated" -ForegroundColor Green
        $changeCount++
        
        Write-Host ""
        Write-Host "Pausing 10 seconds for changes to settle..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        
        Write-Host ""
        Write-Host "Verifying updated Default Domain Password Policy..." -ForegroundColor Yellow
        $updatedPolicy = Get-ADDefaultDomainPasswordPolicy -Identity $domainDNS `
            -ErrorAction Stop
        
        Write-Host "  New LockoutThreshold: $($updatedPolicy.LockoutThreshold)" -ForegroundColor Green
        Write-Host ""
    }
    catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        $errorCount++
    }
    
    # ========================================================================
    # COMPLETION
    # ========================================================================
    
    Write-Host ""
    Write-Host "========== GPO: Modify Default Domain Policy Complete ==========" -ForegroundColor Cyan
    Write-Host "  Changes: $changeCount" -ForegroundColor Green
    if ($errorCount -gt 0) {
        Write-Host "  Errors: $errorCount" -ForegroundColor Red
    }
    Write-Host ""
    
    return ($errorCount -eq 0)
}

Export-ModuleMember -Function Invoke-GPODefaultDomain