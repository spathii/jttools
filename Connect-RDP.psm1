Function Connect-RDP {

<#
.SYNOPSIS
This script will allow the mstsc app to be launched with the appropriate settings

.DESCRIPTION
Name: Connect-RDP
Author: jtatman 10/30/2019

.NOTES

TODO - NA
    First
Updates
    1/1/2010 - User - Explaination

.PARAMETER user
The user to connect as
.PARAMETER computer
The computer to connect to
.PARAMETER rdp
Whether to use the RDG server 


.EXAMPLE
Connect-RDP wintools
Will use all the defaults, and connect to wintools

Connect-RDP -computer wintools -user jason.tatman
Will connect, but use the jason.tatman (admin) account

Connect-RDP -computer maple -user spathii -nordg
Will connect to a local computer off the mailfly domain, and not use RDG

Connect-RDP -computer wintools -nordgmatchcredentials
Will connect, but will prompt for seperate credentials for the RDG and destination server

Connect-RDP -computer wintools -audio
Will connect audio back to local computer

Connect-RDP -computer wintools -size full
Will connect with full screen

Connect-RDP -computer wintools -size all
Will connect with all monitors
#>

[CmdletBinding()]
param (
    [Parameter(
        Position=0, 
        Mandatory=$true, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][String]$computer,
    [Parameter(
        Position=1, 
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][String]$user,
    [Parameter(
        Position=2, 
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][ValidateSet('small','medium','large','full','all')
    ][String]$size = "large",
    [Parameter(
        Position=3, 
        Mandatory=$false)
    ][switch]$nordg,
    [Parameter(
        Position=4, 
        Mandatory=$false)
    ][switch]$nordgmatchcredentials,
    [Parameter(
        Position=5, 
        Mandatory=$false)
    ][switch]$audio
)

##################################################################################################
#Configurable Script Variables
##################################################################################################
$rdgServer = "rdg.corp.shutterfly.com"

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

    #Standard outputs
    $sObj | add-member ExecutionStatus $ExecutionStatus
    $sObj | add-member ExecutionError $ExecutionError

    return $sObj  
}

function Set-Cleanup {

    #This is a standard function to cleanup any temporary files, or scrub sensitive data from output
    $Message = "Internalfunction: $($MyInvocation.MyCommand); [$MessageType]; Cleaning up script" 
    FN_WL

    #Do specific cleanup tasks
 
}
#!#!#!#!#

##################################################################################################
#Script Code
##################################################################################################
##########
#Do Main - The main overall logic of the script
##########
function Do-Main {

    #Build the config file based on user input
    $RDPConfigFile = Get-RDPConfig

    #Connect based on config file
    Connect-Computer

    #Exit with success (standard exit)
    Exit-ScriptWithSuccess

}

##########
#RDG File Defaults
##########
$RDPConfig = @"

smart sizing:i:1
session bpp:i:32
winposstr:s:0,1,-7,1,1769,1040
compression:i:1
keyboardhook:i:2
audiocapturemode:i:0
videoplaybackmode:i:1
connection type:i:7
networkautodetect:i:1
bandwidthautodetect:i:1
displayconnectionbar:i:1
enableworkspacereconnect:i:0
disable wallpaper:i:0
allow font smoothing:i:0
allow desktop composition:i:0
disable full window drag:i:1
disable menu anims:i:1
disable themes:i:0
disable cursor setting:i:0
bitmapcachepersistenable:i:1
full address:s:
redirectprinters:i:0
redirectcomports:i:0
redirectsmartcards:i:0
redirectclipboard:i:1
redirectposdevices:i:0
autoreconnection enabled:i:1
authentication level:i:2
prompt for credentials:i:0
negotiate security layer:i:1
remoteapplicationmode:i:0
alternate shell:s:powershell
shell working directory:s:
gatewaybrokeringtype:i:0
use redirection server name:i:0
rdgiskdcproxy:i:0
kdcproxyname:s:
drivestoredirect:s:C:\;
"@

##########
#Script Functions
##########

function Get-RDPConfig {
    #Check for what computer to connect to
    $RDPConfig += "`nalternate full address:s:$Computer"

    #Check for which user (use local user if none specified)
    if ($user) {
        $username = $user
    }
    else {
        $username = $env:username + "@" + $env:USERDNSDOMAIN
    }
    $RDPConfig += "`nusername:s:$username"

    #Check for the size
    Switch ($size) {
        "small" {$RDPConfig += "`ndesktopwidth:i:924`ndesktopheight:i:668"}
        "medium" {$RDPConfig += "`ndesktopwidth:i:1180`ndesktopheight:i:924"}
        "large" {$RDPConfig += "`ndesktopwidth:i:1820`ndesktopheight:i:980"}
        "full" {$RDPConfig += "`ndesktopwidth:i:1900`ndesktopheight:i:1080"; $FS = $TRUE}
        "all" {$multimonswitch = $TRUE}
    }
    #Check to see if it should connect as full screen mode
    if ($FS -eq $TRUE) {
       $RDPConfig += "`nscreen mode id:i:0"
    }
    else {
       $RDPConfig += "`nscreen mode id:i:1"
    }

    #Set multimon flag if all was set in size
    if ($multimonswitch) {
        $RDPConfig += "`nuse multimon:i:1"  
    }
    else {
        $RDPConfig += "`nuse multimon:i:0"  
    }

    #Check to see if rdg should be used
    if ($nordg) {
        $RDPConfig += "`ngatewayprofileusagemethod:i:1`ngatewaycredentialssource:i:0`ngatewayusagemethod:i:1"
    }
    else {
        $RDPConfig += "`ngatewayprofileusagemethod:i:1`ngatewaycredentialssource:i:0`ngatewayusagemethod:i:1`ngatewayhostname:s:$rdgServer"
        
        #Check to see if the same credentials should be used with rdg
        if ($nordgmatchcredentials) {
            $RDPConfig += "`npromptcredentialonce:i:0"
        }
        else {
            $RDPConfig += "`npromptcredentialonce:i:1"
        }
    }

    #Check to see if audio is enabled
    if ($audio) {
        $RDPConfig += "`naudiomode:i:1"
    }
    else {
        $RDPConfig += "`naudiomode:i:2"
    }
    

    $RDPConfigFile = $env:USERPROFILE + "\default.rdp"
    
    $RDPConfig | Out-file -Encoding ASCII $RDPConfigFile
    
    return $RDPConfigFile
}

function Connect-Computer {
    #Log start of function
    $Message = "Internalfunction: $($MyInvocation.MyCommand); [$MessageType]; Starting to get the RDP file" 
    FN_WL

    mstsc $RDPConfigFile
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

Export-ModuleMember Connect-RDP
