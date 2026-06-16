# 点豆成金 - Moonbit + Node.js 重构版

该目录包含了“点豆成金”后端的 Moonbit 与 Node.js 重构版本。原本笨重的 Java Spring Boot 后端现已被拆分为以下两个部分：

## 1. Moonbit 核心算法 (`moonbit-core/`)

在这个目录中，我们将原来由 Java 承担的繁重的 CPU 计算任务（图像 Median Cut 中位切分、像素网格化、颜色统计等）转移到了 **Moonbit** 中。
Moonbit 会被编译为 WebAssembly (WASM) 模块，这能极大地提升图像处理的性能。

*   `median_cut.mbt`: 实现了 Heckbert 中位切分颜色量化算法，用于提取图像的核心颜色（限制在128色以内）。
*   `pixelate.mbt`: 将像素进行最近邻采样，计算逻辑网格，并生成最终的拼豆颜色统计数据。

**如何编译：**
如果您安装了 Moonbit CLI，可以在该目录下运行：
```bash
moon build --target wasm
```

## 2. Node.js 轻量级网关 (`node-backend/`)

这是一个轻量级的 Express.js 后端，用于取代 Java 的 `Controller` 和 `Service`。它的主要职责是：
1. 保护 MiniMax API Key 不被前端泄露。
2. 调用 MiniMax 的 API 接口生成原画/动漫图。
3. 加载 Moonbit 编译的 WASM 模块 (`moonbit_core.wasm`) 进行极速图像处理。
4. 将处理好的数据返回给前端。

**如何运行：**
```bash
cd node-backend
npm install
# 设置您的 MiniMax API 密钥环境变量
export MINIMAX_API_KEY="您的key"
# 启动服务器
npm start
```

## 3. 前端修改建议
原有的 Vue 3 前端几乎不需要修改，您只需要将 API 调用的地址从原来的 Java 端口（如 `http://localhost:8080`）修改为 Node.js 端口（默认 `http://localhost:3000`）即可。

修改点示例 (`src/api/index.js` 或类似文件)：
```javascript
// 原来的 Java 后端
// const baseURL = 'http://localhost:8080';

// 新的 Node.js 后端
const baseURL = 'http://localhost:3000';
```
