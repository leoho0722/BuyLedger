# custom-theme-color (孤兒變更狀態備忘)

本檔備忘 `spec-corpus-hygiene` change 任務 4.1 刪除前的內容，供日後查閱。原始檔案：

- `.spectra/changes/custom-theme-color.started` (內容僅一行 commit hash `1b150dfe3af40ad30b51c6242f83a4cc60f9a8e4`，為啟動變更時的 base commit，該 commit 本身與此功能無關，只是起點標記)
- `.spectra/touched/custom-theme-color.json`

`openspec/changes/` 下從未存在對應的 `custom-theme-color/` 變更目錄 (無 proposal.md、tasks.md、specs)，程式碼庫中也不存在任何相關檔案 (`AppThemeColor.swift`、`ThemeColorPickerView.swift`、`AppThemeColorTests.swift` 均不存在)。判斷為從未經過 `/spectra-propose` 正式建案、僅留下啟動與觸碰標記的孤兒狀態檔。

## 原記錄的任務描述 (逐條保留原文)

1. **task_id 1**：依決策〈主題色模型：以列舉包裝系統動態色，不存色值〉，新增 `AppThemeColor` 列舉 (`apps/ios/BuyLedger/Features/Settings/AppThemeColor.swift`)：raw String，case 為 systemDefault 加 12 個系統動態色 (red、orange、yellow、green、mint、teal、cyan、blue、indigo、purple、pink、brown)；提供 color 存取器 (systemDefault 回傳 nil、其餘回傳對應 systemXxx 動態色) 與 title 本地化 key 存取器。涉及檔案：`AppThemeColor.swift`、`SettingsFeature.swift`、`SettingsSnapshot.swift`、`SettingsStorage.swift`、`AppThemeColorTests.swift`、`SettingsFeatureTests.swift`。

2. **task_id 3**：依決策〈根層以 Optional tint 套用，避免條件式 modifier〉，`RootView` 以 `.tint(themeColor.color)` 恆常掛載 (systemDefault 傳 nil 即恢復系統預設)，主題色取自 settings 狀態，切換即時生效。涉及檔案：`RootView.swift`、`BLPalette.swift`。

3. **task_id 5**：依決策〈選擇器為專屬色票清單，不重用 OptionPickerSheet〉，新增 `ThemeColorPickerView` (`apps/ios/BuyLedger/Features/Settings/ThemeColorPickerView.swift`)：List 每列為圓形色票加本地化名稱、目前選擇顯示勾選，首列系統預設；嵌入呈現 (不自帶 NavigationStack、無關閉鈕、由宿主 Back 返回)。涉及檔案：`SettingsView.swift`、`ThemeColorPickerView.swift`、`Localizable.xcstrings`。

4. **task_id 9**：`ContrastComplianceTests` 依清單新增參數化測試：`AppThemeColor` 全案例 (排除 systemDefault) 乘兩外觀驗證 4.5:1 地板；不達標的組合修改該元件的文字承色方式。涉及檔案：`DashboardView.swift`、`FxView.swift`、`BLFilterChip.swift`、`ContrastComplianceTests.swift`。

5. **task_id 11**：實機驗收清單 (整體觀感、深淺外觀切換、增強對比開啟下的主題色表現)；文件審視。涉及檔案：`apps/ios/CLAUDE.md`。

## 判斷：是否仍有價值

功能構想本身 (讓使用者從系統動態色中挑選 App 主題色，以列舉包裝、不存色值、對比度有專屬測試覆蓋) 設計得相當完整，不是隨手留下的空殼。

但其核心實作路徑 (task_id 3：`RootView` 恆常掛載 `.tint(themeColor.color)`) 與現行 `color-system-foundation` 規格的既有規則直接衝突：該規格明訂「The app SHALL NOT apply an explicit global tint」，即 App 不得強制套用全域 tint，系統元件應維持平台預設 accent 行為；需要 accent 視覺的自訂元件改由 palette 取色 (解析為系統動態藍)，而非任意色值。custom-theme-color 提案的作法正是「讓使用者選色後在根層套用全域 tint」，若照原設計實作會直接違反這條已生效的規則。

因此本檔判斷：這不是一個「被遺漏、仍應補做」的功能，而是一個與既有視覺誠實度政策存在架構性衝突、合理被擱置的構想。若使用者未來仍想要主題色功能，需要先重新決定如何在不違反「不強制全域 tint」規則的前提下實作 (例如：主題色只影響自訂元件的 accent 視覺，不透過根層 `.tint()` 套用)，而非直接復用這份舊記錄的路徑；此判斷回報給使用者，不逕行建議或動手實作。
