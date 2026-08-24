## Summary

讓四種主檔 (訂單來源、商品類別、付款方式、對帳狀態) 在 App 內只剩一份真相：改名、新增、刪除自動對所有消費端生效，並把三組逐字重複的資料層收斂成泛型；新增第五種主檔時漏補分支會是編譯錯誤，而不是執行期的靜默不一致。

## Motivation

**主檔資料存在多份副本，一致性靠手寫 cascade 維持。** 主檔管理頁持有一份清單，訂單 feature 另外持有四份記憶體副本 (訂單來源、商品類別、付款方式、對帳狀態各一)，兩者靠根 feature 約 300 行手寫的攔截與 cascade helper 保持同步。真正的病灶不是「有幾份副本」，而是**一致性由十餘個手寫攔截分支維持，而編譯器不會告訴你漏了哪一個**。漏接任一 action，或新增第五種主檔時忘了補分支，症狀就是「改名後訂單頁仍顯示舊值」這種執行期靜默不一致。

**可見性目前只有單向。** 主檔管理頁的變更會流到訂單編輯的選單，但在訂單編輯 sheet 內新增的類別不會出現在主檔管理頁，除非重啟 App。這是四份副本各自 append 造成的直接後果。

**資料層有三份逐字複製。** 三種只有名稱欄位的主檔，其 repository (各 108 行)、持久層 actor (各 78 行) 與持久化記錄 (各 31 行) 合計 652 行，正規化後彼此的差異只剩註解文字。Feature 層早已用一個列舉統一分流，資料層卻沒跟上，形成倒三角。

**這是拆分訂單 feature 的前置切面。** 主檔副本不消掉，訂單 feature 的狀態就瘦不下來。

## Proposed Solution

本案分兩個各自可編譯、可獨立驗證的半場，避免一次動二十個檔的大爆炸差異。

**資料層。** 抽出只有名稱欄位主檔的共用協定、泛型持久層 actor 與操作工廠，三個具體型別退化成十行左右的宣告。三個 repository 的對外欄位名、相依鍵與三個注入入口全部保留，呼叫點與既有測試零改動。付款方式因帶三個旗標、其寫入與更名語意與只有名稱的主檔不同，不納入泛型層。

**狀態層。** 引入一份主檔目錄值型別作為單一儲存，由訂單 feature 與主檔管理 feature 共用同一份記憶體儲存 (使用架構套件已 re-export 的共享狀態機制，不需新增套件產品、不引入新的第三方相依)。四份記憶體副本改為由該目錄導出的計算屬性，根 feature 的七個同步 helper 全數刪除。

**把差異掛回列舉。** 在主檔種類列舉上新增「訂單是否引用此主檔值」與「更名後的訂單」兩個成員，讓 cascade 對訂單表的重寫縮成一段不含分支判斷的映射，唯一的分支收在列舉內受窮舉檢查保護。同時把根 feature 的四個具名主檔狀態併成以種類為識別的陣列，攔截區從十餘個分支降到四個。兩者合起來，「新增第五種主檔忘了補分支」才會從執行期靜默不一致變成編譯錯誤。

**修好可見性。** 訂單編輯內新增主檔的四條路徑改為寫入同一份目錄，讓訂單編輯內新增的類別對主檔管理頁立刻可見。

## Non-Goals

- **不新增第五種主檔。**
- **不動主檔管理的畫面與種類列舉的既有分流語意。**
- **不把付款方式納入泛型資料層。** 它帶三個旗標，寫入語意是「已存在則更新旗標」、更名要做「任一邊為真就保留」的合併，與只有名稱的主檔不同。為了多消約 100 行而讓泛型層帶上額外的關聯型別與旗標合併策略，會讓泛型層比它取代的重複碼更難讀。
- **不把主檔目錄改成自帶持久化。** 專案硬規則是資料唯一來源為 SwiftData；目錄自帶檔案持久化等於用新的雙來源換掉舊的多份副本。
- **不併「更多」分頁的四個主檔路由。** 那會牽動可及性識別碼與介面自動化測試。
- **不改變任何使用者可見行為**，除了修好上述單向可見性這一項缺陷。

## Alternatives Considered

- **根 feature 唯一持有目錄，以雙向變更回呼整份覆寫同步到訂單 feature。** 已評估：能達成同樣的「消除漏接」效果，且步驟大部分共用。已否決：那仍是兩份記憶體，每個 action 都要對整份目錄做相等比較，且循環終止依賴「賦相同值不再觸發」這個需要人工推理的性質。共享儲存是三個選項中唯一真正做到單一儲存的。
- **本次只做資料層泛型化，狀態層副本留到下一個 change。** 已否決：範圍最小但主檔一致性仍靠手寫 cascade 維持，本案要解決的主要問題原封不動。
- **保留四個具名主檔狀態，只把攔截收斂成單一處理函式。** 已評估為退場方案：若識別陣列讓畫面端的可選解包過於彆扭，退回此作法仍能把攔截區降到四個分支，但新增第五種主檔時仍要在三處手動同步。
- **泛型層直接寫查詢條件並讓具體型別以別名退化。** 已否決：泛型參數上的鍵路徑不保證能被持久化框架轉譯成查詢條件，且失敗會發生在執行期而非編譯期。改由協定要求各具體記錄以自身型別展開查詢條件。

## Impact

- Affected specs: `lookup-management` (修改)
- Affected code:
  - New:
    - apps/ios/BuyLedger/Core/Persistence/NameLookupRecord.swift
    - apps/ios/BuyLedger/Core/Persistence/NameLookupPersistence.swift
    - apps/ios/BuyLedger/Core/Dependencies/NameLookupOperations.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupCatalog.swift
    - apps/ios/BuyLedgerTests/NameLookupPersistenceTests.swift
  - Modified:
    - apps/ios/BuyLedger/Core/Persistence/CategoryRecord.swift
    - apps/ios/BuyLedger/Core/Persistence/OrderSourceRecord.swift
    - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift
    - apps/ios/BuyLedger/Core/Dependencies/CategoryRepository.swift
    - apps/ios/BuyLedger/Core/Dependencies/OrderSourceRepository.swift
    - apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupKind.swift
    - apps/ios/BuyLedger/Features/Lookups/LookupManagementFeature.swift
    - apps/ios/BuyLedger/Features/App/RootFeature.swift
    - apps/ios/BuyLedger/Features/More/MoreView.swift
    - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
    - apps/ios/BuyLedger/Core/Domain/LedgerOrder.swift
    - apps/ios/BuyLedgerTests/RootFeatureTests.swift
    - apps/ios/BuyLedgerTests/LookupManagementFeatureTests.swift
    - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
    - apps/ios/CLAUDE.md
  - Removed:
    - apps/ios/BuyLedger/Core/Persistence/CategoryPersistence.swift
    - apps/ios/BuyLedger/Core/Persistence/OrderSourcePersistence.swift
    - apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusPersistence.swift
