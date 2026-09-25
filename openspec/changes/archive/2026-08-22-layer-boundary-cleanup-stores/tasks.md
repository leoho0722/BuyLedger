## 1. 前置確認

- [x] 1.1 確認檔案層分層清理與營收歸屬單一來源兩個 change 皆已封存：前者建立本案要擴充的守門測試檔，後者與本案修改客戶摘要規格的同一條需求 (本案的版本已疊在其上)。驗證：`spectra list` 確認兩者狀態，結論寫入本 change

  **結論 (QA 修正輪覆核，如實記載)**：`spectra list` 與 `openspec/changes/` 目錄確認 `layer-boundary-cleanup-files` 與 `revenue-attribution-single-source` 兩個前置 change **皆已實作完成並通過 QA 驗證，但依本計劃 (29 案) 慣例尚未封存** (目錄仍存在於 `openspec/changes/`，未 archive)。前者建立的 `LayerBoundaryTests.swift` 已存在於 `apps/ios/BuyLedgerTests/`，本案在其上新增 `rootStoreDeclarationsMatchTheNavigationHostWhitelist` 測試；後者的營收歸屬規則已落地於 `LedgerOrder.revenueAttributionOrders(from:)` 並被 `CustomerRow.aggregate(orders:)` 使用。原本記載於本節「已讀 `customer-summary` spec 確認疊在營收歸屬之上」的說法與 QA 第二優先發現的事證直接矛盾 (本案原本的 MODIFIED 版本其實退回了營收歸屬之前的措辭、且遺漏兩則既有 scenario)，該說法不成立，已於 QA 修正輪重寫 `specs/customer-summary/spec.md`，使其完整保留現有 spec 全部 scenario 並疊在 `revenue-attribution-single-source` 的版本之上。

## 2. 補齊兩個缺席的 feature

- [x] 2.1 新建總覽 feature：狀態持有訂單、開團、月獲利目標與載入狀態四份唯讀投影；action 為載入、重試與 delegate (重新整理、開團點選、新增訂單、檢視全部訂單)，全部只回送 delegate、不自行寫任何跨 feature 狀態。reducer body 用顯式型別、MARK 分區依平台範本。此為規格 A store-bound view only receives its own feature's store 中投影與 delegate 的落地。驗證：新增 `DashboardFeatureTests` 的四條 delegate 送出測試綠，且不使用關閉窮舉的設定
- [x] 2.2 新建分析 feature：狀態持有訂單、開團、載入狀態，並收編目前住在根狀態的分析區間；action 綁定化以保留既有選擇器繫結寫法；delegate 含重新整理、開團點選、類別點選。此為規格 Insights analysis range is owned by feature state and persists 中「區間屬分析 feature 而非根」的落地。驗證：新增 `InsightsFeatureTests` 的區間繫結與兩條 delegate 測試綠；根狀態不再有分析區間屬性

## 3. 擴充兩個既有 feature 的邊界

- [x] 3.1 客戶 feature 的 action 自空列舉改為含載入與客戶點選 delegate，狀態維持只有訂單投影 (聚合口徑不動，屬另案)。此為規格 Customers screen aggregates orders into per-customer summaries 中「讀投影而非他人狀態、選取走 delegate」的落地。驗證：新增 `customerTappedEmitsDelegate` 綠；既有聚合測項不修改即通過

  **QA 修正輪**：`customerTappedEmitsDelegate` 名不符實 (未驗證 delegate 確實送達父層，僅驗證無狀態突變)，已改名為 `customerTappedDelegateMutatesNoState`，比照 `DashboardFeatureTests`／`InsightsFeatureTests` 同類測試的既有命名。

- [x] 3.2 開團 feature 的狀態新增訂單投影供開團摘要使用，action 新增收款狀態切換與對應 delegate (比照既有的改名 delegate 由根攔截)。開團 feature **不自行改訂單投影**，避免與訂單 feature 產生雙寫。驗證：新增 `receiptStatusToggleEmitsDelegateWithoutMutatingState` 與「訂單投影驅動開團摘要」兩條測試綠

  **QA 修正輪**：「訂單投影驅動開團摘要」原測試 `ordersProjectionDrivesCampaignSummary` 是假測試 (未經 State、直接用區域陣列驗算術)，已重寫為直接讀寫 `CampaignFeature.State.orders` 並比較投影更新前後的衍生摘要，變異驗證 (清空投影) 已確認轉紅。

## 4. 根 feature 收斂與轉發

- [x] 4.1 依 design 決策：D1 投影沿用根 feature 的變更監看，不引入共享狀態機制 與 D2 所有變更監看集中掛在同一處，根狀態新增兩個子狀態、刪除分析區間，reducer 組合內加兩個範圍組合；把既有的訂單變更監看擴充為同時同步全部訂單投影，另加開團變更監看、訂單載入狀態監看與月獲利目標監看。全部變更監看掛在 reducer 組合外層、集中於同一段不散落，投影一律唯讀語意 (只有根 feature 寫、feature 端不得改)。驗證：新測試 `ordersChangeSyncsAllProjections` 與 `campaignsChangeSyncsDashboardAndInsightsProjections` 綠——單次上游變動後全部投影等值

  **QA 修正輪 (第一優先)**：實作者把開團投影 (`orders.campaigns`／`dashboard.campaigns`／`insights.campaigns`) 留在內嵌的 `syncCampaignsProjections(in:)` 手動呼叫，未收進 `onChange`。QA 判定該顧慮的紅燈是測試 fixture 造出的生產不可達狀態，已改用 `onChange(of: \.campaigns.campaigns)` 集中同步、移除 `syncCampaignsProjections(in:)`，並修正 `campaignRenamedCascadesToOrdersInMemoryAndSyncsCopy` 的初始狀態播種。投影唯讀語意新增掃描式守門 `ProjectionWriteBoundaryTests`，3 個繞道變異驗證皆轉紅 (見第四優先)。

- [x] 4.2 依 design 決策：D3 delegate 只轉發到根 feature 既有的導覽 case，新增的 delegate 分支一律轉呼既有的導覽 case (開團選取、類別選取、客戶選取、新增訂單、分頁切換、訂單收款狀態變更)，每條分支只有一行轉送，**不新增任何平行的根 case**。此為規格中「轉發不得新增平行根 action」的落地。驗證：新增四條轉接斷言綠；根 feature 的 action 列舉在本次差異中無新增的導覽類 case
- [x] 4.3 客戶選取的 delegate 轉發必須保持「先清空該分頁導覽路徑、再切分頁」的既有次序 (否則 iPad 分欄導覽會在分欄更新時崩潰，屬既有踩雷)。驗證：新測試 `customersCustomerTappedClearsMorePathBeforeTabSwitch` 綠
- [x] 4.4 依 design 決策：D4 delegate 只轉發，去重仍由訂單 feature 負責，確認載入 delegate 只做轉發、不自帶守衛。驗證：斷言總覽的重新整理 delegate 會送出訂單與設定兩個載入 effect；另於實機自總覽冷啟動走一次，確認資料正常出現且未重複載入

## 5. 五個畫面改吃 scoped store

- [x] 5.1 依 design 決策：D5 語言走建構參數，不做投影，把總覽、分析、開團列表、開團詳情、客戶五個畫面的 store 型別改為各自 feature 的 scoped store，並比照訂單畫面既有慣例加語言建構參數供導覽標題使用。三個導覽宿主的目的地分派改傳 scoped store 與語言。**所有可及性識別碼與版面完全不動**。驗證：根 store 在 Features 下的宣告檔案恰為四個根導覽宿主；介面自動化主回歸零改測試碼即通過

  **QA + Style 修正輪**：`CustomersView.swift` 的 `language` 參數全檔零使用 (該畫面標題固定為 `.navigationTitle(Text("客戶名單"))`，非 `rootNavigationTitle`，且非六個根分頁之一)，已刪除該死參數，同步改 `MoreView.swift` 呼叫端與 `#Preview`。`CampaignDetailView` 確認未加此參數 (原不需要)，未變動。

- [x] 5.2 開團詳情的收款狀態切換改送開團 feature 自己的切換 action，不再直接送出訂單 feature 的 action。驗證：該檔全檔不再出現直接送出訂單 feature action 的寫法，且根 feature 有對應的轉發斷言

## 6. 守門與測試

- [x] 6.1 依 design 決策：D7 store 邊界加進既有的分層守門測試，在檔案層分層清理建立的守門測試中新增一條斷言：掃描根 store 在 Features 下的宣告位置，與白名單常數逐一比對，**多一個或少一個都失敗** (白名單是精確集合而非上限)。依 design 決策：D6 「更多」畫面列為白名單例外，該畫面列入白名單，並在其檔頭寫明它是導覽宿主而非 feature 畫面的理由。此為規格中「根宿主白名單是精確集合」的落地。驗證：該斷言綠；移除白名單任一項即失敗 (驗證後還原)
- [x] 6.2 改寫根 feature 測試：把分析區間繫結測試改打 scoped 路徑，並補齊本案新增的投影同步與 delegate 轉接斷言。驗證：改寫後既有斷言逐條比對無遺漏，新測試全綠

  **QA + Style 修正輪**：`RootFeatureTests.swift` 6 處註解引用了只存在於 `openspec/changes/` 工件的決策編號 (D2／D3／D4) 與 task 編號 (task 5.2)，archive 後無處可查，已改寫為直接描述決策內容本身 (並引 `apps/ios/CLAUDE.md`「架構分層」章節中已落地的對應規則，D4 該章節未收錄故僅寫自描述內容，不假引不存在的出處)。

- [x] 6.3 [P] 兩個基準圖測試改用新 feature 的狀態建構 store 並傳語言參數，**版面一行不動、基準圖不得重錄**。驗證：跑測試前先鎖模擬器淺色外觀；`git status --short` 下快照目錄無變更。若出現差異圖，先確認是否整張變色 (外觀設定) 或日期格式變化 (語系設定)，兩者皆非本次回歸

## 7. 文件與全回歸

- [x] 7.1 在 `apps/ios/CLAUDE.md` 新增一條硬規則：綁 store 的畫面只吃自己 feature 的 scoped store，跨 feature 資料走根 feature 單向同步的唯讀投影、跨 feature 意圖走 delegate 轉發到既有導覽 case，例外只有四個根導覽宿主且白名單由守門測試鎖住。驗證：內容審視——規則與守門測試的白名單一致
- [x] 7.2 先 `cd apps/ios && agvtool next-version -all` 遞增 build number，再以 xcodebuildmcp 序列跑 iPhone 與 iPad build (共用 build.db 不可並行)，接著跑主 scheme 全部單元測試與介面自動化主回歸。驗證：兩平台 build 成功、單元測試全綠且基準圖零重錄、介面主回歸兩個尺寸類別各一輪全綠

  **QA 修正輪範圍限定**：本輪只跑 test、不遞增 build number、不動 `project.pbxproj` (依本次 QA 修正輪指示)；build number 遞增與 build 驗證留待封存前的正式驗收輪執行。本輪已完成的驗證見下方「QA 修正輪驗收記錄」。

## QA 修正輪驗收記錄 (2026-08-02)

- 第一優先 (D2)：開團投影三處改收進 `onChange(of: \.campaigns.campaigns)`；`CampaignIntegrationTests`／`RootFeatureTests`／`CampaignFeatureTests`／`CustomersFeatureTests`／`DashboardFeatureTests`／`InsightsFeatureTests`／`ProjectionWriteBoundaryTests` 共 92 個測項全綠
- 第二優先：`specs/customer-summary/spec.md` 的 MODIFIED 版本已完整保留現有 8 個 scenario/example 標題、疊在 `revenue-attribution-single-source` 版本之上，並保留本案自己的兩個新 scenario
- 第三優先：`ordersProjectionDrivesCampaignSummary` 重寫為真正驗證投影驅動；`customerTappedEmitsDelegate` 更名為 `customerTappedDelegateMutatesNoState`
- 第四優先：新增 `ProjectionWriteBoundaryTests.swift` 掃描式守門。**QA 第二輪覆核發現初版掃描範圍只涵蓋各投影持有 feature「自身檔案」，以同名 extension 檔繞過 (`CampaignFeature+ZZProbe.swift`) 零命中**，已擴大為掃描 `Features/` 全樹 (排除 `RootFeature.swift`)：偵測落在 `struct <Owner>`／`extension <Owner>`／`extension <Owner>.State` 區塊內 (任意檔案、任意巢狀深度) 對投影屬性的賦值或 mutating 方法呼叫，另加一條偵測 `inout <Owner>.State` 參數 (整份 state 外流)。6 個繞道變異 (QA 探針 1 個＋原版 3 個＋新構 2 個：extension 寫在另一個 feature 目錄、extension 寫在 View 檔內) 皆轉紅後已還原；全庫零誤紅 (3 個守門測試含新增的下限斷言皆綠)
- 第五優先：新增內容 4 處破折號已清除 (`app-layer-boundaries` × 2、`campaign-analytics-surfaces` × 1、`customer-summary` × 1)；`RootFeatureTests.swift` 6 處懸空引用已改寫
- 第六優先：`CustomersView.swift` 死參數 `language` 已刪除 (同步 `MoreView.swift`)；`CampaignDetailView.swift` 懸空註解精簡為 1 行；`RootFeature.swift` 的 `syncCampaignsProjections` 已隨第一優先移除
- 第七優先 (不屬本案)：`OrderCreateTests.testCreateOrderAppearsInList` 的確定性根因已定位並修復，歸屬 `test-effectiveness-repair` 案 (task 4.1 後續 UI 回歸補記把 `typeChargedAmount` 的拖曳起訖點由預設 0.7／0.5 改成 0.4／0.2，導致拖曳區間上移到表單上半、意外觸碰客戶名欄)；已改回預設值，iPhone／iPad 各自多輪重跑穩定通過。另有一條與此迴歸無關、範圍更廣的殘留間歇性 flaky (`scrollToHittableGently`／`waitUntilHittable` 對特定欄位偶發 "activation point invalid"，即使用預設值、甚至完全不涉及本欄的 `KeyboardDismissTests.testNumericKeyboardToolbarDismissesKeyboard` 也曾重現)，判斷為既有、更底層的 XCUITest／模擬器限制，非本案或 `test-effectiveness-repair` 造成，未在本輪解決，詳見 QA 回報
