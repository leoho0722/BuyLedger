## Summary

把 Core 層 (現有 71 個 Swift 檔) 與跨平台 codegen 的 Swift 輸出模板，對齊 ios-dev-kit 規範，並修掉其中三處會讓失敗無聲消失的路徑。這是 2026-09-14 全庫審查修正順序的第 1 步。

## Motivation

全庫審查在 Core 與 codegen golden 檔上記錄 69 筆判讀違規、298 筆機械必擋、186 筆機械違規。Core 的錯誤型別、格式化與 doc 慣例被上層每一個 Feature 依賴，若先修 Feature 再回頭改 Core，上層會因為錯誤型別與生成型別再次變動而重做。

三處靜默失敗已造成可觀察的錯誤結果：

- SwiftData 記錄轉領域型別時，無法解析的 rawValue 會靜默降級 (收款狀態變 `.pending`、開團狀態變 `.ongoing`)，使用者看到的是與資料庫不符的假狀態。
- `PhotoClient.importPhotos` 逐張 `catch { continue }`，選 5 張壞 2 張只會回傳 3 張，畫面沒有任何提示。
- `FxRates.toTwd` 以 `Decimal(string:) ?? 0` 建表，解析失敗會得到 0 匯率而不是建置期錯誤。

同時，Core 的錯誤型別把原始錯誤壓成 `message: String` 並遵循 `Equatable`，違反 ios-dev-kit「包裝底層錯誤用 `underlying` 保留原始錯誤、不遵循 `Equatable`」；診斷時拿不到原始 `NSError` 的 domain 與 code。

## Proposed Solution

**錯誤型別保留原始錯誤**：`PersistenceError` 與三個持久化 domain 錯誤、`PersistenceRecoveryError`、`APIError`、`CurrencyMetadataRepositoryError`、`CalendarReminderError`，帶底層錯誤的 case 改為 `underlying: any Error & Sendable` 並移除 `Equatable`。包裝框架錯誤時一律 `error as NSError`；App 自己定義的錯誤 (記錄解析錯誤) 原樣承載不橋接，呼叫端才能 pattern-match 它的欄位。純分類用、不含底層錯誤的 case (如 `APIError.http(statusCode:)`) 維持既有形狀。測試改以 `if case` 比對 case，不比對整個值。`network-error-handling` 既有的「錯誤訊息不得含憑證」不因保留 underlying 而放寬。

本次不改任何 typed throws 簽章所宣告的錯誤型別，只改那些型別內部 case 的 payload 形狀，所以 `persistence-error-contract` 既有的 boundary 契約維持原狀。

**記錄解析失敗改為拋錯**：新增 `RecordDecodingError` 承載「哪一筆記錄的哪個欄位的哪個 rawValue 解析不了」，`OrderRecord` 與 `CampaignRecord` 轉領域型別時把它包進 `PersistenceError.fetchFailed(underlying:)` 拋出，由該次讀取整批失敗，畫面走既有錯誤空狀態。

**照片匯入回報失敗張數**：新增 `PhotoImportResult` (成功資料與失敗張數)，`PhotoClient.importPhotos` 改為回傳它，`OrderEditFeature` 以 inline 文字告知失敗張數；可用的照片照常匯入。

**匯率表改用無 optional 的字面值**：`FxRates.toTwd` 改以 `Decimal(sign:exponent:significand:)` 建構，移除 `?? 0` 掩蓋。

**時間改走依賴注入**：`CurrencyMetadataRepository.live` 保留 `now` 參數但移除 `{ Date() }` 預設值，`liveValue` 與 `previewValue` 顯式傳入以 `@Dependency(\.date)` 取得、在呼叫時才讀 `date.now` 的 closure，寫法與專案既有慣例一致。

**Core 日誌分類去掉 Feature 名稱**：`AppLogger.Category.aiSummary` 改名為 `inference`。

**codegen 模板對齊規範**：`datamodel-gen` 的 Swift 輸出改掉 doc 複述名稱、把 `- Note:` 以外的自由段落收成 `- Note:`、手寫實作的 protocol 遵循 (`Identifiable` 的 `id`) 改寫在 extension 的分區內；三句固定 doc 的最終文字在 design 定案，讓 golden 的逐字比對有唯一目標。改完重新產生，golden fixtures 與 `Core/Domain/Generated/` 一起更新。已查證 `shared/data-model/schema/` 的 doc 字串都沒有複述型別名，因此本步不改任何 schema YAML。

**機械規則就地修正**：本次動到的 Core 檔案一併修 MARK 分區名稱、缺 `///` 的宣告、`- Parameter` 缺漏、行寬 100、檔頭日期補零 (`YYYY/MM/DD`)、型別成員間空行、`switch` case 間不空行、多行 closure 不用 `$0`、`@Dependency` 與 `var` 不同行，不另開全庫 diff。

Core 相關的單元測試在同一批內跟著改成 ios-dev-kit 的 Swift Testing 寫法與命名。

## Impact

- Affected specs: persistence-error-contract (modified), network-error-handling (modified), order-photo-attachments (modified), data-model-codegen (modified)
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Core/ 現有 71 個 Swift 檔：Dependencies 14、Diagnostics 2、Domain 手寫 16、Domain/Generated 12、Networking 7、Persistence 20 (完工後為 73 檔：Dependencies 15、Networking 8、Persistence 21，含新增與拆檔)
    - apps/ios/BuyLedger/Core/Domain/Generated/ 的 12 個生成檔由 generator 重新產生，不手改
    - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift、apps/ios/BuyLedger/Features/Orders/OrderEditView.swift (照片匯入結果與失敗提示)
    - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift (`catch CalendarReminderError.noWritableCalendar` 在錯誤型別去掉 `Equatable` 後的適配)
    - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift、apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift、apps/ios/BuyLedger/Features/FX/FxFeature.swift、apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift (`APIError` 建構與比對處的最小適配)
    - apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift (錯誤替身建構)
    - apps/ios/BuyLedger/Resources/Localizable.xcstrings (只加照片匯入失敗一條字串與其英文)
    - apps/ios/BuyLedgerTests/ 中 Core 對應的測試檔
    - shared/data-model/generator/src/datamodel-gen.ts
    - shared/data-model/fixtures/expected/swift/ 底下全部 10 個 Swift golden 檔 (generator 改動會波及用到 wrapper rawValue doc 或 identity id 的型別)
    - .claude/rules/ios-data-layer.md (若錯誤契約描述因本次改動失效)
  - New:
    - apps/ios/BuyLedger/Core/Persistence/RecordDecodingError.swift (記錄解析失敗的專用錯誤型別)
    - apps/ios/BuyLedger/Core/Dependencies/PhotoImportResult.swift (照片匯入的成功資料與失敗張數)
    - 這兩個新檔不在 findings.md 的審查清單內 (清單是 2026-09-14 既有檔案的掃描結果)，但一樣要符合 ios-dev-kit；完工後 Dependencies 為 15 檔、Persistence 為 21 檔
  - Removed:
    - apps/ios/BuyLedger/Core/Networking/ExchangeRateDTO.swift (拆成 ExchangeRateLatestResponse.swift 與 ExchangeRateCodesResponse.swift，一檔一個主型別)
    - apps/ios/BuyLedger/Core/Persistence/NameLookupRecord.swift (protocol 改名為 NameLookupRecordProtocol，檔名同步；@Model 型別主體未動)
    - 不刪任何手寫 extension 檔；生成與手寫的拆分在先前的 change 已完成
  - 不動：shared/data-model/schema/ 的 YAML (已查證 doc 字串無複述型別名)
