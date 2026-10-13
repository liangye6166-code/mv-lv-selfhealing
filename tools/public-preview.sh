#!/usr/bin/env bash
# 把 index.html 通过 Cloudflare 快速隧道（免登录）发布到公网。
#   用法：bash tools/public-preview.sh
#   说明：隧道地址是随机生成的，进程结束后失效；重跑会换一个新地址。
#        需要固定域名请改用 Cloudflare 命名隧道（需登录账号）。
#
#   想让它常驻（不随终端 / 会话结束而失效）：
#     setsid nohup bash tools/public-preview.sh >/tmp/petal-preview.log 2>&1 < /dev/null &
#     grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' /tmp/petal-preview-tunnel.log | head -1
#   找回当前地址：grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' /tmp/petal-preview-tunnel.log | tail -1
#   关闭：pkill -f 'cloudflared tunnel'; pkill -f 'http.server 8099'
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PORT="${PORT:-8099}"
BIN="${CLOUDFLARED:-cloudflared}"

if ! command -v "$BIN" >/dev/null 2>&1; then
  echo "未找到 cloudflared，安装说明：https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/install-and-setup/installation/"
  exit 1
fi

# 只暴露页面本身：站点根目录里只放一个指向 index.html 的符号链接（.git 等不会被发布）
mkdir -p "$ROOT/.public"
ln -sf ../index.html "$ROOT/.public/index.html"

if ! pgrep -f "http[.]server $PORT" >/dev/null 2>&1; then
  (cd "$ROOT" && setsid nohup python3 -m http.server "$PORT" --bind 127.0.0.1 \
     --directory "$ROOT/.public" >/tmp/petal-preview-http.log 2>&1 &)
  sleep 2
fi

echo "本地站点： http://127.0.0.1:$PORT/  （直接读磁盘上的 index.html，改完刷新即可）"
echo "正在建立公网隧道，地址形如 https://xxx.trycloudflare.com ："
echo "（地址同时写入 /tmp/petal-preview-tunnel.log，随时可用 grep 找回）"
"$BIN" tunnel --no-autoupdate --protocol http2 --url "http://127.0.0.1:$PORT" 2>&1 \
  | tee -a /tmp/petal-preview-tunnel.log
