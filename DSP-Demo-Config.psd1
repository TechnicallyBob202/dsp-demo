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
        # Set this to your DSP server FQDN if you want to use a specific server
        # Leave empty string "" to auto-discover via SCP
        DspServer = "dsp.d3.lab"
        
        # Number of times to loop the entire script
        LoopCount = 1
        
        # Number of generic test users to create in OU=TEST
        GenericUserCount = 250
        
        # Default password for demo accounts (will prompt if not set)
        DefaultPassword = "P@ssw0rd123!"
        
        # Logging settings
        LogPath = "C:\Logs\DSP-Demo"
        VerboseLogging = $true
    }
    
    #---------------------------------------------------------------------------
    # DEMO USER ACCOUNTS
    #
    # Named demo users that get specific attributes and changes throughout
    # the script to generate interesting DSP change data.
    #
    DemoUsers = @{
        AdminTier0 = @{
            Name = 'Admin-Tier0'
            SamAccountName = 'Admin-Tier0'
            GivenName = 'Admin'
            Surname = 'Tier0'
            DisplayName = 'Admin-Tier0'
            Initials = 'AT0'
            Description = 'Tier 0 Non-Privileged Admin'
            Mail = 'Admin-Tier0@fabrikam.com'
            Title = 'Sr Solution Architect'
            Department = 'Pre-Sales'
            Division = 'Product Sales'
            Company = 'Semperis'
            TelephoneNumber = '408-555-0100'
            City = 'Silicon Valley'
            EmployeeID = '000000100'
            Path = "{LAB_USERS_OU}"
        }
        
        AdminTier1 = @{
            Name = 'Admin-Tier1'
            SamAccountName = 'Admin-Tier1'
            GivenName = 'Admin'
            Surname = 'Tier1'
            DisplayName = 'Admin-Tier1'
            Initials = 'AT1'
            Description = 'Tier 1 Admin Account'
            Mail = 'Admin-Tier1@fabrikam.com'
            Title = 'Infrastructure Admin'
            Department = 'IT Operations'
            Division = 'Infrastructure'
            Company = 'Semperis'
            TelephoneNumber = '408-555-0101'
            City = 'Silicon Valley'
            EmployeeID = '000000101'
            Path = "{LAB_USERS_OU}"
        }
        
        OpsAdmin1 = @{
            Name = 'OpsAdmin1'
            SamAccountName = 'opsadmin1'
            GivenName = 'Operations'
            Surname = 'Admin'
            DisplayName = 'OpsAdmin1'
            Initials = 'OA1'
            Description = 'Ops Admin - Tier 1 admin account'
            Mail = 'opsadmin1@fabrikam.com'
            Title = 'Operations Manager'
            Department = 'IT Operations'
            Division = 'Operations'
            Company = 'Semperis'
            TelephoneNumber = '408-555-0200'
            City = 'Silicon Valley'
            EmployeeID = '000000200'
            Path = "{LAB_USERS_OU}"
        }
        
        DemoUser1 = @{
            Name = 'Axl Rose'
            SamAccountName = 'arose'
            GivenName = 'William'
            Surname = 'Rose'
            DisplayName = 'Axl Rose'
            Initials = 'AFR'
            Description = 'Coder'
            Mail = 'arose@fabrikam.com'
            Title = 'Application Mgr'
            Department = 'Sales'
            Division = 'Rock Analysis'
            Company = 'Roses and Guns'
            TelephoneNumber = '408-555-1212'
            TelephoneNumberAlt = '(000) 867-5309'
            FAX = '(408) 555-1212'
            FAXalt = '+501 11-0001'
            City = 'City of Angels'
            EmployeeID = '000123456'
            Path = "{LAB_USERS_OU}"
        }
        
        DemoUser2 = @{
            Name = 'Brian May'
            SamAccountName = 'bmay'
            GivenName = 'Brian'
            Surname = 'May'
            DisplayName = 'Brian May'
            Initials = 'BHM'
            Description = 'Sales Engineer'
            Mail = 'bmay@fabrikam.com'
            Title = 'Sales Engineer'
            Department = 'Engineering'
            Division = 'Solutions'
            Company = 'Semperis'
            TelephoneNumber = '408-555-2200'
            TelephoneNumberAlt = '408-555-2201'
            City = 'London'
            EmployeeID = '000123457'
            Path = "{LAB_USERS_OU}"
        }
        
        DemoUser3 = @{
            Name = 'Freddie Mercury'
            SamAccountName = 'fmercury'
            GivenName = 'Freddie'
            Surname = 'Mercury'
            DisplayName = 'Freddie Mercury'
            Initials = 'FM'
            Description = 'Product Manager'
            Mail = 'fmercury@fabrikam.com'
            Title = 'Product Manager'
            Department = 'Product'
            Division = 'Engineering'
            Company = 'Semperis'
            TelephoneNumber = '408-555-3300'
            City = 'London'
            EmployeeID = '000123458'
            Path = "{LAB_USERS_OU}"
        }
        
        DemoUser4 = @{
            Name = 'Roger Taylor'
            SamAccountName = 'rtaylor'
            GivenName = 'Roger'
            Surname = 'Taylor'
            DisplayName = 'Roger Taylor'
            Initials = 'RMT'
            Description = 'Support Engineer'
            Mail = 'rtaylor@fabrikam.com'
            Title = 'Support Engineer'
            Department = 'Support'
            Division = 'Operations'
            Company = 'Semperis'
            TelephoneNumber = '408-555-4400'
            City = 'London'
            EmployeeID = '000123459'
            Path = "{LAB_USERS_OU}"
        }
        
        DemoUser5 = @{
            Name = 'John Deacon'
            SamAccountName = 'jdeacon'
            GivenName = 'John'
            Surname = 'Deacon'
            DisplayName = 'John Deacon'
            Initials = 'JD'
            Description = 'Developer'
            Mail = 'jdeacon@fabrikam.com'
            Title = 'Developer'
            Department = 'Engineering'
            Division = 'Development'
            Company = 'Semperis'
            TelephoneNumber = '408-555-5500'
            City = 'London'
            EmployeeID = '000123460'
            Path = "{LAB_USERS_OU}"
        }
        
        DemoUser6 = @{
            Name = 'David Bowie'
            SamAccountName = 'dbowie'
            GivenName = 'David'
            Surname = 'Bowie'
            DisplayName = 'David Bowie'
            Initials = 'DB'
            Description = 'System Administrator'
            Mail = 'dbowie@fabrikam.com'
            Title = 'System Administrator'
            Department = 'IT Operations'
            Division = 'Operations'
            Company = 'Semperis'
            TelephoneNumber = '408-555-6600'
            City = 'London'
            EmployeeID = '000123461'
            Path = "{LAB_USERS_OU}"
        }
        
        DemoUser7 = @{
            Name = 'Prince'
            SamAccountName = 'prince'
            GivenName = 'Prince'
            Surname = 'Rogers'
            DisplayName = 'Prince'
            Initials = 'PR'
            Description = 'Database Administrator'
            Mail = 'prince@fabrikam.com'
            Title = 'Database Administrator'
            Department = 'Data Services'
            Division = 'Engineering'
            Company = 'Semperis'
            TelephoneNumber = '408-555-7700'
            City = 'Minneapolis'
            EmployeeID = '000123462'
            Path = "{LAB_USERS_OU}"
        }
        
        DemoUser8 = @{
            Name = 'Michael Jackson'
            SamAccountName = 'mjackson'
            GivenName = 'Michael'
            Surname = 'Jackson'
            DisplayName = 'Michael Jackson'
            Initials = 'MJ'
            Description = 'Security Officer'
            Mail = 'mjackson@fabrikam.com'
            Title = 'Security Officer'
            Department = 'Security'
            Division = 'Operations'
            Company = 'Semperis'
            TelephoneNumber = '408-555-8800'
            City = 'Los Angeles'
            EmployeeID = '000123463'
            Path = "{LAB_USERS_OU}"
        }
        
        DemoUser9 = @{
            Name = 'Madonna'
            SamAccountName = 'madonna'
            GivenName = 'Madonna'
            Surname = 'Veronica'
            DisplayName = 'Madonna'
            Initials = 'MV'
            Description = 'Help Desk Manager'
            Mail = 'madonna@fabrikam.com'
            Title = 'Help Desk Manager'
            Department = 'Support'
            Division = 'Operations'
            Company = 'Semperis'
            TelephoneNumber = '408-555-9900'
            City = 'New York'
            EmployeeID = '000123464'
            Path = "{LAB_USERS_OU}"
        }
        
        DemoUser10 = @{
            Name = 'Kurt Cobain'
            SamAccountName = 'kcobain'
            GivenName = 'Kurt'
            Surname = 'Cobain'
            DisplayName = 'Kurt Cobain'
            Initials = 'KC'
            Description = 'Network Engineer'
            Mail = 'kcobain@fabrikam.com'
            Title = 'Network Engineer'
            Department = 'Networking'
            Division = 'Infrastructure'
            Company = 'Semperis'
            TelephoneNumber = '408-555-0010'
            City = 'Seattle'
            EmployeeID = '000123465'
            Path = "{LAB_USERS_OU}"
        }
        
        AutomationAcct1 = @{
            Name = 'AutomationAcct1'
            SamAccountName = 'AutomationAcct1'
            GivenName = 'Automation'
            Surname = 'Account'
            DisplayName = 'AutomationAcct1'
            Initials = 'AA'
            Description = 'Automation Account'
            Mail = 'automation@fabrikam.com'
            Title = 'Automation Account'
            Department = 'IT Operations'
            Division = 'Automation'
            Company = 'Semperis'
            EmployeeID = '000999001'
            Path = "{LAB_USERS_OU}"
        }
        
        MonitoringAcct1 = @{
            Name = 'MonitoringAcct1'
            SamAccountName = 'MonitoringAcct1'
            GivenName = 'Monitoring'
            Surname = 'Account'
            DisplayName = 'MonitoringAcct1'
            Initials = 'MA'
            Description = 'Monitoring Account'
            Mail = 'monitoring@fabrikam.com'
            Title = 'Monitoring Account'
            Department = 'IT Operations'
            Division = 'Monitoring'
            Company = 'Semperis'
            EmployeeID = '000999002'
            Path = "{LAB_USERS_OU}"
        }
    }
    
    #---------------------------------------------------------------------------
    # DEMO GROUP ACCOUNTS
    #
    # Named demo groups created to show group membership changes and 
    # group object modifications
    #
    DemoGroups = @{
        SpecialLabUsers = @{
            Name = 'SpecialLabUsers'
            Description = 'Special Lab Users Group'
            Path = "{LAB_GROUPS_OU}"
            Members = @('arose', 'bmay', 'fmercury')
        }
        
        SpecialLabAdmins = @{
            Name = 'SpecialLabAdmins'
            Description = 'Special Lab Admins Group'
            Path = "{LAB_GROUPS_OU}"
            Members = @('Admin-Tier0', 'Admin-Tier1', 'opsadmin1')
        }
        
        PizzaParty = @{
            Name = 'PizzaParty'
            Description = 'Pizza Party Planning Group'
            Path = "{LAB_GROUPS_OU}"
            Members = @('madonna', 'mjackson')
        }
        
        PartyPlannersGroup = @{
            Name = 'PartyPlanners'
            Description = 'Event Planning Group'
            Path = "{LAB_GROUPS_OU}"
            Members = @('dbowie', 'prince')
        }
    }
    
    #---------------------------------------------------------------------------
    # ORGANIZATIONAL UNITS (OUs)
    #---------------------------------------------------------------------------
    OUs = @{
        # Main demo OU structure
        DemoOU = @{
            Name = "DSP-Demo-Objects"
            Description = "OU for DSP demo objects"
            Path = "{DOMAIN_DN}"
            ProtectFromAccidentalDeletion = $false
        }
        
        # Lab Users OU
        LabUsersOU = @{
            Name = "Lab Users"
            Description = "Lab user accounts"
            Path = "OU=DSP-Demo-Objects,{DOMAIN_DN}"
            ProtectFromAccidentalDeletion = $false
        }
        
        # Lab Groups OU
        LabGroupsOU = @{
            Name = "Lab Groups"
            Description = "Lab group accounts"
            Path = "OU=DSP-Demo-Objects,{DOMAIN_DN}"
            ProtectFromAccidentalDeletion = $false
        }
        
        # Lab Computers OU
        LabComputersOU = @{
            Name = "Lab Computers"
            Description = "Lab computer accounts"
            Path = "OU=DSP-Demo-Objects,{DOMAIN_DN}"
            ProtectFromAccidentalDeletion = $false
        }
        
        # TEST OU for generic user creation/deletion demos
        TestOU = @{
            Name = "TEST"
            Description = "Test OU - for demonstrating OU recovery"
            Path = "OU=DSP-Demo-Objects,{DOMAIN_DN}"
            ProtectFromAccidentalDeletion = $false
            PopulateWithUsers = $true
            UserCount = 5
            DeleteAfterCreation = $true
        }
        
        # Tier 0 Assets OU - highly restricted
        TierZeroOU = @{
            Name = "Tier-0-Assets"
            Description = "Tier 0 assets - Highly restricted access"
            Path = "{DOMAIN_DN}"
            ProtectFromAccidentalDeletion = $true
            RestrictedAccess = $true
            AllowedAdminGroup = "Tier-0-Admins"
        }
    }
    
    #---------------------------------------------------------------------------
    # DNS CONFIGURATION
    #---------------------------------------------------------------------------
    DNS = @{
        # Forward lookup zone configuration
        ForwardZone = @{
            Name = "{DOMAIN}"
            CreateZone = $false
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
            CreateZone = $true
            Records = @(
                @{Name = "10"; Type = "PTR"; PtrDomainName = "demo-server1.{DOMAIN}"}
                @{Name = "11"; Type = "PTR"; PtrDomainName = "demo-server2.{DOMAIN}"}
                @{Name = "12"; Type = "PTR"; PtrDomainName = "demo-server3.{DOMAIN}"}
            )
        }
        
        # Demo zone for deletion demos
        DemoZone = @{
            Name = "demo-zone.local"
            CreateZone = $true
            ReplicationScope = "Domain"
            Records = @(
                @{Name = "test1"; Type = "A"; IPv4Address = "10.10.10.10"}
                @{Name = "test2"; Type = "A"; IPv4Address = "10.10.10.11"}
                @{Name = "test3"; Type = "A"; IPv4Address = "10.10.10.12"}
                @{Name = "www"; Type = "CNAME"; HostNameAlias = "test1.demo-zone.local"}
            )
            DeleteAfterCreation = $true
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
        }
        
        # Questionable GPO for policy change demos
        QuestionableGPO = @{
            Name = "Questionable-Policy-GPO"
            Comment = "GPO with questionable settings for demo purposes"
            LinkedTo = $null
        }
        
        # SMB Client Policy GPO
        SMBClientGPO = @{
            Name = "Lab-SMB-Client-Policy"
            Comment = "SMB client security policy for lab"
            LinkedTo = "OU=DSP-Demo-Objects,{DOMAIN_DN}"
        }
        
        # Default Domain Policy modifications
        DefaultDomainPolicy = @{
            ModifyMinPasswordLength = $true
            NewMinPasswordLength = 8
            ModifyAccountLockoutThreshold = $true
            NewAccountLockoutThreshold = 11
        }
    }
    
    #---------------------------------------------------------------------------
    # AD SITES AND SERVICES
    #---------------------------------------------------------------------------
    Sites = @{
        # Demo site
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
            SiteLink = "DefaultIPSiteLink"
        }
        
        # Additional demo subnets
        DemoSubnets = @(
            @{Name = "192.168.200.0/24"; Description = "Lab Subnet 1"; Location = "Lab"}
            @{Name = "192.168.201.0/24"; Description = "Lab Subnet 2"; Location = "Lab"}
        )
    }
    
    #---------------------------------------------------------------------------
    # FGPP (Fine-Grained Password Policies)
    #---------------------------------------------------------------------------
    FGPP = @{
        # Demo FGPP
        DemoPolicy = @{
            Name = "DemoPwdPolicy1"
            Description = "Demo fine-grained password policy"
            Precedence = 10
            MinPasswordLength = 10
            PasswordHistoryCount = 5
            MaxPasswordAge = 90
            MinPasswordAge = 1
            LockoutThreshold = 10
            LockoutDuration = 30
            LockoutObservationWindow = 30
            AppliesTo = @()  # Will apply to specific groups
        }
    }
    
    #---------------------------------------------------------------------------
    # ACCOUNT LOCKOUT CONFIGURATION
    #---------------------------------------------------------------------------
    AccountLockout = @{
        # User to lock out for demos
        UserToLockout = "DemoUser1"
        # Number of bad password attempts to trigger lockout
        BadPasswordAttempts = 11
    }
    
    #---------------------------------------------------------------------------
    # CREDENTIAL MANAGEMENT FOR ALTERNATE ADMIN
    #---------------------------------------------------------------------------
    CredentialManagement = @{
        # Alternate admin account for demonstrating "who" changes
        AlternateAdmin = @{
            Name = "OpsAdmin1"
            SamAccountName = "opsadmin1"
        }
    }
    
    #---------------------------------------------------------------------------
    # ATTRIBUTE CHANGES FOR DEMO
    #
    # These are specific attribute changes that will be made to demo users
    # to show change tracking in DSP
    #---------------------------------------------------------------------------
    AttributeChanges = @{
        DemoUser1 = @{
            # Phone number changes
            TelephoneNumberChanges = @(
                @{Attribute = "telephoneNumber"; OldValue = "408-555-1212"; NewValue = "(000) 867-5309"}
            )
            # Title changes
            TitleChanges = @(
                @{OldValue = "Application Mgr"; NewValue = "CEO"}
                @{OldValue = "CEO"; NewValue = "CTO"}
                @{OldValue = "CTO"; NewValue = "Application Mgr"}
            )
            # FAX changes
            FAXChanges = @(
                @{Attribute = "facsimileTelephoneNumber"; OldValue = "(408) 555-1212"; NewValue = "+501 11-0001"}
            )
        }
    }
}