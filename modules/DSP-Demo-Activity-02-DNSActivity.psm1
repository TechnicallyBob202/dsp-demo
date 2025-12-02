################################################################################
##
## DSP-Demo-Activity-02-DNSActivity.psm1
##
## DNS activity generation module for DSP demo
## Generates realistic DNS changes: zone modifications, A records, PTR records,
## TTL changes, and DNS zone property modifications
##
################################################################################

#Requires -Version 5.1
#Requires -Modules DnsServer

################################################################################
# LOGGING
################################################################################

function Write-Status {
    param(
        [string]$Message,
        [ValidateSet('Info','Success','Warning','Error')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $colors = @{
        'Info'    = 'White'
        'Success' = 'Green'
        'Warning' = 'Yellow'
        'Error'   = 'Red'
    }
    
    $color = $colors[$Level]
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host ":: $Title" -ForegroundColor DarkRed -BackgroundColor Yellow
    Write-Host ""
}

################################################################################
# PRIVATE HELPERS
################################################################################

function Get-DNSServerForDomain {
    <#
    .SYNOPSIS
    Gets primary DNS server for the domain
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Domain
    )
    
    try {
        $dcInfo = Get-ADDomainController -Discover -Service PrimaryDC -ErrorAction Stop
        return $dcInfo.HostName
    }
    catch {
        Write-Status "Error discovering DNS server: $_" -Level Warning
        return $null
    }
}

function Add-DNSARecord {
    <#
    .SYNOPSIS
    Adds an A record to a DNS zone
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,
        
        [Parameter(Mandatory=$true)]
        [string]$ZoneName,
        
        [Parameter(Mandatory=$true)]
        [string]$RecordName,
        
        [Parameter(Mandatory=$true)]
        [string]$IPv4Address
    )
    
    try {
        # Check if record already exists
        $existing = Get-DnsServerResourceRecord -ComputerName $ComputerName `
                                               -ZoneName $ZoneName `
                                               -Name $RecordName `
                                               -RRType A `
                                               -ErrorAction SilentlyContinue
        
        if ($existing) {
            Write-Status "A record '$RecordName' already exists in zone '$ZoneName'" -Level Info
            return $true
        }
        
        Write-Status "Creating A record '$RecordName' -> $IPv4Address in zone '$ZoneName'" -Level Info
        
        Add-DnsServerResourceRecordA -ComputerName $ComputerName `
                                    -ZoneName $ZoneName `
                                    -Name $RecordName `
                                    -IPv4Address $IPv4Address `
                                    -TimeToLive 3600 `
                                    -ErrorAction Stop
        
        Write-Status "A record created successfully" -Level Success
        return $true
    }
    catch {
        Write-Status "Error creating A record: $_" -Level Warning
        return $false
    }
}

function Set-DNSRecordTTL {
    <#
    .SYNOPSIS
    Modifies TTL on an existing A record
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,
        
        [Parameter(Mandatory=$true)]
        [string]$ZoneName,
        
        [Parameter(Mandatory=$true)]
        [string]$RecordName,
        
        [Parameter(Mandatory=$true)]
        [int]$TTLSeconds
    )
    
    try {
        # Get existing record
        $oldRecord = Get-DnsServerResourceRecord -ComputerName $ComputerName `
                                                -ZoneName $ZoneName `
                                                -Name $RecordName `
                                                -RRType A `
                                                -ErrorAction Stop
        
        Write-Status "Current TTL for '$RecordName': $($oldRecord.TimeToLive.TotalSeconds) seconds" -Level Info
        
        # Clone and modify
        $newRecord = $oldRecord.Clone()
        $newRecord.TimeToLive = [TimeSpan]::FromSeconds($TTLSeconds)
        
        Write-Status "Setting new TTL to $TTLSeconds seconds" -Level Info
        
        Set-DnsServerResourceRecord -ComputerName $ComputerName `
                                   -ZoneName $ZoneName `
                                   -OldInputObject $oldRecord `
                                   -NewInputObject $newRecord `
                                   -ErrorAction Stop
        
        Write-Status "TTL modified successfully" -Level Success
        return $true
    }
    catch {
        Write-Status "Error modifying TTL: $_" -Level Warning
        return $false
    }
}

function Remove-DNSARecord {
    <#
    .SYNOPSIS
    Removes an A record from a DNS zone
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,
        
        [Parameter(Mandatory=$true)]
        [string]$ZoneName,
        
        [Parameter(Mandatory=$true)]
        [string]$RecordName,
        
        [Parameter(Mandatory=$true)]
        [string]$IPv4Address
    )
    
    try {
        # Check if record exists
        $existing = Get-DnsServerResourceRecord -ComputerName $ComputerName `
                                               -ZoneName $ZoneName `
                                               -Name $RecordName `
                                               -RRType A `
                                               -ErrorAction SilentlyContinue
        
        if (-not $existing) {
            Write-Status "A record '$RecordName' does not exist in zone '$ZoneName'" -Level Info
            return $true
        }
        
        Write-Status "Removing A record '$RecordName' ($IPv4Address) from zone '$ZoneName'" -Level Info
        
        Remove-DnsServerResourceRecord -ComputerName $ComputerName `
                                      -ZoneName $ZoneName `
                                      -Name $RecordName `
                                      -RRType A `
                                      -RecordData $IPv4Address `
                                      -Force `
                                      -ErrorAction Stop
        
        Write-Status "A record removed successfully" -Level Success
        return $true
    }
    catch {
        Write-Status "Error removing A record: $_" -Level Warning
        return $false
    }
}

function Set-DNSZoneProperties {
    <#
    .SYNOPSIS
    Modifies DNS zone properties (dynamic updates, notify settings)
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$ComputerName,
        
        [Parameter(Mandatory=$true)]
        [string]$ZoneName,
        
        [Parameter(Mandatory=$false)]
        [string]$DynamicUpdate = "NonsecureAndSecure",
        
        [Parameter(Mandatory=$false)]
        [string]$Notify = "Notify"
    )
    
    try {
        Write-Status "Modifying zone properties for '$ZoneName'" -Level Info
        Write-Status "  DynamicUpdate: $DynamicUpdate" -Level Info
        Write-Status "  Notify: $Notify" -Level Info
        
        Set-DnsServerPrimaryZone -ComputerName $ComputerName `
                                -Name $ZoneName `
                                -DynamicUpdate $DynamicUpdate `
                                -Notify $Notify `
                                -ErrorAction Stop
        
        Write-Status "Zone properties updated successfully" -Level Success
        return $true
    }
    catch {
        Write-Status "Error modifying zone properties: $_" -Level Warning
        return $false
    }
}

################################################################################
# MAIN ACTIVITY FUNCTION
################################################################################

function Invoke-DNSActivity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        $Environment
    )
    
    Write-Host ""
    Write-Status "Starting DNS Activity (activity-02)" -Level Success
    Write-Host ""
    
    $DomainInfo = $Environment.DomainInfo
    $domainFQDN = $DomainInfo.FQDN
    
    # Get DNS server
    $dnsServer = Get-DNSServerForDomain -Domain $domainFQDN
    
    if (-not $dnsServer) {
        Write-Status "Could not determine DNS server for domain" -Level Error
        return $false
    }
    
    Write-Status "Using DNS server: $dnsServer" -Level Info
    
    $activityCount = 0
    $errorCount = 0
    
    # ============================================================================
    # PHASE 1: CREATE A CUSTOM DEMO ZONE
    # ============================================================================
    
    Write-Section "PHASE 1: CREATE CUSTOM DNS ZONE"
    
    $demoZone = "labdemo.local"
    
    try {
        $existing = Get-DnsServerZone -ComputerName $dnsServer `
                                     -Name $demoZone `
                                     -ErrorAction SilentlyContinue
        
        if ($existing) {
            Write-Status "Zone '$demoZone' already exists" -Level Info
        }
        else {
            Write-Status "Creating new DNS zone '$demoZone'" -Level Info
            Add-DnsServerPrimaryZone -ComputerName $dnsServer `
                                    -Name $demoZone `
                                    -ReplicationScope Forest `
                                    -ErrorAction Stop
            Write-Status "Zone created successfully" -Level Success
            $activityCount++
        }
        
        Start-Sleep -Seconds 2
    }
    catch {
        Write-Status "Error in Phase 1: $_" -Level Warning
        $errorCount++
    }
    
    Write-Host ""
    
    # ============================================================================
    # PHASE 2: ADD DNS RECORDS
    # ============================================================================
    
    Write-Section "PHASE 2: ADD DNS A RECORDS"
    
    try {
        # Add multiple A records
        $records = @(
            @{ Name = "web01"; IP = "192.168.1.10" }
            @{ Name = "web02"; IP = "192.168.1.11" }
            @{ Name = "db01"; IP = "192.168.1.20" }
            @{ Name = "app01"; IP = "192.168.1.30" }
        )
        
        foreach ($record in $records) {
            $result = Add-DNSARecord -ComputerName $dnsServer `
                                    -ZoneName $demoZone `
                                    -RecordName $record.Name `
                                    -IPv4Address $record.IP
            
            if ($result) {
                $activityCount++
            }
            else {
                $errorCount++
            }
            
            Start-Sleep -Milliseconds 500
        }
    }
    catch {
        Write-Status "Error in Phase 2: $_" -Level Warning
        $errorCount++
    }
    
    Write-Host ""
    Start-Sleep -Seconds 2
    
    # ============================================================================
    # PHASE 3: MODIFY DNS RECORD TTL
    # ============================================================================
    
    Write-Section "PHASE 3: MODIFY TTL ON DNS RECORDS"
    
    try {
        $ttlModifications = @(
            @{ Name = "web01"; TTL = 7200 }
            @{ Name = "db01"; TTL = 1800 }
        )
        
        foreach ($mod in $ttlModifications) {
            $result = Set-DNSRecordTTL -ComputerName $dnsServer `
                                       -ZoneName $demoZone `
                                       -RecordName $mod.Name `
                                       -TTLSeconds $mod.TTL
            
            if ($result) {
                $activityCount++
            }
            else {
                $errorCount++
            }
            
            Start-Sleep -Seconds 2
        }
    }
    catch {
        Write-Status "Error in Phase 3: $_" -Level Warning
        $errorCount++
    }
    
    Write-Host ""
    Start-Sleep -Seconds 2
    
    # ============================================================================
    # PHASE 4: MODIFY ZONE PROPERTIES
    # ============================================================================
    
    Write-Section "PHASE 4: MODIFY ZONE PROPERTIES"
    
    try {
        # Change zone to allow secure updates
        $result = Set-DNSZoneProperties -ComputerName $dnsServer `
                                        -ZoneName $demoZone `
                                        -DynamicUpdate "Secure" `
                                        -Notify "NoNotify"
        
        if ($result) {
            $activityCount++
        }
        else {
            $errorCount++
        }
        
        Start-Sleep -Seconds 2
        
        # Change back to allow nonsecure updates
        $result = Set-DNSZoneProperties -ComputerName $dnsServer `
                                        -ZoneName $demoZone `
                                        -DynamicUpdate "NonsecureAndSecure" `
                                        -Notify "Notify"
        
        if ($result) {
            $activityCount++
        }
        else {
            $errorCount++
        }
    }
    catch {
        Write-Status "Error in Phase 4: $_" -Level Warning
        $errorCount++
    }
    
    Write-Host ""
    Start-Sleep -Seconds 2
    
    # ============================================================================
    # PHASE 5: REMOVE DNS RECORDS
    # ============================================================================
    
    Write-Section "PHASE 5: REMOVE DNS RECORDS"
    
    try {
        $recordsToRemove = @(
            @{ Name = "app01"; IP = "192.168.1.30" }
        )
        
        foreach ($record in $recordsToRemove) {
            $result = Remove-DNSARecord -ComputerName $dnsServer `
                                       -ZoneName $demoZone `
                                       -RecordName $record.Name `
                                       -IPv4Address $record.IP
            
            if ($result) {
                $activityCount++
            }
            else {
                $errorCount++
            }
            
            Start-Sleep -Milliseconds 500
        }
    }
    catch {
        Write-Status "Error in Phase 5: $_" -Level Warning
        $errorCount++
    }
    
    Write-Host ""
    
    # ============================================================================
    # COMPLETION
    # ============================================================================
    
    Write-Status "DNS Activity completed: $activityCount changes, $errorCount error(s)" -Level Success
    Write-Host ""
    
    return $true
}

################################################################################
# EXPORTS
################################################################################

Export-ModuleMember -Function Invoke-DNSActivity

################################################################################
# END OF MODULE
################################################################################