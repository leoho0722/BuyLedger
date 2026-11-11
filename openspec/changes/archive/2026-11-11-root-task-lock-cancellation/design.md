## Context

本 change 是 `load-failure-reload-loop` (2026-11-09 archive) design「後續待辦」的第一項。2026-11-10 `/spectra-discuss` 讀碼確認的現況：

- `RootView.mainContent` 是 `Group { if store.appLock.isLocked { AppLockView } else { rootNavigation } }`，其上掛 `.task { await store.send(.view(.task)).finish() }`，同一行有 `// task-finish-exempt: 已知風險，待後續 change` 標記。Apple 的 `Group` 文件說修飾器套用到各成員。
- `RootFeature` 收到 `view(.task)` 時合併送出 `.campaigns(.loadRequested)`、`.more(.catalogLoadRequested)`、`.launch(.loadRequested)`；主檔目錄讀完 (`.more(.delegate(.catalogLoadFinished))`) 才送 `.orders(.rootRequest(.load))`。總覽與分析的 `delegate(.refresh)`、訂單清單的載入請求也都經 Root 先送主檔目錄。
- `LookupCatalogFeature`、`CampaignLoadFeature`、`OrdersLoadFeature` 以「只由回應清除的載入中旗標」去重；`LookupCatalogFeature` 已載入時直接送 `delegate(.loadFinished)`，載入中時略過。
- `RootLaunchFeature.loadRequested` 回傳 `RootLaunchOperations.start()`：合併幣別快取讀取 (`refreshIfStale(604_800)` 後 `fetchCodes`) 與系統時間變更監聽 (`observeSignificantTimeChanges`，`for await` 一個不會結束的 stream)，兩者都沒有 cancel id。live 的 `SignificantTimeChangeService` 在 stream 終止時移除通知 observer。
- `persistenceFailure` 只在 `RootFeature.State.init` 依持久層狀態設定；`PersistenceFailureFeature` 復原成功只把 `phase` 改成 `relaunchRequired`，不清成 `nil`。`RootView` 的持久層正常分支在同一個 process 內不會出現後又消失。
- `AppLockFeature` 在回到前景且鎖定中時送 `delegate(.didBecomeActive)` 並發起驗證；`unlockResponse(.success)` 只改狀態、不送 effect。`delegate(.didBecomeActive)` 對所有使用者都會送出，Root 以它重寫日期脈絡。
- UI 測試的本機驗證替身 (`BLUITestStubs.makeBiometricAuthService`) 原本只有兩種情境：`success` 立即成功、`failure` 延遲 3 秒後失敗。`BLUITestConfiguration` 以 `rawValue` 解析 `-BLUITestBiometricScenario`，新增 case 不需改解析。
- 既有的 `ordersDelayed` 讓每次訂單讀取延遲 8 秒後失敗 (`DependencyValues+BLUITestOverrides`，設定值)。
- App 開啟多場景：`project.xcproj` 以 `INFOPLIST_KEY_UIApplicationSceneManifest_Generation = YES` 生成場景設定，建置產物 `Info.plist` 的 `UIApplicationSupportsMultipleScenes` 為 `true` (4.1 架構審查指出，主對話以 `plutil` 核對)；`BuyLedgerApp` 的 `WindowGroup` 每個視窗各建一個 `RootView`，共用同一個根 store。
- TCA 1.26.2 的 `RootCore._send` (讀套件原始碼確認)：effect 送回的 action 所產生的 task 會併入原本那次送出的 task 清單，取消時逐一取消，所以 `.task` 被取消時經 Root 串起的讀取會一起取消 (`RootFeatureLoadCancellationTests` 以 `TestStore` 固定同一語意)。

discuss 時的推論 (已被下方實測推翻)：鎖定與主畫面互換時，`Group` 上的 `.task` 隨分支取消並重跑，冷啟動驗證通過時經 Root 串起的讀取全被取消，三個載入器卡在載入中；開啟保護的使用者每次解鎖也會隱性重送整條啟動鏈。

決策來源：修法方向由主對話在 `/spectra-discuss` 提出；`opus-arch-reviewer` (Herdr t1p) 唯讀審查同意，並補充三項細節 (容器放在持久層正常分支內、cancel id 只套監聽、需要延遲成功的驗證替身)；使用者 2026-11-10 選定「解鎖不另補重試」(選項 A)，並回覆「採用 A，開 /spectra-propose」。apply 期間的診斷與方向改變見下方「診斷結論與預防性修正」。

## Goals / Non-Goals

**Goals:**

- 鎖定與解鎖只切換顯示內容，不取消、不重送根層啟動工作，且不依賴 SwiftUI 對 `Group` 修飾器的未保證行為。
- 開啟帳本保護冷啟動、驗證在啟動讀取完成前通過時，讀取結果送達各頁：失敗時顯示失敗訊息與重試鍵，不停在載入中 (iOS 26.5 目前已成立，以情境測試固定)。
- 系統時間變更監聽任何時候只有一份。
- `RootView` 不再是 `.task` 規則的例外，`ios-navigation.md` 刪除「已知例外」。

**Non-Goals:**

- 不新增解鎖或回到前景時的自動重試 (選項 B、C，見「解鎖不另補重試」)。
- 不把鎖定改成覆蓋在內容上：app-lock 規格以替換畫面實作，覆蓋會讓內容留在畫面階層中。
- 不改三個載入器的去重規則，不做「載入器自我恢復」：修正後沒有剩下可取消的根層發起者，該項的觸發條件不成立。
- 不處理匯率與報價頁等待 `finish()`、客戶頁載入狀態、移除 `OrderListFeature.State.isLoading` 投影 (工作順序的下一項)。
- 不處理多視窗共用單一根 store 的其他行為 (分頁、導覽路徑與呈現狀態互相鏡像)：Info.plist 生成設定開啟了多場景，這是既有狀況，不在本 change 範圍。
- 不新增掃描「`.task` 掛在 `Group` 上」的守門：詞法上判斷不了 body 是否為條件內容。
- 不追查 `RootView` 的 `Group` 在 iOS 26.5 不重跑 `.task` 的原因：修正後不再依賴這個行為。

## Decisions

### 診斷結論與預防性修正

Supersedes：本 change 原本的問題定位「鎖定切換會取消根層啟動鏈，冷啟動解鎖遺失讀取結果」(proposal 原 Root Cause 與上方 Context 的 discuss 推論)，改為「`RootView` 依賴 SwiftUI 未保證的行為，做預防性修正」。

apply 期間的實測 (iPhone 17、iOS 26.5 模擬器)：

- 2026-11-10 task 1.2 的冷啟動解鎖案例 (驗證延遲 2 秒後成功、`ordersDelayed`) 在修改 `RootView` 前通過，與 design 預期的「停在載入中」不符。result bundle 時間軸：App 約 3.7 秒到前景，鎖定畫面在 4.78 秒仍存在、總覽載入中在 5.84 秒出現，總覽失敗訊息在 10.94 到 11.92 秒之間出現，早於「解鎖時刻 (晚於 4.78 秒) 加 8 秒」，所以是鎖定畫面發起的那次讀取撐過了解鎖。
- 主對話提出、使用者 2026-11-10 選定「先做診斷再決定」：在 `RootView` 的 `.task`、`OrdersLoadFeature` 與 `AppLockFeature` 暫時加入 `print` 診斷 (量完已還原，三檔與 HEAD 逐位元組一致)，以 `launch-app` 啟動同一組參數。冷啟動時根層 `.task` 只啟動一次 (`locked=true`)；解鎖後總覽的訂單請求因載入中被去重，最初那次讀取以未取消狀態完成並送達。接著背景上鎖再回前景解鎖，根層 `.task` 同樣沒有結束或重跑；解鎖後的新訂單讀取來自總覽自己的 `.task` (主畫面重建)。
- 所以在 iOS 26.5 上，`RootView` 的 `Group` 不會讓根層 `.task` 隨鎖定切換取消或重跑；原推論的「每次解鎖隱性重試失敗的讀取、重跑幣別快取過期檢查、重啟時間監聽」也不成立。`load-failure-reload-loop` 實測過總覽的 `Group { switch }` 會在分支互換時重跑 `.task`，兩者差異沒有官方說明。
- 同一輪 `RootLaunchFeatureTests` 新測試在修改前如預期失敗 (第一次監聽的終止狀態為 `[false, false]`，且多收到一次 `delegate(.significantTimeChanged)`)，其他 5 條通過。

使用者 2026-11-11 選定「改成預防性修正」：比照 `load-failure-reload-loop` 開團清單的先例 (使用者 2026-11-08 決定不依當下系統的取樣結果保留舊寫法，因為規則與程式碼會說兩套，且官方沒有保證這個行為不隨 SwiftUI 版本改變)，下方三項修正照做，冷啟動解鎖案例改為修改前後都通過的情境測試。

替代方案：

- 只把紀錄改成實測結論、`RootView` 不改：保留規則唯一的例外，並繼續依賴未保證的行為，不採用。
- 停止並還原、change 重新 park：同上，且已完成的替身與測試會丟棄，不採用。

### 根層 .task 掛在持久層正常分支內包住鎖定切換的單一容器

`mainContent` 改為 `ZStack { if store.appLock.isLocked { AppLockView } else { rootNavigation } }`，`.task` 掛在這個 `ZStack` 上，比照 `load-failure-reload-loop` 開團清單的單一容器寫法。鎖定與解鎖只改變 `ZStack` 的子內容，`ZStack` 本身的身分不變，`.task` 不會因鎖定切換而取消或重跑；這個保證不靠 `Group` 在特定系統版本的行為。

容器留在 `body` 外層 `Group` 的 `else` 分支 (持久層正常) 之內，不抬到 `body` 外層：外層也是 `Group`，修飾器會分給 `PersistenceFailureView` 分支，持久層無法開啟時也會對記憶體內的備援資料庫發起讀取與幣別寫入。持久層正常分支在同一個 process 內不會出現後又消失 (見 Context)，所以不在 reducer 另加 `persistenceFailure == nil` 的守衛，避免多一個事實來源。

替代方案：

- 抬到 `body` 外層：降級模式也會啟動讀取，不採用。
- 鎖定改成覆蓋 (`rootNavigation` 常駐、鎖定畫面疊在上面)：違反 app-lock 規格的替換語意，內容會留在畫面與輔助使用的元素樹中，不採用。

### 根層 .task 只送出不等待 finish

`.task` 只呼叫 `store.send(.view(.task))`，刪除 `task-finish-exempt` 標記。這推翻了 `load-failure-reload-loop` design「後續待辦」RootView 一項寫的「保留 `finish()`」方向 (主對話提出、架構審查同意、使用者 2026-11-10 同意)。

理由：根層啟動鏈的工作屬於 App 層持有的 store (`BuyLedgerApp` 建立並持有根 store)，壽命與 App 相同，不該綁在可能重建的 view 上。即使容器不再隨鎖定切換，根畫面重建時等待中的 `finish()` 仍會取消經 Root 串起的共用讀取，三個載入器又會卡在載入中。重建的來源有系統斷開背景場景後重新連線，以及 iPad 關閉多個視窗中的一個 (各視窗各有一個 `RootView`，見 Context)，兩者都是讀碼推論、未實測 (使用者 2026-11-11 選定不實測 iPad 多視窗)；而 `ios-navigation.md` 已規定以載入中旗標去重的載入器不可在會被取消的 `.task` 底下發起。保留 `finish()` 也會讓「載入器自我恢復」的觸發條件 (根層發起端無法不可取消) 成立。

不等待之後，唯一會一直存活的 effect 是系統時間變更監聽，由下一個決策處理。

兩項修正都不改變 iOS 26.5 上的可觀察行為 (見「診斷結論與預防性修正」)：冷啟動解鎖情境測試在兩項都還原時也通過，所以不能用它對這兩項做變異確認；容器與只送出的保證靠規則與審查守住，見 Risks。

### 時間監聽以 cancel id 取代前一次監聽

`RootLaunchFeature` 新增 `CancelID` (依 ios-dev-kit 放 Nested Types extension)，`RootLaunchOperations` 的 `observeSignificantTimeChanges()` 加 `.cancellable(id: RootLaunchFeature.CancelID.significantTimeChanges, cancelInFlight: true)`；`RootLaunchFeature.Action.loadRequested` 的 doc comment 寫明再次送出時取代前一次監聽。

- 需要的理由：改成只送出後，根層 `.task` 若因根畫面重建而重跑，前一次送出衍生的監聽不再被取消，兩份監聽會各送一次時間變更委派。2026-11-10 的單元測試已在 reducer 層重現疊加 (見「診斷結論與預防性修正」)。
- cancel id 只套監聽 effect，不套 `start()` 合併後的 effect：套在合併 effect 上，再次 `loadRequested` 會連帶取消進行中的幣別讀取。幣別讀取不加 cancel id：重複讀取只多一次 `refreshIfStale`，共用清單只在非空時覆寫，結果冪等。
- 不採用「State 旗標記錄已在監聽、只啟動一次」：旗標要靠 effect 結束時清除，被外部取消時 reducer 收不到，與三個載入器卡住是同一種結構。
- 取代期間的空窗是舊監聽取消到新監聽 Task 開始訂閱之間的一次排程 (TCA 在新 effect 的 task 開始時才取消舊的)；回到前景本來就由 `delegate(.didBecomeActive)` 重寫日期脈絡，可以接受。

### 解鎖不另補重試

使用者 2026-11-10 選定選項 A：解鎖不另外補明確的重試；讀取失敗由各頁的重試鍵恢復。實測顯示目前解鎖本來就不重送根層啟動鏈 (見「診斷結論與預防性修正」)，所以選項 A 等於維持現有行為，不會讓任何重試消失。

- 主畫面在解鎖時整個重建，當下分頁自己的 `.task` 仍會依「畫面出現就載入」的規則重送 (總覽與分析送 `delegate(.refresh)`，訂單清單經 Root 先讀主檔目錄，開團清單重送開團讀取)；2026-11-10 診斷看到的解鎖後訂單讀取即屬此類。這屬於分頁本身的出現規則，不是鎖定政策；app-lock 規格以「解鎖後顯示的畫面依自身出現規則載入」寫明。
- 選項 C (只在解鎖成功時重試) 不採用：`AppLockFeature` 要多一個只為重試存在的 delegate，鎖定功能因此帶有資料語意；開鎖與不開鎖的使用者會有兩套恢復行為；日後若由 `RootFeature` 負責分頁出現就載入，它會成為要拆掉的平行觸發點。
- 選項 B (每次回到前景都重試) 延後：與 `load-failure-reload-loop` 的 Non-Goal「不新增自動重試或退避」相衝突；持續失敗時每次切回 App 各頁會從失敗閃成載入中再回到失敗，VoiceOver 重複播報；本機資料庫讀取失敗通常不會因切回 App 而恢復。觸發條件：使用者要求切回 App 自動恢復，或出現會暫時失敗的網路來源共用讀取。屆時由 Root 處理 `delegate(.didBecomeActive)` 的同一處負責，所有使用者一致。

既有測試已守住「驗證成功只解除鎖定」：`AppLockFeatureTests.scenePhaseChanged_回到前景且鎖定中驗證成功_解除鎖定並送出回前景委派` 以 exhaustive `TestStore` 確認只收到 `delegate(.didBecomeActive)` 與 `unlockResponse`、之後沒有 effect；`RootFeatureForegroundTests` 以 exhaustive `TestStore` 確認 Root 收到 `didBecomeActive` 只重寫日期脈絡。本 change 不新增 reducer 測試。

### 延遲成功的本機驗證替身與冷啟動解鎖情境測試

`BLUITestBiometricScenario` (App 端) 與 `LaunchOptions.BiometricScenario` (UI 測試端) 各加 `successDelayed`，`rawValue` 一致；`BLUITestStubs.makeBiometricAuthService` 對 `successDelayed` 延遲後回傳成功。

延遲秒數：task 1.1 先以主對話估計的 2 秒實作，2026-11-10 實測不足：`launch()` 約在啟動後 3.7 秒才回傳 (實測)，3 次執行中有 2 次在「鎖定畫面 1 秒內出現」的檢查失敗 (實測，鎖定畫面已因解鎖消失)。改為 4 秒 (估計值)：要長到 `launch()` 回傳時鎖定畫面仍在，又要短於 `ordersDelayed` 的 8 秒，讓解鎖發生在訂單讀取進行中、總覽仍顯示載入中。以修改後在 iPhone 17 與 iPad Air 各連跑 3 次全部通過確認；任一次在時間窗檢查失敗即表示估計不成立，回到本節調整。

情境測試放在 `LoadFailureReloadLoopTests` (同屬共用讀取不因發起畫面消失而遺失)，以 `LaunchOptions(loadFailure: .ordersDelayed, isAppLockEnabled: true, biometricScenario: .successDelayed)` 啟動：

- 先確認鎖定畫面 (`BLAccessibilityID.AppLock.root`) 出現，否則時間窗不存在，以診斷訊息失敗。
- 解鎖後確認總覽顯示載入中 (`BLAccessibilityID.Dashboard.loading`)，否則同樣以時間窗不存在失敗；等待秒數要涵蓋 4 秒驗證延遲。
- 以 `assertLoadStateStaysStable` 等待總覽的 `BLAccessibilityID.Dashboard.loadFailure` 出現，期間與之後 `loadFailureRetryButton` 存在、`loading` 不再出現；首次出現的等待傳入 7 秒 (從看到解鎖後的載入中起算)。

失敗訊息的等待秒數：task 1.2 原本傳入 15 秒 (比照同檔延遲失敗測試)，review 指出解鎖若晚於第一次讀取失敗，總覽會依自身出現規則重新讀取，重新顯示的載入中照樣通過上一項檢查，15 秒內也等得到新讀取的失敗，測試分辨不出時間窗不存在。使用者 2026-11-11 採納 review 建議改為 7 秒：短於一次讀取的 8 秒。依據：4.2 回歸那輪 iPad Air 3 次執行 (等待仍為 15 秒)，從看到載入中到看到失敗訊息間隔 4.3 至 5.3 秒 (實測，2026-11-11 讀 result bundle 時間軸)。

分辨條件 (t17 審查指出，主對話核對成立)：重來的讀取在它開始後 8 秒失敗，測試從看到載入中起等 7 秒，所以只有「讀取重新開始到測試看到載入中」少於 1 秒時，重來的讀取才不能讓測試通過；這段延遲主要是 `waitForExistence` 約每秒一次的檢查間隔 (估計)，不是保證值。原讀取一側的餘裕：實測間隔最長 5.29 秒 (5.1 的 iPhone)，距 7 秒約 1.7 秒。不改為 6 秒 (主對話判定)：餘裕只剩約 0.7 秒，常態路徑容易偶發失敗。分辨能力以變異檢查確認：讀取每次請求都取消並重來時，iPhone 17 與 iPad Air 各 3 次都在 7 秒等待失敗 (實測，見實作紀錄)。間隔接近 7 秒，或變異下有任一次通過，即回到本節調整。

這是情境測試，不是修改前會失敗的重現測試：它固定 spec 的冷啟動解鎖情境，若日後 SwiftUI 開始把根層 `.task` 分給分支、且有人把容器與只送出一起還原，它才會轉紅。

### 背景上鎖再解鎖的情境測試

app-lock 需求的上鎖這一半 (使用者 2026-11-11 採納 verify 建議補上) 放在 `LoadFailureReloadLoopTests`，以 `LaunchOptions(loadFailure: .ordersDelayed, isAppLockEnabled: true, biometricScenario: .success)` 啟動：冷啟動解鎖立即完成，總覽等待第一次訂單讀取。

- Given：總覽顯示載入中 (`BLAccessibilityID.Dashboard.loading`)，記下看到的時刻；等不到即以時間窗不存在失敗。
- When：`XCUIDevice.shared.press(.home)` 讓 App 進入背景，確認 App 狀態為 `runningBackground` 或 `runningBackgroundSuspended`，否則以「未進入背景、沒有上鎖」失敗；停在背景直到看到載入中後 3 秒 (估計值)，再以 `app.activate()` 回前景，驗證立即成功而解鎖。
- Then：總覽再次顯示載入中 (主畫面重建後總覽的 `.task` 送出請求，被載入器去重)，等待 3 秒 (估計值)，等不到即以時間窗不存在失敗；再以 `assertLoadStateStaysStable` 等待 `BLAccessibilityID.Dashboard.loadFailure`，首次出現等待 5 秒，期間與之後 `loadFailureRetryButton` 存在、`loading` 不再出現。

選 `.success` 而不用 `successDelayed`：驗證延遲 4 秒時，回前景後解鎖的時刻多半已晚於第一次讀取失敗，總覽依自身出現規則重新讀取，測不到「讀取跨過上鎖」。代價是鎖定畫面一閃即過、XCUITest 觀察不到；上鎖本身由 `AppLockFeatureTests` 守住 (`scenePhaseChanged(.background)` 後 `isLocked` 為 true)，這條 UI 測試只確認 App 真的進過背景。

失敗訊息的等待與背景停留 (5.3 依 t17 審查修正，主對話判定)：

- 分辨條件與冷啟動相同：重來的讀取在它開始後 8 秒失敗，等待 5 秒時，「讀取重新開始到測試看到載入中」要達到 3 秒以上，重來的讀取才會讓測試通過。5.2 原本沿用 7 秒，這段延遲只要達到 1 秒就會誤判通過；`activate()` 回傳後約 1.1 秒才看到載入中 (實測，5.2 的時間軸)，餘裕不足，所以改為 5 秒。
- 停在背景的秒數決定原讀取剩下多少：停得越久，解鎖後看到失敗訊息的間隔越短，越容易落在 5 秒內；但停太久會讓讀取在回前景前結束，「回前景後再次看到載入中」的檢查失敗。3 秒 (估計值) 時，間隔實測 1.35 至 3.33 秒 (5.2)，距 5 秒的上限約 1.7 秒、距 0 的下限約 1.35 秒。
- 調整準則：任一次間隔超過 4 秒或低於 1 秒、時間窗檢查失敗，或變異下有任一次通過，回到本節調整。

變異檢查 (主對話)：暫時讓 `OrdersLoadFeature` 每次 `loadRequested` 都取消進行中的讀取並重新讀取 (移除載入中略過、讀取效果加 `cancelInFlight: true`)，在 iPhone 17 與 iPad Air 各以 `-test-iterations 3` 跑冷啟動解鎖與背景上鎖情境測試，每次都要在失敗訊息的等待逾時失敗 (冷啟動 7 秒、背景上鎖 5 秒)，不是在其他檢查失敗；量完還原，`OrdersLoadFeature.swift` 的雜湊與變異前一致。這證明等待秒數能分辨「讀取被取消後重來」，但只證明當次的觀察延遲夠短，分辨條件見上。

### 規則寫進 ios-navigation.md

- 「根導覽與啟動」的 `.task` 條目刪除「已知例外：`RootView` 的根層 `.task`…」這一行，改寫成現行寫法：根層 `.task` 掛在持久層正常分支內、包住鎖定切換的單一容器上，只送出；不掛在 `body` 外層的 `Group`，否則持久層失敗時也會發起讀取。
- 同一節補一句：系統時間變更監聽以 cancel id 取代前一次監聽，`loadRequested` 重送不會疊加。
- 「App 鎖定」補一條：鎖定與解鎖只切換顯示內容，不發起、不取消、不重試資料讀取；解鎖後顯示的分頁依自身出現規則載入，要加前景重試時由 Root 處理 `didBecomeActive`，不由 `AppLockFeature` 新增 delegate。

規則只寫現行規則與理由，不寫本 change 的事件經過與實測沿革。

## Implementation Contract

**Behavior**

- 開啟帳本保護冷啟動、驗證在啟動讀取完成前通過時，讀取結果送達各頁：訂單讀取失敗時總覽顯示失敗訊息與重試鍵，不停在載入中；重試鍵按下後會再次讀取。
- 鎖定與解鎖不取消、不重送根層的啟動工作 (主檔目錄、開團、幣別讀取與時間監聽)；解鎖後顯示的分頁依自身 `.task` 的規則載入。這項行為由單一容器保證，不依賴 `Group` 的修飾器分配方式。
- 系統時間變更監聽同時只有一份：再次送 `RootLaunchFeature.Action.loadRequested` 時，前一次監聽被取消、新的監聽接手，一次時間變更只送一次 `delegate(.significantTimeChanged)`。
- 持久層無法開啟時不發起啟動讀取 (與現況相同)。
- 沒有開啟帳本保護的使用者行為不變；開啟保護的使用者在 iOS 26.5 上也沒有可察覺的變化。

**Interface / data shape**

- `RootView.mainContent`：持久層正常分支內的單一 `ZStack` 包住鎖定切換，`.task { store.send(.view(.task)) }`，不等待 `finish()`，沒有 `task-finish-exempt` 標記。
- `RootLaunchFeature.CancelID`：新增巢狀列舉，含 `significantTimeChanges` 一個 case；`RootLaunchOperations.observeSignificantTimeChanges()` 的 effect 以它 `.cancellable(id:cancelInFlight: true)`。`RootLaunchFeature.Action` 不新增 case。
- `BLUITestBiometricScenario.successDelayed` 與 `LaunchOptions.BiometricScenario.successDelayed`：命令列值 `successDelayed`，延遲 4 秒後成功；`success`、`failure` 不變。

**Failure modes**

- 訂單讀取失敗：失敗訊息與重試鍵 (既有行為)，不因鎖定切換而遺失。
- 幣別讀取失敗或空結果：保留共用清單 (既有行為)。
- 驗證失敗或取消：維持鎖定畫面 (既有行為)，啟動讀取照常在背後完成。

**Acceptance criteria**

- `LoadFailureReloadLoopTests` 的冷啟動解鎖情境測試：修改前在 iPhone 17 (iOS 26.5) 通過並記錄；修改後在 iPhone 17 與 iPad Air 11-inch (M4) (iPadOS 27.0) 各連跑 3 次都通過。
- 冷啟動解鎖情境測試的失敗訊息首次出現等待為 7 秒；背景上鎖情境測試 (`.success`、`ordersDelayed`，讀取中進背景、看到載入中後 3 秒回前景) 在解鎖後再次看到載入中，5 秒內看到失敗訊息與重試鍵，之後不再回到載入中。兩條在 iPhone 17 與 iPad Air 各連跑 3 次都通過，時間軸間隔記錄進 design。
- 變異檢查：`OrdersLoadFeature` 暫時改成每次請求都取消並重新讀取時，兩條情境測試在 iPhone 17 與 iPad Air 各 3 次都在失敗訊息的等待逾時失敗；還原後雜湊與變異前一致。
- `RootLaunchFeatureTests` 新測試：替身記錄每次訂閱與終止；連續送兩次 `loadRequested` 後送一次時間變更，只收到一次 `delegate(.significantTimeChanged)`，且第一次的 stream 已終止。修改前失敗 (2026-11-10 已實測)，修改後通過。
- `TaskFinishConventionScanTests`、`AppLockFeatureTests`、`RootFeatureForegroundTests`、`RootFeatureLoadCancellationTests`、`RootLaunchFeatureTests` 既有測試不改預期值仍通過。
- 單元測試全套在 iPhone 17 (iOS 26.5) 通過；`RootView` 是所有畫面的根，完整 UI 回歸在兩台模擬器各跑一次。
- `ios-navigation.md` 不再有 `RootView` 的已知例外，並含上述三處補充。

**Scope boundaries**

- In scope：`RootView`、`RootLaunchFeature`、`RootLaunchOperations`、UI 測試支援層的本機驗證替身 (`BLUITestBiometricScenario`、`BLUITestStubs`、`LaunchOptions`)、`LoadFailureReloadLoopTests`、`RootLaunchFeatureTests`、`.claude/rules/ios-navigation.md`、`apps/ios/CLAUDE.md` (kit 差異記錄與診斷時查到的兩條 `mobilebuildmcp` 注意事項)。
- Out of scope：三個載入器 (`OrdersLoadFeature` 只做量完即還原的變異檢查)、`AppLockFeature`、`RootFeature` 的 action 與 reducer、匯率與報價頁、客戶頁、多視窗、鎖定的呈現方式、`Group` 不重跑 `.task` 的成因。

## Risks / Trade-offs

- [冷啟動情境測試守不住這兩項：在 iOS 26.5 上把兩項都還原仍通過] → 加回 `finish()` 需要 `task-finish-exempt` 標記，沒有標記時由 `TaskFinishConventionScanTests` 擋下；豁免理由與容器形狀靠規則 (寫明 `RootView` 不以豁免標記處理) 與審查守住，不新增掃描 (無法以詞法判斷條件內容)。
- [冷啟動情境測試的時間窗依賴 4 秒估計值] → 修改後兩台各連跑 3 次確認；不穩定時依「延遲成功的本機驗證替身與冷啟動解鎖情境測試」調整。
- [幣別快取過期檢查只在冷啟動] → 與現況相同 (診斷顯示解鎖本來就不重跑)；期限 7 天，只有 process 連續存活超過 7 天才會晚於期限刷新；需要時另案由 Root 在 `didBecomeActive` 只送幣別刷新，不帶整條讀取鏈。
- [根畫面容器改為 `ZStack` 可能影響版面或可及性樹] → `RootView` 是所有畫面的根，完整 UI 回歸在兩台模擬器各跑一次。
- [根畫面重建 (系統斷開背景場景、iPad 關閉其中一個視窗) 的行為未實測 (推論)] → 只送出後根層讀取不受取消影響，重送由載入器去重、監聽由 cancel id 取代，結果冪等。
- [解鎖時主畫面整棵重建，畫面本地狀態 (捲動位置等) 重置] → 替換式鎖定的既有代價，本 change 不改。
- [兩條情境測試依賴失敗訊息的等待 (冷啟動 7 秒、背景上鎖 5 秒)、背景停留 3 秒等估計值與模擬器回前景的速度] → 兩台各連跑 3 次並記錄時間軸間隔；iPad 若出現 XCUITest 閒置等待拉長 `activate()`，依 `ios-ui-tests.md` 重開模擬器重跑，不放寬等待秒數；間隔觸及各節的調整準則時回 design 調整。
- [分辨「讀取被取消後重來」依賴觀察延遲短於門檻差 (冷啟動 1 秒、背景上鎖 3 秒)，不是保證值] → 變異檢查兩台各 3 次確認；日後改到等待寫法或模擬器變慢時，重跑變異檢查。

## 實作與實測紀錄

全部在 iPhone 17 (iOS 26.5) 模擬器，實作者交回前都跑過 `swiftc -parse`，建置與測試由主對話執行。

- 1.1 (t16 實作，2026-11-10)：`successDelayed` 兩端與替身完成；延遲常數命名為 `biometricSuccessDelay`，既有 3 秒常數改名 `biometricFailureDelay` (t16 選擇)，`makeBiometricAuthService` 改為 `switch`。`AppLockTests` 3 條通過。
- 1.2 (t16 實作，2026-11-10 寫入、2026-11-11 修訂)：延遲改 4 秒、總覽載入中的等待改 8 秒 (主對話指定)，鎖定畫面檢查維持 1 秒。修改 `RootView` 前以 `-test-iterations 3` 跑冷啟動解鎖案例，3 次重複都通過 (預期結果，見「診斷結論與預防性修正」)；`AppLockTests` 3 條通過。
- 2.1 (t1n 實作)：新測試修改前失敗 (第一次 stream 終止狀態 `[false, false]`，且多收到一次 `delegate(.significantTimeChanged)`)，其他 5 條通過；加入 `CancelID` 與 `.cancellable` 後 `RootLaunchFeatureTests` 6 條通過。
- 1.3 (t16 實作)：`RootView.mainContent` 改為 `ZStack`、`.task` 只送出、刪除豁免標記。以 `-test-iterations 3` 跑冷啟動解鎖案例與 `AppLockTests`，4 條各 3 次重複全部通過；`TaskFinishConventionScanTests` (11)、`AppLockFeatureTests` (9)、`RootFeatureForegroundTests` (5)、`RootFeatureLoadCancellationTests` (1)、`RootLaunchFeatureTests` (6) 共 32 條不改預期值通過。
- 診斷與回歸期間 (主對話)：`apps/ios/CLAUDE.md`「ui-automation」補兩條這次查到的工具注意事項：`launch-app` 回傳的 OSLog 檔只擷取啟動後一小段時間，跨背景與前景的暫時診斷要改看 Runtime Logs (stdout)；`--extra-args` 的純數字值 (`-test-iterations 3`) 與 `--launch-args` 一樣會驗證失敗，要改用 `--json`。
- 5.1、5.2 (t16 實作，2026-11-11)：冷啟動情境測試的失敗訊息等待改為 7 秒；新增 `testBackgroundLock_訂單延遲讀取失敗_回前景解鎖後總覽收到失敗結果`，以私有 helper `waitUntilInBackground` 每 0.2 秒輪詢 `app.state`，`runningBackground` 或 `runningBackgroundSuspended` 任一即成立 (t16 選擇：App 很快轉為 suspended 時，`app.wait(for: .runningBackground)` 會錯過)；啟動後等總覽載入中的上限 5 秒 (t16 選擇)。兩條以 `-test-iterations 3` 在 iPhone 17 (iOS 26.5) 與 iPad Air 11-inch (M4) (iPadOS 27.0) 各跑 3 次，兩台共 12 次執行全部通過。result bundle 時間軸 (實測，看到解鎖後載入中到看到失敗訊息)：
    - 冷啟動解鎖：iPhone 4.25 至 5.29 秒，iPad 4.29 至 4.32 秒。
    - 背景上鎖：iPhone 2.32 至 3.33 秒，iPad 1.35 至 2.30 秒。iPad 第 1 次啟動較慢 (約慢 3.4 秒)，回前景後看到載入中時離讀取結束只剩約 1.35 秒，是時間窗最窄的一次；時間窗檢查沒有失敗，3 秒停留維持不變 (主對話判定)。背景上鎖的等待在 5.3 由 7 秒改為 5 秒，見「審查紀錄 (5.3)」。

## 審查紀錄 (4.1)

審查者都未參與實作：t9 (codex-luna-max-impl) 唯讀 style 閘門、t17 (`opus-xhigh-reviewer`) 正確性、t1p (`opus-arch-reviewer`) 架構，主對話同時審查。審查前後 `git status --short` 與 15 個檔 (9 個變更檔與 change artifacts) 的雜湊一致。

- t1p：程式碼不需修改。必修：design 的「專案未宣告多場景、目前單視窗」與建置產物不符，已改寫 Context、Non-Goals、「根層 .task 只送出不等待 finish」與 Risks，proposal 的行為描述限定為單一視窗。建議採納：規則補容器不可改成條件內容、不以豁免標記處理的理由 (併入 t17 S3 的前提說明)；「根層 `view(.task)` 衍生的工作必須可重送」寫成通則；Risks 改寫既有守門。kit `tca-architecture.md` 的 Effect 條目 (監聽靠離開畫面取消、`CancelID` 只給使用者動作) 與專案規則衝突，使用者 2026-11-11 選定記到 `apps/ios/CLAUDE.md`「ios-dev-kit 規範與專案差異」。iPad 多視窗的修改前後實測，使用者 2026-11-11 選定不做，標為推論。觀察 (不處理)：多視窗共用單一根 store 會讓分頁與呈現狀態互相鏡像；「持久層失敗不發起讀取」只由 view 結構保證，`PersistenceFailureFeature` 改成不重開就復原時要在 reducer 補守衛。
- t17：無必修。S1 (新單元測試在 `[true, false]` 的斷言時點有理論競態，只會假失敗)：不改，t17 建議的有限次 `Task.yield` 輪詢違反 `ios-unit-tests.md`「非同步結果不得以 `Task.yield` 輪詢」(主對話判定)。S2 (空窗描述不精確)：已改。S3 (規則中 `RootView` 掛在分支內與「body 根」字面不一致)：補上「持久層正常分支出現後不會消失」的前提。
- t9：必修 1 (UI 測試摘要沒有以「驗證」開頭)：已改。必修 2 (同檔 6 處等待放在 Given 或 When)：不改，「等待放在 Then」出自 `ios-unit-tests.md`，對象是 `store.finish()`、`clock.advance`、`continuation` 等 effect 等待，不涵蓋 UI 測試的就緒等待；派工單把它概括寫成通則才造成誤判，同檔既有兩條測試也是同一寫法 (主對話判定)。建議確認 (`RootLaunchFeatureTests` 的 Given 等待首次訂閱)：屬「必須經 effect 才成立的前置可在 Given 用 send／receive」，不改 (主對話判定)。
- 主對話：建置日誌沒有本次檔案的警告；8 個 Swift 檔沒有超過 100 字元的行。
- t9 複查修正處：無必修；2 項措辭建議 (UI 測試摘要避免重複「驗證」、`apps/ios/CLAUDE.md` 新條目的標題改白話並以反引號標 `Effect`) 已採納。複查前後 `git status --short` 與雜湊一致。

## 回歸紀錄 (4.2)

主對話執行，iPhone 17 (iOS 26.5) 與 iPad Air 11-inch (M4) (iPadOS 27.0) 模擬器，外觀都鎖淺色。

- 前置：iPad 第一次跑 `KeyboardDismissTests` 2 條有 1 條失敗 (「數字鍵盤或 Popover 未能收起 (呈現方式：浮動數字面板)」)，Device Hub 的 Simulate Hardware Keyboard 為勾選；取消勾選後重跑 2 條通過。
- 單元：完整 `BuyLedgerTests` 在 iPhone 17 共 2048 條，2045 通過、0 失敗、3 條既有預期失敗；snapshot 沒有重錄 (回歸前後 `git status --short` 一致)。
- UI (iPhone 17)：247 條，197 通過、0 失敗、49 條依版面略過、1 條既有預期失敗。
- UI (iPad Air) 全跑：247 條，215 通過、6 失敗、25 條略過、1 條既有預期失敗。6 條都是超過 10 分鐘執行上限 (`AdaptiveNavigationContinuityUITests.testSearchKeepsOrClearsSelection_…` 與 `OrderEditInputFocusUITests` 5 條)，逾時前沒有斷言失敗；日誌在每條逾時前累積至少 9 次「App animations complete notification not received」，閒置等待集中在搜尋欄與鍵盤輸入步驟，App CPU 接近 0。
- 依 `ios-ui-tests.md` 重開模擬器後單獨重跑 (每次重開後 Simulate Hardware Keyboard 都會再被勾上，重開後先取消)：
    - `testFocusCardFeeRate_` 開頭的 3 條第 1 次重跑通過。
    - `testSearchKeepsOrClearsSelection_…` 與 `testFocusNotesFromFirstLine_…` 第 1 次重跑仍逾時，第 2 次 (重開後單獨跑) 通過。
    - `testFocusChargedAmountFromLeft_零值輸入_即時取代且失焦保留` 第 1 次重跑 (同一次開機已跑過一條 12 分鐘的逾時案例) 以斷言「付款區段的欄位或檢核訊息未能完整露出並保持穩定」失敗，重開後通過。
- 對照：為判斷失敗是否與 `RootView` 的容器改動有關，主對話暫時把 `RootView.swift` 換成 HEAD 版本 (其他變更不動；量完以備份還原，雜湊與備份一致)，重開模擬器後跑上述未通過的 3 條：`testSearchKeepsOrClearsSelection_…` 與 `testFocusChargedAmountFromLeft_…` 通過，`testFocusNotesFromFirstLine_…` 同樣逾時。HEAD 版本也會逾時，逾時屬環境；斷言失敗那條在 HEAD 版本與本次版本重開後都通過，沒有證據顯示與本次改動有關 (主對話判定，回報使用者)。
- 合併結果 (iPad Air)：247 條，221 通過、0 失敗、25 條略過、1 條既有預期失敗。
- 冷啟動解鎖情境測試在 iPad Air 以 `-test-iterations 3` 執行，3 次重複都通過。
- 回歸前後 `git status --short` 一致。

## 審查紀錄 (5.3)

審查者都未參與第 5 組實作：t9 (codex-luna-max-impl) 唯讀 style 閘門、t17 (`opus-xhigh-reviewer`) 正確性，主對話同時審查 (主對話代選)。兩次審查前後 `git status --short` 與變更檔雜湊一致。

- t9：無必修。建議 1 項 (背景停留那行註解容易讀成在背景停滿 3 秒)：已改。
- t17：無嚴重問題。
    - 重要 1 (7 秒等待要靠「讀取重新開始到看到載入中」少於 1 秒才能分辨重來的讀取，5.4 各跑一次不足以確認)：成立。主對話先以 7 秒版本跑變異檢查，iPhone 17 與 iPad Air 各 3 次，兩條測試全部在 7 秒等待逾時失敗 (實測)；背景上鎖的等待改為 5 秒，冷啟動維持 7 秒 (理由見「延遲成功的本機驗證替身與冷啟動解鎖情境測試」)；5.4 改為兩台各 3 次 (主對話判定)。
    - 重要 2 (背景停留 3 秒的理由在 7 秒門檻下不成立，調整準則只看上限)：成立，改寫「背景上鎖再解鎖的情境測試」的理由，調整準則補下限 (主對話判定)。
    - 次要 1 (iPad 的 4.3 至 5.3 秒數據來源不明)：核對 result bundle，是 4.2 回歸那輪 iPad 3 次 (15 秒版本)，已註明。
    - 次要 2 (冷啟動情境測試的 doc comment 沒寫明是情境測試，4.1 改摘要時拿掉)：已補 `- Note:`。
- 主對話：測試檔沒有超過 100 字元的行；背景上鎖的請求路徑與 t17 讀碼結論一致 (重建後總覽的請求經 Root、主檔目錄到 `OrdersLoadFeature`，因載入中略過)。
- 修正由 t16 實作，t9 複查修正處：無必修、無建議。修正後在 iPhone 17 兩條各 3 次全部通過，間隔：冷啟動 4.29 至 5.30 秒，背景上鎖 2.28 至 3.32 秒 (實測)。

## 變異檢查與回歸紀錄 (5.4)

主對話執行，iPhone 17 (iOS 26.5) 與 iPad Air 11-inch (M4) (iPadOS 27.0) 模擬器，跑在 5.3 修正後的版本。

- 修正後的正常路徑：兩條情境測試在 iPad Air 各 3 次全部通過，間隔：冷啟動 4.27 秒，背景上鎖 2.31 至 2.35 秒 (實測；iPhone 的結果見「審查紀錄 (5.3)」)。
- 變異檢查：暫時把 `OrdersLoadFeature` 的 `loadRequested` 改成只在已載入時略過，讀取效果加 `cancellable(id:cancelInFlight: true)`，讓每次請求都取消進行中的讀取並重新讀取。兩條情境測試在兩台各 3 次，12 次全部失敗，失敗訊息都是失敗訊息的等待逾時 (冷啟動 7 秒、背景上鎖 5 秒)，沒有在其他檢查失敗。量完以備份還原，`OrdersLoadFeature.swift` 的雜湊與變異前一致，與 HEAD 沒有差異。
- 回歸：`LoadFailureReloadLoopTests` (5 條) 與 `AppLockTests` (3 條) 在兩台各 8 條全部通過。第 5 組只改 UI 測試檔，production 程式碼自 4.2 起未變，不重跑完整回歸 (主對話判定)。
- 前後 `git status --short` 一致。
