################################################################################
##
## DSP-Demo-Activity-21-DNSRecordModify.psm1
##
## Modify and delete existing DNS records
##
## Original Author: Rob Ingenthron (robi@semperis.com)
## Refactored By: Bob Lyons
##
################################################################################

#Requires -Version 5.1
#Requires -Modules DnsServer

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

function Invoke-DNSRecordModify {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Status "Starting DNS Record Modifications" -Level Success
    Write-Host ""
    
    $DomainInfo = $Environment.DomainInfo
    $DomainDC = $DomainInfo.DomainController
    $ModuleConfig = $Config.Module21_DNSRecordModify
    
    $errorCount = 0
    
    # ============================================================================
    # MODIFY RECORDS
    # ============================================================================
    
    Write-Section "Modify Existing DNS Records"
    
    foreach ($record in $ModuleConfig.RecordModifications) {
        try {
            $oldRecord = Get-DnsServerResourceRecord -ComputerName $DomainDC -ZoneName $record.Zone -Name $record.Name -RRType A -ErrorAction SilentlyContinue
            
            if ($oldRecord) {
                Write-Host "  Modifying: $($record.Name) in $($record.Zone)" -ForegroundColor Cyan
                Remove-DnsServerResourceRecord -ComputerName $DomainDC -ZoneName $record.Zone -Name $record.Name -RRType A -RecordData $oldRecord.RecordData[0].IPv4Address -Confirm:$false -Force
                Start-Sleep -Seconds 1
                Add-DnsServerResourceRecordA -ComputerName $DomainDC -ZoneName $record.Zone -Name $record.Name -IPv4Address $record.NewIPAddress
                Write-Status "Modified: $($record.Name)" -Level Success
            }
            else {
                Write-Status "Record not found: $($record.Name)" -Level Warning
                $errorCount++
            }
        }
        catch {
            Write-Status "Error: $_" -Level Error
            $errorCount++
        }
        Start-Sleep -Seconds 1
    }
    
    # ============================================================================
    # DELETE RECORDS
    # ============================================================================
    
    Write-Section "Delete DNS Records"
    
    foreach ($record in $ModuleConfig.RecordsToDelete) {
        try {
            $dnsRecord = Get-DnsServerResourceRecord -ComputerName $DomainDC -ZoneName $record.Zone -Name $record.Name -RRType A -ErrorAction SilentlyContinue
            
            if ($dnsRecord) {
                Write-Host "  Deleting: $($record.Name) from $($record.Zone)" -ForegroundColor Yellow
                Remove-DnsServerResourceRecord -ComputerName $DomainDC -ZoneName $record.Zone -Name $record.Name -RRType A -RecordData $dnsRecord.RecordData[0].IPv4Address -Confirm:$false -Force
                Write-Status "Deleted: $($record.Name)" -Level Success
            }
            else {
                Write-Status "Record not found: $($record.Name)" -Level Warning
                $errorCount++
            }
        }
        catch {
            Write-Status "Error: $_" -Level Error
            $errorCount++
        }
        Start-Sleep -Seconds 1
    }
    
    # ============================================================================
    # COMPLETION
    # ============================================================================
    
    Write-Host ""
    if ($errorCount -eq 0) {
        Write-Status "DNS Record Modifications completed successfully" -Level Success
    }
    else {
        Write-Status "DNS Record Modifications completed with $errorCount error(s)" -Level Warning
    }
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-DNSRecordModify
