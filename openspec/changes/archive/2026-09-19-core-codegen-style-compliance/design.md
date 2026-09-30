## Context

Core 層現有 71 個 Swift 檔是所有 Feature 的共同下游：錯誤型別、領域型別、SwiftData 記錄轉換與網路 client 都在這裡。2026-09-14 全庫審查在 Core 的 71 檔加上 2 個 codegen golden fixture (共 73 檔) 上記錄 69 筆判讀違規、298 筆機械必擋與 186 筆機械違規；尾隨空白已於 commit 291d841 清除，不計入。

審查明細逐檔列在本 change 目錄的 findings.md，實作時以它決定每個檔案要修哪幾項。本 change 新增的兩個檔案不在那份清單內，一樣要符合 ios-dev-kit。

現況的三個結構性問題：

- 錯誤型別把底層錯誤壓成 `message: String` 並遵循 `Equatable`。`PersistenceError.mapFetch` 等 helper 在轉換時只留 `error.localizedDescription`，原始 `NSError` 的 domain 與 code 在這一步就消失。
- `OrderRecord` 與 `CampaignRecord` 轉領域型別時以 `??` 補預設值，無法解析的 rawValue 變成合法狀態。
- `PhotoClient.importPhotos` 的簽章沒有失敗通道，逐張 `catch { continue }` 是唯一可能的寫法。

限制條件：

- `APIError` 被 `FxFeature`、`QuoteFeature`、`AISummaryFeature`、`OllamaClient` 與 UI 測試替身建構或比對，形狀改變會擴散到這些檔案，但不改它們的 Feature 邏輯。
- 目前沒有任何 TCA `State` 或 `Action` 持有這些錯誤型別 (`AISummaryFeature` 的 `StreamResult` 持有 `APIError`，但它是 private 且不遵循 `Equatable`)。測試中以 `==` 比對錯誤值的只有 4 處。另有 `CampaignFeature` 以 `catch CalendarReminderError.noWritableCalendar` 形式比對一處，移除 `Equatable` 後要確認它仍編得過。
- `PersistenceFailureFeature` 以無型別 `catch` 取 `error.localizedDescription` 顯示復原失敗原因，所以 `PersistenceRecoveryError` 必須保留 `LocalizedError`。
- `network-error-handling` 已規定網路層錯誤訊息不得含 URL、標頭值或任何可能含 API key 的文字。
- 既有 `CurrencyMetadataCacheTests` 在三處以 `now:` 參數注入固定時間，時間注入的改法必須保留這個注入點。
- `apps/ios/CLAUDE.md` 規定時間走 `@Dependency(\.date)` 後以 `date.now` 取值，既有程式碼一致採這個寫法。
- 2026-09-14 那次機械掃描是一次性腳本產出的，腳本已不存在，本 change 沒有可重跑的規則掃描器。
- `datamodel-gen` 只支援 `$newUUID` 一種計算型預設值，沒有時間 sentinel，所以生成檔沒有「時間未走依賴注入」的違規實例。

## Goals / Non-Goals

**Goals:**

- Core 與 codegen 輸出的 Swift 符合 ios-dev-kit，之後第 2 步以上的重構不必再回頭改 Core。
- 三處靜默失敗變成可觀察的失敗：解析不了的資料、匯入不了的照片、建不出來的匯率表。
- 診斷時拿得到原始錯誤的 domain 與 code，而不只是一句本地化字串。

**Non-Goals:**

- 不重構 Feature 的狀態機、畫面結構或導航。`OrderEditView` 只在既有的 `photosSection` 內多一行輔助文字，不改版面結構；其餘 Feature 檔只做 `APIError` 與 `CalendarReminderError` 建構或比對處的最小適配。
- 不改任何 typed throws 簽章所宣告的錯誤型別，只改那些型別內部 case 的 payload 形狀。記錄轉換函式由不可拋出改為 `throws(PersistenceError)` 不在此限：那是替一個原本沒有失敗通道的函式新增通道，不是把既有 boundary 宣告的錯誤型別換掉。
- 不動 `OrderPersistence` 的 rollback 策略 (`try? rollbackPendingOrderRecords` 是 repair-false-passing-tests 的知情決定)。
- 不移除 codegen 的 `$newUUID` 預設值 (見「本 change 接受的規範例外」)。
- 不改 `shared/data-model/schema/` 的任何 YAML。
- 不刪任何手寫 extension 檔：生成與手寫的拆分在先前的 change 已完成，本次沒有會變空的手寫檔。
- 不新增 SwiftData schema 版本，資料庫欄位形狀不變。
- 不處理第 2 步以上的範圍 (Design System、各 Feature、UI 測試)。

## Decisions

### 錯誤型別以 underlying 保留原始錯誤並移除 Equatable

帶底層錯誤的 case 改為 `case fetchFailed(underlying: any Error & Sendable)` 這種形狀，型別不再遵循 `Equatable`。純分類、不含底層錯誤的 case (`APIError.http(statusCode:)`、`APIError.quotaExceeded`、`OrderPersistenceError.identifierCollision(id:)`、`CalendarReminderError.noWritableCalendar` 等) 維持原樣。

payload 型別是 `any Error & Sendable` 而不是 `any Error`：這些錯誤要跨 actor 邊界傳遞，enum 必須遵循 `Sendable`，而 `any Error` 不遵循 `Sendable`。

橋接規則分兩種，不是一律橋接：

- **框架錯誤** (SwiftData、Foundation、EventKit、URL loading system、`DecodingError`) 一律寫 `error as NSError`。typed catch 拿到的是 `any Error`，`as NSError` 是唯一無條件成立的橋接，且保留 domain、code 與 userInfo。這類 underlying 不是原封不動的同一個物件，測試斷言 `domain`、`code` 與 `localizedDescription`，不斷言物件身分。
- **App 自己定義的錯誤** 原樣承載，不橋接。目前只有 `RecordDecodingError` 屬於這一類，因為呼叫端與測試要 pattern-match 它的四個欄位，橋接成 `NSError` 會把那些欄位變成字串。

各型別的目標形狀：

| 型別 | 帶 underlying 的 case | Equatable | LocalizedError |
| --- | --- | --- | --- |
| `PersistenceError` | `fetchFailed`、`saveFailed`、`containerCreationFailed` | 移除 | 移除 |
| `OrderPersistenceError` | 經 `storage(PersistenceError)` | 移除 | 移除 |
| `PaymentMethodPersistenceError` | 經 `storage(PersistenceError)` | 移除 | 移除 |
| `CurrencyMetadataPersistenceError` | 經 `storage(PersistenceError)` | 移除 | 移除 |
| `PersistenceRecoveryError` | `directoryResolutionFailed`、`directoryCreationFailed`、`fileMoveFailed` | 移除 | **保留** |
| `APIError` | `transport`、`decoding` | 移除 | 本來就沒有 |
| `CurrencyMetadataRepositoryError` | 無 (只轉送 `api` 與 `persistence`) | 移除 | 移除 |
| `CalendarReminderError` | `system` | 移除 | 本來就沒有 |

`PersistenceRecoveryError` 保留 `LocalizedError`，是因為 `PersistenceFailureFeature` 用無型別 `catch` 取 `error.localizedDescription` 顯示給使用者；其餘型別移除前要逐一確認沒有顯示路徑取用，確認結果記在 tasks.md。

`PersistenceError.mapFetch` / `mapSave` / `mapContainerCreation` 改成帶入橋接後的錯誤；泛型參數由 `T` 改為具名的 `Value`，只服務單一具體型別的 `mapContainerCreation` 改寫成非泛型。

`network-error-handling` 的憑證限制優先於保留 underlying：`APIError` 的顯示字串不得輸出 URL 或標頭值，underlying 只供日誌與除錯。

測試改以 `if case` 或 `switch` 比對 case，不比對整個值；現有 4 處 `==` 比對一併改寫。`CampaignFeature` 的 `catch CalendarReminderError.noWritableCalendar` 若在移除 `Equatable` 後編不過，改寫成型別化 catch 內的 `if case`。

替代方案：保留 `Equatable` 並同時放 `underlying`，需要手寫 `==` 忽略 underlying，會讓兩個不同原因的失敗比較為相等，正是規範要避免的。

### 記錄解析失敗改為拋出持久化錯誤

`OrderRecord` 與 `CampaignRecord` 轉領域型別的函式改為可拋出，無法解析的 rawValue 拋 `PersistenceError.fetchFailed`，該次讀取整批失敗，畫面走既有的錯誤空狀態。

`fetchFailed` 改成只收 `underlying` 之後，解析失敗沒有底層框架錯誤可放，所以新增專用型別承載診斷資訊：`RecordDecodingError` 遵循 `Error` 與 `Sendable`，帶四個字串：

- `entity`：記錄型別名，例如 `"OrderRecord"`、`"CampaignRecord"`
- `identifier`：該筆記錄的 id 字串
- `field`：欄位名，例如 `"paymentReceiptStatus"`、`"status"`
- `rawValue`：無法解析的原始字串

它是上一節所說「App 自己定義、原樣承載不橋接」的唯一型別，拋出時寫 `PersistenceError.fetchFailed(underlying: RecordDecodingError(...))`，`PersistenceError` 的 case 集合因此不變。

理由：專案政策是「寧可顯示空狀態也不顯示假資料」。降級後的 `.pending` 與 `.ongoing` 是合法值，使用者與後續彙總都無從分辨，錯誤會沿著統計與收款流程擴散。

替代方案：領域 enum 加 `.unknown(rawValue)` case，只讓壞掉那一筆顯示未知。這兩個 enum 由 codegen 產生，要改 schema 並補齊所有 `switch` 窮舉點，會把第 3 至 7 步的 Feature 提前捲進來；使用者裁決採整批拋錯。

### 照片匯入回傳成功資料與失敗張數

新增 `PhotoImportResult`，遵循 `Sendable` 與 `Equatable`，兩個成員：`photos: [Data]` 與 `failedCount: Int`。`PhotoClient.importPhotos` 的型別改為 `@Sendable (_ items: [PhotosPickerItem]) async -> PhotoImportResult`，不拋出。

算入 `failedCount` 的情形有三種：`loadTransferable` 拋錯、`loadTransferable` 回傳 nil、正規化 (縮放與 JPEG 編碼) 回傳 nil。

呈現方式是 inline 而不是 alert：`OrderEditFeature.State` 新增 `photoImportFailureCount: Int = 0`，`OrderEditView` 的 `photosSection` 在該值大於 0 時多顯示一行輔助文字，樣式比照同一 section 既有的「照片載入失敗，請稍後再試。」那一行，版面結構不變。文案採 source language 即 key 的既有慣例，字串為 `"有 %lld 張照片無法匯入。"`，加進 `Localizable.xcstrings` 並補英文。下一次開啟照片選擇器或下一批匯入時該值歸零。`OrderEditFeature.Action.photosImported` 的 payload 由 `[Data]` 改為 `PhotoImportResult`。

理由：使用者一次可選多張，任一張失敗就整批不匯入會逼使用者重選全部；但完全不提示則是現況的靜默失敗。alert 會打斷編輯流程，而這個訊息不需要使用者立即決策。

替代方案：`typed throws` 整批失敗，語意最嚴格但體驗最差；使用者裁決採回報張數。

### 幣別快取的時間改走依賴注入

`CurrencyMetadataRepository.live` 保留 `now` 參數但移除 `{ Date() }` 預設值，`liveValue` 與 `previewValue` 顯式傳入一個在呼叫時才取值的 closure：

```swift
now: {
    @Dependency(\.date) var date
    return date.now
}
```

寫法與 `apps/ios/CLAUDE.md` 的規定以及專案既有用法一致 (宣告 `@Dependency(\.date)` 後讀 `date.now`)，不用 `@Dependency(\.date.now)`。production 因此不再直接呼叫 `Date()`，且每次呼叫取當下時間。保留參數而非移除，是因為既有 `CurrencyMetadataCacheTests` 三處就是靠這個參數注入固定時間，移除會讓它們無處注入；保留後那三處測試不需改動。

### Core 日誌分類不使用 Feature 名稱

`AppLogger.Category.aiSummary` 改名為 `inference`，rawValue 由 `"AISummary"` 改為 `"Inference"`，對應的 `static var aiSummary: Logger` 改名為 `inference`，呼叫端跟著改名。`persistence` 分類與 subsystem 的取得方式不動。

可觀察的影響：主控台日誌的 category 字串會從 `AISummary` 變成 `Inference`。

### codegen 模板本步只改 doc 與 protocol 位置

`datamodel-gen` 的 Swift 輸出修三項：doc 摘要不複述所文件化的宣告名稱、`- Note:` 以外的自由段落收成 `- Note:`、手寫實作的 protocol 遵循 (identity enum 與 wrapper 的 `Identifiable` 與其 `id`) 改寫在帶 MARK 分區的 extension。

generator 三句固定 doc 的最終文字在此定案，golden 的逐字比對才有唯一目標：

| 位置 | 現況 | 定案文字 |
| --- | --- | --- |
| 生成的 initializer | `/// 建立 SampleOrder` | `/// 以必填欄位建立值，宣告了預設值的欄位可以省略` |
| wrapper 的 rawValue | `/// 包裝的原始值` | `/// 實際保存的基礎值` |
| identity 的 id | `/// 穩定識別值 (以 rawValue 表示)` | `/// 以實際保存的值作為穩定識別` |

schema 帶來的 doc 字串照舊原樣輸出 (只做既有的去尾句號)，不做改寫。

已查證 `shared/data-model/schema/` 全部 doc 字串都沒有複述型別名 (例如 `CurrencyCode` 的 doc 是「交易幣別的 ISO 4217 三位代碼」)，複述名稱的只有上表三句 generator 寫死的固定 doc，因此本步只改 generator，不改任何 schema YAML。

`datamodel-gen` 只支援 `$newUUID` 一種計算型預設值，沒有時間 sentinel，所以審查那條「時間與 UUID 走依賴注入」在目前 schema 下只有 UUID 一個違規實例，時間部分沒有實例要處理。生成的 init 仍保留 `itemId: UUID = UUID()`，理由見下一節。

### 本 change 接受的規範例外

本 change 明列兩條 accepted exception。

第一條：codegen 生成的 init 保留 `$newUUID` 帶來的 `UUID = UUID()` 預設值。

移除它要同步改 schema 的 `$newUUID` sentinel，並讓 `LedgerOrderItem` 的 59 個建構點改傳注入的 UUID，其中 56 處在第 3 至 7 步才會動到的 Feature 測試檔；使用者裁決本步不做，留給後續步驟。findings.md 在該項目旁標註了這個接受結論。

第二條：`LedgerOrder.contributesToCategoryBreakdown` 維持現名，不改成 `is` 前綴的 Bool 命名。它已是第三人稱動詞開頭、語意清楚，而改名會牽動 `.claude/rules/ios-data-layer.md` 這份不在本步範圍的規則檔 (該檔明文以這個名稱說明「類別與開團彙總用另一口徑」)，且它與 `revenueAttributionOrders` 是資料層刻意並存的一組口徑命名。留待第 7 步 (Dashboard、Insights) 或第 10 步調整 rules 時一併處理。

驗收時「判讀違規歸零」的說法一律排除這兩條與下列既有登記例外。Core 與 codegen 範圍的既有登記例外共 18 筆，只有兩種：

- `TC4 宣告 testValue` 共 17 筆，分布在 `Core/Dependencies/` 的 13 個 client 與 repository、`Core/Networking/` 的 `AppConfiguration`、`ExchangeRateClient`、`HTTPClient`，以及 `Core/Persistence/PersistenceStoreQuarantineClient`。struct-of-closures 形式的 Client 在審查時已整批登記為例外。
- `禁 .shared` 1 筆，在 `Core/Persistence/PersistenceContainer.swift`，屬必擋級的已登記例外。

除這 18 筆與 `$newUUID` 那一條之外，Core 與 codegen 範圍沒有其他例外；驗收時若出現新的例外需求，停下來回報而不是自行登記。

### 機械規則只修本步動到的檔案

MARK 分區名稱、缺 `///`、缺 `- Parameter` / `- Returns`、行寬 100、檔頭日期補零成 `YYYY/MM/DD`、型別成員間空行、`switch` case 間不空行、多行 closure 不用 `$0`、`@Dependency` 與 `var` 不同行，全部在 Core 與 codegen 範圍內就地修，不擴散到其他目錄。

驗收分兩半，因為 2026-09-14 的掃描腳本已不存在，沒有可重跑的規則掃描器。可機器檢查的三項對該 task 的檔案集合執行，要求無輸出：

- 行寬 (按字元計)：`python3 -c 'import sys
for f in sys.argv[1:]:
    for i, l in enumerate(open(f, encoding="utf-8"), 1):
        if len(l.rstrip("\n")) > 100: print(f"{f}:{i}")' <檔案...>`。不用 `awk 'length > 100'`：macOS 的 awk 按位元組計算，一行 80 字元的中文註解會被算成 104 而誤報
- 尾隨空白與定位字元：`awk '/[ \t]+$/ { print FILENAME":"FNR }' <檔案...>`
- 檔頭日期格式：`awk 'FNR == 5 && $0 !~ /^\/\/  Created by .+ on [0-9]{4}\/[0-9]{2}\/[0-9]{2}\.$/ { print FILENAME }' <檔案...>` (Xcode 檔頭的第 5 行固定是 Created by 那一行；已驗證 Core 全部手寫檔都符合這個位置。`Core/Domain/Generated/` 的生成檔用 do-not-edit 檔頭，不適用這條檢查)

三項都用 `awk` 而不是 `grep -P`：`-P` 在不同平台的 grep 實作不一定存在，`awk` 對 `\t` 的支援是各平台一致的。

每個 task 執行時把 `<檔案...>` 換成該 task 負責的實際檔案集合，命令與輸出記在 tasks.md。需要判讀的項目 (MARK 分區名稱、缺 `///` 與 `- Parameter`、doc 措辭、成員順序) 逐檔對照 findings.md 的項目清單與 ios-dev-kit 的 `references/formatting.md`、`references/coding-style.md` 人工核對，並在 tasks.md 逐檔記錄已處理的項目代碼。

## Implementation Contract

**行為**：

- 資料庫中存有無法解析的收款狀態或開團狀態時，該次讀取失敗，畫面顯示既有的錯誤空狀態，不再出現與資料庫不符的「未收款」或「進行中」。
- 照片匯入時，可用的照片照常加入草稿；有照片匯入失敗時，照片區塊出現一行文字說明失敗張數。
- 主控台日誌的 AI 總結分類字串從 `AISummary` 變成 `Inference`。
- 其餘使用者可見行為不變。

**介面與資料形狀**：

- 上表八個錯誤型別依「錯誤型別以 underlying 保留原始錯誤並移除 Equatable」調整 case payload 與遵循，簽章宣告的錯誤型別不變。
- `RecordDecodingError`：`Error` 與 `Sendable`，成員為 `entity`、`identifier`、`field`、`rawValue`，四者皆為字串，原樣承載不橋接。
- `PhotoImportResult`：`Sendable` 與 `Equatable`，成員為 `photos: [Data]` 與 `failedCount: Int`。
- `PhotoClient.importPhotos` 的型別為 `@Sendable (_ items: [PhotosPickerItem]) async -> PhotoImportResult`。
- `OrderRecord` 與 `CampaignRecord` 的領域型別轉換函式可拋出 `PersistenceError`。
- `CurrencyMetadataRepository.live` 的 `now` 參數保留但不再有預設值。
- `FxRates.toTwd` 不再出現 `?? 0`。
- `datamodel-gen` 產出的 Swift：三句固定 doc 採上表定案文字、補充段落一律 `- Note:`、手寫 protocol 實作寫在 extension。

**失敗模式**：

- 解析失敗、fetch 失敗、save 失敗一律以 typed throws 往上傳，不再有靜默降級。
- 照片匯入失敗是部分失敗，不是整批失敗，也不拋出。
- 錯誤顯示字串不得包含 URL、標頭值或設定值；原始錯誤只供日誌與除錯使用。

**驗收方式**：

- `shared/data-model/generator` 先 `bun run unlock` 解除生成檔唯讀鎖再 `bun run generate`，最後 `bun run check` 退出碼 0，`bun test` 通過。
- 單元測試涵蓋：無法解析的 rawValue 讓讀取拋出帶 `RecordDecodingError` 的 `PersistenceError.fetchFailed` 且四個欄位正確；照片部分失敗回報正確張數；`CurrencyMetadataRepository` 以注入時間判斷 TTL；框架錯誤包裝後取得的 underlying 其 domain 與 code 等於來源錯誤。
- iOS 與 iPadOS 兩個目的地各完成一次 build，`BuyLedgerTests` 全數通過。
- 完整單元測試回歸在最後一次改檔之後執行，結果逐筆核對，並與開工前的 baseline 數字比較。
- 機械項目依上一節的兩段式驗收；判讀違規與機械必擋歸零，本節明列的 accepted exception 與既有登記例外除外。

**可改檔案 allowlist**：

- `apps/ios/BuyLedger/Core/` 全部檔案，加上新增的 `Core/Persistence/RecordDecodingError.swift` 與 `Core/Dependencies/PhotoImportResult.swift`
- `apps/ios/BuyLedger/Core/Domain/Generated/` 的 12 個生成檔 (由 generator 重新產生，不手改)
- `shared/data-model/generator/src/datamodel-gen.ts` 與 `shared/data-model/fixtures/expected/swift/` 底下全部 10 個 Swift golden 檔：generator 的 doc 與 protocol 位置改動會波及任何用到 wrapper rawValue doc 或 identity id 的型別，golden 本來就要跟著 emitter 走。`fixtures/expected/kotlin/` 與 `fixtures/expected/typescript/` 不在清單內：本步只改 Swift emitter，那兩個目錄若出現變更代表改壞了，要停下來回報
- `apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift` 與 `apps/ios/BuyLedger/Features/Orders/OrderEditView.swift`
- `apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift` (只改 `CalendarReminderError` 的 catch 寫法)
- `apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift` 與 `apps/ios/BuyLedger/Features/Orders/OrderDraft.swift` (只跟著 `LedgerOrder.applyingPaymentMethodFlags` 的參數標籤改名，不改邏輯)
- `apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift`、`apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift`、`apps/ios/BuyLedger/Features/FX/FxFeature.swift`、`apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift`
- `apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift`
- `apps/ios/BuyLedger/Resources/Localizable.xcstrings` (只加照片匯入失敗那一條)
- `apps/ios/BuyLedgerTests/` 中 Core 對應的測試檔，以及因錯誤型別改形狀而需調整的 `CampaignFeatureTests`、`CampaignReminderFailureTests`
- `.claude/rules/ios-data-layer.md` (只在錯誤契約或型別名稱描述因本次改動失效時)
- `apps/ios/README.md` (只同步「專案結構」一節因本次檔案增刪而失效的項目，依根 CLAUDE.md 的文件同步鐵則)
- `apps/ios/CLAUDE.md` (只同步因本次符號改名而失效的描述，依根 CLAUDE.md 的文件同步鐵則)
- `apps/ios/BuyLedgerTests/__Snapshots__/SnapshotTests/orderEditViewBaseline.1.png` 與 `quoteViewBaseline.1.png` (使用者裁決重錄這兩條既有紅燈的基準圖，其餘 baseline 一律不重錄，避免稀釋守門力)

清單以外的檔案一律不動；實作中若發現非改不可，停下來回報而不是自行擴大範圍。

這份清單規範的是產出程式碼與資源的檔案。change 自身的文件另有規則：`openspec/changes/core-codegen-style-compliance/tasks.md` 的勾選與驗證紀錄是實作流程的一部分，實作者本來就要更新，不受此清單限制；其餘 artifacts (proposal、design、specs、findings) 在實作期間不改，要改先回到 ingest。

**範圍邊界**：

- 在範圍內：上列 allowlist 的檔案，以及因介面改變而必須適配的測試。
- 不在範圍內：Feature 的狀態機與畫面結構重構、Design System、UI 測試、SwiftData schema 版本、`shared/data-model/schema/` 的 YAML、`OrderPersistence` 的 rollback 策略、codegen 的 `$newUUID` 預設值、typed throws 簽章所宣告的錯誤型別。

## Risks / Trade-offs

- [移除 `Equatable` 後有未預期的編譯破口] → 已知 4 處測試以 `==` 比對、`CampaignFeature` 一處以 `catch <case>` 比對；其餘以編譯器找出。
- [整批拋錯讓一筆壞資料擋住整個列表] → 這是使用者裁決接受的取捨；`RecordDecodingError` 帶記錄型別、id、欄位與 rawValue，讓問題可直接追到那一筆。
- [`error as NSError` 讓框架錯誤的 underlying 不是原物件] → 診斷需要的 domain、code 與 userInfo 都保留；測試斷言這三者而非物件身分。App 自己的錯誤不橋接，所以 pattern-match 不受影響。
- [照片匯入回傳型別改變波及 `OrderEditFeature` 的既有測試] → 該 Feature 的測試只改匯入結果的建構方式，不改狀態機斷言。
- [沒有可重跑的規則掃描器，機械項目靠人工核對] → 可機器檢查的三項用固定命令驗收，其餘逐檔記錄已處理的項目代碼，讓遺漏看得出來。
- [generator 改動讓生成檔與既有手寫 extension 衝突] → 重新產生後先跑 `bun run check` 與專案編譯，再跑完整單元測試。
