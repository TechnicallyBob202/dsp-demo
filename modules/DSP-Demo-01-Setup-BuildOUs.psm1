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
            
            # Create top-level OU
            $ouDN = "OU=$ouName,$domainDN"
            
            $ou = Get-ADOrganizationalUnit -Identity $ouDN -ErrorAction SilentlyContinue
            if ($ou) {
                Write-Host "  $ouName (already exists)" -ForegroundColor Green
            }
            else {
                New-ADOrganizationalUnit -Name $ouName -Path $domainDN -Description $ouDesc -ProtectedFromAccidentalDeletion $ouDef.ProtectFromAccidentalDeletion
                Write-Host "  $ouName (created)" -ForegroundColor Green
            }
            
            # Create child OUs if defined
            if ($ouDef.ContainsKey('Children') -and $ouDef.Children) {
                foreach ($childKey in $ouDef.Children.Keys) {
                    $childDef = $ouDef.Children[$childKey]
                    $childName = $childDef.Name
                    $childDesc = $childDef.Description
                    
                    $childDN = "OU=$childName,$ouDN"
                    
                    $child = Get-ADOrganizationalUnit -Identity $childDN -ErrorAction SilentlyContinue
                    if ($child) {
                        Write-Host "    $childName (already exists)" -ForegroundColor Green
                    }
                    else {
                        New-ADOrganizationalUnit -Name $childName -Path $ouDN -Description $childDesc -ProtectedFromAccidentalDeletion $childDef.ProtectFromAccidentalDeletion
                        Write-Host "    $childName (created)" -ForegroundColor Green
                    }
                }
            }
        }
        
        Write-Host ""
        Write-Host "OU hierarchy created successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to create OUs: $_"
        return $false
    }
}

Export-ModuleMember -Function Invoke-BuildOUs