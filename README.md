# 随性先生的博客

基于 [Hexo](https://hexo.io/) 的个人博客，主题为 [Tessera](https://github.com/LumiDesk/hexo-theme-tessera)，托管于 GitHub Pages。

在线地址：<https://suixingsir.github.io/>

## 技术栈

- Hexo 8（Node.js 24）
- 主题：hexo-theme-tessera
- 部署：GitHub Actions → GitHub Pages

## 本地开发

```bash
npm install        # 安装依赖（使用 package-lock.json，统一用 npm，不要用 yarn）
npx hexo server    # 本地预览 http://localhost:4000
npx hexo generate  # 构建到 public/
npx hexo clean     # 清理缓存后重新构建
```

## 写文章

两种方式任选：

1. 命令行创建：`npx hexo new "文章标题"`（自动在 `source/_posts/` 下建文件）
2. 手动创建：在 `source/_posts/` 下新建 `.md` 文件

文件开头必须有 front-matter（`---` 之间的部分），例如：

```markdown
---
title: 文章标题
date: 2026-08-30 12:00:00
categories:
  - 技术        # 首页三个模块：技术 / 生活 / 随笔，三选一
tags:
  - React
---
```

- `categories` 填 `技术` / `生活` / `随笔` 之一，首页开屏的「技术 / 生活 / 随笔」入口会自动跳到对应分类
- `tags` 可填多个，用 `-` 列表
- 参考示例：`source/_posts/` 下的 `周末走走-示例文章.md`、`随便写点-示例文章.md`、`图片和视频怎么发-示例文章.md`

### 图片和视频

**图片**：把文件放到 `source/images/`，文章里引用：

```markdown
![](/images/你的图片.png)
```

多张图用主题画廊标签（自动排网格、可放大）：

```markdown
{% gallery %}
![](/images/1.png)
![](/images/2.png)
{% endgallery %}
```

**视频**：本地视频放到 `source/videos/`，用 HTML 标签嵌入：

```html
<video src="/videos/你的视频.mp4" controls style="width:100%"></video>
```

嵌入 B站 / YouTube：视频页点「分享 → 嵌入」，把 iframe 代码粘到文章里即可。

> 路径以 `/` 开头表示网站根目录；文件会随 `git push` 一起上传，别放太大的文件。

### 作品集（密码保护）

`/projects/` 页面是密码保护的：输入简历里写的密码后才显示项目链接。

- 项目链接以 base64 藏在页面脚本里，页面源码中看不到明文链接，爬虫拿不到
- **修改密码 / 添加项目**：编辑 `scripts/gen-portfolio.ps1` 里的 `$Password` 和 `$ProjectsJson`，运行 `powershell -ExecutionPolicy Bypass -File scripts/gen-portfolio.ps1`，把输出的 HASH 和 DATA 粘回 `source/projects/index.md`，然后推送
- 默认示例密码是 `123456`，**上线前一定要改**

> 注意：静态站只能做客户端校验——能挡住爬虫和普通访客，但无法真正加密。如果演示服务器本身容易被攻击，建议同时在服务器侧加访问限制（如 Basic Auth / 白名单 / Cloudflare 防护）。

## 发布

推送到 `master` 分支即可，GitHub Actions 会自动构建并部署：

```bash
git add .
git commit -m "新文章"
git push origin master
```

也可以在仓库 Actions 页面手动触发（workflow_dispatch）。

## 目录结构

- `source/_posts/` —— 文章
- `source/about/`、`source/links/` —— 关于页、友链页
- `source/_data/link.yml` —— 友链数据
- `_config.yml` —— 站点配置
- `_config.tessera.yml` —— 主题配置
- `.github/workflows/pages.yml` —— 部署流水线
