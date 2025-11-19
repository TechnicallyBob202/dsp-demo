################################################################################
##
## DSP-Demo-Config.psd1
##
## Configuration file for DSP Demo script suite
## This centralizes all the hardcoded values from the original script
##
################################################################################

@{
    #---------------------------------------------------------------------------
    # GENERAL SETTINGS
    #---------------------------------------------------------------------------
    General = @{
        # Number of times to loop the entire script (default: 1)
        LoopCount = 1
        
        # Number of generic test users to create in OU=TEST
        GenericUserCount = 250
        
        # Default password for demo accounts (will prompt if not set)
        # IMPORTANT: In production, leave this blank and use prompts!
        DefaultPassword = "P@ssw0rd123!"
        
        # Logging settings
        LogPath = "C:\Logs\DSP-Demo"
        VerboseLogging = $true
    }
    
    #---------------------------------------------------------------------------
    # DEMO USER ACCOUNTS
    #
    # These are the named demo users that get specific attributes and changes
    # throughout the script to generate interesting DSP change data.
    #
    # Original script context:
    # - DemoUser1 (Axl Rose): Primary demo user, gets many attribute changes
    # - DemoUser2 (Slash Hudson): Used for account lockout demos
    # - DemoUser3 (Duff McKagan): Used for auto-undo rule testing (Title attribute)
    # - DemoUser4 (Paul McCartney): Additional demo user for variety
    #---------------------------------------------------------------------------
    DemoUsers = @{
        DemoUser1 = @{
            Name = "Axl Rose"
            GivenName = "Axl"
            Surname = "Rose"
            SamAccountName = "arose"
            UserPrincipalName = "arose@{DOMAIN}"  # {DOMAIN} will be replaced
            DisplayName = "Axl Rose"
            Description = "Demo user #1 for DSP testing - Primary demo account"
            Department = "Music"
            Title = "Lead Singer"
            Company = "Guns N Roses"
            Office = "Los Angeles"
            StreetAddress = "123 Sunset Blvd"
            City = "Los Angeles"
            State = "CA"
            PostalCode = "90028"
            Country = "US"
            TelephoneNumber = "555-0101"
            MobilePhone = "555-0102"
            Fax = "555-0103"
            EmployeeID = "100001"
            EmployeeNumber = "EMP-001"
            Manager = $null  # Set to another user's DN if desired
            Enabled = $true
            PasswordNeverExpires = $false
            # This user gets extensive attribute changes throughout the script
            # for demo purposes - see User module for specific change operations
        }
        
        DemoUser2 = @{
            Name = "Slash Hudson"
            GivenName = "Slash"
            Surname = "Hudson"
            SamAccountName = "shudson"
            UserPrincipalName = "shudson@{DOMAIN}"
            DisplayName = "Slash Hudson"
            Description = "Demo user #2 for DSP testing - Account lockout demonstrations"
            Department = "Music"
            Title = "Lead Guitarist"
            Company = "Guns N Roses"
            Office = "Los Angeles"
            EmployeeID = "100002"
            Enabled = $true
            PasswordNeverExpires = $false
            # This user is used for account lockout and brute force attack demos
        }
        
        DemoUser3 = @{
            Name = "Duff McKagan"
            GivenName = "Duff"
            Surname = "McKagan"
            SamAccountName = "dmckagan"
            UserPrincipalName = "dmckagan@{DOMAIN}"
            DisplayName = "Duff McKagan"
            Description = "Demo user #3 for DSP testing - Auto-undo rule trigger"
            Department = "Music"
            Title = "Bass Player"
            Company = "Guns N Roses"
            EmployeeID = "100003"
            Enabled = $true
            # This user's Title attribute is changed to "CEO" to trigger auto-undo rules
            # IMPORTANT: You must manually create the auto-undo rule in DSP for this to work!
            # Rule: When Title changes to "CEO" for this user, automatically undo the change
        }
        
        DemoUser4 = @{
            Name = "Paul McCartney"
            GivenName = "Paul"
            Surname = "McCartney"
            SamAccountName = "pmccartney"
            UserPrincipalName = "pmccartney@{DOMAIN}"
            DisplayName = "Paul McCartney"
            Description = "Demo user #4 for DSP testing - Additional variety"
            Department = "Music"
            Title = "Bassist"
            Company = "The Beatles"
            EmployeeID = "100004"
            Enabled = $true
        }
    }
    
    #---------------------------------------------------------------------------
    # ADMINISTRATIVE ACCOUNTS
    #
    # Special administrative accounts used for different scenarios
    #---------------------------------------------------------------------------
    AdminUsers = @{
        # Tier 2 Administrator
        # Used for general admin operations and group membership changes
        Tier2Admin = @{
            Name = "T2 Admin Demo"
            GivenName = "T2"
            Surname = "Admin"
            SamAccountName = "t2admin"
            UserPrincipalName = "t2admin@{DOMAIN}"
            DisplayName = "T2 Admin Demo"
            Description = "Tier 2 administrator for DSP demos"
            Department = "IT Operations"
            Title = "Tier 2 Administrator"
            Company = "{COMPANY}"
            EmployeeID = "200001"
            Enabled = $true
            MemberOf = @("Domain Admins")  # Groups to add user to
        }
        
        # Operations Admin
        # Used with Credential Manager to make changes as a different user
        # This demonstrates "who made the change" scenarios in DSP
        OpsAdmin1 = @{
            Name = "Ops Admin Tier 1"
            GivenName = "Ops"
            Surname = "Admin"
            SamAccountName = "opsadmin1"
            UserPrincipalName = "opsadmin1@{DOMAIN}"
            DisplayName = "Operations Admin - Tier 1"
            Description = "Tier 1 operations administrator - Used for alternative credential demos"
            Department = "IT Operations"
            Title = "Operations Administrator"
            EmployeeID = "200002"
            Enabled = $true
            MemberOf = @("Account Operators")  # This user makes changes to show different "Changed By"
        }
        
        # Unprivileged DSP Admin
        # Used for DSP operations without full Domain Admin rights
        DspAdmin = @{
            Name = "DSP Admin Demo"
            GivenName = "DSP"
            Surname = "Admin"
            SamAccountName = "dspadmin"
            UserPrincipalName = "dspadmin@{DOMAIN}"
            DisplayName = "DSP Administrator (Unprivileged)"
            Description = "Unprivileged DSP administrator for demonstrations"
            Department = "IT Security"
            Title = "DSP Administrator"
            EmployeeID = "200003"
            Enabled = $true
            # This user has DSP admin rights but NOT Domain Admin
        }
    }
    
    #---------------------------------------------------------------------------
    # GROUP OBJECTS
    #---------------------------------------------------------------------------
    Groups = @{
        # Special Lab Admins - Used for auto-undo demo
        # This group's membership is cleared to trigger auto-undo rule
        SpecialLabAdmins = @{
            Name = "DSP-LAB-Special-Admins"
            SamAccountName = "DSP-LAB-Special-Admins"
            DisplayName = "DSP Lab Special Administrators"
            Description = "Special lab administrators group for DSP demos - Auto-undo trigger"
            GroupCategory = "Security"
            GroupScope = "Global"
            ManagedBy = "t2admin"
            Members = @("arose", "shudson", "t2admin")
            # IMPORTANT: Create auto-undo rule for when this group is emptied!
        }
        
        # Special Lab Users
        SpecialLabUsers = @{
            Name = "DSP-LAB-Special-Users"
            SamAccountName = "DSP-LAB-Special-Users"
            DisplayName = "DSP Lab Special Users"
            Description = "Special lab users group for DSP demos"
            GroupCategory = "Security"
            GroupScope = "Global"
            Members = @("arose", "shudson", "dmckagan", "pmccartney")
        }
        
        # Helpdesk Operations
        HelpdeskOps = @{
            Name = "Helpdesk-Operations"
            SamAccountName = "Helpdesk-Ops"
            DisplayName = "Helpdesk Operations Team"
            Description = "Helpdesk operations team members"
            GroupCategory = "Security"
            GroupScope = "Global"
            Members = @("opsadmin1")
        }
        
        # Tier 0 Admins - High security group
        TierZeroAdmins = @{
            Name = "Tier-0-Admins"
            SamAccountName = "Tier0Admins"
            DisplayName = "Tier 0 Administrators"
            Description = "Tier 0 privileged administrators - Highest security"
            GroupCategory = "Security"
            GroupScope = "Universal"
            Members = @("Administrator", "t2admin")
        }
    }
    
    #---------------------------------------------------------------------------
    # ORGANIZATIONAL UNIT STRUCTURE
    #---------------------------------------------------------------------------
    OUs = @{
        # Root OU for all demo objects
        DemoRoot = @{
            Name = "DSP-Demo-Objects"
            Description = "Root OU for all DSP demonstration objects"
            Path = "{DOMAIN_DN}"  # Will be replaced with domain DN
            ProtectFromAccidentalDeletion = $true
        }
        
        # Users OU under demo root
        DemoUsers = @{
            Name = "Users"
            Description = "Demo user accounts"
            ParentOU = "DSP-Demo-Objects"
            ProtectFromAccidentalDeletion = $true
        }
        
        # Groups OU under demo root
        DemoGroups = @{
            Name = "Groups"
            Description = "Demo group objects"
            ParentOU = "DSP-Demo-Objects"
            ProtectFromAccidentalDeletion = $true
        }
        
        # Computers OU under demo root
        DemoComputers = @{
            Name = "Computers"
            Description = "Demo computer objects"
            ParentOU = "DSP-Demo-Objects"
            ProtectFromAccidentalDeletion = $true
        }
        
        # Generic test users OU (at domain root)
        TestOU = @{
            Name = "TEST"
            Description = "Generic test user accounts (bulk created)"
            Path = "{DOMAIN_DN}"
            ProtectFromAccidentalDeletion = $false
        }
        
        # OU that gets deleted for recovery demos
        # This OU is created, populated, then deleted to demonstrate OU recovery
        ToBeDeleted = @{
            Name = "DeleteMe-OU"
            Description = "OU for deletion and recovery demonstrations - Will be deleted!"
            ParentOU = "DSP-Demo-Objects"
            ProtectFromAccidentalDeletion = $false
            PopulateWithUsers = $true  # Create some users in this OU
            UserCount = 5
            DeleteAfterCreation = $true  # This OU will be deleted later in the script
        }
        
        # Highly restricted Tier 0 OU
        # This OU has special ACLs to restrict access
        TierZero = @{
            Name = "Tier-0-Assets"
            Description = "Tier 0 assets - Highly restricted access"
            Path = "{DOMAIN_DN}"
            ProtectFromAccidentalDeletion = $true
            RestrictedAccess = $true  # Special ACLs will be applied
            AllowedAdminGroup = "Tier-0-Admins"
        }
    }
    
    #---------------------------------------------------------------------------
    # DNS CONFIGURATION
    #---------------------------------------------------------------------------
    DNS = @{
        # Forward lookup zone configuration
        ForwardZone = @{
            Name = "{DOMAIN}"  # Will use domain FQDN
            CreateZone = $false  # Usually zone already exists
            Records = @(
                @{Name = "demo-server1"; Type = "A"; IPv4Address = "192.168.100.10"}
                @{Name = "demo-server2"; Type = "A"; IPv4Address = "192.168.100.11"}
                @{Name = "demo-server3"; Type = "A"; IPv4Address = "192.168.100.12"}
                @{Name = "demo-alias"; Type = "CNAME"; HostNameAlias = "demo-server1.{DOMAIN}"}
                @{Name = "demo-web"; Type = "CNAME"; HostNameAlias = "demo-server2.{DOMAIN}"}
            )
        }
        
        # Reverse lookup zone configuration
        ReverseZone = @{
            Name = "100.168.192.in-addr.arpa"
            NetworkID = "192.168.100.0/24"
            CreateZone = $true  # Create this zone for demos
            Records = @(
                @{Name = "10"; Type = "PTR"; PtrDomainName = "demo-server1.{DOMAIN}"}
                @{Name = "11"; Type = "PTR"; PtrDomainName = "demo-server2.{DOMAIN}"}
                @{Name = "12"; Type = "PTR"; PtrDomainName = "demo-server3.{DOMAIN}"}
            )
        }
        
        # Additional forward zone for deletion demos
        # This zone is created and then deleted to demo zone recovery
        DemoZone = @{
            Name = "demo-zone.local"
            CreateZone = $true
            ReplicationScope = "Domain"  # "Forest", "Domain", or "Legacy"
            Records = @(
                @{Name = "test1"; Type = "A"; IPv4Address = "10.10.10.10"}
                @{Name = "test2"; Type = "A"; IPv4Address = "10.10.10.11"}
                @{Name = "test3"; Type = "A"; IPv4Address = "10.10.10.12"}
                @{Name = "www"; Type = "CNAME"; HostNameAlias = "test1.demo-zone.local"}
            )
            DeleteAfterCreation = $true  # Zone will be deleted for recovery demo
        }
    }
    
    #---------------------------------------------------------------------------
    # GPO CONFIGURATION
    #---------------------------------------------------------------------------
    GPOs = @{
        # Demo GPO with various settings
        DemoGPO = @{
            Name = "DSP-Demo-GPO"
            Comment = "Demo GPO for DSP change tracking demonstrations"
            LinkedTo = "OU=DSP-Demo-Objects,{DOMAIN_DN}"
            Settings = @{
                # Registry-based policies
                RegistrySettings = @(
                    @{
                        Key = "HKLM\Software\Policies\Microsoft\Windows\System"
                        ValueName = "DontDisplayNetworkSelectionUI"
                        Value = 1
                        Type = "DWord"
                    }
                )
            }
        }
        
        # "Questionable GPO" - for demonstrating policy changes
        QuestionableGPO = @{
            Name = "Questionable-Policy-GPO"
            Comment = "GPO with questionable settings for demo purposes"
            LinkedTo = $null  # Not linked initially
            Settings = @{}
        }
        
        # SMB Client Policy GPO
        SMBClientGPO = @{
            Name = "Lab-SMB-Client-Policy"
            Comment = "SMB client security policy for lab"
            LinkedTo = "OU=DSP-Demo-Objects,{DOMAIN_DN}"
            Settings = @{}
        }
        
        # Default Domain Policy modifications
        # The script modifies the Default Domain Policy to change password settings
        # and account lockout settings for demo purposes
        DefaultDomainPolicy = @{
            ModifyMinPasswordLength = $true
            NewMinPasswordLength = 8
            ModifyAccountLockoutThreshold = $true
            NewAccountLockoutThreshold = 11  # Changed from default of 0
            # These changes enable account lockout demos
        }
    }
    
    #---------------------------------------------------------------------------
    # AD SITES AND SERVICES
    #---------------------------------------------------------------------------
    Sites = @{
        # Demo site for AD Sites and Services changes
        DemoSite = @{
            Name = "SemperisLabs"
            Description = "AD site for Semperis Labs"
            Location = "USA-TX-Labs"
            Subnets = @(
                @{
                    Name = "10.3.22.0/24"
                    Description = "AD subnet for Semperis Labs"
                    Location = "USA-TX-Labs"
                }
            )
            SiteLink = "DefaultIPSiteLink"  # Link this site to default site link
        }
    }
    
    # Subnet modifications
    # The script creates, modifies, and deletes subnets for demo purposes
    Subnets = @{
        DemoSubnets = @(
            @{Name = "192.168.200.0/24"; Site = "Default-First-Site-Name"; Description = "Demo Subnet 1"; Location = "Lab"}
            @{Name = "192.168.201.0/24"; Site = "Default-First-Site-Name"; Description = "Demo Subnet 2"; Location = "Lab"}
            @{Name = "192.168.202.0/24"; Site = "Default-First-Site-Name"; Description = "Demo Subnet 3"; Location = "Lab"}
        )
    }
    
    #---------------------------------------------------------------------------
    # FINE-GRAINED PASSWORD POLICIES (FGPP)
    #---------------------------------------------------------------------------
    FGPPs = @{
        # FGPP for special lab users
        SpecialLabUsersFGPP = @{
            Name = "SpecialLabUsers_PSO"
            Precedence = 100
            ComplexityEnabled = $true
            LockoutDuration = "00:30:00"  # 30 minutes
            LockoutObservationWindow = "00:30:00"
            LockoutThreshold = 5
            MaxPasswordAge = "42.00:00:00"  # 42 days
            MinPasswordAge = "1.00:00:00"  # 1 day
            MinPasswordLength = 12
            PasswordHistoryCount = 24
            ReversibleEncryptionEnabled = $false
            AppliesTo = "CN=DSP-LAB-Special-Users,OU=Groups,OU=DSP-Demo-Objects,{DOMAIN_DN}"
        }
        
        # Additional demo FGPP that gets created and deleted
        DemoFGPP = @{
            Name = "DSP-Demo-FGPP"
            Precedence = 200
            ComplexityEnabled = $true
            LockoutThreshold = 3
            MinPasswordLength = 14
            PasswordHistoryCount = 12
            DeleteAfterCreation = $true  # This FGPP will be deleted for recovery demo
        }
    }
    
    #---------------------------------------------------------------------------
    # WMI FILTERS
    #
    # WMI filters are created to demonstrate the grouping function in DSP Changes.
    # Multiple WMI filters with description changes show nicely in the grouped view.
    #---------------------------------------------------------------------------
    WMIFilters = @{
        Filter1 = @{
            Name = "WMI-Filter-Windows-10"
            Description = "Windows 10 operating systems"
            Query = "SELECT * FROM Win32_OperatingSystem WHERE Caption LIKE '%Windows 10%'"
        }
        Filter2 = @{
            Name = "WMI-Filter-Windows-Server"
            Description = "Windows Server operating systems"
            Query = "SELECT * FROM Win32_OperatingSystem WHERE Caption LIKE '%Server%'"
        }
        Filter3 = @{
            Name = "WMI-Filter-Domain-Controllers"
            Description = "Domain Controller systems"
            Query = "SELECT * FROM Win32_OperatingSystem WHERE ProductType = '2'"
        }
    }
    
    #---------------------------------------------------------------------------
    # SPECIAL COMPUTER OBJECTS
    #
    # These are created in the Tier-0-Assets OU for restricted access demos
    #---------------------------------------------------------------------------
    TierZeroComputers = @(
        @{
            Name = "DC-TIER0-01"
            Description = "Tier 0 Domain Controller"
            Location = "Primary Datacenter"
        }
        @{
            Name = "PKI-ROOT-CA"
            Description = "Root Certificate Authority"
            Location = "Secure Datacenter"
        }
        @{
            Name = "BASTION-HOST01"
            Description = "Bastion host for restricted privileged access"
            Location = "DMZ"
        }
    )
    
    #---------------------------------------------------------------------------
    # TIMING CONFIGURATION
    #
    # Sleep/wait times throughout the script for replication and pacing
    #---------------------------------------------------------------------------
    Timing = @{
        # Standard replication wait
        DefaultReplicationWait = 10
        
        # Longer wait for specific operations
        ExtendedReplicationWait = 20
        
        # Wait after auto-undo trigger (auto-undo takes longer)
        AutoUndoWait = 20
        
        # Wait before account lockout attempts
        LockoutAttemptDelay = 2
        
        # Wait between major sections
        SectionTransitionWait = 5
        
        # Final replication wait before script completion
        FinalReplicationWait = 20
    }
    
    #---------------------------------------------------------------------------
    # ATTACK SIMULATION SETTINGS
    #---------------------------------------------------------------------------
    AttackSimulation = @{
        # Account lockout / brute force simulation
        AccountLockout = @{
            TargetUser = "shudson"  # DemoUser2
            BadPasswordAttempts = 15  # More than the threshold
            DelayBetweenAttempts = 2  # seconds
        }
        
        # Password spray simulation
        PasswordSpray = @{
            TargetUsers = @("arose", "shudson", "dmckagan", "pmccartney")
            BadPassword = "WrongPassword123!"
            AttemptsPerUser = 3
            DelayBetweenUsers = 1  # seconds
        }
    }
    
    #---------------------------------------------------------------------------
    # USER ATTRIBUTE CHANGE SCENARIOS
    #
    # Specific attribute changes made throughout the script to generate
    # interesting change data in DSP
    #---------------------------------------------------------------------------
    AttributeChangeScenarios = @{
        # Department changes (shows organizational movement)
        DepartmentChanges = @(
            @{User = "arose"; NewValue = "Executive Management"}
            @{User = "shudson"; NewValue = "Engineering"}
            @{User = "dmckagan"; NewValue = "Finance"}
        )
        
        # Title changes (job role changes)
        TitleChanges = @(
            @{User = "arose"; NewValue = "Chief Executive Officer"}
            @{User = "dmckagan"; NewValue = "CEO"}  # This triggers auto-undo!
        )
        
        # Fax number changes (demonstrates attribute modifications)
        FaxChanges = @(
            @{User = "arose"; NewValue = "555-9999"}
            @{User = "shudson"; NewValue = "555-8888"}
        )
        
        # Manager changes (organizational hierarchy)
        ManagerChanges = @(
            @{User = "shudson"; ManagerSamAccountName = "arose"}
            @{User = "dmckagan"; ManagerSamAccountName = "arose"}
        )
    }
}
