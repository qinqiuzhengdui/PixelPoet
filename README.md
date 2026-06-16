# PixelPoet (点豆成金) - 全栈重构版

这是一个基于大语言模型与图像处理的自动拼豆图纸生成系统。目前项目已重构为一个包含前端、Node.js 网关以及 Moonbit 核心算法的完整代码库。原本笨重的 Java Spring Boot 后端现已被拆分，大幅提升了计算性能和轻量化程度。

## 项目结构

*   `frontend/`：基于 Vue 3 + Vite 构建的用户交互界面。
*   `node-backend/`：Express.js 轻量级网关，主要职责是保护大模型 API Key、调用生成接口，以及加载 WASM 模块处理图像。
*   `moonbit-core/`：使用 **Moonbit** 编写的极速图像处理核心算法（包含中位切分颜色量化、像素网格化等），会被编译为 WebAssembly 供 Node 后端调用。

## 如何运行本项目

本项目分为三个主要模块，建议您打开三个不同的终端窗口分别运行：

### 1. 编译 Moonbit 核心算法 (WASM)

我们需要先把 Moonbit 算法代码编译为 WebAssembly，以便后端能够加载并使用它进行极速图像计算。
```powershell
cd moonbit-core
moon build --target wasm
cd ..
```

### 2. 启动 Node.js 网关服务

Node 后端负责连接大语言模型并加载上面编译出的 WASM 模块。
```powershell
cd node-backend
npm install

# 设置您的 MiniMax API 密钥（此处以 Windows PowerShell 为例）
$env:MINIMAX_API_KEY="您的key"

# 启动服务器（默认运行在 http://localhost:3000 ）
npm start
```

### 3. 启动前端页面

前端是基于 Vite 的轻量化项目，会自动向 Node.js 提供的 `http://localhost:3000` 端口发送请求。
```powershell
# 在新的终端窗口中运行：
cd frontend
npm install

# 启动前端本地开发服务器
npm run dev
```

当看到 `VITE v5.x.x ready` 的提示后，按住 `Ctrl` 键点击终端里输出的本地地址（通常是 `http://localhost:5173`），即可在浏览器中开始使用 PixelPoet！
