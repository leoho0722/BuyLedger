## Why

HIG 審查列出 38 項 suggestion。多數屬風格偏好或系統版本遷移，不修不會出錯。但其中有四項被這個等級低估了——它們不是「可以更好」，而是「已經或即將出錯」：

分隔線的左側內縮以 `BLSpacing.large + 40 + BLSpacing.medium` 手算，其中的 40 是複製自頭像尺寸。change dynamic-type-and-grouping 已排定把頭像改為隨字級縮放，屆時這四處分隔線會與頭像右緣錯開——這是跨 change 的相依性缺陷，不處理就會在下一個 change 落地時顯現。

收鍵盤手勢靠 Apple 私有型別名稱的關鍵字比對來排除系統文字選單。這些名稱隨 iOS 版本改名即靜默失效，沒有編譯或執行期警訊，症狀是回歸到「點『貼上』也收鍵盤」的舊 bug——而該 bug 正是當初實作這段過濾的原因。

結團結算按下即寫入結算日期並永久停用該按鈕，App 內沒有取消結團的路徑，卻沒有任何確認。這是不可逆的資料變更，其風險等級與訂單刪除相當，而後者有確認。

篩選 sheet 採 pending 狀態、只有按套用才提交，卻未阻擋下滑關閉，因此下滑會靜默丟棄已改的三項選擇。專案已為訂單、開團與付款方式編輯建立了未儲存變更防護的規範，此處是唯一的例外。

其餘納入的項目屬「實質影響使用者且修法成本低」與「純減法」兩類：輔助技術會朗讀出十餘處純裝飾的指示符號與 SF Symbol 名稱、篩選列的選取態無法被切換控制識別、開團詳情的標題不帶團名因此無法辨識當前是哪一團、App 重啟後一律回到總覽頁、刪除確認的文案塞入對使用者無意義的識別碼、進行中的採購狀態被塗成警示色、空狀態在捲動容器內不置中；以及三個零呼叫點元件與一個無效修飾子的刪除。

## What Changes

### 不可逆動作補上安全網

- 結團結算加入確認，文案點明結團後無法復原。
- 篩選 sheet 在有未提交變更時阻擋下滑關閉，取消時彈出捨棄確認，與專案既有規範一致。
- 選項選擇器在非嵌入模式的多選情境補上取消動作，修補元件契約的漏洞。

### 輔助技術朗讀清理

- 十餘處列尾的指示符號排除於無障礙樹外，避免朗讀出「Right chevron」這類無意義內容。
- 篩選列的選取態改以標準特徵表達，使切換控制與轉子能識別。
- 引導畫面的裝飾插圖排除於無障礙樹外，避免朗讀出 SF Symbol 名稱。

### Design System 清理

- 分隔線內縮抽成單一 token，與頭像尺寸同源，消除跨檔案的數值相依。
- 膠囊類元件的內距與狀態點尺寸改為隨字級縮放。
- 移除覆寫系統光學字距的無效修飾子。
- 刪除三個零呼叫點元件，其中一個的預覽正在示範會被照抄的錯誤作法。

### 一致性與可用性

- 開團詳情標題改為顯示團名。
- 收鍵盤手勢的私有型別名稱比對補上回歸測試，使其失效時能被察覺。
- 應用程式重啟後回到上次所在的分頁。
- 刪除確認文案改為主動語態並移除識別碼。
- 進行中的採購狀態改用資訊語意色，不再塗成警示色。
- 捲動容器內的空狀態正確垂直置中。
- 照片檢視器的關閉動作改放取消位置，不佔用主要動作位置。

## Non-Goals

- 不處理其餘 19 項 suggestion。明確排除且不再回頭處理的包含：分頁圖示的填色變體選擇、圖表 Y 軸刻度的顯示與否、搜尋列擺位的明確指定、字級層級補齊 Callout、較新系統版本的同心圓角與分頁縮小行為、觸覺回饋、右至左鏡像、以及色盤的 base 與 elevated 兩層合併 (後者若採用系統取色將自然解除，見 ux-honesty-and-visual-foundation)。
- 不移除 App 內的語言選擇。該功能牽動專案既有的本地化解析機制，且屬產品決策而非合規缺陷。
- 不納入三項架構重構：訂單列表三欄分割視圖、根層可轉換分頁樣式、訂單編輯表單拆分。
- 不改動側邊欄與總覽頁的比例版面實作，該兩項雖與註解描述不符但視覺結果可接受。

## Capabilities

### New Capabilities

- `irreversible-action-safeguard`: 不可逆動作與未提交變更的安全網契約。
- `assistive-announcement-hygiene`: 輔助技術朗讀內容的清理契約——排除裝飾、正確表達選取態。
- `design-system-hygiene`: Design System 的維護契約——數值同源、隨字級縮放、無效與無呼叫點程式碼的清除。
- `interface-consistency`: 介面一致性契約——標題具名、狀態語意正確、文案面向使用者、狀態恢復。

### Modified Capabilities

(none)

## Impact

- Affected specs: irreversible-action-safeguard、assistive-announcement-hygiene、design-system-hygiene、interface-consistency
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLMetrics.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/ViewModifiers/BLTypographyModifier.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoViewer.swift
    - apps/ios/BuyLedger/Shared/Keyboard/KeyboardDismissOnTap.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OptionPickerSheet.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OrderStatus+Presentation.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersCompactView.swift
    - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
    - apps/ios/BuyLedger/Features/App/RootFeature.swift
    - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
    - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
    - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
    - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
    - apps/ios/BuyLedger/Features/FX/FxView.swift
    - apps/ios/BuyLedger/Resources/Localizable.xcstrings
    - apps/ios/BuyLedgerTests/__Snapshots__
  - New:
    - apps/ios/BuyLedgerUITests（收鍵盤手勢的回歸測試）
  - Removed:
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Lists/BLListRow.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLAmountField.swift
