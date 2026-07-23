## 1. 前置確認

- [x] 1.1 確認前八個 change 皆已完成實作：hig-blocker-remediation、design-system-component-reduction、touch-target-and-input、navigation-integrity、dynamic-type-and-grouping、ui-polish-and-safeguards、keyboard-dismissal-native-rewrite、ux-honesty-and-visual-foundation。行為：稽核對照的是完整落地後的現況，而非中間狀態。驗證：逐一檢視八者的任務完成狀態；若有未完成者則不啟動後續任務，或僅處理已完成者對應的文件項並於稽核筆記標明未涵蓋範圍。
- [x] 1.2 建立稽核筆記檔案於本 change 目錄，預先列出五個區塊：各 change 文件宣告的核對結果、符號存在性掃描結果、既有漂移的處理決定、失效註解的判別與處理、以及待提升為文件規則與待修產生器的記錄。行為：稽核結論有固定的記錄位置，不散落於 commit 訊息。驗證：筆記檔案存在且五個區塊皆已建立標題。

## 2. 逐 change 核對文件宣告

- [x] 2.1 依決策〈以各 change 的文件任務宣告作為核對索引〉，逐一取出前八個 change 文件同步任務中宣告要寫入的規則與要移除的描述，於文件中指出其落地位置；找不到者記錄為未落地並補上。滿足 Declared documentation updates are verified against the documents。行為：每一項宣告的更新都能在文件中被指出位置，而非僅憑任務被勾選。驗證：稽核筆記的第一區塊列出每個 change 的每一項宣告及其落地位置或補齊記錄，無「假定已由他處涵蓋」的條目。

## 3. 修正已定位的失效描述

- [x] 3.1 改寫平台指引中收鍵盤的硬規則：移除以 window 級手勢實作、逐層過濾排除系統選單、以及「不可改成對所有 touch 都收鍵盤」等已被 keyboard-dismissal-native-rewrite 推翻的描述，改為記錄四條收起路徑 (return 鍵／鍵盤工具列／捲動／背景層點擊) 與「不得以全域攔截加排除清單實作」的新規則。滿足 Documentation contains no statements contradicting the current implementation。行為：文件不再指示已不存在的實作方式。驗證：對照 keyboard-dismissal-native-rewrite 的實際實作逐句確認改寫後內容相符。
- [x] 3.2 [P] 修正三處以已刪除元件為例的規則：extension 放置規則不再以收鍵盤修飾子與其檔案為例、本地化規則不再以分段控制元件為例、Design System 檔名規則不再以搜尋欄與金額欄元件為例，一律改用仍存在的元件。滿足 Documentation contains no statements contradicting the current implementation。行為：規則的舉例指向真實存在的程式碼。驗證：改寫後的每個舉例皆可在程式碼中找到對應宣告。
- [x] 3.3 [P] 修正底部工具列規則的結尾：移除「該擺位在 iPad 仍安全」與其舉例，改為記錄兩種尺寸皆採頂部擺位、筆數由導覽標題承載。滿足 Documentation contains no statements contradicting the current implementation。行為：規則與 navigation-integrity 的實作一致。驗證：對照該 change 的實作確認描述相符。

## 4. 符號存在性掃描

- [x] 4.1 依決策〈以符號存在性作為文件正確性的客觀依據〉，掃描平台指引與說明文件中出現的型別名與檔名，逐一確認其在程式碼中存在；不存在者逐筆人工判定為錯誤或示意用法，錯誤者修正、示意者於稽核筆記標記並說明理由。滿足 Symbols named in documentation exist in the codebase。行為：文件不再提及不存在的型別或檔案。驗證：稽核筆記的第二區塊列出掃描結果，所有不存在的符號皆有處理決定；反向缺漏 (程式碼有而文件未提) 不列為缺陷。

## 5. 程式碼註解稽核

- [x] 5.1 依決策〈註解稽核只問「是否與現況矛盾」，不問風格〉，以前八個 change 的變更範圍為索引，掃描手寫原始碼中描述機制、設計理由與實作意圖的註解，判別其內容是否仍成立；掃描涵蓋未被任何 change 修改的檔案，因為那正是風格閘門結構上看不到的部分。滿足 Comment auditing is limited to currency, not style。行為：失效註解被找出，而風格問題留給專責閘門。行為驗證：稽核筆記的第四區塊列出每一條被判定失效的註解及其所在位置與失效理由；過程中遇到的純風格問題不列入亦不修改。
- [x] 5.2 依決策〈註解失效分三類，處理方式各異〉處理已確認的三個案例與 5.1 掃描出的其餘失效註解：解釋理由已不成立者連同解釋改寫或隨構造刪除；描述意圖與實作不符且實作已決定維持現狀者改寫註解以反映實際做法並指出該決定出處；實作才是該改的一方者僅記錄、不在本 change 改動任何一邊。滿足 Comments do not describe mechanisms or rationale that no longer hold。行為：註解描述的內容與程式碼一致，且未越界修改應由其他 change 負責的實作。驗證：逐條對照稽核筆記第四區塊確認每項皆有處理決定；被判定為「實作該改」者確認其已記錄於對應 change 而非在此改動。
- [x] 5.3 [P] 依決策〈生成檔的註解只記錄不修改〉，掃描涵蓋生成檔但不修改其註解；發現的問題記錄為產生器待修項目。滿足 Generated file comments are reported rather than edited。行為：生成檔保持未經手動編輯。驗證：稽核筆記的第五區塊列出產生器待修項目；於 shared/data-model/generator 執行同步檢查確認仍通過 (exit 0)。
- [x] 5.4 [P] 依決策〈註解失效分三類〉之第三類，識別註解中記錄且適用範圍已超出所在檔案的踩雷知識，記錄其是否值得提升為文件層級硬規則，但不在本 change 逕行搬移。滿足 Widely applicable knowledge in comments is identified for promotion。行為：跨檔案適用的知識被辨識出來，留待獨立決定其措辭與歸屬層級。驗證：稽核筆記的第五區塊列出候選項目及其建議歸屬層級 (根目錄或平台目錄)。
- [x] 5.5 確認本組對原始碼的變更僅含註解行且專案可建置。滿足 Comment edits change no executable code。行為：註解稽核未意外改動任何可執行語句。驗證：以差異比對逐行確認變更皆為註解行；iOS 與 iPadOS 皆建置成功 (build 前先於 apps/ios 執行 agvtool next-version 遞增 build number)。

## 6. 累積結構整理

- [x] 6.1 依決策〈結構整理限於分層與合併，不刪減規則〉，將八個 change 新增至平台指引的規則依主次層級重整：語意重疊者合併、細節與 caveat 降為次層級、同主題者相鄰排列；合併後逐條回讀確認原規則的約束力未被削弱，有疑慮者維持分列。滿足 Accumulated additions preserve document structure。行為：平台指引維持可讀的層級結構而非流水帳，且無實質規則遺失。驗證：整理前後的規則逐條對照，確認條數變化皆可歸因於明確的合併且每條原約束仍可指出其所在；無任何規則的實質內容被移除。

## 7. 既有漂移修正

- [x] 7.1 [P] 依決策〈既有漂移逐項列出來源，不與本次失效混談〉，於說明文件的專案結構樹補上未列出的既有原始碼目錄 (含媒體處理目錄，以及鍵盤目錄若於 keyboard-dismissal-native-rewrite 後仍存在)，並在稽核筆記標明此為既有漂移而非前八個 change 造成。滿足 Accumulated additions preserve document structure 中關於結構列表涵蓋既有目錄的要求。行為：結構樹涵蓋所有既有原始碼目錄。驗證：以原始碼目錄清單逐一對照結構樹確認無遺漏。
- [x] 7.2 [P] 修正說明文件中相依注入目錄的數量描述，改為與現況相符或改為不綁定數量的描述以免再次漂移，並於稽核筆記標明此為既有漂移。滿足 Documentation contains no statements contradicting the current implementation。行為：描述不因新增相依項而再次過時。驗證：清點該目錄現有檔案數並確認描述相符或已改為不綁定數量。
- [x] 7.3 [P] 將稽核過程中發現但需要重新查證才能斷言正誤的描述記錄於稽核筆記的待查區塊，不逕行修改。行為：不確定的項目留下線索而非被猜測性改寫。驗證：稽核筆記的第三區塊列出待查項目及其疑點。

## 8. 收尾

- [x] 8.1 依根目錄文件同步表逐列檢視本次變更本身是否觸發其他文件影響，並確認跨平台通用規範與平台細節的歸屬原則未被本次整理破壞 (通用規則留根目錄、平台細節留平台目錄)。行為：本 change 自身也遵守其所稽核的規則。驗證：對照文件同步表逐列確認，結論為「有影響，已同步」或「確認無文件影響」；並確認整理後無平台細節被移入根目錄文件。
