################################################################################
##
## DSP-Demo-Activity-10-GPOCIS.psm1
##
## Create or modify CIS Benchmark Windows Server Policy GPO
##
################################################################################

#Requires -Version 5.1
#Requires -Modules GroupPolicy, ActiveDirectory

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

function Invoke-GPOCIS {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Environment
    )
    
    Write-Host ""
    Write-Host "+------------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "| GPO - CIS Benchmark Windows Server Policy                      |" -ForegroundColor Cyan
    Write-Host "+------------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""
    
    $createdCount = 0
    $modifiedCount = 0
    $errorCount = 0
    
    # Get config - REQUIRED
    $gpoName = $Config.Module10_GPOCIS.GpoName
    if (-not $gpoName) {
        Write-Status "ERROR: GpoName not configured in Module10_GPOCIS" -Level Error
        Write-Host ""
        return $false
    }
    
    Write-Status "Target GPO: $gpoName" -Level Info
    Write-Host ""
    
    try {
        # Check if GPO exists
        $gpo = Get-GPO -Name $gpoName -ErrorAction SilentlyContinue
        
        if ($gpo) {
            Write-Status "GPO '$gpoName' already exists" -Level Info
            $modifiedCount++
        }
        else {
            # Create new GPO
            Write-Status "Creating GPO: $gpoName" -Level Info
            $gpo = New-GPO -Name $gpoName -ErrorAction Stop
            Write-Status "Created GPO: $gpoName" -Level Success
            $createdCount++
        }
        
        Start-Sleep -Milliseconds 500
    }
    catch {
        Write-Status "Error with GPO: $_" -Level Error
        $errorCount++
    }
    
    # Summary
    Write-Host ""
    Write-Status "Created: $createdCount, Modified: $modifiedCount, Errors: $errorCount" -Level Info
    
    if ($errorCount -eq 0) {
        Write-Status "GPO CIS Benchmark completed successfully" -Level Success
    }
    else {
        Write-Status "GPO CIS Benchmark completed with $errorCount error(s)" -Level Error
    }
    
    Write-Host ""
    return ($errorCount -eq 0)
}

Export-ModuleMember -Function Invoke-GPOCIS