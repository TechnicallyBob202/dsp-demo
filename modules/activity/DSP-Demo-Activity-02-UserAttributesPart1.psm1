################################################################################
##
## DSP-Demo-Activity-02-UserAttributesPart1.psm1
##
## Set/change attributes on demo users (lskywalker, peter.griffin, pmccartney)
## Config-driven approach - all values come from Module02_UserAttributesP1
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

function Write-ActivityHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host ("+--" + ("-" * 62) + "--+") -ForegroundColor Cyan
    Write-Host ("| " + $Title.PadRight(62) + " |") -ForegroundColor Cyan
    Write-Host ("+--" + ("-" * 62) + "--+") -ForegroundColor Cyan
    Write-Host ""
}

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

function Invoke-UserAttributesPart1 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Environment
    )
    
    Write-ActivityHeader "User Attributes - Part 1"
    
    $modifiedCount = 0
    $notFoundCount = 0
    $errorCount = 0
    
    # Get users list from config Module02_UserAttributesP1
    if (-not $Config.Module02_UserAttributesP1 -or -not $Config.Module02_UserAttributesP1.Users) {
        Write-Status "No users found in Module02_UserAttributesP1 config" -Level Warning
        Write-Host ""
        return $false
    }
    
    $usersList = $Config.Module02_UserAttributesP1.Users
    
    # Ensure usersList is an array
    if ($usersList -isnot [array]) {
        $usersList = @($usersList)
    }
    
    Write-Status "Processing $($usersList.Count) user(s)" -Level Info
    Write-Host ""
    
    foreach ($userConfig in $usersList) {
        $samAccountName = $userConfig.SamAccountName
        
        try {
            # Find the user in AD
            $adUser = Get-ADUser -Identity $samAccountName -ErrorAction Stop
            
            Write-Status "Modifying: $samAccountName ($($adUser.Name))" -Level Info
            
            # Apply each attribute from config
            if ($userConfig.Attributes -and $userConfig.Attributes -is [hashtable]) {
                $attributeCount = 0
                
                foreach ($attrName in $userConfig.Attributes.Keys) {
                    $attrValue = $userConfig.Attributes[$attrName]
                    
                    try {
                        # Map attribute names to Set-ADUser parameters
                        $setParams = @{
                            Identity = $adUser
                            ErrorAction = 'Stop'
                        }
                        
                        switch ($attrName) {
                            'telephoneNumber' { $setParams['OfficePhone'] = $attrValue }
                            'City' { $setParams['City'] = $attrValue }
                            'Division' { $setParams['Division'] = $attrValue }
                            'EmployeeID' { $setParams['EmployeeID'] = $attrValue }
                            'Office' { $setParams['Office'] = $attrValue }
                            'Department' { $setParams['Department'] = $attrValue }
                            'Title' { $setParams['Title'] = $attrValue }
                            'Company' { $setParams['Company'] = $attrValue }
                            'Description' { $setParams['Description'] = $attrValue }
                            'Fax' { $setParams['Fax'] = $attrValue }
                            default { 
                                $setParams['Replace'] = @{$attrName = $attrValue}
                            }
                        }
                        
                        Set-ADUser @setParams
                        Write-Status "  Set $attrName = '$attrValue'" -Level Success
                        $attributeCount++
                    }
                    catch {
                        Write-Status "  Error setting $attrName : $_" -Level Error
                        $errorCount++
                    }
                }
                
                if ($attributeCount -gt 0) {
                    $modifiedCount++
                }
                
                Start-Sleep -Milliseconds 500
            }
            else {
                Write-Status "  No attributes defined for $samAccountName" -Level Warning
            }
        }
        catch {
            Write-Status "User not found: $samAccountName" -Level Warning
            $notFoundCount++
        }
    }
    
    # Summary
    Write-Host ""
    Write-Status "Modified: $modifiedCount, Not Found: $notFoundCount, Errors: $errorCount" -Level Info
    
    if ($errorCount -eq 0 -and $notFoundCount -eq 0) {
        Write-Status "User Attributes Part 1 completed successfully" -Level Success
    }
    else {
        Write-Status "User Attributes Part 1 completed with issues" -Level Warning
    }
    
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-UserAttributesPart1