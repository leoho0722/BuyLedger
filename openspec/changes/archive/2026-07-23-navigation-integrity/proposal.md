## Why

HIG 審查在導航與呈現層找出九項 warning，它們的共通性質是「狀態機容許了不該存在的狀態」。

路徑唯一性方面：設定頁有兩條獨立的推進路徑，使用者已從清單進入設定後，AI 提示的深連結會再疊一層，返回路徑因而變成「更多 → 匯率工具 → 設定」這種與實際層級不符的序列。側邊欄同時混用兩種選取模型，選一個智慧分組會使「訂單」列與該分組列同時呈現選取態，而該操作還會靜默覆寫使用者原本的日期區間與類別篩選。訂單編輯 sheet 之上再疊全螢幕照片檢視，形成一次呈現兩層 modal。主檔管理頁上並列兩個 sheet 修飾子，兩個狀態若因競態同時成立，第二張會被靜默吞掉。

慣例遵循方面：iPad 的批次操作放在視窗底部工具列，而 iPadOS 使用者可自由拖曳視窗，下緣被拖出螢幕外時操作無法觸及。設定頁隱藏系統返回鍵後自繪返回鈕，連帶停用了系統的邊緣滑動返回。主檔的新增與重新命名做成帶輸入框的 alert，而 alert 的用途是傳達需要立即決策的關鍵資訊，不是承載表單。篩選 sheet 的搜尋提示寫死為「搜尋類別」，實際範圍卻同時涵蓋付款方式。

破壞性動作方面：主檔項目的刪除既無確認也不回滾——刪除立即從狀態移除並寫入資料庫，失敗時只送出訊息卻不還原，使用者同時看到「刪除失敗」與已經消失的項目。而主檔刪除會連帶影響既有訂單，破壞性其實高於單筆訂單刪除，後者反而有確認。

## What Changes

### 導航路徑唯一化

- 設定頁改由單一值導向堆疊承載，清單點擊與深連結寫入同一條路徑，深連結時先清空再推入。
- 側邊欄的分頁與智慧分組併入同一個選取模型，使系統只高亮一列；智慧分組不再靜默覆寫既有的日期區間與類別篩選。
- 照片檢視改以推進呈現於編輯表單既有的導覽堆疊內，不再疊第二層 modal。
- 主檔管理的新增與編輯併入單一呈現狀態，由狀態機保證互斥。

### 回歸系統慣例

- iPad 批次操作改放頂部位置，選取筆數改由導覽標題承載。
- 設定頁交回系統返回鍵，取回邊緣滑動返回。
- 主檔的新增與重新命名改用 sheet 內的表單。
- 篩選 sheet 的搜尋提示改為涵蓋實際範圍。

### 破壞性動作安全網

- 主檔刪除加入確認，文案點明會影響既有訂單；刪除失敗時回滾狀態，使畫面與資料庫一致。

## Non-Goals

- 不處理 blocker 與 suggestion 等級的發現。
- 不納入兩項大型架構重構：訂單列表以三欄分割視圖取代手刻並排、以及根層改用可轉換的分頁樣式取代尺寸類別分流。兩者各自都能拆掉整棵視圖樹，風險與其餘項目不同級，另案評估。
- 不重新設計側邊欄的資訊架構，例如把工具項目攤平到側邊欄，該項屬 suggestion 等級。
- 不調整訂單編輯表單的整體規模，例如改為全螢幕呈現或拆成多層，該項屬 suggestion 等級。
- 不為目前沒有搜尋的畫面新增搜尋。

## Capabilities

### New Capabilities

- `navigation-path-integrity`: 導航與呈現狀態的唯一性契約——單一路徑、單一選取模型、單一呈現層。
- `standard-navigation-affordance`: 系統導航慣例的遵循契約——控制項擺位、系統返回、alert 與 sheet 的分工、搜尋範圍揭示。
- `destructive-action-safeguard`: 破壞性動作的安全網契約——確認時機與失敗回滾。

### Modified Capabilities

(none)

## Impact

- Affected specs: navigation-path-integrity、standard-navigation-affordance、destructive-action-safeguard
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Features/More/MoreView.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsView.swift
    - apps/ios/BuyLedger/Features/App/RootSidebarLayout.swift
    - apps/ios/BuyLedger/Features/App/RootFeature.swift
    - apps/ios/BuyLedger/Features/Orders/OrderEditView.swift
    - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersView.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupManagementView.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupManagementDestination.swift
    - apps/ios/BuyLedger/Resources/Localizable.xcstrings
    - apps/ios/BuyLedgerTests/__Snapshots__
  - New:
    - apps/ios/BuyLedger/Features/More/MoreRoute.swift（更多分頁的值導向路徑列舉）
