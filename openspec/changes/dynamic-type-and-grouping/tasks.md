## 1. 前置確認

- [x] 1.1 確認 hig-blocker-remediation 的熱力圖離散深度階梯已落地，本 change 對熱力圖的尺寸與標籤調整需建立在其成果之上。行為：避免兩個 change 對同一段程式碼產生衝突修改。驗證：檢視熱力圖現況已採離散階梯與成對色彩資源，若尚未落地則暫緩第 2 與第 4 組中的熱力圖相關任務。

## 2. 版面隨字級調整

- [ ] 2.1 [P] 依決策〈以字級環境值判斷是否為無障礙字級，而非逐級列舉〉與〈移除最小縮放係數與單行限制，改為允許換行〉，讓 DashboardView 的淨獲利與關鍵指標格在無障礙字級下解除單行限制並允許換行，關鍵指標格由兩欄降為單欄。滿足 Layouts change structure at accessibility text sizes 與 Text scaling is not cancelled by shrink-to-fit。行為：最大無障礙字級下兩者皆完整可讀，標準字級下版面結構不變。驗證：實機將字級調至最大無障礙級距檢視總覽頁，確認無截斷且已降為單欄；再切回標準字級確認版面與變更前一致。
- [ ] 2.2 [P] 讓 OrderRowView 在無障礙字級下把右欄的狀態與金額改置於左欄下方，標準字級維持三欄橫排。滿足 Layouts change structure at accessibility text sizes。行為：大字級下狀態與金額不再被擠壓到極窄寬度。驗證：實機於最大無障礙字級檢視訂單列表確認已改為堆疊，標準字級下確認排列未變。
- [x] 2.3 [P] 依決策〈固定點數的尺寸改為隨字級縮放的度量〉，將 InsightsView 熱力圖的星期欄寬與格高改為隨字級縮放 (格高需由型別層級常數改為實例屬性)，並將 BLDonutChart 直徑改為隨字級縮放、中央文字併用單行限制與縮放係數作為次要防線。滿足 Fixed point dimensions scale with text size。行為：大字級下星期標籤與格內數字不被裁切，圈狀圖中央文字不溢出內圈。驗證：實機於最大無障礙字級檢視分析頁熱力圖與圈狀圖確認無裁切與溢出。
- [x] 2.4 [P] 將 RootSidebarLayout、DashboardView、MergePhotoPickerSheet、BLPhotoThumbnail、BLAvatar 五處寫死的字級點數改為綁定文字樣式或隨字級縮放的度量。滿足 Fixed point dimensions scale with text size。行為：這五處的文字與圖示隨系統字級設定縮放。驗證：實機切換字級前後逐一比對五處確認尺寸有變化。

## 3. 複合元素合併

- [x] 3.1 [P] 依決策〈複合列以合併子元素的方式成為單一朗讀單位〉，將 OrderRowView、CampaignListView 的開團列、DashboardView 與 OrderDetailView 的關鍵指標格各自合併為單一無障礙元素，合併前先排除指標格內的裝飾色點。滿足 Composite rows are announced as a single unit 與 Decorative and duplicated elements are excluded。行為：輔助技術一次朗讀完整列，裝飾色點不貢獻朗讀內容。驗證：實機開啟輔助技術逐一走過訂單列表、開團列表與總覽頁指標區，確認各為單一停留點且朗讀順序符合版面順序；實際聆聽完整一列確認長度可接受。
- [x] 3.2 [P] 依決策〈頭像在與姓名同列時排除於無障礙樹〉，為 BLAvatar 新增表示僅作裝飾的參數 (預設為否)，並讓 OrderRowView 傳入該旗標。滿足 Decorative and duplicated elements are excluded。行為：訂單列的客戶姓名只被朗讀一次，頭像獨立出現時仍朗讀姓名。驗證：實機以輔助技術確認訂單列姓名不重複；並確認其他頭像呼叫點的朗讀行為未變。

## 4. 熱力圖無障礙

- [x] 4.1 依決策〈熱力圖格子標籤補座標，零值格子排除，整圖提供摘要〉，讓 InsightsView 熱力圖的非零格子朗讀出星期與週次位置及筆數、零值格子排除於無障礙樹外、整張圖提供涵蓋週數的摘要。滿足 Grid cells convey their position。行為：輔助技術不再朗讀出七十次無位置的數字。驗證：實機以輔助技術聚焦熱力圖，確認非零格子含位置、零值格子被略過、整圖有摘要。

## 5. 動態效果偏好

- [x] 5.1 依決策〈減少動態效果以環境值判斷並在動畫來源處統一處理〉，讓 BLButtonStyle 讀取減少動態效果偏好並於啟用時不套用動畫。滿足 Animations honor the reduce motion preference。行為：開啟減少動態效果後按壓回饋無動畫，關閉時表現與變更前一致。驗證：實機於系統設定開關該偏好前後各按一次按鈕確認差異。

## 6. 收尾與驗收

- [x] 6.1 將本次新增的熱力圖位置描述與圖表摘要等無障礙字串補進 Localizable.xcstrings 的中英值，採文字插入方式而非全量重新序列化。行為：英文模式不露出中文 fallback。驗證：LocalizationCatalogTests 通過，並人工確認新增字串確實已收錄。
- [x] 6.2 重錄受版面變更影響的 snapshot baseline，並確認標準字級下的版面未意外偏移。行為：baseline 與新實作一致。驗證：snapshot 測試全綠；因 baseline 於標準字級錄製、不涵蓋大字級成果，另以第 2 組任務的實機大字級檢視作為主要驗收手段。
- [x] 6.3 依文件同步鐵則檢視本次 diff：將「無障礙字級下版面降維而非以縮放係數抵銷」、「複合列須合併為單一朗讀單位」與「新增動畫一律先過減少動態效果判斷」寫入 apps/ios/CLAUDE.md 對應章節。行為：後續實作者不需重新推導這三條規則。驗證：對照根目錄 CLAUDE.md 的文件同步表逐列確認，結論為「有影響，已同步」或「確認無文件影響」。
