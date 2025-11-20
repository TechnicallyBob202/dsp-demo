################################################################################
##
## DSP-Demo-Config.psd1 (Corrected Structure)
##
## Configuration file for DSP Demo script suite with OUs matching original script.
## All top-level OUs created at domain root (no DSP-Demo-Objects wrapper).
##
## Key Changes:
##   - Removed DSP-Demo-Objects root OU
##   - All OUs now at domain root level (LabAdmins, LabUsers, BadOU, DeleteMeOU, TEST)
##   - Sub-OUs maintain parent/child hierarchy
##   - User/Group OUPath references updated (no "Root/" prefix)
##
## How to use:
##   1. Edit OUs section to customize naming/descriptions
##   2. Edit Users section - assign each user to an OU via OUPath
##   3. Edit Groups section - reference users by SamAccountName
##   4. Placeholders like {DOMAIN_DN}, {DOMAIN}, {PASSWORD} expanded at runtime
##
################################################################################

@{
    #---------------------------------------------------------------------------
    # GENERAL SETTINGS
    #---------------------------------------------------------------------------
    General = @{
        DspServer = "dsp.d3.lab"
        LoopCount = 1
        GenericUserCount = 250
        DefaultPassword = "P@ssw0rd123!"
        Company = "HaleHapa"
        LogPath = "C:\Logs\DSP-Demo"
        VerboseLogging = $true
    }
    
    #---------------------------------------------------------------------------
    # ORGANIZATIONAL UNITS STRUCTURE
    #
    # OUs defined hierarchically at domain root level, matching original script.
    # All top-level OUs created directly at {DOMAIN_DN}.
    #
    # Logical paths: LabAdmins, LabAdmins/Tier0, LabUsers/Dept101, etc.
    # These are converted to actual DNs by the Directory module.
    #
    # Properties:
    #   Name = AD OU name
    #   Description = OU description
    #   ProtectFromAccidentalDeletion = $true or $false (default: $true)
    #   Children = nested hashtable of child OUs
    #---------------------------------------------------------------------------
    OUs = @{
        # =====================================================
        # ADMIN TIER STRUCTURE
        # =====================================================
        LabAdmins = @{
            Name = "Lab Admins"
            Description = "Lab administrator accounts"
            ProtectFromAccidentalDeletion = $true
            Children = @{
                Tier0 = @{
                    Name = "Tier 0"
                    Description = "Tier 0 - Enterprise administrators and sensitive accounts"
                    ProtectFromAccidentalDeletion = $true
                }
                Tier1 = @{
                    Name = "Tier 1"
                    Description = "Tier 1 - Domain and infrastructure administrators"
                    ProtectFromAccidentalDeletion = $true
                }
                Tier2 = @{
                    Name = "Tier 2"
                    Description = "Tier 2 - Application and service administrators"
                    ProtectFromAccidentalDeletion = $true
                }
            }
        }
        
        # =====================================================
        # USER STRUCTURE
        # =====================================================
        LabUsers = @{
            Name = "Lab Users"
            Description = "Lab user accounts for demonstrations"
            ProtectFromAccidentalDeletion = $true
            Children = @{
                Dept101 = @{
                    Name = "Dept101"
                    Description = "Department 101 for user movement demonstrations"
                    ProtectFromAccidentalDeletion = $true
                }
                Dept999 = @{
                    Name = "Dept999"
                    Description = "Department 999 for user movement demonstrations"
                    ProtectFromAccidentalDeletion = $true
                }
            }
        }
        
        # =====================================================
        # SPECIAL OUs FOR DEMO SCENARIOS
        # =====================================================
        BadOU = @{
            Name = "Bad OU"
            Description = "OU intentionally created with problematic configurations for demo"
            ProtectFromAccidentalDeletion = $true
        }
        
        DeleteMeOU = @{
            Name = "DeleteMe OU"
            Description = "OU and contents will be deleted during script to demonstrate recovery"
            ProtectFromAccidentalDeletion = $false
            Children = @{
                CorpSpecialOU = @{
                    Name = "Corp Special OU"
                    Description = "Corporate special OU sub-resource"
                    ProtectFromAccidentalDeletion = $false
                }
                Resources = @{
                    Name = "Resources"
                    Description = "Resources sub-OU that will be deleted"
                    ProtectFromAccidentalDeletion = $false
                }
                Servers = @{
                    Name = "Servers"
                    Description = "Server computer objects that will be deleted"
                    ProtectFromAccidentalDeletion = $false
                }
            }
        }
        
        TEST = @{
            Name = "TEST"
            Description = "Test OU for generic bulk user creation"
            ProtectFromAccidentalDeletion = $false
        }
    }
    
    #---------------------------------------------------------------------------
    # USERS
    #
    # Define users by category. Each user must have:
    #   - SamAccountName: AD logon name
    #   - Name, GivenName, Surname: AD naming
    #   - OUPath: Logical path to OU (e.g., "LabAdmins/Tier0")
    #   - Password: Will be replaced with {PASSWORD} placeholder value
    #
    # Optional fields:
    #   - DisplayName, Title, Department, Company, Mail, TelephoneNumber, etc.
    #   - PasswordNeverExpires: $true or $false
    #   - Enabled: $true or $false (default: $true)
    #
    # OUPath must match an OU defined in the OUs section above.
    # If OUPath doesn't exist, user creation will be skipped with warning.
    #---------------------------------------------------------------------------
    Users = @{
        
        # =====================================================
        # TIER 0 ADMIN ACCOUNTS
        # =====================================================
        Tier0Admins = @(
            @{
                SamAccountName = "adm.globaladmin"
                Name = "Global Admin"
                GivenName = "Global"
                Surname = "Admin"
                DisplayName = "Global Admin"
                Title = "Tier 0 Administrator"
                Department = "Infrastructure"
                Company = "{COMPANY}"
                Mail = "adm.globaladmin@{DOMAIN}"
                TelephoneNumber = "555-0100"
                Description = "Tier 0 special admin account"
                OUPath = "LabAdmins/Tier0"
                Password = "{PASSWORD}"
                PasswordNeverExpires = $true
                Enabled = $true
            }
            @{
                SamAccountName = "automationacct1"
                Name = "Automation Account 1"
                GivenName = "Automation"
                Surname = "Account"
                DisplayName = "Automation Account 1"
                Title = "Service Account"
                Department = "Infrastructure"
                Company = "{COMPANY}"
                Mail = "automationacct1@{DOMAIN}"
                TelephoneNumber = "555-0101"
                Description = "Automation and workflow service account"
                OUPath = "LabAdmins/Tier0"
                Password = "{PASSWORD}"
                PasswordNeverExpires = $true
                Enabled = $true
            }
        )
        
        # =====================================================
        # TIER 1 ADMIN ACCOUNTS
        # =====================================================
        Tier1Admins = @(
            @{
                SamAccountName = "monitoringacct1"
                Name = "Monitoring Account 1"
                GivenName = "Monitoring"
                Surname = "Account"
                DisplayName = "Monitoring Account 1"
                Title = "Monitoring Service Account"
                Department = "Infrastructure"
                Company = "{COMPANY}"
                Mail = "monitoringacct1@{DOMAIN}"
                TelephoneNumber = "555-0102"
                Description = "Monitoring and observability service account"
                OUPath = "LabAdmins/Tier1"
                Password = "{PASSWORD}"
                PasswordNeverExpires = $false
                Enabled = $true
            }
            @{
                SamAccountName = "opsadmin1"
                Name = "Operations Admin 1"
                GivenName = "Operations"
                Surname = "Admin"
                DisplayName = "Operations Admin 1"
                Title = "Operations Manager"
                Department = "Operations"
                Company = "{COMPANY}"
                Mail = "opsadmin1@{DOMAIN}"
                TelephoneNumber = "555-0103"
                Description = "Tier 1 operations administrator"
                OUPath = "LabAdmins/Tier1"
                Password = "{PASSWORD}"
                PasswordNeverExpires = $false
                Enabled = $true
            }
        )
        
        # =====================================================
        # TIER 2 ADMIN ACCOUNTS
        # =====================================================
        Tier2Admins = @(
            @{
                SamAccountName = "adm.draji"
                Name = "D. Raji (Admin)"
                GivenName = "D."
                Surname = "Raji"
                DisplayName = "D. Raji (admin)"
                Title = "Application Administrator"
                Department = "Applications"
                Company = "{COMPANY}"
                Mail = "adm.draji@{DOMAIN}"
                TelephoneNumber = "555-0104"
                Description = "Tier 2 application administrator"
                OUPath = "LabAdmins/Tier2"
                Password = "{PASSWORD}"
                PasswordNeverExpires = $true
                Enabled = $true
            }
            @{
                SamAccountName = "adm.gjimenez"
                Name = "G. Jimenez (Admin)"
                GivenName = "G."
                Surname = "Jimenez"
                DisplayName = "G. Jimenez (admin)"
                Title = "Application Administrator"
                Department = "Applications"
                Company = "{COMPANY}"
                Mail = "adm.gjimenez@{DOMAIN}"
                TelephoneNumber = "555-0105"
                Description = "Tier 2 application administrator"
                OUPath = "LabAdmins/Tier2"
                Password = "{PASSWORD}"
                PasswordNeverExpires = $true
                Enabled = $true
            }
        )
        
        # =====================================================
        # DEMO USERS (subject to attribute changes, movement, etc.)
        # =====================================================
        DemoUsers = @(
            @{
                SamAccountName = "arose"
                Name = "Axl Rose"
                GivenName = "Axl"
                Surname = "Rose"
                DisplayName = "Axl Rose"
                Title = "Application Developer"
                Department = "Engineering"
                Company = "{COMPANY}"
                Mail = "arose@{DOMAIN}"
                TelephoneNumber = "555-1001"
                MobilePhone = "555-1001-mobile"
                Fax = "555-1001-fax"
                Description = "Demo user - subject to attribute modifications"
                OUPath = "LabUsers/Dept101"
                Password = "{PASSWORD}"
                Enabled = $true
            }
            @{
                SamAccountName = "shudson"
                Name = "Luke Skywalker"
                GivenName = "Luke"
                Surname = "Skywalker"
                DisplayName = "Luke Skywalker"
                Title = "Systems Engineer"
                Department = "Infrastructure"
                Company = "{COMPANY}"
                Mail = "shudson@{DOMAIN}"
                TelephoneNumber = "555-1002"
                Description = "Demo user - subject to attribute modifications"
                OUPath = "LabUsers/Dept101"
                Password = "{PASSWORD}"
                Enabled = $true
            }
            @{
                SamAccountName = "dmckagan"
                Name = "Peter Griffin"
                GivenName = "Peter"
                Surname = "Griffin"
                DisplayName = "Peter Griffin"
                Title = "Database Administrator"
                Department = "Database"
                Company = "{COMPANY}"
                Mail = "dmckagan@{DOMAIN}"
                TelephoneNumber = "555-1003"
                Description = "Demo user - subject to auto-undo rule testing"
                OUPath = "LabUsers/Dept101"
                Password = "{PASSWORD}"
                Enabled = $true
            }
            @{
                SamAccountName = "pmccartney"
                Name = "Paul McCartney"
                GivenName = "Paul"
                Surname = "McCartney"
                DisplayName = "Paul McCartney"
                Title = "Security Analyst"
                Department = "Security"
                Company = "{COMPANY}"
                Mail = "pmccartney@{DOMAIN}"
                TelephoneNumber = "555-1004"
                Description = "Demo user for security demonstrations"
                OUPath = "LabUsers/Dept101"
                Password = "{PASSWORD}"
                Enabled = $true
            }
        )
        
        # =====================================================
        # GENERIC BULK USERS (created in TEST and DeleteMe OUs)
        # =====================================================
        GenericUsers = @(
            @{
                SamAccountNamePrefix = "GdAct0r"
                Count = 250
                OUPath = "TEST"
                Description = "Generic bulk user account"
                Company = "{COMPANY}"
                Password = "{PASSWORD}"
                Enabled = $true
            }
            @{
                SamAccountNamePrefix = "GenericAct0r"
                Count = 10
                OUPath = "DeleteMeOU"
                Description = "Generic user account for deletion demo"
                Company = "{COMPANY}"
                Password = "{PASSWORD}"
                Enabled = $true
            }
        )
    }
    
    #---------------------------------------------------------------------------
    # GROUPS
    #
    # Define groups by category. Each group must have:
    #   - SamAccountName: Group logon name
    #   - Name, DisplayName: Group names
    #   - OUPath: Logical path where group is created
    #   - Members: Array of user SamAccountNames to add to group
    #
    # Optional fields:
    #   - Description: Group description
    #   - GroupScope: Global, Universal, DomainLocal (default: Global)
    #   - GroupCategory: Security, Distribution (default: Security)
    #
    # Members are resolved by looking up users with matching SamAccountNames.
    # If a user doesn't exist, they're skipped with warning.
    #---------------------------------------------------------------------------
    Groups = @{
        AdminGroups = @(
            @{
                SamAccountName = "SpecialLabAdmins"
                Name = "Special Lab Admins"
                DisplayName = "Special Lab Admins"
                Description = "Special lab administrator group with elevated privileges"
                OUPath = "LabAdmins"
                GroupScope = "Global"
                GroupCategory = "Security"
                Members = @("adm.draji", "adm.gjimenez", "adm.globaladmin")
            }
            @{
                SamAccountName = "SpecialLabUsers"
                Name = "Special Lab Users"
                DisplayName = "Special Lab Users"
                Description = "Special lab users group"
                OUPath = "LabUsers"
                GroupScope = "Global"
                GroupCategory = "Security"
                Members = @("arose", "shudson", "dmckagan")
            }
        )
        
        OperationalGroups = @(
            @{
                SamAccountName = "PizzaPartyGroup"
                Name = "Pizza Party Group"
                DisplayName = "Pizza Party Group"
                Description = "Distribution group for team events"
                OUPath = "LabUsers"
                GroupScope = "Global"
                GroupCategory = "Distribution"
                Members = @("arose", "shudson", "dmckagan", "pmccartney")
            }
            @{
                SamAccountName = "HelpdeskOps"
                Name = "Helpdesk Operations"
                DisplayName = "Helpdesk Operations"
                Description = "Helpdesk operations security group"
                OUPath = "LabUsers"
                GroupScope = "Global"
                GroupCategory = "Security"
                Members = @("opsadmin1", "monitoringacct1")
            }
        )
        
        DeleteMeGroups = @(
            @{
                SamAccountName = "SpecialAccessDatacenter"
                Name = "Special Access - Datacenter"
                DisplayName = "Special Access - Datacenter"
                Description = "Datacenter access group to be deleted"
                OUPath = "DeleteMeOU/CorpSpecialOU"
                GroupScope = "Global"
                GroupCategory = "Security"
                Members = @("adm.globaladmin")
            }
            @{
                SamAccountName = "ServerAdminsUS"
                Name = "Server Admins - US"
                DisplayName = "Server Admins - US"
                Description = "US server admin group to be deleted"
                OUPath = "DeleteMeOU/Servers"
                GroupScope = "Global"
                GroupCategory = "Security"
                Members = @("adm.draji")
            }
            @{
                SamAccountName = "ServerAdminsAPAC"
                Name = "Server Admins - APAC"
                DisplayName = "Server Admins - APAC"
                Description = "APAC server admin group to be deleted"
                OUPath = "DeleteMeOU/Servers"
                GroupScope = "Global"
                GroupCategory = "Security"
                Members = @("adm.gjimenez")
            }
            @{
                SamAccountName = "ResourceAdmins"
                Name = "Resource Admins"
                DisplayName = "Resource Admins"
                Description = "Resource admin group to be deleted"
                OUPath = "DeleteMeOU/Resources"
                GroupScope = "Global"
                GroupCategory = "Security"
                Members = @("opsadmin1")
            }
        )
    }
    
    #---------------------------------------------------------------------------
    # FINE-GRAINED PASSWORD POLICIES (FGPP)
    #
    # Define password policies. Each FGPP must have:
    #   - Name: Policy name
    #   - Precedence: Priority (lower number = higher priority)
    #
    # Other properties are standard FGPP settings.
    #---------------------------------------------------------------------------
    FGPPs = @(
        @{
            Name = "DSP-Demo-FGPP"
            Precedence = 10
            MinPasswordLength = 12
            ComplexityEnabled = $true
            LockoutThreshold = 5
            MaxPasswordAge = 42
            MinPasswordAge = 1
            PasswordHistoryCount = 24
            ReversibleEncryptionEnabled = $false
        }
        @{
            Name = "SpecialLabUsers_PSO"
            Precedence = 20
            MinPasswordLength = 14
            ComplexityEnabled = $true
            LockoutThreshold = 3
            MaxPasswordAge = 30
            MinPasswordAge = 1
            PasswordHistoryCount = 24
            ReversibleEncryptionEnabled = $false
        }
    )
    
    #---------------------------------------------------------------------------
    # DEFAULT DOMAIN POLICY SETTINGS
    #
    # Configure password and lockout policy settings applied to all users
    # via the Default Domain Policy GPO.
    #---------------------------------------------------------------------------
    DefaultDomainPolicy = @{
        MinPasswordLength = 8
        PasswordComplexity = $true
        PasswordHistoryCount = 24
        MaxPasswordAge = 42
        MinPasswordAge = 1
        LockoutThreshold = 5
        LockoutDuration = 30
        LockoutObservationWindow = 30
        ReversibleEncryption = $false
    }
}

################################################################################
# END OF CONFIGURATION
################################################################################