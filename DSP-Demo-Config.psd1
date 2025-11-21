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
    # USERS - ALL USERS FROM LEGACY SCRIPT
    #---------------------------------------------------------------------------
    Users = @{
        
        # =====================================================
        # TIER 0 ADMIN ACCOUNTS
        # =====================================================
        Tier0Admins = @(
            @{
                SamAccountName = "adm.globaladmin"
                Name = "Global Admin"
                GivenName = "Warren"
                Surname = "Buffet"
                DisplayName = "Global Admin"
                Title = "Tier 0 Administrator"
                Department = "Operations"
                Company = "{COMPANY}"
                Mail = "adm.globaladmin@{DOMAIN}"
                TelephoneNumber = "1 (500) 555-4554"
                Description = "Global Systems Admin (old acct)"
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
                Department = "Orchestration"
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
                SamAccountName = "adm.johnwick"
                Name = "adm.JohnWick"
                GivenName = "John"
                Surname = "Wick"
                DisplayName = "John Wick (admin)"
                Title = "Operations Lead"
                Department = "Demo"
                Company = "{COMPANY}"
                Mail = "adm.johnwick@{DOMAIN}"
                TelephoneNumber = "408-555-1919"
                Description = "Admin for Lab Operations"
                OUPath = "Lab Admins/Tier 1"
                Password = "{PASSWORD}"
                PasswordNeverExpires = $false
                Enabled = $true
            }
            @{
                SamAccountName = "monitoringacct1"
                Name = "Monitoring Account 1"
                GivenName = "Monitoring"
                Surname = "Account"
                DisplayName = "Monitoring Account 1"
                Title = "Monitoring Service Account"
                Department = "Orchestration"
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
                TelephoneNumber = "408-555-1919"
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
                SamAccountName = "AppAdminII"
                Name = "App Admin II"
                GivenName = "App"
                Surname = "Admin II"
                DisplayName = "App Admin II"
                Title = "Application Lead"
                Department = "Demo Development"
                Company = "{COMPANY}"
                Mail = "AppAdminII@{DOMAIN}"
                TelephoneNumber = "408-555-2424"
                Description = "Admin for Lab Applications"
                OUPath = "Lab Admins/Tier 2"
                Password = "{PASSWORD}"
                PasswordNeverExpires = $false
                Enabled = $true
            }
            @{
                SamAccountName = "AppAdminIII"
                Name = "App Admin III"
                GivenName = "App"
                Surname = "Admin III"
                DisplayName = "App Admin III"
                Title = "Application Manager"
                Department = "Demo Development"
                Company = "{COMPANY}"
                Mail = "AppAdminIII@{DOMAIN}"
                TelephoneNumber = "408-555-3434"
                Description = "Admin for Lab Applications"
                OUPath = "Lab Admins/Tier 2"
                Password = "{PASSWORD}"
                PasswordNeverExpires = $false
                Enabled = $true
            }
            @{
                SamAccountName = "adm.draji"
                Name = "adm.draji"
                GivenName = "Dawn"
                Surname = "Raji"
                DisplayName = "Dawn Raji (ADM)"
                Title = "Site CIO"
                Department = "Engineering"
                Company = "{COMPANY}"
                Mail = "dawn45@{DOMAIN}"
                TelephoneNumber = "1 (11) 500 555-0126"
                Description = "System Engineering Manager"
                OUPath = "Lab Admins/Tier 2"
                Password = "{PASSWORD}"
                PasswordNeverExpires = $true
                Enabled = $true
            }
            @{
                SamAccountName = "adm.gjimenez"
                Name = "adm.gjimenez"
                GivenName = "Gary"
                Surname = "Jimenez"
                DisplayName = "Gary Jimenez (ADM)"
                Title = "Site Manager"
                Department = "Engineering"
                Company = "{COMPANY}"
                Mail = "gjimenez@{DOMAIN}"
                TelephoneNumber = "1 (500) 555-1221"
                Description = "System Engineering Site Manager"
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
                GivenName = "William"
                Surname = "Rose"
                DisplayName = "Axl Rose"
                Title = "Application Mgr"
                Department = "Sales"
                Company = "{COMPANY}"
                Mail = "arose@{DOMAIN}"
                TelephoneNumber = "408-555-1212"
                Description = "Coder"
                OUPath = "Lab Users"
                Password = "{PASSWORD}"
                Enabled = $true
            }
            @{
                SamAccountName = "lskywalker"
                Name = "Luke Skywalker"
                GivenName = "Luke"
                Surname = "Skywalker"
                DisplayName = "Luke Skywalker"
                Title = "Nerfherder"
                Department = "Religion"
                Company = "{COMPANY}"
                Mail = "lskywalker@{DOMAIN}"
                TelephoneNumber = "408-555-5151"
                Description = "apprentice"
                OUPath = "Lab Users"
                Password = "{PASSWORD}"
                Enabled = $true
            }
            @{
                SamAccountName = "peter.griffin"
                Name = "Peter Griffin"
                GivenName = "Peter"
                Surname = "Griffin"
                DisplayName = "Peter Griffin"
                Title = "Sales"
                Department = "Parody"
                Company = "{COMPANY}"
                Mail = "peter.griffin@{DOMAIN}"
                TelephoneNumber = "408-777-3333"
                Description = "cartoon character"
                OUPath = "Lab Users"
                Password = "{PASSWORD}"
                Enabled = $true
            }
            @{
                SamAccountName = "pmccartney"
                Name = "Paul McCartney"
                GivenName = "Paul"
                Surname = "McCartney"
                DisplayName = "Paul McCartney"
                Title = "Lead Beatle"
                Department = "Music"
                Company = "{COMPANY}"
                Mail = "pmccartney@{DOMAIN}"
                TelephoneNumber = "011 44 20 1234 5678"
                Description = "Bandmember"
                OUPath = "Lab Users"
                Password = "{PASSWORD}"
                Enabled = $true
            }
            @{
                SamAccountName = "yanli"
                Name = "Yan Li"
                GivenName = "Yan"
                Surname = "Li"
                DisplayName = "Yan Li"
                Title = "Manager"
                Department = "Widget Manufacturing"
                Company = "{COMPANY}"
                Mail = "yanli@{DOMAIN}"
                TelephoneNumber = "408-555-5959"
                Description = "manager of shop line"
                OUPath = "Lab Users"
                Password = "{PASSWORD}"
                Enabled = $true
            }
            @{
                SamAccountName = "acruz"
                Name = "Angel Cruz"
                GivenName = "Angel"
                Surname = "Cruz"
                DisplayName = "Angel Cruz"
                Title = "Vice President"
                Department = "Sales"
                Company = "{COMPANY}"
                Mail = "acruz@{DOMAIN}"
                TelephoneNumber = "408-555-2020"
                Description = "VP Sales"
                OUPath = "Lab Users"
                Password = "{PASSWORD}"
                Enabled = $true
            }
            @{
                SamAccountName = "cmhernandez"
                Name = "Cheryl Hernandez"
                GivenName = "Cheryl"
                Surname = "Hernandez"
                DisplayName = "Cheryl Hernandez"
                Title = "Database Administrator"
                Department = "Database"
                Company = "{COMPANY}"
                Mail = "cmhernandez@{DOMAIN}"
                TelephoneNumber = "408-555-7979"
                Description = "DBA"
                OUPath = "Lab Users"
                Password = "{PASSWORD}"
                Enabled = $true
            }
            @{
                SamAccountName = "draji"
                Name = "Draji"
                GivenName = "D."
                Surname = "Raji"
                DisplayName = "D. Raji"
                Title = "Site Manager"
                Department = "Engineering"
                Company = "{COMPANY}"
                Mail = "draji@{DOMAIN}"
                TelephoneNumber = "1 (500) 555-0126"
                Description = "System Engineering Manager"
                OUPath = "Lab Users"
                Password = "{PASSWORD}"
                Enabled = $true
            }
            @{
                SamAccountName = "gjimenez"
                Name = "Gary Jimenez"
                GivenName = "Gary"
                Surname = "Jimenez"
                DisplayName = "Gary Jimenez"
                Title = "Site Manager"
                Department = "Engineering"
                Company = "{COMPANY}"
                Mail = "gjimenez@{DOMAIN}"
                TelephoneNumber = "1 (500) 555-1221"
                Description = "System Engineering Site Manager"
                OUPath = "Lab Users"
                Password = "{PASSWORD}"
                Enabled = $true
            }
            @{
                SamAccountName = "vlevin"
                Name = "Vladimir Levin"
                GivenName = "Vladimir"
                Surname = "Levin"
                DisplayName = "Vladimir Levin"
                Title = "Sr Site Manager"
                Department = "Engineering"
                Company = "{COMPANY}"
                Mail = "vlevin@{DOMAIN}"
                TelephoneNumber = "1 (500) 555-8321"
                Description = "Suspicious User"
                OUPath = "Lab Users"
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
    # COMPUTERS
    #---------------------------------------------------------------------------
    Computers = @(
        @{
            SamAccountName = "srv-iis-us01"
            Name = "srv-iis-us01"
            DisplayName = "srv-iis-us01"
            Description = "Special application server for lab (srv-iis-us01)"
            OUPath = "Root/DeleteMe OU/Servers"
            Password = "{PASSWORD}"
            Enabled = $true
        }
        @{
            SamAccountName = "ops-app-us05"
            Name = "ops-app-us05"
            DisplayName = "ops-app-us05"
            Description = "Special application server for lab"
            OUPath = "Root/DeleteMe OU/Resources"
            Password = "{PASSWORD}"
            Enabled = $true
        }
        @{
            SamAccountName = "PIMPAM"
            Name = "PIMPAM"
            DisplayName = "PIMPAM"
            Description = "Privileged access server"
            OUPath = "Root/zSpecial OU"
            Password = "{PASSWORD}"
            Enabled = $true
        }
        @{
            SamAccountName = "VAULT"
            Name = "VAULT"
            DisplayName = "VAULT"
            Description = "Vault server to store passwords and credentials"
            OUPath = "Root/zSpecial OU"
            Password = "{PASSWORD}"
            Enabled = $true
        }
        @{
            SamAccountName = "BASTION-HOST01"
            Name = "BASTION-HOST01"
            DisplayName = "BASTION-HOST01"
            Description = "Bastion host for restricted privileged access"
            OUPath = "Root/zSpecial OU"
            Password = "{PASSWORD}"
            Enabled = $true
        }
    )
    
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
# CONFIGURATION SECTION FOR DSP-Demo-07 (Sites and Subnets)
# 
################################################################################

AdSites = @{
    LabSite001 = @{
        Description = "Lab site for demonstration"
        Location = "SemperisLabs-USA-AZ"
    }
}

AdSubnets = @{
    "172.16.0.0/24" = @{
        Site = "LabSite001"
        Description = "Lab network subnet"
        Location = "Lab-Primary"
    }
    "10.0.0.0/24" = @{
        Site = "LabSite001"
        Description = "Additional lab subnet"
        Location = "Lab-Secondary"
    }
    "10.0.0.0/8" = @{
        Site = "LabSite001"
        Description = "Primary Lab Infrastructure Network"
        Location = "Lab-USA-All"
    }
    "172.16.32.0/20" = @{
        Site = "LabSite001"
        Description = "Special demo lab subnet"
        Location = "Lab-USA-CA"
    }
    "10.222.0.0/16" = @{
        Site = "LabSite001"
        Description = "Special Devices Infrastructure Network"
        Location = "Lab-USA-East"
    }
    "192.168.0.0/16" = @{
        Site = "LabSite001"
        Description = "Primary Demo Lab Infrastructure Network"
        Location = "Lab-USA-TX"
    }
    "192.168.57.0/24" = @{
        Site = "LabSite001"
        Description = "Special DMZ network"
        Location = "Lab-USA-AZ"
    }
}

AdSiteLinks = @{
    "Default-First-Site-Name -- LabSite001" = @{
        Sites = @("Default-First-Site-Name", "LabSite001")
        Cost = 22
        ReplicationFrequencyInMinutes = 18
        Description = "Site link for lab replication"
    }
}

################################################################################
# CONFIGURATION SECTION FOR DSP-Demo-08 (DNS Zones)
# 
################################################################################

DnsForwardZones = @{
    "specialsite.lab" = @{
        Description = "Custom lab zone for demonstrations"
    }
}

DnsReverseZones = @{
    "10.in-addr.arpa" = @{
        Description = "Reverse zone for 10.x.x.x network"
    }
    "172.in-addr.arpa" = @{
        Description = "Reverse zone for 172.x.x.x network"
    }
    "168.192.in-addr.arpa" = @{
        Description = "Reverse zone for 192.168.x.x network"
    }
}

################################################################################
# END OF CONFIGURATION
################################################################################