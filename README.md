# 拾光集 · 个人 vlog 网站

一个**纯静态**的个人 vlog 站点：Markdown 写内容，Git 存版本，Cloudflare Pages 托管，视频放 Cloudflare R2 或 B 站，评论用 Giscus。

没有数据库、没有后台、没有服务器需要维护。构建一次只要十几毫秒。

---

## 目录结构

```
vlog-site/
├── hugo.toml              ← 全站配置（标题、评论、R2 域名都在这）
├── content/
│   ├── about.md           ← 「关于我」页面
│   └── videos/
│       ├── _index.md      ← 「全部视频」页面的标题
│       └── 2025-03-16-morning-walk.md   ← 每一期 = 一个 .md 文件
├── layouts/               ← 页面模板（不用改，除非你想换版式）
├── assets/css/main.css    ← 全站样式（改颜色只改开头的变量）
├── static/                ← 原样复制到网站根目录的文件
│   ├── covers/            ← 封面图
│   ├── favicon.svg
│   ├── robots.txt
│   └── _headers           ← 安全响应头（Cloudflare Pages 专用）
└── public/                ← 构建产物（自动生成，已忽略）
```

## 本地预览

```bash
cd vlog-site
hugo server
```

打开 <http://localhost:1313>，改文件浏览器会自动刷新。

## 新建一期

在 `content/videos/` 里新建 `2025-04-01-我的标题.md`：

```markdown
---
title: 这期的标题
description: 一句话简介，会显示在卡片和搜索结果里
date: 2025-04-01
cover: /covers/封面图.jpg
duration: '08:32'
location: 杭州
tags: [日常, 旅行]
video:
  type: bilibili      # bilibili | r2 | youtube
  bvid: BV1xx411c7mD
---

正文从这里开始，用 Markdown 写。
```

- `type: bilibili` 只需要填 `bvid`（B 站视频地址里 `/video/` 后面那串）
- `type: r2` 需要填 `src`，例如 `videos/xxx.mp4`（配合 `hugo.toml` 里的 `mediaBase`）
- 想让某期只在本地可见，加一行 `draft: true`

## 发布

推送到 GitHub 的 `main` 分支，Cloudflare Pages 会自动构建并上线，一般 1–2 分钟。

---

完整的手把手操作说明（建仓库、连 Cloudflare、绑域名、配 R2、开评论、加固）见上级目录的 **vlog网站搭建手册.md**。
