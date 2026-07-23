# 文件一致性稽核筆記

稽核自 2026-07-21 的 `main`（commit `9c15ae4`），涵蓋前八個 change 落地後的
`apps/ios/CLAUDE.md`、`apps/ios/README.md`、根目錄兩檔與全部手寫原始碼註解。

## 一、各 change 文件宣告的核對結果

逐一取出前八個 change 文件同步任務宣告的規則，核對其落地位置：

| Change | 宣告寫入的規則 | 落地位置 | 結果 |
|--------|----------------|----------|------|
| hig-blocker-remediation | 語意色分軌判準、命中區宣告在標籤內部 | `CLAUDE.md` Design System 準則 | ✓ 已落地 |
| design-system-component-reduction | 系統能力不得重造、破壞性以 role 表達；移除失效描述 | `CLAUDE.md` Design System 準則；`BLSegmentedControl`／`BLSearchField` 引用已清 | ✓ 已落地 |
| touch-target-and-input | 命中區形狀用元件自身形狀、焦點狀態下放 Feature.State | `CLAUDE.md` 命中區 sub-bullet、「焦點與鍵盤」節 | ✓ 已落地 |
| navigation-integrity | 單一路徑、選取單一來源、單層 modal、alert 不裝表單、先寫後改；更正 bottomBar 描述 | `CLAUDE.md`「導覽與呈現」節 | ✓ 已落地 |
| dynamic-type-and-grouping | 大字級降維、複合列合併、動畫過減少動態判斷 | `CLAUDE.md`「Dynamic Type 與無障礙」節 | ✓ 已落地 |
| ui-polish-and-safeguards | 尺寸單一來源推導、不可逆轉換加確認；清 `BLAmountField` 失效引用 | `CLAUDE.md` Design System 準則與「導覽與呈現」節 | ✓ 已落地 |
| keyboard-dismissal-native-rewrite | 改寫收鍵盤硬規則 | `CLAUDE.md`「App 進入點與平台導覽」的收鍵盤 bullet | ✓ 已落地（見下方偏差說明） |
| ux-honesty-and-visual-foundation | 系統取色、不透明度降階、不模仿 bar／材質；移除外觀切換描述 | `CLAUDE.md` Design System 準則 | ✓ 已落地 |

**與原任務宣告的偏差**：本 change 任務 3.1 要求記錄「四條收起路徑（含背景層點擊）」。
實作期間背景層點擊經介面測試證實在 `Form`／`List` 與 `ScrollView` 上皆收不到觸控，
已於 change 7（commit `7b8130f`）移除，文件記錄為**三條路徑**並明文「點背景收鍵盤在本專案
不可行、不要再嘗試」。此為實證推翻任務前提，非漏寫。

## 二、符號存在性掃描結果

掃描兩份文件中反引號包裹的型別名、檔名與方法名共 74 個（排除系統框架符號），
逐一以 grep 確認存在性：

**判定為錯誤並已修正（2 個）**：

- `dismissKeyboardOnTap()`／`KeyboardDismissOnTap.swift`——extension 放置規則仍以已刪除的
  收鍵盤修飾子為例，改為只以 `blCardShadow()`／`BLButtonStyle` 為例。
- `LookupItemEditorSheet`——sheet 選擇器規則引用的元件名有誤，實際型別為
  `LookupNameEditorSheet`，已更正。

**判定為示意用法、保留（4 個）**：

- `BLCharts.swift`／`BLTextFields.swift`——檔名規則中「避免建立這類大檔」的反例，本就不應存在。
- `Aggregation`——MARK 段名規則中被禁止的 purpose 段名舉例。
- `BuyLedger.entitlements`——安全性一節描述「日後若加 entitlements」的假想路徑，非現存檔。

## 三、既有漂移的處理決定與待查項目

**已處理（此為既有漂移，非前八個 change 造成）**：

- README 專案結構樹缺 `Shared/Media/`（`PhotoDataProcessor` 所在目錄，v1.4 照片功能時新增）
  ——已補列。`Shared/Keyboard/` 已於 change 7 隨手勢刪除而消失，毋須補列。
- README 相依注入目錄寫死「5 個 Repository」，實際已 11 檔（8 個 repository + 3 個
  system-call client）——改為不綁定數量的描述以免再次漂移；「Repository 層」一節的
  逐一列舉同步改為不綁定數量。

**待查項目（不逕行修改）**：

- README「開發環境設定」宣稱兩把 API key——新增 `OpenSettingsClient` 等不影響此數，
  但 AI 總結是否仍僅用 `OLLAMA_API_KEY` 與匯率 `EXCHANGE_RATE_API_KEY` 兩把，
  建議下次動 Networking 時順手核對 `Config.example.xcconfig` 與 `AppConfiguration` 是否同步。

## 四、失效註解的判別與處理

依「只問是否與現況矛盾、不問風格」掃描全部手寫原始碼，發現並處理 3 處：

| 位置 | 失效原因 | 類別 | 處理 |
|------|----------|------|------|
| `BLPhotoViewer.swift` 型別 doc | 仍稱「以 sheet 形式呈現、右上 toolbar ✕」；實際已改推進呈現（change 4）且 ✕ 在取消位置（change 6） | 第二類（描述與實作不符，實作維持現狀） | 改寫並指出決定出處 |
| `BLPhotoThumbnail.swift` `onTap` doc | 仍稱「tap gesture 僅掛在縮圖內容區」；實際已改為獨立 `Button`（change 2） | 第二類 | 改寫 |
| `OrdersView.swift` `detailTitleBar` doc | 仍稱「自繪標題列代替系統 navigation title」；實際已改 `safeAreaInset` + 系統 bar 材質（change 8） | 第二類 | 改寫 |

**第三類（實作才是該改的一方，僅記錄、不動任一邊）**：

- `Color+Extensions.swift` 的 `Color(blHex:)`——BLPalette 改走系統取色後已零呼叫端。
  註解本身仍正確描述其行為，但整個 extension 屬死程式碼；刪除屬程式碼變更，
  超出本 change 的註解稽核範圍，留待後續清理。

## 五、待提升為文件規則與產生器待修項目

**生成檔註解掃描（只記錄不修改）**：`Core/Domain/Generated/` 全數掃描完畢，
註解皆為 schema `doc:` 的平台中立描述，與前八個 change 的 UI 變更無交集，**無發現**。
產生器待修項目：無。

**適用範圍超出所在檔案、值得提升為文件規則的註解知識（僅記錄，不逕行搬移）**：

- `InsightsView.heatmapCard`：「LazyVGrid 只可靠展開直接子層的 ForEach，巢狀 ForEach
  帶 sibling 時不會被攤成 cell」——任何 LazyVGrid 使用者都會踩，建議提升。
- `InsightsView.heatmapCell`：「Shape 無 intrinsic size，在 LazyVGrid 靠 aspectRatio
  會被壓成 0 高度」——同上。
- `BLPhotoViewer.photoPage`：「image-backed layer 上的 clipShape 在 snapshot 光柵化
  路徑不生效，mask 兩者皆穩定」——涉及 snapshot 測試的元件皆適用，建議提升。
