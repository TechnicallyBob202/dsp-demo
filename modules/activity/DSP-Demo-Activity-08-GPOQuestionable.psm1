################################################################################
##
## DSP-Demo-Activity-08-GPOQuestionable.psm1
##
## Create Questionable GPO and modify registry values
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
    
    $errorCount = 0
    $gpoName = "Questionable GPO"
    
    try {
        # Create GPO if it doesn't exist
        $gpo = Get-GPO -Name $gpoName -ErrorAction SilentlyContinue
        if (-not $gpo) {
            Write-Status "Creating GPO: $gpoName" -Level Info
            $gpo = New-GPO -Name $gpoName -Comment "This is a GPO with some questionable settings for testing 2022-02-15" -ErrorAction Stop
            Write-Status "GPO created successfully" -Level Success
            Start-Sleep -Seconds 10
        }
        else {
            Write-Status "GPO already exists: $gpoName" -Level Info
        }
        
        # Get the GPO object
        $gpo = Get-GPO -Name $gpoName -ErrorAction Stop
        
        # Try to unlink from Bad OU (may not exist, that's OK)
        Write-Status "Attempting to unlink from Bad OU" -Level Info
        try {
            $badOU = Get-ADOrganizationalUnit -Filter { Name -eq "Bad OU" } -SearchBase $Environment.DomainInfo.DN -ErrorAction SilentlyContinue
            if ($badOU) {
                Remove-GPLink -Name $gpoName -Target $badOU.DistinguishedName -ErrorAction SilentlyContinue
                Write-Status "Unlinked from Bad OU" -Level Success
            }
            else {
                Write-Status "Bad OU not found, skipping unlink" -Level Warning
            }
        }
        catch {
            Write-Status "Unlink attempt completed (may have failed if link didn't exist)" -Level Info
        }
        
        # Wait for replication
        Write-Status "Waiting 10 seconds for replication..." -Level Info
        Start-Sleep -Seconds 10
        
        # Trigger replication
        try {
            $dc = $Environment.PrimaryDC
            if ($dc) {
                Repadmin /syncall $dc /APe | Out-Null
                Write-Status "Replication triggered" -Level Success
            }
        }
        catch {
            Write-Status "Could not trigger replication: $_" -Level Warning
        }
        
        # =====================================================================
        # REGISTRY VALUE 1: BlockDomainPicturePassword
        # =====================================================================
        Write-Host ""
        Write-Status "Setting BlockDomainPicturePassword registry value" -Level Info
        
        try {
            $regKey = "HKLM\Software\Policies\Microsoft\Windows\System"
            $regValue = "BlockDomainPicturePassword"
            
            # Check if it exists
            try {
                Get-GPRegistryValue -Name $gpoName -Key $regKey -ValueName $regValue -ErrorAction Stop | Out-Null
                Write-Status "Current value retrieved" -Level Info
            }
            catch {
                Write-Status "Value does not exist yet" -Level Info
            }
            
            # Set to 1
            Write-Status "Setting $regValue to 1" -Level Info
            Set-GPRegistryValue -Name $gpoName -Key $regKey -ValueName $regValue -Type DWord -Value 1 -ErrorAction Stop
            Write-Status "Successfully set to 1" -Level Success
            
            # Wait for replication
            Write-Status "Waiting 10 seconds for replication..." -Level Info
            Start-Sleep -Seconds 10
            
            # Trigger replication again
            try {
                $dc = $Environment.PrimaryDC
                if ($dc) {
                    Repadmin /syncall $dc /APe | Out-Null
                }
            }
            catch { }
            
            # Set back to 0
            Write-Status "Setting $regValue back to 0" -Level Info
            Set-GPRegistryValue -Name $gpoName -Key $regKey -ValueName $regValue -Type DWord -Value 0 -ErrorAction Stop
            Write-Status "Successfully set to 0" -Level Success
        }
        catch {
            Write-Status "Error with BlockDomainPicturePassword: $_" -Level Error
            $errorCount++
        }
        
        # =====================================================================
        # REGISTRY VALUE 2: CreateEncryptedOnlyTickets
        # =====================================================================
        Write-Host ""
        Write-Status "Setting CreateEncryptedOnlyTickets registry value" -Level Info
        
        try {
            $regKey = "HKLM\Software\policies\Microsoft\Windows NT\Terminal Services"
            $regValue = "CreateEncryptedOnlyTickets"
            
            # Check if it exists
            try {
                Get-GPRegistryValue -Name $gpoName -Key $regKey -ValueName $regValue -ErrorAction Stop | Out-Null
                Write-Status "Current value retrieved" -Level Info
            }
            catch {
                Write-Status "Value does not exist yet" -Level Info
            }
            
            # Set to 1
            Write-Status "Setting $regValue to 1" -Level Info
            Set-GPRegistryValue -Name $gpoName -Key $regKey -ValueName $regValue -Type DWord -Value 1 -ErrorAction Stop
            Write-Status "Successfully set to 1" -Level Success
            
            # Wait for replication
            Write-Status "Waiting 20 seconds for replication..." -Level Info
            Start-Sleep -Seconds 20
            
            # Trigger replication again
            try {
                $dc = $Environment.PrimaryDC
                if ($dc) {
                    Repadmin /syncall $dc /APe | Out-Null
                }
            }
            catch { }
            
            # Set back to 0
            Write-Status "Setting $regValue back to 0" -Level Info
            Set-GPRegistryValue -Name $gpoName -Key $regKey -ValueName $regValue -Type DWord -Value 0 -ErrorAction Stop
            Write-Status "Successfully set to 0" -Level Success
        }
        catch {
            Write-Status "Error with CreateEncryptedOnlyTickets: $_" -Level Error
            $errorCount++
        }
        
    }
    catch {
        Write-Status "Fatal error: $_" -Level Error
        $errorCount++
    }
    
    # Summary
    Write-Host ""
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