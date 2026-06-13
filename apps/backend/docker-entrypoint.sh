#!/bin/sh
# 後端容器啟動：等 DB 就緒 → 套用 schema → 種子 (有資料自動略過) → 啟動服務。
set -e

echo "[backend] 套用資料庫 schema (等待 DB 就緒)..."
ATTEMPTS=0
until ./node_modules/.bin/prisma db push --skip-generate --accept-data-loss; do
  ATTEMPTS=$((ATTEMPTS + 1))
  if [ "$ATTEMPTS" -ge 30 ]; then
    echo "[backend] 資料庫長時間無法連線，放棄。"
    exit 1
  fi
  echo "[backend] DB 尚未就緒，2 秒後重試 ($ATTEMPTS/30)..."
  sleep 2
done

echo "[backend] 執行種子資料..."
node_modules/.bin/ts-node --transpile-only prisma/seed.ts || echo "[backend] 種子略過或失敗 (不阻擋啟動)。"

echo "[backend] 啟動服務..."
exec node dist/main.js
