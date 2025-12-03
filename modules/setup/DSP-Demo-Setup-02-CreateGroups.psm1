################################################################################
##
## DSP-Demo-Setup-02-CreateGroups.psm1
##
## Creates security and distribution groups from configuration file.
## Also configures ACL delegations as specified in config.
##
## All groups created with idempotent logic (create if not exists).
## Group membership populated in CreateUsers phase.
## ACL delegations applied after group creation.
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
    }
    else {
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
    }
    
    Write-Host ""
    
    # ============================================================================
    # APPLY ACL DELEGATIONS FROM CONFIG
    # ============================================================================
    
    Write-Status "Processing ACL delegations..." -Level Info
    
    if (-not $Config.ContainsKey('ACLDelegations') -or -not $Config.ACLDelegations) {
        Write-Status "No ACL delegations configured - skipping" -Level Info
        Write-Host ""
        return $true
    }
    
    $aclCount = 0
    $aclSkipped = 0
    
    foreach ($delegationKey in $Config.ACLDelegations.Keys) {
        $delegation = $Config.ACLDelegations[$delegationKey]
        
        # Check if enabled
        if ($delegation.ContainsKey('Enabled') -and -not $delegation.Enabled) {
            Write-Status "Skipping disabled delegation: $delegationKey" -Level Info
            $aclSkipped++
            continue
        }
        
        try {
            $groupName = $delegation.GroupName
            $ouName = $delegation.OUName
            $rights = $delegation.Rights
            
            Write-Status "Configuring ACL: Grant '$groupName' $rights on OU '$ouName'" -Level Info
            
            # Get the group
            $group = Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction Stop
            Write-Status "  Found group: $($group.Name)" -Level Info
            
            # Get the OU
            $ou = Get-ADOrganizationalUnit -Filter "Name -eq '$ouName'" -ErrorAction Stop
            Write-Status "  Found OU: $($ou.Name)" -Level Info
            
            # Build ACL rule based on rights type
            $groupSID = New-Object System.Security.Principal.SecurityIdentifier $group.SID
            
            if ($rights -eq "WriteProperty") {
                # Create WriteProperty rule for all properties on child objects
                $accessRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule(
                    $groupSID,
                    [System.DirectoryServices.ActiveDirectoryRights]::WriteProperty,
                    [System.Security.AccessControl.AccessControlType]::Allow,
                    [System.DirectoryServices.ActiveDirectorySecurityInheritance]::Children,
                    [Guid]'00000000-0000-0000-0000-000000000000'  # All properties
                )
            }
            else {
                Write-Status "  Warning: Unknown rights type '$rights'" -Level Warning
                continue
            }
            
            # Get and update ACL
            $ouPath = "AD:$($ou.DistinguishedName)"
            $acl = Get-Acl -Path $ouPath -ErrorAction Stop
            
            # Check if rule already exists
            $ruleExists = $acl.Access | Where-Object {
                $_.IdentityReference.Value -match [regex]::Escape($group.SID) -and
                $_.ActiveDirectoryRights -eq $rights
            }
            
            if ($ruleExists) {
                Write-Status "  ACL rule already exists - skipping" -Level Info
                $aclSkipped++
            }
            else {
                Write-Status "  Adding ACL rule..." -Level Info
                $acl.AddAccessRule($accessRule)
                Set-Acl -Path $ouPath -AclObject $acl -ErrorAction Stop
                Write-Status "  ACL rule applied successfully" -Level Success
                $aclCount++
            }
        }
        catch {
            Write-Status "  Error configuring ACL for delegation '$delegationKey': $_" -Level Error
        }
    }
    
    Write-Host ""
    if ($aclCount -gt 0 -or $aclSkipped -gt 0) {
        Write-Status "ACL delegation summary: $aclCount applied, $aclSkipped skipped" -Level Info
    }
    
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-CreateGroups