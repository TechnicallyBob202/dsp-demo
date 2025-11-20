################################################################################
##
## DSP-Demo-Config.psd1 (Corrected Structure)
##
## Configuration file for DSP Demo script suite with OUs matching original script.
## All top-level OUs created at domain root (no DSP-Demo-Objects wrapper).
##
## CORRECTED: OUPath values now match actual OU names from Phase 1
##   - "Lab Admins" not "LabAdmins"
##   - "Tier 0", "Tier 1", "Tier 2" with spaces
##   - "Lab Users" with space
##   - "DeleteMe OU" with space
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
        
        zSpecialOU = @{
            Name = "zSpecial OU"
            Description = "Special OU for demonstrations"
            ProtectFromAccidentalDeletion = $true
        }
        
        Tier0SpecialAssets = @{
            Name = "Tier-0-Special-Assets"
            Description = "Tier 0 special assets with restricted access"
            ProtectFromAccidentalDeletion = $true
        }
    }
    
    #---------------------------------------------------------------------------
    # USERS - CORRECTED OUPATHS
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
                OUPath = "Lab Admins/Tier 0"
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
                OUPath = "Lab Admins/Tier 0"
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
                OUPath = "Lab Admins/Tier 1"
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
                OUPath = "Lab Admins/Tier 1"
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
                OUPath = "Lab Admins/Tier 2"
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
                OUPath = "Lab Admins/Tier 2"
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
                OUPath = "Lab Users/Dept101"
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
                OUPath = "Lab Users/Dept101"
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
                OUPath = "Lab Users/Dept101"
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
                OUPath = "Lab Users/Dept101"
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
                OUPath = "DeleteMe OU"
                Description = "Generic user account for deletion demo"
                Company = "{COMPANY}"
                Password = "{PASSWORD}"
                Enabled = $true
            }
        )
    }
    
    #---------------------------------------------------------------------------
    # GROUPS
    #---------------------------------------------------------------------------
    Groups = @{
        LabUserGroups = @(
            @{
                SamAccountName = "SpecialLabUsers"
                Name = "Special Lab Users"
                DisplayName = "Special Lab Users"
                Description = "Members of this lab group are special"
                OUPath = "Root/Lab Users"
                GroupScope = "Global"
                GroupCategory = "Security"
            }
            @{
                SamAccountName = "PizzaPartyGroup"
                Name = "Pizza Party Group"
                DisplayName = "Pizza Party Group"
                Description = "Members of this lab group get info about pizza parties"
                OUPath = "Root/Lab Users"
                GroupScope = "Global"
                GroupCategory = "Distribution"
            }
            @{
                SamAccountName = "PartyPlannersGroup"
                Name = "Party Planners Group"
                DisplayName = "Party Planners Group"
                Description = "Members of this lab group do party planning"
                OUPath = "Root/Lab Users"
                GroupScope = "Global"
                GroupCategory = "Distribution"
            }
            @{
                SamAccountName = "HelpdeskOps"
                Name = "Helpdesk Ops"
                DisplayName = "Helpdesk Ops"
                Description = "Members of this lab group are Helpdesk operators"
                OUPath = "Root/Lab Users"
                GroupScope = "Global"
                GroupCategory = "Security"
            }
        )
        
        AdminGroups = @(
            @{
                SamAccountName = "SpecialLabAdmins"
                Name = "Special Lab Admins"
                DisplayName = "Special Lab Admins"
                Description = "Members of this lab group are admins"
                OUPath = "Root/Lab Admins"
                GroupScope = "Global"
                GroupCategory = "Security"
            }
            @{
                SamAccountName = "SpecialAccounts"
                Name = "Special Accounts"
                DisplayName = "Special Accounts"
                Description = "Members of this lab group are special accts and service accts"
                OUPath = "Root/Lab Admins"
                GroupScope = "Universal"
                GroupCategory = "Security"
            }
        )
        
        DeleteMeOUGroups = @(
            @{
                SamAccountName = "SpecialAccessDatacenter"
                Name = "Special Access - Datacenter"
                DisplayName = "Special Access - Datacenter"
                Description = "Resource Administrators for special Lab"
                OUPath = "Root/DeleteMe OU/Corp Special OU"
                GroupScope = "Global"
                GroupCategory = "Security"
            }
            @{
                SamAccountName = "ServerAdminsUS"
                Name = "Server Admins - US"
                DisplayName = "Server Admins - US"
                Description = "Resource Administrators for special Lab"
                OUPath = "Root/DeleteMe OU/Servers"
                GroupScope = "Global"
                GroupCategory = "Security"
            }
            @{
                SamAccountName = "ServerAdminsAPAC"
                Name = "Server Admins - APAC"
                DisplayName = "Server Admins - APAC"
                Description = "Resource Administrators for special Lab"
                OUPath = "Root/DeleteMe OU/Servers"
                GroupScope = "Global"
                GroupCategory = "Security"
            }
            @{
                SamAccountName = "ResourceAdmins"
                Name = "Resource Admins"
                DisplayName = "Resource Admins"
                Description = "Resource Administrators for special Lab"
                OUPath = "Root/DeleteMe OU/Resources"
                GroupScope = "Global"
                GroupCategory = "Security"
            }
        )
    }
    
    #---------------------------------------------------------------------------
    # FINE-GRAINED PASSWORD POLICIES (FGPP)
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