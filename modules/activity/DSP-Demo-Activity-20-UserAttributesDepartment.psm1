################################################################################
##
## DSP-Demo-Activity-20-UserAttributesDepartment.psm1
##
## Change Department attribute on demo users
##
## Original code from Rob Ingenthron's Invoke-CreateDspChangeDataForDemos.ps1
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

function Invoke-UserAttributesDepartment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Host "========== Directory: User Attributes Part 3 ==========" -ForegroundColor Cyan
    Write-Host ""
    
    $errorCount = 0
    $changeCount = 0
    
    # Get user information from config - looking for Module20_UserAttributesPart3
    $users = @()
    if ($Config.ContainsKey('Module20_UserAttributesPart3') -and $Config.Module20_UserAttributesPart3.ContainsKey('Users')) {
        $users = $Config.Module20_UserAttributesPart3.Users
    }
    
    if ($users.Count -eq 0) {
        Write-Host "WARNING: No users configured in Module20_UserAttributesPart3" -ForegroundColor Yellow
        Write-Host ""
        return $true
    }
    
    # Change Department on each configured user
    foreach ($userConfig in $users) {
        $samAccountName = $userConfig.SamAccountName
        
        Write-Host ""
        Write-Host "========== Changing Department on $samAccountName ==========" -ForegroundColor Yellow
        Write-Host ""
        
        try {
            $userObj = Get-ADUser -Filter { sAMAccountName -eq $samAccountName } `
                -Properties department `
                -ErrorAction Stop
            
            if ($userObj) {
                Write-Host "User found: $($userObj.Name)" -ForegroundColor White
                Write-Host "  Current Department: $($userObj.department)" -ForegroundColor White
                
                # Get new Department from config
                $newDept = $userConfig.Attributes.Department
                
                Write-Host "  New Department: $newDept" -ForegroundColor White
                Write-Host ""
                
                Set-ADUser -Identity $userObj.DistinguishedName `
                    -Department $newDept `
                    -ErrorAction Stop
                
                Write-Host "  - Department updated" -ForegroundColor Green
                $changeCount++
                
                # Verify the change
                Start-Sleep -Seconds 1
                $verifyObj = Get-ADUser -Identity $userObj.DistinguishedName `
                    -Properties department `
                    -ErrorAction SilentlyContinue
                
                Write-Host "  Verified Department: $($verifyObj.department)" -ForegroundColor Green
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
    Write-Host "========== Directory: User Attributes Part 3 Complete ==========" -ForegroundColor Cyan
    Write-Host "  Changes: $changeCount" -ForegroundColor Green
    if ($errorCount -gt 0) {
        Write-Host "  Errors: $errorCount" -ForegroundColor Red
    }
    Write-Host ""
    
    return ($errorCount -eq 0)
}

Export-ModuleMember -Function Invoke-UserAttributesDepartment