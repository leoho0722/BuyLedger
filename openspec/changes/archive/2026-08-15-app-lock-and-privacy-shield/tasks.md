## 1. 前置與相依

- [x] 1.1 補上使用生物辨識所需的用途說明宣告，避免請求驗證時應用程式直接終止。驗證：資訊屬性清單含該宣告；缺少時的終止情形不再可能發生（apps/ios/BuyLedger/Resources/Info.plist）。
- [x] 1.2 新增可注入的本機驗證相依，提供「是否可用」與「請求驗證」兩項能力，不儲存任何驗證憑據。對應 spec requirement「Authentication is delegated to the system」與「System-level settings are not duplicated in the app」新增的機制沿用要求，依 design「驗證完全交由系統，不自建任何流程」。驗證：新增測試以替身覆蓋可用、成功、失敗、取消四種結果；全專案搜尋確認無自建密碼流程與儲存的驗證憑據（apps/ios/BuyLedger/Core/Dependencies/BiometricAuthClient.swift）。

## 2. 設定開關

- [x] 2.1 先寫紅燈測試釘住「啟用必先通過驗證」：斷言驗證成功才寫入設定；失敗、取消與裝置不支援三種情況下設定維持關閉且持有可呈現的說明。對應 spec requirement「Enabling protection requires passing authentication first」。驗證：四條斷言在實作前皆失敗（apps/ios/BuyLedgerTests/AppLockFeatureTests.swift）。
- [x] 2.2 設定頁新增單一「帳本保護」開關，啟用路徑先請求驗證、成功才寫入偏好，失敗或不支援則回到關閉並以對話框說明原因。對應 spec requirement「One setting controls both locking and authentication」，依 design「單一開關同時控制上鎖與驗證」與「啟用前先驗證，失敗則不啟用」。驗證：2.1 四條斷言轉綠；只新增自己的區塊、不重排既有列（apps/ios/BuyLedger/Features/Settings/SettingsView.swift、apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift、apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift）。
- [x] 2.3 補上開關與其對話框的輔助技術識別碼。驗證：識別碼常數新增於共用目錄且畫面端引用常數而非字面值（apps/ios/BuyLedgerAccessibilityIDs/BLAccessibilityID.swift）。

## 3. 背景上鎖接線

**範圍收斂記錄 (2026-08-01)**：本節原規劃視窗層遮蔽機制 (獨立 `UIWindow`，任務 3.1／3.2)。QA 審查發現該機制的觸發訊號 (`AppDelegate.applicationWillResignActive`／`applicationDidBecomeActive`) 在 SwiftUI 場景式 App 中從未被呼叫，機制完全零生效且全庫零測試觸及，屬不實完成宣告 (詳見下方已移除任務的歷史記錄)。修正輪確認以 `\.scenePhase` 重新接線後機制本身技術上可行，但使用者評估後決定收斂掉整個遮蔽層，只保留「進入背景即上鎖」；`PrivacyShieldWindowController.swift`／`PrivacyShieldClient.swift` 已刪除，本節任務改為場景階段轉送鎖定／解鎖動作的接線與其測試覆蓋。

- [x] 3.1 讓 `AppLockFeature` 的鎖定／解鎖動作依 `\.scenePhase` 轉送，且這段接線本身有單元測試覆蓋 (先前的根本問題：reducer 邏輯雖有完整測試，但「scenePhase 轉換是否真的送出對應 action」這段接線全庫零測試觸及)。對應 spec requirement「One setting controls both locking and authentication」，依 design「單一開關同時控制上鎖與驗證」。做法：抽出獨立、可直接呼叫的 `AppScenePhaseCoordinator.handle(newPhase:send:)`，`Scene.body` 本身無法在單元測試中觸發，抽出後才能以替身斷言「哪個場景轉換觸發了哪個 action」。訊號選擇：`.background` 上鎖、`.active` 解鎖 (與收斂前既有設計一致，非本輪變更)，理由是 `AppLockFeature` 的鎖定／解鎖語意即以「背景化」「回到前景」為觸發點，且維持既有已驗證的 UX (來電、下拉通知中心等短暫 `.inactive` 不誤觸發鎖定畫面)；不用 `AppDelegate` 的場景生命週期回呼，理由同上。驗證：`AppScenePhaseCoordinatorTests` 覆蓋 `.background`／`.active`／`.inactive` 三種轉換；變異驗證：拔掉 `.background`／`.active` 分支的 `send(...)` 呼叫，確認測試轉紅後已還原（apps/ios/BuyLedger/Features/App/AppScenePhaseCoordinator.swift、apps/ios/BuyLedger/App/BuyLedgerApp.swift、apps/ios/BuyLedgerTests/AppScenePhaseCoordinatorTests.swift）。
- [x] 3.2 讓上鎖僅在保護開啟時生效，保護關閉時場景轉換不產生任何鎖定行為。驗證：`AppLockFeature` reducer 本身已對 `appDidResignActive`／`appDidBecomeActive` 在保護關閉時短路為 no-op (見 `AppLockFeatureTests.resigningActiveDoesNothingWhenProtectionIsDisabled` 等)；`AppScenePhaseCoordinator` 不重複這層判斷，接線與閘門分屬兩層各自測試（apps/ios/BuyLedger/Features/App/AppLockFeature.swift）。

**已移除任務的歷史記錄**：原 3.1「讓遮蔽層在視窗層呈現，使其覆蓋已呈現的浮層與照片檢視器」與 3.2「讓遮蔽依場景階段呈現與移除」已隨範圍收斂移除。QA 曾指出初版驗證敘述宣稱「實機確認多工切換器顯示遮蔽層」不實，修正輪已用 `\.scenePhase` 重新接線並附變異驗證證實機制本身可行 (截圖佐證一般畫面、呈現中的 sheet、開啟中的照片檢視器三種情況皆被完整覆蓋)；隨後使用者決定收斂掉此機制，故上述佐證與程式碼皆不再保留於本案範圍內。

## 4. 鎖定與解鎖

- [x] 4.1 讓保護開啟時，冷啟動與回到前景皆需通過驗證才顯示內容；驗證失敗或取消時內容維持鎖定並提供再次驗證的途徑，不提供跳過。對應 spec requirement「One setting controls both locking and authentication」的驗證情境。驗證：新增測試覆蓋冷啟動鎖定、解鎖成功、解鎖失敗後可再試三條路徑（apps/ios/BuyLedger/Features/App/AppLockFeature.swift、apps/ios/BuyLedger/Features/App/RootFeature.swift）。
- [x] 4.2 確認保護關閉時完全回到現況：不上鎖、不驗證、啟動流程不變。驗證：新增測試斷言關閉狀態下無任何鎖定行為。

## 5. 測試替身

- [x] 5.1 讓介面測試不觸發系統生物辨識提示，且驗證結果可由啟動旗標選擇。對應 spec requirement「External dependency doubles in UI test mode」。驗證：介面測試執行時不出現系統提示；成功與失敗兩條路徑各可被選定（apps/ios/BuyLedger/Core/Testing/BLUITestDependencyOverrides.swift）。
- [x] 5.2 讓「保護已開啟」的啟動狀態可由旗標直接設定，使鎖定相關測試不必先走一遍設定頁。依 design「測試替身涵蓋驗證，並讓鎖定狀態可直接抵達」。驗證：新增介面測試以該旗標啟動後直接進入鎖定狀態（apps/ios/BuyLedger/Core/Testing/BLUITestConfiguration.swift、apps/ios/BuyLedgerUITests/Tests/Smoke/AppLockTests.swift）。

## 6. 文案與驗收

- [x] 6.1 補齊新增文案的中英對照並納入本地化目錄的必備清單。驗證：本地化目錄測試綠燈，英文模式下無語言回退（apps/ios/BuyLedger/Resources/Localizable.xcstrings）。
- [x] 6.2 讓文件記錄本次的兩條硬規則：進入背景即上鎖的觸發訊號是 `\.scenePhase`、不是 `AppDelegate` 的場景生命週期回呼 (兩者在 SwiftUI 場景式 App 中從不被呼叫且 iOS 26 已 deprecated，此為本專案實際踩過的案例)，以及啟用保護前必先驗證的理由。驗證：兩段各可搜尋到對應內容（apps/ios/CLAUDE.md、apps/ios/README.md）。**QA 修正記錄 (2026-08-01)**：原文另包含「遮蔽必須掛視窗層而非根層」一條，已隨範圍收斂移除；`AppDelegate` 生命週期回呼不觸發那條是本次踩雷的核心依據，保留。
- [x] 6.3 執行整體驗收：主 scheme 全套單元測試綠燈、UI 主回歸在 iPhone 與 iPad 各一次綠燈、且新增的鎖定畫面通過無障礙掃描守門。**QA 修正記錄 (2026-08-01)**：初版「實機確認一次多工切換器快照不含內容」的敘述依 QA 實測必定失敗：遮蔽層當時零生效，不可能通過此驗證，屬不實完成宣告；修正輪隨後隨範圍收斂移除整個遮蔽層機制，此驗證項目本身已不適用 (見第 3 節範圍收斂記錄)。**收斂後實際驗到的數字**：單元測試 559 passed／1 failed (`orderEditViewMergeContextBaseline`，已知環境紅燈、非本次改動所致，逐一重跑重現一致)，較改動前的 555/1 基準上升；UI 主回歸 iPhone 54/54 全綠 (含 `AppLockTests` 3 條)、iPad 53/54 (唯一失敗 `testCreateOrderAppearsInList` 為既有已知 flaky，與本次改動無關)。背景上鎖接線本身經 `AppScenePhaseCoordinatorTests` 變異驗證 (見 3.1)。**多工切換器卡片本身的像素仍未驗到**：`xcodebuildmcp ui-automation gesture` 在此環境未能可靠觸發系統切換器供螢幕截圖；改以 `biometricOutcome=failure` 直接截圖確認 `isLocked=true` 時 `AppLockView` 完全不含先前內容，並結合 `AppScenePhaseCoordinatorTests` 的變異驗證與既有 `AppLockFeatureTests` 證明 `appDidResignActive` 確實把 `isLocked` 設為 `true`，三者鏈接可高度確信背景化後畫面內容已替換為鎖定畫面；但 OS 擷取多工快照的確切時間點相對於此狀態轉換完成的先後順序仍無法由現有工具直接觀測，如實記錄為已知殘餘缺口 (亦記入 design.md 的 Risks)，非重新宣稱已驗證。

## 7. 解鎖文案依生物辨識類型顯示

**追加記錄 (2026-08-02)**：初版解鎖畫面的按鈕文案為泛用「重新驗證」，未區分裝置支援的生物辨識種類。本節任務為就地補上機型感知文案，對應 spec requirement「The unlock prompt names the device's biometric method」。

- [x] 7.1 為 `BiometricAuthClient` 新增生物辨識類型查詢介面，回傳 Face ID／Touch ID／無三態；`LAContext.biometryType` 的查詢與 `canEvaluatePolicy` 求值順序、`.opticID` 等四值窮舉映射皆在 `liveValue` 內完成，不留 `default` 分支。驗證：新增測試涵蓋四種 `LABiometryType` 值的映射（apps/ios/BuyLedger/Core/Dependencies/BiometricAuthClient.swift、apps/ios/BuyLedgerTests/BiometricAuthClientTests.swift）。
- [x] 7.2 `AppLockFeature` 於回到前景 (`appDidBecomeActive`，涵蓋冷啟動與一般返回前景) 查詢生物辨識類型並存入 state，衍生解鎖按鈕文案；裝置無可用生物辨識硬體時 (可能經由裝置密碼即已通過啟用門檻) 退回中性文案「解鎖」，不顯示空字串或殘缺句子。驗證：TestStore 以替身分別注入 Face ID／Touch ID／無三種類型並斷言衍生文案，不使用 `exhaustivity = .off`（apps/ios/BuyLedger/Features/App/AppLockFeature.swift、apps/ios/BuyLedgerTests/AppLockFeatureTests.swift）。
- [x] 7.3 鎖定畫面按鈕改用衍生文案取代泛用「重新驗證」；輔助技術識別碼不變。驗證：畫面程式碼改用 `store.unlockButtonTitleKey`，既有識別碼與無障礙掃描不受影響（apps/ios/BuyLedger/Features/App/AppLockView.swift）。
- [x] 7.4 補齊新增文案「使用 Face ID 解鎖」／「使用 Touch ID 解鎖」／「解鎖」的中英對照，移除已無使用的「重新驗證」條目。驗證：本地化目錄測試綠燈，英文模式下無語言回退（apps/ios/BuyLedger/Resources/Localizable.xcstrings）。

**追加記錄 (2026-08-02 補做)**：7.3 僅改了鎖定畫面，設定頁「帳本保護」開關與 footer 說明維持泛用措辭，使用者指出此為範圍缺口。當時給出的不改理由「需要額外把 `BiometricAuthClient` 依賴拉進 `SettingsView`」不成立——`store.appLock.biometryType` 本已是 `SettingsView` 既有可讀欄位。真正需要修正的是查詢閘門：`biometryType` 原本只在保護已開啟且鎖定時才查詢，保護關閉 (預設狀態) 下永遠停留在建構時的預設值 `.unavailable`，設定頁在使用者開啟保護「之前」因此永遠只能看到中性退路文案。對應 spec requirement「The unlock prompt names the device's biometric method」擴充後的設定頁部分。

- [x] 7.5 讓 `biometryType` 查詢不受 `isBiometricUnlockEnabled`／`isLocked` 閘門限制：查詢移到 `appDidBecomeActive` 分支最前，`attemptUnlock` 的觸發仍維持原 guard 條件。驗證：新增測試涵蓋保護關閉時查詢仍會發生；既有兩處斷言「appDidBecomeActive 在保護關閉時無可觀察變化」的測試已更新為斷言 `biometryType` 變化（apps/ios/BuyLedger/Features/App/AppLockFeature.swift、apps/ios/BuyLedgerTests/AppLockFeatureTests.swift、apps/ios/BuyLedgerTests/RootFeatureTests.swift）。
- [x] 7.6 `SettingsView` 的 Toggle 標籤改讀既有的 `store.appLock.unlockButtonTitleKey`，逐字重用鎖定畫面解鎖按鈕的文案 (不新增設定頁專屬的 Toggle 標籤屬性)；`AppLockFeature.State` 新增 `protectionDescriptionKey` 一個依 `biometryType` 衍生的 `LocalizedStringKey` 計算屬性供 footer 使用，命名與衍生方式比照 `unlockButtonTitleKey`。**判準記錄 (定案)**：使用者最初提出需求時已逐字引用「使用 Face ID 解鎖」／「使用 Touch ID 解鎖」；派工單寫「與鎖定畫面按鈕一致的點名方式」，此措辭本身有歧義 (協調者原意是「都點名實際機型」，可合理讀成「字串逐字相同」)，歧義出在派工單措辭，非實作判斷失誤。**已評估並否決的替代方案 (供日後對照，避免誤判為疏漏)**：協調者曾基於語意提出異議 (Toggle 是開關、描述「這個功能是什麼」；按鈕描述「按下去會發生什麼動作」，兩者職責不同，逐字共用會讓其中一處調整措辭時意外牽動另一處)，主張改為獨立文案；此異議已提交使用者裁定，使用者選擇維持逐字重用。日後若有人覺得「使用 Face ID 解鎖」用在開關上語意不符而想改成獨立文案，這個選項已評估過且已被使用者否決，不是疏漏。驗證：TestStore 以替身分別注入 Face ID／Touch ID／無三種類型並斷言 `unlockButtonTitleKey`／`protectionDescriptionKey`，不使用 `exhaustivity = .off`（apps/ios/BuyLedger/Features/App/AppLockFeature.swift、apps/ios/BuyLedger/Features/Settings/SettingsView.swift、apps/ios/BuyLedgerTests/AppLockFeatureTests.swift）。
- [x] 7.7 補齊新增 footer 兩句 (Face ID／Touch ID) 的中英對照；Toggle 標籤因重用既有的「使用 Face ID 解鎖」／「使用 Touch ID 解鎖」／「解鎖」，不再新增條目。原 Toggle 舊文案「離開後鎖定並要求驗證」已無任何程式碼使用，自 `Localizable.xcstrings` 移除。驗證：本地化目錄測試綠燈，英文模式下無語言回退（apps/ios/BuyLedger/Resources/Localizable.xcstrings）。
- [x] 7.8 使用者裁定 Toggle 逐字重用「使用 Face ID 解鎖」後，將 `isProtectionEnabled` 全樹改名為 `isBiometricUnlockEnabled` (`AppLockFeature.State`、`SettingsSnapshot`、`SettingsStorage` 含 `UserDefaults` key 字串本身、`RootFeature.State.init` 參數、`BuyLedgerApp.init`、`BLUITestDependencyOverrides`，與各測試檔斷言)，貼近文案已改用「解鎖」措辭的實際語意；不做新舊 key 過渡遷移 (使用者裁定)，既有已持久化的偏好會在下次啟動讀不到舊 key 而退回預設關閉。驗證：全樹搜尋 `isProtectionEnabled` 零殘留（apps/ios/BuyLedger/Features/App/AppLockFeature.swift、apps/ios/BuyLedger/Features/App/AppLockView.swift、apps/ios/BuyLedger/Features/App/RootFeature.swift、apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift、apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift、apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift、apps/ios/BuyLedger/Features/Settings/SettingsView.swift、apps/ios/BuyLedger/App/BuyLedgerApp.swift、apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift、apps/ios/BuyLedgerTests/AppLockFeatureTests.swift、apps/ios/BuyLedgerTests/RootFeatureTests.swift、apps/ios/BuyLedgerTests/SettingsFeatureTests.swift）。
