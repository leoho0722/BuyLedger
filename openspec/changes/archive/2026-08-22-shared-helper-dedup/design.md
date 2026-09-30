## Context

BuyLedger 的金額與百分比呈現規則原本散落在多個 feature 與 view helper 中。這些實作使用相同的幣別代碼、精度與 App locale，但各畫面自行維護，因此任何呈現規則的調整都需要同步修改多個位置。

本 change 已建立 `BLFormatters` 作為 Shared DesignSystem Foundations 的共用入口，並以明確的 `Locale` 參數隔離格式化結果與執行環境。現有 `OrderFormatters` 與 `CampaignFormatters` 仍可能承載日期、時間或訂單／開團專屬格式化；本 change 只收斂金額與百分比規則，不要求刪除仍有其他職責的 feature helper。

另外，Dashboard、Insights 與訂單詳情原本以量測容器搭配軌道與填色形狀繪製 determinate progress。這會重造系統 `ProgressView` 已提供的語意與輔助技術行為。專案已有 `BLProgressBarStyle`，因此收斂方向是讓這些呼叫點使用系統進度視圖與既有樣式，而不是新增另一個自訂進度元件。

## Goals / Non-Goals

**Goals:**

- 讓金額與百分比的呈現規則由 `BLFormatters` 單一來源提供。
- 保留既有金額、百分比、空值與 locale 的輸出結果。
- 讓 Dashboard、Insights、Customers、FX 與 Quote 的相關呈現使用共用格式化入口。
- 讓 determinate progress 使用 `ProgressView` 與 `BLProgressBarStyle`，使進度值可被輔助技術讀取。
- 保留 Dashboard 疊在漸層背景上的視覺需求，透過既有樣式的可選軌道色處理，而不建立第二套 progress 元件。
- 以單元測試、搜尋守門與 UI／snapshot 回歸確認收斂沒有造成非預期行為變更。

**Non-Goals:**

- 不改變金額或百分比的幣別、精度、負數表示、佔位符或 locale 語意。
- 不刪除仍負責日期、時間、訂單或開團專屬格式化的 feature helper。
- 不建立新的設計系統元件或新的格式化協定。
- 不收斂空狀態文案、其他相似但語意不同的格式化規則或非 determinate 的裝飾形狀。
- 不改動 SwiftData schema、財務計算、TCA state/action 或持久化資料。

## Decisions

### 共用格式化入口

以無 case 的 `BLFormatters` namespace 放置跨畫面共用規則，公開四個明確的靜態介面：

- `twd(_:locale:)` 接受 `Decimal`，使用 `CurrencyCode.twd.code`、零位小數與傳入 locale。
- `twd(_:locale:)` 的 optional overload 對 `nil` 回傳 `—`，對非 `nil` 委派至非 optional overload。
- `percent(_:locale:)` 接受 0 到 1 的比例，使用百分比 formatter 與一位小數。
- `percent(scaled:locale:)` 接受已經是百分比尺度的數值，使用數字 formatter 加上 `%`，避免把 65.4 再乘成 6,540%。

選擇明確的 namespace 與 overload，而不是把規則放進 `Decimal` extension，是為了讓呼叫端清楚表達呈現用途，也避免把 UI locale 與領域數值型別耦合。選擇把 locale 作為參數傳入，而不是在 formatter 內讀取全域設定，是為了讓測試可重現並維持既有畫面依 App 設定呈現的行為。

**既有 feature helper 的責任邊界：**

目標畫面直接使用 `BLFormatters` 的金額與百分比入口；既有 `OrderFormatters`／`CampaignFormatters` 若仍提供日期、時間、訂單摘要或開團專屬格式化則保留其 namespace。若某個 feature helper 的金額或百分比 API 因其他呼叫點仍需保留，實作只能委派至 `BLFormatters`，不可再持有一份等價 formatter 規則。

替代方案是一次刪除整個 feature helper，但這會把本案範圍擴張到日期與領域專屬呈現，並增加無關的呼叫點變更；因此不採用。

### 手繪進度條收斂

Dashboard、Insights 與訂單詳情的 determinate progress 統一使用 `ProgressView(value:)`，並套用既有 `BLProgressBarStyle`。呼叫端傳入的 fraction 仍遵守原本的 0 到 1 語意；需要保護輸入範圍的畫面先在呼叫點夾值，`BLProgressBar` 本身也維持其既有的夾值行為。

`BLProgressBarStyle` 增加具預設值的可選 `track` 參數。一般呼叫維持原本的 palette track；Dashboard 的 hero 卡則傳入與底色協調的半透明白色 track。這是既有樣式擴充點的向後相容擴充，不是新增自訂元件。

選擇系統 `ProgressView` 而不是保留 `GeometryReader`、`Capsule` 與填色寬度的手繪組合，是為了取得系統提供的 progress 語意與 accessibility value。選擇延伸既有 `BLProgressBarStyle` 而不是另建樣式，是為了讓三個呼叫點共用相同的高度、軌道與填色規則。

### 確認純裝飾用途的形狀未被誤改

作為 loading placeholder、標籤底色、裁切外框、圖例色點或 heatmap 格子的 `RoundedRectangle`／其他 Shape 不承擔系統元件提供的互動或語意，因此不在進度條收斂範圍內。掃描守門只針對「量測容器 + 軌道形狀 + 填色形狀」的 determinate progress 組合，不把純裝飾形狀誤判為重造系統能力。

### 驗收

先以 `BLFormattersTests` 鎖定正數、零、負數、大數、optional nil、ratio 與 scaled percentage 的既有輸出，再以全專案搜尋確認目標畫面不再持有等價的私有金額／百分比規則。進度條則確認三個呼叫點使用 `ProgressView` 與 `BLProgressBarStyle`，並以 UI automation 讀取其 accessibility value。

因為 formatter 收斂預期不改變文字結果，既有 snapshot 原則上不需重錄；若 progress style 造成已知的高度差異，只能在確認是共用樣式的預期結果後更新對應 baseline，並逐張檢查視覺差異。主 scheme 單元測試與 UI 主回歸必須維持綠燈。

## Implementation Contract

**行為：**

- Dashboard、Insights、Customers、FX 與 Quote 的金額／百分比文字與 accessibility value 維持收斂前的輸出。
- `BLFormatters.twd` 對 `Decimal` 以新台幣、零位小數與傳入 locale 格式化；optional overload 對 `nil` 顯示 `—`。
- `BLFormatters.percent` 將比例值格式化為一位小數的百分比；`percent(scaled:)` 將已是百分比尺度的數值格式化為一位小數並附加 `%`。
- Dashboard、Insights 與訂單詳情的 determinate progress 以系統 `ProgressView` 呈現，並由 `BLProgressBarStyle` 提供一致的軌道與填色外觀。

**介面與資料形狀：**

- 共用 formatter 介面為 `BLFormatters.twd(_:locale:)`、`BLFormatters.percent(_:locale:)` 與 `BLFormatters.percent(scaled:locale:)`，其輸入為 `Decimal`／`Decimal?` 與 `Locale`，回傳 `String`，不拋出錯誤。
- `BLProgressBarStyle` 保留 `tint`，並提供具預設值的 optional `track`；未傳入 `track` 時沿用 palette 的既有軌道色。
- 不新增持久化欄位、schema 版本、外部依賴或 TCA action/state。

**失敗模式：**

- optional 金額為 `nil` 時不拋錯，固定回傳 `—`。
- ratio 與 scaled value 的尺度由不同 overload 明確區分；呼叫端傳錯尺度時不由 formatter 猜測或自動修正，應由呼叫端選擇正確介面。
- progress fraction 超出範圍時，既有 `BLProgressBar` 與需要它的呼叫點將值限制在 `0...1`；不以超出容器寬度的手繪結果呈現。
- 本 change 不新增網路、持久化或其他可恢復錯誤，因此不新增 error UI 或 retry flow。

**驗收標準：**

- `BLFormattersTests` 覆蓋正數、零、負數、大數、optional nil、ratio 與 scaled percentage，且輸出與既有基準一致。
- 目標畫面不再定義等價的金額／百分比格式化規則；仍保留的 feature helper 其共用金額／百分比方法委派至 `BLFormatters`。
- Dashboard、Insights 與訂單詳情的 determinate progress 呼叫點皆使用 `ProgressView` 加 `BLProgressBarStyle`；手繪 track-and-fill progress 組合零命中。
- UI automation 可在 Dashboard、Insights 與 iPad 訂單詳情讀取 progress 的 accessibility value。
- 主 scheme 全套 Unit Tests、UI 主回歸與受影響 snapshot 比對皆通過；不得以刪除測試或放寬既有門檻換取綠燈。

**範圍邊界：**

- 在範圍內：`BLFormatters`、五個目標畫面的金額／百分比呼叫點、進度條三個呼叫點、`BLProgressBarStyle` 的 optional track、格式化單元測試與相關回歸驗證。
- 不在範圍內：日期／時間／訂單／開團專屬 formatter、純裝飾 Shape、空狀態文案、財務計算、資料模型、TCA 狀態與 action、其他尚未證明等價的重複 helper。

## Risks / Trade-offs

- [不同呼叫端把 ratio 與 scaled value 混用] → 以不同方法簽名區分兩種尺度，並以 ratio、scaled value 與大於 100% 的測試固定契約。
- [刪除 feature helper 時誤傷日期或領域專屬格式化] → 只移除等價的金額／百分比實作；仍有其他職責的 helper 保留，必要的共用方法改為委派。
- [ProgressView 收斂造成軌道高度或外觀細節變化] → 所有呼叫點使用同一個 `BLProgressBarStyle`，Dashboard 以 optional `track` 保留漸層背景上的對比，並以 UI／snapshot 回歸確認差異是預期的。
- [純裝飾形狀被掃描器誤判而被不必要移除] → 將「量測容器 + track/fill」定義為守門模式，loading、label background、clipping、legend 與 heatmap 維持在非範圍內。
- [formatter 入口與畫面 locale 脫鉤] → 所有入口要求呼叫端傳入 `Locale`，不在共用層讀取隱含的全域 locale。

## Migration Plan

本 change 不涉及資料遷移或部署階段。實作順序為先加入 `BLFormatters` 與行為保存測試，再替換目標畫面的呼叫點，接著將 determinate progress 改為 `ProgressView`，最後執行搜尋守門、Unit Tests、UI automation 與 snapshot 比對。若回歸發現非預期差異，回退對應呼叫點或樣式參數即可，不需要資料庫 rollback。

## Open Questions

無。ratio 與 scaled value 的輸入契約、optional 金額的佔位符、progress 的樣式擴充方式與純裝飾 Shape 的範圍均已由現有實作、proposal、delta specs 與驗收任務決定。
