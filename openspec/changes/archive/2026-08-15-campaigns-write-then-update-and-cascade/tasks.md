## 1. 讓失敗被看見

- [x] 1.1 先寫紅燈測試釘住「失敗必定可見」：以注入失敗的儲存層執行結團，斷言出現可呈現的失敗對話框。對應 spec requirement「Campaign write failures are visible to the user」。驗證：測試在實作前失敗（apps/ios/BuyLedgerTests/CampaignFeatureTests.swift）。
- [x] 1.2 把一次性寫入失敗改以可呈現的對話框狀態承載，`errorMessage` 收窄為只由 `.task` 載入失敗路徑設值。依 design「移除無人讀取的訊息欄位，改以對話框承載一次性失敗」。驗證：1.1 測試轉綠；既有的載入失敗測試維持綠燈（apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift）。
    - ⚠ **修正輪更正**：本項原驗證敘述「全專案搜尋該欄位零命中」與實作不符，`errorMessage` 並未移除，而是收窄為只由 `.task` 載入失敗路徑設值，並新增 `loadState` + `BLLoadFailureView` 讓它首次真正被呈現 (實作結果比原案更好，且與 `OrdersFeature` 既有分工對齊：`errorMessage` 專用於載入失敗的持續呈現、寫入失敗走 alert)。spec 的真正語意是「沒有任何呈現處讀取該欄位」，`errorMessage` 現在有呈現處讀它，spec 滿足；保留實作，改寫此處驗證敘述以反映實況。
- [x] 1.3 讓對話框在兩種版面層級都出現在正確位置：列表與詳情各自保留呈現入口並掛上對話框。驗證：iPhone 與 iPad 各跑一次 UI 回歸，確認自兩處觸發失敗時對話框皆可見（apps/ios/BuyLedger/Features/Campaigns/CampaignListView.swift、apps/ios/BuyLedger/Features/Campaigns/CampaignDetailView.swift）。

## 2. 五條寫入路徑改為先寫後改

- [x] 2.1 先寫紅燈測試釘住五條路徑的不變性：以注入失敗的儲存層分別執行儲存、狀態切換、結團、列表刪除、詳情刪除，逐一斷言畫面狀態未變。對應 spec requirement「Campaign write paths update presented state only after persistence resolves」。驗證：五條斷言在實作前皆失敗。
- [x] 2.2 讓儲存、狀態切換、結團三條路徑在寫入成功後才更新畫面狀態。驗證：2.1 對應三條斷言轉綠，既有的成功路徑測試維持綠燈（apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift）。
- [x] 2.3 確認翻轉寫入順序後，名稱唯一性檢查仍在流程最前面、於任何寫入與行事曆呼叫之前返回。對應 spec requirement「Duplicate-name rejection stays ahead of any write」，依 design「保留前一變更放在寫入之前的名稱守門」。驗證：新增測試斷言重複名稱的儲存不觸發任何儲存層或行事曆相依呼叫；前一變更的名稱唯一性與結單日測試維持綠燈。

## 3. 刪除的連動清理

- [x] 3.1 先寫紅燈測試釘住「刪除不留痕跡」：刪除一個具成員訂單與提醒的開團後，斷言三件事同時成立，該開團名稱不在任何訂單的名稱陣列、提醒連結記錄不存在、行事曆客戶端收到移除該事件的呼叫。對應 spec requirement「Deleting a campaign removes every trace of it」與「Campaign entity with two-state lifecycle」的刪除語意。驗證：三條斷言在實作前皆失敗。
- [x] 3.2 讓本機三件事在單次落盤內完成：開團資料列移除、該名稱自所有訂單移除（比照既有的改名連動走同一條全表更新路徑）、提醒連結記錄移除。依 design「刪除的連動清理與開團刪除在同一次操作內完成」。驗證：3.1 前兩條斷言轉綠；另補測試斷言任一部分注入失敗時開團仍存在且訂單名稱未被移除（apps/ios/BuyLedger/Core/Dependencies/CampaignReminderRepository.swift）。
- [x] 3.3 讓行事曆事件在本機刪除成功之後才移除，且其失敗不回滾本機刪除但必須告知。對應 spec requirement「Deleting a campaign removes every trace of it」的行事曆情境。驗證：3.1 第三條斷言轉綠；另補測試斷言行事曆移除失敗時開團維持已刪除且出現告知對話框。
- [x] 3.4 把兩條逐字重複的刪除處理與其對話框內容建構收斂為單一實作，但保留兩個呈現入口。依 design「兩條刪除路徑收斂為單一實作，但保留兩個呈現入口」。驗證：兩段處理去縮排後差異為零；自列表與詳情刪除的既有測試皆維持綠燈。

## 4. 提醒生命週期

- [x] 4.1 先寫紅燈測試釘住重建不留殘影：在提醒重建過程注入舊事件刪除失敗，斷言連結記錄指向的是新建立的事件識別碼。對應 spec requirement「Campaign-to-event link with timestamp is stored in local SwiftData」的重建情境。驗證：測試在實作前失敗（apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift）。
    - ⚠ **修正輪更正**：本項先前標記 [x]，但描述的測試實際不存在——全庫沒有任何 rebuild 情境注入 `removeReminder` 失敗；`design.md`「舊事件可能殘留，該情形須告知」與 spec scenario「Interrupted rebuild leaves a resolvable link」的失敗回報也未實作（舊事件移除失敗被 `try?` 靜默吞掉，未送出任何 action）。已於修正輪補上 `CampaignReminderFailureTests.rebuildReportsFailureWhenTheOldEventCannotBeRemoved`（先確認拿掉告知後測試轉紅、實作後轉綠），並讓該失敗經 `campaignWriteFailed` 告知使用者（`CampaignFeature.swift` 的 `.rebuild` 分支），補上中英文案。
- [x] 4.2 讓提醒重建改為先建立新事件並更新連結、成功後才刪除舊事件，使中途失敗最壞只留下重複的行事曆項目而非指向虛無的連結。依 design「提醒重建改為先建後刪」。驗證：4.1 測試轉綠，且既有的提醒建立與移除測試維持綠燈。

## 5. 行事曆存取的失敗分類

- [x] 5.1 讓存取不可用的原因以使用者能採取行動的方式呈現：區分被裝置政策限制、被使用者拒絕、以及找不到可寫入的行事曆三種情境，各自給訊息，後者不得描述為權限問題。對應 spec requirement「Calendar access is requested lazily and denial is surfaced」，依 design「行事曆存取的失敗分成三類」。驗證：三種情境各有一條測試斷言對應訊息；既有的「授權後失敗不得走拒絕路徑」測試維持綠燈（apps/ios/BuyLedger/Core/Dependencies/CalendarReminderClient.swift、apps/ios/BuyLedgerTests/CalendarReminderTests.swift）。

## 6. 一致性與文案

- [x] 6.1 讓「畫面等於資料庫」成為可驗證的性質：新增測試在任一寫入失敗後重新自儲存層載入，斷言重載結果與失敗當下的畫面呈現相同。驗證：五條路徑各一次，皆通過。
- [x] 6.2 補齊新增對話框文案的中英對照並納入本地化目錄的必備清單。驗證：本地化目錄測試綠燈，英文模式下無語言回退（apps/ios/BuyLedger/Resources/Localizable.xcstrings）。

## 7. 驗收

- [x] 7.1 執行整體驗收：主 scheme 全套單元測試綠燈且新增測試全程未關閉窮舉檢查、UI 主回歸在 iPhone 與 iPad 各一次綠燈。驗證：測試通過數不低於改動前；對本次新增測試搜尋關閉窮舉檢查的呼叫零命中。
    - 修正輪獨立複驗：上一輪宣稱的 UI 主回歸未經獨立複驗；本輪重新在 iPhone 與 iPad 各跑一次，見下方結果。

## 8. 修正輪：QA 契約缺口與弱測試修補

上一輪 16/16 完成、444 測試綠燈，QA 以變異測試複驗五條核心修正為根本修正，但找到 3 項契約未兌現與數項弱測試，本節記錄修正輪的補完項目。

- [x] 8.1 還原 `OrdersFeature` 的編譯期窮舉：change 8 遺留兩處 `default: return .none`（Reduce 1／2），讓新增 action case 能靜默 no-op 且編譯通過，牴觸本變更「先寫後改」要根除的靜默失敗模式。換回顯式列舉並修正誤導性註解（「單一 switch 會逾時」不支持 `default:`：顯式列舉已拆成三段、本就不是單一 switch）。驗證：iOS 與 iPadOS 各 build 一次成功（apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift）。
- [x] 8.2 補上 `RootFeature` 副本同步斷言的真測試：`CampaignIntegrationTests.campaignDeletedCascadesToOrdersInMemoryAndSyncsCopy` 原本 `campaigns.campaigns`／`orders.campaigns` 皆留在預設 `[]`，讓 `state.orders.campaigns = state.campaigns.campaigns` 這行成為 no-op、刪掉仍綠燈（假測試型態）。改為兩者皆以 `[campaign]` 起始。驗證：刪掉該行測試轉紅、restore 後轉綠（apps/ios/BuyLedgerTests/CampaignIntegrationTests.swift）。
- [x] 8.3 補上刪除原子性測試：`CampaignPersistenceTests.deleteIsAllOrNothingWhenSaveFails` 以唯讀 disk-backed store 模擬 `save()` 失敗，斷言開團仍存在、訂單名稱未被剝除、提醒連結未被移除。`CampaignPersistence.delete` 加註解說明不需 `rollback()` 的理由（依賴 per-operation context，失敗即整個丟棄）。對應 spec scenario「Local deletion is all or nothing」。驗證：把 `save()` 改成 `try?` 吞錯的變異測試轉紅、原實作轉綠；另實測 QA 原始「拆成兩次 save()」的變異在唯讀 store 技巧下不可偵測（唯讀會讓兩種實作都在第一次 save 就失敗，故障模式相同、無法區分），已誠實揭露此技術限制（apps/ios/BuyLedgerTests/CampaignPersistenceTests.swift、apps/ios/BuyLedger/Core/Persistence/CampaignPersistence.swift）。
- [x] 8.4 五條 reload consistency 測試改用真正的唯讀 disk-backed `CampaignRepository`（而非把失敗當下的 state 塞回 mock 造成重載來源自我回填、斷言恆真）。驗證：改用空陣列 seed 會轉紅、改回正確 seed 轉綠，證明重載來源已與呈現值解耦（apps/ios/BuyLedgerTests/CampaignFeatureTests.swift）。
- [x] 8.5 測試 helper `failureAlert(_:)` 參數型別由 `String` 改為 `LocalizedStringKey`：原型別會讓 `TextState` 走 verbatim init，在 zh-Hant 測試計畫下與正確的 catalog key 解析結果剛好相等，抓不到生產端退回 verbatim init 的回歸（apps/ios/BuyLedgerTests/CampaignFeatureTests.swift）。
- [x] 8.6 判斷：`CampaignFeature.removeReminder(campaignID:...)`（使用者主動關閉提醒時呼叫）也有兩個 `try?` 靜默吞錯；design／spec 未要求告知這條 (該路徑設計為「使用者意圖即移除，事件不存在或移除失敗一律仍清除連結」)，故不比照 4.1 修改，維持現狀。
- [x] 8.7 判斷：`CampaignPersistence.delete` 用未 trim 的 `name` 剝除訂單，`RootFeature` 用 trim 後的名稱剝除記憶體副本；決定不統一——change 8 起儲存時已 trim、風險低，且此差異屬 design 明訂 Non-Goals（不改變以名稱字串關聯的結構）範圍外，不在本輪處理。

## 9. 修正輪：Coding Style 審查

功能面已驗收完畢（單元測試 446/0、UI 主回歸兩尺寸皆綠），本節記錄 Style 審查找出的問題與修正，不改變任何行為。

- [x] 9.1 移除兩處破折號：`CampaignFeature.swift` 表單關閉與清單更新的註解、`CampaignReminderFailureTests.swift` rebuild 測試的註解，改用全形逗號／冒號。`CampaignFeature.swift` 另一處既有的「權限已授予」註解 (經 `git show HEAD` 比對確認僅隨 Reduce 拆分位移) 依既有內容不回頭清的慣例保留不動。
- [x] 9.2 改寫 4 處註解，讓其描述「程式在做什麼」而非「這次改了什麼」：`CampaignFeature.swift` 移除「改為」措辭；`CampaignReminderFailureTests.swift` 移除「過去被 try? 靜默吞掉」的 diff 敘事；`CampaignIntegrationTests.swift` 移除 `P1-1` 編號並改寫為對現況的陳述；`CampaignFeatureTests.swift` 三處移除 `P2-1`／`P2-2` 內部審查編號，保留其後的技術理由。
- [x] 9.3 修正 `CampaignFeature.swift` 的 `CampaignFeature.State` MARK 順序：`Nested Types` (`LoadState`) 原本排在該型別所有方法段之後，與 `apps/ios/CLAUDE.md` 的區段順序表（Nested Types 為第 5 段、方法為第 7 段）不符，且與下一個屬 `CampaignFeature` 的 `Nested Types` 相鄰同名。改為排在該型別 `Internal Method` 之前，比照 `OrdersFeature.State.LoadState` 的既有排法。
- [x] 9.4 合併 `.noticeAlert(.presented(.openSettings))` 與 `.detailNoticeAlert(.presented(.openSettings))` 兩段逐字重複的 3 行 body 為單一 case pattern，呼應本案「兩條逐字重複的處理收斂為單一實作」的既有原則。
- [x] 9.5 新增 `notice(title:message:)` helper，收斂 `reminderAccessRestricted`／`reminderCreationFailed`／`reminderCalendarUnavailable` 三處與既有 `failureNotice(_:)` 形狀相同的 inline `AlertState` 字面值；`failureNotice(_:)` 改為呼叫 `notice(title: "操作失敗", message:)`。`reminderAccessDenied` 因多帶一個「前往設定」按鈕、形狀不同，維持原樣不收斂。
- [x] 9.6 拆分 `// MARK: 一次性通知`：`deletionAlert(for:)` 是刪除確認對話框而非一次性通知，另立 `// MARK: 刪除確認`；`presentNotice`／`notice`／`failureNotice` 留在 `// MARK: 一次性通知`。
- [x] 9.7 補齊本地化目錄必備清單：`LocalizationCatalogTests.requiredProgrammaticKeys` 補上本案新增／首次真正呈現的 11 條開團文案（7 條 `campaignWriteFailed` 訊息、4 條行事曆存取分類與操作失敗相關的對話框標題／訊息），比照 change 8 為 `OrdersFeature` 文案所做的處理；catalog 本身已確認齊全，不需改動。順帶修正 `requiredEnglishValues` 字典字面值多餘的尾逗號。
- [x] 9.8 修正 tasks 1.2 的驗證敘述與現況不符：`errorMessage` 並未如原敘述移除，而是收窄為只由 `.task` 載入失敗路徑設值並新增呈現處；保留實作、改寫驗證敘述（詳見 1.2 項下的修正輪更正）。
- [x] 9.9 補齊 4 條硬規則到 `apps/ios/CLAUDE.md`：「資料層與 Dependency 注入」節新增開團刪除三件事的單一交易不變式、`CampaignRepository` per-operation context 故 `delete`／`upsert` 失敗不需 `rollback()`（與訂單持久層長命實例須 `rollback()` 的規則方向相反）；「行事曆整合 (EventKit)」節新增提醒重建先建後刪的規則、`CalendarReminderClient.requestAccess` 三態與 `noWritableCalendar` 不屬權限問題的規則。
