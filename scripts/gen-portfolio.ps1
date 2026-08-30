# 作品集密码 / 项目数据生成器
# 用法：
#   1. 修改下面的 $Password 和 $ProjectsJson（按需增删项目）
#   2. 运行:  powershell -ExecutionPolicy Bypass -File scripts/gen-portfolio.ps1
#   3. 把输出的 HASH 和 DATA 两行，粘贴到 source/projects/index.md 的脚本里（替换对应两行）
#   4. git add . && git commit -m "更新作品集" && git push origin master

# ===== 改成你自己的访问密码（写进简历的那个） =====
$Password = "123456"

# ===== 项目列表：name 项目名 / desc 简介 / demo 演示地址 / code 源码地址（可选） =====
$ProjectsJson = @'
[
  { "name": "示例项目 A", "desc": "项目简介：一句话说明这个项目", "demo": "https://example.com/demo-a", "code": "https://github.com/suixingsir/example-a" },
  { "name": "示例项目 B", "desc": "项目简介：一句话说明这个项目", "demo": "https://example.com/demo-b" }
]
'@

$sha = [System.Security.Cryptography.SHA256]::Create()
$hashBytes = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Password))
$hashHex = ($hashBytes | ForEach-Object { $_.ToString("x2") }) -join ""

$dataB64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($ProjectsJson))

Write-Host ""
Write-Host "========== 把下面两行粘贴到 source/projects/index.md =========="
Write-Host "HASH = $hashHex"
Write-Host "DATA = $dataB64"
Write-Host "=================================================================="
