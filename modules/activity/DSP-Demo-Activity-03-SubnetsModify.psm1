################################################################################
##
## DSP-Demo-Activity-03-SubnetsModify.psm1
##
## Modify subnet descriptions for AD replication subnets
## Changes descriptions on subnets 111.111.4.0/24 and 111.111.5.0/24
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

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

function Invoke-SubnetsModify {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Environment
    )
    
    Write-ActivityHeader "Sites and Services - Modify Subnet Descriptions"
    
    $modifiedCount = 0
    $notFoundCount = 0
    $errorCount = 0
    
    # Get subnets list from config Module03_SubnetsModify
    if (-not $Config.Module03_SubnetsModify -or -not $Config.Module03_SubnetsModify.Subnets) {
        Write-Status "No subnets found in Module03_SubnetsModify config" -Level Warning
        Write-Host ""
        return $false
    }
    
    $subnetsList = $Config.Module03_SubnetsModify.Subnets
    
    # Ensure subnetsList is an array
    if ($subnetsList -isnot [array]) {
        $subnetsList = @($subnetsList)
    }
    
    Write-Status "Processing $($subnetsList.Count) subnet(s)" -Level Info
    Write-Host ""
    
    foreach ($subnetConfig in $subnetsList) {
        $subnetName = $subnetConfig.Name
        
        try {
            # Check if subnet exists (will throw if not found)
            Get-ADReplicationSubnet -Identity $subnetName -ErrorAction Stop | Out-Null
            
            Write-Status "Found subnet: $subnetName" -Level Info
            
            # Build Set-ADReplicationSubnet parameters
            $setParams = @{
                Identity = $subnetName
                ErrorAction = 'Stop'
            }
            
            if ($subnetConfig.Description) {
                $setParams['Description'] = $subnetConfig.Description
            }
            
            if ($subnetConfig.Location) {
                $setParams['Location'] = $subnetConfig.Location
            }
            
            # Apply the changes
            Set-ADReplicationSubnet @setParams
            Write-Status "  Modified: Description set to '$($subnetConfig.Description)'" -Level Success
            $modifiedCount++
            
            Start-Sleep -Milliseconds 500
        }
        catch {
            Write-Status "Subnet not found: $subnetName" -Level Warning
            $notFoundCount++
        }
    }
    
    # Summary
    Write-Host ""
    Write-Status "Modified: $modifiedCount, Not Found: $notFoundCount, Errors: $errorCount" -Level Info
    
    if ($errorCount -eq 0 -and $notFoundCount -eq 0) {
        Write-Status "Subnets Modify completed successfully" -Level Success
    }
    else {
        Write-Status "Subnets Modify completed with issues" -Level Warning
    }
    
    Write-Host ""
    return $true
}

Export-ModuleMember -Function Invoke-SubnetsModify