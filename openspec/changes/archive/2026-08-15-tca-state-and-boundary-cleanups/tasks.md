## 1. OrdersFeature.State 承載未套用篩選

- [x] 1.1 依 design 決策：D1 未套用篩選採非 optional 值型別，在 `OrdersFeature.State` 新增巢狀值型別承載三欄未套用選擇 (日期區間、商品類別、付款方式) 並以非 optional 成員持有，另新增篩選 sheet 的搜尋文字成員與 `@Presents` 的捨棄確認成員。此為規格 Unified filter sheet exposes date period, category, and payment method sections 中「未套用選擇由 feature 而非 view 持有」的落地。驗證：專案可編譯，且新測試 `filterSheetTappedSeedsPendingFilterFromCommittedValues` 可直接對這些成員斷言
- [x] 1.2 新增「是否有未套用變更」的計算屬性 (三欄各自與已套用值比對)，供互動式關閉阻擋與取消分流使用。驗證：新測試 `pendingSelectionsDoNotTouchCommittedFilters` 中，選擇後該屬性為真而三個已套用欄位不變
- [x] 1.3 把兩段搜尋過濾計算自 `OrderFilterSheet` 搬到 `OrdersFeature.State`，來源改為新的搜尋文字成員，過濾語意 (不分大小寫的包含比對) 原樣保留。此為規格 Search in the unified filter sheet filters the category and payment method sections 的落地。驗證：新測試 `filterSheetSearchTextFiltersCategoriesAndPaymentMethods` 綠：輸入關鍵字後兩份清單只剩匹配項，日期區間清單不受影響

## 2. 開啟、套用、取消、捨棄四條 reducer 路徑

- [x] 2.1 新增六個 action (三個未套用選擇、套用、取消、捨棄確認的呈現 action) 與捨棄確認的巢狀列舉，並在 reducer body 尾端比照既有刪除確認掛上對應的 `.ifLet`。新增 case 相鄰擺放於既有開啟 sheet 的 case 之後，並以無破折號的子分類註解集中，讓未來拆分是連續區塊。驗證：專案可編譯，且既有 `OrdersFeatureTests` 全綠代表未影響既有分支
- [x] 2.2 讓開啟 sheet 的分支先以三個已套用值重種未套用選擇、清空搜尋文字，再把 sheet 開關設為真；三個未套用選擇的分支只寫入對應欄位、不碰任何已套用值。驗證：`filterSheetTappedSeedsPendingFilterFromCommittedValues` 與 `pendingSelectionsDoNotTouchCommittedFilters` 兩測綠 (皆使用 TestStore 預設窮舉模式，窮舉即可證明沒有額外狀態突變)
- [x] 2.3 依 design 決策：D2 套用在 reducer 內直接提交，不轉派既有 action，讓套用分支逐欄比對、有差異才寫回已套用欄位，任一欄變動則重算一次選取中的訂單，最後關閉 sheet。此為規格 Apply control commits pending changes and dismisses the sheet 的落地。驗證：`filterApplyCommitsChangedPendingValuesAndClosesSheet` 與 `filterApplyWithNoPendingChangesClosesSheetAndChangesNothing` 兩測綠
- [x] 2.4 依 design 決策：D4 捨棄確認改用 AlertState，讓取消分支在有未套用變更時建立捨棄確認 (沿用既有四句字面值、不新增字串目錄項目)，無變更時直接重種並關閉；確認捨棄的分支重種並關閉。驗證：`filterCancelWithPendingChangesPresentsDiscardConfirmation`、`filterDiscardConfirmedRevertsPendingFilterAndClosesSheet`、`filterCancelWithoutPendingChangesClosesSheetDirectly` 三測綠
- [x] 2.5 依 design 決策：D3 關閉一律由 reducer 決定，確認上述四條路徑的關閉動作全部由 reducer 設定 sheet 開關完成，View 端不再持有關閉能力。驗證：TestStore 可完整走完「開啟 → 三個未套用選擇 → 取消 → 確認出現 → 確認捨棄 → 未套用值回到已套用值且 sheet 開關為假」，全程三個已套用欄位未變

## 3. OrderFilterSheet 改為純呈現元件

- [x] 3.1 移除該元件的全部 `@State`、自訂 `init` 與 dismiss 環境值；搜尋輸入改綁 feature 的搜尋文字，各列動作改送對應 action，勾選判斷與可及性特徵改讀 State 的未套用選擇，互動式關閉阻擋改讀「是否有未套用變更」。既有可及性識別碼全數原樣保留。驗證：該檔 `@State`、`@Environment(\.dismiss)`、`init(store:` 三者命中數皆為零，且 iPhone build 成功
- [x] 3.2 移除該元件私有段中的未套用變更判斷、套用並關閉、以及兩份過濾清單定義；捨棄確認改為呈現 feature 的警示狀態。若該私有 extension 因此清空則整段一併移除 (專案禁留空 extension)。驗證：該檔不再定義這四個成員，且無空 extension 殘留
- [x] 3.3 同步該元件三個預覽的種子狀態，讓預覽傳入的日期與類別也種進未套用選擇。驗證：三個預覽開啟後勾選列與傳入值一致，未落回預設值 (人工於 Xcode 預覽確認)

## 4. 收斂 @unchecked Sendable

- [x] 4.1 依 design 決策：D5 先移除 @unchecked 再編譯，失敗才退回 wrapper，把設定、匯率、報價、訂單編輯四個 `Feature.State` 的 `@unchecked Sendable` 改為顯式 `Sendable` 後跑一次 iOS build。驗證：`grep -rn "@unchecked Sendable" apps/ios/BuyLedger/` 命中數為零；若某一個編不過，只對該型別的非 Sendable 成員抽出最小 wrapper 並在宣告上方以一行註解寫明是哪個成員、為何跨執行緒安全，該 State 本身仍維持 `Sendable`，且在本 change 的 design 記錄是哪一個
- [x] 4.2 [P] 以四個對應 feature 的既有測試作為 Sendable 化的回歸驗證。驗證：`OrderEditFeatureTests`、`FxFeatureTests`、`QuoteFeatureTests`、`SettingsFeatureTests` 全綠，代表 State 結構在此過程中未被誤改

## 5. 清掉 OrderEditFeature 的重構痕跡

- [x] 5.1 [P] 刪除訂單編輯 feature 的空 extension，並把選擇器 route 的說明註解自焦點欄位列舉上方搬回 route 列舉上方，焦點欄位列舉只保留焦點說明。此步純註解與空宣告移動，不得動任何可執行程式碼。驗證：該檔無空 extension 命中；route 列舉上方存在其說明、焦點欄位列舉上方只有焦點說明；`git diff` 中此段除註解與空白外無其他變更

## 6. 測試

- [x] 6.1 在 `OrdersFeatureTests` 新增篩選未套用流程測試段，共七條涵蓋：開啟時種值、未套用選擇不動已套用值、套用提交有差異欄位並關閉、無變更套用只關閉、有變更取消出現確認、確認捨棄回復並關閉、無變更取消直接關閉。一律使用 TestStore 預設窮舉模式，該段不得出現關閉窮舉的設定 (這幾條全是純狀態變更、無並行 effect)。需要斷言選取中訂單者以固定時間與固定日曆注入。驗證：七條全綠，且該段內關閉窮舉模式的命中數為零
- [x] 6.2 [P] (QA 修正輪更正敘述) 新增搜尋過濾測試，驅動搜尋文字後斷言 `filterSheetFilteredCategories`／`filterSheetFilteredPaymentMethods` 兩份清單只剩匹配項，取樣值須能拆穿誤用 `hasPrefix` 或誤用區分大小寫比對兩種錯誤實作 (原敘述誤稱本測試斷言「日期區間清單不受影響」；日期區間 section 由 view 直接列舉 `OrderDatePeriod.orderBrowsingCases` 呈現、不經任何 state 過濾計算，其「不受搜尋影響」屬結構性保證，本測試不涵蓋、也無需涵蓋)。驗證：`filterSheetSearchTextFiltersCategoriesAndPaymentMethods` 綠

## 7. 規格漂移更正

- [x] 7.1 依 design 決策：D6 規格漂移一併更正而非沿用，確認本 change 的規格差異已將 Unified filter sheet exposes date period and category sections 與 Search in the unified filter sheet filters only the category section 兩條移除，並由涵蓋付款方式 section 的替代 requirement 承接全部規範內容。驗證：`spectra validate tca-state-and-boundary-cleanups` 通過，且逐項比對替代 requirement 未遺漏原有任一規範句
- [x] 7.2 (QA 修正輪更正) 篩選 sheet 的互動式關閉阻擋與取消捨棄確認，其規範已由 `irreversible-action-safeguard` 既有的 Sheets holding uncommitted changes resist accidental dismissal requirement (跨案，由 `ui-polish-and-safeguards` 建立) 涵蓋；`sheet-dismissal-safeguard` 的 Purpose 明文排除篩選 sheet，本案故不延伸該 spec 承接同一行為 (原任務曾誤延伸，回歸了批 1 `spec-contradiction-cleanup` 已消除的矛盾與重複涵蓋，QA 修正輪已撤掉該延伸)。`order-filter-sheet` 規格差異改為指向此既有 requirement。驗證：`sheet-dismissal-safeguard/spec.md` 未被本案觸及、其 Purpose 與現況一致無矛盾；任務 6.1 的七條測試即為 irreversible-action-safeguard 該 requirement 新增情境 (篩選 sheet) 的機器守門，全綠即滿足

## 8. 建置與人工驗收

- [x] 8.1 先 `cd apps/ios && agvtool next-version -all` 遞增 build number，再以 xcodebuildmcp 序列跑 iPhone 與 iPad simulator build (共用 build.db 不可並行)，接著跑主 scheme 全部單元測試 (跑 snapshot 前先把模擬器外觀鎖淺色)。驗證：兩平台 build 成功、主 scheme 測試全綠，且兩張訂單清單 compact 版面的 snapshot 未被重錄 (`git status --short` 下快照目錄無變更)
- [x] 8.2 人工驗收篩選 sheet 五條路徑：改選後按取消出現捨棄確認；選繼續編輯則保留原未套用選擇；選捨棄則關閉且清單篩選摘要未變；未改選按取消直接關閉；按套用後摘要更新為新篩選。驗證：於 iPhone 逐條實測通過
- [x] 8.3 切換 App 語言為英文，確認捨棄確認的標題、訊息與兩顆按鈕皆顯示英文。驗證：實測為英文，且 `Localizable.xcstrings` 在本次差異中無新增 key (若被 Xcode 建置寫入結構字串，提交前以 `git checkout` 還原該檔)
