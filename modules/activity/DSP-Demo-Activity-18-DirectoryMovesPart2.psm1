################################################################################
##
## DSP-Demo-Activity-18-UserMovesPart2.psm1
##
## Move all users from Dept101 to Dept999 (reverse of Module 01)
##
## Original code from Rob Ingenthron's Invoke-CreateDspChangeDataForDemos.ps1
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

function Invoke-UserMovesPart2 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Host "========== Directory: User Moves Part 2 ==========" -ForegroundColor Cyan
    Write-Host ""
    
    # OU names from config
    $dept101Name = "Dept101"
    $dept999Name = "Dept999"
    
    $errorCount = 0
    $moveCount = 0
    
    try {
        Write-Host "Locating source and target OUs..." -ForegroundColor Yellow
        
        $dept101OU = Get-ADOrganizationalUnit -LDAPFilter "(Name=$dept101Name)" `
            -ErrorAction Stop
        $dept999OU = Get-ADOrganizationalUnit -LDAPFilter "(Name=$dept999Name)" `
            -ErrorAction Stop
        
        $dept101DN = $dept101OU.DistinguishedName
        $dept999DN = $dept999OU.DistinguishedName
        
        Write-Host "  Source OU: $dept101DN" -ForegroundColor White
        Write-Host "  Target OU: $dept999DN" -ForegroundColor White
        Write-Host ""
        
        Write-Host "Retrieving enabled users from $dept101Name..." -ForegroundColor Yellow
        $usersToMove = Get-ADUser -Filter { Enabled -eq $true } `
            -SearchBase $dept101DN `
            -ErrorAction Stop
        
        if ($usersToMove.Count -gt 0) {
            Write-Host "  Found $($usersToMove.Count) user(s) to move" -ForegroundColor Green
            Write-Host ""
            
            foreach ($user in $usersToMove) {
                try {
                    Write-Host "  Moving user: $($user.Name)" -ForegroundColor Yellow
                    Write-Host "    -> to: $dept999DN" -ForegroundColor Magenta
                    
                    Move-ADObject -Identity $user.DistinguishedName `
                        -TargetPath $dept999DN `
                        -ErrorAction Stop
                    
                    Write-Host "      - moved" -ForegroundColor Green
                    $moveCount++
                    
                    Start-Sleep -Milliseconds 100
                }
                catch {
                    Write-Host "      - ERROR: $_" -ForegroundColor Red
                    $errorCount++
                }
            }
            
            Write-Host ""
            Write-Host "========================================================" -ForegroundColor Green
            Write-Host "User objects moved from $dept101Name to $dept999Name" -ForegroundColor Green
            Write-Host "Check the Activity graph on the Overview page for impact" -ForegroundColor Green
            Write-Host "========================================================" -ForegroundColor Green
            Write-Host ""
        }
        else {
            Write-Host ""
            Write-Host "========================================================" -ForegroundColor Yellow
            Write-Host "WARNING: No users found in $dept101Name" -ForegroundColor Yellow
            Write-Host "Skipping user moves" -ForegroundColor Yellow
            Write-Host "========================================================" -ForegroundColor Yellow
            Write-Host ""
        }
    }
    catch {
        Write-Host "ERROR: $_" -ForegroundColor Red
        $errorCount++
    }
    
    # ========================================================================
    # COMPLETION
    # ========================================================================
    
    Write-Host ""
    Write-Host "========== Directory: User Moves Part 2 Complete ==========" -ForegroundColor Cyan
    Write-Host "  Moved: $moveCount" -ForegroundColor Green
    if ($errorCount -gt 0) {
        Write-Host "  Errors: $errorCount" -ForegroundColor Red
    }
    Write-Host ""
    
    return ($errorCount -eq 0)
}

Export-ModuleMember -Function Invoke-UserMovesPart2