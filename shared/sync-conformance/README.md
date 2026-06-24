# 跨裝置同步 conformance vectors

本目錄存放跨平台同步的**唯一**測試向量來源。backend (NestJS)、web (TypeScript) 與 iOS (Swift) 各自的同步原語實作，必須對這裡的同一組向量全綠，確保三平台行為一致 (對齊 `openspec` 的 `sync-conflict-resolution` 與 `firestore-realtime-projection`)。

## `hlc-vectors.json`

Hybrid Logical Clock (HLC) 的 conformance vectors。HLC token 為 `{ p, c, w }`：

- `p`：物理毫秒 (epoch millis)。
- `c`：邏輯計數器 (同一毫秒內的因果序)。
- `w`：writerId (決勝最後一關)；後端固定 `server`，client 各自帶每安裝穩定 id。

向量分類：

| 區段 | 驗證 |
|------|------|
| `encode` | 序列化為可排序字串 `p(13):c(6):w`，使字典序等同因果序 |
| `compare` | 依 `p → c → w` 比較，回傳 `-1 / 0 / 1` |
| `generate` | 本地寫入事件的下一個時鐘 (lastIssued、nowMs → next) |
| `receive` | 觀察遠端時鐘後推進 lastIssued (標準 HLC 合併規則) |
| `tolerance` | incoming 物理時間不得超過 `now + toleranceMs` (預設 5 分鐘) |

各平台測試以檔案讀取 (非複製) 本 JSON，避免向量漂移。

## `field-merge-vectors.json`

欄位級合併 (field-level merge) 的 conformance vectors。每個 case 給定 `storedValues`/`storedClocks` 與一筆 `patch`，驗證合併後的 `expectedValues`、`expectedAppliedClocks`，以及該欄位是否變更 (`expectedChanged`)。涵蓋不相交欄位皆存活 (auto-merge)、同欄較高時鐘勝、等時鐘保留 stored、低時鐘落敗、新實體全收、重送 no-op、`items` 整欄 LWW 等情境。clock 採 `p(13):c(6):w` 編碼。

## `field-categories.json`

Order/Campaign **每欄位的同步分類**唯一來源。`field-merge-vectors.json` 驗證合併「行為」，本檔則宣告每欄位「屬於哪一類、套何種規則」，讓三平台的 `applyFieldWrites` (及同等物) 載入同一份分類來決定每欄位是否參與合併、是否帶 client clock、是否走特殊路徑。欄位列舉以 `openspec` design 的「欄位分類 (apply 定案)」為唯一依據，完整涵蓋 `LedgerOrder` 與 `Campaign` 所有欄位。

四類定義 (見檔內 `categoryLegend`)：

| 類別 | 意義 |
|------|------|
| `A` | 唯讀/不可變：create 後鎖定、不收 client clock、排除於欄位時鐘圖 |
| `B` | 後端衍生/重算：不收 clock、不參與合併，由 normalize 依勝出來源欄位重算 (`derivedFrom`/`dto-only`) |
| `C` | 一般可合併：各帶 clock、incoming 嚴格大於 stored 才套用、tie 由 writerId 決 |
| `D` | 可合併但帶特殊規則：在 C 基礎上加 sticky 終態、內容雜湊 union、整欄 LWW、lookup cascade、auto-close 投影等 (見欄位 `ruleTag` 與 `ruleTagLegend`) |

結構：`entities.{Order,Campaign}.fields.<欄位>` → `{ category, ruleTag?, rule?, derivedFrom?, baseCategory? }`。`baseCategory` 標出 D 類欄位其底層仍為 C 類可合併 (如 Campaign `name`/`status`)。

消費方式：各平台測試與合併核心以檔案讀取 (非複製) 本 JSON，依 `category` 分派合併策略、依 `ruleTag` 接特殊規則處理器，避免分類在三平台各自 hardcode 而漂移。

## 平台中立

本目錄所有 JSON 為三平台共用合約，**不得**出現任一平台的語言/框架用詞或型別名 (欄位名為跨平台資料概念，非平台型別)。
