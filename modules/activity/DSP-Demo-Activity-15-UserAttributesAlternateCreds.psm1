################################################################################
##
## DSP-Demo-Activity-15-UserAttributesAltCreds.psm1
##
## Set user attributes on arose (DemoUser1) using alternate credentials
## Shows changes made by a different user (lskywalker/DemoUser2)
##
## This demonstrates DSP's ability to track who made changes and when,
## especially when the same attribute is modified by different users.
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

function Invoke-UserAttributesAlternateCreds {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Status "Starting UserAttributesAltCreds" -Level Success
    Write-Host ""
    
    $errorCount = 0
    
    $targetUserName = $Config.Module15_UserAttributesAltCreds.TargetUser
    $changeAsUserName = $Config.Module15_UserAttributesAltCreds.ChangeAsUser
    
    # ============================================================================
    # IMPLEMENTATION
    # ============================================================================
    
    Write-Section "PHASE 1: Get user objects"
    
    try {
        Write-Status "Finding target user: $targetUserName" -Level Info
        $targetUser = Get-ADUser -Filter "SamAccountName -eq '$targetUserName'" -ErrorAction Stop
        Write-Status "Found: $($targetUser.Name)" -Level Success
        
        Write-Status "Finding alternate credentials user: $changeAsUserName" -Level Info
        $altCredUser = Get-ADUser -Filter "SamAccountName -eq '$changeAsUserName'" -ErrorAction Stop
        Write-Status "Found: $($altCredUser.Name)" -Level Success
    }
    catch {
        Write-Status "Error finding users: $_" -Level Error
        $errorCount++
        Write-Host ""
        Write-Status "Cannot continue without both user objects" -Level Error
        Write-Host ""
        return $false
    }
    
    Write-Host ""
    Write-Section "PHASE 2: Prepare alternate credentials (Unattended)"
    
    try {
        Write-Status "Retrieving credentials for $changeAsUserName from config" -Level Info
        
        # Check if password exists in config
        if (-not $Config.Module15_UserAttributesAltCreds.ContainsKey('AltUserPassword')) {
            throw "Configuration missing 'AltUserPassword' for Module 15 unattended execution."
        }

        $plainPassword = $Config.Module15_UserAttributesAltCreds.AltUserPassword
        
        # Convert plain text to SecureString
        $securePass = ConvertTo-SecureString $plainPassword -AsPlainText -Force
        
        # Create the Credential object programmatically
        $altCreds = New-Object System.Management.Automation.PSCredential ($altCredUser.UserPrincipalName, $securePass)
        
        if (-not $altCreds) {
            Write-Status "ERROR: Failed to create credential object" -Level Error
            $errorCount++
            Write-Host ""
            return $false
        }
        
        Write-Status "Credentials created successfully for $($altCredUser.UserPrincipalName)" -Level Success
    }
    catch {
        Write-Status "Error creating credentials: $_" -Level Error
        $errorCount++
        Write-Host ""
        return $false
    }
    
    Write-Host ""
    Write-Section "PHASE 3: Modify telephoneNumber (first change)"
    
    try {
        Write-Status "Setting telephoneNumber using alternate credentials" -Level Info
        Set-ADUser -Identity $targetUser.DistinguishedName `
            -OfficePhone "(000) 867-5309" `
            -Credential $altCreds `
            -ErrorAction Stop
        Write-Status "telephoneNumber set successfully" -Level Success
        
        Start-Sleep 8
    }
    catch {
        Write-Status "Error setting telephoneNumber: $_" -Level Error
        $errorCount++
    }
    
    Write-Host ""
    Write-Section "PHASE 4: Modify info attribute (first change with alt creds)"
    
    try {
        Write-Status "Setting info attribute using alternate credentials" -Level Info
        Set-ADUser -Identity $targetUser.DistinguishedName `
            -Replace @{info='first change of info attribute text'} `
            -Credential $altCreds `
            -ErrorAction Stop
        Write-Status "info attribute set successfully" -Level Success
        
        Write-Status "Waiting 8 seconds..." -Level Info
        Start-Sleep 8
    }
    catch {
        Write-Status "Error setting info attribute: $_" -Level Error
        $errorCount++
    }
    
    Write-Host ""
    Write-Section "PHASE 5: Multiple additional attribute changes"
    
    try {
        Write-Status "Waiting 8 seconds before additional changes..." -Level Info
        Start-Sleep 8
        Write-Host ""
        
        Write-Status "Setting telephoneNumber (second value) with alt creds" -Level Info
        Set-ADUser -Identity $targetUser.DistinguishedName `
            -OfficePhone "(555) 123-4567" `
            -Credential $altCreds `
            -ErrorAction Stop
        Write-Status "telephoneNumber updated" -Level Success
        
        Write-Status "Setting city" -Level Info
        Set-ADUser -Identity $targetUser.DistinguishedName `
            -City "Tribeca" `
            -Credential $altCreds `
            -ErrorAction Stop
        Write-Status "city set" -Level Success
        
        Write-Status "Setting division with alt creds" -Level Info
        Set-ADUser -Identity $targetUser.DistinguishedName `
            -Division "Special Operations" `
            -Credential $altCreds `
            -ErrorAction Stop
        Write-Status "division set" -Level Success
        
        Write-Status "Setting employeeID with alt creds" -Level Info
        Set-ADUser -Identity $targetUser.DistinguishedName `
            -EmployeeID "EMP-001337" `
            -Credential $altCreds `
            -ErrorAction Stop
        Write-Status "employeeID set" -Level Success
    }
    catch {
        Write-Status "Error during multi-attribute changes: $_" -Level Error
        $errorCount++
    }
    
    Write-Host ""
    Write-Section "PHASE 6: Additional attributes (current user context)"
    
    try {
        Write-Status "Setting initials" -Level Info
        Set-ADUser -Identity $targetUser.DistinguishedName `
            -Initials "JSL" `
            -ErrorAction Stop
        Write-Status "initials set" -Level Success
        
        Write-Status "Setting company" -Level Info
        Set-ADUser -Identity $targetUser.DistinguishedName `
            -Company "Semperis" `
            -ErrorAction Stop
        Write-Status "company set" -Level Success
        
        Write-Status "Setting fax" -Level Info
        Set-ADUser -Identity $targetUser.DistinguishedName `
            -Fax "(000) 222-3333" `
            -ErrorAction Stop
        Write-Status "fax set" -Level Success
    }
    catch {
        Write-Status "Error during additional attribute changes: $_" -Level Error
        $errorCount++
    }
    
    Write-Host ""
    Write-Section "PHASE 7: Final info attribute change (alt creds)"
    
    try {
        Write-Status "Setting info attribute (second change) with alt creds" -Level Info
        Set-ADUser -Identity $targetUser.DistinguishedName `
            -Replace @{info='second change of info attribute text'} `
            -Credential $altCreds `
            -ErrorAction Stop
        Write-Status "info attribute updated" -Level Success
        
        Write-Status "Waiting 15 seconds..." -Level Info
        Start-Sleep 15
    }
    catch {
        Write-Status "Error updating info attribute: $_" -Level Error
        $errorCount++
    }
    
    Write-Host ""
    Write-Section "PHASE 8: Clear info attribute (alt creds)"
    
    try {
        Write-Status "Clearing info attribute using alternate credentials" -Level Info
        Set-ADUser -Identity $targetUser.DistinguishedName `
            -Clear info `
            -Credential $altCreds `
            -ErrorAction Stop
        Write-Status "info attribute cleared" -Level Success
    }
    catch {
        Write-Status "Error clearing info attribute: $_" -Level Error
        $errorCount++
    }
    
    # ============================================================================
    # COMPLETION
    # ============================================================================
    
    Write-Host ""
    if ($errorCount -eq 0) {
        Write-Status "UserAttributesAltCreds completed successfully" -Level Success
    }
    else {
        Write-Status "UserAttributesAltCreds completed with $errorCount error(s)" -Level Warning
    }
    Write-Host ""
    return ($errorCount -eq 0)
}

Export-ModuleMember -Function Invoke-UserAttributesAlternateCreds