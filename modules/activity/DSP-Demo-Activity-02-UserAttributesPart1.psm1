################################################################################
##
## DSP-Demo-Activity-02-UserAttributesPart1.psm1
##
## Set/change attributes on users
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
    $errorCount = 0
    
    # Get users to modify - REQUIRED
    $users = $Config.Module02_UserAttributesP1.Users
    if (-not $users -or $users.Count -eq 0) {
        Write-Status "ERROR: Users not configured in Module02_UserAttributesP1" -Level Error
        Write-Host ""
        return $false
    }
    
    Write-Status "Found $($users.Count) user(s) to modify" -Level Info
    Write-Host ""
    
    # Process each user
    foreach ($userConfig in $users) {
        $samAccountName = $userConfig.SamAccountName
        
        try {
            # Find user
            $user = Get-ADUser -Filter { SamAccountName -eq $samAccountName } -ErrorAction SilentlyContinue
            
            if (-not $user) {
                Write-Status "User '$samAccountName' not found" -Level Error
                $errorCount++
                continue
            }
            
            Write-Status "Found user: $($user.Name)" -Level Success
            
            # Apply attributes
            if ($userConfig.Attributes) {
                foreach ($attrName in $userConfig.Attributes.Keys) {
                    $attrValue = $userConfig.Attributes[$attrName]
                    
                    try {
                        # Map attribute names to Set-ADUser parameters
                        $setParams = @{
                            Identity = $user
                            ErrorAction = 'Stop'
                        }
                        
                        switch ($attrName) {
                            'telephoneNumber' { $setParams['OfficePhone'] = $attrValue }
                            'City' { $setParams['City'] = $attrValue }
                            'Division' { $setParams['Division'] = $attrValue }
                            'EmployeeID' { $setParams['EmployeeID'] = $attrValue }
                            'Office' { $setParams['Office'] = $attrValue }
                            'Company' { $setParams['Company'] = $attrValue }
                            'Department' { $setParams['Department'] = $attrValue }
                            'Title' { $setParams['Title'] = $attrValue }
                            'Fax' { $setParams['Fax'] = $attrValue }
                            'MobilePhone' { $setParams['MobilePhone'] = $attrValue }
                            default { 
                                Write-Status "Skipping unknown attribute: $attrName" -Level Warning
                                continue 
                            }
                        }
                        
                        Set-ADUser @setParams
                        Write-Status "  Set $attrName = $attrValue" -Level Info
                        Start-Sleep -Milliseconds 250
                    }
                    catch {
                        Write-Status "Error setting $attrName : $_" -Level Error
                        $errorCount++
                    }
                }
            }
            
            Write-Status "Modified: $($user.Name)" -Level Success
            $modifiedCount++
            Start-Sleep -Seconds 2
        }
        catch {
            Write-Status "Error modifying user $samAccountName : $_" -Level Error
            $errorCount++
        }
    }
    
    # Trigger replication
    Write-Host ""
    Write-Status "Triggering replication..." -Level Info
    try {
        $dc = (Get-ADDomainController -Discover -ErrorAction SilentlyContinue).HostName
        if ($dc) {
            Repadmin /syncall $dc /APe | Out-Null
            Start-Sleep -Seconds 5
            Write-Status "Replication triggered" -Level Success
        }
        else {
            Write-Status "No DC available for replication" -Level Warning
        }
    }
    catch {
        Write-Status "Warning: Could not trigger replication: $_" -Level Warning
    }
    
    # Summary
    Write-Host ""
    Write-Status "Modified: $modifiedCount, Errors: $errorCount" -Level Info
    
    if ($errorCount -eq 0) {
        Write-Status "User Attributes Part 1 completed successfully" -Level Success
    }
    else {
        Write-Status "User Attributes Part 1 completed with $errorCount error(s)" -Level Error
    }
    
    Write-Host ""
    return ($errorCount -eq 0)
}

Export-ModuleMember -Function Invoke-UserAttributesPart1