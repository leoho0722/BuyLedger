## Context

- `shared/data-model` 以 YAML schema 宣告 12 個型別，`datamodel-gen` (TypeScript + Bun) 依 `codegen.yaml` 只輸出 Swift 到 `apps/ios/BuyLedger/Core/Domain/Generated/`；Kotlin 與 TypeScript emitter 只由 `fixtures/` 的 golden 測試鎖住，沒有消費者。
- 12 個生成型別中，10 個在 `Core/Domain/` 有同名手寫檔，內容全是 `extension <Type>` (計算、方法、自訂 `Codable`、`static let`)；`LedgerCustomer` 與 `Money` 沒有手寫檔；`Money` 在 App 與測試都沒有任何引用 (以 `grep -rnw Money --include='*.swift' apps/ios` 確認只出現在生成檔)。
- 生成檔的排版由 emitter 決定：`// MARK: - Data Properties`、enum 的 `// MARK: - Cases`、`var id: String { rawValue }` 單行本體、init 文件沒有 `- Parameters`，與 ios-dev-kit `formatting.md` 不一致。
- 同一型別在 `Core/Domain/` 以外還有 extension：Feature 層的 `Features/Orders/Domain/LedgerOrder+OrderMutation.swift`、`Features/Orders/Presentation/Formatting/OrderStatus+Presentation.swift`，測試 target 的 `Fixtures/Campaign+Fixture.swift`、`Fixtures/LedgerOrder+Fixture.swift`、`Support/LedgerOrder+TestSupport.swift`。
- `BuyLedgerTests/Guards/Scanning/SwiftSourceFiles.swiftFiles(under:shouldIncludeGenerated:)` 預設排除路徑含 `Generated` 的檔案；`apps/` 下唯一名為 `Generated` 的目錄就是 `Core/Domain/Generated` (以 `find apps -type d -name 'Generated*'` 確認)，10 個呼叫端傳 `shouldIncludeGenerated: true`，其餘用預設值。
- **持久化形狀**：
  - `OrderRecord` 與 `BuyLedgerSchema.swift` 各保留版本的 `OrderRecord` shadow 都直接內嵌現行的 `LedgerCustomer` (含 `CustomerTier`)、`OrderStatus`、`[LedgerOrderItem]`，shadow 沒有替它們凍結副本。
  - `CampaignRecord.statusRaw`、`OrderRecord.paymentReceiptStatus`、`OrderRecord.currency` 是 `String` 欄位，分別以 `CampaignStatus`、`PaymentReceiptStatus` 的 raw value 與 `CurrencyCode.rawValue` 寫入、以 `init(rawValue:)` 讀回；`CurrencyCode` 的自訂 `Codable` (單值字串) 不在任何持久化路徑上 (App 只有 `HTTPClient` 與 `AISummaryService` 用 JSON 編解碼)。
  - `LedgerOrderItem` 的自訂 `Codable` 只寫出 `name`、`quantity`、`unitPrice`，解碼時由本體 init 以 `UUID()` 產生新 `id`。
- **目前的守門**：`BuyLedgerTests` 內搜尋 `JSONEncoder`、`JSONDecoder`、`CodingKeys`、`singleValue` 為零筆；只有 `OrderStatusTests` 鎖了 `merged`、`pickedUp` 兩個 raw value 與兩組 `allCases` 相對順序；`SchemaMigrationTests.makeOrder` 的 `items` 固定是 `[]`，且舊 store 由同一個 binary 建立。改內嵌型別的鍵、stored property 或其他 raw value 時，現有測試仍會全綠 (t23、t22 審查指出，主對話查證屬實)。
- `.github/workflows/ci.yml` 的 `codegen` job 跑 `bun run check`、`bun test`、`bun run typecheck`；`ios-unit-tests` 與 `ui-regression` 不依賴它 (沒有 `needs:`)。`main` 分支沒有 branch protection 與 ruleset (以 GitHub API 查詢 `branches/main/protection` 回 404、`rulesets` 回空陣列)，移除 job 不會留下永遠等不到的必要檢查。
- **進行中的其他 change 與 session**：
  - 主目錄 (`features/test-suite-convention-alignment`，主對話 t6) 改到 `apps/ios/CLAUDE.md`、`apps/ios/README.md`、`.claude/rules/ios-design-system.md` 與 `Guards/TestSuiteIntegrityTests.swift`，並把 `KeyboardDismissTests` 改名為 `OrderEditKeyboardDismissUITests`；它的新守門以 `SwiftSourceFiles.swiftFiles(under:)` 呼叫預設值。主目錄目前有兩百多筆未提交改動。
  - worktree `features-new-requirement` (`features/custom-fee-items`，主對話 t1v) 的 `custom-fee-items` 要改 `shared/data-model/schema/` 的 `LedgerOrder.yaml`、`PaymentMethodInfo.yaml`，以 `bun run check` 為驗收，也改 `LedgerOrder.swift`、`PaymentMethodInfo.swift`；它規劃的 `SchemaShapeGuardTests.swift` 比對各版 `@Model` entity 的 `entityVersionHashesByName` 與屬性形狀。
  - 三個 checkout 共用同一台 iPhone 17 與 iPad Air 模擬器；`hc ls` 只顯示 idle／working／done，看不出是否正在跑測試。
- worktree 內的 `spectra` 指令讀寫主目錄 (`/Users/leoho/Develop/BuyLedger`)；`features/remove-codegen` 由本 worktree 簽出，git 不允許主目錄同時簽出同一分支 (以 `git worktree list` 確認)。

## Goals / Non-Goals

**Goals:**

- Swift 原始碼成為資料形狀的唯一來源，repo 不再有 schema、generator、生成檔、Bun 工具鏈與 codegen CI job。
- `Core/Domain/` 內每個原本生成的型別，其宣告與領域層 extension 集中在同名檔 (`+Samples` 範例資料檔除外)，排版符合 ios-dev-kit。
- App 行為、SwiftData 指紋、存進記錄的值形狀與所有既有 init 簽章維持不變，且持久化形狀由測試鎖住。
- 守門掃描、文件、規則與 spec 不再描述生成檔或跨平台 schema。

**Non-Goals:**

- 不併入 `Campaign+Samples.swift` 與 `LedgerOrder+Samples.swift` (使用者選擇保留獨立檔)，兩檔仍是跨檔 extension，是已知且刻意保留的 kit 例外。
- 不搬動 `Core/Domain/` 以外的 extension：Feature 層的 `LedgerOrder+OrderMutation.swift`、`OrderStatus+Presentation.swift` 受分層規則約束 (`app-layer-boundaries` 要求領域到視覺的對應留在 orders feature)，測試 target 的 `+Fixture`、`+TestSupport` 是 kit 允許的例外。
- 不改 `LedgerOrderItem.init` 的 `id: UUID = UUID()` 預設值與 `init(from:)` 內產生新 `id` 的行為：屬依賴注入議題，與移除 codegen 無關。
- 不為內嵌值型別預先凍結各版本副本，也不修改 `.claude/skills/swiftdata-schema-migration/SKILL.md`：本 change 不改任何形狀；「刻意變更內嵌值型別」的做法先寫進規則，skill 補充記為後續工作 (t23 建議)。
- 不改 `openspec/changes/archive/` 與各 spec 的 `<!-- @trace -->` 區塊 (歷史紀錄)；`.archify/` 的各 Feature 架構圖 (`architecture-buyledger-features-20261024-132242/`) 不重繪：它們沒有 codegen 內容；改動路徑中只有 Insights 圖引用 `Features/Insights/Domain/InsightsStats.swift`，證據釘在舊 revision 仍可開啟，`stats` 節點的說明 (趨勢、類別、成本與開團排行仍由 `InsightsStats` 對外提供) 在 3.3、3.4 後仍成立 (7.5 t23 第二輪以 `git diff --name-only HEAD` 的路徑逐一搜尋各 Feature 圖確認)。只有整體架構圖重繪 (見 Decisions「整體架構圖在本 change 重繪」)。
- 不為日後的跨平台需求預先定義契約：出現第二個平台或匯出／同步格式時，在那個邊界另訂 DTO 或 wire schema，不讓領域型別兼任；generator 可從本 change 的刪除 commit 取回 (t23 建議，主對話採納)。
- 不重新設計任何領域型別的欄位、遵循的 protocol 或存取層級。

## Decisions

### 持久化形狀先以測試鎖住

使用者選擇新增測試；內容與第二輪審查後的調整由主對話採納 t22、t23 建議。在合併前新增 `apps/ios/BuyLedgerTests/Core/Persistence/PersistedValueShapeTests.swift` (Swift Testing，依 ios-dev-kit `tests/Tests.swift` 樣板，測試名 `<方法>_<情境>_<預期>`，Given／When／Then，預期值寫字面值)：

- `LedgerOrderItem`：Given 固定 `id` (依 `.claude/rules/ios-unit-tests.md` 以 `UUID(0)` 這類固定值)、整數單價 (例如 `1200`，不用經 `Double` 轉換的小數字面值)，以 `JSONEncoder` (`.sortedKeys`) 編碼後的字串等於 `{"name":"Tote","quantity":2,"unitPrice":1200}` 這類字面值；不含 `id` 的 JSON 可解碼，且只比對 `name`、`quantity`、`unitPrice` (解碼會產生新的 `id`，不整筆比對)。
- `LedgerCustomer`：編碼輸出的鍵為 `initials`、`name`、`tier`；以 `Mirror` 列出 stored property 的標籤與型別，依宣告順序等於 `name: String`、`initials: String`、`tier: CustomerTier` (t23 建議，補上 JSON 擋不住的「新增 optional 欄位」與宣告順序)。
- raw value：`OrderStatus`、`CampaignStatus`、`PaymentReceiptStatus` 以 `Set(allCases.map(\.rawValue))` 比對字面值集合 (不比順序，順序不落盤，避免畫面調整順序造成誤報)；`CustomerTier` 沒有 `CaseIterable`，以不含 `default` 的窮舉 `switch` 把每個 case 對到字面值，新增 case 時測試無法編譯；內建幣別常數 `twd`、`krw`、`jpy`、`usd`、`cny` 的 `rawValue` 等於 `TWD`、`KRW`、`JPY`、`USD`、`CNY`。
- `CurrencyCode` 的單值字串編解碼保留一條斷言，作為本次搬移 Codable extension 的安全網，不屬於持久化需求。
- 失敗訊息寫明「持久化形狀改變，見 `.claude/rules/ios-data-layer.md`」。

測試在生成檔還在時先通過，合併後不改任何字面值仍通過，才算資料形狀不變。變異驗證暫時刪除 `LedgerOrderItem` 的 `CodingKeys`、`init(from:)` 與 `encode(to:)` 改回合成 `Codable`，測試要轉紅 (t22 指出原本「`CodingKeys` 加 `id`」不會改變編碼輸出)。

與 `custom-fee-items` 的 `SchemaShapeGuardTests.swift` 分工：本檔鎖指紋看不到的內容層 (陣列以整塊資料儲存時的編碼鍵、字串欄位的 raw value) 與 `LedgerCustomer` 的欄位清單；後者鎖各版 entity 的結構層 (`entityVersionHashesByName` 與屬性形狀)。兩者不重疊，`custom-fee-items` 落地前，結構層由本 change 的「合併前後比對 SwiftData 指紋」一次性量測補位。

檔名與位置是主對話代選的 kit 例外：kit `project-structure.md` 只為 Service 等型別寫單元測試、檔名為 `<TypeUnderTest>Tests`、位置鏡像主 target；本檔跨多個領域型別鎖的是持久化形狀，放 `Core/Persistence/` 並以用途命名，style 閘門不判違規 (t22 審查指出需記錄)。

替代方案：只寫規則不加測試 (使用者未採用)；鎖 enum 順序 (t23 指出會誤報，主對話未採用)。

### 合併前後比對 SwiftData 指紋

主對話採納 t23 建議。Goal 宣稱指紋不變，但上述測試與 `SchemaMigrationTests` 都不是指紋本身。主對話在 2.1 通過後、合併前，以量完即刪的暫時測試對每個保留版本以 `Schema(versionedSchema:)` 與 `NSManagedObjectModel.makeManagedObjectModel(for:)` 印出 `entityVersionHashesByName`，7.2 合併後再印一次，兩次逐字相同才算成立；暫時測試以 `shasum` 確認還原。這不新增常駐檔案，不搶 `SchemaShapeGuardTests` 的常駐職責。規劃時這兩個 API 在 iOS 26 的可用性未實測；2.1 與 7.2 已以它們量到 28 筆指紋 (見「實作與驗證」)。

### 生成宣告依 kit 同檔分區併回同名手寫檔

使用者選擇。每個型別的檔案結構：

- 本體：`// MARK: - Properties` 放 `static let` (原本寫在 extension 的一併移入，static 在前) 與 stored properties (名稱、型別、`let`／`var`、順序與生成檔相同)，再接 `// MARK: - Init` (有顯式 init 時)。enum 本體先放 cases (不加 `// MARK: - Cases`)，有 `static let` 時接在 cases 之後的 `// MARK: - Properties`：kit 的 enum 樣板「本體只放 cases」沒有涵蓋帶 `static let` 的 enum，此排列由主對話代選，比照 kit `file-templates.md`「手寫 `init?(rawValue:)` 放在本體 cases 之後的 `// MARK: - Init`」的先例。
- extension：Nested Types → Computed Properties → Internal Method → protocol 遵循 (依 protocol 名稱字母序) → Private Method，沿用手寫檔既有內容。
- 自動合成的遵循留在型別宣告行；有手寫實作的遵循 (`CampaignStatus`／`OrderStatus`／`PaymentReceiptStatus`／`CurrencyCode` 的 `Identifiable`、`CurrencyCode` 與 `LedgerOrderItem` 的 `Codable`) 各自一個 `// MARK: - <Protocol>` extension，extension 內不再有子 MARK。
- 改到的檔整檔對齊：computed property 本體另起一行 (含 `CurrencyCode.code` 與各型別的 `id`)、init 補 `- Parameters`、文件註解沿用生成檔的 doc 文字，不符 kit `coding-style.md` 寫法時改寫 (例如 `id` 的屬性 doc 改成名詞片語「穩定識別值，即實際保存的原始字串」、`LedgerOrderItem.init` 的摘要改寫：t24、t25 實作時改寫，t22、t23 審查指出與原措辭不符，主對話採納改寫並更新本條)。檔頭沿用手寫檔原本的 `Created by` 日期；新檔 `LedgerCustomer.swift` 從 kit `domain/Model.swift` 樣板建立。

| 型別 | 本體 | 同檔 extension |
| --- | --- | --- |
| `Campaign` | 7 個 stored properties | Computed Properties (`isSettled`、`reminderTitle`)、Internal Method (`evaluatingAutoClose`) |
| `CampaignStatus` | cases | Computed Properties (`title`)、Identifiable |
| `CurrencyCode` | `defaults`、`twd`、`krw`、`jpy`、`usd`、`cny`、`rawValue` | Computed Properties (`code`)、Codable、Identifiable |
| `CustomerTier` | cases | Nested Types (`DisplayTitle`)、Computed Properties (`title`) |
| `FxRateSnapshot` | `fallback`、`date`、`base`、`rates` | Internal Method (`twdRate`) |
| `LedgerCustomer` | `name`、`initials`、`tier` | 無 |
| `LedgerOrder` | `maxPhotoCount` 與 26 個 stored properties | 既有 Computed Properties、Internal Method |
| `LedgerOrderItem` | 4 個 stored properties、Init | Nested Types (`CodingKeys`)、Computed Properties (`subtotal`)、Codable |
| `OrderStatus` | cases、`realizedStatuses`、`deliveryStatuses` | Computed Properties (`title`)、Identifiable |
| `PaymentMethodInfo` | 4 個 stored properties、Init (兩個) | Computed Properties (`currentFlags`) |
| `PaymentReceiptStatus` | cases | Computed Properties (`title`)、Identifiable |

替代方案：所有成員寫進型別本體 (違反 kit 分區，使用者未採用)；保留 `Generated/` 子目錄只改排版 (仍是跨檔 extension)。

### Campaign 改用合成的 memberwise init

主對話代選，t22、t23 審查同意。生成檔的顯式 init 與合成的 memberwise init 參數標籤、順序完全相同，`closeDate`／`settledDate` 是 optional `var`，合成版同樣給 `nil` 預設值；依 `apps/ios/CLAUDE.md`「能用合成的 memberwise init 就用」刪除顯式 init。替代方案是保留顯式 init 並補 `- Parameters`，但它不提供轉換或驗證，屬於該條規則禁止的情況。

### LedgerOrderItem 的 CodingKeys 移到 Nested Types

主對話代選，t23 審查同意。kit 樣板把 `CodingKeys` 放在型別的 `// MARK: - Nested Types` extension、Codable extension 只放 `init(from:)` 與 `encode(to:)`；現行手寫檔把 `CodingKeys` 與 `// MARK: - Nested Types`、`// MARK: - Init` 寫在 Codable extension 內部。搬移後保留 `private` 與三個 case (`name`、`quantity`、`unitPrice`)，刪除 Codable extension 內的兩個子 MARK，`init(from:)` 與 `encode(to:)` 的實作行不變，由「持久化形狀先以測試鎖住」的測試確認編碼不變。保留 `LedgerOrderItem` 的顯式 init：`id` 的 `UUID()` 預設值無法由合成 init 提供。

### PaymentMethodInfo 在本體寫出 memberwise init

使用者選擇。kit 規定 Init 在本體，把 `init(name:flags:)` 移入本體後 Swift 不再合成 memberwise init，而 `PaymentMethodInfo(name:isCardless:isBankTransfer:isCashOnDelivery:)` 在 App 與測試有 56 處呼叫 (實測：`grep -rn -A2 'PaymentMethodInfo(' --include='*.swift' apps/ios` 的結果中含 `isCardless:` 的行數)，因此本體同時寫出四參數 init 與 `init(name:flags:)`，兩者都補 `- Parameters`。這與 `apps/ios/CLAUDE.md`「不為補註解新增顯式 init，能用合成的 memberwise init 就用」衝突 (t22 審查指出)，使用者裁定此處依 kit 的 Init 位置；style 閘門不判此四參數 init 為違規。替代方案：`init(name:flags:)` 留在同檔 extension 以保留合成 init (kit 沒有 extension 內的 Init 區，使用者未採用)。

### Money 刪除

使用者選擇。全專案沒有引用，刪除生成檔即可，不新增手寫檔。

### SwiftSourceFiles 移除生成檔參數

主對話代選，t23 審查同意。`Generated/` 消失後 `shouldIncludeGenerated` 的兩種值行為相同，保留參數只會留下描述不存在目錄的死碼：移除參數與排除邏輯，10 個傳 `true` 的呼叫端改為不帶參數。提到生成檔的 doc comment 一併改寫：`SwiftSourceFiles.swiftFiles` 的參數與回傳說明、`LayerBoundaryScanner.coreDomainTopLevelDeclarationNames` 與 `coreDomainRoot`、`LayerBoundaryTests` 領域清單測試的說明與 Note、`ViewAnimationSwitchScanTests.countMatches`、`AccessibilityIdentifierScanTests.sourceFiles`、`NumericInputGroupingScanTests.productionRoot`。原本用預設值的掃描合併後會開始讀到原生成宣告 (只有 stored property、init 與 `id`)，預期不會命中任何規則，以建置後的完整單元測試為準。主目錄 `test-suite-convention-alignment` 的新守門只用預設值呼叫，合併後仍可編譯。

### 領域清單測試改由檔名推導

主對話採納 t23 建議 (二選一中的檔名推導)，第二輪再依 t22、t23 補強。`LayerBoundaryTests.coreDomainTopLevelDeclarationNames_含生成檔的領域目錄_收錄必要型別` 改名為 `coreDomainTopLevelDeclarationNames_領域目錄_收錄每個檔名對應的型別`，不再維護手寫名單：

- 預期名稱以獨立於 `SwiftSourceFiles` 的方式列檔 (例如 `FileManager.default.subpaths(atPath:)`)，取 `LayerBoundaryScanner.coreDomainRoot` 下 `.swift` 且檔名不含 `+` 的檔名主幹；這樣在 `SwiftSourceFiles` 重新加入排除時，掃描清單會少名字而預期名稱不會，測試轉紅。
- 斷言預期名稱非空、每個都在掃描清單內，並另以字面值錨點斷言清單包含 `LedgerOrder` 與 `OrderStatus`，避免根目錄指到另一個存在且一檔一型的目錄時仍綠。
- 合併後 `Core/Domain/` 有 17 個不含 `+` 的檔，每檔宣告一個與檔名同名的頂層型別 (主對話以 `grep -E "^(struct|enum|final class|class|actor) <檔名>"` 確認：合併前只有 10 個原生成型別的手寫檔不符，合併後應全部相符)；合併前因 `Generated/` 的 `X.generated` 主幹與只有 extension 的手寫檔而必然失敗，4.1 已註明。

替代方案：維持 4 個名稱抽樣並把 spec 情境降級 (主對話未採用)。

### shared 目錄刪除並列為保留目錄

主對話代選，t23 審查同意。`shared/` 的唯一內容是 `shared/data-model`，依「不留 stub」整個刪除；root `CLAUDE.md` 的佈局規則「跨平台共享內容放 `shared/`」保留為未來慣例，root `README.md` 的結構樹把 `shared/` 標為「(未來，尚未建立)」，與 `apps/android` 相同處理。`monorepo-layout` spec 同步改寫。

### CI 移除 codegen job

刪除 `codegen` job 與其 Bun 設定，檔頭註解改為只描述 iOS 單元測試與手動 UI 回歸；`ios-unit-tests`、`ui-regression` 不變。`ci-guardrails` 的 delta 只描述現行要守的 iOS 單元測試，不寫「不得有 codegen job」這類否定條文 (t22、t23 審查指出它會誤傷日後釘選 Node 版本的設定，主對話採納)。

### 文件與規則同步

- root `CLAUDE.md`：刪除「跨平台 Data Model (codegen)」整節；其餘提及「shared 模組」的條件式規則 (規則放置層級) 仍適用未來的 shared 模組，不改。
- root `README.md`、`AGENTS.md`：移除 `shared/data-model` 的結構與 `shared/data-model/CLAUDE.md` 範例；CI 註解改為 iOS 單元測試。
- `apps/ios/README.md`：結構樹刪除 `Generated/` 並把 `Core/Domain/` 的說明改為「領域 model」；開發環境設定刪除 Bun 與「見第 6 節」；CI 節改為一個 push／PR job 加手動 UI 回歸；刪除「重新產生 data model (codegen)」節並把後續節次往前遞補；架構速覽的「`CampaignReminderRecord` 是唯一的 iOS-only 表，不入跨平台 schema」改成以裝置本機資料說明。
- `apps/ios/CLAUDE.md`：規則檔對照表的 `ios-data-layer.md` 涵蓋範圍刪除「生成型別」，`LayerBoundaryTests` 子條目不再提 `Generated/`。
- `.claude/rules/ios-data-layer.md`：
  - 刪除「生成型別 (`Core/Domain/Generated/`)」節，frontmatter 的測試 paths 樣式加入 `Shape`，讓改 `PersistedValueShapeTests` 時載入本規則 (t23 指出原樣式不涵蓋此檔名)。
  - 在「Schema 與遷移」新增 (t22、t23 審查建議，主對話採納並依第二輪修正措辭)：`LedgerCustomer` (含 `CustomerTier`)、`OrderStatus`、`LedgerOrderItem` 內嵌於 `OrderRecord` 與各版 shadow，shadow 沒有替它們凍結；改內嵌 struct 的鍵或 stored property 會同時改變所有保留版本讀取既有資料列的方式，要刻意變更時先在每個保留版本的 shadow 內凍結一份舊形狀並改引用它，再以落地 store 遷移測試判定 (凍結副本能否保住指紋未實測，不憑推測)，並 invoke `/swiftdata-schema-migration`。
  - 同節：`CampaignStatus`、`PaymentReceiptStatus` 以 raw value 字串存進記錄，移除或改名 raw value 會讓讀取既有資料列失敗，需要遷移；內建幣別常數的代碼以 `CurrencyCode(rawValue:)` 讀回、不會失敗，改代碼會讓既有資料列不再等於該常數而靜默算錯 (7.5 t23 審查指出，主對話以 `OrderRecord` 讀回幣別的程式碼查證)。內嵌的 `OrderStatus`、`CustomerTier` 與上述兩個 enum 新增 case 只更新 `PersistedValueShapeTests` 的字面值，改名或移除 raw value 比照內嵌 struct 的刻意變更處理。
  - 同節：新的內嵌值型別要在同一個 change 加進 `PersistedValueShapeTests`；`LedgerOrderItem` 的自訂 `Codable` 刻意不寫出 `id`，不改回合成 `Codable`。
- `.claude/rules/ios-design-system.md`：`LayerBoundaryTests` 的掃描範圍改寫為 `Core/Domain/` 全部檔案。
- `.claude/rules/ios-integrations.md`：「提醒連結不進跨平台 `Campaign` schema，寫進生成型別會違反平台中立」改成「不進 `Campaign` 領域型別：`eventIdentifier` 是裝置本機資料」(t22 審查與主對話自審指出)。
- `openspec/specs/code-comment-currency/spec.md` 的 Purpose 刪除「產生檔註解僅回報不編輯」：delta 動不到 Purpose，改在 archive 後手改，避免 archive 前 Purpose 與仍存在的需求不一致 (t23 建議，步驟見 Migration Plan)。

### contributesToCategoryBreakdown 改名

使用者選擇 (2026-11-15，7.5 t22 style 閘門指出)。`LedgerOrder` 的 `Bool` 屬性 `contributesToCategoryBreakdown` 不以 `is`／`has`／`can`／`should` 開頭，違反 kit `coding-style.md` 的 `Bool` 命名；`LedgerOrder.swift` 本次改到，依「改到的檔一律整檔對齊」要改名。新名稱 `isCountedInCategoryBreakdown` 由主對話代選，對應現行 doc「是否計入「類別收益」彙總」，判定邏輯與 doc 不變。

範圍因此擴大到 `Features/Insights/Domain/InsightsStats.swift` (唯一呼叫端，以 `grep -rn contributesToCategoryBreakdown` 確認) 與 `.claude/rules/ios-data-layer.md` 的引用；`InsightsStats.swift` 因本次改到而整檔對齊 kit，判定與彙總邏輯不變。替代方案：記為例外、另開後續工作 (使用者未採用)。

### 走勢計算抽成獨立型別

使用者選擇 (2026-11-15，7.5 第二輪 t22 指出)。`Features/Insights/Domain/InsightsStats+Trend.swift` 是 `InsightsStats` 的跨檔 extension (kit `formatting.md`「避免跨檔 extension 自己的型別」，且不在已記錄的例外內)，`InsightsStats.swift` 因 3.3 改到，依 kit「先拆責任，再拆型別，不拆檔案」把走勢計算抽成獨立型別。

- 新型別 `InsightsTrend` (名稱與形狀由主對話代選)：放在 `Features/Insights/Domain/InsightsTrend.swift` 的無 case enum，只有 static func，依 `apps/ios/CLAUDE.md`「純計算放無 case 的 enum，只放 `static func`」；三個 internal 函式 `makeTrendBuckets(attributedOrders:range:calendar:now:)`、`previousPeriodProfit(...)`、`comparisonRatio(current:previous:)` 與兩個 private 函式 (`dailyTrendBuckets`、`monthlyTrendBuckets`) 從 `InsightsStats+Trend.swift` 原樣搬入，簽章、本體與 doc 的計算描述不變，排版依 kit 分區；唯一例外是 `previousPeriodProfit` 內與 `guard total != 0` 不符的 `//` 註解 (原文只講「沒有訂單」，漏了合計為零)，依 7.5 第三輪 t22 審查修正 (主對話代選：註解與程式碼矛盾比破壞逐字搬移更糟，且不影響行為)。
- 呼叫端只有 `InsightsStats.init` 三處 (以 `grep -rn "makeTrendBuckets\|previousPeriodProfit\|comparisonRatio" apps/ios` 確認)，改呼叫 `InsightsTrend.*`；`InsightsStats+Trend.swift` 刪除。檔頭沿用原檔的 `Created by` 日期 (程式碼搬移，不是新寫)。
- 測試不改：走勢行為由 `InsightsStatsTests` 經 `InsightsStats.trendBuckets`／`trendRatio` 驗證，`InsightsFeatureScreenStateTests` 也讀 `trendBuckets`，搬移後結果必須相同。
- 替代方案：併回 `InsightsStats.swift` (約 370 行，使用者未採用)；記為已知例外或另開後續工作 (使用者未採用)。`custom-fee-items` 5.2 也改 `InsightsStats` 的成本組成，該 change ingest 時以抽出後的結構為準 (見 Risks)。

### 整體架構圖在本 change 重繪

使用者選擇 (2026-11-15，7.5 t23 審查指出 root `README.md` 與 `apps/ios/README.md` 仍把讀者指向畫著 codegen 產線的整體架構圖)。Supersedes：Non-Goals 原本寫「不重繪 `.archify/` 的架構圖快照，重繪另記為後續工作」。

以 `/archify` 重新產出整體架構圖：以 `.archify/architecture-buyledger-20261024-115559/candidate.json` 為底，在新的時間戳資料夾移除 `datamodel-gen` 節點及其關係 (如 `codegen-to-models`)，領域 model 的證據改指 `apps/ios/BuyLedger/Core/Domain/` 的同名檔，以 `finalize --repo-root` 產出，再刪除舊資料夾，不保留過時的圖。各 Feature 架構圖不在範圍 (見 Non-Goals)。兩份 README 對 `.archify/` 的引用是通用描述，不綁資料夾名稱，不需要改。

`swiftdata-schema-migration` skill 補「刻意變更內嵌值型別」的做法仍是後續工作 (見 Non-Goals)；archive 會把本檔移入歷史，主對話另記到 archive 後仍查得到的 roadmap 記錄 (t23 建議)。

### 審查後補鎖 LedgerOrderItem 的 stored property

主對話採納 7.5 t23 建議。spec「Value shapes stored in persisted records are locked by a test」要求每個內嵌 struct 都鎖住 stored property 清單，2.1 只替 `LedgerCustomer` 寫了 `Mirror` 測試；在 `PersistedValueShapeTests` 補一條 `LedgerOrderItem` 的 `Mirror` 測試 (預期 `id: UUID`、`name: String`、`quantity: Int`、`unitPrice: NSDecimal`：Apple 平台上 `Decimal` 的執行期型別名稱，7.2 實測後更正)。這條在合併後才加入，無法在生成檔仍存在時先通過；合併前後形狀相同的根據是 t22、t23 與主對話以 `git show HEAD:` 對生成檔的逐行比對 (宣告行與 stored property 相同)。

### 最終驗收不跑 UI 主回歸

使用者選擇 (2026-11-15，apply 中)。原計畫依 2026-10-18 的裁決在 iPhone 17 與 iPad Air 各跑一次 UI 主回歸；本 change 沒有改畫面程式與 accessibility identifier，UI 回歸能多抓的只有真實 App 經合併後型別讀寫訂單、分析頁走勢呈現兩類，已由 `PersistedValueShapeTests`、合併前後指紋比對、`SchemaMigrationTests`、`InsightsStatsTests` 系列與分析頁 snapshot 在完整 `BuyLedgerTests` 守住，而 iPhone 一輪約 100 分鐘 (t6 的實測) 且要與其他 checkout 輪流使用模擬器。主對話提出的三個選項中，使用者選擇不跑 UI 回歸 (另兩個是照原計畫、只跑冒煙測試)，以完整 `BuyLedgerTests` 為最終驗收。

### archive 等主目錄收尾後在主目錄執行

使用者選擇；第二輪審查指出主目錄無法簽出本 worktree 已簽出的分支，使用者改定「先提交再 amend 成一筆」。實作與驗證都在本 worktree 完成；`test-suite-convention-alignment` 提交後，依 Migration Plan 在 worktree 提交、釋放分支、於主目錄 archive，再把 archive 結果 amend 進同一筆 commit。不使用 `git worktree remove --force` (會丟掉未提交的實作)。archive 屬於全部 task 完成後的收尾，不列為 task。

## Implementation Contract

- **行為**：App 的畫面、資料讀寫與遷移行為不變；開發者在 `Core/Domain/<Type>.swift` 一處找到型別的 stored properties、init 與領域層 extension (`+Samples` 範例資料檔除外)。
- **資料形狀不變式** (每個合併型別都要成立)：
  - stored property 的名稱、型別、`let`／`var` 與宣告順序與生成檔相同；enum 的 cases、raw value 與順序相同。
  - 型別宣告行的遵循集合與生成檔相同 (`Codable`、`Equatable`、`Hashable`、`Identifiable`、`CaseIterable`、`Sendable` 各依原狀)，手寫遵循的實作逐行不變。
  - `PersistedValueShapeTests` 在合併前後都通過，且合併時沒有改動它的任何字面值；合併前後各保留版本的 `entityVersionHashesByName` 逐字相同 (API 無法使用時記錄原因)。
  - 既有 init 呼叫形式全部可編譯：`Campaign(id:name:openDate:closeDate:status:settledDate:notes:)` (`closeDate`／`settledDate` 可省略)、`LedgerOrderItem(id:name:quantity:unitPrice:)` (`id` 可省略)、`PaymentMethodInfo` 的四參數與 `(name:flags:)` 兩種、其餘型別的合成 memberwise init。
- **移除後的 repo 狀態**：`apps/ios/BuyLedger/Core/Domain/Generated/` 與 `shared/` 不存在；`.github/workflows/ci.yml` 只有 `ios-unit-tests` 與 `ui-regression` 兩個 job，且可被 YAML 解析器讀取；`.gitignore` 沒有 generator 的 `node_modules` 規則。
- **殘留引用檢查**：在 repo 根目錄以 `grep -rniE 'datamodel-gen|data-model|Generated/|\.generated\.swift|bun run|\bbun\b|shouldIncludeGenerated|codegen|生成檔|生成型別|生成宣告|生成領域|產生檔|跨平台.*(schema|Campaign)'` 搜尋，排除 `.git/`、`openspec/` (現行 spec 由 archive 套用 delta 後才更新，archive 後另行確認) 與 skill 目錄 (`.claude/skills`、`.agents/skills` 等的通用詞) 後，每一筆結果都要逐一判讀並記錄為「與 codegen 無關」(例如 String Catalog 的 `GeneratedStringSymbols`)；與 codegen 相關的結果必須為零。
- **驗收**：
  - `PersistedValueShapeTests` 在生成檔還在時通過 (3.1、3.2 開始前)，合併後仍通過；指紋比對見上。
  - iOS 與 iPadOS 模擬器建置成功；`BuyLedgerTests` 全部通過 (含 `PersistedValueShapeTests`、`SchemaMigrationTests`、`LayerBoundaryTests`、各守門掃描與 snapshot)，或失敗清單與基準相同。
  - 變異驗證 (每次只跑對應類別，還原後以 `shasum` 確認與變異前相同)：
    1. 暫時讓 `Shared/DesignSystem/` 某檔引用 `LedgerCustomer`，`findViolations_設計系統目錄_不引用領域型別` 轉紅。
    2. 暫時在該檔加入 `import ComposableArchitecture`，對應守門轉紅。
    3. 暫時把 `LayerBoundaryScanner.coreDomainRoot` 指到不存在的子路徑，領域清單測試轉紅；設計系統引用測試是否同時轉紅取決於 `FileManager.enumerator(at:)` 對不存在路徑的行為，照實記錄。
    4. 暫時刪除 `LedgerOrderItem` 的 `CodingKeys`、`init(from:)` 與 `encode(to:)` 改回合成 `Codable`，`PersistedValueShapeTests` 轉紅。
  - 最終驗收是 iPhone 17 (iOS 26.5) 完整 `BuyLedgerTests`，不跑 UI 主回歸 (見 Decisions「最終驗收不跑 UI 主回歸」)。
- **範圍**：只動 Proposal Impact 列出的檔案與目錄；不改 SwiftData `@Model`、`BuyLedgerSchema` 與其他守門的判定邏輯；Feature 程式碼只改 `InsightsStats.swift` 的改名呼叫端與其整檔對齊 (見「contributesToCategoryBreakdown 改名」)，以及把 `InsightsStats+Trend.swift` 抽成 `InsightsTrend.swift` (見「走勢計算抽成獨立型別」)。
- **走勢抽出**：`InsightsStats+Trend.swift` 不存在；`Features/Insights/` 下沒有 `extension InsightsStats` 出現在 `InsightsStats.swift` 以外的檔案；`InsightsStatsTests`、`InsightsStatsBreakdownTests`、`InsightsAttributionTests`、`InsightsFeatureScreenStateTests` 全綠且未修改。
- **改名**：`grep -rn contributesToCategoryBreakdown apps .claude` 無結果；`isCountedInCategoryBreakdown` 的判定與 `InsightsStats` 的彙總結果不變，由 `InsightsStatsTests`、`InsightsStatsBreakdownTests`、`InsightsAttributionTests` 守住。
- **架構圖**：`.archify/architecture-buyledger-20261024-115559/` 不存在，新的整體架構圖資料夾只有一份，archify `finalize` 的自動檢查通過，殘留引用檢查對 `.archify/` 為零。

## Risks / Trade-offs

- [合併時誤改內嵌型別的鍵、stored property 或 raw value，會同時改變所有保留版本讀取既有資料列的方式] → `PersistedValueShapeTests` 在合併前先綠、合併後仍綠，`LedgerCustomer` 的欄位清單與順序由 `Mirror` 鎖住；合併前後比對指紋；stored property 宣告順序沒有編譯器把關的是有顯式 init 的 `LedgerOrderItem` 與 `PaymentMethodInfo`，t23 逐欄比對以這兩型為重點。
- [enum 帶 `static let` 的排列是 kit 未涵蓋的主對話代選] → 記錄在 Decisions；style 閘門若判定不合 kit，回報使用者並以 ios-dev-kit session 修規範後依新版調整。
- [`custom-fee-items` 的 schema 任務與 `bun run check` 驗收在本 change 合併後全部失效，且兩者都改 `LedgerOrder.swift`、`PaymentMethodInfo.swift`、`InsightsStats.swift` (後者因改名與走勢抽出才列入，`InsightsStats+Trend.swift` 也改成 `InsightsTrend.swift`)] → 本 change 先合併；`custom-fee-items` apply 前先以 `/spectra-ingest` 改寫 codegen 相關任務，並沿用 `PersistedValueShapeTests` 與本 change 的規則 (t23 審查指出)。
- [主目錄 `test-suite-convention-alignment` 同時改 `apps/ios/CLAUDE.md`、`apps/ios/README.md`、`.claude/rules/ios-design-system.md`] → 兩邊改的段落不相鄰，後合併的一方解衝突。
- [沒有 UI 主回歸，真實 App 的整合問題要到下次 UI 回歸才會發現] → 使用者知情的取捨 (見 Decisions「最終驗收不跑 UI 主回歸」)。
- [三個 checkout 共用模擬器，`hc ls` 看不出誰在跑測試，同時跑會互相干擾、失敗可能被誤記為基準] → 長時間測試 (1.1、7.2、7.6) 開始前一律以 `hc send` 通知其他 checkout 的主對話 (目前是 t6 與 t1v，以執行當下的 `hc ls` 為準)，說明預計時段並等對方回覆、期間不啟動測試，跑完再通知解除 (t23 建議)。
- [在主目錄放臨時副本跑 `spectra validate` 會混進對方 `git status --short` 的歸屬比對] → 放副本前後比對主目錄 `git status --short`，先以 `hc send` 知會主目錄主對話，跑完立即刪除。
- [全部 task 完成後要等主目錄的 change 提交才能 archive，期間 worktree 處於「完成但未提交」，`custom-fee-items` 也跟著等] → 使用者知情的取捨 (t23 提醒)。
- [`Campaign` 改用合成 init 後，日後在本體加 stored property 會改變 init 參數] → 與其他使用合成 init 的型別相同，由編譯器指出呼叫端。

## Migration Plan

- 無資料遷移；回滾為 revert 本 change 的 commit。
- 收尾 (全部 task 完成後，依「archive 等主目錄收尾後在主目錄執行」)：
  1. 確認 `test-suite-convention-alignment` 已提交、主目錄 `git status --short` 為空。
  2. 取得使用者針對該筆 commit 的授權後，在 worktree 以明確路徑清單 (本 change 的實作檔與 `openspec/changes/remove-data-model-codegen/`) 提交到 `features/remove-codegen`；worktree 的 change 是手動勾選，主目錄 `.spectra` 沒有 touched 紀錄，不靠 `/spectra-commit` 的歸屬挑檔。
  3. 在 worktree 執行 `git switch --detach` 釋放分支 (不刪除 worktree，不使用 `git worktree remove --force`)。
  4. 主目錄 `git switch features/remove-codegen`。主目錄留有本分支不再忽略的 `shared/data-model/generator/node_modules/` (原本被 `.gitignore` 忽略，切換後 `shared/` 會成為未追蹤目錄)，以及舊整體架構圖資料夾 `.archify/architecture-buyledger-20261024-115559/` 內被忽略的 archify 中間檔 (7.5 最終審查 t23 指出)：確認兩處只剩這些本機產物後，取得使用者同意再刪除，並確認主目錄 `git status --short` 為空；之後執行 `/spectra-archive remove-data-model-codegen`。archive 是否接受手動勾選的 tasks.md 未實測，被拒時回報使用者。
  5. 確認 `openspec/specs/data-model-codegen/` 已被移除 (若留下空殼，回報使用者再處理)，手改 `openspec/specs/code-comment-currency/spec.md` 的 Purpose，並以殘留引用檢查的同一指令只搜 `openspec/specs/` 的非 `@trace` 內文，與 codegen 相關的結果為零。
  6. 依使用者指示把 archive 結果 amend 進第 2 步的 commit，以明確路徑 (`openspec/`) 加入，不用 `git add -A`。
  7. 主目錄切回原本的分支後，worktree 執行 `git switch features/remove-codegen`，確認 HEAD 是 amend 後的 commit、`git status --short` 為空 (第 3 步的 detached HEAD 停在被 amend 取代的舊 commit，不可在上面繼續提交)。
- 收尾後的後續工作 (不在本 change，archive 後記到 roadmap)：本 change 推上遠端後，以新的 commit 重新釘選並重繪整體架構圖 (目前證據釘在 `19ef9ccc`，`Core/Domain` 的連結會打開合併前的內容；圖無法釘到包含它自己、又會被 amend 換掉 hash 的 commit)，`/spectra-review` 建議明確追蹤。

## 實作與驗證

由主對話 t21 執行與記錄。

### 1.1 環境與基準 (2026-11-15)

- 分支 `features/remove-codegen`；`df -h /` 已用 35% (可用 24 GiB)。
- `hc ls` 當下本 worktree 的終端：t21 主對話、t22 與 t23 (leader & reviewer)、t24 `claude-haiku-max-impl`、t25 `claude-sonnet-xhigh-impl`，分工照本檔開頭不變。其他 checkout 的主對話為主目錄 t6、`features-new-requirement` t1v。
- worktree 缺少的 ignored 設定由主目錄補上：`Config.xcconfig`、`GoogleService-Info.plist`、`.claude/settings.local.json`，以及 `projectPath` 改指 worktree 的 `.mobilebuildmcp/config.yaml`；MCP session defaults 設為 worktree 專案、`BuyLedger` scheme、iPhone 17 (iOS 26.5) `CBE3AABB-FFBF-4F91-AFF9-5DD283DDB410`。
- 模擬器協調：t1v 回覆未跑測試並讓出；t6 正在 iPad Air 11-inch (M4) 跑 UI 回歸，要求等它結束，16:20 後通知讓出 iPhone 17，基準跑完已以 `hc send` 交還。
- `spectra status`／`instructions` 在 worktree 回報找不到本 change，依本檔開頭做法改在 tasks.md 直接勾選。
- 基準：iPhone 17 (iOS 26.5，淺色外觀) 完整 `BuyLedgerTests` (scheme 預設測試計畫) 共 2080 個：2077 通過、0 失敗、0 略過、3 個 expected failure (xcresult 摘要的 `expectedFailures`，來自 `ServiceTestValueStrictnessTests` 的三處 `withKnownIssue`，刻意驗證未覆寫的 Service 依賴會回報 issue)，耗時 343 秒，沒有既有失敗。

### 2.1 持久化形狀測試與合併前指紋

- t25 新增 `PersistedValueShapeTests.swift` (11 個測試，`CustomerTier` 以參數化窮舉 `switch` 鎖住)，`swiftc -parse` 通過；`CurrencyCode` 安全網拆成編碼、解碼兩條 (t25 選定，避免同一測試多組 When／Then)。主對話審查未發現問題。
- 生成檔仍在時，iPhone 17 (iOS 26.5) 以 `-only-testing:BuyLedgerTests/PersistedValueShapeTests` 執行：11 通過、0 失敗。
- 合併前指紋：暫時測試以 `Schema(versionedSchema:)` 與 `NSManagedObjectModel.makeManagedObjectModel(for:)` (iOS 26 起的 static 版本) 印出各保留版本的 `entityVersionHashesByName` (base64)，1 通過；量完刪除，`BuyLedgerTests` 目錄全部檔案的 `shasum` 彙總值與放入前相同 (`80d84e725e43d0ba5e8a89745e9478e9a2299249`)。基準如下：

```text
15.0.0 CampaignRecord tDcIfi/yXimEUIjot9R8/QOgTunST8KVcGrSh/R2B1Q=
15.0.0 CampaignReminderRecord oje+l2hhwZ9nLBXw2YMZPLNHTGUfXiqUqXS/jq3OekE=
15.0.0 CategoryRecord r1UlIt2DRmCPeT0TtqPfnRZ5r8ADcl/HLblOQyZ+20s=
15.0.0 CurrencyMetadataRecord Zn7ZAalqaggg4DpKRQC0QAHfN8bHvDUfFzAhpGZLJbU=
15.0.0 OrderRecord IU9P7cG/FDgrnHtaaFbrDk8ZUluugP5S2Y8d2WYdb7M=
15.0.0 OrderSourceRecord Aw47oXvyZWxSeFE9UjtWJc+KZ8U7bZmJn7wejFt7Xck=
15.0.0 PaymentMethodRecord h0C+7rg86fN7r7LVvJYDh2wUfH8Mdv4/VBVbRpv+oWA=
15.0.0 SyncMeta 0+IqACVaqWmsHHuxPTUs1TlYk5yVDBej5BBHjtBNgYY=
15.0.0 SyncQueueItem melhpaPMCpBrhE613q1rbHdyDE8HFe6dWBpAwZqf44Y=
15.0.0 VerificationStatusRecord aOLiHo33YMslZBBUibh8XuJ0zKbA/abrUSTfpShHpV0=
16.0.0 CampaignRecord tDcIfi/yXimEUIjot9R8/QOgTunST8KVcGrSh/R2B1Q=
16.0.0 CampaignReminderRecord oje+l2hhwZ9nLBXw2YMZPLNHTGUfXiqUqXS/jq3OekE=
16.0.0 CategoryRecord r1UlIt2DRmCPeT0TtqPfnRZ5r8ADcl/HLblOQyZ+20s=
16.0.0 CurrencyMetadataRecord Zn7ZAalqaggg4DpKRQC0QAHfN8bHvDUfFzAhpGZLJbU=
16.0.0 OrderRecord zM/cF4kYDk+ZQtQBj2RCygSnl8QjQ40AdBtfmakVknM=
16.0.0 OrderSourceRecord Aw47oXvyZWxSeFE9UjtWJc+KZ8U7bZmJn7wejFt7Xck=
16.0.0 PaymentMethodRecord h0C+7rg86fN7r7LVvJYDh2wUfH8Mdv4/VBVbRpv+oWA=
16.0.0 ReconciliationStatusRecord 8AGq10NLdpSK1hF8qXW0lNT00xRsMEEfoQYEaB+dm3I=
16.0.0 SyncMeta 0+IqACVaqWmsHHuxPTUs1TlYk5yVDBej5BBHjtBNgYY=
16.0.0 SyncQueueItem melhpaPMCpBrhE613q1rbHdyDE8HFe6dWBpAwZqf44Y=
17.0.0 CampaignRecord tDcIfi/yXimEUIjot9R8/QOgTunST8KVcGrSh/R2B1Q=
17.0.0 CampaignReminderRecord oje+l2hhwZ9nLBXw2YMZPLNHTGUfXiqUqXS/jq3OekE=
17.0.0 CategoryRecord r1UlIt2DRmCPeT0TtqPfnRZ5r8ADcl/HLblOQyZ+20s=
17.0.0 CurrencyMetadataRecord Zn7ZAalqaggg4DpKRQC0QAHfN8bHvDUfFzAhpGZLJbU=
17.0.0 OrderRecord zM/cF4kYDk+ZQtQBj2RCygSnl8QjQ40AdBtfmakVknM=
17.0.0 OrderSourceRecord Aw47oXvyZWxSeFE9UjtWJc+KZ8U7bZmJn7wejFt7Xck=
17.0.0 PaymentMethodRecord h0C+7rg86fN7r7LVvJYDh2wUfH8Mdv4/VBVbRpv+oWA=
17.0.0 ReconciliationStatusRecord 8AGq10NLdpSK1hF8qXW0lNT00xRsMEEfoQYEaB+dm3I=
```

### 3.1 至 6.2 實作與 7.5 審查 (2026-11-15)

- 派工：5.1 (t24)、6.1 (t25) 在 1.1 基準後先做；2.1 驗證完成後派 3.1 (t25)、4.1 (t24)，4.1 交回後派 3.2 (t24)。6.1 依 tasks.md 原排在 3.1 之後，主對話代選提前：純文件、沒有前置依賴、沒有測試讀 Markdown。
- 4.1 的派工文件誤寫「只改相關行，不順手重排」，與使用者裁決「改到的檔一律整檔對齊」衝突 (t24 回報指出)；改由 t25 把 11 個守門檔整檔對齊，實際改 3 個檔、只動排版與命名 (主對話代選分工)。
- 主對話審查：3.1、3.2 以 `git show HEAD:` 取生成檔，逐欄比對 11 型的宣告行、stored property 與 enum case，全部相同；`Money` 零引用；`PersistedValueShapeTests` 既有測試的字面值未變。
- 7.5 第一輪 (t22 style 閘門 9 條、t23 形狀與文件 7 條，皆無高嚴重度)：採納的修正由原實作者完成；t22 #7 (`contributesToCategoryBreakdown` 命名) 與 t23 F3 (架構圖) 由使用者裁定在本 change 處理，ingest 成 3.3、6.2 (主目錄副本 validate 通過，analyze 0 Critical／Warning)。
- 第二輪 (t22 5 條、t23 3 條，皆低至中)：t22 A (`InsightsStats+Trend.swift` 跨檔 extension) 由使用者裁定抽成 `InsightsTrend`，ingest 成 3.4 (validate 通過)；其餘採納並修正，其中幣別常數規則的例子經 t22、t23 先後指正，改成有程式碼對應的路徑 (`OrderRecord`、`CurrencyMetadataService`、`SettingsService` 讀回，`FxFeature`、`QuoteRateFeature` 以 `.twd` 判斷)。
- 第三輪 (t22 1 條低)：`InsightsTrend` 內與 `guard total != 0` 不符的註解修正 (見 Decisions)。審查已收斂，主對話不再續開新輪。
- 審查者唯讀：每輪前後比對 `git status --short` 與改動檔雜湊，皆未被修改。t22、t23 不能寫檔，回報以 `hc send` 傳送，主對話存摘要。
- 6.2：t25 以 `/archify` 從舊 `candidate.json` 移除 `schema`、`codegen` 節點、兩條關係、「開發期 · 跨平台資料模型生成」群組與卡片，`models` 改為「Core / Domain」並改指同名檔；依 archify 規定做一輪只改位置的調整，走線交叉由 14 降到 2；t23 指出卡片文字與新規則相反後修正並重跑 `finalize`。新資料夾 `.archify/architecture-buyledger-20261115-181531/`，四道自動檢查通過，receipt 留在 scratchpad 不入 repo；主對話以瀏覽器開啟確認不再有 codegen 產線。已知限制：證據釘在 revision `19ef9ccc` (本 change 未 commit)、舊圖既有的 `BLLayoutClass` 描述仍在、`models` 沒有關係，重繪到現況記為後續工作。
- 7.6 依使用者裁定改為只跑完整 `BuyLedgerTests` (見 Decisions「最終驗收不跑 UI 主回歸」)。

### 7.1 至 7.6 驗證 (2026-11-15，iPhone 17 iOS 26.5 淺色外觀，t6 讓出 19:01–19:21)

- 7.1：刪除已空的 `Core/Domain/Generated/` 後，iOS (iPhone 17) 與 iPadOS (iPad Air 11-inch (M4) iPadOS 27.0) 模擬器建置都成功、無警告；`Package.resolved` 未被刪除、`find apps -type d -name Generated` 無結果、`CURRENT_PROJECT_VERSION` 維持 420。
- 7.2：第一次完整 `BuyLedgerTests` 共 2092 個 (基準 2080，多出的 12 個是 `PersistedValueShapeTests`)，2088 通過、1 失敗、3 個 expected failure (基準同為 3)。唯一失敗是審查後補的 `storedProperties_訂單項目_依宣告順序為識別碼名稱數量與單價()`：Apple 平台上 `type(of:)` 把 `Decimal` 印成 `NSDecimal`，預期字面值寫錯，不是形狀改變；t25 改成 `NSDecimal` 並加註解後，單獨重跑 `PersistedValueShapeTests` 12 通過。`SchemaMigrationTests`、`OrderServiceResidueTests`、`LayerBoundaryTests`、`DesignSystemSourceScanTests`、各守門類別與 Insights 四個類別都在完整測試中通過。
- 7.2 指紋：同一個暫時測試在合併後再量一次，28 筆 `entityVersionHashesByName` 與 2.1 的基準逐字相同 (`diff` 無差異)；量完刪除，測試目錄 `shasum` 彙總值與放入前相同 (`42b975db66eea463dff8198e85cd95cc82374456`)。
- 7.3 變異驗證 (每項只跑對應類別，還原後以 `shasum -c` 確認與變異前相同)：
  1. `Shared/DesignSystem/Foundations/BLHitTarget.swift` 加 `private typealias MutationProbeCustomer = LedgerCustomer`：`findViolations_設計系統目錄_不引用領域型別()` 轉紅 (報出 `BLHitTarget.swift:20 (LedgerCustomer)`)，其餘 6 通過。
  2. 同檔加 `import ComposableArchitecture`：`composableArchitectureImportViolations_設計系統目錄_不匯入狀態管理套件()` 轉紅 (報出第 8 行)，其餘 6 通過。
  3. `LayerBoundaryScanner.coreDomainRoot` 改指 `Core/Domain/MutationProbeMissing`：領域清單測試轉紅 (`subpaths(atPath:)` 回 nil，`#require` 失敗)；設計系統引用測試維持綠燈：`FileManager.enumerator(at:)` 對不存在的路徑沒有回 nil、只是列不出檔案，領域名單為空所以不報違規。
  4. `LedgerOrderItem` 刪除 `CodingKeys`、`init(from:)`、`encode(to:)` 改回合成 `Codable`：`encode_固定識別碼與整數單價_只輸出名稱數量與單價()` (輸出多了 `id`) 與 `decode_缺少識別碼的資料_還原名稱數量與單價()` (`keyNotFound: id`) 轉紅，其餘 10 通過。
- 7.4：殘留引用檢查 (含 `.archify/`) 只命中 worktree 的 `.git` 指標檔 (路徑含分支名)，skill 目錄只有 spectra-discuss 的通用詞，與 codegen 相關為零；`Generated/` 與 `shared/` 不存在，CI 只有 `ios-unit-tests` 與 `ui-regression`，`.gitignore` 沒有 `node_modules` 規則；文件中沒有 `InsightsStats+Trend`、舊名 `contributesToCategoryBreakdown` 與舊架構圖資料夾名。文件同步鐵則逐列對照 `git status --short`：有影響，已同步 (規則：`ios-data-layer.md` 新增持久化形狀規則、root `CLAUDE.md` 刪除 codegen 節；技術棧：`apps/ios/README.md` 刪除 Bun 與 codegen CI；結構：兩份 README 的 `shared/`、`Generated/`；失效描述：改名引用、`ios-integrations.md`、`ios-design-system.md`、`apps/ios/CLAUDE.md`)。`NSDecimal` 型別名稱以測試內註解說明，不另立規則。知會 t6 後在主目錄放副本跑 `spectra validate` 通過 (analyze 0 Critical／Warning、17 則 Suggestion)，刪除副本後主目錄 `git status --short` 與放入前相同。
- 7.6：測試檔在 7.2 之後有修改，不沿用 7.2；最終完整 `BuyLedgerTests` 2092 個，2089 通過、0 失敗、3 個 expected failure (與基準相同)。本 change 依使用者裁定不跑 UI 主回歸。

### archive 前最終審查 (2026-11-15，使用者要求)

- 四份審查同時進行，皆唯讀 (t22、t23 前後雜湊相同)：`/spectra-verify` (0 Critical／Warning，2 則建議)、`/spectra-review` (Swift 無缺陷，1 則建議)、t22 opus-xhigh-reviewer (6 條低)、t23 fable-arch-reviewer (1 條中、5 條低、1 條觀察)。spectra 指令在 worktree 看不到 change，兩個 spectra 審查改以 git 狀態界定範圍。
- 主對話代選的處置：
  - 程式碼 (原實作者修正)：`SwiftSourceFiles`、`LayerBoundaryScanner` 的空 enum 依 kit 樣板改成多行 (t24)；領域清單測試的錨點補上 spec 範例表的 `LedgerCustomer`、`PaymentMethodFlags` (verify 建議，t24)；`LedgerOrder`、`CustomerTier`、`PaymentReceiptStatus` 的型別 doc 改寫成說出用途 (t25、t24；`CustomerTier` 拿掉配色描述，避免領域型別的 doc 隨畫面過時)；`PersistedValueShapeTests` 註解的型別名加反引號 (t25)。
  - 不採納：verify 建議 `LedgerCustomer.swift` 補 `import Foundation`：該檔只用標準函式庫型別，依 kit「只 import 用到的模組」維持不加 (t22 第一輪同判定)。
  - 文件 (主對話更正)：本檔的 `NSDecimal` 預期值、API 可用性已實測、1.1 基準補記總數 2080 與 3 個 expected failure (來自 `ServiceTestValueStrictnessTests` 的 `withKnownIssue`)；Migration Plan 補上主目錄 `shared/` 的 `node_modules` 與舊架構圖中間檔清理 (t23 F1、F2，刪除前取得使用者同意)、amend 不用 `git add -A`、收尾後 worktree 回到分支 (t23 F3)、架構圖重新釘選的後續工作 (`/spectra-review` 建議)；tasks.md 開頭註明實際派工的偏離記在本節 (t23 F5)。
  - 維持現狀：spec 的訂單項目情境只鎖編碼鍵、需求本文已涵蓋 stored property 清單，測試也已補上 (t23 F6)。
  - 記為後續工作 (專案記憶)：內嵌型別名單的自動守門交給 `custom-fee-items` (t23 F7)；`designSystemRoot` 路徑寫錯時設計系統引用測試會空轉 (t22 觀察)。
- 修正後驗證 (純排版、註解與測試錨點，依「中途只跑受影響類別」的分層驗證)：iPhone 17 (iOS 26.5) 以 `-only-testing` 跑 `LayerBoundaryTests` 與 `PersistedValueShapeTests`，含 App 與測試 target 建置，19 通過、0 失敗。當下 `openspec/` 以外全部改動與新增檔的 `shasum` 彙總值為 `1de389a7d48c2bb5338d74e1c545702e5b2d7ad1`，供日後確認測試對應的檔案版本。
