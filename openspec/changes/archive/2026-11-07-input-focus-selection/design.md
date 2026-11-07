## Context

App 內輸入框聚焦時從未指定游標或選取範圍，游標落在點擊位置。以下數量為 2026-11-04 對 apps/ios/BuyLedger 搜尋 `TextField(`、`.searchable(` 的實際計數，不含 Preview 示範欄位：

- `TextField(value:format:)` 宣告 6 處，綁定型別全部是 `Decimal`：`OrderEditDecimalField` (實付金額、無卡折抵與補款、成本區共 7 個呼叫點)、`OrderEditPercentField` (3 個費率欄)、品項單價 (`OrderEditItemsSection`)、報價輸入 (`QuoteInputsCard`，同一宣告畫出 7 欄)、匯率金額 (`FxView`)、每月目標 (`SettingsView`)。
- 文字 `TextField` 9 處：客戶名稱、品項名稱、訂單備註、開團名稱、開團備註、主檔名稱、付款方式名稱、類別搜尋，以及選項新增 alert 的名稱欄。
- `.searchable` 4 處：`OrdersCompactView`、`OrdersRegularListContent`、`OrderMergeCandidateSheet`、共用的 `BLSearchableModifier` (由 `OptionPickerSheet` 使用)。

使用者 2026-10-28 決定另開 change 修正所有輸入框；使用者 2026-11-04 先決定游標一律在最後面、值為 0 時先清空，最後決定改成每次輸入時都先清空，文字欄位維持游標在尾端。當時 `adaptive-navigation-continuity` 已 archive，原本的跨 change 檔案先後限制已解除。

限制：

- `.claude/rules/ios-navigation.md` 規定綁 store 的 View 不留 `@State`，焦點狀態放 `Feature.State`；不綁 store 的可重用元件，其本地狀態屬元件內部狀態。
- `Shared/DesignSystem/` 不引用 Feature 與 `Core/Domain/` 型別，也不 import TCA。
- `NumericInputGroupingScanTests` 掃描正式原始碼中每處 `format: .number`，要求帶 `.grouping(.never)`。
- 表單 dirty 判斷比對草稿：`OrderEditFeature.State.isDirty` 是 `draft != initialDraft`，只聚焦不輸入不得寫回。
- 寫回路徑會改值：`OrderEditDraftOperations.reconcileCardlessDeductionCap` 把無卡折抵限制在實付金額以內，`OrderPercentConversion.percentageBinding` 把百分比捨入到兩位小數，兩者讀回值都可能不同於輸入值。
- App 最低支援 iOS 26.0。官方文件標示 `TextSelection` 與 `searchFocused(_:)` 為 iOS 18.0+、`searchSelection(_:)` 為 iOS 26.0+，都在支援範圍內；`TextField(_:text:selection:prompt:axis:)` 已對照 iOS 27.1 SDK 的 SwiftUI 介面確認存在。

## Goals / Non-Goals

**Goals:**

- 文字欄位 (單行、多行、搜尋) 在焦點由無到有時把游標放在既有內容尾端，不全選、不清空，且不打斷注音組字。
- 數字欄位在該欄焦點由無到有時一律先清空，輸入即取代原值；不輸入就離開時回到原本的顯示。
- 所有欄位經 Design System 共用元件取得這個行為，之後新增欄位不必各自實作，並以掃描測試守住。
- 數字解析、小數位、寫回時機與表單驗證行為不變 (無卡折抵的例外見 Non-Goals)。

**Non-Goals:**

- 不改欄位外觀、對齊、鍵盤類型、數字格式與驗證規則。
  - 例外：品項單價欄寬由固定 120 改為 `@ScaledMetric` (基準 120)，依 `ios-accessibility-localization.md`「固定點數的尺寸一律 `@ScaledMetric`」；預設字級寬度不變，較大字級隨字級加寬。style 閘門提出、主對話採納，使用者 2026-11-06 同意保留。
  - 例外：無卡折抵超過實付由「自動改成上限並說明」改為紅字檢核並停用儲存，見「無卡折抵超過實付以紅字檢核並停用儲存」(使用者 2026-11-06 決定)。
- 不改鍵盤收合路徑與鍵盤工具列。
- 不處理 SwiftUI Preview 內的示範欄位 (`BLReadableContentLayout` 的 Preview)。
- 不把游標或選取位置存進 TCA `Feature.State`；報價頁只把焦點狀態由 Bool 改為逐欄列舉。
- 不新增鍵盤「下一欄」動作：App 目前沒有這個入口，焦點只經點擊或程式設定移動。
- 不在聚焦期間把游標移回尾端：聚焦後再點其他位置由系統放置，供微調。這是主對話對「點擊輸入框開始輸入時」的解讀。

## Decisions

### 文字欄位聚焦時把游標放在尾端

**Supersedes**: input-focus-selection / 以 SwiftUI 官方 TextSelection 在焦點取得時設定選取

使用者 2026-11-04 決定不論文字或數字欄位，點擊開始輸入時游標一律在最後面，取代 2026-10-28「數字欄位聚焦全選」的決定。數字欄位隨後改為聚焦清空 (見下一節)，空欄位的游標自然在尾端，因此選取只用在文字欄位。

使用 `TextField(_:text:selection:prompt:axis:)` 綁定 `TextSelection?`，在焦點由 `false` 變 `true` 時設定一次 `TextSelection(insertionPoint: text.endIndex)`，之後由系統更新。搜尋欄用 `searchFocused(_:)` 與 `searchSelection(_:)`，Apple 文件 `searchSelection(_:)` 的範例即為在焦點取得時設定選取的同一模式。

文件沒有說明這次設定與系統依點擊位置放游標的先後。垂直切片以模擬器上的 UI 測試點擊驗證：若設定被點擊落點覆蓋，改為在 `onChange` 內以 `Task { @MainActor in … }` 排到下一輪主執行緒再設定，不用固定秒數延遲。

替代方案：

- 數字欄位聚焦全選：原決定，使用者已取消。
- 保留 `TextField(value:format:)`，監聽 `UITextField.textDidBeginEditingNotification` 後操作選取：依賴 SwiftUI 內部以 UIKit 實作的細節，通知是全域的，需要再判斷哪個欄位，否決。
- 以 `UIViewRepresentable` 包 `UITextField`：失去 SwiftUI 焦點、格式與無障礙整合，維護成本高，否決。

### 數字欄位每次聚焦都先清空

**Supersedes**: input-focus-selection / 值為 0 的數字欄位聚焦時先清空

使用者 2026-11-04 決定改成每次輸入時都先清空。這同時解決三個會讓金額出錯的情況：點擊位置造成多一位數 (`0` 前輸入 1000 成為 10000)；固定小數位的零值 (訂單費率 `0.00` 輸入 5 會成為 `0.005`，依 `OrderPercentConversion.rate(from:)` 捨入後是 0.01%，此為 Mac 上 Foundation 解析實測加讀程式碼推得)；已有數字時接在後面 (`2500` 輸入 1000 成為 25001000)。

清空只套用在數字欄位是主對話的解讀：使用者這句話接在數字欄位零值的討論之後，而文字欄位清空會讓接續輸入名稱或備註變成整段重打。

規則：

- 焦點由無到有時草稿設為空字串，不論綁定值是多少。清空不寫回，綁定值維持原值，建議售價等相依結果在打字前不變。
- 沒有輸入就結束編輯時，草稿依格式回到原本的顯示，表單不會變成已修改。
- 輸入後全部刪掉時，若這次聚焦已經寫回過，把綁定值還原成聚焦當下的值；沒有寫回過就不動。這條由主對話選定：否則 `2500` 輸入 1 再刪除會默默變成 1，表單也會被標成已修改。
- 聚焦期間的後續點擊不再次清空。
- 清空後欄位顯示呼叫端既有的提示 (報價欄的 `0`、匯率與每月目標的標題)，其餘欄位空白，不新增文案。

### 共用 BLTextField 集中游標邏輯

新增 Design System 元件 `BLTextField`，包 `TextField(_:text:selection:prompt:axis:)`，持有 `TextSelection?` 並在焦點取得時把游標放到尾端；支援單行與多行 (`axis: .vertical`)。呼叫端保留原本的文字 binding、焦點 binding、`textContentType`、identifier 與修飾器。

文字為空時不設定選取，維持系統預設。元件只在焦點轉換時寫入選取，其餘時間由系統更新，降低打斷注音組字的機會；組字是否受影響以 UI 測試逐鍵輸入驗證，`typeText` 直接送字元、走不到組字流程，不能代替。文字被外部改變時 (例如類別搜尋的清除鈕) 元件要清掉舊選取，避免舊字串的索引套到新字串。

### 數字欄位改用共用 BLNumberField，以字串草稿編輯

`TextField(value:format:)` 不能在聚焦時清空畫面文字，所以數字欄位改成字串編輯。新增 Design System 元件 `BLNumberField`：內部持有字串草稿，用一般的 `TextField(_:text:prompt:)`，欄位聚焦時是空的，不需要 `TextSelection`，也就沒有舊索引套到新字串的問題；以呼叫端傳入的 `Decimal.FormatStyle` 把值格式化成草稿、以該格式的 `parseStrategy` 把草稿解析回值。六處宣告綁定的都是 `Decimal`，不做泛型。

寫回與顯示規則：

- 使用者改動草稿且可解析時立即寫回 (使用者 2026-10-28 確認現行是打字當下更新，例如報價輸入期間建議售價即時更新)；無法解析不寫回。
- 寫回後記下讀回值。之後綁定值變成與記錄不同時視為外部改值，以格式重設草稿。
- 只有使用者輸入經文字 binding 的 setter 寫回，且草稿沒有改變時不寫回；聚焦清空、結束編輯與外部改值由程式直接設定草稿，都不寫回，避免只聚焦就讓表單變成已修改。
- 結束編輯時草稿依格式重新顯示目前的綁定值。
- `@State` 草稿在 `init` 以格式化後的值建立，不靠 `onAppear`：snapshot 只畫第一幀，首幀不可空白。

草稿轉換抽成可單元測試的純邏輯型別 `BLNumberFieldDraft`，放在同目錄的獨立檔 `BLNumberFieldDraft.swift` (依 `ios-design-system.md`「變大時拆出」，主對話決定)。呼叫端仍以 `format: .number…grouping(.never)` 傳入格式，`NumericInputGroupingScanTests` 的掃描錨點與規則不變；`OrderEditPercentField` 原本寫 `Decimal.FormatStyle.number`，掃描比對不到，遷移時改成 `format: .number` 開頭。

替代方案：把各欄位改成 `Feature.State` 裡的字串草稿，否決：每個功能都要新增草稿欄位、解析與同步邏輯，且游標屬畫面暫態，不應進 reducer。

### 報價頁改為逐欄焦點

`QuoteInputsCard` 的七個數字欄共用 `QuoteFeature.State.isAmountFieldFocused` 這個 Bool。焦點從一欄直接移到另一欄時值維持 true，元件判斷不出焦點轉換，換欄後不會清空，輸入會插進原值造成金額錯誤。改為 `QuoteFeature.State.focusedField: Field?`，`Field` 依畫面順序宣告七欄；鍵盤工具列完成鍵設為 `nil`，`QuoteView` 的 `@FocusState` 鏡像改用同一型別。

替代方案：元件內另持 `@FocusState` 判斷自身焦點，再同步回共用 Bool，否決：同一欄掛兩個 `focused` 修飾的行為沒有文件保證，舊欄失焦與新欄聚焦的同步順序不定，可能把共用 Bool 寫成 false 而收掉鍵盤。

`FxView`、`SettingsView` 與主檔、付款方式、類別搜尋都只有一個欄位綁 Bool，不受影響。

### 新增選項 alert 的輸入欄不遷移

`OptionPickerAddSection` 的名稱欄放在 `.alert` 內，每次開啟前 `triggerAdd` 都把草稿清空，alert 內也只有這一個輸入欄，不會有「點回有內容的欄位」的情況，符合規格「空欄位維持系統預設」。`.claude/rules/ios-navigation.md` 也記錄 alert 的 actions 只支援 `Button`／`TextField`，包進自訂元件沒有實益，因此保留原生 `TextField`，列入掃描測試的允許清單。

### 搜尋欄依基準量測決定是否修改

基準量測記錄 `.searchable` 搜尋欄與類別搜尋欄聚焦時的游標位置：四種搜尋欄都不會把游標放到尾端，全部要改 (見 `verification.md`)。類別搜尋是一般 `TextField`，一律改用 `BLTextField`；`.searchable` 搜尋欄的做法見下一節。

### 系統搜尋欄集中於單一入口

**Supersedes**: input-focus-selection / 搜尋欄依基準量測決定是否修改 (`BLSearchFieldCaretModifier` 與舊 `BLSearchableModifier` 並存)；input-focus-selection / 以掃描測試守住輸入欄規範 (`.searchable` 不納入)

2.5 完成後，「App 的標準搜尋欄」這一個概念由兩個型別表達：`BLSearchFieldCaretModifier` 連 `.searchable` 一起套用，舊的 `BLSearchableModifier` 只多一個 `isEnabled`。兩個名稱分不出差別，`Caret` 也只講到一半的工作。

決策來源：主對話與 Codex 討論後收斂，使用者 2026-11-05 核定整個方案。`BLSearchableModifier` 名稱、`.blSearchable` 與三個 API 一起掃描由 Codex 提出；條件留在 `OptionPickerSheet` 與這次不抽共用型別由主對話提出。

規則：

- 合併為 `BLSearchableModifier`，放 `Shared/DesignSystem/Foundations/ViewModifiers/`，同檔提供 `View.blSearchable(text:prompt:)`，與該目錄其他 modifier 的寫法一致；不在綁 store 的 View 加 `@State`。名稱對應系統 `.searchable`。
- `prompt` 必填：訂單清單與合併候選、選項選擇器的提示不同。
- `.searchable`、`.searchFocused`、`.searchSelection` 與文字、選取追蹤留在同一封裝，維持已驗證的組合。第一版 `.searchable` 在 modifier 外時，合併候選與選項選擇器的游標停在點擊處；修好的那次同時把 `.searchable` 移進 modifier 並沿用文字與選取追蹤，沒有隔離變因，所以不宣稱是哪一項修好的。註解同樣只寫集中套用，失敗經過留在 `verification.md`。
- 條件留在 `OptionPickerSheet`，共用 API 不帶 `isEnabled`：四個呼叫端只有它需要。條件分支包在持有搜尋狀態的 modifier 外面，啟用時才建立搜尋狀態，與舊結構相同；`isSearchEnabled` 是 `let`，各呼叫處都是固定值。不承諾切換時維持畫面識別。
- 保留 `@MainActor`：`ViewModifier` 的遵循寫在 extension，型別不會推斷成 MainActor，少了會有 Sendable 警告。
- 這次不抽 `BLTextField` 與 modifier 相同的追蹤邏輯：目前沒有必須同步修的缺陷，改動已驗證的 `BLTextField` 會擴大回歸範圍。出現第三個使用點、同一個 bug 要兩邊一起改，或追蹤規則變複雜時再評估。

替代方案：

- 兩個型別都改名 (`BLSearchFieldModifier`、`BLConditionalSearchFieldModifier`)：名稱變清楚，但兩個入口都還在，否決。
- `isEnabled` 進共用 API：其餘呼叫端都不需要這個參數；若分支寫進持有狀態的 `body`，停用期間 `lastInputText` 不會更新，重新啟用時游標可能放不到尾端，否決。

### 先量基準，再以垂直切片驗證機制

字串草稿要重現 `TextField(value:format:)` 的行為，先在現行程式碼量測：游標位置、打字當下是否寫回、結束編輯後的顯示、清空與超過上限時的結果、裝置地區使用逗號小數點時的解析與顯示。量測用暫時的 XCUITest，量完即刪，結果以文字寫進 `verification.md`，不提交也不引用截圖或結果檔。元件是否套用 `@Environment(\.locale)` 依此決定。

量測與規格範例表不符時先暫停並回報，不自行選邊。

通過量測後，只遷移實付金額與客戶名稱兩欄，在兩台模擬器驗證聚焦清空、游標尾端與注音組字。這一步涵蓋最大的技術風險 (選取時機、iPad 數字 Popover、組字)，不通過時只需調整兩個元件，不必重做其餘遷移。

### UI 測試輸入 helper 改依賴 App 的聚焦行為

`XCUIElement+TextInput.swift` 的 `moveCursorToTextEnd` 目前在聚焦後點欄位右端，並在數字 Popover 或浮動面板時點兩下換成完整鍵盤。App 保證數字欄位聚焦即清空、文字欄位聚焦時游標在尾端後，這個步驟不再需要，因此移除。

`typeInField` 改為：欄位尚未取得焦點才點擊；已取得焦點時不點擊，避免把游標移到文字中間。這條路徑有實際呼叫：`AdaptiveNavigationContinuityUITests` 轉向後在已聚焦的客戶欄呼叫 `appendText`，`OrderEditScreen.typeChargedAmount` 也可能先點一次再交給 `clearAndType`。其餘流程不變：確認焦點、等鍵盤就位、依既有字元數從尾端送刪除鍵、輸入；數字欄位已清空時刪除鍵為空操作。helper 本身不比對結果，由各測試斷言欄位值。

`dismissNumericKeyboard` 不因這項調整而改變；它的完成鍵處理另依使用者 2026-11-05 決定，改為呈現方式連續取樣都是完整鍵盤才點，理由與實測見 `verification.md` 的 2.2 調查。`.claude/rules/ios-ui-tests.md` 描述右端點擊與 `appendText` 的條目同步改寫。

### 以掃描測試守住輸入欄規範

新增 `InputFieldConventionScanTests`，掃描正式原始碼不得直接宣告 `TextField`，允許清單為 `BLTextField`、`BLNumberField`、`OptionPickerAddSection` 與 `BLReadableContentLayout` (Preview 示範)。規則文件只靠人工遵守時，新增欄位會默默退回舊行為，且畫面看不出差異。

同一個測試類別另守系統搜尋 API：`searchable`、`searchFocused`、`searchSelection` 只准出現在 `Shared/DesignSystem/Foundations/ViewModifiers/BLSearchableModifier.swift`，允許清單用完整相對路徑，檔案搬走時測試會失敗。三者一起守，因為呼叫端即使沒有直接寫 `.searchable`，也可能在共用入口的畫面階層上另掛焦點或選取。

比對完整識別字，不要求前面有點或後面緊接括號，泛型特殊化、括號前的空白與隱含 `self` 才不會漏判；註解與字串內容不計入。

### 無卡折抵保留使用者設定的值

已由「無卡折抵超過實付以紅字檢核並停用儲存」取代 (使用者 2026-11-06)，3.6 的實作由 3.7 移除；以下保留 3.6 當時的設計供追溯。

數字欄逐字寫回後，`OrderEditDraftOperations.reconcileCardlessDeductionCap` 在實付每次變動時直接把折抵夾到實付以內，夾掉的值不再恢復。實付 2500、折抵 1000 的無卡訂單把實付改成 2600 時，第一個打的 2 就把折抵壓成 2；輸入 1 再全部刪除時折抵停在 1，取消會出現捨棄確認。舊欄位逐字刪除時同樣會經過中途值，聚焦先清空後，修改實付一定會經過。最終交叉審查由 Codex 讀碼提出，主對話以暫時單元測試確認後刪除。

決策來源：保留使用者設定的值、由實付即時推導的方向由主對話提出；提示獨立記錄、初始值採修正後的折抵、付款方式切換時保留與規則措辭由 Codex 兩輪唯讀審查提出；折抵欄的撤回語意由使用者 2026-11-06 選擇「動過折抵欄即確認」。

規則：

- `OrderEditFeature.State` 另存使用者設定的折抵 (以下稱設定值)，不放進 `OrderDraft`，不參與 `isDirty`。初始值是 `prepareDraft` 修正後的草稿折抵，舊資料或合併預填的超額值不會在提高實付時恢復。
- 實付經綁定變動：草稿折抵為設定值與 `max(0, 實付)` 的較小者，提示為「設定值大於草稿折抵」，設定值不變。
- 折抵經綁定寫入 v：設定值與草稿折抵都是 v 與 `max(0, 實付)` 的較小者，提示為「v 大於上限」。直接輸入超額時記夾限後的值，之後提高實付也不會超過使用者看過的值。
- 提示 `isCardlessDeductionCapped` 獨立儲存，不由設定值與草稿折抵推導：直接輸入超額後兩者相等，推導會失去說明。初始提示沿用現行判斷。
- 折抵欄的任何寫入都確認畫面上的值，包含全部刪除後還原聚焦當下的值。折抵正被實付壓低時編輯折抵欄再全部刪除，設定值變成當時顯示的值，之後提高實付不會回到原本的設定值。
- 付款方式切換、新增付款方式、選擇器往返與其他欄位的綁定都不動設定值與草稿折抵；存檔讀草稿，非無卡的歸零沿用存檔時的正規化。
- 不改 `BLNumberField`。

替代方案：

- 結束編輯才夾限：改低後離開再改高仍會遺失，且要接住收鍵盤、聚焦中存檔、推入選擇器等每條失焦路徑，否決。
- 只在全部刪除時連折抵一起還原：一般修改實付仍會寫錯，否決。
- `BLNumberField` 只在結束編輯時寫回：違反打字當下更新相依結果的規格，否決。
- `BLNumberField` 通知撤回、表單以焦點快照完整還原：寫回順序、包住整個 reducer 的焦點觀察與欄位重建語意都要一致，只為了折抵被壓低時的撤回，維護成本與時序風險高，使用者選擇不採用。

### 無卡折抵超過實付以紅字檢核並停用儲存

Supersedes：「無卡折抵保留使用者設定的值」。

使用者 2026-11-06 在提交前實機測試時決定：折抵超過實付時不自動改成上限，改以紅字提示使用者調整折抵欄。同日選定三項細節：

- 超額時停用儲存，與必填未齊相同。
- 開啟時折抵就已超額的既有訂單與合併預填草稿，保留原值並提示，不在開啟時修正。
- 文案「無卡折抵金額不得超過客戶實付金額，請調整折抵金額。」，原本放在折抵欄正下方；使用者 2026-11-07 實機檢視後改為收款區段底部，排在灰字的無卡計算說明下方。

規則：

- 表單不改折抵：實付與折抵的綁定都只寫回各自的值，`prepareDraft` 與 `OrderDraft(original:)` 不再夾限。
- 超額判斷 `isCardlessDeductionExceeded` 由草稿推導：付款方式為無卡，且折抵大於 `max(0, 實付)`。非無卡的折抵在存檔時歸零，不提示也不擋存檔。
- `canSave` 為「必填齊全且未超額」，儲存鈕的停用與 `save` 的 guard 都看它；必填提示改看 `hasRequiredFields`，折抵超額時不顯示必填提示。
- 紅字放在收款區段的 footer，排在無卡計算說明下方，footnote 字級，色彩 `BLTone.destructive.onSurface`，掛 `BLAccessibilityID.OrderEdit.cardlessDeductionExceededMessage`。
- 存檔正規化 `LedgerOrder.applyingPaymentMethodFlags` 仍把折抵限制在實付以內，作為表單以外寫入路徑 (付款方式回溯更正) 的資料保證。

主對話的技術決定：

- 移除 3.6 的設定值 `userSetCardlessDeductionAmount` 與儲存的提示旗標 `isCardlessDeductionCapped`：表單不再改折抵後，折抵欄的值就是使用者設定的值，實付的中途值也不會覆寫它。
- 色彩用 `BLTone.destructive.onSurface`，它由 `ContrastComplianceTests` 守 4.5:1。`.blRed` 是 systemRed，主對話以 sRGB 相對亮度估算疊白底約 3.6:1 (未實測)，達不到本專案的文字地板。開團名稱衝突的既有紅字用 `.blRed`，不在本 change 範圍。
- 提示只在無卡時顯示：非無卡時折抵欄隱藏、存檔歸零，原本 footer 在非無卡時仍可能出現的上限說明一併消失。

替代方案：

- 可存檔、存檔時才改成上限：使用者選擇停用儲存。
- 開啟時自動修正既有超額：與不自動調整的方向不一致，使用者選擇保留原值並提示。

## Implementation Contract

**行為：**

- 數字欄位 (實付金額、無卡折抵與補款、成本區金額、百分比、品項單價、報價七欄、匯率金額、每月目標) 焦點由無到有時顯示空字串，綁定值不變；沒有輸入就結束編輯時回到格式化顯示；輸入後全部刪掉時還原聚焦當下的值；聚焦期間的後續點擊不再次清空。
- 文字欄位 (客戶名稱、品項名稱、訂單備註、開團名稱、開團備註、主檔名稱、付款方式名稱、類別搜尋，及全部 `.searchable` 搜尋欄) 焦點由無到有時游標在既有內容尾端，不全選、不清空；空欄位維持系統預設；注音組字不被打斷；聚焦期間的後續點擊由系統放置游標。
- 由程式設定焦點 (例如新訂單表單開啟時聚焦客戶名稱) 同樣經過焦點轉換，套用相同行為。
- 不開搜尋的選項選擇器 (`isSearchEnabled` 為 `false`) 沒有搜尋欄。
- 無卡訂單的折抵超過實付時，折抵欄保留輸入值，收款區段底部顯示紅字檢核訊息，儲存停用；實付或折抵改到不超過時訊息消失、可儲存。表單不自行修改折抵，既有超額訂單開啟時也保留原值；非無卡付款方式不檢核。

**介面：**

- `BLTextField(_ titleKey: LocalizedStringKey, text: Binding<String>, prompt: Text? = nil, axis: Axis? = nil, …)`，焦點參數有兩種形式：`FocusState<Bool>.Binding`，或 `FocusState<Value?>.Binding` 加比對值。
- `BLNumberField(_ titleKey: LocalizedStringKey, value: Binding<Decimal>, format: Decimal.FormatStyle, prompt: Text? = nil, …)`，焦點參數同上，內部用一般 `TextField(_:text:prompt:)`，不持有 `TextSelection`。
- 兩者都放 `Shared/DesignSystem/Components/Forms/`，不綁 store、不 import TCA、不引用 Feature 型別，`#Preview` 放檔尾。鍵盤類型、對齊、字型、identifier 由呼叫端以修飾器提供。
- `BLNumberFieldDraft`：放 `Shared/DesignSystem/Components/Forms/BLNumberFieldDraft.swift` 的純邏輯型別，提供格式化、解析、全部刪除時是否還原聚焦當下的值與「外部改值時是否重設草稿」的判斷，不依賴 SwiftUI 檢視。
- `QuoteFeature.State.focusedField: Field?` 取代 `isAmountFieldFocused`。
- `BLSearchableModifier` 與 `View.blSearchable(text: Binding<String>, prompt: Text)`：放 `Shared/DesignSystem/Foundations/ViewModifiers/`，不帶 `isEnabled`；訂單清單 (compact、regular)、合併候選與 `OptionPickerSheet` 都經這個入口。
- 新增 UI 測試用 identifier：百分比欄、品項名稱與單價、訂單備註、無卡折抵、報價其餘六欄、匯率快捷金額、開團備註，常數放 `BuyLedgerAccessibilityIDs/` 對應區域，由垂直切片一次補齊，遷移批不改這些檔。

**失敗模式：**

- 草稿無法解析時不寫回，維持原值；結束編輯時草稿依格式重新顯示目前值。
- 選取設定失敗 (例如焦點取得後文字被外部改變) 時保持系統預設游標，不得崩潰或改值；文字被外部改變時清掉舊選取。

**驗收：**

- 單元測試 `BLNumberFieldDraftTests` 涵蓋規格範例表 (1000、22.8、abc、空字串、12.345)、全部刪除時的還原 (這次寫回過才還原)、輸入中途字串 (`12.`) 與外部改值判斷。
- `QuoteFeatureTests` 涵蓋逐欄焦點與完成鍵清除焦點，一律用 `TestStore` (使用者 2026-11-05 指示)。
- 各規格情境以 UI 測試在 iPhone 17 iOS 26.5 與 iPad Air 11-inch (M4) iOS 27.0 模擬器驗證 (使用者 2026-11-04 決定，本 change 的量測、單元測試與 UI 測試都不跑實機)，新增的 UI 測試放 `apps/ios/BuyLedgerUITests/Tests/Forms/`，類別與檔名後綴依 ios-dev-kit 樣板用 `UITests`。
- 受影響 snapshot (`SnapshotOrderEditSectionsTests`、`SnapshotToolsTests`、`SnapshotMoreTests`、`SnapshotSharedTests`、`SnapshotLookupsTests`、`SnapshotCampaignDetailTests`、`SnapshotOrdersBaselineTests`、`SnapshotOrderFilterEmptyStatesTests`、`SnapshotOrderMergeTests`) 在 iPhone 17 iOS 26.5 模擬器淺色模式下無差異；差異先回報使用者，不自行重錄。
- `NumericInputGroupingScanTests`、`InputFieldConventionScanTests`、`LayerBoundaryTests`、`LocalizationCatalogTests` 在模擬器通過；`InputFieldConventionScanTests` 同時守住 `TextField` 與三個搜尋 API，加入探針時會失敗。
- UI 測試確認不開搜尋的選項選擇器 (訂單來源) 沒有搜尋欄。
- `OrderEditFeatureDeductionTests` 以 `TestStore` 涵蓋：超額輸入保留並標示超額、不可儲存；調低後可儲存；逐字輸入實付 (2、26、260、2600) 與 500 改 3000 時折抵不變、超額標示隨之出現與消失；刪空還原不算修改；既有與合併預填的超額保留原值、未修改、不可儲存；非無卡不標示、切回無卡再標示；其他欄位綁定不動折抵；規格範例表 deduction validation 五列 (可儲存的列經 `resolveWriteResult` 斷言存下折抵與營收)。
- `OrdersFeatureEditDeductionTests` 與 `OrderSaveGuardTests` 涵蓋超額時按儲存不送出存檔，以及既有超額訂單調低後才寫入。
- UI 測試以有折抵的無卡訂單驗證改實付後折抵不變 (含存檔後重開讀回)、輸入後全部刪除再取消不出捨棄確認 (3.6 交付，3.7 保留)；`testFocusCardlessDeduction_超過實付金額_保留輸入並提示調整` 驗證超額時折抵仍為輸入值、紅字位於補款欄下方的區段底部、儲存停用，調低後紅字消失、儲存可用。紅字顏色、位置與中英文案以截圖目視確認。

**範圍內：** 上列欄位、兩個共用元件、報價頁逐欄焦點、搜尋欄單一入口 `BLSearchableModifier` 與 `OptionPickerSheet` 的搜尋條件、`XCUIElement+TextInput.swift`、輸入欄與搜尋 API 掃描測試、`.claude/rules/` 三份規則檔的輸入欄條目、`ios-unit-tests.md` 的 `TestStore` 條目與 `QuoteFeatureTests`。 `OrderEditFeature` 的無卡折抵超額檢核與停用儲存 (3.7 移除 3.6 的設定值機制)、`OrderDraft(original:)` 的載入夾限、收款區段底部的紅字、`Localizable.xcstrings` 的折抵訊息文案、`ios-navigation.md` 的跨欄位限制規則。

**範圍外：** 選項新增 alert 的輸入欄、Preview 示範欄位、鍵盤收合、欄位外觀與格式、UI 測試既有類別的 `UITests` 改名 (排在後續工作)、其他 Feature 測試檔的 `Store` 遷移 (使用者 2026-11-05 決定本 change 收尾後另開 change；當日搜尋計數為 16 個檔 30 處)、選取追蹤的共用型別。

## Risks / Trade-offs

- [聚焦後看不到原值，也不能微調：`1.50` 要改成 `1.55` 得整個重打] → 這是使用者 2026-11-04 選擇每次清空的直接結果，主對話已告知使用者；不輸入就離開時原值不變。
- [輸入後全部刪掉再還原時，費率欄的舊資料若超過兩位小數會被捨入，表單可能標成已修改] → `OrderPercentConversion` 的既有捨入規則；只有這次聚焦寫回過才還原，不輸入就離開不會碰到。
- [設定游標後被系統依點擊位置放的游標覆蓋] → 垂直切片以模擬器點擊驗證，必要時排到下一輪主執行緒；以欄位值斷言，不只看畫面。
- [`selection` 綁定干擾注音組字，`typeText` 測不到] → UI 測試逐鍵點注音鍵盤並選字。裝置鍵盤未安裝注音時，測試明確以環境差異 skip 並回報使用者。
- [字串草稿與 `TextField(value:format:)` 的中間行為不同，例如清空、輸入「12.」、超過上限] → 基準量測先記錄，單元測試與 UI 回歸比對；不符時暫停回報。
- [裝置地區使用逗號小數點時解析不同] → 基準量測以 `-AppleLocale de_DE` 啟動參數記錄現況，元件依結果決定是否套用環境語系。
- [iPadOS 27 浮動數字面板或 Popover 下清空與輸入行為不同] → 兩台模擬器都驗收；helper 移除換鍵盤步驟後，以 iPad 回歸確認。
- [模擬器與實機行為可能不同：2026-10-28 的問題是在 iPhone 12 與 iPad Air 5 發現的，這次不在實機驗證] → 使用者 2026-11-04 決定只跑模擬器；`verification.md` 寫明未在實機驗證。
- [模擬器開著 Simulate Hardware Keyboard 時軟體鍵盤不出現，鍵盤相關測試會因環境失敗] → 量測前先跑 `KeyboardDismissTests`，失敗訊息是「數字鍵盤未能換成完整鍵盤」時先修環境。
- [報價頁焦點改列舉影響旋轉續輸入] → `QuoteTests` 的旋轉測試回歸；旋轉不產生焦點轉換，不應再次清空。
- [輸入實付途中 (例如 4200 改成 5000 時的 5、50、500) 會短暫出現紅字並停用儲存] → 檢核即時反映目前的值，打完即消失；這是使用者 2026-11-06 選擇不自動調整的直接結果。
- [既有超額訂單開啟後必須先改折抵或實付才能儲存] → 使用者 2026-11-06 選擇保留原值並提示；未修改時取消直接關閉，不出捨棄確認。
- [合併搜尋入口會動到已驗證的搜尋欄] → 只搬移、改名與移動條件，不改追蹤邏輯；受影響的搜尋、導覽 UI 測試與 snapshot 在兩台模擬器回歸。
- [表單 sheet 因版面變化被系統重新呈現時欄位重建，焦點恢復算一次轉換] → 數字欄會清空、文字欄游標回到尾端，綁定值不變；`AdaptiveNavigationContinuityUITests` 的草稿與接續輸入測試回歸確認。

## Migration Plan

1. 量基準，建立兩個共用元件與單元測試，以實付金額與客戶名稱驗證機制。
2. 依功能分批遷移呼叫端，每批 build、跑對應單元與 UI 測試。
3. 調整 UI 測試 helper 與規則文件，加掃描測試，收斂搜尋入口，跑完整回歸。

回滾：各批呼叫端可個別改回原本的 `TextField`，共用元件不影響未遷移的欄位。

## Open Questions

無待使用者決定的問題。搜尋欄是否修改、結束編輯後的顯示與地區小數點處理由基準量測決定，結果記入 `verification.md`；與規格不符時暫停回報。
