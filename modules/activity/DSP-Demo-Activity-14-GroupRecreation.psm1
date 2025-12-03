################################################################################
##
## DSP-Demo-Activity-14-GroupRecreation.psm1
##
## Complex group recreation sequence:
## 1. DELETE "Special Lab Users" group
## 2. CREATE new group in Lab Users OU (Security/Global)
## 3. CHANGE category: Security -> Distribution
## 4. CHANGE scope: Global -> Universal
## 5. MOVE group: Lab Users OU -> Lab Admins OU
## 6. ADD member: App Admin III
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

function Invoke-GroupRecreation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Status "Starting GroupRecreation" -Level Success
    Write-Host ""
    
    $DomainInfo = $Environment.DomainInfo    
    $domainDN = $DomainInfo.DN
    
    $errorCount = 0
    $groupName = "Special Lab Users"
    $groupSAM = "SpecialLabUsers"
    $labUsersOU = "OU=Lab Users,$domainDN"
    $labAdminsOU = "OU=Lab Admins,$domainDN"
    
    # ============================================================================
    # IMPLEMENTATION
    # ============================================================================
    
    Write-Section "PHASE 1: DELETE Special Lab Users group"
    
    try {
        $existingGroup = Get-ADGroup -Filter "Name -eq '$groupName'" -ErrorAction SilentlyContinue
        
        if ($existingGroup) {
            Write-Status "Found group: $groupName" -Level Info
            Write-Status "Deleting group..." -Level Info
            Remove-ADGroup -Identity $existingGroup.DistinguishedName -Confirm:$false -ErrorAction Stop
            Write-Status "Group deleted successfully" -Level Success
            
            Write-Status "Waiting 10 seconds before recreation..." -Level Info
            Start-Sleep 10
        }
        else {
            Write-Status "Group '$groupName' not found - skipping deletion" -Level Warning
        }
    }
    catch {
        Write-Status "Error deleting group: $_" -Level Error
        $errorCount++
    }
    
    Write-Host ""
    Write-Section "PHASE 2: CREATE new group in Lab Users OU (Security/Global)"
    
    try {
        Write-Status "Creating group: $groupName (Security/Global) in Lab Users OU" -Level Info
        New-ADGroup `
            -Name $groupName `
            -SamAccountName $groupSAM `
            -GroupCategory Security `
            -GroupScope Global `
            -DisplayName $groupName `
            -Path $labUsersOU `
            -Description "Members of this lab group are special" `
            -ErrorAction Stop
        
        Write-Status "Group created successfully" -Level Success
        
        Write-Status "Waiting 10 seconds for replication..." -Level Info
        Start-Sleep 10
    }
    catch {
        Write-Status "Error creating group: $_" -Level Error
        $errorCount++
        # Can't continue if group creation failed
        Write-Host ""
        Write-Status "Cannot continue - group creation failed" -Level Error
        Write-Host ""
        return $false
    }
    
    Write-Host ""
    Write-Section "PHASE 3: CHANGE category Security -> Distribution"
    
    try {
        Write-Status "Changing group category to Distribution..." -Level Info
        Set-ADGroup -Identity $groupSAM -GroupCategory Distribution -ErrorAction Stop
        Write-Status "Category changed successfully" -Level Success
        
        Start-Sleep 10
    }
    catch {
        Write-Status "Error changing group category: $_" -Level Error
        $errorCount++
    }
    
    Write-Host ""
    Write-Section "PHASE 4: CHANGE scope Global -> Universal"
    
    try {
        Write-Status "Changing group scope to Universal..." -Level Info
        Set-ADGroup -Identity $groupSAM -GroupScope Universal -ErrorAction Stop
        Write-Status "Scope changed successfully" -Level Success
        
        Start-Sleep 10
    }
    catch {
        Write-Status "Error changing group scope: $_" -Level Error
        $errorCount++
    }
    
    Write-Host ""
    Write-Section "PHASE 5: MOVE group from Lab Users OU to Lab Admins OU"
    
    try {
        $groupObj = Get-ADGroup -Identity $groupSAM -ErrorAction Stop
        Write-Status "Moving group to Lab Admins OU..." -Level Info
        Move-ADObject -Identity $groupObj.DistinguishedName -TargetPath $labAdminsOU -ErrorAction Stop
        Write-Status "Group moved successfully" -Level Success
        
        Write-Status "Waiting 10 seconds for replication..." -Level Info
        Start-Sleep 10
    }
    catch {
        Write-Status "Error moving group: $_" -Level Error
        $errorCount++
    }
    
    Write-Host ""
    Write-Section "PHASE 6: ADD member App Admin III to group"
    
    try {
        Write-Status "Finding member: App Admin III" -Level Info
        $memberObj = Get-ADUser -Filter "Name -eq 'App Admin III'" -ErrorAction SilentlyContinue
        
        if ($memberObj) {
            Write-Status "Found member: $($memberObj.Name)" -Level Info
            Write-Status "Adding member to group..." -Level Info
            Add-ADGroupMember -Identity $groupSAM -Members $memberObj.DistinguishedName -ErrorAction Stop
            Write-Status "Member added successfully" -Level Success
        }
        else {
            Write-Status "ERROR: Member 'App Admin III' not found" -Level Error
            $errorCount++
        }
    }
    catch {
        Write-Status "Error adding member to group: $_" -Level Error
        $errorCount++
    }
    
    # ============================================================================
    # COMPLETION
    # ============================================================================
    
    Write-Host ""
    if ($errorCount -eq 0) {
        Write-Status "GroupRecreation completed successfully" -Level Success
    }
    else {
        Write-Status "GroupRecreation completed with $errorCount error(s)" -Level Warning
    }
    Write-Host ""
    return ($errorCount -eq 0)
}

Export-ModuleMember -Function Invoke-GroupRecreation

