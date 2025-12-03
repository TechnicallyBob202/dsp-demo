################################################################################
##
## DSP-Demo-Config-Setup.psd1
##
## Setup configuration for DSP Demo script suite
## Contains all baseline AD objects created during setup phase:
## - Organizational Units (14 total)
## - Groups (3 security groups)
## - Users (demo, admin, service, generic)
## - AD Sites, Subnets, Site Links
## - DNS Zones (forward and reverse)
## - Group Policy Objects
##
## Corrected to match legacy script: Invoke-CreateDspChangeDataForDemos-20251002_0012.ps1
## 
## Original Author: Rob Ingenthron (robi@semperis.com)
## Refactored By: Bob Lyons
## Version: 2.0.0-20251202 (CORRECTED)
##
################################################################################

@{
    #---------------------------------------------------------------------------
    # GENERAL SETTINGS
    #---------------------------------------------------------------------------
    General = @{
        DspServer = "dsp.d3.lab"
        Company = "HaleHapa"
        LogPath = "C:\Logs\DSP-Demo"
        VerboseLogging = $true
    }
    
    #---------------------------------------------------------------------------
    # ORGANIZATIONAL UNITS STRUCTURE (14 TOTAL)
    #---------------------------------------------------------------------------
    OUs = @{
        # Root level OUs
        LabAdmins = @{
            Name = "Lab Admins"
            Description = "OU for all lab admins!!"
            ProtectFromAccidentalDeletion = $true
            Children = @{
                Tier0 = @{
                    Name = "Tier 0"
                    Description = "OU for all TIER 0 lab admins!!"
                    ProtectFromAccidentalDeletion = $true
                }
                Tier1 = @{
                    Name = "Tier 1"
                    Description = "OU for all TIER 1 lab admins!!"
                    ProtectFromAccidentalDeletion = $true
                }
                Tier2 = @{
                    Name = "Tier 2"
                    Description = "OU for all TIER 2 lab admins!!"
                    ProtectFromAccidentalDeletion = $true
                }
            }
        }
        
        LabUsers = @{
            Name = "Lab Users"
            Description = "OU for all lab users!!"
            ProtectFromAccidentalDeletion = $true
            Children = @{
                Dept999 = @{
                    Name = "Dept999"
                    Description = "OU for users in Dept999"
                    ProtectFromAccidentalDeletion = $true
                }
                Dept101 = @{
                    Name = "Dept101"
                    Description = "OU for users in Dept101"
                    ProtectFromAccidentalDeletion = $true
                }
            }
        }
        
        LabComputers = @{
            Name = "Lab Computers"
            Description = "Lab computer accounts"
            ProtectFromAccidentalDeletion = $true
        }
        
        DeleteMeOU = @{
            Name = "DeleteMe OU"
            Description = "OU that gets DELETED by someone"
            ProtectFromAccidentalDeletion = $true
            Children = @{
                Servers = @{
                    Name = "Servers"
                    Description = "Server computers for demo recovery"
                    ProtectFromAccidentalDeletion = $false
                }
                Resources = @{
                    Name = "Resources"
                    Description = "Resource accounts for demo purposes"
                    ProtectFromAccidentalDeletion = $false
                }
            }
        }
        
        BadOU = @{
            Name = "Bad OU"
            Description = "OU that gets modified by someone"
            ProtectFromAccidentalDeletion = $false
        }
        
        TestOU = @{
            Name = "TEST"
            Description = "OU for generic test user accounts"
            ProtectFromAccidentalDeletion = $false
        }
        
        SpecialOU = @{
            Name = "zSpecial OU"
            Description = "Restricted OU for special objects"
            ProtectFromAccidentalDeletion = $true
        }
    }
    
    #---------------------------------------------------------------------------
    # SECURITY GROUPS (3 TOTAL)
    #---------------------------------------------------------------------------
    Groups = @{
        SpecialLabUsers = @{
            Name = "Special Lab Users"
            Path = "Lab Users"
            GroupScope = "Global"
            GroupCategory = "Security"
            Description = "Special lab users group"
        }
        SpecialLabAdmins = @{
            Name = "Special Lab Admins"
            Path = "Lab Admins"
            GroupScope = "Global"
            GroupCategory = "Security"
            Description = "Special lab admins group"
        }
        HelpdeskOps = @{
            Name = "HelpDesk Ops"
            Path = "Lab Admins"
            GroupScope = "Global"
            GroupCategory = "Security"
            Description = "HelpDesk operations group"
        }
    }
    
    #---------------------------------------------------------------------------
    # TIER ADMIN ACCOUNTS
    #---------------------------------------------------------------------------
    Tier0Admins = @{
        "admin-t0" = @{
            GivenName = "Tier"
            Surname = "ZeroAdmin"
            UserPrincipalName = "admin-t0@{DOMAIN}"
            SamAccountName = "admin-t0"
            DisplayName = "Tier 0 Admin"
            Description = "Tier 0 administrator account"
            Title = "Enterprise Admin"
            Department = "IT Administration"
            Path = "Lab Admins/Tier 0"
            PasswordNeverExpires = $true
        }
    }
    
    Tier1Admins = @{
        "admin-t1" = @{
            GivenName = "Tier"
            Surname = "OneAdmin"
            UserPrincipalName = "admin-t1@{DOMAIN}"
            SamAccountName = "admin-t1"
            DisplayName = "Tier 1 Admin"
            Description = "Tier 1 administrator account"
            Title = "Domain Admin"
            Department = "IT Administration"
            Path = "Lab Admins/Tier 1"
            PasswordNeverExpires = $true
        }
    }
    
    Tier2Admins = @{
        "admin-t2" = @{
            GivenName = "Tier"
            Surname = "TwoAdmin"
            UserPrincipalName = "admin-t2@{DOMAIN}"
            SamAccountName = "admin-t2"
            DisplayName = "Tier 2 Admin"
            Description = "Tier 2 administrator account"
            Title = "Application Admin"
            Department = "IT Administration"
            Path = "Lab Admins/Tier 2"
            PasswordNeverExpires = $true
        }
    }
    
    #---------------------------------------------------------------------------
    # DEMO USERS (5 NAMED + ADDITIONAL)
    #---------------------------------------------------------------------------
    DemoUsers = @{
        "arose" = @{
            GivenName = "William"
            Surname = "Rose"
            UserPrincipalName = "arose@{DOMAIN}"
            SamAccountName = "arose"
            DisplayName = "Axl Rose"
            Description = "Coder"
            Title = "Application Mgr"
            Department = "Sales"
            Division = "Rock Analysis"
            Company = "Roses and Guns"
            OfficePhone = "408-555-1212"
            Fax = "(408) 555-1212"
            City = "City of angels"
            EmployeeID = "000123456"
            Path = "Lab Users/Dept101"
            PasswordNeverExpires = $true
        }
        "lskywalker" = @{
            GivenName = "Luke"
            Surname = "Skywalker"
            UserPrincipalName = "lskywalker@{DOMAIN}"
            SamAccountName = "lskywalker"
            DisplayName = "Luke Skywalker"
            Description = "apprentice"
            Title = "Nerfherder"
            Department = "Religion"
            Division = "Spoon Bending"
            Company = "Jedi Knights, Inc"
            OfficePhone = "408-555-5151"
            Fax = "(408) 555-5555"
            City = "Tatooine"
            EmployeeID = "00314159"
            Path = "Lab Users/Dept101"
        }
        "peter.griffin" = @{
            GivenName = "Peter"
            Surname = "Griffin"
            UserPrincipalName = "peter.griffin@{DOMAIN}"
            SamAccountName = "peter.griffin"
            DisplayName = "Peter Griffin"
            Description = "cartoon character"
            Title = "Sales"
            Department = "Parody"
            Division = "Blue Collar"
            Company = "Happy-Go-Lucky Toy Factory"
            OfficePhone = "408-777-3333"
            Fax = "(216) 555-1000"
            City = "Quahog"
            EmployeeID = "00987654321"
            Path = "Lab Users/Dept101"
        }
        "pmccartney" = @{
            GivenName = "Paul"
            Surname = "McCartney"
            UserPrincipalName = "pmccartney@{DOMAIN}"
            SamAccountName = "pmccartney"
            DisplayName = "Paul McCartney"
            Description = "Bandmember"
            Title = "Lead Beatle"
            Department = "Music"
            Division = "Legends"
            Company = "The Beat Brothers"
            OfficePhone = "011 44 20 1234 5678"
            Fax = "011 44 20 5555 1111"
            City = "Liverpool"
            EmployeeID = "000001212"
            Path = "Lab Users/Dept101"
        }
        "yanli" = @{
            GivenName = "Yan"
            Surname = "Li"
            UserPrincipalName = "yanli@{DOMAIN}"
            SamAccountName = "yanli"
            DisplayName = "Yan Li"
            Description = "manager of shop line"
            Title = "Manager"
            Department = "Wiget Manufacturing"
            Division = "Manufacturing"
            Company = "Contractors Inc"
            OfficePhone = "212 555-5600"
            Fax = "212 555-5699"
            City = "Jersey"
            EmployeeID = "000062312"
            Path = "Lab Users/Dept101"
        }
    }
    
    #---------------------------------------------------------------------------
    # OPS ADMIN ACCOUNT (for alternate credentials in Module 15)
    #---------------------------------------------------------------------------
    OpsAdmin = @{
        "opsadmin1" = @{
            GivenName = "Ops"
            Surname = "Admin"
            UserPrincipalName = "opsadmin1@{DOMAIN}"
            SamAccountName = "opsadmin1"
            DisplayName = "Ops Admin 1"
            Description = "Operations administrator account"
            Title = "Operations Admin"
            Department = "IT Operations"
            Path = "Lab Admins/Tier 2"
            PasswordNeverExpires = $true
        }
    }
    
    #---------------------------------------------------------------------------
    # SERVICE ACCOUNTS
    #---------------------------------------------------------------------------
    ServiceAccounts = @{
        "svc-dsp" = @{
            GivenName = "DSP"
            Surname = "Service"
            UserPrincipalName = "svc-dsp@{DOMAIN}"
            SamAccountName = "svc-dsp"
            DisplayName = "DSP Service Account"
            Description = "Service account for DSP integration"
            Path = "Lab Admins/Tier 1"
            PasswordNeverExpires = $true
        }
        "svc-dns" = @{
            GivenName = "DNS"
            Surname = "Service"
            UserPrincipalName = "svc-dns@{DOMAIN}"
            SamAccountName = "svc-dns"
            DisplayName = "DNS Service Account"
            Description = "Service account for DNS operations"
            Path = "Lab Admins/Tier 1"
            PasswordNeverExpires = $true
        }
    }
    
    #---------------------------------------------------------------------------
    # GENERIC USERS (BULK) - CREATED IN DEPT999, NOT DEPT101
    #---------------------------------------------------------------------------
    GenericUsers = @{
        Count = 15
        NamePrefix = "User"
        Path = "Lab Users/Dept999"
        Description = "Generic lab user account"
        PasswordRandomized = $true
    }
    
    #---------------------------------------------------------------------------
    # AD SITES - SemperisLabs (NOT LabSite001)
    #---------------------------------------------------------------------------
    AdSites = @{
        "SemperisLabs" = @{
            Name = "SemperisLabs"
            Description = "AD site for Semperis Labs"
            Location = "USA-TX-Labs"
        }
    }
    
    #---------------------------------------------------------------------------
    # AD SUBNETS - INCLUDES TEMPORARY SUBNETS FOR ACTIVITY MODULES
    #---------------------------------------------------------------------------
    AdSubnets = @{
        # Site-specific subnet for SemperisLabs
        "10.3.22.0/24" = @{
            Site = "SemperisLabs"
            Description = "AD subnet for Semperis Labs"
            Location = "USA-TX-Labs"
        }
        
        # Permanent subnets
        "10.0.0.0/8" = @{
            Site = "SemperisLabs"
            Description = "Primary Lab Infrastructure Network"
            Location = "Lab-USA-All"
        }
        "172.16.32.0/20" = @{
            Site = "SemperisLabs"
            Description = "Special demo lab subnet"
            Location = "Lab-USA-CA"
        }
        "10.222.0.0/16" = @{
            Site = "SemperisLabs"
            Description = "Special Devices Infrastructure Network"
            Location = "Lab-USA-East"
        }
        "10.111.0.0/16" = @{
            Site = "SemperisLabs"
            Description = "Test subnet 0002"
            Location = "Lab-EMEA-ES"
        }
        "10.112.0.0/16" = @{
            Site = "SemperisLabs"
            Description = "Test subnet 0002"
            Location = "Lab-EMEA-ES"
        }
        "111.2.5.0/24" = @{
            Site = "SemperisLabs"
            Description = "Lab subnet in TX"
            Location = "USA-TX-Labs"
        }
        "111.2.6.0/24" = @{
            Site = "SemperisLabs"
            Description = "Lab subnet in Dallas,TX"
            Location = "USA-TX-Dallas-Labs"
        }
        "192.168.0.0/16" = @{
            Site = "SemperisLabs"
            Description = "Primary Demo Lab Infrastructure Network"
            Location = "Lab-USA-TX"
        }
        "192.168.57.0/24" = @{
            Site = "SemperisLabs"
            Description = "Special DMZ network"
            Location = "Lab-USA-AZ"
        }
        
        # Temporary subnets (for Module 03 modification, deleted in Module 12)
        "111.111.4.0/24" = @{
            Site = "SemperisLabs"
            Description = "test subnet added via script"
            Location = "USA-TX-Labs"
        }
        "111.111.5.0/24" = @{
            Site = "SemperisLabs"
            Description = "test subnet added via script"
            Location = "USA-TX-Labs"
        }
    }
    
    #---------------------------------------------------------------------------
    # AD SITE LINKS
    #---------------------------------------------------------------------------
    AdSiteLinks = @{
        "Default-First-Site-Name -- SemperisLabs" = @{
            Sites = @("Default-First-Site-Name", "SemperisLabs")
            Cost = 22
            ReplicationFrequencyInMinutes = 18
            Description = "Site link for [SemperisLabs]"
        }
    }
    
    #---------------------------------------------------------------------------
    # DNS ZONES (FORWARD)
    #---------------------------------------------------------------------------
    DnsForwardZones = @{
        "specialsite.lab" = @{
            Description = "Custom lab zone for demonstrations"
        }
    }
    
    #---------------------------------------------------------------------------
    # DNS ZONES (REVERSE)
    #---------------------------------------------------------------------------
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
    
    #---------------------------------------------------------------------------
    # GROUP POLICY OBJECTS
    #---------------------------------------------------------------------------
    GPOs = @{
        "Questionable GPO" = @{
            Comment = "Simple test GPO for demonstrations"
        }
        "Lab SMB Client Policy GPO" = @{
            Comment = "SMB client security configuration for lab"
        }
        "CIS Benchmark Windows Server Policy GPO" = @{
            Comment = "CIS Windows Server hardening policy baseline"
        }
    }
}

################################################################################
# END OF SETUP CONFIGURATION
################################################################################