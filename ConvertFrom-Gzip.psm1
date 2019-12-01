Function ConvertFrom-GZIP {
 <#     
.SYNOPSIS     
    Exctracts the contents of a gzip file, using native .net. 
     
.DESCRIPTION    
                  
.NOTES     
    Name: ConvertFrom-GZIP 
    Author: Jason Tatman     
    Date Created: 4/7/2016   
       
    To Do: Right now it will only parse our AXFR files, which have been pulled by a slave, from a master.  
    It cannot parse the db files directly.             
      
.EXAMPLE     
                   
#>  

Param(
    $InputFile,
    [boolean]$Tar=$TRUE
    )

import-module jttools

if (!(test-path "c:\program files\7-zip\7z.exe")) {
    throw "No decompression utility found (7zip)"
}

[string]$pathToZipExe = "$($Env:ProgramFiles)\7-Zip\7z.exe"

#Unzip 
[Array]$UnzipArguments = "e", $InputFile
& $pathToZipExe $UnzipArguments

if ($Tar = $TRUE) {
    #Untar
    [Array]$UntarArguments = "x", ($InputFile -replace "\.gz$","")
    & $pathToZipExe $UntarArguments
}

}

Export-ModuleMember -Function ConvertFrom-GZIP