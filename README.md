# RDP 证书自动申请与绑定工具
基于 PowerShell 7 + win-acme + Cloudflare DNS 验证  
全自动为 Windows 远程桌面（RDP）申请、续期、绑定 Let's Encrypt 证书

## 项目介绍
本项目为模块化的 RDP 证书自动化工具，解决 Windows 服务器 RDP 默认自签名证书不安全、手动续期繁琐的问题。  
全程无明文密码、无硬编码密钥、严格错误处理、可重复执行、可放入计划任务自动续期。

## 核心能力
- 智能检查：自动识别有效证书，避免重复申请  
- 自动申请：调用 win-acme 完成 DNS 验证（Cloudflare）  
- 自动导入：将 PFX 证书导入计算机证书存储  
- 自动绑定：按微软官方规范写入 RDP 二进制注册表项  
- 安全合规：全程 SecureString、环境变量存密钥  

## 文件结构
```
├── rdpcert.ps1                # 主入口脚本（执行入口）
├── exampleenv.toml            # 配置模板（复制为 rdpcert.toml 使用）
├── rdpconfig.psm1             # 配置解析模块
├── rdpcert.check.psm1         # 证书检查模块
├── rdpcert.request.psm1       # 证书申请模块（调用 win-acme）
├── rdpcert.import.psm1        # 证书导入模块
├── rdpcert.bind.psm1          # RDP 证书绑定模块
└── Test-RdpCertBinding.ps1    # RDP 绑定专项测试脚本
```

## 环境要求
1. PowerShell 7+（不支持 Windows PowerShell 5.1）  
2. 必须以管理员身份运行  
3. 安装依赖模块：PSToml  
4. win-acme 工具包  
5. Cloudflare API Token（DNS 编辑权限）

## 快速部署

### 1. 安装依赖
```powershell
Install-Module -Name PSToml -Scope CurrentUser -Force
```

### 2. 配置文件
复制 `exampleenv.toml` 为 `rdpcert.toml`，按实际信息修改：

```toml
domain          = "rdp.yourdomain.com"   # 域名
pfxFolder       = "D:\Certs\RDP"         # PFX 存储目录
pfxFile         = "rdp_cert.pfx"         # PFX 文件名
pfxPassword     = ""                     # PFX 密码（留空则自动生成）
wacsPath        = "D:\win-acme\wacs.exe"  # win-acme 路径
cfEnvVarName    = "CF_API_TOKEN"         # Cloudflare 令牌环境变量名
email           = "admin@yourdomain.com" # 邮箱
```

### 3. 设置 Cloudflare 令牌（环境变量）
```powershell
# 永久写入用户环境变量
[System.Environment]::SetEnvironmentVariable("CF_API_TOKEN", "你的Cloudflare令牌", "User")
```

### 4. 执行脚本
```powershell
# 管理员 PWSH 7 执行
.\rdpcert.ps1 -ConfigPath "D:\win-acme\rdpcert.toml"
```

## 运行逻辑
1. 检查有效证书  
   - 存在 → 自动绑定 → 退出  
   - 不存在/已过期 → 进入申请流程  
2. 申请新证书  
   - 调用 win-acme 完成 DNS 验证  
   - 导出 PFX 到指定目录  
3. 导入证书  
   - 导入 LocalMachine\My 存储  
   - 校验私钥可用性  
4. 绑定 RDP  
   - 按微软官方规范写入二进制注册表项  
   - RDP 立即生效  

## 自动续期（计划任务）
1. 任务程序：`pwsh.exe`  
2. 参数：`-ExecutionPolicy Bypass -File "D:\win-acme\rdpcert.ps1" -ConfigPath "D:\win-acme\rdpcert.toml"`  
3. 触发条件：每 60 天执行一次  
4. 安全选项：使用管理员账户、不存储密码  

## 测试脚本
测试 RDP 证书绑定逻辑（不影响生产环境）：
```powershell
.\Test-RdpCertBinding.ps1
```

## 安全规范
1. 密钥不硬编码：Cloudflare 令牌走环境变量  
2. 密码无明文：全程使用 SecureString  
3. 最小权限：证书存储只读/读写严格分离  
4. 错误即停：严格模式 + 全局异常捕获  
5. 无残留：密码内存即时清理  

## 常见问题

### 1. 重复执行会重复申请证书吗？
不会。存在有效证书时，脚本会直接退出，不会进入申请流程。

### 2. RDP 证书不生效？
本工具严格按微软官方规范写入 `REG_BINARY` 字节数组，可通过以下命令验证：
```powershell
Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name SSLCertificateSHA1Hash
```

### 4. 必须使用 PowerShell 7？
是，本项目使用跨平台规范、.NET 特性、安全字符串处理。
