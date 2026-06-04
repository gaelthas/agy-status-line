# Design Specification: agy-status-line README

This document outlines the design, structure, and contents for the `README.md` file of the `agy-status-line` repository.

## 1. Requirements

The README needs to describe:
- The features and functionality of the custom status line script (`statusline.sh`).
- How the script parses data and responds to different CLI events.
- Configuration steps for different operating systems (Windows Git Bash, Linux/macOS).
- Troubleshooting and debugging steps.

## 2. Document Structure

The `README.md` will be structured in Chinese as follows:

1. **项目标题与简介 (Title and Introduction)**: A clean title with a brief explanation of what `agy-status-line` is.
2. **效果预览 (Visual Preview)**: ANSI code colored terminal representation in code blocks simulating the widescreen (single-line) and narrow-screen (two-line) layout.
3. **核心特性 (Core Features)**:
   - **状态指示器 (Agent States)**: Mapping to Emoji badges.
   - **AI 模型显示 (AI Model Badge)**: Which model is in use.
   - **Git & 工作区监控 (Git & Workspace details)**: Real-time Git branches, uncommitted files, and ahead/behind counts.
   - **Token 上下文用量条 (Token Context Progress Bar)**: Dynamic colors matching utilization.
   - **数据统计卡片 (Metrics Cards)**: Active subagents, background tasks, and artifact counts.
   - **沙箱标识 (Sandbox indicator)**.
4. **运行环境要求 (Environment Prerequisites)**: Mentioning dependencies like `jq`, `python`, `node` and how the script fallbacks gracefully.
5. **配置指南 (Configuration Guide)**:
   - Configuration file path (`settings.json`).
   - Windows (Git Bash) configuration details.
   - Linux / macOS configuration details.
6. **调试与测试 (Debugging & Testing)**:
   - How `last_payload.json` works.
   - Troubleshooting tips for path escaping, executable permissions, and encoding.

## 3. Implementation Details

We will create `README.md` in the root of the workspace.

- File path: `D:/workspace/agy-status-line/README.md`
