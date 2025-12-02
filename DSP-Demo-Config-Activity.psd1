################################################################################
##
## DSP-Demo-Config-Activity.psd1
##
## Activity configuration for DSP Demo script suite
## Contains all 30 activity modules mapped from legacy script analysis
##
## Original Author: Rob Ingenthron (robi@semperis.com)
## Refactored By: Bob Lyons
## Version: 1.1.0-20251202
##
## MODULES (30 TOTAL):
## Directory: 01, 02, 15, 18, 19, 20, 23
## DNS: 16, 21
## GPO: 08, 09, 10, 17, 24, 25
## FGPP: 11, 13
## Sites: 03, 12, 27
## ACL: 04, 22, 26
## Security: 06, 07
## DSP: 28, 29, 30
## Group: 05, 14
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
        NewUsersToCreate = 15
    }
    
    #---------------------------------------------------------------------------
    # MODULE 02: Directory-UserAttributes-Part1
    # Set multiple attributes on DemoUser2, DemoUser3, DemoUser4
    #---------------------------------------------------------------------------
    Module02_UserAttributesP1 = @{
        Users = @(
            @{
                SamAccountName = "DemoUser2"
                Attributes = @{
                    telephoneNumber = "555-1234"
                    City = "Phoenix"
                    Division = "Engineering"
                    EmployeeID = "10002"
                    Office = "Building A"
                }
            }
            @{
                SamAccountName = "DemoUser3"
                Attributes = @{
                    telephoneNumber = "555-1235"
                    City = "Seattle"
                    Division = "Sales"
                    EmployeeID = "10003"
                    Office = "Building B"
                }
            }
            @{
                SamAccountName = "DemoUser4"
                Attributes = @{
                    telephoneNumber = "555-1236"
                    City = "Denver"
                    Division = "Marketing"
                    EmployeeID = "10004"
                    Office = "Building C"
                }
            }
        )
    }
    
    #---------------------------------------------------------------------------
    # MODULE 03: Sites-SubnetModifications
    # Change subnet descriptions and locations
    #---------------------------------------------------------------------------
    Module03_SubnetMods = @{
        SubnetChanges = @(
            @{
                Name = "172.16.32.0/20"
                NewDescription = "Modified demo lab subnet"
                NewLocation = "Lab-USA-CA-Updated"
            }
            @{
                Name = "10.222.0.0/16"
                NewDescription = "Updated Special Devices Network"
                NewLocation = "Lab-USA-East-Updated"
            }
        )
    }
    
    #---------------------------------------------------------------------------
    # MODULE 04: ACL-BadOU-Part1
    # Modify ACL on Bad OU (placeholder - actual perms in code)
    #---------------------------------------------------------------------------
    Module04_ACLBadOUP1 = @{
        TargetOU = "Lab Users"
        Modifications = @(
            @{
                Principal = "Tier2Admins"
                Permission = "GenericRead"
            }
        )
    }
    
    #---------------------------------------------------------------------------
    # MODULE 05: Group-MembershipChanges
    # REMOVE App Admin III from Special Lab Users
    #---------------------------------------------------------------------------
    Module05_GroupMembership = @{
        GroupName = "Special Lab Users"
        MembersToRemove = @("App Admin III")
    }
    
    #---------------------------------------------------------------------------
    # MODULE 06: Security-AccountLockout
    # 50 bad password attempts against DemoUser2
    #---------------------------------------------------------------------------
    Module06_AccountLockout = @{
        TargetUser = "DemoUser2"
        BadPasswordAttempts = 50
        BadPassword = "WrongPassword999"
        DelayBetweenAttempts = 100
    }
    
    #---------------------------------------------------------------------------
    # MODULE 07: Security-PasswordSpray
    # 5 users, 10 different passwords each (50 total attempts)
    #---------------------------------------------------------------------------
    Module07_PasswordSpray = @{
        TargetUsers = @(
            "User001", "User002", "User003", "User004", "User005"
        )
        PasswordsPerUser = 10
        BadPasswords = @(
            "Password1!", "Password2!", "Password3!", "Welcome123!",
            "Admin123!", "Test123!", "Demo123!", "Lab123!",
            "Semperis1!", "Change123!"
        )
        DelayBetweenAttempts = 50
    }
    
    #---------------------------------------------------------------------------
    # MODULE 08: GPO-QuestionableGPO
    # Create/modify Questionable GPO
    #---------------------------------------------------------------------------
    Module08_GPOQuestionable = @{
        GpoName = "Questionable GPO"
        Description = "Test GPO for demonstrations"
        Comment = "Modified test GPO"
    }
    
    #---------------------------------------------------------------------------
    # MODULE 09: GPO-LabSMBClientPolicy
    # Create/modify Lab SMB Client Policy GPO
    #---------------------------------------------------------------------------
    Module09_GPOLabSMB = @{
        GpoName = "Lab SMB Client Policy GPO"
        Description = "SMB client security configuration"
        Comment = "Modified SMB policy"
    }
    
    #---------------------------------------------------------------------------
    # MODULE 10: GPO-CISBenchmark
    # Work with CIS Benchmark Windows Server Policy GPO
    #---------------------------------------------------------------------------
    Module10_GPOCIS = @{
        GpoName = "CIS Benchmark Windows Server Policy GPO"
        Description = "CIS hardening baseline"
        Comment = "Modified CIS Benchmark policy"
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
    Module12_SubnetDelete = @{
        SubnetsToDelete = @(
            "10.50.0.0/24"
        )
    }
    
    #---------------------------------------------------------------------------
    # MODULE 13: FGPP-Modifications
    # Modify existing FGPP settings
    #---------------------------------------------------------------------------
    Module13_FGPPModify = @{
        PolicyName = "SpecialLabUsers_PSO"
        Modifications = @(
            @{
                Setting = "LockoutThreshold"
                Value = 5
            }
            @{
                Setting = "LockoutDuration"
                Value = 60
            }
        )
    }
    
    #---------------------------------------------------------------------------
    # MODULE 14: Group-SpecialLabUsersLifecycle
    # 6-step group lifecycle: DELETE/CREATE/MODIFY/MOVE
    #---------------------------------------------------------------------------
    Module14_GroupLifecycle = @{
        GroupName = "Special Lab Users"
        DeleteThenRecreate = $true
        RecreateOU = "Lab Users"
        RecreateScope = "Global"
        RecreateCategory = "Security"
        ChangeToCategory = "Distribution"
        ChangeScopeTo = "Universal"
        MoveToOU = "Lab Admins"
        MembersToAdd = @("App Admin III")
    }
    
    #---------------------------------------------------------------------------
    # MODULE 15: Directory-UserAttributes-AlternateCredentials
    # DemoUser1 changes using OpsAdmin1 credentials
    #---------------------------------------------------------------------------
    Module15_UserAttributesAltCreds = @{
        TargetUser = "DemoUser1"
        AlternateAdmin = "OpsAdmin1"
        Attributes = @{
            telephoneNumber = "555-0001"
            info = "Modified by alternate admin"
        }
    }
    
    #---------------------------------------------------------------------------
    # MODULE 16: DNS-ZoneAndRecordCreation
    # Create reverse zones, forward zone, A records, PTR records, CNAME
    #---------------------------------------------------------------------------
    Module16_DNSCreate = @{
        ReverseZones = @(
            "10.in-addr.arpa",
            "172.in-addr.arpa",
            "168.192.in-addr.arpa"
        )
        ForwardZone = "specialsite.lab"
        ARecords = @(
            @{ Name = "mylabhost01"; IPAddress = "172.16.1.1" }
            @{ Name = "mylabhost02"; IPAddress = "172.16.1.2" }
            @{ Name = "mylabhost03"; IPAddress = "172.16.1.3" }
            @{ Name = "mylabhost04"; IPAddress = "172.16.1.4" }
            @{ Name = "mylabhost05"; IPAddress = "172.16.1.5" }
            @{ Name = "mylabhost06"; IPAddress = "172.16.1.6" }
            @{ Name = "mylabhost07"; IPAddress = "172.16.1.7" }
            @{ Name = "mylabhost08"; IPAddress = "172.16.1.8" }
        )
        PTRRecords = @(
            @{ PTRDomainName = "mylabhost01.specialsite.lab"; IPAddress = "172.16.1.1" }
            @{ PTRDomainName = "mylabhost02.specialsite.lab"; IPAddress = "172.16.1.2" }
        )
        CNAMERecord = @{
            Name = "alias"
            CanonicalName = "mylabhost01.specialsite.lab"
        }
    }
    
    #---------------------------------------------------------------------------
    # MODULE 17: GPO-DefaultDomainPolicy
    # Modify Default Domain Policy settings
    #---------------------------------------------------------------------------
    Module17_GPODefaultDomain = @{
        Modifications = @(
            @{ Setting = "MinPasswordLength"; Value = 12 }
            @{ Setting = "PasswordComplexity"; Value = $true }
            @{ Setting = "LockoutThreshold"; Value = 5 }
        )
    }
    
    #---------------------------------------------------------------------------
    # MODULE 18: Directory-UserMoves-Part2
    # Move ALL users FROM Dept101 TO Dept999 (REVERSE)
    #---------------------------------------------------------------------------
    Module18_UserMovesP2 = @{
        SourceOU = "Lab Users/Dept101"
        TargetOU = "Lab Users/Dept999"
        Description = "Move all users from Dept101 back to Dept999"
    }
    
    #---------------------------------------------------------------------------
    # MODULE 19: Directory-UserAttributes-Part2
    # DemoUser1, DemoUser2, DemoUser3: Change FAX
    #---------------------------------------------------------------------------
    Module19_UserAttributesP2 = @{
        Users = @(
            @{ SamAccountName = "DemoUser1"; facsimileTelephoneNumber = "(555) 555-0001" }
            @{ SamAccountName = "DemoUser2"; facsimileTelephoneNumber = "(555) 555-0002" }
            @{ SamAccountName = "DemoUser3"; facsimileTelephoneNumber = "(555) 555-0003" }
        )
    }
    
    #---------------------------------------------------------------------------
    # MODULE 20: Directory-UserAttributes-Part3
    # DemoUser1, DemoUser2, DemoUser3: Change department
    #---------------------------------------------------------------------------
    Module20_UserAttributesP3 = @{
        Users = @(
            @{ SamAccountName = "DemoUser1"; Department = "Finance" }
            @{ SamAccountName = "DemoUser2"; Department = "Operations" }
            @{ SamAccountName = "DemoUser3"; Department = "Development" }
        )
    }
    
    #---------------------------------------------------------------------------
    # MODULE 21: DNS-RecordModifications
    # Modify existing DNS records, delete records, change TTL
    #---------------------------------------------------------------------------
    Module21_DNSModify = @{
        Zone = "specialsite.lab"
        RecordModifications = @(
            @{ Name = "mylabhost01"; NewIPAddress = "172.16.2.1" }
            @{ Name = "mylabhost02"; NewIPAddress = "172.16.2.2" }
        )
        RecordsToDelete = @("mylabhost08")
        TTLChanges = @(
            @{ Name = "mylabhost03"; NewTTL = 7200 }
        )
    }
    
    #---------------------------------------------------------------------------
    # MODULE 22: ACL-AdditionalChanges
    # Additional ACL modifications
    #---------------------------------------------------------------------------
    Module22_ACLAdditional = @{
        TargetOU = "Lab Computers"
        Modifications = @(
            @{
                Principal = "Tier1Admins"
                Permission = "GenericWrite"
            }
        )
    }
    
    #---------------------------------------------------------------------------
    # MODULE 23: Directory-OU-DeleteMeOU
    # Disable protection on DeleteMe OU and delete entire structure
    #---------------------------------------------------------------------------
    Module23_OUDeleteMe = @{
        TargetOU = "DeleteMe OU"
        DisableProtection = $true
        DeleteEntireStructure = $true
    }
    
    #---------------------------------------------------------------------------
    # MODULE 24: GPO-LinkToBadOU
    # Link GPO to Bad OU
    #---------------------------------------------------------------------------
    Module24_GPOLinkBadOU = @{
        GpoName = "Questionable GPO"
        TargetOU = "Lab Users"
        Enforce = $false
    }
    
    #---------------------------------------------------------------------------
    # MODULE 25: GPO-CISBenchmark-Part2
    # Additional CIS Benchmark modifications
    #---------------------------------------------------------------------------
    Module25_GPOCISPart2 = @{
        GpoName = "CIS Benchmark Windows Server Policy GPO"
        Modifications = @(
            @{ Setting = "AuditAccountLogon"; Value = "Success" }
            @{ Setting = "AuditPrivilegeUse"; Value = "Failure" }
        )
    }
    
    #---------------------------------------------------------------------------
    # MODULE 26: ACL-BadOU-Part2
    # More ACL changes on Bad OU
    #---------------------------------------------------------------------------
    Module26_ACLBadOUP2 = @{
        TargetOU = "Lab Users"
        Modifications = @(
            @{
                Principal = "Tier0Admins"
                Permission = "DeleteChild"
            }
        )
    }
    
    #---------------------------------------------------------------------------
    # MODULE 27: Sites-ConfigurationChanges
    # Modify site configuration, change replication settings
    #---------------------------------------------------------------------------
    Module27_SitesConfig = @{
        SiteModifications = @(
            @{
                Site = "LabSite001"
                NewLocation = "Updated Location"
                NewDescription = "Updated Description"
            }
        )
        ReplicationFrequencyChanges = @(
            @{
                SiteLink = "Default-First-Site-Name -- LabSite001"
                NewFrequency = 30
                NewCost = 25
            }
        )
    }
    
    #---------------------------------------------------------------------------
    # MODULE 28: DSP-AutomatedUndo
    # Connect to DSP server and use DSP cmdlets to undo change
    #---------------------------------------------------------------------------
    Module28_DSPUndo = @{
        DspServer = "dsp.d3.lab"
        ConnectToDSP = $true
        ChangeToUndo = @{
            ObjectType = "User"
            ObjectName = "DemoUser2"
            Attribute = "facsimileTelephoneNumber"
        }
    }
    
    #---------------------------------------------------------------------------
    # MODULE 29: DSP-TriggerUndoRule-TitleChange
    # Change Title on DemoUser3 to trigger DSP undo rule
    #---------------------------------------------------------------------------
    Module29_DSPTriggerTitle = @{
        TargetUser = "DemoUser3"
        Attribute = "Title"
        NewValue = "Senior Manager"
    }
    
    #---------------------------------------------------------------------------
    # MODULE 30: DSP-TriggerUndoRule-GroupMembership
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