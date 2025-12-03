################################################################################
##
## DSP-Demo-Activity-19-UserAttributesPart2.psm1
##
## Change FAX attribute on demo users 1, 2, 3
##
## Original code from Rob Ingenthron's Invoke-CreateDspChangeDataForDemos.ps1
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

function Invoke-UserAttributesFAX {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Host "========== Directory: User Attributes Part 2 ==========" -ForegroundColor Cyan
    Write-Host ""
    
    $errorCount = 0
    $changeCount = 0
    
    # Get demo user information from config
    $demoUsers = @()
    if ($Config.ContainsKey('DemoUsers')) {
        $demoUsers = $Config.DemoUsers
    }
    
    if ($demoUsers.Count -lt 3) {
        Write-Host "WARNING: Expected 3 demo users in config, found $($demoUsers.Count)" -ForegroundColor Yellow
    }
    
    # Change FAX on each of the first 3 demo users
    for ($i = 0; $i -lt [Math]::Min(3, $demoUsers.Count); $i++) {
        $userIndex = $i + 1
        $demoUser = $demoUsers[$i]
        $samAccountName = $demoUser.SamAccountName
        
        Write-Host ""
        Write-Host "========== Changing FAX on DemoUser$userIndex ($samAccountName) ==========" -ForegroundColor Yellow
        Write-Host ""
        
        try {
            $userObj = Get-ADUser -Filter { sAMAccountName -eq $samAccountName } `
                -Properties facsimileTelephoneNumber `
                -ErrorAction Stop
            
            if ($userObj) {
                Write-Host "User found: $($userObj.Name)" -ForegroundColor White
                Write-Host "  Current FAX: $($userObj.facsimileTelephoneNumber)" -ForegroundColor White
                
                # Alternate FAX numbers to show change
                $newFax = "(555) 867-$($([string]$i).PadLeft(4, "0"))"
                
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

Export-ModuleMember -Function Invoke-UserAttributesFAX