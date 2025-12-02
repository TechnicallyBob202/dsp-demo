################################################################################
##
## DSP-Demo-01-Setup-BuildOUs.psm1
##
## Creates all organizational unit (OU) structure for the demo environment.
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

function Invoke-BuildOUs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Environment
    )
    
    $domainDN = $Environment.DomainInfo.DN
    
    if (-not $domainDN) {
        Write-Error "Domain DN is empty"
        return $false
    }
    
    Write-Host ""
    Write-Host "Creating OU hierarchy at: $domainDN" -ForegroundColor Cyan
    Write-Host ""
    
    try {
        # Create all OUs from config
        foreach ($ouKey in $Config.OUs.Keys) {
            $ouDef = $Config.OUs[$ouKey]
            $ouName = $ouDef.Name
            $ouDesc = $ouDef.Description
            $ouProtect = $ouDef.ProtectFromAccidentalDeletion
            
            # Create top-level OU
            $ouDN = "OU=$ouName,$domainDN"
            
            Write-Host "  Creating: $ouName" -ForegroundColor Cyan
            
            try {
                $ou = Get-ADOrganizationalUnit -Identity $ouDN -ErrorAction Stop
                Write-Host "    Already exists" -ForegroundColor Green
            }
            catch {
                Write-Host "    Creating new OU..." -ForegroundColor Yellow
                New-ADOrganizationalUnit -Name $ouName -Path $domainDN -Description $ouDesc -ProtectedFromAccidentalDeletion $ouProtect -ErrorAction Stop
                Write-Host "    Created" -ForegroundColor Green
            }
            
            # Create child OUs if defined
            if ($ouDef.ContainsKey('Children') -and $ouDef.Children) {
                foreach ($childKey in $ouDef.Children.Keys) {
                    $childDef = $ouDef.Children[$childKey]
                    $childName = $childDef.Name
                    $childDesc = $childDef.Description
                    $childProtect = $childDef.ProtectFromAccidentalDeletion
                    
                    $childDN = "OU=$childName,$ouDN"
                    
                    Write-Host "    Creating child: $childName" -ForegroundColor Cyan
                    
                    try {
                        $child = Get-ADOrganizationalUnit -Identity $childDN -ErrorAction Stop
                        Write-Host "      Already exists" -ForegroundColor Green
                    }
                    catch {
                        Write-Host "      Creating new child OU..." -ForegroundColor Yellow
                        New-ADOrganizationalUnit -Name $childName -Path $ouDN -Description $childDesc -ProtectedFromAccidentalDeletion $childProtect -ErrorAction Stop
                        Write-Host "      Created" -ForegroundColor Green
                    }
                }
            }
        }
        
        Write-Host ""
        Write-Host "OU hierarchy created successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to create OUs: $($_.Exception.Message)"
        Write-Error "Stack: $($_.Exception.StackTrace)"
        return $false
    }
}

Export-ModuleMember -Function Invoke-BuildOUs