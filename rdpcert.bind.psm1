function Set-RdpCertBinding {
    param(
        [Parameter(Mandatory)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Cert
    )
    Set-ItemProperty `
      -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" `
      -Name "SSLCertificateSHA1Hash" `
      -Value $Cert.Thumbprint
}
Export-ModuleMember -Function Set-RdpCertBinding