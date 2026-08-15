## 1. 主卡對比達標

- [x] 1.1 讓主卡底色改用設計系統中既有、已壓暗且受對比測試保護的主卡漸層資源，取代畫面內直接以兩個系統色組成的漸層。驗證：該畫面不再直接引用系統色組漸層；以對比計算確認白字對新底色兩端在淺色與深色外觀下皆達 4.5 比 1 的地板（apps/ios/BuyLedger/Features/Quote/QuoteView.swift）。
- [x] 1.2 移除主卡文字上會進一步降低對比的不透明度調整，層級改由字重與字級表達。驗證：該畫面的主卡區段搜尋不透明度調整零命中；視覺上仍能分辨主要金額與次要說明的層級（人工確認）。
- [x] 1.3 確認修正後能被擴大範圍的對比守門驗證通過：本變更排在測試有效性修復之後，該守門已把畫面內組成的配色納入受測對象。驗證：對比測試綠燈，且該頁的主卡出現在受測對象中。修正輪落地：新增單一語意入口 `BLPalette.heroGradient`，`QuoteView`／`DashboardView`／`ContrastComplianceTests` 三處皆取用同一入口；原先與 QuoteView 無綁定的重複測試已刪除，改由 `ContrastComplianceTests.heroCardWhiteTextMeetsTheFloorOnBothGradientEnds` 斷言該入口、並由既有 `SnapshotTests.quoteViewBaseline` 提供對畫面實際輸出的綁定（反向驗證：QuoteView 改回 `[palette.green, palette.teal]` 後 `quoteViewBaseline` 轉紅）。
    - **QA 修正輪 (結構性根治)**：`BLPalette.heroGradient` 這個共用值本身不阻止畫面繞過它現組漸層——守門實質仍只靠 `quoteViewBaseline` 這一條 snapshot 拉住。改把底色抽成 `Shared/DesignSystem/Foundations/ViewModifiers/BLHeroCardBackground.swift` 的 `ViewModifier`，`QuoteView`／`DashboardView` 改呼叫 `.blHeroCardBackground()`，不再各自於畫面內組 `LinearGradient`；`ContrastComplianceTests` 的兩條斷言 (`heroCardWhiteTextMeetsTheFloorOnBothGradientEnds`、`everyNamedColorResourceActuallyResolves`) 改綁 `BLHeroCardBackground.gradientColors`。反向驗證：令 `QuoteView` 繞過 modifier、改回行內 `LinearGradient(colors: [palette.green, palette.teal], ...)` 後，`SnapshotTests.quoteViewBaseline` 轉紅 (`Snapshot does not match reference`)；還原呼叫 `.blHeroCardBackground()` 後轉綠。規則已同步寫入 `apps/ios/CLAUDE.md`。

## 2. 匯率不可用時的呈現

- [x] 2.1 讓匯率不可用時說得出原因並提供畫面內的重試途徑，取代目前只有破折號的呈現。對應 spec requirement「Failed loads offer a retry path within the screen」新增的依賴型畫面情境。驗證：新增測試斷言匯率不可用時狀態持有可呈現的原因與重試動作，且重試成功後恢復正常內容（apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift、apps/ios/BuyLedgerTests/QuoteFeatureTests.swift）。
- [x] 2.2 補上重試控制項的輔助技術識別碼，使其可被介面測試定位。驗證：識別碼常數新增於共用目錄且畫面端引用常數而非字面值（apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift）。
    - **QA 修正輪**：識別碼常數雖已存在，`BuyLedgerUITests/Screens/QuoteScreen.swift` 原先完全未暴露 `statusBanner`／`retryButton`，介面測試端零命中，「可被介面測試定位」的字面驗證條件雖成立但目的未兌現。已補上 `QuoteScreen.statusBannerExists` 與 `QuoteScreen.tapRetry()`。**未補上失敗情境的 UI 測試**：查 `BLUITestDependencyOverrides.applyNetworkOverrides` 後確認 `ExchangeRateClient` 無視 `-BLUITestLoadFailure` 一律安裝成功的替身 (`BLUITestLoadFailure` 只有 `.orders`／`.ordersFirstReadOnly`／`.campaigns`／`.lookups`，皆不影響匯率查詢)；`fromCurrency` 預設 `.krw`，可選幣別集合 (`CurrencyCode.defaults` ∪ 幣別主檔) 又與匯率替身的固定匯率表同源，無任何現有啟動旗標組合能讓報價頁落入「無可用匯率」狀態。此為現有機制的缺口，不屬本變更範圍，未新增 `BLUITestLoadFailure` case 勉強湊出測試；`QuoteScreen` 的新暴露方法保留供日後補上該機制時使用。

## 3. 設計系統採用

- [x] 3.1 讓該頁改用設計系統的語意色，不再自行組色。驗證：該畫面搜尋直接的系統色引用零命中，色彩一律取自設計系統的語意入口。
- [x] 3.2 讓該頁改用共用的金額格式化，不再自行格式化。驗證：該畫面不再持有私有的金額格式化方法；格式化結果與訂單畫面對同一數值一致（apps/ios/BuyLedger/Features/Quote/QuoteView.swift）。

## 4. 文案與驗收

- [x] 4.1 補齊新增文案的中英對照並納入本地化目錄的必備清單。驗證：本地化目錄測試綠燈，英文模式下無語言回退（apps/ios/BuyLedger/Resources/Localizable.xcstrings）。本案對此任務為 no-op：畫面用到的「重試」與「尚無可用匯率資料，暫時無法試算。」在 HEAD 即已存在且已有 `en` 對照（分別供 FxView/AISummary、舊版 QuoteView 使用），本案未新增任何字面值；驗證條件（目錄測試綠燈、英文模式無回退）本就成立，不代表本案新增了本地化工作。
- [x] 4.2 重錄報價頁的視覺快照並目視確認：底色、文字層級與新增的說明區塊皆為預期變化。驗證：重錄前先鎖模擬器淺色外觀；差異逐一目視確認。`SnapshotTests.quoteViewBaseline` 已於模擬器淺色外觀下錄製並目視確認（`BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewBaseline.1.png`）。
    - **QA 修正輪**：`quoteViewBaseline` 的 state 帶 `FxRateSnapshot.fallback` (成功態)，深色外觀與失敗態橫幅 (含重試鈕) 完全無畫面級快照守護。新增 `SnapshotTests.quoteViewRateUnavailable`（`errorMessage` 帶明確失敗原因、無 `snapshot`），已於模擬器淺色外觀下錄製並目視確認橫幅、原因文字、重試鈕與拆解卡空狀態皆在圖上（`BuyLedgerTests/__Snapshots__/SnapshotTests/quoteViewRateUnavailable.1.png`）。深色外觀的 hero 卡漸層本身仍只由 `ContrastComplianceTests` 的數值斷言把關，未新增深色快照。
- [x] 4.3 執行整體驗收：主 scheme 全套單元測試綠燈、UI 主回歸綠燈。驗證：測試通過數不低於改動前。主 scheme 509 passed／0 failed／0 skipped（`.off` 維持 9、`default: return .none` 維持 0）。通過數較審查前的 510 少 1，差額即 F1 刪除的重複測試 `quoteHeroWhiteTextMeetsTheFloorOnTheSharedHeroGradient`（該測試不引用 QuoteView 任何符號，移除不損失真實覆蓋率；反向驗證見 1.3）。UI 主回歸沿用協調者本輪已跑過的結果，本輪未重跑。
    - **QA 修正輪**：新增 `SnapshotTests.quoteViewRateUnavailable` 後，主 scheme 510 passed／0 failed／0 skipped（`.off` 仍 9、`default: return .none` 仍 0，三方交叉核對一致）。UI 主回歸重跑（`-only-testing:BuyLedgerUITests` + `-skip-testing:BuyLedgerUITests/LaunchPerformanceTests`，iPhone 17 模擬器）：51 passed／0 failed／0 skipped (⏱️ 1452s)——已知 flaky 的 `OrderCreateTests.testCreateOrderAppearsInList` 本輪剛好通過，未改動任何 UI 測試基礎設施。iPhone 與 iPad 模擬器 build 皆綠燈。
