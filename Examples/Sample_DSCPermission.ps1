configuration Sample_DSCPermission
{
    Import-DscResource -Module cServicePermission
    Node localhost
    {
        #Grants a banch of rights for TestService to a Power Users.
        cServicePermission Demo1
        {
            servicename = 'TestService'
            Principal = 'PU'
            Ensure = 'Present'
            AccessRights = 'QueryConfig, QueryStatus, EnumerateDependents, Start, Stop, PauseContinue, Interrogate, UserDefinedControl, ReadControl'
        }
        #Grants a ReadControl right for TestService to Everyone.
        cServicePermission Demo2
        {
            servicename = 'TestService'
            Principal = 'S-1-1-0'
            Ensure = 'Present'
            AccessRights = 'ReadControl'
        }
        #Grants a banch of rights to restart, pause and continue, and Read Control for TestService to AD Group.
        cServicePermission Demo3
        {
            servicename = 'TestService'
            Principal = 'contoso\GroupOfUsers'
            Ensure = 'Present'
            AccessRights = 'Start, Stop, PauseContinue, ReadControl'
        }
        #Revokes all existing rights for TestService for specific user.
        cServicePermission Demo4
        {
            servicename = 'TestService'
            Principal = 'contoso\Brent'
            Ensure = 'Absent'
            #AccessRights field is not effect anything if it used with the Ensure Absent.
            AccessRights = 'Start, Stop, PauseContinue, ReadControl'
        }
    }
}

Sample_DSCPermission -OutputPath "$Env:SystemDrive\Sample_DSCPermission"

Start-DscConfiguration -Path "$Env:SystemDrive\Sample_DSCPermission" -Force -Verbose -Wait

Get-DscConfiguration