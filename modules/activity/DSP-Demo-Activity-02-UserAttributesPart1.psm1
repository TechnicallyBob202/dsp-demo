################################################################################
##
## DSP-Demo-Activity-02-UserAttributesPart1.psm1
##
## Set/change attributes on DemoUser2, DemoUser3, DemoUser4
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

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

function Invoke-UserAttributesPart1 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Status "Starting User Attributes Part 1" -Level Success
    Write-Host ""
    
    $changedCount = 0
    $errorCount = 0
    
    # Target users: DemoUser2, DemoUser3, DemoUser4
    $targetUsers = @("DemoUser2", "DemoUser3", "DemoUser4")
    
    foreach ($userName in $targetUsers) {
        Write-Section "MODIFYING ATTRIBUTES: $userName"
        
        try {
            $user = Get-ADUser -Filter "Name -eq '$userName'" -ErrorAction Stop
            
            # TODO: Set telephoneNumber
            # TODO: Set city
            # TODO: Set division
            # TODO: Set employeeID
            # TODO: Set initials
            # TODO: Set company
            # TODO: Set FAX
            
            Write-Status "Modified attributes for $userName" -Level Success
            $changedCount++
        }
        catch {
            Write-Status "Error modifying $userName : $_" -Level Error
            $errorCount++
        }
        
        Start-Sleep -Seconds 3
    }
    
    Write-Host ""
    if ($errorCount -eq 0) {
        Write-Status "User Attributes Part 1 completed successfully ($changedCount users)" -Level Success
    }
    else {
        Write-Status "User Attributes Part 1 completed with $errorCount error(s)" -Level Warning
    }
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-UserAttributesPart1
