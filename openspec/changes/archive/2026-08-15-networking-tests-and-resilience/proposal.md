## Why

網路層完全沒有測試。`HTTPClient`、匯率 client、其回應資料型別、錯誤列舉與請求組裝器，在單元測試目錄中零引用。這是 App 唯一與外部世界互動的部分，也是最容易因對方改動而壞掉的部分，卻是覆蓋率為零的區域。

零覆蓋讓三個實際缺陷長期存在：

**錯誤分類的重試策略只寫在註解裡。** 錯誤列舉的文件註解寫著「配額耗盡與金鑰無效不重試、傳輸錯誤與伺服器錯誤才重試」，但整個網路層找不到任何重試實作。這段註解描述的是意圖而非現況，讀者會以為已有防護。

**空回應會清空幣別快取。** 取得支援幣別的路徑在回應缺少欄位時回傳空陣列，而快取的寫入是「先刪光全部、再寫入」。兩者相乘的結果是：一次格式異常但狀態為成功的回應，就會把使用者本機的幣別清單清空且不寫回任何內容。而幣別清單是明文的「動態載入、不可寫死」政策，清空後使用者沒有幣別可選。

**金鑰會流進錯誤訊息。** 匯率 client 在網址組裝失敗時把完整網址放進錯誤訊息，而該網址的路徑中就含 API 金鑰。這個訊息會呈現在畫面上。

此外，AI 總結的串流只依賴請求層的閒置逾時，沒有整體時長上限，一個持續緩慢吐字的回應可以無限期佔住畫面。

## What Changes

- 為網路層建立測試覆蓋：請求組裝 (直接檢查 `URLRequest` 的 method、headers、body 與 timeout)、狀態碼判讀、六種錯誤的分類與映射、回應解碼的成功與失敗路徑，以及匯率 client 對業務錯誤碼的分流。
- 移除錯誤訊息中的網址內插，改為不含任何網址內容的固定訊息，使金鑰不可能出現在使用者可見的文字中。
- 幣別快取改為只在取得非空結果時才替換；空結果視為異常，保留既有快取並回報，不清空。
- AI 總結的串流加上整體時長上限，逾時即結束並回報，使畫面不會被無限期佔住。
- 把錯誤列舉註解中描述的重試策略與現況對齊：本次不實作重試，改為明文記錄目前沒有重試，避免註解繼續誤導。

## Non-Goals

- 不實作重試機制。重試需要決定退避策略、次數上限與對配額的影響，屬獨立的產品與成本決定；本次只讓文件不再宣稱有它。
- 不改變任何 API 的呼叫方式、端點或參數。
- 不改變匯率快取的有效期或更新時機。
- 不改動 AI 總結的提示詞內容或串流解析格式。
- 不處理金鑰隨產物出貨這個更大的暴露面。那屬於金鑰暴露緩解的範圍。
- 不為網路層引入第三方測試框架或模擬伺服器；測試一律以既有的可注入客戶端達成。

## Capabilities

### New Capabilities

- `network-error-handling`: 網路層錯誤處理的契約，涵蓋六種錯誤的分類邊界、錯誤訊息不得洩漏憑證、以及目前不具備重試這個明文事實。
- `currency-metadata-cache`: 幣別快取的更新契約，涵蓋何時可以替換快取、空結果如何處理，以及快取不得因異常回應而被清空。

### Modified Capabilities

- `ai-order-summary`: 串流補上整體時長上限與逾時後的呈現。

## Impact

- Affected specs: `network-error-handling`（新增）、`currency-metadata-cache`（新增）、`ai-order-summary`（修改）
- Affected code:
  - New:
    - apps/ios/BuyLedgerTests/HTTPClientTests.swift
    - apps/ios/BuyLedgerTests/ExchangeRateClientTests.swift
    - apps/ios/BuyLedgerTests/APIErrorMappingTests.swift
    - apps/ios/BuyLedgerTests/CurrencyMetadataCacheTests.swift
  - Modified:
    - apps/ios/BuyLedger/Features/FX/ExchangeRateClient.swift
    - apps/ios/BuyLedger/Core/Networking/APIError.swift
    - apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataPersistence.swift
    - apps/ios/BuyLedger/Core/Dependencies/CurrencyMetadataRepository.swift
    - apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift
    - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
    - apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift
    - apps/ios/BuyLedger/Resources/Localizable.xcstrings
    - apps/ios/BuyLedger.xcodeproj/project.pbxproj
  - Removed: （無）
- 不涉及 SwiftData schema 或資料形狀；幣別快取的資料表結構不變，只改變寫入的判斷條件。
- 次序約束：本變更必須排在金鑰暴露緩解之前（該變更會把認證方式由網址路徑改為標頭，屆時本次移除的網址內插已不存在），並排在分層邊界整理之前（該變更會把匯率 client 整檔搬移，屆時只搬位置不改內容）。
