<#
.SYNOPSIS
导入PFX证书到本地计算机个人证书存储（LocalMachine\My），专供RDP使用
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction'] = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

<#
.SYNOPSIS
导入RDP证书PFX到计算机证书存储
.PARAMETER PfxFile
PFX证书文件路径
.PARAMETER PfxPassword
PFX密码（SecureString）
.OUTPUTS
System.Security.Cryptography.X509Certificates.X509Certificate2
#>
function Import-RdpCert {
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
    param(
        [Parameter(Mandatory)]
        [string]$PfxFile,

        [Parameter(Mandatory)]
        [System.Security.SecureString]$PfxPassword
    )

    # 1. 检查PFX文件存在
    if (-not (Test-Path $PfxFile -PathType Leaf)) {
        throw "PFX证书文件不存在：$PfxFile"
    }

    # 2. 证书密钥存储标志
    [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]$keyFlags =
        [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::Exportable -bor
        [System.Security.Cryptography.X509Certificates.X509KeyStorageFlags]::PersistKeySet

    # 3. 直接用 SecureString 加载证书
    [System.Security.Cryptography.X509Certificates.X509Certificate2]$cert =
        [System.Security.Cryptography.X509Certificates.X509Certificate2]::new(
            $PfxFile,
            $PfxPassword,  # 直接传 SecureString
            $keyFlags
        )

    # 4. 验证证书已正确加载私钥
    if (-not $cert.HasPrivateKey) {
        throw "导入的证书不包含私钥，无法用于RDP"
    }

    [System.Security.Cryptography.X509Certificates.X509Store]$store =
        New-Object System.Security.Cryptography.X509Certificates.X509Store("My", "LocalMachine")

    try {
        $store.Open("ReadWrite")
        $store.Add($cert)
    }
    finally {
        if ($store) { $store.Close() }
    }

    return $cert
}

Export-ModuleMember -Function Import-RdpCert
