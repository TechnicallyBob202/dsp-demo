################################################################################
##
## DSP-Demo-Config.psd1 (New Structure)
##
## Configuration file for DSP Demo script suite with hierarchical OU structure
## Operators can modify OUs, users, and groups by editing this file
##
## Key Changes from old structure:
##   - OUs defined hierarchically (parent/child relationships)
##   - Users reference OUs by logical path (e.g., "Root/LabAdmins/Tier0")
##   - Groups reference users by name (e.g., "dspadmin")
##   - All placeholders {DOMAIN_DN}, {DOMAIN}, {PASSWORD} expanded at runtime
##
## How to use:
##   1. Edit OUs section to define your OU structure
##   2. Edit Users section - assign each user to an OU via OUPath
##   3. Edit Groups section - reference users by SamAccountName
##   4. Placeholders like {DOMAIN_DN} are automatically replaced
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
    # Define OUs hierarchically. Parent/child relationships are implicit from nesting.
    # All OUs reference {DOMAIN_DN} which gets replaced at runtime.
    #
    # Paths are referenced as: Root, Root/LabAdmins, Root/LabAdmins/Tier0, etc.
    # These logical paths are converted to actual DNs by the Directory module.
    #
    # Properties:
    #   Name = AD OU name
    #   Description = OU description
    #   ProtectFromAccidentalDeletion = $true or $false (default: $true)
    #   Children = nested hashtable of child OUs
    #---------------------------------------------------------------------------
    OUs = @{
        Root = @{
            Name = "DSP-Demo-Objects"
            Description = "Root OU for DSP demo activity generation"
            Path = "{DOMAIN_DN}"
            ProtectFromAccidentalDeletion = $true
            Children = @{
                
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
                        LabUsers01 = @{
                            Name = "Lab Users 01"
                            Description = "Lab users group 1"
                            ProtectFromAccidentalDeletion = $true
                        }
                        LabUsers02 = @{
                            Name = "Lab Users 02"
                            Description = "Lab users group 2"
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
                        Resources = @{
                            Name = "Resources"
                            Description = "Sub-OU that will be deleted"
                            ProtectFromAccidentalDeletion = $false
                        }
                        CorpSpecial = @{
                            Name = "Corp Special OU"
                            Description = "Corporate special OU sub-resource"
                            ProtectFromAccidentalDeletion = $false
                        }
                    }
                }
                
                Servers = @{
                    Name = "Servers"
                    Description = "Server computer objects"
                    ProtectFromAccidentalDeletion = $true
                }
                
                Tier0SpecialAssets = @{
                    Name = "Tier-0-Special-Assets"
                    Description = "Tier 0 special assets with restricted access"
                    ProtectFromAccidentalDeletion = $true
                }
                
                TEST = @{
                    Name = "TEST"
                    Description = "Test OU for generic bulk user creation"
                    ProtectFromAccidentalDeletion = $false
                }
            }
        }
    }
    
    #---------------------------------------------------------------------------
    # USERS
    #
    # Define users by category. Each user must have:
    #   - SamAccountName: AD logon name
    #   - Name, GivenName, Surname: AD naming
    #   - OUPath: Logical path to OU (e.g., "Root/LabAdmins/Tier0")
    #   - Password: Will be replaced with {PASSWORD} placeholder value
    #
    # Optional fields:
    #   - DisplayName, Title, Department, Company, Mail, TelephoneNumber, etc.
    #   - PasswordNeverExpires: $true or $false
    #   - Enabled: $true or $false (default: $true)
    #
    # The OUPath must match an OU defined in the OUs section above.
    # If OUPath doesn't exist, user creation will be skipped with a warning.
    #---------------------------------------------------------------------------
    Users = @{
        
        # =====================================================
        # TIER 0 ADMIN ACCOUNTS
        # =====================================================
        Tier0Admins = @(
            @{
                SamAccountName = "Admin-Tier0"
                Name = "Admin-Tier0"
                GivenName = "Admin"
                Surname = "Tier0"
                DisplayName = "Admin-Tier0"
                Title = "Tier 0 Administrator"
                Department = "Infrastructure"
                Company = "{COMPANY}"
                Mail = "admin-tier0@{DOMAIN}"
                TelephoneNumber = "555-0100"
                Description = "Tier 0 special admin account"
                OUPath = "Root/LabAdmins/Tier0"
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
                Name = "John Wick (Admin)"
                GivenName = "John"
                Surname = "Wick"
                DisplayName = "John Wick (admin)"
                Title = "Operations Lead"
                Department = "Operations"
                Company = "{COMPANY}"
                Mail = "adm.johnwick@{DOMAIN}"
                TelephoneNumber = "555-0101"
                Description = "Tier 1 operations administrator"
                OUPath = "Root/LabAdmins/Tier1"
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
                SamAccountName = "dspadmin"
                Name = "DSP Admin"
                GivenName = "DSP"
                Surname = "Admin"
                DisplayName = "DSP Admin"
                Title = "DSP Administrator"
                Department = "Infrastructure"
                Company = "{COMPANY}"
                Mail = "dspadmin@{DOMAIN}"
                TelephoneNumber = "555-0102"
                Description = "Administrator for DSP management server"
                OUPath = "Root/LabAdmins/Tier2"
                Password = "{PASSWORD}"
                PasswordNeverExpires = $true
                Enabled = $true
            }
            @{
                SamAccountName = "t2admin"
                Name = "T2 Admin"
                GivenName = "Tier"
                Surname = "Two Admin"
                DisplayName = "T2 Admin"
                Title = "Application Administrator"
                Department = "Applications"
                Company = "{COMPANY}"
                Mail = "t2admin@{DOMAIN}"
                TelephoneNumber = "555-0103"
                Description = "Tier 2 application administrator"
                OUPath = "Root/LabAdmins/Tier2"
                Password = "{PASSWORD}"
                PasswordNeverExpires = $true
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
                TelephoneNumber = "555-0104"
                Description = "Tier 2 operations administrator"
                OUPath = "Root/LabAdmins/Tier2"
                Password = "{PASSWORD}"
                PasswordNeverExpires = $false
                Enabled = $true
            }
        )
        
        # =====================================================
        # DEMO USERS (subject to attribute changes, lockouts, etc.)
        # =====================================================
        DemoUsers = @(
            @{
                SamAccountName = "arose"
                Name = "Axl Rose"
                GivenName = "Axl"
                Surname = "Rose"
                DisplayName = "Axl Rose"
                Title = "Lead Singer"
                Department = "Music"
                Company = "Guns N Roses"
                Mail = "arose@{DOMAIN}"
                TelephoneNumber = "555-0200"
                Description = "Demo user #1 - Subject to frequent attribute changes"
                OUPath = "Root/LabUsers"
                Password = "{PASSWORD}"
                PasswordNeverExpires = $false
                Enabled = $true
            }
            @{
                SamAccountName = "shudson"
                Name = "Slash Hudson"
                GivenName = "Slash"
                Surname = "Hudson"
                DisplayName = "Slash Hudson"
                Title = "Guitarist"
                Department = "Music"
                Company = "Guns N Roses"
                Mail = "shudson@{DOMAIN}"
                TelephoneNumber = "555-0201"
                Description = "Demo user #2 - Used for account lockout demonstrations"
                OUPath = "Root/LabUsers"
                Password = "{PASSWORD}"
                PasswordNeverExpires = $false
                Enabled = $true
            }
            @{
                SamAccountName = "dmckagan"
                Name = "Duff McKagan"
                GivenName = "Duff"
                Surname = "McKagan"
                DisplayName = "Duff McKagan"
                Title = "Bass Player"
                Department = "Music"
                Company = "Guns N Roses"
                Mail = "dmckagan@{DOMAIN}"
                TelephoneNumber = "555-0202"
                Description = "Demo user #3 - Used for auto-undo rule testing"
                OUPath = "Root/LabUsers"
                Password = "{PASSWORD}"
                PasswordNeverExpires = $false
                Enabled = $true
            }
            @{
                SamAccountName = "pmccartney"
                Name = "Paul McCartney"
                GivenName = "Paul"
                Surname = "McCartney"
                DisplayName = "Paul McCartney"
                Title = "Musician"
                Department = "Music"
                Company = "The Beatles"
                Mail = "pmccartney@{DOMAIN}"
                TelephoneNumber = "555-0203"
                Description = "Demo user #4 - Additional demo user for variety"
                OUPath = "Root/LabUsers"
                Password = "{PASSWORD}"
                PasswordNeverExpires = $false
                Enabled = $true
            }
        )
    }
    
    #---------------------------------------------------------------------------
    # GROUPS
    #
    # Define security groups. Each group must have:
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
    # If a user doesn't exist, they're skipped with a warning.
    #---------------------------------------------------------------------------
    Groups = @{
        AdminGroups = @(
            @{
                SamAccountName = "SpecialLabAdmins"
                Name = "Special Lab Admins"
                DisplayName = "Special Lab Admins"
                Description = "Special lab administrator group with elevated privileges"
                OUPath = "Root/LabAdmins"
                GroupScope = "Global"
                GroupCategory = "Security"
                Members = @("dspadmin", "t2admin", "opsadmin1")
            }
            @{
                SamAccountName = "SpecialLabUsers"
                Name = "Special Lab Users"
                DisplayName = "Special Lab Users"
                Description = "Special lab users group"
                OUPath = "Root/LabUsers"
                GroupScope = "Global"
                GroupCategory = "Security"
                Members = @("arose", "shudson", "dmckagan")
            }
        )
    }
    
    #---------------------------------------------------------------------------
    # FINE-GRAINED PASSWORD POLICIES (FGPP)
    #
    # Define password policies. Each FGPP must have:
    #   - Name: Policy name
    #   - Precedence: Priority (lower number = higher priority)
    #   - AppliesTo: User/group to apply policy to (optional)
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
}

################################################################################
# END OF CONFIGURATION
################################################################################