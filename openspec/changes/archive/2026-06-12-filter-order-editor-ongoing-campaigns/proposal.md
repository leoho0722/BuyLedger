## Why

訂單編輯器的「開團」選單目前列出所有現有開團 (含已收單)。隨著開團數量累積，選單會越來越長、難以選取；而實務上歸團幾乎只會歸到「還在收單」的開團。將選單篩成「只列開團中」可大幅縮短清單、貼合實際歸團情境。

## What Changes

- 訂單編輯器的開團選單 (一般訂單的單選下拉、合併情境的多選 sheet) 改為只列出狀態為「開團中 (ongoing)」的開團；已收單 (closed) 的開團不再出現在可選清單。
- 「未歸團」永遠是可選項，語意不變 (空選即未歸團)。
- 為避免既有歸屬遺失：正在編輯的訂單若已歸屬到某個現在已收單的開團，該開團仍保留為可見選項；合併情境中由來源訂單帶入的既有開團 (即使已收單) 也一併保留。
- 開團選單資料改由編輯器自身載入 (比照其餘主檔清單)，使所有入口 (Orders 分頁新增／編輯、Dashboard 直接新增、冷啟動直衝) 行為一致，不再依賴呼叫端傳入。

## Non-Goals

- 不改變開團本身的狀態模型 (仍為 ongoing／closed 兩態) 與結單日到期自動轉狀態的規則。
- 不改變訂單列表「依開團狀態篩選」的行為 (order-campaign-filter capability)。
- 不在編輯器內新增開團 (維持既有限制)。
- 不改變「空選即未歸團」以及「一般訂單單選、合併情境多選」的既有區分。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `order-campaign-assignment`: 「The order editor selects from existing campaigns only」需求新增狀態限定——編輯器可選清單只含開團中的開團，但任一已歸屬的既有開團 (即使已收單) 必須保留為可見選項，避免既有歸屬在選單中消失。

## Impact

- Affected specs: order-campaign-assignment
- Affected code:
  - Modified:
    - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
    - apps/apple/BuyLedger/Features/Orders/OrderEditFeature.swift
