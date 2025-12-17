################################################################################
##
## DSP-Demo-Config-Activity.psd1
##
## Activity configuration for DSP Demo script suite
## Contains all 30 activity modules mapped from legacy script analysis
##
## Demo users from legacy script:
## - arose (Axl Rose - DemoUser1)
## - lskywalker (Luke Skywalker - DemoUser2)
## - peter.griffin (Peter Griffin - DemoUser3)
## - pmccartney (Paul McCartney - DemoUser4)
##
## Original Author: Rob Ingenthron (robi@semperis.com)
## Refactored By: Bob Lyons
## Version: 2.0.0-20251202
##
################################################################################

@{
    #---------------------------------------------------------------------------
    # GENERAL SETTINGS
    #---------------------------------------------------------------------------
    General = @{
        DspServer = "dsp.d3.lab"
        DefaultPassword = "P@ssw0rd123!"
        LogPath = "C:\Logs\DSP-Demo"
        VerboseLogging = $true
    }
    
    #---------------------------------------------------------------------------
    # MODULE 01: Directory-UserMoves-Part1
    # Move ALL users FROM Dept999 TO Dept101
    #---------------------------------------------------------------------------
    Module01_UserMovesP1 = @{
        SourceOU = "Lab Users/Dept999"
        TargetOU = "Lab Users/Dept101"
        Description = "Move all users from Dept999 to Dept101"
    }
    
    #---------------------------------------------------------------------------
    # MODULE 02: Directory-UserAttributes-Part1
    # Set multiple attributes on lskywalker, peter.griffin, pmccartney
    #---------------------------------------------------------------------------
    Module02_UserAttributesP1 = @{
        Users = @(
            @{
                SamAccountName = "lskywalker"
                Attributes = @{
                    telephoneNumber = "408-555-5151"
                    City = "Tatooine"
                    Division = "Spoon Bending"
                    EmployeeID = "00314159"
                    Office = "Building A"
                }
            }
            @{
                SamAccountName = "peter.griffin"
                Attributes = @{
                    telephoneNumber = "408-777-3333"
                    City = "Quahog"
                    Division = "Blue Collar"
                    EmployeeID = "00987654321"
                    Office = "Building B"
                }
            }
            @{
                SamAccountName = "pmccartney"
                Attributes = @{
                    telephoneNumber = "011 44 20 1234 5678"
                    City = "Liverpool"
                    Division = "Legends"
                    EmployeeID = "000001212"
                    Office = "Building C"
                }
            }
        )
    }
    
    #---------------------------------------------------------------------------
    # MODULE 03: Sites-SubnetModifications
    # Change subnet descriptions that were created during setup
    #---------------------------------------------------------------------------
    Module03_SubnetsModify = @{
        Subnets = @(
            @{
                Name = "111.111.4.0/24"
                Description = "Changed the subnet description attribute!!"
            }
            @{
                Name = "111.111.5.0/24"
                Description = "Changed the subnet description attribute!!"
            }
        )
    }
    
    #---------------------------------------------------------------------------
    # MODULE 04: ACL-BadOU-Part1
    # Modify ACL on Bad OU
    #---------------------------------------------------------------------------
    Module04_ACLBadOUPart1 = @{
        OU = "Bad OU"
        Modifications = @(
            @{
                Identity = "Authenticated Users"
                Action = "Add"
                Rights = "GenericRead"
            }
        )
    }
    
    #---------------------------------------------------------------------------
    # MODULE 05: Group-MembershipChanges
    # Remove App Admin III from Special Lab Users
    #---------------------------------------------------------------------------
    Module05_GroupMembership = @{
        GroupName = "Special Lab Users"
        RemoveMembers = @("App Admin III")
    }
    
    #---------------------------------------------------------------------------
    # MODULE 06: Security-AccountLockout
    # 50 bad password attempts against lskywalker
    #---------------------------------------------------------------------------
    Module06_AccountLockout = @{
        TargetUser = "lskywalker"
        BadPasswordAttempts = 50
        DelayBetweenAttempts = 100
    }
    
    #---------------------------------------------------------------------------
    # MODULE 07: Security-PasswordSpray
    # Password spray attack against multiple users
    #---------------------------------------------------------------------------
    Module07_PasswordSpray = @{
        SourceOU = "Lab Users"
        UserCount = 5
        PasswordsToTry = @(
            "P@ssw0rd", "Password", "Pass123!", "Welcome", "Admin123!",
            "Test123!", "Demo123!", "Lab123!", "Semperis1!", "Change123!"
        )
        DelayBetweenAttempts = 50
    }
    
    #---------------------------------------------------------------------------
    # MODULE 08: GPO-QuestionableGPO
    # Create/modify Questionable GPO
    #---------------------------------------------------------------------------
    Module08_GPOQuestionable = @{
        GpoName = "Questionable GPO"
        DisplayName = "Questionable GPO"
        Comment = "Simple test GPO for demonstrations"
    }
    
    #---------------------------------------------------------------------------
    # MODULE 09: GPO-LabSMBClientPolicy
    # Create/modify Lab SMB Client Policy GPO
    #---------------------------------------------------------------------------
    Module09_GPOLabSMB = @{
        GpoName = "Lab SMB Client Policy GPO"
        DisplayName = "Lab SMB Client Policy GPO"
        Comment = "SMB client security configuration for lab"
    }
    
    #---------------------------------------------------------------------------
    # MODULE 10: GPO-CISBenchmark
    # Work with CIS Benchmark Windows Server Policy GPO
    #---------------------------------------------------------------------------
    Module10_GPOCIS = @{
        GpoName = "CIS Benchmark Windows Server Policy GPO"
        DisplayName = "CIS Benchmark Windows Server Policy GPO"
        Comment = "CIS Windows Server hardening policy baseline"
    }
    
    #---------------------------------------------------------------------------
    # MODULE 11: FGPP-SpecialLabUsersPSO
    # Create SpecialLabUsers_PSO with settings and assign to group
    #---------------------------------------------------------------------------
    Module11_FGPPCreate = @{
        PolicyName = "SpecialLabUsers_PSO"
        Precedence = 10
        LockoutThreshold = 3
        LockoutDuration = 30
        LockoutObservationWindow = 30
        MinPasswordLength = 12
        PasswordComplexity = $true
        PasswordHistoryCount = 24
        MaxPasswordAge = 30
        MinPasswordAge = 1
        ApplyToGroup = "Special Lab Users"
    }
    
    #---------------------------------------------------------------------------
    # MODULE 12: Sites-SubnetDeletion
    # Delete AD subnets
    #---------------------------------------------------------------------------
    Module12_SubnetDeletion = @{
        SubnetsToDelete = @(
            "111.111.4.0/24"
            "111.111.5.0/24"
        )
    }
    
    #---------------------------------------------------------------------------
    # MODULE 13: FGPP-Modifications
    # Modify existing FGPP settings
    #---------------------------------------------------------------------------
    Module13_FGPPModify = @{
        PolicyName = "SpecialLabUsers_PSO"
        Modifications = @{
            LockoutThreshold = 5
            MaxPasswordAge = 60
        }
    }
    
    #---------------------------------------------------------------------------
    # MODULE 14: Group-SpecialLabUsers-Recreation (MAJOR ACTIVITY)
    # Complex sequence: Delete, Create, Change category, Change scope, Move, Add member
    #---------------------------------------------------------------------------
    Module14_GroupRecreation = @{
        GroupName = "Special Lab Users"
        Operations = @(
            @{ Operation = "Delete"; GroupName = "Special Lab Users" }
            @{ Operation = "Create"; GroupName = "Special Lab Users"; Scope = "Global"; Category = "Security"; Path = "Lab Users" }
            @{ Operation = "ChangeCategory"; GroupName = "Special Lab Users"; NewCategory = "Distribution" }
            @{ Operation = "ChangeScope"; GroupName = "Special Lab Users"; NewScope = "Universal" }
            @{ Operation = "Move"; GroupName = "Special Lab Users"; NewPath = "Lab Admins" }
            @{ Operation = "AddMember"; GroupName = "Special Lab Users"; Member = "App Admin III" }
        )
    }
    
    #---------------------------------------------------------------------------
    # MODULE 15: Directory-UserAttributes-AlternateCredentials
    # DemoUser1 (arose) changes using alternate credentials (OpsAdmin1)
    #---------------------------------------------------------------------------
    Module15_UserAttributesAltCreds = @{
        TargetUser = "arose"
        ChangeAsUser = "opsadmin1"     # Changed from lskywalker to opsadmin1
        AltUserPassword = "P@ssw0rd123!" # Added for unattended execution
        Attributes = @{
            telephoneNumber = "(000) 867-5309"
            info = "Changed by alternate user"
        }
    }
    
    #---------------------------------------------------------------------------
    # MODULE 16: DNS-ZoneAndRecordCreation
    # Create reverse zones and DNS records
    #---------------------------------------------------------------------------
    Module16_DNSZoneCreate = @{
        ReverseZones = @(
            "10.in-addr.arpa"
            "172.in-addr.arpa"
            "168.192.in-addr.arpa"
        )
        ForwardZones = @(
            "specialsite.lab"
        )
        ARecords = @(
            @{ Name = "mylabhost01"; IPAddress = "192.168.1.100"; Zone = "specialsite.lab" }
            @{ Name = "mylabhost02"; IPAddress = "192.168.1.101"; Zone = "specialsite.lab" }
            @{ Name = "mylabhost03"; IPAddress = "192.168.1.102"; Zone = "specialsite.lab" }
            @{ Name = "mylabhost04"; IPAddress = "192.168.1.103"; Zone = "specialsite.lab" }
            @{ Name = "mylabhost05"; IPAddress = "192.168.1.104"; Zone = "specialsite.lab" }
            @{ Name = "mylabhost06"; IPAddress = "192.168.1.105"; Zone = "specialsite.lab" }
            @{ Name = "mylabhost07"; IPAddress = "192.168.1.106"; Zone = "specialsite.lab" }
            @{ Name = "mylabhost08"; IPAddress = "192.168.1.107"; Zone = "specialsite.lab" }
        )
        CNAMERecords = @(
            @{ Name = "www"; Target = "mylabhost01"; Zone = "specialsite.lab" }
        )
    }
    
    #---------------------------------------------------------------------------
    # MODULE 17: GPO-DefaultDomainPolicy
    # Modify Default Domain Policy settings
    #---------------------------------------------------------------------------
    Module17_GPODefaultDomain = @{
        GpoName = "Default Domain Policy"
        Modifications = @{
            MinPasswordLength = 14
            PasswordComplexity = $true
            AccountLockoutThreshold = 5
        }
    }
    
    #---------------------------------------------------------------------------
    # MODULE 18: Directory-UserMoves-Part2 (REVERSE MOVE)
    # Move ALL users FROM Dept101 TO Dept999 (reverses Module 01)
    #---------------------------------------------------------------------------
    Module18_UserMovesPart2 = @{
        SourceOU = "Lab Users/Dept101"
        TargetOU = "Lab Users/Dept999"
        Description = "Move all users from Dept101 back to Dept999"
    }
    
    #---------------------------------------------------------------------------
    # MODULE 19: Directory-UserAttributes-Part2
    # Change FAX on arose, lskywalker, peter.griffin
    #---------------------------------------------------------------------------
    Module19_UserAttributesPart2 = @{
        Users = @(
            @{
                SamAccountName = "arose"
                Attributes = @{
                    Fax = "+501 11-0001"
                }
            }
            @{
                SamAccountName = "lskywalker"
                Attributes = @{
                    Fax = "+41 111-9999"
                }
            }
            @{
                SamAccountName = "peter.griffin"
                Attributes = @{
                    Fax = "+1 216 111-888"
                }
            }
        )
    }
    
    #---------------------------------------------------------------------------
    # MODULE 20: Directory-UserAttributes-Part3
    # Change department on arose, lskywalker, peter.griffin
    #---------------------------------------------------------------------------
    Module20_UserAttributesPart3 = @{
        Users = @(
            @{
                SamAccountName = "arose"
                Attributes = @{
                    Department = "Engineering"
                }
            }
            @{
                SamAccountName = "lskywalker"
                Attributes = @{
                    Department = "Operations"
                }
            }
            @{
                SamAccountName = "peter.griffin"
                Attributes = @{
                    Department = "Management"
                }
            }
        )
    }
    
    #---------------------------------------------------------------------------
    # MODULE 21: DNS-RecordModifications
    # Modify and delete DNS records
    #---------------------------------------------------------------------------
    Module21_DNSRecordModify = @{
        RecordModifications = @(
            @{ 
                Name = "mylabhost01"
                Zone = "specialsite.lab"
                NewIPAddress = "192.168.1.200"
            }
        )
        RecordsToDelete = @(
            @{ Name = "mylabhost08"; Zone = "specialsite.lab" }
        )
    }
    
    #---------------------------------------------------------------------------
    # MODULE 22: ACL-AdditionalChanges
    # Additional ACL modifications
    #---------------------------------------------------------------------------
    Module22_ACLAdditional = @{
        OU = "Bad OU"
        Modifications = @(
            @{
                Identity = "SYSTEM"
                Action = "Modify"
                Rights = "GenericWrite"
            }
        )
    }
    
    #---------------------------------------------------------------------------
    # MODULE 23: Directory-OU-DeleteMeOU
    # Disable protection on DeleteMe OU and delete entire structure
    #---------------------------------------------------------------------------
    Module23_OUDeleteMe = @{
        OUPath = "DeleteMe OU"
        DisableProtection = $true
        DeleteOUStructure = $true
    }
    
    #---------------------------------------------------------------------------
    # MODULE 24: GPO-LinkToBadOU
    # Link GPO to Bad OU
    #---------------------------------------------------------------------------
    Module24_GPOLinkBadOU = @{
        GpoName = "Questionable GPO"
        TargetOU = "Bad OU"
        Enabled = $true
    }
    
    #---------------------------------------------------------------------------
    # MODULE 25: GPO-CISBenchmark-Part2
    # Additional CIS Benchmark modifications
    #---------------------------------------------------------------------------
    Module25_GPOCISPart2 = @{
        GpoName = "CIS Benchmark Windows Server Policy GPO"
        Modifications = @{
            AuditAccountLogon = "Success"
            AuditObjectAccess = "Success"
        }
    }
    
    #---------------------------------------------------------------------------
    # MODULE 26: ACL-BadOU-Part2
    # More ACL changes on Bad OU
    #---------------------------------------------------------------------------
    Module26_ACLBadOUPart2 = @{
        OU = "Bad OU"
        Modifications = @(
            @{
                Identity = "Domain Users"
                Action = "Add"
                Rights = "GenericRead"
            }
        )
    }
    
    #---------------------------------------------------------------------------
    # MODULE 27: Sites-ConfigurationChanges
    # Modify site configuration and change replication settings
    #---------------------------------------------------------------------------
    Module27_SitesConfig = @{
        SiteModifications = @{
            Site = "LabSite001"
            NewLocation = "Updated Location"
            NewDescription = "Updated Description"
        }
        ReplicationFrequencyChanges = @{
            SiteLink = "Default-First-Site-Name -- LabSite001"
            NewFrequency = 30
            NewCost = 25
        }
    }
    
    #---------------------------------------------------------------------------
    # MODULE 28: DSP-AutomatedUndo (DSP-SPECIFIC)
    # Connect to DSP server and use DSP cmdlets to undo change
    #---------------------------------------------------------------------------
    Module28_DSPUndo = @{
        DspServer = "dsp.d3.lab"
        ConnectToDSP = $true
        ChangeToUndo = @{
            ObjectType = "User"
            ObjectName = "lskywalker"
            Attribute = "facsimileTelephoneNumber"
        }
    }
    
    #---------------------------------------------------------------------------
    # MODULE 29: DSP-TriggerUndoRule-TitleChange (DSP-SPECIFIC)
    # Change Title on peter.griffin to trigger DSP undo rule
    #---------------------------------------------------------------------------
    Module29_DSPTriggerTitle = @{
        TargetUser = "peter.griffin"
        Attribute = "Title"
        Value1 = "Sales"
        Value2 = "Senior Manager"
    }
    
    #---------------------------------------------------------------------------
    # MODULE 30: DSP-TriggerUndoRule-GroupMembership (DSP-SPECIFIC)
    # Remove ALL users from Special Lab Admins to trigger DSP undo rule
    #---------------------------------------------------------------------------
    Module30_DSPTriggerGroup = @{
        GroupName = "Special Lab Admins"
        RemoveAllMembers = $true
    }
}

################################################################################
# END OF ACTIVITY CONFIGURATION
################################################################################