Function Get-JTWhoIs {

<#
.SYNOPSIS
This script will query whois similar to a whois query

.DESCRIPTION
Name: Get-JTWhoIs
Author: jtatman 1/11/2023

Reference: https://www.powershellgallery.com/packages/PSScriptTools/2.9.0/Content/functions%5CGet-WhoIs.ps1

.NOTES

TODO

Updates

.PARAMETER IP
The IP to query

.EXAMPLE
get-JTWhois -IP 4.2.2.2
Default useage of the function/module
#>

[CmdletBinding()]
param (
    [Parameter(
        Position=0, 
        Mandatory=$false, 
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][String]$IP
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


#!#!#!#!#



##################################################################################################
#Script Code
##################################################################################################
##########
#Do Main - The main overall logic of the script
##########
function Do-Main {

    Get-Whois -IPAddress $IP

}


##########
#Script Functions
##########
Function Get-WhoIs {
    [cmdletbinding()]
    [OutputType("WhoIsResult")]
    Param (
        [parameter(Position = 0,
            Mandatory,
            HelpMessage = "Enter an IPV4 address to lookup with WhoIs",
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [ValidatePattern("^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$")]
         [ValidateScript( {
            #verify each octet is valid to simplify the regex
                $test = ($_.split(".")).where({[int]$_ -gt 254})
                if ($test) {
                    Throw "$_ does not appear to be a valid IPv4 address"
                    $false
                }
                else {
                    $true
                }
            })]
        [string]$IPAddress
    )

    Begin {
        Write-Verbose "Starting $($MyInvocation.Mycommand)"
        $baseURL = 'http://whois.arin.net/rest'
        #default is XML anyway
        $header = @{"Accept" = "application/xml"}

    } #begin

    Process {
        Write-Verbose "Getting WhoIs information for $IPAddress"
        $url = "$baseUrl/ip/$ipaddress"
        Try {
            $r = Invoke-Restmethod $url -Headers $header -ErrorAction stop
            Write-verbose ($r.net | Out-String)
        }
        Catch {
            $errMsg = "Sorry. There was an error retrieving WhoIs information for $IPAddress. $($_.exception.message)"
            $host.ui.WriteErrorLine($errMsg)
        }

        if ($r.net) {
            Write-Verbose "Creating result"
            [pscustomobject]@{
                PSTypeName             = "WhoIsResult"
                IP                     = $ipaddress
                Name                   = $r.net.name
                RegisteredOrganization = $r.net.orgRef.name
                City                   = (Invoke-RestMethod $r.net.orgRef.'#text').org.city
                StartAddress           = $r.net.startAddress
                EndAddress             = $r.net.endAddress
                NetBlocks              = $r.net.netBlocks.netBlock | foreach-object {"$($_.startaddress)/$($_.cidrLength)"}
                Updated                = $r.net.updateDate -as [datetime]
            }
        } #If $r.net
    } #Process

    End {
        Write-Verbose "Ending $($MyInvocation.Mycommand)"
    } #end
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

Export-ModuleMember Get-JTWhoIs
