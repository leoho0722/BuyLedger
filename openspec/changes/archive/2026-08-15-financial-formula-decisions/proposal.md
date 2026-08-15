## Why

**無卡折抵沒有上限，可以把收款算成負數。** 輸入端只做「不得為負」的正規化，沒有與實付金額比較。收款的計算是實付金額加補款減折抵，因此折抵大於實付時收款為負、獲利也為負，而毛利率是獲利除以收款，兩個負數相除得到正值。畫面會顯示「獲利 −500 元，毛利率 +23%」。一旦這種資料被存進去，它會污染所有以收款與獲利為基礎的彙總。

**報價頁的欄位叫「目標毛利」，公式卻是成本加成。** 建議售價的算法是成本乘以一加目標值，那是加成率而非毛利率。使用者輸入 30% 時，同一張卡片下方以真毛利公式算出的「預估毛利率」只會顯示約 23%，兩個數字互相打臉，而使用者無從得知該相信哪一個。

**報價頁全程使用二進位浮點數。** 訂單的財務路徑一律使用十進位型別以避免累積誤差，報價頁卻是另一套。同一筆生意在報價與建單兩處算出的金額可能有尾差。

## What Changes

- 無卡折抵金額不得超過實付金額。此上限以資料不變量的形式成立，使收款不可能為負；表單在使用者輸入超額時以可見的方式修正為上限並說明，不得靜默改值。
- 收款為零時不再顯示毛利率數字，改顯示空值。收款為零代表沒有基準可算比率，顯示百分之零是假資料。
- 報價頁的建議售價改用真正的毛利公式：成本除以一減目標毛利。使用者輸入的目標毛利與卡片上顯示的預估毛利率自此一致。
- 目標毛利維持不設上限。當輸入達到或超過百分之百時不計算、不顯示建議售價與預估獲利，改顯示說明文字指出目標毛利需小於百分之百。
- 報價頁的金額計算全面改用與訂單財務路徑相同的十進位型別，浮點數僅保留給圖表繪製。

## Non-Goals

- 不處理商品明細小計與手填商品成本之間缺乏勾稽的問題。該問題需要新增一個參考換算值的呈現，屬獨立的產品決定，本次不擴大範圍。
- 不改變手續費以實付金額為基準的既有作法。刷卡、平台與金流手續費的計算對象是原始收款金額，不因折抵或補款而改變，此設計不變。
- 不改變貨到付款訂單把三種運費計入成本的既有規則。
- 不改變彙總層的歸屬口徑。那屬於同批次的另一個變更。
- 不追溯修正既有已存入的超額折抵資料。上限自本次起對新的寫入生效；既有資料若已超額，於下次編輯儲存時才會被修正。

## Capabilities

### New Capabilities

- `order-financial-formula`: 單筆訂單財務計算的不變量，涵蓋折抵金額的上限、收款不得為負，以及收款為零時毛利率的呈現。
- `quote-pricing-formula`: 報價試算的公式語意，涵蓋目標毛利與建議售價的關係、目標值達到上界時的呈現，以及金額型別的精度要求。

### Modified Capabilities

（無）

## Impact

- Affected specs: `order-financial-formula`（新增）、`quote-pricing-formula`（新增）
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
    - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
    - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
    - apps/ios/BuyLedger/Core/Domain/OrderSummary.swift
    - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
    - apps/ios/BuyLedger/Features/Quote/QuoteView.swift
    - apps/ios/BuyLedgerTests/OrderCalculationTests.swift
    - apps/ios/BuyLedgerTests/QuoteFeatureTests.swift
    - apps/ios/BuyLedger/Resources/Localizable.xcstrings
  - New: （無）
  - Removed: （無）
- 不涉及 SwiftData schema 或資料形狀；既有資料零影響。
- 報價頁與訂單詳情的視覺快照基準需重錄，因金額格式與新增的說明文字會改變版面。
- 次序約束：本變更必須排在彙總歸屬守門之後、付款方式旗標回溯之前，因為三者都改動訂單編輯的正規化路徑。
