################################################################################
##
## DSP-Demo-Activity-23-OUDeleteMe.psm1
##
## Disable protection and delete the DeleteMe OU structure
##
## Original Author: Rob Ingenthron (robi@semperis.com)
## Refactored By: Bob Lyons
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

function Invoke-OUDeleteMe {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Status "Starting DeleteMe OU Deletion" -Level Success
    Write-Host ""
    
    $DomainInfo = $Environment.DomainInfo
    $ModuleConfig = $Config.Module23_OUDeleteMe
    
    $errorCount = 0
    
    Write-Section "Delete OU Structure"
    
    try {
        # Try exact match first, then case-insensitive search
        $OU = Get-ADOrganizationalUnit -LDAPFilter "(name=$($ModuleConfig.OUPath))" -ErrorAction SilentlyContinue
        
        if ($OU) {
            Write-Host "  Found OU: $($OU.DistinguishedName)" -ForegroundColor Cyan
            
            if ($ModuleConfig.DisableProtection) {
                Write-Host "  Disabling accidental deletion protection..." -ForegroundColor Yellow
                Set-ADOrganizationalUnit -Identity $OU.DistinguishedName -ProtectedFromAccidentalDeletion $false
                Start-Sleep -Seconds 5
                Write-Status "Protection disabled" -Level Success
            }
            
            if ($ModuleConfig.DeleteOUStructure) {
                Write-Host "  Deleting OU structure..." -ForegroundColor Yellow
                Remove-ADOrganizationalUnit -Identity $OU.DistinguishedName -Recursive -Confirm:$false -ErrorAction SilentlyContinue
                Write-Status "OU deleted" -Level Success
            }
        }
        else {
            Write-Status "OU not found: $($ModuleConfig.OUPath)" -Level Warning
            $errorCount++
        }
    }
    catch {
        Write-Status "Error: $_" -Level Error
        $errorCount++
    }
    
    Write-Host ""
    if ($errorCount -eq 0) {
        Write-Status "DeleteMe OU Deletion completed successfully" -Level Success
    }
    else {
        Write-Status "DeleteMe OU Deletion completed with $errorCount error(s)" -Level Warning
    }
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-OUDeleteMe