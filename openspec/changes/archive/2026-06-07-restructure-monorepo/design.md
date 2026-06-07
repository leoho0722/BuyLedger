## Context

repo 根目錄目前只有單一 Apple 平台 Xcode 專案 (BuyLedger/，含 BuyLedger.xcodeproj、BuyLedger/ source root、BuyLedgerTests/、BuyLedgerUITests/)，加上 openspec/、assets/ 與根目錄文件。BuyLedger 規劃擴展 Android、Web、Backend 並跨平台共享 Data Model，需在新平台動工前確立 monorepo 佈局。

現況限制與已知條件：

- Xcode 專案使用 file system synchronized groups，pbxproj 內部一律是專案目錄內的相對路徑——整個專案資料夾搬移不需改動 pbxproj。
- 無 CI 設定、無進行中的其他 change、working tree 乾淨——搬移時機理想。
- 路徑引用集中在四處：README.md (~28 處)、CLAUDE.md (2 處)、.gitignore (2 處)、openspec/specs 既有 spec (~1477 處)。
- .spectra/ 本地索引與 xcodebuildmcp session defaults 屬本機狀態 (不入版控)，搬移後需個別重設。
- 三平台 build 共用同一份 DerivedData build.db，驗證 build 必須序列化執行。

## Goals / Non-Goals

**Goals:**

- 將 Xcode 專案以 git mv 搬移至 apps/apple，保留 git 歷史 (rename detection)。
- 確立並文件化 apps/ + shared/ 的頂層佈局契約 (含未來 apps/android、apps/web、apps/backend、shared/data-model)。
- 所有 committed 檔案的路徑引用一次收斂到新佈局，repo 內不殘留舊前綴。
- 搬移後三平台 build 全數通過，證明 Xcode 專案不受影響。

**Non-Goals:**

- 不建立 Android/Web/Backend 程式碼或專案骨架、不建立 shared/data-model 實際內容 (格式選型留待後續 change)。
- 不調整 Xcode 專案內部結構、scheme 名稱、bundle identifier。
- 不引入 monorepo 工具鏈 (Nx/Turborepo/Bazel)、不新增 CI。
- 不建立空的 stub 目錄或 .gitkeep 占位檔。

## Decisions

### 以 git mv 整資料夾搬移，不重建專案

以 git mv 將 BuyLedger/ 整個搬到 apps/apple/，而非建新目錄複製內容。理由：(1) git rename detection 保留逐檔歷史，git log --follow 可追溯；(2) file system synchronized groups 讓 pbxproj 免改，搬移後專案內部零變更；(3) 一個 commit 內完成搬移與引用更新，避免中間態。替代方案「重建 Xcode 專案於新位置」被否決——風險高且無任何額外收益。

### 舊前綴以 BuyLedger/BuyLedger 子字串作為殘留檢測錨點

搬移後合法路徑一律是 apps/apple/BuyLedger... 形式，不再有 BuyLedger/BuyLedger 相鄰重複——以該子字串全 repo grep 作為「零殘留」的機械性驗收條件。單獨 grep BuyLedger/ 會誤中新路徑，不採用。

### openspec 既有 spec 的路徑引用以 sed 批次更新

~1477 處引用分佈於 16 個 capability 的 spec.md，逐檔手改不可行。以 sed 將 BuyLedger/BuyLedger 前綴替換為 apps/apple/BuyLedger (連帶涵蓋 BuyLedger/BuyLedgerTests → apps/apple/BuyLedgerTests 等變體)，替換後用上述 grep 錨點驗證歸零。此為機械性字串更新，不涉及需求變更，故不需為 16 個既有 capability 建 delta spec。實作時發現 openspec/changes/archive/ 的歷史歸檔 change (23 個 markdown，153 行) 亦含同前綴，套用同一條機械性替換一併收斂——原始路徑紀錄由 git 歷史保存，repo 內文件一律指向現行佈局。

### 未來目錄只文件化、不建 stub

README 專案結構章節重寫為 monorepo 佈局，列出 apps/apple 實際內容與保留位置 (apps/android、apps/web、apps/backend、shared/data-model) 並標注「未建立」。不建空目錄：git 不追蹤空目錄，.gitkeep 是噪音且會讓「保留位置」與「已動工」難以區分。

### 三平台 build 序列化驗證 + 本機狀態重設

搬移後以 xcodebuildmcp CLI 對 apps/apple/BuyLedger.xcodeproj 依序跑 iOS simulator、iPadOS simulator、macOS build (`&&` 串接，不並行——共用 build.db)。另重設 xcodebuildmcp session defaults 的 project path；.spectra/ 本地索引如檢索異常以 spectra 工具重建。這兩項是本機狀態，不入版控、不影響其他協作者。

## Implementation Contract

- **可觀察行為**：搬移完成後，(1) apps/apple/BuyLedger.xcodeproj 存在且 repo 根目錄不再有 BuyLedger/ 目錄；(2) 以 xcodebuildmcp 指定 --project-path apps/apple/BuyLedger.xcodeproj、scheme BuyLedger，iOS simulator / iPadOS simulator / macOS 三個 build 序列化執行全數成功；(3) README 專案結構章節呈現 monorepo 佈局契約 (實際 + 保留目錄)。
- **介面／資料形狀**：目錄對應——BuyLedger/BuyLedger.xcodeproj → apps/apple/BuyLedger.xcodeproj、BuyLedger/BuyLedger → apps/apple/BuyLedger、BuyLedger/BuyLedgerTests → apps/apple/BuyLedgerTests、BuyLedger/BuyLedgerUITests → apps/apple/BuyLedgerUITests。文件引用對應見 spec monorepo-layout 的 reference rewrite mapping 表。
- **失敗模式**：build 失敗時以 xcodebuildmcp --log-level error 取得詳細錯誤；若肇因於搬移 (理論上 file system synchronized groups 不會)，以 git 還原整個 commit 回滾，不做半套修補。
- **驗收條件**：(1) 全 repo grep 子字串 BuyLedger/BuyLedger 在 committed 檔案中零命中；(2) 三平台 build 成功；(3) spectra validate 通過；(4) git status --short 確認只含本次變更檔案。
- **範圍邊界**：in scope——git mv 搬移、README/CLAUDE.md/.gitignore/openspec specs 引用更新、README 佈局章節重寫、本機工具狀態重設、三平台 build 驗證。out of scope——任何 Swift 程式碼變更、pbxproj 變更、新平台骨架、shared/ 目錄建立、CI、monorepo 工具鏈。

## Risks / Trade-offs

- [外部引用遺漏——文件或設定檔仍指向舊路徑] → 以 BuyLedger/BuyLedger 子字串全 repo grep 作機械性收斂，驗收條件要求零命中。
- [sed 批次替換誤傷——spec 內文出現非路徑的同名字串] → 替換錨點即是路徑前綴本身；替換後 grep 歸零 + 抽查數個 spec diff 確認語意未變。
- [本機工具狀態殘留——xcodebuildmcp session defaults 或 .spectra 索引指向舊路徑] → 列為獨立 task：重設 session defaults、必要時重建索引；此為 per-machine 操作，README 不需記載。
- [協作者本機 worktree／分支衝突——其他分支仍以舊路徑為基底] → 目前無其他進行中 change 且 working tree 乾淨；搬移以單一 commit 完成，rebase 時 git rename detection 可自動跟隨多數變更。
- [DerivedData 殘留舊路徑快取] → 搬移後首次 build 會以新路徑重建 build graph；如遇異常先 clean 再 build。
