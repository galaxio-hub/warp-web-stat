#!/usr/bin/env sh
# 生成样例 nginx 数据，灌进 warp-parse 的 tcp 源。
#
#   sh sys/gen-data.sh [wpgen 参数…]
#   例：sh sys/gen-data.sh -n 5000 -s 5000 -p
#
# 生成器配置 = sys/setting/warp-parse/conf/wpgen.toml（经 gops sys localize 落到
# sys/<model>/mods/warp-parse/local/conf/wpgen.toml）：输出是 tcp_sink，直接打到
# warp-parse 的 syslog_1 源（127.0.0.1:6514，即拓扑里那个 tcp 源）。
#
# 前置：gops sys install（产出 sys/<model>/bin/wpgen）、gops sys start（warp-parse 在监听）。
set -e

SYS_ROOT="$(cd "$(dirname "$0")" && pwd)"
MODEL="$(sed -n 's/^model:[[:space:]]*//p' "${SYS_ROOT}/sys_model.yml" | head -1)"
WORK_ROOT="${SYS_ROOT}/${MODEL}/mods/warp-parse/local"
WPGEN="${SYS_ROOT}/${MODEL}/bin/wpgen"

[ -n "${MODEL}" ] || { echo "读不到 model：${SYS_ROOT}/sys_model.yml" >&2; exit 1; }
[ -x "${WPGEN}" ] || { echo "wpgen 不存在：${WPGEN}（先运行 gops sys install）" >&2; exit 1; }
[ -d "${WORK_ROOT}" ] || { echo "work-root 不存在：${WORK_ROOT}（先运行 gops sys update && gops sys localize）" >&2; exit 1; }

# 目标在不在监听：直接连不上时 wpgen 只报 "tcp sink connect tcp"，看不懂，这里提前说清
SINK_ADDR="$(grep -A4 '^\[output.params\]' "${WORK_ROOT}/conf/wpgen.toml" | sed -n 's/^[[:space:]]*addr[[:space:]]*=[[:space:]]*//p' | tr -d '"' | head -1)"
SINK_PORT="$(grep -A4 '^\[output.params\]' "${WORK_ROOT}/conf/wpgen.toml" | sed -n 's/^[[:space:]]*port[[:space:]]*=[[:space:]]*//p' | tr -d '"' | head -1)"
case "${SINK_ADDR}" in
  127.0.0.1|localhost|0.0.0.0|"") ;;
  *) SINK_PORT="" ;;   # 非本地目标不做检查（可能是远端 warp-parse）
esac
if [ -n "${SINK_PORT}" ] && command -v lsof >/dev/null 2>&1 \
   && ! lsof -nP -iTCP:"${SINK_PORT}" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "输出目标 ${SINK_ADDR}:${SINK_PORT} 没有在监听 —— warp-parse 没启动？" >&2
  echo "先运行：gops sys start" >&2
  exit 1
fi

echo "+ wpgen sample -w ${WORK_ROOT} $*"

# wpgen 的 [models]/[logging] 路径按 cwd 解析（-w 只管工程根），必须先切到 work-root
cd "${WORK_ROOT}"
exec "${WPGEN}" sample -w "${WORK_ROOT}" "$@"
