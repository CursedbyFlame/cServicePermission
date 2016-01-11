#
#Creating a Test-TargetResource for DSCResource.
#

function Test-TargetResource {
    param (
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceName,

        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Principal,

        [ValidateSet('Present','Absent')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Ensure = 'Present',

        [String[]]
        $AccessRights = @()
    )
    Create-Type
    #Building an accessmask.
    $AccessMask = $AccessRights -as [ServiceAccessFlags]
    $Account = Resolve-PrincipalToSID -Principal $Principal
    try
    {
        $Service = Get-WmiObject Win32_Service -Filter "name = `'$ServiceName`'"
        if ($ServiceName -ne "MockService")
        {
            $Service.PSBase.Scope.Options.EnablePrivileges = $true
        }
        $SecurityDescriptor = ($service.GetSecurityDescriptor()).descriptor
        $RecordExist = $false
        Write-Verbose "Checking for record existment."
        #Check if recordexist and if it has right accessmask.
        for ($i=0; $i -lt $SecurityDescriptor.DACL.Length; $i++)
        {
            if ($SecurityDescriptor.DACL[$i].Trustee.SIDString -eq $Account.SID)
            {
                $RecordExist = $true
                Write-Verbose "Checking for the right value in the record."
                $NumberInArray = $i
            }
        }
        #Main
        if ($Ensure -eq 'Present')
        {
            if ($RecordExist)
            {
                if ($SecurityDescriptor.DACL[$NumberInArray].AccessMask -eq [int64]$AccessMask)
                {
                    Write-Verbose "Record exists with the correct value. Nothing to configure."
                    return $true
                }
                else
                {
                    Write-Verbose "Record exists with incorrect value. Needs to be modified."
                    return $false
                }
            }
            else
            {
                Write-Verbose "Record does not exists, but it should. Must be created."
                return $false
            }
        }
        else
        {
            if ($RecordExist)
            {
                Write-Verbose "Record exists, but it should not. It will be deleted."
                return $false
            }
            else
            {
                Write-Verbose "Record does not exists and it should not. Nothing to configure."
                return $true
            }
         }
    }
    catch
    {
        $exception = $_
        Write-Verbose "Error occurred while executing Test-TargetResource function"
        while ($exception.InnerException -ne $null)
        {
            $exception = $exception.InnerException
            Write-Verbose $exception.Message
        }
    }
}

#
#Creating a Set-TargetResource for DSCResource.
#

function Set-TargetResource {
    param (
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceName,

        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Principal,

        [ValidateSet('Present','Absent')]
        [ValidateNotNullOrEmpty()]
        [string]
        $Ensure = 'Present',

        [String[]]
        $AccessRights = @()
    )
    Create-Type
    #Building an accessmask.
    $AccessMask = $AccessRights -as [ServiceAccessFlags]
    $Account = Resolve-PrincipalToSID -Principal $Principal
    $DomainAndPrincipal = $Account.Name.Split('\')
    try
    {
        $Service = Get-WmiObject Win32_Service -Filter "name = `'$ServiceName`'"
        if ($ServiceName -ne "MockService")
        {
            $Service.PSBase.Scope.Options.EnablePrivileges = $true
        }
        $SecurityDescriptor = ($Service.GetSecurityDescriptor()).Descriptor
        if ($Ensure -eq 'Present')
        {
            $RecordExist = $false
            #Check if record for account is exist.
            for ($i=0; $i -lt $SecurityDescriptor.DACL.Length; $i++)
            {
                if ($SecurityDescriptor.DACL[$i].Trustee.SIDString -eq $Account.SID)
                {
                    $RecordExist = $true
                    $NumberInArray = $i
                }
            }
            #If it exist then modify, if it is not - create.
            if ($RecordExist)
            {
                Write-Verbose "Attempting to modify ACE in DACL of $ServiceName for $Principal"
                $ModifyResults = Modify-SecurityDescriptorRecord -ServiceName  $ServiceName `
                                                                 -AccessRights $AccessRights `
                                                                 -Principal    $Principal
                if ($ModifyResults.ReturnValue -eq 0)
                {
                    Write-Verbose "Record has been modified successfully."
                }
                else
                {
                    Write-Verbose "Record has not been modified. An error occured."
                }
            }
            else
            {
                Write-Verbose "Attempting to create ACE in DACL of $ServiceName for $Principal"
                $CreateResult = Create-SecurityDescriptorRecord -ServiceName  $ServiceName `
                                                                -AccessRights $AccessRights `
                                                                -Principal    $Principal
                if ($CreateResult.ReturnValue -eq 0)
                {
                    Write-Verbose "Record has been created successfully."
                }
                else
                {
                    Write-Verbose "Record has not been created. An error occured."
                }
            }
        }
        else
        {
            Write-Verbose "Attempting to delete ACE in DACL of $ServiceName for $Principal"
            $DeleteResult = Delete-SecurityDescriptorRecord -ServiceName $ServiceName `
                                                            -Principal   $Principal
            if ($DeleteResult.ReturnValue -eq 0)
            {
                Write-Verbose "Record has been deleted successfully."
            }
            else
            {
                Write-Verbose "Record has not been deleted. An error occured."
            }
        }
    }
    catch 
    {
        $exception = $_
        Write-Verbose "An error occurred while running Set-TargetResource function"
        while ($exception.InnerException -ne $null)
        {
            $exception = $exception.InnerException
            Write-Verbose $exception.message
        }
    }
}

#
#Creating a Get-TargetResource for DSCResource.
#

function Get-TargetResource {
    [OutputType([Hashtable])]
    param (
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceName,

        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Principal,

        [String[]]
        $AccessRights = @()
    )
    Create-Type
    $Configuration = @{
        ServiceName = $ServiceName
        }
    try
    {    
        $Service = Get-WmiObject Win32_Service -Filter "name = `'$ServiceName`'"
        if ($ServiceName -ne "MockService")
        {
            $Service.PSBase.Scope.Options.EnablePrivileges = $true
        }
        $SecurityDescriptor = ($Service.GetSecurityDescriptor()).descriptor
        $RecordExist = $false
        $Account = Resolve-PrincipalToSID -Principal $Principal
        Write-Verbose "Checking for record existment."
        for ($i=0; $i -lt $SecurityDescriptor.DACL.Length; $i++)
        {
            if ($SecurityDescriptor.dacl[$i].trustee.SIDString -eq $Account.SID)
            {
                $RecordExist = $true
                $NumberInArray = $i
            }
        }
        if ($RecordExist)
        {
            Write-Verbose "ACE record in DACL of $ServiceName for $Principal exists."
            $Configuration.Add('Ensure','Present')
            $EffectiveAccessRights = $SecurityDescriptor.DACL[$NumberInArray].AccessMask -as [ServiceAccessFlags]
            [string[]]$StringAccessRights = $EffectiveAccessRights.ToString() -replace '/s' -split ', '
            $Configuration.Add('AccessRights',$StringAccessRights)
            $Configuration.Add('Principal',($Account.Name))
        }
        else
        {
            Write-Verbose "ACE record in DACL of $ServiceName for $Principal does not exists."
            $Configuration.Add('Ensure','Absent')
            $Configuration.Add('Principal',($Account.Name))
        }
        return $Configuration
    }
    catch
    {
        $exception = $_
        Write-Verbose "Error occurred while running Get-TargetResource function"
        while ($exception.InnerException -ne $null)
        {
            $exception = $exception.InnerException
            Write-Verbose $exception.message
        }
    }
}


Export-ModuleMember -Function *-TargetResource

#region Helper Functions

function Modify-SecurityDescriptorRecord {
    <#
    .SYNOPSIS
        Modifies an Security Descriptor on specified service.
    .DESCRIPTION
        The Modify-SecurityDescriptorRecord get's the Security Descriptor on a Service Win32_Class,
        and modify it with a new value.
    .PARAMETER ServiceName
        Specifies the name of the service.
    .PARAMETER Principal
        Specifies the identity of the principal.
    .PARAMETER AccessRights
        Specifies the access rights to be granted to principal.
    #>
    param (
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceName,

        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Principal,

        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $AccessRights = @()
    )
    Create-Type
    $AccessMask = $AccessRights -as [ServiceAccessFlags]
    $Account = Resolve-PrincipalToSID -Principal $Principal 
    #creating temporary SecurityDescriptor                
    $Service = Get-WmiObject Win32_Service -Filter "name = `'$ServiceName`'"
    if ($ServiceName -ne "MockService")
    {
        $Service.PSBase.Scope.Options.EnablePrivileges = $true
    }
    $SecurityDescriptor = ($Service.GetSecurityDescriptor()).Descriptor       
    $TemporarySecurityDescriptor = ([WMIClass]"Win32_SecurityDescriptor").CreateInstance()
    $DomainAndPrincipal = $Account.Name.Split('\')
    for ($i=0; $i -lt $SecurityDescriptor.DACL.Length; $i++)
    {
        if ($SecurityDescriptor.DACL[$i].Trustee.SIDString -eq $Account.SID)
        {
            $NumberInArray = $i
        }
    }
    for ($i=0; $i -lt $SecurityDescriptor.DACL.Length; $i++)
    {
        if ($i -ne $NumberInArray)
        {
            #Puting all records that should not be modified in temporary SD.
            $TemporarySecurityDescriptor.DACL += $SecurityDescriptor.DACL[$i]
        }
        else
        {
            #Creating new ACE for the record.
            $ACERecord = ([WMIClass]"Win32_ACE").CreateInstance()
            #Transfer all values from the old one.
            $ACERecord = $SecurityDescriptor.DACL[$NumberInArray]
            #Assigning new accessmask.
            $ACERecord.AccessMask = $AccessMask
            #Adding ACE to DACL of temporary SD.
            $TemporarySecurityDescriptor.DACL += $ACERecord
        }
    }
    #Assigning modified DACL to the SD.
    $SecurityDescriptor.DACL = $TemporarySecurityDescriptor.DACL
    $Service.SetSecurityDescriptor($SecurityDescriptor)
}

function Create-SecurityDescriptorRecord {
    <#
    .SYNOPSIS
        Creates an record in a Security Descriptor on specified service.
    .DESCRIPTION
        The Create-SecurityDescriptorRecord get's the Security Descriptor on a Service Win32_Class,
        and create a new ACE record.
    .PARAMETER ServiceName
        Specifies the name of the service.
    .PARAMETER Principal
        Specifies the identity of the principal.
    .PARAMETER AccessRights
        Specifies the access rights to be granted to principal.
    #>
    param (
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceName,

        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Principal,

        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String[]]
        $AccessRights = @()
    )
    
    Create-Type
    $AccessMask = $AccessRights -as [ServiceAccessFlags]
    $Account = Resolve-PrincipalToSID -Principal $Principal
    #creating temporary SecurityDescriptor                
    $Service = Get-WmiObject Win32_Service -Filter "name = `'$ServiceName`'"
    if ($ServiceName -ne "MockService")
    {
        $Service.PSBase.Scope.Options.EnablePrivileges = $true
    }
    $SecurityDescriptor = ($Service.GetSecurityDescriptor()).descriptor
    $DomainAndPrincipal = $Account.Name.Split('\')
    #assigning originate dacl to a temporary variable.
    $TemporaryDACL = $SecurityDescriptor.dacl
    #creating new ACE and Trustee instances.
    $ACERecord = ([WMIClass]"Win32_ACE").CreateInstance()
    $Trustee = ([WMIClass]"Win32_Trustee").CreateInstance()
    #Configuring Trustee with the information needed.
    $Trustee.Domain = $DomainAndPrincipal[0]
    $Trustee.Name = $DomainAndPrincipal[1]
    $Trustee.SIDString = $Account.SID
    #Adding necessary information to the ACE record.
    $ACERecord.Trustee = $Trustee
    $ACERecord.AccessMask = $AccessMask
    $ACERecord.AceType = 0
    $ACERecord.AceFlags = 0
    #Assigning new entry to the temporary DACL.
    $TemporaryDACL += $ACERecord
    #Substitute originate DACL with the modified one.
    $SecurityDescriptor.DACL = $TemporaryDACL
    $SecurityDescriptor.ControlFlags = 40980
    $Service.SetSecurityDescriptor($SecurityDescriptor)
}

function Delete-SecurityDescriptorRecord {
    <#
    .SYNOPSIS
        Deletes an record in a Security Descriptor on specified service.
    .DESCRIPTION
        The Delete-SecurityDescriptorRecord get's the Security Descriptor on a Service Win32_Class,
        and delete a ACE record for specified Principal.
    .PARAMETER ServiceName
        Specifies the name of the service.
    .PARAMETER Principal
        Specifies the identity of the principal.
    #>
    param (
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $ServiceName,

        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Principal
    ) 
    $Service = Get-WmiObject Win32_Service -Filter "name = `'$ServiceName`'"
    if ($ServiceName -ne "MockService")
    {
        $Service.PSBase.Scope.Options.EnablePrivileges = $true
    }
    $SecurityDescriptor = ($Service.GetSecurityDescriptor()).descriptor
    $Account = Resolve-PrincipalToSID -Principal $Principal
    #Finding a record number of record in DACL array.
    for ($i=0; $i -lt $SecurityDescriptor.DACL.Length; $i++)
    {
        if ($SecurityDescriptor.DACL[$i].Trustee.SIDString -eq $Account.SID)
        {
            $NumberInArray = $i
        }
    }
    #Creating temporary SD to hold DACL.
    $TemporarySecurityDescriptor = ([WMIClass]"Win32_SecurityDescriptor").CreateInstance()
    #Adding all records exept the one that we should delete to the temporary SD.
    for ($i=0; ($i -lt $SecurityDescriptor.DACL.Length) -and ($i -ne $NumberInArray); $i++)
    {
        $TemporarySecurityDescriptor.DACL += $SecurityDescriptor.DACL[$i]
    }
    #Substitute originate DACL with the temporary one.
    $SecurityDescriptor.DACL = $TemporarySecurityDescriptor.DACL
    $Service.SetSecurityDescriptor($SecurityDescriptor)
}

function Create-Type {

    try
    {
        [ServiceAccessFlags] | Out-Null
    }
    catch
    {
    Add-Type @"
    [System.FlagsAttribute]
    public enum ServiceAccessFlags : uint
    {
        QueryConfig = 1,
        ChangeConfig = 2,
        QueryStatus = 4,
        EnumerateDependents = 8,
        Start = 16,
        Stop = 32,
        PauseContinue = 64,
        Interrogate = 128,
        UserDefinedControl = 256,
        Delete = 65536,
        ReadControl = 131072,
        WriteDac = 262144,
        WriteOwner = 524288,
        Synchronize = 1048576,
        AccessSystemSecurity = 16777216,
        GenericAll = 268435456,
        GenericExecute = 536870912,
        GenericWrite = 1073741824,
        GenericRead = 2147483648
    }
"@
    }
}

function Resolve-PrincipalToSID {
    <#
    .SYNOPSIS
        Resolves Principal name to SID and vice versa.
    .DESCRIPTION
        The Resolve-PrincipalToSID get's the account name, SID or well-known alliases as an input,
        and return name and SID.
    .PARAMETER Principal
        Specifies the identity of the principal.
    #>
    param (
        [parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Principal
    )
    try
    {
    [System.Security.Principal.SecurityIdentifier]$Identity = "$Principal"
    $SID = $Identity.Translate([System.Security.Principal.SecurityIdentifier])
    $NTAccount = $SID.Translate([System.Security.Principal.NTAccount])
    
    $OutputObject = [PSCustomObject]@{Name = $NTAccount.Value; SID = $SID.Value}

    return $OutputObject
    }
    catch
    {
        if ($Principal -match '^S-\d-(\d+-){1,14}\d+$')
        {
            [System.Security.Principal.SecurityIdentifier]$Identity = $Principal
        }
        else
        {
            [System.Security.Principal.NTAccount]$Identity = $Principal
        }
    $SID = $Identity.Translate([System.Security.Principal.SecurityIdentifier])
    $NTAccount = $SID.Translate([System.Security.Principal.NTAccount])
    
    $OutputObject = [PSCustomObject]@{Name = $NTAccount.Value; SID = $SID.Value}

    return $OutputObject
    }
}

#end region