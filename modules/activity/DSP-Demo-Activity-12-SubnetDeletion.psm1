################################################################################
##
## DSP-Demo-Activity-12-SubnetDeletion.psm1
##
## Delete AD subnets (111.111.4.0/24 and 111.111.5.0/24)
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

function Invoke-SubnetDeletion {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Status "Starting SubnetsDelete" -Level Success
    Write-Host ""
    
    $errorCount = 0
    
    # ============================================================================
    # IMPLEMENTATION
    # ============================================================================
    
    Write-Section "PHASE 1: Delete AD subnets"
    
    $subnetsToDelete = $Config.Module12_SubnetDeletion.SubnetsToDelete
    
    if (-not $subnetsToDelete -or $subnetsToDelete.Count -eq 0) {
        Write-Status "ERROR: SubnetsToDelete not configured" -Level Error
        $errorCount++
    }
    else {
        Write-Status "Found $($subnetsToDelete.Count) subnet(s) to delete" -Level Info
        Write-Host ""
        
        foreach ($subnet in $subnetsToDelete) {
            try {
                # Try to get the subnet first
                $existingSubnet = Get-ADReplicationSubnet -Identity $subnet -ErrorAction SilentlyContinue
                
                if ($existingSubnet) {
                    Write-Status "Deleting subnet: $subnet" -Level Info
                    
                    # Before deletion, optionally update description to show activity
                    Write-Status "Updating description before deletion..." -Level Info
                    Set-ADReplicationSubnet -Identity $subnet -Description "Marked for deletion" -ErrorAction SilentlyContinue
                    
                    Start-Sleep 2
                    
                    # Now delete it
                    Remove-ADReplicationSubnet -Identity $subnet -Confirm:$false -ErrorAction Stop
                    Write-Status "Subnet deleted successfully" -Level Success
                }
                else {
                    Write-Status "Subnet '$subnet' not found (may already be deleted)" -Level Warning
                }
            }
            catch {
                Write-Status "Error deleting subnet '$subnet': $_" -Level Error
                $errorCount++
            }
            
            Start-Sleep 2
        }
    }
    
    # ============================================================================
    # COMPLETION
    # ============================================================================
    
    Write-Host ""
    if ($errorCount -eq 0) {
        Write-Status "SubnetsDelete completed successfully" -Level Success
    }
    else {
        Write-Status "SubnetsDelete completed with $errorCount error(s)" -Level Warning
    }
    Write-Host ""
    return ($errorCount -eq 0)
}

Export-ModuleMember -Function Invoke-SubnetDeletion
