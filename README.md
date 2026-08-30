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
- 参考示例：`source/_posts/` 下的 `周末走走-示例文章.md`、`随便写点-示例文章.md`

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
