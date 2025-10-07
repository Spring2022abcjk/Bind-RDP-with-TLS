# rdpconfig.psm1
Import-Module PSToml
function Import-RdpConfig {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ConfigPath
    )

    if (!(Test-Path $ConfigPath)) {
        throw "配置文件不存在: $ConfigPath"
    }

    # 解析 TOML 配置
    $config = ConvertFrom-Toml -InputObject (Get-Content $ConfigPath -Raw)

    foreach ($line in $toml -split "`n") {
        if ($line -match $pattern) {
            $key = $matches['key']
            $value = $matches['value'].Trim()
            $config[$key] = $value
        }
    }

    # 返回配置对象
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

function New-RandomPassword {
    param(
        [int]$Length = 24
    )
    # 包含大写、小写、数字、特殊字符
    $chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()-_=+[]{}'
    -join (1..$Length | ForEach-Object { $chars | Get-Random -Count 1 })
}

Export-ModuleMember -Function Import-RdpConfig,New-RandomPassword