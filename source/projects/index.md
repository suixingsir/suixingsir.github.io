---
title: 作品集
comments: false
---

<!-- 作品集页面：输入简历里的访问密码后，才会显示项目链接。
     项目链接以 base64 藏在下面的脚本里，页面源码中看不到明文链接，爬虫拿不到。
     修改密码 / 添加项目：编辑 scripts/gen-portfolio.ps1，运行后把输出的 HASH 和 DATA 粘贴到下方脚本对应位置。 -->

<div id="portfolio-gate" style="text-align:center;padding:40px 0">
  <p style="font-size:1.1em;margin-bottom:8px">此页面仅对拿到访问密码的人开放</p>
  <p style="color:#888;margin-bottom:16px">请输入密码（访问密码见简历）</p>
  <input type="password" id="pf-password" placeholder="请输入访问密码"
         style="padding:8px 14px;border:1px solid #ccc;border-radius:6px;margin-right:8px" />
  <button id="pf-unlock" style="padding:8px 18px;border:none;border-radius:6px;background:#425AEF;color:#fff;cursor:pointer">解锁</button>
  <p id="pf-error" style="color:#f65c2c;display:none;margin-top:12px">密码错误，请重试</p>
</div>

<div id="portfolio-content" style="display:none"></div>

<script data-pjax>
(async function () {
  // ===== 以下两个值由 scripts/gen-portfolio.ps1 生成，改密码/加项目时重新生成再粘回来 =====
  var HASH = '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92'
  var DATA = 'W3sibmFtZSI6IuekuuS+i+mhueebriBBIiwiZGVzYyI6IumhueebrueugOS7i++8muS4gOWPpeivneivtOaYjui/meS4qumhueebriIsImRlbW8iOiJodHRwczovL2V4YW1wbGUuY29tL2RlbW8tYSIsImNvZGUiOiJodHRwczovL2dpdGh1Yi5jb20vc3VpeGluZ3Npci9leGFtcGxlLWEifSx7Im5hbWUiOiLnpLrkvovpobnnm64gQiIsImRlc2MiOiLpobnnm67nroDku4vvvJrkuIDlj6Xor53or7TmmI7ov5nkuKrpobnnm64iLCJkZW1vIjoiaHR0cHM6Ly9leGFtcGxlLmNvbS9kZW1vLWIifV0='
  // =============================================================================

  var gate = document.getElementById('portfolio-gate')
  var content = document.getElementById('portfolio-content')
  var input = document.getElementById('pf-password')
  var err = document.getElementById('pf-error')

  function sha256hex (s) {
    return crypto.subtle.digest('SHA-256', new TextEncoder().encode(s)).then(function (buf) {
      return Array.prototype.map.call(new Uint8Array(buf), function (b) { return ('0' + b.toString(16)).slice(-2) }).join('')
    })
  }

  function render () {
    var PROJECTS = JSON.parse(new TextDecoder().decode(Uint8Array.from(atob(DATA), function (c) { return c.charCodeAt(0) })))
    gate.style.display = 'none'
    content.style.display = 'block'
    content.innerHTML = PROJECTS.map(function (p) {
      return '<div style="border:1px solid #eee;border-radius:10px;padding:16px 20px;margin-bottom:14px">' +
        '<h3 style="margin:0 0 6px">' + p.name + '</h3>' +
        '<p style="margin:0 0 10px;color:#666">' + p.desc + '</p>' +
        '<a href="' + p.demo + '" target="_blank" rel="noopener" style="margin-right:14px;color:#425AEF;text-decoration:none">在线演示 →</a>' +
        (p.code ? '<a href="' + p.code + '" target="_blank" rel="noopener" style="color:#425AEF;text-decoration:none">源码 →</a>' : '') +
        '</div>'
    }).join('')
  }

  function unlock () {
    sha256hex(input.value).then(function (h) {
      if (h === HASH) {
        err.style.display = 'none'
        render()
      } else {
        err.style.display = 'block'
        input.select()
      }
    })
  }

  document.getElementById('pf-unlock').addEventListener('click', unlock)
  input.addEventListener('keydown', function (e) { if (e.key === 'Enter') unlock() })
})()
</script>
