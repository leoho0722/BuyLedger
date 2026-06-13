# BuyLedger

為個人代購業務而生的帳本 App。提供 Apple 平台版本 (iOS、iPadOS、macOS) 與 Web 全棧版本 (Next.js 前端 + NestJS 後端 + PostgreSQL)；功能與設計語言跨平台一致。Android 為未來規劃。

## Web 全棧一鍵啟動

```bash
# 需要 Docker、Docker Compose 與 make
make env                      # 由範本建立 deploy/ 下的 .env 與 *.env (再填入實值)
make up                       # 建置並啟動 PostgreSQL 18 + 後端 (:4000) + 前端 (:3000)
```

部署物件統一收斂在 **`deploy/`**。環境變數分層：**`deploy/common.env`** 放 compose 內插用的非祕密拓樸值 (ports 與前端 build arg)；**`deploy/<service>.env`** 為各容器執行期變數 (per-service `env_file`)——`deploy/db.env` (PostgreSQL 帳密)、`deploy/backend.env` (DATABASE_URL / CORS / 選填 API key)，祕密只進對應容器，web 容器不帶任何祕密。各 `*.example` 為範本、其餘不入版控。

`make up` 會把 backend / web 的 **image tag 自動帶上各自 `package.json` 的 version** (例 `buyledger-web:1.0.0`)；其他指令見 `make`（`env` / `build` / `down` / `logs` / `ps` / `versions`）。也可直接 `docker compose -f deploy/docker-compose.yml up --build`，但 image 會退回 `:latest`。

啟動後開啟 <http://localhost:3000>；首次啟動會自動套用資料庫 schema 並種子示範資料。未提供外部 API key 時，AI 商品總結與即時匯率以空狀態降級 (不偽造資料)。端對端驗收見 [apps/web/README.md](apps/web/README.md#端對端測試-playwright)。

<details open>
  <summary>🖥️&nbsp; <b>macOS</b></summary>
  <br>
  <p align="center"><img src="assets/macos-intro.png" alt="BuyLedger 於 macOS 的總覽頁" width="820"></p>
</details>

<details>
  <summary>📱&nbsp; <b>iOS</b></summary>
  <br>
  <p align="center"><img src="assets/ios-intro.png" alt="BuyLedger 於 iOS 的總覽頁" height="620"></p>
</details>

<details>
  <summary>📲&nbsp; <b>iPadOS</b></summary>
  <br>
  <p align="center"><img src="assets/ipados-intro.png" alt="BuyLedger 於 iPadOS 的總覽頁" height="620"></p>
</details>

## 專案結構

```text
BuyLedger (repo)/
├── apps/                                 # 可部署單元 (每個平台一個子目錄)
│   ├── apple/                            # Apple 平台 App (iOS / iPadOS / macOS)
│   │   ├── BuyLedger.xcodeproj/          # Xcode 專案；project.pbxproj 提交、xcuserdata/ 不提交
│   │   ├── BuyLedger/                    # App source root (App / Core / Features / Shared / Resources)
│   │   ├── BuyLedgerTests/               # 單元測試 + swift-snapshot-testing baseline
│   │   └── BuyLedgerUITests/             # UI 與啟動畫面測試
│   ├── web/                             # Web 前端 (Next.js + React + Tailwind v4 + TanStack Query)
│   │   ├── src/app/                      # App Router 頁面 (儀表板/訂單/開團/分析/更多)
│   │   ├── src/components/               # 設計系統 (ds/) 與共用元件
│   │   ├── src/features/                 # 訂單/開團功能模組 (表單、合併、AI 總結等)
│   │   ├── src/lib/                      # 資料層、領域邏輯、格式化、生成型別
│   │   ├── e2e/                          # Playwright 端對端測試
│   │   └── Dockerfile                    # standalone 容器
│   ├── backend/                         # Web 後端 (NestJS + Prisma + PostgreSQL)
│   │   ├── src/                          # 各 feature module + domain/ (財務公式移植) + 生成型別
│   │   ├── prisma/                       # schema.prisma 與種子
│   │   └── Dockerfile                    # 多階段容器
│   └── android/                          # (未來，尚未建立) Android App
├── shared/                               # 跨平台共享內容
│   └── data-model/                       # 跨平台 Data Model schema 與產生器
│       ├── schema/                       # 統一 schema (YAML，一型一檔)
│       ├── generator/                    # datamodel-gen 產生器 (TypeScript + Bun)
│       └── fixtures/                     # 產生器 golden file 測試素材
├── deploy/                               # Web 全棧部署：docker-compose.yml + 分層 env (compose common.env + per-service *.env)
├── Makefile                              # 部署入口 (make env / up / build / down / logs / ps / versions)
├── openspec/                             # Spectra 規格與變更提案
└── assets/                               # README 圖片等共用素材
```

**佈局契約**：可部署單元一律放 `apps/` (每個平台一個子目錄)，跨平台共享內容放 `shared/`，`openspec/` 與 `assets/` 留在根目錄。`apps/apple`、`apps/web`、`apps/backend` 與 `shared/data-model` 均已實際動工；`apps/android` 為文件化保留位置，待動工時才建立 (目前不放 stub)。

## 平台導覽

| 平台                         | 位置            | 開發指南                                                                                           |
|------------------------------|-----------------|----------------------------------------------------------------------------------------------------|
| Apple (iOS / iPadOS / macOS) | `apps/apple/`   | [apps/apple/README.md](apps/apple/README.md)：技術棧、環境設定、build / test、架構速覽、Troubleshooting |
| Web 前端                     | `apps/web/`     | [apps/web/README.md](apps/web/README.md)：技術棧、開發、設計系統、Playwright                          |
| Web 後端                     | `apps/backend/` | [apps/backend/README.md](apps/backend/README.md)：技術棧、API、Prisma、容器化                         |
| Android                      | `apps/android/` | (未來，尚未建立)                                                                                    |

各平台的 AI 協作硬規則見該平台目錄的 `CLAUDE.md`；跨平台通用規範見根目錄 [`CLAUDE.md`](CLAUDE.md)。

## 產品政策

- **UI 寧可顯示空狀態也不顯示假資料**——API 失敗或無資料時顯示空狀態，不繪空圖表也不退回 hardcoded 數字。
- **幣別清單動態載入、不可 hardcode**——cache 7 天。

## Spec-Driven Development

本專案採用 [Spectra](https://github.com/kaochenlong/spectra-app) (SDD)：

- 規格在 `openspec/specs/`
- 變更提案在 `openspec/changes/`
- 工作流程：`discuss?` → `propose` → `apply` ⇄ `ingest` → `archive`

詳細 workflow 與貢獻者注意事項見 `CLAUDE.md`。
