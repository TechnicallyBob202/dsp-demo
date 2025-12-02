################################################################################
##
## DSP-Demo-Activity-02-UserAttributesPart1.psm1
##
## Set/change attributes on DemoUser2, DemoUser3, DemoUser4
## Mirrors original script pattern with config-driven values
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
    $skippedCount = 0
    $errorCount = 0
    
    # Get DemoUsers from config - we're modifying users 2, 3, 4 (indices 1, 2, 3)
    if (-not $Config.Users.DemoUsers) {
        Write-Status "No DemoUsers found in config" -Level Warning
        return $false
    }
    
    # Convert from .psd1 format (array of Name/Value pairs) to hashtables if needed
    $demoUsers = @()
    foreach ($user in $Config.Users.DemoUsers) {
        if ($user -is [hashtable]) {
            $demoUsers += $user
        } else {
            # Convert Name/Value pairs to hashtable
            $ht = @{}
            foreach ($item in $user) {
                $ht[$item.Name] = $item.Value
            }
            $demoUsers += $ht
        }
    }
    
    if ($demoUsers.Count -lt 4) {
        Write-Status "Expected 4 DemoUsers, found $($demoUsers.Count)" -Level Warning
    }
    
    # Process DemoUser2 (index 1)
    if ($demoUsers.Count -gt 1) {
        $user2 = $demoUsers[1]
        Write-Status "Modifying attributes for $($user2.Name) ($($user2.SamAccountName))" -Level Info
        
        try {
            $userObj = Get-ADUser -Filter "SamAccountName -eq '$($user2.SamAccountName)'" -Properties telephoneNumber -ErrorAction SilentlyContinue
            
            if ($userObj) {
                Write-Status "Found user: $($userObj.Name)" -Level Success
                
                # Check current phone number
                $currentPhone = $userObj.telephoneNumber
                if ($currentPhone -ne $user2.TelephoneNumber) {
                    Write-Host ":: Set 'telephoneNumber' for user '$($userObj.Name)' to '$($user2.TelephoneNumber)'..." -ForegroundColor Yellow
                    Set-ADUser -Identity $userObj -OfficePhone $user2.TelephoneNumber
                    Start-Sleep -Milliseconds 500
                }
                
                Write-Status "Forcing replication (15 second pause)..." -Level Info
                Start-Sleep -Seconds 15
                
                # Set multiple attributes
                Write-Host ":: Setting more attributes on user '$($userObj.Name)' to simulate HR changes..." -ForegroundColor Yellow
                Write-Host ":: (pausing 5 seconds before setting more attributes)"
                Start-Sleep -Seconds 5
                Write-Host ""
                
                Write-Host ":: Set 'telephoneNumber' for user '$($userObj.Name)' to '$($user2.TelephoneNumberAlt)'..." -ForegroundColor Yellow
                Set-ADUser -Identity $userObj -OfficePhone $user2.TelephoneNumberAlt -Verbose -ErrorAction Stop
                Start-Sleep -Milliseconds 500
                
                Write-Host ":: Set 'city' for user '$($userObj.Name)' to '$($user2.City)'..." -ForegroundColor Yellow
                Set-ADUser -Identity $userObj -City $user2.City -Verbose -ErrorAction Stop
                Start-Sleep -Milliseconds 500
                
                Write-Host ":: Set 'division' for user '$($userObj.Name)' to '$($user2.Division)'..." -ForegroundColor Yellow
                Set-ADUser -Identity $userObj -Division $user2.Division -Verbose -ErrorAction Stop
                Start-Sleep -Milliseconds 500
                
                Write-Host ":: Set 'employeeID' for user '$($userObj.Name)' to '$($user2.EmployeeID)'..." -ForegroundColor Yellow
                Set-ADUser -Identity $userObj -EmployeeID $user2.EmployeeID -Verbose -ErrorAction Stop
                Start-Sleep -Milliseconds 500
                
                Write-Host ":: Set 'initials' for user '$($userObj.Name)' to '$($user2.Initials)'..." -ForegroundColor Yellow
                Set-ADUser -Identity $userObj -Initials $user2.Initials -Verbose -ErrorAction Stop
                Start-Sleep -Milliseconds 500
                
                Write-Host ":: Set 'company' for user '$($userObj.Name)' to '$($user2.Company)'..." -ForegroundColor Yellow
                Set-ADUser -Identity $userObj -Company $user2.Company -Verbose -ErrorAction Stop
                Start-Sleep -Milliseconds 500
                
                Write-Host ":: Set 'FAX' for user '$($userObj.Name)' to '$($user2.FAX)'..." -ForegroundColor Yellow
                Set-ADUser -Identity $userObj -Fax $user2.FAX -Verbose -ErrorAction Stop
                Start-Sleep -Milliseconds 500
                
                Write-Status "Modified: $($user2.Name)" -Level Success
                $modifiedCount++
            }
            else {
                Write-Status "User not found: $($user2.SamAccountName)" -Level Warning
                $skippedCount++
            }
        }
        catch {
            Write-Status "Error modifying $($user2.Name): $_" -Level Error
            $errorCount++
        }
    }
    
    # Process DemoUser3 (index 2)
    if ($demoUsers.Count -gt 2) {
        Write-Host ""
        $user3 = $demoUsers[2]
        Write-Status "Modifying attributes for $($user3.Name) ($($user3.SamAccountName))" -Level Info
        
        try {
            $userObj = Get-ADUser -Filter "SamAccountName -eq '$($user3.SamAccountName)'" -Properties telephoneNumber -ErrorAction SilentlyContinue
            
            if ($userObj) {
                Write-Status "Found user: $($userObj.Name)" -Level Success
                
                # Check current phone number
                $currentPhone = $userObj.telephoneNumber
                if ($currentPhone -ne $user3.TelephoneNumber) {
                    Write-Host ":: Set 'telephoneNumber' for user '$($userObj.Name)' to '$($user3.TelephoneNumber)'..." -ForegroundColor Yellow
                    Set-ADUser -Identity $userObj -OfficePhone $user3.TelephoneNumber
                    Start-Sleep -Milliseconds 500
                }
                
                Write-Status "Forcing replication (15 second pause)..." -Level Info
                Start-Sleep -Seconds 15
                
                # Set multiple attributes
                Write-Host ":: Setting more attributes on user '$($userObj.Name)' to simulate HR changes..." -ForegroundColor Yellow
                Write-Host ":: (pausing 5 seconds before setting more attributes)"
                Start-Sleep -Seconds 5
                Write-Host ""
                
                Write-Host ":: Set 'telephoneNumber' for user '$($userObj.Name)' to '$($user3.TelephoneNumberAlt)'..." -ForegroundColor Yellow
                Set-ADUser -Identity $userObj -OfficePhone $user3.TelephoneNumberAlt -Verbose -ErrorAction Stop
                Start-Sleep -Milliseconds 500
                
                Write-Host ":: Set 'city' for user '$($userObj.Name)' to '$($user3.City)'..." -ForegroundColor Yellow
                Set-ADUser -Identity $userObj -City $user3.City -Verbose -ErrorAction Stop
                Start-Sleep -Milliseconds 500
                
                Write-Host ":: Set 'division' for user '$($userObj.Name)' to '$($user3.Division)'..." -ForegroundColor Yellow
                Set-ADUser -Identity $userObj -Division $user3.Division -Verbose -ErrorAction Stop
                Start-Sleep -Milliseconds 500
                
                Write-Host ":: Set 'employeeID' for user '$($userObj.Name)' to '$($user3.EmployeeID)'..." -ForegroundColor Yellow
                Set-ADUser -Identity $userObj -EmployeeID $user3.EmployeeID -Verbose -ErrorAction Stop
                Start-Sleep -Milliseconds 500
                
                Write-Host ":: Set 'initials' for user '$($userObj.Name)' to '$($user3.Initials)'..." -ForegroundColor Yellow
                Set-ADUser -Identity $userObj -Initials $user3.Initials -Verbose -ErrorAction Stop
                Start-Sleep -Milliseconds 500
                
                Write-Host ":: Set 'company' for user '$($userObj.Name)' to '$($user3.Company)'..." -ForegroundColor Yellow
                Set-ADUser -Identity $userObj -Company $user3.Company -Verbose -ErrorAction Stop
                Start-Sleep -Milliseconds 500
                
                Write-Host ":: Set 'FAX' for user '$($userObj.Name)' to '$($user3.FAX)'..." -ForegroundColor Yellow
                Set-ADUser -Identity $userObj -Fax $user3.FAX -Verbose -ErrorAction Stop
                Start-Sleep -Milliseconds 500
                
                Write-Status "Modified: $($user3.Name)" -Level Success
                $modifiedCount++
            }
            else {
                Write-Status "User not found: $($user3.SamAccountName)" -Level Warning
                $skippedCount++
            }
        }
        catch {
            Write-Status "Error modifying $($user3.Name): $_" -Level Error
            $errorCount++
        }
    }
    
    # Process DemoUser4 (index 3)
    if ($demoUsers.Count -gt 3) {
        Write-Host ""
        $user4 = $demoUsers[3]
        Write-Status "Modifying attributes for $($user4.Name) ($($user4.SamAccountName))" -Level Info
        
        try {
            $userObj = Get-ADUser -Filter "SamAccountName -eq '$($user4.SamAccountName)'" -Properties telephoneNumber -ErrorAction SilentlyContinue
            
            if ($userObj) {
                Write-Status "Found user: $($userObj.Name)" -Level Success
                
                # Check current phone number
                $currentPhone = $userObj.telephoneNumber
                if ($currentPhone -ne $user4.TelephoneNumber) {
                    Write-Host ":: Set 'telephoneNumber' for user '$($userObj.Name)' to '$($user4.TelephoneNumber)'..." -ForegroundColor Yellow
                    Set-ADUser -Identity $userObj -OfficePhone $user4.TelephoneNumber
                    Start-Sleep -Milliseconds 500
                }
                
                Write-Status "Forcing replication (10 second pause)..." -Level Info
                Start-Sleep -Seconds 10
                
                # Set multiple attributes
                Write-Host ":: Setting more attributes on user '$($userObj.Name)' to simulate HR changes..." -ForegroundColor Yellow
                Write-Host ":: (pausing 5 seconds before setting more attributes)"
                Start-Sleep -Seconds 5
                Write-Host ""
                
                Write-Host ":: Set 'telephoneNumber' for user '$($userObj.Name)' to '$($user4.TelephoneNumberAlt)'..." -ForegroundColor Yellow
                Set-ADUser -Identity $userObj -OfficePhone $user4.TelephoneNumberAlt -Verbose -ErrorAction Stop
                Start-Sleep -Milliseconds 500
                
                Write-Host ":: Set 'city' for user '$($userObj.Name)' to '$($user4.City)'..." -ForegroundColor Yellow
                Set-ADUser -Identity $userObj -City $user4.City -Verbose -ErrorAction Stop
                Start-Sleep -Milliseconds 500
                
                Write-Host ":: Set 'division' for user '$($userObj.Name)' to '$($user4.Division)'..." -ForegroundColor Yellow
                Set-ADUser -Identity $userObj -Division $user4.Division -Verbose -ErrorAction Stop
                Start-Sleep -Milliseconds 500
                
                Write-Host ":: Set 'employeeID' for user '$($userObj.Name)' to '$($user4.EmployeeID)'..." -ForegroundColor Yellow
                Set-ADUser -Identity $userObj -EmployeeID $user4.EmployeeID -Verbose -ErrorAction Stop
                Start-Sleep -Milliseconds 500
                
                Write-Host ":: Set 'initials' for user '$($userObj.Name)' to '$($user4.Initials)'..." -ForegroundColor Yellow
                Set-ADUser -Identity $userObj -Initials $user4.Initials -Verbose -ErrorAction Stop
                Start-Sleep -Milliseconds 500
                
                Write-Host ":: Set 'company' for user '$($userObj.Name)' to '$($user4.Company)'..." -ForegroundColor Yellow
                Set-ADUser -Identity $userObj -Company $user4.Company -Verbose -ErrorAction Stop
                Start-Sleep -Milliseconds 500
                
                Write-Host ":: Set 'FAX' for user '$($userObj.Name)' to '$($user4.FAX)'..." -ForegroundColor Yellow
                Set-ADUser -Identity $userObj -Fax $user4.FAX -Verbose -ErrorAction Stop
                Start-Sleep -Milliseconds 500
                
                Write-Status "Modified: $($user4.Name)" -Level Success
                $modifiedCount++
            }
            else {
                Write-Status "User not found: $($user4.SamAccountName)" -Level Warning
                $skippedCount++
            }
        }
        catch {
            Write-Status "Error modifying $($user4.Name): $_" -Level Error
            $errorCount++
        }
    }
    
    # Trigger replication
    Write-Host ""
    Write-Status "Triggering final replication..." -Level Info
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
    Write-Status "Modified: $modifiedCount, Skipped: $skippedCount, Errors: $errorCount" -Level Info
    
    if ($errorCount -eq 0) {
        Write-Status "User Attributes Part 1 completed successfully" -Level Success
    }
    else {
        Write-Status "User Attributes Part 1 completed with $errorCount error(s)" -Level Warning
    }
    
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-UserAttributesPart1