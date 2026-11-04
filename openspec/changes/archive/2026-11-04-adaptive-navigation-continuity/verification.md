# 驗收記錄

主對話負責驗收與review；codex-impl／gemini-impl依使用者指定負責實作。任務checkbox以驗收通過為準。

實測內容直接寫在各段，不引用本機檔案 (使用者 2026-11-04 決定)。

## 任務1.1：真實TCA導覽原型

狀態：已完成 (version411，2026-10-27 Asia/Taipei)。

- RED：2026-10-26，主對話使用MobileBuildMCP simulator test，BuyLedger scheme，iOS26.5 iPhone17模擬器 `1FB73457-BA2B-4D45-9233-1C53F1DB2362`。
- Filter：`BuyLedgerTests/OrdersFeatureDetailTests/orderTapped_相同訂單重開_保留path元素識別值()`。實際1條執行、1條失敗、0條略過；編譯錯誤0。
- 行為證據：同一訂單再開啟時path IDs由`[#0]`改為`[#1]`，TestStore回報非預期state改變，符合本次要修正的identity遺失。
- 待驗：最小修正GREEN、相關reducer回歸、真實split原型、原生Back與手勢、只resize不誤pop、iPad tabs/sidebar與Duo姿勢UI證據。
- 初次測試建置有既存ColorContrast actor隔離與套件傳遞依賴warning，未在本批修改其來源；若後續變成錯誤則另依具體診斷處理。

- GREEN：同一 iOS 26.5 模擬器執行 `OrdersFeatureDetailTests` 與 `OrdersDetailNavigationFeatureTests`，26 條通過、0 失敗、0 略過；建置錯誤 0。測試依父層 `.list` 命名為 `list_相同訂單重開_保留path元素識別值()`。此結果只驗證最小 identity 修正，1.1 完整 UI 原型仍待驗收。

- 原型入口 UI RED：`AdaptiveSplitPrototypeTests/testLaunchFlag_AdaptiveSplitPrototype_啟動後可選取訂單詳情`，iOS 26.5，1 條執行／1 失敗／0 略過，App 已進入前景但未出現旗標要求的入口。
- 主對話 review 發現既有 `orders.list.root` 無法唯一證明原型，已要求專屬 marker 與由 path 投影的所選 orderID 斷言，需再確認精準 UI RED 後才實作原型。
- 該 UI run 有 LLVM `default.profraw` 寫入權限的 profiling 診斷；不以它當作預期 RED，預期失敗證據是明確的入口斷言。

- 精準原型 UI RED：專屬 `BLAccessibilityID.AdaptiveSplitPrototype.root` marker 及所選 ID 契約加入後重跑，實際 1 條執行／1 失敗／0 略過，失敗為專屬 marker 未出現。

- 第一版原型可編譯：iOS 26.5 iPhone 的 AdaptiveSplitPrototypeTests 為 3 通過／0 失敗／2 略過，通過入口／選取、原生 Back、邊緣返回；尚不算完整 1.1 GREEN。
- 相關 unit／guards：75 通過／0 失敗／0 略過，涵蓋 Orders 詳情與導覽、旗標解析、分層、設計系統、無障礙及測試完整性。
- 已核實 review：原型測試錯用根 tab/sidebar 判斷功能分欄，會令 iPad expanded 案例被略過；已交回改為功能欄位可見性／frame 判定，並補 Preview 與 kit 屬性順序。
- Gemini 的「無 NavigationLink 必然無原生 Back」未採為確定缺陷：目前實際 compact Back／手勢已通過；跨尺寸是否需 preferredCompactColumn 仍以姿勢實測判斷。

- 2026-10-27 review 修正首次 build-for-testing：`AdaptiveSplitPrototypeScreen.swift` 的 actor-isolated key path 無法形成，未執行測試。已由 Codex 將 XCUI 存取隔離到 `@MainActor` extension、以 closure 取代 key path 並清理未使用變數。此為編譯修復，不計為行為 RED。
- 最終唯讀審查：Gemini 對修正後 Screen／原型 View 無新增 finding；審查前後所有 iOS Swift／project／catalog 檔案 SHA-256 無變動。主對話另核對 store→@State→language 順序、Preview、identity 直接投影及缺 marker 不可 skip。修正後已成功 build-for-testing，實際 UI 結果待回收。

- 修正後 iPhone 精準三條重驗：1 通過／2 失敗／0 略過。唯一失敗已定位為測試 helper：詳情成功顯示後，欄位辨識仍要求已從 collapsed AX tree 移除的清單存在，因而尚未操作 Back 就失敗。已交回原作者分開「啟動清單就緒」與「目前欄位辨識」前提；不修改產品導覽，也不以 skip 掩蓋。首次 App 冷啟動約 98 秒，屬等待成本；實際失敗位置為 helper 前提。

- iPhone helper 修正後精準重驗：3 通過／0 失敗／0 略過。基本入口／選取、原生 Back、邊緣返回皆通過。新增的 5 個 Optional frame 插值 warning 與成功路徑預算 diagnostics 的多餘 AX 查詢，已由 Gemini／主對話提出最後兩項 minor，交回 Codex 修正。iPad 與 Duo 尚待實測，1.1 不勾選。

- iPad UI 前提：主對話先關閉 Device Hub，再透過 MobileBuildMCP boot iOS 26.5 iPad Air 11-inch (M4) `E30658D5-A19C-40CE-AA6E-C11BEAE95A1A`、鎖淺色；`KeyboardDismissTests` 2 通過／0 失敗／0 略過。數字鍵盤案例有 `Invalid frame dimension (negative or non-finite)` runtime warning；原型旗標未啟用，兩條鍵盤操作斷言均通過，先保留診斷而不改無關來源。診斷 Optional frame 編譯警告已清除。

- iPad 原型首次三條：1 通過／2 失敗／0 略過。專屬 marker 與詳情皆存在，實測 root `(0,32,820,1124)`、清單 `(10,96,320,1031.5)`、詳情 `(0,32,820,1105.5)`，兩欄可點但重疊，證明直向 automatic 為系統 overlay，不是並排。主對話保留框線斷言，交回原作者將原型改用原生 `.balanced` 樣式；仍由系統分配欄寬，無固定比例。
- `.balanced` 查證：Context7 官方 SwiftUI 文件及 Xcode DocumentationSearch 均確認此樣式會縮小 detail 以騰出 leading 欄；安裝 SDK 的 SwiftUI swiftinterface 標記 iOS 16.0 起可用，符合 iOS 26 目標。來源：[BalancedNavigationSplitViewStyle](https://developer.apple.com/documentation/swiftui/balancednavigationsplitviewstyle)。此為原型內實作選擇，不改使用者已定的佈局與導覽要求。

- `.balanced` iPad 重驗：仍為 1 通過／2 失敗／0 略過；820 pt 直向幾何與前輪相同，不能宣稱此尺寸已並排。依原設計的系統適配與不固定比例要求，主對話修正驗收前提：並排案例改由實際橫向起始並嚴格量測兩欄；旋回直向驗證同訂單／同 StackElementID。直向仍另有實際入口／詳情選取通過證據，未把 overlay 當成並排，也不新增 skip。下一輪未完成。

- 橫向起始第三輪 iPad 原型：仍 1 通過／2 失敗／0 略過；無建置錯誤或 warning。橫向 window `(0,0,1180,820)`，原型 root `(280,0,900,796)`，清單 `(290,32,320,735.5)` 不可點，詳情 `(280,0,900,777.5)` 可點；橫向嚴格並排前提失敗，尚未操作旋回直向或第二筆替換，不能宣稱這些已驗證。Gemini 靜態審查無新增 blocker、源碼 SHA-256 無變動；其對 assertion 能證明什麼的推論不代表本輪 runtime 已通過。
- 因症狀持續，改用 spectra-debug：重現已由以上三次受控實測成立，優先隔離根 native sidebar／TabView 與功能 split 的互動，停止繼續試樣式或放寬幾何。先擷取已安裝 iPad App 的實際畫面與 AX；首次唯讀 capture 是 Home，待主對話帶原型旗標啟動。

- 唯讀實圖已由驗收代理與主對話讀取：portrait 頂部五 tabs，根原生 toggle identifier `ToggleSideBar`；功能左側清單為浮動卡片。靜態截圖本身不能證明詳情前景互蓋，因系統容器背景可能延伸；後續診斷將同時量測實際訂單列與財務 summary tile 的 frame/hittability，不以 ScrollView 外框單獨認定內容欄錯誤。單變因實驗保持橫向，只切換根原生 sidebar。

- 單變因診斷首次執行：0 通過／1 失敗／0 略過，失敗為 landscape 根 toggle 的 native ID 是 `ToggleSidebar` 而非 portrait 的 `ToggleSideBar`，尚未執行點擊，故不能宣稱根寬變化實驗完成。
- 該診斷已定位舊 helper 的錯誤量測：root 900 pt 時，017 列 `(290,290.5,320,108.5)`、015 列 `(290,561.5,320,126.5)` 都可點；詳情 revenue `(642,470,53,36.5)`、cost `(877,470,53,36.5)`、profit `(642,376.5,112,61)` 全可點，前景與列互不重疊。清單容器 `hittable=false` 不代表其實際列不可互動，詳情 ScrollView 背景全寬不代表前景跨欄。主對話已讀完整 before PNG，確認原生根 sidebar、訂單清單與詳情前景確實三欄。根空間壓力導致無法並排的假設不成立；問題在驗收 Screen 的觀測對象，已交回修正。

- iPad 前景量測修正後：4 通過／0 失敗／0 略過，無編譯或 runtime 診斷。包括 017 同筆重選保留 identity、015 明確替換、橫向→直向保留同訂單／StackElementID，以及原生根 sidebar 收合時 root 寬 900→1180、window 固定 1180×820、017 與 `#0` 均保留。切換前後實際列與三個摘要前景皆可點且分離。
- Gemini 對前景量測版本無新增 finding，並明確將靜態審查與 runtime 結果分開；該次唯讀審查前後 source SHA-256 無變動。前面各輪「無並排」的推論已被本輪前景 AX 與實圖否定，不作產品缺陷結論；UI helper 修復已由同一批原始失敗案例驗證。iPhone 最終重驗及 Duo 姿勢仍待完成。

- iPhone 最終版本重驗：3 通過／0 失敗／0 略過，無 warning/error；選取、原生 Back、邊緣返回均通過。此版本與 iPad 四條通過版本相同。

- 最終相關 reducer／guards：75 通過／0 失敗／0 略過；涵蓋兩組 Orders 詳情 reducer、旗標正常與無效參數、LayerBoundary、DesignSystemSourceScan、AccessibilityConventionScan、TestSuiteIntegrity。錯誤 0，既存 ColorContrast actor 隔離與 SPM 傳遞 dependency warning 與初始輪相同；未改無關來源。

- Duo 409 已由 MobileBuildMCP build-and-run 成功啟動；PID `61747`，App Info 為 minimum iOS 26.0、SDK iphonesimulator27.1、Xcode build 27A9275，裝置 `8940608C-3665-4E4E-8ED0-5384321254EC`／iOS 27.1，外觀鎖淺色。
- Duo 姿勢進度 (未完成整批)：Closed 實際點選 Mika 017 後 `#0`；Device Hub native Open 與 Partially Open 兩個實際姿勢後，CLI rs/1 與主對話 CUA AX 均保持 017／`#0`，主對話亦讀實際全圖，Partial 有可見硬體半摺中縫，前景與原生右側 rail 不互蓋。
- Duo 工具限制已分流處理：Xcode unbound session 在姿勢改變後失效／擷取舊 viewport 黑畫面；一次方向更新仍失配即停。MobileBuildMCP screenshot 回多 displays 無法選擇 (CLI 無 display 參數)，沒有改用專案禁止的 raw simctl。Open／Partial 的畫面證據採主對話 CUA，canonical ID／identity 另由 CLI AX 交叉確認，不把黑圖或 NotRun 欄位當產品崩潰。
- Partial 改選 Joyce 的實際操作：大型 Device Hub 一次座標點擊無效，切 native compact window 後重新取圖、點可見 Joyce 列，CUA 顯示 Joyce／BL-2604-015／收款 $0／成本 $13,728／獲利 -$13,728、caption `#1`；CLI rs/1 再核對 root=015、identity=#1。主對話點 native Closed 收合後，CUA 仍是 Joyce／015／#1，並出現原生 Back。Closed 返回與再次展開空選取仍待完成，1.1 保持未勾選。

- Duo Back／手勢／搜尋取消／單一新增 sheet 取消均已由驗收代理在同 PID 61747 完成，最後 path 空；再 Open 的 CUA 全圖與 CLI (`screenHash=0uetehh`) 皆確認空提示、不復活017/015。
- 新 blocker (產品／框架原因未定)：初次 Joyce #1 Closed 的狀態與更多操作 capsule 空白、AX兩menu ID缺失。Back仍可用，重開Mika恢復。Main第二次換單到Joyce #4再Closed曾正常，故不把單次正常當修好。
- 最小同ID對照已再現：固定Joyce 015/#4，僅 Open→Partially Open→Closed。前兩步status/More均存在，Closed兩者均缺；再重新取完整AX/實圖仍缺，header/data/#4皆保留。這證偽「必須因不同StackElementID替換」的候選，轉向 split collapse toolbar host；1.1不完成，也不放行1.2。正在蒐集有官方依據的最小修正候選，尚未修改source。

- Toolbar最小重現的 CLI 交叉證據：`screenHash=0dfxxyq`、seq1、count143，root015／#4與摘要不變，targets僅Back+五個根tabs，兩Menu ID均無。不是只在不同ID替換時發生，也不是容器frame誤判。
- 修正候選1 (尚未驗證)：採Apple官方 NavigationLink(value:) + List(selection:) 轉接，保持唯一path與既有detail scope，先排除純tag缺少顯式原生導航連結的可能。Context7官方來源及Xcode DocumentationSearch均已核對 [NavigationLink](https://developer.apple.com/documentation/swiftui/navigationlink) 的Coordinate with a list語義；文件不保證此舉一定修復toolbar，須用同一Duo重現流程比較。未採用在同ID摺展時強制重建state或任意delay。

- 候選1 (NavigationLink) 最低OS回歸：iOS26.5 iPhone四條 4 通過／0失敗／0略過，無warning/error；包含新 `testAdaptiveSplit_轉向後詳情Menu可用_保留path元素` 的初始直向／橫向／返回直向三處兩Menu可點與same path/StackID，另三條選取/Back/手勢均通過。這是26回歸，真正RED仍為Duo27.1已測的collapse toolbar缺失，不冒稱26新test先失敗。
- Gemini候選1唯讀無阻斷性finding；唯一modifier縮排minor已由原作者單點修正，語義未變。審查期間source SHA-256無變動，修正後主對話核對只變該縮排。版本三處410已準備第二次Duo buildrun；先驗焦點Duo重現，通過後再擴展其餘回歸。

- 候選1焦點Duo再現失敗：410／PID8102，Closed Mika017/#0有兩Menu；Main只按Open→Partial→Closed，前兩步皆有，Closed兩ID缺失。稍後再完整AX+實圖仍缺/空pill，017/#0與數值均保持。這證明value link不足以修復toolbar，不把26四條pass當27已修好。
- 候選2範圍經主對話依實測核准增加既有 `OrderDetail/Views/OrderDetailView.swift`：僅把toolbar modifier從有order的內容條件分支移到此feature View穩定body根，內容仍以有效order為條件、沿用同Store與detail column、移除原掛點。無第二stack、無強制ID重建、無延遲。此為待驗證的toolbar host邊界候選，版本411，未宣稱根因確立；Task1.1與後續仍未完成。

- 候選2 version411／PID19568 已成功建置啟動，錯誤/warning 0。Closed基準由驗收代理確認Mika017/#0與兩Menu正常。Main保持同一App同一ID，連續兩輪Open→Partially Open→Closed，每一姿勢兩Menu AX皆存在、#0不變；再Open/Partial實際改選Joyce015/#1並Closed，兩Menu仍存在且全圖顯示正常圖示。這是焦點reproducer的重複GREEN證據，尚待Menu實際開啟/正確編輯與26完整受影響回歸，不單憑建置/靜態審查完成1.1。

- 候選2的Duo實際操作GREEN：同PID19568，Closed Joyce015/#1的status選單9項可開關、More→Edit僅一個表單且customer為Joyce黃，取消後仍015/#1。原生Back清空→017/#2→edgeBack再次清空，再Open維持「選擇訂單」而無詳情。Menu不只AX存在，實際動作及資料來源正確。Open清空後CLI交叉證據screenHash=0rmbxcf、seq1、count181。空Text可能被AX省略，故空identity以Closed正式AX與Open根value/空詳情提示共同判斷。
- Main以native Quit and Keep Simulators Running關閉DeviceHub並用pgrep確認無程序後，開始411 iPhone26.5四條原型及既有OrderDetailMenuTests／OrderDetailTests五條回歸；結果尚待回收。本批沒有強制重建detail、增加延遲或引入27-only API，仍未完成1.1。

- 候選2 iPhone26.5回歸：9通過／0失敗／0略過，warning/error 0。四條原型涵蓋選取、Back、edgeBack、直橫直向Menu及identity；五條正式入口涵蓋編輯／合併／刪除取消、財務摘要、付款方式更正重啟持久化。DeviceHub仍關閉，iPad以CLI boot並鎖淺色，正在先跑獨立KeyboardDismissTests。

- iPad411鍵盤前提：2通過／0失敗／0略過。數字鍵盤案例保留與409之前同樣的 `Invalid frame dimension (negative or non-finite)` warning，prototype旗標未開啟、兩項互動均通過；沒有將警告當RED或更改無關產品。其後依序啟動iPad五條原型與既有詳情Menu三條／摘要一條，待回收。

- 候選2 iPad26.5回歸：9通過／0失敗／0略過，warning/error 0。五條原型均通過，包括同ID重選／異ID替換、橫直向同StackElementID、根sidebar收合前後前景並排、三方向Menu與入口；既有Menu三種取消與摘要也正常。

- 候選2最終相關reducer／guards／詳情snapshot：76通過／0失敗／0略過，錯誤0。包含原75條及SnapshotOrderDetailTests。既存ColorContrast兩條actor warning與SPM傳遞依賴warning同基線，未更改無關來源。iPhone initially Shutdown造成一次appearance設定失敗，隨後CLI boot與set-appearance light均成功，當時仍在build-for-testing、snapshot尚未執行。
- 1.1放行：main最終diff／git diff --check通過；Gemini最終唯讀審查無待修正finding且source SHA-256不變；main另檢查單一path投影、同ID不重建、Store scope／action、原生Back、欄位呈現與root條件、availability及工具列僅一個掛點。App 端事件順序：清單選取的 getter 直接投影 `detail.path` 的訂單 ID，不存第二份 ID；setter 送 view action，有效 ID 才開啟，相同目的地保留 `StackElementID`；系統 columnVisibility 回寫只更新 View 的 `@State`；原生返回使選取回 nil 並清空 path。前面失敗與被推翻假設保留為歷史，不視為現況缺陷。正式More鏈、草稿、完整最終導覽及全面無障礙仍依後續任務驗收。

## 任務1.2：彈性閱讀寬度與局部環境

狀態：測試階段實作中。由gemini-impl實作、codex-impl唯讀審查，main驗收；不改尚未遷移入口的runtime語意，舊BLLayoutClass暫留局部相容橋接，移除其全App強制政策與專屬守門。候選寬640／680／840源自Gemini預讀建議，尚待實際內容量測，非使用者指定或已驗收數字。

- 1.2測試草稿main review：尚未執行；發現safeAreaInsets參數未實際設定、modifier外框被當內容frame、expected直接讀production上限且<=可讓0寬過關、長文字/字級僅公式而無渲染。已回Gemini修測試、保留pass-through API骨架；不把草稿問題當產品RED。
- 官方API交叉查證：main以Context7 Apple SwiftUI/UIKit來源及Xcode DocumentationSearch確認frame是包裝視圖的約束外框，UIViewController.additionalSafeAreaInsets修改host安全區；UIView.safeAreaInsets在未加入可見階層時可能為0，因此fixture必須真正掛載並檢查，不用假設inset參數有生效。來源：[frame](https://developer.apple.com/documentation/swiftui/view/frame(minwidth:idealwidth:maxwidth:minheight:idealheight:maxheight:alignment:))、[additionalSafeAreaInsets](https://developer.apple.com/documentation/uikit/uiviewcontroller/additionalsafeareainsets)、[safeAreaInsets](https://developer.apple.com/documentation/uikit/uiview/safeareainsets)、[safe area positioning](https://developer.apple.com/documentation/uikit/positioning-content-relative-to-the-safe-area)。UIKit safeAreaInsets availability iOS11起，無需提高iOS26目標。

- 1.2修訂回報一致性檢查：Gemini報告稱測試均修正，main讀回source發現兩份tests仍為舊稿，無additionalSafeAreaInsets／內層anchor／真實Text，且仍引用已從production移除的calculatedWidth。已退回原作者要求實際修改後讀回核對；沒有執行此錯配版本，不計runtime RED、不標完成。

- 1.2首個實際行為RED：iPhone17/iOS26.5、BuyLedger scheme、MobileBuildMCP精準執行寬區／窄區／父層compact覆寫三條，0通過／3失敗／0略過。寬區及局部覆寫實測width1024/minX0/maxX1024，預期640/192/832；窄區實測375/0/375，預期343/16/359。無編譯或缺型別失敗，證據是實際frame斷言；LLVM default.profraw權限診斷不是本次預期RED原因。此時primitive維持pass-through。
- 安全區／長文字／AX fixture另由codex-impl獨立唯讀審查，尚未宣稱通過或允許其不可靠斷言作驗收。main已核對第二次Gemini修訂確實落在source（calculatedWidth引用0，加入additionalSafeAreaInsets與Text）；前次文字回報不一致已更正。

- 1.2獨立審查：Codex已完成唯讀測試審查，source SHA-256前後無變動。main採納：先校準未修飾fixture的host bounds／有效safeInsets／座標，改用未限行Text自然高度oracle以捕捉lineLimit(1)，補feature-scoped canonical selection-value marker。Chart Color案例僅證明候選寬度，不宣稱已驗真實標籤可讀性。另補寬／窄兩向根覆寫與AX5實際寬度退讓，Gemini實作測試修訂中，仍不做GREEN。

- 1.2校準首輪：build-for-testing失敗、未執行任何測試。新helper的 `InnerFramePreferenceKey.defaultValue` 是nonisolated static var，Swift6拒絕共享可變狀態。已交回改不可變常數，不用隔離豁免或關檢查；另要求真正讀取更新後最新幾何，因草稿的sleep50ms後回第一筆並不是穩定取樣。這是測試基建修復，不當作行為RED；先前3條core RED證據仍保留。

- 1.2校準第二輪：成功編譯、0通過／3失敗／0略過，無新warning/error。root Geometry size已是(1024,672)而非physical(1024,768)；左20/200案例再扣proxy safeInsets分別算成335/624，恰比獨立UIKit安全寬355/824少20/200。證據支持fixture重複扣除安全區的假設。已交回以UIKit bounds.inset(by:effectiveSafeInsets)校準root size、真實祖先座標與host frame，原內容邊界要求維持不變；仍不把校準失敗當產品RED。

- 1.2校準第三輪GREEN：3通過／0失敗／0略過，無warning/error。以獨立UIKit有效安全框校準root proxy實際size，不二次扣proxy safeInsets；named space置於真正root祖先，raw frame經實際root/host原點轉換成host frame，原literal內容邊界仍保留。三個純fixture對照均未呼叫.blReadableContent，因此校準GREEN不宣稱產品已實作。下一步以同一fixture跑完整SUT RED。

- 1.2完整渲染RED：3通過（純fixture校準）／10失敗（SUT）／0略過，無error。窄asym SUT host frame為20/355/375，預期36/323/359；寬asym為200/824/1024，預期292/640/932。標準寬/窄、表單/chart候選、長文字、AX5寬度退讓及兩向舊根環境覆寫皆實際達到斷言失敗。
- 依RED來源核對：長Text intrinsic frame為944.667/1011而非外層1024，不能把glyph自身必須等於640當成UI契約；允許fixture用flexible內容region量閱讀寬度並保留自然Text高度oracle/單行反例，其他region exact-width及安全區literal不變。main已授權Gemini最小GREEN與本批style/獨立literal/共享marker清理，仍未完成任務。

- 1.2第一版GREEN渲染：13通過／0失敗／0略過，error0。原ColorContrast兩條actor warning仍屬基線。原生@ScaledMetric取代未驗自訂倍率表，元件僅frame/padding組合；長Text以fixture flexible region保護閱讀寬度，另與自然高度oracle對比。此結果不等於已完成任務：Codex最終review、其餘guard/legacy/localization及受控lineLimit反例仍待完成。

- 1.2相關guards／legacy／localization：81通過／0失敗／0略過，warning/error0。涵蓋BLAccessibilityID、BLLayoutClass九組與環境相容、DesignSystemSourceScan/ScaledMetric、LayerBoundary、AccessibilityConvention、TestSuiteIntegrity及三組LocalizationCatalog套件。移除的只有舊尺寸分類單檔強制掃描，其他守門在此版保持通過。最終review與文字受控mutation仍待完成。

- 1.2最終review第一輪 Needs revision：source hash前後未變。main採納production單一基準、AX同fixture標準/AX5 paired觀測及具體目錄/文件/MARK規範修訂。AX finding限focused case，原整套standard640已拒絕全域固定700，不誤稱整套可假通過。main另補factory未指定type的default .text契約與後續受控mutation。已交Gemini修訂；13+81通過是前一版有效證據，修後執行所屬檢查再完成。

- 1.2修訂後GREEN：95通過／0失敗／0略過，error0。包含14渲染（新增factory default）及81相關guard/legacy/localization；原ColorContrast兩條actor warning仍是基線。production ScaledMetric由enum唯一候選基準初始化，modifier歸位ViewModifiers、factory唯一default、Snapshot真正nested及文件/測試MARK修訂。Codex複核與受控mutation仍待完成，不提前勾選1.2。

- 1.2最終複核第二輪：source hash未變；Codex 複核確認單一基準、AX paired、目錄/協定、Snapshot nested、test MARK與default渲染均已修正。只剩Probe.body缺///與自創Layout Modifier MARK兩個文件層級問題，已請Gemini單點修正，不改邏輯。新版本95/95已由main回收，peer未收到時保留其當時runtime待驗敘述，整體結論由main證據整合。

- 1.2文件層修訂確認：main實際讀回Probe.body的///及modifier MARK修正；受控mutation前全source雜湊已保存。Mutation A只注入lineLimit(1)與factory預設.form，3條指定測試0通過／3預期失敗／0略過，error0；繁中／英文高度20.333而自然oracle42.333，無參數寬680而預期640。Gemini反向還原後main確認所有source hash完全等於mutation前；三條加AX paired恢復4通過／0失敗／0略過。
- 1.2 Mutation B只將body maxWidth改固定700；只跑成對large／AX5測試，0通過／1預期失敗／0略過，error0。直接因AX5.width700未大於large.width700失敗，並非依賴其他標準640測試代證。已交Gemini精確反向還原，待main雜湊與最終整批驗證後才完成1.2。

- 1.2 Mutation B已反向還原；main比對全部Swift source hash等於注入前，SUT SHA256為311babff9de28d9247e0fb3fee651665d5bd475278e1a7b208109ed10e43ccad。精確還原版最終95通過／0失敗／0略過，warning/error0。main額外發現新檔半形括號／MARK格式遺漏，交未參與實作的Codex補核；只剩文字格式收尾，未以功能GREEN掩蓋規範問題。

- 1.2放行：main逐行檢查最終文字diff，7檔只改註解／MARK／Preview及assertion-message括號與空格；排除comment後僅正規化文案括號／空格即與95/95版本完全相同，fixtures、conditions、數值、ID、API與執行流程均未變，無無關Swift變動，git diff --check通過。因此沿用精確還原版95/95的有效功能證據，不為純註解重跑。peer style報告中的Layout Modifier line48是已刪項的過期定位，main以實際source核對，不重複改已修項。無剩餘待修finding；候選640/680/840仍待功能L4實測，不宣稱已驗真實chart標籤或所有feature consumer。1.2完成，後續正式root／features依任務依賴繼續。

## 任務1.3：正式根導覽整合

狀態：實作測試階段，codex-impl實作、gemini-impl唯讀審查、main驗收。1.2完成後CLI start3基線已記錄。main草稿審查要求保留matching CUSTOMER-1的本批舊選取結果、給stale狀態/日期/search真正非預設Given及補回same-tab guard案例，Codex已實際修訂。

- Stage1首次實跑build-for-testing失敗，未執行測試，不計行為RED。MemberImportVisibility要求Foundation以建立Decimal integer literal；path.ids為OrderedSet，直接以[sourcePathID]對比需要OrderedCollections import或先明確轉為Array。既存ColorContrast兩條actor warning仍為基線。修復限測試imports／集合比較型別，不改production、斷言意圖或最低版本。

- 文件補正：1.3 peer指出async throws測試需Throws文件，main回查1.2亦有相同遺漏，已由原作者Gemini補齊兩份新測試共14處。main驗證排除comment後與已測版完全相同，純文件更正不影響95/95證據；先前放行文字已由本條補充。1.3三個unit檔的peer review前後hash相同，並行Codex只新增獨立UI test/helper檔，未改受審scope。peer關於成功觀測的措辭只視為靜態審查，不當作runtime proof；目前production尚未改、第一輪無測試執行。

- 1.3 Stage1修復後實際行為RED：14通過／5預期失敗／0略過，error0。五個失敗正是sidebar設定／主檔與兩條Root customer、More relay的path被清空；id從[#0]或[#0,#1]變[]、子state變nil，沒有額外的matching-order預期差異。canonical兩條與same-tab保護實際通過，仍需受控regression反例。不提高目標版本或改production來補償測試。

- 1.3 canonical regression反例：只在RootFeature.tabSelected加state.more.popToRoot()，其他Swift hash不變；兩條原先PASS案例各自因path由[#0]變[]及子state遺失失敗，0通過／2預期失敗／0略過，error0。已立即指示Codex反向還原，原檔SHA186fd106509a1fe77105988d14545accd4b55f1f7224a59e1a8ca15787bc675d；待main核對後才續UI及正式實作。

- canonical反例已精確還原，main核對全部Swift hashes與注入前相同，RootFeature SHA186fd106509a1fe77105988d14545accd4b55f1f7224a59e1a8ca15787bc675d。兩條恢復PASS將納入同批正式GREEN的全三組測試；未將目前仍預期5失敗的舊production誤稱整批通過。DeviceHub pgrep確認未執行；iPad boot回報已Booted，無新重開機，本輪另獨立執行KeyboardDismissTests確認鍵盤前提。

- 1.3 iPad26.5鍵盤前提：KeyboardDismissTests獨立2通過／0失敗／0略過，error0。新nativeTabBar查詢及既有UI helpers有MainActor隔離warnings，正式helper遷移時處理新介面正確隔離；另記錄numeric鍵盤case的Invalid frame dimension診斷，該case實際通過，不以診斷推定產品失敗或省略後續驗收。開始對舊正式入口執行native五分頁UI RED。

- iPad native UI首輪環境失敗，未執行測試、不計RED：2026-10-26T21:30:37Z MobileBuildMCP ENOSPC，SwiftPM manifest linker及CLI寫log/JSON均因磁碟滿失敗，結果檔為 0 byte 無效結果。main釋出磁碟至可用10.85GiB；不是產品或測試斷言修訂。未獲任何auto-review rejection；繼續原命令重跑。

- 1.3正式入口UI有效RED：iPadAir11 M4 iOS26.5、BuyLedgerUITests scheme，LaunchSmokeTests/testAdaptiveRoot_首次啟動顯示五個原生分頁 實際0通過／1預期失敗／0略過，warning/error0。總覽root就緒後native tabBar查詢回nil，對規格literal5失敗。這是舊正式iPad RootSidebarLayout的真實對照，與前次ENOSPC無效結果分開。main已放行Codex按packet執行正式GREEN整合；尚未宣稱新根或N5通過。

- 1.3 production切片停寫：新RootNavigationLayout與OrdersLegacyNavigationView、RootView正常入口、Root/More撤path清空、exact4whitelist已實際落檔並由main讀回。Gemini唯讀審六Swift，main另指示Codex只將project三target build411→412、MARKETING_VERSION2.1.0不變，Swift hash未動。開始build-and-run412取得nativeAX；helper／N5UI尚待實際階層資料，不先臆測selectors。

- 新根build-and-run412成功，warning/error0，iPadAir11M4 iOS26.5 UUID E30658D5-A19C-40CE-AA6E-C11BEAE95A1A，PID79642。正式fullOrders/no prototype啟動；root為native TabView，語意helper仍待AX實測。尚未把build成功當N5通過，所有19unit與N1/N5 UI、rootguard正反仍待驗收。

- 412實測推翻TabSection方案：initial AX與截圖顯示頂部只有「工作區／工具」2個群組tab（AX各雙節點），沒有直接5個destinations，Root.tab.*與orders徽章也未在頂部曝光。Gemini靜態review-1先前認可5個source Tab宣告，不等於實際topbar有5個；main以runtime優先退回修正。read-only review所有Swift hash未變。設計已允許原生能力差異記錄，不自畫第二套root；下一版先查官方TabSection行為／合法composition，保持五個直接目的地為主需求，未放行1.3。

- TabSection修正決策來源為main：Apple文件將section定位為次層階層；沒有經文件證實可把相同5個Tab同時alias為top-level及group children。依既有design允許記錄native能力差異，選最小flat5 direct nativeTabs+既有品牌header；sidebar工作區/工具分組差異明列，不複製目的地、不新造root、不宣稱其他組合不可能。Codex提出修正計畫，main已授權只改RootNavigationLayout+三target413，待重build/runtime。
- 412 sidebar互動未驗證：第一個e11 tap因snapshot超過78秒expired，未送動作；刷新後第二個e11/ToggleSideBar成功送tap，但後續AX仍2sectiontab、圖無sidebar，不能把工具success視為UI轉換通過。先隔離composition修正，後續以實際XCUITest再驗，不同時猜多項修補。

- flat修正版413 build-and-run成功，warning/error0、PID87386。initial AX五個Root.tab.*都曝光（每項2個rs/1節點），截圖頂部清楚為總覽／訂單／開團／分析／更多，Orders原生badge視覺4。peer複核source成因移除，所有Swift hash在唯讀前後不變；未將AX重複節點直接當XCTest buttons count。
- 413有效CLI tap ToggleSideBar回success，但後續AX與截圖仍tabs，未觀察到sidebar；412有效CLI tap亦如此。開始隔離自動化輸入與placement產品行為，以XCUITest作對照；不猜root cause、不把動作回報success算N1通過。

- sidebar Debug隔離：在413新鮮AX下，用同一CLI tap點root.tab.more作對照亦回success，但後續仍dashboard.root、dashboard selected1、more selected0；不只ToggleSideBar沒有可見變化。因此先驗證CLI輸入路徑與XCUITest對照，未有足夠證據改產品placement或selection。新鮮elementRef均在期限內取得；每次navigation後刷新。開始執行原native5 UI case對照XCTest計數，下一步由Codex完成最小XCUITest原生More/Toggle探測，App source暫不改。

- 413既有native5 XCTest仍0通過／1失敗／0略過，warning/error0。helper用app.tabBars.firstMatch找不到浮動原生列，而同版實際AX/截圖五個Root.tab.*已曝光，不能直接據nil否認畫面五目的地。main授權只修AppNavigator+LaunchSmoke query，保持literal5、以實測IDs/前景判定並排除sidebar marker，防舊customsidebar五IDs假通過；另加XCTest More/toggle對照，不改App/placement/選取以猜修。

- 執行安排：App source凍結在413 flat版；Codex只改BuyLedgerUITests兩檔，main同時跑BuyLedger scheme的unit/Root/More/LayerBoundary，該scheme不包含UITests target，受測App及unit sources未變；建置／測試仍同時只一組。UI probes會等本組結束再跑，不競用build.db或device輸入。

- 413 App／unit正向GREEN：42通過／0失敗／0略過，error0。涵蓋三組19行為案例、RootFeatureTests、MoreFeatureTests、LayerBoundary實際production掃描；五條先RED的path保留與兩條canonical mutation後恢復案例均在本組通過。保留既存ColorContrast2actor／SPM傳遞依賴warning基線；未為無關warning改功能。root guard負向與UI N5仍待驗收。

- Native UI probe GREEN：iPad26.5 2通過／0失敗／0略過，error0。同版413的五semanticIDs初始tabs檢查通過；XCTest真實點More後More.root出現，再點ToggleSideBar後root.sidebar presence+有效frame與五前景入口均通過。這反駁產品binding/defaultplacement完全不能切sidebar的假設；CLI tap success仍未帶來UI變化，精確工具內部機制未定，不改App猜修，後續iPad操作走XCTest。
- 2UI檔peer前後全Swift hashes未變，新Root helper接口具@MainActor；既有待遷移AppNavigator/RootNavigationScreen仍有actor warnings，將隨本批正式helper分離處理，不用unsafe壓制。N1完整sidebar偏好與N5設定/客戶來源往返仍未驗，task1.3維持pending。

## 前置工作粒度修訂 (main決策，產品範圍不變)

- 依tasks每批需一個未壓縮context的要求，原未完成1.3拆為1.3原生宿主／狀態、1.4正式helper、1.5完整N1/N5；原1.3 start3僅基線無完成紀錄，原描述映射保留於tasks追溯註記。1.1／1.2已完成描述逐字不變。總數16→18是工作粒度增加，驗收沒有降低或延後。
- 整個前置批1.3–1.5全數通過才啟動2.x；1.4／1.5同依1.3且不同file scopes可並行，Codex helper／Gemini UI，各審對方。2.3／2.5同步維護各自split改變的scope/Back smoke，Root與Orders分檔避免競寫。
- tasks／design／proposal透過CLI更新，spec需求未改；proposal locator同步1.2真實ViewModifiers位置。cache contextRef三artifact一致。analyze無Critical/Warning，保留原6項app-layer具體Example建議；validate通過，dependency圖18節點無環。現有user apply授權延續。

- 1.3 Root Store邊界有效負例：只在OrdersLegacyNavigationView加入private default-nil StoreOf<RootFeature> property與///，全部962份Swift hash僅此檔不同；原備份SHA e57e75b45b34fdf1b03c15b593b6f5ee3436285ce0437a7e633dd185ab7b4265。iPhone17/iOS26.5 focused guard實際0通過／1預期失敗／0略過，error0，failure明列額外OrdersLegacyNavigationView而非編譯失敗。已立即交Codex只反向還原暫時property，待hash/正向確認。

- 1.3受控守門已完整還原：main比對全部962份Swift hash與注入前完全相同、bridge與備份byte相同且SHA e57e75b45b34fdf1b03c15b593b6f5ee3436285ce0437a7e633dd185ab7b4265。相同focused guard恢復1通過／0失敗／0略過，error0。連同413原生probe2/2與unit/guard42/42、peer及main review，1.3宿主／狀態切片放行；正式helper與完整N1/N5仍由1.4/1.5全數驗收前禁止2.x。

## 任務1.4／1.5：正式helper與完整根UI前置批

- CLI start4／start5均在1.3完成後建立基線。Codex限定AppNavigator／RootNavigationScreen／PlatformScope與OrdersLayoutScopeSmoke，Gemini只新增RootNavigationContinuitySmokeTests與OrdersNavigationSmokeTests，不競寫。tdd/audit皆true，worker不build/test/git/Spectra。
- 1.4 StageA main審查發現兩scope草稿都先用舊goToOrders，會在導航先失敗而未到版面判定；交Codex改用已驗tapRootTab，讓scope負例真正驗根與功能分離，舊導航另由既有五頁LaunchSmoke驗證。這是測試有效性修訂，非產品變更。

- 1.4有效UI行為RED：iPadAir11M4/iOS26.5、build413 App不變，BuyLedgerUITests實際0通過／3預期失敗／0略過。五頁LaunchSmoke在舊AppNavigator:93找不到root class timeout；Orders Tabs已真進詳情但舊root推論timeout；Sidebar已真切換品牌及5入口且詳情前景，但isCompactLayout=false於scope:99。Peer所推測Tabs下list與detail同時AX存在不符合實測，改以實際timeout記錄。三條均實際到達預期舊helper斷言失敗，非編譯失敗。診斷另有1條LLVM default.profraw權限error，與前次既知工具profile雜訊相同，個別測試失敗原因均有對應assertion；不稱error0。全Swift hash在兩方readonly review與執行前後完全相同。

- 1.5草稿審查未放行：Codex獨立peer確認5P1與5P2，main採納5P1及等待／scoped內容／sidebar證據／風格四類P2。Back唯一ID候選已靜態修正，尚待runtime；兩受審檔hash在review前後完全相同。P2-4開團未收款案例屬2.4/3.2，不擴1.5範圍，packet N5摘錄已標清。main原packet以Mika簡稱未給完整exact值，peer發現草稿誤用exact Mika；main查Core/Domain/LedgerOrder+Samples.swift:62-64確認應為Mika 周，已交原作者修測試，不改seed。
- 1.4行為RED後放行Codex StageB僅三helper；1.5 peer落檔後才放行Gemini修自己兩新檔，源碼仍無交疊。首輪產品App維持413不變，全部新增只是UI test/helper，不執行新build而遞增版本。

- iPad前置實際狀態更新：pgrep找到DeviceHub PID79382，不能沿用前次closed推定；main用CUA實讀目前iPhone Duo視窗與Device Hub選單，點「Quit and Keep Simulators Running」，之後pgrep exit1確認前端已關閉且不再呼叫getApp重新啟動。開始新根413/KBD2獨立前置，沒有重開或清除模擬器。
- 1.4 StageB主審要求：兩內容框線重疊不當collapsed，toolbar小鈕不足以證兩欄；tapRootTab保留實際tap，高階已選取操作另處理。Codex已修三helper並parse，Gemini peer-1確認這些已解，但仍找到RootNavigationScreen.go在目標前景ready時漏必要root控制項檢查，以及NestedTypes重複/順序錯置，未放行。peer引用六區順序文案有誤，main按formatting.md實際規則Properties→Init→NestedTypes→ComputedProperties→InternalMethod→PrivateMethod核對，finding本身成立。KBD執行期間全部source hash不變，後續修訂待本組結束，不競寫。

- KBD首次新helper嘗試是build-for-testing失敗，沒有執行測試、無counts，不算行為RED/GREEN。RootNavigationScreen.swift:308 predicates contains呼叫被解析為Collection overload，三個相關型別診斷；另1條LLVM default.profraw權限雜訊。已交Codex第一輪有證據的可恢復修復，同批補peer必要root-control guard及NestedTypes順序，仍只3helper。既存CampaignsScreen/DashboardScreen/LookupManagementScreen actor warnings不屬本項新改方法，未擴全庫改寫。

- 1.5 peer-2確認5P1及先前選定P2已解，只剩兩處count前景即時讀取；Gemini只把兩condition改waitUntilHittable，main實讀兩處與精確2條件保持，Orders smoke在peer2後hash未變，其他finding不需整份重審。尚無runtime GREEN。peer-2之Campaign歸屬指示實為main按tasks2.4/3.2決策，非使用者另下指令，紀錄來源以本條更正。
- 1.4第一輪可恢復修復已停寫：root go先驗rootTab可互動再依前景決定tap、contains(where:)明確標籤、NestedTypes順序及合併。main限定4處source變動符合3helper+Gemini兩count condition；未修改App/project/其他source。DeviceHub仍closed；同一KBD2命令重新編譯執行。

- KBD第二輪仍未執行，27.4秒build-for-testing失敗。新診斷揭露AppNavigator:216／RootNavigationScreen:319在XCUIElement(下標結果)呼叫query才有的allElementsBoundByIndex，及AppNavigator:289回傳private enum的方法層級不符。前輪contains診斷只是推論表面，不能據此宣稱Collection overload是真根因；本輪明確更正。Gemini peer-2已靜態核對root guard/MARK修訂，但未發現這些型別問題，main以實際編譯優先，未放行。全部Swift在重編譯／唯讀前後hash相同。已授權Codex第2輪有新證據的最小query／access修復，仍原3helper，App413未動。

- 第三輪KBD已編譯成功並實際1通過／1失敗／0略過：文字return正常，數字完成鍵未收鍵盤。DeviceHub在當時及之後pgrep均closed。第二輪query/access型別修復已由真編譯證實；Context7與Xcode DocumentationSearch均對照matching(identifier:)回傳XCUIElementQuery、下標回XCUIElement、allElementsBoundByIndex屬query。private method是配合private result的編譯必要層級，未拓寬封裝。
- 失敗後CLI snapshot僅6節點/無前景targets，未取得失敗時Keyboard frame，不能據此宣稱是硬體鍵盤。Xcode GUI結果檢視2026-10-26晚間呼叫發生長時間timeoutReached，直到2026-10-27T11:21:49Z才恢復；期間沒有來源變動。main重驗全部Swift等於repair2，project三target仍413，Package.resolved存在，herdr兩impl皆done，DeviceHubclosed。改用Codex僅在KeyboardDismissTests暫加KEYBOARD_DIAG print(原操作/斷言不變)，前後hash只一檔差異；主跑numeric單例後立即反向還原。沒有以工具故障或靜態PASS當作驗收完成。

- 數字鍵盤單例暫時診斷實際0通過／1失敗／0略過。Window frame=(0,0,820,1180)，Keyboard=(0,1224,820,279)，鍵盤y1224明確大於視窗高1180；done兩AX候選frame=(760/764,1120,36/28,36)、均hittable=false。符合ios CLAUDE記錄應先修環境的具體症狀，未據此改App鍵盤工具列或放寬測試。main已立即請Codex反向還原診斷，待全Swift hash一致後重置僅iPad測試sim E30658D5-A19C-40CE-AA6E-C11BEAE95A1A，閉Hub boot並重跑原始KBD2。

- 暫時鍵盤診斷已由原作者精確還原，main確認全部Swift hash等於診斷前、KeyboardDismissTests與備份逐byte相同。MCP erase --shutdown-first只重置iPad E306...，成功；boot回success但appearance回Shutting Down，且DeviceHub PID87592出現，沒有據此當Ready。main發現前提不完整後SIGINT停止該次MCP test PID89006，exit130且無殘留xcodebuild，不計通過／失敗測試。MCP list稍後顯示iPad Booted；安裝工具的boot/erase source不直接openGUI，Hub重現原因未確定。QA子代理缺CUA surface，未操作任何App；main用CUA timeout10000讀正確iPad Simulator，見Apple開機進度直到主畫面，不誤用Inspector殘留Duo AX文字。選單無可靠勾選標記，main只做一次Simulate Hardware Keyboard切換後Quit and Keep Simulators Running，未聲稱先前checked狀態；pgrep確認Hubclosed，appearance第二次成功，才重跑原始KBD2。鍵盤實際操作結果作環境完成證據，非僅採boot回報。

- 環境復原後E306的KBD2在build成功、runner安裝後停留startup，約8分鐘未有Test Case，xcodebuild CPU0且截圖停在主畫面並有UITest runner圖示。main精確SIGINT該MCP PID191，exit130、pgrep無xcodebuild，不計任何測試數。先前不完整run PID89006亦exit130。另啟既有同機型同OS iPad E2AA8A17-769E-4D22-8F4A-C67531688232作環境對照，不刪其他device或改驗收版本；開機期間先序列跑既有iPhone17/iOS26.5上6項受影響Launch／Tabs scope／Orders smoke，Pad N1/N5門檻仍保留。HardwareKeyboard偏好讀取只見舊DevicePreferences UUID之false，未取得E306可靠checked證據，不能把GUI切換方向寫成已證實。

- iPhone26.5六項受影響UI對照build成功，但實際只有System Failures 0pass/1fail/0skip，產品六case均未開始，錯誤Runner Failed to establish communication / Channel disconnected。不當作六項產品斷言失敗或通過。查可讀DiagnosticReports／兩sim CrashReporter未找到對應runner crash。先前known-working testproducts(含11:26diag)已不在快取，無法oldbinary對照。按debug流程先跑未改RootFeatureTests比較一般／UI runner，再由Gemini只在/tmp建獨立無依賴、單空UIcase探針，不改repo或算產品coverage。此仍是定位階段，不憑連線中斷猜產品架構或盲重啟服務。

- 2026-10-27 runner隔離：未改RootFeatureTests在iPhone17/iOS26.5亦build-for-testing成功，但test-without-building超過6分鐘沒有案例開始；main SIGINT自有MCP PID20761，exit130並確認無xcodebuild殘留。這次沒有 counts，不能把中止當作產品失敗或通過。日誌引用不存在的/Volumes/SN750 500G/Xcode/DerivedData，因缺可用舊成功log對照，因果未證實；不更改使用者Xcode全域設定。全部965份Swift hash仍精確等於repair2。MCP新list僅列26.5，E2AA...實體device.plist已不存在，不能再把先前boot回報當作目前可用；不自行重建Duo或其他裝置。Gemini在/tmp建立無依賴空UI case供最小隔離，由Codex交叉唯讀審查；此探針不計產品coverage或前批任務完成。

- 最小獨立UI探針已由Gemini完成、Codex交叉唯讀審查，main確認五檔hash凍結；26.5 simulator實際編譯成功，排除peer條件式SUPPORTED_PLATFORMS疑慮在build階段發生。但run階段315秒仍無唯一空case，main中止MCP31759、exit130，無殘留xcodebuild。沒有counts，不當作0fail通過。探針沒有 BuyLedger 程式碼或套件，唯一案例只做 `XCTAssertTrue(true)`，不啟動或操作 App。當時已接受 1.1、1.2、1.3；1.4／1.5 已實作並交叉審查，但執行門檻未通過；全部 965 份 Swift 來源等於 repair2 基線，沒有殘留鍵盤診斷或受控 mutation。獨立無依賴專案亦重現startup停滯，尚未確認底層根因；不憑外接DerivedData寫入錯誤推定因果、不改全域Xcode偏好或產品。1.4／1.5繼續未完成，依既定依賴不啟動2.x；CLI總計仍3/18。

## 2026-10-27：改用實機與 runner 復原

- 使用者指定：SN750 外接碟已接上；除 iPhone Duo 外，單元與 UI 測試改跑實體機 iPhone 12 (iOS 26.7.2，UDID 3552E16B-F199-548A-95F9-76A0BEDE408F) 與 iPad Air 5 (iOS 27.2，UDID E08B5195-951A-5C86-AB67-2CFFD1ECCD9E)；兩台 SwiftData 資料不需保留。主對話 (Claude) 查到 Xcode 全域 `IDECustomDerivedDataLocation` 指向 SN750，先前未掛載，與 runner 啟動停滯的日誌現象相符；接上後實機 runner 正常，但模擬器端未做對照，仍不宣稱已證實根因。
- 安全確認：工作區 `BuyLedgerSchema.swift` 與 ios-v2.1.0 逐字相同 (V17)；單元測試宿主略過資料庫建立，UI 測試使用記憶體或獨立 `BuyLedgerUITest` store，不碰 App store；UI 測試會清 App 的 UserDefaults，屬使用者容許範圍。
- 版本落差：iPad Air 5 是 iOS 27.2，1.5 原文「iPad26.5」與 4.2「不以新系統代替最低版本驗收」的 iPad iOS 26 部分不由此機涵蓋；照使用者指示先以 iPad Air 5 執行，tasks 文字待 ingest 更新。
- iPhone 12 runner 復原：未改的 `BuyLedgerTests/RootFeatureTests` 8 通過／0 失敗／0 略過，206.9 秒，exit 0；只有既有 SPM 傳遞依賴 warning。執行前 975 份 Swift hash 已存快照，App 與測試版本仍 413。
- iPhone 12 UI 首次嘗試在簽章階段失敗：找不到 `com.leoho.BuyLedgerUITests.xctrunner` 的 development profile，沒有執行任何案例。專案為 Automatic signing (team 23JEQ2524P)，主對話加 `-allowProvisioningUpdates` 讓 Xcode 建立 runner profile 後重跑，未改專案簽章設定。
- iPhone 12 UI GREEN：BuyLedgerUITests 8 通過／0 失敗／0 略過，298 秒，error 0；KeyboardDismissTests 2 條 (文字 return、數字完成鍵)、LaunchSmoke 五分頁初始與依序切回總覽 2 條、Orders 原生 Tabs scope 1 條、OrdersNavigationSmokeTests 3 條 (詳情與原生 Back、編輯單一 sheet 與捨棄、新增單一 sheet)。29 條 actor warning 全在未改檔 (Screen、Assertions、Diagnostics、Campaigns／Dashboard／LookupManagement Screen)，1.4 三個 helper 無新 warning。sidebar、N1、N5 屬 iPad 適用案例，於 iPad Air 5 執行。
- iPad Air 5 首次 UI 執行：build、簽章與 runner 安裝成功 (`-allowProvisioningUpdates -allowProvisioningDeviceRegistration`)，但只有 System Failure 0 通過／1 失敗／0 略過，錯誤為 runner 初始化 UI testing 時 `Timed out while enabling automation mode`；13 個產品案例均未開始，不計通過或失敗。需在裝置開啟開發者設定的 UI Automation 並解鎖授權後，以同一份 test products 重跑。
- 主對話確認全部 Swift hash 與實機首跑前快照相同後，iPad Air 5 實際執行 13 案例：10 通過／3 失敗／0 略過，282 秒，error 0。通過：KeyboardDismissTests 文字 return、LaunchSmoke 三條 (含原生 More 與側邊欄切換)、OrdersLayoutScope Tabs／Sidebar 兩條、OrdersNavigationSmokeTests 三條、N5B 客戶來源往返。中間兩次是 CLI 參數互斥 (test products 與 session projectPath) 驗證失敗，未執行案例。
- N1 失敗 (`切換至訂單分頁後側邊欄偏好未保留`) 與 N5A 失敗 (`切回分頁列後側邊欄品牌標記仍存在`) 為同一成因：iPad Air 5／iOS 27.2 直向 820×1180 下，根側邊欄是蓋住內容的 overlay (背景變暗)，在 overlay 點選目的地後系統收起側邊欄、回到浮動分頁列；N5A 因此在已回分頁列時再點 ToggleSideBar，反而把側邊欄打開。失敗 AX 顯示 ToggleSideBar 與五個 root.tab.* 位於頂部分頁列、訂單 Selected、徽章 4，目的地本身正確。Xcode DocumentationSearch 對照 sidebarAdaptable、defaultAdaptableTabBarPlacement、TabViewCustomization，未找到直向固定側邊欄的 API；design N1 只要求切換側邊欄再選分頁時目的地與徽章正確、根樣式變化不重建狀態，測試把直向 overlay 收起當成偏好遺失，屬 1.5 測試前提錯誤，非產品缺陷判定。iOS 26 iPad 是否相同未實測。
- KeyboardDismissTests 數字鍵盤失敗：`Neither element nor any descendant has keyboard focus`。軟體鍵盤在 y=898 (非硬體鍵盤)，新增訂單 sheet 被推到 (120,91.5,580,660)，實付金額欄 (231.5,745,432.5,44) 只有 6.5 pt 落在 sheet 內，點擊未取得焦點，焦點仍在 customerField。`clearAndType` 只以鍵盤存在判斷聚焦，前一欄已有鍵盤時不重試即 typeText。此為既有 UI 測試 helper 在 iOS 27.2 實機幾何下的缺口，不屬 1.4 三個 helper 範圍。1.4／1.5 維持未勾選，修正方向待使用者決定。
- 使用者決定：N1／N5A 改測試前提 (側邊欄保留檢查改在橫向；直向驗 overlay 點選後收起、目的地與徽章正確、功能狀態不重建)；數字鍵盤 helper 修正併入 1.4。使用者指定改由 claude-leader (Claude 主對話) 擔任原 codex-leader 角色。主對話因 codex-impl weekly limit 剩 3%，改派 claude-impl 實作 helper (TextInput／OrderEditScreen，必要時 Scrolling)、gemini-impl 實作 RootNavigationContinuitySmokeTests，兩檔範圍不重疊，完成後互相唯讀審查。派工前 git status 39 列已存快照。
- gemini-impl 第 1 輪退回已修 (主對話審查發現：整棵樹 `label CONTAINS '4'` 徽章比對會被日期／金額假通過，改為側邊欄可見時以 `root.tab.orders` 的 Cell label 結尾驗 4、分頁列模式附截圖；N5A 第一次切根樣式改為先斷言分頁列再無條件切換；補中英文間距)。
- iPad Air 5 第 2 次執行同 13 案例：12 通過／1 失敗／0 略過，317 秒，error 0。N1、N5A、N5B 與其他 1.4／1.5 案例全數通過。
- 唯一失敗：KeyboardDismissTests 數字鍵盤 `數字鍵盤工具列的完成鍵未能收起鍵盤`。新 helper 已讓實付金額欄取得焦點並輸入 (前一輪的聚焦問題已排除)。失敗時 AX：`keyboardBackground` 與 `UIKeyboardLayoutStar Preview` 在 y=1180 (視窗高 1180，畫面外)，`Keyboard` 只剩底部 64 pt 列，App 完成鍵 `common.keyboard.doneButton` 在 (764,1120,28,36)；截圖只見右下浮動 ✓、sheet 置中未被推高。與先前模擬器接硬體鍵盤的症狀相同，依 apps/ios/CLAUDE.md 判為環境 (iPad 接上實體鍵盤)，不改產品或 helper；第 1 次執行時軟體鍵盤仍在 y=898，表示期間鍵盤重新連上。另觀察：欄位值為 1230 (預期 123)，游標停在原值「0」之前，清空未生效，待回歸確認是否影響 OrderCreateTests 等數值斷言。
- 更正：使用者確認 iPad Air 5 未接任何鍵盤，上一條「接上實體鍵盤」的環境判斷不成立，撤回。測試錄影點完成鍵前後的影格顯示 iPadOS 27.2 的數字鍵盤是貼在欄位旁的浮動小型數字面板，App 鍵盤工具列的完成鍵 ✓ 變成右下角浮動按鈕 (AX 即 (764,1120))；XCTest 以座標點擊該 ✓ 後面板未收起、欄位仍為 Keyboard Focused。`1230` 為點擊靠右對齊欄位時游標落在原值「0」之前，刪除鍵未刪到字。兩者都是 iOS 27 的系統呈現差異，與 iPhone 12 (iOS 26.7.2) 不同；完成鍵在真人操作下能否收起尚未確認，產品或測試歸屬待定。
- 交叉審查 (主對話比對審查前後全部 Swift hash 與 git status 不變)：claude-impl 審 N1／N5A 得 P1 一項 (三個側邊欄案例與 LaunchSmoke 側邊欄案例未宣告 regular 版面，iPhone 全回歸會固定失敗；`isRegularLayout` 綁訂單並排，不適用根導覽) 與 P2 四項 (橫向後未等側邊欄穩定、轉直向斷言順序缺觀測值、徽章 `hasSuffix("4")` 過寬、teardown 還原直向未等待)；gemini-impl 審鍵盤 helper 得 P1 (`scrollGently` 捲不動時盲拖滿 12 次，未用位置簽章停止) 與 P2 兩項 (完整可見判斷含水平軸、重試點擊未先確認可點)。主對話全數採納。
- style 閘門 (haiku-max-implementer，逐檔逐條 43 條規則)：違規 93 處 (TextInput 5、Scrolling 13、OrderEditScreen 1、RootNav 74，多為排版)。主對話裁定：B1 保留 `keyboardFocusSummary` (僅失敗路徑、約 12 行)、B2 保留 guard 內 `first(where:)`、B3 依 kit 調整方法順序、B5 保留手動截圖 (1.5 原文要求截圖核對徽章)。使用者裁決：B4 UI 旅程測試允許多組 When／Then；B6 檔名與 B8 Bool 動作型 helper 命名留到 ios-dev-kit 第 9 步；B7 N5 預期值改 seed 字面值。
- iPhone 12 回歸 (第 1 輪修正後原始碼，未含第 2 輪)：1.4 iPhone 適用 8 案例加 `clearAndType`／捲動 helper 影響的 12 類別，共 72 案例：71 通過／1 失敗／0 略過，1988 秒，error 0。OrderCreateTests 金額斷言全過，`1230` 清空問題未在 iOS 26.7.2 出現。唯一失敗 `OrientationLayoutTests.testRotateToLandscape_含開團與訂單資料_分析頁附上橫向截圖` 為 `insights.chart.costDonut` 的 `Activation point invalid`，同一份原始碼單獨重跑 1 通過／0 失敗，依 apps/ios/CLAUDE.md 判為環境雜訊。
- 使用者手動實測 (iPad Air 5，iPadOS 27.2)：叫出浮動數字面板時沒有 ✓ 可點；叫出數字面板後在欄位點兩下會換成完整軟體鍵盤，此時才有 ✓。KeyboardDismissTests 數字鍵盤案例「數字鍵盤上方有 App 完成鍵」的前提在 iPadOS 27 浮動數字面板不成立，屬 iOS 27 系統呈現差異；iPhone 12 (iOS 26.7.2) 同案例通過。
- spectra-ingest (主對話執行，來源為本次對話的使用者決定)：design 新增「測試裝置與 iPadOS 27 適應」(含 Supersedes 原 iPad iOS 26.5 模擬器安排、已實測的三項 iPadOS 27 差異、實機前置、範圍內外)，更新 1.4 描述與 Risks；tasks 更新分工表、加 2026-10-27 修訂說明，改寫 1.4、1.5、3.1、4.1、4.2，已完成 1.1–1.3 原樣保留、總數仍 18。proposal 與 specs 不變 (ui-test-support-layer 既有「重新輸入內容剛好等於要求值」「數字鍵盤經工具列完成鍵收起」與新 helper 一致)。spectra analyze 0 Critical／0 Warning，保留原 6 項 Suggestion；spectra validate 通過。
- 主對話審查未暫存內容 (使用者要求；第 2 輪修正中的 7 檔另審)：P1 `PlatformScope.isRegularLayout／isCompactLayout` 由根導覽判斷改為「訂單前景並排／收合」判斷，但約 42 個既有呼叫端 (OrderFilterSheet*、OrderCategoryPicker*、OrderPaymentMethodMenu、OrderRegular*) 都在 `launch` 後、仍停在總覽時判斷，讀碼判定會 10 秒後 failWithDiagnostics 而非依版面 skip，違反 design「每批維持對應測試通過」(呼叫端遷移原排在 3.2)，待實機驗證。P2：原型 `AdaptiveSplitPrototypeOrdersView`、`BLAccessibilityID+AdaptiveSplitPrototype` 與 `OrdersFeature.adaptiveSplitSelectionChanged` 未以 DEBUG 包住而編入 release，且 tasks 無原型清理歸屬 (原型依賴 3.1 要刪的 BLLayoutClass)；apps/ios/CLAUDE.md、ios-design-system.md、ios-navigation.md、README 的根宿主與版面描述已與程式碼矛盾，會被 2.x agent 自動載入；1.3–1.5 其餘檔案未經逐檔 style 閘門。P3：BLReadableContentLayout 註解寫入 agent 來源與 task 編號、非規範 MARK 區名；原型 `#Preview` 不在檔尾；`showDetail` 雙重否定 guard；容器直接 `path.removeAll()` 未經子 State 方法；預留 identifier 用字串型別參數。
- 第 2 輪修正 (claude-impl 六檔、gemini-impl 一檔) 完成後，iPad Air 5 首次執行在 build 階段失敗，未執行任何案例：`AppNavigator.swift:321` 回傳 private 型別 `RootPresentationMode` 的方法在本輪「private extension 內移除逐成員 private」後變成 fileprivate，編譯錯誤 `method must be declared private because its result uses a private type`。此為第 1 輪已記錄的編譯必要存取層級，待交叉審查結束後交 claude-impl 恢復。
- 第 2 輪交叉審查 (主對話比對審查前後全部 Swift hash 與 git status 不變)：gemini-impl 審 claude-impl 六檔，上一輪 4 項確認修好，新 P2 為 KeyboardDismissTests 浮動面板判定以即時 `isHittableOnScreen` 判斷完成鍵、未先等待，iPhone 鍵盤升起動畫中可能誤點兩下 (採納：先等完成鍵 1.5 秒)，P3 補註解；確認 App 無 `clearButtonMode`，尾端點擊不會誤清空。claude-impl 審 gemini-impl 一檔，上一輪項目大多修好，新 P1 為三個 skip 訊息宣稱「compact 由 LaunchSmokeTests 覆蓋」不實 (主對話決定：訊息改為 compact 無根樣式切換、不切換根樣式的 N5 連續性由 3.2 補)，P2 兩項：每月目標 `80000` 等於預設值、無法區分保留與重建 (採納：離開設定前改為 `90000` 再比對)，客戶列保留比對仍用執行期 baseline (採納：改用 `林書宇` 字面值)，P3 teardown 逾時無訊息、轉直向讀 marker 前未等待、rootLayout 失敗訊息缺觀測值 (採納)。
- 風格閘門第 2 輪 (haiku-max-implementer，7 檔逐條 33 條規則)：違規 20 項 (AppNavigator 11、LaunchSmokeTests 5、RootNav 4；多為 3 參數未合併單行與 Bool 命名，含 `rootSidebarMarkerIsVisible` 改 `isSidebarMarkerVisible`)。第 3 輪派工：claude-impl 修 `AppNavigator` 編譯錯誤 (恢復回傳 private 型別方法的 `private`)、浮動面板判定先等完成鍵、V1–V16 與改名 (含 OrdersLayoutScopeSmokeTests 引用)；gemini-impl 修 skip 訊息如實、每月目標先改 `90000` 再驗保留、客戶列改字面值、teardown 逾時 XCTFail、轉直向讀 marker 前等待、rootLayout 失敗訊息帶觀測值、V17–V20。新名稱由主對話先約定，兩檔範圍不重疊。
- 第 3 輪修正後 iPad Air 5 (build 成功)：18 案例 13 通過／5 失敗／0 略過，468 秒，error 0。1.4／1.5 門檻 13 案例全數通過：KeyboardDismissTests 2 條 (數字鍵盤走浮動面板點兩下換完整鍵盤再按完成鍵)、LaunchSmoke 3 條 (側邊欄案例以 rootLayout 判為 regular 實跑)、OrdersLayoutScope 2 條、OrdersNavigationSmoke 3 條、N1／N5A／N5B (含每月目標改 90000 後保留、林書宇字面值)。5 個失敗全為 OrderCategoryPickerTests，訊息 `無法辨識 Orders 前景欄位` (PlatformScope.swift:36)，實機證實主對話審查 P1：PlatformScope 改為訂單前景判斷後，launch 後停在總覽即判斷的既有呼叫端直接失敗。
- 第 3 輪交叉審查 (審查前後全部 Swift hash 與 git status 不變)：gemini-impl 審 claude-impl 五檔，上一輪 P2／P3 與 V1–V16 全數修好、無新發現；claude-impl 審 gemini-impl 一檔，上一輪 P1／P2／P3 與 V17–V20 全數修好、無新 P1／P2，另列 OrderCategoryPickerTests 失敗即主對話審查 P1，P3 五項：改名後 `:68`、`:236` 程式碼行超過 100、轉直向後固定等 1 秒、`setMonthlyGoal` 後立即讀值未等待、設定頁收數字鍵盤無浮動面板補救 (本次實機通過)、gemini 回報行號不準。
- 使用者決定 (主對話審查建議全部採納)：P1 版面判斷呼叫端遷移併入 1.4；原型只在 DEBUG 編譯、移除併入 3.1；規則文件現在寫最終契約、未成立部分以「遷移中」子項標出 (使用者確認此「接近一次到位」做法)，3.1 只刪子項並更新 README 結構；風格閘門擴大到全部 1.3–1.5 檔案。主對話決定：風格第 3 輪 Q1 比照 rootLayout 宣告 OrdersLayoutScope 側邊欄案例；Q2 依 2026-10-09「Given 直設」裁決改用 `LaunchOptions.monthlyProfitGoalTWD: 90000`，因設定即時存檔、畫面重建也讀回同值，UI 輸入不增加區分力。第 4 輪派工：claude-impl 修風格 N1–N17、Q1 與五份規則文件；gemini-impl 修 RootNav N18–N20、P3-2、Q2、十個呼叫端類別、原型 DEBUG 化與主對話審查 P3。三個 haiku-max-implementer 平行審第 4 輪不動的 1.3–1.5 檔 (產品 7、單元測試 13、UI 測試 5)。spectra-ingest：1.4、3.1 與分工表、design 範圍與 1.4 段落更新，已完成任務不變，analyze 0 Critical／0 Warning，validate 通過。
- iPhone 12 第 3 輪程式碼回歸 (含 OrderFilterSheetTests 與 RootNav)：87 案例 70 通過／13 失敗／4 略過，2499 秒，error 0。略過 4 條為 RootNav 三條與 LaunchSmoke 側邊欄案例依 rootLayout 判為 compact (版面宣告生效)。失敗：OrderFilterSheetTests 10 條 `無法辨識 Orders 前景欄位` (P1 在 iPhone 亦證實，第 4 輪已遷移呼叫端)；OrdersLayoutScope Sidebar 案例 `找不到原生根側邊欄切換按鈕` (iPhone 無側邊欄，第 4 輪 Q1 已補版面宣告)；OrientationLayoutTests 分析頁 `Activation point invalid` 第二次在整批中出現 (前次單獨重跑通過)，列入觀察；QuoteTests `testTypePrincipal` 預期 `$230` 實得 `$30`。
- QuoteTests 判定為既有假通過：錄影 顯示 iOS 26.7.2 點「商品定價」欄後游標也落在預設值「0」之前；舊 clearAndType 刪除鍵刪不到字，輸入 1000 實為 10000 KRW，依 `FxRates` KRW 0.0228 換算 228 TWD、進位為 $230，測試預期值即由此而來。新 helper 先移游標到尾端後正確輸入 1000，得 22.8 TWD 進位 $30。第 5 輪改正預期值。另：真人點預設值為 0 的金額欄直接輸入同樣會接在 0 之前 (iPhone iOS 26 亦然)，屬本 change 範圍外的產品輸入問題，已回報使用者另行決定。
- 擴大範圍風格閘門結果 (haiku-max-implementer 唯讀)：產品碼 7 檔 7 項 (另 5 項待裁決：P-1 RootNavigationLayout 名稱、P-2 BL 前綴、P-3 guard 內 preconditionFailure、P-4 init 參數預設值由主對話裁定保留，P-5 `DEBUG` 加反引號)；單元測試 13 檔 87 項 (主對話裁定測試名內程式識別字與平台名詞如 path、UI、compact、regular 允許，一般英文詞如 Oracle、HostBounds、Inset 改中文；單元測試仍一個測試一組 When／Then；框架名不加反引號；測試支援型別後綴與同檔 View 擴充保留)；UI 測試 5 檔 69 項 (另 B9 多行下標比照呼叫端計入、原型測試 skip 位置與返回鍵定位一併修；測試名夾技術詞允許、整段英文不允許)；第 4 輪呼叫端 10 檔 2 項 (helper 複製排到 ios-dev-kit 第 9 步)。第 4 輪改動 12 檔的閘門因輸出超過上限中途失敗，拆成 5 檔與 7 檔兩組並要求精簡輸出重跑。
- 第 5 輪派工 (檔案不與重跑中的 12 檔閘門重疊)：claude-impl 修文件四項 (ios-ui-tests 主條目與 goToOrders、ios-design-system 規則十一現況、apps/ios/CLAUDE.md 的 test products 與 projectPath 互斥 gotcha；LaunchSmoke skip 訊息主對話決定保留)、產品碼 7 檔、單元測試 13 檔；gemini-impl 修 UI 測試 5 檔、呼叫端 2 項、QuoteTests 預期值改 `$30`。
- 第 5 輪後 iPhone 12 單元測試 (排除 17 個 snapshot 類別)：前兩次 build 因 P1 移除 import 失敗 (`DesignSystemSourceScanTests`、`RootFeatureSidebarTests` 需 `Foundation`，MemberImportVisibility)，已請 claude-impl 恢復；第三次 build 成功，1745 案例 1703 通過／42 失敗／0 略過，117 秒。42 個失敗全屬讀取 repo 原始碼或資源檔的守門測試 14 類 (LocalizationCatalogTests、DependencyConventionScanTests、OrderListSnapshotSourceScanTests、LayerBoundaryTests、ServiceOwnershipScanTests、TestSuiteIntegrityTests、ProjectionWriteBoundaryGuardsTests、PrivacyManifestTests、LocalizationCatalogSourceGuardsTests、NumericInputGroupingScanTests、DesignSystemSourceScanTests、DesignSystemSourceScanScaledMetricTests、ActionGroupingScanTests、AccessibilityConventionScanTests)，錯誤為裝置上找不到 `/Users/leoho/Develop/BuyLedger/...` 檔案：實機無法存取主機檔案系統，屬環境限制，非產品或測試回歸。邏輯類單元測試 (含第 5 輪拆分的閱讀寬度測試與新字面值斷言) 全數通過。
- 使用者決定 (2026-10-28)：讀 repo 原始碼的守門測試 14 類與 snapshot 測試 17 類改在 iPhone 17 iOS 26.5 模擬器執行，其餘單元測試維持 iPhone 12。design「測試裝置與 iPadOS 27 適應」與 Risks、tasks 4.1 與修訂說明已同步。
- 模擬器環境復原 (主對話)：原 iPhone 17 (1FB73457) 停在 Shutting Down，開機與 erase 皆無回應。主對話正常結束 Device Hub 無效、SIGTERM 被服務忽略，使用者手動 `kill -9` 服務後全部模擬器重建，改用新 iPhone 17 iOS 26.5 `CBE3AABB-FFBF-4F91-AFF9-5DD283DDB410` (iPhone Duo iOS 27.1 新 UDID `1666A373-A43C-4CF5-A468-ED8D513A3269`，4.3 使用)。
- 第 5 輪後程式碼於 iPhone 17 iOS 26.5 模擬器 (淺色外觀、關閉平行測試) 執行守門 14 類與 snapshot 17 類：154 測試 (參數化共 333 次執行) 全數通過／0 失敗／0 略過，417 秒；result bundle 的 TestCaseRuns 確認 31 類皆有執行列，snapshot 無差異、未重錄。合併 iPhone 12 的 1703 個邏輯類通過，第 5 輪程式碼的單元測試全數通過。
- 第 6 輪派工 (守門測試結束後才派)：gemini-impl 修 RootNavigationContinuitySmokeTests 的 R1–R3、P1 與產品／identifier 7 檔 V1–V13、D6、D8、D9，`clearDetail()` 搬入 OrdersDetailNavigationFeature.State 緊接 `showDetail(orderID:)` (修正主對話第 4 輪指示錯誤)；claude-impl 修 OrdersLayoutScopeSmokeTests R4、AppNavigator P2、三個單元測試檔的反引號與斷行、「已落盤」白話，並在 apps/ios/CLAUDE.md 與 README 記錄守門與 snapshot 跑模擬器的例外。兩組檔案不重疊。
- 第 6 輪修正後 (claude-impl 5 個 Swift 檔與 2 份文件、gemini-impl 9 檔，改動範圍與派工一致) 於 iPhone 17 iOS 26.5 模擬器重跑守門 14 類與 snapshot 17 類：154 測試 (333 次執行) 全數通過，201 秒，31 類皆有執行列；App 與單元測試編譯通過，確認移除 `@CasePathable`、`import Foundation` 與 `clearDetail()` 搬移安全。
- 第 6 輪交叉審查 (審查前後 Swift hash 與 git status 不變)：gemini-impl 審 claude-impl 全數已修，新 P2 為 AppNavigator 診斷字串 189 字 (主對話上一輪裁定內插所致)、P3 兩項；claude-impl 審 gemini-impl 全數已修，P2-1 指 `showDetail` 同一訂單重開保留元素未經測試，主對話核對已有 `list_相同訂單重開_保留path元素識別值` 覆蓋，只採文件未同步部分；P2-2 Common 預留識別碼屬 1.2 擴充階段，主對話決定保留並在 3.1 寫明 2.x 後零呼叫或重複者刪除。主對話自審另列 N1 測試名「保全」用錯字、冗餘條件、原型 action doc 重複。
- 風格閘門第 6 輪 (haiku-max-implementer 三組唯讀)：UI 測試 3 檔計入 6 項、產品 7 檔計入 7 項、單元測試 4 檔計入 1 項；主對話裁定不計：空命名空間單行、原型無參數 typealias、樣板的 `- Parameter action` 與 Action／Effect、範圍外既有佔位預設值、App 既有術語 (投影、推入、KPI)、ASCII、多參數 closure 的 `_`、任意順序 receive 的謂詞形式、`@MainActor` 標在 extension、`app.windows.firstMatch`。
- 第 7 輪派工 (檔案不重疊)：gemini-impl 修 RootNavigationContinuitySmokeTests、原型 view、BLReadableContentLayout、OrdersDetailNavigationFeature、OrdersFeature、BLAccessibilityID+Common、BLAccessibilityIDTests；claude-impl 修 AppNavigator、OrdersLayoutScopeSmokeTests、RootFeatureLookupSyncTests、OrdersFeatureDetailTests、apps/ios/CLAUDE.md、ios-navigation.md。
- 第 7 輪完成 (改動範圍與派工一致，git status 列數不變)：claude-impl 修 AppNavigator 診斷字串改 `"""` 多行、`rootLayout`／`selectTab` 條件先以 `let` 接結果 (保留判斷順序)、OrdersLayoutScope 摘要、`落盤` 測試名、CLAUDE.md snapshot 外觀條目、ios-navigation.md 補「重開目前唯一詳情時保留原元素」；gemini-impl 修 N1 測試名、摘要以「驗證」開頭並把 N 編號移到句末、刪 N1 本體結尾重複的轉向 (teardown 已還原)、冗餘條件與 `Equatable`、複述註解、`showDetail` doc、原型屬性 doc、`private let type`、Preview 顏色寫法、OrdersFeature doc 與 core 順序、Common stored property 順序與 Note 白話、BLAccessibilityIDTests 反引號與測試名。主對話審查兩組改動與逐字元機械檢查 (行寬、尾隨空白、全形括號、註解句號、破折號) 無問題。
- 最終程式碼於 iPhone 17 iOS 26.5 模擬器 (淺色) 跑守門 14 類與 snapshot 17 類：154 測試 (333 次執行) 全數通過，190 秒。
- 使用者決定 (2026-10-28)：金額欄游標落在預設值 0 之前的產品問題另開 change 修正，範圍為所有輸入框：數字欄位 (金額、百分比、匯率、報價等) 聚焦時全選、輸入即取代；一般文字欄位聚焦時游標移到既有文字尾端。本 change 的 design 已同步改寫該段。
- 最終程式碼實機回歸 (第 7 輪後)：iPhone 12 邏輯類單元測試 (排除模擬器跑的 31 類) 1667 通過／0 失敗，128 秒。iPhone 12 UI 回歸第一次因 runner「Timed out while enabling automation mode」未執行，使用者開啟 UI 自動化後重跑中。iPad Air 5 完整 UI 回歸 (排除效能測試) 156 案例 99 通過／24 失敗／33 略過，3130 秒，為首次在 iPadOS 27 實機跑完整回歸。
- iPad 失敗分析 (主對話)：英文語系直向頂部分頁列放不下五個標籤，More 收在系統「下一頁」後 (CurrencyPickerTests 9 條)；共用 `dismissNumericKeyboard` 未適應 iPadOS 27 浮動數字面板 (FxTests、OrderCreateTests、QuoteTests)；數字鍵盤本次以 Popover 呈現且 clearAndType 第二次點擊落在 PopoverDismissRegion，值成 1230 (KeyboardDismissTests)；鍵盤晚升起使表單 sheet 上移，儲存點擊用了舊座標 (CampaignCrudTests、CampaignFlowTests)；篩選 sheet 日期選單項目在 iPad 沒有 identifier (OrderFilterSheetTests 4 條)；OrientationLayoutTests 以訂單前景推測根導覽；InsightsTests 空狀態不算前景就緒。LookupManagementTests 刪除失敗保留、OrderFilterSheet 清除搜尋、OrderFilterSheetLarge 輕拖待修正後重跑確認。略過 33 條皆為 regular 專屬案例，iPad 訂單在 2.3 前維持 compact 橋接，略過合理，但其 compact 覆蓋依賴的篩選 sheet 測試須修好。以上皆屬 1.4 列明須在兩台實機通過的類別，1.4／1.5 維持未勾選。
- 第 8 輪派工 (主對話依失敗分析)：claude-impl 修共用 helper：`dismissNumericKeyboard` 涵蓋浮動面板與 Popover 數字鍵盤、`clearAndType` 第一次聚焦即點欄位尾端、`tapAfterWaiting` 等元素位置穩定再點、AppNavigator 根分頁溢出時經原生側邊欄切換並還原呈現、分析頁空狀態算就緒、ios-ui-tests.md 補 iPadOS 27 gotcha；gemini-impl 修 OrientationLayoutTests 根導覽與功能版面分開判斷、`tapMenuItem` 在 identifier 缺席時以可見標籤回退。
- iPhone 12 完整 UI 回歸 (第 7 輪程式碼，使用者開啟 UI 自動化後重跑)：156 案例 116 通過／4 失敗／36 略過，3610 秒。略過皆為 regular 專屬案例。失敗：InsightsTests 空資料 (同 iPad，第 8 輪 K5 已修)；AdaptiveSplitPrototypeTests 3 條：iPhone 12 橫向仍為 compact，原生分欄收合顯示詳情、清單列離開可及性樹，原型欄位分類回傳 unavailable (2 條)；根側邊欄診斷案例未宣告 regular 範圍 (1 條)。原型 3.1 移除，主對話決定先修正使其在兩台實機正確通過或依版面略過，派 codex-impl (使用者告知額度已恢復)。
- 第 8 輪交叉審查 (審查前後 Swift hash 與 git status 不變)：claude-impl 審 gemini-impl 無 P1，P2 為標籤回退可能誤點同名觸發鈕、謂詞 `title`、只取 firstMatch、回退遮蔽 identifier 回歸；gemini-impl 審 claude-impl 無 P1／P2，P3 兩項。主對話裁定後第 9 輪修正：gemini-impl 標籤回退限縮在展開中的選單容器並排除觸發鈕、取第一個可點候選、回退留 activity 紀錄、只用 label 謂詞；claude-impl 點兩下後完成鍵中心點擊備援、tapRootTab 總等待不超過 timeout。主對話另退回 OrientationLayoutTests 的 regular 分支不可強制要求側邊欄 (根導覽預設放置為分頁列)。
- iPad Air 5 第 8／9 輪程式碼重跑 16 類 (失敗類別與 1.4／1.5 核心門檻)：82 案例 73 通過／9 失敗，2227 秒。已解決：CurrencyPicker 英文溢出 9 條、Fx／Quote／KeyboardDismiss 數字鍵盤、Insights 空狀態、OrientationLayout、篩選 sheet 日期選單；LaunchSmoke、OrdersLayoutScope、OrdersNavigationSmoke、RootNavigationContinuity 全數通過。仍失敗：K2 單次尾端點擊在 iPadOS 27 沒有把游標移到尾端 (實付金額得 42000)，且主檔新增、改名、新增失敗由通過變失敗，主對話判為第 8 輪退步；開團新增兩條為鍵盤打字後才升起、sheet 上移時點擊落在舊座標，兩次取樣的穩定判斷不足；篩選 sheet 兩條為 iPad sheet 半高、下方類別群組捲不出來。使用者確認 iPad 未接實體鍵盤、未開通用控制、手動點欄位鍵盤正常。
- 第 9 輪 codex-impl (使用者告知額度恢復) 修 AdaptiveSplitPrototypeTests：分類先驗詳情根與工具列，清單列與清單根皆不在時判收合；替換測試在收合時走原生 Back 再選；根側邊欄診斷以 rootLayout 宣告 regular 範圍。待實機確認。
- 第 10 輪派工：claude-impl 將 clearAndType 退回中央聚焦再點尾端 (數字 Popover 先點兩下換完整鍵盤)、輸入前等鍵盤就位與輸入後等欄位穩定、tapAfterWaiting 改為連續三次取樣穩定；gemini-impl 修 iPad 篩選 sheet 半高時先展開或改捲 sheet 內容器。
- 第 10 輪後 iPad Air 5 重跑 17 類：87 案例 83 通過／2 失敗／2 略過；開團新增、主檔新增與改名、新增訂單金額、篩選 sheet 兩條、數字鍵盤、英文溢出與 1.4／1.5 核心門檻全數通過，略過為原型的收合專屬案例。iPhone 12 同批因 runner「Timed out while enabling automation mode」未執行 (裝置自動鎖定)。第 11 輪 codex-impl 改原型根側邊欄診斷以視窗 horizontalSizeClass 宣告範圍 (原型根畫面是舊分頁、無 root.tab.*)、主檔刪除失敗後等待該列再斷言；iPad 重跑兩類 14 案例 11 通過／1 失敗／2 略過，原型診斷通過。
- iPadOS 27 產品缺陷 (主對話以錄影確認)：主檔刪除寫入失敗、關閉提示後，清單標題仍為「目前已建立 4 項」但只剩 3 列，「生活雜貨」從畫面消失；推測為 `LookupItemList` 的 `swipeActions` 刪除鈕使用 `Button(role: .destructive)`，系統先以刪除動畫移除列，資料未變時 iPadOS 27 不再顯示該列。iPhone 12 (iOS 26.7.2) 同測試通過。使用者決定另開 change 修正；本 change 不改產品端，1.4 的 iPad 驗收將 `LookupManagementTests.testRequestDeletion_刪除寫入失敗_顯示提示並保留項目` 記為已知 iPadOS 27 產品缺陷，不以測試調整掩蓋。
- runner「Timed out while enabling automation mode」原因更正 (主對話)：不是裝置自動鎖定 (使用者確認 iPhone 12 始終解鎖、自動鎖定為永不)。`automationmodetool` 回報這台 Mac「requires user authentication to enable Automation Mode」，且 iPhone 12 第 12 輪重跑啟動 runner 的同一刻起有一個 `automationmode-writer` 卡住 42 分鐘，等待 Mac 端驗證無人回應，runner 60 秒後逾時；之後 iPad Air 5 同樣逾時。使用者選擇關掉 Mac 的驗證要求，但從提示列執行的 sudo 未生效，使用者決定 (2026-10-29) 先跳過 UI 測試。
- 第 12 輪交叉審查與風格閘門 (審查前後 hash 與 git status 不變)：claude-impl 審 gemini／codex 六檔 P1 兩項 (篩選 sheet 展開在 iPhone 也會拖曳、原型替換測試未驗詳情內容)；codex-impl 審 claude-impl 六檔 P1 一項 (數字鍵盤案例未讀回欄位值，主對話降為 P2) 與 P2 三項；風格閘門兩組 (Support／Screens 七檔 35 項、測試四檔與規則文件 18 項)。主對話合併裁定 13 項功能修正與風格收下範圍；不收者包含英文直向溢出時 `rootLayout` 為 nil (呼叫端皆中文、會明確失敗)、以顯示寬度計的行寬誤報、短 helper 內聯 (使用者先前裁定另開一輪)。
- 第 12 輪修正 (三組檔案不重疊，改動範圍與派工一致)：claude-impl 改 TextInput、Waiting、AppNavigator、RootNavigationScreen、KeyboardDismissTests、ios-ui-tests.md (穩定路徑額外等待合計 1.0 秒、鍵盤未就位附件保留、數字案例斷言實付欄位為 `123`、規則文件刪程式常數並拆主次 bullet)；gemini-impl 改 OrderFilterSheetScreen、MenuInteraction、OrientationLayoutTests (目標已可點或 sheet 已全高就不展開、展開失敗附診斷、第二次下滑前確認仍存在、改用 `snapshotFrame`、刪無呼叫端的 `openContextMenu`)；codex-impl 改原型兩檔與 LookupManagementTests (替換後以收款摘要字面值 `NT$0` 驗詳情內容、Back 查找統一、診斷只用附件、整檔成對 When／Then)。建置兩次失敗後修正：codex 解包改寫造成同名 `let` 重複宣告；主對話裁定 V11 有誤，`RootPresentationMode` 為巢狀 private 型別，方法須顯式 `private`，已撤回。第三次建置成功，UI 回歸因上述 Mac 驗證逾時未執行。產品碼與單元測試自最終單元回歸後未變動，守門測試不讀 UI 測試檔，模擬器守門與 snapshot、iPhone 12 邏輯類單元測試結果仍適用。1.4／1.5 列明須以兩台實機執行 UI 驗證，維持未勾選。
- 使用者決定 (2026-10-29)：1.4／1.5 維持未勾選，先開始 2.1 (只改 reducer 與單元測試，不依賴 UI 測試執行)；Mac 自動化驗證處理好後，再以最終程式碼在兩台實機補跑完整 UI 回歸並勾選 1.4／1.5，補跑若失敗須回頭修正並重新評估 2.1。

## 任務2.1：明確選取與篩選失效規則

- 分工：codex-impl 實作 production 與 `OrdersFeatureDetailTests`；gemini-impl 唯讀審查兩輪 (審查前後 hash 與 git status 不變)；claude-impl 修其餘 25 個測試檔的風格與補斷言 (主對話代選，讓 gemini-impl 維持獨立審查者)；haiku-max-implementer 風格閘門三組與複查一組。裁定全部由主對話做出。
- 盤點 (codex-impl)：production 5 檔屬本批語意 (`OrdersFilterOperations`、`OrderListFeature`、`OrdersFeature`、`OrdersDetailNavigationFeature`、`OrdersContainerPlan+Writes`)，3 檔屬 2.2 型別遷移 (`OrdersRegularDetailColumn`、`OrderListInteraction`、`OrderListDestinationOperations`)；snapshot 與 UI 測試皆明確點選訂單，不依賴首筆預設選取，未改、未重錄。`OrdersFeatureStatusFailuresTests` 初被歸為 2.2，完整回歸發現其三條仍斷言載入首選，主對話更正為本批語意更新。
- TDD 紀錄 (iPhone 12 iOS 26.7.2 實機)：
    - 先寫測試：25 類 146 案例 51 條以行為失敗 (例如期待未選取實得首筆 `"O1"`)，無編譯或環境失敗。兩次測試編譯錯誤 (`makeOrder` 多傳 `date:`、`@Test(arguments:)` 讀 MainActor 屬性) 修正後才計 RED。
    - 第一次 GREEN 剩 10 條：9 條為測試寫錯 (選取未變仍期待 `selectionChanged`、對未變狀態寫 closure)，主對話裁定改測試；1 條為 production 缺陷：`filteredOrders` 在日期脈絡未記錄時回傳空陣列，刷新依篩選結果判斷而清掉仍有效的選取，主對話裁定刷新改依「是否仍在載入資料」判斷。
    - path 邊界 (codex-impl 提出、gemini-impl 審查補強)：跨功能導覽或清單篩選排除 compact 推入的詳情時，path 未清空。先寫測試，跨功能兩例 與清單篩選三例 皆以行為失敗後才改 production。清單篩選的改法第一版掛在所有清單 action (主對話退回：會關掉明確開啟但不符篩選的詳情)，第二版在父層攔截子層 `.view` action (守門 `ActionGroupingScanTests` 擋下)，最終改為 `OrdersFeature.body` 以 `.onChange(of: \.list.filterConditions)` 只在篩選條件值改變時檢查 path。
- 最終結果：iPhone 12 邏輯類單元測試 1681 條通過 (含參數化 2497 次執行，另 3 條既有已知問題如預期)；iPhone 17 iOS 26.5 模擬器守門 14 類與 snapshot 17 類 154 條 (333 次執行) 通過，snapshot 無差異、未重錄。
- 主對話裁定不收：日期脈絡未記錄時的 path 檢查防禦 (所有呼叫點都在記錄後)、`OrdersContainerPlan+*` 跨檔 extension 重整與 `ios-navigation.md` 既有長 bullet (不屬本任務)、只被呼叫一次的短 helper 內聯 (使用者先前裁定另開一輪)。測試檔移除未用 import 的裁定撤回：`MemberImportVisibility` 下 SwiftUI 與 ComposableArchitecture 為字串字面值初始化與 case path 所需。
- 文件同步：`.claude/rules/ios-navigation.md` 客戶／類別深連結一句改為保留仍命中的目前選取、失配清除不改選；`apps/ios/CLAUDE.md`、`apps/ios/README.md` 與其他 rules 經 codex-impl 與 gemini-impl 搜尋確認無首筆預設選取的描述。
- UI 驗證：2.1 的驗收列為 reducer 與 Root 整合單元測試；UI 回歸因 Mac 端 Automation Mode 驗證逾時，依使用者 2026-10-29 決定暫緩，與 1.4／1.5 一併補跑。

## 任務2.2：訂單目前目的地收斂為單一 path

- 使用者決定 (2026-10-29，design「明確選取與篩選失效規則」同步記錄)：新增訂單存檔、合併完成後都不自動開啟任何詳情；合併讓目前詳情的訂單消失時清除該詳情。原 iPad 舊右欄自動顯示新訂單與合併結果的行為取消 (1.3 起實際執行的訂單畫面本來就停在清單)。
- 分工：codex-impl 實作 production、規則文件與 Orders 容器層測試；claude-impl 平行遷移清單層、Root 與開團整合測試 (主對話代選，讓 gemini-impl 維持獨立審查者)；gemini-impl 唯讀審查 (審查前後 git status 與檔案雜湊不變)；haiku-max-implementer 風格閘門三組。裁定全部由主對話做出。
- 結果：`OrdersDetailNavigationFeature.State.regularDetail`、`syncRegularDetail`、`OrderListFeature.State.selectedOrderID`、`orderSelected`、`selectionChanged`、`OrdersWriteOutcome.selection` 全數移除；清單點擊經容器 `detail.showDetail(orderID:)` 寫入唯一 `path`，舊寬版詳情欄 (`OrdersRegularDetailColumn`) 改 scope 同一個 path 元素，舊寬版清單列改送 `orderTapped`；篩選條件改變只由 `OrdersFeature.body` 的 `.onChange(of: \.list.filterConditions)` 檢查 path；批次勾選集合維持獨立。`rg` 確認 `apps/ios` 內零殘留。
- TDD 紀錄 (iPhone 12 iOS 26.7.2 實機)：
    - 先寫測試：3 類 29 條中 8 條以行為失敗 (存檔與合併仍產生選取、多收 `selectionChanged`)，無編譯或環境失敗。批次勾選不改目前詳情的回歸測試先通過，主對話以變異 (`.list` 分支清空 path) 確認該測試失敗後還原。
    - 最小 GREEN：只改 `OrdersContainerPlan.writeResult` 不產生存檔與合併的選取，並更新與新決定衝突的既有測試；19 類 108 條通過。
    - 型別收斂與測試遷移後、審查修正後、複查修正後共跑三次完整回歸，最終 iPhone 12 邏輯類單元測試 1682 條通過，iPhone 17 iOS 26.5 模擬器守門 14 類與 snapshot 17 類 154 條通過，snapshot 無差異、未重錄。清單層選取保留／清空測試改由容器層 path 測試承接，搜尋、狀態、日期、類別選擇器、篩選面板、付款、清除篩選皆有命中保留與排除清空 (清除篩選為命中保留與無詳情不自動開啟)。
- 審查：gemini-impl 無 P1／P2，P3 建議補命中保留對稱測試已收；風格閘門收下 production 9 項、測試 A 組 17 處斷行與前置改直接設定等、測試 B 組 6 項。主對話自審另還原 codex-impl 以顯示寬度拆行或改寫的 50 處註解。修正後 haiku-max-implementer 複查：收下 23 條中 20 條完整修好，其餘 3 處 (Note 前空行、閉括號前空行、doc 的 `path` 反引號) 由主對話直接修正並連同同檔既有同類寫法對齊，再跑完整回歸。不收項目與理由見 review-t22-merged.md。
- 文件同步：`.claude/rules/ios-navigation.md` 訂單詳情條目改為單一 path、只有清單點擊開詳情、跨功能導覽只套篩選並檢查 path、篩選檢查由 `.onChange` 觸發、存檔與合併不開詳情；`apps/ios/CLAUDE.md`、`apps/ios/README.md` 與其他 rules 經 rg 確認無被刪成員名稱。
- UI 驗證：task 要求的 standalone 舊入口選取／返回 smoke 屬 UI 測試，因 Mac 端 Automation Mode 驗證未解除而暫緩，與 1.4／1.5 一併補跑；本次舊寬版欄位不在執行路徑 (1.3 起訂單由 `OrdersLegacyNavigationView` 以收合堆疊承接)，2.3 才改成功能 split。

## 使用者決定：UI 測試延到最終回歸 (2026-10-29)

- 使用者決定：本 change 其餘任務的 UI 測試 (含 1.4／1.5 的 UI 驗收與 2.x 的 targeted UI) 一律留到最後完整回歸時一次驗證；各任務照常新增或更新 UI 測試碼並建置，邏輯類單元測試、守門與 snapshot 照常逐批實跑。未實跑的 UI 驗收在各任務紀錄標明，最終回歸失敗時回到所屬任務修正。

## 任務2.3／2.4／2.5：訂單、開團、更多遷移為功能 split

- 分工：codex-impl 實作 2.3 (訂單)；gemini-impl 實作 2.4 (開團) 第一、二步，第三步起連兩次 API 錯誤 (`INVALID_ARGUMENT` 400)，改由 claude-impl 接手 (主對話代選)；claude-impl 實作 2.5 (更多)、閱讀寬度捲動修飾、共用卡片列元件。交叉審查兩輪 (claude-impl 審訂單、codex-impl 審開團／更多／共用元件，審查前後 git status 與檔案雜湊不變)；haiku-max-implementer 風格閘門五組加一次複查。裁定由主對話做出。
- 結果：
    - `OrdersView`、`CampaignView`、`MoreView` 各自持有 `NavigationSplitView`，清單欄每個選取項目都是 `List(selection:)` 的直接列 (`NavigationLink(value:)`)，getter 由功能的 `path` 投影、setter 送 `detailSelectionChanged(_:)`／`entrySelected(_:)`；`OrdersLegacyNavigationView`、`orderTapped`、`campaignTapped`、`OrderRequest.showDetail` 與開團 `showDetail` 請求鏈移除。
    - 開團：`showDetail` 同 ID 保留元素、`clearDetail`、載入完成 (`onChange(of: \.load.hasLoaded)`) 只移除失效詳情；更多：`Entry.lookup(LookupKind)`、`open(_:)` 同工具不動 path、不同工具替換，詳情欄 `NavigationStack` 以 `.id(pathID)` 換工具重建。
    - 訂單清單欄依自身環境選呈現：水平 compact 用窄版清單，水平 regular 用寬版清單欄，垂直 compact 時寬版改精簡篩選 (主對話依 spec「Layout-distinguishing…」與 design「垂直尺寸分類只處理高度需求」裁定)。
    - 卡片外觀改由共用 `BLCardRowBackground`／`BLCardRowPosition` 逐列給背景，同組多筆共用一張卡片的外觀保留。
    - 閱讀寬度：新增 `blReadableScrollContent(_:)` (量測容器 `size.width` 後以 `contentMargins` 限寬)，套在開團詳情 `List`、開團／訂單編輯 `Form`；訂單詳情沿用既有明確寬度約束，上限改為共用候選值。主對話原裁定「量測扣水平安全區」經 rendered 實測 (內容寬 660、minX 192) 證明會扣兩次，已撤回。
- TDD 紀錄 (iPhone 12 iOS 26.7.2 實機、iPhone 17 iOS 26.5 模擬器)：
    - 先寫測試：訂單 2、開團 6、更多 7 共 15 條以行為失敗；閱讀寬度純函式 1 條 RED 後轉綠。
    - 變異檢查：開團載入完成清除失效詳情、切分頁保留開團詳情與未收款篩選、訂單同 ID 保留、寬版清單只取一次快照的守門、捲動修飾扣安全區與不限寬、`.form`／`.text` 上限配對、不存在訂單不改 path，變異後各自轉紅、還原後通過。
    - 最終完整回歸：iPhone 12 邏輯類單元測試 1705 條通過；模擬器守門與 snapshot 156 條通過。
- Snapshot：
    - 第二步 12 張差異經主對話裁定為版面退步，修回後剩繪製層級殘差 (列改直接列後陰影與分隔線的光柵化差 1–7/255、列高 1px)。使用者決定 (2026-10-30)：接受並重錄 10 張 (含新增的訂單與開團同組多筆 2 張) 與寬版清單欄 3 張。
    - 同組多筆 2 張的參考圖先由主對話在 HEAD worktree 錄製，確認新版外觀與改版前一致後才依使用者決定重錄。
    - 使用者決定：大尺寸 iPhone 橫向 snapshot 改拍正式 `OrdersView` (2026-10-29)，新圖收為基準並改名 (2026-10-30) `ordersView_大尺寸iPhone橫向_分欄顯示清單與整合篩選鈕`。
- 文件同步：`.claude/rules/ios-navigation.md` (split 欄位規則與直接列、訂單／開團／更多導覽條目、alert 掛載)、`ios-design-system.md` (遷移中清單、閱讀寬度選用與訂單詳情例外、卡片列元件)、`ios-unit-tests.md` (訂單 snapshot 範圍)、`ios-ui-tests.md` (More 版面判斷)、`apps/ios/README.md` (Views 樹與訂單／開團／更多段)。
- 留給最終回歸與後續任務：UI 測試只寫未跑 (使用者 2026-10-29 決定)，含 N2–N6、L2／L3 的訂單、開團、更多案例；多選時清單 selection 傳 nil 在「展開多選中縮窄」的行為列入實測項目；原型 `AdaptiveSplitPrototypeOrdersView` 與 `adaptiveSplitSelectionChanged` 由 3.1 移除；工具頁閱讀寬度屬 2.7。

## 任務2.6／2.7：總覽分析排列與工具頁閱讀寬度

- 分工：codex-impl 實作 2.6、claude-impl 實作 2.7 (主對話代選；gemini-impl 前一批連兩次 API 錯誤，本批未派)；交叉審查 claude-impl 審 2.6、codex-impl 審 2.7 (審查前後 repo 雜湊不變)；haiku-max-implementer 風格閘門一組。裁定由主對話做出。
- 結果：
    - 總覽：所有寬度為日期、本月摘要、含成本的四項 KPI (標準字級兩欄、輔助字級單欄)、進行中開團、近期訂單；移除 `DashboardSummarySection` 的 `blLayoutClass` 與直欄排列。分析：所有寬度為期間、走勢、類別、成本、有資料才出現的開團毛利、熱力圖；移除 `InsightsView` 的 `blLayoutClass`。骨架依最終順序；失敗、空狀態與 onboarding 沿用原行為。新增 `BLAccessibilityID.Insights.heatmap`。
    - 閱讀寬度：總覽 `.text`、分析 `.chart`、客戶與主檔清單 `.text`、匯率、報價、主檔編輯、付款方式編輯 (DS 共用，Orders 選擇器路徑同受影響)、設定 `.form`。
- TDD 與驗證 (iPhone 12 iOS 26.7.2 實機、iPhone 17 iOS 26.5 模擬器)：
    - 2.6 是純畫面組合，不改統計、狀態與 Action，依 brief 例外不寫 reducer RED，以 snapshot 與 UI 測試驗收。
    - 2.7 先寫 `ToolReadableWidthGuardTests` (原始碼守門)，RED 列出 7 個缺漏容器，套用後轉綠；變異：拿掉一處修飾、`.form` 改 `.text`、修飾只放 Preview，都會失敗。
    - 最終回歸：iPhone 12 單元 1709 條通過 (含新增 956×440 rendered 測試 4 條)；模擬器守門與 snapshot 158 條通過，13 張工具頁窄版 snapshot 零差異；`BuyLedgerUITests` scheme build-for-testing 成功 (先前 2.6 新 UI 測試有 4 處存取層級編譯錯誤)。
- Snapshot：使用者決定 (2026-10-30)：總覽寬版、分析寬版、分析大尺寸 iPhone 橫向、分析載入骨架 4 張收為新基準，描述舊排列的 2 條測試改名 (`dashboardView_寬版_摘要在上四項KPI兩欄`、`insightsView_寬版_卡片依固定順序垂直排列`)。分析空狀態一度因失敗／空狀態套 `blReadableContent` 多折一行，已改回原寫法。
- 956×440 閱讀寬度：總覽大尺寸 iPhone 橫向 snapshot 內容未限寬 (同畫面 956×768 會限寬、等待後再拍不變)；rendered 測試 956×440 (含垂直 compact、可捲動) 皆限寬；在 iPhone 17 Pro Max 模擬器以暫時 UI 探針實測橫向 956×440，hero 從 x=174、寬 608 (= 640 − 兩側內距) 置中，確認產品端正確，屬離屏 snapshot 限制；`.claude/rules/ios-unit-tests.md` 記為 gotcha。
- 文件同步：`ios-design-system.md` 遷移中只剩 DEBUG 原型分支注入 `blLayoutClass`；`ios-unit-tests.md` 尺寸分類分流畫面只剩 `OrdersView`、矮尺寸 snapshot 閱讀寬度 gotcha；`ios-ui-tests.md` 受控例外補 sheet 層數；`apps/ios/README.md` 總覽與分析段。
- 留給最終回歸與 4.4：UI 測試只寫未跑 (總覽／分析排列與輔助字級、工具續輸入、收鍵盤後旋轉、單層 sheet 與捨棄保護)；工具頁 L4 (非對稱安全區、長中英文、最大輔助字級) 與 FX／Quote 的 `lineLimit`／`minimumScaleFactor` 截斷策略 (D4) 在 4.4 以量測決定。

## 任務3.1：清理舊根、版面分類與 Adaptive Split 原型

- 分工：codex-impl 實作 (計畫 plan-t31-codex.md，主對話裁定 plan-t3132-rulings.md)、claude-impl 唯讀交叉審查 (審查前後 repo 雜湊不變)、haiku-max-implementer 風格閘門兩組 (production 5 檔、測試 5 檔)；文件由主對話改。審查與閘門的取捨由主對話裁定。
- 刪除：`RootTabLayout`、`RootSidebarLayout`、`BLLayoutClass` 與其兩個測試檔、`BLLocalEnvironmentAdaptationTests` (兩案只量測已刪的根覆寫注入，幾何與 `BLReadableContentLayoutTests` 重複)、Adaptive Split 原型 (`AdaptiveSplitPrototypeOrdersView`、`BLAccessibilityID+AdaptiveSplitPrototype`、`AdaptiveSplitPrototypeScreen`／`Tests`、`BLUITestConfiguration` 原型旗標、`RootView` 原型分支、`OrdersFeature.adaptiveSplitSelectionChanged`)、`RootFeature.sidebarTabSelected`、零呼叫的 `Common.navigationList`／`detailSelectionPrompt`。保留 `detailEmptyState`、`selectedItem(_:)` 與兩個 catalog key (MoreView、CampaignView、Orders 與 UI 測試仍呼叫)。
- 守門：`LayerBoundaryTests` 白名單精確為 `RootView`、`RootNavigationLayout`；反向驗證暫加第三個 `StoreOf<RootFeature>` 持有者時守門失敗、刪除後通過。`ActionGroupingScanner` 以 `RootNavigationLayout` 取代兩個舊根路徑 (維持根宿主的送出點掃描)；`ProjectionWriteBoundaryGuardsTests` 合成案例改指現存根宿主，一正一反預期不變。`BLLocalEnvironmentAdaptationTests` 刪除後，「局部環境不被根覆寫」改由根覆寫機制不存在本身成立，並由 `ToolReadableWidthGuardTests` 的尺寸分類禁止詞與 `DesignSystemSourceScanTests` 詞法案例守住不回流。
- 殘留檢查：`rg` 舊宿主、分類、原型、sidebar action、兩個 Common ID、「遷移中」、`SidebarSelection`，在 App、測試、UI 測試、`apps/ios/CLAUDE.md`、README 與 `.claude/rules/` 只剩兩處刻意詞法 fixture (`ToolReadableWidthGuardTests` 禁止詞、`DesignSystemSourceScanTests` scanner 輸入)。風格閘門另找到 `OrdersFeature` 的 `view` case 文件殘留「原型選取」，已刪。
- 審查修正：`apps/ios/CLAUDE.md` 與 `LayerBoundaryTests` 註解寫明守門範圍是 `Features/` (App 進入點 `BuyLedgerApp` 也持有根 store)；`RootFeatureSidebarTests` 改名 `RootFeatureTabSelectionTests`，拆成「設定頁非空時切到訂單」「主檔頁非空時切到訂單」「選取目前分頁」三條，每條一組 When／Then、id 以字面值 0 斷言；`ActionGroupingScanner` 內聯單處使用的 `iosRoot` 與三個 regex 屬性並移除未用的 `import Testing`；`BLAccessibilityID.Common.Feature` 移到方法之前；`RootFeature`／`OrdersFeature` 的 body 與投影屬性文件改為名詞片語。不收：`BLUITestConfiguration.warn` 的位置符合 formatting.md「Private Method 依第一次被呼叫順序」；`RootFeature.State.init` 的參數預設值 (W-05) 超出 3.1，改動會波及所有 Root 測試；`Common.Feature` 名稱是完整名稱不是角色後綴，保留。
- 驗證 (iPhone 12 iOS 26.7.2 實機、iPhone 17 iOS 26.5 模擬器)：首輪 `RootFeatureSidebarTests` 缺 `import Foundation` (`Decimal` 整數字面值在 MemberImportVisibility 下不可用) 編譯失敗，補 import 後全綠；審查修正後最終回歸 iPhone 12 單元 1694 條通過、模擬器守門與 snapshot 158 條通過、零 snapshot 差異、`BuyLedgerUITests` scheme build-for-testing 成功。
- 文件同步：`apps/ios/CLAUDE.md` 根 store 條目；`ios-navigation.md` 根導覽、分欄、選取與切分頁保留堆疊的現況；`ios-design-system.md` 版面判定改為各功能依可用區域、規則十一只剩詞法測試；`apps/ios/README.md` 目錄結構、根導覽表與各功能版面描述；全部文件無「遷移中」字樣。主規格 Purpose 依 design 留到 archive 更新。
- 留給 4.2：iPad N5 狀態保留 (More→Settings→Orders→More、More→Customers→Orders→More) 依使用者決定 (2026-10-29) 在最終回歸實跑，本批不以原型或單元測試代替。

## 任務3.2：跨功能導覽連續性 UI 測試與 helper 整併

- 分工：claude-impl 實作 (計畫 plan-t32-claude.md，主對話裁定 plan-t3132-rulings.md)；codex-impl 唯讀審查三輪 (第 1 輪 3 項 P2、2 項 P3；第 2 輪 1 項 P3；第 3 輪 Approve)；haiku-max-implementer 風格閘門三輪、每輪主檔與支援檔各一組；修正共五輪，第 5 輪後由主對話機械核對收斂 (行寬、全形標點、註解句號、`fileprivate`、GWT 首行與同縮排，39 個測試方法全數掃到)。每輪審查前後 repo 雜湊不變。取捨由主對話裁定。
- 新增：`Tests/Navigation/AdaptiveNavigationContinuityUITests.swift` 16 案 (N1–N6 可自動化部分、L1–L4)；純值檢查 `CheckOutcome`、`IdentifierCheck`、`KPIPresenceCheck`、`BoundsCheck`、`PathCheck` (一型別一檔，`Support/Assertions/`)，`requireCheckPassed` 併入 `Assertions.swift`；反例 `AdaptiveLayoutCheckCounterexampleTests` 5 案 (錯 ID、成本缺失、越界或進入保留區、More 路徑丟失會失敗，正常結果通過)。四種檢查都有活體案例使用：訂單選取與未選取比對走 `IdentifierCheck`，「更多」目的地 (`Common.selectedItem(.more)` 的值) 走 `PathCheck`，總覽 KPI 走 `KPIPresenceCheck`，膠囊、新增鈕與分欄框線走 `BoundsCheck`。
- 搬移與刪除 (覆蓋不減少)：`RootNavigationContinuitySmokeTests` 3 案、`OrdersLayoutScopeSmokeTests` 2 案、`CampaignFlowTests` 未收款篩選跨分頁 1 案、`MoreNavigationSmokeTests` 首次未選取 1 案搬入新檔 (原兩檔刪除)；`OrdersNavigationSmokeTests` 初始無選取段由新 N3 承接；開團共用 helper 與種子固定值移到 `Support/Flows/`；`OrdersLayoutAssertions` 移到 `Support/Layout/`；`TextInput` 新增 `appendText` (與 `clearAndType` 共用聚焦與移游標步驟)，`CampaignEditScreen.appendName` 改用它。
- 審查修正重點：N2 旋轉後明確要求 Orders 收合與並排，並核對詳情實際顯示的訂單編號 (改選後不得殘留舊編號，先等新編號出現)；N3「更多」依功能自身版面分支，收合分支以入口列寬度大於視窗 60% 排除「並排但缺提示」誤判；N3 訂單兩種版面都續跑旋轉段；L1 拒絕空白 KPI 值；L2 狀態列存在卻取不到框線即失敗；`assertOrdersSplitGeometry` 不在收合時靜默通過；skip 只用版面條件。
- 主對話裁定：主檔維持單一檔案 (tasks.md 指名)；N2 在直向仍並排的裝置以版面條件 skip (並排與收合的轉換留 Duo)，因此 iPad Air 5 的 4.2 結果可能是 skipped；矩陣編號只留在 `- Note:`，N5A／N5B 沿用 tasks.md 寫法；字級一致性案例以兩種字級互相比對；TextInput 鍵盤未就位的診斷附件保留；失敗開團以文字查列 (需 App 端 identifier) 不在本 change 處理；其他未改動測試檔的開團私有常數不動。
- 反例測試框架：原裁定改 Swift Testing，build 失敗 `Unable to resolve module dependency: '_Testing_Unavailable'`，UI test target 不能 import Testing，改回 XCTest 並記入 `ios-ui-tests.md`；開啟需改 target 設定，屬使用者決定。
- 驗證 (iPhone 17 iOS 26.5 模擬器)：`BuyLedgerUITests` scheme build-for-testing 成功、3.2 改動檔無新警告；守門與 snapshot 158 條通過。App 與單元測試原始碼自 3.1 最終回歸後雜湊不變，沿用 3.1 的 iPhone 12 單元 1694 條結果。
- 文件同步：`.claude/rules/ios-ui-tests.md` 補 UI target 不能 import Testing、續打用 `appendText`、視窗與系統列框線屬受控例外；`apps/ios/README.md` UI 測試目錄補 `Support/Flows` 與 `Tests/Navigation`。
- 待使用者決定：ios-dev-kit 規定 `Support/` 平放，專案 UI 測試的 `Support/` 早已分 `Assertions`／`Interactions`／`Launch`／`Layout` 子資料夾，3.2 新增的 `Support/Flows/` 延續此結構；是否記為 kit 差異或整體平放另議。
- 留給 4.2：全部新 UI 案例與反例只寫未跑 (使用者 2026-10-29 決定)；需確認 N1 徽章讀法、N3 入口列寬度門檻、N2 轉場時新舊詳情標籤是否短暫重疊、反例執行數大於 0。

## 任務4.6：主檔與開團確認刪除後的寫入失敗通知不遺失

- 使用者決定 (2026-10-31)：4.2 第 3 次回歸發現的主檔刪除失敗提示遺失併入本 change；開團經主對話實測重現後依「先實測，有重現才併入」納入；訂單無寫入失敗注入旗標，記為未驗證風險不修改；先試方案 B (destination 另一個 case)，不行再維持方案 A。
- 成因 (主對話以 `[BLDIAG-4.6]` 暫時診斷在 iPadOS 27.0 iPad Air 11 (M4) 模擬器確認)：確認框與失敗通知共用同一個 `destination` 與 `.alert`。成功時確認框關閉後 SwiftUI 回寫 nil 兩次，失敗回應在第二次之後才到；遺失時失敗回應落在兩次之間，SwiftUI 不呈現也不再回寫，`destination` 卡在提示狀態，之後的確認框也不呈現。開團以 `-BLUITestCampaignWriteFailure` 第 2 次即重現同一現象。
- 方案比較 (主對話)：A 獨立 `@Presents notice` 與另一個 `.alert`，實驗 20 次全數呈現 (其中 18 次落在原本會遺失的時間窗)；B destination 的 `failureAlert` case 配獨立 `.alert`，9 次 0 次呈現 (TCA case 綁定 setter 寫 nil 時不分 case，確認框晚到的 nil 把通知一起關掉)。採 A，並寫入 `.claude/rules/ios-navigation.md` 作為單一 destination 的例外 (使用者同意先試 B、不行再維持 A)。
- 分工：主檔管理 claude-impl 實作、codex-impl 交叉唯讀審查；開團 codex-impl 實作、claude-impl 交叉唯讀審查；主對話診斷、實驗、補兩個 Root 單元測試斷言與 `var`→`let`、一行 import、規則文件第 63 行改寫；haiku-max-implementer 風格閘門兩組 (主檔 V11／W6／E3、開團 V11／W3／E6)。主對話裁定：V 全部採納 (單行與斷行、摘要動詞開頭、MARK、When 只留一個 send)；W 維持現狀，只有 W-01 交使用者；E 只採納整檔對齊與單行寫法，import 以建置為準不動，既有測試品質議題 E-4 至 E-6 不在 4.6 範圍。W-01：同畫面第二個 `@Presents notice` 與 kit「一個畫面只有一個 destination」衝突，使用者 2026-10-31 裁定先試 `Destination` case 配獨立 `.alert`，iPad 模擬器 9 次失敗提示 0 次出現，不可行，維持獨立 `notice` 並寫進 `.claude/rules/ios-navigation.md`。
- 改動：主檔管理新增 `notice`／`pendingNotice`，新增、刪除、改名、付款方式更正四種寫入失敗改走通知 (`AlertState.lookupWriteFailure(_:)`)；開團 `noticeRequested` 改走 `notice`，通知 factory 移到 `AlertState` 受限 extension，`CampaignPresentationQueue` 暫存到通知狀態；交叉審查必修 M-01：通知抵達時 `destination` 非 nil 或表單關閉中先暫存，`destination` 清空後沖出，兩者不同時呈現。
- 驗證：
  - 單元測試 (iPhone 12，Lookups／Campaigns 全部類別與兩個 Root 類別)：385 通過／0 失敗 (M-01 後最終版)。
  - 模擬器 ui-automation (方案 A 修正版)：主檔滑動 5、長按選單 5、開團 6 次全數出現「操作失敗」且關閉後可再開確認框。M-01 後最終版：主檔滑動 5、長按選單 5、開團 5 次全數出現且可再開確認框。
  - 模擬器 UI 測試 (A 版)：iPad Air 11 (M4) iPadOS 27.0 `LookupManagementTests`／`CampaignFlowTests`／`CampaignCrudTests` 24 通過／2 略過；iPhone 17 iOS 26.5 25 通過／1 略過。M-01 後最終版 iPad 模擬器同三類 24 通過／0 失敗／2 略過。
  - 實機 (2026-10-31)：iPhone 12 iOS 26.7.2 `LookupManagementTests`／`CampaignFlowTests`／`CampaignCrudTests` 25 通過／0 失敗／1 略過；iPad Air 5 iPadOS 27.2 同三類 24 通過／0 失敗／2 略過；iPad 兩個主檔寫入失敗案例 (`testRequestDeletion_刪除寫入失敗_顯示提示並保留項目`、`testRequestDeletion_長按選單刪除寫入失敗_項目保留且筆數不變`) `-test-iterations 5` 各 5 次全過。同日第一輪兩台在 runner 啟動 60 秒內皆 `Timed out while enabling automation mode`，Mac 端 `automationmodetool` 為不需驗證；使用者重開兩台並在旁看著裝置後第二輪正常執行。
- 未驗證風險與記錄：訂單確認刪除接寫入失敗通知機制相同但無注入旗標；開團通知顯示中又到新通知會覆寫 (既有規格)；主檔表單開啟中暫存通知後取消表單會在 sheet 關閉動畫中沖出 (寫入失敗只在表單送出後到達，實際碰不到)；開團 `isDeleteConfirmationPresented` 只判斷有無 alert (測試順序避免假綠)。
- 文件同步：`.claude/rules/ios-navigation.md`「呈現」節改寫第 63 行並新增例外子項；`apps/ios/CLAUDE.md` 第 108 行 (開團一次性通知仍送 `noticeRequested`) 與 `ios-navigation.md` 訂單相關描述 (訂單未改動) 經 grep 確認仍成立；README 無相關描述。

## 任務4.7：regular 訂單搜尋排除目前訂單時詳情欄清空

- 使用者決定 (2026-10-31)：4.2 第 3 次實機回歸發現的 iPad regular 搜尋無結果時詳情未清空，併入本 change。
- 重現：iPadOS 27.0 iPad Air 11 (M4) 模擬器重複 20 次未重現；iPad Air 5 實機加入 `BLDIAG-4.7` 暫時診斷後第 2 次重現。
- 成因 (主對話以第二、三版診斷確認)：清除確有執行，清單選取沒有回寫。第一個字 `Z` 觸發的 `.onChange(of: \.list.filterConditions)` 執行中，`OrdersView` 與 `OrdersRegularDetailColumn` 的 `body` 被同步重算並讀到舊 `path` (軌跡第 9 至 12 筆)，reducer 隨後才清空，之後兩個畫面再也沒有重算。TCA 1.26.2 的 `RootCore._send` 在狀態副本上執行 reducer、結束才寫回；巢狀 `@ObservableState` 變更的通知在執行中送出，寫回時根狀態 `_$id` 不變，`Store.subscribeToDidSet` 不再通知 (原始碼已核對)。第二版診斷在 `body` 內寫入被觀察的軌跡物件造成無限重繪 (主執行緒忙碌 30 秒)，第三版改為暫存後非同步發布，不影響觀察。
- 修法 (主對話決定，codex-impl 實作)：`OrdersFeature.State.isDetailExcludedByFilter` 共用排除判斷；篩選條件改變且目前詳情被排除時，`.onChange` 回傳 `.run` 送新的內部 action `filterConditionsChanged`，下一個 action 才 `reconcileDetailPathWithFilteredOrders()`。詳情仍命中或沒有詳情時不送 action；Root 的 `applyFilterNavigation` 維持同步清空。被排除的訂單在詳情欄多留一個 run loop。
- 單元測試：經 `.onChange` 清空的 9 個測試改為 `receive(\.filterConditionsChanged)` 後才清空；新增 `list_搜尋排除推入詳情_下一個action清空path` (send 後 `path` 仍在、receive 才清空)；Root 跨功能導覽與刪除、合併、載入、原生返回的同步清空測試維持原樣。
- 審查：claude-impl 交叉唯讀審查 (必修 M1 index 仍為診斷版，屬使用者 stage 狀態，主對話不動 index，已告知使用者；M2 規則文件同步已補；M3 移除診斷後驗收已補跑；建議 S1 重複測試已刪、S2 併入閘門 V-07；S3 刪除目前詳情改為清空屬 2.1 已定行為；S4 日期脈絡刷新不檢查 `path` 記為未處理風險)。haiku-max-implementer 風格閘門 V 9／W 8／E 3：V-01 至 V-09 與 W-07 由 codex-impl 修正；W-01 測試名內 `path`、W-02 語意參數名、W-08 架構用語依既有裁定保留，W-03 清單 `.task` 不等 `finish()` 依 `ios-navigation.md`，W-04 `if let` 與 `store.scope`、W-05 泛型 typealias 斷行、W-06「目的地」用詞維持 (主對話)。審查與閘門前後 repo 雜湊不變。
- 驗證 (實機)：
  - 修正後含診斷版 iPad Air 5 目標測試重複 20 次全過；修正前同診斷版第 1 至 2 次即失敗。
  - 移除診斷後：iPhone 12 `OrdersFeatureDetailTests`／`OrdersFeatureFilterPathTests`／`RootFeatureOrderFiltersTests`／`RootFeatureDetailNavigationTests` 49 通過；iPad Air 5 `OrderRegularColumnScopeTests` 全類別 12 通過；目標測試 `-test-iterations 10` 10 次全過。
  - 風格修正後：iPhone 12 同四類 48 通過 (刪除一條重複測試)；iPad Air 5 全類別 12 通過。
  - `rg BLDIAG-4.7` 與 `OrdersSelectionTrace` 在 `apps/ios` 無殘留。
- 未處理風險：`refreshDateContext` 只更新日期脈絡、不檢查 `path`，跨日、跨月或回到前景時日期篩選若排除目前詳情，詳情不會清空 (交叉審查 S4，記於 design)。
- 文件同步：`.claude/rules/ios-navigation.md` 訂單篩選段改寫為延後清空並寫明原因與 Root 同步例外；`design.md`「regular 訂單搜尋排除目前訂單時詳情欄必須清空」補成因、修法與未處理風險。

## ios-dev-kit 4.2.2 至 4.2.4 對齊 (2026-10-31)

- 來源：使用者指出 staged 內容中 View 回傳畫面內容的成員被放進 Private Method；主對話請 ios-dev-kit session 補規則，使用者裁定後發布 4.2.2 (View 的 Private Views 例外，`some Gesture` 歸 Private Method)、4.2.3 (測試 target 專用、替非自己型別加功能的 extension 獨立成檔)、4.2.4 (Private Views 依 `body` 使用順序排)。
- 改動：claude-impl 把 7 個成員移回 Private Views (`CampaignDetailView.actionsToolbar(for:)`、`CampaignEditView.cancelToolbarItem`／`saveToolbarItem`、`OrderEditView.editorToolbar`、`OrdersRegularListColumn.cardRowBackground(position:)`／`dateChip(_:)`、`OrdersCompactListView.cardRowBackground(position:)`)；主對話把 `anchorContentFrame()` 搬到 `BuyLedgerTests/Support/Rendering/View+LayoutMeasurement.swift` (`// MARK: - Layout Measurement`)；claude-impl 依 4.2.4 重排本 change 改到的 27 個 View 檔中 17 檔的 Private Views (內容行多重集合不變)，`SettingsView.modelPicker` 的 `#if DEBUG` 隨成員搬移 (主對話確認)。
- 閘門：haiku-max-implementer 對 30 個 View 檔逐檔核對分區與排序，V 0／W 2；W-01 `CampaignSectionList.titleText(_:) -> Text` 依規則意圖留在 Private Views 並回報 kit 缺口，W-02 `QuoteView` 檔尾 Preview 函式不在規則範圍。測試型別的樣本 View helper 依 4.2.2 留在 Private Method。
- 驗證：simulator build-for-testing 成功、無新警告；之後的實機單元與 UI 測試涵蓋同一版本。

## 任務4.1：完整單元、守門與 snapshot 回歸 (2026-11-01，4.6／4.7 與 kit 4.2.2 至 4.2.4 對齊之後)

- 單元回歸 (iPhone 12 iOS 26.7.2 實機)：`BuyLedgerTests` 全部，略過讀 repo 原始碼的守門 22 類與 snapshot 20 類 (共 42 類，與 `Guards/`、`SnapshotTests/` 目錄宣告的類別逐一比對相同)，1682 通過、0 失敗。
- 守門與 snapshot (iPhone 17 iOS 26.5 模擬器，先 `set-appearance --mode light`)：上述 42 類 188 通過、0 失敗，沒有與基準不符的 snapshot，未重錄。
- 守門反例 (主對話)：暫時在 `Shared/DesignSystem/Foundations/BLCardRowMetrics.swift` 加入 `import ComposableArchitecture` 與引用 `LedgerOrder`、`OrdersFeature` 的 typealias，並在 `Features/More/Presentation/Root/` 新增宣告 `StoreOf<RootFeature>` 且讀 `store.preferences.language` 的暫時檔；模擬器執行 `LayerBoundaryTests`、`LanguageProjectionBoundaryTests`，預期的 5 條轉紅 (`composableArchitectureImportViolations_設計系統目錄_不匯入狀態管理套件`、`findViolations_設計系統目錄_不引用領域型別`、`findViolations_核心與共用目錄_不引用功能型別`、`filesDeclaringRootStore_功能目錄_僅由兩個根導覽宿主持有`、`languageProjection_功能目錄檢視_跨功能語言投影僅限根宿主`)，訊息皆指向暫時加入的行，其餘 4 條通過。還原後該檔 SHA-256 與 repo `git diff HEAD` 雜湊、`git status` 皆與反例前相同。
- codegen 與資料模型：`shared/data-model/generator` 執行 `bun run check` 通過；`shared/data-model`、`Core/Domain/Generated`、`Core/Persistence` 相對 HEAD 無差異。
- iOS 26 availability：deployment target 為 26.0／26.4；本 change 改到的 App 檔沒有 iOS 27 以上的 `#available`／`@available` 分支，即未使用 iOS 27 專屬 API；iOS 26.5 模擬器建置與 iOS 26.7.2 實機測試皆通過。
- scenario 對照：8 份 delta spec 共 82 條 scenario／example，已驗 40、已寫待跑 25 (4.2 實機 UI)、人工待驗 9 (4.3／4.4)、缺口 8 (依清單交給 4.2 或 4.4)；8 條缺口：`Wording naming both platforms keeps its scope` 沒有 compact 多選 UI 佐證；`Root sidebar lists destinations without status shortcuts` 沒有斷言狀態捷徑不存在；`A dismissed keyboard stays dismissed` 未驗收起後再旋轉仍收起；`The unified sheet control is disabled when the pending values are already default` 沒有驗元素真的停用；`Batch operations remain reachable when the window is dragged` 沒有拖動視窗的案例；`Selection count belongs to the current list presentation` 沒有收合導覽標題的筆數案例；`Settings supports edge swipe back` 只點返回鈕，沒有左緣滑動；`Missing navigation fails with diagnostics` 沒有刻意缺少導覽元素的反例。依各缺口分別交給 4.2 UI 與 4.4 人工。上一輪 4.1 補測：缺口 3 語言守門 `LanguageProjectionBoundaryTests` (白名單只有 `RootView`，即 claude-impl 回報建議的做法)、缺口 5 與 8 `OrdersFeatureFilterPathTests`、缺口 7 `OrderListFeatureFilterSheetTests.destination_待確認篩選只改類別_只提交類別並關閉面板()`；缺口 2 單元層無法建立有效測試，改列 4.4。
- 程式碼與風格：各任務已各自完成交叉審查與 haiku-max-implementer 風格閘門 (見各任務段)；kit 4.2.2 至 4.2.4 的 View 分區與排序已對本 change 全部 View 檔重新核對 (見上段)。kit 4.2.3「測試專用、替非自己型別加功能的 extension 檔名為 `<Type>+<Feature>.swift`」與 `BuyLedgerUITests/Support/` 既有的功能命名檔 (`Waiting.swift`、`TextInput.swift`、`Scrolling.swift` 等，整檔為 `XCUIApplication`／`XCUIElement`／`XCTestCase` 擴充) 不一致，與 3.2 已列的「`Support/` 子資料夾」同屬待使用者決定事項，未自行改名。

## 測試 `Support/` 依 ios-dev-kit 4.2.3 改名並平放 (2026-11-01)

- 使用者決定 (2026-11-01)：`BuyLedgerUITests/Support/` 依 kit 改名並平放；`BuyLedgerTests/Support/Rendering/` 兩檔一併平放 (主對話決定，同一條 kit 規則)。
- 改動 (claude-impl 實作，主對話決定對應)：取消 `Assertions`／`Interactions`／`Launch`／`Layout`／`Flows`／`Rendering` 子資料夾。自有型別一型一檔維持原名 (`AppNavigator`、`BLUITestCase`、`LaunchOptions`、`BoundsCheck`、`CheckOutcome`、`IdentifierCheck`、`KPIPresenceCheck`、`PathCheck`、`ValueParsing`、`CampaignSeedFixture`、`ViewLayoutMeasurementSupport`)；整檔為系統型別擴充的改為 `<Type>+<Feature>.swift` (例如 `XCUIElement+Waiting.swift`、`XCTestCase+PlatformScope.swift`、`XCUIApplication+Scrolling.swift`)；同時擴充兩種型別的 `Diagnostics`、`ValueParsing`、`TextInput` 拆成各自的檔。拆 `TextInput` 時，跨檔使用的 `NumericKeyboardPresentation`、`numericKeyboardPresentation`、`presentedKeyboardFrame`、`isNumericPopoverPresented`、`waitForFullKeyboard(timeout:)` 與檔案層級 `pollUntil(timeout:_:)` 由 private 改為 internal，名稱與本體不變。成員內容與註解措辭不變 (非空白行多重集合核對)。
- 文件同步：`.claude/rules/ios-ui-tests.md` 的 `Support/` 路徑與 helper 引用、`apps/ios/README.md` 的 UI 測試目錄說明。
- 驗證：`BuyLedgerUITests` 與 `BuyLedger` 兩個 scheme simulator build-for-testing 成功。UI 測試 target 有 24 個 actor isolation 警告 (`Screen.swift` 10、`XCTestCase+Assertions.swift` 7、`CampaignsScreen.swift` 6、`XCTestCase+Diagnostics.swift` 1)，皆為既有寫法：`Assertions` 的 7 個在 3.2 建置紀錄已存在，`Screen.swift` 本 change 未改；這次因搬檔重新編譯才全部列出，搬檔前後的 isolation 標註相同。成因是 `Screen` protocol 與 `XCTestCase` 擴充未標 `@MainActor`，`CampaignsScreen.isDetailEmptyStateShown` (2.4 新增) 沿用同一寫法；屬既有問題，未在本 change 處理。

## 任務4.5：主檔滑動刪除不交由系統移除列

- 使用者決定 (2026-10-30)：把 parked change `lookup-swipe-delete-row-retention` 的修正併入本 change (design「主檔滑動刪除不交由系統移除列」，Supersedes 該 change 的 design 與 tasks 1.1、1.2；該 change 保持 parked，是否刪除由使用者決定)。沿用 parked design 與任務排在 4.2 之前由主對話決定。
- 成因 (主對話重現)：4.2 第 1 次實機回歸 iPad Air 5 (iPadOS 27.2) 的 `LookupManagementTests.testDeleteItem_確認刪除商品類別_清單移除該名稱` App 閃退；在 iPadOS 27.0 iPad Air 11 (M4) 模擬器重現，執行期記錄為 `NSInternalInconsistencyException`「Invalid update: invalid number of items in section 0 ... before the update (3) ... (0 inserted, 1 deleted)」。滑動刪除鈕 `Button(role: .destructive)` 被點下時系統先移除列，確認刪除成功後資料再刪一次即閃退；寫入失敗時列不回來 是同一根因。
- 分工：claude-impl 實作兩輪 (App 一檔與 UI 測試兩檔)；codex-impl 唯讀審查 (必修 1 項：缺內容選單長按刪除失敗案例，已由第 2 輪補上)；主對話補標題筆數讀法與三個刪除案例的標題斷言、`.claude/rules/ios-design-system.md` 的滑動刪除例外；haiku-max-implementer 風格閘門 (併入 4.2 測試與 App 檔一組)。審查前後 git status 與檔案雜湊不變。
- 改動：`LookupItemList` 滑動刪除鈕改一般 `Button` 加 `.tint(.blRed)`，標籤「刪除」與 identifier `lookupManagement.deleteButton:<名稱>` 不變；內容選單刪除維持 destructive。`LookupManagementScreen` 新增列數、標題筆數讀法與 `DeletionTrigger` (滑動、內容選單)；`LookupManagementTests` 刪除成功與寫入失敗案例加列數與標題斷言，新增滑動刪除後取消、長按選單刪除寫入失敗兩案。
- 實機結果：`LookupManagementTests` 12 條在 iPhone 12 (iOS 26.7.2) 與 iPad Air 5 (iPadOS 27.2) 的 4.2 第 2 次回歸全數通過，第 3 次回歸再次全數通過。刪除成功不再閃退；長按選單刪除寫入失敗後列保留、列數與標題皆為 4，內容選單維持 destructive 不需改採替代方案。
- 朗讀標籤 (主對話，2026-10-31)：iPadOS 27.0 iPad Air 11 (M4) 模擬器以 `mobilebuildmcp ui-automation` 在商品類別列左滑，可及性快照讀到刪除鈕 label「刪除」、identifier `lookupManagement.deleteButton:生活雜貨`，重新命名鈕 label「重新命名」；畫面為紅底垃圾桶「刪除」與橘底「重新命名」。同一操作中全滑觸發刪除時列保留、確認框正常出現。
- 文件同步：`.claude/rules/ios-design-system.md` 破壞性按鈕條目補 `swipeActions` 例外；其他規則與 README 經搜尋確認無滑動刪除角色的描述。
- 4.6 之後的實機確認 (2026-10-31)：iPhone 12 `LookupManagementTests`／`CampaignFlowTests`／`CampaignCrudTests` 25 通過／1 略過，iPad Air 5 同三類 24 通過／2 略過，`testDeleteItem_確認刪除商品類別_清單移除該名稱` 皆未閃退。
- 朗讀確認方式 (使用者 2026-11-01 決定)：不實際開啟 VoiceOver，以可及性標籤為準；上一條模擬器讀到的 label「刪除」即為驗收依據。

## 任務4.2：兩台實機完整 UI 回歸

- 前置：兩台未接鍵盤、解鎖、開啟「啟用 UI 自動化」；Mac 的 Automation Mode 驗證設定由使用者自行以 sudo 改為免驗證 (`automationmodetool` 顯示 DOES NOT REQUIRE user authentication)。執行中仍出現 runner「Timed out while enabling automation mode」(iPhone 12 連續 4 次、iPad Air 5 1 次，log 顯示 runner 已在裝置啟動但 60 秒內開不起自動化模式，不是裝置上鎖)；使用者把裝置「設定 > 開發者 > 啟用 UI 自動化」關掉再打開後恢復。
- 裝置：iPhone 12 (iOS 26.7.2，UDID 3552E16B-F199-548A-95F9-76A0BEDE408F)、iPad Air 5 (iPadOS 27.2，UDID E08B5195-951A-5C86-AB67-2CFFD1ECCD9E)。
- 命令：`mobilebuildmcp device test --project-path apps/ios/BuyLedger.xcodeproj --scheme BuyLedgerUITests --configuration Debug --device-id <UDID> --extra-args "-allowProvisioningUpdates" --extra-args "-allowProvisioningDeviceRegistration" --extra-args "-only-testing:BuyLedgerUITests" --extra-args "-skip-testing:BuyLedgerUITests/LaunchPerformanceTests" --output json` (鍵盤前置改 `-only-testing:BuyLedgerUITests/KeyboardDismissTests`)，依序 iPhone 12 `KeyboardDismissTests` 兩條 → iPhone 12 完整 → iPad Air 5 完整，同一時間只跑一組。
- 第 1 次 (2026-10-30)：iPhone 12 120 通過／26 失敗／42 略過；iPad Air 5 115 通過／72 失敗／1 略過。產品問題兩項：P1 主檔刪除閃退 (轉 4.5)、P2 訂單分頁徽章覆寫訂單根容器的路徑標記 (改由詳情根 `orders.detail.root` 的 accessibility value 帶訂單編號，移除訂單根的 `selectedItem` 標記)；其餘 T1–T11 為測試端，分類如下 (主對話)：
  - P2 影響兩台共 13 條；VoiceOver 不聚焦 `.contain` 容器，使用者無感，但路徑標記失效。
  - T1 詳情空狀態容器框線跨滿視窗 (0,96,820,1084)，與清單欄重疊，版面判定回傳 nil (iPad 約 55 條)；畫面本身正確。
  - T2 iPhone 橫向詳情錨點在畫面外 (開團摘要 y=438、訂單摘要 y=459，視窗高 390)。
  - T3 iPhone 橫向分頁列按鈕有時沒有 `root.tab.*` identifier，`rootLayout` 回傳 nil。
  - T4 `numericKeyboardPresentation` 把 iPhone 橫向數字鍵盤誤判成浮動面板 (實測 `Keyboard` 全寬、高 64)。
  - T5 總覽與分析逐一捲動後才讀框線，上下順序比對失效；總覽前景就緒只認營收 KPI，最大字級時 KPI 在畫面外。
  - T6 匯率金額欄預設 150000、報價本金預設 0，測試未清空就續打。
  - T7 `app.sheets` 只對應動作表，SwiftUI sheet 計數恆為 0 (主檔管理兩條)。
  - T8 `more.root` 是全頁 CollectionView，iPhone 上等不到 hittable，應等入口列。
  - T9 開團「返回後再進入」在 iPad 並排版面沒有原生返回鍵，需以版面條件略過。
  - T10 iPhone 狀態膠囊點選後部分在捲動列外 (x 324–396.67，視窗寬 390)，邊界檢查以完整框線比對視窗而失敗。
  - T11 橫向首頁讀營收 KPI 時捲動越過目標；分析頁成本圓餅圖未捲入畫面即判定 hittable 而拋錯。
  - 待重跑確認：iPad `OrderEditAddOptionTests.testAddOrderSource` 的 alert 點「新增」後仍在；iPad `KeyboardDismissTests.testTapNumericKeyboardDone` 的 `1230` 由使用者裁定為已知問題。
- 修正第 1 輪 (A–E 五組，claude-impl 兩組、codex-impl 三組，各組交叉唯讀審查，同一時間改的檔不重疊)：版面判定改用詳情內容錨點、iPhone 橫向錨點與分頁 identifier、數字鍵盤浮動判斷、框線同一快照讀取 (`StableVisibleFrame`)、欄位清空、sheet 計數、更多入口列等待、開團並排版面略過條件、膠囊可見部分判定、KPI 與圓餅圖捲動。風格閘門兩組 (support 13 檔、測試與 App 檔)，主對話裁定後修正。
- 第 2 次：iPhone 12 140 通過／5 失敗／45 略過；iPad Air 5 160 通過／13 失敗／17 略過，全部為測試端。
  - iPad 13 條分類：搜尋欄已聚焦時點中央，游標落在文字中間，刪除鍵只刪左半 (2 條)；輸入後鍵盤升起使 alert 上移約 45 pt，點擊落在舊位置 (1 條)；iPadOS 27.2 付款方式選單項目只有標籤，regular helper 未傳標籤回退 (3 條)；詳情欄導覽列從 x = 0 起，延伸到清單欄底下 (`OrderRegularSearchBarTests` 4 條)；並排框線取詳情根容器 (1 條)；regular 版讀 compact 篩選鈕 (1 條)；`1230` 已知問題 (1 條)。
  - 第 1 次的產品問題：P1 經 4.5 修正後兩台 `LookupManagementTests` 12 條全數通過；P2 路徑標記改掛詳情根後，兩台相關測試通過。
- 修正第 2 至 5 輪：iPhone 5 條 (訂單列與設定入口列捲動、完成鍵避讓、成本圓餅圖在上方時輕拖)；iPad 13 條 (搜尋欄改用清除鈕清空並重新聚焦、自訂 alert 上移時等穩定並重試一次、Menu 內 `Picker(.inline)` 選項傳標籤回退、詳情導覽列以右緣判定、並排框線用內容錨點、根樣式切換案例先套用非預設篩選)；iPhone 橫向清單列被分頁列蓋住時改輕拖 (`stableVisibleFrame`)。每輪交叉唯讀審查，第 4 輪風格閘門一組；子集重跑：iPad 29 通過／2 失敗 → 搜尋相關 12 通過／1 略過，iPhone 20 通過／1 失敗 → 5 通過。
- 第 3 次：iPhone 12 `KeyboardDismissTests` 2 通過；iPhone 12 完整 145 通過／0 失敗／45 略過 (95 分鐘)；iPad Air 5 完整 170 通過／3 失敗／17 略過 (85 分鐘)，失敗為數字鍵盤 1230 (已知) 與下列兩項產品問題。略過皆為版面條件 (iPhone 無並排或側邊欄的案例)。
- 3.2 留給 4.2 的確認：反例 `AdaptiveLayoutCheckCounterexampleTests` 5 條在 iPhone 12 實際執行並通過 (執行數大於 0)；N3「更多」收合分支在 iPhone 12 通過 (入口列寬度門檻成立)；第 5 次 `AdaptiveNavigationContinuityUITests` iPhone 12 8 通過／8 略過、iPad Air 5 14 通過／2 略過，反例 5 條兩台皆執行並通過；N1 徽章讀法 (`testSidebarPreferenceSurvivesTabChange_側邊欄展開_目的地與徽章正確`) 在 iPad 通過；N2 (`testSelectionSurvivesLayoutChange_並排且已選取_路徑與詳情同為當前訂單`) 在 iPad Air 5 直向仍並排，依 3.2 裁定以版面條件略過，並排與收合的轉換與新舊詳情標籤是否重疊留給 4.3 Duo。
- 已知問題：iPad Air 5 `KeyboardDismissTests.testTapNumericKeyboardDone` (數字鍵盤完成鍵 1230) 使用者已裁定為 iPadOS 27.2 已知問題，等「數字欄位聚焦全選」change。第 3 次與第 5 次 iPad 仍失敗 (`1230`)，iPhone 12 不受影響。
- 執行期警告：`Invalid frame dimension (negative or non-finite)` 19 條，與 1.1 起記錄的數字鍵盤診斷相同，相關案例皆通過。
- 文件同步：`.claude/rules/ios-ui-tests.md` 補 Menu `Picker(.inline)` 選項的標籤回退、iPadOS 27 詳情欄延伸到清單欄底下 (用內容錨點、導覽列以右緣判定)、搜尋欄用清除鈕清空、自訂 alert 上移時的點擊等待與重試；`apps/ios/CLAUDE.md` 與 README 經搜尋確認無須更動。

- 第 4 次 (2026-10-31，4.6／4.7 修正後)：見任務 4.6、4.7；兩項產品問題修正後相關類別在兩台實機通過。
- 第 5 次 (2026-11-01，4.1 回歸、kit 4.2.2 至 4.2.4 對齊與測試 `Support/` 平放之後)：
  - iPhone 12 `KeyboardDismissTests` 2 通過；完整 146 通過／1 失敗／45 略過，90 分鐘。失敗為 `OrderFilterSheetLargeTests.testFilterSheetLargeApply_展開已收單捲到末格_觸發鈕兩項且結果兩筆`，第 3 次通過、單獨重複 5 次 4 過 1 敗。
  - iPad Air 5 `KeyboardDismissTests` 1 通過／1 失敗 (`1230` 已知問題)；完整回歸跑到第 63 條 (`CurrencyPickerTests`) 時 runner 與裝置連線中斷 (`The connection was invalidated`，裝置隨後顯示已中斷連線)，之前 58 通過／4 略過、無斷言失敗。使用者重新連線後補跑未完成的 36 類：133 通過／1 失敗 (`1230`)／13 略過。合計 191 通過／1 失敗 (已知)／17 略過，略過皆為版面條件。
  - 篩選 sheet 失敗成因 (主對話依失敗 log 判讀，claude-impl 唯讀審查兩輪)：`OrdersScreen.revealElement` 先往下找「類別 300」時，位置簽章在減速中讀值，滑 5 次就誤判到底；轉往上找以 `swipeDown()` 滑到頂端後又滑一次，把沒有未套用變更的篩選 sheet 拉掉 (依 spec 可關閉，屬測試 helper 缺陷，非產品問題)。修正 (codex-impl 實作，主對話調整)：往上找改為慢速輕拖並停住再放開；簽章改用格子相對於 sheet 的位置；每次手勢後等簽章連續兩次相同才判斷，逾時視為仍在捲動；手勢前確認 sheet 存在，不在時 `failWithDiagnostics`；迴圈結束回傳 `element.exists`；方法依 kit 呼叫者在前、深度優先排序。修正後 iPhone 12 該測試重複 10 次全過 (每次約 5.5 分鐘，原約 2.4 分鐘)，`OrderFilterSheetTests`／`OrderCategoryPickerTests`／`OrderCategoryPickerLargeTests` 10 通過／6 略過。審查記錄未處理的設計風險：到頂判斷仍在拖動後進行、往上找的步數接近 `maxSwipes` 上限、取樣成本 (claude-impl 第 2 輪 M-A 至 M-C、S-B 至 S-E)。
  - 排序調整與 kit 對齊後的最終 helper 驗證 (`OrderFilterSheetLargeTests`／`OrderFilterSheetTests`／`OrderCategoryPickerTests`／`OrderCategoryPickerLargeTests`)：iPhone 12 11 通過／0 失敗／6 略過。iPad Air 5 接在 iPhone 之後執行時開不起 UI 自動化 (`Timed out while enabling automation mode`，0 條執行)。使用者決定改用模擬器，並以該結果代替這組的實機驗證；主對話選尺寸與系統最接近的 iPad Air 11 吋 (M4) iOS 27.0 模擬器 (F5BE3685-31EB-4586-B674-B9C48067EF25，加 `-parallel-testing-enabled NO`)：6 通過／0 失敗／11 略過，略過為篩選 sheet 兩類的版面條件，與實機第 5 次相同。
- 文件同步 (第 5 次)：`.claude/rules/ios-ui-tests.md` 補 sheet 內位置簽章用相對位置與等待穩定、往上找不用 `swipeDown()`。
- 既有警告：UI 測試 target 24 個 actor isolation 警告見「測試 `Support/` 依 ios-dev-kit 4.2.3 改名並平放」段。
- 結論：兩台完整回歸除 iPad 數字鍵盤 `1230` (使用者已裁定為已知問題) 外沒有失敗，略過皆為版面條件；篩選 sheet helper 缺陷已修正並通過最終驗證，4.2 完成。

## 任務1.4／1.5：以最終 UI 回歸驗收 (2026-11-01)

- 依使用者 2026-10-29 決定，1.4／1.5 以最終程式碼的兩台實機完整 UI 回歸 (任務4.2 第 5 次) 驗收；1.5 的 `RootNavigationContinuitySmokeTests` 與 1.4 的 `OrdersLayoutScopeSmokeTests` 已於 3.2 併入 `AdaptiveNavigationContinuityUITests` (覆蓋不減少，見任務3.2)。
- 1.4 指定類別 (iPhone 12／iPad Air 5，iPad 為第一段與補跑第二段合計；`CurrencyPickerTests` 在第一段中斷後於第二段完整重跑)：
  - `LaunchSmokeTests` 2 通過／1 略過、3 通過；`OrientationLayoutTests` 4／4 通過
  - `KeyboardDismissTests` 2 通過；iPad 1 通過／1 失敗 (`testTapNumericKeyboardDone` 數字鍵盤 `1230`)
  - `FxTests`、`QuoteTests` 各 4；`CampaignCrudTests` 2；`CampaignDetailTests` 1；`CampaignFlowTests` 10 通過／1 略過、9 通過／2 略過
  - `OrderEditAddOptionTests` 2；`OrdersListTests` 3；`OrderCreateTests` 6；`OrderEditDirtyTests` 3；`LookupManagementTests` 13；`CurrencyPickerTests` 24 (兩台皆通過)
  - `OrderRegularColumnScopeTests` iPhone 12 條依版面略過、iPad 12 通過
  - 十個版面判斷呼叫端類別 (`Tests/Orders/Filters` 5 類、`Tests/Orders/Regular` 5 類)：iPad 上 regular 類別全部通過，`OrderFilterSheetTests`／`OrderFilterSheetLargeTests` 依版面略過；iPhone 上 regular 類別依版面略過，`OrderFilterSheetTests` 10 通過，`OrderFilterSheetLargeTests` 的失敗為篩選 sheet helper 缺陷，修正後見任務4.2。沒有因停在總覽而失敗的案例。
- 1.5 門檻 (iPad Air 5)：N1 `testSidebarPreferenceSurvivesTabChange_側邊欄展開_目的地與徽章正確`、N5 `testMoreSettingsSurvivesRoundTrip_更多設定頁前景_設定頁保留`、`testMoreCustomerSurvivesRoundTrip_更多客戶頁已選取客戶_客戶頁與搜尋保留`、`testRootStyleChangeKeepsOrders_側邊欄展開_訂單選取與篩選不變` 全部通過；`OrdersNavigationSmokeTests` 7 通過／1 略過 (收合版專屬的 `testOrders_選取訂單詳情與原生返回_Mika周017營收4980且path清空`，該案例在 iPhone 12 通過)。iPad 上 `AdaptiveNavigationContinuityUITests` 的 2 條略過為 iPhone 收合版膠囊案例與 N2 (留給 4.3)，不屬 1.5。
- 使用者決定 (2026-11-01)：iPad Air 5 數字鍵盤 `1230` 沿用 4.2 的已知問題裁定，1.4 勾選完成，這條失敗留給「數字欄位聚焦全選」change。

## 任務4.3：iPhone Duo 摺展 UI Automation (2026-11-01)

- 環境：iPhone Duo 模擬器 iOS 27.1 (`1666A373-A43C-4CF5-A468-ED8D513A3269`)，App 2.1.0 (413)、SDK iphonesimulator27.1、Xcode 27A9275、最低 iOS 26.0；安裝時間晚於最後一次產品碼修改。啟動參數 `-BLUITest -BLUITestSeed campaignsWithOrders -BLUITestLanguage traditionalChinese`，同一 PID 72828 全程未重啟。標準字級、淺色、系統語言正體中文。
- 前置：Device Hub 的 Simulate Hardware Keyboard 由主對話關閉 (原為開啟)，之後軟體鍵盤正常顯示；英文輸入以長按地球鍵切到既有的 English (US) 鍵盤，未改模擬器設定。
- 工具分工：姿勢以 Device Hub 底部姿勢鈕切換；Closed 的 AX 用 Xcode DeviceInteraction 階層 (含 Selected／Keyboard Focused)；Open／Partial 下 Xcode 擷取仍沿用 Closed 的舊畫面範圍 (截圖全黑、AX 被裁切)，改以 `mobilebuildmcp ui-automation snapshot-ui` 取 AX、以 macOS 區域截圖保存 Device Hub 畫面。操作以 Device Hub 直接點擊為主，未以 snapshot 代替操作。
- 尺寸：Closed 視窗 466×678 pt、App 介面直向、根分頁列在右側縱向浮條；Open 視窗 951×669 pt、介面 Landscape Left、清單與詳情並排；Partial 仍並排，清單欄比 Open 窄 (未重新量測視窗)。

### 逐案結果

- N2 通過：Closed 點 Mika `BL-2604-017` (列 Selected、詳情 value 017) → Open 仍 017 且清單高亮 Mika → Partial 仍 017 → Partial 改點 Joyce `BL-2604-015` (詳情 value 015) → Closed 仍 015。Closed 的狀態選單 9 項 (報價中 Selected)、更多選單 (合併／編輯／刪除) 實際點開，編輯只開一份「編輯訂單」且客戶為 Joyce 黃，取消後仍 015。
- N6 新增訂單通過：Open 輸入 `DuoDraft` → Closed 同一份「新訂單」、值保留且 Keyboard Focused，續輸入寫回同欄成 `DuoDraftz` → Closed 取消出現捨棄確認 → Open 捨棄確認與草稿保留，繼續編輯回到同欄，最後捨棄。
- N6 開團編輯通過：Open 名稱改為 `四月韓國團Duo` → Closed 同一份「編輯開團」、續輸入成 `四月韓國團Duox` 且 Keyboard Focused → 捨棄確認在 Closed 出現、Open 保留，捨棄後名稱未變。
- N6 報價通過：Open 商品定價 `120` → Closed 同一欄續輸入成 `1205` 且 Keyboard Focused。觀察：摺疊後游標由欄中移到欄尾；`120` 是游標停在原本 0 之前的既有「數字欄位聚焦全選」已知問題。
- N6 主檔改名不通過 (可重現 2/2)：Closed 把「服飾」改成 `服飾Duo` 且 Keyboard Focused → Open 後表單仍只有一份，但值回到「服飾」、焦點消失；Open 以螢幕鍵盤再打成 `服飾Duo` → Closed 同樣回到「服飾」。主對話讀碼：`LookupNameEditorSheet` 的草稿是 sheet 內 `@State`，destination 仍在所以 sheet 重新呈現，內容以 `initialName` 重建；`PaymentMethodEditorSheet` 與新增表單同構，推測同樣受影響 (未實測)。屬已勾選 2.7「Editing remains continuous during layout adaptation」的主檔範圍。
- L2 部分通過：Closed 直向的狀態膠囊在系統列前裁切，捲到最後的「已合併」可點選、框線 293–366 pt 在右側浮條 (x 396 起) 之前；篩選鈕、新增、批次選單在右側浮條可點。Open 橫向的類別篩選 sheet、詳情狀態與更多選單皆可點開且不壓到系統列。未驗證：系統列在左側。模擬器內 Closed 在四個裝置方向下 App 介面都維持直向，Open 經 Device → Orientation 只出現「系統列在右側」(橫向) 與「系統列在上方」(直向) 兩種，Device Hub 的 Rotate 只轉外框並拉伸畫面，三種工具都做不出左側。
- L3 部分不通過：訂單在 Open 收起側邊欄 → Partial 仍收起且 017 → Closed 詳情 017 正確，但狀態與更多兩個選單消失，右側只剩空白膠囊 (Xcode 階層無 `orders.detail.statusMenuButton`／`moreButton`)。同序列再跑兩次未重現 (其中一次 Partial 步驟未截圖確認)；直接 Open → Closed 正常。與任務1.1 記錄的 Closed 空白膠囊同一現象，屬間歇缺陷。其餘通過：側邊欄收起狀態在 Open↔Closed 保留；開團 `CMP-SAMPLE-KR-APR` 與更多「商品類別管理」跨 Closed↔Open 保留；Closed 返回清單後 Open 顯示「選擇訂單」不復活舊詳情。
- 其他觀察 (未列為缺陷，待判斷)：更多分頁在 Open 的右欄空狀態與報價頁，灰色背景只到約三分之二高度、下方為白色；開團清單在並排時不顯示選取高亮。工具雜訊：snapshot-ui 對中心點在可視範圍外的列 tap 無效；Closed 叫出的捨棄確認展開後，前兩次點「繼續編輯」沒反應、第三次生效，同步驟重現一次正常，不計缺陷。

### 結論

- 4.3 不勾選：N6 主檔改名草稿遺失 (確定缺陷)、L3 詳情選單間歇消失。
- 使用者決定 (2026-11-01)：主檔改名草稿遺失與詳情選單間歇消失都併入本 change 修正 (後者先追查成因)；L2 的「系統列在左側」目前 Duo 介面不會發生，先不處理，L2 以右側與上方兩種位置的結果為準；「更多」右欄灰色背景只到三分之二高目前無法重現，先不處理。

## 任務4.8／4.9：Duo 摺展缺陷的診斷 (2026-11-02)

- 環境：iPhone Duo 模擬器 iOS 27.1 (`1666A373-A43C-4CF5-A468-ED8D513A3269`)；含 `BLDIAG-4.8`／`BLDIAG-4.9` 暫時診斷的 Debug 建置以 `mobilebuildmcp simulator build-and-run` 帶 `campaignsWithOrders` 種子啟動 (PID 95698)，之後以 `simulator launch-app` 乾淨重啟一次 (PID 15644)。姿勢以 Device Hub 切換。開始前發現 App 曾被不帶種子參數重新啟動 (空資料)，不是本任務造成，已重新帶種子啟動。
- 4.8 成因 (主對話確認)：Closed 在重新命名表單輸入 `服飾Duo` 後展開到 Open，`LookupManagementView` 的 token 不變 (沒有重建)，`LookupNameEditorSheet` 則依序 disappear、以新 token appear、再 disappear、再以新 token appear，草稿回到 `服飾`。系統在摺展時把 sheet 關掉再重新呈現，sheet 內容是新的 View，`@State` 草稿與焦點因此遺失；草稿與焦點都必須由 feature State 持有。
- 4.9 重現 (主對話)：同一 App 程序內「Open 收起側邊欄 → Partial → Closed」5 次失敗 4 次、收起側邊欄直接 Open → Closed 失敗、側邊欄展開 → Partial → Closed 1 次通過後同批再試失敗；乾淨重啟後側邊欄展開的 Open → Closed 第 1 次通過、第 2 與第 3 次失敗；改選另一張訂單 (`BL-2604-018`) 後第 1 次收合即失敗。開團詳情 (清單不是 `List` 選取) 連續收合 3 次「更多」都在。失敗時 AX 沒有 `orders.detail.statusMenuButton`／`orders.detail.moreButton`，詳情 ID 正確。
- 4.9 成因 (主對話確認)：每次收合系統都印出 `Unbalanced calls to begin/end appearance transitions for <NavigationStackHostingController…>`；失敗時隨後兩個 `OrderDetailMenu` 的 label `onDisappear` 且不再 `onAppear`，`OrderDetailView` 全程同一 token 沒有重建。與 Apple Developer Forums 回報的 SwiftUI 缺陷相同：側邊欄 `List` 有過選取後，詳情欄 `.toolbar` 項目在尺寸分類改變時消失且不會自己回來，只有重建該 View 才恢復 (FB15300614，https://developer.apple.com/forums/thread/764869)。側邊欄收起與 Partial 不是必要條件，任務原本描述的序列只是較容易遇到。
- 觀察 (未定論)：乾淨啟動後第一次收合的 Closed 畫面右側一度沒有返回鈕，之後的收合都有；4.3 首輪 5 次 Closed 擷取都有 `BackButton`。修正後再確認。

## 任務4.9：修正與 Duo 驗證 (2026-11-02)

- 修法 (主對話決定第 1 案，codex-impl 實作)：`OrderDetailView` 不再直接在內容上掛 `.toolbar`，改掛在 `.background` 的透明子 View 上，並以 `horizontalSizeClass` 作為該子 View 的 `.id`；尺寸分類改變時只重建工具列貢獻者，詳情內容不重建。修改處註解記錄繞過 FB15300614。第 2 案 (尺寸分類改變時重建整個 `OrderDetailView`) 未採用。
- Duo 驗證 (修正後建置，PID 47349，含診斷)：選 Mika `BL-2604-017` 後共 16 輪收合，變化包含直接 Open → Closed、收起側邊欄、先展開再收起側邊欄、經 Partial、換選 `BL-2604-018` 後收合；16 輪 Closed 兩個選單都在。第 7–16 輪每輪新開 Xcode DeviceInteraction session 擷取 AX，確認 `orders.detail.statusMenuButton`、`orders.detail.moreButton` 各 1 個、實際點開狀態選單 (含「已取消」項) 與更多選單 (含 `orders.detail.editButton`)、點旁邊後兩者關閉，10 輪全部通過。
- 日誌：`Unbalanced calls to begin/end appearance transitions` 仍出現 9 次 (系統行為未變)，但選單 label 每次收合都重新 appear；`OrderDetailView appear` 全程只有 1 次，詳情內容沒有因摺展或換單重建。
- 待辦：移除 `BLDIAG-4.9` 診斷、claude-impl 唯讀審查、風格閘門、兩台實機 `AdaptiveNavigationContinuityUITests` 與 `OrdersNavigationSmokeTests`。

## 任務4.8：第 1 輪實作的 Duo 驗證 (2026-11-02)

- 實作 (claude-impl)：三種表單的草稿、名稱欄焦點、捨棄確認、dirty 與可提交判斷移入 feature State (`BindableAction`)；兩個 sheet 改以綁定接收；`OptionPickerSheet` 嵌入路徑的草稿留在元件內；新增 `LookupRenameFormFeatureTests` 12 條、`LookupAddFormFeatureTests` 11 條、`PaymentMethodEditFormFeatureTests` 9 條 (尚未執行)。
- 通過：改名表單 Closed 輸入 `服飾Duo` → Open 草稿與游標、鍵盤都保留 → Open 續輸入成 `服飾Duox` → Closed 同一份表單、值保留且 Keyboard Focused；Closed 取消出現捨棄確認 → Open 確認框與草稿保留。同一姿勢內「捨棄變更」正常關閉表單且名稱未變。
- 不通過 (2/2 重現)：捨棄確認跨過摺展後在 Open 按「捨棄變更」，提示框關閉但表單沒有關閉、草稿仍在。推測摺展時 sheet 被重新呈現後 View 的 `dismiss` 失效；提交由父層清除 `destination` 不受影響。主對話決定第 2 輪改由 reducer 的 `dismiss` 關閉表單。

## 任務4.8：第 2 輪與捨棄確認診斷 (2026-11-02)

- 第 2 輪 (claude-impl)：三種表單新增取消與捨棄的 view action，由 reducer 的 `@Dependency(\.dismiss)` 關閉表單；兩個 sheet 的綁定版 init 改由呼叫端傳入取消與捨棄處理；新增 10 條 reducer 測試；`.claude/rules/ios-navigation.md` 同步 (表單草稿、焦點、捨棄確認由 feature State 持有，取消與捨棄由 reducer 關閉)。
- Duo 實測 (第 2 輪建置，PID 96773)：新增表單 Closed `DuoAdd` → Open 保留且有焦點 → 續輸入 `DuoAddx` → Closed 保留、Keyboard Focused、單一 sheet；付款方式編輯 Closed 打開「無卡」並輸入 `信用卡D` → Open 名稱、旗標、焦點都保留 → 續輸入 `信用卡Dx` → Closed 名稱、旗標保留、Keyboard Focused、單一 sheet；同一姿勢內取消再捨棄兩者都關閉表單且資料未變。改名表單在同一姿勢內的 reducer 捨棄正常；捨棄確認跨摺展後按「捨棄變更」仍不關閉 (第 3 次重現)。
- 捨棄確認診斷 (第 3 步 `BLDIAG-4.8`，PID 11273)：Closed 取消後確認框綁定為 true；展開時舊 sheet 實例 disappear，新實例 appear 並把確認框綁定寫回 false，再 disappear、再 appear；之後按畫面上的「捨棄變更」沒有任何日誌 (按鈕動作與 wrapper 都沒被呼叫)，畫面上的確認框屬於已拆掉的舊呈現。訂單與開團的表單 sheet 掛在 `NavigationSplitView` 那一層不受影響，主檔表單由詳情欄內的 `LookupManagementView` 呈現。
- 使用者決定 (2026-11-02)：主檔管理的表單與提示改由 `MoreView` 的分欄層呈現；design 與 tasks 4.8 已更新範圍。

## 任務4.8／4.9：最終程式碼的 Duo 驗證 (2026-11-02)

- 最終程式碼：4.8 主檔管理的表單與提示改由 `MoreView` 分欄層的 `LookupManagementPresentations` 呈現 (claude-impl 第 4 輪，使用者決定)；兩邊診斷整段移除 (`rg BLDIAG apps/ios` 無結果)；交叉審查 (claude-impl 審 4.9、codex-impl 審 4.8，皆無高中嚴重度) 的低嚴重度建議已套用。屬性重新排序後 `RenameFormSheet` 的 memberwise init 參數順序改變，呼叫端兩個引數對調由主對話修正 (型別檢查逾時是此錯誤造成)。建置成功、無警告 (PID 87885)。
- 4.8：
  - 改名表單 Closed 輸入 `服飾Duo` 並取消出現捨棄確認 → 展開 → 按「捨棄變更」表單關閉、名稱仍為「服飾」；Closed 輸入 `服飾Keep` 並出現確認 → 展開 → 按「繼續編輯」回到表單、草稿與鍵盤都在；同姿勢內捨棄正常。
  - 主檔頁刪除確認 Closed 出現 → 展開後仍在 → 按「取消」關閉且「美妝」保留；再一次展開後按「刪除」，項目由 4 項變 3 項 (按鈕確實執行)。
  - 新增表單 Open 輸入後摺回 Closed：值保留、Keyboard Focused、單一 sheet；付款方式編輯 Closed 打開「無卡」並輸入 → 展開：名稱、旗標、游標與鍵盤保留；兩者捨棄後資料未變。
- 4.9：最終程式碼上選 Mika `BL-2604-017` 後 3 輪收合 (直接、收起側邊欄經 Partial、展開側邊欄)，每輪 AX 兩個選單各 1 個、實際點開與關閉都正常。

## 任務4.8／4.9：單元、守門與 snapshot 回歸 (2026-11-02)

- 三個新測試檔缺 `import SwiftUI`，`@Bindable var bindable = store` 解析成 Perception 的不可用版本而編譯失敗 (`MemberImportVisibility`)；主對話依既有 `CampaignEditFeatureTests` 的寫法補上 import。
- iPhone 12 (iOS 26.7.2) Lookups 與相關類別 12 個 (含三個新測試檔)：88 通過／0 失敗 (數量與 `@Test` 宣告一致)。
- iPhone 12 完整單元 (排除守門與 snapshot 清單)：1755 通過／4 失敗。4 條皆為讀 repo 原始碼的守門 (`LanguageProjectionBoundaryTests` 2 條、`ToolReadableWidthGuardTests` 2 條)，實機讀不到 Mac 檔案，不在舊守門清單內；改在 iPhone 17 iOS 26.5 模擬器執行 4/4 通過。之後的守門清單要納入這兩個類別。
- iPhone 17 iOS 26.5 模擬器 (淺色) 守門與 snapshot 31 個類別：156/156 通過，snapshot 基準未變動 (含 `SnapshotLookupsTests`、`SnapshotSharedTests`、`SnapshotOrderDetailTests`、`SnapshotMoreTests`)。

## 任務4.8／4.9：風格閘門與修正後回歸 (2026-11-02)

- 風格閘門 (haiku-max-implementer，唯讀，13 檔整檔審查)：違規 26 項 (Swift 20、`.claude/rules/ios-navigation.md` 6)，`OrderDetailView.swift` 與 `LookupAddFormFeatureTests.swift` 無違規。主對話裁決：A1 註解中指向型別或識別字的 `State`／`View` 加反引號、泛稱不加；A2 `PaymentMethodEditorSheet.SubmitAction` 不動 (既有、待使用者另行決定)；A3 enum case 關聯值比照函式規則單行；A4 `MoreView` 標題與圖示對照、`renameSheetTitle`、`OptionPickerSheet.filteredOptions` 為既有顯示對照，本次不搬；A5 `return .send(.delegate(...))` 允許。觀察 O1 (`MoreView` 列 `Label` 的 `.labelStyle`) 會改變畫面，O2 (一條測試的 `#expect` 比對初始值) 不改。
- 修正 (claude-impl)：`case let` 改 `case .x(let v)`、未達斷行條件的呼叫改單行、`LookupManagementPresentations` 與三個表單 sheet 拆到新檔 `LookupManagementPresentations.swift` (sheet 改 private nested types)、Private Method／View 與修飾子排序、`ios-navigation.md` 主次 bullet 分層與焦點敘述修正。偏離：`LookupNameEditorSheet` 保留 `import ComposableArchitecture` (`.bind(_:to:)` 由 TCA 重新匯出，`MemberImportVisibility` 開啟)；V10 改 nested 後縮排加深超過 100 字元維持多行。主對話複核 diff 與新檔。
- 修正後回歸：Duo 建置成功；iPhone 12 Lookups 與 `MoreFeatureTests` 等 13 個類別 96/96 通過；iPhone 17 iOS 26.5 模擬器 (淺色) 守門與 snapshot 33 個類別 (含 `LanguageProjectionBoundaryTests`、`ToolReadableWidthGuardTests`) 160/160 通過，snapshot 基準未變動。

## 任務4.8／4.9：UI 測試類別回歸 (2026-11-02)

- 實機：iPhone 12 (iOS 26.7.2) 與 iPad Air 5 (iPadOS 27.2) 的 `KeyboardDismissTests` 與類別回歸共 4 次執行，runner 都在啟動時失敗 (`Timed out while enabling automation mode`)，沒有執行任何案例。
- 依使用者 2026-11-02 指示 (實機再逾時就直接改模擬器)，改在 iPhone 17 iOS 26.5 模擬器 (`CBE3AABB-FFBF-4F91-AFF9-5DD283DDB410`) 與 iPad Air 11-inch (M4) iOS 27.0 模擬器 (`F5BE3685-31EB-4586-B674-B9C48067EF25`) 執行，命令為 `mobilebuildmcp simulator test` 帶 `-only-testing`，同一時間只跑一組。
- 類別：`LookupManagementTests` (4.8 呈現位置改到 `MoreView`)、`OrderEditAddOptionTests` (`OptionPickerSheet` 嵌入編輯器)、`AdaptiveNavigationContinuityUITests` 與 `OrdersNavigationSmokeTests` (4.9 詳情工具列)。
  - iPhone 17：28 通過／0 失敗／11 略過 (`LookupManagementTests` 13、`OrderEditAddOptionTests` 2、`AdaptiveNavigationContinuityUITests` 8 通過 8 略過、`OrdersNavigationSmokeTests` 5 通過 3 略過)。
  - iPad Air 11：36 通過／0 失敗／3 略過 (`LookupManagementTests` 13、`OrderEditAddOptionTests` 2、`AdaptiveNavigationContinuityUITests` 14 通過 2 略過、`OrdersNavigationSmokeTests` 7 通過 1 略過)。
  - 略過皆為 `XCTSkipUnless` 版面條件，數量與 4.2 第 5 次兩台實機相同：iPhone 為只存在於 regular 或並排版面的案例，iPad 為 iPhone 收合版膠囊、N2 (直向仍並排) 與收合版原生 Back。
- `KeyboardDismissTests`：兩台模擬器都是 1 通過／1 失敗，失敗為 `testTapNumericKeyboardDone_數字鍵盤顯示中_收起鍵盤` 實付金額 `1230` (預期 `123`)，與 4.2 記錄的「數字欄位聚焦全選」已知問題相同 (使用者已裁定另開 change)。新觀察：iPhone 17 iOS 26.5 模擬器也出現此症狀，iPhone 12 實機先前通過。4.8／4.9 沒有改訂單編輯畫面與 UI 測試 helper，鍵盤收起的斷言本身通過，不據此判定本任務退步。
- 4.9 偏離 (主對話判定)：任務寫的修正前重現序列「至少 20 次」實際為 15 次 (4.3 首輪 3 次、診斷 12 次)，其中 10 次選單消失。成因已由診斷日誌與 FB15300614 確認，修正後 19 次 (16 次加最終程式碼 3 次) 全部通過；以觀測失敗率 2/3 估計，未修正時連續 19 次都通過的機率低於 1e-9。估計重現率的目的已達成，不回退修正補做 5 次。
- 4.8、4.9 其餘驗收條件 (reducer 測試、Duo 三種表單與選單實測、相關 UI 類別、風格閘門) 都已滿足，主對話勾選。

## 任務4.3：4.8／4.9 之後的 Duo 重跑 (2026-11-02)

- 環境：iPhone Duo 模擬器 iOS 27.1 (`1666A373-A43C-4CF5-A468-ED8D513A3269`)，App 2.1.0 (413)，為風格閘門修正後的建置 (`campaignsWithOrders` 種子，PID 73780 全程未重啟)；建置後 `apps/ios` 沒有 Swift 檔再變動。工具分工與首輪相同：姿勢以 Device Hub 底部姿勢鈕切換，Closed 用 Xcode DeviceInteraction 階層，Open／Partial 用 `snapshot-ui` 與 Device Hub 截圖。
- 重跑範圍 (主對話依改動範圍決定)：4.8 影響 N6 主檔三種表單、主檔確認框與「更多」主檔頁跨姿勢保留；4.9 影響詳情工具列，故 N2 的選單操作、L2 Open 的詳情選單與 L3 收合序列一起重跑。N6 新增訂單／開團編輯／報價、L2 Closed 的狀態膠囊與篩選、L3 的開團保留與返回清單後不復活舊詳情，相關畫面沒有被 4.8／4.9 修改，沿用首輪證據。
- N2 通過：Closed 點 Mika `BL-2604-017` (詳情 value 017) → Open 仍 017 且清單高亮 → Partial 仍 017 → Partial 改點 Joyce `BL-2604-015` (詳情 value 015) → Closed 仍 015。Closed 狀態選單 9 項且「報價中」Selected，更多選單有合併、編輯、刪除，編輯只開一份「編輯訂單」且客戶為 Joyce 黃，取消後仍 015、兩個選單仍在。
- L2 Open 通過：詳情狀態選單 9 項 (已下單打勾) 與更多選單 (合併訂單、編輯、刪除) 在 Open 都能點開，觸發鈕位於右側系統狀態列下方、未被遮蔽。
- L3 通過 (3 輪，每輪 Closed 以 AX 確認 `orders.detail.statusMenuButton`、`orders.detail.moreButton` 各 1 個並實際點開與關閉)：第 1 輪 Open 收起側邊欄 → Partial (仍收起、015) → Closed；第 2 輪收起狀態直接 Open → Closed；第 3 輪 Open 展開側邊欄、改選 Mika 017 → Closed。5 次 Closed 擷取都有 `BackButton`，4.9 診斷時記錄的「首次收合沒有返回鈕」本輪未出現。
- N6 主檔通過：
  - 改名：Closed 把「服飾」改成 `服飾Duo` 且 Keyboard Focused → Open 草稿、游標與鍵盤保留，螢幕鍵盤續輸入成 `服飾Duox`，只有一個名稱欄 → Closed 值 `服飾Duox`、Keyboard Focused、單一表單。Closed 取消出現捨棄確認 → Open 確認框與草稿保留，按「繼續編輯」回到同欄且鍵盤仍在；Open 再取消 → Closed 確認框仍在，按「捨棄變更」表單關閉、仍為「服飾」與 4 項。
  - 新增：Closed 輸入 `DuoAdd` 且 Keyboard Focused → Open 保留並續輸入成 `DuoAddx` → Closed 值 `DuoAddx`、Keyboard Focused、單一表單；取消並捨棄後表單關閉、仍 4 項。
  - 付款方式編輯：Closed 打開「無卡」並把「信用卡」輸入成 `信用卡D`、Keyboard Focused → Open 名稱、旗標、游標與鍵盤保留，續輸入成 `信用卡Dx` → Closed 值 `信用卡Dx`、無卡為開、Keyboard Focused、單一表單；取消並捨棄後「信用卡」不變且無無卡標記。輸入名稱那一步的第一次擷取因 session 失敗未取得，重開 session 後同一步驟完成，期間畫面停在表單、名稱未變。
  - 刪除確認：Closed 對 LINE Pay 叫出刪除確認 → Open 確認框保留，按「取消」後 LINE Pay 保留、6 項；再一次 Closed 叫出 → Open 按「刪除」，變為 5 項且 LINE Pay 消失。
  - 「更多」主檔頁跨姿勢保留：Closed 的「商品類別管理」與「付款方式管理」展開後仍是同一頁，「更多」側邊欄同時顯示。
- 工具雜訊：Partial 下以滑鼠滾輪與 `ui-automation swipe` 捲動訂單清單無效，改以 Device Hub 按住拖曳；不影響判定。
- 結論：首輪不通過的 N6 主檔改名與 L3 選單消失在最終程式碼上都通過，受 4.8／4.9 影響的 N2、L2 Open 選單也通過；L2 左側依使用者 2026-11-01 決定不驗。4.3 的驗收條件已滿足，主對話勾選。

## 任務4.4：iPad 閱讀寬度與欄寬量測 (2026-11-02)

- 環境：iPad Air 11-inch (M4) iOS 27.0 模擬器 (`F5BE3685-31EB-4586-B674-B9C48067EF25`)，App 2.1.0 (413)，`campaignsWithOrders` 種子；量測以 Xcode DeviceInteraction 階層的 frame 為準 (`snapshot-ui` 不含 frame)，轉向用 `orientation` 指令。三輪啟動：正體中文標準字級、正體中文 `UICTContentSizeCategoryAccessibilityXXXL` (AX5)、英文標準字級。
- 閱讀上限 (通過)：
  - 直向 820 pt 總覽 hero 寬 608 (= 640 − 兩側內距 16) 於 x=106 置中。橫向 1180 pt 根側邊欄 280 時 hero 426–1034，置中於可見區 280–1180。
  - 分析 (`.chart` 840)：期間選擇器 808 置中。匯率、報價 (`.form` 680)：內容 648 置中於詳情欄 300–1180。客戶 (`.text`)：卡片區 608 置中。訂單詳情：收起根側邊欄時內容約 608 置中於詳情欄。
  - 新增訂單表單 sheet 寬 580，內容 516 填滿，低於上限。
  - AX5：上限隨字級放大，總覽、分析、訂單詳情、匯率內容填滿可用區、KPI 單欄、金額不截斷。英文：總覽與報價內容置中、標籤完整。
- 欄寬：
  - 「更多」入口欄 300 pt，與偏好相符。
  - 訂單與開團清單欄都是系統預設 320 pt。橫向收起根側邊欄時，訂單為 320／860、開團為 320／860 (約 1:2.7)；有根側邊欄時訂單為 320／580；直向訂單為 320／500。標準字級中英文皆可讀；AX5 時訂單清單欄商品名稱每行一兩個字，可讀但擁擠；英文清單欄狀態膠囊「Consolidat-ing」斷字、搜尋提示截斷。
  - 使用者決定 (2026-11-02)：清單欄維持系統預設，不改成「訂單接近各半、開團約 1:2」；初始偏好視為被量測否定，AX5 的擁擠以欄內換行接受。
- 發現的缺陷 (使用者 2026-11-02 決定 1–3 併入本 change 修正，第 4 項不處理)：
  1. 分欄清單選取列文字對比不足：訂單選取列的姓名與金額變白字疊在淺藍底；開團選取卡片標題「四月韓國團」白字疊在白卡上完全看不見 (AX 階層仍有該 StaticText)；「更多」入口欄選取列有兩次為黑底深色字，另一次為藍底黑字，出現條件未定。
  2. `blReadableScrollContent` 用在 `List`／`Form` 時沒有加上前緣安全區：詳情欄延伸到左側欄底下 (前緣安全區 300 或 320)，量到的寬度已扣安全區 (880、860)，但 `contentMargins` 從容器原點起算，商品類別管理列為 120–1060、設定列為 100–1080、開團詳情列為 110–1070，卡片背景滑到左欄底下、內容未置中也未限寬。`ScrollView` 頁面 (匯率、報價、客戶) 不受影響。直向詳情欄 520 低於上限時不加邊距，不受影響。
  3. 報價頁 AX5：輸入列的標籤 (商品定價等) 被擠成一字寬直排並被裁切。
  4. (不處理) 根側邊欄標頭「BuyLedger」在 AX5 斷成三行。

## 任務4.4：Duo 半摺、VoiceOver 與減少動態效果 (2026-11-02，4.10–4.12 修正前的建置)

- 環境：iPhone Duo 模擬器 iOS 27.1 (`1666A373-A43C-4CF5-A468-ED8D513A3269`)，App 2.1.0 (413)，PID 73780 (與 4.3 重跑同一程序)，正體中文標準字級。VoiceOver 與減少動態效果以 Device Hub 右欄開關切換，操作以 Xcode DeviceInteraction (Closed) 與 Device Hub 點擊 (Open／Partial)。
- 半摺連續閱讀 (通過)：分析頁在 Open 捲到「類別排行」在頂端 → Partial 後閱讀位置與卡片順序不變，內容沒有整頁搬到另一半 → 摺回 Closed 仍在「類別排行」。
- 觀察 (未重現)：一次從 Closed 展開到 Open 時，根分頁列浮在左上角並蓋住標題「分析」的第一個字與期間選擇器左緣，點一下分頁後回到右側且標題完整；同序列重做一次為正常位置。Device Hub 剛從 iPad 切回 Duo 時發生，記為工具或系統暫態。
- VoiceOver (通過)：點一下聚焦、點兩下啟動。訂單分頁啟動後保留 Mika 017 詳情；返回鈕啟動後回到清單，清單沒有選取列殘留 (只有狀態膠囊「全部」與訂單分頁為 Selected)；選取 Joyce 015 開啟詳情；更多選單三項可啟動；編輯只開一份「編輯訂單」；客戶欄位取得 Keyboard Focused 並出現鍵盤；取消後回到 015 詳情。首次開啟 VoiceOver 時系統「旁白手勢」說明框先以「好」關閉。
- 減少動態效果 (通過)：返回、選取 017、更多 → 編輯 (單一表單) → 取消、返回清單都正常，清單 4 筆與徽章不變；開啟狀態下 Open → Closed 摺展無卡住。過程中一次誤點到「合併訂單」並以取消關閉，未執行合併。測後兩個開關都已關回。

## 任務4.10／4.11／4.12：實作與審查 (2026-11-02)

- 分工 (主對話分派)：4.10 claude-impl、4.11 codex-impl、4.12 gemini-impl 同時實作，派工前後全 repo 雜湊比對只動到 11 個範圍內檔案。交叉唯讀審查：codex-impl 審 4.10 與 4.12、claude-impl 審 4.11 (審查前後雜湊不變)；主對話同時自審。審查結論：codex-impl 對 4.10／4.12 判 Needs revision (P1 訂單快照沒有建立系統選取，重現不了白字；P2 輔助字級切換改變輸入框結構識別；P2 待量測 AX5 窄寬度輸入框與單位可能溢位)；claude-impl 對 4.11 提 P1 1 項、P2 4 項、P3 4 項。
- 第 1 版做法：
  - 4.10：依 Apple 文件 `BackgroundProminence.increased` 選取列要求單色前景，沒有明確前景色的文字會變白；訂單列 (`OrdersRegularListColumn.navigableRow` 包住 `OrderRowView`) 與開團團名 (`CampaignRow`) 指定 `.blLabel`；「更多」入口標題原本固定 `.blLabel`，在系統深色選取底上變成深字，改為不指定前景，交給系統選取樣式。新增兩條選取列 snapshot。
  - 4.11：`List`／`Form` 多載把左右安全區加進 `.scrollContent` 邊距，`ScrollView` 維持原算法；新增 List、Form 非對稱安全區渲染測試；`BLReadableContentType` 說明改為已實測確認；規則文件同步。
  - 4.12：`numberField` 在輔助字級改為標籤在上的堆疊；新增 AX5 snapshot；盤點其他輸入列，`OrderEditItemsSection.itemEditorRow` 的「Stepper + 單價標籤 + 最大寬 120 輸入框」橫列在 AX5 可能擁擠 (待主對話量測後決定是否納入)。
- 建置 (iPhone 12 與 iPhone 17 模擬器)：測試目標編譯失敗，`BLReadableScrollContentLayoutTests` 新增測試的 `#expect` 訊息以 `+` 串接成 `String`，不符 `Comment?` (8 處)。
- 審查採納 (主對話裁定)：
  - 4.11 P1：改成 `if let` 分支後，容器寬度跨越閱讀上限 (例如轉向) 時捲動容器的結構識別改變，內部焦點與狀態會被重建；改回不分支的寫法。
  - 4.11 P2：補對稱安全區的 List／Form 測試；既有分組清單與表單測試的 helper 回傳 `some View`，實際走 `View` 多載，改為具體型別；整檔行寬；規則文件寫明結構不變與多載選用條件。P3：Bool 模式改 enum。
  - 4.10 P1：訂單選取 snapshot 以 `selection: nil` 渲染，沒有原生選取，修正前也可能通過；改為真正選取。
  - 4.12 P2：字級切換時輸入框在兩個分支間被重建；AX5 時輸入框與單位同列在 393 pt 畫面可能超出卡片。改為共用子樹只切換排列，輸入框在輔助字級改可伸縮寬度。
- 修正輪 1 後建置與 RED (主對話)：
  - iPhone 17 iOS 26.5 模擬器 (淺色)：`SnapshotOrdersTests`、`SnapshotCampaignsTests`、`SnapshotToolsTests`、`SnapshotMoreTests`、`SnapshotLookupsTests`、`ToolReadableWidthGuardTests` 29 通過／3 失敗，3 條為新測試第一次執行自動錄製基準；既有基準全部未變。三張新基準目視：訂單選取列淺藍底黑字、開團團名黑字、報價 AX5 標籤在上且輸入框隨單位伸縮未溢出。
  - RED：拿掉兩處 `.foregroundStyle(.blLabel)` 並把 `QuoteInputsCard` 換回 index 版後重跑，報價 AX5 失敗 (有效)；訂單與開團選取列兩條仍通過，離屏渲染不產生 iPad 的選取強調前景，守不住缺陷。還原後雜湊與修正版一致。
  - iPhone 12 實機：4.11 新增的 4 條 List／Form 安全區渲染測試失敗。測試 host 以 `additionalSafeAreaInsets` 造的安全區，`List`／`Form` 會自己避開 (非對稱 minX 222、對稱左右間距 158／40)。
  - 真實環境以修正版實測，`List`／`Form` 不會自己避開安全區，修正版置中正確：iPad Air 11 iOS 27.0 橫向商品類別列 x=420–1060、寬 640；iPhone 17 iOS 27.0 橫向 874 開團詳情 cell x=117–757、寬 640。
  - 主對話裁定測試改法：4.10 兩條 snapshot 移除 (基準圖已刪)，改為 iPad regular 的 UI 測試，以選取列截圖檢查標題帶狀區有深色文字像素；4.11 刪除 4 條安全區渲染測試，邊距計算抽成純函式以字面值測，另以 iPad UI 測試量商品類別與設定的列寬與置中；單元測試 host 的安全區差異寫入 `ios-unit-tests.md`。
- 修正輪 2 後 (主對話)：iPhone 12 閱讀寬度單元測試 30/30 通過 (含 3 條邊距純函式字面值測試)。iPad Air 11 iOS 27.0 模擬器：`SplitSelectionReadabilityUITests` 2 條、`ReadableWidthUITests` 的兩條選取列測試通過；`testMoreReadableWidth` 失敗，原因是測試啟動後根側邊欄展開，詳情欄只剩 600 pt 低於上限，列寬 560、左右各 20 屬正確的填滿置中，測試前提未控制根導覽樣式。
- 4.10 RED 不成立：拿掉兩處 `.foregroundStyle(.blLabel)` 後 `SplitSelectionReadabilityUITests` 仍 2/2 通過。對照證據，白字只在 iPad 有硬體鍵盤焦點時 (選取列有藍色焦點框) 出現：先前手動實測有焦點框，4.3 時 Duo 關閉模擬硬體鍵盤後選取列為黑字；UI 測試執行後模擬器沒有焦點框。修正版在 Device Hub 取得鍵盤焦點時，訂單姓名與金額、開團團名皆為黑字，「更多」選取列為藍底深色字。
- 主對話裁定：離屏 snapshot 與 XCUITest 都沒有鍵盤焦點，4.10 的兩個新 UI 測試與 snapshot 守不住缺陷，全部刪除；不在測試中送硬體按鍵模擬焦點，以免改變同一模擬器上 `KeyboardDismissTests` 依賴的軟體鍵盤前提。驗收改以焦點狀態下的 UI Automation 截圖 (修正前後)，陷阱寫入 `ios-design-system.md`。`ReadableWidthUITests` 刪除重複的選取列測試，寬度測試先把根導覽切成分頁列再量測。

## 任務4.4：修正版的 AX5 檢查與新發現 (2026-11-02)

- 報價 AX5 (4.12 修正版)：iPad Air 11 iOS 27.0 橫向標籤完整在上、輸入框伸縮、單位完整；iPhone 17 iOS 27.0 (402 寬) 輸入框 32–267、單位 KRW 275–370、「TWD/件」214–370，都在卡片內。iPhone 17 iOS 26.5 模擬器在 AX5 啟動後 `snapshot-ui` 只回傳 1 個元素、MobileBuildMCP 點擊只接受元素參照，無法操作，改用 iOS 27.0 的 iPhone 17 (Xcode 擷取可用座標)。
- 「更多」入口欄在 AX5 選取「報價試算」為淺藍底深色字，可讀。
- 新發現 (使用者 2026-11-02 決定併入本 change，新增 4.13、4.14)：
  - 訂單詳情標頭在 Duo AX5 不換行：Closed (466 寬) 的「日圓」在 x=355.7–439.0，蓋到更多選單鈕 (396.3–434.0) 並進入右側分頁列；「訂單來源」卡片被撐到右側分頁列底下；Open 詳情欄同樣延伸到右側系統列。標準字級同一列只到 x=166。
  - 總覽 hero 目標進度在 AX5 窄寬度把「$80,000」斷成「$80,00」與「0」兩行：iPhone 17 iOS 26.5 (截圖)、Duo Closed。
- 4.12 盤點的訂單編輯商品列：iPhone 17 AX5 新增訂單表單開啟後客戶欄自動聚焦，鍵盤與輸入法候選擋住，捲不到商品列，尚未量測；使用者決定先量測再決定是否處理。

## 任務4.10–4.15：RED、風格閘門與新增任務 (2026-11-02)

- 4.11 RED (iPad Air 11 iOS 27.0 模擬器)：`ReadableWidthUITests.testMoreReadableWidth_商品類別與設定_限寬並置中` 在修正版通過 (根導覽切成分頁列後量測)；把 `BLReadableScrollContentLayout` 換回 index 版後失敗，商品類別列寬 940、左間距 −180 (原缺陷)，還原後雜湊一致。
- 4.12 RED：報價 AX5 snapshot 在 index 版 `QuoteInputsCard` 失敗 (見前段)。iPhone 17 iOS 27.0 AX5 實測修正版報價輸入列都在卡片內。
- 4.10：以修正前後的鍵盤焦點狀態實測為驗收依據 (修正前選取列白字，修正後黑字，見上段)；自動化測試無法重現，規則寫入 `ios-design-system.md`。
- 風格閘門 (haiku-max-implementer，唯讀，Swift 10 檔整檔、規則 2 條目)：違規 24 項 (全為 Swift)，待裁決 6 項。主對話裁決：R1 `defaultMinListRowHeight` 環境值歸版面組；R2 View／List／Form 擴充以修飾函式名稱作 MARK (比照 `// MARK: - blCardShadow`)；R3 99 字元的元組回傳改單行；R4 測試名內的 `nil` 屬識別字保留英文；R5 規則條目主次分層；R6 `CampaignFormatters.twd` 屬格式化過渡例外不處理；`MoreView` Label 樣式觀察比照 O1 不處理。修正由 claude-impl 進行。
- 4.13 (codex-impl)、4.14 (gemini-impl) 實作完成：兩者都以 `AnyLayout` 在輔助字級改為堆疊，標準字級排列與間距不變；各新增一條 393 寬 AX5 snapshot。交叉唯讀審查：gemini-impl 審 4.13、codex-impl 審 4.14。
- 4.15：主對話以 iPhone 17 iOS 27.0 AX5 量測訂單編輯商品列，「數量 1」標籤 x=32、寬 153 的 Stepper 內被擠成每行一字，「單價」標籤寬 41.7 兩行直排，未裁切；使用者決定併入本 change。
- 風格修正 (claude-impl) 後模擬器守門與全部 snapshot (iPhone 17 iOS 26.5，淺色，33 類)：161 通過／2 失敗，2 條為 4.13、4.14 新測試第一次錄製基準；既有基準全部未變 (含 4.12 報價 AX5)，所有守門通過。風格修正只動閘門列出的 9 檔與規則條目，審查者 (gemini-impl 審 4.13、codex-impl 審 4.14) 前後雜湊不變；兩份審查皆無 P1／P2 (4.14 有兩行註解超過 100 字元，併入 4.13–4.15 的風格閘門)。
- 4.14：基準為進度條在上、「14% / $80,000」完整一行；RED 把 `DashboardHeroCard` 換回 index 版後 AX5 那條失敗、6 條既有標準字級基準通過，還原後雜湊一致。
- 4.13：基準顯示標頭已堆疊、「4/24・日圓」在畫面內，但「訂單來源」與「獲利」卡片右緣仍超出畫面，撐寬詳情內容的是標頭以外的子 View。主對話裁定 4.13 再修一輪 (codex-impl)：找出最小寬度超過提議寬度的子 View 並修正，snapshot 改拍 393×1800。4.15 改派 gemini-impl 實作。
- 4.13 第二輪：codex-impl 把 snapshot 改為 393×1800 並改名 `orderDetailView_393點寬最大輔助字級_標頭與卡片留在畫面內`；盤點子 View 後判斷元兇是 `BLDonutChart` 的直徑以 `@ScaledMetric` 從 150 放大且無寬度上限，該元件不在可改範圍，未改 production 即停下回報。主對話錄製長頁面基準證實：AX5 時「成本拆解」圓餅圖直徑大於畫面寬，撐寬整個詳情的卡片。主對話裁定把 `BLDonutChart` 與 `OrderDetailCostView` 納入 4.13 範圍 (分析頁 `InsightsCostStructureCard` 用同一元件，一併檢查)，派 codex-impl 第三輪；錯誤狀態的長頁面基準待修正後刪除重錄。
- 4.15 (gemini-impl)：以 `AnyLayout` 切換商品列排列並新增 393 寬 AX5 區段 snapshot；但移除了 Stepper 與單價之間的 `Spacer()`、改讓 Stepper 撐滿寬度，既有 `orderEditItemsSection_一般既有訂單_符合基準圖` 因此失敗。主對話裁定恢復 `Spacer()`，標準字級與 index 版等價。
- 4.13 第三輪 (codex-impl)：`BLDonutChart` 以 `@ScaledMetric` 直徑為上限，改用 `aspectRatio(1, contentMode: .fit)` 加 `frame(maxWidth:maxHeight:)` 在可用寬度內縮小；以 `AnyLayout` 在輔助字級把中心文字移到圖下方 (標準字級維持 `ZStackLayout`)；`SnapshotInsightsTests` 新增 393×1800 AX5 案例。主對話修正兩處：`donutContent` 多敘述缺 `return` 的編譯錯誤，以及新增的 `.multilineTextAlignment(.center)` 讓標準字級中心金額「$6,500」的逗號字距改變 (5 張既有基準不符：分析頁 3、訂單詳情成本、訂單推入詳情；差異只在中心約 23×30 pt、最大通道差 251)。以暫時拿掉該行實驗確認成因 (該基準即通過)，改為只在輔助字級置中。
- 4.15 修正 (gemini-impl)：恢復 `Spacer()`，標準字級與 index 版等價。
- 圓餅圖對齊修正後，模擬器守門與全部 snapshot 兩輪 165/165 通過：既有基準零差異；新錄 AX5 基準三張經目視確認 (訂單詳情長頁卡片右緣在畫面內、分析頁圓餅圖在卡片內、商品列「數量 1」與「單價 95000」各一列)。
- RED (4.13、4.15)：把 `BLDonutChart`、`OrderDetailContentView`、`OrderEditItemsSection` 換回 index 版後，三條 AX5 snapshot 全部失敗，還原後雜湊一致。
- 觀察 (非缺陷)：商品列 AX5 snapshot 中名稱欄第三行只畫出一半；iPhone 17 iOS 27.0 AX5 實測輸入長名稱，欄位以 3 行上限加內部捲動呈現，欄位 (y=399–540) 與數量列 (y=594 起) 不重疊，判定為離屏渲染對多行輸入框高度的假象。
- 4.13 第三輪與 4.15 交叉審查 (claude-impl，唯讀，前後雜湊不變)：無 P1。主對話裁定：P2-1 採納 (商品列輔助字級堆疊後數量列與單價列間多約 60–70 pt，查明並消除，不增刪子 View)；P2-2 只改註解 (實驗與 165/165 回歸證實 `.leading` 即預設，標準字級不變；註解「字距」說法錯誤)；P2-3 採納 (AX5 全頁快照沒拍到成本卡下半部，改為成本結構卡與訂單詳情成本卡的元件快照)；P2-5 實測非缺陷，快照改用短名稱商品避免離屏假象；P3-2 既有常數不處理。
- P2-4 新發現 (使用者 2026-11-02 決定併入本 change，新增 4.16)：分析頁 393 寬 AX5 的 12 個月走勢圖 x 軸月份標籤全部重疊無法閱讀、類別排行金額「$6,915」斷成「$6,91」與「5」(4.13 的分析頁 AX5 基準圖)。
- 風格閘門 4.13–4.15 (haiku-max-implementer，唯讀，8 檔整檔 1,671 行)：硬性違規 11 項 (`OrderDetailContentView` 4、`OrderEditItemsSection` 4、`BLDonutChart` 1、`SnapshotOrderDetailTests` 2)，低嚴重度 7 處 (computed 屬性 doc 非名詞片語)，待裁決 6 項；codex-impl 先前指出的兩行「超過 100 字元」以 Python `len` 計為 47 與 59 字元 (113、151 是 UTF-8 位元組數)，不成立。主對話裁決：11 項與 L-1 全部採納；R1 `guard` 條件內的 `max(by:)` 屬語法限制不改；R2 多行基底後的 modifier 縮排、R3 `.environment` 與 `.frame` 順序屬規則模稜兩可且現有測試檔一致，本次不改；R4、R6 不改。附帶觀察 `BLDonutChart` 的 `locale: Locale = .current` 預設參數屬既有程式，列為後續。
- 合併派工 (主對話分派，檔案不重疊)：codex-impl 4.13 檔案 (審查 P2-2、P2-3 與閘門違規)、gemini-impl 4.15 檔案 (審查 P2-1、P2-5 與閘門違規)、claude-impl 4.16 (`BLBarChart`、`InsightsCategoryCard`) 並統一改 `SnapshotInsightsTests` (整頁 AX5 測試改為成本結構卡、走勢卡、類別卡三個元件快照)。
- 4.16 實作 (claude-impl)：`BLBarChart` 的軸標抽樣改依 `@ScaledMetric` 放大後的最小標籤間距 (`Layout` 改 internal 供測試)，新增 `BLBarChartLayoutTests` 4 條字面值測試；`InsightsCategoryCard.categoryRow` 在輔助字級以修飾值讓金額維持單行並優先取得寬度 (`fixedSize(horizontal:)`、`layoutPriority`)，名稱負責換行 (claude-impl 選擇，未採名稱與金額分列的堆疊)；`SnapshotInsightsTests` 刪除 4.13 的整頁 AX5 測試，改為成本結構卡、走勢卡、類別卡三個 393 寬 AX5 元件快照。同輪 codex-impl 完成 4.13 審查與閘門修正 (含 `OrderDetailCostView` 元件快照)、gemini-impl 完成 4.15 (輔助字級時 `Spacer` 高度為 0 消除 60–70 pt 空白、AX5 快照改用 `BL-2604-017`)；派工前後雜湊只動到各自範圍。
- 建置：新測試檔 `BLBarChartLayoutTests` 缺 import，`CGFloat` 整數字面值初始化不可用 (`MemberImportVisibility`)，模擬器與 iPhone 12 都編譯失敗。
- 4.16 交叉審查 (codex-impl，唯讀，前後雜湊不變)：無 P1；P2 走勢快照用「1 月～12 月」短標籤，正式 12 個月資料為 `yy/MM`，改用正式格式 (採納)；另一 P2 為驗收尚未執行。
- 最終風格閘門 (haiku-max-implementer，9 檔)：上一輪 14 項全部修好；本輪 12 條。主對話裁決：單一參數 closure 本體沒用到參數時 Swift 語法要求 `_ in`，A-3 與 B-2 共 7 處不算違規；A-2 呼叫者在前採納；A-6 Preview 假資料補空格、B-1「有無」改「是否」採納。最後一輪修正派給 claude-impl (4.16 檔案與 import) 與 codex-impl (B-1)。
- 最後一輪修正後 (claude-impl 補 `import Foundation`、走勢快照改 `yy/MM`、閘門違規；codex-impl B-1)：iPhone 12 單元 34/34 通過 (含 `BLBarChartLayoutTests` 4 條)；模擬器第一輪錄製 5 張新基準，第二輪 167 通過／1 失敗。
  - 失敗為標準字級 `orderEditItemsSection_一般既有訂單_符合基準圖`：「數量 1」標籤消失、Stepper 移到最左 (差異像素 202,158)。成因是 4.15 把 `Spacer()` 包上 `.frame(height: isAX ? 0 : nil)`，被包住的 `Spacer` 在 `HStack` 中搶走空間。主對話裁定改為 `Spacer()` 不加修飾、排列容器加 `.fixedSize(horizontal: false, vertical: isAccessibilitySize)`。
  - 目視新基準：分析頁類別卡金額完整、成本結構卡圓餅圖在卡內且中心文字在圖下方、訂單詳情成本卡完整；走勢卡標籤不再重疊，但第一個「25/08」被左緣裁成「08」、最後一個截成「…」，4.16 再修一輪 (claude-impl)。
- 第二次回歸修正後 (gemini-impl：`Spacer()` 不加修飾、排列容器加 `.fixedSize(horizontal: false, vertical: isAccessibilitySize)`；claude-impl：AX 時 `AxisMarks(preset: .aligned)` 與首尾保留寬度)：標準字級商品列基準恢復通過，模擬器第二輪 167／168，iPhone 12 單元 34/34。商品列 AX5 新畫面目視正確 (數量與單價各一列、無多餘空白)，舊基準刪除重錄。走勢卡 AX5 只剩兩個標籤，「25/05」被左緣裁成「5/05」、「26/04」被裁成「26/0」，`.aligned` 未達效果 (claude-impl 查 Context7 時遇網路錯誤 `getaddrinfo ENOTFOUND mcp-proxy.anthropic.com`，文件只查到宣告)；派 claude-impl 再修，先查清裁切來自哪一層。
- 走勢軸標第三版 (claude-impl：移除無效的 `.aligned`，輔助字級時標籤間距加倍、首尾標籤依 `AxisValue.index`／`count` 靠內側對齊；主對話把錨點由 `.leading`／`.trailing` 改為 `.topLeading`／`.topTrailing`，前者讓首尾標籤垂直置中疊在長條上)：模擬器守門與全部 snapshot 第二輪 168/168，iPhone 12 單元 35/35 (含 `BLBarChartLayoutTests` 5 條)；走勢卡 AX5 基準目視「25/05」「26/04」完整顯示在長條下方。
- 4.16 RED：使用者已在 review 中 stage 本輪多數檔案 (含 4.16)，index 版等於修正後，第一次以 index 版做 RED 兩條皆通過、不具意義；依「不動 index」改以 HEAD 版 (4.16 前這兩檔未被本 change 修改) 並暫時移開依賴新 API 的 `BLBarChartLayoutTests`，走勢卡與類別卡 AX5 快照皆失敗，還原後兩檔仍為已 stage 且無未 stage 差異。先前 4.11–4.15 的 RED 執行時相關檔尚未 stage，結果有效。
- 4.16 補充 (主對話接受 claude-impl 的做法)：輔助字級時走勢圖內容寬度等於可用寬度，不再水平捲動，12 個月只顯示首尾兩個軸標；理由是捲動視窗邊緣會裁掉首尾標籤。代價是長條變細，標準字級的捲動與標籤數不變。

## 任務4.10–4.16：完整單元、守門與 snapshot 回歸 (2026-11-02)

- iPhone 12 實機完整單元測試 (排除讀原始碼的守門與 snapshot 共 42 類)：1735 通過／0 失敗。
- iPhone 17 iOS 26.5 模擬器 (淺色) 同 42 類：196 通過／0 失敗。
- 回歸後主對話修正 `BLBarChart` 兩處註解 (`labelSpacing` 說明移除不屬於它的首尾對齊、`axisLabelAnchor(for:)` 改動詞開頭)，只動註解。

## 任務4.12–4.16：iPhone 17 iOS 26.5 模擬器 AX5 截圖 (2026-11-02)

- 環境：`CBE3AABB-FFBF-4F91-AFF9-5DD283DDB410`，`campaignsWithOrders`、正體中文、`UICTContentSizeCategoryAccessibilityXXXL`；這次 `snapshot-ui` 正常回傳可及性樹 (164 個元素)，以元素參照操作。
- 4.14 總覽 hero：進度條在上，「12% / $80,000」完整一行。
- 4.16 分析：走勢軸標「25/05」「26/04」完整、不重疊，在長條下方；類別排行金額「$6,915」「$2,505」單行，名稱換行 (「美妝」斷在兩字之間，屬中文正常斷行)。
- 4.15 訂單編輯 (BL-2604-017 編輯表單)：商品名稱換行，「數量 1」與 Stepper 一列、「單價 18700」一列，標籤完整。
- 4.12 報價：標籤在上，輸入框與「KRW」同列在卡片內。

## 任務4.4：Duo 英文、連續縮放與 Open (2026-11-02，4.10–4.16 修正版)

- 環境：iPhone Duo iOS 27.1 (`1666A373-A43C-4CF5-A468-ED8D513A3269`)，`campaignsWithOrders`、英文 (`-BLUITestLanguage english`)、標準字級。Closed 以 Xcode DeviceInteraction 擷取階層。Duo 有內外兩個顯示器：Xcode 擷取只拍外螢幕，`mobilebuildmcp ui-automation screenshot` 因無法選顯示器而失敗 (CLI 沒有 `--display`)，Open 與縮放畫面改以 macOS `screencapture` 截 Device Hub 畫布，Open 另存 `snapshot-ui`。
- 英文 Closed 466×678 (通過)：總覽內容右緣 366，目標進度「12% / NT$80,000」一行；訂單清單與 Mika 017 詳情內容右緣 350，工具列與分頁列在 396 之後；分析、更多入口、報價都在內容區內，報價長標籤 (International Shipping、Payment Processing Fee) 換兩行完整。分頁徽章的可及性值「4個項目」由系統依裝置語言產生，不隨 App 內語言切換。
- 連續縮放 (Device Hub「Enter Resize Mode」拖曳右側把手，通過)：
  - 466 → 740×555：「更多」改為入口欄加報價的分欄，底部浮動分頁列；訂單改分欄，保留 Mika 017 詳情。
  - 740 → 416×667：訂單收合為推入詳情，仍是 017，返回鈕在。
  - 416 → 1280×667：訂單分欄，017 選取列保留，詳情內容限寬置中。
  - 以 Device 選單「Exit Resize Mode」回到 Closed，仍為 017 詳情。
  - 工具暫態：第一次拉到 1097×678 時 (同時有實機測試建置)，畫面停在模糊的過渡狀態 3 分鐘；退出縮放後切 Open 也停在過渡畫面 13 分鐘，但 App 階層正常 (951×669 分欄、017 詳情)，摺回 Closed 再展開即恢復。判為 Device Hub 畫面合成的暫態，不是 App 無回應。
- 英文 Open 951×669 (通過)：清單欄標題「Orders」完整，017 選取保留，詳情與工具列在右側系統列左側。
- 發現：英文時，縮放後的分欄清單欄 (約 320 pt) 的 inline 標題被擠成「…」(740 寬) 或「Orde…」(1280 寬)。原因是 Duo 的清單欄比 iPad 多一顆系統分欄切換鈕；iPad 英文清單欄 320 pt 標題完整，Duo Open 清單欄較寬也完整，中文「訂單」 未截斷。使用者 2026-11-02 決定不處理，記為已知限制。
- 限制：
  - Duo 左右 Split View：模擬器沒有並排兩個 App 的入口；以連續縮放的 416、740 寬涵蓋窄視窗版面，未驗證真實並排。
  - iPad 連續縮放：iPad Air 11 的 Device 選單「Enter Resize Mode」為灰色；改成「視窗 App」多工模式會讓 `snapshot-ui` 取不到可及性樹 (apps/ios/CLAUDE.md)，因此未在 iPad 驗證，以 iPad 直向、橫向、根側邊欄展開與收起的固定寬度量測 (本節前段) 加 Duo 連續縮放涵蓋。

## 任務4.13／4.14：修正版的 Duo AX5 重量與新發現 (2026-11-02)

- 環境：iPhone Duo iOS 27.1，`campaignsWithOrders`、正體中文、AX5 (`UICTContentSizeCategoryAccessibilityXXXL`，內文約 310%)；Closed 以 Xcode DeviceInteraction 階層量測，Open 以 Device Hub 畫布截圖。
- 4.14 Duo Closed (通過)：hero 目標進度「12% / $80,000」為單一文字元素，x 31.7–330.4，在右側分頁列 (x 396 起) 之前，未在數字中間斷行。
- 4.13 Duo Closed (通過)：訂單 BL-2604-017 詳情標頭改為堆疊，「已下單」膠囊一列、「4/24・日圓」一列；可見文字右緣最大 292.3，卡片右緣約 366，工具列與分頁列在 396 之後。
- 4.13 Duo Open (通過)：詳情欄標頭同樣堆疊，卡片在右側系統列左側。
- 新發現：成本拆解圖例「$3,936」斷成「$3,93」與「6」、商品明細「¥18,700」斷成「¥18,7」與「00」，Duo Closed、Duo Open 與 iPhone 17 iOS 26.5 (402 寬) 都重現。4.13 的 393 寬成本卡元件快照沒有頁面左右邊距，整頁 393×1800 快照拍不到圖例與商品明細，因此未抓到。使用者 2026-11-02 決定併入本 change，新增 4.17 (claude-impl 實作、codex-impl 審查，主對話分派)。
- 4.17 實作 (claude-impl)：兩處金額 Text 在輔助字級加 `fixedSize(horizontal:)` 與 `layoutPriority`，新增 `SnapshotOrderDetailTests.orderDetailSections_頁面內容寬361最大輔助字級_成本圖例與商品金額不斷字`；派工前後雜湊只動到三個範圍內檔案。模擬器守門與全部 snapshot 196 通過／1 失敗，失敗為新測試第一次錄製基準，既有標準字級與 AX5 基準全部不變。
- 4.17 審查 (codex-impl，唯讀，前後雜湊不變)：無 P1。P2-1：`fixedSize` 讓金額維持單行，但金額本身寬於卡片時會超出並被 `BLCard` 的 `clipShape` 裁切，4.16 類別排行同型；主對話估算 AX5 商品明細「₩1,234,567」約 294 pt，iPhone 卡片內寬約 329 pt、Duo Open 更窄。使用者 2026-11-02 決定 4.17 與 4.16 都改為輔助字級時名稱與金額上下排列 (以 `AnyLayout` 切換)，再派 claude-impl。P2-2 為 RED 與基準尚未驗證，改版後一併執行。
- 4.17 第二版與 4.16 改版 (claude-impl)：三個 View 以 `AnyLayout` 在標準字級橫排、輔助字級上下排列 (色點與名稱、名次標題各為第一個子 View，金額 (類別卡含 chevron) 為最後一個子 View)，移除 `fixedSize`／`layoutPriority`；新增 `orderDetailSections_頁面內容寬361最大輔助字級_大額金額完整不裁切` (韓元 12,345,678)。主對話把三個 `@Environment(\.dynamicTypeSize)` 的過時說明改為「上下排列」。派工前後雜湊只動到四個範圍內檔案。
- 模擬器守門與全部 snapshot：194 通過／4 失敗，3 條為新錄基準 (兩條 361 寬、類別卡；舊基準已刪除)，1 條為 `orderDetailCostView_393點寬最大輔助字級_成本卡圓餅圖與中心文字在卡片內` 只在圖例區不符 (y 1966–2819 px，圓餅圖與中心文字不變)，屬預期的上下排列；所有標準字級基準不變。
- 複審 (codex-impl，唯讀，前後雜湊不變)：無 P1／P2；P3-1 大額快照的 `LedgerOrderItem` 未固定 `id` (採納)。
- 主對話目視新基準後裁定小修：上下排列時名稱到自己金額的距離 (8 + `Spacer` 8 + 8) 大於圖例列間距 12，金額看起來屬於下一項，三個 `VStackLayout` 間距改 0；類別卡快照高度 560 切掉第 3 列進度條，加高；大額快照商品固定 `UUID(0)`。觀察 (不處理)：大額測試中圓餅圖中心的總成本「$12,345,753」在 361 寬 AX5 斷成「$」與數字兩行，數字本身不斷，屬極端金額。
- 小修後 (claude-impl：三個 `VStackLayout` 間距 0、類別卡快照高 580、大額快照 `UUID(0)`；派工前後雜湊只動到五個範圍內檔案)：刪除 4 張受影響的 AX5 基準 後錄製輪 194 通過／4 新錄，驗證輪 198/198 通過。新基準目視：名稱與自己的金額相鄰，類別卡三列與卡片下緣完整入鏡，361 寬「$3,936」「¥18,700」與大額「$12,345,678」「₩12,345,678」完整。
- 4.16／4.17 RED：把 `OrderDetailCostView`、`OrderDetailItemsView`、`InsightsCategoryCard` 換成 HEAD 版 (本 change 修改前；`InsightsCategoryCard` 的 index 為使用者已 stage 的 4.16 版，故不用 index) 後跑 `SnapshotOrderDetailTests`、`SnapshotInsightsTests`：4 條 AX5 快照失敗 (兩條 361 寬、類別卡、成本卡 393 寬)，其餘 10 條通過；還原後三檔雜湊與修正版一致，index 未動。
- AX5 實機畫面確認 (修正版 build-and-run，build 號維持 413)：iPhone 17 iOS 26.5 的分析類別排行「1. 美妝」一行、「$6,915 >」下一列；訂單 017 圖例「$3,936」「$75」與商品「¥18,700」都在名稱下一列且完整。Duo Closed 階層：「$3,936」「$75」「¥18,700」皆為單列文字 (高 52.7／58.7)，右緣最大 231，在分頁列 396 之前；Duo Open 詳情欄同樣上下排列且完整，017 跨姿勢保留。
- 工具雜訊：Duo Open 時 `ui-automation swipe` 與 Device Hub 拖曳都捲不動 AX5 訂單清單，改在 Closed 以 Xcode DeviceInteraction 選取再展開；Mac 螢幕兩次閒置休眠，以 `caffeinate -u` 喚醒、`caffeinate -d -t 1800` 暫時防止休眠 (未改系統設定)。
- 使用者 2026-11-02 指示：依序完成剩餘任務；之後若因放大字級需要調整版面，由主對話依綜合條件選擇最適合的修正方案並直接修正 (決策紀錄寫「主對話依使用者授權選定」)。

## 放大字級版面調整紀錄 (主對話依使用者 2026-11-02 授權選定)

使用者要求每一項都記錄「遇到什麼問題、採取什麼方案」。授權之後由主對話選定的調整逐列記在下表；授權前已由使用者決定的 4.10–4.17 不重複列入。

| 編號 | 畫面與情境 | 問題 | 採取方案 (與未採用的替代方案、理由) | 驗證與證據 |
| --- | --- | --- | --- | --- |
| (尚無) | | | | |

## 任務4.16／4.17：風格閘門 (2026-11-02)

- haiku-max-implementer (唯讀，7 檔 1474 行逐檔逐條)：違規 11 項 (21 處)，待裁決 6 項。
- 主對話裁決：採納 V1 (`BLBarChart` 屬性順序)、V2 (單一表達式改 `$0`)、V3 (`summary` 的 `locale: Locale = .current` 預設值移除，`BLDonutChart` 同型一併移除，取代 4.13 閘門「列為後續」)、V4–V7 (計算屬性 doc 改名詞片語)、V8 (`OrderDetailItemsView` Private Views 順序)、V10 (陣列每元素一行)、Q1 (Private Method 依全檔首次呼叫排序)；V9／V11 (`.environment` 與 `.frame` 順序) 沿用 R3 不改；Q2–Q6 不改 (Q2 `minBarWidth` 是既有常數，輔助字級時走勢圖不捲動；Q3 Card／Row／Descriptor 後綴屬既有命名慣例；Q4 類別列外層為 `Button`，已是單一朗讀元素；Q5 kit 未定義空本體 closure 寫法；Q6 `import Foundation` 是 4.16 建置失敗後補上的必要 import)。修正派 claude-impl。
- 修正 (claude-impl，派工前後雜湊只動到範圍內五檔)：已套用 V2、V3 (含 `BLDonutChart`)、V4–V8、V10、Q1。V1 撤回 (主對話裁定)：移動 `let data` 會改變合成 memberwise init 的參數順序，範圍外的 `InsightsTrendCard`、`SnapshotSharedTests` 會編譯失敗；屬性順序與合成 init 相依，不為排序改呼叫端。
- 風格修正後回歸：iPhone 12 實機完整單元測試 (排除 42 類守門與 snapshot) 1735/1735 通過；iPhone 17 iOS 26.5 模擬器同 42 類 198/198 通過。執行期間檔案雜湊不變。
- 文件同步 (主對話)：README 的專案結構只到目錄層級，`Tests/Navigation` 已含「版面檢查」、`BuyLedgerTests/Shared/` 已含鏡像，新測試檔不需列入，確認無 README 影響。新增硬規則與 gotcha：`.claude/rules/ios-accessibility-localization.md` 的「名稱 + Spacer + 金額」輔助字級上下排列 (不用 `fixedSize`、`VStackLayout` 內 `Spacer` 撐高的處理、置中對齊只在輔助字級設定)；`.claude/rules/ios-unit-tests.md` 的輔助字級元件快照要用頁面實際內容寬度；`apps/ios/CLAUDE.md` 的 Duo 雙顯示器擷取限制、Resize Mode 與 Open 捲動限制。

## 任務4.4：情境對應 (2026-11-02)

各格是本檔上方各段的實測結果；「UI 測試」指 `BuyLedgerUITests` 中的 `AdaptiveNavigationContinuityUITests` 等導覽類別，在最終 UI 回歸 (iPhone 17 iOS 26.5、iPad Air 11 iOS 27.0 模擬器) 執行。

| 情境 | iPad (直／橫、根側邊欄) | Duo (Closed／Open／Partial、連續縮放) | 最大輔助字級 (AX5) | 英文 | VoiceOver／減少動態效果 |
| --- | --- | --- | --- | --- | --- |
| N3 首次未選取、返回後不復活 | UI 測試 `testOrdersStartUnselected_…`、`testMoreStartsUnselected_…` | 4.3：Closed 返回清單後 Open 顯示「選擇訂單」；Open AX5 首次進入訂單顯示「選擇訂單」(主對話目視，未存檔) | 同左 (選取狀態不隨字級變動) | 未另測 (選取狀態不隨語言變動) | VO 返回後清單無選取殘留 |
| N6 草稿跨摺展 | UI 測試 `testDraftSurvivesRotation_…` | 4.3 r1／r2：新增訂單、開團編輯、報價、主檔改名／新增／付款方式 | 未另測 | 未另測 | VO 欄位聚焦與取消；減少動態效果下編輯只開一份 |
| L1 總覽四張 KPI 與分析順序 | 直向與橫向總覽；AX5 橫向總覽與分析 | Open 總覽；AX5 Closed 總覽 | iPhone 17 總覽 hero、分析走勢與類別排行；UI 測試 `testDashboardKPIMatchesAcrossSizes_…` | iPad 橫向總覽；Duo Closed 總覽與分析 | — |
| L2 系統保留區外可達 | UI 測試 `testSidebarReservedRegion_…` | 4.3 首輪 Closed 膠囊、重跑 Open 選單；英文 Closed 詳情；AX5 Closed 與 Open 標頭；左側系統列依使用者決定不驗 | Duo AX5 Closed 與 Open 金額列 | Duo Closed 清單與詳情、Open 詳情 | — |
| L3 並排／收合／側邊欄／半摺狀態保留 | 橫向有無根側邊欄、直向訂單；UI 測試 `testOrdersLayoutCombination_…`、`testCampaignAndMoreKeepTarget_…` (`testSelectionSurvivesLayoutChange_…` 在指定裝置都依版面略過，不算證據，見任務4.26) | 4.3 r2 L3 三輪；連續縮放 416／740／1280 保留 017 | Duo Open 保留 017 | Duo Open 保留 017 | VO 啟動後保留詳情 |
| L4 閱讀上限與可讀可達 | 閱讀上限 640／680／840；`ReadableWidthUITests`、UI 測試 `testReadableRegionCentered_…` | 半摺不搬捲動區；縮放後詳情限寬置中 | iPad、iPhone 17、Duo 的 AX5 實測 | iPad 與 Duo 英文實測 | 減少動態效果下摺展無卡住 |

- 未驗證情境 (工具限制，見本檔「Duo 英文、連續縮放與 Open」)：iPad 連續縮放 (Resize Mode 灰色、視窗 App 模式會讓 UI Automation 失效)；Duo 左右 Split View (模擬器無入口，以 416／740 縮放涵蓋窄視窗版面)；Duo 系統列在左側 (使用者 2026-11-01 決定不驗)。
- 未另測但判定不受影響：N3 在英文與 AX5 (選取狀態由 TCA path 決定，與語言、字級無關)；N6 在英文與 AX5 (草稿由 feature State 持有，4.8 已改)。
- 已知限制 (使用者決定不處理)：英文時 Duo 縮放寬度的分欄清單欄標題截斷；根側邊欄標頭「BuyLedger」在 AX5 斷字。

## 任務4.10–4.17：最終完整 UI 回歸 (2026-11-03，模擬器)

- 環境：依使用者 2026-11-02 指示實機 automation mode 逾時時改模擬器；iPhone 17 iOS 26.5 (`CBE3AABB-FFBF-4F91-AFF9-5DD283DDB410`)、iPad Air 11 (M4) iOS 27.0 (`F5BE3685-31EB-4586-B674-B9C48067EF25`)，`BuyLedgerUITests` 全部類別，略過 `LaunchPerformanceTests`。
- iPhone 17 iOS 26.5：143 通過／4 失敗／46 略過 (81 分鐘)。失敗：`KeyboardDismissTests.testTapNumericKeyboardDone` (`1230`)；`QuoteTests` 3 條 (`testTypePrincipal` 得 `$230`、`testContinueTyping` 得 `100`、`testKeyboardDismissal` 得 `10`)。
- iPad Air 11：172 通過／4 失敗／17 略過 (131 分鐘)。失敗：`KeyboardDismissTests.testTapNumericKeyboardDone` (`1230`)；`QuoteTests.testTypePrincipal` (`$230`)；`AdaptiveNavigationContinuityUITests.testDraftSurvivesRotation` 與 `CampaignFlowTests.testRotated` 超過 10 分鐘執行限制。
- 主對話判讀 (待查證)：`1230` 是使用者已裁定的已知問題；`QuoteTests` 症狀相同 (游標停在預設值 0 之前，多出一位數)，但 4.12 改過 `QuoteInputsCard` 且驗收要求 `QuoteTests` 在模擬器通過，須先排除 4.12 造成。兩條逾時皆為轉向加鍵盤，單獨重跑判定。
- 逾時重跑 (主對話)：iPad Air 11 單獨重跑 `testDraftSurvivesRotation` 與 `testRotated` 2/2 通過，實際執行約 6 分鐘。同時另一個 Claude session (8b3af009) 以 `recheck.sh` 跑相同兩條也 2/2 通過。判定完整回歸中的逾時為長時間連續執行的環境狀態，不是產品或測試缺陷。
- `QuoteTests` 查證進行中：另一 Claude session (8b3af009) 的 `recheck.sh` 在 iPhone 12 實機因裝置鎖定等待至 07:08 後，依使用者指示停止 (該 session 另已確認不再佔用裝置、不再改本 change 的檔案)；使用者解鎖 iPhone 12 後由本 session 接手。以暫存副本把 `QuoteInputsCard` 換回 HEAD 版，在 iPhone 17 iOS 26.5 模擬器跑 `QuoteTests`，不動工作目錄；之後以目前程式碼在 iPhone 12 跑 `QuoteTests`、`KeyboardDismissTests`。
- `QuoteTests` 比對 (暫存副本，只把 `QuoteInputsCard` 換回 HEAD 版，iPhone 17 iOS 26.5 模擬器)：2 通過／2 失敗，`testTypePrincipal` 得 `$230`、`testKeyboardDismissal` 得 `10`，與修正版相同症狀。多一位數不是 4.12 造成。`testContinueTyping` 在此輪通過，修正版完整回歸失敗，待修正版單獨重跑對照。
- iPhone 12 iOS 26.7.2 實機以目前程式碼跑 `QuoteTests`、`KeyboardDismissTests`：6/6 通過。多一位數只在模擬器出現。
- 修正版 `QuoteTests` 單獨重跑 (iPhone 17 iOS 26.5 模擬器)：第一批兩輪因「轉向後 App 視窗寬仍未大於高」失敗 (依 `ios-ui-tests.md` 判為模擬器長時間連續執行的環境狀態)，以結束 Device Hub 重開模擬器後恢復。重開後第 1 輪 `testKeyboardDismissal` (`10`)、`testTypePrincipal` (`$230`) 失敗，第 2 輪 `testContinueTyping` (`100`)、`testTypePrincipal` (`$230`) 失敗。同一份程式碼兩輪失敗項目不同，修改前版本也有相同症狀，判定 `testContinueTyping` 的差異為偶發。
- 結論 (主對話裁定)：`QuoteTests` 在模擬器的多一位數與 `KeyboardDismissTests` 的 `1230` 同為「游標停在預設值 0 之前」，不是 4.12 造成，歸入使用者已裁定留給「數字欄位聚焦全選」change 的已知問題；此已知問題在模擬器穩定可見，實機 iPhone 12 通過。完整回歸其餘失敗皆已排除，指定類別 `OrdersNavigationSmokeTests`、`AdaptiveNavigationContinuityUITests`、`OrderCreateTests`、`InsightsTests`、`LookupManagementTests`、`ReadableWidthUITests` 在兩台模擬器都有執行且無產品失敗 (`ReadableWidthUITests` 在 iPhone 依版面略過)。
- 4.11 補量：iPad Air 11 iOS 27.0 橫向、根側邊欄收起，開團詳情 cell x=430–1070、寬 640，於詳情欄 320–1180 內置中。側邊欄展開時詳情欄 600–1180 低於上限，cell 620–1160 填滿置中。商品類別 640、設定 680 見 `ReadableWidthUITests`。

## 任務4.18–4.20：verify 後修正 (2026-11-03)

- 決策來源：使用者決定 (回覆 `/spectra-verify`)：開團高亮與跨日篩選併入本 change 修；`QuoteTests` 模擬器多一位數併入 `1230` 已知問題，由 parked change `input-focus-selection` 承接；補情境測試並用模擬器跑回歸，不跑實機。主對話查證：開團高亮由程式碼與截圖確認；跨日篩選由讀碼確認，未實際重現。
- 分工調整 (主對話)：本 session 不在 herdr 內，`claude-impl`、`codex-impl`、`gemini-impl` 不可用。4.18、4.20 由 haiku-max-implementer 子代理實作，4.19 由主對話實作。另一個 Claude session (8b3af009) 已確認停止本 change 的工作。
- 4.18：`CampaignSectionList.rowContent` 依 `selection` 在選取時畫 `.blAccent.opacity(0.12)` 圓角底，內縮 `BLSpacing.extraSmall` 讓角落不超出卡片圓角 (子代理選擇，主對話目視基準圖接受)；加 `.isSelected` 特徵。新快照 `campaignListView_選取其中一筆開團_符合基準圖`。
- 4.19：主對話實作時發現兩個實作細節並寫入 design：`applyFilterNavigation` 內部原本呼叫 `refreshDateContext`，改為直接刷新清單脈絡，維持先套新篩選再檢查；`refreshDateContext` 只清除因這次刷新才被排除的詳情，刷新前已被排除的 (改狀態到篩選外，既有測試 `writes_詳情改成篩選外狀態_保留path並更新內容` 鎖定此行為) 維持原樣，否則每次回到前景都會清掉。新測試 `OrdersFeatureDateRefreshTests` 5 條。
- 4.20：子代理新增 `BottomBarPlacementScanTests`、`NavigationScenarioUITests` 5 條。`Isolated content` 原計畫的快照實測不可行：完整 `OrdersView` 在 393 寬以 `.image`、`drawHierarchyInKeyWindow`、`.wait` 三種方式都錄成整張白圖，主對話裁定刪除該快照與白圖，改把判斷抽成 `OrdersView.usesRegularList(horizontalSizeClass:)`，以 `OrdersViewLayoutTests` 3 條字面值測試涵蓋；單欄清單畫面由既有 `OrdersCompactView` 快照涵蓋，收合版返回由既有 UI 測試涵蓋。陷阱寫入 `.claude/rules/ios-unit-tests.md`。
- 單元、守門與快照 (iPhone 17 iOS 26.5 模擬器，新增與受影響 5 類)：23/23 通過。
- RED 與變異：把 `CampaignSectionList`、`OrdersFeature` 換成 index 版 (修正前)，並在 production 暫時加入 `.bottomBar` 後，10 通過／3 失敗：`bottomBarPlacement_生產碼_不出現bottomBar` (命中 1 處)、`refreshDateContext_本月篩選跨到下月_清空目前詳情`、`campaignListView_選取其中一筆開團_符合基準圖`；還原後三檔雜湊一致，index 未動。
- 風格閘門 4.18–4.20 (haiku-max-implementer，唯讀，8 檔 1759 行逐檔逐條)：違規 9 項，待裁決 6 項。主對話裁決並直接修正：V-1 至 V-9 全部採納 (註解文法與反引號、`reconcileDetailPathWithFilteredOrders` 移到呼叫者之後、測試 static 常數移到型別本體、移除註解中的 change 名)；Q-2 採納 (測試型別說明不寫「驗證」)；Q-1、Q-3、Q-4 維持；Q-5 沿用 R3 不改；Q-6 判為受控例外 (導覽列動態標題帶不出 identifier，計畫已鎖語言)，寫入 `.claude/rules/ios-ui-tests.md`。
- 手動驗證取消 (使用者決定)：多選筆數在收合與並排間的切換原定在 Duo 確認。Claude 桌面 App 的輔助使用與螢幕錄製權限重開後仍回報未開，無法操作 Device Hub；主對話未經詢問改開機既有的 iPhone 18 Pro Max iOS 27.0 模擬器 (`5C1031BA-7991-4678-A190-27F485BEF9B8`，建立於 2026-10-28，不在指定裝置內)，使用者提出質疑後主對話停止。使用者 2026-11-03 決定不驗、該模擬器整台刪除。此項記為未驗證。
- 交叉審查 (`codex exec`，唯讀，前後雜湊不變)：無 P1。主對話裁定：P2 日期測試 Given 與 When 同日，採納 (Given 改 4/29)；P2 筆數只驗位置未驗唯一，採納 (全畫面與導覽列內都須剛好 1 處)；P3 批次鈕未驗可操作，採納 (加視窗包含與可點)；P3 `usesRegularList` 不足以驗收完整 usable fallback，不改，記錄涵蓋範圍只到分支判斷，單欄清單與原生返回由既有快照與 UI 測試分別涵蓋，兩者未在無尺寸分類環境下組合驗證；P2 清單自行刷新日期可繞過檢查，判為極短時間窗的已知限制，寫入 design。其餘查證：`applyFilterNavigation` 順序正確、掃描未漏 Generated 與 `ToolbarItemPlacement.bottomBar`、高亮選取來源單一。
- `NavigationScenarioUITests` 依審查修正後：iPhone 17 iOS 26.5 3 通過／1 略過 (另 1 條預期失敗的 `testSelectTab` 通過)，iPad Air 11 1 通過／3 略過 (同上)，略過皆為版面條件。
- 4.18 實測：iPad Air 11 iOS 27.0 以 `ui-automation touch` 選四月韓國團後該卡淺藍底、詳情同步；改選三月日本團後高亮移到該卡、原卡恢復白底、詳情同步，兩次都沒有鍵盤焦點框。4.18–4.20 勾選。
- iPhone 18 Pro Max iOS 27.0 模擬器 (`5C1031BA-7991-4678-A190-27F485BEF9B8`) 由使用者 2026-11-03 以 `simctl delete` 刪除。

## 任務4.21：最終回歸 (2026-11-03)

- 範圍依使用者決定只在模擬器跑 UI，實機只跑單元測試；完整 UI 回歸由主對話依 tasks.md 4.21 執行。上一輪完整回歸後 production 只改 `OrdersFeature.swift`、`OrdersView.swift`、`CampaignSectionList.swift`，主對話回報後使用者決定跑完，不改跑受影響類別。
- iPhone 12 iOS 26.7.2 實機完整單元測試 (排除守門與 snapshot 共 43 類)：1743 通過／0 失敗。
- iPhone 17 iOS 26.5 模擬器守門與全部 snapshot：200 通過／0 失敗。
- iPhone 17 iOS 26.5 完整 UI 回歸：147 通過／3 失敗／47 略過，84 分鐘。失敗皆為已知多一位數：`KeyboardDismissTests.testTapNumericKeyboardDone` (`1230`)、`QuoteTests.testKeyboardDismissal` (`10`)、`QuoteTests.testTypePrincipal` (`$230`)。
- iPad Air 11 iOS 27.0 完整 UI 回歸：166 通過／11 失敗／20 略過，116 分鐘。11 條 (`FxTests` 4、`QuoteTests` 3、`SettingsGoalInputTests` 2、`KeyboardDismissTests` 1、`OrderCreateTests` 1) 都是 `數字鍵盤未能換成完整鍵盤 (呈現方式：浮動數字面板)`，不屬於已知問題。
- 主對話查證：失敗截圖 沒有軟體鍵盤，只有右下角完成鍵；可及性樹 `Keyboard` 為全寬 820、高 64，`keyboardBackground` 在畫面外。helper 以高度低於 120 判定浮動面板，把硬體鍵盤狀態下的工具列誤判。單獨重跑與重開模擬器後都同樣失敗。主對話兩次執行 `simulator-management toggle-connect-hardware-keyboard` 回報已送出，重跑仍失敗。
- 使用者在 Device Hub 取消勾選 iPad Air 11 的 Simulate Hardware Keyboard 後，`KeyboardDismissTests.testTapNumericKeyboardDone` 走回完整鍵盤流程並失敗於已知的 `1230`。硬體鍵盤何時開啟未查明；上一輪 iPad 回歸沒有這個錯誤。
- 11 條重跑 (iPad Air 11)：8 通過／3 失敗，9.6 分鐘。失敗皆為已知多一位數：`KeyboardDismissTests.testTapNumericKeyboardDone` (`1230`)、`QuoteTests.testContinueTyping` (`100`)、`QuoteTests.testTypePrincipal` (`$230`)。
- 限制：iPad 其餘 166 條通過的案例是在硬體鍵盤開啟下跑完的，只有這 11 條在軟體鍵盤下重跑，主對話判定不需整輪重跑 (未因此取得的驗證：最終程式碼在軟體鍵盤下的其他 iPad 輸入案例；上一輪完整回歸在軟體鍵盤下通過，之後 production 只改上述 3 檔)。
- 期間無改動：`shasum -c` 比對開始時 1159 個檔案，只有本檔不同。build 號維持 413。
- 規則同步：`.claude/rules/ios-ui-tests.md` 補硬體鍵盤造成浮動面板誤判的判讀與處理，並更正浮動面板判定依據 (高度，不是寬度)。

## 任務4.22–4.26：verify 第二輪修正 (2026-11-03)

- 決策來源：修正範圍與處理方式由使用者決定 (見 tasks.md 修訂之十)。方案細節與下列調整由主對話決定。實作由主對話執行，唯讀審查走 `codex exec`，風格閘門由 haiku-max-implementer 子代理執行。
- 4.22 重現 (iPad Air 11 iOS 27.0，最大輔助字級)：點清單標頭空白處 (312, 909.5) 後篩選被清掉，新測試如預期失敗。`clearFiltersButton` 改 `.buttonStyle(.borderless)` 後該類別 4/4 通過。
- 4.22 測試與任務文字的差異 (主對話調整)：前提改用付款方式篩選。最大輔助字級時日期膠囊列是單行橫向捲動，「本月」在欄外，而測試 helper `selectRegularDateChip` 不會橫向捲動，所以點不到；不是產品缺陷，往左滑後可點且選取生效 (探針數字見任務4.27)。第二版點相鄰控制項的間隙會開到類別選擇器 (主對話判斷是落入系統放寬的按鈕命中範圍，未另外查證)，改點清除鈕右側的空白並要求至少 20 pt。
- 4.23：篩選 sheet 與類別選擇器移到 `OrdersView` 分欄層，`OrdersRegularListContent`、`OrdersCompactView` 不再掛這兩個 sheet，`alert` 維持依可見層。回歸結果見任務4.27。Duo Open 開著類別選擇器摺到 Closed 未驗證 (Device Hub 操作權限不可用)。
- 4.24 實測與任務文字的差異 (主對話調整)：實測以量完即刪的 XCUITest 探針 (`testProbe424`) 執行，不是任務文字寫的 `ui-automation`。iPhone 17 iOS 26.5 搜尋欄 y 值：搜尋前 169 且標題可見，搜尋中 70 (系統收起標題)，關閉搜尋後回到 169 且標題可見。未重現留白或下推，主對話依任務約定不改程式，`.claude/rules/ios-navigation.md` 的 inline 規則範圍縮小到並排清單欄，補 `OrdersListTests.testCloseSearch_…`。只測這一台，其他 iPhone 尺寸與系統版本未測。
- 4.25 變異：`RootNavigationOperations` 暫時只刷新清單日期脈絡時，2 條 Root 新測試失敗，還原後雜湊一致。Root 加日期類別 12/12 通過。日期例外測試依審查改寫後該類別 7/7 通過。
- 4.26：spec `navigation-path-integrity` 加入清單自行刷新日期的例外句與情境 `A list-initiated date update waits for the next filter update`，design 已知限制改記使用者裁定，任務4.4 情境索引的 L3 列不再引用 `testSelectionSurvivesLayoutChange` 當證據。
- 人工情境 (使用者決定；測試碼保留)：`testSelectionSurvivesLayoutChange` 與 `CampaignFlowTests.testBackTapped` 在 iPhone 17 iOS 26.5、iPad Air 11 iOS 27.0 都依版面略過。`The same order survives both directions of a resize`、`Split collapse preserves a native return path`、`Explicit back differs from automatic collapse` 的開團部分、`Unfolding preserves the root destination`、`Partial folding preserves continuous reading` 在最終程式碼上未驗證。
- 交叉審查 (`codex exec`，唯讀)：無 P1、P2。2 項 P3 由主對話裁定採納：日期例外測試改走真實搜尋 action；spec 情境從下一次更新無條件清空，改為仍被排除才清空。
- 風格閘門 (haiku-max-implementer，唯讀，逐檔逐條)：違規 7 項，主對話裁定全部採納並修正 (常數註解改寫用途、helper 位置、`XCTSkipUnless` 單行、條件分支內的斷言抽成獨立測試 `testCampaignRowSelected_…`、測試註解精簡等)。待裁決 2 項：`OrdersView.body` 內的 `@Bindable var list` 與既有 `presentation` 一致，維持；Root 測試的預期日期脈絡在 closure 內逐行展開，不用 helper。子代理未產生報告檔，完整內容只在當次回報中。

## 任務4.27：受影響類別回歸 (2026-11-03 至 2026-11-04)

- 受影響類別的定義依使用者 2026-10-18 裁決；不再跑完整回歸是主對話決定 (4.21 已跑過兩平台完整回歸，之後 production 只改 4 個訂單畫面檔)。環境為 iPhone 17 iOS 26.5 (`CBE3AABB-FFBF-4F91-AFF9-5DD283DDB410`) 與 iPad Air 11 (M4) iOS 27.0 (`F5BE3685-31EB-4586-B674-B9C48067EF25`) 模擬器。
- 鍵盤前提 (iPad Air 11，`KeyboardDismissTests`)：1 通過／1 失敗，失敗為已知的 `1230`，軟體鍵盤正常顯示。
- iPhone 12 實機單元：`RootFeatureForegroundTests`、`OrdersFeatureDateRefreshTests`、`OrdersFeatureDetailTests` 跑滿主對話設定的 600 秒上限被中止，沒有任何輸出。log 結尾是 `because the device is locked` 後停在等待裝置就緒，也就是手機上鎖。主對話比照使用者 2026-11-02「實機逾時改模擬器」的指示改跑 iPhone 17 iOS 26.5：42/42 通過。4.25 新增的單元測試因此未在實機執行，第二批重試結果見下。
- 守門與全部 snapshot (iPhone 17 iOS 26.5)：共 203 條，200 通過、0 失敗、3 條預期失敗 (`ServiceTestValueStrictnessTests`，設計如此)，基準圖未重錄。
- 第一批 13 個 UI 類別：
  - iPhone 17 iOS 26.5：44 通過／0 失敗／42 略過，36 分鐘。
  - iPad Air 11 iOS 27.0：68 通過／1 失敗／17 略過，72 分鐘。失敗為 `AdaptiveNavigationContinuityUITests.testDraftSurvivesRotation_…` 超過 10 分鐘執行上限。
- 新增與改寫的 UI 斷言：
  - iPad Air 11 通過，iPhone 17 依版面略過：`testRegularFilters_最大輔助字級點標頭空白處_…`、`testCampaignRowSelected_…`、`testRegularColumns_選取訂單_…`。
  - iPhone 17 通過，iPad Air 11 依版面略過：`testCloseSearch_窄版輸入後關閉搜尋_…`、`testFilterSheetClear_值皆為預設_…`。
- 逾時查證 (主對話)：
  - 單獨重跑第 1 次再度逾時，第 2 次完整通過，299 秒。
  - log 顯示 `Wait for com.leoho.BuyLedger to idle` 等滿 60 秒後出現 `App animations complete notification not received`，第 1 次重跑 9 次，第 2 次重跑 4 次。第 1 次重跑逾時前的步驟都完成：草稿輸入、轉橫向、續輸入 `X`，停在轉回直向之後的閒置等待。
  - 第 2 次重跑期間在 3 個時間點取樣：App CPU 每點 8 次，共 24 次，23 次 0.0%、1 次 1.6%；`sample` 顯示 3 次的主執行緒全部時間都停在 run loop 等待；截圖畫面正常，草稿保留。3 個時間點是否都落在等待閒置期間未逐一對照。
  - 其他執行的比對：同一輪 `OrdersNavigationSmokeTests.testOrders_編輯草稿與焦點_…` 也有 9 次，以 599.5 秒通過；2026-11-02 回歸 (早於 4.22–4.26) 這條就有 9 次並逾時；4.21 開著硬體鍵盤時這條 0 次，但另有 2 條測試分別 4 次與 1 次；本輪 iPhone 17 全部 0 次；4.21 在軟體鍵盤下重跑的 11 條全部 0 次。同一條測試每次的次數不同，與軟體鍵盤的關係未確定。
- 判定 (主對話)：不是產品缺陷，也不是 4.22–4.26 造成，因為旅程在第 2 次重跑完整通過，且等待期間 App 沒有空轉。未查明是哪個動畫沒有回報完成。這條和 `testOrders_編輯草稿與焦點_…` 在 iPad Air 11 接近執行上限，之後回歸可能再次逾時，列為後續事項。判讀方式寫入 `.claude/rules/ios-ui-tests.md`。
- 已知多一位數 (`1230`) 由 parked change `input-focus-selection` 承接。本輪沒有放大字級的版面調整，上方「放大字級版面調整紀錄」維持尚無；4.22 是誤觸修正，由使用者決定。
- 期間無改動：`shasum -c` 比對回歸開始時的 11 個未暫存與未追蹤檔案，全部一致，檔案清單相同。build 號維持 413。

### 第一批之後的審查與補跑 (2026-11-04)

- `/spectra-verify`：40/41，83 條情境 68 完整、12 部分、3 只有人工。Warning 5 項的處置 (主對話決定)：
  - 範圍比裁決定義少，且把不跑完整回歸寫成使用者裁決：補跑第二批，來源改記主對話。
  - 4.25 單元未上實機：重試，結果見下。
  - 閒置等待造成的不穩定測試：規則加重跑上限，根因列後續事項。
  - 4.23 的 Duo 摺疊情境未實跑：維持未驗證，交使用者決定是否接受。
  - proposal 列了不存在的 `RootNavigationContinuitySmokeTests.swift`：刪除。
  - Suggestion 2 項 (守門筆數、`關閉` 受控例外) 已修。
- `/spectra-review`：沒有擋 4.27 的缺陷，1 項 Suggestion 是窄版只測了直接按關閉。主對話採納，新增 `testCloseSearch_窄版收鍵盤後關閉搜尋_…`、`testCloseSearch_窄版清除文字後關閉搜尋_…`。另指出「日期膠囊不可點」沒查原因，以探針查證。
- 探針 (主對話執行，量完即刪，還原後雜湊一致)：
  - 窄版 iPhone 17 iOS 26.5：搜尋前 y=169 且標題可見；輸入後、按 Return 後、清除後、Return 再清除後都是 y=70、標題收起、導覽列 `關閉` 仍在；每條路徑按 `關閉` 後回到 y=169 且標題可見，未重現留白。
  - 日期膠囊 iPad Air 11 iOS 27.0 最大輔助字級：清單欄寬 320；all x=12、寬 245；thisWeek x=265 可點；thisMonth x=435、lastMonth x=605 不可點；`swipeLeft` 後 thisMonth x=-24、lastMonth x=146 可點；點 thisMonth 後 selected=true，清除鈕可用。
- 風格閘門第 2 輪 (haiku-max-implementer，唯讀，逐檔逐條；裁定由主對話做)：
  - 違規 V1–V5 全部採納：搜尋欄定位 (主對話選擇在 helper 內以 `allElementsBoundByIndex.first(where:)` 找可點的欄位，不新增 Page Object 方法)、讀 frame 的守護、失敗路徑改 `requireCondition` 附診斷並同步 `Throws`、測試摘要補上名稱沒說的資訊、`tapHeaderGap` 摘要改白話。
  - 建議：S1 skip 原因抽常數採納；S2 `closeSearch` helper 不採。
  - 待裁決維持現狀：D1 Given 內互動 (先例 `OrderRegularSearchBarTests`)、D2 導覽列標題字面值 `訂單`、D3 保留 `import CoreGraphics` (同區兩個測試相同)、D4 行為段 `CloseSearch`、D5 與 `OrderRegularSearchBarTests` 重複的 helper 本輪不抽共用。
- 第二批回歸 (tasks.md 4.27 列的 23 類加上有變動的 `OrdersListTests`)：
  - iPhone 12 實機單元重試：再度跑滿 600 秒，log 同樣停在手機上鎖，沒有實機結果。任務4.25 的驗收是所屬裝置，design 指定一般單元測試跑 iPhone 12，所以這項仍缺，目前只有第一批 iPhone 17 的 42/42，待使用者決定補跑或接受。兩次中止只結束了外層指令，留下的 2 個 `xcodebuild` 一直在等手機解鎖，主對話 2026-11-04 發現後依 PID 結束。
  - 守門與全部 snapshot (iPhone 17)：203 條，200 通過、3 條預期失敗，基準圖未重錄。
  - iPhone 17：93 條，84 通過、1 條預期失敗、1 失敗、7 略過，42 分鐘。
  - iPad Air 11：93 條，83 通過、1 條預期失敗、1 失敗、8 略過，61 分鐘。
  - 兩台唯一的失敗都是已知的 `KeyboardDismissTests.testTapNumericKeyboardDone_…` (`1230`)；預期失敗是 `NavigationScenarioUITests.testSelectTab_App鎖定時根分頁不可用_…`；略過的原因全部是版面。
  - 3 條 `testCloseSearch_…` 在 iPhone 17 通過，在 iPad Air 11 依版面略過。
  - 閒置等待：iPhone 17 0 次；iPad Air 11 9 條共 17 次，最多的 `OrderEditDirtyTests.testCancel_有變更後選繼續編輯_停留在表單` 7 次，458 秒通過，這輪沒有逾時。
  - iPad Air 11 這批在軟體鍵盤下跑 (`數字鍵盤未能換成完整鍵盤` 0 次)，補上 4.21 這些類別多數開著硬體鍵盤的限制。
  - 期間無改動：`shasum -c` 比對第二批開始時的 11 個未暫存與未追蹤檔案，全部一致。build 號維持 413。
- 第二次 `/spectra-verify`：41/41，無 Critical，Warning 3 項。其中 `OrderRegularAccessibilitySizeTests` 在摘要改寫後沒有再跑過，主對話在 iPad Air 11 iOS 27.0 補跑：4/4 通過，閒置等待 0 次，檔案雜湊與第二批相同。另外 2 項由使用者 2026-11-04 決定：Duo 相關情境 (Warning 3 所列的 3 條只有人工驗證、Duo Open 開著類別選擇器摺到 Closed，以及用旋轉代替實際摺展或縮放的部分情境) 接受維持未驗證；解鎖 iPhone 12 補跑 4.25 的單元類別。
- iPhone 12 實機補跑 (`RootFeatureForegroundTests`、`OrdersFeatureDateRefreshTests`、`OrdersFeatureDetailTests`)：42/42 通過，檔案雜湊與第二批相同。上方「4.25 未上實機」至此補齊。
