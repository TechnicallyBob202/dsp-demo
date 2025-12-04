# DSP-Demo: Active Directory Demo Activity Generator

DSP-Demo is a modular PowerShell system that generates realistic Active Directory changes for Directory Services Protector (DSP) demonstrations. It creates a baseline AD environment, then executes 30+ activity modules that simulate enterprise scenarios—user moves, group modifications, policy changes, security events—across a 15+ minute window.

**Original Author:** Rob Ingenthron (robi@semperis.com)  
**Refactored By:** Bob Lyons  
**Latest Version:** 7.1.0-20251202

---

## Quick Start

### Prerequisites

- PowerShell 5.1+
- Active Directory PowerShell module
- Domain admin credentials on domain controller
- Windows Server 2016+ environment
- Administrator privileges to run scripts

### Basic Usage

```powershell
# Run with default configuration (setup + activity)
.\DSP-Demo-MainScript.ps1

# Run setup phase only
.\DSP-Demo-MainScript.ps1 -SetupOnly

# Use custom configuration paths
.\DSP-Demo-MainScript.ps1 -SetupConfigPath "C:\custom\setup.psd1" -ActivityConfigPath "C:\custom\activity.psd1"
```

---

## How It Works

### Architecture

The system follows a three-phase execution model:

1. **Preflight Checks** — Validates environment, discovers domain controllers, detects DSP server (if available), confirms connectivity
2. **Setup Phase** — Loads 20+ setup modules that build baseline AD infrastructure (OUs, users, groups, computers, policies)
3. **Activity Phase** — Sequentially executes 30 activity modules that modify the environment, creating trackable changes for DSP

### File Structure

```
DSP-Demo/
├── DSP-Demo-MainScript.ps1              # Primary orchestration script
├── Test-ActivityModule.ps1              # Test harness for individual modules
├── DSP-Demo-Config-Setup.psd1           # Setup phase configuration
├── DSP-Demo-Config-Activity.psd1        # Activity phase configuration
├── modules/
│   ├── DSP-Demo-Preflight.psm1          # Environment validation
│   ├── setup/                           # Setup modules (DSP-Demo-Setup-##-Name.psm1)
│   ├── activity/                        # Activity modules (DSP-Demo-Activity-##-Name.psm1)
│   └── lib/                             # Shared helper modules
└── logs/                                # Demo execution logs (created on run)
```

---

## Configuration

### Setup Configuration (DSP-Demo-Config-Setup.psd1)

Defines baseline AD objects. Key sections:

```powershell
General = @{
    DomainName = "{DOMAIN}"           # Auto-resolved at runtime
    AdminUser = "Administrator"        # Domain admin account
}

OUs = @{
    Root = "OU=Demo,{DOMAIN_DN}"      # Demo root OU
    Users = "OU=Users,OU=Demo,{DOMAIN_DN}"
    Groups = "OU=Groups,OU=Demo,{DOMAIN_DN}"
    Computers = "OU=Computers,OU=Demo,{DOMAIN_DN}"
}

Users = @{
    "arose" = @{
        FullName = "Axl Rose"
        Password = "P@ssw0rd123!"
        OU = "{Users}"
    }
    "lskywalker" = @{
        FullName = "Luke Skywalker"
        Password = "P@ssw0rd123!"
        OU = "{Users}"
    }
    # ... more users
}

Groups = @{
    "DemoAdmins" = @{
        Scope = "Global"
        Category = "Security"
        Members = @("arose", "lskywalker")
        OU = "{Groups}"
    }
    # ... more groups
}
```

**Placeholder tokens (expanded at runtime):**
- `{DOMAIN}` → Detected domain FQDN (e.g., "d3.lab")
- `{DOMAIN_DN}` → Domain DN (e.g., "DC=d3,DC=lab")

### Activity Configuration (DSP-Demo-Config-Activity.psd1)

Defines parameters for activity modules. Key sections:

```powershell
General = @{
    DspServer = "dsp.d3.lab"          # DSP server for connectivity tests
    DefaultPassword = "P@ssw0rd123!"
    OperationDelayMs = 500             # Delay between operations (ms)
}

DemoUsers = @{
    PrimaryAdmin = "arose"
    SecondaryAdmin = "lskywalker"
    ServiceAccounts = @("svc_admin", "svc_exchange")
}

BulkUsers = @{
    Prefix = "GdActor-"
    BaseOU = "OU=TEST,OU=Demo,{DOMAIN_DN}"
    Count = 250
}
```

### Customizing Configuration

Edit the `.psd1` files directly. Keep these practices in mind:

- Keep `{DOMAIN}` and `{DOMAIN_DN}` placeholders—they're auto-expanded at runtime for portability
- Don't hardcode domain names; use placeholders
- Password fields should follow complexity rules: uppercase, lowercase, number, special char
- OUs must follow Distinguished Name format: `OU=Name,OU=Parent,{DOMAIN_DN}`
- Groups need both `Scope` (Global/Local/Universal) and `Category` (Security/Distribution)

---

## Running Demos

### Standard Demo Run

```powershell
# From the DSP-Demo directory
cd C:\DSP-Demo
.\DSP-Demo-MainScript.ps1
```

This runs:
1. Preflight validation
2. Setup phase (builds baseline environment)
3. 30 activity modules (simulates enterprise changes over ~15 minutes)

**What happens:**
- Console shows real-time progress with color coding (green = success, yellow = warning, red = error)
- Each module reports completion status
- At phase boundaries, you can review output before proceeding (10-second auto-advance or Y/N prompt)

### Setup Only

Run baseline environment setup without activity:

```powershell
.\DSP-Demo-MainScript.ps1 -SetupOnly
```

Useful for establishing a clean baseline for repeated demo activity runs.

### Test Individual Activity Module

Use the test harness to validate a single activity module in isolation:

```powershell
# Test module 07 (Activity-07-xxx)
.\Test-ActivityModule.ps1 -ModuleNumber 07

# Test module 07, running all setup modules first
.\Test-ActivityModule.ps1 -ModuleNumber 07 -IncludeSetup
```

This skips modules 01-06 and jumps directly to module 07, useful for debugging specific activities.

---

## Understanding the Demo Users

The baseline setup creates demo accounts for activity scenarios:

| User | Full Name | Role | Password |
|------|-----------|------|----------|
| arose | Axl Rose | Primary admin | (from config) |
| lskywalker | Luke Skywalker | Secondary admin | (from config) |
| peter.griffin | Peter Griffin | Standard user | (from config) |
| pmccartney | Paul McCartney | Standard user | (from config) |

Plus 250 bulk test users named `GdActor-001` through `GdActor-250` created in the TEST OU.

Activity modules perform realistic operations on these accounts: moves between OUs, group membership changes, password resets, disabling/enabling, deletions.

---

## Activity Modules

The system executes 30+ activity modules in sequence. Each module performs specific AD changes:

- **Modules 01-05:** Basic user/group operations (moves, group modifications)
- **Modules 06-15:** Security-related changes (privileged group modifications, policy updates)
- **Modules 16-25:** Bulk operations (large-scale user moves, group policy refreshes)
- **Modules 26-30:** Cleanup and recovery scenarios

Each module:
- Reports what it's doing in console output
- Handles errors gracefully (reports but continues)
- Tracks success/failure counts
- Respects timing delays (useful for DSP monitoring windows)

To see what modules exist, list the activity folder:

```powershell
Get-ChildItem -Path "modules/activity/" -Filter "*.psm1" | ForEach-Object { $_.BaseName }
```

---

## Troubleshooting

### "Preflight checks failed"

Check that:
- You're running as Administrator
- You're on a domain-joined Windows Server
- Active Directory PowerShell module is installed: `Get-Module -ListAvailable ActiveDirectory`
- You have connectivity to a domain controller

### "Configuration file not found"

Ensure both config files exist in the script directory:
- `DSP-Demo-Config-Setup.psd1`
- `DSP-Demo-Config-Activity.psd1`

Or provide explicit paths:

```powershell
.\DSP-Demo-MainScript.ps1 -SetupConfigPath "C:\path\to\setup.psd1" -ActivityConfigPath "C:\path\to\activity.psd1"
```

### "Module function not found"

If you see "Function Invoke-ModuleName not found—skipping," the module file exists but doesn't export the expected function. Check:

1. Module file exists in `modules/setup/` or `modules/activity/`
2. Function is named `Invoke-` + the module's readable name (e.g., `DSP-Demo-Activity-07-SomeName.psm1` should export `Invoke-SomeName`)
3. Function has proper `Export-ModuleMember` at end of module

### Demo runs slower than expected

Check `OperationDelayMs` in `DSP-Demo-Config-Activity.psd1`. Default is 500ms between operations. Adjust down for faster execution, up for more realistic enterprise timing.

### Users already exist / Objects can't be created

Setup modules check for existing objects and skip creation. If you need a truly clean state, delete the Demo OU from Active Directory Users and Computers, then run setup again.

---

## Advanced Usage

### Logging

Logs are created in the `logs/` subdirectory (created automatically). Each run generates a timestamped log.

### Custom Configurations

Create variant configuration files for different scenarios:

```powershell
# Run demo with custom configs
.\DSP-Demo-MainScript.ps1 -SetupConfigPath "C:\configs\setup-v2.psd1" -ActivityConfigPath "C:\configs\activity-v2.psd1"
```

### Repeatable Demo Runs

For repeated demos with the same baseline:

1. Run once with full setup: `.\DSP-Demo-MainScript.ps1`
2. On subsequent runs, just reset the environment back to baseline (set user properties, restore group membership)
3. Re-run activity phase without setup

### Extending with Custom Modules

Add new activity modules to `modules/activity/`. Follow naming: `DSP-Demo-Activity-##-DescriptiveName.psm1`

Module structure:

```powershell
function Invoke-DescriptiveName {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Config,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Environment
    )
    
    # Your activity logic here
    # Use $Config for settings, $Environment for domain info
    
    Write-Host "Activity completed" -ForegroundColor Green
}

Export-ModuleMember -Function Invoke-DescriptiveName
```

Then run normally—the orchestration script auto-discovers numbered modules.

---

## Support & Feedback

For issues or questions:
- Check logs in the `logs/` directory
- Review the troubleshooting section above
- Examine the config files for typos or missing objects
- Test individual modules with `Test-ActivityModule.ps1`

---

## Version History

- **7.1.0** (Dec 2024) — Production release; modular refactor of Rob Ingenthron's legacy script
- **7.0.0** (Nov 2024) — Initial refactor: 30 activity modules, split configuration
- **6.x** — Legacy monolithic script era (Invoke-CreateDspChangeDataForDemos)
