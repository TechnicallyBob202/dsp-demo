################################################################################
################################################################################
##
## Invoke-CreateDspChangeDataForDemos.ps1 (REFACTORED)
##
## Refactored version with improved maintainability, portability, and efficiency
##
## Author: Rob Ingenthron (Original), Refactored by Bob Lyons
## Version: 4.0.0-20251119 (Refactored)
##
################################################################################
################################################################################

<#  
.SYNOPSIS  
    Active Directory activity-generation script (Refactored).

.DESCRIPTION
    Automatically generate AD activities such as users, groups, DNS, GPOs, FGPP, 
    and changes to objects and ACLs. This refactored version uses configuration-driven
    approach with reusable helper functions.

.PARAMETER ConfigPath
    Path to external JSON configuration file (optional)

.PARAMETER SkipDSPOperations
    Skip DSP-specific operations

.PARAMETER LogPath
    Custom log file path

.EXAMPLE
    .\Invoke-CreateDspChangeDataForDemos-Refactored.ps1

.EXAMPLE
    .\Invoke-CreateDspChangeDataForDemos-Refactored.ps1 -ConfigPath "C:\Config\demo-config.json"

.NOTES  
    Author     : Rob Ingenthron (Original), Bob Lyons (Refactor)
    Version    : 4.0.0-20251119
    
    Key Improvements:
    - Centralized configuration using hashtables
    - Reusable helper functions
    - Consistent error handling
    - Reduced code duplication by ~70%
    - Better logging and progress tracking
    - Support for external configuration files
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipDSPOperations,
    
    [Parameter(Mandatory=$false)]
    [string]$LogPath
)

#Requires -Modules ActiveDirectory
#Requires -RunAsAdministrator

################################################################################
# CONFIGURATION SECTION
################################################################################

$Script:Config = @{
    # Domain Configuration
    Domain = @{
        FQDN = $null  # Will be auto-detected
        NetBIOS = $null  # Will be auto-detected
        RootDN = $null  # Will be auto-detected
        DomainControllers = @()  # Will be auto-detected
    }
    
    # DSP Configuration
    DSP = @{
        Enabled = -not $SkipDSPOperations
        ServerName = $null  # Will be auto-detected via SCP
        Port = 7031
        Credential = $null
        UnprivilegedAdmin = "DSP-Admin-demo"
    }
    
    # Demo User Configuration
    Users = @{
        DemoUser1 = @{
            Name = "Axl Rose"
            SamAccountName = "arose"
            GivenName = "Axl"
            Surname = "Rose"
            Department = "Music"
            Title = "Lead Singer"
            Company = "Guns N Roses"
            EmployeeID = "100001"
            Description = "Demo user for DSP testing"
            Password = "P@ssw0rd123!"
            Enabled = $true
        }
        DemoUser2 = @{
            Name = "Slash Hudson"
            SamAccountName = "shudson"
            GivenName = "Slash"
            Surname = "Hudson"
            Department = "Music"
            Title = "Lead Guitarist"
            Company = "Guns N Roses"
            EmployeeID = "100002"
            Description = "Demo user for DSP testing"
            Password = "P@ssw0rd123!"
            Enabled = $true
        }
        DemoUser3 = @{
            Name = "Duff McKagan"
            SamAccountName = "dmckagan"
            GivenName = "Duff"
            Surname = "McKagan"
            Department = "Music"
            Title = "Bass Player"
            Company = "Guns N Roses"
            EmployeeID = "100003"
            Description = "Demo user for DSP testing - Auto Undo trigger"
            Password = "P@ssw0rd123!"
            Enabled = $true
        }
        Tier2Admin = @{
            Name = "T2 Admin Demo"
            SamAccountName = "t2admin"
            GivenName = "T2"
            Surname = "Admin"
            Department = "IT"
            Title = "Tier 2 Administrator"
            EmployeeID = "200001"
            Description = "Tier 2 admin for demos"
            Password = "P@ssw0rd123!"
            Enabled = $true
        }
    }
    
    # Group Configuration
    Groups = @{
        SpecialLabAdmins = @{
            Name = "DSP-LAB-Special-Admins"
            SamAccountName = "DSP-LAB-Special-Admins"
            GroupCategory = "Security"
            GroupScope = "Global"
            Description = "Special lab administrators group for DSP demos"
            Members = @("arose", "shudson", "t2admin")
        }
        TierZeroAdmins = @{
            Name = "Tier 0 Admins"
            SamAccountName = "Tier0Admins"
            GroupCategory = "Security"
            GroupScope = "Global"
            Description = "Tier 0 administrators"
            Members = @("Administrator")
        }
    }
    
    # OU Configuration
    OUs = @{
        DemoRoot = @{
            Name = "DSP-Demo-Objects"
            Description = "Root OU for all DSP demo objects"
            Path = $null  # Will be set to domain root DN
        }
        Users = @{
            Name = "Users"
            Description = "Demo users OU"
            ParentOU = "DSP-Demo-Objects"
        }
        Groups = @{
            Name = "Groups"
            Description = "Demo groups OU"
            ParentOU = "DSP-Demo-Objects"
        }
        DeletedDemo = @{
            Name = "To-Be-Deleted-OU"
            Description = "OU that will be deleted for recovery demos"
            ParentOU = "DSP-Demo-Objects"
            DeleteAfterCreation = $true
        }
        TierZero = @{
            Name = "Tier-0-Assets"
            Description = "Highly restricted Tier 0 OU"
            RestrictAccess = $true
        }
    }
    
    # DNS Configuration
    DNS = @{
        ForwardZone = @{
            Name = $null  # Will be set to domain FQDN
            Records = @(
                @{ Name = "demo-server1"; Type = "A"; IPv4Address = "192.168.100.10" }
                @{ Name = "demo-server2"; Type = "A"; IPv4Address = "192.168.100.11" }
                @{ Name = "demo-alias"; Type = "CNAME"; HostNameAlias = "demo-server1" }
            )
        }
        ReverseZone = @{
            Name = "100.168.192.in-addr.arpa"
            NetworkID = "192.168.100.0/24"
            Records = @(
                @{ Name = "10"; Type = "PTR"; PtrDomainName = "demo-server1" }
                @{ Name = "11"; Type = "PTR"; PtrDomainName = "demo-server2" }
            )
        }
    }
    
    # GPO Configuration
    GPOs = @{
        DemoGPO = @{
            Name = "DSP-Demo-GPO"
            Comment = "Demo GPO for DSP testing"
            LinkedTo = $null  # Will link to demo OU
        }
    }
    
    # Site Configuration
    Sites = @{
        DemoSite = @{
            Name = "DSP-Demo-Site"
            Description = "Demo site for DSP testing"
            Subnet = "192.168.200.0/24"
            SiteLink = "DefaultIPSiteLink"
        }
    }
    
    # FGPP Configuration
    FGPPs = @{
        DemoPolicy = @{
            Name = "DSP-Demo-FGPP"
            Precedence = 100
            ComplexityEnabled = $true
            LockoutThreshold = 3
            MinPasswordLength = 12
            PasswordHistoryCount = 24
        }
    }
    
    # Logging Configuration
    Logging = @{
        Path = if ($LogPath) { $LogPath } else { "C:\Logs\DSP-Demo-$(Get-Date -Format 'yyyyMMdd-HHmmss').log" }
        VerboseLogging = $true
    }
}

################################################################################
# HELPER FUNCTIONS
################################################################################

function Write-LogMessage {
    <#
    .SYNOPSIS
        Consistent logging with color-coded output
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet('Info','Success','Warning','Error','Header','SubHeader')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        'Info'      { Write-Host $Message -ForegroundColor Cyan }
        'Success'   { Write-Host $Message -ForegroundColor Green }
        'Warning'   { Write-Host $Message -ForegroundColor Yellow }
        'Error'     { Write-Host $Message -ForegroundColor Red }
        'Header'    { Write-Host "`n$Message" -ForegroundColor White -