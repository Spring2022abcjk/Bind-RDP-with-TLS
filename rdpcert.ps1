<#
.SYNOPSIS
  智能申请并绑定 RDP 证书主流程脚本
#>

#region 导入模块
Import-Module "$PSScriptRoot\rdpconfig.psm1"
Import-Module "$PSScriptRoot\rdpcert.check.psm1"
Import-Module "$PSScriptRoot\rdpcert.request.psm1"
Import-Module "$PSScriptRoot\rdpcert.import.psm1"
Import-Module "$PSScriptRoot\rdpcert.bind.psm1"
#endregion

#region 读取配置与准备密码
$configPath = "$PSScriptRoot\exampleenv.toml"
$config = Import-RdpConfig -ConfigPath $configPath

# 处理 pfxPassword
if ([string]::IsNullOrWhiteSpace($config.pfxPassword)) {
    $pfxPasswordVarName = "RDP_PFX_PASSWORD"
    $pfxPassword = New-RandomPassword
    [System.Environment]::SetEnvironmentVariable($pfxPasswordVarName, $pfxPassword, "User")
    Write-Host "未检测到 pfxPassword，已生成新密码并写入环境变量 $pfxPasswordVarName"
} else {
    $pfxPasswordVarName = $null
    $pfxPassword = $config.pfxPassword
}
if ($pfxPasswordVarName) {
    $pfxPassword = (Get-Item -Path "Env:$pfxPasswordVarName").Value
}
#endregion

#region 检查现有证书
$cert = Get-ValidRdpCert -Domain $config.domain
if ($cert) {
    Write-Host "✅ 已找到有效证书：" $cert.Thumbprint
    Write-Host "📅 有效期至：" $cert.NotAfter
    Set-RdpCertBinding -Cert $cert
    Write-Host "🔗 已绑定现有证书到 RDP：" $cert.Thumbprint
    exit 0
}
#endregion

#region 申请新证书
Write-Host "⚠️ 未找到有效证书或已过期，开始申请新证书..."
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
Write-Host "✅ 新证书已申请并绑定到 RDP：" $pfxCert.Thumbprint
#endregion
exit 0
