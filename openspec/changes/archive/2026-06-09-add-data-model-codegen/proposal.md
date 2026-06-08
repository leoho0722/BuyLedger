## Why

跨平台共享的 data model 形狀目前只存在於 apps/apple 的手寫 Swift Domain 型別中。未來擴展到 Android (Kotlin)、Web 與 Backend (TypeScript) 時，每次 schema 變更都必須逐平台手動同步等價定義，容易漏改、欄位漂移且無機制可察覺。需要一份統一的 schema (YAML) 作為唯一宣告來源，並以產生器自動輸出各平台語言的 data model 程式碼。

## What Changes

- 新增 shared/data-model/schema/ 目錄作為跨平台 data model 的唯一宣告來源，採**一型一檔** (12 檔，與 apps/apple Swift Domain 的「一型一檔」慣例 1:1 對應)，涵蓋 7 個 entity (LedgerOrder、LedgerOrderItem、LedgerCustomer、Campaign、Money、PaymentMethodInfo、FxRateSnapshot)、4 個 string enum (OrderStatus、CampaignStatus、PaymentReceiptStatus、CustomerTier)、1 個 string wrapper (CurrencyCode)；每個型別與欄位皆帶正體中文 doc
- schema 採**平台中立詞彙**：trait 用 `value-equality` / `serializable` / `identity` / `case-iterable` / `hashable` (不出現 Swift 專屬的 `sendable` 等)；optionality 以欄位的顯式 `nullable: true/false` 表示 (不用型別字串的 `?` 後綴)；型別文法其餘部分 (`array<T>` / `map<K, V>` / by-name 引用) 維持字串 DSL
- 新增 codegen.yaml 宣告 schema version 與輸出 targets (language + 輸出目錄 + 語言選項)
- 新增 **TypeScript + Bun** 產生器 datamodel-gen (置於 shared/data-model/generator)：以 zod 做「宣告即驗證」的 IR 解碼、npm `yaml` 套件做 YAML 解析、Bun 作 runtime 與測試器；提供 generate 與 check 兩個子命令，自 schema 目錄產生 Swift、Kotlin、TypeScript 三種語言的 data model 程式碼；輸出具決定性 (同一輸入永遠 byte-identical)，check 模式比對磁碟產出是否與 schema 同步
- Swift emitter 套用**全域 Sendable 政策**：對所有生成的 struct/enum 一律加 `Sendable` (補上編譯器本已合成、現行源碼漏標的標註)
- Apple Domain 層「生成式接管」(後續階段)：資料形狀由 generator 產出至 apps/apple/BuyLedger/Core/Domain/Generated/；手寫業務邏輯 (computed properties、display titles、static 集合、自訂 Codable) 保留並改寫為 extension —— **BREAKING** (Domain 檔案內容重組；型別對外 API 與行為不變，以三平台 build 與既有測試驗證)
- Kotlin 與 TypeScript 輸出因 apps/android、apps/web 尚未動工，正確性以產生器測試中的 golden file 驗證；未來平台動工時於 codegen.yaml 加 target 即接上
- 建立 shared/ 目錄 (首個內容為 data-model)，同步更新 monorepo 佈局相關文件

## Non-Goals

- 不生成 SwiftData Records、版本化 schema 與 migration plan (影子型別 attribute fingerprint 凍結鐵則，見 apps/apple 持久化層的版本化 schema 定義)
- 不生成業務邏輯：computed properties、display titles、static 集合、自訂 Codable 一律手寫
- 不建立 apps/android、apps/web、apps/backend 目錄 (monorepo-layout：動工才建立)
- 不實作 sum type (`kind: union`) 與 `platform:` 平台逃生艙——兩者皆已於 design 設計為向後相容擴充點，待實際需求出現再實作
- 不做 Kotlin / TypeScript 的序列化 wiring (kotlinx.serialization 註記、zod schema)，本次只輸出純 schema 形狀
- 不做 Xcode build phase 自動觸發生成 (生成檔全部 commit，手動執行 generate)

## Capabilities

### New Capabilities

- `data-model-codegen`: 統一 schema (YAML 目錄、一型一檔) 的格式與型別系統、datamodel-gen (TypeScript + Bun) 產生器的 Swift/Kotlin/TypeScript 輸出規則、平台中立 trait 與 Swift 全域 Sendable 政策、nullable/default 語意、決定性輸出與 check 模式、以及 Apple Domain 層「生成檔 + 手寫 extension」的整合契約

### Modified Capabilities

- `monorepo-layout`: 「保留目錄只文件化、不放 stub」要求中「磁碟上不得存在 shared/ 目錄」的斷言，隨 shared/data-model 實際動工而失效——shared/data-model 自此存在於磁碟上且含實際內容，README 佈局描述同步更新

## Impact

- Affected specs: data-model-codegen (新增)、monorepo-layout (修改)
- Affected code:
  - New:
    - shared/data-model/schema/ (12 個型別 YAML，一型一檔)
    - shared/data-model/codegen.yaml
    - shared/data-model/README.md
    - shared/data-model/generator/package.json
    - shared/data-model/generator/tsconfig.json
    - shared/data-model/generator/src/datamodel-gen.ts (IR + zod 驗證 + 目錄 loader + Swift/Kotlin/TypeScript emitters + generate/check CLI)
    - shared/data-model/generator/test/datamodel-gen.test.ts (bun:test 驗證規則表 + golden + 決定性 + 漂移 + 目錄載入 + Sendable 注入)
    - shared/data-model/fixtures/ (fixture schema + 三語言 golden file)
    - apps/apple/BuyLedger/Core/Domain/Generated/ (12 個 .generated.swift 檔，後續階段產出)
  - Modified:
    - apps/apple/BuyLedger/Core/Domain/ 下 12 個既有型別檔 (後續階段改寫為 extension；Money / LedgerCustomer / PaymentMethodInfo 無剩餘手寫邏輯者刪檔)
    - README.md
  - Removed: (none)
- 相依性：產生器引入 zod、yaml (npm 套件) 與 Bun runtime；Apple App 本體不新增任何相依
