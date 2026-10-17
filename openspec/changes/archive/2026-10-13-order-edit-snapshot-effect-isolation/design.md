## Context

歷史實測：2026-10-06 的 `progress-title-render-reliability` task 1.1 五輪整批 `SnapshotTests`，長識別碼測試 4／5 輪、合併訂單測試 2／5 輪出現 Unimplemented，觸發 Service 隨輪次不同。這些是相依缺失 issue，不是圖片像素不符。

歷史追加證據：2026-10-06T12:54Z 的 xcresult 只記錄一條進度標題圖片失敗，但日誌對一般既有訂單 snapshot 記錄六個主檔 Service 的 Unimplemented 與「No test reporter」。bundle：`/Users/leoho/Library/Developer/MobileBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-10-06T12-54-22-178Z_pid47262_2a2ddd00.xcresult`；log：同 workspace 的 `logs/test_sim_2026-10-06T12-54-22-178Z_pid47262_70a1d4b6.log`。歷史證據不代替本次執行。

本次來源追查：`OrderEditView` 送 `.view(.task)` 並等待 `finish()`，`OrderEditOperations.apply` 在既有訂單情境回傳 `.none`；選項由 `OrderEditOptions` 在 State 初始化時帶入。`OrderEditPhotosSection` 有獨立 `.task`，送出照片子 Feature 的 `.view(.task)`；`OrderEditPhotosFeature.core` 只有 `orderID` 非空且 `photoLoadPhase == .notLoaded` 才啟動 `orderService.fetchOrderPhotos`。三條 snapshot 已各自設定 `state.photos.photoLoadPhase = .loaded`。六種主檔讀取已不在現行 OrderEdit 系列程式碼內，不能再以注入它們作為修正。

## Goals / Non-Goals

- In scope：訂單編輯 snapshot 的共用初始 State、同檔載入事件回歸測試、變異驗證與執行證據；形成新 gotcha 時才同步測試規則。
- Out of scope：正式 reducer 與 View、共用 harness、Service 預設值、snapshot 基準圖、其他元件與平台情境。

## Decisions

### Supersedes：以共用初始 State 取代六個主檔載入替身

取代原「在 Store 建立時注入完整且固定的載入替身」決策。原因是現行主檔選項已在初始化帶入，表單 `.task` 不再呼叫 `orderSourceService.fetchOrderSources`、`categoryService.fetchCategories`、`paymentMethodService.fetchPaymentMethodInfos`、`reconciliationStatusService.fetchReconciliationStatuses`、`campaignService.fetchCampaigns`、`currencyMetadataService.fetchCodes`。這六個 closure 不覆寫，讓未來意外重新載入仍立即回報 issue。

在 `SnapshotTests+OrderEdit.swift` 集中建立初始 State，與現有三條測試使用相同 original、`UUID(0)`、`TestDependencies.fixedNow`、`Asia/Taipei` 行事曆及已載入照片。圖片仍在原方法內以 key window 渲染，保留名稱與 baseline 路徑。共用 `withFixedNow` 只負責原有的時間相依，不修改。

### Supersedes：以確定送出的現行事件驗證沒有載入效果

取代原「以載入觸發和整批執行驗證隔離」中「缺失的六個主檔 closure 必須重現」與「移除其中一個主檔覆寫」的要求；保留整批、日誌、實際數量與基準圖檢查。

同檔新增 Swift Testing 測試，以共用初始 State 建立窮舉 TestStore，明確送 `.view(.task)` 與 `.photos(.view(.task))`，各重複送出以涵蓋畫面再次出現；`send` 不帶狀態變更 closure，最後 `finish()`，確保整筆 State 不變、無未接收 action、無未完成效果。所有 Service 維持原本會立即回報 issue 的 testValue。

這是既有行為的回歸驗證：先確認綠燈，再暫移除共用 State 的 `.loaded` 設定，使用相同測試必須出現 `OrderService.fetchOrderPhotos` 的 Unimplemented 與狀態差異；立刻還原並確認通過。變異只改本檔測試設定，不改產品或共用 harness。若變異不失敗，不能聲稱已驗證隔離。

### Supersedes：以無新增圖片差異取代既有圖片方法全綠要求

取代原 Implementation Contract Acceptance 與 pending task 1.2 的「三條方法層 snapshot 各通過」要求，以及 pending task 2.1 只依既有像素雜訊規則判讀圖片失敗的限制。使用者已明確確認：本 change 的圖片驗收改為修改前後無新增差異，修改前已存在的日期排列失敗保留並另案處理。這不代表圖片測試通過。

修改前整批實測已有四條圖片失敗：`campaignEditView_編輯既有開團_符合基準圖()`、`orderEditView_一般既有訂單_符合基準圖()`、`orderEditView_合併訂單情境_符合基準圖()`、`orderEditView_長訂單識別碼_顯示短識別碼()`。圖片顯示 DatePicker 日期與時間由同行改為上下排列；此差異不屬於已知導覽列像素雜訊。此處只豁免這四條既有失敗，不豁免新增圖片差異、其他新失敗或未預期 Service issue。

三條訂單編輯 snapshot 必須各實際執行，逐一比較修改前與修改後的 `abs(baseline - actual)` 差異圖，差異圖須逐像素相同。新增受控事件測試仍須真正通過，變異仍須失敗且還原後通過；五輪整批、完整單元回歸、日誌與基準圖無修改檢查全部保留。DatePicker、正式程式、精度與 baseline 均不修改。

### 整批與完整回歸

先於修改前執行一次完整 `SnapshotTests`，把本次結果與歷史分列。最終設定於同台 iPhone 17、淺色外觀連續五輪完整 `SnapshotTests`，再執行完整 `BuyLedgerTests` 單元回歸。五輪是沿用歷史失敗頻率所選的驗證次數，不是可靠度估計。每次 xcresult 必須實際執行大於零，同時查 xcresult 與日誌的 Unimplemented (含 No test reporter)。上述四條修改前已存在的日期排列圖片失敗依使用者確認另案處理；最終五輪與完整回歸不得新增失敗。不能重錄、放寬或刪除斷言。完整單元回歸中既有 ServiceTestValueStrictnessTests 以 withKnownIssue 刻意驗證的 Unimplemented，須對照測試來源與 xcresult expectedFailures 分類，不列為訂單編輯載入外溢。

環境以 `mobilebuildmcp simulator list` 確認 iPhone 17 `DDAA3311-B464-4DD3-96B8-360B26AF1929` (iOS 26.5) 仍存在；以明確識別碼執行，避免預設 simulatorId 指向不同裝置。build/test 皆使用 MobileBuildMCP；只有 xcresult 摘要可用專案允許的唯讀 `xcrun xcresulttool get test-results summary`。

## Implementation Contract

- Behavior：三條 snapshot 的可見資料與基準圖檔案不變，修改前後的圖片差異圖相同；明確觸發表單及照片載入事件時 State 不變、效果完成、未覆寫 Service 沒有被呼叫；整批與完整回歸不出現訂單編輯載入的 Unimplemented。capability-level observable behavior is unchanged。
- Interface：既有三個 snapshot 方法名稱、Store 泛型與產品 Action／Service API 不變；新增的 helper 與測試只在本檔。
- Failure modes：Service testValue 保留立即失敗，不捕捉或忽略 issue。變異要能回報 `OrderService.fetchOrderPhotos`；圖片像素差異依上述使用者確認的範圍與修改前證據判讀，不重錄或放寬精度。
- Acceptance：修改前一輪整批有實際執行數；受控事件測試綠燈，移除 `.loaded` 設定的變異失敗且還原後綠燈；三條 snapshot 各有方法層實際執行大於零的證據，修改前後差異圖逐像素相同；上述四條既有日期排列圖片失敗如實保留並另案處理，不要求其在本 change 轉為綠燈；最終五輪整批各有大於零的執行數且日誌與 xcresult 無上述 Unimplemented；完整單元回歸無新失敗；`git status --short apps/ios/BuyLedgerTests/__Snapshots__` 無變動。
- Scope：僅本檔初始 State 設定、必要測試與 change 內證據；形成新測試 gotcha 才改規則。若發現需要正式 reducer 或共用 harness 修改，停下回報證據與新範圍。

## Risks / Trade-offs

- [集中 State 時誤改選項、日期或照片，造成 baseline 改變] → 保留原建構參數，逐條方法層比對。
- [非同步 issue 被歸到下一條測試] → 以明確 action、窮舉 TestStore 與 finish 檢查生命週期，並同時檢查整批日誌與 xcresult。
- [只確認沒有失敗但測試未執行] → 每次從 xcresult 記錄實際數量；方法篩選帶完整 `()`。
- [重複寫入無效的替身掩蓋未來回歸] → 所有 Service 維持未覆寫，以變異證明照片載入會立即失敗。
