<#
.SYNOPSIS
RDP证书检查模块：从本地机器证书存储查找有效且匹配域名的RDP证书
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction'] = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

<#
.SYNOPSIS
获取当前机器中有效、匹配域名、包含私钥的最新RDP证书
.DESCRIPTION
从 LocalMachine\My 存储中筛选：CN匹配 + 未过期 + 有私钥，取最新一张
.PARAMETER Domain
要匹配的证书域名（CN）
.OUTPUTS
System.Security.Cryptography.X509Certificates.X509Certificate2
#>
function Get-ValidRdpCert {
    [OutputType([System.Security.Cryptography.X509Certificates.X509Certificate2])]
    param(
        [Parameter(Mandatory)]
        [string]$Domain
    )

    # 域名不能为空校验
    if ([string]::IsNullOrWhiteSpace($Domain)) {
        throw "域名参数不能为空"
    }

    # 强类型声明证书存储
    [System.Security.Cryptography.X509Certificates.X509Store]$store = `
        New-Object System.Security.Cryptography.X509Certificates.X509Store("My", "LocalMachine")

    try {
        $store.Open("ReadOnly")

        # 筛选：匹配CN + 未过期 + 有私钥 → 取最新
        $cert = $store.Certificates |
            Where-Object {
                $_.Subject -like "*CN=$Domain*" -and
                $_.NotAfter -gt (Get-Date) -and
                $_.HasPrivateKey
            } |
            Sort-Object NotAfter -Descending |
            Select-Object -First 1
    }
    finally {
        if ($store) {
            $store.Close()
        }
    }

    return $cert
}

Export-ModuleMember -Function Get-ValidRdpCert
