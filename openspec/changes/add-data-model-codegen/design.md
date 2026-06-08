## Context

跨平台 data model 的形狀目前唯一存在於 apps/apple 的手寫 Swift Domain 型別 (apps/apple/BuyLedger/Core/Domain/)。這些檔案混合兩種內容：

1. **資料形狀**：stored properties、enum cases、機械式 conformances (Equatable / Sendable / Identifiable / 合成 Codable)、memberwise init——跨平台等價、可機器產生
2. **業務邏輯**：computed properties (如 LedgerOrder.summary)、display titles、static 集合 (如 OrderStatus.realizedStatuses)、自訂 Codable 實作 (LedgerOrderItem 排除 id、CurrencyCode 的 single value container)——平台與產品專屬、必須手寫

monorepo-layout spec 已保留 shared/data-model 作為跨平台 Data Model 的文件化位置 (尚未建立)。SwiftData 版本化 schema 因影子型別 attribute fingerprint 凍結鐵則，永遠不在生成範圍內。

本設計的所有關鍵選擇均已與使用者逐項確認 (見各 Decision 的決策歷程)。

## Goals / Non-Goals

**Goals:**

- 一份 shared/data-model/schema/ 目錄 (一型一檔) 成為跨平台 data model 形狀的唯一宣告來源
- datamodel-gen (TypeScript + Bun) CLI 自 schema 產生 Swift / Kotlin / TypeScript 三種語言的 data model 程式碼，輸出具決定性
- Apple Domain 層的資料形狀改由生成檔提供，對外 API 與行為不變 (三平台 build 與既有測試驗證)
- check 模式讓 CI 與提交前流程可偵測「schema 與產出漂移」
- Kotlin / TypeScript 輸出正確性以 golden file 測試鎖定，未來平台動工時直接接上
- schema 詞彙平台中立，不偏袒任何單一平台

**Non-Goals:**

- 不生成 SwiftData Records、版本化 schema 與 migration plan (fingerprint 凍結鐵則)
- 不生成業務邏輯：computed properties、display titles、static 集合、自訂 Codable 一律手寫
- 不建立 apps/android、apps/web、apps/backend 目錄 (monorepo-layout：動工才建立)
- 不實作 sum type kind 與 platform 逃生艙 (設計待命，見 Decision 7)
- 不做 schema 版本演進 / migration 機制 (YAML 改了就重新生成)
- 不做 Xcode build phase 自動觸發生成 (生成檔全部 commit，手動執行 generate)

## Decisions

### Decision 1: Generator 以 TypeScript + Bun 實作

generator 經多輪語言特性分析後拍板 TypeScript + Bun。決策準則由使用者定下：工具鏈重要性 de-weight、優先「發揮語言特性少寫 template code」，並以三個維度檢驗——窮舉 ADT、宣告即驗證的型別化解碼、模板插值能力。

選 TypeScript 的理由：
- **zod 宣告即驗證**：IR 型別由 `z.infer` 推導 (零重複宣告)、未知鍵 / 缺 doc / 錯 kind 於解析期即報錯、跨型別規則收在 `superRefine`——解碼層幾乎零 plumbing
- **template literals**：emitter 可在模板字面值內嵌 `map`/`join`，所見即輸出，template code 最少
- **discriminated union + assertNever**：TypeExpr / DefaultValue / TypeDecl 的每個 switch 受編譯期窮舉保護 (配 `tsc --noEmit`)，新增型別漏接 emitter 即型別錯誤

選 Bun 的理由：runtime + 測試器 (`bun test`) + 套件管理三合一；`bun build --compile` 未來可產 standalone binary，讓其他平台開發者免裝 runtime 跑 codegen。YAML 解析用成熟的 npm `yaml` 套件，**不用 Bun 內建的 Bun.YAML** (其有 parser regression 紀錄、block scalar 邊角保真度未驗證)。型別檢查走 `tsc --noEmit`。

被否決方案：Swift (解碼 unknown-key 預設忽略、模板插值不能放多行邏輯須拆 helper)、Rust (最安全但 `format!` 無多行插值、模板 code 最囉嗦，與準則反向)、Kotlin (特性同級但 JVM 啟動慢、押注原生 Android 才划算)、Python + pydantic (解碼與 TS 打平，但輸出 C-family 大括號語言有「大括號稅」)、quicktype 等現成工具 (輸出風格無法符合專案檔案規範)、暫行的 Ruby 參考實作 (無靜態窮舉，僅作為 golden 規格的可執行驗證後移除)。

### Decision 2: 統一 schema 為 YAML 目錄、一型一檔

schema 置於 shared/data-model/schema/ 目錄，**一型一檔** (12 檔，如 schema/LedgerOrder.yaml)，與 apps/apple Swift Domain 的「一型一檔」慣例 1:1 對應：schema 檔 <-> .generated.swift <-> 手寫 .swift 三者同名對齊。每檔僅含 `types:` (該型別宣告)，不含 version。

頂層型別三種 kind：
- `entity`：多欄位記錄 -> struct / data class / interface
- `enum`：字串 raw value 列舉 -> String enum / enum class / union
- `wrapper`：單值 newtype -> struct over rawValue / @JvmInline value class / type alias

型別表達式文法 (字串 DSL，#4 決議)：基礎型別 `string / int / bool / decimal / date / data / uuid`、容器 `array<T>` 與 `map<K, V>`、對其他型別的 by-name 引用。**nullability 不在字串內**——拉成欄位的顯式 `nullable: true/false` (見 Decision 5)。

doc 為必填 (型別與欄位 / case 層級皆是)，單一正體中文，內容自現行手寫檔案逐字搬入。

替代方案：結構化 YAML 型別文法在「機器可驗證 / 無 parser」軸長期較優，但現有型別淺、且最成熟的 schema 語言 (Protobuf / GraphQL SDL / Smithy) 多採專屬 DSL 而非結構化 YAML；字串 DSL 對淺型別可讀性最高。因解析層與 IR 嚴格分離 (Decision 6)，此選擇可日後無痛遷移，故 v1 選字串 DSL。

### Decision 3: 平台中立 trait 詞彙與 Swift 全域 Sendable 政策

schema 只描述跨平台中立語意，不出現任何單一平台才懂的詞彙。中立 trait 與三平台對應：

| schema trait | Swift | Kotlin | TypeScript |
|--------------|-------|--------|------------|
| `value-equality` | Equatable | data class 自動 | interface 結構比較 |
| `serializable` | Codable | @Serializable (未來) | zod (未來) |
| `serialization: custom` (與 serializable 互斥的 marker) | 不含 Codable，手寫 extension | 同左 | 同左 |
| `identity` | Identifiable + var id | id 慣例 | id 欄位 |
| `case-iterable` | CaseIterable | enum values() | union 窮舉 |
| `hashable` | Hashable | data class 自動 | 忽略 (明確分支，非靜默吞) |

**純平台政策下放 emitter，不入 schema**：`sendable` 不是「型別的性質」而是「Swift 平台對 value 型別的並發政策」，因此移出 schema，改由 Swift emitter 對**所有**生成的 struct/enum 一律加 `Sendable`。這補上了編譯器本已合成、但現行源碼漏標的標註——現行 12 型別中只有 Money 未顯式標 Sendable，而 Money 是 internal struct 且成員皆 Sendable，本已隱式 Sendable，補標僅是把事實寫出來，零行為差異。

未知 trait 於驗證期報錯；已知但某平台無對應的 trait (如 hashable 之於 TypeScript) 以 emitter 內的明確分支忽略，非靜默吞掉。

### Decision 4: 型別文法用字串 DSL，nullability 除外

型別表達式維持單行字串 (`array<map<CurrencyCode, decimal>>`)，自寫遞迴下降 parser；但 `?` 後綴移除，nullability 改由欄位的顯式 `nullable` 布林承載 (見 Decision 5)。理由：nullability 是最常用的型別修飾，主流 schema 語言 (SQL NOT NULL / Protobuf optional / JSON Schema nullable) 多將其一級化於型別名之外；顯式 `nullable` 較可掃描。代價是失去巢狀 optional (`array<date?>`) 表達力——現有 domain 無此需求。

### Decision 5: nullable 與 default 的語意

欄位以兩個正交屬性描述可空性與預設：

- `nullable: true/false` (預設 false)：true 時型別包一層 optional (Swift `T?` / Kotlin `T?` / TypeScript `T | null`)
- `default`：建構時的預設值，文法為字面值 (`0` / `""` / `false`)、空陣列 `[]`、enum case 引用 (`Type.case`)、計算 default sentinel `$newUUID`

init / 欄位預設規則 (三 emitter 一致)：
- `default` 有設 -> init 用其值
- `nullable && 無 default` -> Swift `= nil` / Kotlin `= null` / TypeScript optional key (`name?:`)
- **非 nullable && 無 default -> 必填** (不給語言零值)；給零值會讓 `LedgerOrder(id:)` 可省略金額自動帶 0，不符現狀且違反產品「寧可空狀態也不顯示假資料」政策

`$newUUID` 保留為計算 default：emit Swift `id: UUID = UUID()`，保真 `LedgerOrderItem` 現行 init 簽名 (UI 新增商品列時 id 自動生)。不一般化成計算 default 家族 (出現 `$now` 等第二個再收斂)。

實作補洞：entity 同時有 nullable 欄位與帶 default 欄位時會走顯式 init 路徑，該路徑須為 nullable 欄位補 `= nil` (fixture SampleOrder.closeDate 觸發此路徑，當回歸測試)。

### Decision 6: 解析層與 IR 驗證層嚴格分離

資料流 `schema 來源 -> [解析層 (yaml 套件)] -> IR -> [zod 驗證] -> emitters`。emitter 與 IR 不在乎型別當初在來源裡怎麼拼，故 schema 格式 (字串 DSL vs 結構化 YAML、單檔 vs 目錄) 是可逆選擇——未來換格式只動解析層與 zod 宣告，emitter 零影響。這是 Decision 2/4 敢選「v1 字串 DSL + 目錄」卻不鎖死長期的底氣。

### Decision 7: sum type 與 platform 逃生艙——設計待命、暫不實作

兩個向後相容的擴充點，設計寫入此 design 但本次不實作 (加 kind / 加區塊皆 additive，不影響現有型別)：

- **sum type (`kind: union`)**：帶 payload 的「數種形狀之一」，預定 `kind: union` + `variants` (各 variant 可帶 fields)，映射 Swift enum-with-payload / Kotlin sealed class / TypeScript discriminated union。現有 12 型別無 sum type (所有「多選一」要嘛固定 enum、要嘛使用者自訂字串主檔)
- **`platform:` 逃生艙**：真正的型別級平台差異 (某型別只在 Kotlin 加註記、某欄位只在特定平台出現)，預定 per-type `platform:` 區塊。現有 domain 無平台限定欄位，唯一平台限定現象 (Sendable) 已由 Decision 3 的 emitter 政策處理

### Decision 8: Apple Domain 生成式接管——生成檔 + 手寫 extension (後續階段)

- 生成檔置於 apps/apple/BuyLedger/Core/Domain/Generated/<TypeName>.generated.swift，每型別一檔，內容為型別主宣告 (stored properties、enum cases、traits 對應 conformances + 全域 Sendable、必要時顯式 init)；檔頭固定「自動產生，請勿手動編輯」header (不含日期，保決定性)
- 既有手寫檔案改寫為 extension：Display Properties、Computed Properties、Static Properties、View Method、自訂 Codable 與 CodingKeys 留下；無剩餘手寫邏輯者 (Money / LedgerCustomer / PaymentMethodInfo) 刪檔，由生成檔完整取代
- `serialization: custom` 的型別 (LedgerOrderItem、CurrencyCode)：生成宣告不含 Codable，手寫 extension 維持現行自訂實作，編碼行為 (排除 id、single value container) 不變
- 生成的 Swift 比照 swift-file-template 與 CLAUDE.md 排版 (MARK 區段順序、enum case 間空行、型別宣告後首行空行、正體中文 doc、半形括號與 CJK 間距)
- 此階段在 generator 收斂與三平台 build 驗證後執行；本次 change 的首輪 apply 聚焦 generator 收斂，Apple 整合為後續 apply 範圍

### Decision 9: 生成檔預設唯讀、需顯式解鎖

`generate` 對每個生成檔寫完後 chmod `0o444` (唯讀)，防止開發者誤手改 (使用者要求)。重生成為冪等的「解鎖→重寫→重鎖」，故 `bun run generate` 仍可直接覆寫唯讀檔；另提供 `unlock` 命令 (`bun run unlock`) 把各 target 生成檔改回可寫，供刻意手動檢視／實驗，下次 generate 會再上鎖。`unlock` 只依 codegen 設定掃描輸出目錄、不需 schema 有效。此為本機工作副本防線——git 不追蹤 user write bit，clone 後檔案回到可寫，故唯讀鎖與檔頭警語、check 守門三者並行、互補而非取代；`check` 只讀取、不受唯讀影響。

## Implementation Contract

**可觀察行為：**

1. 於 shared/data-model/generator 執行 `bun run generate --schema ../schema --config ../codegen.yaml` (或經 package.json script `bun run generate`)，會 (重新) 寫出 codegen.yaml 中每個 target 的程式碼檔；重複執行輸出 byte-identical
2. `bun run check ...`：磁碟產出與 schema 同步時 exit 0；任何漂移 (手改生成檔、改 schema 未重生成) 時 exit 1 並列出漂移檔案路徑
3. schema 違反驗證規則時，generate / check 以非零 exit code 終止並輸出指明型別 / 欄位的錯誤訊息，不寫出任何檔案
4. Apple App 對外行為不變 (後續階段)：12 個 Domain 型別的 API (型別名、屬性、init 簽名與預設值、conformances、Codable 編碼形狀) 與重構前一致，唯一刻意差異是全型別補上顯式 Sendable

**介面 / 資料形狀：**

- schema/ 目錄每檔含 `types:` 陣列，型別 kind 為 entity / enum / wrapper；欄位含 `name` / `type` (字串 DSL) / `doc` / `nullable` / `mutable` / `default`
- codegen.yaml：`version` + `targets:` 陣列 (每 target 含 `language` (swift/kotlin/typescript)、`output`、`options`)
- 驗證規則 (zod，解碼後生成前)：型別名與欄位/case 名不得重複、by-name 引用必須存在、identity 要求 entity 有 id 欄位、`serialization: custom` 與 `serializable` trait 互斥、default 的 enum case 引用必須存在、未知 trait / 未知 kind 報錯；違規一律非零 exit、不寫出

**失敗模式：**

- YAML 解析失敗、驗證失敗、不支援的輸出語言：stderr 錯誤訊息 + 非零 exit，不部分寫出
- check 漂移：exit 1 + 漂移檔案清單 (預期的守門行為，非錯誤)

**驗收條件：**

1. `bunx tsc --noEmit` 零錯誤；`bun test` 全綠 (IR 解碼 / 驗證規則表 / 三語言 golden / 決定性 / 漂移 / 目錄合併載入 / Sendable 全域注入 / 中立 trait 對應)
2. 以正式 schema/ 目錄執行 generate 至暫存目錄，兩次 byte-identical、檔數符合預期、check 模式 exit 0
3. (後續階段) iOS / iPadOS / macOS 三平台 build 成功 (序列化)，BuyLedgerTests 既有測試全綠 (含 snapshot 與 LedgerOrderItem 編碼不含 id 的既有行為)
4. Kotlin / TypeScript golden 輸出以人工檢視確認語法正確 (可被各語言編譯器接受的形狀)

**範圍邊界：**

- 本輪 in scope：schema/ 目錄、codegen.yaml、datamodel-gen (TS+Bun，三語言 emitter + generate/check + 目錄 loader + 中立 trait + Sendable 政策 + nullable/default)、golden 測試、shared/data-model README、root README 佈局、monorepo-layout delta spec
- 後續階段 in scope：Apple Domain 12 型別生成式接管、三平台 build 驗證、root CLAUDE.md 與 apps/apple 兩份文件
- Out of scope：SwiftData Records 與版本化 schema、業務邏輯檔、Android / Web / Backend 平台目錄、序列化 wiring、Xcode build phase 整合、sum type 與 platform 逃生艙實作

## Risks / Trade-offs

- [拆分後 Domain 行為意外改變] → traits 與 init 簽名逐一比照現行宣告搬移；以三平台 build、既有單元測試與 snapshot 測試驗收；自訂 Codable 留手寫 extension 保住編碼形狀
- [中立 trait 改名後輸出意外變化] → Swift 輸出的 conformance 關鍵字不變 (只是 schema 詞彙中立化)，唯一刻意差異是 Sendable 全域注入，已記入 golden 與測試
- [Sendable 全域注入改變 Money 宣告] → Money 本已隱式 Sendable，補標為安全擴充，使用者已確認
- [目錄合併破壞決定性] → 輸出順序以「檔名排序 + 檔內宣告序」保證，測試明文斷言「同輸入生成兩次 byte-identical」
- [Bun 安裝失敗 / 網路] → CLI 與 Node 相容，可暫以 node 執行不阻塞
- [schema 格式日後再調整] → 解析層與 IR 分離 (Decision 6)，只動 loader 與 zod 宣告，emitter 零影響
- [生成檔被誤手改] → 檔頭警語 + check 模式擋提交 + (後續) CLAUDE.md 硬規則

## Migration Plan

1. 先建 / 收斂 shared/data-model (schema 目錄 + codegen.yaml + generator + 測試)，此階段不動 apps/apple
2. (後續階段) generate 產出 Generated/ 12 檔，再將既有 Domain 檔逐一改寫為 extension (一次 commit 完成拆分，避免中間態編譯失敗)
3. 三平台 build + 全測試驗證後，同步 root CLAUDE.md 與 apps/apple 文件
4. Rollback：整個 change 為純 additive + 檔案內容重組，git revert 即可完整回退；無資料 migration、無 schema 版本影響
