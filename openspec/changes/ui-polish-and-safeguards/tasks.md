## 1. 不可逆動作與未提交變更

- [x] 1.1 [P] 依決策〈結團結算比照既有的刪除確認實作〉，為 CampaignFeature 加入結團確認的警示狀態，文案說明結團後無法復原，確認後才寫入結算日期。滿足 Irreversible state transitions require confirmation。行為：按下結團出現確認，取消則不寫入任何資料。驗證：以 TestStore 斷言確認前不寫入結算日期、取消後開團仍為未結團且結團動作仍可用；實機操作一次確認流程。
- [x] 1.2 [P] 依決策〈篩選 sheet 的未提交變更防護比照付款方式編輯器〉，讓 OrderFilterSheet 以三個 pending 值與其提交後現值的比對得出髒值判斷，有未提交變更時阻擋下滑關閉、取消時彈出捨棄確認。滿足 Sheets holding uncommitted changes resist accidental dismissal。行為：有變更時下滑不關閉、取消會確認；無變更時下滑正常關閉。驗證：實機分別於有變更與無變更兩種狀態測試下滑與取消。
- [x] 1.3 [P] 讓 OptionPickerSheet 的多選分支在非嵌入模式提供取消動作，嵌入模式維持僅由宿主 Back 承接、不新增重複的取消。滿足 Multi-selection pickers offer a way out that is not completion。行為：獨立呈現的多選選擇器同時有取消與完成，嵌入時只有 Back。驗證：以元件預覽分別呈現嵌入與非嵌入兩種模式確認按鈕組合正確。

## 2. 輔助技術朗讀清理

- [x] 2.1 [P] 依決策〈列尾指示符號一律排除於無障礙樹〉，將 InsightsView、SettingsView、QuoteView、FxView 與 OrderEditView 中位於按鈕標籤內的列尾指示符號一律排除於無障礙樹外。滿足 Decorative indicators are excluded from announcements。行為：輔助技術朗讀這些列時不再帶出符號名稱。驗證：實機以輔助技術逐一聚焦上述畫面的列，確認朗讀內容為列內容加按鈕特徵、不含符號名稱。
- [x] 2.2 [P] 將 DashboardView 引導畫面的裝飾插圖排除於無障礙樹外。滿足 Decorative indicators are excluded from announcements。行為：輔助技術遍歷空狀態時跳過插圖而非朗讀其符號名稱。驗證：實機於無訂單狀態以輔助技術遍歷總覽頁確認插圖被跳過。
- [x] 2.3 [P] 讓 OrderFilterSheet 各區塊的選取列以標準選取特徵表達選取態，並將條件顯示的勾選符號排除於朗讀外。滿足 Selection state is expressed through the standard trait。行為：選取列被輔助技術與切換控制識別為已選取，勾選符號不產生獨立朗讀。驗證：實機以輔助技術聚焦已選取的篩選列確認被朗讀為已選取；以切換控制確認可識別選取狀態。

## 3. Design System 清理

- [x] 3.1 依決策〈分隔線內縮與頭像尺寸抽成同源 token〉，在 BLMetrics 新增頭像尺寸與分隔線內縮兩個 token (後者由前者推導)，並讓 DashboardView、OrdersView、OrdersCompactView、CustomersView 四處分隔線與 BLAvatar 的預設尺寸皆引用之。滿足 Dimensions shared across files derive from a single source。行為：改動頭像尺寸時四處分隔線自動維持對齊。驗證：全專案搜尋確認無殘留的手算式；實機目視確認四處分隔線與頭像右緣對齊；並在 dynamic-type-and-grouping 的頭像任務落地後複驗一次對齊。
- [ ] 3.2 [P] 讓 BLStatusPill 與 BLBadge 的內距與狀態點尺寸改為隨字級縮放。滿足 Component padding and indicators scale with text size。行為：大字級下膠囊隨內容長大而非壓縮文字，狀態點維持比例。驗證：實機於最大無障礙字級檢視訂單列與開團列的狀態膠囊，確認內距擴大且文字未貼邊。
- [x] 3.3 [P] 移除 BLTypographyModifier 中的零寬字距設定，讓系統字型的光學字距生效；並刪除零呼叫點的 BLListRow 與 BLAmountField 兩個元件。滿足 Ineffective and unreferenced code is removed。行為：大字級標題的字距回歸系統光學值；Design System 不再提供這兩個會被誤用的元件。驗證：全專案搜尋確認兩個型別無殘留呼叫；iOS 與 iPadOS 皆建置成功 (build 前先於 apps/ios 執行 agvtool next-version 遞增 build number)。

## 4. 一致性與可用性

- [x] 4.1 [P] 讓 CampaignDetailView 的導覽標題固定為通用的「開團詳情」，團名由開團資訊區段承載。滿足 The campaign detail keeps a generic title (原「標題顯示團名」經實機驗收判定不符實際需求，已修正提案)。行為：標題恆為通用名稱，團名顯示於內容區。驗證：實機進入開團詳情確認標題為「開團詳情」且資訊區段首列為團名。
- [x] 4.2 [P] 依決策〈採購狀態改用資訊語意色〉，將 OrderStatus+Presentation 中採購完成狀態的語意色由警示改為資訊，其餘映射不變。滿足 Status colors match the meaning of the status。行為：採購完成不再被塗成警示色，真正需要注意的部分到貨狀態維持警示色。驗證：實機檢視兩種狀態的膠囊確認色彩符合語意。
- [x] 4.3 [P] 將 OrdersFeature 與 CampaignFeature 的刪除確認文案改為主動語態並移除內部識別碼，訂單改以客戶名稱指稱。滿足 Confirmation messages are written for the user。行為：確認訊息不含識別碼且語句自然。驗證：實機觸發訂單與開團刪除確認，確認文案無識別碼。
- [x] 4.4 [P] 依決策〈分頁選擇的恢復以既有偏好儲存承載〉，讓 RootFeature 於啟動時自偏好儲存還原上次的分頁選擇，切換分頁時寫入；不恢復導覽堆疊與捲動位置。滿足 The app reopens on the tab last used。行為：重啟後回到上次分頁，首次啟動使用預設分頁。驗證：以 TestStore 斷言啟動時讀取與切換時寫入；實機切到訂單分頁後終止並重啟確認回到訂單分頁；並以既有偏好資料啟動確認其他設定未被重置。
- [x] 4.5 [P] 依決策〈空狀態改以容器相對定位置中〉，讓 CustomersView 與 OrdersCompactView 的空狀態垂直置中於可視區域，作法比照 InsightsView 既有的正確實作。滿足 Empty states center within their visible area。行為：空狀態不再貼頂而使下半留白。驗證：實機於無資料狀態檢視兩個畫面確認置中。
- [x] 4.6 [P] 將 BLPhotoViewer 的關閉動作改置於取消位置，不佔用主要動作位置。滿足 Dismissal is not placed in the primary action position。行為：關閉控制項位於取消位置，既有的鍵盤快捷鍵維持可用。驗證：實機開啟照片檢視器確認關閉鈕位置，並以外接鍵盤確認快捷鍵仍可關閉。

## 5. 收鍵盤手勢的失效可見化

- [x] 5.1 依決策〈收鍵盤手勢補回歸測試，而非改寫過濾機制〉，新增介面測試：於文字欄位進入選取狀態後點擊系統文字選單，斷言鍵盤不收起；並將手勢的同時辨識判斷由無條件放行收窄為僅對已知的捲動類辨識器放行。滿足 Mechanisms depending on non-public identifiers are covered by regression tests。行為：iOS 改名導致過濾失效時測試會失敗而非靜默退化；捲動時鍵盤仍正常收起。此測試斷言的是行為而非實作，將於後續 change keyboard-dismissal-native-rewrite 把手勢改寫為背景層點擊後繼續作為其驗證基準，因此撰寫時不得依賴現行實作的內部細節。驗證：新增的介面測試通過；實機於各主要捲動畫面確認捲動仍會收鍵盤。

## 6. 收尾與驗收

- [x] 6.1 將本次新增的結團確認、捨棄確認與取消動作等字串補進 Localizable.xcstrings 的中英值，並同步更新改寫後的刪除確認文案，採文字插入方式而非全量重新序列化。行為：英文模式不露出中文 fallback。驗證：LocalizationCatalogTests 通過，並人工確認新增與改寫的字串確實已收錄。
- [x] 6.2 重錄受膠囊內距與狀態色變更影響的 snapshot baseline，重錄前逐張檢視差異確認變化符合預期。行為：baseline 與新實作一致。驗證：snapshot 測試全綠，差異檢視結論記錄於 commit 說明。
- [x] 6.3 依文件同步鐵則檢視本次 diff：將「跨檔案共用的尺寸須由單一來源推導」與「不可逆的狀態轉換比照刪除加確認」寫入 apps/ios/CLAUDE.md 對應章節，並移除該檔中因元件刪除而失效的描述。行為：文件無與現況矛盾的內容。驗證：對照根目錄 CLAUDE.md 的文件同步表逐列確認，結論為「有影響，已同步」或「確認無文件影響」。
