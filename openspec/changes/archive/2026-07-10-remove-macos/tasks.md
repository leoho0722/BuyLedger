## 1. 刪除 macOS-only 檔與資產

- [x] 1.1 [P] 刪除 Features/Orders/OrdersMacView.swift 與 Features/Settings/SettingsMacView.swift (兩者整檔包在 #if os(macOS))。行為：專案不再有 macOS 專屬訂單/設定畫面。驗證：兩檔不存在；唯一引用點 (OrdersView 的 macOS 分支、BuyLedgerApp 的 macOS Settings scene) 於第 2 組一併移除後無 dangling。
- [x] 1.2 [P] 刪除 Resources/Assets.xcassets/AppIcon.appiconset 的 10 個 AppIcon-mac-*.png 並移除 Contents.json 中 10 筆 idiom=mac 條目 (保留 3 筆 universal)；刪除 root 的 assets/macos-intro.png。行為：只剩 iOS 通用圖示。驗證：png 與 json 條目成對移除、asset catalog 編譯無缺檔警告；macos-intro.png 不存在。

## 2. 拆除 Swift 條件編譯 (鐵律：保留 #else、只刪 #if os(macOS))

- [x] 2.1 進入點 App/BuyLedgerApp.swift 與 App/AppDelegate.swift：刪 macOS 的 NSApplicationDelegateAdaptor 分支 (保留 iOS UIApplicationDelegateAdaptor)、macOS 的 .windowStyle+.commands 與 Settings{SettingsMacView} scene、整組 NewOrderMenuCommand/NewOrderActionKey/FocusedValues 選單機制、AppDelegate 的 NSApplicationDelegate 分支。行為：App 進入點為純 iOS WindowGroup，Firebase 初始化 configure() 保留。驗證：iOS build 成功、App 啟動正常，無 NSApplication/menu 殘留。
- [x] 2.2 導覽層 Features/App/RootView.swift、RootFeature.swift、RootSidebarLayout.swift：RootView.layout 刪 macOS 分支保留 #else (compact→RootTabLayout / regular→RootSidebarLayout)；RootFeature 刪 NSApp.sendAction(showSettingsWindow:) 分支保留 iOS deep-link、移除 #if canImport(AppKit) import AppKit；RootSidebarLayout 剝掉 body 的 macOS .toolbarBackgroundVisibility 與 sidebar 的 .scrollContentBackground/.ultraThinMaterial。行為：iPhone compact 與 iPad regular 導覽完整保留。驗證：iPad build 後側邊欄兩欄佈局正常、iPhone TabView 正常。
- [x] 2.3 Features/Orders/OrdersView.swift 與 OrdersCompactView.swift：platformContent 刪 #if os(macOS) 的 OrdersMacView 分支、保留 #else (compact→OrdersCompactView / regular→regularSplitContent)；去掉 regularSplitContent 內 .bottomBar/.topBarLeading 與 horizontalSizeClass 的 #if !os(macOS) guard 但保留內容 (iPad 多選工具列)；OrdersCompactView 去外層 #if !os(macOS) wrapper。行為：iPad regular 兩欄含全選/批次改狀態/已選筆數工具列完整保留。驗證：iPad build 後訂單兩欄與多選列正常、iPhone 訂單清單正常。
- [x] 2.4 [P] 各 feature view 的 macOS 分支 (Dashboard/Insights/More/AISummary/Settings/FX/Lookups 等)：刪 #if os(macOS) 分支保留 #else、去 #if !os(macOS) guard 保留內容。特別：刪除 InsightsView.titleHeader 孤兒函式 (移除 macOS 分支後其唯一呼叫消失)；保留 DashboardView.titleHeader (line 100 無條件呼叫)。行為：各頁在 iPhone/iPad 呈現不變、無死碼。驗證：iOS+iPad build 成功、各頁畫面正常。
- [x] 2.5 [P] 各 sheet 與 DesignSystem 的 macOS 分支：OrderEditView、OptionPickerSheet、OrderFilterSheet、OrderMergeCandidateSheet、PaymentMethodEditorSheet、LookupItemEditorSheet、OrderDetailView 的 #if os(macOS) 視窗 .frame(minWidth:minHeight:) 塊整刪、#if !os(macOS) guard 去掉保留內容 (navigationBarTitleDisplayMode/keyboardType/presentationDetents 等)；BLButtonStyle 的 #if os(macOS)/#else minimumHeight 保留 #else(44)；BLPhotoViewer 去 #if !os(macOS) guard。行為：sheet 在 iOS 走 presentationDetents、無 macOS 視窗尺寸。驗證：build 成功、各 sheet 呈現正常。
- [x] 2.6 [P] 拆 canImport(AppKit) 分支 (D2)：Shared/DesignSystem/Foundations/Image+PhotoData.swift 只留 canImport(UIKit) 實作、移除 AppKit 分支；RootFeature 的 AppKit import 已於 2.2 移除。行為：影像解碼只走 UIKit。驗證：build 成功、照片顯示/解碼正常；務必保留 UIKit 主分支不誤刪。
- [x] 2.7 [P] 清理殘留：BuyLedgerTests/RootFeatureTests.swift 去掉包住 goToAISettings 測試的 #if !os(macOS) guard；清 CampaignFeature.swift/OrderDetailView.swift/BLMetrics.swift 的純註解 macOS 字樣 (無 #if 指令)。行為：測試恆執行、註解與現況一致。驗證：測試 target 編譯通過、該測試被執行。

## 3. Xcode 平台收斂 (與第 2 組同批，確保 build 一致)

- [x] 3.1 project.pbxproj App target (Debug/Release) 平台收斂：SUPPORTED_PLATFORMS 由 "iphoneos iphonesimulator macosx" 改為 "iphoneos iphonesimulator"；刪 MACOSX_DEPLOYMENT_TARGET、LD_RUNPATH_SEARCH_PATHS[sdk=macosx*]、SUPPORTS_MACCATALYST、ENABLE_APP_SANDBOX、ENABLE_HARDENED_RUNTIME、ENABLE_USER_SELECTED_FILES、CODE_SIGN_ENTITLEMENTS；並刪除 Resources/BuyLedger.entitlements 檔 (D1，與 CODE_SIGN_ENTITLEMENTS 同批)。行為：App target 只 build iOS、無 macOS 沙盒/授權設定。驗證：iOS build 成功、codesign 不因缺 entitlements 檔失敗。絕不可動 TARGETED_DEVICE_FAMILY 的 "1,2" (2=iPad)。
- [x] 3.2 [P] project.pbxproj Tests/UITests target (各 Debug/Release) 平台收斂 (D3)：四處 SUPPORTED_PLATFORMS 移除 macosx 與未使用的 xros/xrsimulator (→ "iphoneos iphonesimulator")；刪對應 MACOSX_DEPLOYMENT_TARGET。行為：測試不再被排到 macOS/visionOS destination。驗證：測試在 iOS simulator 正常執行。

## 4. 文件與 spec 同步

- [x] 4.1 [P] 改寫 apps/apple/README.md：標題去 macOS、結構樹 (App/ macOS Settings scene/CommandGroup、Settings/ SettingsMacView、Orders 三平台分流)、架構表刪 macOS 列保留 iPad regular 列、Build&Run 的 macOS 指令、刪除兩個 Troubleshooting 小節 (macOS 沙盒空狀態、macOS DNS 失敗)。行為：文件只描述 iOS/iPadOS。驗證：grep -i "macos" apps/apple/README.md 無殘留 (canImport 等程式碼詞除外)。
- [x] 4.2 [P] 改寫 apps/apple/CLAUDE.md：標題、build 規則的「三平台/macOS」措辭改 iOS+iPadOS (規則本體保留)、刪 BuyLedgerApp #if os(macOS) Scene 規則、macOS rebuild stop、macOS 沙盒 entitlement 首句、dismissKeyboardOnTap macOS no-op、.bottomBar 那條剝 macOS 留 iPad 指引。行為：平台硬規則反映純 iOS/iPadOS。驗證：無殘留 macOS build/scene 規則、iPad 指引保留。
- [x] 4.3 [P] 改寫 root README.md (引言平台措辭、刪 macOS <details open> 展示區塊並把 iOS 或 iPadOS 改 open、結構註解、平台導覽表列)、root CLAUDE.md L36、openspec/config.yaml (context 與 #if os(macOS) 例示)。行為：root 文件與 config 反映純 iOS/iPadOS。驗證：grep 無殘留 macOS 平台敘述。
- [x] 4.4 monorepo-layout 的 requirement「Deployable units are rooted under apps/」於 archive 套用 MODIFIED delta：把「All three Apple platforms still build after relocation」scenario 改為「iOS and iPadOS both build after relocation」(移除 macOS build)。行為：spec 的 build 驗證只列 iOS+iPadOS。驗證：archive 後 openspec/specs/monorepo-layout 的該 requirement scenario 無 macOS。

## 5. 驗收

- [x] 5.1 iPhone + iPad 兩佈局驗證：依 apps/apple/CLAUDE.md 先遞增 build number，iOS(iPhone) 與 iPadOS(iPad) simulator 各 build-and-run 一次，確認 compact(RootTabLayout+OrdersCompactView) 與 regular(RootSidebarLayout+regularSplitContent 兩欄多選工具列) 皆正常；跑 BuyLedgerTests。行為：純 iOS/iPadOS App 兩佈局可 build、測試全綠、功能與移除前一致、不再有 macOS build。驗證：兩平台 BUILD SUCCEEDED、測試通過、手動確認 iPhone/iPad 訂單/開團/分析/設定畫面正常。
