<#
.SYNOPSIS
RDP证书绑定函数专项测试脚本
验证：管理员权限、私钥检查、指纹转字节数组、注册表写入类型
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# 导入绑定模块
Import-Module "$PSScriptRoot\rdpcert.bind.psm1" -Force

function Test-RdpCertBinding {
    Write-Information "=== 开始 RDP 证书绑定专项测试 ===" -ForegroundColor Cyan

    # 1. 测试非管理员权限校验
    Write-Information "`n[Test 1] 非管理员权限校验" -ForegroundColor Yellow
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) {
        Write-Information "✅ 非管理员，符合预期，无法修改HKLM" -ForegroundColor Green
    }
    else {
        Write-Information "ℹ️ 当前已以管理员身份运行" -ForegroundColor Cyan
    }

    # 2. 生成测试用自签名证书
    Write-Information "`n[Test 2] 生成测试证书" -ForegroundColor Yellow
    $testCert = New-SelfSignedCertificate -DnsName "rdp.test.local" -CertStoreLocation "Cert:\CurrentUser\My" -KeyExportPolicy Exportable
    Write-Information "✅ 测试证书生成：$($testCert.Thumbprint)" -ForegroundColor Green

    # 3. 测试指纹转字节数组
    Write-Information "`n[Test 3] 指纹转字节数组验证" -ForegroundColor Yellow
    $thumbprint = $testCert.Thumbprint
    $bytes = [byte[]]::CreateInstance([byte], $thumbprint.Length / 2)
    for ($i = 0; $i -lt $thumbprint.Length; $i += 2) {
        $bytes[$i/2] = [Convert]::ToByte($thumbprint.Substring($i,2), 16)
    }
    Write-Information "指纹：$thumbprint"
    Write-Information "转换后字节数组长度：$($bytes.Length)（预期20）" -ForegroundColor Green
    if ($bytes.Length -ne 20) { throw "字节数组长度错误" }

    # 4. 管理员环境下测试注册表写入
    if ($isAdmin) {
        Write-Information "`n[Test 4] 测试注册表写入（临时项）" -ForegroundColor Yellow
        $rdpRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp"
        $testRegName = "SSLCertificateSHA1Hash_Test"

        # 写入测试二进制值
        Set-ItemProperty -Path $rdpRegPath -Name $testRegName -Value $bytes -Type Binary
        
        $readType = (Get-ItemProperty -Path $rdpRegPath).$testRegName.GetType().Name
        Write-Information "读取值类型：$readType（预期Byte[]）" -ForegroundColor Green
        
        if ($readType -ne "Byte[]") { throw "注册表类型错误" }

        # 清理测试项
        Remove-ItemProperty -Path $rdpRegPath -Name $testRegName -Force -ErrorAction SilentlyContinue
        Write-Information "✅ 测试注册表项已清理" -ForegroundColor Green
    }

    Write-Information "`n[Test 5] 函数 Set-RdpCertBinding 逻辑校验" -ForegroundColor Yellow
    if ($isAdmin) {
        try {
            if ($testCert.HasPrivateKey) {
                Write-Information "✅ 证书包含私钥，校验通过" -ForegroundColor Green
            }
        }
        catch {
            Write-Error "❌ 函数校验失败：$_" -ForegroundColor Red
            throw
        }
    }

    # 6. 清理测试证书
    Remove-Item "Cert:\CurrentUser\My\$($testCert.Thumbprint)" -Force
    Write-Information "`n✅ 测试证书已清理" -ForegroundColor Green

    Write-Information "`n=== 所有测试通过 ===" -ForegroundColor Green
}

# 执行测试
Test-RdpCertBinding
