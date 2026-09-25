## Why

三份權威來源記載的都是已被實測否定、程式碼也已刪除的舊方案，而依規格施工的人與 AI 不會回頭質疑規格：

- `keyboard-dismissal-paths` 仍要求「非捲動畫面以點擊背景收鍵盤」，並把「掛在畫面背景層」寫成正解。實際上這個作法在 Form、List 與 ScrollView 版面都收不到觸控（Form 即使隱藏捲動背景亦然），已於實作中移除，平台指引也明文寫「不可行、不要再嘗試」。
- `campaign-calendar-reminder` 仍以「點按鈕開 popup 選日期時間」描述提醒設定。該設計經兩版被否決，現行實作是表單內的開關加條件顯示的 inline 日期選擇器，且 `sheet-nested-presentation` 已經以 inline 口徑寫過一次，兩份規格互相打架。
- `apps/ios/CLAUDE.md` 對同一個功能給出互斥指令：一處描述以 sheet 加 graphical 日期選擇器呈現，另一處明文寫「走 Form 內 inline 日期選擇器，不要再自製 sheet／push／overlay」。

錯誤規格是施工指令的污染源：任何依它動工的後續變更都會先被帶偏一次，而本輪計畫後續還有二十餘個變更要依這些規格施工。本變更成本極低，卻是讓後續每一個變更的起點是正確的前置條件。

順帶清掉兩個同源殘留：兩個從未被顯示的孤兒本地化字串，以及平台指引裡一個已不存在的元件範例。

## What Changes

- 改寫 `keyboard-dismissal-paths` 三條 requirement：把收鍵盤路徑收斂為實際採用的三條（一般鍵盤的 return 鍵、數字鍵盤的鍵盤工具列動作、可捲動畫面的捲動收合），刪除背景點擊的 scenario；保留「不得以 window 級手勢加排除清單實作」這條仍然有效的禁令，並把「改掛背景層」這個補救方案改為指向前述三條具名路徑，同時明文記載背景層點擊已被實測否定。
- 汰換 `campaign-calendar-reminder` 的 popup requirement：以 REMOVED 加 ADDED 取代原標題（原標題本身含 popup 字樣，直接改標題會讓封存時比對失敗而多出重複條目），新條目描述表單內開關加條件顯示的 inline 日期選擇器，用詞與 `sheet-nested-presentation` 對齊，避免製造新的雙份宣告。
- 清除 `apps/ios/CLAUDE.md` 的兩處殘留：刪除描述 sheet 呈現方式的子句，只保留與呈現方式無關的資料規則（預設值取結單日或當日上午九點、儲存時重新校準事件），讓 inline 那條成為唯一敘述；並把一條版面規則的範例收斂為仍然存在的那一個，移除已改為開關而不再使用該元件的範例。
- 移除兩個孤兒本地化字串（新增提醒、移除提醒），兩者在產品程式碼中只出現於註解、零實際使用點；並在本地化目錄測試加一組「已退役字串不得復活」的斷言。

## Non-Goals

- 不改動任何產品程式碼。本變更唯一進入產物的差異是移除兩個從未被顯示的字串。
- 不動任何 `@trace` 區塊。這些區塊由封存工具重寫，其路徑失效與體積問題屬另一個變更的範圍。
- 不回頭修改已封存變更內的任務描述。封存內容記錄的是當時的施工事實，改它等於竄改歷史，且它不是施工指令的來源。
- 不為 inline 日期選擇器補上輔助技術識別碼、也不新增 UI 測試。識別碼與消費它的測試同批交付是既有慣例；在此動它會讓本變更從純規格對齊擴大成需要跑兩輪 UI 回歸的產品變更。
- 不改寫 `keyboard-dismissal-paths` 的第四條 requirement（焦點狀態放置慣例），該條與現況一致。

## Capabilities

### New Capabilities

（無）

### Modified Capabilities

- `keyboard-dismissal-paths`: 收鍵盤路徑的定義由四條收斂為三條，並移除已被否定的背景層補救方案。
- `campaign-calendar-reminder`: 提醒設定的呈現方式由 popup 改為表單內 inline 日期選擇器。

## Impact

- Affected specs: `keyboard-dismissal-paths`（修改）、`campaign-calendar-reminder`（修改）
- Affected code:
  - Modified:
    - apps/ios/CLAUDE.md
    - apps/ios/BuyLedger/Resources/Localizable.xcstrings
    - apps/ios/BuyLedgerTests/LocalizationCatalogTests.swift
  - New: （無）
  - Removed: （無檔案刪除；移除的是兩個孤兒本地化字串條目）
- 不涉及 SwiftData schema、產品程式碼與建置設定；對使用者可見的行為變化為零。
- 已知的既有問題但不在本次處理：開團編輯畫面的提醒開關有一個零呼叫者的測試輔助方法，留給 UI 測試覆蓋類的變更處理。
