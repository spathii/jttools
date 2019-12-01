 function Get-JTOpt {  
 <#     
.SYNOPSIS     
    This is a simple wrapper for robocopy, to push (publish) the contents of the DEV opt directory,
    to a central repository.  This is written specifically for the Shutterfly environment.
     
.DESCRIPTION   
                  
.NOTES     
    Name: Get-JTOpt 
    Author: Jason Tatman     
    Date Created: 2/19/2016   
       
    To Do: 
             
.EXAMPLE     
    Set-JTopt

    This is the default usage of the script, accepting all defaults. 
               
#> 



param (
    $excludedir
)

$Server = "corp.shutterfly.com"
#$Server = "172.16.24.78"

$SourceDirectory = "\\$Server\departments\security\opt"
$DestinationDirectory = """c:\opt"""

$RobocopyApp = "c:\opt\bin\robocopy.exe"
$RobocopyParamType = "/MIR"
$RobocopyParamCopyType = "/COPY:DAT"
$RobocopyParamRetry = "/R:1 /W:5"
$RobocopyParamExcludeFile = "/XF desktop.ini"

$RobocopyParamExcludeDir = "/XD Archive dev home lib workstation router hardwaretype"
if ($excludedir) {
    $RobocopyParamExcludeDir = $RobocopyParamExcludeDir + " " + $excludedir
}
#$RobocopyFlags = "/COPY:DAT /XD Archive /XF desktop.ini /NFL /NDL /NS /NJH /R:1 /W:5"
$RobocopyFlags = "/COPY:DAT " + $ExcludeParam + " /XF desktop.ini /R:1 /W:5"
$RobocopyCommandExpression = $RobocopyApp + " " + $RobocopyParamType + " " + $SourceDirectory + " " + `
                             $DestinationDirectory + " " + $RobocopyParamCopyType + " " + $RobocopyParamRetry + " " + `
                             $RobocopyParamExcludeFile + " " + $RobocopyParamExcludeDir
$RobocopyCommandExpression

invoke-expression $RobocopyCommandExpression


}

Export-ModuleMember -Function Get-JTOpt