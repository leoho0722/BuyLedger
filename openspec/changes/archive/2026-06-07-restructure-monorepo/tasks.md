## 1. 搬移 Xcode 專案 (Deployable units are rooted under apps/)

- [x] 1.1 依 design 決策「以 git mv 整資料夾搬移，不重建專案」執行 git mv BuyLedger apps/apple，落實 spec 要求 (Deployable units are rooted under apps/)：完成後 apps/apple/BuyLedger.xcodeproj、apps/apple/BuyLedger、apps/apple/BuyLedgerTests、apps/apple/BuyLedgerUITests 存在，repo 根目錄不再有 BuyLedger/ 目錄，且 pbxproj 零變更。驗證：ls apps/apple 列出四個項目，git status 顯示整批 rename (R)，git diff --stat 無 pbxproj 內容變更。
- [x] 1.2 確認搬移未波及平台中立內容 (Cross-platform content stays at the repository root)：openspec/、assets/ 與 README.md、CLAUDE.md、AGENTS.md 仍在 repo 根目錄。驗證：ls 根目錄逐項確認，git status 無這些路徑的 rename 紀錄。

## 2. 更新 committed 路徑引用 (Committed path references track the actual layout)

- [x] 2.1 [P] .gitignore 的兩條規則改指 apps/apple/BuyLedger/Resources/Config.xcconfig 與 apps/apple/BuyLedger/Resources/GoogleService-Info.plist，使敏感檔案於新路徑下持續被忽略。驗證：git check-ignore -v apps/apple/BuyLedger/Resources/Config.xcconfig 與 GoogleService-Info.plist 皆命中對應規則。
- [x] 2.2 [P] CLAUDE.md 的兩處路徑引用 (Design System 一節的 BuyLedger/BuyLedger/Shared/DesignSystem/、測試準則一節的 BuyLedger/BuyLedgerTests/ 與 BuyLedger/BuyLedgerUITests/) 改為 apps/apple 前綴，指引與實際佈局一致。驗證：grep -n 'apps/apple' CLAUDE.md 命中、grep -n 'BuyLedger/BuyLedger' CLAUDE.md 零命中。
- [x] 2.3 [P] README.md 全面對齊新佈局並落實 design 決策「未來目錄只文件化、不建 stub」(Reserved future directories are documented, not stubbed)：所有 xcodebuildmcp 指令的 --project-path 改為 apps/apple/BuyLedger.xcodeproj；專案結構章節重寫為 monorepo 佈局，呈現 apps/apple 實際內容，並把 apps/android、apps/web、apps/backend、shared/data-model 列為保留位置且標注尚未建立。驗證：內容審閱結構圖與保留目錄標注，grep -n 'BuyLedger/BuyLedger' README.md 零命中。
- [x] 2.4 [P] 依 design 決策「openspec 既有 spec 的路徑引用以 sed 批次更新」：16 個既有 capability 的 openspec/specs/*/spec.md 內 BuyLedger/BuyLedger 前綴批次替換為 apps/apple/BuyLedger (連帶 BuyLedger/BuyLedgerTests → apps/apple/BuyLedgerTests 等變體)，僅做機械性字串更新、不動需求內容。驗證：git diff 抽查至少 3 個 spec 確認只有路徑前綴變更，grep -rn 'BuyLedger/BuyLedger' openspec/specs/ 零命中。

## 3. 殘留收斂與三平台驗證

- [x] 3.1 依 design 決策「舊前綴以 BuyLedger/BuyLedger 子字串作為殘留檢測錨點」做全 repo 收斂，落實 spec 要求 (Committed path references track the actual layout)：所有 committed 檔案不殘留舊前綴。驗證：git grep -n 'BuyLedger/BuyLedger' 在整個 repo 零命中 (openspec/changes/restructure-monorepo 內描述對應表的 Before 欄為唯一允許例外)。
- [x] 3.2 依 design 決策「三平台 build 序列化驗證 + 本機狀態重設」：先以 xcodebuildmcp session 重設 project path 為 apps/apple/BuyLedger.xcodeproj (本機狀態，不入版控)，再以 && 串接序列化執行 iOS simulator、iPadOS simulator、macOS 三個 build (simulator 名稱先以 xcodebuildmcp simulator list-sims 查詢，不寫死)。驗證：三個 build 全數回報成功，無任何 Swift 原始碼或 pbxproj 修改。
- [x] 3.3 最終佈局與變更範圍驗收：apps/ 之下僅有 apple 一個目錄、shared/ 不存在於磁碟 (無 stub 目錄與占位檔)。驗證：ls apps/ 僅列 apple，ls shared/ 回報不存在，spectra validate restructure-monorepo 通過，git status --short 僅含本次變更檔案。
