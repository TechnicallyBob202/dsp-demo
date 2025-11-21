################################################################################
##
## DSP-Demo-07-Setup-CreateADSitesAndSubnets.psm1
##
## Creates Active Directory Sites and Services objects including sites,
## subnets, and replication links.
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

function Invoke-CreateADSitesAndSubnets {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Environment
    )
    
    Write-Host ""
    Write-Host "Creating AD Sites and Subnets" -ForegroundColor Cyan
    Write-Host ""
    
    $createdCount = 0
    $skippedCount = 0
    
    # Create Sites if configured
    if ($Config.ContainsKey('AdSites') -and $Config.AdSites) {
        Write-Host "  Processing AD Sites..." -ForegroundColor Cyan
        
        foreach ($siteName in $Config.AdSites.Keys) {
            $siteConfig = $Config.AdSites[$siteName]
            
            try {
                $existing = Get-ADReplicationSite -Filter "Name -eq '$siteName'" -ErrorAction Stop
                Write-Host "    $siteName - already exists" -ForegroundColor Green
                $skippedCount++
            }
            catch {
                try {
                    $params = @{
                        Name = $siteName
                        ErrorAction = 'Stop'
                    }
                    
                    if ($siteConfig.Description) {
                        $params.Description = $siteConfig.Description
                    }
                    
                    if ($siteConfig.Location) {
                        $params.OtherAttributes = @{ 'Location' = $siteConfig.Location }
                    }
                    
                    New-ADReplicationSite @params
                    Write-Host "    $siteName - created" -ForegroundColor Green
                    $createdCount++
                    Start-Sleep -Seconds 1
                }
                catch {
                    Write-Host "    $siteName - ERROR: $_" -ForegroundColor Red
                }
            }
        }
    }
    
    Write-Host ""
    
    # Create Subnets if configured
    if ($Config.ContainsKey('AdSubnets') -and $Config.AdSubnets) {
        Write-Host "  Processing AD Subnets..." -ForegroundColor Cyan
        
        foreach ($subnetName in $Config.AdSubnets.Keys) {
            $subnetConfig = $Config.AdSubnets[$subnetName]
            
            if (-not $subnetConfig.Site) {
                Write-Host "    $subnetName - SKIPPED (no Site specified)" -ForegroundColor Yellow
                $skippedCount++
                continue
            }
            
            try {
                $existing = Get-ADReplicationSubnet -Filter "Name -eq '$subnetName'" -ErrorAction Stop
                Write-Host "    $subnetName - already exists" -ForegroundColor Green
                $skippedCount++
            }
            catch {
                try {
                    $params = @{
                        Name = $subnetName
                        Site = $subnetConfig.Site
                        ErrorAction = 'Stop'
                    }
                    
                    if ($subnetConfig.Description) {
                        $params.Description = $subnetConfig.Description
                    }
                    
                    if ($subnetConfig.Location) {
                        $params.Location = $subnetConfig.Location
                    }
                    
                    New-ADReplicationSubnet @params
                    Write-Host "    $subnetName - created" -ForegroundColor Green
                    $createdCount++
                    Start-Sleep -Seconds 1
                }
                catch {
                    Write-Host "    $subnetName - ERROR: $_" -ForegroundColor Red
                }
            }
        }
    }
    
    Write-Host ""
    
    # Create Site Links if configured
    if ($Config.ContainsKey('AdSiteLinks') -and $Config.AdSiteLinks) {
        Write-Host "  Processing AD Site Links..." -ForegroundColor Cyan
        
        foreach ($linkName in $Config.AdSiteLinks.Keys) {
            $linkConfig = $Config.AdSiteLinks[$linkName]
            
            if (-not $linkConfig.Sites -or $linkConfig.Sites.Count -lt 2) {
                Write-Host "    $linkName - SKIPPED (need at least 2 sites)" -ForegroundColor Yellow
                $skippedCount++
                continue
            }
            
            try {
                $existing = Get-ADReplicationSiteLink -Filter "Name -eq '$linkName'" -ErrorAction Stop
                Write-Host "    $linkName - already exists" -ForegroundColor Green
                $skippedCount++
            }
            catch {
                try {
                    $params = @{
                        Name = $linkName
                        SitesIncluded = $linkConfig.Sites
                        Cost = $linkConfig.Cost
                        ReplicationFrequencyInMinutes = $linkConfig.ReplicationFrequencyInMinutes
                        ErrorAction = 'Stop'
                    }
                    
                    if ($linkConfig.Description) {
                        $params.Description = $linkConfig.Description
                    }
                    
                    New-ADReplicationSiteLink @params
                    Write-Host "    $linkName - created" -ForegroundColor Green
                    $createdCount++
                    Start-Sleep -Seconds 1
                }
                catch {
                    Write-Host "    $linkName - ERROR: $_" -ForegroundColor Red
                }
            }
        }
    }
    
    Write-Host ""
    Write-Host "Sites and Subnets: Created $createdCount, Skipped $skippedCount" -ForegroundColor Green
    Write-Host ""
    
    return $true
}

Export-ModuleMember -Function Invoke-CreateADSitesAndSubnets