################################################################################
##
## DSP-Demo-Activity-09-GPOLabSMBClientPolicy.psm1
##
## Create or modify "Lab SMB Client Policy GPO"
## Sets AllowInsecureGuestAuth to 1 (insecure), triggers replication,
## then changes it to 0 (secure) to create trackable changes
##
################################################################################

#Requires -Version 5.1
#Requires -Modules GroupPolicy, ActiveDirectory

################################################################################
# HELPER FUNCTIONS
################################################################################

function Write-ActivityHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host ("+--" + ("-" * 62) + "--+") -ForegroundColor Cyan
    Write-Host ("| " + $Title.PadRight(62) + " |") -ForegroundColor Cyan
    Write-Host ("+--" + ("-" * 62) + "--+") -ForegroundColor Cyan
    Write-Host ""
}

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
# MAIN FUNCTION
################################################################################

function Invoke-GPOLabSMBClientPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Environment
    )
    
    Write-ActivityHeader "GPO - Lab SMB Client Policy Modifications"
    
    $modifiedCount = 0
    $createdCount = 0
    $errorCount = 0
    
    $gpoName = "Lab SMB Client Policy GPO"
    
    try {
        # Check if GPO exists
        $gpo = Get-GPO -Name $gpoName -ErrorAction SilentlyContinue
        
        if (-not $gpo) {
            # Create the GPO
            try {
                Write-Status "Creating new GPO: $gpoName" -Level Info
                $gpo = New-GPO -Name $gpoName -Comment "SMB Client policy for lab demonstrations" -ErrorAction Stop
                Write-Status "Created GPO: $gpoName" -Level Success
                $createdCount++
                Start-Sleep -Seconds 2
            }
            catch {
                Write-Status "Failed to create GPO: $_" -Level Error
                $errorCount++
                Write-Host ""
                return $true
            }
        }
        else {
            Write-Status "GPO already exists: $gpoName" -Level Info
        }
        
        # ====================================================================
        # PHASE 1: Set AllowInsecureGuestAuth to 1 (INSECURE)
        # ====================================================================
        
        Write-Status "Getting current setting for AllowInsecureGuestAuth..." -Level Info
        try {
            Get-GPRegistryValue -Name $gpoName -Key "HKLM\Software\Policies\Microsoft\Windows\LanmanWorkstation" -ValueName AllowInsecureGuestAuth -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
            Write-Status "AllowInsecureGuestAuth not currently set (first run)" -Level Info
        }
        
        Write-Status "Setting AllowInsecureGuestAuth to 1 (allow INSECURE SMB connections)..." -Level Info
        try {
            Set-GPRegistryValue -Name $gpoName -Key "HKLM\Software\Policies\Microsoft\Windows\LanmanWorkstation" `
                -ValueName AllowInsecureGuestAuth -Value 1 -Type DWord -ErrorAction Stop
            Write-Status "Set AllowInsecureGuestAuth = 1" -Level Success
            $modifiedCount++
        }
        catch {
            Write-Status "Error setting AllowInsecureGuestAuth to 1: $_" -Level Error
            $errorCount++
        }
        
        # Force replication
        Write-Status "Waiting 20 seconds before replication..." -Level Info
        Start-Sleep -Seconds 20
        
        Write-Status "Triggering replication..." -Level Info
        try {
            $dc = (Get-ADDomainController -Discover -ErrorAction SilentlyContinue).HostName
            if ($dc) {
                Repadmin /syncall $dc /APe | Out-Null
                Start-Sleep -Seconds 5
                Write-Status "Replication complete" -Level Success
            }
            else {
                Write-Status "No DC available for replication" -Level Warning
            }
        }
        catch {
            Write-Status "Warning: Could not trigger replication: $_" -Level Warning
        }
        
        # GP Update
        Write-Status "Running gpupdate /force..." -Level Info
        try {
            Invoke-GPUpdate -Force -ErrorAction Stop | Out-Null
            Write-Status "gpupdate complete" -Level Success
        }
        catch {
            Write-Status "Warning: gpupdate failed: $_" -Level Warning
        }
        
        # ====================================================================
        # PHASE 2: Set AllowInsecureGuestAuth to 0 (SECURE)
        # ====================================================================
        
        Write-Status "Waiting 10 seconds before second change..." -Level Info
        Start-Sleep -Seconds 10
        
        Write-Status "Getting current setting for AllowInsecureGuestAuth..." -Level Info
        try {
            Get-GPRegistryValue -Name $gpoName -Key "HKLM\Software\Policies\Microsoft\Windows\LanmanWorkstation" -ValueName AllowInsecureGuestAuth -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
            Write-Status "Could not read current setting" -Level Warning
        }
        
        Write-Status "Setting AllowInsecureGuestAuth to 0 (prevent INSECURE SMB connections)..." -Level Info
        try {
            Set-GPRegistryValue -Name $gpoName -Key "HKLM\Software\Policies\Microsoft\Windows\LanmanWorkstation" `
                -ValueName AllowInsecureGuestAuth -Value 0 -Type DWord -ErrorAction Stop
            Write-Status "Set AllowInsecureGuestAuth = 0" -Level Success
            $modifiedCount++
        }
        catch {
            Write-Status "Error setting AllowInsecureGuestAuth to 0: $_" -Level Error
            $errorCount++
        }
        
        # Force replication
        Write-Status "Waiting 25 seconds before replication..." -Level Info
        Start-Sleep -Seconds 25
        
        Write-Status "Triggering replication..." -Level Info
        try {
            $dc = (Get-ADDomainController -Discover -ErrorAction SilentlyContinue).HostName
            if ($dc) {
                Repadmin /syncall $dc /APe | Out-Null
                Start-Sleep -Seconds 5
                Write-Status "Replication complete" -Level Success
            }
            else {
                Write-Status "No DC available for replication" -Level Warning
            }
        }
        catch {
            Write-Status "Warning: Could not trigger replication: $_" -Level Warning
        }
        
        # GP Update
        Write-Status "Running gpupdate /force..." -Level Info
        try {
            Invoke-GPUpdate -Force -ErrorAction Stop | Out-Null
            Write-Status "gpupdate complete" -Level Success
        }
        catch {
            Write-Status "Warning: gpupdate failed: $_" -Level Warning
        }
    }
    catch {
        Write-Status "Fatal error: $_" -Level Error
        $errorCount++
    }
    
    # Summary
    Write-Host ""
    Write-Status "Created: $createdCount, Modified: $modifiedCount, Errors: $errorCount" -Level Info
    
    if ($errorCount -eq 0) {
        Write-Status "GPO Lab SMB Client Policy completed successfully" -Level Success
    }
    else {
        Write-Status "GPO Lab SMB Client Policy completed with $errorCount error(s)" -Level Warning
    }
    
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-GPOLabSMBClientPolicy