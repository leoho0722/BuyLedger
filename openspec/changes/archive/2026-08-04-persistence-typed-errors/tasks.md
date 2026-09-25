## 1. 共用錯誤契約與測試基礎

- [x] 1.1 依 Decision: 用共用 PersistenceError 表示儲存基礎失敗，先建立 Persistence storage failures use a shared typed error、Currency metadata preserves cache and API error categories 的失敗測試，具體驗證錯誤 case、底層訊息與空 cache 保護；以新增的 persistence error tests 作為 Red 階段驗證。
- [x] 1.2 實作 PersistenceError、OrderPersistenceError、PaymentMethodPersistenceError、CurrencyMetadataPersistenceError 與共用錯誤轉換 helper，讓 Interface and data shape 的 Error／Equatable／Sendable 契約成立；重新執行 1.1 的測試確認轉換後 case 與 localizedDescription 保留。

## 2. Persistence actor 與 container

- [x] 2.1 依 Decision: domain semantic error 與 storage error 分層，完成 Domain persistence errors preserve semantic failures：將 OrderPersistence 與 PaymentMethodPersistence 的 public throwing methods 改為完整 concrete typed throws，保留 identifier collision／missing order 語意並在 transactional save failure 後 rollback；以 OrderPersistenceTests、PaymentMethodPersistenceTests 與 failure injection 測試驗證。
- [x] 2.2 依 Persistence boundaries use complete typed throws contracts，將 CampaignPersistence、CampaignReminderPersistence、NameLookupPersistence、CurrencyMetadataPersistence 與 PersistenceContainer 的 fetch／save／container creation failure 映射為指定 typed error；以各 persistence tests、CurrencyMetadataCacheTests 與 iOS compile 驗證。
- [x] 2.3 依 Decision: recovery error 與一般 persistence error 分離，完成 Store quarantine uses a separate typed recovery error：新增 PersistenceRecoveryError 並讓 PersistenceStoreQuarantine 與 PersistenceStoreQuarantineClient 對外只拋出 recovery typed error；以 PersistenceRecoveryTests 驗證無 store 時不建立目錄、失敗時包含檔名與底層訊息。

## 3. Repository boundary

- [x] 3.1 依 Decision: repository 只在錯誤集合單一時收窄 typed throws，將只轉發 persistence 的 repository dependency closure 改成對應 concrete error，並以 CurrencyMetadataRepositoryError 包住 API 與 cache error；以 repository dependency 編譯檢查、CurrencyMetadataCacheTests 與相關 feature tests 驗證呼叫端可 pattern-match 完整錯誤集合。
- [x] 3.2 更新受影響測試替身與既有 WriteError 參照，讓所有測試 injection closure、錯誤 pattern matching 與 Swift 6 typed closure signature 對齊新名稱；以 rg 搜尋舊 error 名稱並執行受影響測試驗證。

## 4. 安全性與整體驗證

- [x] 4.1 依 Decision: 保留 rollback 與既有成功流程，完成 Typed error conversion preserves existing data safety behavior，逐項確認 Observable behavior、Failure modes 與成功資料操作未改變；以 persistence tests、失敗後重新 fetch 的 assertion 與 git diff review 驗證。
- [x] 4.2 依 Interface and data shape、Acceptance criteria 與 Scope boundaries 完成最終檢查：source scan 確認 persistence boundary 無未收窄的 throws(any Error)，執行 spectra analyze persistence-typed-errors --json、spectra validate persistence-typed-errors、git diff --check 與 xcodebuildmcp build／targeted test；所有指令輸出需可供 reviewer 追溯。
