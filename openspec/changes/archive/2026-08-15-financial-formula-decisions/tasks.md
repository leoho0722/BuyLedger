## 1. 折抵上限與收款非負

- [x] 1.1 先寫紅燈測試釘住收款不為負：以折抵等於、略大於、遠大於實付金額三種輸入斷言儲存值等於實付金額且收款不為負。對應 spec requirement「A cardless deduction never exceeds the charged amount」。驗證：三條斷言在實作前皆失敗（apps/ios/BuyLedgerTests/OrdersFeatureTests.swift）。
- [x] 1.2 讓折抵上限成為儲存值的不變量：在既有正規化路徑加入與實付金額的比較，不新增欄位。依 design「折抵上限以資料不變量表達，而非只在畫面提示」。驗證：1.1 三條斷言轉綠（apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift）。
- [x] 1.3 讓修正發生在使用者眼前而非儲存瞬間：表單在輸入超額與載入既有超額資料時，都把值改為上限並顯示原因說明，不得靜默改值。對應同一條 requirement 的可見性要求。驗證：新增測試斷言超額輸入後表單值等於實付金額且持有說明；既有超額資料開啟後即顯示修正（apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift、apps/ios/BuyLedger/Features/Orders/OrderEditView.swift）。

## 2. 收款為零時的毛利率

- [x] 2.1 讓沒有收款基準時不顯示比率：收款為零的訂單，毛利率呈現為空值而非百分之零。對應 spec requirement「Margin is not reported when there is no revenue to measure against」，依 design「收款為零時毛利率顯示空值，而非零」。驗證：新增測試斷言收款為零時呈現為空值、收款為正時照常呈現比率；搜尋所有毛利率呈現點確認皆走同一格式化入口（apps/ios/BuyLedger/Core/Domain/OrderSummary.swift）。

## 3. 報價公式

- [x] 3.1 先寫紅燈測試釘住輸入與輸出一致：對數組成本與目標毛利的組合，斷言卡片顯示的預估毛利率等於輸入的目標毛利（容許進位差異）。對應 spec requirement「The target margin input means gross margin, and the suggested price follows from it」。驗證：測試在實作前失敗（apps/ios/BuyLedgerTests/QuoteFeatureTests.swift）。
- [x] 3.2 讓建議售價改用真毛利公式，使輸入的目標毛利名副其實，欄位名維持不變。依 design「報價頁改用真毛利公式，欄位名不動」。驗證：3.1 測試轉綠（apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift）。
- [x] 3.3 讓目標毛利維持不設上限，但在達到或超過百分之百時不呈現任何數字，改顯示說明；降回後恢復。對應 spec requirement「A target margin at or above one hundred percent yields no price」，依 design「目標毛利不設上限，改以空狀態處理數學邊界」。驗證：新增測試涵蓋百分之百、超過、以及降回三種情境，斷言三個數字一起消失與一起恢復；輸入值本身不被夾住（apps/ios/BuyLedger/Features/Quote/QuoteView.swift）。

## 4. 精度一致

- [x] 4.1 讓報價與建單對同一筆生意算出相同金額：報價頁的金額計算改用與訂單財務路徑相同的十進位型別，浮點數僅保留於圖表繪製邊界。對應 spec requirement「Quote amounts use the same decimal precision as order finances」，依 design「報價頁改用十進位型別，浮點數只留給繪圖」。驗證：新增測試斷言相同成本輸入下報價與訂單金額完全相等；搜尋報價計算路徑確認除圖表邊界外無浮點型別。
- [x] 4.2 確認型別替換未改變語意：以既有報價測試為基準，對同一組輸入斷言改動前後結果相等（容許進位差異）。驗證：既有報價測試全數維持綠燈。

## 5. 文案與視覺

- [x] 5.1 補齊新增說明文字的中英對照並納入本地化目錄的必備清單。驗證：本地化目錄測試綠燈，英文模式下無語言回退（apps/ios/BuyLedger/Resources/Localizable.xcstrings）。
- [x] 5.2 確認受影響的視覺快照並逐張目視確認：報價頁與訂單詳情因金額格式與新增說明文字而可能改變版面；若 footer 修正後三條訂單編輯快照自動回綠，確認無需重錄，若仍有差異才逐張確認差異只有預期變化。驗證：測試前先鎖模擬器淺色外觀；三條 `orderEditView` 快照實際通過。

> 注意：`apps/ios/BuyLedger/Resources/Localizable.xcstrings` 的 diff 包含非本案內容 (444 行插入、34 行刪除)，成因是 Xcode 編譯階段同步其他批次原本缺少的條目，提交時需注意歸屬。

## 6. 驗收

- [x] 6.1 執行整體驗收：主 scheme 全套單元測試與 UI 主回歸都跑完；已知 flaky `OrderCreateTests.testCreateOrderAppearsInList` 若單獨失敗，記錄為既知環境例外，不修改 UI 測試基礎設施。驗證：測試通過數不低於改動前。
