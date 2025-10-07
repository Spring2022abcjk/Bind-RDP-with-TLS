function Import-RdpCert {
    param(
        [Parameter(Mandatory)]
        [string]$PfxFile,
        [Parameter(Mandatory)]
        [System.Security.SecureString]$PfxPassword
    )
    $keyFlags = [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable `
              -bor [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet
    $passwordBSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($PfxPassword)
    $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($passwordBSTR)
    $cert = [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
        $PfxFile, $plainPassword, $keyFlags
    )
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordBSTR)
    $store = New-Object System.Security.Cryptography.X509Certificates.X509Store("My","LocalMachine")
    $store.Open("ReadWrite")
    $store.Add($cert)
    $store.Close()
    return $cert
}
Export-ModuleMember -Function Import-RdpCert