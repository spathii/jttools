Function Get-JTCredentials {

<#
.SYNOPSIS
This script will output a secure credentials for AD related accounts, to be placed into an object in the running environment.  it can also be
used to output plaintext credentials

.DESCRIPTION
Name: Get-JTCredentials
Author: jtatman 12/01/2019

.NOTES

TODO
    12/1/2019 - jtatman - Complete script
Updates
    12/1/2019 - jtatman - Initial script write
    12/2/2019 - jtatman - Change output to be a hashtable

.PARAMETER DecryptionKey
The key used to decrypt the Keepass database
.PARAMETER KeepassFile
The instance of the keepass database as a file
.PARAMETER RootGroupName
The root group name
.PARAMETER GroupName
The child group name
.PARAMETER Filter
The filter to use for credentials to return
.PARAMETER Plaintext

.EXAMPLE
$Identities = Get-JTCredentials
Promt user for password, and use default configuration, and put into an object called identities.
THIS IS THE DEFAULT USE OF THE SCRIPT

.EXAMPLE
Get-JTCredentials -Decryptionkey 'this is a test' -KeepassFile "c:\temp\kp.kdbx" -RootGroupName "Shutterfly" -GroupName "Identity" -Filter "^AD"
With all paramaters, outputting to standard output

.EXAMPLE
Get-JTCredentials 
Promt user for password, and use default configuration
#>

[CmdletBinding()]
param (
    [Parameter(
        Position=0, 
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][String]$DecryptionKey,
    [Parameter(
        Position=1, 
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][String]$KeepassFile,
    [Parameter(
        Position=2, 
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][String]$RootGroupName = "Shutterfly",
    [Parameter(
        Position=3, 
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][String]$GroupName = "Identity",
    [Parameter(
        Position=4, 
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][String]$Filter = "^AD",
    [Parameter(
        Position=4, 
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][Switch]$Plaintext,
    [Parameter(
        Position=5, 
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][Switch]$Hashtable
)

##################################################################################################
#Configurable Script Variables
##################################################################################################

#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#
#Hard Coded Values
#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#
#!#!#!#!#
#Hard Coded Variables
#!#!#!#!#
$CallingScript = $MyInvocation.InvocationName
$InstanceID = (get-date -format yyyyMMdd-hhmmss).tostring()
$MessageType = "INFORMATIONAL"

#!#!#!#!#
#Hard Coded Common Functions
#!#!#!#!#

function FN_WL {
    Write-JTLog -InstanceID $InstanceID -message $Message
    Write-Verbose $Message
}


function Get-InputParameters {

    $ParameterList = (Get-Command -Name $PSCmdlet.MyInvocation.InvocationName).Parameters;
    $ParameterList | ForEach-Object {
        $Params = Get-Variable -Name $_.Values.Name -ErrorAction SilentlyContinue;
        $Params | Foreach-Object {
            #$Outputobject.InputParameters.$($_.Name) = $($_.Value)
        }

        $InputParameters = new-object PSObject
        $Params | % { 
            $InputParameters | Add-Member $_.name $_.value
        }

    }

    return $InputParameters
}


function Exit-ScriptWithError {
    
    param ($ExecutionError)

    write-error $ExecutionError

    Set-Cleanup
    #There is a bug where object output is not sent back to user
    Write-ObjectOutput -ExecutionStatus $FALSE -ExecutionError $ExecutionError


    #Write script error
    $MessageType = "TERMINATINGERROR"
    $Message = "Internalfunction: $($MyInvocation.MyCommand); [$MessageType]; Script exited with error" 
    FN_WL

    break
    
}

function Exit-ScriptWithSuccess {

    Set-Cleanup
    Write-ObjectOutput

    #Write script success
    $Message = "Internalfunction: $($MyInvocation.MyCommand); [$MessageType]; Script completed successfully" 
    FN_WL
    
}


#!#!#!#!#

#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#
#Common User defined functions
#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#

function Write-ObjectOutput {

    #$IDTable = @{}
    if ($Plaintext) {

    }
    elseif ($Hashtable) {
        $ht = @{}
        $Identities | ForEach-Object {
            $username = $_.username
            $secpasswd = ConvertTo-SecureString $_.password -AsPlainText -Force
            $mycreds = New-Object System.Management.Automation.PSCredential ($username, $secpasswd)  
            $ht[$_.title] = $mycreds         
        }
        $Identities = $ht
    }
    else {
        $IDs = $Identities | ForEach-Object {
            $SecCred = new-object PSObject
            $SecCred | Add-Member "Name" $_.title
            $username = $_.username
            $secpasswd = ConvertTo-SecureString $_.password -AsPlainText -Force
            $mycreds = New-Object System.Management.Automation.PSCredential ($username, $secpasswd)
            $SecCred | Add-member "Credential" $mycreds
            return $SecCred
            #$IDTable.$($_.title) = $mycreds
        }
        $identities = $IDs
        
    }

    #return $IDTable
    $Identities
}

function Set-Cleanup {

    #This is a standard function to cleanup any temporary files, or scrub sensitive data from output
    $Message = "Internalfunction: $($MyInvocation.MyCommand); [$MessageType]; Cleaning up script" 
    FN_WL
 
}
#!#!#!#!#

##################################################################################################
#Script Code
##################################################################################################
##########
#Do Main - The main overall logic of the script
##########
function Do-Main {

    #Run various functions
    $KeepassFile = Check-KeepassFile
    #Get the identities
    $Identities = Get-KeepassIdentities
    #Exit with success (standard exit)
    Exit-ScriptWithSuccess

}


##########
#Script Functions
##########

function Check-KeepassFile {
    #This is a standard function to cleanup any temporary files, or scrub sensitive data from output
    $Message = "Internalfunction: $($MyInvocation.MyCommand); [$MessageType]; Verifying existence of keepass file" 
    FN_WL

    if (!$KeepassFile) {
        if (test-path $env:KeepassFilePathJtatman) {
            $KeepassFile = $env:KeepassFilePathJtatman
        }
        else {
            Write-Error "KeepassFile parameter required"
            break
        }
    }
    return $KeepassFile

}

Function Get-KeepassIdentities {

    # Helper Function: Convert secure string back into plaintext
    Function Convert-FromSecureStringToPlaintext ( $SecureString )
    {
        [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString))
    }

    # Load the classes from KeePass.exe:
    $KeePassProgramFolder = Dir C:\'Program Files (x86)'\KeePass* | Select-Object -Last 1
    $KeePassEXE = Join-Path -Path $KeePassProgramFolder -ChildPath "KeePass.exe"
    [Reflection.Assembly]::LoadFile($KeePassEXE) | out-null


    # To open a KeePass database, the decryption key is required, Create the composite key
    $CompositeKey = New-Object -TypeName KeePassLib.Keys.CompositeKey #From KeePass.exe

    if (!$DecryptionKey) {
        $PasswordCT = Read-Host -Prompt "Enter Keepass Database Passphrase" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($PasswordCT)
        $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    } else {
        $Password = $DecryptionKey
    }

    $KcpPassword = New-Object -TypeName KeePassLib.Keys.KcpPassword($Password)

    $CompositeKey.AddUserKey( $KcpPassword )

    #Open the keepass database
    $IOConnectionInfo = New-Object KeePassLib.Serialization.IOConnectionInfo
    $IOConnectionInfo.Path = $KeepassFile
    $StatusLogger = New-Object KeePassLib.Interfaces.NullStatusLogger
    $PwDatabase = New-Object -TypeName KeePassLib.PwDatabase #From KeePass.exe
    $PwDatabase.Open($IOConnectionInfo, $CompositeKey, $StatusLogger)


    #List entries in the group name (user input)
    #$Group = $PwDatabase.RootGroup.Groups | where { $_.name -eq $RootGroupName } | where {$_.groups.name -eq $GroupName }
    $Group = ($PwDatabase.RootGroup.Groups | where { $_.name -eq $RootGroupName }).groups | where {$_.name -eq $GroupName }

    #Get the Password associated with the account
    $Identities = ($group.getentries($true)) | where {$_.Strings.ReadSafe("Title") -match "AD"} | % {
        $Title = New-Object PSObject
        $title | add-member Title $_.Strings.ReadSafe("Title")
        $title | add-member UserName $_.Strings.ReadSafe("UserName")
        $title | add-member Password $_.Strings.ReadSafe("Password")
        return $title
        }

    #Close the open database.
    $PwDatabase.Close()

    #Return password back to user
    return $Identities
}

##################################################################################################
#Execute Script Code
##################################################################################################

#Execute Main
#Log the start of the function
$Message = "Starting script" 
FN_WL
#!#!#!#!#

Do-Main

#Log the start of the function
$Message = "Completing script" 
FN_WL
#!#!#!#!#

}

Export-ModuleMember Get-JTCredentials
