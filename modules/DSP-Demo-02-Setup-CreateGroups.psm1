################################################################################
##
## DSP-Demo-02-Setup-CreateGroups.psm1
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

################################################################################
# LOGGING
################################################################################

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
# PRIVATE HELPER FUNCTIONS
################################################################################

function Resolve-OUPath {
    <#
    .SYNOPSIS
    Converts logical OU path (e.g., "Root/LabAdmins") to DN
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogicalPath,
        
        [Parameter(Mandatory=$true)]
        $DomainInfo
    )
    
    $domainDN = $DomainInfo.DomainDN
    
    if ([string]::IsNullOrWhiteSpace($LogicalPath) -or $LogicalPath -eq "Root") {
        return $domainDN
    }
    
    # Split path and build DN from right to left
    $parts = $LogicalPath -split '/'
    $dn = $domainDN
    
    for ($i = $parts.Count - 1; $i -ge 0; $i--) {
        if ($parts[$i] -and $parts[$i] -ne "Root") {
            $dn = "OU=$($parts[$i]),$dn"
        }
    }
    
    return $dn
}

################################################################################
# PUBLIC FUNCTION
################################################################################

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
    
    # Track results
    $createdCount = 0
    $skippedCount = 0
    $failedCount = 0
    
    # Check if Groups section exists in config
    if (-not $Config.ContainsKey('Groups') -or -not $Config.Groups) {
        Write-Status "No Groups section in configuration - skipping" -Level Info
        Write-Host ""
        return $true
    }
    
    # Process all groups in config
    # Groups can be nested in arrays or hashtables (AdminGroups, UserGroups, etc.)
    foreach ($groupCategory in $Config.Groups.Values) {
        # Handle both array and hashtable formats
        if ($groupCategory -is [array]) {
            $groupList = $groupCategory
        }
        elseif ($groupCategory -is [hashtable] -and $groupCategory.ContainsKey('Name')) {
            # Single group object
            $groupList = @($groupCategory)
        }
        else {
            continue
        }
        
        foreach ($groupDef in $groupList) {
            # Validate required fields
            if (-not $groupDef.SamAccountName -or -not $groupDef.Name) {
                Write-Status "Skipping group - missing required SamAccountName or Name" -Level Warning
                $skippedCount++
                continue
            }
            
            # Resolve OU path
            $ouPath = if ($groupDef.OUPath) {
                Resolve-OUPath -LogicalPath $groupDef.OUPath -DomainInfo $DomainInfo
            }
            else {
                $DomainInfo.DomainDN
            }
            
            # Verify target OU exists
            if (-not (Test-Path -Path "AD:\$ouPath" -ErrorAction SilentlyContinue)) {
                Write-Status "Target OU does not exist: $ouPath - skipping $($groupDef.SamAccountName)" -Level Warning
                $skippedCount++
                continue
            }
            
            # Check if group already exists
            $existingGroup = Get-ADGroup -Filter "SamAccountName -eq '$($groupDef.SamAccountName)'" -ErrorAction SilentlyContinue
            
            if ($existingGroup) {
                Write-Status "Group already exists: $($groupDef.SamAccountName)" -Level Info
                $skippedCount++
                continue
            }
            
            # Create new group
            try {
                $newGroupParams = @{
                    SamAccountName = $groupDef.SamAccountName
                    Name = $groupDef.Name
                    Path = $ouPath
                    GroupScope = if ($groupDef.GroupScope) { $groupDef.GroupScope } else { 'Global' }
                    GroupCategory = if ($groupDef.GroupCategory) { $groupDef.GroupCategory } else { 'Security' }
                    ErrorAction = 'Stop'
                }
                
                if ($groupDef.DisplayName) {
                    $newGroupParams.DisplayName = $groupDef.DisplayName
                }
                
                if ($groupDef.Description) {
                    $newGroupParams.Description = $groupDef.Description
                }
                
                $newGroup = New-ADGroup @newGroupParams
                Write-Status "Created group: $($groupDef.SamAccountName)" -Level Success
                $createdCount++
            }
            catch {
                Write-Status "Error creating group $($groupDef.SamAccountName) : $_" -Level Error
                $failedCount++
            }
        }
    }
    
    Write-Host ""
    Write-Status "Group creation summary: $createdCount created, $skippedCount skipped, $failedCount failed" -Level Info
    Write-Host ""
    
    return $true
}

################################################################################
# EXPORTS
################################################################################

Export-ModuleMember -Function Invoke-CreateGroups