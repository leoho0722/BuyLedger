# Apple 平台指引 (iOS / iPadOS)

本檔記錄 Apple 平台 (apps/ios) 的硬規則與隱性 gotcha；跨平台通用規範 (產品政策、標點、註解、Commit 風格等) 見 repo 根目錄的 [`CLAUDE.md`](../../CLAUDE.md)，產品介紹與 monorepo 結構見根目錄 [`README.md`](../../README.md)，平台環境設定與 build / test 見本目錄 [`README.md`](README.md)。

## 主要技術棧

- **Swift 6 strict concurrency**：專案層級 `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated` (不是 `MainActor`)。改成 `MainActor` 會讓 SwiftData `@Model` 與 `@ModelActor` 編不過。需要 main actor 才安全的型別請對個別宣告加 `@MainActor`。
- **`Feature.State` 上顯式標註的 `Sendable` 是刻意的編譯期契約，不是冗餘、不可視為「與隱式合成等價」而刪除**：目前有此標註的是 `SettingsFeature.State`／`FxFeature.State`／`QuoteFeature.State`／`OrderEditFeature.State`／`CampaignEditFeature.State`；前四者原本標 `@unchecked Sendable`，查證 SDK 與套件介面後確認豁免範圍內成員本身皆已具備 Sendable 遵循才改為顯式 `Sendable`。
    - 顯式標註把「這個型別必須是 Sendable」寫成編譯期契約：日後若有人往這些 State 塞入非 Sendable 的 reference type，編譯器會立即報錯。若誤判這行與型別不標註時編譯器隱式合成的結果相同而刪掉它，這道契約會被靜默拆除，且不會有任何測試轉紅 (已實測驗證：State 內混入一個非 Sendable 成員後，唯有保留顯式 `Sendable` 標註才會在編譯期擋下，移除標註則整個編譯器檢查連帶消失)。
    - 其餘 `Feature.State` 尚未收斂為顯式 `Sendable`，這是刻意的 Non-Goal (牽涉全庫一致性慣例，不隨單一改動順手做)、不是遺漏；日後統一收斂前，不要把已標註的這幾個當作「已完成一半、應該補完」的訊號回頭反向移除。
- **TCA Reducer body** 使用顯式 `some Reducer<State, Action>`，不可用 `some ReducerOf<Self>` (會 circular reference)。
- **`IPHONEOS_DEPLOYMENT_TARGET = 18.0`**：`EnumeratedSequence` 對 `RandomAccessCollection` 的條件遵循是 iOS 26+ 才具備，`ForEach` 直接吃 `x.enumerated()` 會編不過 (「conformance of 'EnumeratedSequence' to 'RandomAccessCollection' is only available in iOS 26.0 or newer」)。`ForEach(indexed:)` 一律包 `Array(x.enumerated())`，不要為了「現代化」拿掉 `Array()`。

## 文件查證準則

- Apple 原生框架 (SwiftUI、SwiftData、CloudKit、Swift Charts、Xcode 工具鏈) 除了 Context7 之外，另外用 **Apple docs MCP** 對照；兩邊文件矛盾時不可自決，先列差異與建議選項問使用者。

## 架構分層

- **`Core/` 與 `Shared/` 不得引用 `Features/` 下宣告的任何型別**：依賴只能向下，feature 可以用 Core 與 Shared，Core 與 Shared 不能知道任何特定 feature 存在。Core 需要的 API client 放進 Core 的網路層 (`Core/Networking/`，與它組合的 `HTTPClient`／`AppConfiguration` 同層，因為它是 API client 而非 repository)；Core 需要的 fallback 表放進 Core 的領域層 (`Core/Domain/`，因為它唯一的使用者就是領域層型別)。
    - **組裝根是合法例外，但不得住在 Core**：啟動時一次把每個 feature 的相依換成替身的組裝檔 (`App/Testing/BLUITestConfiguration`／`BLUITestHarness`／`BLUITestSeedData`／`BLUITestSeedProfile`／`BLUITestDependencyOverrides`) 認得所有 feature 是它職責所在，但要與呼叫它的啟動設定 (`App/AppLaunchConfigurator`) 同層，不歸在 Core。
    - **文件註解內以反引號引用 Feature 型別的符號連結不算違規**，只有實際程式碼依賴 (作為建構參數、屬性型別、函式簽章等) 才算。
    - 由 `BuyLedgerTests/LayerBoundaryTests` 全樹掃描守門：動態抓出 Features 下全部零縮排的頂層宣告名 (逐次執行時從原始碼擷取，非寫死清單)，比對 Core／Shared 下每一支檔案，命中即失敗並印出檔名、行號與型別名；找不到原始碼根目錄時測試直接失敗，不會略過。
    - **掃描範圍僅涵蓋 `Core/` 與 `Shared/`，`App/` 不在掃描範圍內**：這是刻意的範圍界線，不是疏漏，組裝根本就要認得所有 feature (見上一條)，`App/` 因此沒有需要守的引用邊界；`App/` 下任何檔案引用 Features 型別皆不受此掃描約束。
- **共用層元件的三個判準**：一個 UI 元件要放進 `Shared/DesignSystem/` 前，須同時滿足「不綁 store」「以 closure 與呼叫端溝通」「不依賴任何 Feature 型別」三者，才可從擁有它的 feature 上遷；任一項不滿足就留在該 feature 底下，即使被多個 feature 呼叫。
    - 帶著領域詞彙的元件仍可能滿足三判準：`PaymentMethodEditorSheet` (`Shared/DesignSystem/Components/Forms/`) 以三個布林旗標參數化，領域語意 (無卡／銀行匯款／貨到付款) 由呼叫端決定。**這不代表「有領域語意」本身是進入共用層的理由**，新元件要進共用層前仍須逐一核對三判準，不可比照此例直接放行。
- **綁 store 的畫面只吃自己 feature 的 scoped store**：跨 feature 需要的資料一律走根 feature 單向同步的唯讀投影 (只有根 feature 寫、feature 端不得改)；跨 feature 意圖一律以 delegate action 轉發到根 feature 既有的導覽 case，不新增平行的根 case。純顯示用的值 (如目前選用的 App 語言) 走建構參數，不做投影。
    - **例外只有四個根導覽宿主**：角色是持有導覽路徑並為其目的地建立子 store 的畫面 (`RootView`／`RootTabLayout`／`RootSidebarLayout`／`MoreView`) 才可宣告根 store；白名單為精確集合，由 `LayerBoundaryTests.rootStoreDeclarationsMatchTheNavigationHostWhitelist` 鎖住，多一個或少一個都會失敗。`MoreView` 雖非根版面本身，但與另兩個根版面完全同構 (持有導覽路徑、為七個目的地各自建立子 store)，故一併列入白名單，理由詳見該檔檔頭。
    - **投影的變更監看集中掛在單一處**：`RootFeature.body` 尾端以連續的 `onChange(of:)` 一次同步全部同源投影，不要為每個投影各自散落一條監看；漏掛任一條的症狀是「畫面顯示舊資料而使用者無感」，難以從介面直接發現。

## 建置、測試與開發指令

本平台必守鐵則：

- 絕不退回原生 `xcodebuild` / `xcrun` / `simctl`。
- **任何 build 前先把 build number +1**——凡 build / build-and-run (不論 simulator / device、不論 MCP 工具或 CLI)，執行前必須先跑 `cd apps/ios && agvtool next-version -all`，將 `CURRENT_PROJECT_VERSION` (即 CFBundleVersion，相當於 Android 的 versionCode) 遞增 1；**跑 test 不遞增** (test binary 不會被安裝或散佈，遞增只製造 pbxproj 雜訊)。`agvtool` 是上一條「絕不退回原生工具」的明文例外 (版本管理不在 XcodeBuildMCP 能力範圍)。同一輪驗證中以 `&&` 串接的多平台 build 視為一次、只遞增一次；遞增產生的 pbxproj 變更隨當次工作一併 commit，不可丟棄。
- **CI (`.github/workflows/ci.yml`) 同樣一律經 `xcodebuildmcp` CLI 建置與測試，不因為在遠端就破例退回原生工具**：
    - CI 安裝／釘選該 CLI 版本本身是「絕不退回原生工具」的第二個明文例外 (比照 `agvtool`：`xcodebuildmcp` 無法自我安裝或指定版本，改用套件管理工具 `npm install -g xcodebuildmcp@<釘選版本>` 取得，裝妥後所有 build / test 動作仍一律經由它執行)。
    - 升級該 CLI 時要同步更新 workflow 內的釘選版本。
    - 模擬器一律先查詢可用清單再以識別碼指定，不寫死名稱；找不到符合版本的執行環境時 job 必須明確失敗，不得退回舊版執行環境。
- **發版改 marketing version 直接編輯 pbxproj 的 `MARKETING_VERSION`**，不要用 agvtool new-marketing-version：它會報 Cannot find YES 且不會更新 pbxproj (本專案版號在 build settings，Info.plist 無版號 key)。
- iOS 與 iPadOS simulator build 共用同一份 `DerivedData/.../XCBuildData/build.db`，**不能並行**——請序列化 (`cmd1 && cmd2`)，否則 `database is locked`。
- 詳細 build error 要加 `xcodebuildmcp --log-level error <subcommand> ...`，否則 CLI 只回 trailing `BUILD FAILED`。
- simulator 名稱不要寫死，跑 build-and-run 前先 `xcodebuildmcp simulator list-sims` 查當前可用名稱。
- **跑 snapshot 測試前把模擬器外觀鎖淺色** (`xcodebuildmcp simulator-management set-appearance --mode light`)：模擬 OS 的自動外觀入夜會切深色，淺色 baseline 會整批 false-fail (差異圖整張變色即此因，非程式碼回歸)。
- **erase 模擬器不會讓 `DatePicker` 日期格式退化**：2026-08-03 實測 (Xcode 26.6 / iOS 26.5)，erase 後日期膠囊仍為 `2026年8月3日`，且完整單元測試與 erase 前逐項相同 (691 passed / 4 failed、失敗集合不變)。此處先前記載的「erase 會退化成數字短式且無已知復原法」已被推翻，勿再據此迴避 erase。
    - 進 Settings 檢查設定可用 `xcodebuildmcp ui-automation` (`simulator launch-app --bundle-id com.apple.Preferences` 進入 App 後 `snapshot-ui`／`tap`／`touch` 導覽)，不需要 `computer-use` (其 macOS 輔助使用權限不一定已授權)。
    - 但 Settings 的**開關與滑桿不一定會被 expose 成可點目標** (實測「放大文字」頁的開關與字級滑桿都查不到 ref)，要改系統層設定時別假設走得通。
- **工具列的 prominent 玻璃按鈕 (`.borderedProminent`) 會讓 snapshot 離屏渲染整張變黑**：實跑正常、只有測試渲染路徑壞。含此類按鈕的畫面其 snapshot 測試要改用 `.image(drawHierarchyInKeyWindow: true)` 於 key window 渲染 (參考訂單編輯的兩個 baseline 測試)。
- 模擬器跑 App 用 `build-and-run`，不要先 `build` 再 `build-and-run`。
- **要在特定 Dynamic Type 字級下驗證版面，用啟動參數而非改系統設定**：`--launch-args '-UIPreferredContentSizeCategoryName' --launch-args 'UICTContentSizeCategoryAccessibilityXXXL'` (accessibility5)。⚠ **常數名寫錯不會報錯、只會靜默無效** (`...AccessibilityExtraExtraExtraLarge` 是錯的，正確為 `...AccessibilityXXXL`)，故套用後必先截圖確認字級真的變了再往下驗。
- **`-only-testing` 跑 UI 測試要指定 `BuyLedgerUITests` scheme**：`BuyLedgerUITests` target 不在 `BuyLedger` scheme 的 test plan 內，用 `--scheme BuyLedger` 會回「isn't a member of the specified test plan or scheme」。
- **UI 測試的文字輸入用 `XCUIElement.typeText`、不要用 `ui-automation type-text` 打數字**：後者走 Mac 當前輸入來源，注音模式下數字鍵會被轉成ㄅㄆㄇ (`111` → `ㄅㄅㄅ`)；`toggle-connect-hardware-keyboard` 需要 osascript 輔助取用權限、未授權時無法繞過。
- **TCA 的傳遞相依若要在原始碼中直接具名使用 (如 `@Shared`／`SharedKey`／`InMemoryKey`)，必須在 Xcode 把該套件產品加入連結清單，「傳遞相依」本身不足以讓連結器找到符號**：`ComposableArchitecture` 透過 `@_exported import` 讓 `Dependencies`／`CasePaths`／`Perception`／`PerceptionCore`／`Sharing` 等傳遞相依的 API 在原始碼層可見，但編譯只看得到型別宣告、**連結階段仍需要該套件的實際產物**。症狀是編譯過得了、連結才炸 (`Undefined symbols for architecture arm64: "nominal type descriptor for <Package>.<Type>"`)。修法：在 Xcode 把該套件的產品加入 `BuyLedger` 與 `BuyLedgerTests` 兩個 target 的 Package Dependencies／Frameworks 連結階段 (`Dependencies`／`CasePaths`／`Perception`／`PerceptionCore`／`Sharing` 皆已比照辦理)；**加 SPM 產品一律用 Xcode 操作、勿手改 pbxproj**。
- ⚠ **Xcode 26 把「沒有宣告 traits」的套件加入連結清單時，可能自動在該套件的 `XCRemoteSwiftPackageReference` 插入一個空的 `traits = ( );`，導致 SPM 拒絕解析、所有 build 卡在依賴解析階段** (症狀：`Could not resolve package dependencies: Disabled default traits by command-line trait configuration on package '<name>' that declares no traits`，數秒內即失敗，與程式碼改動無關)。已知踩雷套件：`swift-sharing`；`swift-composable-architecture` 也有同樣空 `traits = ( );` 卻不受影響，因為它本身有宣告 traits，空選擇在該情境合法。加入新套件產品後若整個專案突然連依賴解析都過不了，先檢查該套件參照是否被插入這個空區塊，移除該 `traits` 區塊即可解除。
- ⚠ **macOS BSD `sed -E` 清尾隨空白勿用 `[ \t]`**：POSIX 括號表達式內反斜線沒有特殊意義，`[ \t]` 會被解讀成三個字面字元的集合 (空格、反斜線、小寫 t)，不是「空格或 tab」。對 Swift 檔跑 `sed -i '' -E 's/[ \t]+$//'` 會把每一行行尾剛好是小寫 t 的地方連同該字元一起吃掉 (`swift`→`swif`、`default`→`defaul`、`count`→`coun`)，且落在註解或字串字面值時編譯器不會抗議，是會靜默損壞內容的坑。改用 POSIX 字元類 `[[:space:]]+$`，或直接放入實際 tab 字元。

## App 進入點與平台導覽

動到這層程式碼時請遵守：

- **啟動時的服務初始化集中在 `AppLaunchConfigurator.configure()`** (Firebase Analytics / Crashlytics / Performance)——iOS / iPadOS 的 `AppDelegate` 在 `didFinishLaunching` 呼叫它，新增啟動設定請加在這裡，不要散落各進入點。Firebase 依賴 pbxproj 的 `OTHER_LDFLAGS = "-ObjC"`，不可移除。
- **跨頁觸發新訂單**請使用 `RootFeature.Action.startNewOrder`：reducer 會同時把 `selectedTab` 切到 `.orders` 並把 `OrdersFeature.State.editOrder` 設成空白草稿。從非 `.orders` 分頁直接設 sheet state 會發生 view-not-in-hierarchy 的 race——`.sheet(...)` 修飾子掛在 `OrdersView` 上，當下不在 hierarchy 就不會 mount。
- **`OrdersView` 的 `.sheet(item: $store.scope(state: \.editOrder, action: \.editOrder))`** 一律掛在 `OrdersView` 外層，iPhone / iPad 共用——不可移到平台分流後的子 view 裡。
- **兩種尺寸都不要用 `.toolbar` 的 `.bottomBar`**：批次／選取類操作一律放 `.primaryAction` 等頂部 placement，筆數等資訊由 `navigationTitle` 承載 (compact 與 regular 共用 `OrdersFeature.State.navigationTitleKey`)。
    - compact：`RootTabLayout` 的底部 tab bar 會蓋掉 `.bottomBar`，工具列項目在實機上看不到。
    - regular (iPad)：可拖曳視窗的下緣可能超出螢幕而遮住整條工具列。
- **訂單多選工具列與可勾選列由單一定義提供** (`OrdersToolbarContent`／`OrderSelectableRow`，位於 `Features/Orders/Components/`)，供 compact／regular 共用；不可回頭讓兩種尺寸各自維護等價實作 (此前 compact 版勾選圖示對輔助技術隱藏且帶 `.isSelected` 特徵、regular 版兩者皆缺的漂移即為前車之鑑)。
- **帳本保護「進入背景即上鎖」的觸發訊號是 `\.scenePhase` 的 `.background`／`.active`，不是 `AppDelegate` 的 `applicationWillResignActive`／`applicationDidBecomeActive`**：後兩者在採用 `UIApplicationSceneManifest` 的 SwiftUI 場景生命週期 App 中從不被呼叫 (轉場交由場景層而非 App 層)，且於 iOS 26.0 已 deprecated；誤掛在那裡的程式碼會完全零生效，這是本專案踩過的實際案例，不是理論風險。
    - 鎖定／解鎖動作由 `BuyLedgerApp.body` 的 `onChange(of: scenePhase)` 呼叫 `AppScenePhaseCoordinator.handle(newPhase:send:)` 轉送：`.background` 送出 `AppLockFeature.Action.appDidResignActive` (上鎖)，`.active` 送出 `.appDidBecomeActive` (嘗試解鎖)。
    - `AppScenePhaseCoordinator` 抽成獨立型別是刻意的：`Scene.body` 無法在單元測試中直接觸發，抽出後才能以替身斷言「哪個場景轉換觸發了哪個 action」(見 `AppScenePhaseCoordinatorTests`)。**日後任何「畫面／系統事件 → 動作」的接線都要有對應測試**，不能只靠程式碼看起來合理。
    - **背景上鎖只保證回到前景需要驗證，不保證多工切換器縮圖不含內容**：`.background` 觸發的畫面替換 (換成 `AppLockView`) 與 iOS 系統擷取切換器縮圖的時間點兩者先後順序無法由 App 端保證，縮圖仍可能短暫含有背景化前最後一幀的內容。這是已知取捨、非疏漏；若日後需要更強保證，要另以獨立 `UIWindow` 的遮蔽層處理，不是調整這裡的接線就能達成。
- **啟用帳本保護前必須先通過一次驗證，不可先開關再驗證**：若開關可以在未驗證的情況下開啟，會出現「使用者開了保護、下次啟動卻無法通過驗證」的狀態，而那在 App 內無法自救，只能重裝並失去資料。`AppLockFeature.enableToggled(true)` 因此先呼叫 `BiometricAuthClient`，驗證成功才把 `isProtectionEnabled` 設為真並持久化；失敗、取消或裝置不支援時開關維持關閉並顯示對話框。設定頁的 Toggle 不可用一般的 `$store.xxx` 雙向繫結 (會在驗證完成前就把開關撥到開)，改用自訂 `Binding`：`get` 讀已確定生效的值、`set` 只送出意圖，讓驗證失敗時開關自動彈回關閉。
- **App 內切換語言後的根分頁 `navigationTitle`**：iOS 18+ 不會可靠地讓 `navigationTitle` 隨 `\.locale` 重新解析 String Catalog。Dashboard、Orders、Campaigns、Insights、More 與 Settings 一律以必填 `language` 參數呼叫 `rootNavigationTitle(_:language:)`，由 `AppLanguage.localized(_:)` 先從對應 `.lproj` bundle 解析再交給原生 `.navigationTitle(_:)`；Orders 的多選三態 key 必須由 `OrdersFeature.State.navigationTitleKey` 計算屬性衍生。RootView 僅保留 `\.locale` 注入給一般 SwiftUI 文案與格式化器；`Tab(LocalizedStringKey)` 不需要此 workaround。
- **`Text(字串變數)` 不會本地化 (英文模式露中文)**：`Text("字面值")` 與 `Text(LocalizedStringKey(x))` 會走本地化，但 `Text(someString)` (參數型別 `String`) 走 verbatim init。凡把「固定中文詞」經 `String` 變數丟進 `Text` / `Label` / `navigationTitle` 都要包 `LocalizedStringKey(...)`——可重用元件 (`BLBadge`) 內部已比照，`BLStatusPill` / `BLProgressBar` / `BLDonutChart.centerTitle` 本就有包。帶插值的中文 (如 `\(count) 件進行中`) 必須走 `Text(LocalizedStringKey("\(count) …"))`——SwiftUI 的 `Text(LocalizedStringKey)` 才會隨注入的 `\.locale` 解析;**不可用 `String(localized:locale:)`**，它走系統語言 bundle、不吃 App 內語言切換 (Dashboard KPI delta 曾因此在英文模式露中文)。若字串經參數傳遞，把參數型別設為 `LocalizedStringKey` (不是 `String`)、由 `Text` 端解析 (參考 `DashboardView.kpiTile(delta:)`)。**使用者資料 (主檔名稱、`customer.name`)、格式化數字/日期維持 verbatim**、不可包 `LocalizedStringKey`。
- **新增任何 UI 字串都要同步補 `Localizable.xcstrings` 的 `en`**：新寫的中文字面值 (含 TCA `AlertState`／`TextState`、`Button`／`Text`／`accessibilityLabel` 等) 若沒補英文，英文模式會露中文 fallback (F1 捨棄變更 alert 曾漏)。`AlertState`／`TextState` 一樣走 catalog 本地化 (資料來源同 `Text(LocalizedStringKey)`)，補齊 `en` 即修好。手動補 catalog 用**文字插入** (在 `"strings"` 物件內加展開格式的 entry)、**不要全量 `json.dump` re-serialize**：`.xcstrings` 是 Xcode 自訂序列化 (部分 entry 單行、部分展開)，全量重寫會格式不吻合、產生巨量 diff 且 Xcode 下次開檔又重排。`LocalizationCatalogTests.catalogContainsCompleteTraditionalChineseAndEnglishValues` 除了驗 catalog 內既有條目完整，**也會掃描程式碼中的使用者可見字串字面值、比對是否已收錄**，抓得到「code 有用但 catalog 沒收錄」的漏字並指名字串與行號；掃描以結構性規則收錄候選字串 (任何未加標籤字串引數的大寫開頭型別呼叫，如 `Text(...)`／`Menu(...)`／日後新增的 SwiftUI 顯示元件皆自動涵蓋，**型別呼叫層級**不需回頭補列舉清單) 再套排除規則過濾；**但文字類 modifier (如 `.help(...)`) 與回傳 `LocalizedStringKey`／`String` 的 display property 這兩類仍是列舉清單**，新增這兩類時須同步補程式碼內的 `visiblePatterns`／`displayProperties`，新增字串仍建議人工確認有進 catalog，但漏補時測試會主動抓到、不必完全仰賴人工。
    - 已知盲區：多行 `"""` 字面值若直接作為型別呼叫的引數 (如 `Text("""…""")`) 卻不落在文字類 modifier／display property 的範圍內，掃描抓不到；逐字元掃描會把開頭 `"""` 拆成一個空字面值與一個內容字面值，型別呼叫規則只命中前者 (隨即被排除)。目前只有落在 display scope 內的多行字面值才會被收錄，新增此類寫法時仍需人工確認已補 catalog。

## 資料層與 Dependency 注入

- **`liveValue` 不自動 seed sample 資料**——使用者首次啟動是真正的空狀態 (Dashboard 顯示 `onboardingHero`、Insights 顯示空狀態 `ContentUnavailableView`、Orders 顯示「沒有符合條件的訂單」)。
- **`previewValue`** 使用 in-memory container 並傳 `seedSampleOrdersIfEmpty: true`，讓 SwiftUI Preview 與 snapshot 測試看得到內容。
- **`LedgerOrder.sampleOrders`、`FxRateSnapshot.fallback` 與 `FxRates`** 僅供 Preview / 單元測試 / `previewValue` 使用，runtime path **不應讀取**。
- **`@ModelActor` init 帶 main actor 隔離**：actor 實例必須在 `async` context 才能建立。參考 `OrderRepository.PersistenceInstanceProvider.instance()` 用 `MainActor.run { ... }` 跳上 main 取得 actor 後再回到原 task。
- **多個 repository 共用單一 `ModelContainer`**：`Core/Dependencies/` 下所有 `*Repository` 的 `liveValue` 一律走 `PersistenceContainer.shared`，**不可各自建立 container**；建立 container 的工廠函式已收斂為 `private`，唯一呼叫者是 `PersistenceContainer` 內部的 bootstrap 解析。同一 process 內並存多個 container (即使底層 SQLite 同名) 會造成 SwiftData 內部狀態錯亂。
- **Repository 一律以 type-based `@Dependency(SomeRepository.self)` 注入**——新 repo 不再新增 `DependencyValues` keyPath；reducer 在 `// MARK: - Dependency Properties` 宣告 `@Dependency(OrderRepository.self) private var orderRepository`。
- **訂單持久層寫入區分建立／更新意圖，不可用同一入口覆寫**：`OrderPersistence.create(_:)` 偵測到既有同編號資料列時拋出 `WriteError.identifierCollision` 且不寫入任何內容；`OrderPersistence.update(_:)` 才維持既有 upsert 語意 (找不到則插入)。`OrdersFeature.resolveWriteResult` 依實際走的插入／更新分支純計算寫入意圖 (不觸碰 state)，`saveTapped` 直接採用該值呼叫 `OrderRepository.createOrder`／`saveOrder`，不可由呼叫端自行重算 `editState.original == nil` (兩者在 `original` 存在但已不在 `state.orders` 時會分歧，例如並行刪除或詳情堆疊過期)；新增訂單寫入呼叫點務必比照，否則撞號會退回靜默覆寫。建立意圖 (連同其餘四條訂單寫入路徑) 走先寫後改：落盤成功才由 `orderSavePersisted` 以 `applyWriteResult` 套用到畫面狀態，失敗時 state 從未被樂觀插入過，故不需要回滾快照；合併路徑 (`mergeSourceIDs` 非空) 是既有的樂觀更新 + 快照回滾例外，維持 `applyEditDraft` 立即套用，不在此列。
    - 訂單持久層存取一律經 `OrderRepository.PersistenceInstanceProvider` 取得的單一長命 `OrderPersistence` 實例，不可回頭讓每個操作各自建立實例：資料表無唯一性約束 (CloudKit 限制)，各自實例會讓同編號並發寫入各自查無、各自插入。
    - 長命實例代表 `modelContext` 也長命、autosave 關閉：`update`／`upsertAll`／`mergeOrders` 的 `modelContext.save()` 失敗時必須先 `modelContext.rollback()` 再 rethrow，否則已套用的 `apply()`／`insert()` 會停留在 context 的 pending 狀態，被下一次成功的 `save()` 一併夾帶落盤 (`FetchDescriptor` 預設含 pending 變更，連讀取都看得到)。
    - 訂單編號一律用完整長度的隨機識別碼存入 `LedgerOrder.id`，不得在寫入前截短；需要短碼顯示時用 `LedgerOrder.displayID` (顯示層計算屬性，僅在儲存值超出可讀長度時才截短)，不回頭改變儲存值。
- **四種主檔 (訂單來源／商品類別／付款方式／對帳狀態) 以共享的記憶體儲存 `LookupCatalog` 作為單一來源**：`LookupManagementFeature` 與 `OrdersFeature` 皆以 `@Shared(.lookupCatalog)` 指向同一份 `LookupCatalog`，任一端的新增／移除／更名寫入後，另一端下一次讀取即自動反映，不再需要手動同步兩份副本。CRUD 仍走 `LookupManagementFeature` (以 `LookupKind` 分流共用同一份 reducer/view)，它負責目錄寫入與各自的 DB 主檔表持久化；`RootFeature` 仍攔截 `renameRequested` 處理目錄不涵蓋的「訂單表 cascade」(更名時把已存在訂單中引用該值的欄位一併更新)，這段落在單一分支、透過 `LookupKind.isReferenced(by:name:)`／`LookupKind.renamingReference(in:from:to:)` 分派，不含手寫的 if/switch。**新增第五種主檔種類時，凡未窮舉新分支的 switch 皆是編譯錯誤而非執行期靜默不同步**：實測涉及範圍不只這兩個 cascade 方法，`LookupKind` 其餘顯示文案 switch、`LookupCatalog`、`LookupManagementFeature`、`LookupManagementView` 共 4 支檔 23 處編譯錯誤皆由編譯器逐一標出待補處，`RootFeature`／`OrdersFeature` 不受影響。付款方式編輯成功則另走下方的 `paymentMethodEditSucceeded` 不變式 (旗標權威覆寫語意特殊，不循 `renameRequested` 這條路徑)。
    - **協定遵循不碰型別主體**：`NameLookupRecord` 協定遵循一律放在各記錄檔尾端的 extension (`static func matchingName(_:) -> Predicate<Self>`)；碰動型別主體本身即使邏輯等價，也會改變 SwiftData 的 attribute fingerprint，讓保留版本的舊 shadow 對不上、破壞 migration。
    - **共享狀態機制 (`@Shared` + `.inMemory` key) 的使用邊界僅限主檔目錄一處**：`LookupCatalog` 是目前全庫唯一一處採此機制的跨 feature 狀態，不得因為好用就順手擴及其他狀態 (如客戶彙總、開團列表)；這些仍走既有的「`RootFeature` 攔截子 feature action 手動同步 in-memory 副本」模式，改動前需重新評估是否真的符合「多個 feature 需要讀寫同一份資料」的前提，不是預設路徑。
    - **編譯期義務覆蓋資料一致性、不覆蓋可達性**：`LookupKind` 的窮舉 switch 只保證新增主檔種類時 cascade 正確性 (漏補是編譯錯誤)；`RootFeature.State.lookupManagements` 的四元素初始陣列與 `MoreRoute` 的四個主檔路由皆為手寫字面值，不受此窮舉保護，加第五種主檔後編譯仍會成功，但會靜默沒有管理畫面與入口。`MoreRoute` 不涵蓋第五種主檔是 design 明列的 Non-Goal；`lookupManagements` 陣列則單純是此邊界未涵蓋到的範圍，非刻意決策。
- **付款方式旗標正規化只有一個來源**：`LedgerOrder.applyingPaymentMethodFlags(...)` 是手動編輯 (`OrdersFeature.resolveWriteResult`) 與回溯更正 (`LookupManagementFeature.editConfirmed`) 共用的唯一規則；折抵上限、對帳狀態清空、貨到付款運費三條規則都在此，兩端不得另寫。
- **付款方式主檔更新與訂單重算是同一次操作**：`PaymentMethodPersistence.applyEdit` 以單一 context、單次 `save()` 完成兩者，任一步失敗都 rollback 整個 context；`PaymentMethodRepository.applyPaymentMethodEdit` 只轉呼叫，不拆成兩次寫入。
- **確認筆數與重算對象同源**：兩者都取自同一個 `PaymentMethodEditPlan` 的一次 fetch/filter，不可各算一次。
- **確認閘門的邊界固定**：取消確認時主檔旗標也不套用；零筆受影響，或只是純改名且旗標未變更時，不出現回溯確認。
- **付款方式編輯的跨檔不變式**：`LookupManagementFeature` 取樣／確認 (同時寫入共享的 `LookupCatalog`) → `PaymentMethodPersistence` 原子落盤 → `RootFeature` 攔 `paymentMethodEditSucceeded` 純轉送同一份已正規化 payload → `OrdersFeature` 以此 payload 處理 `paymentMethodFlagsApplied`、把旗標套用到既有訂單列且不再次落盤；四檔要一併檢視。
- **付款方式持久層的具名例外**：`PaymentMethodPersistence.applyEdit` 是第二個從非 `OrderPersistence` context 寫 `OrderRecord` 的案例，第一個是 `CampaignPersistence.delete`。測試 `PaymentMethodPersistenceTests.applyEditPersistsMasterAndNormalizedOrdersTogether` 已先暖機長命 `OrderPersistence` 再讀回並通過；因此在「訂單側只更新既有列、不插入、找不到 id 即整批拋錯」的限制下，已確認長命 context 的 stale read 風險不可達。若任一限制改變，須重跑此測試並重新評估例外。
- **`LedgerOrder` 是 immutable struct**：cascade rename 等要改任一欄位時必須用 memberwise init 重建整筆 (參考 `LedgerOrder.swift` 內的 `renaming*`／`removingCampaign` 系列擴充方法)，不可就地 mutate。
- **Reducer body 內呼叫 State 上的 instance method** 必須走 `store.state.method(...)`，不可透過 `@dynamicMemberLookup` 的 `store.method(...)`。
- **開團是否已收單的日粒度判定三處共用單一實作，不可各自重寫**：`CampaignFeature`／`OrdersFeature`／`OrderEditFeature` 載入開團時一律呼叫 `Campaign.evaluatingAutoClose(asOf:calendar:)` 取得目前狀態，不得各自另寫日期比對邏輯
    - 日粒度邊界是結單日隔天 00:00：結單日當天仍算進行中，隔天才轉為已收單
    - `asOf`／`calendar` 一律吃 reducer 注入的 `date.now`／`calendar`，不呼叫系統時間／行事曆 API
- **營收歸屬單一入口**：總覽本月損益、分析走勢與成本結構、客戶累計消費一律呼叫 `LedgerOrder.revenueAttributionOrders(from:)`，不得各自寫 predicate。
    - 類別／開團彙總維持另一口徑 (`contributesToCategoryBreakdown`)；兩套口徑刻意並存，不可互相替換。
- **合併來源的守門條件取自現存結果**：只要現存的合併結果把訂單列為來源，該來源就不得計入營收歸屬。
    - 合併結果被刪除後，來源恢復計入；不得改用寫在來源訂單上的永久標記。
    - 合併結果被取消時，來源維持排除且該筆營收不計；這與刪除結果後恢復計入是刻意不同的規則。
- **客戶列的資格與彙總分開取值**：客戶頁成員資格、initials、tier 與最近訂單日期取自全部訂單。
    - 金額與筆數取自營收歸屬子集，讓訂單全部取消的客人仍在名單且顯示零元。
- **成長率的百分比與方向必須同源**：`DashboardStats.ratio` 與 `InsightsStats.trendDelta` 都以同一個本期減上期的差額決定方向，分母取 `abs(previous)`。
    - 在 `InsightsStats.trendDelta` 中，呈現量級本來就使用 `abs(ratio)`，分母正負號不改變數學結果；絕對值分母的有效行為修正發生在 `DashboardStats.ratio`。
- **開團刪除的三件事必須在單一 `modelContext` 交易內完成，不可拆成多次 `save()`**：`CampaignPersistence.delete(id:name:)` 於同一次呼叫內移除 `CampaignRecord`、自所有訂單的 `campaignNames` 剝除該名稱、移除對應的 `CampaignReminderRecord`，最後單次 `save()` 落盤，任一步驟失敗則整體不生效；`CampaignRepository.removeCampaign` 只轉呼叫，不拆分。行事曆事件的移除排在本機刪除成功之後，其失敗不回滾本機刪除，但必須以 `campaignWriteFailed` 告知使用者。
    - 這是跨 `CampaignPersistence`／`CampaignRepository`／`CampaignFeature`／`RootFeature` 四檔的不變式：`CampaignFeature` 收到刪除結果後才更新畫面狀態 (先寫後改)，`RootFeature` 再攔截 `campaignDeleted` 同步 `OrdersFeature.State` 的 in-memory 訂單與 `campaigns` 副本；新增或調整開團刪除邏輯時四檔要一併檢視。
- **`CampaignRepository.live` 每次操作以 `makePersistence` 新建 `CampaignPersistence` 實例 (per-operation context)，故 `delete`／`upsert` 的 `modelContext.save()` 失敗不需要 `rollback()`**：失敗時該次呼叫的 context 隨實例一起丟棄，不會有 pending 變更留到下一次操作。
    - 這與上方訂單持久層「長命實例的 `save()` 失敗須先 `rollback()`」方向相反，成因是兩者的實例生命週期不同 (開團側逐次新建、訂單側單一長命實例)；若日後把開團側改成比照訂單側共用長命實例，須同步補上 `rollback()`，否則會重蹈訂單持久層曾踩過的坑。

## 生成式 Data Model (Core/Domain/Generated/)

`Core/Domain/` 的資料形狀由 `shared/data-model` 的 `datamodel-gen` 產生器產出 (跨平台 schema → Swift)，**不再手寫**。跨平台規範見 root [`CLAUDE.md`](../../CLAUDE.md) 的「跨平台 Data Model」；Apple 端 gotcha：

- **生成檔在 `Core/Domain/Generated/<Type>.generated.swift`**——含型別主宣告 (stored properties / cases、由 trait 對應的 conformances + 全域 `Sendable`、必要時的顯式 init)。**不可手動編輯**；要改形狀請改 `shared/data-model/schema/` 後 `cd shared/data-model/generator && bun run generate`。
- **生成檔在磁碟上預設唯讀** (`generate` 會 chmod `0o444`)——Xcode 編譯只讀取、不受影響；重生成直接再跑 `bun run generate` 即可 (會自動解鎖重寫)，真要手動檢視才 `bun run unlock`。若 IDE 提示檔案唯讀無法存檔，代表你正試圖手改生成檔——應改 schema 重生成。
- **手寫邏輯放同名 extension 檔**——例如 `LedgerOrder.swift` 只含 `extension LedgerOrder { ... }` 的 computed properties、display title、static 集合、自訂 `Codable`；無剩餘手寫邏輯的型別 (如 `Money`、`LedgerCustomer`、`PaymentMethodInfo`) 沒有手寫檔，由生成檔完整提供。
- **全型別補 `Sendable`**——emitter 對所有生成 struct / enum 無條件加 `Sendable` (補上編譯器本已合成、舊源碼漏標的標註)；`sendable` 不是 schema trait，不要寫進 schema。
- **`serialization: custom` 的型別** (`CurrencyCode`、`LedgerOrderItem`) 生成宣告不含 `Codable`，自訂 `Codable` 留在手寫 extension，保住既有編碼形狀 (如 `LedgerOrderItem` 刻意不寫出 `id`)。
- **提交前跑 `bun run check`** (於 `shared/data-model/generator`) 確認生成檔與 schema 同步 (exit 0)；生成檔與 schema 一起 commit。
- **新增／刪除 Domain 型別後以 iOS + iPadOS build 驗證**——`Core/Domain/` 是 file system synchronized group，新檔 (含 `Generated/` 子資料夾) 自動納入；務必 iOS + iPadOS 各 build 一次確認拾取正確。

## SwiftData Schema 與 Migration

Schema 採版本化 `VersionedSchema` + `BuyLedgerMigrationPlan`，設 migration floor，全定義在 `Core/Persistence/BuyLedgerSchema.swift`。**改 schema 前先 invoke `/swiftdata-schema-migration`** 取得逐步指引 (新增版本 enum、凍結舊版 shadow、append stage、更新 `PersistenceContainer.make`)。

- **shadow 凍結**：floor 以外每個保留版本必須把當時的 `@Model` 凍結為內嵌 shadow，保住當時 attribute fingerprint。
  - target 的 `models` 引用 top-level `@Model`；改動 top-level 型別會破壞舊版指紋、導致 migration 失敗。
  - 現況 floor V15、target V17：V15 把對帳狀態改名前的 `OrderRecord`／`VerificationStatusRecord`，以及 `SyncMeta`／`SyncQueueItem` (V17 移除同步兩表) 凍結為影子；V16 把 V17 變動前形狀的 `OrderRecord` 與 `SyncMeta`／`SyncQueueItem` 凍結為影子。凍結後的 shadow 註解一律寫明「僅為保住該版本指紋而凍結，runtime 恆為空、勿新增讀寫」，不得保留描述已移除機制 (如 HLC、tombstone) 的舊敘述。
- **遷移方式**依改動類型選擇：
  - 加欄位／加表、**丟棄零列 entity**、**加索引 (`#Index`)** → `.lightweight`；改既有欄位型別 → `.custom` dump-and-restore。
  - 改欄位名 → `@Attribute(originalName:)` (lightweight，底層欄位名不變)。
  - 改 `@Model` 類別名 (=entity 名) → 必須 `.custom`：SwiftData **無 entity 級 originalName**，類別改名等同新 entity、舊表資料不自動帶入。凍舊 shadow 後於 `.custom` 的 `willMigrate` 讀舊 entity 暫存 (`nonisolated(unsafe) static`)、`didMigrate` 寫新 entity (兩 closure 各只見舊／新 schema)。
  - **stage 種類拿不準時以落地 store 遷移測試判定，不要用文件推測**：V16 → V17 曾評估「改變照片欄位儲存位置」是否仍算輕量，靠 `SchemaMigrationTests` 的落地 store 測試證實 `.lightweight` 可行才採用，未改用 `.custom`。
- **移除舊版本是單向操作**：forward-only，移除會把 floor 往上抬，停在低於新 floor 的 store 失去遷移路徑；啟動會保留原始檔案並呈現阻斷式復原畫面，等待後續版本補回遷移路徑。
  - 只在確定無 store 停在被移除版本時才可移除；上架後此前提幾乎不成立、須保留完整版本鏈。
  - 「已在 target 就安全」是 per-device 結論：目前 CloudKit `.disabled` 故成立；啟用 sync 前須重評 (離線舊版第二台裝置同樣可能無法遷移，且同步影響需另行設計)。
- **持久層 fallback**：on-disk store 無法開啟時會保留檔案、退到 in-memory 並阻斷正常介面；要恢復資料須補正確 migration stage，或由使用者明確確認後搬移 store 以改用空白資料庫。
- **`@Attribute(.externalStorage)` 對 `[Data]` 陣列型別實測不生效**：以 300 KB × 3 張寫入僅帶此 attribute 的 `[Data]` 屬性後，store 目錄下未出現任何外部 blob 目錄 (`_SUPPORT`／`_EXTERNAL_DATA` 等)，位元組仍留在 `-wal` 內。此 attribute 只在文件記載的單一 `Data` 屬性上有效，不要對陣列型別重複嘗試；讓「讀取不帶照片位元組」成立要靠 `FetchDescriptor.propertiesToFetch` 明確排除該欄位，不能依賴外部儲存這層。
- **加索引不需凍結 shadow，既有 store 仍可正常遷移 (已固化為永久測試，適用範圍見下)**：先前以「無索引 schema 建立的 store，用有索引的 schema 直接開啟仍成功不觸發遷移」推論『`#Index` 不計入 schema 指紋』，此舉證方式不成立；對照組顯示即使改動明顯會讓指紋不同的欄位 (新增一個帶 default 值的欄位)，只要 stages 留空同樣開得起來，可見「開得起來」只證明 SwiftData 會為未登記的改動自動推導輕量遷移，不能反推指紋未變。操作面結論改以生產情境模擬驗證，並固化為永久測試 `SchemaMigrationTests.addingIndexDoesNotRequireFrozenShadow()`：store 建於無索引時期，floor 宣告之後才加上 `#Index`，既有資料仍能正常開啟且完整讀回；因此新增或調整索引不需要為此凍結對應版本的 shadow，也不會抬高既有 store 的遷移成本。
  - **這條通則的實證範圍僅涵蓋「單一 `#Index` 加在單一 `String` 欄位、且不拉新版本」這一個樣式**：該測試的探針型別只對一個 `String` 欄位加單欄索引 (`#Index<ProbeRecord>([\.identifier])`)，加索引前後的 `versionIdentifier` 刻意相同。多欄複合索引 (`[\.a, \.b]`)、非 `String` 型別的欄位、以及伴隨拉新版本的索引調整都在這份證據之外，套用前仍須依上面「stage 種類拿不準時以落地 store 遷移測試判定」補一條落地 store 測試，不可直接引用本條結論當背書。
  - 現行 `OrderRecord` 的 `#Index<OrderRecord>([\.id], [\.date])` 含一個 `Date` 欄位索引，已超出上述探針測試的範圍，因此它不靠這條通則背書：其安全性由 `SchemaMigrationTests` 的 `v16StoreMigratesToV17PreservingOrdersAndPhotos` 與 `v15StoreMigratesThroughV16ToV17` 兩條落地 store 遷移測試直接守住。
- **訂單照片位元組不隨訂單列常駐**：`OrderRecord.photos` 不常駐於清單讀取路徑，`OrderPersistence.fetchAll()` 以 `propertiesToFetch` 明確排除該欄位，回傳的每筆訂單照片皆為空陣列 (空陣列不代表沒有照片)。任何新增的「讀取整表／多筆訂單」路徑，若會被清單畫面等高頻場景呼叫，都不得觸碰 `photos` 欄位，否則會讓這層排除失效、把位元組又拉回記憶體。真正需要照片時走 `OrderPersistence.fetchPhotos(id:)` 依訂單編號按需讀取。
- **`OrderRecord.apply(_:)` 永不寫入照片**：批次改狀態、主檔與開團 cascade 更名重建訂單、合併時更新既有訂單、一般 upsert 皆經 `apply(_:)` 落地，此路徑不觸碰 `photos` 欄位，故上述操作對已存照片一律無副作用。照片實際落地的入口只有「插入」與「顯式覆寫」兩種：插入分支一律經 `OrderRecord.init(order:)` 寫入呼叫端提供的照片，`create(_:)`、`update(_:)`／`updatePersistingPhotos(_:)` 找不到既有列時的插入語意、以及 `mergeOrders(newOrder:consumedIDs:)` 的新單插入皆屬此類；既有列的顯式覆寫則只有 `updatePersistingPhotos(_:)` 一處，於 `apply(_:)` 之後另行以 `existing.photos = order.photos` 覆寫。新增讀寫路徑時，不要圖方便把 `photos` 併進 `apply(_:)` 的欄位清單，會讓「漏改路徑照片消失」重新變成可能。

## 外部 API 實作

- **兩把外部 API 金鑰 (`EXCHANGE_RATE_API_KEY`、`OLLAMA_API_KEY`) 內嵌於產物是已評估並接受的風險，非未經考慮的預設**：成立前提是產物不對外散布 (僅安裝於開發者自己的裝置)，且金鑰為開發者自有。未記錄的內嵌不得僅因無人反對而視為已接受，本條即是該項記錄
    - 前提不成立時 (例如產物開始對外散布)，金鑰必須移出產物、改為執行期提供，不得沿用內嵌做法
    - 撤換程序 (含建置期注入需重新 build 並重新安裝才生效) 見 [README.md › API 金鑰](README.md#1-api-金鑰-configxcconfig)
- 兩把金鑰皆以 Authorization header (`Bearer <key>`) 攜帶，端點路徑不含金鑰；`ExchangeRateClient`／`OllamaClient` 一致採此作法，不得回退為網址路徑帶憑證
    - 這條規則有具體機制撐腰、不只是理論風險：本專案連結的 `FirebasePerformance` 會自動記錄 `URLSession` 請求網址並上傳 (不收集 header)；金鑰若留在網址即隨這條既有管道外流，改走 header 才真正堵住它
- 幣別清單經 `CurrencyMetadataRepository.refreshIfStale(604_800)` 打 `/codes` 並 cache 7 天 (動態載入、不可 hardcode 的政策見 root `CLAUDE.md`)
- 網路層錯誤訊息不得內插網址、header 或設定值，避免把金鑰帶入使用者可見訊息
- `ExchangeRateClient` 送出請求前必須獨立拒絕含控制字元的金鑰，避免注入 Authorization header 值，不得以 `URL(string:)` 的後置失敗 guard 取代這層前置檢查
    - `URL(string:)` 的後置失敗 guard 是防禦性分支，必須保留
- 幣別快取只在取得非空結果時才替換；空結果視為異常，保留既有 cache 並回報，不得清空
    - `CurrencyMetadataPersistence.replace` 保留防禦性 guard，直接呼叫時也不可讓空結果進入先刪後寫路徑
- AI 摘要串流的整體時長上限為 30 秒；逾時保留已收到內容、將 `phase` 設為 `.finished`，並使用 `truncationMessage`，不得改走 `errorMessage`
- `ExchangeRateClient.serviceError` 是唯一的服務錯誤映射實作；`fetchLatest` 與 `fetchSupportedCodes` 共用它，不得在 endpoint 內複製

## 行事曆整合 (EventKit)

開團訂購提醒經 `CalendarReminderClient` (`Core/Dependencies/`，比照 `PhotoClient` 的 system-call client 範本) 寫入／移除系統行事曆。硬規則與 gotcha：

- **必須請求 full access、不能只用 write-only**——「移除提醒」需先 `event(withIdentifier:)` 讀回事件才能刪，write-only 讀不到事件。故走 `requestFullAccessToEvents()`，Info.plist 帶 `NSCalendarsFullAccessUsageDescription` (權限在實際新增／移除的當下才請求，非啟動即請求)。
- **campaign 連結存 iOS-only 的 `CampaignReminderRecord` (SwiftData 表)，不入跨平台 `Campaign` schema**——記 `eventIdentifier` 與使用者自選的提醒時間戳 `reminderTimestamp` (Date)；行事曆識別碼是裝置本機資料，寫進跨平台生成型別會違反平台中立原則且與 CloudKit 耦合。此表於 v1.5.0 建立並演進為使用者自選的 `reminderTimestamp` (當時的 V13 建表、V14 加提示時間、V15 改 `reminderTimestamp` 皆 lightweight；V13/V14 已隨 floor 收斂到 V15 而移除)。連結資料以 `CampaignReminderLink` 值型別在 repository / reducer 間流轉。
- **提醒日期＋時間由使用者自選、以時間戳保存**：不再自動掛結單日。事件為**全天事件** (`isAllDay`)，事件日期＝`calendar.startOfDay(for: reminderTimestamp)`，提示 (`EKAlarm(relativeOffset:)`) 以該時間戳的當天分鐘數換算秒數 (`Campaign.reminderTitle` 提供標題)。預設值取結單日 (無結單日則取今天) 的上午 09:00 (呈現方式見下方「開團訂購提醒選擇器走 Form 內 inline `DatePicker`」)，儲存時 reconcile (名稱或時間戳變更即重建事件)；**開團詳情頁純顯示**該提醒時間戳、不提供新增／移除 (管理走編輯頁)。
- **提醒重建一律先建立新事件、成功後才刪除舊事件，不可先刪後建**：`CampaignFeature` 對 `.rebuild(oldEventIdentifier)` 的處理先呼叫 `addReminder` 建新事件並以 `reminderStored` 更新連結，新事件建立成功後才呼叫 `removeReminder` 移除舊事件。
    - 新事件建立失敗時，連結維持指向舊事件、不得呼叫 `removeReminder`；反過來先刪後建，中途失敗會留下指向已刪除事件、無法解析的連結。
    - 移除舊事件本身失敗時，連結已指向新事件 (不回滾)，但該失敗要以 `campaignWriteFailed` 告知，不可用 `try?` 靜默吞掉。
- **`CalendarReminderClient.requestAccess` 回三態 (`granted`／`denied`／`restricted`)，寫入時另外可能拋出 `noWritableCalendar`**：`restricted` 是裝置政策限制 (家長監護／MDM)，使用者無法自行到設定開啟，訊息不得引導前往設定；`noWritableCalendar` 是權限已授予後找不到可寫入的行事曆 (例如僅有唯讀訂閱行事曆)，**不屬於權限問題**，訊息同樣不得指向設定。四種情境 (含可經設定開啟的 `denied`) 各自呈現對應訊息，不可合併成單一「需要權限」訊息。

## 程式風格 Apple 補充

通用標點、註解語言與 Commit 風格見 root `CLAUDE.md`；以下是 Swift / SwiftUI / TCA 專屬規則。

### 結構與命名

- **商業邏輯／資料計算** (彙總、分組、排序、格式化) 一律放 reducer 或可測試的 feature helper；SwiftUI View (含 Swift Charts) 只負責呈現，不要把計算 inline 在 view body。
- **綁 store 的 View 不持有 presentation 狀態**——sheet／picker 呈現開關、編輯草稿、選取焦點、導覽路徑等一律下放對應 `Feature.State`，以 `$store.xxx` binding 綁定，不留 `@State`。Feature 未採 `BindableAction` 時，先讓 `Action` conform `BindableAction` 並在 reducer body 最前加 `BindingReducer()` (與既有 `.ifLet`／`.forEach` 正交、可並存)；導覽堆疊用 `StackState`。若某 `.binding` 帶副作用 (如 `SettingsFeature` 在 `.binding` 存檔)，對純 UI 欄位用 `case .binding(\.showsXxx): return .none` 排除，避免開 sheet 就觸發副作用。**例外**：不綁 store、以 closure 與 caller 溝通的可重用元件 sheet (`OptionPickerSheet`／`PaymentMethodEditorSheet`／`LookupNameEditorSheet` 等) 的本地 `@State` 屬元件內部狀態，不在此列。
- **TCA feature** 內部用 `// MARK: - State / Action / Dependency Properties / Reducer Body` 等清楚切分 (順序見「MARK 區段與排版」一節的對照表)。
- **Swift/SwiftUI 內建型別的通用 extension 放 `Shared/Extensions/`**，一型一檔，檔名 `<型別>+Extensions.swift` (如 `Image+Extensions.swift`、`Color+Extensions.swift`)。**與特定 DesignSystem 元件或功能耦合的 extension 不搬到這裡、留在該元件檔**：「套一層 modifier 就回傳」的 `View` 方法 (`blCardShadow()`／`blTextStyle()`) 與其 `ViewModifier` 同檔、`ButtonStyle where Self == BLButtonStyle` 的工廠留在 `BLButtonStyle.swift`。判準：可獨立重用的通用 helper 才進 `Shared/Extensions/`。
- **不用 `switch`／`if` 運算式賦值**：避免 `let x = switch … { … }` / `let x = if … { … }` 這種運算式寫法；改用傳統陳述式 (先宣告 `let x: T`，再於各分支賦值)。若該計算寫在 `@ViewBuilder` body 內會與 result builder 衝突，請抽成獨立 helper 回傳該值，view body 只呼叫 helper。
- **`Label` 放在 `Form`／`List` row 內且後接 `Spacer`**：自動 label style 會把 icon 與 title 撐到 row 兩端 (icon 與文字中間出現大空隙)，須加 `.labelStyle(.titleAndIcon)` 讓兩者貼合 (`RootSidebarLayout` nav row)。
- **大型 reducer 以「同域輔助型別」拆分，不拆成子 reducer**：分支主體多到單一 switch 會拖慢型別檢查或難以審閱時，依子域各自抽一支無 case 的列舉型別 (如 `OrdersFilterOperations`)，只放 `static func`、不宣告任何相依 (`@Dependency` 一律留在 reducer 解析)，以 `inout State` 與明確參數溝通；需要「現在」時間、行事曆、新識別碼時一律由呼叫端的 reducer 解析後傳入，輔助型別內不得出現 `Date()`／`UUID()`／`Calendar.current`。跨檔會被輔助型別呼叫的成員 (State 的 mutating 方法、reducer 的靜態工廠等) 不可留在私有擴充，要收為 internal。
    - **主 switch 一律維持窮舉且零預設分支，此邊界由機器守門**：`TestSuiteIntegrityTests.defaultNoneBranchesRemainAbsent` 斷言 `apps/ios/BuyLedger` 內 `default: return .none` 恆為 0，不得為了拆分而放寬，也不得改寫成規避字串比對的形式 (如 `default:` 換行再 `return .none`)；那是規避守門而非修改它。
    - **reducer 拆成多段 `Reduce` 的理由若是型別檢查逾時，段間歸屬一律用列舉式 case 清單、不得改用預設分支**：每段各自窮舉、把「由別段處理」的 case 明列交出，讓新增 action case 時編譯期強制三段都更新。
    - **草稿型別必須標註為可觀察狀態 (`@ObservableState`)**，只標可相等比較會讓觀察粒度退化為整張表單重繪；非同步載入的欄位 (如訂單編輯的照片) 不得參與草稿相等比較，須另以獨立旗標追蹤是否被使用者實際編輯過。
- **sheet 遵循 Apple HIG「Sheets」兩條硬規則** (依 HIG 合規審視落地)：
  - **編輯類 sheet 防未儲存變更靜默遺失**：訂單／開團／付款方式編輯 sheet 一律加 dirty 判斷 (feature 用單一草稿值型別對照開啟時的初始草稿、closure 元件用初始值快照)，sheet 掛 `.interactiveDismissDisabled(<isDirty>)`，取消鍵於 dirty 時改彈「捨棄變更／繼續編輯」確認。確認一律用 `AlertState`／`.alert` (centered modal)，**不用 `.confirmationDialog`**：取消是 toolbar 按鈕，iOS 26 起 `.confirmationDialog` 對 toolbar 觸發會位置偏移。訂單編輯的照片是唯一以額外旗標 (`hasEditedPhotos`) 表達的例外：照片草稿非同步載入，若納入草稿相等比較，載入完成會被誤判為使用者的未儲存變更。
  - **不從 sheet 內再疊 sheet**——已呈現的 sheet 內開選擇器或子表單，用 push 或置中 overlay、不疊第二層 sheet。
    - **選擇器走 push**：`OptionPickerSheet`／`PaymentMethodEditorSheet` 有 `isEmbedded` 參數：預設 `false` = 自帶 `NavigationStack` 的單層 sheet (主介面呼叫點不變)，`true` = 去 `NavigationStack`／sheet 專屬修飾／取消鍵、由宿主 Back 返回。訂單編輯以單一 `OrderEditFeature.State.PickerRoute` enum + `navigationDestination(for:)` 驅動所有選擇器 (避開 `navigationDestination(item:)` 的 test-target 連結踩雷，見下「測試準則」相關 memory)。
    - **開團訂購提醒選擇器走 Form 內 inline `DatePicker`** (最貼 HIG，經 push → 置中自製對話框兩版被使用者否決後定案)：`CampaignEditView` 以 `Toggle("訂購提醒", isOn: $store.draft.wantsReminder)` + 條件顯示的 inline `DatePicker(selection: $store.draft.reminderTimestamp, displayedComponents: [.date, .hourAndMinute])` 呈現，與上方開團／結單日期列同款、點擊跳系統原生月曆／時間浮層。因此無獨立呈現、根本不涉「疊 sheet」；提醒時間戳即表單草稿、隨整張表單儲存/取消落地 (F1 dirty 已涵蓋)。**不要**為此再自製 sheet/push/overlay 對話框。

### Dynamic Type 與無障礙

- **無障礙字級要改版面結構，不是用縮放係數把字壓回去**——`minimumScaleFactor`／`lineLimit(1)` 抵銷了使用者的字級設定。以 `@Environment(\.dynamicTypeSize)` 的 `isAccessibilitySize` 判斷 (不要逐級列舉 case，系統新增級距時會失效)，在無障礙字級下解除單行限制、允許換行，並降維：多欄格降為單欄 (`DashboardView.kpiColumns`)、橫排三欄改為堆疊 (`OrderRowView`)。
- **固定點數的尺寸一律 `@ScaledMetric`**——圖示、格高、欄寬、圖表直徑都要隨字級長大，否則字放大後被容器截斷。`@ScaledMetric` 需要 view 實例，因此原本的 `static let` 尺寸常數要改成實例屬性。
- **複合列合併為單一朗讀單位**——由多個子元素組成的列 (訂單列、開團列、KPI 格) 加 `.accessibilityElement(children: .combine)`，否則輔助技術要逐一走過每個子元素。合併前先把純裝飾元素 (色點、與相鄰文字重複的頭像) 標 `.accessibilityHidden(true)`，避免它們被併進朗讀內容。
    - 可重用元件用參數表達裝飾與否 (`BLAvatar.isDecorative`)，而不是在呼叫端外層硬蓋 `accessibilityHidden`。
- **格狀資料的每一格要有座標**——熱力圖等格狀元素的 label 須帶「哪一列哪一欄」，否則輔助技術只會朗讀出一連串沒有位置的數字；空值格子直接排除於無障礙樹，整張圖另給一句摘要。
- **表達選取狀態一律加標準選取特徵**：列表中可選取的列 (訂單清單、選項選擇器、篩選 chip、合併照片格等) 於選取時加 `.accessibilityAddTraits(.isSelected)`；若同時顯示條件式勾號，勾號本身標 `.accessibilityHidden(true)` (特徵已表達狀態，勾號僅為視覺重複)。此規則由 `AccessibilityConventionScanTests.selectionCheckmarksCarryTheStandardSelectedTrait` 掃描式守門強制：候選鎖定「單元內同時具備 `.buttonStyle(.plain)` (本專案選取列的既有慣例) 與結構上條件式渲染的勾號圖示 (內嵌三元運算式或 `if` 區塊)」，以程式碼形狀而非變數／條件命名判定 (換名不影響判定結果)，找不到 `.isSelected` 特徵即失敗；不再有 `.accessibilityLabel(` 的豁免 (動作描述無法取代選取列表在 rotor 中應有的標準選取語意)。**已知邊界**：只涵蓋 `.buttonStyle(.plain)` 這個既有慣例，日後若有選取列改用其他 button style 或非 `Button` 元件呈現選取，掃描不會涵蓋，仍須人工複核；詳見該測試檔內文件註解。
- **新增動畫一律先過減少動態效果判斷**：`@Environment(\.accessibilityReduceMotion)` 為真時傳 `nil` 給 `.animation(_:value:)`。判斷放在動畫來源處 (`ButtonStyle` 等元件內，或抽成可單元測試的 `static func`／計算屬性，如 `BLPhotoViewer.zoomAnimation(reduceMotion:)`) 統一處理，不要散在各呼叫端。此規則由 `AccessibilityConventionScanTests.animationDeclarationsConsultTheReduceMotionPreference` 掃描式守門強制：`.animation(` 呼叫本身未含 `reduceMotion` 字樣、且該呼叫引用的同檔屬性／函式宣告本身也未含該字樣，即視為未判斷 (後者讓「判斷抽成獨立函式」不會被誤判為漏判)。**已知邊界**：只涵蓋 `.animation(` 這一種 API，不涵蓋 `withAnimation`／`.transition`／`.symbolEffect`；全專案目前也沒有這三者的呼叫點，涵蓋範圍與現況一致。
- **圖表元件補平台原生圖表描述**：Design System 的圖表元件 (`BLBarChart`／`BLDonutChart`／`BLSparkline`) 除既有逐點標籤與整體摘要外，另呼叫 `.accessibilityChartDescriptor(_:)` 提供 `AXChartDescriptorRepresentable`，讓輔助技術可用平台原生手勢以圖表方式導覽 (軸、資料序列、依繪製順序排列的數值)；新增圖表元件時比照補上。`AXChartDescriptor` 系列型別的 `title`／`series name` 等參數型別是 `String` 而非 `LocalizedStringKey`，不會隨 App 內語言切換自動翻譯 (與 `Text(String)` 走 verbatim 同理)。三個元件因此把這些字串開放為建構參數 (`axisXTitle`／`axisYTitle`／`seriesName`，`BLSparkline` 另有逐點描述用的 `pointOrdinalDescription`)，預設值維持正體中文字面值 (未傳入時行為不變，涵蓋 Preview 與尚未更新的呼叫端)。**Design System 元件本身不持有 `AppLanguage`，仍由呼叫端解析後傳入已本地化字串** (`AppLanguage` 現位於 `Shared/Localization/`，維持這個參數化慣例是既有選擇，不是分層限制)：`DashboardView`／`InsightsView` 已持有 `store.settings.language: AppLanguage`，直接呼叫 `AppLanguage.localized(_:)`；`OrderDetailView` 不持有該狀態，由 `language: AppLanguage` 計算屬性從既有的 `@Environment(\.locale)` 換算；`currencyDisplayText(for:)` 的語系判斷同樣呼叫此計算屬性，是同一入口而非兩份邏輯。這些字面值仍要在 `Localizable.xcstrings` 補上對應 entry：`LocalizationCatalogTests.catalogContainsCompleteTraditionalChineseAndEnglishValues()` 以結構性掃描 (比對 `title`／`name` 等參數標籤) 要求任何形似使用者可見文字的字面值都有 catalog entry 收錄英文翻譯；上述三個呼叫點已改為執行期實際查表，entry 不再只是翻譯對照文件。

### 導覽與呈現

- **每個目的地只有一條抵達路徑**——清單點擊與深連結必須寫入同一條路徑。「更多」分頁以 `RootFeature.MoreRoute` 值導向堆疊驅動 (`NavigationStack(path:)` + `navigationDestination(for:)`)，深連結時於同一次狀態更新內先清空再推入。
    - 用值導向堆疊而非「呈現旗標 + 去重判斷」：後者只是把不合法狀態擋掉，前者讓它根本無法表達。
    - **從「更多」分頁下的 pushed 頁深連結去別的根分頁時，切分頁前必須先 `state.morePath.removeAll()`**——客戶頁掛在 `morePath = [.customers]` 下，`customerSelected` 若在路徑仍非空時就改 `selectedTab`，iPad 的 `NavigationSplitView` 會在分欄更新的 `NavigationColumnState.boundPathChange` 觸發 `swift_unexpectedError` assertion 崩潰 (iPhone 不走 split view 故不崩，易漏)。任何新增的「More 下 pushed 頁 → 根分頁」深連結都要比照先清空 `morePath`。
- **選取狀態單一來源**——同一個清單裡的不同項目類別要併進同一個選取型別 (參考 `RootSidebarLayout.SidebarSelection`)，系統才只會高亮一列；兩套選取機制並存必定同時高亮。
- **任一時刻只呈現一層 modal**——同一畫面的多個 sheet 併進單一 `@Presents` destination 列舉，以單一呈現點依型別分派 (參考 `LookupManagementFeature.Destination`)，互斥由型別系統保證，而非多個並列的 `.sheet` 修飾子各自靠布林避讓。
    - 已在 sheet 內要再開子畫面時走 push、加入既有的路徑列舉即可 (訂單編輯的照片檢視與各選擇器共用 `PickerRoute`)。
- **push 目的地不可自帶 `NavigationStack`**，巢狀 stack 會讓推進呈現與 pop 動畫整個壞掉 (照片檢視改 push 時踩過：元件從 modal 改 push 呈現，務必連元件本體的 stack 一起拆)。嵌入元件比照 `OptionPickerSheet` 的 `isEmbedded` 模式：不自帶 stack、不設關閉鈕，標題掛在內容上、由宿主堆疊的 Back 返回。
- **alert 不拿來裝表單**——alert 的職責是傳達需要立即決策的關鍵資訊。有輸入框或開關的流程一律用 sheet 內表單 (`LookupNameEditorSheet`／`PaymentMethodEditorSheet`)；alert 的 actions builder 只支援 `Button`／`TextField`，塞 `Toggle` 會被靜默丟棄。
- **不要 `navigationBarBackButtonHidden(true)` 自繪返回鍵**，會連帶停用邊緣滑動返回。也**不要用 `.toolbarRole(.editor)` 藏返回標題**：該角色會把收合後的 inline 導覽標題 leading 對齊 (設定頁踩過)；iOS 26 返回鍵預設只顯示符號，維持預設角色即可。
- **不可逆的狀態轉換比照刪除加確認**——結團等寫入後無法改回的操作，與刪除同級：先以 `AlertState` 確認、文案點明不可復原，確認後才寫入。
- **破壞性操作：先確認、再寫入、寫入成功才改狀態**——確認一律用 `AlertState`，文案點明後果與不可復原。狀態更新放在寫入成功的 action 裡，不做樂觀更新加回滾；「先寫後改」從根本消除狀態與資料庫不一致的可能，也不必維護回滾邏輯。
    - 此原則適用於所有寫入路徑，不是只有刪除；`OrdersFeature` 的單筆狀態變更、批次狀態變更、收款狀態變更、刪除、編輯儲存皆改為落盤成功後才由對應的 `xxxPersisted` action 套用畫面狀態 (參考 `statusChangePersisted`／`batchStatusChangePersisted`／`orderSavePersisted`／`orderDeleted`)。合併路徑 (`mergeSourceIDs` 非空) 是既有的樂觀更新 + 快照回滾例外，刻意保留、不隨此原則收斂。
    - **一次性操作失敗與持續性載入失敗不可共用同一個狀態欄位**：前者是使用者關閉即結束生命週期的瞬時事件，後者是「資料沒拿到」的持續畫面狀態，若共用一個可選字串欄位，唯一的清空點常被「已載入」之類的旗標守衛擋住，導致失敗訊息在後續操作全部成功後仍殘留。`OrdersFeature` 把兩者分開：`errorMessage` 只由 `.task` 的載入失敗路徑設值 (維持既有的持續失敗呈現與重試)，其餘寫入失敗一律經 `orderWriteFailed(String)` 呈現為 `writeFailureAlert` (`AlertState`)，隨使用者關閉對話框而結束，不殘留。
- **表單儲存前置驗證失敗時，dismiss 決定權交給父層，不由子層無條件觸發**：子層 `saveTapped` 只回傳 `.none`，父層驗證通過才 `state.xxx = nil` 關閉表單；拒絕時保留呈現，並把原因寫回子層 State 供表單顯示 (如 `CampaignEditFeature.State.nameConflictMessage`)。`LookupManagementFeature.Destination` 系列本就是這個模式，`CampaignEditFeature` 是延伸套用。
    - 與上一條「先寫後改」不同：這裡的驗證 (如名稱唯一性) 在進入任何寫入副作用之前就能同步判定，不需要等寫入結果，因此拒絕原因直接顯示在仍呈現中的表單上，而非另開 `writeFailureAlert`。

### 焦點與鍵盤

- **收鍵盤有三條路徑，且不得以全域攔截加排除清單實作**：一般鍵盤的 return 鍵、數字鍵盤的鍵盤工具列 (`ToolbarItemGroup(placement: .keyboard)`)、以及 `scrollDismissesKeyboard(.interactively)`。每個有輸入的畫面至少要有兩條。
    - **不要再掛 window 級手勢**：舊實作 (`dismissKeyboardOnTap()`) 對所有觸控先攔一次、再靠黑名單沿 superview 逐層排除互動元件，而黑名單永遠追不上系統新增的 view 型別 (曾誤觸貼上／選取等系統 action)，已移除。
    - **「點背景收鍵盤」在本專案不可行，不要再嘗試**：以 `.background { Color.clear.contentShape(.rect).onTapGesture { … } }` 承接的作法，在 `Form`／`List` 與 `ScrollView` 版面均**經介面測試證實收不到觸控** (`Form` 即使加 `.scrollContentBackground(.hidden)` 亦然)——這些容器會消耗空白處的觸控且不向下傳遞。
    - **`scrollDismissesKeyboard(.interactively)` 無法以 XCUITest 合成手勢可靠觸發，不要再嘗試用 UI 測試守它**：以 `XCUIElement.coordinate(withNormalizedOffset:)` + `press(forDuration:thenDragTo:)`／`swipeUp()` 對 `Form` 施加拖曳，經量測可及性樹確認觸控座標確實落在表單可見範圍 (非鍵盤區域) 且畫面內容也確實產生真實捲動，但鍵盤 frame 全程停在原地未受影響；換手指往下拖 (符合「往下拉走鍵盤」的教科書手勢方向) 同樣無效。這與「點背景收鍵盤不可行」是同一類限制：私有的「鍵盤隨手指即時位移」追蹤機制不吃 XCTest 的合成觸控事件，即使合成手勢能驅動一般的 `UIScrollView` 內容捲動。**產品端的 `.scrollDismissesKeyboard(.interactively)` 維持不動**，對真實使用者仍然有效，只是沒有 UI 測試能守住它；`KeyboardDismissTests` 因此只覆蓋另外兩條可靠路徑，不保留恆紅或靠 fallback 手勢才勉強轉綠的第三條測試。
    - 收鍵盤一律把焦點設為 `nil`／`false`，不呼叫 UIKit 的 `endEditing`——讓收鍵盤與焦點成為同一個狀態的兩面。
    - 用系統 `.searchable` 的畫面另有 Cancel 鈕與捲動收合，由系統提供。
    - **UI 測試走獨立的 `BuyLedgerUITests` scheme**：主 scheme 只含單元測試以維持快速回圈；`KeyboardDismissTests` 守住上述三條路徑中可測的兩條確實生效 (一般鍵盤 return 鍵、數字鍵盤工具列完成鍵)，而非已移除機制的舊行為。
- **焦點狀態下放 `Feature.State`、不留在 view**——焦點是呈現狀態，與 sheet 開關同級 (見上方「綁 store 的 View 不持有 presentation 狀態」)。view 只宣告 `@FocusState` 作為鏡像，以 TCA 的 `.bind($store.focusedField, to: $focusedField)` 連結。
  - 這讓「新訂單自動聚焦第一個欄位」「關閉時清除焦點」能在 reducer 表達並被 TestStore 涵蓋，而不是散在 view 的生命週期回呼裡。
  - 焦點欄位的 enum case **依畫面上的視覺順序宣告** (參考 `OrderEditFeature.State.Field`)，讓「下一欄」的語意直接由宣告順序表達。
- **數字鍵盤必須有收起路徑**——`.numberPad`／`.decimalPad` 沒有 return 鍵。表單加 `ToolbarItemGroup(placement: .keyboard)` 只放一個「完成」，並加 `.scrollDismissesKeyboard(.interactively)`。
  - 工具列**不要出現在有 return 鍵的一般鍵盤上**：畫面若混有文字與數字欄位，以焦點欄位判斷後再決定是否顯示 (參考 `OrderEditView.isNumericFieldFocused`)；整個畫面只有數字欄位時才可無條件顯示。
  - 不加上一欄／下一欄箭頭——焦點順序已由焦點管理提供，重複入口只增加工具列負擔。

### 註解

- 不要為了補註解而新增不必要的顯式 `init`；能使用 Swift 合成 memberwise initializer 時請優先使用。只有在需要 `@ViewBuilder` trailing closure、無標籤參數的語意化 API、驗證、轉換或相依注入時才新增顯式 `init`。

### MARK 區段與排版

- `struct` / `enum` / `extension` / `final class` 等型別宣告後第一行要空一行。
- 所有型別共用同一套「由上到下」的區段順序。View 型別用完整版；非 View 型別沿用**相同順序**，只是把 View 專屬段落換成語意對應段名、或在無內容時直接略過。**沒有對應成員的段落不要寫**——不留空 `// MARK:`、不留空 `extension` (例如沒有任何 `@ViewBuilder` 方法時，不保留 `// MARK: - ViewBuilder`)。

  | # | 位置語意             | View                                 | TCA Reducer                          | 其他型別 (enum / struct / class)                                                     |
  |---|----------------------|--------------------------------------|--------------------------------------|--------------------------------------------------------------------------------------|
  | 1 | 內容定義 (狀態／屬性) | `View Properties`                    | `State`、`Action`                     | `Cases` (enum) → `Identifiable Properties` → `Data Properties` → `Static Properties` |
  | 2 | 初始化               | `Init`                               | (少見)                               | `Init`                                                                               |
  | 3 | 相依注入             | 併入 `View Properties`               | `Dependency Properties`              | `Dependency Properties` (若有)                                                       |
  | 4 | 主體／核心計算        | `View Body`                          | `Reducer Body`                       | `Computed Properties`／主要對外計算 (可用語意名，如 `Display Properties`)              |
  | 5 | 巢狀型別             | `Nested Types`                       | `Nested Types`                       | `Nested Types`                                                                       |
  | 6 | ViewBuilder          | `ViewBuilder`                        | —                                    | —                                                                                    |
  | 7 | 方法                 | `Internal Method` → `Private Method` | `Internal Method` → `Private Method` | `Internal Method` → `Private Method`                                                 |
  | 8 | 預覽                 | `Preview`                            | —                                    | `Preview` (僅 Design System 元件等可預覽型別)                                        |

- **第 5～8 區段一律寫在型別主體外**，讓主體專注在「它是什麼」與「主要計算」。其中 Nested Types 視該巢狀型別是否需被外部 (其他檔／測試) 引用，用 `extension` 或 `private extension` 切分 (型別本身的 access level 也據此決定)；ViewBuilder 一律 `private extension`；方法段依 access 分 (見下)；Preview 則是檔尾的 `#Preview`。
- **段落 MARK 寫在 `extension` 宣告行的「上方」，不是大括號「內」**：`// MARK: - Nested Types`／`ViewBuilder`／`Internal Method`／`Private Method`／`Dependency Values` 等**用來標示一整個 extension 的段名**，一律置於 `extension`／`private extension` 那行的**上方** (中間空一行)，`extension {` 之後第一行直接是成員 (需再細分時才於 extension 內用**無破折號** `// MARK: 子分類`)。只有寫在**型別主體大括號內**的段名 (如 `View Properties`、`State`、`Action`、`Reducer Body`、`Cases`) 才留在型別內。
- **TCA 結構元素留在 Reducer 主體內**：`State`、`Action`、`CancelID` (effect 取消識別) 等屬 TCA 架構的一部分，寫在 `@Reducer` 型別主體內對應段名下 (`CancelID` 用 `// MARK: - Cancel ID`)，**不歸入 `Nested Types` 也不外移 extension**。
- **`VersionedSchema` 版本的凍結影子 `@Model` 留在該 version enum 主體內** (`// MARK: - Nested Types`)：影子型別是「那個版本 schema 的一部分」，寫在 `enum BuyLedgerSchemaVxx` 主體、**不外移 extension** (搬位置雖不改指紋，但留主體語意更貼切、也少一層 extension)。
- **`ViewBuilder` 段的成員 (`func` 或 `var` 回傳 `some View`) 一律標註 `@ViewBuilder`**——即使只回傳單一 view 也要標，全專案統一這一種寫法，不採「不標 `@ViewBuilder`、改用 `return` 回傳單一 view」的另一種。理由：`@ViewBuilder` 對單一 view 同樣合法，且日後加 `if`／`switch` 分支或並列多個 view 時不必改寫。此規定僅適用於「組合 view 內容」的 helper；下列不在此列：協定的 `body`／`makeBody`／`ViewModifier.body(content:)` (已隱含 builder)、以及 `View` 擴充上「套一層 modifier 就回傳」的 API (如 `blCardShadow()`／`blTextStyle()`，歸 `// MARK: - View Method`)。
- **方法段依 access 拆兩段，`Internal Method` 在上、`Private Method` 在下**：`internal` 方法收 `// MARK: - Internal Method` (寫在 `extension X`)、`private` 方法收 `// MARK: - Private Method` (寫在 `private extension X`)。**`static` 方法不另立段，依其 access 併入對應段** (internal static → `Internal Method`、private static → `Private Method`)；不使用獨立的 `// MARK: - Static Method`。理由：範本原本一律用 `Private Method`，但不少方法其實是 internal (如 `Feature.State` 給 view 呼叫的計算、會被其他測試檔呼叫的 `static func`)，標「Private」名實不符；改依實際 access 命名。
- **`private extension` 內的成員不再重複標 `private`**：`private extension` 已把成員預設成 private，其內寫 `func`／`static func`／`var`，**不寫 `private func` 等** (`private(set)` 例外，語意不同)。
- **不要用 purpose 名稱另立方法段**：`Formatting`、`Layout Helper`、`Aggregation`、`Filter Method`、`Section Method`、`AI Method` 等一律收斂到 `Internal Method`／`Private Method`；需要分小類時，在同一個 extension 內用無破折號的 `// MARK: <子分類>` 細分。property／計算類語意名 (如 `Display Properties`) 仍可用，放第 1 或第 4 區段。
- **例外保留的語意化段名**：`Dependency Values` (DependencyKey 的 `liveValue`／`testValue`／`previewValue`)、`Codable`／`CodingKeys`、`Response DTO`／`Request DTO`、協定遵循名 (`UIGestureRecognizerDelegate` 等) 這類「描述這段是什麼」的語意名保留，不強制收斂到範本表。
- **`ViewModifier` 型別**比照 View 排序 (其 `body(content:)` 即第 4 區段「主體」，由協定隱含 `@ViewBuilder` 故毋須標)；若是某檔的次要型別，段首以 `// MARK: - ViewModifier` 標示 (而非 `ViewBuilder`)。Design System 中可重用的 ViewModifier 各自獨立一檔，集中放 `Shared/DesignSystem/Foundations/ViewModifiers/`。
- **`ToolbarContent` 型別**同樣比照 View 排序 (內容定義收於 `// MARK: - View Properties`，主體收 `// MARK: - Toolbar Content Body`，協定隱含 `@ToolbarContentBuilder` 故毋須標)。目前唯一案例為 `OrdersToolbarContent.swift`；該型別不含相依注入，均由呼叫端解析後以 init 參數傳入。
- `#Preview` 放在檔案最後，前方加上 `// MARK: - Preview`。

建立新 Swift 檔案時，invoke `/swift-file-template` 取得檔案 header 格式與 View / 非 View 型別 / TCA Reducer 的具體程式碼範本。

## Design System 準則

- Design System 放在 `apps/ios/BuyLedger/Shared/DesignSystem/`，並區分 `Foundations/` 與 `Components/`。`Foundations/` 放跨元件共用的 token、modifier 與語意模型；`Components/` 放可視 UI 元件，並依類別建立子資料夾。
- 每個主要元件或資料型別原則上各自一個 Swift 檔案，檔名必須對應主要型別名稱 (例如 `BLBarChart.swift`、`BLDonutChart.swift`、`BLSparkline.swift`、`BLFilterChip.swift`)。避免建立 `BLCharts.swift`、`BLTextFields.swift` 這類同時涵括多種元件的大檔。若小型 enum 或 extension 只服務單一元件，可以與該元件同檔；若開始跨元件重用或變大，請拆出獨立檔案。
- 每個可視 Design System 元件都應提供自己的 `#Preview`；需要 binding 時使用 `.constant(...)`，需要圖表或狀態資料時用小型 sample data。
- 調整 Design System 結構或元件後，請至少執行 iPhone 與 iPad Simulator build，確認 file system synchronized groups 正確拾取新增、搬移或刪除的 Swift 檔案。
- **跨檔案共用的尺寸由單一來源推導、不各自寫死**——例如分隔線內縮由頭像尺寸推導 (`BLListMetrics.dividerInset` ← `avatarSize`)。兩個本就必須對齊的數值各自寫死，會在其中一方改動時默默錯開。
- **跨畫面共用的呈現規則 (非僅尺寸) 同樣走單一入口**：`BLFormatters` (`Shared/DesignSystem/Foundations/BLFormatters.swift`) 是 Dashboard／Customers／FX／Insights／Quote 五個畫面的金額與百分比格式化入口 (開團詳情的利潤率亦直接取用其百分比多載)，空值與比例／已縮放數值以多載處理，畫面不得另寫等價的 `.formatted(.currency(...))`／`.formatted(.percent(...))`。Orders／Campaigns 既有的 `OrderFormatters`／`CampaignFormatters` 保留各自 feature 專屬的格式化方法 (如 `OrderFormatters.marginPercent`／`shortDate`、`CampaignFormatters.shortDate`)，但其 TWD 金額與比例百分比規則已改為一行委派 `BLFormatters`、不再各自定義；新畫面選用格式化工具時留意勿再新增等價的第二份實作。
    - **`shortDate` 是唯一的具名同名例外，收斂格式化時不可盲併**：`OrderFormatters.shortDate` 用 `.month(.defaultDigits).day(.defaultDigits)`，`CampaignFormatters.shortDate` 用 `.month(.abbreviated).day()`；同名但呈現規則不同，併了會直接改掉呈現。
- **字級一律走 `BLTypography` (`Shared/DesignSystem/Foundations/BLTypography.swift`) 的 `BLTypographyStyle` token、不手寫 `.font(.footnote)`／`.font(.title3.weight(...))` 等字面值**：View 上直接套用 `.blTextStyle(_:)`；需要純 `Font` 值 (如元件內部按尺寸切換字級的 `switch`) 才用 `BLTypographyStyle.<case>.font`。呼叫端需要 token 未內建的字重時，用 `BLTypographyStyle.<case>.font.weight(_:)` 組合，不在呼叫端另寫 `.footnote`／`.subheadline` 等基底字面值；token 本身若還沒有涵蓋某個實際用到的字級 (例如某層級需要 bold 而非既有 case 內建的字重)，補進 `BLTypographyStyle` 新增 case，不留在呼叫端手寫 (`title3Bold` 即一例：`title3` case 本身內建 semibold，KPI 卡等處需要的是 bold，兩者是不同字級)。純比例縮放的字級 (隨元件自身尺寸參數等比縮放，如 `BLAvatar` 姓名縮寫、`@ScaledMetric` 驅動的 hero 數字) 不是固定字級層級，不適用此 token 系統，維持 `.font(.system(size:...))`。
    - **`Font.bold()` 與 `Font.weight(.bold)` 不是逐位元相同的渲染結果**：實測 swift-snapshot-testing 下兩者的 rasterize 結果有微小但會被 snapshot 抓到的差異 (肉眼在單張截圖上不易察覺)。收斂手寫字級時若原呼叫點用的是 `.bold()`，token 端組合也要用 `.font.bold()`，不要換成 `.font.weight(.bold)`；反之亦然，兩種寫法不可互相替代。
    - **是否新增 case 的判準是語意獨立性，不是出現次數**：字重差異只有在代表一個獨立、具名的視覺層級時才補進 `BLTypographyStyle` (如 `title3Bold`：`title3` case 本身內建 semibold，呼叫端需要的 bold 是另一個層級)；純粹用於「強調」、未構成獨立層級的字重組合 (`subheadline`／`caption`／`footnote` 搭配 `.semibold`／`.medium` 等)，即使單一組合的呼叫端數量達兩位數 (實測最高頻的 `subhead.font.weight(.semibold)` 32 處、`caption.font.weight(.semibold)` 23 處、`footnote.font.weight(.semibold)` 15 處)，仍留在呼叫端以 `.font.weight(_:)` 組合，不逐一收攏為 case；這類零散強調組合本就不是「token 涵蓋不到的字級」，收攏的回歸風險 (參見上一條 `.bold()`／`.weight(.bold)` 的細微光柵化差異) 不成比例。
- **語意色與系統色一律走系統取色介面 (`Color(uiColor: .systemXxx)`)、不手抄十六進位值**：系統色是動態色，隨系統版本、深淺外觀、增強對比與 vibrancy 自動調整；`BLPalette` 無外觀參數也無亮暗分支。系統取色介面呼叫僅限色盤檔 (`BLPalette.swift`)，其餘檔案一律經色盤或建立於色盤之上的 Design System 入口取色，由 `DesignSystemSourceScanTests` 掃描守門；從原始分量建構色彩 (十六進位／RGB／色彩空間) 僅色盤檔與頭像元件 (`BLAvatar`，演算法產生漸層色相) 兩處可用。
    - **例外：`secondaryLabel` 刻意不用系統值**：系統 `.secondaryLabel` 淺色僅約 3.4:1，低於本專案 4.5:1 的資訊文字地板，改以 `label.opacity(0.6)` 推導 (仍為動態色，實測兩外觀皆逾 5.4:1)。資訊性次要文字 (含表單與清單的 section footer，不留豁免) 一律經 `Color.blSecondaryLabel` (`Shared/Extensions/Color+Extensions.swift`) 取用，不直接寫系統的 `.secondary`；呼叫端一律用 `Color.blSecondaryLabel` 明確型別形式，不用 `.blSecondaryLabel` 前置點縮寫。縮寫在本專案 `foregroundStyle(_:)` 情境下必然解析不到 (`type 'ShapeStyle' has no member 'blSecondaryLabel'`)：`blSecondaryLabel` 是掛在 `Color` 上的靜態屬性，而 `foregroundStyle(_:)` 參數型別是 `some ShapeStyle`，implicit member 只認參數宣告型別上的成員，屬確定性行為而非型別檢查器不穩定；要支援前置點需改用 `extension ShapeStyle where Self == Color`，本案選擇不做以縮小改動面 (56 個呼叫點)。
    - **具名系統色 (強調色、綠、橘、紅、藍等) 不得直接取代色盤色，唯一例外是白、黑、透明**：三者不隨外觀解析、不是語意色 (漸層上的白字、遮罩、透明背景)，其餘一律經色盤的顯示屬性取用。
    - **不設全域 tint、`AccentColor` 資源維持不填值**：讓系統元件保持系統預設的 accent 行為。曾於根層 `.tint` 加補值資源統一強調色，實機驗收判定整個 App 被強制上色、不符需求而移除。自訂元件的強調視覺一律取 `BLPalette.accent` (系統動態藍)。
- **色彩不做亮暗分支，view 不得為了取色宣告 `@Environment(\.colorScheme)`**：色盤與語意色軌道全走系統動態色與資源目錄，外觀切換由系統驅動；唯一例外是卡片陰影修飾子 (`BLCardShadow.swift`)，深色外觀需要不同陰影不透明度，是全庫唯一真正讀取此環境值的地方。
- **設計系統原始碼掃描守門**：`BuyLedgerTests/DesignSystemSourceScanTests.swift` 以文字層級掃描強制上述色彩入口不變式，共八條規則 (次要色、強調色、色相字面值、系統取色介面限色盤檔、原始分量建構限兩處、外觀環境宣告限卡片陰影、十六進位建構子零命中、豁免標記須帶非空理由)，另有一條守門測試斷言掃描到的檔案數不為零 (避免 `productionRoot` 解析錯誤時對空集合靜默恆為綠燈)，隨主 scheme 測試執行。需要例外時在**違規那一行本身**加具名豁免標記 `// design-system-scan-exempt: <理由>` (理由必須非空，掃描會檢查)；掃描比對前會剝除行註解、區塊註解、成對雙引號字串字面值與多行三引號字串字面值，避免文件或本地化文案中的相同字樣被誤判。色相字面值規則不依賴呼叫名清單，改以括號結構判定裸前置點寫法 (如 `.red`) 是否落在顏色值位置，細節見該測試檔內文件註解。**該規則比對的色相名稱本身 (`red`／`green`／`mint`／`gray` 等) 是刻意列舉的封閉集合**：SwiftUI 具名系統色是 Apple 文件記載的小型固定集合，與修飾子名稱那種會持續增長的開放集合性質不同，此處列舉不是本規則要消滅的白名單反例；**但這代表它有維護義務**：日後 SwiftUI 新增具名系統色時，需同步補進 `namedHueTokenPattern` 的兩個交替，否則新色相會重演本次「清單漏列」的缺口。
- **層級不以文字的不透明度降階表達**——降階直接損害對比 (主卡曾落在 2.03–3.24:1)；層級由字重與字級表達，文字不透明度一律為一。彩底上的白字由 `ContrastComplianceTests` 的漸層斷言把關。
- **不以實色模仿系統 bar、不以半透明色模仿玻璃材質**——需要 bar 底就用系統材質 (`.background(.bar)`) 並讓捲動內容延伸至其下方；層次區隔用系統材質，不自訂半透明色 (原 `glassBackground`／`glassBorder` 已刪除)。
- **語意色分四軌，選軌的唯一判準是「這個色彩最終疊在什麼底色上」**——`BLTone` 提供 `onSurface`／`background`／`indicator`／`onIndicator`，皆為讀取 asset catalog 具名資源的計算屬性 (不收色盤參數，外觀與 Increase Contrast 由系統依 trait 解析)。
  - 文字疊在卡片、列背景或 `background` 淡底 → `onSurface`；本身就是圖形 (狀態點、進度條填色、實心徽章底色) → `indicator`；文字疊在 `indicator` 實心底上 → `onIndicator`。
  - **色值改在 asset catalog、不在程式碼算**：`Assets.xcassets` 的 `BLTone<Tone><Role>` 每組都定義 Any／Dark 與各自的 High Contrast 變體。程式碼算色表達不了 Increase Contrast 這個維度。
  - **具名色彩資源缺失時 SwiftUI 靜默回退系統預設色**，無編譯或執行期警訊——新增 Color Set 必須與引用它的程式碼同批合入，且驗收要逐一目視確認顏色，不以「畫面沒壞」當通過。
  - 對比門檻由 `BuyLedgerTests/ContrastComplianceTests` 把關 (helper 為 `ColorContrast`，自帶對照案例鎖住計算模型)。**旁有文字標籤的圖形 (如膠囊色點) 屬裝飾**，豁免 3:1 並標 `.accessibilityHidden(true)`；3:1 只約束單獨承載意義的圖形。
- **訂單狀態色分兩套並行且刻意分離的軌道，各自只服務一種介面**：`BLTone` 語意色軌道 (六值) 表達「值得多少注意力」，狀態膠囊等一切帶文字標籤呈現狀態的介面一律走它；`BLStatusHue` (`Shared/DesignSystem/Foundations/BLStatusHue.swift`) 色相軌道以窮舉分支涵蓋每個 `OrderStatus`，只服務側邊欄智慧分組色點：八個分組經 `BLTone` 映射後只剩四種顏色、其中兩個在側邊欄是相鄰兩列，同色會被讀成渲染錯誤。兩軌各自唯一來源，不得在呼叫端內嵌狀態到顏色的映射；新增訂單狀態時兩邊的窮舉 switch 都會因缺分支而編譯失敗，逼出色彩指派。
- **彩底 hero 卡一律取單一語意入口**：不得以系統色 (`palette.green`／`palette.teal`／`accent`) 現組漸層，也不得在畫面內直接呼叫 `BLPalette.heroGradient` 自組 `LinearGradient`；一律呼叫 `.blHeroCardBackground()` (`Shared/DesignSystem/Foundations/ViewModifiers/BLHeroCardBackground.swift`)，由該 modifier 內部讀取 `BLPalette.heroGradient` 並套用圓角裁切。總覽頁與報價頁主卡共用同一份 modifier，值測試 (`ContrastComplianceTests`) 直接綁定 `BLHeroCardBackground.gradientColors`；用錯漸層不再能在單一畫面內靜默發生，日後新增的 hero 卡呼叫此 modifier 也自動套用同一份受測底色。
  - `BLHeroGradientStart`／`End` 兩個 colorset 目前只定義 Any／Dark，未定義 High Contrast 變體，故 Increase Contrast 會回落到基礎值；四種既有外觀組合皆已達標，暫不需處理，但新增依賴此漸層的畫面時留意這個落差。
  - hero 卡文字固定 `.foregroundStyle(.white)` 是刻意保留的例外：白色本身不是 `BLPalette` 的系統色 token，而是疊在受測漸層上取得最高對比的選擇，不屬於「自行組色」規則的約束對象；兩處呼叫點皆有行內註解點出此例外。
- **系統已提供的能力不得重造**——搜尋、分段選擇、進度、清單列的按壓回饋等一律用系統元件。自製版本的代價不在外觀，而在那些不可見卻會一併失去的行為 (搜尋的 Cancel 鈕／Search return 鍵／聽寫／捲動收合、進度的 progress 語意、列的按壓 highlight)，這些在目視檢查中不會暴露。
  - 需要自訂外觀時走系統的**樣式擴充點**而非重畫元件：`ProgressViewStyle` (`BLProgressBarStyle`)、`ButtonStyle` (`BLButtonStyle`)。這樣外觀可完全自訂，語意仍由系統提供。
  - **不得以內聯的量測容器搭配軌道／填色形狀模擬進度條**：即使沒有宣告可重用型別，以 `GeometryReader` 量測寬度、疊兩層 `Capsule`／`RoundedRectangle` 分別畫軌道與填色仍是重造，會失去 `ProgressView` 的進度語意 (輔助技術讀不到目前值)。三處進度指示一律走 `ProgressView` + `.progressViewStyle(BLProgressBarStyle(...))`，即使畫面既有排版 (如數值已在同列另外呈現) 而未使用該樣式自帶的標題／當前值列亦同。彩底 (如漸層卡) 上的進度條以 `BLProgressBarStyle` 的 `track` 參數指定與底色調和的軌道色，比照該畫面固定白字的既有例外寫法；不得改用不帶自訂樣式的系統 `ProgressView`：樣式的預設軌道色是為淺色表面設計，疊在彩底上會顯得混濁。
  - 訂單搜尋走 `.searchable(placement: .navigationBarDrawer(displayMode: .always))`；設定頁的值選擇列走 `NavigationLink` + `LabeledContent` + `OptionPickerSheet(isEmbedded: true)`，取得列 highlight 與原生 disclosure indicator。
  - **零呼叫點的重造元件一律刪除、不留在 Design System 目錄**——目錄的預設語意是「這裡的元件是本專案的標準作法」，留著等同背書。
- **破壞性以按鈕 role 表達，不做成視覺樣式變體**——`Button(role: .destructive)` 才是系統語意來源，決定語音播報、系統紅色在各外觀下的自動調整、以及在確認對話框與選單中的一致呈現。`BLButtonStyle` 不提供破壞性變體。
- **自繪背景的 `ButtonStyle` 必須自己讀 `@Environment(\.isEnabled)`**——樣式不會自動反映停用態，不讀就會讓停用按鈕與可用時長得一模一樣。
- **可點擊元素用 `Button`、不用 `onTapGesture`**——點擊手勢沒有按壓態，也不支援 switch control 與外接鍵盤的啟用路徑。
- **`ScrollView` 內容上不可常駐掛 `simultaneousGesture(DragGesture())`**，會搶走 scroll 的 pan，讓捲動／換頁整個失效 (照片檢視器的縮放平移踩過：手勢的 onChanged 內判斷不做事**擋不住**它吃觸控)。條件性手勢用 `.simultaneousGesture(_:isEnabled:)` 依狀態掛上，如 `BLPhotoViewer` 的平移只在放大後啟用。
- **命中區的尺寸與形狀宣告要加在按鈕的「標籤內部」**——`Button { Image(...).frame(width: BLHitTarget.minimum, height: BLHitTarget.minimum).contentShape(.rect) }` 才會擴大可點區域；加在 `Button` 外層 (`.padding()`／`.frame()`) 只增加版面間距、命中區仍只有圖示大小。
  - 需要維持原本的貼齊角落外觀時用 `.offset(...)` 把放大後的命中區推回原位——`offset` 不影響 layout，視覺尺寸與版面比例都不變。
  - **形狀宣告要用元件自身的形狀、不是外接矩形**：膠囊類控制項用 `.contentShape(.capsule)`，用 `.rect` 會讓相鄰膠囊的命中區在圓角處重疊。命中區尺寸統一取 `BLHitTarget.minimum`。
  - 命中區撐高會讓該列變高、下方內容順勢位移，這是達標的必然代價；元件本身的視覺尺寸不應隨之改變。

## 測試準則

單元測試放在 `apps/ios/BuyLedgerTests/`，UI 流程測試放在 `apps/ios/BuyLedgerUITests/`。測試檔名對應被測試的型別或功能 (例如 `OrdersFeatureTests.swift`、`OrderPersistenceTests.swift`)。

### TCA TestStore

- **`exhaustivity = .off` 搭 `store.finish()` 不保證效果派送的 action 已處理完成**：要斷言失敗路徑或先寫後改成功路徑等由效果派送的 action (如 `.orderWriteFailed`、`.statusChangePersisted`) 造成的 state 變更，須明確 `await store.receive(\.actionName)` 等它處理完再讀 `store.state`，不能只憑 `finish()` 就認定已套用
    - 省略這一步的斷言即使當下看起來通過也可能只是還沒跑到，是一類容易被忽略的假測試，比照 `CampaignReminderFailureTests`／`OrdersFeatureTests.newOrderSaveDoesNotInsertWhenCreateFails` 的既有寫法
- **純 `AlertState` 的 `.ifLet` 收到 `.presented` 動作時會隱含自動清空該呈現**：這是框架層行為 (`PresentationReducer.swift`，`AlertState` 遵循 `_EphemeralState`)，清空發生在 `base._reduce` 之後，故父層 reducer 仍讀得到該次呈現的值。窮舉測試斷言 `.xxx(.presented(.yyy))` 送出後容易多寫或漏寫一次 `$0.xxx = nil`，須以實際行為為準逐一核對，不要憑直覺假設呈現狀態的清空時機
- **AISummaryFeature 的串流測試一律注入 `TestClock`**：測試環境的 `\.continuousClock` 預設可能是 `ImmediateClock`，會讓整體時長上限的 `sleep` 立即返回、計時器搶在串流前結束。以同一個 `TestClock` 注入 `$0.continuousClock`，串流替身也用該 clock 的 `sleep(for:)`，再以 `advance(by:)` 明確推進 chunk 間隔與 timeout；不要在串流替身使用 `ContinuousClock` 或 `Task.sleep`，避免依賴真實牆鐘
    - 測試 target 必須明確連結 `Clocks` product；只靠 `ComposableArchitecture` 的轉出 import 可能在 linker 階段失敗
    - 測試以 `OllamaClient.overallStreamDuration` 驅動 production 上限，不新增 `DependencyValues` keyPath 作為測試旋鈕

### 測試套件完整性守門 (`TestSuiteIntegrityTests`)

- **`exhaustivity = .off` 在單元測試 target 上限為 9 處，只能下降不可上升**：`TestSuiteIntegrityTests.exhaustivityRelaxationsDoNotExceedTheRecordedBound` 掃描 `apps/ios/BuyLedgerTests` (不含 `BuyLedgerUITests`) 比對此上限；新增一處關閉窮舉檢查而未同時移除他處會讓此測試轉紅，逼作者要嘛不關、要嘛連帶拿掉別處的關閉。上限只檢查總數不檢查位置，測試搬移不會誤報。
- **`BuyLedger` App target 內 `default: return .none` 恆為 0 處**：同一守門的 `defaultNoneBranchesRemainAbsent` 掃描 `apps/ios/BuyLedger` (不含測試 target)；新增一處會讓此測試轉紅。本小節三條皆為列舉式數量守門 (不是清單式收錄)，刻意與其餘守門的「掃描優於清單」原則並存；它宣稱的是「不超過這個數」而非「窮舉某個集合」，數量斷言與完整性斷言性質不同。
- **`BuyLedger` App target 內疑似把完整 URL／URLRequest 內插進使用者可見訊息或診斷輸出恆為 0 處**：`credentialBearingURLInterpolationsRemainAbsent` 同樣掃描 `apps/ios/BuyLedger` (不含測試 target)，比對含 `url`／`request` 子字串的識別字被直接內插、或接上 `absoluteString`／`url`／`description`／`debugDescription` 等會攤平出完整值的存取子。這是憑證外洩契約 (`openspec/specs/api-key-handling/spec.md`「Credentials never reach logs, messages, or diagnostics」) 的自動守門，取代原本只靠一次性人工檢視；屬子字串比對的啟發式規則，未涵蓋所有可能的迂迴寫法 (例如變數名不含 `url`／`request` 字樣、或透過中介變數改名再內插)，新增疑似把完整值輸出的程式碼仍須人工複核。

### 效能測試 (`OrdersFeaturePerformanceTests`)

- **不用 XCTest 的 `measure { }` 隱式基準比較，改用 `ContinuousClock` 自行計時 + `XCTAssertLessThan` 顯式斷言上限**：本專案經 XcodeBuildMCP 執行測試一律拆成 `build-for-testing` + `test-without-building` 兩階段，第二階段產生的 `.xctestrun` 中 `BuyLedgerTests` target 完全沒有 `BaselinePath` 這個 key、且 `TREAT_MISSING_BASELINES_AS_TEST_FAILURES=NO`，`xcshareddata/xcbaselines/` 的基準檔永遠讀不到、`measure` 的比較邏輯不會觸發、測試恆為 passed。這是此工具鏈的結構性限制，顯式斷言是目前唯一能真正發火的作法。
- **門檻抓數量級退化，不是微小波動**：正常執行約 0.5 秒，門檻設在 3 秒 (約 6 倍)；改動此門檻時同樣要抓「慢一個數量級」的方向，不要抄舊基準檔的 10 倍餘裕 (10 倍餘裕在此工具鏈下等同恆真，先前已證實 1.1 秒的量測仍會通過)。
- **效能測試不進主回歸**：`BuyLedger.xctestplan` 的 `skippedTests` 已排除 `OrdersFeaturePerformanceTests`，避免機器負載造成無法重現的失敗；需要單獨執行才手動指定 `-only-testing:BuyLedgerTests/OrdersFeaturePerformanceTests`。

### Snapshot 測試 (swift-snapshot-testing)

Baseline 在 `BuyLedgerTests/__Snapshots__/`；`SnapshotTests.swift` 以 `#if canImport(SnapshotTesting) && os(iOS)` 包住，目前僅 iOS 393×852 baseline。record / commit 流程與設計大改重建見 [README.md › 執行測試](README.md#3-執行測試) 與本目錄 README 的 Troubleshooting。

**硬規則**：每個 snapshot test 必須用 `TestDependencies.withFixedNow { ... }` (`BuyLedgerTests/TestDependencies.swift`) 包住 view 建構與 `assertSnapshot`，注入固定 `\.date` (2026-04-30 UTC)；不要在測試裡直接 `Date()`。

### UI 自動化測試 (XCUITest)

`BuyLedgerUITests` target 走獨立 scheme，共用 Support 層 (`BuyLedgerUITests/Support/`)、Page Object (`BuyLedgerUITests/Screens/`) 與地基掛鉤。動這層時必守：

- **一律以 `accessibilityIdentifier` 定位、禁止用顯示文字或 `accessibilityLabel`**——App 支援中英切換，文字定位在英文模式整批失效。identifier 常數集中在 `BuyLedgerAccessibilityIDs/BLAccessibilityID.swift` (共用資料夾、同時編入 App 與 UITests 兩個 target)，兩端一律引用常數、不寫字面值。
- **identifier 只掛在「本身就是無障礙元素」的東西上**——按鈕、輸入欄、捲動容器、`accessibilityElement(children: .combine/.contain)` 後的容器。掛在單純的 `VStack` 這類版面容器上會把子元素全併吞、整塊只剩一個字串 (Dashboard 空狀態與 `BLLoadFailureView` 踩過，改掛 `.accessibilityElement(children: .contain)` 才保住內部按鈕)。
- **合併朗讀的列以 `accessibilityValue` 承載主要數值**——不要為了測試把 `.combine` 改成拆開的元素 (違反「複合列合併為單一朗讀單位」)；容器掛 identifier、數值放 `accessibilityValue`，測試以 identifier 定位後讀 `element.value`。XCUITest 中這類合併元素歸為 `staticText`，Page Object 查詢用 `app.descendants(matching: .any)[id]`、不要用 `otherElements`。
- **導覽列不掛 identifier**——SwiftUI 導覽列是 `NavigationStack` 建立的 `UINavigationBar`，identifier 掛不上；畫面就緒改以「畫面根容器 identifier」判定，導覽列由測試端 `app.navigationBars` 定位。
- **測試前必須以啟動參數指定資料與語言**——模擬器首次啟動是空狀態。以 `LaunchOptions` 指定 seed profile 與語言，經 `BLUITestConfiguration` 注入 in-memory container、固定時間、外部相依 test double；正式路徑不受影響 (整套 harness 以 `#if DEBUG` 圈住)。啟動掛鉤集中在 `AppLaunchConfigurator`。
- **外部相依一律走 test double**——`PhotoClient` / `CalendarReminderClient` / `ExchangeRateClient` 在 UI 測試模式換成不開系統彈窗、不打網路的替身；不依賴系統照片選擇器或行事曆權限。
- **不得以 `XCTSkip` 掩蓋 App 自身元素缺失**——找不到 App 元素一律 `failWithDiagnostics` (附截圖與可及性樹)。`XCTSkip` 只留給真正的外部環境差異 (系統文字選單等跨行程 UI)，且須寫明原因。
- **compact 與 regular 版面差異由 `AppNavigator` 吸收**——iPhone 走底部分頁列、iPad 走側邊欄。系統 tab bar 按鈕掛不上 identifier，分頁列版面依 `RootTab` 宣告順序取按鈕、再等目的地畫面根 identifier 確認 (受控例外)。
- **`LabeledContent` 的內建 value 在 XCUITest 讀不到**——要顯式加 `.accessibilityElement(children: .combine)` + `.accessibilityValue(...)` 才讀得到 `element.value` (開團詳情應收/已收、成本摘要卡踩過)。
- **`AlertState` (TCA) 系統 alert 掛不上 identifier**——這是平台限制 (受控例外，同 tab bar)。測試端以 `app.alerts.firstMatch` 判定呈現 (`alertPresented`/`alertDismissed`)、以 `tapAlertButton(label:)` 依按鈕文字點擊 (主回歸計畫已鎖語言故文字為決定值)。能自掛 identifier 的自訂 `.alert` 才用 `tapAlertButton(identifier:)`。
- **`Menu` 的 identifier 掛在 `Menu` 那層 (`} label: { } ` 之後)、不是 label 內的 `Label`**——掛在 label 內定位不到 (`app.buttons` 找不到)。選單內項目掛在各 `Button` 上，測試以 `tapMenuItem` 先展開再點。
- **`Picker(.segmented)` 的選項掛不上 identifier**——同 tab bar。identifier 掛在 `Picker` 本身，測試端以 `segmentedControls.buttons` 依列舉宣告順序 (`boundBy`) 取選項。
- **表單下半的數字欄會被別欄鍵盤蓋住而聚焦失敗**——建單流程在其他文字欄輸入前 (鍵盤未升起時) 先填數字欄；填完文字欄若被捲走，`swipeDown` 捲回頂端再輸入。數字鍵盤完成鍵一律掛 `Common.keyboardDoneButton` (含 OrderEdit/FX/Quote 各自的 keyboard toolbar)。
- **iPad 置中 sheet 上「僅差數點露於底緣下方」的欄位不可用整頁 `swipeUp` 捲入**——整頁 swipe 帶慣性、一次捲數百點，會把只差幾點的目標整個衝過頭捲離螢幕 (訂單編輯客戶實付欄踩過：iPad 開表單自動聚焦客戶名、該欄剛好落在表單底緣下方 3 點，整頁 swipe 一路衝到備註區使目標離屏)。改用 `Scrolling.scrollToHittableGently`：以固定短距、無慣性的 `press…thenDragTo` 逐步逼近，每步查可點就停。此 helper 要求目標已在樹上 (frame 有效)，離屏未渲染的惰性列仍走 `swipeUp` 查 `exists` 版。
- **`LazyVStack`/`LazyVGrid` 未渲染的離屏列 frame 無效**——查 `isHittable`/`waitUntilHittable` 會直接報錯 (非回 false)；只需確認存在時用 `swipeUp` 逐次捲動查 `exists`，不要查 hittability。照片縮圖列 (水平 `ScrollView` 內) 亦然：先 `swipeUp` 查 `exists` 把它捲入樹再查可點，否則列渲染未穩時查 hittability 會報「activation point invalid」而偶發 flaky。
- **訂單編輯表單的 TextField 有已知的間歇性 hittability 失敗，遇到單獨重跑即可，不要為此改測試碼或放寬斷言**：症狀是 `Waiting.swift` 的等待可點失敗並回報「`Failed to determine hittability of "<identifier>" TextField: Activation point invalid and no suggested hit points based on element frame`」。已實測確認它是隨機的、不是特定元素或特定測試的缺陷：同一台模擬器、同一份程式碼連跑兩輪，兩輪各有一條失敗但**失敗的測試與元素都不同** (一輪是 `KeyboardDismissTests.testNumericKeyboardToolbarDismissesKeyboard` 卡 `orderEdit.chargedAmountField`，另一輪是 `OrderCreateTests.testCreateOrderAppearsInList` 卡 `orderEdit.customerField`)，其餘 52 條皆綠。
    - **與模擬器是否 erase 過無關**：曾假設是 erase 後的狀態退化所致，以「從未 erase 的模擬器」做單變數對照後推翻 —— 未 erase 的機器同樣重現。
    - 與上一條的離屏列情形不同：離屏列是 frame 根本無效 (查 hittability 會直接報錯)，此處元素已在畫面上、只是判定間歇失敗。
    - 判讀方式比照 snapshot 的環境雜訊：**失敗清單在連續重跑間不一致**即是隨機性的證據；單獨重跑轉綠即可判定為雜訊。若某一條變成穩定重現，那才是真缺陷、要查根因。
- **push 目的地的返回鍵在 iPad 要 scope 到目的地那條導覽列**——iPad 側邊欄／清單／詳情各有自己的 `navigationBar`，`app.navigationBars.buttons.firstMatch` 會落在側邊欄的鈕、把整個 sheet 誤關 (照片檢視器返回踩過)。作法：先鎖定目的地的導覽列 (照片檢視器以其標題含 `/` 的換頁計數認出)，再點其返回鍵。SwiftUI 系統返回鍵帶穩定且語言無關的 identifier `BackButton` (`Common.backButton`)，可用來定位。
- **UI 測試僅覆蓋 iOS 26.x 模擬器**——`BuyLedgerUITests` target 部署目標為 26.x，不覆蓋 iOS 18。
- **測試計畫**：主 scheme 掛 `BuyLedger.xctestplan` (鎖 zh-Hant/TW、字母序執行、覆蓋率僅統計 App target)，取代舊有的自動建立測試計畫設定：單元測試的語言與地區從此由計畫決定，不再受模擬器系統狀態影響；UI 主回歸 `BuyLedgerUITests.xctestplan` (鎖 zh-Hant/TW、關閉隨機順序、排除效能測試)；效能獨立 `BuyLedgerUITests-Performance.xctestplan`。三份計畫皆以物件形式只把 App target 設為覆蓋率統計對象、不設門檻，測試完成後可由結果套件查得覆蓋率數字。目前主回歸涵蓋全 App 各區域流程 (根導覽、總覽、訂單清單/篩選/詳情/建單/編輯/合併、開團 CRUD/詳情、客戶、分析、匯率、報價、AI 總結、照片檢視)。
- **跑完整功能回歸別靠 `--extra-args -testPlan`**——xcodebuildmcp CLI 的 `test` 不理會經 `--extra-args` 傳入的 `-testPlan`，會退回 scheme 預設計畫 (效能計畫，只含 `LaunchPerformanceTests`)。要跑全功能回歸改用 `--extra-args -only-testing:BuyLedgerUITests --extra-args -skip-testing:BuyLedgerUITests/LaunchPerformanceTests` (整個 target 減效能)；跑單一類別直接 `-only-testing:BuyLedgerUITests/<類別>`。

## 環境相依性與依賴注入

root `CLAUDE.md` 的注入原則在本平台的具體落地：production code **一律走 `@Dependency`，不可直接呼叫 `Date()` / `UUID()` / `Locale.current` / `TimeZone.current` / `Calendar.current`** (除了 dependency 註冊處本身)。

具體規則：

- TCA Reducer：在 `// MARK: - Dependency Properties` 區塊加 `@Dependency(\.date) private var date` 等；reducer body 中以 `date.now`、`uuid()` 取值。
- SwiftUI View：同樣可加 `@Dependency(\.date) private var date`，在 view body 或 helper method 中以 `date()` / `date.now` 取值。
- State 上的 computed property 不可內部呼叫 `Date()`——改成 `func foo(referenceDate: Date) -> ...` 由 caller (reducer 或 view) 以注入後的 date 傳入。

測試端：`TestStore` 用 `withDependencies: { $0.date = .constant(TestDependencies.fixedNow) }`；snapshot test 用 `TestDependencies.withFixedNow { ... }`。Calendar 相關測試需要固定 `TimeZone(secondsFromGMT: 0)` 與 `Calendar(identifier: .gregorian)` 確保跨機器一致。

## 安全性與設定注意事項

- **目前專案無 entitlements 檔**：日後若加 App Groups / CloudKit / Push 需新增 entitlements 檔並在 pbxproj 掛上 `CODE_SIGN_ENTITLEMENTS = BuyLedger/Resources/BuyLedger.entitlements;` build setting，否則 binary 上只會出現 Xcode 自動加的預設 key，runtime 會抓不到設定的 entitlements 並出現難以診斷的錯誤。
    - CloudKit container、`aps-environment` 等 entitlement key 等 Apple Developer 帳號實際 provision 後再加；未 provision 時加上會讓 codesign 失敗。CloudKit container、iCloud capability 與 entitlements 的變更需要在 PR 中明確說明。
- **App 沒有資料匯出或備份出口，store 三件套維持系統預設保護等級 (裝置首次解鎖後即維持可讀)，是已評估並由使用者裁定不採用的結果，非疏漏**：曾規劃使用者主動匯出全量備份、以及對 store 追溯套用最高等級靜態保護兩項能力 (`data-export-and-file-protection`)，經審視後裁定不採用；store 內含客戶姓名、備註與內嵌照片，此決策已使用者知悉並接受。未記錄的省略不得僅因無人反對而視為已接受，本條即是該項記錄。
    - 持久層開啟失敗時的救援路徑不受此影響：`PersistenceFailureFeature` 的逃生門是自有的隔離備份搬移 (把開不起來的 store 搬到裝置備份目錄、資料不刪除)，不依賴匯出功能，見上方「SwiftData Schema 與 Migration」的「持久層 fallback」。

## Firebase (遙測底座、無雲端同步)

移除 Web/Backend 後，Firebase 僅作崩潰與使用分析的遙測底座，App 為純本機 (資料唯一來源為 SwiftData、`PersistenceContainer.shared`、CloudKit `.disabled`)。

- **target 僅 link `FirebaseCore` / `FirebaseCrashlytics` / `FirebaseAnalytics` / `FirebasePerformance`** (皆監測類)；`GoogleService-Info.plist` 放在 `BuyLedger/Resources/` (gitignored)。啟動時 `AppLaunchConfigurator.configure()` 呼叫 `FirebaseApp.configure()` 完成初始化，無登入、無 Firestore、無 Auth/Storage/Messaging。
- **遙測強制開啟、不提供使用者設定**：App 產物不對外散布、僅安裝於開發者自己的裝置 (見上方「安全性與設定注意事項」)，不涉及第三方使用者的同意權議題，故設定頁不含任何遙測相關 UI，`isTelemetryEnabled`／`telemetryToggle` 於全樹零命中。分析收集初始值在 App 自身 `Info.plist` 的 `FIREBASE_ANALYTICS_COLLECTION_ENABLED`；`GoogleService-Info.plist` 的 `IS_ANALYTICS_ENABLED` 在 iOS 無效，不得留下來暗示它能關閉 Analytics，Firebase Console 重新產生設定檔時若帶回該旗標仍須移除。揭露只留在 `PrivacyInfo.xcprivacy`，不在畫面上重複陳述。
- **`TelemetryClient` (`Core/Dependencies/TelemetryClient.swift`) 兩個方法皆不帶參數**：`enablePreInitializationCollection()`／`enableCollection()` 呼叫即代表啟用，不留 `Bool` 參數——遙測強制開啟後若保留參數，呼叫端只會恆傳 `true`，屬新的「零呼叫點殘留」。`enableCollection()` 於每次啟動的初始化後都無條件呼叫，藉此覆寫裝置上任何殘留自舊版「可關閉遙測」時期的停用狀態 (Analytics／Crashlytics 的執行期開關會持久化，只呼叫一次無法保證覆寫掉更早之前的關閉紀錄)。
- **Performance 的自動埋點必須早於 Firebase 初始化設定**：`AppLaunchConfigurator.configure()` 維持 UI 測試 guard 在最前，之後直接呼叫 `TelemetryClient.liveValue.enablePreInitializationCollection()` 設定 Performance 的自動埋點初始狀態 (不經尚未建立的相依注入容器)，再呼叫 `FirebaseApp.configure()`；初始化後才呼叫 `TelemetryClient.liveValue.enableCollection()` 套用 Analytics、Crashlytics 與 Performance 的執行期開關 (Performance 因此被套用兩次：初始化前那次決定自動埋點的起始值，初始化後這次只是重申同一個固定值，兩次不衝突)。碰 `Performance.sharedInstance()` 的地方只有 `TelemetryClient` 這一處，`AppLaunchConfigurator` 不直接呼叫 Performance API。這條順序要求不因遙測改為強制開啟而鬆動，不可因為值變成常數就把這步拿掉而改成初始化後才設。
- **保留四個 Firebase 產品但目前零自訂埋點，屬已知落差**：`FirebaseCore`／`FirebaseCrashlytics`／`FirebaseAnalytics`／`FirebasePerformance` 四個產品目前沒有任何自訂事件、使用者屬性或自訂效能追蹤，收集的全是各 SDK 的預設自動收集內容；未縮減連結面是刻意決策 (保留日後可能用到的彈性)，此落差記錄於此，作為日後重新評估是否縮減連結面的依據。
- **`OTHER_LDFLAGS = "-ObjC"` 與 pbxproj 的「Run Script: Crashlytics Symbol Upload」build phase 不可移除**——它執行 `firebase-ios-sdk/Crashlytics/run`，移除 firebase-ios-sdk 套件或 Crashlytics 產品卻不刪此 build phase 會使腳本路徑消失、build 直接失敗。
- 加 SPM 產品一律用 Xcode 操作、勿手改 pbxproj。
- **`GoogleService-Info.example.plist` 僅供 CI 使用、不是本機開發用的範本**：本機開發仍使用真實 `GoogleService-Info.plist` (gitignored)，不要拿範本檔覆蓋它。
    - 崩潰成因：單元測試以 App 為宿主，宿主啟動就會呼叫 `FirebaseApp.configure()`，乾淨 clone 缺 `GoogleService-Info.plist` 會讓宿主直接崩潰、CI 整組測試全紅。
    - 此檔的值一律是明顯假字串 (不含任何真實識別碼)，已列入 `BuyLedger` folder 的 `PBXFileSystemSynchronizedBuildFileExceptionSet` 成員例外清單，不會被打包進 App bundle。
    - CI 於建置前複製成正式檔名。
- **`PrivacyInfo.xcprivacy` (`BuyLedger/Resources/PrivacyInfo.xcprivacy`) 能進產物的唯一原因是它沒有被列進 `PBXFileSystemSynchronizedBuildFileExceptionSet.membershipExceptions`**：與它同目錄的 `Info.plist`／`Config.xcconfig`／`Config.example.xcconfig`／`BuyLedger.entitlements`／`GoogleService-Info.example.plist` 全部都在那份排除清單裡 (各自有專屬的 build setting 或 CI-only 用途)，只有隱私清單刻意不排除，讓 file system synchronized group 把它當一般資源自動收進 bundle。日後若有人「為了一致」把它也加進排除清單，清單會**靜默**從 bundle 消失；本機 build 不會報錯，只有送審時才會被 Apple 擋下。新增／移除 `Resources/` 下的檔案或調整這份排除清單時，務必確認 `PrivacyInfo.xcprivacy` 仍在名單之外。
- **改動 Firebase 產品組合 (新增或移除連結的 SDK) 時必須同步更新 `PrivacyInfo.xcprivacy`**：`NSPrivacyCollectedDataTypes` 與 `NSPrivacyTrackingDomains` 的宣告要與實際連結的產品逐項相符，不可多宣告也不可漏宣告 (見 `PrivacyManifestTests` 與 openspec `telemetry-transparency` spec)。
