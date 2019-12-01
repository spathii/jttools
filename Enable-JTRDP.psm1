Function Enable-JTRDP {
<#     
.SYNOPSIS     
    Enables Remote Desktop on the computer   
     
.DESCRIPTION        
                  
.NOTES     
    Name: Enable-JTRDP 
    Author: Jason Tatman     
    Date Created: 2/17/2016   
                   
      
.EXAMPLE     
    Enable-JTRDP
               
#>  

set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"
set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -name "UserAuthentication" -Value 1  

}

Export-ModuleMember -Function Enable-JTRDP