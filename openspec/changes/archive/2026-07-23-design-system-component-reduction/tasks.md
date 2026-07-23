## 1. 低風險元件取代

- [x] 1.1 [P] 依決策〈分段控制元件直接刪除〉移除零呼叫點的 BLSegmentedControl 原始檔，確認既有的互斥視圖切換皆使用系統分段選擇器。滿足 System-provided capabilities are not reimplemented。行為：Design System 目錄不再提供有缺陷的分段控制供後續採用。驗證：全專案搜尋不到該型別；iOS 與 iPadOS 皆建置成功 (build 前先於 apps/ios 執行 agvtool next-version 遞增 build number)。
- [x] 1.2 [P] 依決策〈進度條改用系統進度視圖並保留既有版面〉，讓 BLProgressBar 內部改以系統進度視圖實作、對外呼叫形狀不變，並保留既有的進度值範圍限制邏輯。滿足 System-provided capabilities are not reimplemented 與 Replaced components restore the behaviors their hand-built versions lacked。行為：六個呼叫點視覺結果與變更前一致，且輔助技術可播報進度值。驗證：實機以 VoiceOver 聚焦 Dashboard 與 CampaignListView 的進度條確認播報包含進度值；snapshot 差異逐張比對確認僅系統樣式細微差別。
- [x] 1.3 [P] 依決策〈設定頁 disclosure row 改用系統元件〉，將 SettingsView 兩處手繪的可點擊列改用系統元件呈現，取回列的按壓 highlight 與原生 disclosure indicator。滿足 Replaced components restore the behaviors their hand-built versions lacked。行為：這兩列按下時有 highlight，指示符號與系統一致。驗證：實機確認按壓回饋存在，且與同頁其他系統元件的列外觀一致。

## 2. 搜尋欄取代

- [x] 2.1 依決策〈搜尋欄改用系統搜尋呈現並刪除自製元件〉，將 OrdersCompactView 與 OrdersView 的搜尋改用系統搜尋呈現，並移除 BLSearchField 原始檔。滿足 System-provided capabilities are not reimplemented 與 Replaced components restore the behaviors their hand-built versions lacked。行為：搜尋列具備 Cancel 鈕、Search return 鍵、聽寫與捲動收合展開，清除控制項命中區符合系統標準。驗證：實機逐一確認上述四項行為；並確認 hig-blocker-remediation 記錄的清除鈕命中區缺口已因元件移除而解除。
- [x] 2.2 讓取消搜尋時 OrdersFeature 的過濾狀態正確重置為未過濾。滿足 Search state remains consistent when search is cancelled。行為：使用者取消搜尋後看到完整訂單列表，而非停留在已過濾結果。驗證：以 TestStore 撰寫「輸入查詢後取消」的測試，斷言查詢字串清空且過濾結果為完整集合。

## 3. 互動回饋補齊

- [x] 3.1 [P] 依決策〈自訂按鈕樣式讀取啟用狀態〉，讓 BLButtonStyle 讀取環境中的啟用狀態並於停用時呈現可辨識的視覺差異，啟用態外觀維持不變。滿足 Custom controls express disabled state visually。行為：停用的按鈕不再與可用態外觀相同。驗證：以 Dashboard onboarding 的主要按鈕在停用與啟用兩種狀態下目視比對；並確認既有按壓態表現未改變。
- [x] 3.2 [P] 依決策〈破壞性動作改以按鈕角色表達〉，移除 BLButtonStyle 的破壞性變體，並將受影響的呼叫端改以系統按鈕角色標註。滿足 Destructive actions are expressed through button role。行為：破壞性按鈕由系統呈現顏色並被輔助技術播報為破壞性。驗證：全專案搜尋不到原變體名稱；實機以 VoiceOver 確認播報含破壞性語意，並目視確認每個受影響按鈕仍為系統紅色。
- [x] 3.3 [P] 依決策〈照片縮圖的點擊改用按鈕〉，將 BLPhotoThumbnail 的點擊手勢改為按鈕實作。滿足 Custom tappable elements provide press feedback。行為：縮圖按下時有視覺回饋，且可由 switch control 與外接鍵盤啟用。驗證：實機確認按壓態；以 switch control 啟用縮圖確認照片檢視器開啟。

## 4. 訂單列表列回收

- [x] 4.1 依決策〈維持自製分組結構，但以惰性容器承擔列回收責任〉，將 OrdersCompactView 中承載日期區段的容器 (listSection 內包住 sections 迴圈的那一層) 改為惰性垂直容器；BLCard 內單一日期區段的訂單列容器維持非惰性，以免卡片的圓角背景與描邊畫不完整。滿足 Deliberately retained hand-built structures provide the behaviors they forgo。行為：區段在接近視野前不被建構，呈現成本不隨訂單筆數線性增長，且卡片背景仍完整包住當日所有列。驗證：以數百筆、橫跨多個日期的訂單資料集捲動列表，確認初次呈現時間不隨筆數明顯增長；捲動至列表深處確認卡片圓角、描邊與背景完整無缺口。

## 5. 收尾與驗收

- [x] 5.1 將本次因系統元件取代而新增或變更的字串補進 Localizable.xcstrings 的中英值，採文字插入方式而非全量重新序列化。行為：英文模式不露出中文 fallback。驗證：LocalizationCatalogTests 通過，並人工確認新增字串確實已收錄。
- [x] 5.2 重錄受版面變更影響的 snapshot baseline，重錄前逐張檢視差異確認變化僅來自元件取代而非非預期的版面錯位。行為：baseline 與新實作一致。驗證：snapshot 測試全綠，差異檢視結論記錄於 commit 說明。
- [x] 5.3 依文件同步鐵則檢視本次 diff：將「系統已提供的能力不得重造」與「破壞性以按鈕角色而非視覺樣式表達」寫入 apps/ios/CLAUDE.md 的 Design System 準則一節，並移除該檔中任何因元件刪除而失效的描述。行為：後續實作者不需重新推導這兩條規則，且文件無與現況矛盾的內容。驗證：對照根目錄 CLAUDE.md 的文件同步表逐列確認，結論為「有影響，已同步」或「確認無文件影響」。
