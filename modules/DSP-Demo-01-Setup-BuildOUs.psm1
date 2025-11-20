################################################################################
##
## DSP-Demo-01-Setup-BuildOUs.psm1
##
## Creates all organizational unit (OU) structure for the demo environment.
##
## OUs Created (at domain root):
## - Lab Admins (parent)
##   - Tier 0, Tier 1, Tier 2
## - Lab Users (parent)
##   - Dept101, Dept999
## - Bad OU (standalone)
## - DeleteMe OU (parent)
##   - Corp Special OU, Resources, Servers
## - TEST (standalone)
##
## All OUs created with idempotent logic (create if not exists).
## No modifications or deletions in this phase.
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
        # Build the DN for this OU
        $ouDN = "OU=$Name,$Path"
        
        # Check if OU already exists at this exact path
        $existingOU = Get-ADOrganizationalUnit -Identity $ouDN -ErrorAction SilentlyContinue
        
        if ($existingOU) {
            Write-Verbose "OU already exists: $Name at $Path"
            return $existingOU
        }
        
        # Create the OU
        $ou = New-ADOrganizationalUnit -Name $Name -Path $Path -Description $Description -ProtectedFromAccidentalDeletion $ProtectFromAccidentalDeletion -ErrorAction Stop
        
        Write-Verbose "Created OU: $Name at $Path"
        return $ou
    }
    catch {
        Write-Error "Failed to create OU $Name : $_"
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
    
    try {
        # Create all top-level OUs at domain root
        foreach ($ouKey in $OUConfig.Keys) {
            $ouDef = $OUConfig[$ouKey]
            $ouName = $ouDef.Name
            $ouDesc = $ouDef.Description
            $ouProtect = $ouDef.ProtectFromAccidentalDeletion
            
            Write-Verbose "Creating top-level OU: $ouName"
            
            $ou = New-OU -Name $ouName -Path $DomainDN -Description $ouDesc -ProtectFromAccidentalDeletion $ouProtect
            
            if ($ou) {
                $ouObjects[$ouKey] = $ou
                
                # Create child OUs if defined
                if ($ouDef.ContainsKey('Children') -and $ouDef.Children) {
                    foreach ($childKey in $ouDef.Children.Keys) {
                        $childDef = $ouDef.Children[$childKey]
                        $childName = $childDef.Name
                        $childDesc = $childDef.Description
                        $childProtect = $childDef.ProtectFromAccidentalDeletion
                        
                        Write-Verbose "Creating child OU: $childName under $ouName"
                        
                        $childOU = New-OU -Name $childName -Path $ou.DistinguishedName -Description $childDesc -ProtectFromAccidentalDeletion $childProtect
                        
                        if ($childOU) {
                            $ouObjects["$ouKey/$childKey"] = $childOU
                        }
                    }
                }
            }
        }
        
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
        
        # Validate config
        if (-not $Config -or -not $Config.ContainsKey('OUs')) {
            Write-Warning "No OUs defined in configuration"
            return $true
        }
        
        # Validate environment
        if (-not $Environment -or -not $Environment.DomainInfo) {
            Write-Error "Invalid environment object"
            return $false
        }
        
        $domainDN = $Environment.DomainInfo.DN
        
        if (-not $domainDN) {
            Write-Error "Domain DN is empty or missing from environment"
            return $false
        }
        
        Write-Verbose "Creating OUs in domain: $domainDN"
        
        # Build OU structure
        $ouObjects = Build-OUStructure -DomainDN $domainDN -OUConfig $Config.OUs
        
        if (-not $ouObjects) {
            Write-Error "Failed to create OU structure"
            return $false
        }
        
        Write-Verbose "BuildOUs module completed successfully"
        
        # Store OU objects in script-level variable for use by other modules
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