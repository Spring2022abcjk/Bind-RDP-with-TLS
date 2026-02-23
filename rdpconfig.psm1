<#
.SYNOPSIS
RDP证书配置解析模块，负责读取TOML配置、生成随机密码
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction'] = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 检查并加载依赖模块
if (-not (Get-Module -Name PSToml -ListAvailable)) {
    throw "缺失必需模块：PSToml，请先安装：Install-Module PSToml -Scope CurrentUser"
}
Import-Module PSToml -Force

<#
.SYNOPSIS
从TOML文件导入RDP配置
#>
function Import-RdpConfig {
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    if (-not (Test-Path $ConfigPath)) {
        throw "配置文件不存在: $ConfigPath"
    }

    # 读取并解析 TOML
    $rawContent = Get-Content -Path $ConfigPath -Raw -Encoding UTF8
    $config = ConvertFrom-Toml -InputObject $rawContent

    # 必填配置项校验
    $requiredKeys = @("domain", "pfxFolder", "pfxFile", "wacsPath", "cfEnvVarName", "email")
    foreach ($key in $requiredKeys) {
        if ([string]::IsNullOrWhiteSpace($config[$key])) {
            throw "配置文件缺失或为空项：$key"
        }
    }

    # 返回标准化配置对象
    return [PSCustomObject]@{
        domain       = $config['domain']
        pfxFolder    = $config['pfxFolder']
        pfxFile      = Join-Path $config['pfxFolder'] $config['pfxFile']
        pfxPassword  = $config['pfxPassword']
        wacsPath     = $config['wacsPath']
        cfEnvVarName = $config['cfEnvVarName']
        email        = $config['email']
    }
}

<#
.SYNOPSIS
生成高强度随机密码
#>
function Get-RandomPassword {
    [OutputType([string])]
    param(
        [int]$Length = 24
    )

    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+[]{}'
    -join (1..$Length | ForEach-Object { $chars | Get-Random -Count 1 })
}

Export-ModuleMember -Function Import-RdpConfig, Get-RandomPassword
