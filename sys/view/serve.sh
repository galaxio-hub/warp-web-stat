#!/usr/bin/env sh
# 从 sys/ 根启动本地静态服务，同时提供「展示页」和「引擎输出文件」。
#
#   sh sys/view/serve.sh [端口]      # 默认 8123
#   浏览器打开：http://localhost:8123/view/
#
# 页面会自动依次尝试两种模块布局下的数据文件（gops ≥1.3.5 的新布局在前）：
#   sys/<model>/mods/<mod>/local/data/alerts/nginx.ndjson     （新）
#   sys/mods/<mod>/<model>/local/data/alerts/nginx.ndjson     （旧）
# 若系统模型不是 arm-mac14-host，可在页面右上角改「数据文件」路径。
set -e

PORT="${1:-8123}"
SYS_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DATA_NEW="arm-mac14-host/mods/warp-fusion/local/data/alerts/nginx.ndjson"
DATA_OLD="mods/warp-fusion/arm-mac14-host/local/data/alerts/nginx.ndjson"

echo "页面   : http://localhost:${PORT}/view/"
if [ -f "${SYS_ROOT}/${DATA_NEW}" ]; then
  echo "数据   : http://localhost:${PORT}/${DATA_NEW}"
elif [ -f "${SYS_ROOT}/${DATA_OLD}" ]; then
  echo "数据   : http://localhost:${PORT}/${DATA_OLD}   (旧布局)"
else
  echo "数据   : 尚未生成 —— 先 gops sys update/localize/install、gops sys start，再喂数据"
fi
echo "根目录 : ${SYS_ROOT}  (Ctrl-C 停止)"

cd "${SYS_ROOT}"
exec python3 -m http.server "${PORT}"
