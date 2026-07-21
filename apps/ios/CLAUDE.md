# Apple 平台指引 (iOS / iPadOS)

本檔記錄 Apple 平台 (apps/ios) 的硬規則與隱性 gotcha；跨平台通用規範 (產品政策、標點、註解、Commit 風格等) 見 repo 根目錄的 [`CLAUDE.md`](../../CLAUDE.md)，產品介紹與 monorepo 結構見根目錄 [`README.md`](../../README.md)，平台環境設定與 build / test 見本目錄 [`README.md`](README.md)。

## 主要技術棧

- **Swift 6 strict concurrency**：專案層級 `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated` (不是 `MainActor`)。改成 `MainActor` 會讓 SwiftData `@Model` 與 `@ModelActor` 編不過。需要 main actor 才安全的型別請對個別宣告加 `@MainActor`。
- **TCA Reducer body** 使用顯式 `some Reducer<State, Action>`，不可用 `some ReducerOf<Self>` (會 circular reference)。
- **`IPHONEOS_DEPLOYMENT_TARGET = 18.0`**：`EnumeratedSequence` 對 `RandomAccessCollection` 的條件遵循是 iOS 26+ 才具備，`ForEach` 直接吃 `x.enumerated()` 會編不過 (「conformance of 'EnumeratedSequence' to 'RandomAccessCollection' is only available in iOS 26.0 or newer」)。`ForEach(indexed:)` 一律包 `Array(x.enumerated())`，不要為了「現代化」拿掉 `Array()`。

## 文件查證準則

- Apple 原生框架 (SwiftUI、SwiftData、CloudKit、Swift Charts、Xcode 工具鏈) 除了 Context7 之外，另外用 **Apple docs MCP** 對照；兩邊文件矛盾時不可自決，先列差異與建議選項問使用者。

## 建置、測試與開發指令

本平台必守鐵則：

- 絕不退回原生 `xcodebuild` / `xcrun` / `simctl`。
- **任何 build 前先把 build number +1**——凡 build / build-and-run (不論 simulator / device、不論 MCP 工具或 CLI)，執行前必須先跑 `cd apps/ios && agvtool next-version -all`，將 `CURRENT_PROJECT_VERSION` (即 CFBundleVersion，相當於 Android 的 versionCode) 遞增 1；**跑 test 不遞增** (test binary 不會被安裝或散佈，遞增只製造 pbxproj 雜訊)。`agvtool` 是上一條「絕不退回原生工具」的明文例外 (版本管理不在 XcodeBuildMCP 能力範圍)。同一輪驗證中以 `&&` 串接的多平台 build 視為一次、只遞增一次；遞增產生的 pbxproj 變更隨當次工作一併 commit，不可丟棄。
- iOS 與 iPadOS simulator build 共用同一份 `DerivedData/.../XCBuildData/build.db`，**不能並行**——請序列化 (`cmd1 && cmd2`)，否則 `database is locked`。
- 詳細 build error 要加 `xcodebuildmcp --log-level error <subcommand> ...`，否則 CLI 只回 trailing `BUILD FAILED`。
- simulator 名稱不要寫死，跑 build-and-run 前先 `xcodebuildmcp simulator list-sims` 查當前可用名稱。
- **跑 snapshot 測試前把模擬器外觀鎖淺色** (`xcodebuildmcp simulator-management set-appearance --mode light`)：模擬 OS 的自動外觀入夜會切深色，淺色 baseline 會整批 false-fail (差異圖整張變色即此因，非程式碼回歸)。
- 模擬器跑 App 用 `build-and-run`，不要先 `build` 再 `build-and-run`。

## App 進入點與平台導覽

動到這層程式碼時請遵守：

- **啟動時的服務初始化集中在 `AppLaunchConfigurator.configure()`** (Firebase Analytics / Crashlytics / Performance)——iOS / iPadOS 的 `AppDelegate` 在 `didFinishLaunching` 呼叫它，新增啟動設定請加在這裡，不要散落各進入點。Firebase 依賴 pbxproj 的 `OTHER_LDFLAGS = "-ObjC"`，不可移除。
- **跨頁觸發新訂單**請使用 `RootFeature.Action.startNewOrder`：reducer 會同時把 `selectedTab` 切到 `.orders` 並把 `OrdersFeature.State.editOrder` 設成空白草稿。從非 `.orders` 分頁直接設 sheet state 會發生 view-not-in-hierarchy 的 race——`.sheet(...)` 修飾子掛在 `OrdersView` 上，當下不在 hierarchy 就不會 mount。
- **`OrdersView` 的 `.sheet(item: $store.scope(state: \.editOrder, action: \.editOrder))`** 一律掛在 `OrdersView` 外層，iPhone / iPad 共用——不可移到平台分流後的子 view 裡。
- **兩種尺寸都不要用 `.toolbar` 的 `.bottomBar`**：批次／選取類操作一律放 `.primaryAction` 等頂部 placement，筆數等資訊由 `navigationTitle` 承載 (compact 與 regular 共用 `OrdersFeature.State.navigationTitleKey`)。
    - compact：`RootTabLayout` 的底部 tab bar 會蓋掉 `.bottomBar`，工具列項目在實機上看不到。
    - regular (iPad)：可拖曳視窗的下緣可能超出螢幕而遮住整條工具列。
- **App 內切換語言後的根分頁 `navigationTitle`**：iOS 18+ 不會可靠地讓 `navigationTitle` 隨 `\.locale` 重新解析 String Catalog。Dashboard、Orders、Campaigns、Insights、More 與 Settings 一律以必填 `language` 參數呼叫 `rootNavigationTitle(_:language:)`，由 `AppLanguage.localized(_:)` 先從對應 `.lproj` bundle 解析再交給原生 `.navigationTitle(_:)`；Orders 的多選三態 key 必須由 `OrdersFeature.State.navigationTitleKey` 計算屬性衍生。RootView 僅保留 `\.locale` 注入給一般 SwiftUI 文案與格式化器；`Tab(LocalizedStringKey)` 不需要此 workaround。
- **`Text(字串變數)` 不會本地化 (英文模式露中文)**：`Text("字面值")` 與 `Text(LocalizedStringKey(x))` 會走本地化，但 `Text(someString)` (參數型別 `String`) 走 verbatim init。凡把「固定中文詞」經 `String` 變數丟進 `Text` / `Label` / `navigationTitle` 都要包 `LocalizedStringKey(...)`——可重用元件 (`BLBadge`) 內部已比照，`BLStatusPill` / `BLProgressBar` / `BLDonutChart.centerTitle` 本就有包。帶插值的中文 (如 `\(count) 件進行中`) 必須走 `Text(LocalizedStringKey("\(count) …"))`——SwiftUI 的 `Text(LocalizedStringKey)` 才會隨注入的 `\.locale` 解析;**不可用 `String(localized:locale:)`**，它走系統語言 bundle、不吃 App 內語言切換 (Dashboard KPI delta 曾因此在英文模式露中文)。若字串經參數傳遞，把參數型別設為 `LocalizedStringKey` (不是 `String`)、由 `Text` 端解析 (參考 `DashboardView.kpiTile(delta:)`)。**使用者資料 (主檔名稱、`customer.name`)、格式化數字/日期維持 verbatim**、不可包 `LocalizedStringKey`。
- **新增任何 UI 字串都要同步補 `Localizable.xcstrings` 的 `en`**：新寫的中文字面值 (含 TCA `AlertState`／`TextState`、`Button`／`Text`／`accessibilityLabel` 等) 若沒補英文，英文模式會露中文 fallback (F1 捨棄變更 alert 曾漏)。`AlertState`／`TextState` 一樣走 catalog 本地化 (資料來源同 `Text(LocalizedStringKey)`)，補齊 `en` 即修好。手動補 catalog 用**文字插入** (在 `"strings"` 物件內加展開格式的 entry)、**不要全量 `json.dump` re-serialize**——`.xcstrings` 是 Xcode 自訂序列化 (部分 entry 單行、部分展開)，全量重寫會格式不吻合、產生巨量 diff 且 Xcode 下次開檔又重排。`LocalizationCatalogTests.catalogContainsCompleteTraditionalChineseAndEnglishValues` 只驗 catalog 內既有條目完整，**抓不到「code 有用但 catalog 沒收錄」的漏字**，故新增字串要人工確認有進 catalog。

## 資料層與 Dependency 注入

- **`liveValue` 不自動 seed sample 資料**——使用者首次啟動是真正的空狀態 (Dashboard 顯示 `onboardingHero`、Insights 顯示空狀態 `ContentUnavailableView`、Orders 顯示「沒有符合條件的訂單」)。
- **`previewValue`** 使用 in-memory container 並傳 `seedSampleOrdersIfEmpty: true`，讓 SwiftUI Preview 與 snapshot 測試看得到內容。
- **`LedgerOrder.sampleOrders`、`FxRateSnapshot.fallback` 與 `FxRates`** 僅供 Preview / 單元測試 / `previewValue` 使用，runtime path **不應讀取**。
- **`@ModelActor` init 帶 main actor 隔離**——actor 實例必須在 `async` context 才能建立。參考 `OrderRepository.makePersistence(container:)` 用 `MainActor.run { ... }` 跳上 main 取得 actor 後再回到原 task。
- **多個 repository 共用單一 `ModelContainer`**——`Core/Dependencies/` 下所有 `*Repository` 的 `liveValue` 一律走 `PersistenceContainer.shared`，**不可各自呼叫 `makeForApp()`**；同一 process 內並存多個 container (即使底層 SQLite 同名) 會造成 SwiftData 內部狀態錯亂。
- **Repository 一律以 type-based `@Dependency(SomeRepository.self)` 注入**——新 repo 不再新增 `DependencyValues` keyPath；reducer 在 `// MARK: - Dependency Properties` 宣告 `@Dependency(OrderRepository.self) private var orderRepository`。
- **主檔 (訂單來源／商品類別／付款方式) CRUD 走 `LookupManagementFeature`** (以 `LookupKind` 分流共用同一份 reducer/view)，它只負責寫各自的 DB 主檔表。**cascade 到 `OrdersFeature.State` 的 in-memory master 副本 (`orderSourceMaster` / `categoryMaster` / `paymentMethodMaster`) 與訂單表的 rename，由 `RootFeature` 攔截 `renameRequested` / `addConfirmed` / `deleteRequested` 處理**——新增主檔型別或動到 cascade 時這兩處都要顧。
- **`LedgerOrder` 是 immutable struct**——cascade rename 等要改任一欄位時必須用 memberwise init 重建整筆 (參考 `RootFeature.rebuildOrder`)，不可就地 mutate。
- **Reducer body 內呼叫 State 上的 instance method** 必須走 `store.state.method(...)`，不可透過 `@dynamicMemberLookup` 的 `store.method(...)`。

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
  - 現況 floor V15 即把對帳狀態改名前的 `OrderRecord` 與 `VerificationStatusRecord` 凍結為影子。
- **遷移方式**依改動類型選擇：
  - 加欄位／加表 → `.lightweight`；改既有欄位型別 → `.custom` dump-and-restore。
  - 改欄位名 → `@Attribute(originalName:)` (lightweight，底層欄位名不變)。
  - 改 `@Model` 類別名 (=entity 名) → 必須 `.custom`：SwiftData **無 entity 級 originalName**，類別改名等同新 entity、舊表資料不自動帶入。凍舊 shadow 後於 `.custom` 的 `willMigrate` 讀舊 entity 暫存 (`nonisolated(unsafe) static`)、`didMigrate` 寫新 entity (兩 closure 各只見舊／新 schema)。
- **移除舊版本是單向操作**：forward-only，移除會把 floor 往上抬，停在低於新 floor 的 store 失去遷移路徑、開啟時 `makeForApp()` 砍檔。
  - 只在確定無 store 停在被移除版本時才可移除；上架後此前提幾乎不成立、須保留完整版本鏈。
  - 「已在 target 就安全」是 per-device 結論：目前 CloudKit `.disabled` 故成立；啟用 sync 前須重評 (離線舊版第二台裝置升級同樣砍檔、刪除可能經 sync 傳播)。
- **`makeForApp()` fallback** (清舊 store 重建 → 退 in-memory) 是開發期救援：要保資料請補正確 migration stage、勿依賴這段砍檔。

## 外部 API 實作

- 幣別清單經 `CurrencyMetadataRepository.refreshIfStale(604_800)` 打 `/codes` 並 cache 7 天 (動態載入、不可 hardcode 的政策見 root `CLAUDE.md`)。

## 行事曆整合 (EventKit)

開團訂購提醒經 `CalendarReminderClient` (`Core/Dependencies/`，比照 `PhotoClient` 的 system-call client 範本) 寫入／移除系統行事曆。硬規則與 gotcha：

- **必須請求 full access、不能只用 write-only**——「移除提醒」需先 `event(withIdentifier:)` 讀回事件才能刪，write-only 讀不到事件。故走 `requestFullAccessToEvents()`，Info.plist 帶 `NSCalendarsFullAccessUsageDescription` (權限在實際新增／移除的當下才請求，非啟動即請求)。
- **campaign 連結存 iOS-only 的 `CampaignReminderRecord` (SwiftData 表)，不入跨平台 `Campaign` schema**——記 `eventIdentifier` 與使用者自選的提醒時間戳 `reminderTimestamp` (Date)；行事曆識別碼是裝置本機資料，寫進跨平台生成型別會違反平台中立原則且與 CloudKit 耦合。此表於 v1.5.0 建立並演進為使用者自選的 `reminderTimestamp` (當時的 V13 建表、V14 加提示時間、V15 改 `reminderTimestamp` 皆 lightweight；V13/V14 已隨 floor 收斂到 V15 而移除)。連結資料以 `CampaignReminderLink` 值型別在 repository / reducer 間流轉。
- **提醒日期＋時間由使用者自選、以時間戳保存**：不再自動掛結單日。事件為**全天事件** (`isAllDay`)，事件日期＝`calendar.startOfDay(for: reminderTimestamp)`，提示 (`EKAlarm(relativeOffset:)`) 以該時間戳的當天分鐘數換算秒數 (`Campaign.reminderTitle` 提供標題)。新增／編輯開團頁點「新增提醒」以 sheet (graphical `DatePicker([.date, .hourAndMinute])`、`presentationDetents([.fraction(0.7)])` 螢幕 70% 高，狀態/流程全在 reducer、view 只送 action) 選日期＋提示時間 (預設結單日／今天 09:00)，儲存時 reconcile (名稱或時間戳變更即重建事件)；**開團詳情頁純顯示**該提醒時間戳、不提供新增／移除 (管理走編輯頁)。

## 程式風格 Apple 補充

通用標點、註解語言與 Commit 風格見 root `CLAUDE.md`；以下是 Swift / SwiftUI / TCA 專屬規則。

### 結構與命名

- **商業邏輯／資料計算** (彙總、分組、排序、格式化) 一律放 reducer 或可測試的 feature helper；SwiftUI View (含 Swift Charts) 只負責呈現，不要把計算 inline 在 view body。
- **綁 store 的 View 不持有 presentation 狀態**——sheet／picker 呈現開關、編輯草稿、選取焦點、導覽路徑等一律下放對應 `Feature.State`，以 `$store.xxx` binding 綁定，不留 `@State`。Feature 未採 `BindableAction` 時，先讓 `Action` conform `BindableAction` 並在 reducer body 最前加 `BindingReducer()` (與既有 `.ifLet`／`.forEach` 正交、可並存)；導覽堆疊用 `StackState`。若某 `.binding` 帶副作用 (如 `SettingsFeature` 在 `.binding` 存檔)，對純 UI 欄位用 `case .binding(\.showsXxx): return .none` 排除，避免開 sheet 就觸發副作用。**例外**：不綁 store、以 closure 與 caller 溝通的可重用元件 sheet (`OptionPickerSheet`／`PaymentMethodEditorSheet`／`LookupNameEditorSheet` 等) 的本地 `@State` 屬元件內部狀態，不在此列。
- **TCA feature** 內部用 `// MARK: - State / Action / Dependency Properties / Reducer Body` 等清楚切分 (順序見「MARK 區段與排版」一節的對照表)。
- **Swift/SwiftUI 內建型別的通用 extension 放 `Shared/Extensions/`**，一型一檔，檔名 `<型別>+Extensions.swift` (如 `Image+Extensions.swift`、`Color+Extensions.swift`)。**與特定 DesignSystem 元件或功能耦合的 extension 不搬到這裡、留在該元件檔**：「套一層 modifier 就回傳」的 `View` 方法 (`blCardShadow()`／`blTextStyle()`) 與其 `ViewModifier` 同檔、`ButtonStyle where Self == BLButtonStyle` 的工廠留在 `BLButtonStyle.swift`。判準：可獨立重用的通用 helper 才進 `Shared/Extensions/`。
- **不用 `switch`／`if` 運算式賦值**：避免 `let x = switch … { … }` / `let x = if … { … }` 這種運算式寫法；改用傳統陳述式 (先宣告 `let x: T`，再於各分支賦值)。若該計算寫在 `@ViewBuilder` body 內會與 result builder 衝突，請抽成獨立 helper 回傳該值，view body 只呼叫 helper。
- **`Label` 放在 `Form`／`List` row 內且後接 `Spacer`**：自動 label style 會把 icon 與 title 撐到 row 兩端 (icon 與文字中間出現大空隙)，須加 `.labelStyle(.titleAndIcon)` 讓兩者貼合 (`RootSidebarLayout` nav row、`CampaignEditView` 訂購提醒按鈕皆然)。
- **sheet 遵循 Apple HIG「Sheets」兩條硬規則** (依 HIG 合規審視落地)：
  - **編輯類 sheet 防未儲存變更靜默遺失**——訂單／開團／付款方式編輯 sheet 一律加 dirty 判斷 (feature 用 draft fingerprint 值型別對照初始基準、closure 元件用初始值快照)，sheet 掛 `.interactiveDismissDisabled(<isDirty>)`，取消鍵於 dirty 時改彈「捨棄變更／繼續編輯」確認。確認一律用 `AlertState`／`.alert` (centered modal)，**不用 `.confirmationDialog`**——取消是 toolbar 按鈕，iOS 26 起 `.confirmationDialog` 對 toolbar 觸發會位置偏移。
  - **不從 sheet 內再疊 sheet**——已呈現的 sheet 內開選擇器或子表單，用 push 或置中 overlay、不疊第二層 sheet。
    - **選擇器走 push**：`OptionPickerSheet`／`PaymentMethodEditorSheet` 有 `isEmbedded` 參數：預設 `false` = 自帶 `NavigationStack` 的單層 sheet (主介面呼叫點不變)，`true` = 去 `NavigationStack`／sheet 專屬修飾／取消鍵、由宿主 Back 返回。訂單編輯以單一 `OrderEditFeature.State.PickerRoute` enum + `navigationDestination(for:)` 驅動所有選擇器 (避開 `navigationDestination(item:)` 的 test-target 連結踩雷，見下「測試準則」相關 memory)。
    - **開團訂購提醒選擇器走 Form 內 inline `DatePicker`** (最貼 HIG，經 push → 置中自製對話框兩版被使用者否決後定案)：`CampaignEditView` 以 `Toggle("訂購提醒", isOn: $store.wantsReminder)` + 條件顯示的 inline `DatePicker(selection: $store.reminderTimestamp, displayedComponents: [.date, .hourAndMinute])` 呈現，與上方開團／結單日期列同款、點擊跳系統原生月曆／時間浮層。因此無獨立呈現、根本不涉「疊 sheet」；提醒時間戳即表單草稿、隨整張表單儲存/取消落地 (F1 dirty 已涵蓋)。**不要**為此再自製 sheet/push/overlay 對話框。

### Dynamic Type 與無障礙

- **無障礙字級要改版面結構，不是用縮放係數把字壓回去**——`minimumScaleFactor`／`lineLimit(1)` 抵銷了使用者的字級設定。以 `@Environment(\.dynamicTypeSize)` 的 `isAccessibilitySize` 判斷 (不要逐級列舉 case，系統新增級距時會失效)，在無障礙字級下解除單行限制、允許換行，並降維：多欄格降為單欄 (`DashboardView.kpiColumns`)、橫排三欄改為堆疊 (`OrderRowView`)。
- **固定點數的尺寸一律 `@ScaledMetric`**——圖示、格高、欄寬、圖表直徑都要隨字級長大，否則字放大後被容器截斷。`@ScaledMetric` 需要 view 實例，因此原本的 `static let` 尺寸常數要改成實例屬性。
- **複合列合併為單一朗讀單位**——由多個子元素組成的列 (訂單列、開團列、KPI 格) 加 `.accessibilityElement(children: .combine)`，否則輔助技術要逐一走過每個子元素。合併前先把純裝飾元素 (色點、與相鄰文字重複的頭像) 標 `.accessibilityHidden(true)`，避免它們被併進朗讀內容。
    - 可重用元件用參數表達裝飾與否 (`BLAvatar.isDecorative`)，而不是在呼叫端外層硬蓋 `accessibilityHidden`。
- **格狀資料的每一格要有座標**——熱力圖等格狀元素的 label 須帶「哪一列哪一欄」，否則輔助技術只會朗讀出一連串沒有位置的數字；空值格子直接排除於無障礙樹，整張圖另給一句摘要。
- **新增動畫一律先過減少動態效果判斷**——`@Environment(\.accessibilityReduceMotion)` 為真時傳 `nil` 給 `.animation(_:value:)`。判斷放在動畫來源處 (`ButtonStyle` 等元件內) 統一處理，不要散在各呼叫端。

### 導覽與呈現

- **每個目的地只有一條抵達路徑**——清單點擊與深連結必須寫入同一條路徑。「更多」分頁以 `RootFeature.MoreRoute` 值導向堆疊驅動 (`NavigationStack(path:)` + `navigationDestination(for:)`)，深連結時於同一次狀態更新內先清空再推入。
    - 用值導向堆疊而非「呈現旗標 + 去重判斷」：後者只是把不合法狀態擋掉，前者讓它根本無法表達。
- **選取狀態單一來源**——同一個清單裡的不同項目類別要併進同一個選取型別 (參考 `RootSidebarLayout.SidebarSelection`)，系統才只會高亮一列；兩套選取機制並存必定同時高亮。
- **任一時刻只呈現一層 modal**——同一畫面的多個 sheet 併進單一 `@Presents` destination 列舉，以單一呈現點依型別分派 (參考 `LookupManagementFeature.Destination`)，互斥由型別系統保證，而非多個並列的 `.sheet` 修飾子各自靠布林避讓。
    - 已在 sheet 內要再開子畫面時走 push、加入既有的路徑列舉即可 (訂單編輯的照片檢視與各選擇器共用 `PickerRoute`)。
- **push 目的地不可自帶 `NavigationStack`**，巢狀 stack 會讓推進呈現與 pop 動畫整個壞掉 (照片檢視改 push 時踩過：元件從 modal 改 push 呈現，務必連元件本體的 stack 一起拆)。嵌入元件比照 `OptionPickerSheet` 的 `isEmbedded` 模式：不自帶 stack、不設關閉鈕，標題掛在內容上、由宿主堆疊的 Back 返回。
- **alert 不拿來裝表單**——alert 的職責是傳達需要立即決策的關鍵資訊。有輸入框或開關的流程一律用 sheet 內表單 (`LookupNameEditorSheet`／`PaymentMethodEditorSheet`)；alert 的 actions builder 只支援 `Button`／`TextField`，塞 `Toggle` 會被靜默丟棄。
- **不要 `navigationBarBackButtonHidden(true)` 自繪返回鍵**——會連帶停用邊緣滑動返回。要讓返回鍵只顯示符號而不顯示可能過期的標題，用 `.toolbarRole(.editor)`。
- **不可逆的狀態轉換比照刪除加確認**——結團等寫入後無法改回的操作，與刪除同級：先以 `AlertState` 確認、文案點明不可復原，確認後才寫入。
- **破壞性操作：先確認、再寫入、寫入成功才改狀態**——確認一律用 `AlertState`，文案點明後果與不可復原。狀態更新放在寫入成功的 action 裡，不做樂觀更新加回滾；「先寫後改」從根本消除狀態與資料庫不一致的可能，也不必維護回滾邏輯。

### 焦點與鍵盤

- **收鍵盤有三條路徑，且不得以全域攔截加排除清單實作**：一般鍵盤的 return 鍵、數字鍵盤的鍵盤工具列 (`ToolbarItemGroup(placement: .keyboard)`)、以及 `scrollDismissesKeyboard(.interactively)`。每個有輸入的畫面至少要有兩條。
    - **不要再掛 window 級手勢**：舊實作 (`dismissKeyboardOnTap()`) 對所有觸控先攔一次、再靠黑名單沿 superview 逐層排除互動元件，而黑名單永遠追不上系統新增的 view 型別 (曾誤觸貼上／選取等系統 action)，已移除。
    - **「點背景收鍵盤」在本專案不可行，不要再嘗試**：以 `.background { Color.clear.contentShape(.rect).onTapGesture { … } }` 承接的作法，在 `Form`／`List` 與 `ScrollView` 版面均**經介面測試證實收不到觸控** (`Form` 即使加 `.scrollContentBackground(.hidden)` 亦然)——這些容器會消耗空白處的觸控且不向下傳遞。
    - 收鍵盤一律把焦點設為 `nil`／`false`，不呼叫 UIKit 的 `endEditing`——讓收鍵盤與焦點成為同一個狀態的兩面。
    - 用系統 `.searchable` 的畫面另有 Cancel 鈕與捲動收合，由系統提供。
    - **UI 測試走獨立的 `BuyLedgerUITests` scheme**——主 scheme 只含單元測試以維持快速回圈；`KeyboardDismissTests` 守住「點系統文字選單不收鍵盤」與「點互動控制項不收鍵盤」兩條行為。
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
- `#Preview` 放在檔案最後，前方加上 `// MARK: - Preview`。

建立新 Swift 檔案時，invoke `/swift-file-template` 取得檔案 header 格式與 View / 非 View 型別 / TCA Reducer 的具體程式碼範本。

## Design System 準則

- Design System 放在 `apps/ios/BuyLedger/Shared/DesignSystem/`，並區分 `Foundations/` 與 `Components/`。`Foundations/` 放跨元件共用的 token、modifier 與語意模型；`Components/` 放可視 UI 元件，並依類別建立子資料夾。
- 每個主要元件或資料型別原則上各自一個 Swift 檔案，檔名必須對應主要型別名稱 (例如 `BLBarChart.swift`、`BLDonutChart.swift`、`BLSparkline.swift`、`BLFilterChip.swift`)。避免建立 `BLCharts.swift`、`BLTextFields.swift` 這類同時涵括多種元件的大檔。若小型 enum 或 extension 只服務單一元件，可以與該元件同檔；若開始跨元件重用或變大，請拆出獨立檔案。
- 每個可視 Design System 元件都應提供自己的 `#Preview`；需要 binding 時使用 `.constant(...)`，需要圖表或狀態資料時用小型 sample data。
- 調整 Design System 結構或元件後，請至少執行 iPhone 與 iPad Simulator build，確認 file system synchronized groups 正確拾取新增、搬移或刪除的 Swift 檔案。
- **跨檔案共用的尺寸由單一來源推導、不各自寫死**——例如分隔線內縮由頭像尺寸推導 (`BLListMetrics.dividerInset` ← `avatarSize`)。兩個本就必須對齊的數值各自寫死，會在其中一方改動時默默錯開。
- **語意色與系統色一律走系統取色介面 (`Color(uiColor: .systemXxx)`)、不手抄十六進位值**——系統色是動態色，隨系統版本、深淺外觀、增強對比與 vibrancy 自動調整；`BLPalette` 無外觀參數也無亮暗分支。
    - **例外：`secondaryLabel` 刻意不用系統值**——系統 `.secondaryLabel` 淺色僅約 3.4:1，低於本專案 4.5:1 的資訊文字地板，改以 `label.opacity(0.6)` 推導 (仍為動態色，實測兩外觀皆逾 5.4:1)。
    - **強調色以 `AccentColor` 資源檔為單一來源**——資源檔定義亮暗與增強對比變體，`BLPalette.accent` 引用它、`RootView` 以 `.tint` 於根層統一設定，系統元件與自訂元件取同一個值。
- **層級不以文字的不透明度降階表達**——降階直接損害對比 (主卡曾落在 2.03–3.24:1)；層級由字重與字級表達，文字不透明度一律為一。彩底上的白字由 `ContrastComplianceTests` 的漸層斷言把關。
- **不以實色模仿系統 bar、不以半透明色模仿玻璃材質**——需要 bar 底就用系統材質 (`.background(.bar)`) 並讓捲動內容延伸至其下方；層次區隔用系統材質，不自訂半透明色 (原 `glassBackground`／`glassBorder` 已刪除)。
- **語意色分四軌，選軌的唯一判準是「這個色彩最終疊在什麼底色上」**——`BLTone` 提供 `onSurface`／`background`／`indicator`／`onIndicator`，皆為讀取 asset catalog 具名資源的計算屬性 (不收色盤參數，外觀與 Increase Contrast 由系統依 trait 解析)。
  - 文字疊在卡片、列背景或 `background` 淡底 → `onSurface`；本身就是圖形 (狀態點、進度條填色、實心徽章底色) → `indicator`；文字疊在 `indicator` 實心底上 → `onIndicator`。
  - **色值改在 asset catalog、不在程式碼算**：`Assets.xcassets` 的 `BLTone<Tone><Role>` 每組都定義 Any／Dark 與各自的 High Contrast 變體。程式碼算色表達不了 Increase Contrast 這個維度。
  - **具名色彩資源缺失時 SwiftUI 靜默回退系統預設色**，無編譯或執行期警訊——新增 Color Set 必須與引用它的程式碼同批合入，且驗收要逐一目視確認顏色，不以「畫面沒壞」當通過。
  - 對比門檻由 `BuyLedgerTests/ContrastComplianceTests` 把關 (helper 為 `ColorContrast`，自帶對照案例鎖住計算模型)。**旁有文字標籤的圖形 (如膠囊色點) 屬裝飾**，豁免 3:1 並標 `.accessibilityHidden(true)`；3:1 只約束單獨承載意義的圖形。
- **系統已提供的能力不得重造**——搜尋、分段選擇、進度、清單列的按壓回饋等一律用系統元件。自製版本的代價不在外觀，而在那些不可見卻會一併失去的行為 (搜尋的 Cancel 鈕／Search return 鍵／聽寫／捲動收合、進度的 progress 語意、列的按壓 highlight)，這些在目視檢查中不會暴露。
  - 需要自訂外觀時走系統的**樣式擴充點**而非重畫元件：`ProgressViewStyle` (`BLProgressBarStyle`)、`ButtonStyle` (`BLButtonStyle`)。這樣外觀可完全自訂，語意仍由系統提供。
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

### Snapshot 測試 (swift-snapshot-testing)

Baseline 在 `BuyLedgerTests/__Snapshots__/`；`SnapshotTests.swift` 以 `#if canImport(SnapshotTesting) && os(iOS)` 包住，目前僅 iOS 393×852 baseline。record / commit 流程與設計大改重建見 [README.md › 執行測試](README.md#3-執行測試) 與本目錄 README 的 Troubleshooting。

**硬規則**：每個 snapshot test 必須用 `TestDependencies.withFixedNow { ... }` (`BuyLedgerTests/TestDependencies.swift`) 包住 view 建構與 `assertSnapshot`，注入固定 `\.date` (2026-04-30 UTC)；不要在測試裡直接 `Date()`。

## 環境相依性與依賴注入

root `CLAUDE.md` 的注入原則在本平台的具體落地：production code **一律走 `@Dependency`，不可直接呼叫 `Date()` / `UUID()` / `Locale.current` / `TimeZone.current` / `Calendar.current`** (除了 dependency 註冊處本身)。

具體規則：

- TCA Reducer：在 `// MARK: - Dependency Properties` 區塊加 `@Dependency(\.date) private var date` 等；reducer body 中以 `date.now`、`uuid()` 取值。
- SwiftUI View：同樣可加 `@Dependency(\.date) private var date`，在 view body 或 helper method 中以 `date()` / `date.now` 取值。
- State 上的 computed property 不可內部呼叫 `Date()`——改成 `func foo(referenceDate: Date) -> ...` 由 caller (reducer 或 view) 以注入後的 date 傳入。

測試端：`TestStore` 用 `withDependencies: { $0.date = .constant(TestDependencies.fixedNow) }`；snapshot test 用 `TestDependencies.withFixedNow { ... }`。Calendar 相關測試需要固定 `TimeZone(secondsFromGMT: 0)` 與 `Calendar(identifier: .gregorian)` 確保跨機器一致。

## 安全性與設定注意事項

目前專案無 entitlements 檔；日後若加 App Groups / CloudKit / Push 需新增 entitlements 檔並在 pbxproj 掛上 `CODE_SIGN_ENTITLEMENTS = BuyLedger/Resources/BuyLedger.entitlements;` build setting，否則 binary 上只會出現 Xcode 自動加的預設 key，runtime 會抓不到設定的 entitlements 並出現難以診斷的錯誤。

CloudKit container、`aps-environment` 等 entitlement key 等 Apple Developer 帳號實際 provision 後再加；未 provision 時加上會讓 codesign 失敗。CloudKit container、iCloud capability 與 entitlements 的變更需要在 PR 中明確說明。

## Firebase (遙測底座、無雲端同步)

移除 Web/Backend 後，Firebase 僅作崩潰與使用分析的遙測底座，App 為純本機 (資料唯一來源為 SwiftData、`PersistenceContainer.shared`、CloudKit `.disabled`)。

- **target 僅 link `FirebaseCore` / `FirebaseCrashlytics` / `FirebaseAnalytics` / `FirebasePerformance`** (皆監測類)；`GoogleService-Info.plist` 放在 `BuyLedger/Resources/` (gitignored)。啟動時 `AppLaunchConfigurator.configure()` 呼叫 `FirebaseApp.configure()` 完成初始化，無登入、無 Firestore、無 Auth/Storage/Messaging。
- **`OTHER_LDFLAGS = "-ObjC"` 與 pbxproj 的「Run Script: Crashlytics Symbol Upload」build phase 不可移除**——它執行 `firebase-ios-sdk/Crashlytics/run`，移除 firebase-ios-sdk 套件或 Crashlytics 產品卻不刪此 build phase 會使腳本路徑消失、build 直接失敗。
- 加 SPM 產品一律用 Xcode 操作、勿手改 pbxproj。
