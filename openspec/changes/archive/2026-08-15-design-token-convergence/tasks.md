## 1. 先建立掃描器並以現況校準

- [x] 1.1 ~~依 design 決策：D6 掃描守門以測試內的原始碼掃描實作...驗證：在未改動的工作樹跑一次，回報數字與逐項量測完全吻合——系統次要色 49 處、系統強調色 4 處、外觀環境宣告 18 個、字級修飾子呼叫 3 處~~

  **⚠ 2026-08-01 基準已重新校準，取代上方原始文字 (保留刪除線作沿革記錄)。** 原基準寫於本計劃開始前，本案排入時已因前 25 個 change (含本計劃自己的第 21 案 `accessibility-coverage-sweep`) 疊加而全面漂移；且 tasks 原文「對不上就先修掃描器，不得先動程式碼」的指示在此不成立：25 案疊加後基準過時才是預設答案，對不上時應先判斷是掃描器邏輯錯誤還是基準漂移，而非預設前者。

  新增 `BuyLedgerTests/DesignSystemSourceScanTests.swift`：以自身檔案路徑往上定位 `apps/ios/BuyLedger/`，列舉全部 Swift 檔 (排除 `Core/Domain/Generated/`)，每行先剝除行註解與成對雙引號字串字面值再比對。此階段先只輸出各規則的命中清單、不設斷言。驗證：在**未改動**的工作樹跑一次，回報數字與 2026-08-01 逐項精確量測完全吻合：系統次要色 **56** 處 (17 檔)、系統強調色 **4** 處、外觀環境宣告 **17** 個 (16 未讀取)、系統綠 **9** 處 (6 生產 + 3 預覽)、系統橘 **4** 處 (1 生產滑動操作 + 3 預覽)、系統紅 **5** 處 (原基準未列，本次新查出)、系統藍 **2** 處 (原基準未列，皆預覽)、十六進位建構子 **0** 呼叫點；字級修飾子呼叫改為**不設掃描規則** (見任務群組 2 說明)。詳細校準表見 design.md Context 一節
- [x] 1.2 讓掃描器的失敗訊息帶檔名、行號與引導句 (例如新增系統色請加進色盤的顯示屬性再由呼叫端取用)，而非只回報數量。此為規格 Design system entry points are enforced by a source scan 中「訊息即修正指引」的落地。驗證：於未改動工作樹的輸出中，逐條規則皆可看到 `檔名:行號` 與對應引導句

## 2. 字級軌道決策撤除、刪除零呼叫點的十六進位建構子

- [x] 2.1 ~~依 design 決策：D1 字級 token 軌道直接刪除，刪掉字級列舉與其修飾子兩支檔...~~

  **🔴 本任務於 2026-08-01 撤除，不執行。** 原任務的前提「字級 token 軌道生產呼叫點為零、僅 `BLCard` 預覽區塊三處」已被本計劃自己的第 21 案 (`accessibility-coverage-sweep`) 完全反轉：該案已把手寫字型指定收斂進 `BLTypographyStyle`／`blTextStyle(_:)`，並在 `apps/ios/CLAUDE.md` 新增「字級一律走 token」規則。2026-08-01 實測 `blTextStyle(` 呼叫點 **117 處、橫跨 39 個檔**，字級 token 已是專案標準寫法。若仍執行此任務，刪除兩支檔會讓 39 個檔全部編不過、摧毀第 21 案成果。詳見 design.md 決策標題「D1 (已撤除) 字級 token 軌道直接刪除」。**不刪除 `BLTypography.swift`、不刪除 `BLTypographyModifier.swift`、不動 `BLCard` 的預覽字級呼叫。**

  對應的 design.md 決策標題與 openspec/changes/design-token-convergence/specs/design-system-hygiene/spec.md 已同步撤除「A token track used only by a preview is removed」情境 (該情境專門描述此任務的行為契約，隨任務撤除一併移除，避免規格描述一個不會發生的行為)
- [x] 2.2 [P] 刪除顏色擴充檔內零呼叫點的十六進位建構子 (該檔保留，用於承載任務 3.1 的新入口)。驗證：該建構子在全庫零命中

## 3. 次要文字換單一入口

- [x] 3.1 依 design 決策：D2 次要文字改走 Color 擴充的單一入口，在顏色擴充檔新增代理到色盤次要標籤色的靜態屬性，doc comment 寫明「系統次要色淺色僅約 3.4:1、低於本專案 4.5:1 地板，資訊性次要文字一律走這支」。刻意放在顏色型別擴充而非色盤上，不必在 20 餘個私有 helper 內各自取得色盤實例。**2026-08-01 施工中修正**：呼叫端一律用 `Color.blSecondaryLabel` 明確型別形式，不用 `.blSecondaryLabel` 前置點縮寫 (縮寫在本專案 `foregroundStyle(_:)` 情境下必然解析不到，6 處呼叫點實測失敗，技術成因與詳細清單見 design.md D2)。驗證：新增斷言 `blSecondaryLabelShorthandResolvesToThePaletteColor` 綠：該入口與色盤次要標籤色在四種外觀下的色彩分量完全相同
- [x] 3.2 先只把設定頁 (`SettingsView.swift`) 的系統次要色換成新入口 (2026-08-01 重新量測實際為 6 處，原基準寫 3 處已過時)，build-and-run 到實機目視比對。驗證：人工確認變深後的說明文字可接受；若判定過深，改為微調色盤次要標籤色的推導係數並重跑既有對比測試 (仍須逾 4.5:1)，**不得**回頭保留系統值
- [x] 3.3 依 design 決策：D3 Section footer 一併收回，不留豁免，把其餘全部系統次要色換成新入口，含表單與清單的 section footer，以及以另一種寫法出現 (`Color.secondary`) 的那一處 (2026-08-01 重新量測：改動前基準合計 **56** 處、分佈 17 檔，原基準 49 處已過時)。不要順手動非資訊性的第三層文字色 (揭示指示箭頭屬純圖形、仍走系統色)、也不動用於背景填色的 `.secondary` (`AISummaryView.swift` 2 處，非文字用途、不在本規則範圍)。此為規格 Informational text meets the 4.5:1 contrast floor 中新增的次要文字與 footer 情境的落地。驗證：系統次要色 (文字用途) 在全庫零命中，且既有對比測試不修改即通過

## 4. 色彩字面值收回色盤

- [x] 4.1 依 design 決策：D4 色彩字面值的唯一例外是 white black clear，把系統強調色、系統綠、系統橘 (含滑動操作) 全部改為在該 helper 內取得色盤實例後取用對應色，沿用專案既有的 body 內建構慣例。2026-08-01 重新量測實際數字為：強調色 4 處 (未漂移)、綠 9 處 (6 生產 + 3 元件預覽區塊，原基準 2 處已過時)、橘 4 處 (1 生產滑動操作 + 3 元件預覽區塊，原基準 1 處已過時)。**另新增範圍**：`color-system-foundation` 規格正文本就是「具名系統色一律不得取代色盤色、唯一例外白黑透明」的概括規則，本次一併查出系統紅 5 處 (`PersistenceFailureView.swift` 2 處、`CampaignEditView.swift`、`LookupManagementView.swift`、`OrderRowView.swift`，皆生產程式碼) 與系統藍 2 處 (`BLDonutChart.swift`、`BLMetrics.swift`，皆元件預覽區塊)，一併改為色盤取色，不留在規則範圍外。`Core/Testing/BLUITestDependencyOverrides.swift` 的 `photoPalette: [UIColor]` 用於合成 UI 測試替身假照片像素、非語意 UI 色彩，不轉色盤。**2026-08-01 QA 修正**：原文字宣稱此行「以具名豁免標記排除」，經查證該行的隱式成員寫法 (`.systemBlue` 等) 不落在任何一條掃描規則的判定範圍內 (規則三僅比對單一色相字面值，`systemBlue` 等複合識別字不吻合；規則四僅比對 `UIColor(` 呼叫或 `UIColor.` 顯式成員存取，`[UIColor]` 型別標註加隱式成員語法兩者皆不符)，該標記從未真正排除任何違規，屬裝飾性標記，已移除；此處不需要例外機制。**同批一併查出的相鄰違規**：`PersistenceFailureView.swift`／`AppLockView.swift` 兩處阻斷畫面直接呼叫 `Color(uiColor: .systemBackground)`，屬「系統取色介面限色盤檔」規則的違規 (非本任務列舉的具名色相字面值，但屬同一條規則)，已在色盤新增 `plainBackground` 顯示屬性並改為呼叫該入口。白、黑與透明維持不動。此為規格 Semantic and system colors are obtained through system APIs 中「具名系統色不得取代色盤色」的落地。驗證：系統強調色、系統色相字面值 (綠／橘／紅／藍) 與指定系統色的滑動操作在全庫零命中；系統取色介面呼叫僅出現在色盤檔、色相構造僅出現在頭像元件

## 5. 清除未讀取的外觀宣告

- [x] 5.1 依 design 決策：D7 刪除從未讀取的 colorScheme 宣告，逐檔刪除 16 個未被讀取的外觀環境宣告與其文件註解 (2026-08-01 重新量測：全庫共 17 個宣告，其中 16 個未讀取，原基準「18 個中 17 個未讀取」已過時)，只保留卡片陰影修飾子那一個真正的讀者。此為規格 Ineffective and unreferenced code is removed 中新增的「從未讀取的環境宣告應移除」情境的落地。驗證：外觀環境宣告在全庫恰好 1 行且位於卡片陰影修飾子；iPhone 與 iPad 各 build 成功，並於實機切換深淺外觀目視確認卡片陰影仍正確變化

## 6. 狀態色點單一來源

- [x] 6.1 依 design 決策：D5 狀態色點承認為獨立 token 軌道，新增承載分組色相的獨立來源型別，以窮舉分支把每個訂單狀態映到色盤色 (沿用現行 8 色映射、視覺零變更)，doc comment 寫明兩軌的適用邊界：語意色軌道表達語意強度 (6 值)、色相軌道表達流程階段可區分性 (8 值)，狀態膠囊一律走語意色、只有側邊欄分組色點走色相軌道。側邊欄原本內嵌的映射整段刪除改為呼叫此來源。此為規格 Status colors match the meaning of the status 中兩軌單一來源的落地。驗證：側邊欄 8 個色點與改動前逐一相同 (人工目視)，且側邊欄檔內不再有狀態到顏色的內嵌映射
- [x] 6.2 新增分組色相測試：斷言側邊欄實際顯示的 8 個分組色相在四種外觀下兩兩相異 (保住可區分性)。**2026-08-01 施工中修正**：「每個訂單狀態都有對應色」已由 `BLStatusHue.color(for:in:)` 的窮舉 `switch` (無 `default` 分支) 在編譯期保證，新增訂單狀態時若未補分支會直接編譯失敗；此保證屬語言層級的靜態檢查，包成執行期測試不會呼叫到任何實際會失敗的路徑 (只要能通過編譯，逐一呼叫全部 case 必然成功)，屬無意義的假測試，故不新增對應的第二條執行期斷言，只保留可區分性這一條有實質保護力的斷言。驗證：可區分性斷言綠

## 7. 開啟掃描守門

- [x] 7.1 把任務 1.1 的診斷模式改為正式斷言，共八條規則：禁系統次要色 (文字用途)、禁系統強調色、禁系統色相字面值 (綠／橘／紅／藍) 與指定系統色的滑動操作、系統取色介面限色盤檔、色相構造限頭像元件且無原始分量構造、外觀環境宣告限卡片陰影修飾子、十六進位建構子零命中、以及豁免標記必須帶非空理由。**字級修飾子零命中規則不設立** (D1 已撤除，字級 token 為專案標準，`blTextStyle(` 117 處呼叫皆為合規寫法，沒有「零命中」的意義)。驗證：八條在最終工作樹全綠

  > **附帶建議 (不在本任務範圍內自行實作，留給協調者裁定)：** 字級軌道現為專案標準卻無掃描守門，剩餘約 112 處手寫 `.font(` 字面值 (117 處 `blTextStyle(` 之外) 目前無機制攔截新增。是否要仿照本案的色彩守門，另加一條「剩餘手寫 `.font(` 需具名豁免理由」的規則？這會擴大本案範圍 (需重新盤點全部手寫字級呼叫、逐一補理由或改寫)，故本次不自行決定，僅提出建議
- [x] 7.2 實作具名豁免標記的支援：標記帶理由才放行，理由為空即失敗，並讓測試輸出列出當前全部豁免與其理由。此為規格 Design system entry points are enforced by a source scan 中豁免可見性的落地。驗證：刻意加一個無理由的標記後該條失敗、補上理由後通過，且輸出可見該豁免 (驗證後還原)
- [x] 7.3 對八條規則逐條做失效驗證：各刻意插入一個違例後單獨跑該條，必須失敗並在訊息中印出正確的檔名與行號。驗證：八條逐一確認後還原，工作樹回到全綠

## 8. 文件、規格與全回歸

- [x] 8.1 更新 `apps/ios/CLAUDE.md`：**不移除**字級修飾子符號的既有敘述 (D1 已撤除，該規則仍有效)，在 Design System 準則新增三條：色彩不做亮暗分支故不宣告外觀環境值 (卡片陰影修飾子除外)、資訊性次要文字走新入口且白黑透明為唯一色彩字面值例外、以及具名豁免標記的格式。驗證：該檔內字級修飾子符號 (`BLTypographyStyle`／`blTextStyle`) 出現次數與改動前相同 (不變動)，且三條新敘述可查得
- [x] 8.2 鎖模擬器淺色外觀後重錄受影響的基準圖。**2026-08-01 施工中修正**：實際受影響的是 7 張 (`dashboardViewBaseline`／`orderEditViewBaseline`／`orderEditViewLongIdentifierBaseline`／`ordersCompactViewBaseline`／`ordersCompactViewLongContentBaseline`／`ordersCompactViewMultiSelectBaseline`／`ordersRegularViewMultiSelectBaseline`)，原基準「5 張 (訂單清單兩張、訂單編輯兩張、訂單詳情成本明細一張)」已過時 (實際分佈更廣、且不含 `orderDetailCostBreakdownBaseline`)；新舊並排檢視 (Python PIL 逐張裁切比對) 而非直接覆蓋。驗證：7 張差異皆只出現在次要文字變深，逐張目視確認完畢；其餘基準圖 (含成本明細、長條圖、分析頁) 未變動

  **2026-08-01 QA 修正補記**：`orderEditViewMergeContextBaseline` 未被列入上述 7 張重錄清單，但本案的色彩改動同樣使其**額外過期**：該基準圖仍留有 12,127 px 舊制 `(127,127,127)` 灰階與 3,544 px `(187,187,193)` 灰階 (皆為改動前的次要色數值)。此圖原本就因既有的環境紅燈 (`orderEditViewMergeContextBaseline()`，見 `apps/ios/CLAUDE.md`「erase 模擬器會讓 compact DatePicker 膠囊的日期格式退回數字短式」) 而恆為已知失敗，本案改動後成為**雙重紅**：即使日後環境問題修好，仍會因色彩過期而繼續失敗。**本輪不得重錄**：使用者尚未拍板次要色深淺，此時重錄會把當下模擬器環境退化的數字短式日期格式一併烙進新基準，需等使用者拍板配色且環境問題修復後一併處理
- [x] 8.3 以 xcodebuildmcp 序列跑 iPhone 與 iPad build (共用 build.db 不可並行)，接著跑主 scheme 全部單元測試與介面自動化主回歸 (`-only-testing:BuyLedgerUITests` 加 `-skip-testing:BuyLedgerUITests/LaunchPerformanceTests`)。**2026-08-01 施工中修正**：`CURRENT_PROJECT_VERSION` 維持 237 不依賴口頭指示背書，`apps/ios/CLAUDE.md`「建置、測試與開發指令」一節本就明訂「跑 test 不遞增」(test binary 不會被安裝或散佈)，本次收尾驗證屬此例外範圍；施工中一度誤跑 `agvtool next-version -all` (237→238)，發現後已手動改回 `CURRENT_PROJECT_VERSION = 237` (工作區原有值)，不使用 `git checkout`。此敘述可由讀者直接核對 `apps/ios/CLAUDE.md` 該句規則與 `project.pbxproj` 目前的 `CURRENT_PROJECT_VERSION` 數值查證，不依賴無法查核的口頭指示。驗證：兩平台 build 成功 (iPhone 17 與 iPad Air 11-inch)、主 scheme 631 passed／1 known-red (另有 1 次全套件並跑時的資源競爭 flaky `quoteViewBaseline`，單獨重跑確認綠)、介面主回歸在 iPhone 17 Pro Max 與 iPad Air 各 54/54 全綠
