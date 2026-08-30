---
title: 记录一次 pdfjs-dist 实现 PDF 文件自动翻页
date: 2026-08-30 11:30:00
categories:
  - 技术
tags:
  - React
  - PDF
  - pdfjs-dist
---

# 记录一次使用 pdfjs-dist 实现 PDF 自动翻页
>  *⚠️本文由chatgpt进行语言优化与总结*

最近公司项目临近交付，突然又被客户提了一个新需求：

> PDF 不仅要预览，还要实现自动翻页轮播。

其实一开始项目对 PDF 的需求非常简单，客户只要求**展示 PDF 的第一页**，所以之前直接使用了：

```bash
@cyntler/react-doc-viewer
```

代码大概就是通过 `DocViewer` 来实现普通的 PDF 预览。

但是项目临近交付的时候，需求突然变了：

> “能不能让 PDF 像 PPT 一样自动轮播？”

于是开始重新找方案，最后选择使用 `pdfjs-dist` 自己实现 PDF 渲染和自动翻页。

过程中也踩了几个坑，尤其是 **Worker 文件、版本匹配、PDF 加载失败、高清屏渲染以及组件销毁后的定时器问题**。

这里记录一下，方便以后再使用 `pdfjs-dist` 的时候直接参考。

---

## 一、为什么没有继续使用 `react-doc-viewer`

之前使用 `@cyntler/react-doc-viewer` 主要是因为需求比较简单：

- 能打开 PDF
- 能预览 PDF
- 只需要展示第一页

这种场景下直接使用现成组件确实非常方便。

但是现在需求变成了：

- PDF 自动翻页
- 自定义翻页间隔
- PDF 完整适应容器
- 高清屏显示
- 支持多个 PDF
- PDF 加载失败处理
- 组件销毁时清理资源

这时候继续基于现成的 PDF Viewer 做定制就比较麻烦了。

所以最后决定直接使用 `pdfjs-dist`，自己控制 PDF 的加载、渲染和翻页逻辑。

---

# 二、安装 pdfjs-dist

公司的项目比较老，所以没有直接安装最新版，而是指定了一个比较稳定的版本：

```bash
yarn add pdfjs-dist@3.11.174
```

这里需要特别注意：

> **pdfjs-dist 的版本一定要和 Worker 文件版本保持一致。**

这也是这次踩坑比较重要的一点。

---

# 三、PDF.js 的 Worker 是干什么的？

第一次使用 `pdfjs-dist` 的时候，很容易遇到这样的报错：

```text
Deprecated API usage: No "GlobalWorkerOptions.workerSrc" specified.
```

然后 PDF.js 可能会尝试使用：

```text
Setting up fake worker
```

甚至最终出现：

```text
Uncaught SyntaxError
```

这是因为 PDF.js 本身会使用 Web Worker 来处理 PDF 的解析和相关计算。

简单理解就是：

```text
浏览器主线程
     │
     │ PDF 页面渲染
     ↓
PDF.js
     │
     │ Worker
     ↓
pdf.worker.min.js
```

所以我们需要告诉 `pdfjs-dist`：

> Worker 文件到底在哪里。

---

# 四、Worker 文件放在哪里？

我这里使用的是比较简单的一种方案。

首先在：

```text
node_modules/pdfjs-dist/
```

里面找到：

```text
pdf.worker.min.js
```

然后把它复制到项目的：

```text
public/
```

目录下。

例如：

```text
项目
├── public
│   └── pdf.worker.min.js
├── src
│   ├── pages
│   └── ...
├── package.json
└── ...
```

如果项目部署的时候有项目上下文路径，例如：

```text
/GinsengBase/
```

那么最终访问地址就是：

```text
/GinsengBase/pdf.worker.min.js
```

代码中配置：

```ts
import * as pdfjsLib from 'pdfjs-dist';

pdfjsLib.GlobalWorkerOptions.workerSrc =
  '/GinsengBase/pdf.worker.min.js';
```

### 这里有一个容易踩的坑

`public` 目录中的文件，在项目运行和打包之后通常会直接映射到网站根路径。

所以：

```text
public/pdf.worker.min.js
```

并不是写成：

```text
/public/pdf.worker.min.js
```

而是：

```text
/pdf.worker.min.js
```

如果项目部署在：

```text
/GinsengBase/
```

那么就是：

```text
/GinsengBase/pdf.worker.min.js
```

所以这里一定要根据项目实际的 `publicPath` / 部署路径来配置。

---

# 五、最终实现思路

整个 PDF 自动翻页的实现其实并不复杂，可以拆成几个步骤：

```text
获取 PDF URL
    ↓
pdfjsLib.getDocument()
    ↓
获取 PDF 对象
    ↓
获取 PDF 总页数
    ↓
renderPage(1)
    ↓
Canvas 渲染第一页
    ↓
页面渲染完成
    ↓
启动 setTimeout
    ↓
等待指定时间
    ↓
currentPage + 1
    ↓
renderPage(下一页)
    ↓
循环
```

这里有一个比较重要的设计：

> **不是设置一个固定的 setInterval，而是在当前页面渲染完成之后，再启动下一次计时。**

这样可以避免 PDF 页面还没有渲染完成，下一页就开始加载的问题。

---

# 六、完整代码

下面就是最终实现的 `PdfAutoViewer.tsx`：

```tsx
import React from 'react'
import * as pdfjsLib from 'pdfjs-dist'

pdfjsLib.GlobalWorkerOptions.workerSrc =
  '/GinsengBase/pdf.worker.min.js'

import './auto.less'

interface Props {
  url: string
  width?: number | string
  height?: number | string
  interval?: number
  autoPlay?: boolean
}

interface State {
  loading: boolean
  error: boolean
  currentPage: number
  totalPages: number
}

class PdfAutoViewer extends React.Component<Props, State> {
  canvasRef = React.createRef<HTMLCanvasElement>()

  pdf: any = null

  timer: any = null

  destroyed = false

  state: State = {
    loading: true,
    error: false,
    currentPage: 1,
    totalPages: 0,
  }

  componentDidMount() {
    this.loadPdf()
  }

  componentWillUnmount() {
    this.destroyed = true

    if (this.timer) {
      clearTimeout(this.timer)
      this.timer = null
    }

    if (this.pdf) {
      this.pdf.destroy()
      this.pdf = null
    }
  }

  componentDidUpdate(prevProps: Props) {
    if (prevProps.url !== this.props.url) {
      this.reset()
      this.loadPdf()
    }
  }

  reset = () => {
    if (this.timer) {
      clearTimeout(this.timer)
      this.timer = null
    }

    if (this.pdf) {
      this.pdf.destroy()
      this.pdf = null
    }

    this.setState({
      loading: true,
      error: false,
      currentPage: 1,
      totalPages: 0,
    })
  }

  loadPdf = async () => {
    const { url } = this.props

    console.log('PDF URL:', url)

    if (!url) {
      console.error('PDF URL为空')
      return
    }

    try {
      this.setState({
        loading: true,
        error: false,
      })

      const loadingTask = pdfjsLib.getDocument({
        url,

        // 当前项目采用关闭 Worker 的方式
        disableWorker: true,
      })

      loadingTask.onProgress = (progress: any) => {
        console.log('PDF加载进度:', progress)
      }

      const pdf = await loadingTask.promise

      this.pdf = pdf

      this.setState(
        {
          loading: false,
          totalPages: pdf.numPages,
          currentPage: 1,
        },
        () => {
          this.renderPage(1)
        },
      )
    } catch (error: any) {
      this.setState({
        loading: false,
        error: true,
      })
    }
  }

  renderPage = async (pageNumber: number) => {
    if (!this.pdf || this.destroyed) {
      return
    }

    try {
      const page = await this.pdf.getPage(pageNumber)

      if (this.destroyed) {
        return
      }

      const canvas = this.canvasRef.current

      if (!canvas) {
        return
      }

      const context = canvas.getContext('2d')

      if (!context) {
        return
      }

      /**
       * PDF 原始尺寸
       */
      const viewport = page.getViewport({
        scale: 1,
      })

      /**
       * 获取容器尺寸
       */
      const container = canvas.parentElement

      if (!container) {
        return
      }

      const containerWidth = container.clientWidth
      const containerHeight = container.clientHeight

      /**
       * 根据容器计算缩放比例
       *
       * 保证 PDF 完整显示
       */
      const scaleX = containerWidth / viewport.width
      const scaleY = containerHeight / viewport.height

      const scale = Math.min(scaleX, scaleY)

      const scaledViewport = page.getViewport({
        scale,
      })

      /**
       * 高清屏
       */
      const dpr = window.devicePixelRatio || 1

      canvas.width = Math.floor(
        scaledViewport.width * dpr,
      )

      canvas.height = Math.floor(
        scaledViewport.height * dpr,
      )

      canvas.style.width =
        `${scaledViewport.width}px`

      canvas.style.height =
        `${scaledViewport.height}px`

      context.setTransform(
        dpr,
        0,
        0,
        dpr,
        0,
        0,
      )

      context.clearRect(
        0,
        0,
        scaledViewport.width,
        scaledViewport.height,
      )

      await page.render({
        canvasContext: context,
        viewport: scaledViewport,
      }).promise

      /**
       * 当前页渲染完成后才开始计时
       *
       * 避免：
       *
       * 第1页还没加载完
       * ↓
       * 第2页又开始加载
       * ↓
       * 页面闪烁
       */
      this.startNextPageTimer()
    } catch (error) {
      console.error(
        `PDF第${pageNumber}页渲染失败:`,
        error,
      )
    }
  }

  startNextPageTimer = () => {
    if (this.timer) {
      clearTimeout(this.timer)
    }

    const {
      interval = 5000,
      autoPlay = true,
    } = this.props

    if (
      !autoPlay ||
      this.state.totalPages <= 1
    ) {
      return
    }

    this.timer = setTimeout(() => {
      if (this.destroyed) {
        return
      }

      this.setState(
        (prevState) => {
          let nextPage =
            prevState.currentPage + 1

          /**
           * 最后一页之后回到第一页
           */
          if (
            nextPage >
            prevState.totalPages
          ) {
            nextPage = 1
          }

          return {
            currentPage: nextPage,
          }
        },
        () => {
          this.renderPage(
            this.state.currentPage,
          )
        },
      )
    }, interval)
  }

  render() {
    const {
      width = '100%',
      height = 400,
    } = this.props

    const {
      loading,
      error,
    } = this.state

    return (
      <div
        className="pdf-auto-viewer"
        style={{
          width,
          height,
        }}
      >
        {loading && (
          <div className="pdf-loading">
            PDF加载中...
          </div>
        )}

        {error && (
          <div className="pdf-error">
            PDF加载失败
          </div>
        )}

        <canvas
          ref={this.canvasRef}
          className="pdf-canvas"
        />
      </div>
    )
  }
}

export default PdfAutoViewer
```

---

# 七、几个比较重要的实现细节

## 1. 为什么使用 `canvas`？

`pdfjs-dist` 本身提供了 PDF 页面渲染能力，我们可以直接获取 PDF 的某一页：

```ts
const page = await this.pdf.getPage(pageNumber)
```

然后通过：

```ts
page.render({
  canvasContext: context,
  viewport,
})
```

将 PDF 页面绘制到 Canvas。

所以整个组件实际上是：

```text
PDF
 ↓
PDF.js
 ↓
Page
 ↓
Canvas
```

我们只需要不断改变：

```ts
pageNumber
```

就可以实现 PDF 翻页。

---

## 2. 为什么使用 `Math.min()`？

这里是整个自适应显示的核心：

```ts
const scaleX =
  containerWidth / viewport.width

const scaleY =
  containerHeight / viewport.height

const scale = Math.min(
  scaleX,
  scaleY,
)
```

假设 PDF 原始尺寸是：

```text
800 × 1200
```

容器尺寸：

```text
1000 × 600
```

那么：

```text
scaleX = 1000 / 800 = 1.25

scaleY = 600 / 1200 = 0.5
```

最终：

```ts
scale = Math.min(1.25, 0.5)
      = 0.5
```

这样 PDF 会按照高度缩放，保证整个 PDF 都能显示出来，而不会被容器裁剪。

也就是说：

> **宽、高两个方向分别计算缩放比例，最终取较小值。**

这就是常见的 `contain` 思路。

---

# 八、为什么要处理 devicePixelRatio？

如果直接：

```ts
canvas.width = scaledViewport.width
canvas.height = scaledViewport.height
```

在一些高清屏上可能会发现 PDF 有点模糊。

例如：

```text
普通屏幕
devicePixelRatio = 1

Retina / 高清屏
devicePixelRatio = 2
```

所以这里使用：

```ts
const dpr =
  window.devicePixelRatio || 1
```

然后让 Canvas 实际绘制尺寸变成：

```ts
canvas.width =
  scaledViewport.width * dpr

canvas.height =
  scaledViewport.height * dpr
```

但是 CSS 显示尺寸仍然保持原来的大小：

```ts
canvas.style.width =
  `${scaledViewport.width}px`

canvas.style.height =
  `${scaledViewport.height}px`
```

最后通过：

```ts
context.setTransform(
  dpr,
  0,
  0,
  dpr,
  0,
  0,
)
```

来解决高清屏下的模糊问题。

简单来说：

```text
Canvas实际绘制尺寸
        ↓
       × DPR
        ↓
   提高实际像素数量
        ↓
CSS显示尺寸保持不变
        ↓
      更清晰
```

---

# 九、为什么使用 setTimeout，而不是 setInterval？

这里也是这次实现中我觉得比较值得记录的一点。

很多人第一反应可能是：

```ts
setInterval(() => {
  renderPage(nextPage)
}, 5000)
```

但是这样存在一个问题。

假设：

```text
第1页渲染需要 3 秒
```

然后：

```text
setInterval = 5 秒
```

那么程序实际上可能变成：

```text
0s
↓
开始渲染第1页

3s
↓
第1页渲染完成

5s
↓
开始渲染第2页
```

如果某一页因为网络、PDF 内容复杂等原因渲染时间比较长，就可能出现多个渲染任务重叠。

所以我这里使用：

```ts
await page.render(...).promise
```

等当前页面真正渲染完成之后：

```ts
this.startNextPageTimer()
```

然后再：

```ts
setTimeout(...)
```

也就是：

```text
开始渲染第1页
       ↓
第1页渲染完成
       ↓
等待5秒
       ↓
开始渲染第2页
       ↓
第2页渲染完成
       ↓
等待5秒
       ↓
开始渲染第3页
```

这种方式会更加稳定。

---

# 十、组件销毁时为什么一定要清理？

React 组件如果已经销毁，但是定时器还在运行，就可能继续执行：

```ts
this.setState(...)
```

或者继续执行：

```ts
this.renderPage(...)
```

所以在：

```ts
componentWillUnmount()
```

中需要清理定时器：

```ts
if (this.timer) {
  clearTimeout(this.timer)
  this.timer = null
}
```

同时销毁 PDF：

```ts
if (this.pdf) {
  this.pdf.destroy()
  this.pdf = null
}
```

并通过：

```ts
this.destroyed = true
```

防止异步任务继续操作已经销毁的组件。

例如：

```ts
if (this.destroyed) {
  return
}
```

这样可以避免一些比较隐蔽的异步问题。

---

# 十一、还有一个比较特殊的地方：Worker 和 disableWorker

这里可能会有人发现一个问题：

前面明明配置了：

```ts
pdfjsLib.GlobalWorkerOptions.workerSrc =
  '/GinsengBase/pdf.worker.min.js'
```

但是 `getDocument()` 里面又写了：

```ts
disableWorker: true
```

这其实是因为我当时项目部署环境比较特殊，在实际调试过程中遇到了 Worker 加载相关问题。

如果设置：

```ts
disableWorker: true
```

那么 PDF.js 会关闭 Worker，PDF 解析会直接在主线程执行。

也就是说：

```text
正常情况：

主线程
  │
  └── PDF.js Worker
          ↓
       PDF解析
```

关闭 Worker：

```text
主线程
  │
  └── PDF.js
       ↓
     PDF解析
```

所以这两种配置实际上是有点“矛盾”的：

```ts
GlobalWorkerOptions.workerSrc = ...
```

负责指定 Worker。

而：

```ts
disableWorker: true
```

则直接禁用 Worker。

### 如果项目 Worker 可以正常加载

更推荐：

```ts
pdfjsLib.GlobalWorkerOptions.workerSrc =
  '/GinsengBase/pdf.worker.min.js'

const loadingTask = pdfjsLib.getDocument({
  url,
})
```

也就是**不要再设置 `disableWorker: true`**。

这样可以让 PDF 解析放到 Worker 中，避免大量 PDF 解析工作阻塞浏览器主线程。

---

# 十二、最终效果

最终这个组件支持：

```tsx
<PdfAutoViewer
  url={pdfUrl}
  width="100%"
  height={600}
  interval={5000}
  autoPlay={true}
/>
```

其中：

| 参数 | 作用 | 默认值 |
| --- | --- | --- |
| `url` | PDF 地址 | 必填 |
| `width` | 容器宽度 | `100%` |
| `height` | 容器高度 | `400` |
| `interval` | 自动翻页间隔，单位 ms | `5000` |
| `autoPlay` | 是否自动播放 | `true` |

例如：

```tsx
<PdfAutoViewer
  url={pdfUrl}
  width="100%"
  height={500}
  interval={3000}
  autoPlay
/>
```

表示：

> PDF 每一页渲染完成后等待 3 秒，然后自动切换到下一页，最后一页播放完成之后重新回到第一页。

---

# 十三、这次踩坑总结

这次看起来只是一个简单的“PDF 自动翻页”，实际上还是踩了几个坑。

### ① `pdfjs-dist` 和 Worker 版本必须对应

安装：

```bash
yarn add pdfjs-dist@3.11.174
```

那么 Worker 也应该使用对应版本的：

```text
pdf.worker.min.js
```

不要随便从网上找一个 Worker 文件过来。

---

### ② Worker 路径一定要确认

例如：

```ts
pdfjsLib.GlobalWorkerOptions.workerSrc =
  '/GinsengBase/pdf.worker.min.js'
```

然后直接在浏览器访问：

```text
http://你的域名/GinsengBase/pdf.worker.min.js
```

确认文件能不能正常访问。

如果访问不到，那么 PDF.js 自然也加载不了 Worker。

---

### ③ `public` 目录不是 URL 的一部分

例如：

```text
public/pdf.worker.min.js
```

访问通常是：

```text
/pdf.worker.min.js
```

而不是：

```text
/public/pdf.worker.min.js
```

如果项目有部署前缀：

```text
/GinsengBase/
```

那么：

```text
/GinsengBase/pdf.worker.min.js
```

---

### ④ 自动翻页最好不要简单使用 setInterval

推荐：

```text
页面渲染完成
    ↓
setTimeout
    ↓
下一页
    ↓
页面渲染完成
    ↓
setTimeout
```

这样可以避免多个 PDF 页面同时进行渲染。

---

### ⑤ 高清屏需要考虑 devicePixelRatio

如果发现 PDF 在电脑上看起来比较模糊，可以考虑：

```ts
const dpr =
  window.devicePixelRatio || 1
```

让 Canvas 实际像素尺寸乘以 DPR。

---

# 十四、最后

这次需求本来只是：

> “PDF 展示第一页。”

最后变成了：

> “PDF 能不能自动轮播？”

然后又一路折腾到了：

```text
react-doc-viewer
       ↓
pdfjs-dist
       ↓
Worker
       ↓
Canvas
       ↓
高清屏 DPR
       ↓
setTimeout 自动翻页
       ↓
组件销毁资源清理
```

虽然过程有点曲折，但是自己实现之后，对 `pdfjs-dist` 的整个工作流程也算是有了更直观的了解。

以后如果再遇到类似：

- PDF 自动轮播
- PDF 大屏展示
- PDF 自定义翻页
- PDF 指定页面渲染
- PDF Canvas 渲染

之类的需求，直接基于 `pdfjs-dist` 自己封装一个组件，应该会比继续魔改现成的 Viewer 方便不少。

**记录一下踩坑过程，也方便以后自己再踩的时候回来看看。**