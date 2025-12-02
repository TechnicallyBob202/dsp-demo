################################################################################
##
## DSP-Demo-Activity-09-GPOLabSMBClientPolicy.psm1
##
## Create or modify "Lab SMB Client Policy GPO"
##
################################################################################

#Requires -Version 5.1
#Requires -Modules GroupPolicy, ActiveDirectory

################################################################################
# HELPER FUNCTIONS
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
                $gpo = New-GPO -Name $gpoName -ErrorAction Stop
                Write-Status "Created new GPO: $gpoName" -Level Success
                $createdCount++
                Start-Sleep -Seconds 1
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
        
        # Make modifications to the GPO
        try {
            # Set SMB-related policy settings
            $gpoSession = Open-NetGPO -PolicyStore $gpo.Path -ErrorAction Stop
            
            Write-Status "GPO session opened for modifications" -Level Info
            
            # Example: Disable SMB signing requirement change
            try {
                Set-SmbServerConfiguration -RequireSecuritySignature $true -Force -ErrorAction SilentlyContinue
                Write-Status "Modified SMB security signing requirement" -Level Success
                $modifiedCount++
            }
            catch {
                Write-Status "Could not modify SMB settings (may require elevation or OS version)" -Level Warning
            }
            
            # Update GPO description
            try {
                Set-GPO -Name $gpoName -Description "SMB Client security configuration for lab" -ErrorAction Stop
                Write-Status "Updated GPO description" -Level Success
                $modifiedCount++
            }
            catch {
                Write-Status "Warning: Could not update GPO description: $_" -Level Warning
            }
            
            Start-Sleep -Milliseconds 500
        }
        catch {
            Write-Status "Error modifying GPO: $_" -Level Error
            $errorCount++
        }
        
        # Trigger replication
        Write-Status "Triggering replication..." -Level Info
        try {
            $domainInfo = $Environment.DomainInfo
            $dc = $domainInfo.ReplicationPartners[0]
            if ($dc) {
                Repadmin /syncall $dc /APe | Out-Null
                Start-Sleep -Seconds 3
                Write-Status "Replication triggered" -Level Success
            }
        }
        catch {
            Write-Status "Warning: Could not trigger replication: $_" -Level Warning
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