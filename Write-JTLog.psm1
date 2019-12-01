Function Write-JTLog {

<#
.SYNOPSIS
This script will write to a common log format

.DESCRIPTION
Name: Write-JTLog
Author: jtatman 3/4/2016

.NOTES

TODO - NA

.PARAMETER LogFile
The log file to be written to
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
        Mandatory=$true, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][String]$Message,
    [Parameter(
        Position=1, 
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][String]$InstanceID,
    [Parameter(
        Position=0, 
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][String]$LogFile,
    [Parameter(
        Position=4, 
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)    
    ][String]$CallingScript

)

$User = ($env:USERNAME + "@" + $env:USERDNSDOMAIN)
$LogFile = "c:\log\PowershellModules\" + (ls $MyInvocation.ScriptName).Name.split(".")[0] + ".log"
$CallingScript = $MyInvocation.ScriptName

#Get a timestamp to set on logs
function Get-SFLYLogTimestamp {
    $timestamp = get-date -format yyyyMMdd-HHmmss
    return $timestamp.tostring()
}
$LogString = (Get-SFLYLogTimestamp + "F,$InstanceID,$User,$CallingScript,$Message")
$LogString = ($(Get-SFLYLogTimestamp) + "|InstanceID=$InstanceID|User=$User|CallingScript=$CallingScript|Message=$Message")
$LogString | Out-File -FilePath $LogFile -Encoding ASCII -Append

}

Export-ModuleMember Write-JTLog