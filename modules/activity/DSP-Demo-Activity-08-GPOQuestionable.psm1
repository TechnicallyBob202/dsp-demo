################################################################################
##
## DSP-Demo-Activity-08-GPOQuestionable.psm1
##
## Create or modify "Questionable GPO"
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

function Invoke-GPOQuestionable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Environment
    )
    
    Write-ActivityHeader "GPO - Questionable GPO Modifications"
    
    $modifiedCount = 0
    $createdCount = 0
    $errorCount = 0
    
    $gpoName = "Questionable GPO"
    
    try {
        # Check if GPO exists
        $gpo = Get-GPO -Name $gpoName -ErrorAction SilentlyContinue
        
        if (-not $gpo) {
            # Create the GPO
            try {
                Write-Status "Creating new GPO: $gpoName" -Level Info
                $gpo = New-GPO -Name $gpoName -Comment "Simple test GPO for demonstrations" -ErrorAction Stop
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
        # PHASE 1: Set CreateEncryptedOnlyTickets to 1
        # ====================================================================
        
        Write-Status "Getting current setting for CreateEncryptedOnlyTickets..." -Level Info
        try {
            Get-GPRegistryValue -Name $gpoName -Key "HKLM\Software\policies\Microsoft\Windows NT\Terminal Services" `
                -ValueName CreateEncryptedOnlyTickets -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
            Write-Status "CreateEncryptedOnlyTickets not currently set (first run)" -Level Info
        }
        
        Write-Status "Setting CreateEncryptedOnlyTickets to 1..." -Level Info
        try {
            Set-GPRegistryValue -Name $gpoName -Key "HKLM\Software\policies\Microsoft\Windows NT\Terminal Services" `
                -ValueName CreateEncryptedOnlyTickets -Value 1 -Type DWord -ErrorAction Stop
            Write-Status "Set CreateEncryptedOnlyTickets = 1" -Level Success
            $modifiedCount++
        }
        catch {
            Write-Status "Error setting CreateEncryptedOnlyTickets to 1: $_" -Level Error
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
        
        # ====================================================================
        # PHASE 2: Set CreateEncryptedOnlyTickets to 0
        # ====================================================================
        
        Write-Status "Waiting 20 seconds before second change..." -Level Info
        Start-Sleep -Seconds 20
        
        Write-Status "Getting current setting for CreateEncryptedOnlyTickets..." -Level Info
        try {
            Get-GPRegistryValue -Name $gpoName -Key "HKLM\Software\policies\Microsoft\Windows NT\Terminal Services" `
                -ValueName CreateEncryptedOnlyTickets -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
            Write-Status "Could not read current setting" -Level Warning
        }
        
        Write-Status "Setting CreateEncryptedOnlyTickets to 0..." -Level Info
        try {
            Set-GPRegistryValue -Name $gpoName -Key "HKLM\Software\policies\Microsoft\Windows NT\Terminal Services" `
                -ValueName CreateEncryptedOnlyTickets -Value 0 -Type DWord -ErrorAction Stop
            Write-Status "Set CreateEncryptedOnlyTickets = 0" -Level Success
            $modifiedCount++
        }
        catch {
            Write-Status "Error setting CreateEncryptedOnlyTickets to 0: $_" -Level Error
            $errorCount++
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
        Write-Status "GPO Questionable completed successfully" -Level Success
    }
    else {
        Write-Status "GPO Questionable completed with $errorCount error(s)" -Level Warning
    }
    
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-GPOQuestionable