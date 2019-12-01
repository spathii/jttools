Function Install-PowershellModules {

<#
.SYNOPSIS
This script will install the powershellmodules based on either a git repo, or from a zip file

.DESCRIPTION
Name: Install-PowershellModules
Author: jtatman 1/4/2019

.NOTES

TODO - 
    First pass
Updates
    11/8/2019 jtatman - Updates to standard format, pull down from gh if available.

.PARAMETER SourceFile
The zip file to use as a source
.PARAMETER InstallDirectory
The directory to install the powershell modules to


.EXAMPLE
Install-PowershellModules -SourceFile c:\temp\PowershellModules-master.zip -InstallDirectory c:\opt\bin\PowershellModules\

#>

[CmdletBinding()]
param (
    [Parameter(
        Position=0, 
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][String]$SourceFile,
    [Parameter(
        Position=1, 
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][String]$InstallDirectory = "c:\opt\bin\PowershellModules\",
    [Parameter(
        Position=2, 
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][PSCredential]$Credential
)

##################################################################################################
#Configurable Script Variables
##################################################################################################
$SourceFileUri = "https://gh.internal.shutterfly.com/shutterfly/PowershellModules/archive/master.zip"

#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#
#Output Object
#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#

$OutputObject = @{
    SourceFile = ""
    InstallDirectory = ""
    ExitCode = 0
    RunAsAdmin = $TRUE
    InputParameters = @{
        SourceFile = ""
        InstallDirectory = ""
    }
}


#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#
#Hard Coded Values
#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#

#!#!#!#!#
#Hard Coded Variables
#!#!#!#!#

$CallingScript = $MyInvocation.InvocationName
$InstanceID = (get-date -format yyyyMMdd-hhmmss).tostring()
$MessageType = "INFO"

#!#!#!#!#
#Hard Coded Functions
#!#!#!#!#

function FN_WL {
    Write-JTLog -InstanceID $InstanceID -message $Message
    Write-Verbose $Message
}

function FN_WL {
    #For local dev work
    #Write-JTLog -InstanceID $InstanceID -message $Message
    #Write-Host $Message

    #For module
    Write-JTLog -InstanceID $InstanceID -message $Message
    Write-Verbose $Message

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
    Write-ObjectOutput -ExecutionStatus $TRUE

    #Write script success
    $Message = "Internalfunction: $($MyInvocation.MyCommand); [$MessageType]; Script completed successfully" 
    FN_WL
    
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


#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#
#Common User defined functions
#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#

function Write-ObjectOutput {

    param ($ExecutionStatus,$ExecutionError)

    #This function will output an object to the user, which will typically be the standard output
    $Message = "Internalfunction: $($MyInvocation.MyCommand); [$MessageType]; Writing object output" 
    FN_WL
        
    $sObj = new-object PSObject

    #Standard outputs
    $sObj | add-member ExecutionStatus $ExecutionStatus
    $sObj | add-member ExecutionError $ExecutionError
    $sObj | add-member InputParameters $InputParameters


    #These are user configurable outputs
    $sObj | add-member ZipFile $ZipFile
    $sObj | add-member InstallDirectory $InstallDirectory
    $sObj | add-member envSetStatus $envSetStatus

    return $sObj  
}

function Set-Cleanup {

    #This is a standard function to cleanup any temporary files, or scrub sensitive data from output
    $Message = "Internalfunction: $($MyInvocation.MyCommand); [$MessageType]; Cleaning up script" 
    FN_WL

    #Do specific cleanup tasks
    #Cleanup X
    $Message = "Internalfunction: $($MyInvocation.MyCommand); [$MessageType]; Cleaning up X" 
    FN_WL

    #Cleanup Y
    $Message = "Internalfunction: $($MyInvocation.MyCommand); [$MessageType]; Cleaning up X" 
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

    #!#!#!#!#
    #Hard coded function calls, start coding in next section
    $InputParameters = Get-InputParameters
    #!#!#!#!#

    #########
    #Run various functions
    #########
    $Admin = Test-Admin
    $Zipfile = Test-Sourcefile
    $InstallDirectory = Build-InstallDirectory
    Extract-SourceFile
    $envSetStatus = Set-EnvironmentVariable
    
    #!#!#!#!#
    #Hard coded function calls, start coding in next section
    #Exit with success (standard exit)
    Exit-ScriptWithSuccess
    #!#!#!#!#

}


##########
#Script Functions
##########

function Test-Admin {
    #Log the start of the function
    $Message = "InternalFunction: $($MyInvocation.MyCommand); [$MessageType]; Starting function, looking to verify running with Admin permissions (for environment variable set)" 
    FN_WL


    #Test to make sure the user running script is an admin, otherwise setting environment variable will fail
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $checkcurrentPrincipal = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($checkcurrentPrincipal -eq $FALSE) {
        
        $MessageType = "ERROR"
        $Message = "InternalFunction: $($MyInvocation.MyCommand); [$MessageType]; Script not run with sufficient permissions" 
        FN_WL  

        Exit-ScriptWithError -ExecutionError "Script not run with sufficient permissions"
    }

    #Write source file to output object
    return $checkcurrentPrincipal
}


function Get-GHHeader {

    #Log the start of the function
    $Message = "InternalFunction: $($MyInvocation.MyCommand); [$MessageType]; Building auth header for potential GH Download" 
    FN_WL

    
    
    if (!$credential){
        $MessageType = "ERROR"
        $Message = "InternalFunction: $($MyInvocation.MyCommand); [$MessageType]; No credential available to log into gh" 
        FN_WL  

        Exit-ScriptWithError -ExecutionError "No credential provided"     
    }  

    #Convert secure credentials to plain text
    if ($credential.UserName -match "\\") {
        $user = $credential.username.split("\")[1]
    }
    else {
        $user = $credential.username
    }
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credential.password)
    $pw = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    $pair = "${user}:${pw}"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pair)
    $base64 = [System.Convert]::ToBase64String($bytes)
    $basicAuthValue = "Basic $base64"
    $headers = @{ Authorization = $basicAuthValue }
    return $headers
}


function Test-Sourcefile {
    #Log the start of the function
    $Message = "InternalFunction: $($MyInvocation.MyCommand); [$MessageType]; Starting function, looking for source file: $($SourceFile)" 
    FN_WL

    if (!$SourceFile) {

        $Message = "InternalFunction: $($MyInvocation.MyCommand); [$MessageType]; Source file could not be found, attempting to download from gh" 
        FN_WL  
        $Zipfile = $env:TEMP + "\Master.zip"
        
        $headers = Get-GHHeader
        $wr = Invoke-WebRequest  -Headers $headers -Uri $SourceFileUri -OutFile $ZipFile
        $SourceFile = $ZipFile
    }

    if (!(test-path $SourceFile)) {
        $MessageType = "ERROR"
        $Message = "InternalFunction: $($MyInvocation.MyCommand); [$MessageType]; Source file could not be found, exiting: $($SourceFile)" 
        FN_WL  
        
        $OutputObject.ExitCode = 1002

        Exit-ScriptWithError             
    }
    else {
        $ZipFile = $SourceFile
    }

    #Write source file to output object
    return $ZipFile
}

function Build-InstallDirectory {

    #Log the start of the function
    $Message = "InternalFunction: $($MyInvocation.MyCommand); [$MessageType]; Starting function" 
    FN_WL
    
    if (!(test-path $InstallDirectory)) {
        $Message = "InternalFunction: $($MyInvocation.MyCommand); [$MessageType]; Install Directory does not exist, creating: $($InstallDirectory)" 
        FN_WL          
        $mkdir = mkdir -force $InstallDirectory
        if ($mkdir.name) {
            $Message = "InternalFunction: $($MyInvocation.MyCommand); [$MessageType]; Directory now exists: $($InstallDirectory)"  
            FN_WL       
        }
        else {
            $MessageType = "ERROR"
            $Message = "InternalFunction: $($MyInvocation.MyCommand); [$MessageType]; Could not create directory, exiting: $($InstallDirectory)" 
            FN_WL  
            
            Exit-ScriptWithError "Could not build install directory"            
        }

    }

    else {
        $Message = "InternalFunction: $($MyInvocation.MyCommand); [$MessageType]; Install Directory already exists: $($InstallDirectory)" 
        FN_WL  
    }

    #Write install directory to output object
    Return $InstallDirectory 

}

function Extract-SourceFile {

    #Log the start of the function
    $Message = "InternalFunction: $($MyInvocation.MyCommand); [$MessageType]; Starting function" 
    FN_WL
    
    Try {
        $mkdirtemp = mkdir (Join-Path ([System.IO.Path]::GetTempPath()) ([System.IO.Path]::GetRandomFileName()))
        Expand-Archive -Path $ZipFile -OutputPath $mkdirtemp
        cp -force (join-path $mkdirtemp "PowershellModules-master\*") $InstallDirectory -exclude README.md
        rm $mkdirtemp -force -confirm:$FALSE -recurse
    }
    Catch {
        Write-Error $_.Exception 
        $MessageType = "ERROR"
        $Message = "InternalFunction: $($MyInvocation.MyCommand); [$MessageType]; Could not copy from source, exiting" 
        FN_WL  
        
        Exit-ScriptWithError "Could not extract zip file"
    }

}

function Set-EnvironmentVariable {
    
    #Log the start of the function
    $Message = "InternalFunction: $($MyInvocation.MyCommand); [$MessageType]; Starting function" 
    FN_WL

    $CurrentValue = [Environment]::GetEnvironmentVariable("PSModulePath", "Machine")
    if (!($CurrentValue -match [Regex]::Escape($InstallDirectory))) {
        Try {
            [Environment]::SetEnvironmentVariable("PSModulePath", $($CurrentValue + ";" + $InstallDirectory), "Machine")
            $envSetStatus = $TRUE
        }   
        Catch {
            Write-Error $_.Exception 
            $MessageType = "ERROR"
            $Message = "InternalFunction: $($MyInvocation.MyCommand); [$MessageType]; Could not set environment variable" 
            FN_WL  
        
            Exit-ScriptWithError "Could not set environment variable"

        } 
    }
    else {
        $Message = "InternalFunction: $($MyInvocation.MyCommand); [$MessageType]; Environment variable already set" 
        FN_WL  
        $envSetStatus = $FALSE

    }

    return $envSetStatus

}

##################################################################################################
#Execute Script Code
##################################################################################################

#Execute Main
#Log the start of the function
$Message = "Script: $($CallingScript); [$MessageType]; Starting Script" 
FN_WL
#!#!#!#!#

Do-Main

#Log the start of the function
$Message = "Script: $($CallingScript); [$MessageType]; Completing Script" 
FN_WL
#!#!#!#!#

}

#For local testing and development
#Copy-SFLYADGroup -SourceGroup sfly-enterprisestandardrole-cis-admin -DestinationGroup sfly-aws-infosec-dev-cis-admin

#For production module membership
Export-ModuleMember Install-PowershellModules