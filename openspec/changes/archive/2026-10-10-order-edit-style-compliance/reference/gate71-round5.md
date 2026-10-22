# 7.1 第五輪紀錄 (2026-10-10)

第四輪修正改到的 13 檔分 2 組唯讀重審 (準則為第四輪準則加上 `gate71-round4.md` 的判定)，各組完整報告在 session scratchpad `gate71/n01.txt`、`n02.txt`；`style_checks.py` 13 檔只有 1 筆不計失敗的 `WSTR`。

## 主對話判定：要修 (已修)

- **`@ScaledMetric` 同組依名稱字母序**：`DashboardView` 改為 `heroPlaceholderHeight`、`kpiPlaceholderHeight`、`listPlaceholderHeight`、`onboardingCircleSize`、`onboardingIconSize`；`InsightsView` 改為 `rangePlaceholderHeight`、`rankingPlaceholderHeight`、`trendPlaceholderHeight`。
- **註解識別字加反引號**：`DashboardView` 的 `NavigationStack`、`refresh`、`loadState`、`Group`；同句的去重位置改為實際的 `OrdersLoadFeature`。
- **測試摘要與內容一致**：`OrdersFeatureTests+FailureTiming` 第一條測試的摘要改為只描述暫存通知 (顯示時機由同檔其他測試涵蓋)。
- **刪除重複測試**：`CampaignFeatureTests+Presentation` 的 `presentation_開啟中到達後選繼續編輯再捨棄_關閉後才輪到暫存通知` 在 Given 改為直設後，Given、When、Then 與同檔 `presentation_確認捨棄變更_進入關閉中且暫存通知不提前呈現` 相同 (直設無法表達「先選繼續編輯」的經過)；「選繼續編輯時表單維持開啟、通知保留」由同檔 `選繼續編輯_表單維持開啟且暫存通知保留` 涵蓋。

## 不算違規

- `typealias` 放 Nested Types 區 (`CampaignView.AlertBinding`)：型別別名屬巢狀型別宣告。
- State 屬性 doc 說明投影與監看來源 (`RootFeature`)：屬說明用途，不是沿革。
- `#Preview` 巨集不加 `///`：不是宣告，全庫一致。
- Private Views 區內順序：「呼叫者在前」只規定 Internal Method 與 Private Method 區。
- 「依語言偏好注入的 locale」與 `- locale:` 說明中的 locale 指語系概念，加不加反引號都可 (全庫 25 處未加、Orders 5 處有加)，不逐一統一。
- 「tag 顯示文字」「關閉回呼」等用詞：專案文件通用的說法。
- 以 `…Queue()` 表示清空後的佇列：型別初始值即字面等價的預期值。

## 驗證

- 修正後 4 檔 `style_checks.py` `TOTAL {}`。
- `OrdersFeatureTests`、`CampaignFeatureTests`、`SnapshotTests`、`DashboardFeatureTests`、`InsightsFeatureTests` total 178、passed 174，4 條失敗皆為登記的 `longformwrap` 編輯表單 snapshot，`check_snapshot_alternates.py` 判定與替代圖逐像素相同 (bundle `test_sim_2026-10-09T17-12-05-029Z_pid7452_3c52b956.xcresult`)。

## 第六輪 (2026-10-10)

第五輪修正改到的 4 檔 (`DashboardView`、`InsightsView`、`OrdersFeatureTests+FailureTiming`、`CampaignFeatureTests+Presentation`) 由 1 組唯讀重審 (報告 scratchpad `gate71/o01.txt`)，`style_checks.py` `TOTAL {}`。

- 要修 (已依建議修正，主對話以 `style_checks.py` 確認)：`InsightsView.shouldUseWideLayout` 的 doc 為 `regular` 加反引號；`DashboardView.content` 刪除只複述 switch 結構的註解。兩處都是 HEAD 既有的註解。
- 不算違規：`currentDateSubtitle` 以現在時間組字與 `trend(from:)` 的 `Bool?` 屬第 7 步 (首頁與分析頁的現在時間與畫面計算)；`.multilineTextAlignment` 的位置依第二輪 modifier 歸組判定。
- 收斂：第六輪只剩兩處低嚴重度的既有註解，修正方式與審查建議逐字相同，不再續輪。

## 第七輪 (2026-10-10，7.3 回歸後)

7.3 的 iPhone 17 與 iPad 主回歸發現 `OrientationLayoutTests` 的成本圖捲動失敗：本 change 把 `Scrolling` helper 的 `isHittable` 換成 `isHittableOnScreen`，後者讀 `frame`，而成本圖的 identifier 擴散到圖內兩段文字 (查詢對到 3 個元素)，讀 `frame` 時記錄「Multiple matching elements」。`isHittableOnScreen` 改以 `firstMatch` 判斷並同步 `.claude/rules/ios-ui-tests.md`。修改後的 `Waiting.swift` 由 1 組唯讀重審 (報告 scratchpad `gate71/p01.txt`)，`style_checks.py` `TOTAL {}`。

- 不算違規：`wait(for:timeout:)` 的摘要「以述詞輪詢自身到成立或逾時」是動詞片語，「述詞輪詢」與 `ios-ui-tests.md` 原文用語一致 (HEAD 既有文字)；「附診斷失敗」是 UI 測試規則的既定用語；模組名 `XCTest` 加不加反引號同第三輪 `SwiftUI` 判定。
- 結論：0 違規。

## 第八、九輪 (2026-10-10，task 8.4)

verify／review 後補修 (8.1 至 8.3) 改到與新增的 17 檔分 2 組唯讀審查 (報告 scratchpad `gate71/q01.txt`、`q02.txt`)，修正後 5 檔再由 1 組重審 (`r01.txt`)。

- 第八輪要修 (已修)：`BLFormatters` 空本體 enum 改多行；`OrdersDetailNavigationFeature.State` 的 `orders` 與 `popUnavailable(orders:)` 改 `private` (8.1 後只剩本檔與測試使用)，三條 `popUnavailable_` 測試改經 `applyLoadedOrders(selectedOrderID:)` 驗證並刪除與其重複的新測試；`DateSectionFormattingTests` 一條 When 呼叫兩次的測試拆成兩條；`OrdersFeatureTests+Detail` 一則語意含糊的摘要。
- 第九輪要修 (已修)：`BLFormatters` 兩個 `twd` 改呼叫者在前、兩段未達 100 字元卻斷行的格式化鏈接成一行；`OrdersDetailNavigationFeature.State` 的 `syncRegularDetail` 移到呼叫它的 `applyLoadedOrders` 之後。修正為純搬移與接行 (差異前後行內容相同)，以 `style_checks.py` 與測試確認後收斂，不再續輪。
- 不算違規：kit TCA 範本原文「依收到的 Action 更新 State，並回傳要執行的 Effect」「接下來要執行的 Effect」不加反引號；`View` 為概念詞；alert 動作 case 名；`idOfA`／`idsBefore` 讀回識別值作前方元素比對基準；預期中的 `SharedReader($0.$orders)`；預期 closure 以 `removeLast`／`removeAll` 描述 TestStore 狀態變化；讀回替身紀錄當預期；`daySectionTitle` 內賦值的格式化鏈。
- 文件同步：`ios-unit-tests.md` 補「有測試閘門的效果鏈，共享斷言寫在閘門釋放後承接回應的 `receive`」；`apps/ios/CLAUDE.md` 補「驗證注入時區或曆法的測試，注入值與執行環境不同，不套用固定 GMT+0 與西曆」。
