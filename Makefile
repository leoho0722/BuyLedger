# BuyLedger Web 全棧 compose 包裝 (留在 repo root 當入口)。
# 部署物件收斂在 deploy/ (compose + env)；image tag 自動跟隨各 app package.json version。
# 裸跑 compose 請自行帶 -f deploy/docker-compose.yml；要帶版號請走 `make`。

# compose 指定 deploy/ 下的檔案；project-directory 自動為 deploy/ (env_file 相對 deploy/)。
# 內插用變數以 --env-file 載入 deploy/common.env (compose 只會自動載入名為 .env 的檔，故顯式指定)。
COMPOSE := docker compose -f deploy/docker-compose.yml --env-file deploy/common.env --env-file deploy/web.env

# 由各自 package.json 取版號，export 給 compose 內插。
export BACKEND_VERSION := $(shell node -p "require('./apps/backend/package.json').version")
export WEB_VERSION := $(shell node -p "require('./apps/web/package.json').version")

.PHONY: env up build down restart logs ps versions

## 由範本建立缺少的 env 檔 (deploy/common.env 與 deploy/*.env)
env:
	@[ -f deploy/common.env ] || cp deploy/common.env.example deploy/common.env
	@[ -f deploy/db.env ] || cp deploy/db.env.example deploy/db.env
	@[ -f deploy/backend.env ] || cp deploy/backend.env.example deploy/backend.env
	@[ -f deploy/web.env ] || cp deploy/web.env.example deploy/web.env
	@echo "env 檔已就緒，請確認已填入實值 (deploy/common.env 與 deploy/*.env)。"

## 建置 (image 帶版號) 並啟動全棧
up:
	$(COMPOSE) up --build -d

## 僅建置 image (帶版號)
build:
	$(COMPOSE) build

## 停止並移除容器
down:
	$(COMPOSE) down

## 重啟
restart:
	$(COMPOSE) restart

## 追蹤 log
logs:
	$(COMPOSE) logs -f

## 容器狀態
ps:
	$(COMPOSE) ps

## 顯示將套用的 image 版號
versions:
	@echo "backend -> buyledger-backend:$(BACKEND_VERSION)"
	@echo "web     -> buyledger-web:$(WEB_VERSION)"
