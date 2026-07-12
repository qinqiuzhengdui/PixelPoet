# PixelPoet (点豆成金)

这是一个基于大语言模型与极速图像处理算法的自动拼豆图纸生成系统。本项目包含前端交互界面、Node.js 网关以及基于 Moonbit 编写的高性能图像处理核心算法。

## 🔗 项目链接 (Project Links)
*   **GitHub**: [https://github.com/qinqiuzhengdui/PixelPoet](https://github.com/qinqiuzhengdui/PixelPoet)
*   **GitLink**: [https://gitlink.org.cn/aaabbb111/PixelPoet](https://gitlink.org.cn/aaabbb111/PixelPoet)
*   **Mooncakes**: [https://mooncakes.io/docs/PixelPoet/pixelate/](https://mooncakes.io/docs/PixelPoet/pixelate/)

## 🎯 项目目标 (Project Goal)

PixelPoet 旨在为拼豆（Perler Beads）爱好者提供一个全自动的图纸设计工具：
1. **自动像素化与降采样**：将任意输入的图片自动转换为适合拼豆制作的低分辨率像素网格。
2. **颜色量化与调色盘匹配**：采用高效的中位切分（Median Cut）等算法，将图片中的海量颜色压缩量化为拼豆常用的有限颜色集。
3. **精准拼豆数量统计**：自动统计每种颜色所需要的拼豆颗粒数量，列出 Hex/RGB 颜色值并输出清单，指导用户进行物理拼装。
4. **大语言模型创意辅助**：结合大语言模型（如 MiniMax）进行提示词扩展与创意图纸生成，让用户能够通过文字描述直接生成精美的拼豆图纸。

---

## 🛠️ 安装方式 (Installation)

运行本项目前，请确保您的系统已安装以下依赖：
*   [MoonBit CLI](https://www.moonbitlang.cn/download/) (用于编译 `moonbit-core` 为 WASM)
*   [Node.js](https://nodejs.org/) (v16 及以上) & npm

### 1. 克隆代码仓库
```bash
git clone <repository-url>
cd PixelPoet
```

### 2. 初始化与安装依赖
分别进入前端与后端目录安装所需的 Node 依赖：
```bash
# 安装后端依赖
cd node-backend
npm install
cd ..

# 安装前端依赖
cd frontend
npm install
cd ..
```

---

## 🚀 使用方法 (Usage)

本项目分为三个主要部分，建议在三个独立的终端窗口中运行：

### 🏁 第一步：编译 MoonBit 核心算法 (WASM)
我们将 MoonBit 算法代码编译为 WebAssembly 模块，以供 Node.js 后端高性能调用：
```bash
cd moonbit-core
moon build --target wasm
cd ..
```

### 🏁 第二步：启动 Node.js 网关服务
配置大模型 API Key 并启动后端服务（默认运行在 `http://localhost:3000`）：
```bash
cd node-backend

# 配置 MiniMax API Key (此处以 Windows PowerShell 为例，Linux/macOS 请使用 export)
$env:MINIMAX_API_KEY="您的 MiniMax API 密钥"

# 启动服务器
npm start
```

### 🏁 第三步：启动前端开发服务器
```bash
cd frontend
npm run dev
```
启动成功后，在浏览器中打开提示的本地地址（通常为 `http://localhost:5173`）即可使用。

---

## 💡 示例 (Examples)

### 像素拼豆生成流程：
1. **上传图片**：在网页端上传一张您的卡通头像或心仪的插画。
2. **配置参数**：
   * 设置**网格大小 (Block Size)**：例如选择 `8`，表示将每 8x8 的像素块压缩为 1 颗拼豆。网格大小越小，生成的图纸越精细，所需拼豆也越多。
3. **查看效果与清单**：
   * 页面将实时渲染出像素化、颜色量化后的拼豆设计图纸。
   * 下方会自动生成一份**拼豆用料统计表**，详列：颜色色块（如 `#FF0000`）、所需拼豆数量（如 `120` 颗），方便您按图索骥采购原材料。

---

## 🧪 测试集 (Test Suite)

在 `moonbit-core` 中，我们为核心的算法编写了完备的单元测试，包含对颜色空间转换、滤波、图像量化及数据处理等各模块的校验。

### 运行测试命令
在项目根目录或 `moonbit-core` 目录下运行：
```bash
moon test
```

### 测试集覆盖内容
测试用例定义在 `moonbit-core/pixelate` 下的多个 `tests*.mbt` 文件中，覆盖以下核心逻辑：
1. **图像像素化核心** (`test_pixelate`、`test_pixelate_parameters` 等)：验证不同 Block Size 参数下生成的逻辑网格与像素转换正确性。
2. **颜色量化** (`test_median_cut`、`test_find_closest_color`、`test_color_distance`)：测试中位切分颜色量化算法，确保量化后的调色盘能精准匹配源图像。
3. **图像重采样** (`test_resize_nearest`、`test_resize_bilinear`)：测试最近邻与双线性插值缩放，保证图像缩放后边缘轮廓清晰。
4. **图像滤波与抖动** (`test_gaussian_blur`、`test_sobel_filter`、`test_dither`)：测试高斯模糊、Sobel 边缘检测以及抖动处理。
5. **拼豆统计与数据导出** (`test_simulation`、`test_exporter`、`test_vectorize`)：测试拼豆颗粒数量统计与各输出格式（如矢量图/仿真拼图）的准确性。
6. **鲁棒性与性能测试** (`test_invalid_inputs`、`test_empty_image`、`test_large_image`、`test_perf_threshold`)：确保在面对大图、空图像或异常输入时算法不崩溃且满足性能要求。

