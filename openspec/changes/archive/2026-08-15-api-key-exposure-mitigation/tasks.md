## 1. 憑證移出網址

- [x] 1.1 讓匯率請求的憑證改以 Bearer 權杖標頭攜帶，端點路徑不再含憑證段，使金鑰不再出現在網址中。服務端支援此認證方式已確認。對應 spec requirement「Credentials travel in headers, not in the URL」，依 design「金鑰移出網址，理由與產物散布無關」。驗證：新增測試斷言組出的請求網址不含憑證、授權標頭以 Bearer 形式攜帶之（apps/ios/BuyLedger/Features/FX/ExchangeRateClient.swift、apps/ios/BuyLedgerTests/ExchangeRateClientTests.swift）。
- [x] 1.2 確認端點路徑改變未破壞既有的回應處理：兩條路徑（最新匯率、支援幣別）的解碼與業務錯誤分流行為不變。驗證：既有的匯率取得與六種錯誤分流測試全數維持綠燈。
- [x] 1.3 以實際請求確認匯率仍能正常取得，而非只看單元測試。驗證：以實機或模擬器實際載入一次匯率頁與報價頁，兩者皆取得資料成功。

## 2. 憑證不進入任何輸出

- [x] 2.1 確認全專案沒有任何位置把憑證或含憑證的值寫入日誌、錯誤訊息或診斷輸出。對應 spec requirement「Credentials never reach logs, messages, or diagnostics」。驗證：逐一檢視日誌、錯誤建構與診斷上報的呼叫點，確認無憑證或完整網址的內插；搜尋結果記錄一次。

## 3. 把取捨寫成有前提的記錄

- [x] 3.1 讓內嵌金鑰成為有記錄的決定而非沒人提過的預設：在平台指引寫明它是已評估並接受的風險、成立前提為產物不對外散布且金鑰為開發者自有，以及前提失效時金鑰必須移出產物。對應 spec requirement「An embedded credential is recorded as an accepted risk with its precondition」，依 design「維持建置期注入，把風險記錄為有前提的接受」。驗證：平台指引可搜尋到該段，且三個要素（接受、前提、失效後作法）皆齊備（apps/ios/CLAUDE.md）。
- [x] 3.2 讓撤換有可照做的步驟：記錄兩個服務各自的換發位置，以及本專案因採建置期注入，換發後必須重新建置並重新安裝才會生效。依 design「撤換程序寫成可照做的步驟，而非原則」。驗證：程序可被沒有背景的人照著執行；明載重新建置與安裝這一步（apps/ios/README.md）。
- [x] 3.3 讓環境設定文件反映認證方式的改變，使新機器設定時不會照舊把金鑰當成網址的一部分。驗證：說明文件描述的注入鏈路與實際一致（apps/ios/README.md）。

## 4. 驗收

- [x] 4.1 執行整體驗收：主 scheme 全套單元測試綠燈。驗證：測試通過數不低於改動前。
