################################################################################
##
## DSP-Demo-01-Setup-BuildOUs.psm1
##
## Builds the OU hierarchy defined in the configuration file
## Supports nested OUs with proper parent-child relationships
##
## Author: Bob Lyons
## Version: 1.0.0-20251120
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

################################################################################
# INTERNAL VARIABLES
################################################################################

$Script:OUPathMap = @{}

################################################################################
# OU MANAGEMENT FUNCTIONS
################################################################################

function New-OU {
    <#
    .SYNOPSIS
        Creates an OU if it doesn't already exist
    
    .PARAMETER Name
        The name of the OU
    
    .PARAMETER Path
        The distinguished name of the parent container
    
    .PARAMETER Description
        Description for the OU
    
    .PARAMETER ProtectFromAccidentalDeletion
        Whether to protect the OU from deletion (default: $true)
    
    .OUTPUTS
        PSCustomObject with OU information or $null if creation failed
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name,
        
        [Parameter(Mandatory=$true)]
        [string]$Path,
        
        [Parameter(Mandatory=$false)]
        [string]$Description = "",
        
        [Parameter(Mandatory=$false)]
        [bool]$ProtectFromAccidentalDeletion = $true
    )
    
    try {
        # Check if OU already exists
        $existingOU = Get-ADOrganizationalUnit -Filter "Name -eq '$Name' -and DistinguishedName -like '*$Path'" -ErrorAction SilentlyContinue
        
        if ($existingOU) {
            Write-Host "    [EXISTS] OU: $Name" -ForegroundColor Green
            return $existingOU
        }
        
        # Create the OU
        Write-Host "    [CREATE] OU: $Name" -ForegroundColor Cyan
        
        $newOU = New-ADOrganizationalUnit -Name $Name -Path $Path -Description $Description -ErrorAction Stop
        
        # Set protection
        if ($ProtectFromAccidentalDeletion) {
            Set-ADOrganizationalUnit -Identity $newOU -ProtectedFromAccidentalDeletion $true -ErrorAction SilentlyContinue
        }
        
        Write-Host "    [SUCCESS] Created OU: $Name at path: $Path" -ForegroundColor Green
        return $newOU
    }
    catch {
        Write-Host "    [FAILED] Error creating OU '$Name': $_" -ForegroundColor Red
        return $null
    }
}

function Build-OUHierarchy {
    <#
    .SYNOPSIS
        Recursively builds the OU hierarchy from config structure
    
    .PARAMETER OUStructure
        Hashtable of OUs from config (single level)
    
    .PARAMETER ParentPath
        The DN of the parent container for this level
    
    .PARAMETER LogicalPath
        The logical path (e.g., "Root/LabAdmins/Tier0") for mapping
    
    .OUTPUTS
        None - updates internal path map
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$OUStructure,
        
        [Parameter(Mandatory=$true)]
        [string]$ParentPath,
        
        [Parameter(Mandatory=$false)]
        [string]$LogicalPath = ""
    )
    
    foreach ($ouKey in $OUStructure.Keys) {
        $ouConfig = $OUStructure[$ouKey]
        
        # Build logical path
        if ($LogicalPath) {
            $currentLogicalPath = "$LogicalPath/$ouKey"
        } else {
            $currentLogicalPath = $ouKey
        }
        
        # Create the OU
        $ou = New-OU -Name $ouConfig.Name -Path $ParentPath -Description $ouConfig.Description -ProtectFromAccidentalDeletion $ouConfig.ProtectFromAccidentalDeletion
        
        if ($ou) {
            # Store mapping of logical path to DN
            $Script:OUPathMap[$currentLogicalPath] = $ou.DistinguishedName
            
            # Process children recursively
            if ($ouConfig.ContainsKey('Children') -and $ouConfig.Children) {
                Build-OUHierarchy -OUStructure $ouConfig.Children -ParentPath $ou.DistinguishedName -LogicalPath $currentLogicalPath
            }
        }
    }
}

function Invoke-BuildOUs {
    <#
    .SYNOPSIS
        Main entry point for OU creation from config
    
    .PARAMETER Config
        Configuration hashtable with OUs section
    
    .PARAMETER DomainDN
        Distinguished name of the domain
    
    .OUTPUTS
        Hashtable mapping logical OU paths to distinguished names
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [string]$DomainDN
    )
    
    Write-Host ""
    Write-Host "=================================================================================" -ForegroundColor Green
    Write-Host "PHASE 1: Building OU Hierarchy" -ForegroundColor Green
    Write-Host "=================================================================================" -ForegroundColor Green
    Write-Host ""
    
    if (-not $Config.ContainsKey('OUs')) {
        Write-Host "[SKIP] No OUs defined in configuration" -ForegroundColor Yellow
        return @{}
    }
    
    # Clear path map for this run
    $Script:OUPathMap = @{}
    
    $ouConfig = $Config.OUs
    
    # Process the root OU (typically "DSP-Demo-Objects")
    foreach ($rootKey in $ouConfig.Keys) {
        $rootConfig = $ouConfig[$rootKey]
        
        Write-Host "Creating root OU: $($rootConfig.Name)" -ForegroundColor Cyan
        
        # Create root OU in domain root
        $rootOU = New-OU -Name $rootConfig.Name -Path $DomainDN -Description $rootConfig.Description -ProtectFromAccidentalDeletion $rootConfig.ProtectFromAccidentalDeletion
        
        if ($rootOU) {
            # Store root path mapping
            $Script:OUPathMap[$rootKey] = $rootOU.DistinguishedName
            
            # Process children
            if ($rootConfig.ContainsKey('Children') -and $rootConfig.Children) {
                Write-Host ""
                Write-Host "Creating child OUs under $($rootConfig.Name):" -ForegroundColor Cyan
                Build-OUHierarchy -OUStructure $rootConfig.Children -ParentPath $rootOU.DistinguishedName -LogicalPath $rootKey
            }
        }
    }
    
    Write-Host ""
    Write-Host "OU Hierarchy Summary:" -ForegroundColor Green
    Write-Host "-" * 80 -ForegroundColor Green
    
    foreach ($path in $Script:OUPathMap.Keys | Sort-Object) {
        Write-Host "  $path => $($Script:OUPathMap[$path])" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "Total OUs created: $($Script:OUPathMap.Count)" -ForegroundColor Green
    Write-Host ""
    
    return $Script:OUPathMap
}

function Get-OUPath {
    <#
    .SYNOPSIS
        Retrieves the distinguished name for a logical OU path
    
    .PARAMETER LogicalPath
        The logical path (e.g., "Root/LabAdmins/Tier0")
    
    .OUTPUTS
        String containing the distinguished name, or $null if not found
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogicalPath
    )
    
    if ($Script:OUPathMap.ContainsKey($LogicalPath)) {
        return $Script:OUPathMap[$LogicalPath]
    }
    
    Write-Host "WARNING: OU path not found in map: $LogicalPath" -ForegroundColor Yellow
    return $null
}

################################################################################
# EXPORTS
################################################################################

Export-ModuleMember -Function @(
    'Invoke-BuildOUs',
    'Get-OUPath',
    'New-OU'
)