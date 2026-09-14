---
paths:
  - "apps/ios/BuyLedgerUITests/**"
  - "apps/ios/BuyLedgerAccessibilityIDs/**"
  - "apps/ios/BuyLedger/App/Testing/**"
  - "apps/ios/BuyLedger/Features/**/*{View,Sheet,Layout,Row,Content}.swift"
  - "apps/ios/BuyLedger/Shared/DesignSystem/Components/**"
---

# iOS UI 自動化測試 (XCUITest)

`BuyLedgerUITests` 共用 `Support/`、Page Object (`Screens/`) 與 `App/Testing/` 的啟動掛鉤；執行方式、測試計畫與雜訊判讀見 `apps/ios/CLAUDE.md` 的「建置與開發指令」。App 端加 identifier 時同樣適用下方「定位與 identifier」。

## 定位與 identifier

- **一律以 `accessibilityIdentifier` 定位，不用顯示文字或 `accessibilityLabel`**：App 支援中英切換，文字定位在英文模式整批失效。
    - 常數集中在 `BuyLedgerAccessibilityIDs/BLAccessibilityID.swift` (同時編入 App 與 UITests)，兩端引用常數、不寫字面值。
- **identifier 只掛在本身就是無障礙元素的東西上**：按鈕、輸入欄、捲動容器、`accessibilityElement(children: .combine/.contain)` 後的容器。
    - 掛在純 `VStack` 等版面容器會把子元素併吞成單一字串；容器需要 identifier 時先加 `.accessibilityElement(children: .contain)`。
- **合併朗讀的列以 `accessibilityValue` 承載主要數值**，不為了測試把 `.combine` 拆開。
    - 這類元素在 XCUITest 歸為 `staticText`，查詢用 `app.descendants(matching: .any)[id]`，不用 `otherElements`。
    - `LabeledContent` 的內建 value 讀不到，要顯式加 `.accessibilityElement(children: .combine)` + `.accessibilityValue(...)`。
- **掛不上 identifier 的系統元件 (受控例外)**：
    - 導覽列：以畫面根容器 identifier 判定就緒，導覽列用 `app.navigationBars` 定位。
    - 系統 tab bar：`AppNavigator` 依 `RootTab` 宣告順序取按鈕，再等目的地根 identifier。
    - TCA `AlertState`：以 `app.alerts.firstMatch` 判定呈現、`tapAlertButton(label:)` 依按鈕文字點擊 (計畫已鎖語言)；能自掛 identifier 的自訂 `.alert` 才用 `tapAlertButton(identifier:)`。
    - `Picker(.segmented)` 的選項：identifier 掛在 `Picker`，以 `segmentedControls.buttons` 依宣告順序 `boundBy` 取。
- **`Menu` 的 identifier 掛在 `Menu` 本身，不是 label 內的 `Label`**：選單項目掛在各 `Button`，測試以 `tapMenuItem` 先展開再點。
- **push 目的地的返回鍵在 iPad 要 scope 到目的地那條導覽列**：`app.navigationBars.buttons.firstMatch` 可能點到側邊欄的鈕而關掉整個 sheet。
    - 系統返回鍵帶語言無關的 identifier `BackButton` (`Common.backButton`)。

## 資料與相依

- **測試前以 `LaunchOptions` 指定 seed profile 與語言**：模擬器首次啟動是空狀態。
    - `BLUITestConfiguration` 注入 in-memory container、固定時間與外部相依替身；整套 harness 以 `#if DEBUG` 圈住，啟動掛鉤集中在 `AppLaunchConfigurator`。
- **外部相依一律走 test double**：`PhotoClient`／`CalendarReminderClient`／`ExchangeRateClient` 在 UI 測試模式換成不開系統彈窗、不打網路的替身。
- **找不到 App 元素一律 `failWithDiagnostics` (附截圖與可及性樹)，不用 `XCTSkip` 掩蓋**：`XCTSkip` 只留給真正的外部環境差異 (如系統文字選單)，並寫明原因。
- **compact 與 regular 版面差異由 `AppNavigator` 吸收** (iPhone 底部分頁列、iPad 側邊欄)。

## 輸入、捲動與鍵盤

- **表單下半的數字欄在其他文字欄輸入前先填**：別欄鍵盤升起後會蓋住它而聚焦失敗；被捲走時 `swipeDown` 回頂端再輸入。
    - 數字鍵盤完成鍵一律掛 `Common.keyboardDoneButton`。
- **只差幾點露出底緣的欄位用 `Scrolling.scrollToHittableGently`，不用整頁 `swipeUp`**：整頁 swipe 帶慣性，會把目標衝出螢幕。
    - 此 helper 要求目標已在可及性樹上；離屏未渲染的惰性列走下一條。
- **`LazyVStack`／`LazyVGrid` 離屏未渲染的列 frame 無效，查 `isHittable` 會直接報錯**：先 `swipeUp` 逐次捲動查 `exists`，捲入樹後再查可點。
    - 水平 `ScrollView` 內的照片縮圖列相同。
- **`scrollDismissesKeyboard(.interactively)` 無法以 XCUITest 合成手勢觸發，不寫 UI 測試守它 (產品端仍保留)**：`KeyboardDismissTests` 只覆蓋 return 鍵與數字鍵盤完成鍵兩條路徑。
