Function <FUNCTIONNAME> {

<#
.SYNOPSIS
An explanation of what the script does, inputs and outputs, in an outlined format.

--This script is a template, but will also attempt to self explain it's use.

.DESCRIPTION
Name: <FUNCTIONNAME>
Author: <AUTHOR> <DATE>

.NOTES

TODO - NA
    1/1/2010 - User - Explaination
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
.PARAMETER Switch
A parameter, where if it is set, can do something


.EXAMPLE
<FUNCTIONNAME> <PARAMS>

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
    ][bool]$bool,
    [Parameter(
        Position=5, 
        Mandatory=$false)
    ][switch]$switch
)

##################################################################################################
#Configurable Script Variables
##################################################################################################
$GV_Variable1 = $NULL

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
    Write-ObjectOutput -ExecutionStatus $TRUE

    #Write script success
    $Message = "Internalfunction: $($MyInvocation.MyCommand); [$MessageType]; Script completed successfully" 
    FN_WL
    
}


#!#!#!#!#

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
    $sObj | add-member Example $Example

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

    #Run various functions


    #Exit with success (standard exit)
    Exit-ScriptWithSuccess

}


##########
#Script Functions
##########

function Some-Function {
    param ($someVariable)

    #Log start of function
    $Message = "Internalfunction: $($MyInvocation.MyCommand); [$MessageType]; Starting function to do stuff" 
    FN_WL

    #Example call to an external function
    $Message = "ExternalFunction: NAMEOFEXTERNALFUNCTION PARAMS OF EXTERNALFUNCTION" 
    FN_WL

    #Example of exiting script with error
    if ($a -ne 1) {
        Exit-ScriptWithError -ExecutionError "Could not find module: $ModuleName"
    }

}

##################################################################################################
#Execute Script Code
##################################################################################################

#Execute Main
#Log the start of the function
$Message = "Starting script: $CallingScript - Command: $($MyInvocation.line)" 
FN_WL
#!#!#!#!#

Do-Main

#Log the start of the function
$Message = "Completing script: $CallingScript - Command: $($MyInvocation.line)" 
FN_WL
#!#!#!#!#

}

Export-ModuleMember <FUNCTIONNAME>