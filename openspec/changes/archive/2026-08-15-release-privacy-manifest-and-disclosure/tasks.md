## 1. 隱私資訊清單

- [x] 1.1 讓產物具備送審所需的隱私資訊清單：新增清單並宣告使用者預設值的具名理由，以及所連結遙測 SDK 的資料類型與追蹤網域。`PrivacyInfo.xcprivacy` 位於 file-system synchronized group，且未列入 `PBXFileSystemSynchronizedBuildFileExceptionSet.membershipExceptions`，因此會自動隨資源進入產物；本案不修改建置設定或 `project.pbxproj`。對應 spec requirement「A privacy manifest ships with the application」。驗證：對發行組態產物檢查，清單存在於應用程式套件內且可解析出具名理由條目（apps/ios/BuyLedger/Resources/PrivacyInfo.xcprivacy）。
- [x] 1.2 確認宣告內容與實際連結的 SDK 相符（依 design 決策：保留四個產品，改以補足透明度而非縮減蒐集面）：逐一比對連結的四個產品與清單中宣告的資料類型與追蹤網域。驗證：比對表逐項相符，無多宣告也無漏宣告。

## 2. 讓遙測設定真的生效

- [x] 2.1 改以平台實際承認的機制控制分析收集，且遙測強制啟用、不承載任何使用者選擇：資訊屬性清單的 `FIREBASE_ANALYTICS_COLLECTION_ENABLED` 鍵決定啟動初始狀態，`TelemetryClient.liveValue.enableCollection()` 於每次啟動的初始化後以固定值重申三支 SDK 皆已啟用，藉此覆寫裝置上任何殘留自舊版「可關閉遙測」時期的停用狀態。對應 spec requirement「Telemetry configuration reflects actual behaviour」，依 design「遙測強制開啟，移除使用者可調整入口」。驗證：`TelemetryClient` 兩個方法皆不帶參數、呼叫端無條件呼叫；全樹掃描確認 `isTelemetryEnabled`／`telemetryToggle` 零命中（apps/ios/BuyLedger/Resources/Info.plist、apps/ios/BuyLedger/App/AppLaunchConfigurator.swift、apps/ios/BuyLedger/Core/Dependencies/TelemetryClient.swift）。
- [x] 2.2 移除服務設定檔中在此平台無效的分析旗標，使設定不再暗示一個不存在的效果。驗證：設定檔中不再存在該旗標；平台指引記錄「該旗標在此平台無效、真正的控制在何處」。
- [x] 2.3 讓 Performance 自動埋點開關的套用早於框架初始化：`AppLaunchConfigurator.configure()` 維持 UI 測試 guard 在最前，之後直接呼叫 `TelemetryClient.liveValue.enablePreInitializationCollection()`（不經尚未建立的相依注入容器、不讀取任何偏好），再呼叫 `FirebaseApp.configure()`。依 design「Performance 早於初始化的順序要求不因遙測改為強制開啟而鬆動」。驗證：人工檢視 `AppLaunchConfigurator.configure()` 內呼叫順序；以介面測試執行一次確認 UI 測試 guard 仍在最前、不觸碰 Firebase SDK（apps/ios/BuyLedger/App/AppLaunchConfigurator.swift）。

## 3. 設定頁的隱私區塊

**範圍收斂記錄**：本節原規劃於設定頁新增「隱私」區塊（遙測開關＋說明文字），任務 3.1～3.3 皆已完成並發布。使用者其後裁定：本 App 產物不對外散布、僅安裝於開發者自己的裝置（見 `apps/ios/CLAUDE.md`「安全性與設定注意事項」一節），不涉及第三方使用者的同意權議題；因此遙測改為**強制開啟、不提供使用者設定**，原「隱私」區塊（含開關、header、footer 說明）整段移除，揭露只留在 `PrivacyInfo.xcprivacy`。對應地，spec 的「The user can reach and change the telemetry setting」requirement（連同其 3 個 scenario）已隨此決策自 spec.md 整條移除。

隨此收斂一併移除：`SettingsFeature.State.isTelemetryEnabled`、對應的 `.binding` 分支與 `telemetryClient` 相依注入、`SettingsSnapshot`／`SettingsStorage` 的 `isTelemetryEnabled` 欄位與持久化 key、`BLAccessibilityID.Settings.telemetryToggle`、`Localizable.xcstrings` 內「隱私」「啟用遙測」「遙測預設為開啟…」三個已無使用者的字串條目，以及 `SettingsFeatureTests` 內兩條專屬測試 (`telemetryTogglePersistsAndAppliesToClient`／`telemetryPreferenceSurvivesSettingsStorageRoundTrip`)。

**已移除任務的歷史記錄**：原 3.1「設定頁新增隱私區塊」、3.2「開關狀態跨啟動持久並於啟動時套用」、3.3「補上隱私區塊的輔助技術識別碼」已隨範圍收斂移除，不再適用。

## 4. 外送第三方的揭露

- [x] 4.1 讓外送行為在動作發生處被誠實揭露：AI 總結的呈現處常駐一段說明，逐項寫明送出的欄位為類別、品名、數量、單價與幣別，送往第三方雲端服務，且不含客戶姓名。對應 spec requirement「Sending data off device is disclosed where the action is taken」，依 design「揭露文案與實際送出的欄位綁定」。驗證：逐項比對揭露文字與實際組出的內容格式，確認欄位一致且未誇大（apps/ios/BuyLedger/Features/AISummary/AISummaryView.swift）。
- [x] 4.2 補齊所有新增文案的中英對照並納入本地化目錄的必備清單。驗證：本地化目錄測試綠燈，英文模式下無語言回退（apps/ios/BuyLedger/Resources/Localizable.xcstrings）。

## 5. 文件同步

- [x] 5.1 讓平台指引記錄本次的事實：分析收集在此平台的正確控制位置與服務設定檔旗標的無效性、效能監測開關必須早於初始化且不因強制開啟而鬆動、保留四個產品但目前零自訂埋點的落差作為日後重估依據，以及遙測現況為強制開啟、無使用者可調整入口、`TelemetryClient` 兩方法皆不帶參數的現行機制形狀。驗證：各段落皆可搜尋到對應內容（apps/ios/CLAUDE.md）。
- [x] 5.2 讓平台說明文件反映現況：設定頁不含隱私區塊，遙測為強制開啟且無使用者入口，揭露留在 `PrivacyInfo.xcprivacy`。驗證：說明文件可搜尋到對應段落（apps/ios/README.md）。

## 6. 驗收

- [x] 6.1 執行整體驗收：主 scheme 全套單元測試綠燈（基準扣除本次移除的遙測專屬測項後的預期值）、UI 主回歸綠燈、發行組態建置成功且產物含隱私資訊清單。驗證：測試通過數與預期值對帳；產物檢查結果記錄一次。**本輪實測**：單元測試 689 passed／1 known-red（`orderEditViewMergeContextBaseline`）＝ 690 總數，與基準 691−2（移除的遙測專屬測項）相符；UI automation iPhone 17 Pro Max 53/53、iPad Air 52 passed＋1 條環境雜訊（`CustomersTests/testEmptySeedShowsEmptyState`，單獨重跑轉綠）；iOS／iPadOS 兩平台 simulator build 皆成功（`CURRENT_PROJECT_VERSION` 243）；`PrivacyManifestTests` 通過；snapshot 零重錄（14 張 mtime 不變、`git status` 10 筆）。

## 後續驗證紀錄

- 2.1（原記錄，已由本輪範圍收斂取代）：先前卡在「無法以 UI automation 完成關閉遙測、終止、重啟」的驗證，成因是舊設計仰賴使用者可關閉的開關。本輪使用者裁定遙測強制開啟、不提供使用者設定，該驗證路徑本身已不適用；改以程式碼驗證取代：`TelemetryClient` 兩方法皆不帶參數、呼叫端無條件呼叫，全樹掃描確認無殘留的使用者切換路徑。2.1 依新描述判定完成。
- 6.1（原記錄，已由本輪範圍收斂取代）：先前記錄的 linker 階段失敗與 504 個單元測試未執行完成，與本次改動無直接關聯（環境問題）；本輪驗收數字另行記錄於本次改動的執行結果，不沿用該筆舊數字。
- A-1：查閱 Context7 的 Firebase 官方文件後，再檢視 Firebase iOS SDK 原始碼確認 Performance Monitoring 會以 Firebase Installations ID 識別 App instance，並將其寫入 `application_info.app_instance_id`。因此 `NSPrivacyCollectedDataTypeDeviceID` 同時宣告 Analytics 與 AppFunctionality，用途與 Performance 的實際行為一致。
- E-3：隱私清單既然宣告 Device ID，設定頁面向使用者的揭露也補上「裝置識別碼」，並同步更新 `SettingsView.swift`、`Localizable.xcstrings` 與 `LocalizationCatalogTests.swift`。此揭露文字隨本輪「隱私」區塊整段移除一併移除；裝置識別碼的宣告仍完整保留於 `PrivacyInfo.xcprivacy`，不受影響。
- E-5：`.failed` 分支目前已保留 `.frame(maxWidth: .infinity, maxHeight: .infinity)`。曾以 XcodeBuildMCP 建置並啟動 App，但 UI automation daemon 無法取得 accessibility hierarchy，且 Computer Use 未獲 Simulator 權限；因此尚未聲稱完成失敗態的實際目視確認。
- F-1（本輪新增）：查證 Firebase iOS SDK 原始碼（`SourcePackages/checkouts/firebase-ios-sdk`）內各產品自帶的 `PrivacyInfo.xcprivacy`，確認 `FirebaseCore` 不宣告任何資料類型（僅 UserDefaults 具名理由）、`FirebaseCrashlytics`（Crashlytics 模組）宣告 `CrashData`／`OtherDiagnosticData`（皆 AppFunctionality）且與專案清單逐項相符；`FirebaseAnalytics`／`GoogleAppMeasurement`（二進位 xcframework）與 `FirebasePerformance` 皆未內附自身的隱私清單，代表其資料類型需由 App 自行宣告，專案既有的 `DeviceID`（Analytics＋AppFunctionality）與 `ProductInteraction`（Analytics）、`PerformanceData`（AppFunctionality）已涵蓋兩者實際行為。專案未使用 IDFA／跨 App 廣告追蹤，`NSPrivacyTracking = false` 與空的 `NSPrivacyTrackingDomains` 符合實際行為。本輪遙測強制開啟不改變任何 SDK 可能收集的資料類型集合（原本預設即開啟），故 `PrivacyInfo.xcprivacy` 本次無需改動。
