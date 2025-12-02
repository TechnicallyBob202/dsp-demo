################################################################################
##
## DSP-Demo-Config-Setup.psd1
##
## Setup configuration for DSP Demo script suite
## Contains all baseline AD objects created during setup phase:
## - Organizational Units
## - Groups
## - Users (Tier admins, demo users, service accounts, generic users)
## - Computers
## - AD Sites
## - AD Subnets
## - AD Site Links
## - DNS Zones (forward and reverse)
## - Group Policy Objects
##
## Original Author: Rob Ingenthron (robi@semperis.com)
## Refactored By: Bob Lyons
## Version: 1.0.0-20251202
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
        DefaultPassword = "Password1"
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
        # COMPUTERS STRUCTURE
        # =====================================================
        LabComputers = @{
            Name = "Lab Computers"
            Description = "Lab computer accounts"
            ProtectFromAccidentalDeletion = $true
        }
        
        # =====================================================
        # DELETE ME - FOR RECOVERY DEMOS
        # =====================================================
        DeleteMeOU = @{
            Name = "DeleteMe OU"
            Description = "OU structure for deletion and recovery demonstrations"
            ProtectFromAccidentalDeletion = $true
            Children = @{
                Servers = @{
                    Name = "Servers"
                    Description = "Server computers for demo purposes"
                    ProtectFromAccidentalDeletion = $false
                }
                Resources = @{
                    Name = "Resources"
                    Description = "Resource accounts for demo purposes"
                    ProtectFromAccidentalDeletion = $false
                }
            }
        }
        
        # =====================================================
        # SPECIAL RESTRICTED OU FOR TIER 0 ASSETS
        # =====================================================
        SpecialOU = @{
            Name = "Special Restricted OU"
            Description = "Highly restricted OU for tier 0 infrastructure assets"
            ProtectFromAccidentalDeletion = $true
        }
    }
    
    #---------------------------------------------------------------------------
    # GROUPS
    #---------------------------------------------------------------------------
    Groups = @{
        AdminGroups = @(
            @{
                SamAccountName = "Tier0Admins"
                Name = "Tier0Admins"
                DisplayName = "Tier 0 Admins"
                Description = "Tier 0 admin group for enterprise administrators"
                GroupScope = "Global"
                GroupCategory = "Security"
                OUPath = "Lab Admins"
            }
            @{
                SamAccountName = "Tier1Admins"
                Name = "Tier1Admins"
                DisplayName = "Tier 1 Admins"
                Description = "Tier 1 admin group for domain administrators"
                GroupScope = "Global"
                GroupCategory = "Security"
                OUPath = "Lab Admins"
            }
            @{
                SamAccountName = "Tier2Admins"
                Name = "Tier2Admins"
                DisplayName = "Tier 2 Admins"
                Description = "Tier 2 admin group for application administrators"
                GroupScope = "Global"
                GroupCategory = "Security"
                OUPath = "Lab Admins"
            }
        )
        UserGroups = @(
            @{
                SamAccountName = "DemoUsers"
                Name = "DemoUsers"
                DisplayName = "Demo Users"
                Description = "Group for demo user accounts"
                GroupScope = "Global"
                GroupCategory = "Security"
                OUPath = "Lab Users"
            }
        )
    }
    
    #---------------------------------------------------------------------------
    # TIER ADMIN ACCOUNTS
    #---------------------------------------------------------------------------
    Users = @{
        Tier0Admins = @(
            @{
                Name = "t0-admin-enterprise"
                GivenName = "Enterprise"
                Surname = "Admin"
                UserPrincipalName = "t0-admin-enterprise@{DOMAIN}"
                SamAccountName = "t0-admin-ent"
                Description = "Tier 0 Enterprise Admin account"
                OUPath = "Lab Admins/Tier 0"
                Enabled = $true
                PasswordNeverExpires = $false
            }
        )
        Tier1Admins = @(
            @{
                Name = "t1-admin-domain"
                GivenName = "Domain"
                Surname = "Admin"
                UserPrincipalName = "t1-admin-domain@{DOMAIN}"
                SamAccountName = "t1-admin-dom"
                Description = "Tier 1 Domain Admin account"
                OUPath = "Lab Admins/Tier 1"
                Enabled = $true
                PasswordNeverExpires = $false
            }
            @{
                Name = "t1-admin-infrastructure"
                GivenName = "Infrastructure"
                Surname = "Admin"
                UserPrincipalName = "t1-admin-infrastructure@{DOMAIN}"
                SamAccountName = "t1-admin-inf"
                Description = "Tier 1 Infrastructure Admin account"
                OUPath = "Lab Admins/Tier 1"
                Enabled = $true
                PasswordNeverExpires = $false
            }
        )
        Tier2Admins = @(
            @{
                Name = "t2-admin-application"
                GivenName = "Application"
                Surname = "Admin"
                UserPrincipalName = "t2-admin-application@{DOMAIN}"
                SamAccountName = "t2-admin-app"
                Description = "Tier 2 Application Admin account"
                OUPath = "Lab Admins/Tier 2"
                Enabled = $true
                PasswordNeverExpires = $false
            }
            @{
                Name = "t2-admin-service"
                GivenName = "Service"
                Surname = "Admin"
                UserPrincipalName = "t2-admin-service@{DOMAIN}"
                SamAccountName = "t2-admin-svc"
                Description = "Tier 2 Service Admin account"
                OUPath = "Lab Admins/Tier 2"
                Enabled = $true
                PasswordNeverExpires = $false
            }
        )
        DemoUsers = @(
            @{
                Name = "demo-user-01"
                GivenName = "Demo"
                Surname = "User01"
                UserPrincipalName = "demo-user-01@{DOMAIN}"
                SamAccountName = "demo-user-01"
                Description = "Demo user account for demonstrations"
                OUPath = "Lab Users/Dept101"
                Enabled = $true
                PasswordNeverExpires = $false
            }
            @{
                Name = "demo-user-02"
                GivenName = "Demo"
                Surname = "User02"
                UserPrincipalName = "demo-user-02@{DOMAIN}"
                SamAccountName = "demo-user-02"
                Description = "Demo user account for demonstrations"
                OUPath = "Lab Users/Dept101"
                Enabled = $true
                PasswordNeverExpires = $false
            }
            @{
                Name = "demo-user-03"
                GivenName = "Demo"
                Surname = "User03"
                UserPrincipalName = "demo-user-03@{DOMAIN}"
                SamAccountName = "demo-user-03"
                Description = "Demo user account for demonstrations"
                OUPath = "Lab Users/Dept101"
                Enabled = $true
                PasswordNeverExpires = $false
            }
        )
        ServiceAccounts = @(
            @{
                Name = "svc-dsp"
                GivenName = "DSP"
                Surname = "Service"
                UserPrincipalName = "svc-dsp@{DOMAIN}"
                SamAccountName = "svc-dsp"
                Description = "Service account for DSP integration"
                OUPath = "Lab Admins/Tier 1"
                Enabled = $true
                PasswordNeverExpires = $false
            }
            @{
                Name = "svc-dns"
                GivenName = "DNS"
                Surname = "Service"
                UserPrincipalName = "svc-dns@{DOMAIN}"
                SamAccountName = "svc-dns"
                Description = "Service account for DNS operations"
                OUPath = "Lab Admins/Tier 1"
                Enabled = $true
                PasswordNeverExpires = $false
            }
        )
        GenericUsers = @(
            @{
                Count = 250
                SamAccountNamePrefix = "User"
                OUPath = "Lab Users/Dept101"
                Description = "Generic lab user account"
            }
        )
    }
    
    #---------------------------------------------------------------------------
    # COMPUTERS
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
            OUPath = "Special Restricted OU"
        }
        @{
            Name = "VAULT"
            SamAccountName = "VAULT"
            Description = "Vault server to store passwords and credentials"
            OUPath = "Special Restricted OU"
        }
        @{
            Name = "BASTION-HOST01"
            SamAccountName = "BASTION-HOST01"
            Description = "Bastion host for restricted privileged access"
            OUPath = "Special Restricted OU"
        }
    )
    
    #---------------------------------------------------------------------------
    # FINE-GRAINED PASSWORD POLICIES (FGPP)
    #---------------------------------------------------------------------------
    FGPPs = @(
        @{
            Name = "SpecialLabUsers_PSO"
            Description = "Account Lockout policy for Special Lab Users members"
            DisplayName = "SpecialLabUsers_PSO"
            Precedence = 2
            MinPasswordLength = 8
            ComplexityEnabled = $true
            LockoutThreshold = 20
            MaxPasswordAge = 42
            MinPasswordAge = 1
            PasswordHistoryCount = 24
            ReversibleEncryptionEnabled = $false
            ApplyToGroup = "SpecialLabUsers"
        }
    )
    
    #---------------------------------------------------------------------------
    # DEFAULT DOMAIN PASSWORD POLICY SETTINGS
    #---------------------------------------------------------------------------
    DefaultDomainPolicy = @{
        MinPasswordLength = 8
        PasswordComplexity = $true
        PasswordHistoryCount = 24
        MaxPasswordAge = 42
        MinPasswordAge = 0
        LockoutThreshold = 11
        LockoutDuration = 3
        LockoutObservationWindow = 3
        ReversibleEncryption = $false
    }
    
    #---------------------------------------------------------------------------
    # AD SITES
    #---------------------------------------------------------------------------
    AdSites = @{
        LabSite001 = @{
            Description = "Lab site for demonstration"
            Location = "SemperisLabs-USA-AZ"
        }
    }
    
    #---------------------------------------------------------------------------
    # AD SUBNETS
    #---------------------------------------------------------------------------
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
    
    #---------------------------------------------------------------------------
    # AD SITE LINKS
    #---------------------------------------------------------------------------
    AdSiteLinks = @{
        "Default-First-Site-Name -- LabSite001" = @{
            Sites = @("Default-First-Site-Name", "LabSite001")
            Cost = 22
            ReplicationFrequencyInMinutes = 18
            Description = "Site link for lab replication"
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