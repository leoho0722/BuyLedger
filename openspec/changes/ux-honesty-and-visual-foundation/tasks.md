## 1. 前置確認

- [x] 1.1 確認 hig-blocker-remediation 的語意色分軌與色彩資源已落地，且其對比測試基礎設施可供本 change 沿用。行為：色盤改動建立在既有成果之上而非與其衝突。驗證：檢視 BLTone 已提供分軌方法且對比測試 helper 存在可呼叫；若尚未落地則暫緩第 3 與第 4 組任務。

## 2. 內容誠實

- [x] 2.1 [P] 依決策〈無可用匯率時以空狀態取代零值，而非顯示零〉，讓 QuoteView 在無可用匯率時把建議售價與預估獲利顯示為破折號、成本拆解整卡改為說明無法試算的空狀態、不繪製零值進度條，作法比照 FxView 對無資料的既有處理。滿足 Absent data is presented as absent, not as zero。行為：畫面上不出現看似計算結果的零值金額。驗證：實機於無可用匯率情境開啟報價試算確認無零值金額與零值進度條；並確認有匯率時計算結果與變更前一致。
- [x] 2.2 [P] 依決策〈錯誤文案改用使用者語彙，診斷資訊改走記錄〉，將 AISummaryFeature 面向使用者的錯誤訊息改為不含環境變數名稱與建置期識別碼的描述，診斷細節改走記錄。滿足 User-facing errors use user vocabulary。行為：使用者看到的訊息描述狀態與可行的下一步。驗證：實機觸發服務未設定與金鑰無效兩種失敗，確認訊息不含識別碼。
- [x] 2.3 [P] 依決策〈首次載入改以骨架呈現〉，讓 DashboardView 與 InsightsView 以既有版面結構渲染骨架並套用佔位效果，轉圈降為逾一兩秒後才疊加。滿足 Initial loading presents a structural skeleton。行為：冷啟動先見骨架、內容就緒時版面不跳動。驗證：實機反覆冷啟動觀察兩頁的銜接是否平順且無跳動。
- [x] 2.4 [P] 為 FxView 的載入失敗補上重試入口，行為與 AISummaryView 既有的失敗呈現一致。滿足 Failed loads offer a retry path within the screen。行為：失敗時可於畫面內重試並在成功後顯示內容。驗證：實機使匯率載入失敗確認重試入口存在，啟用後可恢復內容。

## 3. 色彩來源收斂

- [x] 3.1 依決策〈色盤語意色改走系統取色介面〉，將 BLPalette 的語意色與系統色改走系統取色介面，移除亮暗兩套手抄值分支與外觀判斷屬性，並讓取色不再需要外觀參數。滿足 Semantic and system colors are obtained through system APIs。行為：色彩隨系統版本、增強對比與 vibrancy 自動調整，色盤實作不再有外觀分支。驗證：實機於增強對比開啟與關閉兩種狀態瀏覽主要畫面確認色彩隨設定調整；檢視色盤實作確認無外觀分支與外觀參數。
- [x] 3.2 依決策〈強調色以資源檔為單一來源並於根層設定〉，補齊強調色資源檔的亮暗外觀與增強對比變體，讓 BLPalette 的強調色引用它，並於 RootView 統一設定色調。滿足 Accent color has a single source。行為：系統元件與自訂元件取用同一個強調色。驗證：實機於同一畫面比對系統元件與自訂元件的強調色一致；檢視資源檔確認變體齊備。
- [x] 3.3 依決策〈主卡層級改以字重與字級表達，並調整漸層使白字達標〉，移除 DashboardView 主卡各段文字的不透明度降階、層級改以字重與字級表達，並降低漸層兩端亮度使純白文字達標。滿足 Visual hierarchy is not expressed by reducing opacity of text。行為：主卡文字全為不透明且各段對其底色達 4.5:1，圖形元素達 3:1。驗證：沿用 hig-blocker-remediation 的對比測試基礎設施，將主卡標籤、差額、分隔點、目標進度文字與走勢圖線條納入斷言並確認全數達標，且漸層兩端各自驗過。

## 4. 材質與 bar

- [x] 4.1 [P] 依決策〈手工模仿玻璃的色盤項目直接刪除〉，移除 BLPalette 中無呼叫端、以半透明色模仿玻璃材質的兩個項目。滿足 Materials are not imitated with translucent color values。行為：色盤不再提供會被誤用的假材質色。驗證：全專案搜尋確認無殘留呼叫；iOS 與 iPadOS 皆建置成功 (build 前先於 apps/ios 執行 agvtool next-version 遞增 build number)。
- [x] 4.2 依決策〈自繪標題列改由系統承載〉，讓 OrdersView 訂單詳情的自繪標題列改由系統標題列承載其標題與選單；若與既有並排結構衝突則改為移除實色底與分隔線並採用系統材質，兩者皆須使捲動內容延伸至其下方。滿足 Bars are not imitated with opaque backgrounds。行為：捲動內容不再於標題列邊緣停住，且不存在兩層堆疊的標題列。驗證：實機捲動訂單詳情確認內容延伸至標題列下方；若採用替代路徑則於本 change 目錄記錄原因。

## 5. 尊重系統設定

- [x] 5.1 [P] 依決策〈移除 App 內外觀切換〉，移除設定頁的外觀區塊、AppearancePreference 型別、RootView 的外觀覆寫，以及功能狀態、快照型別與偏好儲存中的對應欄位。滿足 System-level settings are not duplicated in the app。行為：App 外觀跟隨系統，設定頁無外觀控制項。驗證：實機切換系統外觀確認 App 隨之改變；以既有偏好資料啟動確認其餘設定值未被連帶重置。
- [x] 5.2 [P] 依決策〈權限提示補上前往系統設定〉，為 CampaignFeature 的行事曆權限被拒提示加入前往系統設定的按鈕，開啟能力以可注入的相依項提供，並確保無法開啟時提示仍可關閉。滿足 Prompts directing users to system settings provide a way there。行為：使用者可從提示直接前往本 App 的系統設定頁。驗證：以 TestStore 搭配替身斷言按鈕觸發開啟設定的相依項；實機於權限被拒時確認按鈕可正確開啟。

## 6. 收尾與驗收

- [x] 6.1 將本次新增的空狀態文案、重試按鈕、AI 錯誤訊息與前往設定按鈕等字串補進 Localizable.xcstrings 的中英值，採文字插入方式而非全量重新序列化。行為：英文模式不露出中文 fallback。驗證：LocalizationCatalogTests 通過，並人工確認新增字串確實已收錄。
- [x] 6.2 全面重錄 snapshot baseline，重錄前逐張檢視差異確認變化僅來自色彩來源變更而非版面位移；本項與其他任務分開提交以便必要時單獨回退。行為：baseline 與新色彩來源一致。驗證：snapshot 測試全綠，差異檢視結論記錄於 commit 說明。
- [x] 6.3 依文件同步鐵則檢視本次 diff：將「語意色一律走系統取色介面、不手抄十六進位值」、「層級不以不透明度降階表達」與「不以實色模仿系統 bar、不以半透明色模仿材質」寫入 apps/ios/CLAUDE.md 對應章節，並移除該檔中因外觀切換移除而失效的描述。行為：文件無與現況矛盾的內容。驗證：對照根目錄 CLAUDE.md 的文件同步表逐列確認，結論為「有影響，已同步」或「確認無文件影響」。
