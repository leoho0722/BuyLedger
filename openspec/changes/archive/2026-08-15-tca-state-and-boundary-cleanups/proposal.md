## Summary

把訂單篩選 sheet 的未套用選擇與捨棄確認流程自 View 下放到 `OrdersFeature.State`，讓它進得了 TestStore；同時讓四個 `Feature.State` 移除 `@unchecked Sendable`、回到 Swift 6 編譯器的檢查範圍，並清掉訂單編輯 feature 的空 extension 與錯位註解。

## Motivation

**篩選 sheet 的核心流程完全測不到。** `OrderFilterSheet` 的參數型別是 `StoreOf<OrdersFeature>`，卻在自己的 `init` 內以 `store.state` 種下四個 presentation `@State` (三個未套用選擇加一個捨棄確認旗標)，另有搜尋文字與兩段搜尋過濾計算也留在 View。平台指引明訂「綁 store 的 View 不持有 presentation 狀態」，其例外只給不綁 store、以 closure 與呼叫端溝通的可重用元件，本元件不適用。後果是未套用狀態的變更、是否有未套用變更的判斷、以及捨棄確認流程全部落在 TestStore 觸及不到的地方；UI 測試側也只有一個從未被呼叫的開啟入口，等於零覆蓋。這是先前的 View 到 Store 重構宣稱已清理完畢後唯一的實質殘留。

**四個 State 用型別範圍的豁免繞過 strict concurrency。** 設定、匯率、報價與訂單編輯四個 `Feature.State` 都標了 `@unchecked Sendable`，實際起因只是持有本地化字串資源或照片選擇項目。`@unchecked` 的豁免範圍是整個型別：日後有人往這些 State 塞進真正非執行緒安全的成員時，編譯器不會再出聲，而 strict concurrency 正是本專案的技術基礎之一。查證 SDK 與套件介面後，這些成員本身其實都已具備 Sendable 遵循，豁免很可能自始就不必要。

**訂單編輯 feature 留有重構痕跡。** 有一個完全空的 extension (違反專案「不留空 extension」規則)，且選擇器 route 的文件註解被錯貼到焦點欄位列舉上方，導致焦點欄位頂著一段描述 route 的說明，而真正的 route 列舉沒有任何說明。

**順帶發現的規格漂移。** 撰寫規格差異時發現 `order-filter-sheet` 規格從未記載付款方式 section，但該 section 在程式碼中確實存在；規格另稱搜尋「只過濾類別 section」，實際上付款方式清單同樣被過濾。本次要改的正是這幾條 requirement，無法在明知其內容與現況不符的情況下照抄，故一併更正。

## Proposed Solution

**一、未套用篩選狀態下放到 feature。** `OrdersFeature.State` 新增一個承載三欄未套用選擇的值型別 (日期區間、商品類別、付款方式)、篩選 sheet 的搜尋文字，以及一個捨棄確認的 `AlertState`。是否有未套用變更的判斷與兩段搜尋過濾清單自 View 搬成 State 的計算屬性，符合「資料計算不 inline 在 view body」。未套用選擇採非 optional 值型別而非 optional：optional 會讓 View 端每一列的判斷與搜尋綁定都要走 optional chaining，且巢狀 binding 在 optional 下不成立。

**二、開啟、套用、取消、捨棄四條路徑都由 reducer 表達。** 開啟 sheet 時以目前已套用值重種未套用選擇並清空搜尋文字；套用時逐欄比對、有差異才寫回已套用欄位，任一欄變動則重算一次選取中的訂單，最後關閉 sheet；取消時若有未套用變更則呈現捨棄確認，否則重種並直接關閉；確認捨棄則重種並關閉。View 端的 `@Environment(\.dismiss)` 一併移除，關閉一律由 reducer 把 sheet 開關設為 false，這是讓整條流程進得了 TestStore 的關鍵。

**三、`OrderFilterSheet` 變成純呈現元件。** 移除全部 `@State`、自訂 `init` 與 dismiss 環境值，各列的動作改送 action、勾選判斷改讀 State 的未套用選擇，捨棄確認改用 TCA 的 `AlertState` 呈現。既有的可及性識別碼全數原樣保留。

**四、四個 State 收斂 `@unchecked`。** 逐一移除 `@unchecked` 並顯式標註 `Sendable` 後編譯；顯式標註等於把「這個型別必須是 Sendable」寫成編譯期契約，日後往 State 塞入 reference type 會當場失敗。只有真的編不過的型別，才把該非 Sendable 成員抽成最小 wrapper 並在 wrapper 上寫明豁免理由，State 本身維持 `Sendable`。

**五、清掉重構痕跡。** 刪除空 extension，把 route 說明搬回其列舉上方，焦點欄位列舉只留焦點說明。此步純註解與空宣告移動，不動任何可執行程式碼。

## Non-Goals

- **不拆分 `OrdersFeature`。** 該檔已過大，本次新增的成員會讓它再長約九十行。這是把測不到的狀態換成測得到的必要代價；把純結構搬移的風險混進本次改動會讓出事時無法分離歸因。新增的 case 會相鄰擺放並以子分類註解集中，讓未來拆分是一刀可切的連續區塊。
- **不動導覽結構。** 選擇器 route 沿用既有的 `navigationDestination(for:)`，不改為 `navigationDestination(item:)` (會踩測試 target 的連結問題)。
- **不統一其餘尚未顯式標註 `Sendable` 的 `Feature.State`。** 那牽涉全庫一致性約定，屬專案慣例層級的決定，塞進本次會讓差異面積翻倍並模糊掉本次的三件事。
- **不新增任何本地化字串。** 捨棄確認沿用既有四句字面值，已確認皆存在於字串目錄。

## Alternatives Considered

- **套用時回傳三個 `Effect.send` 轉派既有的篩選 action。** 已否決：直接在 reducer 內改三個欄位是單一次狀態變更，TestStore 只需一段斷言、不必處理三個接收的順序，選取中訂單也只重算一次而非三次；兩種作法的最終值完全相同。
- **只下放風險點名的四個狀態，搜尋文字留在 View。** 已否決：搜尋文字同樣是綁 store 的 View 所持有的呈現狀態，留著代表平台規則仍未滿足，下一輪稽核會再報同一件事；且兩段搜尋過濾屬於資料計算 inline 在 view body，同樣違反既有規則。一併下放後驗收可簡化為「該檔 `@State` 數為零」這種一眼可驗的形式。
- **先為四個 State 各寫一個最小 wrapper。** 已否決：查證 SDK 與套件介面後，相關成員本身皆已具備 Sendable 遵循，預期四個都能直接編過；先寫四個 wrapper 再回頭刪除是多餘工序，也讓豁免無法真正歸零。改為先移除再編譯，只有實際失敗的那一個才退回 wrapper。

## Impact

- Affected specs: `order-filter-sheet` (修改)。篩選 sheet 的關閉防護規範已由既有的 `irreversible-action-safeguard` capability 涵蓋 (跨案，由 `ui-polish-and-safeguards` 建立)，本案不延伸 `sheet-dismissal-safeguard` 承接同一行為，僅在 `order-filter-sheet` 差異中指向該既有 requirement
- Affected code:
  - Modified:
    - apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift
    - apps/ios/BuyLedger/Features/Orders/Components/OrderFilterSheet.swift
    - apps/ios/BuyLedger/Features/Settings/SettingsFeature.swift
    - apps/ios/BuyLedger/Features/FX/FxFeature.swift
    - apps/ios/BuyLedger/Features/Quote/QuoteFeature.swift
    - apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift
    - apps/ios/BuyLedgerTests/OrdersFeatureTests.swift
