
<#
.SYNOPSIS
This is the basic shell to import all of the functions related to MPSTools powershell module.
It will echo the process of importing the module back to the user, and then load all
nested modules.
  #>

function Get-JTTools {

	Write-Host "Loading JTTools Module"

}

Export-ModuleMember -Function "*"

