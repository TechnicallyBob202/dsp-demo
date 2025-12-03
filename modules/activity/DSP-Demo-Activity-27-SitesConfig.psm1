################################################################################
##
## DSP-Demo-Activity-27-SitesConfig.psm1
##
## Modify site replication settings (DEFAULTIPSITELINK)
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

function Invoke-SitesConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Host "========== Sites: Configuration Changes ==========" -ForegroundColor Cyan
    Write-Host ""
    
    $ModuleConfig = $Config.Module27_SitesConfig
    $errorCount = 0
    
    try {
        Write-Host "Retrieving DEFAULTIPSITELINK..." -ForegroundColor Yellow
        $SiteLink = Get-ADReplicationSiteLink -Identity "DEFAULTIPSITELINK" -ErrorAction Stop
        
        Write-Host "Current settings:" -ForegroundColor Green
        Write-Host "  Cost: $($SiteLink.Cost)" -ForegroundColor Cyan
        Write-Host "  ReplicationFrequencyInMinutes: $($SiteLink.ReplicationFrequencyInMinutes)" -ForegroundColor Cyan
        Write-Host ""
        
        Write-Host "Updating Cost to $($ModuleConfig.ReplicationFrequencyChanges.NewCost)..." -ForegroundColor Yellow
        Set-ADReplicationSiteLink -Identity "DEFAULTIPSITELINK" -Cost $ModuleConfig.ReplicationFrequencyChanges.NewCost -ErrorAction Stop
        
        Write-Host "Updating ReplicationFrequencyInMinutes to $($ModuleConfig.ReplicationFrequencyChanges.NewFrequency)..." -ForegroundColor Yellow
        Set-ADReplicationSiteLink -Identity "DEFAULTIPSITELINK" -ReplicationFrequencyInMinutes $ModuleConfig.ReplicationFrequencyChanges.NewFrequency -ErrorAction Stop
        
        Write-Host ""
        Write-Host "Verifying changes..." -ForegroundColor Green
        $UpdatedSiteLink = Get-ADReplicationSiteLink -Identity "DEFAULTIPSITELINK" -ErrorAction Stop
        Write-Host "  Cost: $($UpdatedSiteLink.Cost)" -ForegroundColor Cyan
        Write-Host "  ReplicationFrequencyInMinutes: $($UpdatedSiteLink.ReplicationFrequencyInMinutes)" -ForegroundColor Cyan
    }
    catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        $errorCount++
    }
    
    Write-Host ""
    if ($errorCount -eq 0) {
        Write-Host "========== SitesConfig completed successfully ==========" -ForegroundColor Green
    }
    else {
        Write-Host "========== SitesConfig completed with $errorCount error(s) ==========" -ForegroundColor Yellow
    }
    Write-Host ""
    
    return ($errorCount -eq 0)
}

Export-ModuleMember -Function Invoke-SitesConfig