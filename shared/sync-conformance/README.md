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
