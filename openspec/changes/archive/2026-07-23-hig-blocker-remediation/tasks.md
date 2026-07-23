## 1. 對比度驗證基礎設施 (TDD 先行)

- [x] 1.1 建立可在單元測試中計算 WCAG 相對亮度與對比比值的 test helper，能接受 SwiftUI Color 與明確的合成底色、回傳對比比值，並支援指定 light / dark / increased contrast 三種 trait 情境解析色值。行為：測試程式碼可對任一組前景與背景色斷言其對比比值。驗證：新增的 helper 自帶對照案例 (已知的黑白 21:1、以及審查報告列出的 success 1.98:1) 皆通過。
- [x] 1.2 針對 Informational text meets the 4.5:1 contrast floor 撰寫涵蓋六個 tone 的膠囊文字、計數徽章數字、客戶排名徽章三種名次分支、熱力圖各深度級數、頭像至少八個代表色相的對比測試，於 light、dark 與 increased contrast 下各斷言文字達 4.5:1、純圖形元素達 3:1。行為：對比不達標會使測試失敗而非只能靠目測。驗證：此時測試應為 red (依審查報告，至少 success / warning / destructive / accent 四個 tone 與頭像、排名徽章、熱力圖失敗)，並在後續任務逐一轉綠。

## 2. BLTone 三軌拆分與色彩資源

- [x] 2.1 依決策〈色值來源改為 asset catalog Color Set，取代程式碼內的透明度推導〉，在 asset catalog 為六個 tone 各建立 surface text、soft background、indicator、on-indicator 四組具名 Color Set，每組定義 Any 與 Dark 外觀並附 High Contrast variant，色值以 1.1 的 helper 反覆試算至達標。滿足 Tone colors are defined as named asset catalog resources。行為：色彩查詢改由具名資源提供。驗證：1.2 中屬於膠囊文字與計數徽章的斷言轉綠。
- [x] 2.2 依決策〈語意色拆成 onSurface、indicator、onIndicator 三軌並移除 foreground〉，讓 BLTone 提供 onSurface、indicator、onIndicator、background 四個方法並移除 foreground，各自讀取 2.1 的具名資源。滿足 Semantic tones expose separate text and graphic colors。行為：文字色與圖形色在型別層面不再共用同一個值。驗證：全專案搜尋不到 foreground 呼叫；移除後所有既有呼叫點皆編譯失敗，作為 2.3 的遷移清單。
- [x] 2.3 將 BLStatusPill 與 BLBadge 的呼叫點依「這個色彩最終疊在什麼底色上」逐一遷移到正確軌道：膠囊文字與 label 徽章文字走 onSurface、狀態色點走 indicator、計數徽章底色走 indicator 且其數字走 onIndicator。行為：狀態膠囊與徽章在六個 tone 下文字皆可讀，色點維持既有鮮度。驗證：iOS 與 iPadOS 皆建置成功 (build 前先於 apps/ios 執行 agvtool next-version 遞增 build number)，且 1.2 相關斷言全綠。

## 3. 其餘對比缺口

- [x] 3.1 [P] 依決策〈頭像維持色相演算法並壓低明度〉調整 BLAvatar 生成漸層的飽和度與明度，色相推導邏輯不變，使任意色相下白色縮寫達 4.5:1。滿足 Avatar initials remain legible across all generated hues。行為：每位客戶仍有專屬且互異的色相，縮寫在所有色相下可讀。驗證：1.2 中頭像各代表色相的斷言轉綠，且針對兩個不同名稱的色相互異性測試維持通過。
- [x] 3.2 [P] 修正 CustomersView 排名徽章：白字僅保留給實測達標的深底，rank 3 以後改以次要標籤色作前景並保留系統填色底，rank 1 底色改用達標的具名色彩資源。行為：三種名次分支的徽章數字皆可讀。驗證：1.2 中排名徽章三個分支的斷言轉綠。
- [x] 3.3 [P] 依決策〈熱力圖改用離散深度階梯，底色與前景色成對定義〉，將 InsightsView 熱力圖的連續 opacity 階梯改為五級離散深度，每級的底色與數字色在 asset catalog 內成對定義。滿足 Heatmap cells use discrete depth levels with paired colors。行為：最淺與最深的格子在兩種外觀下數字皆可讀，相鄰密度級數視覺可辨。驗證：1.2 中五個深度級數的斷言轉綠。
- [x] 3.4 [P] 將被誤用於承載資訊文字的 tertiaryLabel 呼叫點改為 secondaryLabel，涵蓋 CustomersView 區段標題、FxView 與 QuoteView 的單位與說明、InsightsView 與 OrderDetailView 的輔助文字、BLBarChart 軸標籤、RootSidebarLayout 的次要文字；tertiaryLabel 僅保留給停用態與 placeholder。滿足 Tertiary label color is reserved for non-informational text。行為：這些文字達 4.5:1。驗證：新增針對軸標籤與區段標題的對比斷言並確認通過。

## 4. 圖表無障礙

- [x] 4.1 [P] 為 BLBarChart 的每個 BarMark 補上名稱與數值的無障礙描述，並提供圖表層級摘要。滿足 Chart data points are announced with name and value。行為：VoiceOver 逐一聚焦長條時朗讀出期間與金額。驗證：實機開啟 VoiceOver 聚焦長條圖確認朗讀內容；資料為空時摘要描述無資料而非朗讀零值。
- [x] 4.2 [P] 依決策〈圈狀圖以類別維度驅動配色，取代直接指定色彩〉，讓 BLDonutChart 的 SectorMark 改以區段名稱作為 foregroundStyle 的類別維度，並以樣式對應表保住現有配色，同時補上區段的數值描述與圖表摘要。滿足 Donut segments carry category identity through the chart framework。行為：區段名稱進入無障礙樹，各類別顏色與變更前一致。驗證：實機以 VoiceOver 確認每個區段朗讀出類別名稱與金額；目視比對變更前後配色未改變。
- [x] 4.3 [P] 為 BLSparkline 補上趨勢摘要描述，或在確認其資訊已由相鄰文字完整呈現時明確標記為對輔助技術隱藏，兩者擇一但不得維持現狀。滿足 Every chart provides a summary for assistive technology。行為：走勢圖不再是既無標籤也未隱藏的空白區域。驗證：實機以 VoiceOver 在 Dashboard hero 卡上確認走勢圖要嘛朗讀摘要、要嘛被正確跳過。

## 5. 命中區

- [x] 5.1 [P] 依決策〈命中區以固定尺寸框加形狀宣告撐開，視覺尺寸不變〉，將 BLPhotoThumbnail 刪除鈕的尺寸與形狀宣告移入按鈕標籤內部使命中區達 44×44pt，並以位移維持既有的貼齊角落外觀。滿足 Tappable controls provide a 44 point minimum hit region 與 Destructive controls are not undersized。行為：刪除鈕可靠地被點中，圖示視覺尺寸與縮圖版面不變。驗證：實機以 Accessibility Inspector 量測命中區不小於 44×44pt，並確認點擊縮圖本體仍開啟照片檢視器。
- [x] 5.2 [P] 確認 BLSearchField 清除鈕的命中區缺口將由後續 change design-system-component-reduction 以系統 .searchable 取代整個自製搜尋欄來解除，本 change 不修改該元件以免對即將移除的程式碼做白工。滿足 Tappable controls provide a 44 point minimum hit region 於本 change 範圍內的部分。行為：命中區契約已載入 spec 並涵蓋此元件，實際落地由取代 change 完成。驗證：確認 design-system-component-reduction 的任務清單含有以 .searchable 取代 BLSearchField 的項目，且該 change 的驗收包含系統搜尋列的命中區確認。

## 6. 狀態誠實性

- [x] 6.1 [P] 依決策〈通知區塊連同偏好欄位一併移除〉，移除設定頁的通知區塊與開關，並清除 SettingsFeature.State、SettingsSnapshot 與 SettingsStorage 的對應欄位。滿足 Controls without backing behavior are not presented。行為：設定頁不再出現無實作支撐的提醒開關，且程式碼中不留下會被誤認為功能存在的欄位。驗證：既有 Settings 相關單元測試調整後通過；以既有偏好資料啟動確認其餘設定值未被連帶重置。
- [x] 6.2 [P] 依決策〈載入狀態機補上失敗分支，不讓已載入旗標兼職〉，讓 DashboardView 與 InsightsView 改為已載入 / 有錯誤 / 載入中三分支，失敗時顯示帶有錯誤訊息的失敗狀態與重試控制項，重試沿用訂單功能既有的載入動作、不新增狀態欄位。滿足 Load failure is surfaced with a reason and a recovery path。行為：訂單載入失敗時兩頁顯示原因與重試而非無限轉圈；重試成功恢復內容，再次失敗不進入自動重試迴圈。驗證：以注入失敗的 repository 撰寫 TestStore 測試涵蓋三種狀態解析，並手動確認畫面表現。
- [x] 6.3 [P] 依決策〈行事曆錯誤拆成權限被拒與建立失敗兩條路徑〉，讓 CampaignFeature 以權限請求回傳值決定路徑：僅在存取未獲授權時走既有權限說明，事件儲存失敗、識別碼缺失與連結寫入失敗改送新增的建立失敗動作且訊息不提權限，失敗時不留下部分寫入的連結。滿足 Calendar access is requested lazily and denial is surfaced、Reminder creation failure is reported distinctly from permission denial 與 Error messages describe the actual failure。行為：權限已授予時的失敗不再要求使用者去改權限，訊息描述真正發生的失敗。驗證：以 TestStore 撰寫涵蓋四種失敗條件的測試 (權限未授予、事件儲存拋錯、識別碼缺失、連結寫入拋錯) 斷言各自的訊息與連結狀態；並確認移除不存在事件仍為無操作、不報錯。

## 7. 收尾與驗收

- [x] 7.1 將本次新增的失敗訊息、重試按鈕與圖表無障礙描述等字串補進 Localizable.xcstrings 的中英值，採文字插入方式而非全量重新序列化。行為：英文模式不露出中文 fallback。驗證：LocalizationCatalogTests 通過，並人工確認新增字串確實已收錄進 catalog。
- [x] 7.2 重錄受配色變更影響的 snapshot baseline，重錄前逐張檢視差異確認變化僅來自配色而非版面。行為：baseline 與新配色一致且未掩蓋非預期的版面變化。驗證：snapshot 測試全綠，且差異檢視結論記錄於 commit 說明。
- [x] 7.3 依文件同步鐵則檢視本次 diff：將「語意色分軌後該用哪一軌」與「命中區須加在按鈕標籤內部而非外層容器」寫入 apps/ios/CLAUDE.md 的程式風格或 Design System 準則一節。行為：後續實作者不需重新推導這兩條規則。驗證：對照根目錄 CLAUDE.md 的文件同步表逐列確認，結論為「有影響，已同步」或「確認無文件影響」。
- [x] 7.4 於實體 iPhone 執行完整驗收：以 Accessibility Inspector 的對比檢查覆核六個 tone 的膠囊、計數徽章、排名徽章三種名次、頭像至少三個代表色相、熱力圖五個級數於 light / dark / increased contrast 下皆通過；以 VoiceOver 逐一確認三個圖表；量測兩個關閉鈕命中區；並確認設定頁無通知區塊、載入失敗有重試、行事曆建立失敗訊息不提權限。行為：12 項 blocker 在真實裝置上均已解除。驗證：逐項對照 design.md 的驗收標準一節，全數通過後方可標記 change 完成。
