## Context

BuyLedger 目前在 iOS 與 iPadOS 平台採用正體中文作為 String Catalog（`Localizable.xcstrings`）的 Key。雖然當初快速支援了雙語切換，但以中文為 Key 存在多項架構缺陷：
1. **文案與程式碼強耦合**：文案調整會使 Key 改變，導致程式碼、測試與快照關聯連帶受到波及。
2. **同詞異義歧義 (Ambiguity)**：如「取消」、「確定」、「待處理」在不同視圖與動作中需翻譯為不同英文詞彙（如 Dismiss vs Cancel vs Abort），以中文為 Key 會產生語境污染。
3. **跨平台相容性受限**：未來 Monorepo 將納入 Android 平台，Android 資源命名必須為英數字識別碼。
4. **格式化工具中中文寫死**：`BLFormatters.daySectionTitle` 直接回傳 `"今天"` 與 `"昨天"` 字串，在英文模式下露出中文。
5. **缺少嚴格格式化與單複數規則**：多參數未強制使用位置標記（`%1$lld`），英文單複數未能完全透過 String Catalog 的 Plural substitutions 進行正規化。
6. **目錄冗餘與非本地化字串污染**：遷移初期生成的重複通用 Key、歷史重構廢棄的孤立 Key，以及視圖中因未加 `verbatim:` 而被 Xcode 自動萃取的純符號與品牌名，造成目錄體積虛胖與維護雜訊。

在完成規範制定、格式化工具修復與守門測試基礎後，依據使用者明確指示，本變更全面推進全 App 所有本地化字串的改寫、字串目錄瘦身與非本地化字面值防禦。

## Goals / Non-Goals

**Goals:**
- 定義標準結構化英文 Key 格式 `<domain>.<component>.<elementType>.<descriptor>`，複合詞採 `lowerCamelCase`。
- 更新 `openspec/specs/app-localization/spec.md` 政策規格，移除過期條款並補齊結構化 Key、單複數、多參數與資料邊界要求。
- 修正 `BLFormatters.daySectionTitle` 中寫死「今天 / 昨天」字串的問題，使其依照注入的 AppLanguage / Locale 正確本地化。
- 升級 `LocalizationCatalogTests` 守門測試，支援新 Key 格式檢查、中英文對照完整性與禁止拼接字串規則。
- 將 `Localizable.xcstrings` 中既有的全部 499 條中文 Key 全量改寫為結構化英文 Key。
- 將全 App 所有模組（Shared、Dashboard、Insights、Orders、Campaigns、Customers、Settings 等）的生產代碼與測試呼叫端全量改寫為結構化英文 Key。
- 達成字串目錄內 100% 結構化英文 Key，徹底移除舊有中文 Key 殘留。
- 安全移除目錄中未使用的通用重複 Key（如 `common.general.message.deletingCannot`）與歷史廢棄死碼 Key（共約 50 條）。
- 將視圖中誤入目錄的排版符號、品牌名稱、語言自稱與預覽假資料改寫為 `Text(verbatim:)`，並從字串目錄移除對應的 `shouldTranslate: false` 條目。

**Non-Goals:**
- 變更 App 既有的語言持久化方式（維持 `SettingsStorage`）或支援正體中文與英文以外的第三種語言。
- 變更使用者輸入資料（如客戶名、商品名、自訂分類）與外部標識符（幣別代碼、系統錯誤碼）的 verbatim 呈現邊界。
- 變更現有任何畫面的視覺呈現或佈局排版。

## Decisions

### 結構化英文 Key 格式與命名範式 (Structured English Key Hierarchy and Naming Convention)

**決策**：String Catalog 的 Key 統一規範為 `<domain>.<component>.<elementType>.<descriptor>` 點記號層級結構。
- `domain`：業務模組（如 `common`、`orders`、`campaigns`、`dashboard`、`insights`、`settings`、`error`）。
- `component`：視圖或元件（如 `list`、`detail`、`edit`、`filter`、`row`、`toolbar`）。
- `elementType`：元素類別（限定 `title`、`button`、`action`、`label`、`field`、`placeholder`、`message`、`hint`、`status`、`accessibility`）。
- `descriptor`：具體語意，優先使用單一動詞或名詞（如 `save`、`cancel`、`pending`）；複合語意一律使用 `lowerCamelCase`（如 `saveAndContinue`、`pendingPayment`、`selectedCount`）。

**替代方案評估**：
- *snake_case (如 `save_order`)*：Swift 識別碼風格與 Xcode `STRING_CATALOG_GENERATE_SYMBOLS` 自動產生的強型別符號為小駝峰，使用 snake_case 會導致在 Swift 代碼搜尋與在 String Catalog 搜尋名稱不對稱。
- *英文自然語言 (如 `Save Order`)*：無法解決同詞異義（Context disambiguation），且英文文案潤飾會直接導致 Key 變更。

### 參數位置標記與 String Catalog 單複數 Substitutions (Positional Arguments and Plural Substitutions)

**決策**：
1. 包含兩個（含）以上參數的格式化字串，強制使用位置標記（如 `%1$lld`、`%2$@`），允許不同語言在翻譯時安全調整詞序而不破壞型別。
2. 英文數值單複數差異交由 String Catalog 的 `plural substitutions` 機制處理，禁止在 Swift 業務邏輯中以 `if count == 1` 進行文案分流。

### 格式化工具的語言依賴注入與修復 (Formatter Language Injection and Date Header Repair)

**決策**：
修正 `BLFormatters.daySectionTitle`。該方法將今天與昨天改由傳入的 `AppLanguage`（或使用本地化資源）解析，確保在英文模式下分別回傳 `"Today"` 與 `"Yesterday"`，徹底消除英文模式下日期標題露出中文的缺陷。

### 靜態守門測試轉型與文字防拼接驗證 (Static Guardrails Evolution and Anti-Concatenation Enforcement)

**決策**：
升級 `LocalizationCatalogTests`：
1. 新增 Key 格式正規式驗證，確保新收錄的英文 Key 嚴格符合四段式點記號與 `lowerCamelCase`。
2. 驗證新 Key 在 `zh-Hant` 與 `en` 目錄中皆有非空白值。
3. 嚴格禁止在 UI 代碼中透過 `+` 拼接本地化 `Text`，複合訊息必須在目錄中建立單一帶參數的 Key。

### 全量本地化字串漸進遷移策略 (Full Localization Migration Strategy: Expand-Migrate-Contract)

**決策**：
為確保龐大代碼庫（499 條中文 Key、數十個視圖與功能模組）遷移過程零破壞、CI 隨時保持綠燈，採取四階段垂直切分：
1. **Expand（擴充階段）**：建立 1:1 映射字典，在 `Localizable.xcstrings` 中注入所有結構化英文 Key，新舊 Key 雙軌並存。
2. **Migrate（分批遷移階段）**：
   - Batch 1: Shared、DesignSystem、App、Settings、More 核心模組。
   - Batch 2: Dashboard、Insights、AISummary 總覽分析模組。
   - Batch 3: Orders、Lookups 訂單模組。
   - Batch 4: Campaigns、Customers、Quote、FX 開團業務模組。
3. **Contract（收縮階段）**：測試套件同步更新斷言，徹底移除 `Localizable.xcstrings` 內所有舊中文 Key。
4. **Enforce（全面守門）**：將 `LocalizationCatalogTests` 守門條件全面收緊為 100% 結構化英文 Key，杜絕未來任何中文 Key 殘留。

### 非本地化字串防禦與 Verbatim 邊界落實 (Non-Localizable Literal Preservation and Verbatim Boundary Enforcement)

**決策**：
嚴格遵守 `openspec/specs/app-localization/spec.md` 中的 `Verbatim preservation for user data and external content` 條款與國際化規範：
1. **排版符號與格式符號**（如 `·`、`%`、`""`）：在 UI 視圖中一律改用 `Text(verbatim:)` 或由 Swift 格式化工具處理，禁止作為未標記的 `LocalizedStringKey`，防範 Xcode 編譯時自動將其收錄為 `shouldTranslate: false` 條目。
2. **品牌專有名詞**（`BuyLedger`、`BL`、`VIP`）：全球維持品牌原樣，視圖呼叫端統一使用 `Text(verbatim: "BuyLedger")`。
3. **語言原文自稱 (Endonym)**：在語言切換選單中，`English` 永遠顯示為 `English`，不應受當前 App 語言影響而被翻譯。
4. **預覽假資料**：`#Preview` 程式碼中的硬編碼資料（如 `$12,480`、`0`）全面補上 `verbatim:`。
5. **目錄精簡**：自 `Localizable.xcstrings` 中徹底刪除上述非本地化之純符號、純佔位符與假資料條目。

### 字串目錄瘦身與死碼清理策略 (Catalog Pruning and Dead Key Elimination)

**決策**：
對 `Localizable.xcstrings` 進行全面瘦身，安全剔除兩類在專案中已無任何呼叫端引用的死碼條目：
1. **過渡期通用 Key**：在 Expand 階段生成的 `common.general.*` 條目，但後續已完全由領域專屬 Key 代替者（如 `common.general.message.deletingCannot` 等共 21 條）。
2. **歷史重構廢棄 Key**：相關畫面、彈窗或功能已在先前重構中完全移除者（如 `common.action.label.back`、`common.general.label.addReminder`、`common.ui.label.dark` 等共 29 條）。
移除前透過全專案原始檔搜尋確認引用計數為 0，並由全量測試套件保證無破壞。

## Implementation Contract

- **行為**：
  - 英文語系下，全 App 所有導覽標題、按鈕、欄位、狀態膠囊、錯誤提示與日區段標題皆以英文呈現，無任何中文殘留。
  - 排版符號、品牌名稱、客戶資料與幣別代碼維持字面原文（verbatim），不參與翻譯。
  - 新定義的結構化 Key 可在 `Localizable.xcstrings` 透過 Xcode Symbol Generation 直接以強型別形式調用。
- **介面與資料形狀**：
  - Key 正規式：`^[a-z]+(\.[a-z][a-zA-Z0-9]*){2,3}$`（點記號，首段純小寫，後續各段符合 lowerCamelCase）。
  - `AppLanguage` 提供 `localized(_:)` 與 `localizedString(forKey:_:)` 方法支援純文字、單複數與位置引數。
- **邊界與驗收標準**：
  - `Localizable.xcstrings` 內 100% 條目為結構化英文 Key，且無任何未使用的死碼條目殘留。
  - 非本地化符號與品牌專有名詞均以 `Text(verbatim:)` 呈現，不在字串目錄保留 `shouldTranslate: false` 條目。
  - 全 App 生產程式碼中不再使用正體中文作為本地化鍵值。
  - 單元測試套件（包含 `LocalizationCatalogTests`）全數通過（exit 0）。

## Risks / Trade-offs

- **[Risk] 全量更換 Key 造成大幅度代碼變更** → **Mitigation**：採 Expand-Migrate-Contract 策略分批推進，每個批次各自進行編譯與測試驗證，保證隨時可交付與回歸安全。
- **[Risk] 移除死碼 Key 可能因動態字串拼接誤判** → **Mitigation**：在執行移除前，透過全量原始碼靜態掃描與交叉比對驗證零引用，並在 `LocalizationCatalogTests` 中鎖定。
- **[Risk] 呼叫端可能混用字面值與符號** → **Mitigation**：全面將非本地化文字加上 `Text(verbatim:)`，並透過 `LocalizationCatalogTests` 靜態掃描檢查，逐步收緊掃描規則。
