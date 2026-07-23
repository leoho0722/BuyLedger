## Why

本 change 收斂審查中兩類彼此相關的 warning：介面呈現的內容是否誠實，以及視覺基礎是否建立在系統機制之上。

內容誠實方面，報價試算在沒有可用匯率時仍渲染完整的建議售價與成本拆解，只是所有金額都是零——橫幅雖寫著「尚無可用匯率資料」，畫面上卻是一組看起來像真實計算結果的數字，這與專案自訂政策「寧可顯示空狀態也不顯示假資料」直接衝突。AI 總結的錯誤文案對使用者露出 build 時的環境變數名稱，而使用者無從設定它——它來自建置設定，App 內沒有任何輸入處。首次載入是一顆填滿畫面的轉圈，沒有任何版面骨架，內容出現時整頁跳變。匯率載入失敗只有一條靜態橫幅，整頁沒有重試入口，使用者唯一的復原方式是離開分頁再回來，而這件事畫面上沒有提示。

視覺基礎方面，整份色盤以手抄系統色的十六進位值構成，這些值不會跟隨系統版本演進，也拿不到增強對比與 vibrancy；強調色資源檔案沒有定義任何色值，導致系統元件取用的強調色與色盤自訂的強調色是兩套互不同步的來源。總覽頁的主卡以不透明度降階表達層級，把白字對比壓到最低 2.03:1。色盤另定義了兩個以半透明色手工模仿玻璃材質的項目，目前無任何呼叫端，是等著被誤用的陷阱。訂單詳情的自繪標題列以不透明底色模仿系統導覽列，使捲動內容在其邊緣停住而非延伸至其下方。

此外設定頁提供 App 內的外觀切換覆寫系統設定，而行事曆權限被拒的提示要求使用者去系統設定卻沒有提供跳轉。

## What Changes

### 內容誠實

- 報價試算在無可用匯率時以空狀態取代零值數字，不繪製零值的成本拆解。
- AI 錯誤文案改為使用者語彙，診斷資訊改走記錄而非介面。
- 首次載入改以既有版面的骨架呈現，轉圈降為逾時後才疊加。
- 匯率載入失敗補上重試入口，與 AI 總結既有的失敗呈現一致。

### 視覺基礎回歸系統機制

- 色盤的語意色與系統色改走系統取色介面，取得增強對比與 vibrancy，並移除亮暗兩套手抄值的分支。
- 強調色資源補齊色值與增強對比變體，色盤的強調色改為引用它，並於根層統一設定。
- 總覽頁主卡移除以不透明度降階的作法，層級改以字重與字級表達，漸層調整至白字達標。
- 移除手工模仿玻璃材質的色盤項目。
- 訂單詳情的自繪標題列改由系統承載或改用系統材質，使捲動內容延伸至其下方。

### 尊重系統設定

- 移除 App 內的外觀切換，一律跟隨系統。
- 權限被拒的提示補上前往系統設定的按鈕。

## Non-Goals

- 不處理 blocker 與 suggestion 等級的發現。對比度的驗證基礎設施由 hig-blocker-remediation 建立，本 change 沿用它驗證總覽頁主卡，因此應排在該 change 之後實作。
- 不納入以可轉換分頁樣式取代尺寸類別分流的架構重構，該項與訂單列表三欄分割一併另案評估。
- 不改用較新系統版本才具備的玻璃材質介面作為主要實作，因部署目標涵蓋較舊版本；僅在可用性判斷成立時採用。
- 不新增分頁縮小等較新系統版本的行為，該項屬 suggestion 等級。
- 不實作 AI 總結服務本身的設定介面。

## Capabilities

### New Capabilities

- `content-truthfulness`: 介面內容的誠實性契約——無資料不繪製零值、錯誤文案使用使用者語彙、載入有骨架、失敗有復原路徑。
- `color-system-foundation`: 色彩來源的契約——語意色走系統取色、強調色單一來源、層級不以不透明度降階表達。
- `material-and-bar-treatment`: 材質與 bar 的處理契約——不以不透明底色模仿系統 bar、不以半透明色手工模仿材質。
- `system-setting-deference`: 系統層級設定的尊重契約——不在 App 內重複系統設定、需使用者前往系統設定時提供跳轉。

### Modified Capabilities

(none)

## Impact

- Affected specs: content-truthfulness、color-system-foundation、material-and-bar-treatment、system-setting-deference
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLPalette.swift
    - apps/ios/BuyLedger/Shared/Extensions/Color+Extensions.swift
    - apps/ios/BuyLedger/Resources/Assets.xcassets/AccentColor.colorset
    - apps/ios/BuyLedger/Features/App/RootView.swift
    - apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift
    - apps/ios/BuyLedger/Features/Insights/InsightsView.swift
    - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
    - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
    - apps/ios/BuyLedger/Features/FX/FxView.swift
    - apps/ios/BuyLedger/Features/FX/FxFeature.swift
    - apps/ios/BuyLedger/Features/AISummary/AISummaryFeature.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsSnapshot.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsStorage.swift
    - apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift
    - apps/ios/BuyLedger/Resources/Localizable.xcstrings
    - apps/ios/BuyLedgerTests/__Snapshots__
  - Removed:
    - apps/ios/BuyLedger/Features/Settings/AppearancePreference.swift
