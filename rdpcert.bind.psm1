<#
.SYNOPSIS
将有效证书绑定到 RDP 服务（写入注册表 SSLCertificateSHA1Hash）
.DESCRIPTION
需要管理员权限；将证书 SHA1 指纹以字节数组形式写入 RDP-Tcp 配置
#>

#Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction'] = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

<#
.SYNOPSIS
为 RDP 服务设置指定证书
.PARAMETER Cert
已导入的有效证书（包含私钥）
#>
function Set-RdpCertBinding {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [System.Security.Cryptography.X509Certificates.X509Certificate2]$Cert
    )

    # 1. 校验证书包含私钥
    if (-not $Cert.HasPrivateKey) {
        throw "证书无私钥，无法用于 RDP 绑定：$($Cert.Thumbprint)"
    }

    # 2. RDP 注册表路径
    $rdpRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
    $regName = "SSLCertificateSHA1Hash"

    # 3. Thumbprint字符串 → 字节数组
    $thumbprintBytes = [byte[]]($Cert.Thumbprint -split '(?<=\G.{2})' | Where-Object { $_ } | ForEach-Object { [Convert]::ToByte($_, 16) })

    # 4. 写入注册表
    $targetInfo = "Registry: $rdpRegPath\$regName (Thumbprint: $($Cert.Thumbprint))"
    
    if ($PSCmdlet.ShouldProcess($targetInfo, "Set RDP Certificate Binding")) {
        Set-ItemProperty -Path $rdpRegPath -Name $regName -Value $thumbprintBytes
        Write-Information "✅ RDP 证书已绑定：$($Cert.Thumbprint)" 
    }
}
Export-ModuleMember -Function Set-RdpCertBinding
