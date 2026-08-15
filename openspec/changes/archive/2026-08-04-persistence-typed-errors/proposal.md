## Why

目前 SwiftData 持久化 actor 與 repository boundary 大量暴露 `any Error`，上層無法從型別看出是讀取、寫入、container 建立或資料完整性錯誤。Swift 6 Typed Error 已經啟用，現在應把儲存基礎錯誤與訂單／付款方式等語意錯誤收斂成可辨識的錯誤契約。

## What Changes

- 新增共用 `PersistenceError`，統一表示 SwiftData 與持久化 container 的基礎錯誤。
- 各 persistence domain 保留自己的語意錯誤，並以 typed throws 宣告可拋出的完整錯誤集合。
- 將 SwiftData 的原生錯誤在 persistence boundary 轉換，不讓上層直接依賴 SwiftData 或 NSError 的具體型別。
- 讓對應的 repository dependency closure 與測試替身同步使用新的 typed error contract。
- 補上錯誤分類與底層訊息保留的單元測試。

## Non-Goals

- 不變更 SwiftData schema、migration、資料格式或 CloudKit 行為。
- 不變更使用者看得到的錯誤文案。
- 不把行事曆、網路或 AI client 的錯誤併入 `PersistenceError`。
- 不把所有 domain-specific error 粗暴合併成一個沒有語意的 generic case。

## Capabilities

### New Capabilities

- `persistence-error-contract`: 定義持久化層的 typed error 邊界、基礎錯誤分類與 domain-specific error 保留規則。

### Modified Capabilities

- (none)

## Impact

- Affected specs: persistence-error-contract
- Affected code:
  - New: apps/ios/BuyLedger/Core/Persistence/PersistenceError.swift
  - Modified: apps/ios/BuyLedger/Core/Persistence/
  - Modified: apps/ios/BuyLedger/Core/Dependencies/
  - Modified: apps/ios/BuyLedgerTests/

