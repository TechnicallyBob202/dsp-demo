################################################################################
##
## DSP-Demo-Activity-11-FGPPCreate.psm1
##
## Create SpecialLabUsers_PSO FGPP with settings and assign to group
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

function Invoke-FGPPCreate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][hashtable]$Config,
        [Parameter(Mandatory=$true)]$Environment
    )
    
    Write-Host ""
    Write-Status "Starting FGPPCreate" -Level Success
    Write-Host ""
    
    $errorCount = 0
    
    # ============================================================================
    # IMPLEMENTATION
    # ============================================================================
    
    Write-Section "PHASE 1: Create SpecialLabUsers_PSO FGPP"
    
    $psoName = $Config.Module11_FGPPCreate.PolicyName
    $psoGroup = $Config.Module11_FGPPCreate.ApplyToGroup
    
    try {
        # Check if PSO already exists
        $existingPSO = Get-ADFineGrainedPasswordPolicy -Filter "Name -eq '$psoName'" -ErrorAction SilentlyContinue
        
        if ($existingPSO) {
            Write-Status "PSO '$psoName' already exists, skipping creation" -Level Warning
        }
        else {
            Write-Status "Creating FGPP: $psoName" -Level Info
            
            New-ADFineGrainedPasswordPolicy `
                -Name $psoName `
                -Precedence $Config.Module11_FGPPCreate.Precedence `
                -Description $Config.Module11_FGPPCreate.Description `
                -DisplayName $psoName `
                -LockoutDuration "8:00" `
                -LockoutObservationWindow "8:00" `
                -LockoutThreshold $Config.Module11_FGPPCreate.LockoutThreshold `
                -MinPasswordLength $Config.Module11_FGPPCreate.MinPasswordLength `
                -PasswordComplexity $Config.Module11_FGPPCreate.PasswordComplexity `
                -PasswordHistoryCount $Config.Module11_FGPPCreate.PasswordHistoryCount `
                -MaxPasswordAge $Config.Module11_FGPPCreate.MaxPasswordAge `
                -MinPasswordAge $Config.Module11_FGPPCreate.MinPasswordAge `
                -Verbose -ErrorAction Stop
            
            Write-Status "FGPP created successfully" -Level Success
            
            Write-Status "Waiting 5 seconds before assignment..." -Level Info
            Start-Sleep 5
            
            # Assign to group
            Write-Status "Assigning PSO to group: $psoGroup" -Level Info
            Add-ADFineGrainedPasswordPolicySubject -Identity $psoName -Subjects $psoGroup -ErrorAction Stop
            Write-Status "PSO assigned to group successfully" -Level Success
        }
    }
    catch {
        Write-Status "Error creating/assigning FGPP: $_" -Level Error
        $errorCount++
    }
    
    # ============================================================================
    # COMPLETION
    # ============================================================================
    
    Write-Host ""
    if ($errorCount -eq 0) {
        Write-Status "FGPPCreate completed successfully" -Level Success
    }
    else {
        Write-Status "FGPPCreate completed with $errorCount error(s)" -Level Warning
    }
    Write-Host ""
    return ($errorCount -eq 0)
}

Export-ModuleMember -Function Invoke-FGPPCreate