## 1. 憑證不得出現在錯誤訊息

- [x] 1.1 讓錯誤訊息不可能包含金鑰：移除網址組裝失敗時的網址內插，改為不含任何網址內容的固定訊息。對應 spec requirement「Error messages never carry credentials」，依 design「錯誤訊息改為不含網址的固定字串，而非遮罩金鑰」。驗證：全專案搜尋錯誤建構點確認無網址或設定值內插；新增測試斷言該失敗路徑的訊息不含端點網域字串（apps/ios/BuyLedger/Features/FX/ExchangeRateClient.swift）。

## 2. 錯誤分類的測試覆蓋

- [x] 2.1 讓狀態碼與傳輸兩類失敗有測試釘住：依 design「測試以既有的可注入客戶端達成，不引入模擬伺服器」，以注入的替身驅動非成功狀態碼與傳輸失敗，斷言各自的分類與攜帶內容。對應 spec requirement「Every error category has a defined boundary and is covered by tests」。驗證：兩條測試通過，且刻意改動狀態碼判斷範圍時對應測試轉紅（apps/ios/BuyLedgerTests/HTTPClientTests.swift）。
- [x] 2.2 讓解碼的成功與失敗兩條路徑有測試：以符合與不符合預期形狀的回應各驅動一次，斷言解碼成功回傳預期值、不符合時分類為解碼失敗。驗證：兩條測試通過（apps/ios/BuyLedgerTests/ExchangeRateClientTests.swift）。
- [x] 2.3 讓服務端回報的業務錯誤各自對應到正確分類：涵蓋金鑰無效、帳號停用、配額耗盡與其他代碼四種情境，斷言前二者映射到憑證無效、第三者映射到配額、其餘映射到攜帶代碼的一般服務錯誤。驗證：四條測試通過，對照規格的分類表逐一核對（apps/ios/BuyLedgerTests/APIErrorMappingTests.swift）。
- [x] 2.4 確認測試是對照規格而非對照實作撰寫：逐條比對測試斷言與規格分類表，確認沒有把現有的非預期行為當成正確行為鎖住。驗證：分類表六個項目與測試一一對應，無多也無少。

## 3. 幣別快取不被異常回應清空

- [x] 3.1 先寫紅燈測試釘住快取不被清空：以回傳空清單的替身觸發一次重新整理，斷言既有快取內容前後逐項相同且異常被回報。對應 spec requirement「The currency cache is never emptied by an anomalous response」。驗證：測試在實作前失敗（apps/ios/BuyLedgerTests/CurrencyMetadataCacheTests.swift）。
- [x] 3.2 讓快取只在取得非空結果時才替換，空結果視為異常而非成功：替換的前置條件改為新內容非空，空內容不進入刪除路徑。依 design 決策：快取以「取得非空結果才替換」為條件，空結果視為異常。驗證：3.1 測試轉綠；另補測試斷言非空結果正確替換、請求失敗時快取不變（apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataPersistence.swift、apps/ios/BuyLedger/Core/Dependencies/CurrencyMetadataRepository.swift）。

## 4. 串流的整體時長上限

- [x] 4.1 先寫紅燈測試釘住串流不會無限等待：以持續緩慢輸出且不結束的替身驅動串流，斷言到達上限後串流停止、已收內容保留、進度指示結束且出現截斷說明。對應 spec requirement「Streaming Markdown summary sheet」的時長上限情境。驗證：測試在實作前失敗（apps/ios/BuyLedgerTests/AISummaryFeatureTests.swift）。
- [x] 4.2 讓串流以整體時長上限包裹，逾時保留已收到的內容而非丟棄或報錯。依 design「串流加整體時長上限，逾時保留已收到的內容」。驗證：4.1 測試轉綠；既有的串流累積、完成與取消三條測試維持綠燈（apps/ios/BuyLedger/Features/AISummary/OllamaClient.swift、apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift）。
- [x] 4.3 補齊截斷說明文字的中英對照並納入本地化目錄的必備清單。驗證：本地化目錄測試綠燈，英文模式下無語言回退（apps/ios/BuyLedger/Resources/Localizable.xcstrings）。

## 5. 文件與現況對齊

- [x] 5.1 讓錯誤分類的文件不再宣稱不存在的重試行為：刪除依分類決定是否重試的描述，改為明文記錄目前無自動重試、失敗直接回到呼叫端。對應 spec requirement「The absence of retry is stated rather than implied」，依 design「文件與現況對齊的方式是刪除宣稱，而非補上實作」。驗證：對該檔搜尋重試相關描述，確認只剩「無自動重試」的陳述（apps/ios/BuyLedger/Core/Networking/APIError.swift）。

## 6. 驗收

- [x] 6.1 執行整體驗收：主 scheme 全套單元測試綠燈，並自測試結果套件確認網路層相關檔案的覆蓋率由零變為非零。驗證：測試通過數不低於改動前；覆蓋率報告列出對應檔案且數值非零。

## 7. QA 修正輪

- [x] 7.1 修正 A1 的契約與測試命名：依 design「控制字元 guard 是獨立於 Foundation 解析的前置檢查」，保留控制字元 key 的前置拒絕 guard，將它寫入 spec，明確區分於 `URL(string:)` 的防禦性 nil 分支；測試改名為描述前置 guard，並明確不宣稱覆蓋後置分支
- [x] 7.2 修正 A2 的映射重複：依 design「服務錯誤映射只有一份實作」，將 `fetchLatest` 與 `fetchSupportedCodes` 的服務結果映射收斂為單一實作；新增 supported-codes 路徑測試，並為未預期 result 的 generic service error 補 spec 與測試
- [x] 7.3 修正 A3 的牆鐘相依：五條 AISummary 串流測試改用 `TestClock`，測試 target 明確連結 `Clocks` product，串流替身用注入 clock 睡眠，測試以 `advance(by:)` 驅動 chunk 與上限；以 3600 秒變異確認逾時測試轉紅
- [x] 7.4 修正 A4 文件：在 `apps/ios/CLAUDE.md` 記錄 AISummary 測試必須以同一個 `TestClock` 注入 `\.continuousClock` 並由 `advance(by:)` 控制時間的 gotcha
- [x] 7.5 對齊 B1、B6 文件註解：移除 `APIError.swift` 註解結尾全形句號，讓 `CurrencyMetadataPersistence.replace` 的方法 doc 與型別 doc 都描述「以非空結果取代」
- [x] 7.6 對齊 B2、B4 文件：proposal Impact 列入 `AISummaryView.swift`，spec 明確寫出 production overall duration limit 為 30 秒
- [x] 7.7 補齊 B3 請求組裝承諾：落實 spec requirement「Request construction preserves its contract」，在 HTTP client 測試捕捉注入 `data` 替身收到的 `URLRequest`，斷言 method、headers、body、timeout，並以 network spec 描述此契約
- [x] 7.8 更正 B5 覆蓋率敘述：由 0% 變為非零的是 5 個檔案 (`HTTPClient`、`ExchangeRateClient`、`ExchangeRateDTO`、`URLRequestBuilder`、`CurrencyMetadataPersistence`)；`OllamaClient` 與 `AISummaryFeature` 既有測試不列入
- [x] 7.9 執行本輪驗收：主 scheme 至少 496 passed / 0 failed、`spectra validate networking-tests-and-resilience` 通過，並保存 A1／A2／A3 的紅綠變異證據

提交次序約束：本案 `CurrencyMetadataCacheTests.swift` 直接呼叫 change 1 `persistence-failure-safe-recovery` 的 `PersistenceContainer.makeInMemory()` API，因此本案無法先於 change 1 單獨 commit。
