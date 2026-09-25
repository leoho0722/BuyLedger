---
paths:
  - "apps/ios/BuyLedger/App/AppLaunchConfigurator.swift"
  - "apps/ios/BuyLedger/Core/Dependencies/TelemetryClient.swift"
  - "apps/ios/BuyLedger/Resources/**"
  - "apps/ios/BuyLedger.xcodeproj/project.pbxproj"
  - "apps/ios/BuyLedgerTests/PrivacyManifestTests.swift"
  - ".github/workflows/**"
---

# iOS Firebase、隱私清單與簽署設定

- **Firebase 只作崩潰與使用分析的遙測底座**：target 只連結 `FirebaseCore`／`FirebaseCrashlytics`／`FirebaseAnalytics`／`FirebasePerformance`，沒有登入、Firestore、Auth、Storage、Messaging；App 純本機 (資料唯一來源為 SwiftData，CloudKit `.disabled`)。
    - `GoogleService-Info.plist` 放在 `BuyLedger/Resources/` (gitignored)。
    - 四個產品目前沒有自訂埋點，只有 SDK 預設收集；保留連結面是刻意決策，日後據此重新評估是否縮減。
- **改動 Firebase 產品組合時同步更新 `PrivacyInfo.xcprivacy`**：`NSPrivacyCollectedDataTypes` 與 `NSPrivacyTrackingDomains` 要與實際連結的產品逐項相符，不多不漏 (`PrivacyManifestTests` 守門)。
- **`PrivacyInfo.xcprivacy` 不可加進 `PBXFileSystemSynchronizedBuildFileExceptionSet.membershipExceptions`**：它靠不在排除清單內才被收進 bundle；同目錄其他檔案都在清單內，「為了一致」加進去不會報錯，直到送審才被 Apple 擋下。
- **遙測強制開啟，設定頁不提供任何遙測 UI**：產物不對外散布，揭露只放在 `PrivacyInfo.xcprivacy`。
    - 分析收集初始值在 App `Info.plist` 的 `FIREBASE_ANALYTICS_COLLECTION_ENABLED`。
    - `GoogleService-Info.plist` 的 `IS_ANALYTICS_ENABLED` 在 iOS 無效，重新下載設定檔帶回時要移除，避免暗示它能關閉 Analytics。
- **`TelemetryClient` 的兩個方法不帶參數**：`enablePreInitializationCollection()`／`enableCollection()` 呼叫即啟用。
    - `enableCollection()` 每次啟動初始化後都呼叫：Analytics／Crashlytics 的執行期開關會持久化，要覆寫裝置上殘留的停用狀態。
- **Performance 自動埋點的初始狀態必須在 `FirebaseApp.configure()` 之前設定**：`AppLaunchConfigurator.configure()` 依序為 UI 測試 guard、`TelemetryClient.liveValue.enablePreInitializationCollection()`、`FirebaseApp.configure()`、`TelemetryClient.liveValue.enableCollection()`。
    - 初始化前相依注入容器尚未建立，所以直接呼叫 `TelemetryClient.liveValue`，不改成 `@Dependency`。
    - 值是常數也不能把第一步移到初始化之後。
    - `Performance.sharedInstance()` 只在 `TelemetryClient` 內呼叫，`AppLaunchConfigurator` 不直接呼叫 Performance API。
- **`OTHER_LDFLAGS = "-ObjC"` (Firebase 所需) 與「Run Script: Crashlytics Symbol Upload」build phase 不可移除**：移除 Crashlytics 產品時要一併刪掉該 build phase，否則腳本路徑消失、build 失敗。
- **`GoogleService-Info.example.plist` 只給 CI 用**：CI 建置前複製成正式檔名；乾淨 clone 缺少設定檔時，以 App 為宿主的單元測試會在 `FirebaseApp.configure()` 崩潰。
    - 本機開發用真實的 `GoogleService-Info.plist`，不拿範本覆蓋。
    - 範本值一律是明顯的假字串，且列在 membership 排除清單內、不進 bundle。
- **目前沒有 entitlements 檔**：加 App Groups／CloudKit／Push 時新增 `BuyLedger/Resources/BuyLedger.entitlements` 並在 pbxproj 設 `CODE_SIGN_ENTITLEMENTS`，否則 runtime 讀不到設定的 entitlements。
    - CloudKit container、`aps-environment` 等 key 等 Apple Developer 帳號 provision 之後才加 (未 provision 會讓 codesign 失敗)。
    - CloudKit container、iCloud capability 與 entitlements 的變更要在 PR 中明確說明。
