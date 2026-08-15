## Why

跨平台產生器的 Kotlin 輸出把列舉 case 名稱直接轉成全大寫。單字 case 沒問題，但多字的駝峰式 case 會失真：實際 schema 中的兩個多字 case 會產出沒有底線的全大寫字串，不符合該平台的命名慣例。同一個轉換在列舉預設值那裡被重複寫了一次，因此修一處不會修到另一處。

這個缺陷之所以一直存在，是因為 golden 檔測試的素材只有兩個單字 case。素材涵蓋不到的路徑，測試就永遠是綠的。同樣的盲區還有幾條 emitter 分支目前無任何素材涵蓋：其中自訂序列化的實體對應產線既有形狀 (例如 LedgerOrderItem)；字串與布林欄位預設值、以及整數基底的包裝型別，產線目前並未實際使用這兩種形狀，補上純粹是為了補齊 emitter 分支覆蓋，避免這些路徑壞掉時完全無測試可偵測。

另外，schema 註解必須保持平台中立（不得出現任一平台的語言或框架用詞），而根目錄指引另有「不使用破折號」的規範。這兩條目前都靠人自律，沒有任何測試守著。現況是乾淨的，正是把它鎖住的最好時機。

Kotlin 輸出目前不在產線（只有一個平台的產出被消費），因此這是一個潛伏缺陷：等到真的接第二個平台時才會發現命名全錯，屆時修正會連動已產出的程式碼。

## What Changes

- 列舉 case 的平台命名轉換改為正確的分詞形式，讓多字駝峰式 case 產出帶底線的全大寫；case 宣告與列舉預設值兩處共用同一份轉換函式，不再各寫一次。
- golden 檔素材補上四條目前無保護的 emitter 分支：多字列舉 case 與自訂序列化的實體對應產線既有形狀；字串與布林欄位預設值、整數基底的包裝型別則純為補齊 emitter 分支覆蓋 (產線目前未使用這兩種形狀)。素材補齊後對應的期望輸出一併建立。
- 新增測試守住 schema 註解的平台中立性：註解出現任一平台的語言或框架用詞時測試失敗。
- 新增測試守住註解不使用破折號的規範。
- 明訂 golden 素材必須涵蓋產線實際使用的所有 emit 路徑，讓「素材涵蓋不到就永遠綠燈」這個結構性問題有規格層的約束。

## Non-Goals

- 不把 Kotlin 或 TypeScript 產出接上產線。本次只修正它們的正確性與測試覆蓋，產線消費仍只有一個平台。
- 不改變任何既有的 Swift 產出。修正只影響 Kotlin 的列舉命名，Swift 的列舉產出不變。
- 不改動 schema 的任何資料形狀。
- 不重構產生器的整體架構或 emitter 的分層。
- 不為 TypeScript 輸出新增命名轉換規則（該平台的列舉表示方式不受此缺陷影響）。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `data-model-codegen`: golden 檔測試的素材涵蓋範圍由「有測試」提升為「必須涵蓋產線實際使用的所有 emit 路徑」；schema 註解的平台中立性由人工規範提升為測試強制；並新增列舉 case 的平台命名轉換規則。

## Impact

- Affected specs: `data-model-codegen`（修改）
- Affected code:
  - Modified:
    - shared/data-model/generator/src/datamodel-gen.ts
    - shared/data-model/generator/test/datamodel-gen.test.ts
    - shared/data-model/fixtures/schema/sample-enums.yaml
    - shared/data-model/fixtures/schema/sample-orders.yaml
    - shared/data-model/fixtures/expected/kotlin/SampleStatus.kt
    - shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift
    - shared/data-model/fixtures/expected/typescript/SampleStatus.ts
    - shared/data-model/README.md
    - CLAUDE.md（root，記錄 schema 中立性／破折號規範已由測試強制，以及 golden 素材涵蓋規則兩條新硬規則）
  - New: shared/data-model/fixtures/schema/sample-trait-matrix.yaml（補齊產線 trait 組合鏡射守門所需的四種型別）；其餘視素材補齊後新增的期望輸出檔而定，落在 shared/data-model/fixtures/expected/ 三個語言目錄下
  - Removed: （無）
- 不影響產線輸出：產線只消費一個平台的產出，而該平台的列舉產出不因本變更改變。變更後仍須跑一次漂移檢查確認產線生成檔無差異。
- 次序約束：本變更的「工作樹無產線生成檔差異」驗收，必須在同批次其他會改動 schema 的變更完成並重新產生之後才成立。
