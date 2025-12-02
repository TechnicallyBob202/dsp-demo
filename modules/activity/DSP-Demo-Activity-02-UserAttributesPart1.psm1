################################################################################
##
## DSP-Demo-Activity-02-UserAttributesPart1.psm1
##
## Set/change attributes on DemoUser2, DemoUser3, DemoUser4
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

################################################################################
# HELPER FUNCTIONS
################################################################################

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

################################################################################
# MAIN FUNCTION
################################################################################

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
    
    $targetUsers = @("DemoUser2", "DemoUser3", "DemoUser4")
    
    foreach ($userName in $targetUsers) {
        Write-Status "Modifying attributes for $userName" -Level Info
        
        try {
            $user = Get-ADUser -Filter "SamAccountName -eq '$userName'" -ErrorAction Stop
            
            if (-not $user) {
                Write-Status "User '$userName' not found - skipping" -Level Warning
                continue
            }
            
            # Prepare attribute updates
            $attrParams = @{
                Identity = $user.DistinguishedName
                ErrorAction = 'Stop'
                TelephoneNumber = "555-0$(Get-Random -Minimum 100 -Maximum 999)"
                City = "New York"
                Division = "Engineering"
                EmployeeID = "EMP$(Get-Random -Minimum 10000 -Maximum 99999)"
                Initials = "DU"
                Company = "Semperis"
                Fax = "555-0$(Get-Random -Minimum 100 -Maximum 999)"
            }
            
            Set-ADUser @attrParams
            
            Write-Status "Modified: $userName (telephone, city, division, employeeID, initials, company, FAX)" -Level Success
            $modifiedCount++
            Start-Sleep -Milliseconds 500
        }
        catch {
            Write-Status "Error modifying $userName : $_" -Level Error
            $errorCount++
        }
    }
    
    # Trigger replication
    Write-Host ""
    Write-Status "Triggering replication..." -Level Info
    try {
        $domainInfo = $Environment.DomainInfo
        if ($domainInfo.ReplicationPartners -and $domainInfo.ReplicationPartners.Count -gt 0) {
            $dc = $domainInfo.ReplicationPartners[0]
            Repadmin /syncall $dc /APe | Out-Null
            Start-Sleep -Seconds 3
            Write-Status "Replication triggered" -Level Success
        }
        else {
            Write-Status "No replication partners available" -Level Warning
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
        Write-Status "User Attributes Part 1 completed with $errorCount error(s)" -Level Warning
    }
    
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-UserAttributesPart1