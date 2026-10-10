#!/usr/bin/env bash
# 一键把本仓库推到 GitHub（主干 + 备份分支 + 全部标签）；可选先调 API 建仓库。
#
# 用法：
#   # ① 仓库已在 GitHub 上建好（空仓库即可）——直接推送
#   tools/push-to-github.sh git@github.com:<user>/<repo>.git
#   tools/push-to-github.sh https://<user>:<TOKEN>@github.com/<user>/<repo>.git
#
#   # ② 连仓库都没有——给一个 Token，脚本替你建（私有仓库）
#   tools/push-to-github.sh --create <user>/<repo> <TOKEN> [public]
#
# 说明：本机没有保存任何 GitHub 凭据；Token 只在本条命令里用一次，不落盘。
set -euo pipefail
cd "$(dirname "$0")/.."

TOKEN_HEADER=""
if [ "${1:-}" = "--create" ]; then
  REPO="${2:-}"; TOKEN="${3:-}"; VIS="${4:-private}"
  [ -n "$REPO" ] && [ -n "$TOKEN" ] || { echo "用法：tools/push-to-github.sh --create <user>/<repo> <TOKEN> [public]" >&2; exit 1; }
  echo "· 通过 GitHub API 创建仓库 $REPO（$VIS）"
  code=$(curl -s -o /tmp/gh-create.json -w '%{http_code}' -X POST https://api.github.com/user/repos \
    -H "Authorization: Bearer $TOKEN" -H 'Accept: application/vnd.github+json' \
    -d "{\"name\":\"${REPO#*/}\",\"description\":\"双花瓣配电网 · 仿真工作台（中压自愈过程演示底座）\",\"private\":$([ "$VIS" = public ] && echo false || echo true)}")
  if [ "$code" = "201" ]; then echo "  已创建"; else echo "  API 返回 $code（多为仓库已存在，继续用已有仓库）"; fi
  URL="https://${TOKEN}@github.com/${REPO}.git"
else
  URL="${1:-}"
fi

if [ -z "$URL" ]; then
  echo "用法：tools/push-to-github.sh <仓库地址>" >&2
  echo "  例：tools/push-to-github.sh git@github.com:me/double-petal-grid.git" >&2
  echo "  例：tools/push-to-github.sh --create me/double-petal-grid <TOKEN>" >&2
  exit 1
fi
case "$URL" in
  *github.com*) : ;;
  *) echo "警告：$URL 看起来不是 github.com 地址，继续尝试推送…" >&2 ;;
esac

# 推送时静默掉 URL 里的 Token，避免回显泄漏
SAFE=$(printf '%s' "$URL" | sed -E 's#(https://)[^@]*@#\1***@#')
if git remote get-url origin >/dev/null 2>&1; then
  echo "· 更新 origin → $SAFE"; git remote set-url origin "$URL"
else
  echo "· 添加 origin → $SAFE"; git remote add origin "$URL"
fi

echo "· 推送主干 main";            git push -u origin main
echo "· 推送全部备份 / 特性分支";  git push origin --all
echo "· 推送全部标签（含 v*）";    git push origin --tags

echo
echo "完成。远端分支与标签："
git ls-remote --heads --tags origin | sed -E 's#(https://)[^@]*@#\1***@#' | sed 's/^/  /'
