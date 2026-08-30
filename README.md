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

在 `source/_posts/` 下新建 Markdown 文件，必须带 front-matter：

```markdown
---
title: 文章标题
date: 2026-08-30 12:00:00
categories:
  - 前端
tags:
  - React
---
```

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
