#!/bin/bash
set -euo pipefail

# ─── ANSI 颜色控制码（使用 $'...' 语法，避免 echo -e 转义风险） ──────────────
R=$'\e[0m'          # 重置所有格式
B=$'\e[1m'          # 粗体/高亮
I=$'\e[3m'          # 斜体

# 标准前景色
FG_RED=$'\e[31m'
FG_GREEN=$'\e[32m'
FG_YELLOW=$'\e[33m'
FG_BLUE=$'\e[34m'
FG_MAGENTA=$'\e[35m'
FG_CYAN=$'\e[36m'

# 亮色前景色
FG_GRAY=$'\e[90m'
FG_BRIGHT_RED=$'\e[91m'
FG_BRIGHT_GREEN=$'\e[92m'
FG_BRIGHT_YELLOW=$'\e[93m'
FG_BRIGHT_BLUE=$'\e[94m'
FG_BRIGHT_MAGENTA=$'\e[95m'
FG_BRIGHT_CYAN=$'\e[96m'
FG_BRIGHT_WHITE=$'\e[97m'

# ─── 读取并备份 stdin 的 JSON 数据 ──────────────────────────────────────────
input=$(cat)

# 使用可移植的 $HOME 路径并确保目录存在
PAYLOAD_DIR="$HOME/.gemini/antigravity-cli"
mkdir -p "$PAYLOAD_DIR"
# 使用 printf 防止 echo 的 option 注入
printf "%s\n" "$input" > "$PAYLOAD_DIR/last_payload.json"

# ─── 多级兼容解析 JSON ──────────────────────────────────────────────────────
parsed_data=""

# 1. 尝试使用 jq 解析
if [ -z "$parsed_data" ] && command -v jq >/dev/null 2>&1; then
  parsed_data=$(printf "%s\n" "$input" | jq -r '
    (.agent_state // "idle"),
    (.context_window.used_percentage // 0 | tonumber | (.*10 | round) / 10),
    (.context_window.used_percentage // 0 | tonumber | floor),
    (.vcs.branch // ""),
    (.vcs.dirty // false),
    (.sandbox.enabled // false),
    (.artifact_count // 0),
    (if .subagents | type == "array" then (.subagents | length) else 0 end),
    (.task_count // 0),
    (if .model | type == "object" then .model.display_name // .model.id else .model end // ""),
    (.terminal_width // 80),
    (.workspace.current_dir // ""),
    (.context_window.total_input_tokens // 0),
    (.context_window.total_output_tokens // 0),
    (.context_window.context_window_size // 1000000)
  ' 2>/dev/null | tr -d '\r') || parsed_data=""
fi

# 2. 尝试使用 python 解析（Windows Git Bash 用户通常装有 Python）
if [ -z "$parsed_data" ] && command -v python >/dev/null 2>&1; then
  parsed_data=$(printf "%s\n" "$input" | python -c '
import sys, json
try:
    d = json.load(sys.stdin)
    cw = d.get("context_window", {})
    up = float(cw.get("used_percentage", 0))
    vcs = d.get("vcs", {})
    sb = d.get("sandbox", {})
    sub = d.get("subagents", 0)
    sub_len = len(sub) if isinstance(sub, list) else 0
    m = d.get("model", "")
    m_name = (m.get("display_name") or m.get("id") or "") if isinstance(m, dict) else str(m)
    ws = d.get("workspace", {})
    print(d.get("agent_state", "idle"))
    print(round(up * 10) / 10)
    print(int(up))
    print(vcs.get("branch", "") if isinstance(vcs, dict) else "")
    print(str(vcs.get("dirty", False)).lower() if isinstance(vcs, dict) else "false")
    print(str(sb.get("enabled", False)).lower() if isinstance(sb, dict) else "false")
    print(d.get("artifact_count", 0))
    print(sub_len)
    print(d.get("task_count", 0))
    print(m_name)
    print(d.get("terminal_width", 80))
    print(ws.get("current_dir", "") if isinstance(ws, dict) else "")
    print(cw.get("total_input_tokens", 0))
    print(cw.get("total_output_tokens", 0))
    print(cw.get("context_window_size", 1000000))
except Exception:
    sys.exit(1)
' 2>/dev/null | tr -d '\r') || parsed_data=""
fi

# 3. 尝试使用 node 解析
if [ -z "$parsed_data" ] && command -v node >/dev/null 2>&1; then
  parsed_data=$(printf "%s\n" "$input" | node -e '
const fs = require("fs");
try {
  const d = JSON.parse(fs.readFileSync(0, "utf-8"));
  const cw = d.context_window || {};
  const up = parseFloat(cw.used_percentage) || 0;
  const vcs = d.vcs || {};
  const sb = d.sandbox || {};
  const sub = d.subagents || 0;
  const sub_len = Array.isArray(sub) ? sub.length : 0;
  const m = d.model || "";
  const m_name = typeof m === "object" ? (m.display_name || m.id || "") : String(m);
  const ws = d.workspace || {};
  
  console.log(d.agent_state || "idle");
  console.log(Math.round(up * 10) / 10);
  console.log(Math.floor(up));
  console.log(vcs.branch || "");
  console.log(String(vcs.dirty || false).toLowerCase());
  console.log(String(sb.enabled || false).toLowerCase());
  console.log(d.artifact_count || 0);
  console.log(sub_len);
  console.log(d.task_count || 0);
  console.log(m_name);
  console.log(d.terminal_width || 80);
  console.log(ws.current_dir || "");
  console.log(cw.total_input_tokens || 0);
  console.log(cw.total_output_tokens || 0);
  console.log(cw.context_window_size || 1000000);
} catch (e) {
  process.exit(1);
}
' 2>/dev/null | tr -d '\r') || parsed_data=""
fi

# 4. 保底静态数据
if [ -z "$parsed_data" ]; then
  parsed_data=$(printf "idle\n0\n0\n\nfalse\nfalse\n0\n0\n0\n\n80\n\n0\n0\n1000000\n")
fi

{
  read -r STATE
  read -r PCT_FMT
  read -r PCT_INT
  read -r VCS_BRANCH
  read -r VCS_DIRTY
  read -r SANDBOX
  read -r ARTIFACTS
  read -r SUBAGENTS
  read -r BG_TASKS
  read -r MODEL
  read -r COLS
  read -r CWD
  read -r INPUT_TOKENS
  read -r OUTPUT_TOKENS
  read -r LIMIT_TOKENS
} <<< "$parsed_data"

# ─── 1. Agent 运行状态（中文） ─────────────────────────────────────────────
case "$STATE" in
  idle)     S="${FG_BRIGHT_GREEN}${B}🟢 就绪${R}" ;;
  thinking) S="${FG_BRIGHT_YELLOW}${B}💭 思考中${R}" ;;
  working)  S="${FG_BRIGHT_CYAN}${B}⚙️ 工作中${R}" ;;
  tool_use) S="${FG_BRIGHT_MAGENTA}${B}🔧 调用工具${R}" ;;
  *)        S="${FG_BRIGHT_WHITE}${B}● $(printf "%s" "$STATE" | tr '[:lower:]' '[:upper:]')${R}" ;;
esac

# ─── 2. 当前 AI 模型 ────────────────────────────────────────────────────────
M=""
if [ -n "$MODEL" ]; then
  M="${FG_BRIGHT_MAGENTA}${B}🤖 ${MODEL}${R}"
fi

# ─── 3. 工作区目录与 Git 分支详情 ───────────────────────────────────────────
DIR_STR=""
if [ -n "$CWD" ]; then
  CWD_CLEAN="${CWD//\\//}"
  DIR_NAME=$(basename "$CWD_CLEAN")
  # 避免某些系统上 basename 空白输出 "."
  if [ -n "$DIR_NAME" ] && [ "$DIR_NAME" != "." ]; then
    DIR_STR="${FG_BRIGHT_BLUE}📁 ${DIR_NAME}${R}"
  fi
fi

# 若 agy 内部 Git 执行失败没有传入分支名，脚本直接尝试在当前目录运行 git 获取
if [ -z "$VCS_BRANCH" ] && [ -n "$CWD" ]; then
  VCS_BRANCH=$(cd "$CWD" 2>/dev/null && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "")
fi

V=""
if [ -n "$VCS_BRANCH" ]; then
  AHEAD=0
  BEHIND=0
  UNCOMMITTED=0
  if [ -n "$CWD" ] && cd "$CWD" 2>/dev/null; then
    # 检查是否有上游分支，若有则计算 ahead/behind
    if git rev-parse --abbrev-ref @{u} >/dev/null 2>&1; then
      AHEAD=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "0")
      BEHIND=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "0")
    fi
    # 计算未提交文件数量。使用 || UNCOMMITTED=0 避免 git status 失败触发 set -e 退出
    UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ') || UNCOMMITTED=0
  fi

  # 拼装分支基本名，若工作区有修改则分支名变红，否则为青色
  V_STR="⎇ ${VCS_BRANCH}"
  if [ "${UNCOMMITTED:-0}" -gt 0 ]; then
    V="${FG_BRIGHT_RED}${V_STR}${R}"
  else
    V="${FG_CYAN}⎇ ${VCS_BRANCH}${R}"
  fi

  # 待推送（ahead）数量展示
  if [ "${AHEAD:-0}" -gt 0 ]; then
    V="${V} ${FG_BRIGHT_GREEN}⇡ ${AHEAD}${R}"
  fi

  # 待拉取（behind）数量展示
  if [ "${BEHIND:-0}" -gt 0 ]; then
    V="${V} ${FG_BRIGHT_RED}⇣ ${BEHIND}${R}"
  fi

  # 未提交修改（uncommitted）数量展示
  if [ "${UNCOMMITTED:-0}" -gt 0 ]; then
    V="${V} ${FG_BRIGHT_YELLOW}📝 ${UNCOMMITTED}${R}"
  fi
fi

# ─── 4. 上下文已用/限制数计算及进度条 ─────────────────────────────────────────────
# 防御性参数扩展：当变量未设置或为空时默认设为 0
used_tokens=$((${INPUT_TOKENS:-0} + ${OUTPUT_TOKENS:-0}))
used_k=$((used_tokens / 1000))
limit_k=$((${LIMIT_TOKENS:-1000000} / 1000))

# 避免 limit_k 为 0 导致后续意外
if [ "$limit_k" -le 0 ]; then
  limit_k=1
fi

pct_val=${PCT_INT:-0}
if [ "$pct_val" -ge 90 ]; then
  PCT_COLOR="$FG_BRIGHT_RED"
elif [ "$pct_val" -ge 60 ]; then
  PCT_COLOR="$FG_BRIGHT_YELLOW"
else
  PCT_COLOR="$FG_BRIGHT_GREEN"
fi

# 生成 10 格的进度条（█ 代表已用，░ 代表空闲）
BAR_LEN=10
FILLED=$((pct_val * BAR_LEN / 100))
if [ "$FILLED" -lt 0 ]; then
  FILLED=0
elif [ "$FILLED" -gt "$BAR_LEN" ]; then
  FILLED="$BAR_LEN"
fi
EMPTY=$((BAR_LEN - FILLED))

BAR=""
for ((i=0; i<FILLED; i++)); do BAR="${BAR}█"; done
for ((i=0; i<EMPTY; i++)); do BAR="${BAR}░"; done

PCT_FMT_VAL=${PCT_FMT:-0}
CTX="${PCT_COLOR}⚡ ${BAR} ${used_k}k/${limit_k}k (${PCT_FMT_VAL}%)${R}"

# ─── 5. 安全沙箱 ─────────────────────────────────────────────────────────────
SB=""
if [ "$SANDBOX" = "true" ]; then
  SB="${FG_BRIGHT_GREEN}🛡️ 安全沙箱${R}"
fi

# ─── 6. 数据统计卡片（使用防御性默认值，防止空变量报错） ──────────────────────────
ART=""
if [ "${ARTIFACTS:-0}" -gt 0 ]; then
  ART="${FG_BRIGHT_CYAN}📦 产物 ${ARTIFACTS}${R}"
fi

SUB=""
if [ "${SUBAGENTS:-0}" -gt 0 ]; then
  SUB="${FG_BRIGHT_MAGENTA}👥 子代理 ${SUBAGENTS}${R}"
fi

BG=""
if [ "${BG_TASKS:-0}" -gt 0 ]; then
  BG="${FG_BRIGHT_YELLOW}⏳ 任务 ${BG_TASKS}${R}"
fi

# ─── 7. 构建和拼装状态栏输出 ──────────────────────────────────────────────────
DIV="${FG_GRAY} │ ${R}"

left_parts=()
[ -n "$S" ] && left_parts+=("$S")
[ -n "$M" ] && left_parts+=("$M")
[ -n "$DIR_STR" ] && left_parts+=("$DIR_STR")
[ -n "$V" ] && left_parts+=("$V")

left_str=""
for i in "${!left_parts[@]}"; do
  if [ "$i" -eq 0 ]; then
    left_str="${left_parts[$i]}"
  else
    left_str="${left_str}${DIV}${left_parts[$i]}"
  fi
done

right_parts=()
[ -n "$CTX" ] && right_parts+=("$CTX")
[ -n "$ART" ] && right_parts+=("$ART")
[ -n "$SUB" ] && right_parts+=("$SUB")
[ -n "$BG" ] && right_parts+=("$BG")
[ -n "$SB" ] && right_parts+=("$SB")

right_str=""
for i in "${!right_parts[@]}"; do
  if [ "$i" -eq 0 ]; then
    right_str="${right_parts[$i]}"
  else
    right_str="${right_str}${DIV}${right_parts[$i]}"
  fi
done

# 使用普通 echo（不再需要 -e 选项，完美避免对路径中反斜杠的二次转义破坏）
COLS_VAL=${COLS:-80}
if [ "$COLS_VAL" -ge 100 ]; then
  echo "${left_str}${DIV}${right_str}"
else
  echo "${left_str}"
  echo "${right_str}"
fi
