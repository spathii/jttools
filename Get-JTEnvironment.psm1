Function Get-JTEnvironment {
    #System Environment
    $SystemEnvPath = 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment'
    $SystemEnv = (Get-ItemProperty -Path $SystemEnvPath -Name PATH).path
    $SystemPaths = ($SystemEnv).split(";") | where {$_ -ne ""} | sort -unique
    foreach ($path in $SystemPaths) {
        $systemenvobj = new-object psobject
        $systemenvobj | add-member Environment System
        $systemenvobj | add-member Path $path
        $SystemEnvobj
    }

    #User Environment
    $UserEnvPath = 'Registry::HKEY_CURRENT_USER\Environment'
    $UserEnv = (Get-ItemProperty -Path $UserEnvPath -Name PATH).path
    $Userpaths = ($Userenv).split(";") | where {$_ -ne ""} | sort -unique
    $userpathslist = @()
    foreach ($path in $Userpaths) {
        $UserEnvobj = new-object psobject
        $UserEnvobj | add-member Environment User
        $UserEnvobj | add-member Path $path
        $UserEnvobj
    }

    #Powershell Profile Environment
    foreach ($path in $ProfilePaths) {
        $ProfileEnvobj = new-object psobject
        $ProfileEnvobj | add-member Environment Profile
        $ProfileEnvobj | add-member Path $path
        $ProfileEnvobj
    }
}
Export-ModuleMember -Function Get-JTEnvironment