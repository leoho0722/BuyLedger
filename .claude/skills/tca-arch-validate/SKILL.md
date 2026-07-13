---
name: tca-arch-validate
description: BuyLedger TCA 架構驗證。檢查 SwiftUI View 是否違反 TCA 分層 (View 直接改 Store 狀態、在 View 做業務邏輯)，並提供修正 pattern。動 store-bound View 或想稽核 TCA 分層時 invoke。
---

BuyLedger 用 The Composable Architecture (TCA)。本 skill 驗證 View 層是否守住「View 只描述畫面與送 action，狀態變更一律回到 reducer」的分層。

## 核心規則

1. **View 不得直接寫 Store 狀態**：View 內**不可**出現 `store.xxx = value`、`store.xxx.append(...)`、`store.xxx.remove(...)` 等對 store 狀態的寫入/mutate。使用者操作 (按鈕、onSelect、onDelete、onTap、onDismiss…) 一律 `store.send(.someAction)`，由 reducer 改狀態。
2. **合法例外——表單控件的 `$store.xxx` 雙向 binding**：`TextField`／`Picker`／`Toggle`／`DatePicker`／`.sheet(isPresented:)`／`.sheet(item:)` 等 SwiftUI 控件用 `$store.xxx` 兩向 binding 是**合法**的 (SwiftUI-TCA 的 binding 機制，經 `BindableAction`／`BindingReducer`)。這與「View 主動寫 `store.x = v` 陳述式」不同——前者是控件自身的雙向綁定，後者是 View 程式碼主動指派。
3. **不在 View 做業務邏輯／建構 domain 物件**：例如 `store.draftItems.append(LedgerOrderItem(...))` 在 View 建構 `LedgerOrderItem` 屬違規；改送 `.addItemTapped`，由 reducer 建構。
4. **presentation 狀態仍留 Feature.State**：sheet／alert 開關等下放 `Feature.State`；「開啟」由 action 觸發 (reducer 設 `state.showsXxx = true`)，`.sheet(isPresented: $store.showsXxx)` 的 binding 僅供 SwiftUI 呈現/收合。

## 偵測

```bash
# 全 View 直接寫 store 狀態 (排除 $store binding / store.send / 讀取)
grep -rnE "store\.[a-zA-Z]+ = |store\.[a-zA-Z]+\.(append|remove|removeAll|insert|removeValue)" \
  --include="*View*.swift" --include="*Layout*.swift" apps/ios/BuyLedger \
  | grep -v ".generated" | grep -v "store.send" | grep -vE "== nil|!= nil"
```
命中的每一行 (排除 `$store.` binding 與純比較) 都是待修違規。

## 修正 pattern

每個 `store.x = v` 違規三步到位：

1. **Action** (`Feature.Action` enum)：加語意化 case
   - 選取類 → `case xSelected(V)`
   - 呈現開關 → `case xPickerTapped` / `case xSheetRequested`
   - 集合變更 → `case addItemTapped` / `case deleteItems(IndexSet)`
2. **Reducer handler**：
   ```swift
   case let .xSelected(value):
       state.x = value
       return .none
   ```
3. **View** 呼叫端：`store.x = v` → `store.send(.xSelected(v))`

### 踩雷
- **保留既有副作用**：若 feature 的 `.binding` 帶副作用 (如 `SettingsFeature` 在變更時存檔)，新 action 的 handler 必須觸發等效副作用，別漏掉。
- **表單 binding 不要動**：`$store.draftName`、`.sheet(isPresented: $store.showsX)` 等保持原樣。
- 改完務必 `build_sim` + 跑該 feature 的 `*FeatureTests` (既有測試不得回歸)，並補新 action 的測試。

## 驗證結論
掃描命中歸零 (只剩 `$store.` binding 與讀取) 即通過。
