## 1. Bun 環境 (design Decision 1: Generator 以 TypeScript + Bun 實作)

- [x] 1.1 於本機安裝 Bun (brew install bun) 並確認 `bun --version` 可執行；generator 改以 Bun 為 runtime 與測試器。驗證：`bun --version` 回報版本號。
- [x] 1.2 `generator/package.json` 的 scripts 改走 `bun run` / `bun test`、devDeps 換 `@types/bun`、移除 npm lockfile 並以 `bun install` 產出 `bun.lock`；依賴維持 zod 與 yaml。驗證：`bun install` 成功且 `bun.lock` 生成。

## 2. Schema 改為最終格式

- [x] 2.1 把現有單檔 schema 拆成 shared/data-model/schema/ 目錄、一型一檔 12 檔 (schema/LedgerOrder.yaml 等)，每檔僅含該型別宣告、不含 version，落實 design Decision 2: 統一 schema 為 YAML 目錄、一型一檔 與 spec「Unified schema directory is the single source of truth for data model shapes」。驗證：目錄含 12 檔，型別名與 apps/apple Swift Domain 1:1 對應。
- [x] 2.2 全部 schema 檔的 trait 改平台中立詞彙 (value-equality / serializable / serialization: custom / identity / case-iterable / hashable) 並移除所有 sendable，落實 design Decision 3: 平台中立 trait 詞彙與 Swift 全域 Sendable 政策 與 spec「Schema vocabulary is platform-neutral」。驗證：grep 全 schema 無 `sendable` 與舊 Swift 詞彙 (codable/equatable/identifiable)。
- [x] 2.3 optionality 改用欄位的顯式 `nullable: true/false` (移除型別字串的 `?` 後綴)，落實 design Decision 4: 型別文法用字串 DSL，nullability 除外 與 spec「Nullability and defaults follow explicit, fidelity-preserving rules」；Campaign.closeDate / settledDate 等改帶 nullable: true。驗證：grep 全 schema type 字串無 `?`，optional 欄位皆有 nullable: true。
- [x] 2.4 codegen.yaml 加 `version: 1`，`--schema` 改指向 schema/ 目錄。驗證：codegen.yaml 含 version 與 swift target。
- [x] 2.5 確認 schema 僅用 entity / enum / wrapper 三 kind、不含 sum type 與平台逃生艙，落實 design Decision 7: sum type 與 platform 逃生艙——設計待命、暫不實作。驗證：grep 全 schema 無 `kind: union` 與 `platform:` 區塊。

## 3. Generator 程式更新 (src/datamodel-gen.ts)

- [x] 3.1 [P] Loader 改為目錄合併，落實 spec「Unified schema directory is the single source of truth for data model shapes」與 design Decision 6: 解析層與 IR 驗證層嚴格分離——`--schema` 接受目錄、glob 各檔 `types:` 串接成單一 IR、version 改讀 codegen.yaml、驗證對合併全集跑、決定性以「檔名排序 + 檔內宣告序」保證。驗證：bun test 中目錄合併載入測試綠、跨檔引用解析正確。
- [x] 3.2 [P] 型別文法移除 `?`、nullability 改由 zod FieldSchema 的 `nullable` 承載，落實 design Decision 4: 型別文法用字串 DSL，nullability 除外；TypeExpr 拿掉 optional variant、parser 不再解析 `?`。驗證：bun test 中型別文法測試綠、`?` 輸入被視為錯誤。
- [x] 3.3 中立 trait 映射，落實 spec「Schema vocabulary is platform-neutral」與 design Decision 3: 平台中立 trait 詞彙與 Swift 全域 Sendable 政策：zod trait enum 改中立名、Swift emitter 的 trait 對應表與標準順序改用中立鍵對應 Swift 關鍵字、hashable 之於 TypeScript 走明確忽略分支。驗證：bun test 中中立 trait→三平台對應測試綠。
- [x] 3.4 Swift emitter 套用全域 Sendable 政策 (對所有生成 struct/enum 無條件加 Sendable，不再來自 trait)，落實 spec「Schema vocabulary is platform-neutral」的 Sendable 條款。驗證：bun test 中「不列序列化 trait 的 fixture 型別仍獲 Sendable」測試綠。
- [x] 3.5 nullable/default emit 規則三 emitter 一致套用，落實 spec「Nullability and defaults follow explicit, fidelity-preserving rules」與 design Decision 5: nullable 與 default 的語意：依 nullable 包 optional 層；default 有設用其值、nullable 無 default 給平台 nil、非 nullable 無 default 必填；顯式 init 路徑為 nullable 欄位補 = nil。驗證：bun test 中 default 解析表 (含 SampleOrder.closeDate 觸發顯式 init 補 nil) 全綠。

## 4. Goldens 與測試 (design Decision 1: Generator 以 TypeScript + Bun 實作)

- [x] 4.1 fixture schema 同步改最終格式 (中立 trait、移除 sendable、nullable 欄位)，並加入一個不列任何序列化 trait 的 fixture 型別以驗證 Sendable 全域注入；重生並 commit 三語言 golden file，落實 spec「Kotlin and TypeScript emitters are locked by golden-file tests」。驗證：fixtures/expected 下 Swift/Kotlin/TypeScript golden 與新格式輸出逐 byte 一致。
- [x] 4.2 測試遷移到 bun:test (test/expect)，涵蓋 spec「Schema validation rejects malformed declarations before generation」的驗證規則表 (重複名/未知引用/identity 缺 id/serialization 衝突/未知 enum case/未知 trait/未知 kind)、golden 鎖定、決定性、漂移偵測、目錄合併載入、Sendable 全域注入、中立 trait 對應。驗證：`bun test` 全綠。
- [x] 4.3 端到端驗證鏈落實 spec「Generator emits deterministic Swift, Kotlin, and TypeScript code」與「Check mode detects drift between schema and committed output」：`bunx tsc --noEmit` 零錯誤；以正式 schema/ 目錄生成至**暫存目錄**兩次 byte-identical (不寫入 apps/apple)；check 模式同步時 exit 0；錯誤路徑 (未知引用 / 不支援語言) exit 1 且不寫任何檔案。驗證：上述指令逐一執行並記錄結果。

## 5. 本輪文件與 spec 同步

- [x] 5.1 [P] 更新 root README.md 佈局章節 (shared/data-model 由「未來尚未建立」改為實際內容：schema 目錄 + generator + fixtures)，落實 monorepo-layout spec「Reserved future directories are documented, not stubbed」。驗證：README 與磁碟實際佈局逐項相符，無殘留「shared/ 不存在」描述。
- [x] 5.2 [P] 新建 shared/data-model/README.md：schema 格式說明 (一型一檔、中立 trait、nullable/default、型別文法字串 DSL)、generate / check 指令 (bun 版)、Bun 環境需求、改欄位標準流程。驗證：依文件內容實跑 generate / check 指令可成功。
- [x] 5.3 檢視 monorepo-layout delta spec「Reserved future directories are documented, not stubbed」與本輪實況一致 (shared/data-model 含 schema 目錄 / generator / fixtures / 文件)；跑 spectra analyze 與 spectra validate。驗證：analyze 無 Critical/Warning、validate 通過。

## 6. 後續階段：Apple Domain 生成式接管

- [x] 6.1 codegen.yaml 的 swift target 指向 apps/apple/BuyLedger/Core/Domain/Generated/，`bun run generate` 產出 12 個 .generated.swift，落實 design Decision 8: Apple Domain 生成式接管——生成檔 + 手寫 extension (後續階段)。驗證：Generated/ 出現 12 檔，內容與現行型別宣告 API 一致 (型別名、屬性、init 簽名、conformances；唯一刻意差異為全型別補 Sendable)。
- [x] 6.2 12 個既有 Domain 檔改寫為只含手寫邏輯的 extension (刪型別主宣告)，落實 spec「Generated Swift owns the data shape and handwritten extensions own behavior」：OrderStatus/CampaignStatus/PaymentReceiptStatus/CustomerTier 留 title (OrderStatus 另留 realizedStatuses)；CurrencyCode 留 code/localizedName/自訂 Codable/static；LedgerOrderItem 留 subtotal/自訂 Codable；LedgerOrder 留 maxPhotoCount/summary/isMergeResult/contributesToCategoryBreakdown/itemSummary；Campaign 留 isSettled；FxRateSnapshot 留 fallback；LedgerCustomer/Money/PaymentMethodInfo 無剩餘邏輯則刪檔。驗證：專案可編譯、12 型別呼叫端零修改。
- [x] 6.3 整體驗收：先 agvtool next-version -all 遞增 build number，三平台 build 序列化執行 (iOS / iPadOS simulator + macOS) 全綠；BuyLedgerTests 全綠 (含 snapshot 與 LedgerOrderItem 編碼不含 id 的既有行為)；`bun run check` exit 0 且 git status 顯示生成檔與 schema 同步。驗證：上述指令逐一執行並記錄結果。
- [x] 6.4 文件補完：root CLAUDE.md 跨平台硬規則 (data model 形狀變更一律改 schema 後 generate、不可手改 .generated.swift、不可單平台私加欄位) 與 apps/apple/CLAUDE.md (Generated/ gotcha、提交前 bun run check、新檔以三平台 build 驗證 file system synchronized groups 拾取) 與 apps/apple/README.md (codegen 開發流程)。驗證：依文件同步鐵則逐列對照 diff，結論為「有影響，已同步」。

## 7. 生成檔唯讀鎖 (使用者追加需求)

- [x] 7.1 生成檔預設唯讀：`generate` 將每個生成檔 chmod 唯讀 (0o444) 防手動編輯、重生成自動「解鎖→重寫→重鎖」保持冪等、新增 `unlock` 命令與 `bun run unlock` script 供刻意解鎖，落實 design Decision 9: 生成檔預設唯讀、需顯式解鎖 與 spec「Generated output files are locked read-only on disk」；文件 (root/apple CLAUDE.md、兩份 README) 同步。驗證：bun test 唯讀鎖測試綠 (generate 後唯讀、重生成不失敗、unlock 後可寫)；正式 Generated/ 12 檔權限為 `r--r--r--`；唯讀檔 iOS build 仍綠。
