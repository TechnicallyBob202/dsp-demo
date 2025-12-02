################################################################################
##
## DSP-Demo-08-Setup-CreateDNSZones.psm1
##
## Creates or configures DNS zones for the demo environment.
##
################################################################################

#Requires -Version 5.1
#Requires -Modules DnsServer

function Invoke-CreateDNSZones {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Environment
    )
    
    Write-Host ""
    Write-Host "Creating DNS Zones" -ForegroundColor Cyan
    Write-Host ""
    
    $dnsServer = if ($Environment.PrimaryDC) { $Environment.PrimaryDC } else { "localhost" }
    $createdCount = 0
    $skippedCount = 0
    
    # Create forward zones if configured
    if ($Config.ContainsKey('DnsForwardZones') -and $Config.DnsForwardZones) {
        Write-Host "  Processing Forward Zones..." -ForegroundColor Cyan
        
        foreach ($zoneName in $Config.DnsForwardZones.Keys) {
            $zoneConfig = $Config.DnsForwardZones[$zoneName]
            
            try {
                $existing = Get-DnsServerZone -ComputerName $dnsServer -Name $zoneName -ErrorAction Stop
                Write-Host "    $zoneName - already exists" -ForegroundColor Green
                $skippedCount++
            }
            catch {
                try {
                    $params = @{
                        ComputerName = $dnsServer
                        Name = $zoneName
                        DynamicUpdate = 'NonsecureAndSecure'
                        ReplicationScope = 'Forest'
                        ErrorAction = 'Stop'
                    }
                    
                    Add-DnsServerPrimaryZone @params
                    Write-Host "    $zoneName - created" -ForegroundColor Green
                    $createdCount++
                    Start-Sleep -Seconds 1
                }
                catch {
                    Write-Host "    $zoneName - ERROR: $_" -ForegroundColor Red
                }
            }
        }
    }
    
    Write-Host ""
    
    # Create reverse zones if configured
    if ($Config.ContainsKey('DnsReverseZones') -and $Config.DnsReverseZones) {
        Write-Host "  Processing Reverse Zones..." -ForegroundColor Cyan
        
        foreach ($zoneName in $Config.DnsReverseZones.Keys) {
            $zoneConfig = $Config.DnsReverseZones[$zoneName]
            
            try {
                $existing = Get-DnsServerZone -ComputerName $dnsServer -Name $zoneName -ErrorAction Stop
                if ($existing.IsReverseLookupZone) {
                    Write-Host "    $zoneName - already exists" -ForegroundColor Green
                    $skippedCount++
                }
                else {
                    Write-Host "    $zoneName - ERROR: Zone exists but is not reverse lookup zone" -ForegroundColor Red
                }
            }
            catch {
                try {
                    $params = @{
                        ComputerName = $dnsServer
                        Name = $zoneName
                        DynamicUpdate = 'NonsecureAndSecure'
                        ReplicationScope = 'Forest'
                        ErrorAction = 'Stop'
                    }
                    
                    Add-DnsServerPrimaryZone @params
                    Write-Host "    $zoneName - created" -ForegroundColor Green
                    $createdCount++
                    Start-Sleep -Seconds 1
                }
                catch {
                    Write-Host "    $zoneName - ERROR: $_" -ForegroundColor Red
                }
            }
        }
    }
    
    Write-Host ""
    Write-Host "DNS Zones: Created $createdCount, Skipped $skippedCount" -ForegroundColor Green
    Write-Host ""
    
    return $true
}

Export-ModuleMember -Function Invoke-CreateDNSZones