# cServicePermissions

The **cServicePermission** module contains a single DSC resource **cServicePermission**. 
And it's designed to update ACL on the Windows Service instance.

## Resources

### cServicePermission
- **ServiceName**: the name of the service on which ACL will be updated.
- **Principal**: Can accept account name in format **domain/user** or **user@domain.com**, SIDs, or well known Aliases as an input.
- **AccessRights**: Assigning the access rights separated by comma.
- **Ensure**: Ensures that the record is **Present** or **Absent**.

## List of available Aliases and Access Rights.

### Aliases.
- **AO** - Account operators
- **AN** - Anonymous logon
- **AU** - Authenticated users
- **BA** - Built-in administrators
- **BG** - Built-in guests
- **BO** - Backup operators
- **BU** - Built-in users
- **CA** - Certificate server administrators
- **CG** - Creator group
- **CO** - Creator owner
- **DA** - Domain administrators
- **DC** - Domain computers
- **DD** - Domain controllers
- **DG** - Domain guests
- **DU** - Domain users
- **EA** - Enterprise administrators
- **ED** - Enterprise domain controllers
- **WD** - Everyone
- **PA** - Group Policy administrators
- **IU** - Interactively logged-on user
- **LA** - Local administrator
- **LG** - Local guest
- **LS** - Local service account
- **SY** - Local system
- **NU** - Network logon user
- **NO** - Network configuration operators
- **NS** - Network service account
- **PO** - Printer operators
- **PS** - Personal self
- **PU** - Power users
- **RS** - RAS servers group
- **RD** - Terminal server users
- **RE** - Replicator
- **RC** - Restricted code
- **SA** - Schema administrators
- **SO** - Server operators
- **SU** - Service logon user

###Access Rights.
- **QueryConfig**
- **ChangeConfig**
- **QueryStatus**
- **EnumerateDependents**
- **Start**
- **Stop**
- **PauseContinue**
- **Interrogate**
- **UserDefinedControl**
- **Delete**
- **ReadControl**
- **WriteDac**
- **WriteOwner**
- **Synchronize**
- **AccessSystemSecurity**
- **GenericAll**
- **GenericExecute**
- **GenericWrite**
- **GenericRead**

## Versions
### 1.0
- Initial release with the following resources: 
- **cServicePermission**

# Examples

## Example 1

Granting **Start** and **Stop** permissions to **Brent** for **TeamViewer** Service at localhost.

```sh
configuration Demo
{
    Import-DscResource -Module cServicePermission
    Node localhost
    {
        cServicePermission Demo
        {
            servicename = 'teamviewer'
            Principal = 'contoso\Brent'
            Ensure = 'Present'
            AccessRights = 'Start, Stop'
        }
    }
}
```
## Example 2

Deleting a record that was created in **Example 1**.
```sh
configuration Demo
{
    Import-DscResource -Module cServicePermission
    Node localhost
    {
        cServicePermission Demo
        {
            servicename = 'teamviewer'
            Principal = 'contoso\Brent'
            Ensure = 'Absent'
        }
    }
}
```
## Example 3

Granting a banch of different access rights for different users for one specific service.
```sh
configuration Demo
{
    Import-DscResource -Module cServicePermission
    Node localhost
    {
        cServicePermission Demo1
        {
            servicename = 'TestService'
            Principal = 'PU'
            Ensure = 'Present'
            AccessRights = 'QueryConfig, QueryStatus, EnumerateDependents, Start, Stop, PauseContinue, Interrogate, UserDefinedControl, ReadControl'
        }
        cServicePermission Demo2
        {
            servicename = 'TestService'
            Principal = 'S-1-1-0'
            Ensure = 'Present'
            AccessRights = 'ReadControl'
        }
        cServicePermission Demo
        {
            servicename = 'TestService'
            Principal = 'contoso\GroupOfUsers'
            Ensure = 'Present'
            AccessRights = 'Start, Stop, PauseContinue, ReadControl'
        }
    }
}
```