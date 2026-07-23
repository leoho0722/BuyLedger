# 篩選膠囊抽取前的現況基準

抽成共用元件前逐處記錄，作為元件參數設計依據與抽取後的驗收比對基準。
量測自 2026-07-20 的 `main`（commit `5a36e30`）。

## 六處清單

| # | 位置 | 用途 | 字級 | 垂直內距 | 水平內距 | 未選前景 | 未選背景 | 已選前景 | 已選背景 | 前綴圖示 | 尾端圖示 |
|---|------|------|------|----------|----------|----------|----------|----------|----------|----------|----------|
| 1 | `OrdersCompactView.chipButton` | 狀態篩選 | `.subheadline` semibold | 7 | 14 | `secondaryLabel` | `fillTertiary` | `background` | `label` | — | — |
| 2 | `OrdersCompactView.unifiedFilterTrigger` | 整合篩選 trigger | `.subheadline` semibold | 7 | 14 | `secondaryLabel` | `fillTertiary` | `purple` | `purple` 18% | `line.3.horizontal.decrease` | `chevron.down` |
| 3 | `OrdersView.chipScrollStrip` | 狀態篩選 | `.footnote` semibold | 7 | 12 | `secondaryLabel` | `fillTertiary` | `background` | `label` | — | — |
| 4 | `OrdersView.dateChipScrollStrip` | 日期區間篩選 | `.footnote` semibold | 7 | 12 | `secondaryLabel` | `fillTertiary` | `accent` | `accent` 18% | `calendar` | — |
| 5 | `OrdersView.categoryFilterTrigger` | 類別 trigger | `.footnote` semibold | 7 | 12 | `secondaryLabel` | `fillTertiary` | `purple` | `purple` 18% | `tag` | `chevron.down` |
| 6 | `OrdersView.paymentMethodFilterTrigger` | 付款方式 trigger | `.footnote` semibold | 7 | 12 | `secondaryLabel` | `fillTertiary` | `purple` | `purple` 18% | `creditcard` | `chevron.down` |

## 觀察到的差異

- **字級與水平內距隨平台分歧**：compact（1、2）用 `.subheadline` ＋ 14pt，regular（3–6）用 `.footnote` ＋ 12pt。垂直內距六處一致為 7pt。
- **選取態配色有三種語意**：狀態篩選用反白（`label` 底＋`background` 字）、日期用 `accent`、類別／付款方式／整合篩選用 `purple`。
- **圖示配置有三種**：無圖示、僅前綴、前綴＋尾端 `chevron.down`。
- **trigger 類（2、5、6）撐滿寬度**：`frame(maxWidth: .infinity, alignment: .leading)` ＋ `fixedSize(horizontal: false, vertical: true)`，可換行；篩選類（1、3、4）為 `lineLimit(1)` 的自然寬度。

## 元件參數推導

由上表收斂出的最小參數集（不提供六處用法以外的彈性）：

- `title`：膠囊文字（`LocalizedStringKey`）
- `isSelected`：選取狀態
- `style`：選取態語意（`.inverted` 反白／`.accent`／`.purple`）
- `icon` / `trailingIcon`：選用的前綴與尾端圖示
- `isExpanded`：是否撐滿寬度並允許換行（trigger 類為 `true`）
- `size`：`.large`（`.subheadline` ＋ 14pt，compact 的 1、2 使用）／`.standard`（`.footnote` ＋ 12pt，regular 的 3–6 使用）
- `action`：點擊動作

`size` 之所以入參而非統一：本 change 的驗收要求「六處視覺與變更前一致，差異僅來自命中區」，統一字級會讓 compact 兩處縮小、混進非預期的視覺變化。字級收斂應另案處理（若要做）。

## 命中區現況

六處皆為 `Text`／`HStack` ＋ `padding(.vertical, 7)`，實際高度約 `字高 + 14`：`.footnote`（13pt）約 **31pt**、`.subheadline`（15pt）約 **33pt**，皆低於 44pt 下限。

抽取後以 `frame(minHeight:)` ＋ `contentShape(.capsule)` 在標籤內部把命中區撐到 44pt。膠囊視覺高度不變（由內距決定），僅命中區外擴；形狀宣告用 `.capsule` 而非外接矩形，避免相鄰膠囊的命中區在圓角處重疊。
