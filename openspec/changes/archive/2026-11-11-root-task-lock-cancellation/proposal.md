## Problem

`RootView` 的根層 `.task` 掛在依鎖定狀態切換的 `Group` 上並等待 `finish()`，是 `.claude/rules/ios-navigation.md`「`.task` 不掛在 `Group` 上、只送出不等待」規則唯一的已知例外 (`task-finish-exempt` 標記)。Apple 的 `Group` 文件說修飾器套用到各成員；若 SwiftUI 把這個 `.task` 分給鎖定畫面與主畫面兩個分支，鎖定切換就會取消經 Root 串起的主檔目錄、開團與訂單讀取，三個載入器的載入中旗標停在載入中，開啟帳本保護 (App 鎖) 的使用者只能結束 App 重開。

這是 `load-failure-reload-loop` (2026-11-09 archive) 留下的後續待辦第一項。

## Current Behavior

2026-11-10 在 iPhone 17 (iOS 26.5) 模擬器實測，目前不會發生上述遺失：

- 冷啟動解鎖情境測試 (開啟帳本保護、驗證延遲後成功、訂單讀取 8 秒後失敗) 在修改 `RootView` 前就通過。result bundle 的時間軸顯示總覽失敗訊息在讀取開始後約 8 秒出現，早於「解鎖時刻加 8 秒」，代表鎖定畫面發起的那次讀取撐過了解鎖。
- 暫時加入的診斷日誌 (量完已移除) 顯示根層 `.task` 只啟動一次：冷啟動解鎖、背景上鎖再解鎖都沒有結束或重跑；訂單讀取以未取消狀態完成並送達。解鎖後的訂單請求來自總覽自己的 `.task`。

原先推論的「每次背景上鎖再解鎖時，隱性重試失敗的讀取、重跑幣別快取的過期檢查、重啟系統時間變更監聽」同樣不成立。

這個結果依賴 SwiftUI 沒有文件保證的行為：`load-failure-reload-loop` 實測過總覽的 `Group { switch }` 在分支互換時重跑 `.task`，同類寫法在 `RootView` 不重跑的原因沒有官方說明，可能隨系統版本改變。

## Proposed Solution

使用者 2026-11-11 選定改成預防性修正，比照 `load-failure-reload-loop` 開團清單的先例 (使用者 2026-11-08 決定不依當下系統的實測保留舊寫法)：

- `RootView` 的根層 `.task` 改掛在持久層正常分支內、包住鎖定切換的單一容器 (`ZStack`)，只呼叫 `store.send(.view(.task))`，不等待 `finish()`；鎖定仍以替換主畫面實作。持久層失敗時不顯示這個容器，啟動讀取也不發起。
- `RootLaunchFeature` 的系統時間變更監聽加 cancel id 並設 `cancelInFlight: true`：改成只送出後，根畫面重建使 `.task` 重跑時不再有取消把舊監聽收掉，cancel id 讓新的監聽取代舊的；幣別讀取不加。
- 解鎖不另外補重試 (使用者 2026-11-10 選定)：與目前實際行為一致，讀取失敗由各頁的重試鍵恢復，解鎖後顯示的分頁依自身 `.task` 的規則運作。
- 新增 UI 測試替身「本機驗證延遲後成功」，配合既有的 `ordersDelayed` 以冷啟動解鎖情境測試固定「解鎖不遺失讀取結果」；它在修改前後都通過，不是修改前會失敗的重現測試。使用者 2026-11-11 另選定兩項補強：冷啟動情境測試等待失敗訊息的時間縮到短於一次讀取，看到載入中的延遲夠短時，重新讀取的結果就不能讓它通過 (以變異檢查確認)；並新增「讀取進行中退到背景上鎖、回前景解鎖」情境測試，補上上鎖這一半。
- 規格：honest-state-feedback 新增冷啟動解鎖情境；app-lock 寫明上鎖與解鎖本身不發起、不取消、不重試資料讀取。
- 規則：`ios-navigation.md` 刪除 `RootView` 的已知例外，補上根層 `.task` 的掛法與時間監聽的取代語意。

決策來源、診斷紀錄與取捨見 design.md。

## Success Criteria

- 冷啟動解鎖情境測試 (開啟帳本保護、本機驗證延遲後成功、訂單延遲後讀取失敗) 修改前在 iPhone 17 通過 (實測紀錄寫進 design)，修改後在 iPhone 17 與 iPad Air 11-inch (M4) (iPadOS 27.0) 連跑 3 次都通過：總覽顯示訂單載入失敗訊息與重試鍵，且不再回到載入中；失敗訊息在看到解鎖後的載入中起 7 秒內出現 (短於一次讀取的 8 秒；背景上鎖情境為 5 秒)。
- 背景上鎖情境測試 (開啟帳本保護、本機驗證立即成功、訂單延遲後讀取失敗，讀取中退到背景再回前景) 在 iPhone 17 與 iPad Air 11-inch (M4) 連跑 3 次都通過；主對話以暫時讓訂單讀取「每次請求都取消並重來」的變異確認兩個情境測試都會失敗。
- `RootLaunchFeatureTests` 新測試：連續兩次 `loadRequested` 後只剩一個監聽在運作，一次時間變更只送出一次 `delegate(.significantTimeChanged)`，第一次的監聽已結束；修改前失敗 (2026-11-10 實測：第一次監聽未結束，且多收到一次委派)。
- `RootView` 不再有 `task-finish-exempt` 標記，`TaskFinishConventionScanTests` 通過；`RootFeatureForegroundTests`、`AppLockFeatureTests`、`RootFeatureLoadCancellationTests` 不改預期值仍通過。
- 單元測試全套在 iPhone 17 (iOS 26.5) 通過；`RootView` 是所有畫面的根，完整 UI 回歸在 iPhone 17 與 iPad Air 11-inch (M4) 各跑一次通過。

## Impact

- Affected specs: honest-state-feedback (modified)、app-lock (modified)
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Features/App/Presentation/Root/RootView.swift
    - apps/ios/BuyLedger/Features/App/Presentation/RootLaunch/RootLaunchFeature.swift
    - apps/ios/BuyLedger/Features/App/Presentation/RootLaunch/RootLaunchOperations.swift
    - apps/ios/BuyLedger/App/Testing/Configuration/BLUITestBiometricScenario.swift
    - apps/ios/BuyLedger/App/Testing/TestDoubles/BLUITestStubs.swift
    - apps/ios/BuyLedgerUITests/Support/LaunchOptions.swift
    - apps/ios/BuyLedgerUITests/Tests/Navigation/LoadFailureReloadLoopTests.swift
    - apps/ios/BuyLedgerTests/Features/App/RootLaunchFeatureTests.swift
    - .claude/rules/ios-navigation.md
    - apps/ios/CLAUDE.md
  - New: (none)
  - Removed: (none)
- 行為：iPhone 與 iPad 單一視窗在 iOS 26.5 上沒有使用者可察覺的變化；鎖定切換不再依賴 SwiftUI 未保證的 `.task` 保留行為，根層啟動工作的壽命改由 App 層持有的 store 決定。App 開啟多場景，iPad 在讀取中關閉其中一個視窗時，修改前依讀碼推論會取消共用讀取，修改後不會 (未實測)。
