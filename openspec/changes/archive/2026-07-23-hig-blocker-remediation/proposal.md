## Why

依 Apple HIG 對 apps/ios 全部 View 與 Design System 元件做的八領域合規審查，找出 99 條發現，其中 12 條為 blocker 等級。這 12 條不是散落的個別疏漏，而是集中在四個根源：Design System 的語意色 token 把「文字色」與「指示色」混為一談、圖表元件完全沒有無障礙描述、兩個關閉鈕的命中區遠低於系統下限、以及三處 UI 呈現與實際系統狀態不符。

這些缺口共同的性質是「使用者已經在受影響、但不會回報」——低對比文字只是看起來吃力不會被當成 bug，圖表對 VoiceOver 不存在只有依賴輔助技術的人才會遇到，死開關讓人以為自己已開啟提醒。因此需要一次從 token 層根治，而不是逐個呼叫點打補丁。

## What Changes

### 對比度：BLTone 拆成文字色與指示色雙軌

- BLTone 現行的單一 foreground 同時被當成文字色與色點色使用，而 background 一律回傳該色的 14% 淡底，導致「同色字疊同色淡底」。淺色模式下 success 1.98:1、warning 1.96:1、destructive 2.69:1、accent 3.35:1，全數低於 4.5:1。
- 拆成 onSurface（文字用，加深至達標）與 indicator（色點與進度條用，維持現有鮮色），色值改由 asset catalog 的 Color Set 提供，每組附 light / dark 與 High Contrast variant。
- 連帶修正五處共用同一病灶的呼叫點：計數徽章的白字、頭像縮寫的白字疊亮色漸層、客戶排名徽章的白字疊系統填色、熱力圖格內白字疊 0.2–1.0 透明度底色，以及被誤用在承載資訊文字上的 tertiaryLabel。

### 圖表：三個元件補齊 VoiceOver 契約

- 走勢圖是兩個裸 Path，對 VoiceOver 完全不存在；長條圖與圈狀圖的 mark 皆無 accessibility label；圈狀圖甚至把區段名稱收進參數卻從未渲染，區段身分只能靠顏色辨認。
- 圈狀圖改以類別維度驅動 foregroundStyle，讓 Swift Charts 自動生成類別語意；各 mark 補 label 與 value；三個元件各自提供圖表層級的摘要描述。

### 觸控目標：建立最小命中區契約

- 照片縮圖的刪除鈕實測約 20×20pt、搜尋欄的清除鈕約 17×17pt，兩者的 padding 都套在按鈕外側因而不擴大命中區。前者是不可復原的破壞性動作。
- 兩處都在維持現有視覺尺寸的前提下把命中區撐到 44×44pt。

### 狀態誠實性：移除死開關、補上失敗回饋

- 設定頁的「接收訂單提醒」開關背後沒有任何通知授權或排程實作，值只寫入偏好儲存後無人讀取。移除整個通知區塊。
- 訂單載入失敗時，總覽頁與分析頁因為只判斷「是否已載入」而停在無限轉圈，畫面上沒有原因也沒有重試入口。兩頁補上失敗分支與重試。
- 開團提醒的錯誤處理把事件建立失敗、識別碼缺失、連結寫入失敗一律報成「權限被拒」，使用者在權限正常時被要求去改權限。拆成兩條錯誤路徑。

## Non-Goals

- 不處理審查報告中 49 條 warning 與 38 條 suggestion，本次僅收斂在 12 條 blocker。
- 不把 BLPalette 整份改走系統色 API：手抄系統色 hex 是 warning 等級，全面改寫會牽動全部 snapshot baseline，留待後續獨立評估。本次只改 tertiaryLabel 被誤用於資訊文字的那些呼叫點。
- 不實作真正的訂單提醒通知功能：那是新功能而非修 blocker，需要先定義提醒的觸發條件與內容。
- 不改動頭像的色相演算法：維持以名稱推導色相、每位客戶一個專屬色的既有識別性，只調整明度使白字達標。
- 不重造被審查點名的元件（分段控制、搜尋欄、進度條、清單列）：那些是 warning 等級的「重造系統元件」議題，與本次的對比度與命中區修正正交。

## Capabilities

### New Capabilities

- `design-system-color-contrast`: Design System 語意色的對比度契約——文字色與指示色分軌、色值來源、以及各外觀與對比設定下的達標門檻。
- `chart-accessibility`: 三個圖表元件對輔助技術的描述契約——資料點語意、圖表層級摘要、以及裝飾性圖形的排除。
- `control-touch-target`: 可點擊控制項的最小命中區契約——視覺尺寸與命中區解耦的規則。
- `honest-state-feedback`: UI 呈現必須對應實際系統狀態——不呈現無後端支撐的控制項、載入失敗必須顯示原因與復原路徑。

### Modified Capabilities

- `campaign-calendar-reminder`: 既有需求只規範了「權限被拒時顯示說明 alert」，未規範其他失敗情境，導致實作把所有失敗都歸因為權限問題。新增需求區分權限被拒與事件建立失敗兩條錯誤路徑。

## Impact

- Affected specs: design-system-color-contrast、chart-accessibility、control-touch-target、honest-state-feedback、campaign-calendar-reminder
- Affected code:
  - New:
    - apps/ios/BuyLedger/Resources/Assets.xcassets/BLTone（各 tone 的文字色與底色 Color Set，含 High Contrast variant）
  - Modified:
    - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLTone.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Status/BLStatusPill.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Badges/BLBadge.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Avatar/BLAvatar.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLSparkline.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLBarChart.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Charts/BLDonutChart.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/Images/BLPhotoThumbnail.swift
    - apps/ios/BuyLedger/Shared/DesignSystem/Components/TextFields/BLSearchField.swift
    - apps/ios/BuyLedger/Features/Customers/CustomersView.swift
    - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
    - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
    - apps/ios/BuyLedger/Features/FX/FxView.swift
    - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OrderDetailView.swift
    - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
    - apps/ios/BuyLedger/Resources/Localizable.xcstrings（新增錯誤與重試文案的中英值）
    - apps/ios/BuyLedgerTests/__Snapshots__（受配色變更影響的 baseline 需重錄）
  - Removed:
    - 設定頁的通知區塊與其偏好欄位（位於前述 Settings 相關檔案內，非整檔刪除）
