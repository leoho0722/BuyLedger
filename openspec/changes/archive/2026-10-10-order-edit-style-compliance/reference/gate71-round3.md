# 7.1 第三輪紀錄 (2026-10-09)

第二輪之後改到的 185 檔 (production 68、測試 117) 分 12 組唯讀重審，準則為第二輪準則加上第二輪裁決 1～6 與 716／722／723 設計的裁決。各組完整報告在 session scratchpad `gate71/k01.txt`～`k12.txt`。

## 主對話判定：要修

- **測試名第一段取最外層 Action**：7.16、7.22 把容器的 `destination` 收進呈現子 Feature 後，送 `.presentation(.destination(…))` 的 55 條測試仍以 `destination_` 開頭，改為 `presentation_`；推入路徑的測試改 `detail_`；When 實際送出 `noticeRequested`、合併確認到期的測試跟著改。
- **關聯值超過一個要有 label**：`OrderWritesFeature` 的 `mergeResponse`、`optionResponse`，`OrdersPresentationFeature` 的 `mergeCandidateCompleted`、`mergeConfirmationDue`，`OrdersFeature` 的 `receiptStatusChangeRequested`。
- **Action 次序**：`RootFeature` 的 `launch`、`RootLaunchFeature` 與 `CampaignPresentationFeature` 的 `delegate` 位置；`RootLaunchFeature.loadRequested` 依字母排在 `currencyCodesResponse` 之後。
- **命名**：`handleRequest` → `fulfill`；`popsUnavailableDetails` → `shouldPopUnavailableDetails`、`notifies` → `shouldNotify`；型別後綴不在專案慣例內的 `MergePhotoCell` → `MergePhotoTile`、`OrderFilterPreviewState` → `OrderFilterPreviewFixtures`、`OrdersCompactListContent` → `OrdersCompactListView`。
- **`OrderRowView` 整檔對齊** (7.19 改名波及)：Properties 順序、body 只放大框架、類別標籤與朗讀值組字與正負號移到 `OrderFormatters`。
- **其他**：空本體 `extension …: Equatable {}` 改多行；三層 optional chaining 拆開；方法依呼叫者在前；只本檔用的成員改 `private`；Given 能直設的不用 `send` (含第二輪 g09 兩項未落實者)；`clock.advance` 留在 Then 或 Given；doc 不只複述名稱、識別字反引號、store doc 標準措辭、沿革用語改現行描述；`RootSidebarLayout` 固定點數改 `@ScaledMetric`。

## 不算違規

- `StatusFailures`、`DeleteEditFailures` 以 `reloadedOrders` 為預期 (第二輪 g14 已判定為測試替身紀錄)；單側正規化 (第二輪 g13)。
- `ContrastComplianceTests` 第一段為受測 token 屬性 (7.20 判定)；`retiredKeys_`、`content_` 第一段為受測資料或屬性。
- `@Test` 宣告 `throws(any Error)` 與 `throws` 等價；`@Test(arguments:)` 用未標籤 tuple 為全庫慣例。
- 父層 `.merge` 多個子層請求 action 是 CLAUDE.md 規定的寫法，不屬 kit 避免的「送 action 給自己共用邏輯」。
- `@Bindable var presentation = store.scope(...)` 為導覽規則與 716 設計明定；計畫型別 `import SwiftUI` 組 `TextState(LocalizedStringKey)` 與 Destination 一致；模組名 `SwiftUI` 加反引號。
- `OrderMergeFeature.State.init` 以區域 `@Dependency(\.uuid)` 產生 id 為既有寫法，改動屬行為重構。
- Preview fixture 未包 `#if DEBUG` 屬 build 設定；照片遮罩不透明度不是文字層級降階；`"篩選: %@"` 為字串目錄既有 key。
- 首頁與分析頁畫面計算依 design Non-Goals 屬第 7 步。

## 延後

- `.quaternary`／`.tertiary` 等直接使用的系統階層色改走色盤：留給結案後的色盤 `ShapeStyle` 重構 (同第二輪 g02 P3)。
- 4 則範圍外既有編譯警告 (`SignificantTimeChangeServiceTests:28`、`OrderServiceTests+Reads:130`、`ColorContrast:66`／`:67`)。
