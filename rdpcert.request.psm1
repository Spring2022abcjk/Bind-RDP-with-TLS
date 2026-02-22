<#
.SYNOPSIS
调用 win-acme 从 Let's Encrypt 申请 RDP 证书，并输出为 PFX 文件
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction'] = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

<#
.SYNOPSIS
调用 win-acme 申请泛域名/单域名证书（Cloudflare DNS 验证）
.PARAMETER Config
配置对象：domain, wacsPath, pfxFolder, pfxFile, cfEnvVarName, email
.PARAMETER PfxPassword
PFX 密码（SecureString）
#>
function Request-RdpCert {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Config,

        [Parameter(Mandatory)]
        [SecureString]$PfxPassword
    )

    # 1. 配置必填项校验
    $requiredProps = @("domain", "wacsPath", "pfxFolder", "pfxFile", "cfEnvVarName", "email")
    foreach ($prop in $requiredProps) {
        if ([string]::IsNullOrWhiteSpace($Config.$prop)) {
            throw "Config 对象缺少必填字段：$prop"
        }
    }

    # 2. 检查 win acme 程序存在
    if (-not (Test-Path $Config.wacsPath -PathType Leaf)) {
        throw "win-acme 程序不存在：$($Config.wacsPath)"
    }

    # 3. 确保输出目录存在
    if (-not (Test-Path $Config.pfxFolder)) {
        New-Item -ItemType Directory -Path $Config.pfxFolder -Force | Out-Null
    }

    $passwordBSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($PfxPassword)
    try {
        $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($passwordBSTR)

        # 5. 构造 win-acme 参数
        $pfxFileName = [System.IO.Path]::GetFileNameWithoutExtension($Config.pfxFile)
        $arguments = @(
            "--target", "manual",
            "--host", $Config.domain,
            "--validation", "cloudflare",
            "--cloudflareapitoken", "env:$($Config.cfEnvVarName)",
            "--store", "pfxfile",
            "--pfxfilepath", $Config.pfxFolder,
            "--pfxfilename", $pfxFileName,
            "--pfxpassword", $plainPassword,
            "--emailaddress", $Config.email,
            "--accepttos"
        )

        # 6. 执行并获取退出码
        $process = Start-Process -FilePath $Config.wacsPath `
            -ArgumentList $arguments `
            -Wait -NoNewWindow -PassThru

        # 7. 检查退出码：0=成功，非0=失败
        if ($process.ExitCode -ne 0) {
            throw "win-acme 证书申请失败，退出码：$($process.ExitCode)，域名：$($Config.domain)"
        }
    }
    finally {
        # 强制清空内存中的明文密码
        if ($passwordBSTR) {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($passwordBSTR)
        }
    }
}

Export-ModuleMember -Function Request-RdpCert
