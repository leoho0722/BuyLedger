# input-focus-selection 驗證紀錄

裝置依使用者 2026-11-04 決定只用模擬器：iPhone 17 iOS 26.5 與 iPad Air 11-inch (M4) iOS 27.0。本 change 未在實機驗證；2026-10-28 的問題是在實機發現的，模擬器與實機行為可能不同。

## 1.1 基準量測 (現行程式碼)

環境確認：`KeyboardDismissTests` 在兩台模擬器各 2 條，1 通過 1 失敗。失敗的是已知的 `testTapNumericKeyboardDone_數字鍵盤顯示中_收起鍵盤`：輸入 123 得到 1230 (多一位數)，訊息不是「數字鍵盤未能換成完整鍵盤」，軟體鍵盤正常呈現。

量測以量完即刪的暫時 XCUITest 進行，先點欄位左側再 `typeText`。結果以欄位 `value` 為準。

### 點欄位左側後輸入的落點

| 欄位 | 既有內容 | 輸入 | iPhone 17 | iPad Air |
| --- | --- | --- | --- | --- |
| 實付金額 | 0 | 1000 | 10000 | 10000 |
| 訂單刷卡手續費 | 0.00 | 5 | 50.00 | 50.00 |
| 品項單價 | 0 | 95 | 950 | 950 |
| 報價本金 | 0 | 1000 | 10000 | 10000 |
| 報價本金 (第二次聚焦) | 10000 | 5 | 510000 | 510000 |
| 匯率金額 | 150000 | 5 | 5150000 | 5150000 |
| 每月目標 | 80000 | 1 | 800001 | 800001 |
| 客戶名稱 (既有訂單) | 林書宇 | 小姐 | 林小姐書宇 | 林小姐書宇 |
| 訂單備註 (點第一行) | 第一行、第二行 | X | X 接在第一行最前面 | X 接在第一行最前面 |

游標落在點擊處，所以金額多出位數、文字插在中間。每月目標與客戶名稱點在文字上，游標依字詞邊界落點；每月目標點在整串數字上時落在尾端，其餘數字欄點在文字左側空白，落在開頭。

### 報價本金打字當下是否更新相依結果

會更新。鍵盤還開著時輸入後，建議售價已從 $0 變成 $230 (當時欄位值是多一位數的 10000)，收鍵盤後不變。兩台相同。

### 結束編輯後的顯示

| 情境 | 輸入中 | 結束編輯 | 備註 |
| --- | --- | --- | --- |
| 訂單百分比輸入 12.345 | 12.345 (iPad 因選取未生效為 12.3450.00) | 12.35 | 兩台結束編輯後相同 |
| 報價本金輸入 22.888 | 22.888 (iPhone 因游標在 0 之前為 22.8880) | 22.89 | 兩台結束編輯後相同 |
| 每月目標 80000 逐字刪到空 | 空白，顯示提示文字 | 8 | 重新推入設定頁仍是 8，兩台相同 |
| 無卡折抵超過實付金額 (實付 10000) | 顯示打的字 (iPhone 輸入 20000 顯示 20000；iPad 輸入 5000 且游標在 0 之前，顯示 50000) | 10000 | 上限在寫回時生效，輸入中不改畫面 |

每月目標的現行結果與規格的新行為不同，這是預期的改動：現行逐字刪除時 8 已寫回，空字串解析失敗所以停在 8。規格要求沒有輸入就離開時保留 80000，輸入後全部刪掉時還原聚焦當下的值。其餘量測與規格範例表相符，不需暫停。

### 地區使用逗號小數點 (`-AppleLocale de_DE`，報價本金)

| 輸入 | 輸入中 | 結束編輯 | 建議售價 |
| --- | --- | --- | --- |
| 22,8 | 22,80 | 22,8 | $10 |
| 22.8 | 22.80 | 22 | $10 |

兩台相同；輸入中多出的 0 是游標落在原本的 0 之前造成的。iPhone 數字鍵盤的小數鍵是逗號。App 內語言維持正體中文，解析與顯示仍跟著系統地區。

### 搜尋欄聚焦時的落點

先輸入文字、收起鍵盤，再點第一個字的位置後輸入。

| 欄位 | 既有內容 | 輸入 | iPhone 17 | iPad Air |
| --- | --- | --- | --- | --- |
| 類別搜尋 (iPhone 篩選 sheet、iPad 類別選擇器) | 保養 | 品 | 品保養 | 品保養 |
| 訂單清單搜尋 | 林書宇 | 小 | 小林書宇 | 小林書宇 |
| 合併候選搜尋 | 林書宇 | 小 | 小林書宇 | 小林書宇 |
| 選項選擇器搜尋 (預設幣別) | 新台 | 幣 | 幣新台 | 幣新台 |

### 結論

- **搜尋欄依基準量測決定是否修改**：四種搜尋欄都不會把游標放到尾端，全部要改。類別搜尋改用 `BLTextField`，三處 `.searchable` 加 `BLSearchFieldCaretModifier`。
- **`BLNumberField` 結束編輯後的顯示**：一律依格式重新顯示目前的綁定值，涵蓋捨入與上限，輸入中顯示使用者打的字。
- **`BLNumberField` 不套用 `@Environment(\.locale)`**：現行解析與顯示跟著系統地區，不跟 App 內語言，元件直接使用呼叫端傳入的格式。

### 寫 UI 測試時要注意

- iPad 新訂單表單收起客戶欄鍵盤後，欄位可能捲到導覽列底下而點不到，要驗證既有文字時改開既有訂單的編輯表單 (seed `minimalOrders` 的 `UITEST-MIN-001`，客戶是林書宇)。
- 新訂單表單開啟時客戶欄已聚焦，鍵盤會蓋住下方欄位，要先收鍵盤。
- iPad 數字欄的鍵盤呈現不固定，訂單表單可能是完整鍵盤或數字 Popover，報價、匯率、每月目標是數字 Popover，`typeText` 都能輸入。

## 1.3 `BLNumberFieldDraft` 單元測試

`BLNumberFieldDraftTests` 在 iPhone 17 iOS 26.5 模擬器 20 條通過。測試與實作同時交回，沒有先失敗的紀錄，改以變異驗證：同時拿掉 `recordWrittenValue` 記錄讀回值、全部刪除時的還原、聚焦清空、失焦重新格式化，8 條失敗 (含上限、還原、重建後失焦)。單獨拿掉聚焦清空時，`setFocused_不同既有金額_清空草稿且不要求寫回` 失敗；這條原本先送空字串才讀文字，守不住清空，已改為先讀文字。

主對話的選擇：

- 聚焦中外部改值時，草稿重設成格式化文字，之後輸入接在該文字後面，不再清空：規格只要求外部改值取代欄位文字，再清空會讓使用者看不到剛套用的值。
- 這輪寫回過又遇到外部改值，全部刪除時仍還原聚焦當下的值，依規格字面。

## 1.4 垂直切片 (實付金額與客戶名稱)

遷移前後都跑 `OrderEditInputFocusUITests` 五條，兩台模擬器結果相同。

遷移前 4 條失敗、1 條略過：

- `testFocusChargedAmountFromLeft_零值輸入_即時取代且失焦保留`：輸入 1000 得到 10000
- `testFocusCustomerFromLeft_既有名稱接續輸入_新增文字接在尾端`：得到「林小姐書宇」，預期「林書宇小姐」
- `testFocusChargedAmountFromLeft_未輸入即失焦_還原原值且直接取消`：聚焦中仍顯示 4200，預期空字串
- `testFocusChargedAmountFromLeft_輸入後全部刪除_還原原值且直接取消`：輸入 1 得到 14200，預期 1
- 注音測試略過：第三聲鍵的標籤是「三聲、」，不是原本寫的 ˇ。修正後實際執行

遷移後 5 條全部通過，略過 0 條，注音組字得到「林書宇小」。游標設定不被點擊落點覆蓋，不需要排到下一輪主執行緒；組字沒有被打斷。

回歸：`KeyboardDismissTests`、`OrderCreateTests`、`OrderEditDirtyTests` 共 11 條，iPhone 全部通過，先前已知的多一位數失敗不再出現。iPad 10 條通過，`OrderCreateTests/testTapSave_填寫必填與實付金額_清單出現新訂單` 超過 10 分鐘執行上限，逾時前沒有斷言失敗，單獨重跑 160 秒通過；這次的 CLI log 沒有「App animations complete」訊息，所以無法確認是已知的 iPad 閒置等待。

遷移 `OrderEditDecimalField` 本身就涵蓋實付金額、無卡折抵與補款、成本區共 7 個呼叫點；無卡折抵的上限由 2.1 的 UI 測試驗證。

範圍說明：`Support/XCUIElement+FocusTap.swift` 不在提案清單內，主對話選定新增，因為 `Tests/Forms/` 的五個測試檔都要用，而 `XCUIElement+TextInput.swift` 屬於 3.1。兩欄的遷移改動很小，由主對話直接修改，其餘由 `codex-impl` 實作，`claude-impl` 審查。

## 2.1、2.2 換元件前 (舊欄位上的測試結果)

新測試先掛在舊欄位上跑，只掛 identifier，不換元件。

因行為錯誤而失敗，兩台相同：

- 訂單費率只聚焦不輸入：聚焦中是 `0.00`，預期空字串
- 訂單費率 `0.00` 輸入 5：得到 `50.00`，預期 `5`
- 品項單價 2800 輸入 95：得到 `952800`，預期 `95`
- 多行備註點第一行輸入 X：得到 `X第一行\n第二行`，預期 `第一行\n第二行X`
- 報價本金 0 輸入 1000：得到 `10000`，預期 `1000`
- 報價費率 `0.0` 輸入 5：得到 `50.0`，預期 `5`

報價的其餘案例停在前置，沒有走到後續斷言：iPhone 上本金 2500 得到 `25000`、運費 30 得到 `300`；iPad 的 `既有本金重新輸入` 同樣得到 `25000`，另外兩條在「完成鍵未能收起鍵盤」失敗 (七欄共用同一個 Bool 焦點的舊實作，換成逐欄焦點後要重驗)。這三條的斷言要到換元件後才算第一次執行。

舊欄位上已通過，不算失敗證據，換元件後要用變異驗證確認會擋錯：訂單費率小數、報價本金小數、訂單費率與客戶欄的再次點左側，以及已遷移的無卡折抵上限。

測試本身的修正 (主對話)：

- 客戶欄再次點左側改點 `dx: 0.01`：`dx: 0.04` 時結果不含連續的「林書宇」，新字落在原文中間，規格的「contains 林書宇」成立不了
- 表單捲動改用左緣起拖的短距離拖曳 `revealFormElementGently`：`swipeUp` 帶慣性，iPad 表單會把欄位衝到導覽列底下；拖曳起點落在輸入欄上時表單不會捲動
- 費率再次點左側前先把欄位拖到表單上半部：iPhone 聚焦後系統把欄位捲到 y=578，鍵盤上緣在 583，欄位不可點
- 費率再次點左側在數字 Popover 呈現時略過：關閉區域蓋住全螢幕，使用者無法在 Popover 開著時再點同一欄。這個情境由 iPhone 與 `BLNumberFieldDraft` 的重複聚焦單元測試涵蓋
- 無卡折抵上限改用既有訂單 `UITEST-MIN-001`：新訂單從選擇器返回會重新觸發 `.task`，客戶欄再度取得焦點

範圍外的現象，未修改，要告知使用者：

- iPhone 新訂單從付款方式選擇器返回時，客戶欄會重新取得焦點 (`OrderEditOperations` 的 `.task` 分支在 `focusedField` 為空時設定)
- iPhone 表單下半的費率欄聚焦後，系統把欄位停在鍵盤上緣之下，輸入中的數字被鍵盤蓋住


## 2.2 iPad 報價頁「完成鍵未能收起鍵盤」調查

只在 iPad Air 11-inch (M4) iOS 27.0 模擬器發生，iPhone 未發生，未在實機驗證。換元件前後都出現，每輪失敗的測試不同；單獨跑同一條可能通過。

在 `QuoteView` 與 `dismissNumericKeyboard` 暫時加紀錄後 (已移除)，同一輪的結果：

| 點完成鍵當下的呈現方式 | 次數 | 按鈕動作是否執行 | 點擊後 |
| --- | --- | --- | --- |
| 完整鍵盤 | 5 | 報價頁 4 次都執行，另 1 次在其他畫面，動作未記錄 | 鍵盤收起 |
| 浮動數字面板 (XCUI 回報可點) | 3 | 都沒有執行 | 換成完整鍵盤，helper 因此報失敗 |

結論：焦點鏈正常，按鈕動作執行時 `focusedField` 在 50ms 內清空；浮動面板呈現時 XCUI 仍回報完成鍵可點，但點擊到不了按鈕。真實手指是否同樣受影響未驗證。

主對話試過兩次修改 `dismissNumericKeyboard`，都未解決，已還原：

1. 假設「等待中才換成完整鍵盤，完成鍵還沒點過」：紀錄顯示失敗時點擊已送出，假設不成立
2. 假設「點擊被 Popover 關閉區域攔下」，Popover 呈現時不點：失敗的呈現方式實際是浮動面板，假設不成立

另有一次讀到「完整鍵盤」後 30ms 就判定為 Popover，單次讀取的呈現方式可能還在轉換中。

第三次修改由使用者 2026-11-05 選定 (改共用 helper，不只改新測試)：呈現方式連續取樣都是完整鍵盤才點完成鍵；浮動面板與 Popover 先在本欄位點兩下換成完整鍵盤；完整鍵盤點過仍收不掉才失敗。`.claude/rules/ios-ui-tests.md` 同步改寫。修改後 iPad 的 `QuoteInputFocusUITests`、`QuoteTests`、`KeyboardDismissTests` 連跑兩輪，每輪 12 條全部通過 (修改前同組每輪都有這項失敗，最後一輪 3 條)。

順帶確認：報價空欄的 `value` 會讀到提示文字 `0`，聚焦中的斷言已收緊為 `"0"`。

## 2.1、2.2 換元件後

變異驗證 (iPhone，暫時弄壞元件，確認後還原並比對雜湊)：

| 暫時的破壞 | 測試 | 失敗內容 |
| --- | --- | --- |
| 失焦不重新格式化 | `testFocusCardFeeRate_小數輸入_收鍵盤後依格式捨入` | `12.345`，預期 `12.35` |
| 失焦不重新格式化 | `testFocusCardlessDeduction_超過實付金額_收鍵盤後顯示上限` | `5000`，預期 `1000` |
| 再次點擊就清空草稿 | `testFocusCardFeeRate_再次點左側_保留已輸入文字` | 已輸入的 12 被清掉 |
| 聚焦中游標一律在尾端 | `testFocusCustomerFromLeft_再次點左側_游標由系統決定且不落在尾端` | `林書宇小` |
| 報價欄位不接受小數 | `testFocusFieldFromLeft_本金輸入小數_失焦後保留小數值` | `23`，預期 `22.8` |

iPhone：`OrderEditInputFocusUITests`、`QuoteInputFocusUITests`、`OrderCreateTests`、`KeyboardDismissTests`、`OrderEditDirtyTests`、`QuoteTests` 與 `testDraftSurvivesRotation_新增訂單草稿已輸入_同欄且單一sheet` 共 35 條全部通過，略過 0 條。

iPad：`QuoteInputFocusUITests`、`QuoteTests`、`KeyboardDismissTests` 連跑兩輪各 12 條通過。`OrderEditInputFocusUITests`、`OrderCreateTests`、`OrderEditDirtyTests` 與同一條草稿案例共 23 條，20 條通過、1 條略過 (費率再次點左側，Popover 呈現)、2 條超過 10 分鐘上限且逾時前沒有斷言失敗，依規則單獨重跑。`testFocusCardFeeRate_未輸入即失焦_還原原值` 單獨重跑通過。

`testFocusChargedAmountFromLeft_零值輸入_即時取代且失焦保留` (1.4 的案例，當時兩台通過) 在這批與兩次單獨重跑都超過 10 分鐘上限，依規則不再重跑，由 3.3 的完整回歸重驗。最後一次重跑的步驟紀錄：收起客戶欄鍵盤後，每個 XCUI 動作前後各等滿約 60 秒閒置 (`Wait for com.leoho.BuyLedger to idle`)；輸入 `1000`、換成完整鍵盤與點完成鍵都已執行，點完成鍵後在等閒置時達到上限，全程沒有斷言失敗。

單元與 snapshot (iPhone 17 iOS 26.5 淺色)：`QuoteFeatureTests`、`SnapshotToolsTests` 通過。`SnapshotOrderEditSectionsTests` 有 1 條差異：`orderEditItemsSection_最大輔助字級_商品列堆疊排列` 的品項名稱換行時，下方內容往下移 2 像素 (約 0.67 pt)，文字、顏色與排列不變。原因是 `BLTextField` 使用 `TextField` 的 `selection:` 參數，暫時拿掉後 12 條全部通過；游標放尾端必須靠這個參數。使用者 2026-11-05 決定重錄這一張，重錄後 12 條通過。

## 2.3、2.4 換元件前 (舊欄位上的測試結果)

新測試先掛在舊欄位上跑，兩台模擬器各 10 條，9 條因行為錯誤失敗，失敗的測試兩台相同：

- 匯率金額 150000 輸入 5：得到 `5150000`，預期 `5`
- 匯率金額只聚焦：聚焦中是 `150000`，預期提示文字 `輸入金額`
- 每月目標 80000 輸入 1：iPhone 得到 `180000`、iPad 得到 `800001`，預期 `1`
- 每月目標只聚焦：聚焦中是 `80000`，預期提示文字 `目標金額`
- 每月目標輸入 1 再刪除：`80000`，預期空欄的提示文字 `目標金額`
- 開團名稱：`四新月韓國團`，預期 `四月韓國團新`
- 開團備註：`X第一行\n第二行`，預期 `第一行\n第二行X`
- 主檔名稱：`類服飾`，預期 `服飾類`
- 付款方式名稱：`新信用卡`，預期 `信用卡新`

`testTapPresetAmount_未聚焦時點按鈕_金額欄顯示該金額` 在舊欄位上通過，不算失敗證據，換元件後要用變異驗證確認會擋錯。

## 2.3、2.4 換元件後

變異驗證 (iPhone)：拿掉 `BLNumberField` 的外部改值同步後，`testTapPresetAmount_未聚焦時點按鈕_金額欄顯示該金額` 失敗 (`150000`，預期 `50000`)，還原後比對雜湊相同。

`ToolsInputFocusUITests`、`EditorTextInputFocusUITests`、`FxTests`、`SettingsGoalInputTests`、`CampaignCrudTests`、`LookupManagementTests`、`OrderEditAddOptionTests` 共 33 條，兩台模擬器全部通過，略過 0 條。iPad 這輪前先重開模擬器。

`SnapshotToolsTests`、`SnapshotMoreTests`、`SnapshotLookupsTests`、`SnapshotCampaignDetailTests`、`SnapshotSharedTests` 共 24 條在 iPhone 17 iOS 26.5 淺色模式通過，沒有差異。

交叉審查：`codex-impl` 審 2.3 沒有問題；`claude-impl` 審 2.4 沒有功能問題，採納修正兩處誤導的測試說明，`revealField` 簽章取不到時多拖幾次、兩個收鍵盤方法重複這兩項不影響結果，未修改。審查前後雜湊相同。

主對話修改的測試：每月目標全部刪除後的預期值改為提示文字 `目標金額`；並排版面的設定頁沒有返回鍵，只在收合版面點返回；開團備註欄改用 `descendants(.any)` 定位。

## 2.5 換元件前 (舊欄位上的測試結果)

兩台模擬器各 4 條全部因行為錯誤失敗：

- 類別搜尋：`品保養`，預期 `保養品`
- 訂單清單搜尋：`書林`，預期 `林書`
- 合併候選搜尋：iPhone `小林書宇`、iPad `林書小宇`，預期 `林書宇小`
- 選項選擇器搜尋：`幣新台`，預期 `新台幣`

類別搜尋第一次以 `dx: 0.12` 點擊時在舊欄位上通過：放大鏡在輸入欄外，文字從輸入欄左緣開始，這個位置已經在文字右邊，守不住規格。主對話改為 `dx: 0.02` 後才失敗。`.searchable` 的放大鏡在欄位內，維持 `dx: 0.12`。

## 2.5 換元件後

`codex-impl` 的審查指出兩項，都已處理：`TextSelection.Indices` 的 switch 少了未知分支，實際建置也編不過；跨字串比較索引不能證明外部改值後選取仍有效。

第一版 `BLSearchFieldCaretModifier` 掛在 `.searchable` 之後，iPhone 上訂單清單通過，合併候選與選項選擇器仍失敗 (`小林書宇`、`幣新台`)。暫時加紀錄比較：訂單清單設定選取後系統會回寫尾端位置，另外兩個完全沒有回寫。第一次修改把設定排到下一輪主執行緒，紀錄顯示有執行但仍沒有回寫，已還原。第二次修改把 `.searchable` 移進 modifier，並沿用 `BLTextField` 的文字與選取追蹤，新測試 5 條在 iPhone 全部通過。暫時紀錄已移除。

新增 `testFocusOrderListSearchFromLeft_深連結取代既有文字_接續在新文字尾端` 驗證客戶深連結改掉搜尋文字後的落點。

snapshot 有 1 條差異，不是這次改動造成：`orderFilterSheet_搜尋無符合類別_符合基準圖` 有 231 個像素不同 (佔 0.0077%，每個色頻最多差 3)，全在工具列關閉鈕的 X 圖示範圍內，搜尋列沒有差異。暫時把類別搜尋還原成原生 `TextField` 後，這條同樣失敗。未重錄。

主對話在第二版 struct 加上 `@MainActor`：`ViewModifier` 的遵循寫在 extension，型別不會推斷成 MainActor，`Binding` 的 closure 有 4 個 Sendable 警告，修正後警告為 0。`codex-impl` 當時審查的是第一版。

### 基準圖

使用者同意重錄 `orderFilterSheet_搜尋無符合類別_符合基準圖` 後，主對話換上當時失敗的實際圖，重跑仍失敗：這次的實際圖與 HEAD 基準沒有差異，與換上去的圖差 231 個像素，範圍同樣在關閉鈕的 X 圖示。同一張圖有兩種渲染，原因未查明。重錄解決不了，主對話把基準還原成 HEAD，這張不在本次 diff 內，之後可能再度間歇失敗。

### 修正後結果

Snapshot (iPhone 17 iOS 26.5 淺色)：`SnapshotOrdersBaselineTests`、`SnapshotOrderFilterEmptyStatesTests`、`SnapshotOrderMergeTests` 共 10 條通過，沒有差異。

UI 測試 7 組：`SearchInputFocusUITests`、`OrderFilterSheetTests`、`OrderCategoryPickerTests`、`OrdersListTests`、`OrderRegularSearchBarTests`、`OrderMergeTests`、`CurrencyPickerTests`，各 56 條：

- iPhone 17 iOS 26.5：47 過、9 略過、0 失敗
- iPad Air 11-inch (M4) iOS 27.0：37 過、14 略過、5 失敗，5 條都是 `SearchInputFocusUITests`，錯誤為未取得鍵盤焦點

略過的都是版面專屬案例。

iPad 的 5 條失敗是模擬器環境造成：搜尋欄已取得鍵盤焦點，但 `Keyboard` 高度為 0，畫面沒有軟體鍵盤。`KeyboardDismissTests.testTapNumericKeyboardDone_數字鍵盤顯示中_收起鍵盤` 同時失敗，`Keyboard` 只剩高 64 的工具列。同一台的 Safari 網址列聚焦後也沒有軟體鍵盤，所以與 App 無關。使用者第一次在 Device Hub 取消勾選 Simulate Hardware Keyboard 後症狀不變，依主對話提供的步驟再操作一次後軟體鍵盤出現，生效的是哪一步未確認。

鍵盤恢復後，iPad 的 `KeyboardDismissTests` 與 `SearchInputFocusUITests` 共 7 條全部通過。其餘 6 組的 37 條是在硬體鍵盤狀態下通過，由 3.1 的 `Tests/Forms/` 與 3.3 的完整回歸在正常鍵盤狀態重驗。

這輪測試用的 test products 建置後沒有再修改 Swift 原始碼。

### 搜尋欄範圍

沒有未修改的搜尋欄：`.searchable` 只剩 `BLSearchFieldCaretModifier` 內一處，由訂單清單 (compact、regular)、合併候選與 `BLSearchableModifier` 四個入口套用；類別搜尋是一般輸入欄，改用 `BLTextField`。

### 測試環境

這輪測試期間，Xcode 預設的 DerivedData 所在外接碟沒有回應，`xcodebuild` 停在開測前建立紀錄目錄。測試指令以單次參數 `-IDECustomDerivedDataLocation` 改用內建磁碟，未修改 Xcode 設定。

### 第二版交叉審查

`codex-impl` 唯讀複查第二版的 modifier、四個入口與 `SearchInputFocusUITests`，沒有需要修正的問題，審查前後雜湊相同。它指出的界線：搜尋欄逐鍵注音組字與連續刪除沒有專門的實測，深連結案例驗證的是離開舊搜尋後替換再聚焦，不是聚焦中替換。

## 3.1 UI 測試輸入 helper

`codex-impl` 實作，`claude-impl` 唯讀審查，主對話同步審查。`moveCursorToTextEnd` 與換鍵盤步驟已移除，`typeInField` 只在欄位未聚焦時點擊。

`claude-impl` 提出 5 項，都是讀碼判斷，取捨由主對話決定：

- 已聚焦判斷只讀一次，過渡期可能多點一次，把游標移到中間：先不改，看 UI 結果。兩台回歸都沒有游標插到中間的失敗，維持不改。
- 文字欄刪除結果沒有驗證：不改，殘留文字會由後面的值斷言抓到。
- 數字欄讀到的既有文字可能早於 App 清空：不改，刪除鍵在空欄位是空操作。
- alert 內的原生輸入欄不在 App 的聚焦保證內：不改，每次開啟前草稿都已清空。
- 驗證聚焦落點的測試與「不用點欄位再 `typeText`」的規則相反：採納，主對話在 `ios-ui-tests.md` 補上例外。

主對話依 2.5 的 iPad 鍵盤調查改寫 `ios-ui-tests.md` 的硬體鍵盤條目，並補上連續執行後先重開模擬器。

結果 (`QuoteTests`、`OrderCreateTests`、`KeyboardDismissTests`、`CampaignCrudTests`、`AdaptiveNavigationContinuityUITests`、`CampaignFlowTests` 與 `Tests/Forms/` 的 5 組，共 76 條)：

- iPhone 17 iOS 26.5：66 過、10 略過、0 失敗。
- iPad Air 11-inch (M4) iOS 27.0：70 過、5 略過、1 失敗。失敗的 `testFocusCardFeeRate_未輸入即失焦_還原原值` 超過 10 分鐘執行上限，逾時前沒有斷言失敗。整輪約 1 小時 54 分，多條測試碰到閒置等待。
- 重開 iPad 模擬器後，`KeyboardDismissTests` 2 條通過，單獨重跑 `OrderEditInputFocusUITests` 13 條全部通過，約 12 分鐘。
- `testTapNumericKeyboardDone_數字鍵盤顯示中_收起鍵盤` 與 `QuoteTests` 4 條在兩台都通過，不再多一位數。

略過都是版面或呈現方式專屬的案例：iPhone 沒有並排、regular 根導覽與側邊欄；iPad 無法建立收合版面。`testFocusCardFeeRate_再次點左側_保留已輸入文字` 在數字 Popover 呈現時略過，因為 Popover 的關閉區域會吃掉對欄位的點擊，同一條在重跑時通過。

多條碰數字欄的測試有 `Invalid frame dimension (negative or non-finite)` 執行期警告，改動前的基準量測就有，不是這次造成，未處理。

## 3.2 輸入欄掃描測試與規則

`claude-impl` 實作，`codex-impl` 唯讀審查，主對話同步審查。

`codex-impl` 指出兩項，都由主對話修改：

- 掃描樣式要求 `TextField` 後緊接左括號，`TextField<Text>(`、`TextField (` 這類有效宣告會漏判，改成比對完整識別字。
- `ios-design-system.md` 把所有搜尋欄都排除於 `BLTextField`，與類別搜尋的做法衝突，限縮到 `.searchable`。

主對話另把 `ios-navigation.md` 插在別條子項中間的條目移到正確位置。

結果 (iPhone 17 iOS 26.5 模擬器，`InputFieldConventionScanTests`)：

- 修改前的樣式：2 條通過；加入違規的 `TextField("probe", text:)` 時 1 過 1 敗，訊息列出探針的檔案與行號。
- 修改後的樣式：`textFieldOccurrences_允許清單檔案_至少掃到一處`、`textFieldOccurrences_正式原始碼_僅允許清單檔案宣告` 通過；同時加入 `TextField<Text>(` 與 `TextField (` 時後者失敗，訊息列出探針的兩行。探針已移除。

## 3.5 `QuoteFeatureTests` 改用 `TestStore`

使用者 2026-11-05 指示 Given 的 `Store` 要用 `TestStore` 建立，並指出測試本就應使用 `TestStore`。主對話把 4 條綁定測試改用 `TestStore` 與 `store.send(\.binding.…)`，移除只為 `@Bindable` 加入的 `import SwiftUI`，`.claude/rules/ios-unit-tests.md` 改為 Feature 測試一律用 `TestStore`。

snapshot 測試保留 `Store` 是主對話提出的例外：畫面只接受 `Store`。主對話原本建議規則只限縮到巢狀欄位，使用者否決。

報價頁綁定的 `focusedField`、`itemPrice` 都是頂層欄位，畫面送出的 action 與 `store.send(\.binding.…)` 相同，守門範圍沒有縮小。

結果 (iPhone 17 iOS 26.5 模擬器)：`QuoteFeatureTests` 40 條全部通過。

其他 Feature 測試檔的 `Store` (當日搜尋計數 16 個檔 30 處) 不在本 change，使用者決定收尾後另開 change。

## 3.4 搜尋入口合併

`claude-impl` 實作，`codex-impl` 唯讀審查，主對話同步審查。使用者 2026-11-05 核定整體方案。名稱、`.blSearchable` 與三個 API 一起掃描由 Codex 提出；條件留在 `OptionPickerSheet`、這次不抽選取共用型別由主對話提出。2.5 以前的紀錄保留當時的 `BLSearchFieldCaretModifier` 與舊 `BLSearchableModifier`，兩者已合併為 `Foundations/ViewModifiers/BLSearchableModifier.swift`，入口是 `.blSearchable(text:prompt:)`。

主對話以 index 裡的舊檔比對新檔：差異只有檔頭、型別說明、型別名與新增入口，文字與選取追蹤邏輯未改。`codex-impl` 只讀碼，Critical 0、Warning 0、Suggestion 0，審查前後檔案雜湊相同。

結果：

- 合併前的舊實作：`InputFieldConventionScanTests` 新增的 2 條如預期失敗，指出 `BLSearchFieldCaretModifier.swift` 第 57、62、63 行。
- 合併後 (iPhone 17 iOS 26.5 模擬器)：同一類別 4 條全部通過。
- 暫時加入 `.searchFocused(` 與隱含 self 的 `searchable(` 探針：3 過 1 敗，`searchAPIOccurrences_正式原始碼_僅共用搜尋入口使用` 列出探針的兩行。探針已移除。
- 暫時把 `OptionPickerSheet` 的條件改成一律套用：`SearchInputFocusUITests` 6 條中只有 `testOpenSourcePicker_訂單來源選擇器_不呈現搜尋欄` 失敗，訊息是「訂單來源選擇器不應呈現搜尋欄」。條件已還原。
- `KeyboardDismissTests`、`SearchInputFocusUITests`、`OrderFilterSheetTests`、`OrderCategoryPickerTests`、`OrdersListTests`、`OrderRegularSearchBarTests`、`OrderMergeTests`、`CurrencyPickerTests`、`AdaptiveNavigationContinuityUITests` 共 76 條：iPhone 17 iOS 26.5 58 過、18 略過、0 失敗；iPad Air 11-inch (M4) iOS 27.0 60 過、16 略過、0 失敗。
- `SnapshotOrdersBaselineTests`、`SnapshotOrderFilterEmptyStatesTests`、`SnapshotOrderMergeTests` 共 10 條全部通過，沒有差異。

略過都是版面專屬的案例：iPhone 沒有 regular 根導覽、並排清單與類別選擇器；iPad 沒有篩選 sheet、窄版清單與收合版面。

`OptionPickerSheet` 的條件在搜尋 modifier 外面，`isSearchEnabled` 在各呼叫點是固定值，切換條件時的畫面識別不在這次承諾內。

## 3.6 無卡折抵保留使用者設定的值

`codex-impl` 實作，審查設計的 Codex 終端唯讀審查，主對話同步審查。

保留使用者設定值、由它推導有效折抵的方向由主對話提出，實作前經 Codex 兩輪唯讀設計審查：

- 第一輪指出主對話原本的提示判斷 (設定值大於有效折抵才提示) 在直接輸入超額折抵時會失去說明，違反既有「修正要說明原因」的要求；改為提示獨立記錄，折抵欄依輸入是否超過上限、實付欄依設定值是否被壓低決定。
- 第二輪指出撤回折抵編輯所需的還原事件與焦點快照有兩階段寫入的缺口。使用者 2026-11-06 選擇「動過折抵欄即確認」：折抵欄的任何寫入 (含刪空時寫回的聚焦值) 都成為新的設定值，不新增還原事件與焦點快照，`BLNumberField` 不改。

實作審查：Critical 0、Warning 1、Suggestion 1，都由主對話修改。

- `saveAndReopenOrderEdit` 只等表單關閉就重開，儲存回應未到時新表單會用舊資料建立：改為先等詳情的營收數字變成這次預期的值再重開。
- 新規則容易被讀成所有跨欄位限制都要保留來源值：`ios-navigation.md` 的條目改為「數字欄逐字寫回，跨欄位限制若須隨輸入恢復，reducer 要保留使用者設定的來源值」，並註明一次性的正規化與使用者明確確認的修改不在此限。

主對話另發現既有測試 `binding_實收金額降到折抵以下_折抵夾到新上限` 直接改草稿，設定值仍是 0，與畫面的實際狀態不一致，改用 `makeState(chargedAmount: 1_000, deduction: 800)` 建立前置。

style 閘門後 `codex-impl` 把新增測試移回 struct 本體並合併為 13 個測試方法 (參數化共 23 組輸入)，兩個只呼叫一次的 helper 內聯回 `applyBinding`，UI helper 的前置斷言改為 `guard` 加診斷。

新測試引用新增的 State 欄位，兩個 production 檔還原成 HEAD 會無法編譯，因此改以暫時把 `applyBinding` 的兩個分支換回 HEAD 的夾限寫法 (欄位保留) 確認測試會失敗，確認後還原：

- 只換實付分支：`OrderEditFeatureDeductionTests` 19 條中 2 條失敗，`binding_受限時切換付款方式後還原實付_恢復原折抵且表單未修改` 與 `binding_受限實付提高或還原_恢復設定折抵並清除提示(testCase:)`，有效折抵停在中途的低值。
- 兩個分支都換：5 條失敗，另加 `binding_折抵輸入超額_確認上限內設定並顯示提示` (設定值 0，預期 1000)、`binding_受限折抵輸入或還原寫回_確認當次寫入值(testCase:)` (1000，預期 1)、`binding_超額折抵後輸入合法值_更新設定並清除提示` (1000，預期 300)。其餘新測試守的是單步夾限、已確認值不回升與其他欄位不影響折抵，舊寫法下也成立。
- 兩個分支都換時的 UI (iPhone 17 iOS 26.5)：`OrderEditInputFocusUITests` 15 條中 2 條新案例失敗，`testFocusChargedAmountFromLeft_已有折抵時提高實付_存檔重開保留折抵` 訊息為「儲存後詳情收款金額未更新為 4000」，`testFocusChargedAmountFromLeft_已有折抵時輸入再刪空_還原折抵且直接取消` 的折抵為 1，預期 1000。

修改後的結果：

- iPhone 17 iOS 26.5 淺色模式的整個 `BuyLedgerTests` (單元、守門與全部 snapshot)：2007 條，2004 過、3 預期失敗、0 失敗。
- 兩條新 UI 案例在兩台模擬器的完整 UI 回歸中都通過 (見 3.3)。

## 3.3 最終驗證

### 審查

- 最終交叉審查由審查設計的 Codex 終端唯讀進行：Critical 0、Warning 1。刪空只還原實付，不還原同一輪輸入壓低的無卡折抵，非零折抵訂單「取消直接關閉」不成立，因此新增 3.6。
- style 閘門交給未參與實作的 `haiku-max-implementer`，分組逐檔逐條審查，共三輪。修正由 `claude-impl` 與 `codex-impl` 依閘門原文處理，主對話審查修正結果，每輪交回後再由閘門核對。
- 第一輪修正把訂單清單的日期分組移進 `OrderListFeature.State`，`OrderListSnapshotSourceScanTests` 因此失敗：原寫法呼叫的是純計算型別，本來就合規，主對話裁定是誤判並還原。
- 第三輪的發現：應修 3 項、同檔既有 2 項、待裁定的 UI helper 前置斷言 1 項，主對話裁定擴大適用，全部修正。
- 閘門依「改到即整檔對齊」與「畫面計算移出 View」帶進的重構，行為不變：
  - 畫面組字搬進 State：`OrderEditFeature.State` 的 `itemQuantityDisplayText(_:locale:)`、`itemDetailsTitle(locale:)`、`orderDateTimestampText(locale:)`，由新檔 `OrderEditFeatureDisplayTextTests` 驗證；`OrderMergeFeature.State.candidateFilterNotice`，由 `OrderMergeFeatureTests` 兩條驗證。
  - 品項單價欄寬由固定 120 改為 `@ScaledMetric` (基準 120)，依 `ios-accessibility-localization.md` 的固定尺寸規則；預設字級寬度與 snapshot 不變，與 design「不改欄位外觀」的例外記在 design。
- 未採納的項目：
  - 使用者裁定：UI 測試名稱第一段維持使用者動作名；iPad 數字 Popover 下的 `XCTSkipIf` 維持；既有用 `Store` 的 Feature 測試另開 change 遷移。
  - 主對話裁定：`BLSearchableModifier` 的 modifier 順序與 `// MARK: - blSearchable` 沿用同目錄以函式名命名的寫法；`BLNumberFieldDraft.swift` 是 2026/11/6 拆出的新檔，檔頭日期維持；`- Parameter` 對無 label 關聯值的命名維持；`store.send(a, b) { ... }` 不要求括號內引數逐行；游標落點未定時的部分比對斷言保留。
  - `OrderEditFeatureDisplayTextTests` 的 `import ComposableArchitecture` 不移除：測試用到的 `UUID(0)` 需要它，缺少時編譯失敗。

### 指令

- 單元：`mobilebuildmcp simulator test --scheme BuyLedger --simulator-id <iPhone 17> --extra-args -only-testing:BuyLedgerTests --extra-args -parallel-testing-enabled --extra-args NO`，模擬器先設為淺色模式。
- UI：`mobilebuildmcp simulator test --scheme BuyLedgerUITests --simulator-id <裝置> --extra-args -only-testing:BuyLedgerUITests --extra-args -skip-testing:BuyLedgerUITests/LaunchPerformanceTests --extra-args -parallel-testing-enabled --extra-args NO`。iPad 那輪以 iPhone 那輪建好的測試產物 (`--test-products-path`) 執行，期間的註解修正不會混入。
- 兩輪都另加 `-IDECustomDerivedDataLocation` 指到內建磁碟。每台開跑前重開模擬器並先跑 `KeyboardDismissTests` 確認軟體鍵盤會呈現。

### 結果

- 單元、守門與全部 snapshot (iPhone 17 iOS 26.5，淺色)：2007 條，2004 過、3 預期失敗、0 失敗，snapshot 沒有差異。`NumericInputGroupingScanTests`、`InputFieldConventionScanTests`、`LayerBoundaryTests`、`LocalizationCatalogTests` 都在其中。
- `KeyboardDismissTests`：兩台各 2 條通過。
- iPhone 17 iOS 26.5 完整 UI 回歸：241 條，191 過、49 略過、1 預期失敗、0 失敗，約 1 小時 46 分。
- iPad Air 11-inch (M4) iOS 27.0 完整 UI 回歸：241 條，215 過、24 略過、1 預期失敗、1 失敗。
  - 失敗的是 `AdaptiveNavigationContinuityUITests.testOrdersLayoutCombination_訂單已選取_路徑保留且並排框線不重疊`，訊息為「無法辨識 Orders 前景欄位」，當下清單欄與詳情欄的框線重疊。
  - 重開模擬器後單獨重跑，1 條通過。3.4 的 iPad 回歸也通過同一條，判斷是版面轉換中途的取樣，不是本 change 造成。
- 預期失敗是 `testSelectTab_App鎖定時根分頁不可用_記錄診斷失敗`。
- 略過都是版面專屬的案例：iPhone 沒有並排、regular 根導覽與側邊欄；iPad 沒有收合版面、篩選 sheet 與窄版搜尋。
- 第三輪 style 修正在兩台回歸開始後才改，改的是註解、`OrderMergeFeature.State` 一個 private 屬性的位置，以及兩個 UI helper 的前置檢查。修正後重跑：
  - 整個 `BuyLedgerTests` 2007 條，2004 過、3 預期失敗、0 失敗。
  - `SearchInputFocusUITests` 與 `QuoteInputFocusUITests` 共 12 條，兩台都全部通過。

### 規格情境與測試

text-input-ergonomics：

| 情境 | 測試 |
| --- | --- |
| Typing appends to an existing name | `testFocusCustomerFromLeft_既有名稱接續輸入_新增文字接在尾端`；其他文字欄見 `EditorTextInputFocusUITests` 4 條 |
| A later tap leaves caret placement to the system | `testFocusCustomerFromLeft_再次點左側_原文保留且新字不在尾端` |
| Multi-line notes continue at the end | `testFocusNotesFromFirstLine_多行備註_新增文字接在尾端`、`testFocusCampaignNotesFromFirstLine_多行備註接續輸入_新增文字接在尾端` |
| Search query continues at the end | `testFocusCategorySearchFromLeft_既有保養輸入品_接續在尾端`；合併候選與選項選擇器各 1 條 |
| List search query continues at the end | `testFocusOrderListSearchFromLeft_既有林輸入書_接續在尾端`、`testFocusOrderListSearchFromLeft_深連結取代既有文字_接續在新文字尾端` |
| Phonetic composition is not interrupted | `testFocusCustomerFromLeft_逐鍵注音組字_保留原文並追加候選字` |
| Typing replaces a displayed zero | 三列依序為 `testFocusChargedAmountFromLeft_零值輸入_即時取代且失焦保留`、`testFocusCardFeeRate_零值輸入_即時取代`、`testFocusFieldFromLeft_零值刷卡費率輸入_取代原值並恢復一位小數` |
| Typing replaces an existing value | `testFocusFieldFromLeft_既有本金重新輸入_取代原值並更新售價` |
| Moving focus between quote fields also clears | `testFocusFieldFromLeft_本金直接換到運費_運費清空後輸入且本金不變` |
| Moving focus from another field also clears | `testFocusItemUnitPrice_從品項名稱直接點單價_輸入取代原值` |
| A later tap does not clear typed text | `testFocusCardFeeRate_再次點左側_保留已輸入文字`，數字 Popover 呈現時略過 |
| An untouched field returns to its display | `testFocusCardFeeRate_未輸入即失焦_還原原值`、`testFocusFieldFromLeft_本金未輸入即失焦_聚焦清空且恢復原值` |
| Fraction digits follow the field's format | 實付 1000 與空白見上兩列的實付案例；22.8 為 `testFocusFieldFromLeft_本金輸入小數_失焦後保留小數值`；每月目標空白為 `testFocusMonthlyGoalFromLeft_只聚焦不輸入_收鍵盤後還原80000`；12.345 為 `testFocusCardFeeRate_小數輸入_收鍵盤後依格式捨入`；`abc` 由 `BLNumberFieldDraftTests` 的 `updateText_整數小數與無效輸入_解析出預期金額且保留原文` 驗證 (數字鍵盤打不出字母) |
| Emptying typed text restores the value from focus | `testFocusChargedAmountFromLeft_輸入後全部刪除_還原原值且直接取消`、`updateText_輸入後全部刪除_要求還原聚焦金額` |
| Typing updates dependent results before editing ends | `testFocusFieldFromLeft_零值本金輸入中_未失焦即更新建議售價` |
| Focusing without typing keeps the form unmodified | `testFocusChargedAmountFromLeft_未輸入即失焦_還原原值且直接取消` |
| An outside value change replaces the field text | `testTapPresetAmount_未聚焦時點按鈕_金額欄顯示該金額`、`synchronizeValue_外部改為不同金額_依格式重設草稿` |
| A value limited by the form is shown when editing ends | `testFocusCardlessDeduction_超過實付金額_收鍵盤後顯示上限` |

order-financial-formula：

| 情境 | 測試 |
| --- | --- |
| Excessive deduction is capped and explained | `binding_無卡折抵超過實收金額_夾到上限並標示`、`binding_折抵輸入超額_確認上限內設定並顯示提示` |
| Revenue cannot be negative | `presentation_無卡折抵超過實收金額_夾限後儲存`、`init_含無卡補款與折抵_營收與毛利反映調整金額` |
| Existing over-cap data is corrected on next save | `presentation_既有訂單折抵超過上限_下次儲存時修正` |
| Editing the charged amount keeps the deduction | `testFocusChargedAmountFromLeft_已有折抵時提高實付_存檔重開保留折抵` (改為 5000、存檔重開讀回)；逐字經過 2、26、260 的中途值由 `binding_實付低於設定值_限制有效折抵並保留設定` 與 `binding_受限實付提高或還原_恢復設定折抵並清除提示` 驗證 |
| Lowering then raising the charged amount restores the deduction | 同上兩條單元測試的 500 與 500→3000 |
| Emptying a typed charged amount keeps the deduction | `testFocusChargedAmountFromLeft_已有折抵時輸入再刪空_還原折抵且直接取消`，及單元測試的 1→2500 |
| An excessive deduction stays capped when the charged amount rises | `binding_折抵輸入超額_確認上限內設定並顯示提示`、`binding_超額折抵後提高實付_維持已確認上限` |
| Editing a lowered deduction confirms the shown value | `binding_受限折抵輸入或還原寫回_確認當次寫入值`、`binding_受限折抵確認顯示值後提高實付_維持已確認折抵` |

範例表 deduction capping 是既有規格，300 與 1500 兩列由 `binding_已夾限後輸入未超額折抵_保留輸入並清除標示`、`binding_無卡折抵超過實收金額_夾到上限並標示` 驗證；補款 200 那列沒有單一測試同時驗證夾限與營收，由夾限測試與 `init_含無卡補款與折抵_營收與毛利反映調整金額` 的營收公式組合涵蓋。這是 3.3 當時的狀態，四列後來由同一條參數化測試補齊，見「驗證與審查後的修正」。

### 文件同步

- `apps/ios/README.md`：UI 測試目錄說明補上 `Forms`。
- `.claude/rules/`：`ios-design-system.md`、`ios-navigation.md`、`ios-ui-tests.md`、`ios-unit-tests.md` 已隨各任務更新。
- `apps/ios/CLAUDE.md`：確認無文件影響。
- `git status --short` 沒有字串目錄、`Package.resolved` 或專案檔的變動。根目錄 `CLAUDE.md` 的 Herdr 段落差異不屬本 change。

## 驗證與審查後的修正

`/spectra-verify` 與 `/spectra-review` 的發現，使用者 2026-11-06 指示全部照做，程式與測試修完先交 Codex 唯讀審查再重跑。

### 發現與處理

文件 (主對話修改)：

- proposal 的 Impact 補上受影響的規格 order-financial-formula，以及漏列的修改檔、新增檔、snapshot 基準圖目錄與 `apps/ios/README.md`。
- design 記下品項單價欄寬改 `@ScaledMetric` 的例外 (style 閘門提出、主對話採納、使用者 2026-11-06 同意保留)，以及 `BLNumberFieldDraft` 拆成獨立檔 (主對話決定)。
- tasks 的總數改為 15 項；3.3 的審查補上 State 組字搬移與 `@ScaledMetric`。

程式與測試：

- 審查：合併候選的篩選說明每個日期區段都重算一次整份候選清單。改為 `candidateFilterNotice(for:in:locale:)`，由畫面傳入同一次更新已算好的區段，「只有最後一個區段附說明」的判斷仍在 State (主對話選定，`claude-impl` 實作)。
- 驗證：deduction capping 範例表的營收欄沒有測試，輸入 1000 那列也沒有。新增參數化測試 `binding_折抵輸入不同金額與補款_存下折抵不超過實付且營收相符(testCase:)` (`codex-impl` 實作)：實付 1000，補款 0、0、0、200 時輸入折抵 300、1000、1500、1500，經正式存檔換算 `OrderDraft.resolveWriteResult` 後，斷言存下折抵為 300、1000、1000、1000，營收為 700、0、0、200。
- 驗證：Zero fields 範例表第一列「聚焦前顯示 0」沒有斷言。`testFocusChargedAmountFromLeft_零值輸入_即時取代且失焦保留` 改為聚焦前讀實付並斷言為 0 (`claude-impl`)。
- 驗證：兩條折抵 UI 測試的金額與規格情境不同 (種子實付 4200，規格為 2500)。兩條的 `- Note:` 寫明種子訂單 `UITEST-MIN-001` 的實付是 4200，中途值由 `OrderEditFeatureDeductionTests` 驗證 (`claude-impl`)。驗證建議一併寫出規格情境名稱，但違反使用者「註解不引用 Spectra／SDD 文件」的規則，由 style 閘門指出後，主對話裁定只留技術理由。

### 修正後的審查

- Codex 唯讀審查：Critical 0、Warning 1、Suggestion 1，前後比對檔案雜湊確認未改檔。
  - W1：零值測試在實付欄露出前就讀值。Given 改為先收起客戶鍵盤、露出實付欄再讀 (`claude-impl`)。
  - S1：3.3 的範例表敘述沒有反映新測試，主對話補註。
- style 閘門 (`haiku-max-implementer`)：違規 5 類 9 處、不確定 2 項。
  - 違規全部修正 (`claude-impl`、`codex-impl`)：註解引用規格範例表與規格情境、`- Note:` 超過行寬且一則講三件事、`- Throws:` 與程式不符、摘要只複述測試名稱、`#expect` 不必要的拆行。
  - 存檔換算 `resolveWriteResult` 與 `OrderSummary` 放在 When：主對話裁定維持，換算屬於受測的存檔動作。
  - 測試名稱含「範例表」：主對話採納改名，案例型別一併改為 `DeductionCappingCase`。

### 重跑時 iPad 的失敗

- iPad Air 11-inch (M4) iOS 27.0 跑 Forms 5 類時，`testFocusChargedAmountFromLeft_零值輸入_即時取代且失焦保留` 失敗，訊息為「找不到客戶名稱欄位，無法準備聚焦測試」(When 的聚焦那一行)；iPhone 通過。
- 主對話判讀：W1 修正後，Given 已捲到實付欄，When 的 `focusChargedAmountFromLeft` 又呼叫 `dismissCustomerKeyboard`。iPad 的 Form 捲下去後，頂端客戶欄已離開可及性樹，所以等不到。這是 W1 修正帶進的測試缺陷，不是環境雜訊。
- When 改為直接 `edit.chargedAmountField.tapLeftToFocus(in: app)`，與同檔兩條折抵測試相同；點擊位置 (`dx` 0.04)、鍵盤就緒等待與失敗診斷不變。`claude-impl` 實作，Codex 唯讀審查 Critical 0、Warning 0、Suggestion 0。

### 指令

- 單元：同 3.3。
- UI：每台先重開模擬器並跑 `KeyboardDismissTests`，再以 `-only-testing:BuyLedgerUITests/<類別>` 跑 `OrderEditInputFocusUITests`、`QuoteInputFocusUITests`、`ToolsInputFocusUITests`、`EditorTextInputFocusUITests`、`SearchInputFocusUITests`，其餘參數同 3.3。
- iPad 失敗修正後，兩台各以 `-only-testing:BuyLedgerUITests/OrderEditInputFocusUITests/testFocusChargedAmountFromLeft_零值輸入_即時取代且失焦保留` 重跑。

### 結果

- 單元、守門與全部 snapshot (iPhone 17 iOS 26.5，淺色)：2008 條，2005 過、3 預期失敗、0 失敗；多出的 1 條是新增的參數化測試。
- `KeyboardDismissTests`：兩台各 2 條通過。
- Forms 5 類：iPhone 17 iOS 26.5 共 37 條全部通過；iPad Air 11-inch (M4) iOS 27.0 共 37 條，36 過、1 失敗 (見上一節)。
- 修正後重跑零值實付測試：兩台各 1 條通過。Forms 5 類其餘 36 條的程式在這次修正後沒有變動。

規格情境對照的更新：order-financial-formula 的「Excessive deduction is capped and explained」與「Revenue cannot be negative」另由 `binding_折抵輸入不同金額與補款_存下折抵不超過實付且營收相符(testCase:)` 驗證；text-input-ergonomics「Typing replaces a displayed zero」第一列的聚焦前顯示 0，由零值實付測試的新斷言守住。

文件同步：確認無文件影響，沒有新增規則。

## 3.7 無卡折抵改為紅字檢核

使用者 2026-11-06 提交前實機測試後決定：折抵超過實付時不自動改成上限，折抵欄保留輸入值，正下方紅字提示「無卡折抵金額不得超過客戶實付金額，請調整折抵金額。」，儲存停用；既有訂單或合併預填草稿開啟時已超額也保留原值並提示。驗證範圍由使用者同日指定為訂單編輯相關測試，不跑完整 UI 回歸。主對話決定移除 3.6 的設定值機制、紅字用 `BLTone.destructive.onSurface`、提示只隨折抵欄顯示。

`codex-impl` 改狀態、`OrderDraft` 與單元測試，`claude-impl` 改畫面、identifier、UI 測試、文案與 `ios-navigation.md`，檔案不重疊並行。開工前 `Localizable.xcstrings` 有一筆已暫存、與本 change 無關的 Xcode 抽取雜訊 (新增空字串與 `%@` 鍵、多個鍵標成 stale)，依核准的計畫還原成 HEAD，之後只改 `orders.edit.message.cardlessDeductionCannot` 的 zh-Hant 與 en 兩個值。

新測試在舊寫法下會失敗：暫時在 `.binding`、`prepareDraft`、`OrderDraft(original:)` 放回夾限 (新屬性保留以便編譯)，`OrderEditFeatureDeductionTests`、`OrdersFeatureEditDeductionTests`、`OrderSaveGuardTests` 共 17 條中 7 條失敗：折抵被改成 1000 (超額輸入、實付逐字、既有與合併預填、付款方式切換、改備註與品項、可儲存的補款組合)，以及既有超額訂單按儲存仍送出存檔。其餘 10 條在新舊寫法下都成立 (直接設定超額前置後按儲存被擋、調低後可儲存等)。確認後還原，檔案比對一致。

### 審查

- Codex 唯讀審查：Critical 0、Warning 1、Suggestion 1，前後比對檔案雜湊確認未改檔。
  - W1：比對紅字位置前只等紅字出現，沒有先露出補款欄、等版面穩定。改為收鍵盤後以 `revealPaymentField` 露出補款欄，三個元素都穩定可點才讀框線 (`claude-impl`)。
  - S1：建議把超額與調低拆成兩條測試。主對話依使用者 2026-10-27 的裁定 (跨步驟連續性的 UI 測試可有多組成對的 When／Then) 不採納。
- style 閘門 (`haiku-max-implementer`)：違規 5 處 3 類、不確定 2 項。
  - 採納：3 處未達斷行條件卻拆行的呼叫併回單行；兩處 identifier 與 accessor 的註解只複述名稱，改寫出金額單位 (`claude-impl`)。
  - 不確定 U1：五列參數化測試的 When 依 `canSave` 分支換算、Then 依案例分支斷言。主對話裁定拆成可儲存與不可儲存兩條參數化測試，測試本體不再分支 (`codex-impl`)。
  - 不確定 U2：`{ _ in` 是否應改 `$0`。主對話裁定維持，被忽略的參數不在 `$0` 規則內。
  - 觀察：測試名稱的「實收金額」統一為「實付」(`codex-impl`)。

### 指令

- 單元：同 3.3。
- UI：每台先重開模擬器並跑 `KeyboardDismissTests`，再以 `-only-testing:BuyLedgerUITests/<類別>` 跑 `OrderEditInputFocusUITests`、`OrderCreateTests`、`OrderEditAddOptionTests`、`OrderEditDateRowTests`、`OrderEditDirtyTests`、`OrderMergeTests`，其餘參數同 3.3。
- 目視：以 `mobilebuildmcp ui-automation` 帶 `-BLUITest -BLUITestSeed minimalOrders` 與語言參數啟動，開 `UITEST-MIN-001` 編輯 (實付 4200)，付款方式改無卡、折抵輸入 5000 後收鍵盤截圖。

### 結果

- 審查前，受影響的 7 個單元類別 50 條在 iPhone 17 iOS 26.5 通過；`OrderEditInputFocusUITests` 15 條在 iPhone 通過。
- 審查後的修正完成後：
  - 整個 `BuyLedgerTests` (iPhone 17 iOS 26.5，淺色)：2000 條，1997 過、3 預期失敗、0 失敗。比上一節少 8 條：3.6 的 20 條折抵測試收斂為 10 條，`OrdersFeatureEditDeductionTests` 與 `OrderSaveGuardTests` 各多 1 條。
  - iPhone 17 iOS 26.5：`KeyboardDismissTests` 2 條、訂單編輯相關 6 類 28 條全部通過。
  - iPad Air 11-inch (M4) iOS 27.0：`KeyboardDismissTests` 2 條通過；6 類第一次執行約 3 分鐘時模擬器服務中斷 (`Loaded CoreSimulatorService is no longer valid`)，測試程式被終止，沒有斷言失敗。重新開機後 `KeyboardDismissTests` 2 條、6 類 28 條全部通過。
- 目視：iPad 以英文與中文各截圖一次，紅字位於折抵欄與補款欄之間、呈紅色，中文兩行內排完，儲存鈕呈停用。iPhone 17 iOS 26.5 在服務中斷後無法開機 (回報找不到 iOS 26.5 runtime，runtime 磁碟映像仍在)，未截圖；iPhone 上的位置與停用由 UI 測試驗證。

### 規格情境與測試 (order-financial-formula 改寫後)

3.3 的 order-financial-formula 對照表與 text-input-ergonomics 的「A value limited by the form is shown when editing ends」是改寫前的規格，現行對照如下：

| 情境 | 測試 |
| --- | --- |
| Excessive deduction is kept and blocks saving | `binding_折抵超過實付_保留輸入且禁止儲存`、`saveTapped_必填齊全但無卡折抵超額_保留表單且不送存檔請求`、`presentation_無卡折抵超過實付_不送出存檔`、`testFocusCardlessDeduction_超過實付金額_保留輸入並提示調整` |
| Adjusting the deduction allows saving | `binding_超額折抵調低至合法值_解除超額且可儲存`、同上 UI 測試的第二組 |
| Lowering the charged amount flags the deduction | `binding_實付逐字降低或提高_保留折抵並更新檢核` 的 500 與 500 改 3000 |
| Editing the charged amount keeps the deduction | `testFocusChargedAmountFromLeft_已有折抵時提高實付_存檔重開保留折抵`；中途值 2、26、260、2600 由 `binding_實付逐字降低或提高_保留折抵並更新檢核` 驗證 |
| Emptying a typed charged amount keeps the deduction | `testFocusChargedAmountFromLeft_已有折抵時輸入再刪空_還原折抵且直接取消`、`binding_實付輸入後還原原值_折抵不變且表單未修改` |
| Existing over-cap data is flagged when opened | `init_既有或合併草稿折抵超額_保留原值且未修改`、`presentation_既有訂單折抵超過上限_不送出存檔`、`presentation_既有訂單折抵超過上限_調低後才儲存` |
| A non-cardless payment method is not flagged | `pickers_超額折抵切換付款方式_保留折抵並依付款類型檢核` |
| Revenue cannot be negative | `applyingPaymentMethodFlags_改為無卡且折抵超過實付_折抵上限為實付金額`、`init_含無卡補款與折抵_營收與毛利反映調整金額` |

範例表 deduction validation：可儲存的三列由 `binding_合法折抵搭配不同補款_可儲存且折抵與營收相符` 經 `resolveWriteResult` 斷言存下折抵與營收，不可儲存的兩列由 `binding_超額折抵搭配不同補款_保留輸入且禁止儲存` 驗證。

### 文件同步

- `.claude/rules/ios-navigation.md`：跨欄位限制條目改為以檢核訊息提示並停用儲存。
- `apps/ios/CLAUDE.md`：ui-automation 一節補上 iPad 數字鍵盤按鍵不在快照內、要以 Caps Lock 切換輸入法後送硬體鍵碼。
- `apps/ios/README.md`：確認無文件影響。

全部在模擬器驗證，未在實機驗證。

## 3.8 紅字移到收款區段底部

使用者 2026-11-07 實機檢視 3.7 後決定，紅字檢核訊息改放收款區段底部，排在無卡計算說明的灰字下方。文案、色彩、identifier 與停用儲存不變。`claude-impl` 實作，主對話審查後先修一輪：位置斷言併回單行；`OrderEditScreen.revealPaymentField` 也用來露出區段底部的紅字，參數說明與失敗訊息改為不限定欄位。

### 審查

- Codex 唯讀審查：Critical 0、Warning 1、Suggestion 1，前後比對檔案雜湊確認未改檔，兩項都採納 (`claude-impl` 修正)。
  - W1：捲動前先等紅字存在。紅字在可視範圍下方時還不在可及性樹上，等待逾時會讓捲動備援不執行。改為直接以 `revealPaymentField` 露出紅字，再等相鄰元素穩定。
  - S1：只比對紅字在補款欄下方，守不住「在灰字說明之後」。灰字說明新增 identifier `OrderEdit.cardlessPaymentNote`，掛在灰字 `Text` 本身；測試等補款欄、灰字、紅字三者穩定可點後，斷言順序為補款欄、灰字、紅字。
- style 閘門 (`haiku-max-implementer`)：違規 1 處、不確定 3 項。
  - V1：`sectionFooter` 的說明改為名詞片語，與同檔其他屬性一致 (採納)。
  - U1：UI 測試的 `- Note:` 以實作機制說明理由，改寫為使用者看得到的結果 (主對話裁定採納)。
  - U3：UI 測試摘要沒反映位置與儲存鈕的斷言，補上 (主對話裁定採納)。
  - U2：`revealPaymentField` 三元式內多行呼叫的右括號欄位。3.8 沒改到這段既有寫法，規範也沒定義此情況的基準欄，主對話裁定維持。

### 指令

- 單元：同 3.3。
- UI：每台先跑 `KeyboardDismissTests`，再以 `-only-testing:BuyLedgerUITests/OrderEditInputFocusUITests` 執行，其餘參數同 3.3。
- 目視：以量完即刪的暫時 XCUITest 開 `UITEST-MIN-001` 編輯，實付輸入 1000、付款方式改無卡、折抵輸入 5000 後收鍵盤，露出紅字後以 `XCTAttachment` 截圖，中英文各一次，兩台都跑；截圖取自 xcresult 附件，量完刪除測試檔。不用 `mobilebuildmcp ui-automation` 操作：iPad 的數字鍵盤按鍵不在快照內，iPhone 這次觸控只改分頁列選取、畫面不切換。

### 結果

- 整個 `BuyLedgerTests` (iPhone 17 iOS 26.5，淺色)：2000 條，1997 過、3 預期失敗、0 失敗。
- iPhone 17 iOS 26.5：`KeyboardDismissTests` 2 條、`OrderEditInputFocusUITests` 15 條全部通過。
- iPad Air 11-inch (M4) iOS 27.0：`KeyboardDismissTests` 2 條通過。`OrderEditInputFocusUITests` 15 條：13 過、1 skip、1 逾時。
  - skip 的是 `testFocusCardFeeRate_再次點左側_保留已輸入文字`，原因是數字 Popover 呈現時會擋掉再次點欄位，這是測試內明確寫好的 skip 條件。
  - 逾時的是 `testFocusCardFeeRate_未輸入即失焦_還原原值`：超過 10 分鐘執行上限，逾時前沒有斷言失敗，log 有 5 次 `App animations complete notification not received`。這條測試 3.8 沒改到，依 `ios-ui-tests.md` 的判讀單獨重跑。
  - 第一次重跑前依規則重開模擬器，結果失敗：「數字鍵盤或 Popover 未能收起 (呈現方式：浮動數字面板)」。原因是模擬器處於硬體鍵盤狀態，見下方「執行中的狀況」。
  - 使用者在 Device Hub 切換 Simulate Hardware Keyboard 後不再重開。`KeyboardDismissTests` 2 條通過，第二次重跑 1 條通過 (約 2 分鐘)。
- 目視：兩台中英文共 4 張截圖。紅字都在收款區段底部、灰字計算說明下方，呈紅色；儲存鈕呈停用。中文一行排完，英文兩行。

位置由 `testFocusCardlessDeduction_超過實付金額_保留輸入並提示調整` 的順序斷言守住。3.7 一節的規格情境對照不變，「Excessive deduction is kept and blocks saving」的位置要求改由這條斷言驗證。

### 執行中的狀況

- 字串目錄再次被建置雜訊污染。第一次完整單元執行時，`LocalizationCatalogTests` 有 2 條失敗：`findBlankLocalizations_每個需翻譯條目_中英文值皆非空白`、`structuredKeysFormat_結構化英文Key_符合點記號與小駝峰規範`。原因是 Xcode 建置又把抽取雜訊寫回 `Localizable.xcstrings`，新增了空字串、`%@`、`orders.batch.message.selectedCount %lld` 三個鍵，並加上 stale 標記。處理方式與 3.7 相同：還原成 HEAD，再補回 `orders.edit.message.cardlessDeductionCannot` 的兩個值，重跑通過 (即上方結果)。
- iPad 模擬器進入硬體鍵盤狀態。主對話為了截圖，對 iPad 模擬器送出 `ui-automation key-press`／`key-sequence` 的硬體按鍵，之後軟體鍵盤不再出現，鍵盤相關 UI 測試都會失敗。使用者在 Device Hub 切換 Simulate Hardware Keyboard 後恢復，但重開模擬器後狀態又回來，所以要再切換一次且不重開。
- iPhone 17 iOS 26.5 開機時回報找不到 runtime。使用者以 `killall -9 com.apple.CoreSimulator.CoreSimulatorService` 重啟模擬器服務後恢復。

### 文件同步

- `apps/ios/CLAUDE.md`：3.7 加入的「iPad 以 Caps Lock 切換輸入法後送硬體鍵碼」會讓模擬器進入硬體鍵盤狀態，改寫為不可對 iPad 送硬體按鍵，需要輸入數字的實測改用量完即刪的暫時 XCUITest。
- `.claude/rules/ios-navigation.md`：跨欄位限制條目的參考改為收款區段底部的紅字。
- `apps/ios/README.md`：確認無文件影響。

全部在模擬器驗證，未在實機驗證。
