---
paths:
  - "apps/ios/BuyLedgerUITests/**"
  - "apps/ios/BuyLedgerAccessibilityIDs/**"
  - "apps/ios/BuyLedger/App/Testing/**"
  - "apps/ios/BuyLedger/Features/**/*{View,Sheet,Layout,Row,Content,Column,Card,Section,Tile,Tiles}.swift"
  - "apps/ios/BuyLedger/Shared/DesignSystem/Components/**"
---

# iOS UI 自動化測試 (XCUITest)

`BuyLedgerUITests` 共用 `Support/`、Page Object (`Screens/`) 與 `App/Testing/` 的啟動掛鉤；執行方式、測試計畫與雜訊判讀見 `apps/ios/CLAUDE.md` 的「建置與開發指令」。App 端加 identifier 時同樣適用下方「定位與 identifier」。

- **選擇性執行與變異驗證必須確認實際執行數大於 0**：`0 tests executed` 不是通過，不能用成功退出碼判定測試有效。

## 定位與 identifier

- **一律以 `accessibilityIdentifier` 定位，不用顯示文字或 `accessibilityLabel`**：App 支援中英切換，文字定位在英文模式整批失效。
    - 常數集中在 `BuyLedgerAccessibilityIDs/` (同時編入 App 與 UITests)，`BLAccessibilityID` 依區域分檔為 `BLAccessibilityID+<區域>.swift`，兩端引用常數、不寫字面值。
- **identifier 只掛在本身就是無障礙元素的東西上**：按鈕、輸入欄、捲動容器、`accessibilityElement(children: .combine/.contain)` 後的容器。
    - 掛在純 `VStack` 等版面容器會把子元素併吞成單一字串；容器需要 identifier 時先加 `.accessibilityElement(children: .contain)`。
- **合併朗讀的列以 `accessibilityValue` 承載主要數值**，不為了測試把 `.combine` 拆開。
    - 這類元素在 XCUITest 歸為 `staticText`，查詢用 `app.descendants(matching: .any)[id]`，不用 `otherElements`。
    - `LabeledContent` 的內建 value 讀不到，要顯式加 `.accessibilityElement(children: .combine)` + `.accessibilityValue(...)`。
- **掛不上 identifier 的系統元件 (受控例外)**：
    - 導覽列：以畫面根容器 identifier 判定就緒，導覽列用 `app.navigationBars` 定位。
    - 系統 tab bar：`AppNavigator` 依 `RootTab` 宣告順序取按鈕，再等目的地根 identifier。
    - TCA `AlertState`：以 `app.alerts.firstMatch` 判定呈現、`tapAlertButton(label:)` 依按鈕文字點擊 (計畫已鎖語言)；能自掛 identifier 的自訂 `.alert` 才用 `tapAlertButton(identifier:)`。
    - 自訂 `.alert` 內的 `TextField` 帶不出 identifier，以 `app.alerts.firstMatch.textFields.firstMatch` 定位 (參考 `OptionPickerScreen.typeNewOptionName`)；按鈕帶得出 identifier，但會以兩層同 identifier 的 Button 出現，直接查詢要加 `.firstMatch` (`tapAlertButton(identifier:)` 已處理)。
    - `Picker(.segmented)` 的選項：identifier 掛在 `Picker`，以 `segmentedControls.buttons` 依宣告順序 `boundBy` 取。
- **`Menu` 的 identifier 掛在 `Menu` 本身，不是 label 內的 `Label`**：選單項目掛在各 `Button`，測試以 `tapMenuItem` 先展開再點。
- **push 目的地的返回鍵在 iPad 要 scope 到目的地那條導覽列**：`app.navigationBars.buttons.firstMatch` 可能點到側邊欄的鈕而關掉整個 sheet。
- **sheet 疊在有搜尋欄的畫面上時，`app.searchFields.firstMatch` 會取到底層那一個**：iPad 的側邊欄版面讓底層 Orders 搜尋欄排在前面，iPhone 恰好順序相反所以不會中；改用 `app.searchFields.allElementsBoundByIndex.first(where: \.isHittableOnScreen)` 取第一個可互動的，取不到就 `failWithDiagnostics`。同型陷阱也適用於其他在 sheet 內重複出現的系統元件。
    - 系統返回鍵帶語言無關的 identifier `BackButton` (`Common.backButton`)。

## 資料與相依

- **測試前以 `LaunchOptions` 指定 seed profile 與語言**：模擬器首次啟動是空狀態。
    - `BLUITestHarness` 依 `BLUITestConfiguration` 建立測試 container (in-memory 或 persistent)，`DependencyValues+BLUITestOverrides.swift` 注入固定時間、`buyLedgerDatabase` 與外部相依替身；整套 harness 以 `#if DEBUG` 圈住，啟動掛鉤集中在 `AppLaunchConfigurator`。
- **外部相依一律走 test double**：`PhotoService`／`CalendarReminderService`／`ExchangeRateService` 在 UI 測試模式換成不開系統彈窗、不打網路的替身。
- **`DependencyValues+BLUITestOverrides.swift` 以注入的 `BuyLedgerDatabase` 組出 Service，不得在 `prepareDependencies` 的 closure 內讀 `$0.xxxService` 當底座**：`@Dependency` 在 `liveValue` 建立時擷取當下的 `_current`，不是正在準備的 `$0`，會拿到正式 store。
    - 需要包上失敗 closure 的 Service，以 `withDependencies { $0.buyLedgerDatabase = database } operation: { XxxService.liveValue }` 建立，改寫 closure 後再指派給 `$0.xxxService`。
    - `BuyLedgerDatabase` 的 `storeLocation` 如實傳入：in-memory 用 `.inMemory`，persistent 用 `.directory(<store 所在目錄>)`，不一律標成 in-memory。
- **找不到 App 元素一律 `failWithDiagnostics` (附截圖與可及性樹)，不用 `XCTSkip` 掩蓋**：`XCTSkip` 只留給真正的外部環境差異 (如系統文字選單)，並寫明原因。
- **compact 與 regular 版面差異由 `AppNavigator` 吸收** (compact 版面是底部分頁列，含 iPhone 任何方向與 iPad 窄視窗；regular 版面是 iPad 全螢幕的側邊欄)。

## 輸入、捲動與鍵盤

- **表單下半的數字欄在其他文字欄輸入前先填**：別欄鍵盤升起後會蓋住它而聚焦失敗；被捲走時 `swipeDown` 回頂端再輸入。
    - 數字鍵盤完成鍵一律掛 `Common.keyboardDoneButton`；共用收鍵盤 helper 與 `OrderEditScreen.tapNumericKeyboardDone` 只點擊這個 App 元素。
    - 若 XCUITest 回報完成鍵不可互動，改點擊該元素 frame 的中心並等待鍵盤消失；仍未消失就附診斷失敗。共用 helper 不得改按系統收鍵盤鍵、送 return、依平台分支或以 `XCTSkip` 掩蓋；只有專門測試外部限制時才可明確 skip。
- **只差幾點露出底緣的欄位用 `Scrolling.scrollToHittableGently`，不用整頁 `swipeUp`**：整頁 swipe 帶慣性，會把目標衝出螢幕。
    - 此 helper 要求目標已在可及性樹上；離屏未渲染的惰性列走下一條。
- **惰性容器與 Form 的離屏 cell 可能存在但 frame 無效，直接查 `isHittable` 會讓 XCTest 記錄失敗**：透過 `Support/Waiting.swift` 的 `isHittableOnScreen` 先排除不存在、座標非有限值或空 frame 的元素，再查可點性；等待用 `waitUntilHittable`，不能只以 `exists` 判斷已完成排版。
    - 查詢對到多個元素時 (如 identifier 擴散到圖表內的文字) 讀 `frame` 也會記錄失敗，`isHittableOnScreen` 以 `firstMatch` 判斷；新增讀 `frame` 的 helper 比照處理。
    - 目標不可點時由 `Scrolling` helper 捲動後再等，不用 `isHittable` 述詞輪詢，避免 XCTest 先記錄失敗而走不到捲動備援。
    - 水平 `ScrollView` 內的照片縮圖列相同。
- **`Form` 內的 `Toggle` 要點內層 `switches.firstMatch`，不點外層開關元素**：外層元素涵蓋整列，點它的中心會落在標題文字上而不切換 (參考 `CampaignEditScreen.toggleReminder`、`CampaignDetailScreen+Content.toggleUnpaidOnly`)。
    - 切換後以開關的 `value` 或切換造成的畫面變化斷言，否則沒切到也會假通過。
- **`scrollDismissesKeyboard(.interactively)` 無法以 XCUITest 合成手勢觸發，不寫 UI 測試守它 (產品端仍保留)**：`KeyboardDismissTests` 只覆蓋 return 鍵與數字鍵盤完成鍵兩條路徑。

## 轉向測試

- **轉向測試 (`XCUIDevice.shared.orientation`) 執行時，模擬器前端的 Device Hub 不可開著**：開著時裝置方向會改變但介面不轉，App 視窗維持直向，測試在等「視窗寬大於高」時逾時；關閉 Device Hub 後即恢復。
    - Device Hub 的旋轉鈕只轉外框，Orientation 選單也不一定讓介面轉向 (iPad 會轉、iPhone 17 Pro Max 不會)，兩者都不能用來驗證橫向版面。
    - 轉向後等到 `app.windows.firstMatch` 寬大於高才斷言或截圖 (參考 `OrientationLayoutTests`)：setter 只設定裝置方向，沒等就斷言會在直向取得 compact 版面而誤判通過。
- **轉向測試失敗且 App 視窗維持直向時，先重開模擬器再重跑，重開後仍失敗才是真問題**：模擬器長時間連續跑 UI 測試後，`XCUIDevice.shared.orientation` 可能只改變裝置方向、介面不轉，屬環境狀態，不是產品或測試缺陷。
    - 判別：`OrientationLayoutTests` 在「轉向後 App 視窗寬仍未大於高」失敗，且單獨重跑同樣失敗；沒有特定測試類別會穩定觸發，不必逐類排查，也不改測試碼或放寬等待。
    - 重開機：`mobilebuildmcp` 沒有關機指令，先開啟 Device Hub 再結束它 (結束時會把模擬器全部關機)，再以 `mobilebuildmcp simulator-management boot` 開機。
- **橫向時 `XCTAttachment(screenshot:)` 的截圖只擷取到部分畫面**：判讀版面以可見部分為準，不因看不到右側元素就判定版面錯誤；需要完整畫面時另以 `mobilebuildmcp ui-automation screenshot` 取得。
