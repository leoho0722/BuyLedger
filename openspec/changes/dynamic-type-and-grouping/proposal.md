## Why

HIG 審查指出兩件互相牽連的事：版面在大字級下會破，以及輔助技術要走過太多元素才能讀完一列。

字級方面，全專案沒有任何一處讀取字級環境值，因此沒有任何版面會因為使用者調大字級而改變結構。實際後果是：總覽頁的淨獲利已正確使用可縮放字級，卻又接上單行限制與最小縮放係數把效果抵銷；關鍵指標格硬編兩欄，在小螢幕搭配大字級時金額必然被截斷；熱力圖的星期欄寬與格高是固定點數，大字級下標籤與數字會被裁切；圈狀圖寫死尺寸，中央文字在大字級下會溢出內圈。另有五處直接寫死字級點數，完全不隨系統設定縮放。

輔助技術方面，訂單列由八個獨立元素組成且未合併，走完一列要滑八次；更糟的是頭像的無障礙標籤與緊鄰的客戶姓名內容完全相同，會連唸兩次。熱力圖的七十個格子各自獨立且標籤只有筆數沒有座標，於是輔助技術會唸出「零單、零單、三單」七十次而完全不知道位置。開團列與關鍵指標格同樣未合併，總覽頁的指標區要滑十二次以上。

此外全專案沒有讀取減少動態效果的偏好。目前唯一的動畫是短促的按壓回饋、本身尚可接受，但這代表日後新增任何轉場都會直接違規。

## What Changes

### 版面隨字級調整結構

- 導入字級環境值判斷，在無障礙字級下讓固定欄數的版面降為單欄、讓橫排元素改為直排。
- 移除抵銷可縮放字級的最小縮放係數與單行限制，改為允許換行。
- 熱力圖的欄寬與格高、圈狀圖的直徑改為隨字級縮放。
- 五處寫死的字級點數改為綁定文字樣式或隨字級縮放。

### 複合元素合併為單一朗讀單位

- 訂單列、開團列、關鍵指標格合併為單一無障礙元素，使輔助技術一次讀完整列。
- 頭像在與姓名同列出現時排除於無障礙樹外，消除重複朗讀。
- 熱力圖格子的標籤補上座標，零值格子排除以減少噪音，並為整張圖提供摘要。

### 動態效果偏好

- 導入減少動態效果的偏好判斷，使既有與後續新增的動畫都會因應該設定。

## Non-Goals

- 不處理 blocker 與 suggestion 等級的發現。熱力圖的深度階梯與配色由 hig-blocker-remediation 處理，本 change 僅調整其尺寸與無障礙標籤，因此應排在該 change 之後實作。
- 不新增圖表的資料點無障礙描述，該項屬 blocker 範圍並由 hig-blocker-remediation 完成。
- 不處理右至左語言的鏡像議題，該項屬 suggestion 等級且目前僅支援中英。
- 不重新設計任何畫面的資訊架構，僅調整既有元素在大字級下的排列方式。
- 不新增動畫，僅讓既有動畫因應偏好設定。

## Capabilities

### New Capabilities

- `dynamic-type-adaptation`: 版面對字級變化的因應契約——結構隨字級調整、不以縮放係數抵銷、尺寸隨字級縮放。
- `assistive-element-grouping`: 複合介面元素對輔助技術的呈現契約——合併朗讀單位、排除重複與裝飾、提供位置資訊。
- `motion-preference-adaptation`: 動畫對減少動態效果偏好的因應契約。

### Modified Capabilities

(none)

## Impact

- Affected specs: dynamic-type-adaptation、assistive-element-grouping、motion-preference-adaptation
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
    - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OrderRowView.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift
    - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
    - apps/ios/BuyLedger/Features/Orders/Components/MergePhotoPickerSheet.swift
    - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Buttons/BLButtonStyle.swift
    - apps/ios/BuyLedger/Resources/Localizable.xcstrings
    - apps/ios/BuyLedgerTests/__Snapshots__
