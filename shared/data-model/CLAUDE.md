# shared/data-model 指引

本檔記錄跨平台 data model schema 與 `datamodel-gen` 產生器的硬規則與 gotcha；schema 格式、指令與改欄位流程見本目錄 [`README.md`](README.md)，跨平台總則見根目錄 [`CLAUDE.md`](../../CLAUDE.md)。

## Schema 與生成檔

- **生成檔預設唯讀** (`generate` 會 chmod `0o444`)：重生成直接再跑 `bun run generate` (自動解鎖、重寫、重鎖)，只有刻意手動檢視／實驗才 `bun run unlock`。唯讀只是本機防線 (git 不追蹤 write bit，clone 後回到可寫)，與檔頭警語、`check` 守門三者並行。
- **schema `doc` 保持平台中立**：只描述資料概念，不得出現任一平台的語言／框架用詞或該平台 codebase 的型別名；平台慣用法 (如 Swift 的 `Sendable`) 由該平台 emitter 決定，不入 schema。
  - 黑名單為大小寫不敏感的整詞比對，含 `interface`／`protocol`／`struct`／`Java`／`Foundation` 等泛用字，寫 doc 時要避開。
  - `doc` 不得使用全形破折號；結尾的 。 由 emitter 在 emit 時統一去除 (`docLines`／`blockDoc` 與檔頭模板)，schema 可照常書寫、不需手動去尾。
  - 以上由 `generator` 的 `bun test` 強制，違反時測試與 CI 皆變紅。

## 測試與守門

- **golden 素材須涵蓋產線實際使用的 emit 路徑**：schema 若用到 `fixtures/` 尚未示範的組合 (新的 trait 組合、wrapper 基底型別、default 種類)，須同步補上對應型別與三平台期望輸出，否則該路徑的 emitter 回歸不會被任何測試偵測到。
- **`bun test` 另含產線輸出同步斷言**：比對 `schema/` 與已提交的 `apps/ios/BuyLedger/Core/Domain/Generated`，並鎖住 `codegen.yaml` 的 swift target 輸出路徑；此處變紅代表生成檔與 schema 不同步，依訊息重新產生即可，不代表 generator 壞掉。
- **改 emitter 後**：`bun run generate` 重生產線輸出、`bun run check` 確認 exit 0，生成檔與 schema 一起 commit。
