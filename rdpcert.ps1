param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot "exampleenv.toml")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

<#
.SYNOPSIS
  智能申请并绑定 RDP 证书主流程脚本
#>

try {
    #region 导入模块
    $moduleFiles = @(
        "rdpconfig.psm1",
        "rdpcert.check.psm1",
        "rdpcert.request.psm1",
        "rdpcert.import.psm1",
        "rdpcert.bind.psm1"
    )

    foreach ($file in $moduleFiles) {
        $moduleFullPath = Join-Path $PSScriptRoot $file
        if (-not (Test-Path $moduleFullPath)) {
            throw "模块文件缺失：$moduleFullPath"
        }
        Import-Module $moduleFullPath -Force
    }
    #endregion

    #region 读取配置与准备密码
    $config = Import-RdpConfig -ConfigPath $ConfigPath

    [SecureString]$pfxPassword = $null
    $pfxPasswordVarName = "RDP_PFX_PASSWORD"

    if ([string]::IsNullOrWhiteSpace($config.pfxPassword)) {
        $randomPw = New-RandomPassword
        [System.Environment]::SetEnvironmentVariable($pfxPasswordVarName, $randomPw, "User")
        Write-Information "未检测到 pfxPassword，已生成新密码写入环境变量 $pfxPasswordVarName"
        $pfxPassword = $randomPw | ConvertTo-SecureString -AsPlainText -Force
    }
    else {
        $pfxPassword = $config.pfxPassword | ConvertTo-SecureString -AsPlainText -Force
    }
    #endregion

    #region 检查现有证书
    $cert = Get-ValidRdpCert -Domain $config.domain
    if ($cert) {
        Write-Information "✅ 已找到有效证书：$($cert.Thumbprint)"
        Write-Information "📅 有效期至：$($cert.NotAfter)"
        Set-RdpCertBinding -Cert $cert
        Write-Information "🔗 已绑定现有证书到 RDP：$($cert.Thumbprint)"
        exit 0
    }
    #endregion

    #region 申请新证书
    Write-Information "⚠️ 未找到有效证书或已过期，开始申请新证书..."
    if (!(Test-Path $config.pfxFolder)) {
        New-Item -ItemType Directory -Path $config.pfxFolder | Out-Null
    }
    if (-not (Get-Item -Path "Env:$($config.cfEnvVarName)" -ErrorAction SilentlyContinue)) {
        throw "环境变量 $($config.cfEnvVarName) 未设置，请先设置环境变量"
    }
    Request-RdpCert -Config $config -PfxPassword $pfxPassword
    #endregion

    #region 导入新证书并绑定
    $pfxCert = Import-RdpCert -PfxFile $config.pfxFile -PfxPassword $pfxPassword
    Set-RdpCertBinding -Cert $pfxCert
    Write-Information "✅ 新证书已申请并绑定到 RDP：$($pfxCert.Thumbprint)"
    #endregion
}
catch {
    Write-Error "发生错误：$_"
    exit 1
}
