<!-- SPECTRA:START v1.3.0 -->

# Spectra Instructions

This project uses Spectra for Spec-Driven Development(SDD). Specs live in `openspec/specs/`, change proposals in `openspec/changes/`.

## Skills

Each `/spectra-*` skill carries its own trigger description; these are the groups:

- Shape and plan → `/spectra-discuss`, `/spectra-propose`
- Continue tasks for an identified change → `/spectra-apply`
- Update requirements or plans for an identified change → `/spectra-ingest`
- Quality gate → `/spectra-verify`, `/spectra-review`, `/spectra-analyze`, `/spectra-audit`, `/spectra-drift`, `/spectra-debug`
- Finish → `/spectra-archive`, `/spectra-commit`

Explicit skill invocation takes precedence. Apply existing authorization within its unchanged scope.

## Workflow

discuss? → propose → apply ⇄ ingest → verify / review → archive

- `discuss` is optional — skip if requirements are clear
- Requirements change mid-work? Plan mode → `ingest` → resume `apply`

## Parked Changes

Changes can be parked（暫存）— temporarily moved out of `openspec/changes/`. Parked changes won't appear in `spectra list` but can be found with `spectra list --parked`. To restore: `spectra unpark <name>`. The `/spectra-apply` and `/spectra-ingest` skills disclose parking and restore when the named operation is already explicitly requested; respect a known refusal, otherwise ask for missing authorization.

<!-- SPECTRA:END -->

# 儲存庫指引

<!-- 維護提示 (HTML 註解不進 context)：每行自問「刪掉會讓 Claude 出錯嗎」，不會就刪；全檔維持 200 行以內；只在單一目錄適用的規則移到該目錄的 CLAUDE.md 或 .claude/rules/；/doctor 可提議修剪 -->

本檔只放**跨平台通用規範**；各平台與 shared 模組的技術棧硬規則與隱性 gotcha 一律放該目錄的 `CLAUDE.md`，不在本檔重複。

## Monorepo 佈局

- **可部署單元放 `apps/<platform>/`，跨平台共享內容放 `shared/`**；`openspec/`、`assets/` 與管轄所有平台的 `.github/` (CI workflow，見 `.github/workflows/ci.yml`) 留在根目錄，不依平台分拆。
- **不留 stub**：`apps/android` 動工時才建立目錄；repo 不放空目錄或占位檔，文件與設定中的路徑引用須與實際佈局一致。
- **每個平台目錄與 shared 模組目錄各有自己的 `CLAUDE.md`** (如 `apps/ios/CLAUDE.md`、`shared/data-model/CLAUDE.md`)，記錄該處隨時適用的硬規則與 gotcha；新平台動工第一件事就是建立它。
- **只和特定子目錄或檔案類型相關的規則放根目錄 `.claude/rules/<平台>-<主題>.md`**，以 frontmatter `paths` 限定載入範圍 (如 `.claude/rules/ios-ui-tests.md`)；平台 `CLAUDE.md` 開頭列出自己的規則檔。

## 規格 (openspec)

- **`<!-- @trace -->` 區塊不可信、不可手改**：它是歸檔工具自動產生並重寫的歷史紀錄，所列路徑未經驗證；判斷程式碼現況一律搜尋程式碼本身。
- **跨領域政策型規格**的 Purpose 以正體中文說明涵蓋範圍，並指名至少一份不涵蓋的相鄰規格；requirement 與 scenario 正文維持英文。目錄名已界定範圍的功能型規格可保留工具樣板，這是已記錄的留白，不是待補缺陷。

## 跨平台 Data Model (codegen)

`shared/data-model/schema/` 是資料形狀的唯一來源，`datamodel-gen` 據此產生各平台型別 (目前只接 Swift，輸出至 `apps/ios`)。

- **不可手改生成檔** (`*.generated.swift` 等，檔頭有警語)：增刪欄位、改型別、調 trait 一律改 schema，再於 `shared/data-model/generator` 執行 `bun run generate`。
- **不可單平台私加欄位**：任一平台需要的形狀變更都回到 schema、讓所有平台一致產生；平台專屬行為 (顯示、計算、自訂序列化) 放手寫 extension。
- **提交前於 `shared/data-model/generator` 跑 `bun run check` 須 exit 0**，生成檔與 schema 一起 commit；遠端 CI 的 codegen job 會再跑 `check` 與 generator 測試，漂移直接變紅。
- 產生器與 schema 細則 (唯讀鎖、doc 平台中立黑名單、golden 涵蓋) 見 `shared/data-model/CLAUDE.md`。

## 文件查證準則

- 動任何框架或第三方套件前先用 **Context7** 查最新官方文件，不憑記憶或舊範例；平台專屬的額外對照規則 (如 Apple docs MCP) 見各平台 `CLAUDE.md`。

## 協作方式

- **交付使用者要求的範圍**：例行判斷自行決定，不同解讀會導致實質不同的工作時才先確認；認為要求有誤或有更好做法時說一句，並照原要求繼續，不暗自縮小、擴大或改寫任務。
    - 完成全部工作才回報完成；做不到的部分照做其餘，並明說缺什麼、為什麼。
- **Claude 撰寫的 Markdown (`CLAUDE.md`、`.claude/rules/`、`openspec/` 文件、README) 長度配合內容所需**，不加填充段落、重複摘要或樣板章節。
- **`CLAUDE.md` 與 `.claude/rules/` 只寫現行規則與理由**：事件經過、日期、實測數字、「曾經／先前／已推翻」的沿革不寫進來，沿革留在 commit 與 openspec。
    - 新增條目前先確認刪掉它會讓 Claude 出錯；讀程式碼就能知道的事不寫。

## 產品政策 (跨平台)

- **UI 寧可顯示空狀態也不顯示假資料**：API 失敗或無資料時顯示「—」、「尚無可用匯率資料」、「尚未有足夠可用於分析的資料」等空狀態，不繪空圖表、不退回 hardcoded 數字。
- **幣別清單動態載入、不可 hardcode**：cache 7 天；各平台實作見其 `CLAUDE.md`。

## 環境相依性與依賴注入

- 任何讀取「現在」時間、locale、時區、UUID、隨機數的 production code 一律走依賴注入，不直接呼叫系統 API (dependency 註冊處除外)；測試注入固定值確保跨機器一致。注入機制與具體規則見各平台 `CLAUDE.md`。

## 程式風格通用規範

各語言／框架慣例不在此重述；以下規則跨平台一體適用，同時約束 UI 顯示字串與正體中文註解。

### 標點與空格

- **一律半形括號 `()`**，不用全形 `（）`。
- **中文與半形內容之間補一個半形空格**：括號、英數、inline-code backtick 緊貼 CJK 時於外側補空格，例如 `收款金額 (NT $)`、`` `nonisolated` (不是 `MainActor`) ``。
- **不補空格的情況**：相鄰為空白、全形標點 (，。、；：！？「」)、引號或行邊界時不補，例如 `Text("(TWD)")`；括號內側也不補，`(NT $)` 而非 `( NT $ )`。
- **Markdown 粗體例外**：`**` 前後不補空格以免破壞語法，`**計算** (彙總)` 可、`**計算 **(彙總)` 不可。

### 註解

- 一律以正體中文撰寫，語氣接近官方文件。
- **結尾不加中文句號 (。)**：`//`／`///`／`/* */`／JSX `{/* */}` 皆然，句中分隔用的 。 保留。此規範只約束程式碼註解，不含 Markdown 等散文。

## 文件同步鐵則

**IMPORTANT**：每次功能開發、調整或修正，**提交前**對照 `git status --short` 逐列檢查本次 diff 是否命中下表，命中卻未同步文件不得提交。審視結論只有「有影響，已同步」或「確認無文件影響」兩種，不可跳過。

| 本次 diff 若包含                                 | 必須同步的文件                                                                 |
|--------------------------------------------------|--------------------------------------------------------------------------------|
| 新的硬規則、gotcha、慣例 (踩到的雷、不可違反的限制) | 對應層級的 `CLAUDE.md` 或 `.claude/rules/` (通用 → root；平台或 shared 模組專屬 → 該目錄；只涉特定子目錄 → 規則檔) |
| 技術棧、外部服務、API key 或環境設定變動           | 平台 `README.md` 的技術棧／開發環境設定 (含 `Config.example.xcconfig` 等範本檔) |
| 目錄結構、feature 模組、build / test 指令變動      | 平台 `README.md` 的專案結構／Build & Run；跨平台佈局變動另須 root `README.md`    |
| 讓既有規則或描述失效的行為改變                   | 刪除或改寫過時內容：與現況矛盾的文件比缺文件更糟                                |

歸屬依受眾分工：`CLAUDE.md` 收 AI 協作硬規則，`README.md` 收人類開發指南。

## Commit 風格

- 提交前先 `git status --short` 確認只包含本次變更的檔案。
- 標題為正體中文 Conventional Commits `<type>(<scope>): <描述>`，type 用 `feat`／`fix`／`refactor`／`docs`／`chore`／`ci`／`test`／`style`；body 用列點。
- 由 Claude 建立或 amend 的 commit 結尾加 Co-Authored-By trailer：display name 是當次實際使用的模型名 (直接接在 `Claude` 之後、不加角括號)，email 固定 `noreply@anthropic.com`；不回溯修改既有提交。

```text
refactor(time): 時間相依改走 @Dependency(\.date) 注入

- DashboardView / InsightsView / RootFeature 加 @Dependency(\.date)
- OrdersFeature.State.filteredOrders 改成 func(referenceDate:)
- 新增 TestDependencies.fixedNow 給 snapshot 與 unit test 共用

Co-Authored-By: Claude Opus 5 (1M Context) <noreply@anthropic.com>
```
