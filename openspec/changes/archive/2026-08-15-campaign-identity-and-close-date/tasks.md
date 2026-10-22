## 1. 結單日的日粒度判定

- [x] 1.1 先寫紅燈測試釘住當日不收單：以固定注入時間建立一個結單日等於今天、但時間戳早於現在的開團，斷言重新載入後狀態仍為進行中；另斷言把注入時間推進到隔日後轉為已收單。對應 spec requirement「Automatic transition from ongoing to closed at the close date」。驗證：第一條斷言在實作前失敗（apps/ios/BuyLedgerTests/CampaignFeatureTests.swift）。
- [x] 1.2 讓自動收單以日為粒度判定，使「結單日設為今天」在當天維持進行中：判定改為以注入的曆法取當日起點、界線為結單日當日起點加一日，不改寫任何既有的結單日資料。依 design「日粒度判定放在評估端，不在寫入時正規化結單日」。驗證：1.1 兩條斷言皆綠；沒有結單日的開團在任何注入時間下維持進行中（apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift）。
- [x] 1.3 確認判定不依賴執行機器的時區設定：判定全程使用注入的曆法與時間，不直接讀取系統設定。驗證：對判定所在區段搜尋直接讀取系統時間或曆法的呼叫零命中；以不同時區的注入曆法各跑一次測試結果一致。

## 2. 開團名稱唯一性

- [x] 2.1 先寫紅燈測試釘住重複名稱被拒：斷言儲存一個名稱與既有開團相同的新開團時，儲存被拒絕且持久層筆數不變；並斷言編輯既有開團維持原名儲存可成功。對應 spec requirement「Campaign entity with two-state lifecycle」新增的唯一性規則。驗證：第一條斷言在實作前失敗（apps/ios/BuyLedgerTests/CampaignFeatureTests.swift，唯一性檢查邏輯由父層 CampaignFeature 持有，紅燈測試放這裡而非 CampaignEditFeatureTests.swift）。
- [x] 2.2 讓儲存流程在進入任何寫入副作用之前擋下重複名稱：比對以去除前後空白後的名稱進行並排除自身識別碼，拒絕時直接返回、不進入行事曆調解等後續副作用。依 design「同名檢查放在寫入之前，拒絕即不進入副作用」。驗證：2.1 兩條斷言皆綠；另斷言拒絕路徑不觸發任何寫入或行事曆相依（apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift）。
- [x] 2.3 讓拒絕的原因對使用者可見：表單上呈現重複名稱的說明，而非靜默不動作。驗證：新增測試斷言拒絕後表單持有可呈現的錯誤說明；中英兩種語言下該文案皆有對應字串（apps/ios/BuyLedger/Features/Campaigns/CampaignEditFeature.swift、apps/ios/BuyLedger/Features/Campaigns/CampaignEditView.swift、apps/ios/BuyLedger/Resources/Localizable.xcstrings）。
- [x] 2.4 確認既有的同名資料不受影響，並依 design「既有重名不自動處理，但在規格中明記為已知限制」不做自動清理或改名：以兩個同名開團的初始狀態驗證兩者皆可讀取、開啟編輯並在不改名的情況下儲存成功。驗證：新增測試涵蓋此情境並通過，證明本次只擋新的重複而非讓既有資料無法儲存。

## 3. 驗收

- [x] 3.1 執行整體驗收：主 scheme 全套單元測試綠燈、UI 主回歸綠燈，並確認開團列表與訂單編輯的可歸屬清單在結單日判定改變後行為正確。驗證：測試通過數不低於改動前；以結單日等於今天的開團確認它仍出現在訂單編輯的可歸屬清單中。

  **實測結果**：主 scheme 單元測試 **421 passed / 0 failed** (改動前基準 415，本案新增 6 條全綠)。UI 主回歸 iPhone 49/50、iPad 49/50，兩者唯一失敗皆為 `OrderCreateTests.testCreateOrderAppearsInList` 這條已知 flaky (早於本程式所有 change，已以乾淨 HEAD `91e074c` 三重舉證)，非本案造成。iPhone 與 iPad simulator build 各成功一次。

  結單日判定改為日粒度後的行為驗證由 `closeDateTodayStaysOngoingUntilTheFollowingDay` 與跨三時區的 `closeDateTodayStaysOngoingRegardlessOfInjectedTimeZone` 兩條測試涵蓋，兩者在判定邏輯改動前為紅、改動後轉綠。

  ⚠ 過程備註：單元測試連兩次撞到 `UIKitNavigation is missing a dependency on X` 的模組相依掃描 flaky (X 分別為 `OrderedCollections` 與 `IssueReportingPackageSupport`)，`xcodebuildmcp utilities clean` 後重跑即正常，非程式碼問題。

## 4. Coding Style 與 QA 審查後續修正

- [x] 4.1 精簡註解在描述改了什麼而非程式碼在做什麼的五處：`CampaignEditFeature.swift` 的 `saveTapped` 註解、`CampaignFeature.swift` 兩處（唯一性檢查段落、關閉表單段落）、`OrdersFeature.swift` 的 `campaignsLoaded` 註解、`OrderEditFeature.swift` 的 `availableCampaignsLoaded` 註解重排並壓縮。驗證：全部改為描述現況而非變更歷程，`OrderEditFeature.swift` 註解順序與其下程式碼順序一致。
- [x] 4.2 清除三處冗餘的 `let calendar = calendar` shadow（`CampaignFeature.swift`、`OrdersFeature.swift`、`OrderEditFeature.swift`）：三處 `calendar` 皆只餵給非逃逸的 `.map { }`，不像鄰行 `campaignRepository` 需要為逃逸的 `.run { }` 捕獲快照；同檔其餘案例（如 `OrdersFeature.swift` 的 `filteredOrders(referenceDate:calendar:)` 呼叫點）本就直接引用屬性、無 shadow。驗證：移除後編譯與全套測試皆通過。
- [x] 4.3 補文件缺口：三處評估端共用 `Campaign.evaluatingAutoClose(asOf:calendar:)` 的不變量只寫在程式碼註解、未回寫 `apps/ios/CLAUDE.md`。於「資料層與 Dependency 注入」節新增主／次 bullet，主規則為三處共用單一實作、次要說明日粒度邊界（結單日隔天 00:00）與 `date`／`calendar` 一律注入。驗證：`apps/ios/CLAUDE.md` 可搜尋到 `evaluatingAutoClose`。
- [x] 4.4 修正 QA 發現的回歸保護缺口：`OrdersFeature.campaignsLoaded` 與 `OrderEditFeature.availableCampaignsLoaded` 呼叫 `evaluatingAutoClose` 的路徑先前無任何測試覆蓋。各補一條測試送出對應 action、斷言結單日等於注入現在時間的開團仍為 `.ongoing`（`apps/ios/BuyLedgerTests/OrdersFeatureTests.swift`、`apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift`）。驗證：以變異測試證實——暫時把兩處呼叫還原為本案要修的原始時間戳比較，兩條新測試皆轉紅；還原程式碼後以 `shasum` 確認與變異前逐位元組相同，兩條測試轉綠。
- [x] 4.5 修正 `Campaign.swift:43` 的 fallback 倒向不安全側：`calendar.date(byAdding:)` 理論上不會回 `nil`，但原寫法 `?? closeDate` 一旦觸發會退化為本案要修的原始 bug（時間戳直接比較）。改為 `guard let boundary = ... else { return self }`，讓 fallback 倒向「維持進行中」的安全側。
- [x] 4.6 修正 `CampaignFeatureTests.swift:272` 的弱斷言：`savingDuplicateNameIsRejectedBeforeAnyWrite` 的 `saveCount.value == 0` 先前在 `store.send` 之後未等任何 effect 就讀取；補上 `await store.finish()` 後再讀。
- [x] 4.7 修正 `tasks.md` 與 `proposal.md` 的過時指路：2.1 補註唯一性紅燈測試實際位置為 `CampaignFeatureTests.swift`（非 `CampaignEditFeatureTests.swift`）；`proposal.md` 的 Affected code 補列 `OrdersFeatureTests.swift`、`OrderEditFeatureTests.swift`（本輪新增測試）、`LocalizationCatalogTests.swift`（既有一行 `已有其他開團使用這個名稱…` key 屬本案）與 `apps/ios/CLAUDE.md`。
- [x] 4.8 判斷題：唯一性檢查依賴 `state.campaigns` 已成功載入（`state.hasLoaded`），若 `.task` 載入失敗則清單為空、重複檢查會真空通過。決定不在本案擴大範圍實作 `guard state.hasLoaded`：design 的「失敗模式」只定義了名稱重複與名稱為空兩種，新增第三種失敗模式需要一併決定使用者可見的呈現方式（沿用 `nameConflictMessage` 或新開錯誤路徑），這是需要另行決定的產品行為而非本案既有範圍的延伸；比照 design 對「既有重名不自動處理」的處理方式，記錄為已知限制，留待後續變更決定。
- [x] 4.9 重新執行整體驗收：主 scheme 單元測試 **423 passed / 0 failed**（改動前基準 421，本輪新增 2 條全綠）；`spectra validate campaign-identity-and-close-date` 通過。本輪僅動註解、文件與測試斷言，行為不變，故未重跑 UI 回歸與兩平台 build。
