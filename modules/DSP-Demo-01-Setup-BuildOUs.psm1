################################################################################
##
## DSP-Demo-01-Setup-BuildOUs.psm1
##
## Creates all organizational unit (OU) structure for the demo environment.
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

################################################################################
# HELPER FUNCTIONS
################################################################################

function New-OU {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$false)]
        [string]$Description,
        
        [Parameter(Mandatory=$false)]
        [bool]$ProtectFromAccidentalDeletion = $true
    )
    
    try {
        $ouDN = "OU=$Name,$Path"
        Write-Host "        Checking for existing: $ouDN" -ForegroundColor Gray
        
        $existingOU = Get-ADOrganizationalUnit -Identity $ouDN -ErrorAction SilentlyContinue
        
        if ($existingOU) {
            Write-Host "        Already exists at: $ouDN" -ForegroundColor Gray
            return $existingOU
        }
        
        Write-Host "        Creating new OU at: $ouDN" -ForegroundColor Gray
        $ou = New-ADOrganizationalUnit -Name $Name -Path $Path -Description $Description -ProtectedFromAccidentalDeletion $ProtectFromAccidentalDeletion -ErrorAction Stop
        
        Start-Sleep -Milliseconds 300
        
        Write-Host "        Fetching created OU from: $ouDN" -ForegroundColor Gray
        $createdOU = Get-ADOrganizationalUnit -Identity $ouDN -ErrorAction Stop
        
        Write-Host "        Created successfully: $ouDN" -ForegroundColor Gray
        return $createdOU
    }
    catch {
        Write-Host "        ERROR - Failed to create: $ouDN" -ForegroundColor Red
        Write-Host "        Error details: $_" -ForegroundColor Red
        return $null
    }
}

function Build-OUStructure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$DomainDN,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$OUConfig
    )
    
    $ouObjects = @{}
    $createdCount = 0
    
    try {
        foreach ($ouKey in $OUConfig.Keys) {
            $ouDef = $OUConfig[$ouKey]
            $ouName = $ouDef.Name
            $ouDesc = $ouDef.Description
            $ouProtect = $ouDef.ProtectFromAccidentalDeletion
            
            Write-Host "  Creating OU: $ouName" -ForegroundColor Cyan
            
            $ou = New-OU -Name $ouName -Path $DomainDN -Description $ouDesc -ProtectFromAccidentalDeletion $ouProtect
            
            if ($ou) {
                Write-Host "    OK: $ouName" -ForegroundColor Green
                $createdCount++
                $ouObjects[$ouKey] = $ou
                
                if ($ouDef.ContainsKey('Children') -and $ouDef.Children) {
                    foreach ($childKey in $ouDef.Children.Keys) {
                        $childDef = $ouDef.Children[$childKey]
                        $childName = $childDef.Name
                        $childDesc = $childDef.Description
                        $childProtect = $childDef.ProtectFromAccidentalDeletion
                        
                        Write-Host "    Creating child OU: $childName" -ForegroundColor Cyan
                        
                        $parentDN = $ou.DistinguishedName
                        $expectedChildDN = "OU=$childName,$parentDN"
                        
                        Write-Host "      Parent OU DN: $parentDN" -ForegroundColor Yellow
                        Write-Host "      Expected child DN: $expectedChildDN" -ForegroundColor Yellow
                        Write-Host "      Child Name: $childName" -ForegroundColor Yellow
                        
                        if (-not $parentDN) {
                            Write-Host "      FAILED: Parent OU DN is empty" -ForegroundColor Red
                            continue
                        }
                        
                        $childOU = New-OU -Name $childName -Path $parentDN -Description $childDesc -ProtectFromAccidentalDeletion $childProtect
                        
                        if ($childOU) {
                            Write-Host "      OK: $childName" -ForegroundColor Green
                            $createdCount++
                            $ouObjects["$ouKey/$childKey"] = $childOU
                        }
                        else {
                            Write-Host "      FAILED: $childName" -ForegroundColor Red
                        }
                    }
                }
            }
            else {
                Write-Host "    FAILED: $ouName" -ForegroundColor Red
            }
        }
        
        Write-Host ""
        Write-Host "  Summary: $createdCount OUs created/verified" -ForegroundColor Green
        
        return $ouObjects
    }
    catch {
        Write-Error "Failed to build OU structure: $_"
        return $null
    }
}

################################################################################
# MAIN FUNCTION
################################################################################

function Invoke-BuildOUs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Environment
    )
    
    try {
        Write-Verbose "Starting BuildOUs module"
        
        if (-not $Config -or -not $Config.ContainsKey('OUs')) {
            Write-Warning "No OUs defined in configuration"
            return $true
        }
        
        if (-not $Environment -or -not $Environment.DomainInfo) {
            Write-Error "Invalid environment object"
            return $false
        }
        
        $domainDN = $Environment.DomainInfo.DN
        
        if (-not $domainDN) {
            Write-Error "Domain DN is empty or missing from environment"
            return $false
        }
        
        Write-Host ""
        Write-Host "Creating OU hierarchy at: $domainDN" -ForegroundColor Cyan
        Write-Host ""
        
        $ouObjects = Build-OUStructure -DomainDN $domainDN -OUConfig $Config.OUs
        
        if (-not $ouObjects) {
            Write-Error "Failed to create OU structure"
            return $false
        }
        
        Write-Host ""
        Write-Host "OU hierarchy created successfully" -ForegroundColor Green
        
        Write-Verbose "BuildOUs module completed successfully"
        
        $script:OUObjects = $ouObjects
        
        return $true
    }
    catch {
        Write-Error "Error in Invoke-BuildOUs: $_"
        return $false
    }
}

################################################################################
# EXPORT
################################################################################

Export-ModuleMember -Function Invoke-BuildOUs