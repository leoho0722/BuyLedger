## 1. 規格與指引同步 (Spec and Guidelines Synchronization)

- [x] 1.1 更新政策規格 `openspec/specs/app-localization/spec.md`：改寫 Purpose 定義涵蓋範圍並指名相鄰規格邊界，移除過期的「Device acceptance」驗收條款，並寫入「Supported App languages」結構化 Key 規範與「Verbatim preservation for user data and external content」邊界，以 `spectra validate` 驗證。
- [x] 1.2 更新開發規則 `.claude/rules/ios-accessibility-localization.md` 與平台指引 `apps/ios/CLAUDE.md`：載明結構化英文 Key 命名範式 `<domain>.<component>.<elementType>.<descriptor>` 與 `lowerCamelCase` 規範，明訂「Prohibition of string concatenation in localized interfaces」防拼接守門與「Positional parameter specifiers for multi-variable strings」位置標記規則，以內容審查驗證。

## 2. 格式化工具修復與基礎設施 (Formatter Repair and Infrastructure)

- [x] 2.1 實作「格式化工具的語言依賴注入與修復 (Formatter Language Injection and Date Header Repair)」：修正 `apps/ios/BuyLedger/Shared/DesignSystem/Foundations/BLFormatters.swift` 的 `daySectionTitle`，將今天與昨天中文字串改由注入的語系/本地化鍵值解析，確保符合「Locale-aware presentation follows App language」，以 `BLFormattersTests` 與新單元測試驗證英文下返回 `Today` 與 `Yesterday`。
- [x] 2.2 在 `apps/ios/BuyLedger/Resources/Localizable.xcstrings` 導入「結構化英文 Key 格式與命名範式 (Structured English Key Hierarchy and Naming Convention)」：為核心共用動作、狀態與日期相對詞建立示範結構化 Key（如 `common.date.today`、`common.date.yesterday`、`common.action.cancel` 等），包含 `zh-Hant` 與 `en` 完整翻譯，以字串目錄解析測試驗證。
- [x] 2.3 設定「參數位置標記與 String Catalog 單複數 Substitutions (Positional Arguments and Plural Substitutions)」：落實「Plural variations handled by String Catalog substitutions」，在 `Localizable.xcstrings` 建立帶位置標記與 plural substitutions 的範例 Key（如選取計數與照片上限通知），以參數化測試驗證單複數解析正確性。

## 3. 守門測試升級與回歸驗證 (Guardrail Tests Evolution and Verification)

- [x] 3.1 實作「靜態守門測試轉型與文字防拼接驗證 (Static Guardrails Evolution and Anti-Concatenation Enforcement)」：在 `apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift` 新增 Key 格式正規式檢查與雙語完整性檢查，並強化禁止在視圖中以 `+` 拼接 `Text` 的靜態掃描測試，以 `LocalizationCatalogTests` 測試執行驗證。
- [x] 3.2 執行回歸測試套件：執行全部本地化單元測試，確認新舊 Key 相容運作、既有單元測試零回歸且 CI 守門全綠，以測試套件全數通過為驗證目標。

## 4. 全量結構化 Key 映射與字串目錄擴充 (Key Mapping and Catalog Expansion)

- [x] 4.1 實施「全量本地化字串漸進遷移策略 (Full Localization Migration Strategy: Expand-Migrate-Contract)」之擴充階段：建立 499 條既有中文 Key 與結構化英文 Key 的全量 1:1 映射字典，依 `<domain>.<component>.<elementType>.<descriptor>` 命名範式生成 Key，並注入寫入 `apps/ios/BuyLedger/Resources/Localizable.xcstrings`（雙軌並存），以 `LocalizationCatalogTests` 驗證新 Key 雙語非空白且格式合法。

## 5. 核心共用與總覽分析模組遷移 (Common, Shared, Dashboard, Insights Migration)

- [x] 5.1 將 `apps/ios/BuyLedger/Shared/`（DesignSystem, Pickers, Components）與 `apps/ios/BuyLedger/Features/`（App, More, Settings）中所有本地化字串呼叫端改寫為結構化英文 Key，以模組單元測試與 `LocalizationCatalogTests` 驗證編譯與執行期解析正確。
- [x] 5.2 將 `apps/ios/BuyLedger/Features/Dashboard/`、`apps/ios/BuyLedger/Features/Insights/` 與 `apps/ios/BuyLedger/Features/AISummary/` 中所有本地化呼叫端（包含圖表描述與軸標題）改寫為結構化英文 Key，以 Dashboard 與 Insights 單元測試驗證數據卡片與圖表文字顯示無回歸。

## 6. 訂單與開團業務模組遷移 (Orders and Campaigns Migration)

- [x] 6.1 將 `apps/ios/BuyLedger/Features/Orders/`（列表、編輯、草稿、篩選、合併、批次操作）與 `Features/Lookups/` 中所有本地化呼叫端改寫為結構化英文 Key，以訂單業務單元測試與 Snapshot 測試驗證功能無回歸。
- [x] 6.2 將 `apps/ios/BuyLedger/Features/Campaigns/`（開團列表、詳情、分貨、編輯）、`Features/Customers/`、`Features/Quote/`、`Features/FX/` 中所有本地化呼叫端改寫為結構化英文 Key，以開團與客戶單元測試驗證功能無回歸。

## 7. 測試套件斷言同步、舊中文 Key 清理與全面守門收緊 (Contract and Full Enforcement)

- [x] 7.1 同步 `apps/ios/BuyLedgerTests/` 測試套件內之硬編碼中文字面值斷言，並從 `apps/ios/BuyLedger/Resources/Localizable.xcstrings` 徹底移除舊有 499 條中文 Key（完成 Contract 收縮階段），以專案編譯零錯誤驗證無殘留引用。
- [x] 7.2 升級 `apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift` 守門測試為全目錄 100% 結構化英文 Key 強制檢查（禁止任何中文 Key 或未符格式規範之 Key 存在於目錄），並執行全量測試套件，以 100% 測試全綠驗證全量改寫完成。

## 8. 字串目錄瘦身、非本地化字串防禦與死碼清理 (Catalog Pruning, Non-Localizable Cleanup, and Literal Guards)

- [x] 8.1 實作「非本地化字串防禦與 Verbatim 邊界落實 (Non-Localizable Literal Preservation and Verbatim Boundary Enforcement)」：將各視圖中的純符號（`·`、`%`）、品牌與專有名詞（`BuyLedger`、`BL`、`VIP`）以及預覽假資料改寫為 `Text(verbatim:)`，並自 `Localizable.xcstrings` 移除 `shouldTranslate: false` 條目，以編譯與 Snapshot 測試驗證視覺排版無回歸。
- [x] 8.2 實作「字串目錄瘦身與死碼清理策略 (Catalog Pruning and Dead Key Elimination)」：從 `apps/ios/BuyLedger/Resources/Localizable.xcstrings` 安全移除過渡期重複生成的通用 Key（21 條）與歷史廢棄 Key（29 條），以原始碼與目錄全量交叉掃描驗證無懸掛引用。
- [x] 8.3 升級本地化守門測試與回歸驗證：在 `apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift` 增補目錄純淨度守門檢查，確保目錄內無未使用的死碼與非本地化條目，並執行全量測試套件，以 100% 測試全綠（1396+ 條）驗證目錄瘦身完成。
