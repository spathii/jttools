Function New-JTFunction {

<#
.SYNOPSIS
This function will create a new function within a specified module, using a common template.

.DESCRIPTION
Name: New-JTFunction
Author: jtatman 10/30/2019

.NOTES

TODO - NA
    First
Updates
    1/1/2010 - User - Explaination

.PARAMETER FunctionName
An input of a string
.PARAMETER ModuleName
The Instance of the job being run

.EXAMPLE
New-JTFunction -FunctionName Connect-RDP -ModuleName JTTools
#>

[CmdletBinding()]
param (
    [Parameter(
        Position=0, 
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][String]$FunctionName,
    [Parameter(
        Position=0, 
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][String]$ModuleName 
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
    $sObj | add-member FunctionName $FunctionName
    $sObj | add-member ModuleName $ModuleName
    $sObj | add-member NewFunctionFile $NewFunctionFile
    $sObj | add-member ExecutionStatus $ExecutionStatus
    $sObj | add-member ExecutionError $ExecutionError

    return $sObj  

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
    $ModuleInfo =  Get-ModuleInfo
    Test-ExistingFunction
    $newFunctionFile = Copy-FromTemplate
    Add-FunctionToModule

    #Exit with success (standard exit)
    Exit-ScriptWithSuccess

}


##########
#Script Functions
##########

function Get-ModuleInfo {

    #Log start of function
    $Message = "Internalfunction: $($MyInvocation.MyCommand); [$MessageType]; Starting function to gather module information" 
    FN_WL

    #This will assume module is relative to the JTTools module (../)
    $moduleInfo = get-module $ModuleName -ListAvailable

    #Example of exiting script with error
    if (!($moduleInfo)) {
        Exit-ScriptWithError -ExecutionError "Could not find module: $ModuleName"
        #break
    }

    return $moduleInfo[0]
}

function Test-ExistingFunction {

    #Log start of function
    $Message = "Internalfunction: $($MyInvocation.MyCommand); [$MessageType]; Testing to verify function does not already exist" 
    FN_WL

    #Example of exiting script with error
    if ((get-command -module $ModuleName).name -contains $FunctionName) {
        Exit-ScriptWithError -ExecutionError "Function already existing Function: $FunctionName Module: $ModuleName"
        #break
    }

}

function Copy-FromTemplate {

    #Log start of function
    $Message = "Internalfunction: $($MyInvocation.MyCommand); [$MessageType]; Copying Template file" 
    FN_WL

    $templateFile = ((get-module jttools -listavailable)[0].modulebase +"\templates\FUNCTION.psm1")
    $newFunctionFile = ((get-module $ModuleName -listavailable)[0].modulebase +"\$($FunctionName).psm1")

    #Copy the template into the new file
    copy-item $TemplateFile $newFunctionFile -force

    $newFileContents = get-content $newFunctionFile
    #Replace instances of function name
    $newFileContents = $newFileContents.replace('<FUNCTIONNAME>', $FunctionName)    
    #Replace instances of author 
    $newFileContents = $newFileContents.replace('<AUTHOR>', ((ls env:\USERNAME).value))
    #Replace instances of date
    $newFileContents = $newFileContents.replace('<DATE>', (Get-Date -Format "MM/dd/yyyy"))

    #Write back to new file
    $newFileContents | Set-Content $newFunctionFile

    return $newFunctionFile


}

function Add-FunctionToModule {

    #Log start of function
    $Message = "Internalfunction: $($MyInvocation.MyCommand); [$MessageType]; Adding function to module" 
    FN_WL

    $psdFile = (get-module $ModuleName -listavailable)[0].path
    $psdFileContents = get-content $psdFile

    $psdFileContentscLineNum = ($psdFileContents | Select-String "# Functions to export from this module").linenumber - 3
    $psdFileContents = $psdFileContents.replace($psdFileContents[$psdFileContentscLineNum],($psdFileContents[$psdFileContentscLineNum] + ", ```n`t`t`t`t`'$functionname" + ".psm1`'"))
    $psdFileContents | set-content $psdFile

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

Export-ModuleMember New-JTFunction