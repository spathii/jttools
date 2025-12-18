Function Connect-JTAsset {

<#
.SYNOPSIS
This function will read a SOT for assets, determine the right way to connect 
to it based on a myraid of management methods (ssh, ssh via jumphost, rdp, rdp 
via jumphost, ssm, etc.), and then make the appropriate connection.

.DESCRIPTION
Name: Connect-JTAsset
Author: jtatman 4/26/2023

.NOTES

TODO - NA
    First
Updates
    1/1/2010 - User - Explaination

.PARAMETER Asset
The name of an asset to connect to.  Can be in the form of short name, ip 
address or fqdn.
.PARAMETER User
A user under a different name with which to connect to the asset.  
.PARAMETER Size
The size to set the on the display.

.EXAMPLE
Connect-JTAsset -Asset archwintools 
Will use all the defaults, and connect to archwintools

Connect-JTAsset -Asset wintools -user ad-jtatman
Will connect to wintools with a different user than default

#>

[CmdletBinding()]
param (
    [Parameter(
        Position=0, 
        Mandatory=$true,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][String]$Asset,
    [Parameter(
        Position=1, 
        Mandatory=$false,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][String]$User,
    [Parameter(
        Position=2, 
        Mandatory=$false,
        ValueFromPipeline=$true,
        ValueFromPipelineByPropertyName=$true)
    ][String]$Size
)

################################################################################
#Configurable Script Variables
################################################################################
$AIF = "$($env:USERPROFILE)\Github\Infosec\reference\assets.csv"
$primary_jumphost = "sfly-jump01.internal.shutterfly.com"

#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!
#Hard Coded Values
#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!
#!#!#!#!#
#Hard Coded Variables
#!#!#!#!#


#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#
#Common User defined functions
#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#!#

##################################################################################################
#Script Code
##################################################################################################
##########
#Do Main - The main overall logic of the script
##########
function Do-Main {

    #Run various functions
    $AI =  Get-AssetInfo -Asset $Asset
    Connect-Asset -AI $AI

}


##########
#Script Functions
##########

function Get-AssetInfo {
    param($Asset)

    $AIS = import-csv $AIF
    foreach ($AI in $AIS) {
        if ($AI.Name -eq $Asset -or $AI.IP -eq $Asset -or $AI.FQDN -eq $Asset) {
            return $AI
        }
    }
}
function Connect-Asset {
    param($AI)

    $rdp_cht = @{
        "computer" = $AI.FQDN
        "user" = "$($env:USERNAME)@$($env:USERDNSDOMAIN)"
        "size" = "full"
        "nordg" = $false
        "nordgmatchcredentials" = $false
    }

    $ssh_cht = @{
        "computer" = $AI.FQDN
        "user" = $env:USERNAME
        "connection_string" = "$($env:USERNAME)@$($AI.FQDN)"
    }    

    if ($user) {
        $rdp_cht["user"] = $User
        $ssh_user_cs = $user
    }
    else {
        if ($AI.asset_type -eq "user") {
            $ssh_user_cs = "$($env:USERNAME)"
        }
        elseif ($AI.asset_type -eq "server") {
            $rdp_cht["user"] = "ad-$($env:USERNAME)"
            $rdp_cht["nordgmatchcredentials"] = $true            
        } 
    }

    if ($AI.Connection_path -eq "Direct") {
        $rdp_cht["nordg"] = $true
    }
    else {
        $ssh_cs += ""
    }
    $ssh_cs = "$($ssh_user_cs)@$($AI.FQDN)"

    if ($Size) {
        $rdp_cht["size"] = $Size
    }
    if ($AI.management_protocol -eq "RDP"){
        #$rdp_cht
        connect-rdp @rdp_cht
    }
    elseif ($AI.management_protocol -eq "SSH") {
        #$ssh_cs
        $sb = [scriptblock]::create("& ssh $($ssh_cs)")
        invoke-command -scriptblock $sb
        #$ssh_cht["connection_string"]
    }
}



##################################################################################################
#Execute Script Code
##################################################################################################

Do-Main

}

#New-Alias -Name CN -scope Global -Value Connect-JTAsset
Export-ModuleMember -Function Connect-JTAsset -Alias CN