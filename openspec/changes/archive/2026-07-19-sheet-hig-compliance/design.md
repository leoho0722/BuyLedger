## Context

BuyLedger 的 sheet 實作經 Apple HIG「Sheets」審視後，確認兩項需修正的偏差 (F1、F2)。相關程式碼落在 Orders 與 Campaigns 兩個 feature，以及共用元件 `OptionPickerSheet` 與 `PaymentMethodEditorSheet`。

現況約束：
- 專案採 TCA，綁 store 的 View 不持有 presentation 狀態；sheet／picker 開關、編輯草稿一律下放對應 `Feature.State`。可重用元件 (`OptionPickerSheet`／`PaymentMethodEditorSheet`) 以 closure 與 caller 溝通、本地 `@State` 屬元件內部狀態 (此為既有例外)。
- `OptionPickerSheet` 目前自帶 `NavigationStack` 與 Cancel toolbar，被 6 處主介面單層 sheet 呼叫點 (設定／報價／匯率／訂單頁) 與 7 處訂單編輯表單內的巢狀 sheet 呼叫點共用。
- `OrderEditFeature.State` 以 6 個布林 (`showsOrderSourceSheet`／`showsCategorySheet`／`showsCampaignSheet`／`showsPaymentMethodSheet`／`showsReconciliationStatusSheet`／`showsCurrencySheet`) 驅動各選擇器 sheet；另有 `photoViewerSelection`。兩個編輯 feature 目前皆無 dirty 概念。
- 既有踩雷 (memory)：test target 曾因 `navigationDestination(item:)` 相關符號出現 SwiftNavigation 連結失敗，該類屬真程式碼問題、需改用 `navigationDestination(for:)`。此為 F2 導覽機制選型的重要約束。

## Goals / Non-Goals

#### Goals

- F1：訂單編輯、開團編輯、付款方式編輯三張 sheet，在有未儲存變更時攔截下滑關閉，並以確認對話框提供「捨棄變更／繼續編輯」，杜絕草稿靜默遺失。
- F2：訂單編輯表單內的選項選擇器、開團編輯的提醒選擇器、以及新增付款方式表單，改以宿主 sheet 內的 push 導覽 (帶系統 Back) 呈現，消除 sheet 疊 sheet (含三層疊 sheet)。
- 主介面單層 sheet 呼叫點行為完全不變。

#### Non-Goals

- **提醒選擇器不加 F1 未儲存確認**：提醒改為 Form 內 inline `DatePicker` 後，時間戳即表單草稿、隨整張表單儲存/取消落地 (F1 已涵蓋)，不需獨立 dirty 判斷。
- 不改動任何選擇器的可選項、新增流程資料面或持久化行為；不動 schema。
- 不改動 macOS (專案已為純 iOS／iPadOS)。

> 註：後續依使用者「全面 HIG 合規」要求，原列為 Non-Goal / 低優先的兩項已納入：照片檢視器改 `.fullScreenCover` (HIG media 全螢幕，消除最後一處 sheet 疊 sheet)；合併流程照片步驟加 Back (多步驟後續步驟以 Back 取代 Cancel)。詳見 `sheet-nested-presentation` spec 對應 requirement。

## Decisions

### Dirty 判斷以各編輯 feature 的 draft fingerprint 計算

在 `OrderEditFeature.State` 與 `CampaignEditFeature.State` 各加一個把「所有草稿欄位」聚合成 `Equatable` 值的 fingerprint，於 State init 後擷取一份 `initialDraftFingerprint` 存起來，`isDirty` 即「目前 fingerprint 是否不等於初始 fingerprint」。`PaymentMethodEditorSheet` 為 closure 驅動元件，以本地 `@State` 記初始 `(name, isCardless, isBankTransfer, isCashOnDelivery)`、比對當前值得出 `isDirty`。

- 為何不比 `original`：新訂單／新開團的 `original` 為 `nil`，需另立空白基準；改以 fingerprint 對照初始快照可同時涵蓋新增與編輯兩種情境、邏輯單一。
- 為何不直接比整個 `State`：State 含 picker route、暫時性 UI 欄位，非草稿內容，直接比會誤判。
- Alternative — 於每次 `.binding` 副作用即時標記 `hasEdited`：被否決，容易漏欄位且與 BindableAction 純 UI 欄位排除規則衝突。

### 捨棄變更以 confirmationDialog 確認、狀態放 reducer

訂單／開團編輯的 `cancelTapped` 改為：`isDirty` 為真時不直接 dismiss，而是呈現一個確認對話框 (action sheet 樣式)，內含「捨棄變更」(destructive → dismiss) 與「繼續編輯」(cancel)；`isDirty` 為假時維持直接 dismiss。對話框狀態依 TCA 慣例放 reducer (以 `ConfirmationDialogState` 或 `@Presents` 承載)。`PaymentMethodEditorSheet` 無 store，以本地 `@State` 布林搭配 SwiftUI `.confirmationDialog` 實作相同兩個選項。

- Alternative — 攔截下滑手勢時直接彈 action sheet：被否決。SwiftUI 未提供「使用者嘗試下滑關閉」的原生 callback，需 UIKit bridging；改以「dirty 時停用互動式關閉 + 取消鍵彈確認」以原生 API 達成「不靜默遺失」的實質目標。

### 以 interactiveDismissDisabled 綁 dirty 阻擋靜默下滑關閉

三張編輯 sheet 的內容加 `.interactiveDismissDisabled(<該 sheet 的 isDirty>)`。語意：有未儲存變更時，下滑手勢不會直接關閉 (阻斷靜默遺失)，使用者改以取消鍵離開並觸發上述確認；無變更時下滑照常快速關閉。

### OptionPickerSheet 拆出可嵌入 (無自帶 NavigationStack) 模式

`OptionPickerSheet` 增加一個呈現情境參數 (預設維持現狀 = 自帶 `NavigationStack` + Cancel toolbar，供 6 處主介面單層呼叫點沿用不變)。嵌入情境下不自帶 `NavigationStack`、不放 Cancel (由宿主 stack 的 Back 取代)，仍保留標題與多選模式的「完成」。作法為把現有 List／搜尋／新增內容抽為內部子 view，由「sheet 包裝」與「push 目的地」兩種外殼共用。

- Alternative — 另開一個獨立的 `OptionPickerContent` 元件：功能等價，但會讓 13 個呼叫點分裂成兩套 API；以單一元件加情境參數可將主介面呼叫點的變動降到零。

### 訂單編輯的巢狀選擇器改用單一 route 的 push 導覽

以 `OrderEditFeature.State` 的單一 optional route enum (涵蓋 orderSource／category／campaign／paymentMethod／reconciliationStatus／currency 六種) 取代六個布林，驅動 `OrderEditView` 既有 `NavigationStack` 上的**單一** `navigationDestination`；目的地 builder 依 route case 建對應的嵌入式 `OptionPickerSheet`。選取後既有 action 照送、並 pop 回表單。

- 為何用單一 route 而非六個 `navigationDestination(isPresented:)`：同一 `NavigationStack` 掛多個 `isPresented` 目的地在 SwiftUI 下不可靠 (僅其一會生效)；單一 route 對應單一目的地是穩健模式。
- 導覽 API 選型受 memory 踩雷約束：優先採本 codebase 既有的 `StackState`／path-append 模式搭配 `navigationDestination(for:)`，避開曾在 test target 造成連結失敗的 `navigationDestination(item:)`。詳見 Risks。

### 開團提醒選擇器與新增付款方式表單改用 push

`CampaignEditView` 的提醒選擇器為該畫面唯一的 push，改用單一 `navigationDestination(isPresented: $store.isReminderPickerPresented)` 沿其 `NavigationStack` 呈現 (單一目的地、不涉 route 多重性、風險低)。`OptionPickerSheet` 內「新增付款方式」由 `.sheet` 改為 push 到當下承載該 picker 的 `NavigationStack`，消除三層疊 sheet；此新增流程僅出現在訂單編輯的嵌入式付款方式選擇器 (push 到宿主 stack)。

## Implementation Contract

#### 可觀察行為

- **F1**：在訂單編輯／開團編輯／付款方式編輯 sheet 內修改任一草稿欄位後嘗試下滑關閉 → sheet 不關閉；點取消鍵 → 出現含「捨棄變更」「繼續編輯」的確認對話框；選「捨棄變更」關閉且不儲存，選「繼續編輯」留在表單。未修改任何欄位時，下滑與取消鍵皆直接關閉、不彈確認。
- **F2**：在訂單編輯表單點任一選擇器列 → 該選擇器以 push (帶 Back) 出現於同一導覽堆疊，而非疊出新 sheet；Back 返回表單。開團編輯點「新增／編輯提醒」→ 提醒選擇器以 push 出現。訂單編輯的付款方式選擇器點「新增付款方式」→ 新增表單以 push 出現 (全程不超過一層 sheet + 導覽 push)。
- 主介面單層 sheet 呼叫點 (設定／報價／匯率／訂單頁篩選選擇器) 的外觀與互動不變。

#### 介面／狀態形狀

- `OrderEditFeature.State`：新增 `isDirty` 與 draft fingerprint；以單一 picker route enum 取代六個 `shows*Sheet` 布林 (`photoViewerSelection` 保留不動)。
- `CampaignEditFeature.State`：新增 `isDirty` 與 draft fingerprint；沿用 `isReminderPickerPresented`。
- 兩個 feature 新增「捨棄變更」確認的 presentation 狀態與對應 Action。
- `OptionPickerSheet`：新增呈現情境參數 (預設值使既有呼叫點免改)。
- `PaymentMethodEditorSheet`：新增本地 dirty 與確認對話框；不改對外 `onSubmit` 簽章。

#### 驗收標準

- `OrderEditFeatureTests`／`CampaignEditFeatureTests` 以 `TestStore` 驗證：修改草稿後 `isDirty` 為真；dirty 時 `cancelTapped` 呈現確認對話框而非直接 dismiss；「捨棄變更」送出 dismiss、「繼續編輯」關閉對話框且留在表單；未修改時 `cancelTapped` 直接 dismiss。
- 既有測試全綠 (269+ tests)；snapshot 若因導覽結構調整而變動需重錄並於 PR 說明。
- iPhone 與 iPad simulator 各 build 成功；六種選擇器與提醒、新增付款方式流程於實機以 push 呈現 (帶 Back)、無疊 sheet。

#### 範圍邊界

- In scope：F1 三張編輯 sheet 的關閉確認；F2 訂單編輯六種選擇器 + 開團提醒 + 新增付款方式的 push 化；`OptionPickerSheet` 可嵌入化。
- Out of scope：`BLPhotoViewer` 呈現方式、提醒選擇器的 F1 確認、任何選項資料面／持久化／schema 變更、macOS。

## Risks / Trade-offs

- [單一 `NavigationStack` 掛多個 `navigationDestination(isPresented:)` 不可靠] → 改採單一 route enum + 單一目的地。
- [`navigationDestination(item:)` 曾在 test target 造成 SwiftNavigation 連結失敗 (memory)] → 優先採既有 `StackState`／`navigationDestination(for:)` 模式；apply 時若仍出現該類連結失敗，依 memory 判別 (AlertState 類=flaky 可 clean 重跑；`navigationDestination(item:)` 類=改 `for:`)。
- [`OptionPickerSheet` 為 13 呼叫點共用，重構恐波及主介面單層情境] → 呈現情境參數預設值＝現況，主介面 6 處呼叫點零改動；以既有測試與雙平台 build 守門。
- [嵌入模式下 Cancel 換成 Back、多選「完成」語意] → 於嵌入情境明確只保留 Back + (多選時)「完成」，避免 Cancel/Done/Back 三者同時出現 (亦符合 HIG)。
- [dirty fingerprint 漏欄位會誤判 not-dirty] → fingerprint 涵蓋所有 draft 欄位並以 `Equatable` 集中定義，新增草稿欄位時同步維護 (於 tasks 明列欄位清單)。

## Migration Plan

- 純 UI／狀態層變更，無資料遷移、無 schema 變動；不需 rollback 資料策略。
- 建置前依平台鐵則將 build number +1、序列化 iOS/iPadOS build。
- 逐 feature 落地並各自跑 `TestStore` 測試；最後雙平台 build 與實機驗收 push 導覽與關閉確認。

## Open Questions

- (無) 導覽 API 選型的最終確認留待 apply 首次 build/test 時依 memory 踩雷判別，已於 Risks 記錄處置方式。
