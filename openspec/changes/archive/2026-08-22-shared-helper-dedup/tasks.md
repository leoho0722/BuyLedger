## 1. 共用格式化入口

- [x] 1.1 先寫行為保存測試釘住收斂前後的輸出相同：以各畫面現行實作的輸出為基準，對一組涵蓋正數、零、負數與大數的輸入建立期望值。驗證：測試以現行實作通過，作為收斂的對照基準（apps/ios/BuyLedgerTests/BLFormattersTests.swift）。
- [x] 1.2 新增共用的格式化入口，承載金額與百分比的呈現規則，空值與型別差異以多載處理。對應 spec requirement「Dimensions shared across files derive from a single source」的呈現規則情境。驗證：1.1 測試對新入口同樣通過，輸出與收斂前逐項相同（apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift）。
- [x] 1.3 讓五個畫面改為呼叫共用入口，並移除七份私有格式化方法。驗證：全專案搜尋私有的金額與百分比格式化方法零命中；五個畫面的呈現結果與改動前相同（apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift、apps/ios/BuyLedger/Features/Insights/InsightsView.swift、apps/ios/BuyLedger/Features/Customers/CustomersView.swift、apps/ios/BuyLedger/Features/FX/FxView.swift、apps/ios/BuyLedger/Features/Quote/QuoteView.swift）。

## 2. 手繪進度條收斂

- [x] 2.1 讓三處以量測容器搭配軌道與填色形狀繪製的進度指示改用系統進度視圖與專案既有的樣式擴充點，取回系統提供的進度語意。對應 spec requirement「System-provided capabilities are not reimplemented」新增的內聯繪製情形。驗證：全專案搜尋該組合零命中；三處呼叫點皆已改用 `ProgressView` + `BLProgressBarStyle`（apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift、apps/ios/BuyLedger/Features/Insights/InsightsView.swift、apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift）。「進度值可被輔助技術讀出」已以 `xcodebuildmcp ui-automation snapshot-ui` 實測核實三處：Dashboard 目標進度 (iPhone 17，總覽頁) 讀出 `14%`；Insights 類別排行 (iPhone 17，分析頁) 讀出 `100%`／`36%`；`OrderDetailView` 成本拆解列 (iPad，`layout: .wide` 訂單詳情，唯一可達路徑) 讀出 `98%`／`2%`。三處在無障礙樹上皆對應一個高度 6pt (與 `BLProgressBarStyle` 一致) 且帶 `value` 欄位的節點，證實輔助技術可讀出目前值，不僅是構造上成立的推論。依 design 決策：Dashboard hero 卡疊在彩底漸層上，`BLProgressBarStyle` 原本固定的軌道色 (`palette.fillQuaternary`) 是為淺色表面設計、疊上去會顯得混濁，因此為該樣式加一個帶預設值 (等於現狀) 的可選 `track` 參數，供 Dashboard 傳入與底色調和的軌道色。此舉屬延伸既有唯一的樣式擴充點，不是 Non-Goals 所指「建立新的設計系統元件」；三處呼叫點皆改走 `BLProgressBarStyle`，沒有新增第二個型別。`OrderDetailView.swift` 成本拆解列改用 `BLProgressBarStyle` 後，軌道高度由該樣式固定的 6pt 決定 (原手繪版本為 5pt)，屬未被任何測試覆蓋的 1pt 視覺變化：該列僅 `layout: .wide` (iPad regular 詳情，唯一呼叫點 `OrdersView.swift` 的 `detailPane`) 會渲染，而既有 snapshot baseline `orderDetailCostBreakdownBaseline` 建的是預設 `.compact`，兩者互不相交。變化本身可接受 (收斂到共用樣式即是採用其高度)，記錄於此以避免誤讀為「已驗證」。
- [x] 2.2 確認純裝飾用途的形狀未被誤改：作為標籤底色或裁切外框的形狀不屬重造，維持原樣。驗證：主檔管理頁與 AI 面板的標籤底色維持不變（apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift）。

## 3. 驗收

- [x] 3.1 執行整體驗收：主 scheme 全套單元測試綠燈、UI 主回歸綠燈。驗證：測試通過數不低於改動前。
- [x] 3.2 確認呈現結果未變：金額與百分比的呈現不變故原則上不需重錄視覺快照；若進度條收斂造成版面差異則重錄並逐張目視確認為預期變化。驗證：快照比對結果逐項確認。
