################################################################################
##
## DSP-Demo-Activity-03-SubnetsModify.psm1
##
## Change subnet descriptions and locations
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

function Invoke-SubnetsModify {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Host "+------------------------------------------------------------------+" -ForegroundColor White
    Write-Host "| Subnets - Modify Descriptions and Locations                    |" -ForegroundColor White
    Write-Host "+------------------------------------------------------------------+" -ForegroundColor White
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Get subnet modifications from activity settings
    $subnetMods = $null
    if ($Config.ContainsKey('ActivitySettings') -and $Config.ActivitySettings.ContainsKey('SubnetsActivity')) {
        $subnetMods = $Config.ActivitySettings.SubnetsActivity
    }
    
    # If no config, return gracefully
    if (-not $subnetMods -or $subnetMods.Count -eq 0) {
        Write-Host "[$timestamp] [Warning] No subnets configured in config file" -ForegroundColor Yellow
        Write-Host ""
        return $true
    }
    
    $modifiedCount = 0
    $errorCount = 0
    
    # Process each subnet modification
    foreach ($subnet in $subnetMods.Keys) {
        $modConfig = $subnetMods[$subnet]
        
        try {
            # Check if subnet exists
            $subnetObj = Get-ADReplicationSubnet -Filter "Name -eq '$subnet'" -ErrorAction Stop
            
            # Build Set-ADReplicationSubnet parameters
            $setParams = @{
                Identity = $subnet
                ErrorAction = 'Stop'
            }
            
            if ($modConfig.Description) {
                $setParams.Description = $modConfig.Description
            }
            
            if ($modConfig.Location) {
                $setParams.Location = $modConfig.Location
            }
            
            # Apply the changes
            Set-ADReplicationSubnet @setParams
            Write-Host "[$timestamp] [Success] Modified subnet: $subnet" -ForegroundColor Green
            $modifiedCount++
        }
        catch {
            Write-Host "[$timestamp] [Error] Failed to modify subnet $subnet : $_" -ForegroundColor Red
            $errorCount++
        }
    }
    
    Write-Host ""
    Write-Host "[$timestamp] [Success] Subnets modified: $modifiedCount, Errors: $errorCount" -ForegroundColor Green
    Write-Host ""
    
    return ($errorCount -eq 0)
}

Export-ModuleMember -Function Invoke-SubnetsModify