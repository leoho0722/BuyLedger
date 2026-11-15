## Summary

移除整個 data model codegen 系統 (`shared/data-model` 的 schema、`datamodel-gen` 產生器、golden fixtures、`codegen.yaml` 與 CI 的 codegen job)，並把 `apps/ios/BuyLedger/Core/Domain/Generated/` 的生成型別依 ios-dev-kit 的同檔分區併回同名手寫檔，之後 Swift 原始碼就是資料形狀的唯一來源。

## Motivation

- 產線只有 Swift 一個輸出目標 (`shared/data-model/codegen.yaml` 只有 swift target)，Kotlin 與 TypeScript emitter 只由 golden fixtures 鎖住、沒有任何消費者，卻要一起維護三種語言的期望輸出。
- 每個生成型別都拆成「生成宣告 + 跨檔手寫 extension」兩個檔案 (例如 `Campaign.generated.swift` 與 `Campaign.swift`)，違反 ios-dev-kit `formatting.md`「避免跨檔 extension 自己的型別」；生成檔也沿用 emitter 自己的排版 (`// MARK: - Data Properties`、`// MARK: - Cases`、單行 computed property 本體、init 沒有 `- Parameters`)，與 kit 不一致且不能手改。
- 改一個欄位要經過 schema、Bun、`bun run generate`、`bun run check` 與 CI 的 Linux job，開發環境多一套 Bun 工具鏈，`.claude/rules/ios-data-layer.md`、root `CLAUDE.md` 與兩份 README 都要額外維護生成檔規則。
- 使用者於 2026-11-15 決定移除整個 codegen 系統，並把生成型別的 extension 收斂回原型別檔。

## Proposed Solution

- **先鎖住持久化形狀**：`OrderRecord` 與各版 shadow 直接內嵌 `LedgerCustomer`、`OrderStatus`、`[LedgerOrderItem]`，`CampaignStatus`、`PaymentReceiptStatus` 與幣別代碼以 raw value 字串存進記錄，目前只有 `OrderStatus` 的兩個 raw value 有測試。合併前新增編碼形狀測試，在生成檔還在時先通過，合併後仍通過才算資料形狀不變 (使用者選擇)。
- **合併生成型別**：12 個生成型別中，10 個有同名手寫檔，把生成宣告移入手寫檔並依 kit 分區：型別本體只放 stored properties (含原本寫在 extension 的 `static let`) 與 Init，其餘維持同檔 extension (Nested Types → Computed Properties → Internal Method → protocol 遵循 → Private Method)；`LedgerCustomer` 沒有手寫檔，改為新建 `LedgerCustomer.swift`；`Money` 全專案沒有引用，直接刪除。stored property 的名稱、型別、順序與 `Codable` 實作不變，SwiftData 指紋與編碼形狀維持原樣。
- **刪除 codegen 本體**：刪除 `shared/` 整個目錄 (唯一內容就是 `shared/data-model`)、`apps/ios/BuyLedger/Core/Domain/Generated/`、CI 的 codegen job 與 `.gitignore` 的 generator `node_modules` 規則。
- **收斂守門掃描的生成檔參數**：`SwiftSourceFiles.swiftFiles(under:shouldIncludeGenerated:)` 的排除邏輯只為 `Generated/` 目錄存在，目錄消失後移除參數與所有呼叫端的 `shouldIncludeGenerated: true`，`LayerBoundaryTests` 的領域宣告清單測試改為驗證「領域目錄全部檔案都納入掃描」。
- **同步文件與規則**：root `CLAUDE.md` 刪除「跨平台 Data Model (codegen)」節，root `README.md`、`AGENTS.md`、`apps/ios/README.md`、`apps/ios/CLAUDE.md`、`.claude/rules/ios-data-layer.md`、`.claude/rules/ios-design-system.md`、`.claude/rules/ios-integrations.md` 移除生成檔、Bun、跨平台 schema 與 `shared/data-model` 的描述；`ios-data-layer.md` 補上「內嵌於記錄的領域型別等同 SwiftData schema」的規則。
- **審查後追加 (使用者 2026-11-15 裁定)**：`LedgerOrder.contributesToCategoryBreakdown` 依 kit 的 `Bool` 命名改名為 `isCountedInCategoryBreakdown`，同步唯一呼叫端 `InsightsStats.swift` 與規則引用；以 `/archify` 重繪仍畫著 codegen 產線的整體架構圖並刪除舊圖；`InsightsStats.swift` 因改名改到，其跨檔 extension `InsightsStats+Trend.swift` 依 kit 抽成獨立的純計算型別 `InsightsTrend`。
- **更新 spec**：`data-model-codegen` 的需求全數移除；`ci-guardrails`、`monorepo-layout`、`app-layer-boundaries`、`design-system-hygiene`、`campaign-calendar-reminder` 改寫涉及 codegen、生成檔或跨平台 Campaign 型別的需求；`code-comment-currency` 移除生成檔註解的需求並手改 Purpose；`schema-migration-plan` 新增持久化形狀由測試鎖住的需求。

## Non-Goals

詳見 design.md 的 Goals／Non-Goals。

## Alternatives Considered

- **保留 generator，只把 Swift 輸出改成 kit 排版**：仍要維護 Bun 工具鏈、三語言 fixtures 與 CI job，且生成宣告與手寫行為仍分兩檔，無法消除跨檔 extension。
- **型別的所有成員都寫進本體、不留 extension**：與 kit「型別本體只放 stored properties 與 Init」衝突，使用者選擇依 kit 同檔分區。

## Impact

- Affected specs: `data-model-codegen` (移除全部需求)、`ci-guardrails`、`monorepo-layout`、`app-layer-boundaries`、`design-system-hygiene`、`campaign-calendar-reminder`、`code-comment-currency`、`schema-migration-plan`
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Core/Domain/Campaign.swift
    - apps/ios/BuyLedger/Core/Domain/CampaignStatus.swift
    - apps/ios/BuyLedger/Core/Domain/CurrencyCode.swift
    - apps/ios/BuyLedger/Core/Domain/CustomerTier.swift
    - apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift
    - apps/ios/BuyLedger/Core/Domain/LedgerOrder.swift
    - apps/ios/BuyLedger/Core/Domain/LedgerOrderItem.swift
    - apps/ios/BuyLedger/Core/Domain/OrderStatus.swift
    - apps/ios/BuyLedger/Core/Domain/PaymentMethodInfo.swift
    - apps/ios/BuyLedger/Core/Domain/PaymentReceiptStatus.swift
    - apps/ios/BuyLedgerTests/Guards/Scanning/SwiftSourceFiles.swift
    - apps/ios/BuyLedgerTests/Guards/LayerBoundary/LayerBoundaryScanner.swift
    - apps/ios/BuyLedgerTests/Guards/LayerBoundary/LayerBoundaryTests.swift
    - apps/ios/BuyLedgerTests/Guards/ActionGrouping/ActionGroupingScanner.swift
    - apps/ios/BuyLedgerTests/Guards/ActionGrouping/ActionGroupingScanTests.swift
    - apps/ios/BuyLedgerTests/Guards/AccessibilityIdentifier/AccessibilityIdentifierScanTests.swift
    - apps/ios/BuyLedgerTests/Guards/AccessibilityConventionScanTests.swift
    - apps/ios/BuyLedgerTests/Guards/BottomBarPlacementScanTests.swift
    - apps/ios/BuyLedgerTests/Guards/NumericInputGroupingScanTests.swift
    - apps/ios/BuyLedgerTests/Guards/TaskFinishConventionScanTests.swift
    - apps/ios/BuyLedgerTests/Guards/ViewAnimationSwitchScanTests.swift
    - apps/ios/BuyLedger/Features/Insights/Domain/InsightsStats.swift (改名呼叫端與整檔對齊)
    - .github/workflows/ci.yml
    - .gitignore
    - CLAUDE.md
    - README.md
    - AGENTS.md
    - apps/ios/CLAUDE.md
    - apps/ios/README.md
    - .claude/rules/ios-data-layer.md
    - .claude/rules/ios-design-system.md
    - .claude/rules/ios-integrations.md
    - openspec/specs/code-comment-currency/spec.md (archive 後只手改 Purpose，delta 動不到該段)
  - New:
    - apps/ios/BuyLedger/Core/Domain/LedgerCustomer.swift
    - apps/ios/BuyLedgerTests/Core/Persistence/PersistedValueShapeTests.swift
    - .archify/architecture-buyledger-<YYYYMMDD-HHMMSS>/ (重繪的整體架構圖：candidate.json、buyledger.html)
    - apps/ios/BuyLedger/Features/Insights/Domain/InsightsTrend.swift (自 InsightsStats+Trend.swift 抽出的走勢計算)
  - Removed:
    - apps/ios/BuyLedger/Core/Domain/Generated/ (12 個 `*.generated.swift`)
    - shared/ (含 shared/data-model 的 schema、generator、fixtures、codegen.yaml、README.md、CLAUDE.md)
    - .archify/architecture-buyledger-20261024-115559/ (畫著 codegen 產線的舊整體架構圖)
    - apps/ios/BuyLedger/Features/Insights/Domain/InsightsStats+Trend.swift (改為 InsightsTrend.swift)
