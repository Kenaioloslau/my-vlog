#!/bin/bash
# ============================================================
#  ziscus 留言审核工具（Mac 专用，不依赖浏览器）
#
#  用法（在终端里）：
#     ./ziscus-mod.sh                 看待审的留言
#     ./ziscus-mod.sh all             看全部留言
#     ./ziscus-mod.sh approve <ID>    批准
#     ./ziscus-mod.sh reject  <ID>    拒绝（不公开）
#     ./ziscus-mod.sh spam    <ID>    标为垃圾
#     ./ziscus-mod.sh delete  <ID>    彻底删除
#     ./ziscus-mod.sh mode on|paused|off   整站开关
#
#  第一次用：右键这个文件 → 打开方式 → 终端
#  或者先执行：chmod +x ziscus-mod.sh
# ============================================================

set -uo pipefail

API="https://comments.canaiolos.com"
ENV_FILE="${ZISCUS_ENV:-$HOME/Documents/my-vlog/.env}"

# ---------- 读取密钥 ----------
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ 找不到密钥文件：$ENV_FILE"
  echo "   请先确认网站文件夹在 ~/Documents/my-vlog"
  exit 1
fi

SECRET=$(grep -E '^ZISCUS_ADMIN_SECRET=' "$ENV_FILE" | head -1 | cut -d= -f2- | tr -d '\r')

if [ -z "${SECRET:-}" ]; then
  echo "❌ $ENV_FILE 里没有 ZISCUS_ADMIN_SECRET"
  echo "   按下面的命令重新生成一个："
  echo '   NEW=$(openssl rand -hex 32)'
  echo '   echo "ZISCUS_ADMIN_SECRET=$NEW" >> ~/Documents/my-vlog/.env'
  echo '   echo "$NEW" | pnpm exec wrangler secret put ADMIN_SECRET'
  exit 1
fi

AUTH="Authorization: Bearer $SECRET"

# ---------- 统一请求函数 ----------
call() {
  # $1=方法  $2=路径  $3=额外数据(可选)
  local method="$1" path="$2" data="${3:-}"
  if [ -n "$data" ]; then
    curl -s -o /tmp/ziscus_body -w "%{http_code}" -X "$method" \
      -H "$AUTH" -H "Content-Type: application/json" -d "$data" "$API$path"
  else
    curl -s -o /tmp/ziscus_body -w "%{http_code}" -X "$method" \
      -H "$AUTH" "$API$path"
  fi
}

explain_code() {
  case "$1" in
    200|303|302) echo "✅ 成功" ;;
    401)         echo "❌ 401 密钥不对（.env 里的值可能过期了）" ;;
    404)         echo "❌ 404 找不到这条留言（ID 写错？）" ;;
    400)         echo "❌ 400 参数错误：$(cat /tmp/ziscus_body)" ;;
    429)         echo "❌ 429 请求太频繁，等一会" ;;
    *)           echo "❌ 返回码 $1：$(cat /tmp/ziscus_body)" ;;
  esac
}

# ---------- 子命令 ----------
ACTION="${1:-list}"
shift || true

case "$ACTION" in

  list)
    echo "── 待审留言 ──"
    code=$(call GET "/admin/comments?status=pending")
    if [ "$code" != "200" ]; then explain_code "$code"; exit 1; fi
    if [ "$(cat /tmp/ziscus_body)" = "[]" ]; then
      echo "（没有待审留言）"
      echo
      echo "提示：如果你想看到待审队列，说明当前是「先审后发」模式。"
      echo "      若 wrangler.toml 里 MODERATION=\"off\"，新留言会直接通过，队列永远是空的。"
      exit 0
    fi
    sed 's/},{/}\n{/g' /tmp/ziscus_body
    echo
    echo "── 批准：./ziscus-mod.sh approve <ID> ──"
    ;;

  all)
    echo "── 全部留言 ──"
    status="${1:-}"
    if [ -n "$status" ]; then
      code=$(call GET "/admin/comments?status=$status")
    else
      code=$(call GET "/admin/comments")
    fi
    if [ "$code" != "200" ]; then explain_code "$code"; exit 1; fi
    if [ "$(cat /tmp/ziscus_body)" = "[]" ]; then echo "（没有留言）"; exit 0; fi
    sed 's/},{/}\n{/g' /tmp/ziscus_body
    ;;

  approve|reject|spam)
    if [ -z "${1:-}" ]; then echo "用法：./ziscus-mod.sh $ACTION <ID>"; exit 1; fi
    code=$(call POST "/$ACTION/$1")
    explain_code "$code"
    ;;

  delete)
    if [ -z "${1:-}" ]; then echo "用法：./ziscus-mod.sh delete <ID>"; exit 1; fi
    code=$(call DELETE "/comments/$1")
    explain_code "$code"
    ;;

  mode)
    if [ -z "${1:-}" ]; then echo "用法：./ziscus-mod.sh mode on|paused|off"; exit 1; fi
    case "$1" in
      on|paused|off) ;;
      *) echo "只接受 on / paused / off"; exit 1 ;;
    esac
    code=$(call POST "/admin/mode" "{\"mode\":\"$1\"}")
    explain_code "$code"
    ;;

  *)
    echo "未知命令：$ACTION"
    echo "可用：list | all | approve <ID> | reject <ID> | spam <ID> | delete <ID> | mode <on|paused|off>"
    exit 1
    ;;
esac
