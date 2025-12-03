################################################################################
##
## DSP-Demo-Activity-24-GPOLinkBadOU.psm1
##
## Link GPO to Bad OU
##
## Original Author: Rob Ingenthron (robi@semperis.com)
## Refactored By: Bob Lyons
##
################################################################################

#Requires -Version 5.1
#Requires -Modules GroupPolicy, ActiveDirectory

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

function Invoke-GPOLinkBadOU {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Status "Starting GPO Link to Bad OU" -Level Success
    Write-Host ""
    
    $DomainInfo = $Environment.DomainInfo
    $DomainDNSRoot = $DomainInfo.DNSRoot
    $ModuleConfig = $Config.Module24_GPOLinkBadOU
    
    $errorCount = 0
    
    Write-Section "Link $($ModuleConfig.GpoName) to $($ModuleConfig.TargetOU)"
    
    try {
        $OU = Get-ADOrganizationalUnit -LDAPFilter "(&(objectClass=OrganizationalUnit)(OU=$($ModuleConfig.TargetOU)))" -ErrorAction Stop
        Write-Status "Found OU: $($OU.DistinguishedName)" -Level Info
        
        $GPO = Get-GPO -Name $ModuleConfig.GpoName -Domain $DomainDNSRoot -ErrorAction SilentlyContinue
        
        if ($GPO) {
            Write-Host "  Found GPO: $($GPO.DisplayName)" -ForegroundColor Cyan
            
            # Remove existing link if present
            Write-Host "  Removing existing GPLink if present..." -ForegroundColor Yellow
            Remove-GPLink -Name $ModuleConfig.GpoName -Target $OU.DistinguishedName -Domain $DomainDNSRoot -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 7
            
            # Add new link
            Write-Host "  Adding GPLink..." -ForegroundColor Cyan
            New-GPLink -Name $ModuleConfig.GpoName -Target $OU.DistinguishedName -LinkEnabled Yes -Domain $DomainDNSRoot
            Start-Sleep -Seconds 5
            Write-Status "GPLink created" -Level Success
        }
        else {
            Write-Status "GPO not found: $($ModuleConfig.GpoName)" -Level Warning
            $errorCount++
        }
    }
    catch {
        Write-Status "Error: $_" -Level Error
        $errorCount++
    }
    
    Write-Host ""
    if ($errorCount -eq 0) {
        Write-Status "GPO Link to Bad OU completed successfully" -Level Success
    }
    else {
        Write-Status "GPO Link to Bad OU completed with $errorCount error(s)" -Level Warning
    }
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-GPOLinkBadOU