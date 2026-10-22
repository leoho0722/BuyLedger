## Why

BuyLedger 現行本地化採用正體中文作為 String Catalog 的 Key，文案潤飾會連帶影響程式碼與測試識別碼；部分功能同詞異義（如取消、確定）產生語境混淆；且既有規格 `app-localization` 的 Purpose 仍為留白，並包含過期的實機驗收條款。

在制定標準結構化英文 Key 規範（`<domain>.<component>.<elementType>.<descriptor>`，複合詞採 `lowerCamelCase`）並完成基礎設施驗證後，使用者明確指示將全 App 既有之所有本地化字串改寫為制定的結構化英文 Key。這將徹底解耦文案迭代與程式碼識別碼，消滅同詞異義歧義，為未來 Monorepo 跨平台（Android / Shared）奠定 100% 統一的資源契約，並配合 Xcode 的 `STRING_CATALOG_GENERATE_SYMBOLS` 實現全 App 編譯期強型別檢查。

在全量改寫完成後的全面盤點中，進一步發現字串目錄仍殘留過渡期重複生成的通用 Key、歷史功能重構後的孤立/廢棄 Key，以及不應被收錄至 String Catalog 的非本地化字面值（排版符號、品牌名稱、預覽假資料）。為了達到目錄極簡、契約純淨與零死碼，本變更同步納入目錄瘦身與非本地化字串防禦改寫。

## What Changes

- **規格更新**：完善 `app-localization` 跨領域政策型規格，明確界定 Purpose 與相鄰規格邊界，移除過期的實機驗收條款，加入結構化英文 Key 命名格式、多參數位置標記、String Catalog 原生單複數與 verbatim 資料邊界條款。
- **命名規範與字典制定**：制定標準結構化英文 Key 格式 `<domain>.<component>.<elementType>.<descriptor>`，規範層級清單與單詞精簡原則（descriptor 複合詞採 `lowerCamelCase`）。
- **String Catalog 現代化與缺陷修復**：修復 `BLFormatters.daySectionTitle` 中硬編碼「今天 / 昨天」中文字串的缺陷，並在 `AppLanguage` 提供單複數與位置引數解析方法。
- **全量本地化字串遷移 (Expand-Migrate-Contract)**：
  - **Expand**：將全 App 499 條既有中文 Key 全數對應生成結構化英文 Key，注入 `Localizable.xcstrings`，保持雙軌並存。
  - **Migrate**：依模組分批（Shared/Common、Dashboard/Insights、Orders、Campaigns/Customers）將生產程式碼與視圖中的本地化呼叫改寫為新 Key。
  - **Contract**：同步測試套件斷言，並從字串目錄徹底移除舊中文 Key。
- **字串目錄瘦身與死碼清理**：安全移除 `Localizable.xcstrings` 內未被使用的重複通用 Key（如 `common.general.message.deletingCannot` 等）、歷史功能重構後的廢棄 Key（如 `common.action.label.back`、`common.general.label.addReminder` 等）與過期插值模版。
- **非本地化字串防禦改寫**：將視圖中被 Xcode 誤擷取的純符號（`"·"`、`"%"`）、品牌專有名詞（`"BuyLedger"`、`"BL"`、`"VIP"`）與預覽假資料（`"$12,480"`、`"0"`）改寫為 `Text(verbatim:)`，並自字串目錄移除其 `shouldTranslate: false` 條目，避免污染翻譯資源。
- **自動化守門與測試升級**：升級 `LocalizationCatalogTests` 守門機制為「全目錄 100% 結構化英文 Key 強制檢查」，驗證 Key 命名結構合法性、中英文雙向完整性與非空白，防範未引用死碼，並禁止在 View 拼接本地化文字。
- **工程規則同步**：同步 `.claude/rules/ios-accessibility-localization.md` 與 `apps/ios/CLAUDE.md`，提供呼叫端最佳實踐與防拼接指引。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `app-localization`: 更新 Purpose 政策定義並指名相鄰規格邊界，新增全量結構化英文 Key 命名與格式規範、雙語目錄完整性、多參數位置標記與單複數 substitution 條款，明確使用者資料、品牌名與非翻譯字面值之 verbatim 邊界，並移除過期的實機驗收需求。

## Impact

- 影響規格：`openspec/specs/app-localization/spec.md`
- 影響規則與文件：`.claude/rules/ios-accessibility-localization.md`、`apps/ios/CLAUDE.md`
- 影響資源：
  - `apps/ios/BuyLedger/Resources/Localizable.xcstrings`（全量結構化改寫、舊中文 Key 移除、未引用死碼清理與符號條目精簡）
- 影響程式碼：
  - `apps/ios/BuyLedger/Shared/`（DesignSystem, Localization, Extensions）
  - `apps/ios/BuyLedger/Features/`（App, Dashboard, Insights, AISummary, Orders, Campaigns, Customers, Lookups, Settings, More, FX, Quote）
- 影響測試：
  - `apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift`
  - `apps/ios/BuyLedgerTests/LocalizationCatalogTests+LiteralScan.swift`
  - `apps/ios/BuyLedgerTests/LocalizationCatalogTests+AppLanguage.swift`
  - `apps/ios/BuyLedgerTests/LocalizationCatalogTests+SourceGuards.swift`
  - `apps/ios/BuyLedgerTests/` 業務單元測試與 Snapshot 測試
