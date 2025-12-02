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
            # Update GPO description
            Set-GPO -Name $gpoName -Description "Modified during demo activity" -ErrorAction Stop
            Write-Status "Updated GPO description" -Level Success
            $modifiedCount++
            
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
            if ($domainInfo.ReplicationPartners -and $domainInfo.ReplicationPartners.Count -gt 0) {
                $dc = $domainInfo.ReplicationPartners[0]
                Repadmin /syncall $dc /APe | Out-Null
                Start-Sleep -Seconds 3
                Write-Status "Replication triggered" -Level Success
            }
            else {
                Write-Status "No replication partners available" -Level Warning
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
        Write-Status "GPO Questionable completed successfully" -Level Success
    }
    else {
        Write-Status "GPO Questionable completed with $errorCount error(s)" -Level Warning
    }
    
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-GPOQuestionable