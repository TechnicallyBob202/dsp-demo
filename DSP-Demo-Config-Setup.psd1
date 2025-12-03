################################################################################
##
## DSP-Demo-Config-Setup.psd1
##
## Setup configuration for DSP Demo script suite
## CORRECTED to match module expectations
##
## Original Author: Rob Ingenthron (robi@semperis.com)
## Refactored By: Bob Lyons
## Version: 2.1.0-20251202 (CORRECTED v2 - Module Compatible)
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
        DefaultPassword = "P@ssw0rd123!"
    }
    
    #---------------------------------------------------------------------------
    # ORGANIZATIONAL UNITS STRUCTURE (14 TOTAL)
    #---------------------------------------------------------------------------
    OUs = @{
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
    # SECURITY GROUPS - Must have SamAccountName
    #---------------------------------------------------------------------------
    Groups = @{
        SpecialLabUsers = @{
            Name = "Special Lab Users"
            SamAccountName = "Special Lab Users"
            Path = "Lab Users"
            GroupScope = "Global"
            GroupCategory = "Security"
            Description = "Special lab users group"
        }
        SpecialLabAdmins = @{
            Name = "Special Lab Admins"
            SamAccountName = "Special Lab Admins"
            Path = "Lab Admins"
            GroupScope = "Global"
            GroupCategory = "Security"
            Description = "Special lab admins group"
        }
        HelpdeskOps = @{
            Name = "HelpDesk Ops"
            SamAccountName = "HelpDesk Ops"
            Path = "Lab Admins"
            GroupScope = "Global"
            GroupCategory = "Security"
            Description = "HelpDesk operations group"
        }
    }
    
    #---------------------------------------------------------------------------
    # USER ACCOUNTS - Organized by type
    #---------------------------------------------------------------------------
    Users = @{
        Tier0Admins = @(
            @{
                GivenName = "Tier"
                Surname = "ZeroAdmin"
                UserPrincipalName = "admin-t0@{DOMAIN}"
                SamAccountName = "admin-t0"
                DisplayName = "Tier 0 Admin"
                Description = "Tier 0 administrator account"
                Title = "Enterprise Admin"
                Department = "IT Administration"
                OUPath = "Lab Admins/Tier 0"
                PasswordNeverExpires = $true
                Groups = @("Special Lab Admins")
            }
        )
        
        Tier1Admins = @(
            @{
                GivenName = "Tier"
                Surname = "OneAdmin"
                UserPrincipalName = "admin-t1@{DOMAIN}"
                SamAccountName = "admin-t1"
                DisplayName = "Tier 1 Admin"
                Description = "Tier 1 administrator account"
                Title = "Domain Admin"
                Department = "IT Administration"
                OUPath = "Lab Admins/Tier 1"
                PasswordNeverExpires = $true
                Groups = @("Special Lab Admins")
            }
        )
        
        Tier2Admins = @(
            @{
                GivenName = "Tier"
                Surname = "TwoAdmin"
                UserPrincipalName = "admin-t2@{DOMAIN}"
                SamAccountName = "admin-t2"
                DisplayName = "Tier 2 Admin"
                Description = "Tier 2 administrator account"
                Title = "Application Admin"
                Department = "IT Administration"
                OUPath = "Lab Admins/Tier 2"
                PasswordNeverExpires = $true
                Groups = @("Special Lab Admins")
            }
            @{
                GivenName = "App"
                Surname = "Admin III"
                UserPrincipalName = "appadminiii@{DOMAIN}"
                SamAccountName = "AppAdminIII"
                DisplayName = "App Admin III"
                Description = "Admin for Lab Applications"
                Title = "Application Manager"
                Department = "Demo Development"
                Company = "Semperis"
                OfficePhone = "408-555-3434"
                Fax = "(619) 555-9110"
                City = "San Diego"
                EmployeeID = "00088120"
                OUPath = "Lab Admins/Tier 2"
                PasswordNeverExpires = $true
                Groups = @("Special Lab Users")
            }
        )
        
        DemoUsers = @(
            @{
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
                OUPath = "Lab Users/Dept101"
                PasswordNeverExpires = $true
                Groups = @("Special Lab Users")
            }
            @{
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
                OUPath = "Lab Users/Dept101"
                Groups = @("Special Lab Users")
            }
            @{
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
                OUPath = "Lab Users/Dept101"
                Groups = @("Special Lab Users")
            }
            @{
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
                OUPath = "Lab Users/Dept101"
                Groups = @("Special Lab Users")
            }
            @{
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
                OUPath = "Lab Users/Dept101"
                Groups = @("Special Lab Users")
            }
        )
        
        OpsAdmins = @(
            @{
                GivenName = "Ops"
                Surname = "Admin"
                UserPrincipalName = "opsadmin1@{DOMAIN}"
                SamAccountName = "opsadmin1"
                DisplayName = "Ops Admin 1"
                Description = "Operations administrator account"
                Title = "Operations Admin"
                Department = "IT Operations"
                OUPath = "Lab Admins/Tier 2"
                PasswordNeverExpires = $true
                Groups = @("Special Lab Admins")
            }
        )
        
        ServiceAccounts = @(
            @{
                GivenName = "DNS"
                Surname = "Service"
                UserPrincipalName = "svc-dns@{DOMAIN}"
                SamAccountName = "svc-dns"
                DisplayName = "DNS Service Account"
                Description = "Service account for DNS operations"
                OUPath = "Lab Admins/Tier 1"
                PasswordNeverExpires = $true
                Groups = @()
            }
        )
        
        GenericUsers = @{
            Count = 250
            NamePrefix = "GdAct0r-"
            OUPath = "TEST"
            Description = "Generic lab user account"
        }
    }
    
    #---------------------------------------------------------------------------
    # COMPUTERS (in DeleteMe OU and zSpecial OU)
    #---------------------------------------------------------------------------
    Computers = @(
        @{
            Name = "srv-iis-us01"
            SamAccountName = "srv-iis-us01"
            Description = "Special application server for lab"
            OUPath = "DeleteMe OU/Servers"
        }
        @{
            Name = "ops-app-us05"
            SamAccountName = "ops-app-us05"
            Description = "Special application server for lab"
            OUPath = "DeleteMe OU/Resources"
        }
        @{
            Name = "PIMPAM"
            SamAccountName = "PIMPAM"
            Description = "Privileged access server"
            OUPath = "zSpecial OU"
        }
        @{
            Name = "VAULT"
            SamAccountName = "VAULT"
            Description = "Vault server to store passwords and credentials"
            OUPath = "zSpecial OU"
        }
        @{
            Name = "BASTION-HOST01"
            SamAccountName = "BASTION-HOST01"
            Description = "Bastion host for restricted privileged access"
            OUPath = "zSpecial OU"
        }
    )
    
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
    # AD SUBNETS - Using Default-First-Site-Name (SemperisLabs may not exist yet)
    #---------------------------------------------------------------------------
    AdSubnets = @{
        "10.3.22.0/24" = @{
            Site = "Default-First-Site-Name"
            Description = "AD subnet for Semperis Labs"
            Location = "USA-TX-Labs"
        }
        "10.0.0.0/8" = @{
            Site = "Default-First-Site-Name"
            Description = "Primary Lab Infrastructure Network"
            Location = "Lab-USA-All"
        }
        "172.16.32.0/20" = @{
            Site = "Default-First-Site-Name"
            Description = "Special demo lab subnet"
            Location = "Lab-USA-CA"
        }
        "10.222.0.0/16" = @{
            Site = "Default-First-Site-Name"
            Description = "Special Devices Infrastructure Network"
            Location = "Lab-USA-East"
        }
        "10.111.0.0/16" = @{
            Site = "Default-First-Site-Name"
            Description = "Test subnet 0002"
            Location = "Lab-EMEA-ES"
        }
        "10.112.0.0/16" = @{
            Site = "Default-First-Site-Name"
            Description = "Test subnet 0002"
            Location = "Lab-EMEA-ES"
        }
        "111.2.5.0/24" = @{
            Site = "Default-First-Site-Name"
            Description = "Lab subnet in TX"
            Location = "USA-TX-Labs"
        }
        "111.2.6.0/24" = @{
            Site = "Default-First-Site-Name"
            Description = "Lab subnet in Dallas,TX"
            Location = "USA-TX-Dallas-Labs"
        }
        "192.168.0.0/16" = @{
            Site = "Default-First-Site-Name"
            Description = "Primary Demo Lab Infrastructure Network"
            Location = "Lab-USA-TX"
        }
        "192.168.57.0/24" = @{
            Site = "Default-First-Site-Name"
            Description = "Special DMZ network"
            Location = "Lab-USA-AZ"
        }
        "111.111.4.0/24" = @{
            Site = "Default-First-Site-Name"
            Description = "test subnet added via script"
            Location = "USA-TX-Labs"
        }
        "111.111.5.0/24" = @{
            Site = "Default-First-Site-Name"
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
    # DNS ZONES
    #---------------------------------------------------------------------------
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