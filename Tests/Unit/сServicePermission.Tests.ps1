$DSCModuleName = 'cServicePermission'
$DSCResourceName = 'cServicePermission'

$Splat = @{
    Path = $PSScriptRoot
    ChildPath = "..\..\DSCResources\$DSCResourceName\$DSCResourceName.psm1"
    Resolve = $true
    ErrorAction = 'Stop'
}
$DSCResourceModuleFile = Get-Item -Path (Join-Path @Splat)

if (Get-Module -Name $DSCResourceName)
{
    Remove-Module -Name $DSCResourceName
}

Import-Module -Name $DSCResourceModuleFile.FullName -Force

$ModuleRoot = "${env:ProgramFiles}\WindowsPowerShell\Modules\$DSCModuleName"

if (-not (Test-Path -Path $ModuleRoot -PathType Container))
{
    New-Item -Path $ModuleRoot -ItemType Directory | Out-Null
}

Copy-Item -Path "$PSScriptRoot\..\..\*" -Destination $ModuleRoot -Recurse -Force -Exclude '.git'

$MockParameters = @{
    ServiceName   = 'MockService'
    Principal     = 'mock\Principal'
    AccessRights = 'QueryConfig'
}
$MockACE = ([WMIClass]"Win32_ACE").CreateInstance()
$MockACE.AccessMask = 1
$MockTrustee = ([WMIClass]"Win32_Trustee").CreateInstance()
$MockDomainAndName = ($MockParameters.Principal).Split('\')
$MockTrustee.Name = $MockDomainAndName[1]
$MockTrustee.SIDString = "S-1-1-1-1-1"
$MockACE.trustee = $MockTrustee
$MockSecurityDescriptor = ([WMIClass]"Win32_SecurityDescriptor").CreateInstance()
$MockSecurityDescriptor.DACL += $MockACE
$Global:MockDescriptor = [PSCustomObject]@{Descriptor = $MockSecurityDescriptor}
$MockSecurityDescriptorEmpty = ([WMIClass]"Win32_SecurityDescriptor").CreateInstance()
$Global:MockDescriptorEmpty = [PSCustomObject]@{Descriptor = $MockSecurityDescriptorEmpty}
$Global:MockAccount = [PSCustomObject]@{Name = $MockParameters.Principal; SID = $MockTrustee.SIDString}

InModuleScope -ModuleName  $DSCResourceName -ScriptBlock {

    Describe 'DSC_ServicePermission\Get-TargetResource' {
        $MockParameters = @{
            ServiceName   = 'MockService'
            Principal     = 'mock\Principal'
            AccessRights = 'QueryConfig'
        }
        Context 'Absent should return correctly' {
            $MockService = New-Module -AsCustomObject -ScriptBlock {
                function GetSecurityDescriptor {
                    $Global:MockDescriptorEmpty
                }
            }
            Mock -CommandName Get-WmiObject -MockWith {
                $MockService
            }
            Mock -CommandName Resolve-PrincipalToSID -MockWith {
                $Global:MockAccount
            }
            It 'should return Absent' {
                $Result = Get-TargetResource @MockParameters
                $Result.Ensure | Should Be 'Absent'
            }
        }
        Context 'Present should return correctly' {
            $MockService = New-Module -AsCustomObject -ScriptBlock {
                function GetSecurityDescriptor {
                    $Global:MockDescriptor
                }
            }
            Mock -CommandName Get-WmiObject -MockWith {
                $MockService
            }
            Mock -CommandName Resolve-PrincipalToSID -MockWith {
                $Global:MockAccount
            }
            It 'should return Present' {
                $Result = Get-TargetResource @MockParameters
                $Result.Ensure | Should Be 'Present'
            }
        }
    }
    Describe "how DSC_ServicePermissions\Test-TargetResource responds to Ensure = 'Absent'" {
        $MockParameters = @{
            ServiceName   = 'MockService'
            Principal     = 'mock\Principal'
            AccessRights = 'QueryConfig'
        }
        Context 'Record does not exist' {
            $MockService = New-Module -AsCustomObject -ScriptBlock {
                function GetSecurityDescriptor {
                    $Global:MockDescriptorEmpty
                }
            }
            Mock -CommandName Get-WmiObject -MockWith {
                $MockService
            }
            Mock -CommandName Resolve-PrincipalToSID -MockWith {
                $Global:MockAccount
            }
            It 'should return True' {
                $Result = Test-TargetResource -Ensure 'Absent' @MockParameters
                $Result | Should Be $true
            }
        }

        Context 'Record does exist' {
            $MockService = New-Module -AsCustomObject -ScriptBlock {
                function GetSecurityDescriptor {
                    $Global:MockDescriptor
                }
            }            
            Mock -CommandName Get-WmiObject -MockWith {
                $MockService
            }
            Mock -CommandName Resolve-PrincipalToSID -MockWith {
                $Global:MockAccount
            }
            It 'should return False' {
                $Result = Test-TargetResource -Ensure 'Absent' @MockParameters
                $Result | Should Be $false
            }
        }
    }
    Describe "how DSC_ServicePermissions\Test-TargetResource responds to Ensure = 'Present'" {
        $MockParameters = @{
            ServiceName   = 'MockService'
            Principal     = 'mock\Principal'
            AccessRights = 'QueryConfig'
        }
        Context 'Record does exist with the correct value' {
            $MockService = New-Module -AsCustomObject -ScriptBlock {
                function GetSecurityDescriptor {
                    $Global:MockDescriptor
                }
            }            
            Mock -CommandName Get-WmiObject -MockWith {
                $MockService
            }
            Mock -CommandName Resolve-PrincipalToSID -MockWith {
                $Global:MockAccount
            }
            It 'should return True' {
                $Result = Test-TargetResource -Ensure 'Present' @MockParameters
                $Result | Should Be $true
            }                            
        }
        Context 'Record does exist with the incorrect value' {
            $MockParameters = @{
                ServiceName   = 'MockService'
                Principal     = 'mock\Principal'
                AccessRights = 'QueryConfig, QueryStatus'
            }
            $MockService = New-Module -AsCustomObject -ScriptBlock {
                function GetSecurityDescriptor {
                    $Global:MockDescriptor
                }
            }  
            Mock -CommandName Get-WmiObject -MockWith {
                $MockService
            }
            Mock -CommandName Resolve-PrincipalToSID -MockWith {
                $Global:MockAccount
            }
            It 'should return false' {
                $Result = Test-TargetResource -Ensure 'Present' @MockParameters
                $Result | Should Be $false
            }                            
        }
        
        Context 'Record does not exist' {
            $MockParameters = @{
                ServiceName   = 'MockService'
                Principal     = 'mock\Principal'
                AccessRights = 'QueryConfig, QueryStatus'
            }
            $MockService = New-Module -AsCustomObject -ScriptBlock {
                function GetSecurityDescriptor {
                    $Global:MockDescriptorEmpty
                }
            }  
            Mock -CommandName Get-WmiObject -MockWith {
                $MockService
            }
            Mock -CommandName Resolve-PrincipalToSID -MockWith {
                $Global:MockAccount
            }
            It 'should return false' {
                $Result = Test-TargetResource -Ensure 'Present' @MockParameters
                $Result | Should Be $false
            }                            
        }
    }
    Describe "how DSC_ServicePermissions\Set-TargetResource responds to Ensure = 'Absent'" {
        Context 'Record does exist'{
            $MockParameters = @{
                ServiceName   = 'MockService'
                Principal     = 'mock\Principal'
                AccessRights = 'QueryConfig, QueryStatus'
            }
            $MockService = New-Module -AsCustomObject -ScriptBlock {
                function GetSecurityDescriptor {
                    $Global:MockDescriptor
                }
            }  
            Mock -CommandName Get-WmiObject -MockWith {
                $MockService
            }
            Mock -CommandName Resolve-PrincipalToSID -MockWith {
                $Global:MockAccount
            }
            Mock -CommandName Delete-SecurityDescriptorRecord
            It "should call expected mocks" {

                $Result = Set-TargetResource -Ensure 'Absent' @MockParameters
                Assert-MockCalled -CommandName Delete-SecurityDescriptorRecord -Exactly 1
    
            }
        }
    }
    Describe "how DSC_ServicePermissions\Set-TargetResource responds to Ensure = 'Present'" {
        $MockParameters = @{
            ServiceName   = 'MockService'
            Principal     = 'mock\Principal'
            AccessRights = 'QueryConfig, QueryStatus'
        }
        Context 'Record does not exist'{
            $MockService = New-Module -AsCustomObject -ScriptBlock {
                function GetSecurityDescriptor {
                    $Global:MockDescriptorEmpty
                }
            }  
            Mock -CommandName Get-WmiObject -MockWith {
                $MockService
            }
            Mock -CommandName Resolve-PrincipalToSID -MockWith {
                $Global:MockAccount
            }
            Mock -CommandName Create-SecurityDescriptorRecord
            It "should call expected mocks" {

                $Result = Set-TargetResource -Ensure 'Present' @MockParameters

                Assert-MockCalled Create-SecurityDescriptorRecord -Exactly 1          
            }            
        }

        Context 'Record does exist, but with incorrect value'{
            $MockService = New-Module -AsCustomObject -ScriptBlock {
                function GetSecurityDescriptor {
                    $Global:MockDescriptor
                }
            }  
            Mock -CommandName Get-WmiObject -MockWith {
                $MockService
            }
            Mock -CommandName Resolve-PrincipalToSID -MockWith {
                $Global:MockAccount
            }
            Mock -CommandName Modify-SecurityDescriptorRecord
            It "should call expected mocks" {

                $Result = Set-TargetResource -Ensure 'Present' @MockParameters

                Assert-MockCalled -CommandName Modify-SecurityDescriptorRecord -Exactly 1     
            }            
        }
    }
    Describe "DSC_ServicePermissions\Modify-SecurityDescriptorRecord" {
        Context 'Should call method and return 0'{
            $MockParameters = @{
                ServiceName   = 'MockService'
                Principal     = 'mock\Principal'
                AccessRights = 'QueryConfig, QueryStatus'
            }
            $MockService = New-Module -AsCustomObject -ScriptBlock {
                function GetSecurityDescriptor {
                    $Global:MockDescriptor
                }
                function SetSecurityDescriptor {
                    return 0
                }
            }  
            Mock -CommandName Get-WmiObject -MockWith {
                $MockService
            }
            Mock -CommandName Resolve-PrincipalToSID -MockWith {
                $Global:MockAccount
            }
            It "should return 0" {
                $Result = Modify-SecurityDescriptorRecord @MockParameters
                $Result | Should Be 0
            }
        }
    }
    Describe "DSC_ServicePermissions\Create-SecurityDescriptorRecord" {
        Context 'Should call method and return 0'{
            $MockParameters = @{
                ServiceName   = 'MockService'
                Principal     = 'mock\Principal'
                AccessRights = 'QueryConfig, QueryStatus'
            }
            $MockService = New-Module -AsCustomObject -ScriptBlock {
                function GetSecurityDescriptor {
                    $Global:MockDescriptorEmpty
                }
                function SetSecurityDescriptor {
                    return 0
                }
            }  
            Mock -CommandName Get-WmiObject -MockWith {
                $MockService
            }
            Mock -CommandName Resolve-PrincipalToSID -MockWith {
                $Global:MockAccount
            }
            It "should return 0" {
                $Result = Create-SecurityDescriptorRecord @MockParameters
                $Result | Should Be 0
            }
        }
    }
    Describe "DSC_ServicePermissions\Delete-SecurityDescriptorRecord" {
        Context 'Should call method and return 0'{
            $MockParameters = @{
                ServiceName   = 'MockService'
                Principal     = 'mock\Principal'
            }
            $MockService = New-Module -AsCustomObject -ScriptBlock {
                function GetSecurityDescriptor {
                    $Global:MockDescriptor
                }
                function SetSecurityDescriptor {
                    return 0
                }
            }  
            Mock -CommandName Get-WmiObject -MockWith {
                $MockService
            }
            Mock -CommandName Resolve-PrincipalToSID -MockWith {
                $Global:MockAccount
            }
            It "should return 0" {
                $Result = Delete-SecurityDescriptorRecord @MockParameters
                $Result | Should Be 0
            }
        }
    }
    Describe "DSC_ServicePermissions\Resolve-PrincipalToSID" {
        Context 'Should show right behavior'{
            $MockParameters = @{
                Principal     = 'BU'
            }
            It "should return right values" {
                $Result = Resolve-PrincipalToSID @MockParameters
                $Result.Name | Should Be 'BUILTIN\Users'
                $Result.SID | Should Be 'S-1-5-32-545'
            }
        }
    }
}

Remove-Item -Path $ModuleRoot -Recurse -Force