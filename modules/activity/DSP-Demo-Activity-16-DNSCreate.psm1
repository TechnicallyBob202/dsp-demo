################################################################################
##
## DSP-Demo-Activity-16-DNSCreate.psm1
##
## Create DNS zones and records for demo environment
##
## Original code from Rob Ingenthron's Invoke-CreateDspChangeDataForDemos.ps1
##
################################################################################

#Requires -Version 5.1
#Requires -Modules DnsServer

function Invoke-DNSCreate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Host "========== DNS: Create Zones and Records ==========" -ForegroundColor Cyan
    Write-Host ""
    
    $primaryDC = $Environment.PrimaryDC
    $secondaryDC = $Environment.SecondaryDC
    
    if (-not $primaryDC) {
        $primaryDC = "localhost"
    }
    
    $errorCount = 0
    $createdCount = 0
    
    # ========================================================================
    # CREATE REVERSE ZONES
    # ========================================================================
    
    Write-Host "Creating reverse zones..." -ForegroundColor Yellow
    Write-Host ""
    
    $reverseZones = @(
        @{ Name = "10.in-addr.arpa"; NetworkId = "10.0.0.0/8" }
        @{ Name = "172.in-addr.arpa"; NetworkId = "172.0.0.0/8" }
        @{ Name = "168.192.in-addr.arpa"; NetworkId = "192.168.0.0/16" }
    )
    
    foreach ($zone in $reverseZones) {
        try {
            $existing = Get-DnsServerZone -ComputerName $primaryDC -Name $zone.Name `
                -ErrorAction Stop
            
            if ($existing.IsReverseLookupZone) {
                Write-Host "  $($zone.Name) - already exists" -ForegroundColor Green
            }
        }
        catch {
            try {
                Write-Host "  Creating $($zone.Name)..." -ForegroundColor Yellow
                Add-DnsServerPrimaryZone -ComputerName $primaryDC `
                    -DynamicUpdate NonsecureAndSecure `
                    -NetworkId $zone.NetworkId `
                    -ReplicationScope Forest `
                    -WarningAction Ignore `
                    -ErrorAction Stop | Out-Null
                
                Write-Host "    - created" -ForegroundColor Green
                $createdCount++
                Start-Sleep -Seconds 1
            }
            catch {
                Write-Host "    - ERROR: $_" -ForegroundColor Red
                $errorCount++
            }
        }
    }
    
    Write-Host "  Forcing replication..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    try {
        $replResult = & C:\Windows\System32\repadmin.exe /syncall /force $primaryDC 2>&1
        if ($replResult -join "-" | Select-String "syncall finished") {
            Write-Host "    - replication synced" -ForegroundColor Green
        }
    }
    catch { }
    
    if ($secondaryDC) {
        & C:\Windows\System32\repadmin.exe /syncall /force $secondaryDC 2>&1 | Out-Null
    }
    
    Write-Host ""
    
    # ========================================================================
    # CREATE FORWARD ZONE AND RECORDS
    # ========================================================================
    
    Write-Host "Creating forward zone 'specialsite.lab'..." -ForegroundColor Yellow
    Write-Host ""
    
    $playzone = "specialsite.lab"
    
    # Check if zone exists
    try {
        $zoneExists = Get-DnsServerZone -ComputerName $primaryDC -Name $playzone `
            -ErrorAction Stop
    }
    catch {
        $zoneExists = $null
    }
    
    if (-not $zoneExists) {
        try {
            Write-Host "  Creating zone '$playzone'..." -ForegroundColor Yellow
            Add-DnsServerPrimaryZone -ComputerName $primaryDC `
                -Name $playzone `
                -DynamicUpdate NonsecureAndSecure `
                -ReplicationScope Forest `
                -ErrorAction Stop | Out-Null
            
            Write-Host "    - zone created" -ForegroundColor Green
            
            # Set Notify properties
            Set-DnsServerPrimaryZone -ComputerName $primaryDC -Name $playzone `
                -Notify Notify -ErrorAction SilentlyContinue | Out-Null
            
            Start-Sleep -Seconds 10
            
            try {
                $replResult = & C:\Windows\System32\repadmin.exe /syncall /force $primaryDC 2>&1
                if ($replResult -join "-" | Select-String "syncall finished") {
                    Write-Host "    - replication synced" -ForegroundColor Green
                }
            }
            catch { }
            
            if ($secondaryDC) {
                & C:\Windows\System32\repadmin.exe /syncall /force $secondaryDC 2>&1 | Out-Null
            }
            
            Set-DnsServerPrimaryZone -ComputerName $primaryDC -Name $playzone `
                -Notify NoNotify -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
            Write-Host "    - ERROR creating zone: $_" -ForegroundColor Red
            $errorCount++
        }
    }
    else {
        Write-Host "  Zone '$playzone' already exists, updating settings..." -ForegroundColor Yellow
        
        try {
            Set-DnsServerPrimaryZone -ComputerName $primaryDC `
                -Name $playzone `
                -DynamicUpdate NonsecureAndSecure `
                -ErrorAction SilentlyContinue | Out-Null
            
            Set-DnsServerPrimaryZone -ComputerName $primaryDC -Name $playzone `
                -Notify Notify -ErrorAction SilentlyContinue | Out-Null
            
            Start-Sleep -Seconds 5
            
            try {
                $replResult = & C:\Windows\System32\repadmin.exe /syncall /force $primaryDC 2>&1
                if ($replResult -join "-" | Select-String "syncall finished") {
                    Write-Host "    - replication synced" -ForegroundColor Green
                }
            }
            catch { }
            
            if ($secondaryDC) {
                & C:\Windows\System32\repadmin.exe /syncall /force $secondaryDC 2>&1 | Out-Null
            }
            
            Set-DnsServerPrimaryZone -ComputerName $primaryDC -Name $playzone `
                -Notify NoNotify -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
            Write-Host "    - ERROR updating zone: $_" -ForegroundColor Red
            $errorCount++
        }
    }
    
    Write-Host ""
    Write-Host "Creating DNS A records in '$playzone'..." -ForegroundColor Yellow
    Write-Host ""
    
    # Define A records to create
    $aRecords = @(
        @{ Name = "mylabhost01"; IP = "172.111.10.11" }
        @{ Name = "mylabhost02"; IP = "172.111.10.12" }
        @{ Name = "mylabhost03"; IP = "172.111.10.13" }
        @{ Name = "mylabhost04"; IP = "172.111.10.14" }
        @{ Name = "mylabhost05"; IP = "172.111.10.15" }
        @{ Name = "mylabhost06"; IP = "172.111.10.16" }
        @{ Name = "mylabhost07"; IP = "172.111.10.17" }
        @{ Name = "mylabhost08"; IP = "172.111.10.18" }
    )
    
    foreach ($record in $aRecords) {
        try {
            $existing = Get-DnsServerResourceRecord -ComputerName $primaryDC `
                -Name $record.Name -ZoneName $playzone `
                -ErrorAction SilentlyContinue
            
            if ($existing) {
                Write-Host "  $($record.Name) - already exists" -ForegroundColor Green
            }
            else {
                Write-Host "  Creating $($record.Name) -> $($record.IP)..." -ForegroundColor Yellow
                
                Add-DnsServerResourceRecordA -ComputerName $primaryDC `
                    -Name $record.Name `
                    -ZoneName $playzone `
                    -IPv4Address $record.IP `
                    -TimeToLive (New-TimeSpan -Hours 1) `
                    -CreatePtr `
                    -AgeRecord `
                    -AllowUpdateAny `
                    -WarningAction Ignore `
                    -ErrorAction SilentlyContinue | Out-Null
                
                Write-Host "    - created" -ForegroundColor Green
                $createdCount++
                Start-Sleep -Milliseconds 500
            }
        }
        catch {
            Write-Host "    - ERROR: $_" -ForegroundColor Red
            $errorCount++
        }
    }
    
    # Create PTR records manually (DNS A record creation often fails for PTR)
    Write-Host ""
    Write-Host "Creating DNS PTR records..." -ForegroundColor Yellow
    Write-Host ""
    
    $ptrRecords = @(
        @{ Name = "11.10.111"; Host = "mylabhost01.specialsite.lab" }
        @{ Name = "12.10.111"; Host = "mylabhost02.specialsite.lab" }
        @{ Name = "13.10.111"; Host = "mylabhost03.specialsite.lab" }
        @{ Name = "14.10.111"; Host = "mylabhost04.specialsite.lab" }
        @{ Name = "15.10.111"; Host = "mylabhost05.specialsite.lab" }
        @{ Name = "16.10.111"; Host = "mylabhost06.specialsite.lab" }
        @{ Name = "17.10.111"; Host = "mylabhost07.specialsite.lab" }
        @{ Name = "18.10.111"; Host = "mylabhost08.specialsite.lab" }
    )
    
    $ptrZone = "172.in-addr.arpa"
    
    foreach ($ptr in $ptrRecords) {
        try {
            $existing = Get-DnsServerResourceRecord -ComputerName $primaryDC `
                -Name $ptr.Name -ZoneName $ptrZone -RRType Ptr `
                -ErrorAction SilentlyContinue
            
            if ($existing) {
                Write-Host "  $($ptr.Name) -> $($ptr.Host) - already exists" -ForegroundColor Green
            }
            else {
                Write-Host "  Creating $($ptr.Name) -> $($ptr.Host)..." -ForegroundColor Yellow
                
                Add-DnsServerResourceRecordPtr -ComputerName $primaryDC `
                    -Name $ptr.Name `
                    -ZoneName $ptrZone `
                    -PtrDomainName $ptr.Host `
                    -TimeToLive (New-TimeSpan -Hours 1) `
                    -AllowUpdateAny `
                    -AgeRecord `
                    -WarningAction Ignore `
                    -ErrorAction SilentlyContinue | Out-Null
                
                Write-Host "    - created" -ForegroundColor Green
                $createdCount++
                Start-Sleep -Milliseconds 500
            }
        }
        catch {
            Write-Host "    - ERROR: $_" -ForegroundColor Red
            $errorCount++
        }
    }
    
    Write-Host ""
    Write-Host "Forcing final replication..." -ForegroundColor Yellow
    Start-Sleep -Seconds 5
    
    try {
        $replResult = & C:\Windows\System32\repadmin.exe /syncall /force $primaryDC 2>&1
        if ($replResult -join "-" | Select-String "syncall finished") {
            Write-Host "  - replication synced" -ForegroundColor Green
        }
    }
    catch { }
    
    if ($secondaryDC) {
        & C:\Windows\System32\repadmin.exe /syncall /force $secondaryDC 2>&1 | Out-Null
    }
    
    # ========================================================================
    # COMPLETION
    # ========================================================================
    
    Write-Host ""
    Write-Host "========== DNS: Create Zones and Records Complete ==========" -ForegroundColor Cyan
    Write-Host "  Created: $createdCount" -ForegroundColor Green
    if ($errorCount -gt 0) {
        Write-Host "  Errors: $errorCount" -ForegroundColor Red
    }
    Write-Host ""
    
    return ($errorCount -eq 0)
}

Export-ModuleMember -Function Invoke-DNSCreate