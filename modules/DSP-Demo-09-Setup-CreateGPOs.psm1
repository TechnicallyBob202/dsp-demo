################################################################################
##
## DSP-Demo-09-Setup-CreateGPOs.psm1
##
## Creates Group Policy Objects (GPOs) with initial configuration.
##
################################################################################

#Requires -Version 5.1
#Requires -Modules GroupPolicy

function Invoke-CreateGPOs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$Environment
    )
    
    Write-Host ""
    Write-Host "Creating GPOs" -ForegroundColor Cyan
    Write-Host ""
    
    $createdCount = 0
    $skippedCount = 0
    
    # Create GPOs if configured
    if ($Config.ContainsKey('GPOs') -and $Config.GPOs) {
        Write-Host "  Processing GPOs..." -ForegroundColor Cyan
        
        foreach ($gpoName in $Config.GPOs.Keys) {
            $gpoConfig = $Config.GPOs[$gpoName]
            
            try {
                $existing = Get-GPO -Name $gpoName -ErrorAction Stop
                Write-Host "    $gpoName - already exists" -ForegroundColor Green
                $skippedCount++
            }
            catch {
                try {
                    $params = @{
                        Name = $gpoName
                        ErrorAction = 'Stop'
                    }
                    
                    if ($gpoConfig.Comment) {
                        $params.Comment = $gpoConfig.Comment
                    }
                    
                    New-GPO @params | Out-Null
                    Write-Host "    $gpoName - created" -ForegroundColor Green
                    $createdCount++
                    Start-Sleep -Seconds 1
                }
                catch {
                    Write-Host "    $gpoName - ERROR: $_" -ForegroundColor Red
                }
            }
        }
    }
    
    Write-Host ""
    Write-Host "GPOs: Created $createdCount, Skipped $skippedCount" -ForegroundColor Green
    Write-Host ""
    
    return $true
}

Export-ModuleMember -Function Invoke-CreateGPOs