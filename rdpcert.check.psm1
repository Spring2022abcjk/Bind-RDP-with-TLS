function Get-ValidRdpCert {
    param(
        [Parameter(Mandatory)]
        [string]$Domain
    )
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("My","LocalMachine")
    $store.Open("ReadOnly")
    $cert = $store.Certificates |
        Where-Object {
            $_.Subject -like "*CN=$Domain*" -and
            $_.NotAfter -gt (Get-Date) -and
            $_.HasPrivateKey
        } |
        Sort-Object NotAfter -Descending |
        Select-Object -First 1
    $store.Close()
    return $cert
}
Export-ModuleMember -Function Get-ValidRdpCert