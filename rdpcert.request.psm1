function Request-RdpCert {
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$Config,
        [Parameter(Mandatory)]
        [SecureString]$PfxPassword
    )
    # 将 SecureString 转为明文，仅用于命令行参数
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($PfxPassword)
    try {
        $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)
        Start-Process -FilePath $Config.wacsPath -ArgumentList @(
            "--target",      "manual",
            "--host",        $Config.domain,
            "--validation",  "cloudflare",
            "--cloudflareapitoken", "env:$($Config.cfEnvVarName)",
            "--store",       "pfxfile",
            "--pfxfilepath", $Config.pfxFolder,
            "--pfxfilename", ([System.IO.Path]::GetFileNameWithoutExtension($Config.pfxFile)),
            "--pfxpassword", $plainPassword,
            "--emailaddress", $Config.email,
            "--accepttos"
        ) -Wait -NoNewWindow
    } finally {
        if ($BSTR) { [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR) }
    }
}
Export-ModuleMember -Function Request-RdpCert