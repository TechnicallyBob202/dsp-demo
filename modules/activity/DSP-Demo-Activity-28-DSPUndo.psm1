################################################################################
##
## DSP-Demo-Activity-28-DSPUndo.psm1
##
## Connect to DSP server and undo facsimileTelephoneNumber changes
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

function Invoke-DSPUndo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Host "========== DSP: Automated Undo ==========" -ForegroundColor Cyan
    Write-Host ""
    
    $ModuleConfig = $Config.Module28_DSPUndo
    $DomainInfo = $Environment.DomainInfo
    $DomainDN = $DomainInfo.DN
    $DomainDNSRoot = $DomainInfo.DNSRoot
    $errorCount = 0
    
    Write-Host "Attempting to load DSP PoSh module..." -ForegroundColor Yellow
    Remove-Module Semperis.PoSh.DSP -ErrorAction SilentlyContinue -Force
    
    try {
        Import-Module Semperis.PoSh.DSP -ErrorAction Stop
    }
    catch {
        Write-Host "WARNING: DSP module not available (OK in demo environments)" -ForegroundColor Yellow
        Write-Host ""
        return $true
    }
    
    Write-Host "OK: DSP module loaded" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Searching for DSP server..." -ForegroundColor Yellow
    $DSPServerName = $null
    
    try {
        $SCPList = Get-ADObject -LDAPFilter "objectClass=serviceConnectionPoint" -SearchBase $DomainDN -ErrorAction Stop
        foreach ($SCPitem in $SCPList) {
            if ($SCPitem.Name.Contains('Semperis.Dsp.Management')) {
                $DSPDN = $SCPitem.DistinguishedName.Split(',')
                $DSPServerName = $DSPDN[1].Substring(3) + '.' + $DomainDNSRoot
                Write-Host "Found DSP server: $DSPServerName" -ForegroundColor Green
                break
            }
        }
    }
    catch {
        Write-Host "Error searching for DSP: $_" -ForegroundColor Yellow
    }
    
    if (-not $DSPServerName) {
        Write-Host "DSP server not found via SCP" -ForegroundColor Yellow
        Write-Host ""
        return $true
    }
    
    Write-Host ""
    
    $DSPServerConnectOption = '-Server'
    try {
        Connect-DSPServer -Server
    }
    catch {
        if ($Error[0].FullyQualifiedErrorId -like "*NamedParameterNotFound*") {
            $DSPServerConnectOption = '-ComputerName'
        }
    }
    
    Write-Host "Connecting to DSP server ($DSPServerConnectOption)..." -ForegroundColor Yellow
    
    $DSPconnection = $null
    $LoopCount = 0
    
    try {
        while ($LoopCount -lt 10) {
            if ($DSPServerConnectOption -eq '-ComputerName') {
                $DSPconnection = Connect-DSPServer -ComputerName $DSPServerName -ErrorAction SilentlyContinue
            }
            else {
                $DSPconnection = Connect-DSPServer -Server $DSPServerName -ErrorAction SilentlyContinue
            }
            
            if ($DSPconnection.ConnectionState) {
                break
            }
            
            Start-Sleep -Seconds 2
            $LoopCount++
        }
        
        if (-not $DSPconnection.ConnectionState) {
            Write-Host "ERROR: Connection failed" -ForegroundColor Red
            $errorCount++
            return ($errorCount -eq 0)
        }
        
        Write-Host "OK: Connected to DSP" -ForegroundColor Green
        Write-Host "  State: $($DSPconnection.ConnectionState)" -ForegroundColor Cyan
        Write-Host ""
        
        $TargetUser = $ModuleConfig.ChangeToUndo.ObjectName
        Write-Host "Finding $TargetUser in AD..." -ForegroundColor Yellow
        $UserObj = Get-ADUser -LDAPFilter "(&(objectCategory=person)(samaccountname=$TargetUser))" -Properties facsimileTelephoneNumber -ErrorAction Stop
        
        if ($UserObj) {
            $ObjectDN = $UserObj.DistinguishedName
            Write-Host "Found: $ObjectDN" -ForegroundColor Green
            Write-Host ""
            
            Write-Host "Searching for facsimileTelephoneNumber changes..." -ForegroundColor Yellow
            $ChangeItem = Get-DSPChangedItem -Domain $DomainDNSRoot -ObjectDN $ObjectDN -Attribute facsimileTelephoneNumber -ErrorAction SilentlyContinue
            
            if ($ChangeItem) {
                Write-Host "Found change, undoing..." -ForegroundColor Yellow
                $UndoStatus = Undo-DSPChangedItem -InputObject $ChangeItem -ForceReplication -Confirm:$false -ErrorAction SilentlyContinue
                
                if ($UndoStatus) {
                    Write-Host "OK: Undo successful" -ForegroundColor Green
                }
                else {
                    Write-Host "WARNING: Undo failed or not found" -ForegroundColor Yellow
                }
            }
            else {
                Write-Host "No facsimileTelephoneNumber changes found for $TargetUser" -ForegroundColor Yellow
            }
        }
        else {
            Write-Host "User $TargetUser not found" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        $errorCount++
    }
    
    Write-Host ""
    if ($errorCount -eq 0) {
        Write-Host "========== DSPUndo completed successfully ==========" -ForegroundColor Green
    }
    else {
        Write-Host "========== DSPUndo completed with $errorCount error(s) ==========" -ForegroundColor Yellow
    }
    Write-Host ""
    
    return ($errorCount -eq 0)
}

Export-ModuleMember -Function Invoke-DSPUndo