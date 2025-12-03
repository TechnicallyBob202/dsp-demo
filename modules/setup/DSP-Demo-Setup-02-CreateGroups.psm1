################################################################################
##
## DSP-Demo-Setup-02-CreateGroups.psm1
##
## Creates security and distribution groups from configuration file.
##
## All groups created with idempotent logic (create if not exists).
## Group membership populated in CreateUsers phase.
## No modifications to existing groups in this phase.
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

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

function Resolve-OUPath {
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogicalPath,
        
        [Parameter(Mandatory=$true)]
        $DomainInfo
    )
    
    $domainDN = $DomainInfo.DN
    
    if ([string]::IsNullOrWhiteSpace($LogicalPath) -or $LogicalPath -eq "Root") {
        return $domainDN
    }
    
    $parts = $LogicalPath -split '/'
    $dnParts = @()
    
    for ($i = $parts.Count - 1; $i -ge 0; $i--) {
        $part = $parts[$i]
        if ($part -and $part -ne "Root") {
            $dnParts += "OU=$part"
        }
    }
    
    $dn = ($dnParts -join ",") + "," + $domainDN
    return $dn
}

function Invoke-CreateGroups {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        $Environment
    )
    
    $DomainInfo = $Environment.DomainInfo
    
    Write-Host ""
    Write-Status "Creating groups..." -Level Info
    
    $createdCount = 0
    $skippedCount = 0
    $failedCount = 0
    
    # Check if Groups section exists
    if (-not $Config.ContainsKey('Groups') -or -not $Config.Groups) {
        Write-Status "No Groups section in configuration - skipping" -Level Info
        Write-Host ""
        return $true
    }
    
    # Process each group in config
    foreach ($groupName in $Config.Groups.Keys) {
        $groupDef = $Config.Groups[$groupName]
        
        # Get group name (use Name if present, otherwise use key)
        $name = if ($groupDef.ContainsKey('Name')) { $groupDef.Name } else { $groupName }
        $path = if ($groupDef.ContainsKey('Path')) { Resolve-OUPath $groupDef.Path $DomainInfo } else { $DomainInfo.DN }
        
        # Check if group already exists
        $existingGroup = Get-ADGroup -Filter { Name -eq $name } -ErrorAction SilentlyContinue
        if ($existingGroup) {
            Write-Status "Group already exists: $name" -Level Info
            $skippedCount++
            continue
        }
        
        try {
            $newGroupParams = @{
                Name = $name
                Path = $path
                GroupScope = if ($groupDef.ContainsKey('GroupScope')) { $groupDef.GroupScope } else { 'Global' }
                GroupCategory = if ($groupDef.ContainsKey('GroupCategory')) { $groupDef.GroupCategory } else { 'Security' }
                ErrorAction = 'Stop'
            }
            
            if ($groupDef.ContainsKey('Description')) {
                $newGroupParams['Description'] = $groupDef.Description
            }
            
            New-ADGroup @newGroupParams | Out-Null
            Write-Status "Created group: $name" -Level Success
            $createdCount++
        }
        catch {
            Write-Status "Error creating group '$name': $_" -Level Error
            Write-Status "  Parameters: Path=$path, Scope=$($newGroupParams.GroupScope), Category=$($newGroupParams.GroupCategory)" -Level Error
            $failedCount++
        }
    }
    
    Write-Host ""
    Write-Status "Group creation summary: $createdCount created, $skippedCount skipped, $failedCount failed" -Level Info
    Write-Host ""
    
    return $true
}

Export-ModuleMember -Function Invoke-CreateGroups