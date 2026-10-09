#!/usr/bin/env bash
# 一键把本仓库推到 GitHub（主干 + 备份分支 + 全部标签）
#
# 用法：
#   tools/push-to-github.sh git@github.com:<user>/<repo>.git
#   tools/push-to-github.sh https://<token>@github.com/<user>/<repo>.git
#
# 说明：本机没有 GitHub 凭据，脚本只负责配置远端并推送，不做认证代理。
set -euo pipefail
cd "$(dirname "$0")/.."

URL="${1:-}"
if [ -z "$URL" ]; then
  echo "用法：tools/push-to-github.sh <仓库地址>" >&2
  echo "  例：tools/push-to-github.sh git@github.com:me/double-petal-grid.git" >&2
  exit 1
fi

if git remote get-url origin >/dev/null 2>&1; then
  echo "· 更新 origin → $URL"
  git remote set-url origin "$URL"
else
  echo "· 添加 origin → $URL"
  git remote add origin "$URL"
fi

echo "· 推送主干 main"
git push -u origin main

echo "· 推送全部备份 / 特性分支"
git push origin --all

echo "· 推送全部标签（含 backup/* 与 v*）"
git push origin --tags

echo
echo "完成。远端分支与标签："
git ls-remote --heads --tags origin | sed 's/^/  /'
