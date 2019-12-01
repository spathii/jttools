Function Set-JTNetworkAddress {
<#     
.SYNOPSIS     
    Sets the IP address of a windows server/computer   
     
.DESCRIPTION        
                  
.NOTES     
    Name: Set-JTNetworkAddress 
    Author: Jason Tatman     
    Date Created: 2/11/2016   
       
    To Do: This script needs extensive testing
        Add additional domains, to update the prefix list               
      
.EXAMPLE     
    Set-JTNetworkAddress -IPAddress 10.1.1.2 -PrefixLength 24 -Gateway 10.1.1.1 -Domain Shutterfly
    This will set the ip, the subnet, and gateway, and add a predefined set of DNS servers, and DNS Search Suffixes

.EXAMPLE     
    Set-JTNetworkAddress -IPAddress 10.1.1.2
    This will set the ip, the subnet, and gateway, and add a predefined set of DNS servers, and DNS Search Suffixes
    using the default values hard coded into the script, and derive the gateway
               
#>  

param (
	$IPAddress,
	$PrefixLengh = "24",
	$Gateway,
    $DNSServers = @("172.16.24.103","172.20.210.71"),
	$Domain = "Shutterfly"
)

#$IPAddress = "172.18.146.182"

switch ($Domain) {
    "Shutterfly" { $Suffixlist = "corp.shutterfly.com,internal.shutterfly.com,tinyprints.local,mypublisher.com,shutterfly.com"  }
    default { $Suffixlist = "corp.shutterfly.com,internal.shutterfly.com,tinyprints.local,mypublisher.com,shutterfly.com"  }
}
    

#If no gateway is input, use the default
If (!($Gateway)) {
	$GatewayArray = $IPAddress.split(".")
	$Gateway = $GatewayArray[0] + "." + $GatewayArray[1] + "." + $GatewayArray[2] + "." + 1
}

#Set the IP address
$Interface = Get-NetAdapter -InterfaceAlias "ethernet"
#Determine if there is an IP address already
if (($Interface | Get-NetIPAddress -AddressFamily ipv4).ipaddress) {
	$Interface | Set-NetIPaddress -AddressFamily ipv4 -IPAddress $IPAddress -PrefixLength 24
}
else {
	$Interface | New-NetIPaddress -AddressFamily ipv4 -IPAddress $IPAddress -PrefixLength 24
}


#Set the default route
#Check to make sure there is not already a default route, and remove it.
If ($Interface | Get-NetRoute -AddressFamily IPv4 -DestinationPrefix "0.0.0.0/0") {
	$Interface | Remove-NetRoute -DestinationPrefix "0.0.0.0/0" -Confirm:$FALSE
}
$Interface | New-NetRoute -AddressFamily IPv4 -NextHop $Gateway -DestinationPrefix "0.0.0.0/0" -Confirm:$FALSE


#Set the DNS Servers
$Interface | Set-DNSClientServerAddress -ServerAddresses $DNSServers


#Set the DNS Suffixes
$Interface | Set-DNSClient -ConnectionSpecificSuffix $Suffixlist


# Allow RDP Connections to this computer
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name fDenyTSConnections -Value 0

# Require Network Level Authentication
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name UserAuthentication -Value 1

# Allow the Remote Desktop firewall exception
Set-NetFirewallRule -DisplayGroup 'Remote Desktop' -Enabled True

}

Export-ModuleMember -Function Set-JTNetworkAddress