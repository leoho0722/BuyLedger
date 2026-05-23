## 1. View body 平台分流骨架

- [x] 1.1 依設計「macOS 卡片版面與 iOS/iPadOS List 以 `#if os(macOS)` 分流」，把 `OptionPickerSheet` 的選項內容區重構為 root (`NavigationStack`) + `@ViewBuilder content`（`#if os(macOS)` → 新 macContent；`#else` → 現有 List 原樣保留）。行為：交付 spec「Platform-adaptive option picker presentation」——macOS 走卡片、iOS/iPadOS 走 List。驗證：序列化執行 `xcodebuildmcp --log-level error macos build` 與 `simulator build`（iPhone 17）皆 BUILD SUCCEEDED。
- [x] 1.2 依設計「共用 navigation / toolbar / alert / sheet / searchable modifier 提取到平台分支之外」，把 `navigationTitle`、toolbar 取消、一般新增 `.alert`、付款方式 `.sheet`（`PaymentMethodEditorSheet`）、`SearchableModifier`、macOS `.frame(minWidth:minHeight:)` 掛在 `content` 之外的 root 共用，`@State`（showsAddAlert / showsAddPaymentMethodSheet / draft / searchText）不變。行為：交付 spec「Add-option flows are preserved across platforms」——兩平台一般新增與付款方式新增觸發與 callback 一致。驗證：iPhone 與 macOS 各跑一次新增（含付款方式無卡 toggle）與取消，結果與變更前相同。

## 2. macOS 卡片內容

- [x] 2.1 依設計「macOS 選項列以 BLCard 呈現並沿用 selected 勾選與 onSelect 行為」與「sheet 內不套全頁深色 `palette.background`」，實作 macContent 的選項列：`ScrollView` (背景以 `palette.isDark ? Color.clear : palette.background` 分模式——淺色用 List 淺灰群組底、深色沿用 sheet 材質) + 單一 `BLCard(padding: 0)` 列表（列間 `Divider` 帶 leading inset），每列為 Button（點選呼叫 `onSelect` 後 `dismiss`），顯示 `displayText(for:)`，`option == selected` 時右側顯示 checkmark。行為：交付 spec「Option selection is preserved across platforms」。驗證：macOS run，於 OrderEditView 開啟訂單來源 pop-up，點一個選項即套用並關閉，目前選項顯示勾選，且背景不出現突兀深色塊。
- [x] 2.2 依設計「macOS 新增入口與空狀態對齊 `LookupManagementView` 樣式」，實作 macContent 的新增按鈕（`allowsAdd` 時於卡片上方，沿用 `onAddPaymentMethod != nil` 開 `PaymentMethodEditorSheet`、否則開一般新增 alert 的點擊邏輯）與置中 `ContentUnavailableView`（`emptyTitle` / `emptyDescription`），沿用 sheet 預設材質背景。行為：交付 spec「Add-option flows are preserved across platforms」與「Search, display name, and empty state are preserved」的空狀態。驗證：macOS run，付款方式 pop-up 可由新增按鈕開啟編輯 sheet；無選項時顯示置中空狀態。
- [x] 2.3 確認 macOS 卡片版面下 `SearchableModifier` 與 `displayText` / `filteredOptions` 行為不變：`searchable` 時可依顯示名稱與 `searchKeywords` 過濾，選項以 `displayName` 呈現。行為：交付 spec「Search, display name, and empty state are preserved」。驗證：macOS run，於可搜尋的幣別 pop-up 輸入關鍵字（如「美」或「USD」）可正確過濾且顯示「USD · 美元」格式。

## 3. iOS/iPadOS 回歸驗證

- [x] 3.1 確認 `#else` 分支沿用原 List（新增按鈕 Section、選項列含勾選、`ContentUnavailableView` 空狀態、`SearchableModifier`）未被更動。行為：交付 spec「Platform-adaptive option picker presentation」中 iOS/iPadOS 維持 List。驗證：iPhone 17 run，於 OrderEditView 開啟訂單來源／付款方式 pop-up 與變更前一致，可選取、新增、取消。

## 4. 整合驗證

- [x] 4.1 交付 design「Implementation Contract」的驗收標準：序列化執行 macOS build 與 iOS Simulator build 皆成功，並確認既有 iOS snapshot 測試（若涵蓋）維持通過、不需重建 baseline。驗證：`xcodebuildmcp --log-level error macos build` 與 `simulator build` 皆 BUILD SUCCEEDED；相關 snapshot 測試綠燈。
