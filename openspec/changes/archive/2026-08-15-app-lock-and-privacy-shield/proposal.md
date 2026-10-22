## Why

App 內存放客戶姓名、交易金額與收款憑證照片，但沒有任何應用程式層的保護：沒有二次驗證，離開前景後回到前景也不需要重新證明身份。

手機在解鎖狀態下被短暫借出時，訂單與客戶清單是完全敞開的。稽核把它評為低度風險，因為裝置本身已有鎖定，但仍點名「借給朋友看照片」是值得補強的情境。

目前設定頁的「關於」區塊只有版本與作者，沒有任何安全相關設定，使用者也沒有任何方式表達「這本帳需要保護」。

## What Changes

- 設定頁新增單一開關「帳本保護」。開啟時同時啟用兩項保護：應用程式進入背景即上鎖，回到前景或冷啟動時要求生物辨識驗證才能檢視內容。關閉時行為與現況完全相同。
- 開關的啟用本身需先通過一次驗證。驗證失敗或裝置不支援時，開關不會被開啟，並以對話框說明原因。這避免了「開了保護卻進不去」這種使用者無法自救的狀態。
- 驗證交由系統的本機驗證機制，App 不自建密碼流程、不儲存任何驗證憑據。
- 補上使用生物辨識所需的用途說明宣告。缺少該宣告會在請求驗證時直接終止。

**範圍收斂記錄**：本提案原規劃另包含視窗層的遮蔽層機制 (獨立 `UIWindow`，覆蓋已呈現的浮層與照片檢視器、企圖讓多工切換器快照不含內容)。QA 審查發現該機制的觸發訊號 (`AppDelegate` 的場景生命週期回呼) 在 SwiftUI 場景式 App 中從未被呼叫、完全零生效且無測試偵測到。修正輪確認以 `\.scenePhase` 重新接線後機制本身可行，但使用者評估後決定**收斂掉整個遮蔽層**，只保留「背景即上鎖、前景即驗證」：此舉讓範圍與驗證能力對齊 (鎖定／解鎖邏輯本身已有完整測試覆蓋且通過兩輪變異驗證)，代價是多工切換器快照可能仍含最後畫面的內容 (見下方 Non-Goals 與 Risks)。

## Non-Goals

- 不提供 App 自訂的密碼或 PIN。驗證一律交由系統，包含系統在生物辨識失敗時的裝置密碼後備。
- 不做逐畫面或逐功能的鎖定，保護是整個應用程式層級的。
- 不在關閉開關時保留任何殘留行為。關閉即完全回到現況。
- 不做閒置逾時自動上鎖，也不做背景停留時間的門檻設定。
- 不改動既有的檔案保護等級，那由資料匯出與檔案保護處理。
- 不改動設定頁的其他區塊。
- **不做視窗層的遮蔽機制**：不保證多工切換器的快照不含內容。App 進入背景時把畫面內容換成鎖定畫面，但這只保證「回到前景時需要驗證才能看到內容」，不保證 iOS 系統擷取切換器縮圖的那一刻已經完成這次畫面替換；縮圖仍可能短暫含有背景化前最後一幀的內容。這是使用者收斂範圍時已知並接受的取捨，非疏漏。

## Capabilities

### New Capabilities

- `app-lock`: 應用程式層保護的契約，涵蓋單一開關同時控制上鎖與驗證、啟用前必須先通過驗證、驗證交由系統而不自建流程；不含遮蔽層 (見上方範圍收斂記錄)。

### Modified Capabilities

- `system-setting-deference`: 補上「驗證交由系統的本機驗證機制，不自建密碼流程」這一條。
- `ui-test-launch-harness`: 外部相依的測試替身清單納入本機驗證，並提供啟動旗標選擇驗證結果。

## Impact

- Affected specs: `app-lock`（新增）、`system-setting-deference`（修改）、`ui-test-launch-harness`（修改）
- Affected code:
  - New:
    - apps/ios/BuyLedger/Core/Dependencies/BiometricAuthClient.swift
    - apps/ios/BuyLedger/Features/App/AppLockFeature.swift
    - apps/ios/BuyLedger/Features/App/AppLockView.swift
    - apps/ios/BuyLedger/Features/App/AppScenePhaseCoordinator.swift
    - apps/ios/BuyLedgerTests/AppLockFeatureTests.swift
    - apps/ios/BuyLedgerTests/AppScenePhaseCoordinatorTests.swift
    - apps/ios/BuyLedgerTests/BiometricAuthClientTests.swift
    - apps/ios/BuyLedgerUITests/Tests/Smoke/AppLockTests.swift
    - apps/ios/BuyLedgerUITests/Screens/AppLockScreen.swift
  - Modified:
    - apps/ios/BuyLedger/App/BuyLedgerApp.swift
    - apps/ios/BuyLedger/App/AppDelegate.swift
    - apps/ios/BuyLedger/Features/App/RootFeature.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
    - apps/ios/BuyLedger/Core/Testing/BLUITestConfiguration.swift
    - apps/ios/BuyLedger/Core/Testing/BLUITestDependencyOverrides.swift
    - apps/ios/BuyLedger/Resources/Info.plist
    - apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift
    - apps/ios/BuyLedger/Resources/Localizable.xcstrings
    - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
    - apps/ios/CLAUDE.md
    - apps/ios/README.md
  - Removed: （無）
  - `apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift` 為混合 hunk：`isBiometricUnlockEnabled` 欄位屬本案，
    同檔的 `isTelemetryEnabled` 欄位屬遙測案 (telemetry-transparency)，非本案改動，僅因兩案改動同檔而共同出現於 diff
- 不涉及 SwiftData schema 或資料形狀。
- 次序約束：本變更必須排在無障礙覆蓋之後，使新增的鎖定畫面受該變更建立的掃描守門約束；並與隱私區塊、金鑰區塊分屬不同批次以免同時大改設定頁表單。
