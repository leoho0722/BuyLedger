## 1. 抽出共用的可勾選列

- [x] 1.1 讓可勾選列成為單一定義，供兩種尺寸版面共用：抽取為純粹的搬移，呈現與行為逐字不變。對應 spec requirement「The same capability is not maintained twice for different size classes」。驗證：兩種版面各自的可勾選列定義移除；抽取前後兩種尺寸的畫面以視覺比對確認相同（apps/ios/BuyLedger/Features/Orders/Components/OrderSelectableRow.swift）。
- [x] 1.2 確認抽取後兩種尺寸的無障礙呈現一致：抽取前緊湊版的勾選圖示對輔助技術隱藏而常規版未隱藏，抽取後兩者必然相同。對應 spec requirement「Orders list provides a multi-select mode」的一致性情境。驗證：以輔助技術檢視兩種尺寸的可勾選列，屬性完全相同。

## 2. 抽出共用的工具列

- [x] 2.1 讓多選工具列成為單一定義，供兩種尺寸版面共用：兩份實作去除縮排後僅相差三行，抽取為純粹的搬移。驗證：兩種版面各自的工具列定義移除；工具列上的每個動作在兩種尺寸下皆可觸發且行為相同（apps/ios/BuyLedger/Features/Orders/Components/OrdersToolbarContent.swift）。
- [x] 2.2 確認工具列的擺放位置規則未被改動：兩種尺寸皆不使用底部工具列，批次與選取類操作維持在頂部擺放。驗證：抽取後的工具列不含底部擺放；iPhone 與 iPad 各實際確認一次工具列可見。

## 3. 呼叫端收斂

- [x] 3.1 讓兩種版面改為呼叫共用實作，移除重複定義，並確認版面結構中真正不同的部分維持分離。驗證：兩個版面檔案不再包含可勾選列與工具列的實作；其餘結構差異保留（apps/ios/BuyLedger/Features/Orders/OrdersView.swift、apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift）。

## 4. 驗收

- [x] 4.1 執行整體驗收：主 scheme 全套單元測試綠燈、UI 主回歸在 iPhone 與 iPad 各一次綠燈。驗證：測試通過數不低於改動前；多選、全選、清除、退出四個流程在兩種尺寸各走一次。
- [x] 4.2 確認呈現未變：抽取為純搬移故原則上不需重錄視覺快照；若出現差異則視為非預期並修正，而非直接重錄接受。驗證：快照比對結果逐項確認。
