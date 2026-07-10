<!-- SPECTRA:START v1.0.2 -->

# Spectra Instructions

This project uses Spectra for Spec-Driven Development(SDD). Specs live in `openspec/specs/`, change proposals in `openspec/changes/`.

## Use `/spectra-*` skills when:

- A discussion needs structure before coding → `/spectra-discuss`
- User wants to plan, propose, or design a change → `/spectra-propose`
- Tasks are ready to implement → `/spectra-apply`
- There's an in-progress change to continue → `/spectra-ingest`
- User asks about specs or how something works → `/spectra-ask`
- Implementation is done → `/spectra-archive`
- Commit only files related to a specific change → `/spectra-commit`

## Workflow

discuss? → propose → apply ⇄ ingest → archive

- `discuss` is optional — skip if requirements are clear
- Requirements change mid-work? Plan mode → `ingest` → resume `apply`

## Parked Changes

Changes can be parked（暫存）— temporarily moved out of `openspec/changes/`. Parked changes won't appear in `spectra list` but can be found with `spectra list --parked`. To restore: `spectra unpark <name>`. The `/spectra-apply` and `/spectra-ingest` skills handle parked changes automatically.

<!-- SPECTRA:END -->

# 儲存庫指引

本檔只制定**跨平台通用規範**；各平台的技術棧硬規則與隱性 gotcha 一律放對應平台目錄的 `CLAUDE.md`，不在本檔重複。

## Monorepo 佈局

- 可部署單元一律放 `apps/` (每個平台一個子目錄)，跨平台共享內容放 `shared/`，`openspec/` 與 `assets/` 留在根目錄。目前有 `apps/apple` (iOS / iPadOS / macOS) 與 `shared/data-model` (跨平台 data model schema + 產生器)；`apps/android` 為文件化保留位置，動工時才建立目錄。
- **每個平台目錄都要有一份自己的 `CLAUDE.md`** (如 `apps/apple/CLAUDE.md`) 記錄該平台的硬規則與 gotcha；新平台動工時第一件事就是建立它。本檔不得參雜平台細節。
- 文件與設定中的路徑引用必須與實際佈局一致；repo 不保留空的 stub 目錄或占位檔。

## 跨平台 Data Model (codegen)

`shared/data-model/` 是跨平台 data model 形狀的唯一宣告來源：一份統一 schema (YAML，一型一檔) 經 `datamodel-gen` 產生器輸出型別程式碼 (格式與指令見 `shared/data-model/README.md`)。目前產線僅配置 Swift target (輸出至 `apps/apple`)；TypeScript 與 Kotlin emitter 仍由 generator 的 golden-file 測試鎖定，待其他平台動工時再加對應 target。硬規則：

- **形狀變更一律改 schema、再 generate**——要增刪欄位、改型別或調整 trait，改 `shared/data-model/schema/` 後執行 `bun run generate`，**不可直接編輯生成檔** (`*.generated.swift` 等，檔頭都有「請勿手動編輯」警語)。
- **生成檔預設唯讀**——`generate` 會把所有生成檔鎖成唯讀 (`0o444`) 以防手動編輯；要重生成直接再跑 `generate` (會自動解鎖→重寫→重鎖)，只有刻意手動檢視／實驗才跑 `bun run unlock` 解鎖。此唯讀是本機工作副本的防線 (git 不追蹤 write bit，clone 後會回到可寫)，與檔頭警語、`check` 守門三者並行。
- **不可單平台私加欄位**——任一平台需要的資料形狀變更都要回到 schema、讓所有平台一致產生；平台專屬的行為 (顯示、計算、自訂序列化) 放手寫 extension，不混進生成檔。
- **schema 註解保持平台中立**——doc 描述資料概念本身，不得出現任一平台的語言／框架用詞或該平台 codebase 的型別名；各平台的慣用法 (如 Swift 的 `Sendable`) 由該平台 emitter 決定，不入 schema。
- **提交前以 check 守門**——提交涉及 data model 的變更前，於 `shared/data-model/generator` 跑 `bun run check` 確認生成檔與 schema 同步 (exit 0)；生成檔與 schema 一起 commit。

## 文件查證準則

- 動任何框架或第三方套件前先用 **Context7** 查最新官方文件，不要憑記憶或舊範例。平台專屬的額外對照規則 (例如 Apple docs MCP) 見各平台 `CLAUDE.md`。

## 產品政策 (跨平台)

- **UI 寧可顯示空狀態也不顯示假資料**——API 失敗或無資料時顯示「—」、「尚無可用匯率資料」、「尚未有足夠可用於分析的資料」等空狀態，不繪空圖表也不退回 hardcoded 數字。
- **幣別清單動態載入、不可 hardcode**——cache 7 天；各平台實作見其 `CLAUDE.md`。

## 環境相依性與依賴注入

任何讀取「現在」時間、locale、時區、UUID、隨機數的 production code，一律走依賴注入、不可直接呼叫系統 API (除了 dependency 註冊處本身)；測試以固定值注入確保跨機器一致。各平台的注入機制與具體規則見其 `CLAUDE.md`。

## 程式風格通用規範

各語言／框架慣例不在此重述；以下規則跨平台一體適用。

### 標點與空格

中英數混排的字串字面值與註解一律使用**半形括號** `()`，不用全形 `（）`；並依前後文在中文與半形內容之間補一個半形空格，讓兩者分開更易讀。

- **補空格**：半形括號緊貼到 CJK 字元、英數或 inline-code backtick 時，於括號外側補一個半形空格。例如 `收款金額 (NT $)`、`為空 (最寬鬆路徑) 的成本`、`` `nonisolated` (不是 `MainActor`) ``。
- **不補空格**：相鄰為空白、全形標點 (，。、；：！？「」)、字串或行邊界時不補，避免重複間距。例如 `` `…回應錯誤 (\(code))，目前無法…` `` 後接全形逗號不補、`Text("(TWD)")` 緊貼引號不補。
- **括號內側不補**：`(NT $)` 而非 `( NT $ )`。
- **Markdown 例外**：粗體結尾 `**` 前後不補空格以免破壞 `**...**` 語法——`**計算** (彙總)` 可，`**計算 **(彙總)` 不可。
- 此規則同時適用於 UI 顯示字串與正體中文註解。

### 註解

- 註解一律使用正體中文撰寫，語氣接近官方文件風格。
- 程式碼註解結尾不加中文句號 (。)——`//`／`///`／`/* */`／JSX `{/* */}` 等各語言註解皆然；句中分隔用的 。 保留 (只去結尾那一個)。此規範僅約束程式碼註解，不含 Markdown 文件等散文。
- 生成檔的註解由 `shared/data-model` 的 `datamodel-gen` emitter 統一在 emit 時去尾 。 (`docLines`／`blockDoc` 與檔頭模板)，故 schema 的 `doc:` 可照常書寫、不需手動去 。；改 emitter 後須 `bun run generate` 重生並 `bun run check` 守門。

## 文件同步鐵則

每完成一項功能的開發、調整或修正，**提交前**必須與 `git status --short` 一起執行文件審視：對照本次 diff 逐列檢查下表，命中卻未同步文件時不得提交。

| 本次 diff 若包含                                 | 必須同步的文件                                                                 |
|--------------------------------------------------|--------------------------------------------------------------------------------|
| 新的硬規則、gotcha、慣例 (踩到的雷、不可違反的限制) | 對應層級的 `CLAUDE.md` (通用 → root；平台專屬 → 該平台目錄)                     |
| 技術棧、外部服務、API key 或環境設定變動           | 平台 `README.md` 的技術棧／開發環境設定 (含 `Config.example.xcconfig` 等範本檔) |
| 目錄結構、feature 模組、build / test 指令變動      | 平台 `README.md` 的專案結構／Build & Run；跨平台佈局變動另須 root `README.md`    |
| 讓既有規則或描述失效的行為改變                   | 刪除或改寫過時內容——與現況矛盾的文件比缺文件更糟                               |

審視結論只有兩種：「有影響，已同步」或「確認無文件影響」，不可跳過。內容歸屬依受眾分工：`CLAUDE.md` 收 AI 協作硬規則、`README.md` 收人類開發指南；層級依「Monorepo 佈局」的分層原則 (通用 → root、平台 → 平台目錄)。

## Commit 風格

提交前先 `git status --short` 確認只包含本次變更的檔案。

使用正體中文撰寫 Conventional Commits：`<type>(<scope>): <描述>`

常用 type：`feat` (新功能)、`fix` (修正)、`refactor` (重構)、`docs` (文件)、`chore` (雜項)、`ci` (CI/CD)、`test` (測試)、`style` (排版)。

由 Claude 建立或 amend 的 commit，commit message 最後須加入 Co-Authored-By trailer，display name 用當次實際使用的模型名 (email 用 Claude Code 預設)：

```text
Co-Authored-By: Claude <當次模型名> <noreply@anthropic.com>
```

description (body) 使用列點格式，例如：

```text
refactor(time): 時間相依改走 @Dependency(\.date) 注入

- DashboardView / InsightsView / RootFeature 加 @Dependency(\.date)
- OrdersFeature.State.filteredOrders 改成 func(referenceDate:)
- 新增 TestDependencies.fixedNow 給 snapshot 與 unit test 共用
```
