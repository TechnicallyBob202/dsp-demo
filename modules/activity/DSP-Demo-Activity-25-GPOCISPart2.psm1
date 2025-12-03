################################################################################
##
## DSP-Demo-Activity-25-GPOCISPart2.psm1
##
## Additional CIS Benchmark Windows Server Policy GPO modifications
##
## Original Author: Rob Ingenthron (robi@semperis.com)
## Refactored By: Bob Lyons
##
################################################################################

#Requires -Version 5.1
#Requires -Modules GroupPolicy

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

function Invoke-GPOCISPart2 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Status "Starting CIS Benchmark GPO Part 2 Modifications" -Level Success
    Write-Host ""
    
    $DomainInfo = $Environment.DomainInfo
    $DomainDNSRoot = $DomainInfo.DNSRoot
    $ModuleConfig = $Config.Module25_GPOCISPart2
    
    $errorCount = 0
    
    Write-Section "Modify $($ModuleConfig.GpoName)"
    
    try {
        $GPO = Get-GPO -Name $ModuleConfig.GpoName -Domain $DomainDNSRoot -ErrorAction SilentlyContinue
        
        if ($GPO) {
            Write-Status "Found GPO: $($GPO.DisplayName)" -Level Info
            
            if ($ModuleConfig.Modifications.AuditAccountLogon) {
                Write-Host "  Setting Audit Account Logon: $($ModuleConfig.Modifications.AuditAccountLogon)" -ForegroundColor Cyan
                Set-GPRegistryValue -Name $ModuleConfig.GpoName -Key "HKLM\System\CurrentControlSet\Control\Lsa" -ValueName "AuditBaseObjects" -Value 1 -Type DWord | Out-Null
                Write-Status "Updated Audit Account Logon" -Level Success
                Start-Sleep -Seconds 3
            }
            
            if ($ModuleConfig.Modifications.AuditObjectAccess) {
                Write-Host "  Setting Audit Object Access: $($ModuleConfig.Modifications.AuditObjectAccess)" -ForegroundColor Cyan
                Set-GPRegistryValue -Name $ModuleConfig.GpoName -Key "HKLM\System\CurrentControlSet\Services\EventLog\Security" -ValueName "Retention" -Value 0 -Type DWord | Out-Null
                Write-Status "Updated Audit Object Access" -Level Success
                Start-Sleep -Seconds 3
            }
        }
        else {
            Write-Status "GPO not found: $($ModuleConfig.GpoName)" -Level Warning
            $errorCount++
        }
    }
    catch {
        Write-Status "Error: $_" -Level Error
        $errorCount++
    }
    
    Write-Host ""
    if ($errorCount -eq 0) {
        Write-Status "CIS Benchmark GPO Part 2 Modifications completed successfully" -Level Success
    }
    else {
        Write-Status "CIS Benchmark GPO Part 2 Modifications completed with $errorCount error(s)" -Level Warning
    }
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-GPOCISPart2