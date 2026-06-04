# agy-status-line README Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create a comprehensive README.md file in the root directory of the workspace that documents the functionality, setup, and configuration of the custom `agy` status line script.

**Architecture:** A single Markdown file (`README.md`) containing sections for Overview, Visual Preview, Features, Dependencies, Detailed Setup (for both Windows and Linux/macOS), Debugging, and FAQ.

**Tech Stack:** Markdown

---

### Task 1: Create README.md

**Files:**
- Create: `README.md`

- [ ] **Step 1: Write the README.md content**

Create the file `README.md` in the root of the workspace with the following content:

```markdown
# agy-status-line

一个为 Antigravity CLI (`agy`) 量身定制的、高颜值的自适应终端状态栏脚本。它通过读取并解析 `agy` 传入的实时状态数据，在终端底部渲染出美观、实用的状态行。

## 效果预览

### 宽屏模式（终端宽度 >= 100 字符）
在宽屏模式下，所有状态信息合并在一行内展示，使用 `│` 作为分隔符：
```text
🟢 就绪 │ 🤖 gemini-2.5-pro │ 📁 my-project │ ⎇ main 📝 3 │ ⚡ ████░░░░░░ 120k/1000k (12%) │ 📦 产物 1 │ 🛡️ 安全沙箱
```

### 窄屏模式（终端宽度 < 100 字符）
在窄屏模式下，为防止排版混乱和文本溢出，状态栏会自动换行并折叠为双行展示：
```text
🟢 就绪 │ 🤖 gemini-2.5-pro │ 📁 my-project │ ⎇ main 📝 3
⚡ ████░░░░░░ 120k/1000k (12%) │ 📦 产物 1 │ 🛡️ 安全沙箱
```

## 核心特性

1. **AI 代理状态指示器**
   - 🟢 **就绪** (`idle`)
   - 💭 **思考中** (`thinking`)
   - ⚙️ **工作中** (`working`)
   - 🔧 **调用工具** (`tool_use`)
2. **当前 AI 模型显示 (🤖)**: 实时展示当前会话中正在运行的 LLM 模型名称（例如 `🤖 gemini-2.5-pro`）。
3. **工作区与 Git 状态集成**
   - **工作区目录 (📁)**: 显示当前所在工作区的根目录名称。
   - **Git 分支 (⎇)**: 自动检测当前 Git 分支。若工作区有修改，分支名呈红色；若工作区干净，分支名呈青色。
   - **推送/拉取指标**: 实时计算并展示 `⇡` (待推送 Commit 数) 和 `⇣` (待拉取 Commit 数)。
   - **未提交修改数 (📝)**: 统计当前未提交文件的数量。
4. **Token 上下文用量监控 (⚡)**
   - 使用 10 格进度条（█/░）直观反映上下文窗口的使用占比。
   - 具有根据使用率自动变色的功能：
     - **使用率 < 60%**：绿色 (安全)
     - **使用率 60% ~ 90%**：黄色 (警告)
     - **使用率 >= 90%**：红色 (危险)
   - 旁边附带 `已用Token/总限制`（单位：k）和具体百分比。
5. **安全沙箱状态 (🛡️)**: 当 `agy` 运行在隔离沙箱环境中时，显示 `🛡️ 安全沙箱` 徽章。
6. **动态统计卡片**
   - 📦 **产物**: 显示当前会话已生成的 Artifacts 数量（> 0 时显示）。
   - 👥 **子代理**: 显示当前活跃的 Subagents 数量（> 0 时显示）。
   - ⏳ **任务**: 显示当前在后台运行的任务数量（> 0 时显示）。
7. **自适应布局**: 脚本会根据 CLI 发送的 `terminal_width` 属性自适应单行/双行展示。

## 运行环境要求

本脚本采用多级解析策略，会按顺序寻找并使用以下工具来解析 `agy` 发送的 JSON 数据：
1. `jq` (推荐，性能最佳且解析最精确)
2. `python` (许多 Windows Git Bash 用户预装)
3. `node` (Node.js 环境)
4. 静态保底数据 (当上述工具均不可用时)

> **推荐安装 `jq` 以获得最佳性能**。

## 配置指南

配置此状态栏需要修改 `agy` 的配置文件 `settings.json`。

### 1. 查找配置文件路径
不同操作系统下的配置文件路径如下：
- **Windows**: `C:\Users\<您的用户名>\.gemini\antigravity-cli\settings.json` (或 `%USERPROFILE%\.gemini\antigravity-cli\settings.json`)
- **Linux / macOS**: `~/.gemini/antigravity-cli/settings.json`

如果该文件或其所在的文件夹不存在，请先行创建。

### 2. 详细配置步骤

#### 选项 A：Windows (使用 Git Bash 或 MSYS2 终端)
在 Windows 环境下，由于需要调用 Bash 执行 `.sh` 脚本，需要在 `settings.json` 的 `command` 字段中显式指明 `bash`。

1. 打开 `settings.json`。
2. 添加或更新 `"statusLine"` 部分，将路径指向你的 `statusline.sh` 脚本所在的**绝对路径**（注意使用正斜杠 `/`）：
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "bash D:/workspace/agy-status-line/statusline.sh"
     }
   }
   ```

#### 选项 B：Linux / macOS
1. 为脚本添加可执行权限：
   ```bash
   chmod +x /path/to/statusline.sh
   ```
2. 打开 `settings.json`。
3. 添加或更新 `"statusLine"` 块，填写脚本的绝对路径：
   ```json
   {
     "statusLine": {
       "type": "command",
       "command": "/path/to/statusline.sh"
     }
   }
   ```

---

## 调试与测试

### Payload 缓存与手动调试
每次状态栏被调用时，它都会自动将 `agy` 传入的 JSON 数据备份到：
`~/.gemini/antigravity-cli/last_payload.json` (Windows 对应 `%USERPROFILE%\.gemini\antigravity-cli\last_payload.json`)

你可以直接通过以下命令管道模拟 `agy` 的输出并运行脚本，以便进行脚本的本地修改和调试：

```bash
# Linux/macOS/Git Bash
cat ~/.gemini/antigravity-cli/last_payload.json | bash /path/to/statusline.sh
```

### 常见问题 (FAQ)

**Q: 终端中没有显示状态栏或者报错？**
1. 检查 `settings.json` 中的语法是否正确，括号是否闭合，JSON 的逗号是否有多余。
2. 确保在 `command` 字段中指向的是 `statusline.sh` 的正确绝对路径。
3. 在 Linux/macOS 下，确保你已经执行了 `chmod +x`。

**Q: 乱码或者进度条显示不正常？**
- 确保你的终端编码设置为了 `UTF-8`。对于 Windows Git Bash，可以在右键 Options -> Text -> Character set 中将其设置为 `UTF-8`。
- 本脚本大量使用了 Emoji 和 Unicode 字符（如 `█` 和 `░`），需要终端字体本身支持这些字符。

**Q: 为什么 Git 分支状态没有更新？**
- 本脚本会尝试自动获取工作区的 Git 状态。如果在非 Git 目录中，或者 Git 检测出现异常，它会隐藏 Git 分支信息。
```

- [ ] **Step 2: Verify file existence and readability**

Run: `ls README.md`
Expected: README.md exists.

Run: `git diff README.md`
Expected: Diff shows the added README.md content.

- [ ] **Step 3: Commit README.md to git**

Run:
```bash
git add README.md
git commit -m "docs: add README.md with features and configuration instructions"
```
Expected: Commit succeeds.
