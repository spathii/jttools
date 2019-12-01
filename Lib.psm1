function Get-JTTimestamp {
    $timestamp = get-date -format yyyyMMdd.hhmmss
    return $timestamp
}

Export-ModuleMember -Function Get-JTTimestamp