################################################################################
##
## DSP-Demo-Activity-03-SubnetsModify.psm1
##
## Change descriptions and locations on AD subnets
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

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

function Write-ActivityHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host ("+--" + ("-" * 62) + "--+") -ForegroundColor Cyan
    Write-Host ("| " + $Title.PadRight(62) + " |") -ForegroundColor Cyan
    Write-Host ("+--" + ("-" * 62) + "--+") -ForegroundColor Cyan
    Write-Host ""
}

################################################################################
# MAIN FUNCTION
################################################################################

function Invoke-SubnetsModify {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Environment
    )
    
    Write-ActivityHeader "Subnets - Modify Descriptions and Locations"
    
    $modifiedCount = 0
    $skippedCount = 0
    $errorCount = 0
    
    # Get subnets from config
    if (-not $Config.ContainsKey('Subnets') -or -not $Config.Subnets) {
        Write-Status "No subnets configured in config file" -Level Warning
        Write-Host ""
        return $true
    }
    
    try {
        foreach ($subnetName in $Config.Subnets.Keys) {
            $subnetConfig = $Config.Subnets[$subnetName]
            
            try {
                # Get existing subnet
                $subnet = Get-ADReplicationSubnet -Filter { Name -eq $subnetName } -ErrorAction Stop
                
                if (-not $subnet) {
                    Write-Status "Subnet '$subnetName' not found" -Level Warning
                    $skippedCount++
                    continue
                }
                
                # Prepare modification parameters
                $modifyParams = @{
                    Identity = $subnet.DistinguishedName
                    ErrorAction = 'Stop'
                }
                
                # Build description if configured
                if ($subnetConfig.Description) {
                    $modifyParams.Description = $subnetConfig.Description
                }
                
                # Build location if configured
                if ($subnetConfig.Location) {
                    $modifyParams.Location = $subnetConfig.Location
                }
                
                # Apply modifications if we have any
                if ($modifyParams.Keys.Count -gt 2) {  # More than just Identity and ErrorAction
                    Set-ADReplicationSubnet @modifyParams | Out-Null
                    Write-Status "Modified: $subnetName" -Level Success
                    $modifiedCount++
                }
                else {
                    Write-Status "No modifications configured for: $subnetName" -Level Info
                    $skippedCount++
                }
                
                Start-Sleep -Milliseconds 100
            }
            catch {
                Write-Status "Error modifying $subnetName : $_" -Level Error
                $errorCount++
            }
        }
        
        # Trigger replication
        if ($modifiedCount -gt 0) {
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
    }
    catch {
        Write-Status "Fatal error in subnet modification: $_" -Level Error
        $errorCount++
    }
    
    # Summary
    Write-Host ""
    Write-Status "Modified: $modifiedCount, Skipped: $skippedCount, Errors: $errorCount" -Level Info
    
    if ($errorCount -eq 0) {
        Write-Status "Subnets Modify completed successfully" -Level Success
    }
    else {
        Write-Status "Subnets Modify completed with $errorCount error(s)" -Level Warning
    }
    
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-SubnetsModify
