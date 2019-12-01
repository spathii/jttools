Function Get-JTScriptTemplate {

<#
.SYNOPSIS
An explanation of what the function does, inputs and outputs, in an outlined format.

--This script is a template, but will also attempt to self explain it's use.

.DESCRIPTION
Name: Get-JTFunctionTemplate
Author: jtatman 6/13/2016

.NOTES

TODO - NA
    First
Updates
    1/1/2010 - User - Explaination

.PARAMETER StringParameter
An input of a string
.PARAMETER InstanceID
The Instance of the job being run
.PARAMETER CallingScript
The script, or job that is writing to the log file
.PARAMETER Step
The name of the function, or the step in the script being run
.PARAMETER Status
The status of the job step
.PARAMETER User
The user the log function (and script) was written by


.EXAMPLE
Write-SFLYLog -LogFile "c:\log\Test-Script.log" -InstanceID 20160304.054557.Test-Script -CallingScript Test-Script -Step Test-Function -Status START -User ($env:USERNAME + "@" + $env:USERDNSDOMAIN)

#>

[CmdletBinding()]
param (
    [Parameter(
        Position=0, 
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][String]$StringParameter,
    [Parameter(
        Position=1, 
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][array]$ArrayParameter, 
    [Parameter(
        Position=2, 
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][String]$Credentials,
    [Parameter(
        Position=3, 
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)    
    ]$CallingScript,
    [Parameter(
        Position=4, 
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][bool]$bool
)

##################################################################################################
#Configurable Script Variables
##################################################################################################


#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#
#Output Object
#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#

$OutputObject = @{
    Parameter1 = ""
    Parameter2 = ""
    InputParameters = @{
        Parameter1 = ""
        Parameter2 = ""
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
    $MessageType = "TERMINATINGERROR"
    $Message = "Script: $CallingScript; $MessageType; Error Detected, exiting script" 
    FN_WL

    break
    
}

function Exit-ScriptSuccess {
    $MessageType = "INFO"
    $Message = "Script: $CallingScript; $MessageType; Script execution success, exiting script" 
    FN_WL

    return $OutputObject
    
    
}

function Get-InputParameters {

    $ParameterList = (Get-Command -Name $PSCmdlet.MyInvocation.InvocationName).Parameters;
    $ParameterList | ForEach-Object {
        $Params = Get-Variable -Name $_.Values.Name -ErrorAction SilentlyContinue;
        $Params | Foreach-Object {
            $Outputobject.$($_.Name) = $($_.Value)
            $Outputobject.InputParameters.$($_.Name) = $($_.Value)
        }
    }
}

##################################################################################################
#Script Code
##################################################################################################
##########
#Do Main - The main overall logic of the script
##########
function Do-Main {

    #!#!#!#!#
    #Hard Coded Execution
    #!#!#!#!#
    Get-InputParameters

    #########
    #Run various functions
    #########


    #########
    #Output and Exit
    #########

    #Exit
    #Exit-ScriptWithError
    Exit-ScriptSuccess

}


##########
#Script Functions
##########

function Example-Function {

    #Log the start of the function
    $Message = "InternalFunction: $($MyInvocation.MyCommand); [$MessageType]; Starting function" 
    FN_WL
    
    $Output = Call-Function $ExampleParameter

    #Prompt user for credentials if they were not input as part of the script  
    if (!($Output)) {
        $MessageType="ERROR"
        $Message = "InternalFunction: $($MyInvocation.MyCommand); [$MessageType]; Could not execute stuff: $($ExampleParameter)" 
        FN_WL  
        Exit-ScriptWithError
    }
    else {
        $Message = "InternalFunction: $($MyInvocation.MyCommand); [$MessageType]; Successfully executed stuff: $($ExampleParameter)"  
        FN_WL  
    }

    $MessageType = "INFO"

    return $Output
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
Copy-SFLYADGroup -SourceGroup sfly-enterprisestandardrole-cis-admin -DestinationGroup sfly-aws-infosec-dev-cis-admin

#For production module membership
#Export-ModuleMember Get-JTFunctionTemplate