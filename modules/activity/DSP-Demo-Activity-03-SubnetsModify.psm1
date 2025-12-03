################################################################################
##
## DSP-Demo-Activity-03-SubnetsModify.psm1
##
## Change subnet descriptions and locations
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

function Invoke-SubnetsModify {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        $Environment
    )
    
    Write-Host ""
    Write-Host "+------------------------------------------------------------------+" -ForegroundColor White
    Write-Host "| Subnets - Modify Descriptions and Locations                    |" -ForegroundColor White
    Write-Host "+------------------------------------------------------------------+" -ForegroundColor White
    
    # Get subnet modifications - REQUIRED
    $subnetChanges = $Config.Module03_SubnetMods.SubnetChanges
    if (-not $subnetChanges -or $subnetChanges.Count -eq 0) {
        Write-Status "ERROR: SubnetChanges not configured in Module03_SubnetMods" -Level Error
        Write-Host ""
        return $false
    }
    
    $modifiedCount = 0
    $errorCount = 0
    
    Write-Status "Found $($subnetChanges.Count) subnet change(s) to apply" -Level Info
    Write-Host ""
    
    # Process each subnet change
    foreach ($change in $subnetChanges) {
        $subnetName = $change.Name
        
        try {
            # Check if subnet exists
            $subnet = Get-ADReplicationSubnet -Filter "Name -eq '$subnetName'" -ErrorAction SilentlyContinue
            
            if (-not $subnet) {
                Write-Status "Subnet '$subnetName' not found" -Level Error
                $errorCount++
                continue
            }
            
            Write-Status "Found subnet: $subnetName" -Level Info
            
            # Build Set-ADReplicationSubnet parameters
            $setParams = @{
                Identity = $subnetName
                ErrorAction = 'Stop'
            }
            
            if ($change.NewDescription) {
                $setParams['Description'] = $change.NewDescription
                Write-Status "  Setting Description: $($change.NewDescription)" -Level Info
            }
            
            if ($change.NewLocation) {
                $setParams['Location'] = $change.NewLocation
                Write-Status "  Setting Location: $($change.NewLocation)" -Level Info
            }
            
            # Apply the changes
            Set-ADReplicationSubnet @setParams
            Write-Status "Modified subnet: $subnetName" -Level Success
            $modifiedCount++
            
            Start-Sleep -Milliseconds 500
        }
        catch {
            Write-Status "Error modifying subnet $subnetName : $_" -Level Error
            $errorCount++
        }
    }
    
    Write-Host ""
    Write-Status "Subnets modified: $modifiedCount, Errors: $errorCount" -Level Info
    
    if ($errorCount -eq 0) {
        Write-Status "Subnets Modify completed successfully" -Level Success
    }
    else {
        Write-Status "Subnets Modify completed with $errorCount error(s)" -Level Error
    }
    
    Write-Host ""
    return ($errorCount -eq 0)
}

Export-ModuleMember -Function Invoke-SubnetsModify