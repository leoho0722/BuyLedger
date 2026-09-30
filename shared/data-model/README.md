# shared/data-model

## 用途 / 概觀

`shared/data-model/` 是 BuyLedger 跨平台 data model 形狀的唯一宣告來源 (single source of truth)。一份統一的 schema (以 YAML 撰寫) 經 `datamodel-gen` 產生器，輸出各平台語言的 data model 程式碼。

目前實際接上的產線目標為 Swift (Apple 平台)；TypeScript 與 Kotlin 的 emitter 已就緒、由 golden file 測試鎖定其正確性，待對應平台動工時於 `codegen.yaml` 加上 target 即可接上。

資料形狀的任何變更一律改 schema、再重新產生，**不手改生成檔**。schema 是唯一可編輯的來源，生成檔 (例如 `.generated.swift`) 為衍生產物。

## 目錄結構

| 路徑 | 內容 |
|------|------|
| `schema/` | 統一 schema，一型一檔的 YAML，目前共 12 個型別 |
| `codegen.yaml` | 產生器設定 (schema version 與輸出 targets) |
| `generator/` | `datamodel-gen` 產生器原始碼 (TypeScript + Bun) |
| `fixtures/` | golden file 測試素材 (測試用 schema 與三平台預期輸出) |

## 環境需求

- **Bun >= 1.3** (`brew install bun`)。產生器以 Bun 作為 runtime、測試器與套件管理工具。
- 型別檢查走 `bunx tsc --noEmit`。
- 執行階段依賴 (見 `generator/package.json`)：
  - `zod`：schema 宣告即驗證。
  - `yaml`：YAML 解析。

## Schema 格式

### 一型一檔

schema 採一型一檔，檔名對應型別名 (例如 `schema/LedgerOrder.yaml`)。每個檔案頂層含一個 `types:` 陣列。

### 三種 kind

每個型別宣告 `kind`，共三種：

- `entity`：多欄位記錄，以 `fields:` 列出欄位。
- `enum`：字串 raw value 列舉，以 `cases:` 列出 case。
- `wrapper`：單值 newtype，以 `base:` 指定底層基礎型別。

### Trait 詞彙

`traits:` 使用平台中立的詞彙 (不出現任何單一平台專屬詞)：

- `value-equality`
- `serializable`
- `identity`
- `case-iterable`
- `hashable`

另有與 `serializable` 互斥的 `serialization: custom` marker，表示序列化由手寫程式處理，生成宣告不含序列化 conformance。

Swift 的 `Sendable` **不是** schema trait——它是 Swift emitter 的全域政策，對所有生成的 struct / enum 一律加上；schema 不需要也不應宣告它。

### 型別文法 (單行字串 DSL)

欄位的 `type` 是單行字串 DSL：

- 基礎型別：`string` / `int` / `bool` / `decimal` / `date` / `data` / `uuid`。
- 容器：`array<T>` 與 `map<K, V>`。
- 對其他宣告型別的 by-name 引用，例如 `array<LedgerOrderItem>`、`map<CurrencyCode, decimal>`。

**nullability 不寫在型別字串內** (不使用 `?` 後綴)——改用欄位上的顯式 `nullable: true` (預設 false)。

### 欄位的其他可選屬性

- `mutable: true`：對應 Swift 的 `var` (預設 `let`)。
- `default`：欄位預設值，可為：
  - 字面值，例如 `0`、`""`、`false`。
  - 空陣列 `[]`。
  - enum case 引用，例如 `OrderStatus.confirmed`。
  - 計算 default sentinel `$newUUID`。

### default 與 nullable 的 emit 規則

- 有 `default`：使用其值。
- nullable 且無 `default`：emit 為平台 nil (`= nil`)。
- 非 nullable 且無 `default`：emit 為必填參數，**不**給零值。

### 文件註解

每個型別、欄位、case 都必須帶一段正體中文 `doc`，產生器會將其輸出為生成程式碼的文件註解。

`doc` 的內容必須維持平台中立，且不使用破折號；這兩條規則由 `shared/data-model/generator` 的 `bun test` 強制執行，不再只靠人工自律：

- 不得出現任一目標平台的語言、框架或型別建構用詞 (例如 Swift、Kotlin、TypeScript、struct、data class)，出現時測試失敗並指出違規的型別／欄位。
- 不得使用全形破折號 `—`，出現時測試同樣失敗。

### 範例

```yaml
types:
  - name: Campaign
    kind: entity
    doc: 開團 (一次團購批次)。
    traits: [value-equality, identity]
    fields:
      - name: id
        type: string
        doc: 開團的穩定識別值；identity trait 要求 entity 具備 id 欄位。
      - name: name
        type: string
        doc: 開團名稱。
      - name: closeDate
        type: date
        doc: 結單日期；選填，未設定時為 nil。
        nullable: true
      - name: notes
        type: string
        doc: 開團備註；無備註時為空字串。
        default: ""
```

## 產生與檢查指令

```bash
# 首次：安裝產生器依賴
cd shared/data-model/generator && bun install

# 產生：依 codegen.yaml 從 schema/ 重新產生各平台程式碼
# (等同 bun run src/datamodel-gen.ts generate --schema ../schema --config ../codegen.yaml)
bun run generate

# 漂移檢查：磁碟產出與 schema 同步時 exit 0；漂移時 exit 1 並列出漂移檔案
# (適合提交前 / CI 守門)
bun run check

# 解鎖：把生成檔改回可寫 (僅供刻意手動檢視／實驗；下次 generate 會重新鎖唯讀)
bun run unlock

# 測試 (golden file 測試；另含「產線 schema 與已提交產線輸出同步」的斷言，見下)
bun test

# 型別檢查
bunx tsc --noEmit
```

## 改欄位的標準流程

1. 編輯 `schema/` 下對應型別的 YAML。
2. 跑 `bun run generate` 重新產生。
3. 將生成檔與 schema 一起 commit。
4. 提交前跑 `bun run check` 確認磁碟產出與 schema 同步。

鐵則：**不可手改生成檔** (`.generated.swift` 等)，這些檔頭都帶有「請勿手動編輯」警語；資料形狀的任何變更一律改 schema。`generate` 會把生成檔鎖成唯讀 (`0o444`) 防手改——重生成會自動解鎖重寫，真要手動檢視才用 `bun run unlock` (本機防線，git 不追蹤 write bit)。

## golden 素材的涵蓋規則

`fixtures/schema/` 的素材必須涵蓋 `schema/` (產線 schema) 實際使用到的每一條 emit 路徑：golden-file 測試只能對素材裡實際存在的內容比對，素材沒涵蓋到的路徑，emitter 壞了也不會有任何測試變紅。新增或修改產線 schema 時，若用到素材尚未涵蓋的組合 (例如新的 trait 組合、新的預設值型別)，應同步補上對應的 fixture 型別與三平台期望輸出。

## 漂移由測試與 CI 強制

`bun test` 除了既有的 golden-file 測試 (鎖 `fixtures/` 的三平台 emitter 輸出) 之外，另含一組專守**產線輸出**的斷言：

- 對 `schema/` 與已提交的 `apps/ios/BuyLedger/Core/Domain/Generated` 執行漂移檢查，兩者不同步時測試失敗，訊息列出每筆漂移的原因與絕對路徑，並附上重新產生的指令。
- 鎖住 `codegen.yaml` 的 swift target 輸出路徑，避免有人改設定讓輸出指向他處、使上一條斷言失去比對標的而永遠綠燈。

這組斷言守的是「已提交的產線輸出是否與 schema 同步」，不是 generator 自身邏輯的回歸；後者已由 fixtures 的 golden-file 測試覆蓋。若在本機對 `generator/` 做實驗性修改時看到這裡變紅，代表 `apps/ios` 的生成檔與 schema 不同步，依失敗訊息重新產生即可，不代表 generator 本身壞掉。

版本庫層級的 `.github/workflows/ci.yml` 之 codegen job 會在每次推送與拉取請求時執行 `bun run check` 與 `bun test`，讓漂移在推送當下就變紅，而不是等人記得手動執行；提交前仍建議自行跑一次以及早發現。
