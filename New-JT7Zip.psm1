Function New-JT7Zip {

<#
.SYNOPSIS
Will create a password protected (encrypted) zip file, for either a directory, or a single file.

.DESCRIPTION
Name: New-JT7Zip
Author: jtatman 12/17/2015

.NOTES

TODO - NA

.PARAMETER InputObject
This will be a file, or a directory, both of which will be compressed.
.PARAMETER OutputObject
This is an optional parameter, only needed if the output needs to be of a different name.  This will
usually be skipped.
.PARAMETER Password
The password used to encrypt the new zip archive.


.EXAMPLE
New-JT7Zip.ps1 -InPutObject .\test.pdf -Password "test"
.EXAMPLE
New-JT7Zip.ps1 -InPutObject c:\temp\testfolder -Password "test"
.EXAMPLE
New-JT7Zip.ps1 -InPutObject c:\temp\testfolder -Output c:\temp\testfolderrename.zip -Password "test"
#>

param (
    [String]$InPutObject, 
    [String]$OutputObject,
    [String]$Password
)


[string]$pathToZipExe = "$($Env:ProgramFiles)\7-Zip\7z.exe";
$PasswordString = "-p$Password"


#Create an object to store output into
$ZipResults = New-Object PSObject

#Remove last \ if the inputobject has one
$InputObject = $inputobject.TrimEnd("\")

#test is input is a directory or file
if ((Get-Item $InputObject) -is [System.IO.DirectoryInfo]) {
    $InputType = "Directory"
    if (!$OutputObject) {
        $OutputObject = (Get-Item $InputObject).fullname + ".zip"
        #$OutputObject
    }
}
else {
    echo "Treating as file"
    if (!$OutputObject) {
        $OutputObject = $InputObject + ".zip"
        #$OutputObject
    }
}


[Array]$arguments = "a", "-tzip", "$Output", "$InPutObject", "-r", $PasswordString;
#echo "$pathToZipExe $arguments"

#Do zipping 
& $pathToZipExe $arguments;


$ZipResults | add-member -notepropertyname "InputObject" -NotePropertyValue $InputObject
$ZipResults | add-member -notepropertyname "OutputObject" -NotePropertyValue $OutputObject

$ZipResults
}

Export-ModuleMember New-JT7Zip