## Context

目前 SwiftData 的 persistence actor、PersistenceContainer 與 store recovery client 多數以 throws(any Error) 對外暴露錯誤。這讓呼叫端無法從函式簽名分辨讀取失敗、寫入失敗、container 建立失敗、資料完整性錯誤或檔案隔離失敗。

本變更只整理錯誤邊界，不改變 SwiftData schema、migration、CloudKit 設定、資料內容或既有成功流程。SwiftData／Foundation 的原始錯誤只在 persistence boundary 內被捕捉，轉成可跨 module 使用的 Sendable typed error；原始錯誤的 localizedDescription 會保留在錯誤 payload 中，方便診斷。

## Goals / Non-Goals

**Goals:**

- 建立共用的 PersistenceError，分類讀取、寫入與 ModelContainer 建立失敗。
- 讓各 persistence domain 保留自己的語意錯誤，並以 storage(PersistenceError) 表示底層儲存失敗。
- 讓 currency metadata 的空回應與 API 錯誤維持可辨識的 domain／repository error，不再錯誤地借用 APIError 表示 persistence invariant。
- 讓 store quarantine 使用獨立的 PersistenceRecoveryError，區分資料庫操作與檔案搬移失敗。
- 讓 persistence actor、container helper、recovery client 與只轉發單一 persistence domain 的 repository closure 使用 Swift 6 typed throws。
- 為錯誤分類、原始訊息保留、交易 rollback 與 recovery 行為補上測試。

**Non-Goals:**

- 不變更 SwiftData schema、migration plan、CloudKit container、儲存路徑或資料格式。
- 不改變成功時的排序、upsert、刪除、cascade 或 seed 行為。
- 不改變使用者看得到的錯誤文案；本變更只調整錯誤型別與內部轉換。
- 不把 network、Calendar、AI client 的錯誤併入 PersistenceError。
- 不為了消除所有 any Error 而建立沒有語意的萬用錯誤；內部 adapter 若需要接住系統原始錯誤，仍可明確寫成 throws(any Error)，但不得讓它穿越公開 persistence boundary。

## Decisions

### Decision: 用共用 PersistenceError 表示儲存基礎失敗

新增 PersistenceError: Error, Equatable, Sendable，至少提供以下 case：

- fetchFailed(message: String)：SwiftData fetch 失敗。
- saveFailed(message: String)：SwiftData save 失敗。
- containerCreationFailed(message: String)：建立 ModelContainer 失敗。

各 case 都保留原始錯誤的 localizedDescription。所有 persistence actor 的 fetch 與 save 失敗都在 actor 內轉換，呼叫端不依賴 SwiftData 或 NSError 的具體型別。

選擇共用分類而不是每個 actor 各自複製 FetchError／SaveError，是因為這些錯誤描述的是同一個儲存基礎層，且 repository 可以直接以相同 typed error 宣告契約。

### Decision: domain semantic error 與 storage error 分層

訂單與付款方式保留原本的業務語意：

- OrderPersistenceError.identifierCollision(id:)
- PaymentMethodPersistenceError.orderNotFound(id:)

兩者另外提供 storage(PersistenceError)，因此 create／mergeOrders 與 applyEdit 仍能在型別上表達「語意錯誤或儲存錯誤」，不把兩者壓成同一個 generic case。原本模糊的巢狀 WriteError 會改成明確的 domain error 名稱。

Currency metadata 另使用 CurrencyMetadataPersistenceError 表示空 code 清單與儲存錯誤；repository 再以 CurrencyMetadataRepositoryError 包住 APIError 或 persistence error，因為該 repository 的操作確實同時會呼叫網路與本機快取。

### Decision: recovery error 與一般 persistence error 分離

新增 PersistenceRecoveryError: Error, Equatable, Sendable，表示建立 recovery 目錄、解析 Application Support 目錄或搬移 store 檔案失敗。PersistenceStoreQuarantine.quarantine 沒有可搬移檔案時仍回傳 nil；只有實際操作失敗才拋出 typed recovery error。

這樣可避免呼叫端把「資料庫無法開啟」與「使用者確認後的備份搬移失敗」視為同一種可自動重試事件。

### Decision: repository 只在錯誤集合單一時收窄 typed throws

只轉發單一 persistence domain 的 repository dependency closure 會宣告對應的 concrete typed throws，例如訂單 CRUD 使用 PersistenceError 或 OrderPersistenceError，付款方式批次編輯使用 PaymentMethodPersistenceError。同時組合 API 與 persistence 的 currency metadata repository 使用 CurrencyMetadataRepositoryError，不讓任一錯誤被靜默轉成另一類。

Preview／test value 的 non-throwing closure 可繼續使用；它們符合 throwing function type 的子集，不需製造虛假的錯誤。

### Decision: 保留 rollback 與既有成功流程

目前已有 rollback 的寫入交易在轉換錯誤時維持 rollback 後再拋出 typed error。需要補強的同一交易寫入也會在 save 失敗時回復 pending context 變更。錯誤轉換只改變錯誤的外觀，不改變既有成功路徑與資料處理順序。

## Implementation Contract

### Observable behavior

- SwiftData fetch／save／container 建立失敗時，呼叫端收到對應的 PersistenceError case。
- 訂單重複建立或合併時仍收到 OrderPersistenceError.identifierCollision(id:)。
- 付款方式批次編輯遇到不存在的訂單時仍收到 PaymentMethodPersistenceError.orderNotFound(id:)。
- currency metadata 收到空 code 清單時收到 CurrencyMetadataPersistenceError.emptyCodeList；API 失敗與 persistence 失敗在 repository boundary 分別可辨識。
- recovery 沒有 store 檔案時仍回傳 nil；建立目錄或搬檔失敗時收到 PersistenceRecoveryError。
- 所有轉換後的 storage／recovery error 都保留底層錯誤的 localizedDescription。

### Interface and data shape

公開錯誤型別必須是 Error, Equatable, Sendable：

- PersistenceError：fetchFailed(message:), saveFailed(message:), containerCreationFailed(message:)
- OrderPersistenceError：identifierCollision(id:), storage(PersistenceError)
- PaymentMethodPersistenceError：orderNotFound(id:), storage(PersistenceError)
- CurrencyMetadataPersistenceError：emptyCodeList, storage(PersistenceError)
- CurrencyMetadataRepositoryError：api(APIError), persistence(CurrencyMetadataPersistenceError)
- PersistenceRecoveryError：directoryResolutionFailed(message:), directoryCreationFailed(message:), fileMoveFailed(fileName:message:)

Persistence actor methods and repository dependency closures SHALL use concrete typed throws matching their complete error set. No raw SwiftData／Foundation error SHALL escape these boundaries.

### Failure modes

- A failed save in a transaction SHALL call modelContext.rollback() before throwing the mapped typed error.
- A duplicate order identifier and missing order referenced by a payment-method edit SHALL not be mapped to a storage case.
- An empty currency code response SHALL not delete existing cached records.
- Quarantine SHALL not create a recovery directory when no known store file exists.
- A failure while creating or moving a recovery directory SHALL be surfaced as PersistenceRecoveryError; partial moves remain the documented accepted behavior of the existing operation.

### Acceptance criteria

- Unit tests pattern-match every public error family and verify the associated identifiers／file names.
- Unit tests inject failures and verify the original localized message is present in the mapped error.
- Unit tests verify rollback／cache preservation for failed writes.
- A source scan confirms no persistence actor, persistence container throwing helper, or quarantine client public throwing closure remains declared as throws(any Error).
- spectra analyze persistence-typed-errors --json reports no critical consistency or coverage finding.
- git diff --check passes and the iOS build completes through the repository's xcodebuildmcp workflow.

### Scope boundaries

本變更只涵蓋 apps/ios/BuyLedger/Core/Persistence、直接綁定這些 persistence API 的 Core/Dependencies 與其測試。既有 network、Calendar、AI、presentation error contract 不在範圍內；Ollama stream 因 SDK 的 AsyncThrowingStream failure type 限制而維持既有 any Error，不視為 persistence boundary 例外。

## Risks / Trade-offs

- [Risk] 將底層錯誤轉成字串會失去原始 error 的結構化欄位 → [Mitigation] 目前 public contract 只需要分類與診斷訊息；localizedDescription 會被保留，未來若需要可在同一 typed error 增加結構化欄位。
- [Risk] domain wrapper 增加 repository 呼叫端的 pattern matching 成本 → [Mitigation] wrapper 只出現在真正組合多種錯誤的 boundary，單一 persistence 操作直接使用 PersistenceError。
- [Risk] recovery 中途失敗可能留下部分檔案已搬移的狀態 → [Mitigation] 保留既有行為與文件說明；錯誤包含失敗檔名，讓上層能記錄並要求人工處理。
- [Risk] typed throws 改變測試注入 closure 的推導 → [Mitigation] 對 throwing closure literal 明確標注 concrete error type，並以編譯與 targeted tests 驗證。
