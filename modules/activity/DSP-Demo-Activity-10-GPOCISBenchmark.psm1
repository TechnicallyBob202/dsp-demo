################################################################################
##
## DSP-Demo-Activity-10-GPOCIS.psm1
##
## Create or modify "CIS Benchmark Windows Server Policy GPO"
## Sets multiple CIS Benchmark registry values for security hardening
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

function Invoke-GPOCISBenchmark {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Environment
    )
    
    Write-ActivityHeader "GPO - CIS Benchmark Windows Server Policy"
    
    $modifiedCount = 0
    $createdCount = 0
    $errorCount = 0
    
    $gpoName = "CIS Benchmark Windows Server Policy GPO"
    $dateTag = Get-Date -Format "yyyy-MM-dd_HHmm"
    
    try {
        # Check if GPO exists
        $gpo = Get-GPO -Name $gpoName -ErrorAction SilentlyContinue
        
        if (-not $gpo) {
            # Create the GPO
            try {
                Write-Status "Creating new GPO: $gpoName" -Level Info
                $gpo = New-GPO -Name $gpoName -Comment "CIS Benchmark recommendations for testing GPO changes $dateTag" -ErrorAction Stop
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
        # Set AllowInsecureGuestAuth (SMB security)
        # ====================================================================
        
        Write-Status "Configuring AllowInsecureGuestAuth..." -Level Info
        try {
            Get-GPRegistryValue -Name $gpoName -Key "HKLM\Software\Policies\Microsoft\Windows\LanmanWorkstation" `
                -ValueName AllowInsecureGuestAuth -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
            Write-Status "AllowInsecureGuestAuth not currently set" -Level Info
        }
        
        try {
            Set-GPRegistryValue -Name $gpoName -Key "HKLM\Software\Policies\Microsoft\Windows\LanmanWorkstation" `
                -ValueName AllowInsecureGuestAuth -Value 0 -Type DWord -ErrorAction Stop
            Write-Status "Set AllowInsecureGuestAuth = 0" -Level Success
            $modifiedCount++
        }
        catch {
            Write-Status "Error setting AllowInsecureGuestAuth: $_" -Level Error
            $errorCount++
        }
        
        # ====================================================================
        # Set Windows Update settings
        # ====================================================================
        
        Write-Status "Configuring Windows Update settings..." -Level Info
        
        try {
            Get-GPRegistryValue -Name $gpoName -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" `
                -ValueName "DetectionFrequencyEnabled" -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
            Write-Status "DetectionFrequencyEnabled not currently set" -Level Info
        }
        
        try {
            Set-GPRegistryValue -Name $gpoName -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" `
                -ValueName "DetectionFrequencyEnabled" -Value 0 -Type DWord -ErrorAction Stop
            Write-Status "Set DetectionFrequencyEnabled = 0" -Level Success
            $modifiedCount++
        }
        catch {
            Write-Status "Error setting DetectionFrequencyEnabled: $_" -Level Error
            $errorCount++
        }
        
        try {
            Get-GPRegistryValue -Name $gpoName -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" `
                -ValueName "De-tectionFrequency" -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
            Write-Status "De-tectionFrequency not currently set" -Level Info
        }
        
        try {
            Set-GPRegistryValue -Name $gpoName -Key "HKLM\Software\Policies\Microsoft\Windows\WindowsUpdate\AU" `
                -ValueName "De-tectionFrequency" -Value 82 -Type DWord -ErrorAction Stop
            Write-Status "Set De-tectionFrequency = 82" -Level Success
            $modifiedCount++
        }
        catch {
            Write-Status "Error setting De-tectionFrequency: $_" -Level Error
            $errorCount++
        }
        
        # ====================================================================
        # Set LSA security settings
        # ====================================================================
        
        Write-Status "Configuring LSA security settings..." -Level Info
        
        # forceguest - should be 0 for proper security
        try {
            Get-GPRegistryValue -Name $gpoName -Key "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Lsa" `
                -ValueName "forceguest" -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
            Write-Status "forceguest not currently set" -Level Info
        }
        
        try {
            Set-GPRegistryValue -Name $gpoName -Key "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Lsa" `
                -ValueName "forceguest" -Value 0 -Type DWord -ErrorAction Stop
            Write-Status "Set forceguest = 0" -Level Success
            $modifiedCount++
        }
        catch {
            Write-Status "Error setting forceguest: $_" -Level Error
            $errorCount++
        }
        
        # allownullsessionfallback - should be 0 to disable
        try {
            Get-GPRegistryValue -Name $gpoName -Key "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Lsa\MSV1_0" `
                -ValueName "allownullsessionfallback" -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
            Write-Status "allownullsessionfallback not currently set" -Level Info
        }
        
        try {
            Set-GPRegistryValue -Name $gpoName -Key "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Lsa\MSV1_0" `
                -ValueName "allownullsessionfallback" -Value 0 -Type DWord -ErrorAction Stop
            Write-Status "Set allownullsessionfallback = 0" -Level Success
            $modifiedCount++
        }
        catch {
            Write-Status "Error setting allownullsessionfallback: $_" -Level Error
            $errorCount++
        }
        
        # LmCompatibilityLevel - should be 5 (NTLMv2 only, refuse LM & NTLM)
        try {
            Get-GPRegistryValue -Name $gpoName -Key "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Lsa" `
                -ValueName "LmCompatibilityLevel" -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
            Write-Status "LmCompatibilityLevel not currently set" -Level Info
        }
        
        try {
            Set-GPRegistryValue -Name $gpoName -Key "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Lsa" `
                -ValueName "LmCompatibilityLevel" -Value 5 -Type DWord -ErrorAction Stop
            Write-Status "Set LmCompatibilityLevel = 5 (NTLMv2 only)" -Level Success
            $modifiedCount++
        }
        catch {
            Write-Status "Error setting LmCompatibilityLevel: $_" -Level Error
            $errorCount++
        }
        
        # NoLMHash - should be 1 to prevent LM hash storage
        try {
            Get-GPRegistryValue -Name $gpoName -Key "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Lsa" `
                -ValueName "NoLMHash" -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
            Write-Status "NoLMHash not currently set" -Level Info
        }
        
        try {
            Set-GPRegistryValue -Name $gpoName -Key "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Lsa" `
                -ValueName "NoLMHash" -Value 1 -Type DWord -ErrorAction Stop
            Write-Status "Set NoLMHash = 1" -Level Success
            $modifiedCount++
        }
        catch {
            Write-Status "Error setting NoLMHash: $_" -Level Error
            $errorCount++
        }
        
        # ====================================================================
        # Force replication
        # ====================================================================
        
        Write-Status "Triggering replication..." -Level Info
        try {
            $dc = (Get-ADDomainController -Discover -ErrorAction SilentlyContinue).HostName
            if ($dc) {
                Repadmin /syncall $dc /APe | Out-Null
                Start-Sleep -Seconds 3
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
        
        # Final replication
        Write-Status "Triggering final replication..." -Level Info
        try {
            $dc = (Get-ADDomainController -Discover -ErrorAction SilentlyContinue).HostName
            if ($dc) {
                Repadmin /syncall $dc /APe | Out-Null
                Start-Sleep -Seconds 3
                Write-Status "Final replication complete" -Level Success
            }
            else {
                Write-Status "No DC available for replication" -Level Warning
            }
        }
        catch {
            Write-Status "Warning: Could not trigger final replication: $_" -Level Warning
        }
        
        # Final GP Update
        Write-Status "Running final gpupdate /force..." -Level Info
        try {
            Invoke-GPUpdate -Force -ErrorAction Stop | Out-Null
            Write-Status "Final gpupdate complete" -Level Success
        }
        catch {
            Write-Status "Warning: Final gpupdate failed: $_" -Level Warning
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
        Write-Status "GPO CIS Benchmark completed successfully" -Level Success
    }
    else {
        Write-Status "GPO CIS Benchmark completed with $errorCount error(s)" -Level Warning
    }
    
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-GPOCISBenchmark