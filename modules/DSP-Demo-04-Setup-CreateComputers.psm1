################################################################################
##
## DSP-Demo-04-Setup-CreateComputers.psm1
##
## Creates all computer objects for the demo environment.
##
## Computers Created (in DeleteMe OU sub-OUs):
## - srv-iis-us01 in Root/DeleteMe OU/Servers
##   Description: Special application server for lab
## - ops-app-us05 in Root/DeleteMe OU/Resources
##   Description: Special application server for lab
##
## Computers Created (in restricted SpecialOU):
## - PIMPAM
##   Description: Privileged access server
## - VAULT
##   Description: Vault server to store passwords and credentials
## - BASTION-HOST01
##   Description: Bastion host for restricted privileged access
##
## All computers created with idempotent logic (create if not exists).
## No modifications to existing computers in this phase.
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

################################################################################
# LOGGING
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
# HELPER FUNCTIONS
################################################################################

function Resolve-OUPath {
    <#
    .SYNOPSIS
    Converts logical OU path (e.g. "Root/DeleteMe OU/Servers") to Distinguished Name
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$LogicalPath,
        
        [Parameter(Mandatory=$true)]
        $DomainInfo
    )
    
    $domainDN = $DomainInfo.DN
    
    if ([string]::IsNullOrWhiteSpace($LogicalPath) -or $LogicalPath -eq "Root") {
        return $domainDN
    }
    
    # Split path from left to right
    $parts = $LogicalPath -split '/'
    
    # Build DN from right to left, so child comes first
    $dnParts = @()
    for ($i = $parts.Count - 1; $i -ge 0; $i--) {
        $part = $parts[$i]
        if ($part -and $part -ne "Root") {
            $dnParts += "OU=$part"
        }
    }
    
    # Join all parts and append domain DN
    $dn = ($dnParts -join ",") + "," + $domainDN
    
    return $dn
}

function New-ComputerAccount {
    <#
    .SYNOPSIS
    Creates a computer account with full idempotent logic:
    - If computer exists in correct OU: return it (no action)
    - If computer exists in wrong OU: move it to correct OU
    - If computer doesn't exist: create it in correct OU
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$ComputerDef,
        
        [Parameter(Mandatory=$true)]
        [string]$OUPath,
        
        [Parameter(Mandatory=$false)]
        [string]$DefaultPassword
    )
    
    $sam = $ComputerDef.SamAccountName
    
    # Check if computer exists anywhere
    $existing = Get-ADComputer -Filter { SamAccountName -eq $sam } -ErrorAction SilentlyContinue
    
    if ($existing) {
        # Computer exists - check if it's in the right place
        if ($existing.DistinguishedName -eq "CN=$($ComputerDef.Name),$OUPath") {
            Write-Status "Computer '$sam' already exists in correct location - skipping" -Level Info
            return $existing
        }
        else {
            # Computer exists but in wrong location - move it
            try {
                Move-ADObject -Identity $existing.DistinguishedName -TargetPath $OUPath -ErrorAction Stop
                Write-Status "Moved computer '$sam' to correct OU" -Level Success
                return $existing
            }
            catch {
                Write-Status "Failed to move computer '$sam' to correct OU: $_" -Level Error
                return $null
            }
        }
    }
    
    # Map config keys to New-ADComputer parameters
    $paramMap = @{
        'DisplayName' = 'DisplayName'
        'Description' = 'Description'
    }
    
    # Determine password to use
    $passwordToUse = $ComputerDef.Password
    if ([string]::IsNullOrWhiteSpace($passwordToUse)) {
        $passwordToUse = $DefaultPassword
    }
    
    if ([string]::IsNullOrWhiteSpace($passwordToUse)) {
        Write-Status "Failed to create computer '$sam': No password specified and no default available" -Level Error
        return $null
    }
    
    # Build params for New-ADComputer
    $newComputerParams = @{
        SamAccountName = $sam
        Name = $ComputerDef.Name
        Path = $OUPath
        AccountPassword = ConvertTo-SecureString $passwordToUse -AsPlainText -Force
        Enabled = if ($ComputerDef.ContainsKey('Enabled')) { $ComputerDef.Enabled } else { $true }
        ErrorAction = 'Stop'
    }
    
    # Add mapped attributes if present in config
    foreach ($configKey in $paramMap.Keys) {
        if ($ComputerDef.ContainsKey($configKey) -and -not [string]::IsNullOrWhiteSpace($ComputerDef[$configKey])) {
            $paramKey = $paramMap[$configKey]
            $newComputerParams[$paramKey] = $ComputerDef[$configKey]
        }
    }
    
    try {
        $computer = New-ADComputer @newComputerParams -PassThru
        Write-Status "Created computer '$sam'" -Level Success
        return $computer
    }
    catch {
        Write-Status "Failed to create computer '$sam': $_" -Level Error
        return $null
    }
}

################################################################################
# PUBLIC FUNCTION
################################################################################

function Invoke-CreateComputers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        $Environment
    )
    
    $DomainInfo = $Environment.DomainInfo
    $DefaultPassword = if ($Config.General.ContainsKey('DefaultPassword')) { $Config.General.DefaultPassword } else { $null }
    
    Write-Host ""
    Write-Status "Creating computer accounts..." -Level Info
    
    $createdCount = 0
    $skippedCount = 0
    
    # Check if Computers section exists in config
    if (-not $Config.ContainsKey('Computers') -or -not $Config.Computers) {
        Write-Status "No Computers section in configuration - skipping" -Level Info
        Write-Host ""
        return $true
    }
    
    # Process all computers in config
    foreach ($computerDef in $Config.Computers) {
        $ouPath = Resolve-OUPath $computerDef.OUPath $DomainInfo
        $computer = New-ComputerAccount $computerDef $ouPath $DefaultPassword
        if ($computer) { $createdCount++ } else { $skippedCount++ }
    }
    
    Write-Host ""
    Write-Status "Computer creation completed - Created: $createdCount, Skipped: $skippedCount" -Level Success
    Write-Host ""
    
    return $true
}

Export-ModuleMember -Function Invoke-CreateComputers