################################################################################
##
## DSP-Demo-01-Core.psm1
##
## Core helper functions for AD demo script suite
## DC-focused, no DSP dependencies
##
################################################################################

#Requires -Version 5.1
#Requires -Modules ActiveDirectory

################################################################################
# LOGGING FUNCTIONS
################################################################################

function Write-LogHeader {
    <#
    .SYNOPSIS
        Write a formatted header for demo sections
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Message
    )
    
    Write-Host ""
    Write-Host ("-" * 80) -ForegroundColor Cyan
    Write-Host ":: $Message" -ForegroundColor Cyan
    Write-Host ("-" * 80) -ForegroundColor Cyan
    Write-Host ""
}

function Write-ScriptLog {
    <#
    .SYNOPSIS
        Write a formatted log message with level-based coloring
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Info','Success','Warning','Error','Verbose')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    switch ($Level) {
        'Info' {
            Write-Host ":: [$timestamp] [INFO] $Message" -ForegroundColor Cyan
        }
        'Success' {
            Write-Host ":: [$timestamp] [SUCCESS] $Message" -ForegroundColor Green
        }
        'Warning' {
            Write-Host ":: [$timestamp] [WARNING] $Message" -ForegroundColor Yellow
        }
        'Error' {
            Write-Host ":: [$timestamp] [ERROR] $Message" -ForegroundColor Red
        }
        'Verbose' {
            Write-Host ":: [$timestamp] [VERBOSE] $Message" -ForegroundColor DarkGray
        }
    }
}

################################################################################
# UTILITY FUNCTIONS
################################################################################

function Wait-ADReplication {
    <#
    .SYNOPSIS
        Wait for AD replication with visual feedback
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [int]$Seconds,
        
        [Parameter(Mandatory=$false)]
        [string]$Message = "Waiting for AD replication..."
    )
    
    if ($Message) {
        Write-ScriptLog $Message -Level Info
    }
    
    for ($i = $Seconds; $i -gt 0; $i--) {
        Write-Host -NoNewline "`r:: Waiting... $i seconds remaining  " -ForegroundColor Gray
        Start-Sleep -Seconds 1
    }
    
    Write-Host ""
    Write-ScriptLog "Replication wait complete" -Level Success
}

function Test-AdminRights {
    <#
    .SYNOPSIS
        Test if the current process has administrator rights
    #>
    [CmdletBinding()]
    param()
    
    try {
        $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = New-Object Security.Principal.WindowsPrincipal($identity)
        
        $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        if ($isAdmin) {
            Write-ScriptLog "Administrator rights verified" -Level Success
        }
        else {
            Write-ScriptLog "WARNING: Not running with administrator rights" -Level Warning
        }
        
        return $isAdmin
    }
    catch {
        Write-ScriptLog "Error checking admin rights: $_" -Level Error
        return $false
    }
}

function Get-Timestamp {
    <#
    .SYNOPSIS
        Get a formatted timestamp
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [string]$Format = "yyyy-MM-dd HH:mm:ss"
    )
    
    return Get-Date -Format $Format
}

function Invoke-DspCommand {
    <#
    .SYNOPSIS
        Execute a command with error handling and logging
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory=$false)]
        [string]$Description = "Executing command",
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Stop','Continue','SilentlyContinue')]
        [string]$ErrorAction = 'Stop'
    )
    
    Write-ScriptLog "Starting: $Description" -Level Verbose
    
    try {
        $result = & $ScriptBlock
        Write-ScriptLog "Completed: $Description" -Level Success
        return $result
    }
    catch {
        Write-ScriptLog "Failed: $Description - $_" -Level Error
        
        if ($ErrorAction -eq 'Stop') {
            throw
        }
        
        return $null
    }
}

################################################################################
# EXPORT FUNCTIONS
################################################################################

Export-ModuleMember -Function @(
    'Write-LogHeader',
    'Write-ScriptLog',
    'Wait-ADReplication',
    'Test-AdminRights',
    'Get-Timestamp',
    'Invoke-DspCommand'
)