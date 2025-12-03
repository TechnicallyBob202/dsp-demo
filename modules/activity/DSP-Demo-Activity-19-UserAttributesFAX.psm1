################################################################################
##
## DSP-Demo-Activity-19-UserAttributesPart2.psm1
##
## Change FAX attribute on demo users
##
## Original code from Rob Ingenthron's Invoke-CreateDspChangeDataForDemos.ps1
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

function Invoke-UserAttributesPart2 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Host "========== Directory: User Attributes Part 2 ==========" -ForegroundColor Cyan
    Write-Host ""
    
    $DomainInfo = $Environment.DomainInfo
    
    $errorCount = 0
    $changeCount = 0
    
    # Get user information from config - looking for Module19_UserAttributesPart2
    $users = @()
    if ($Config.ContainsKey('Module19_UserAttributesPart2') -and $Config.Module19_UserAttributesPart2.ContainsKey('Users')) {
        $users = $Config.Module19_UserAttributesPart2.Users
    }
    
    if ($users.Count -eq 0) {
        Write-Host "WARNING: No users configured in Module19_UserAttributesPart2" -ForegroundColor Yellow
        Write-Host ""
        return $true
    }
    
    # Change FAX on each configured user
    foreach ($userConfig in $users) {
        $samAccountName = $userConfig.SamAccountName
        
        Write-Host ""
        Write-Host "========== Changing FAX on $samAccountName ==========" -ForegroundColor Yellow
        Write-Host ""
        
        try {
            $userObj = Get-ADUser -Filter { sAMAccountName -eq $samAccountName } `
                -Properties facsimileTelephoneNumber `
                -ErrorAction Stop
            
            if ($userObj) {
                Write-Host "User found: $($userObj.Name)" -ForegroundColor White
                Write-Host "  Current FAX: $($userObj.facsimileTelephoneNumber)" -ForegroundColor White
                
                # Get new FAX from config
                $newFax = $userConfig.Attributes.Fax
                
                Write-Host "  New FAX: $newFax" -ForegroundColor White
                Write-Host ""
                
                Set-ADUser -Identity $userObj.DistinguishedName `
                    -Fax $newFax `
                    -ErrorAction Stop
                
                Write-Host "  - FAX updated" -ForegroundColor Green
                $changeCount++
                
                # Verify the change
                Start-Sleep -Seconds 1
                $verifyObj = Get-ADUser -Identity $userObj.DistinguishedName `
                    -Properties facsimileTelephoneNumber `
                    -ErrorAction SilentlyContinue
                
                Write-Host "  Verified FAX: $($verifyObj.facsimileTelephoneNumber)" -ForegroundColor Green
                Write-Host ""
                
                Write-Host "  Pausing 3 seconds..." -ForegroundColor Yellow
                Start-Sleep -Seconds 3
            }
            else {
                Write-Host "ERROR: User $samAccountName not found" -ForegroundColor Red
                $errorCount++
            }
        }
        catch {
            Write-Host "ERROR: $_" -ForegroundColor Red
            $errorCount++
        }
    }
    
    Write-Host ""
    Write-Host "Forcing replication..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
    
    try {
        $primaryDC = $Environment.PrimaryDC
        if (-not $primaryDC) {
            $primaryDC = "localhost"
        }
        
        $replResult = & C:\Windows\System32\repadmin.exe /syncall /force $primaryDC 2>&1
        if ($replResult -join "-" | Select-String "syncall finished") {
            Write-Host "  - replication synced" -ForegroundColor Green
        }
    }
    catch { }
    
    $secondaryDC = $Environment.SecondaryDC
    if ($secondaryDC) {
        & C:\Windows\System32\repadmin.exe /syncall /force $secondaryDC 2>&1 | Out-Null
    }
    
    # ========================================================================
    # COMPLETION
    # ========================================================================
    
    Write-Host ""
    Write-Host "========== Directory: User Attributes Part 2 Complete ==========" -ForegroundColor Cyan
    Write-Host "  Changes: $changeCount" -ForegroundColor Green
    if ($errorCount -gt 0) {
        Write-Host "  Errors: $errorCount" -ForegroundColor Red
    }
    Write-Host ""
    
    return ($errorCount -eq 0)
}

Export-ModuleMember -Function Invoke-UserAttributesPart2