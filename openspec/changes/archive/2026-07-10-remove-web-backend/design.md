## Context

BuyLedger 現況為 Apple 平台 (iOS / iPadOS / macOS) 加 Web 全棧 (Next.js 前端 + NestJS 後端 + PostgreSQL) 的多平台產品。跨裝置同步採 client-server 架構：後端以 Postgres 為 SoT、透過 firebase-admin 把每筆寫入鏡像到 per-user 的 Firestore 投影；iOS 端讀 Firestore 投影、寫入一律 PATCH 到後端 API，並以 `CloudSyncFeatureFlag.isEnabled` (預設 false) 作為 opt-in 總開關。

產品方向調整為只維護純 iOS App。由於同步是 client-server 而非 peer-to-peer，後端一旦移除，iOS 的雲端同步 (寫入端 404、讀取端投影停格) 無法續存，必須一併移除。所幸同步預設關閉，flag OFF 時不實例化任何同步引擎，故移除對現行使用者行為零影響——本次是把「一個從未啟用的功能」連根拆除。

先前已用多路平行分析產出移除範圍報告，並經對抗式 build 完整性驗證。使用者已拍板 5 個關鍵決策 (見 Decisions)。

## Goals / Non-Goals

**Goals:**

- 完整移除 apps/web、apps/backend 與其部署基礎設施 (deploy/、Makefile、firebase.json、firestore.rules)。
- 移除 iOS 雲端同步層 (Core/Sync、Features/App 的 Cloud*、同步 feature flag、同步測試)，並乾淨拆除所有接線，使三平台 build 與測試通過。
- iOS 維持本機 SwiftData 為唯一資料來源，功能行為不變。
- Firebase 降為純遙測底座 (FirebaseCore + Crashlytics + Analytics)，移除同步專屬產品。
- SwiftData schema 以 forward-only 方式升 V13，乾淨移除同步 sidecar 表。
- shared/data-model 降級為 swift-only codegen；移除 shared/sync-conformance。
- 所有文件與 openspec spec 與純 iOS 現況同步。

**Non-Goals:**

- 不收斂 monorepo 成根目錄單一專案 (維持 apps/apple + shared/ 佈局；決策 D3)。
- 不移除 shared/data-model 的 schema 到 codegen 產生層，也不固化生成的 Swift 為手寫檔 (D4)。
- 不移除 Firebase 遙測底座；FirebaseCore / Crashlytics / Analytics、`-ObjC` linker flag、GoogleService-Info.plist、Crashlytics 符號上傳 build phase 一律保留 (D1)。
- 不降版或改動既有 V10 到 V12 版本鏈；只往上新增 V13。
- 不動 apps/android 文件化保留位置。
- Firebase admin service account 金鑰的撤銷屬 GCP / Firebase console 操作，不在本 change 的程式碼範圍內。

## Decisions

**D1 — Firebase 保留遙測底座，只移除同步專屬產品。**
保留 FirebaseCore、FirebaseCrashlytics、FirebaseAnalytics 與 `FirebaseApp.configure()` 啟動鏈路 (AppLaunchConfigurator / AppDelegate / delegate adaptor)、GoogleService-Info.plist、`OTHER_LDFLAGS = -ObjC`、以及執行 firebase-ios-sdk Crashlytics 符號上傳的 Run Script build phase；移除同步專屬的 FirebaseFirestore / FirebaseAuth / FirebaseStorage / FirebaseMessaging / FirebasePerformance 與 GoogleSignIn / GoogleSignInSwift。
- 理由：使用者要保留崩潰與使用分析遙測。因 firebase-ios-sdk 與 Crashlytics 皆保留，該 Run Script 的腳本路徑仍存在，不需 (也不可) 移除該 build phase。
- 替代方案 (未採)：徹底移除全部 Firebase。雖能砍掉整棵依賴樹，但會失去遙測底座，與使用者需求不符。

**D2 — SwiftData 保留 V12 為 target，兩張空 sidecar 表留著 (原擬升 V13，實作證實不可行)。**
不動 schema：`SyncMeta` / `SyncQueueItem` 兩個 `@Model` 與 V12 皆保留，僅移除其持久層 (`SyncMetaPersistence` / `SyncQueuePersistence`) 與同步引擎。兩張表在移除同步後永遠為空、無實際成本。
- 實作發現 (原擬 D2-B 升 V13 drop 表，已否決)：新增 V13 從 models 移除兩型別後，其 schema 形狀與 **V11 完全相同** (領域 model 自 V11 未變、V13 只是移除 sidecar)。CoreData staged migration 以 model checksum 辨識版本，V11 與 V13 checksum 相同會拋 `NSInvalidArgumentException: Duplicate version checksums across stages detected` (實測 `SchemaMigrationTests` crash 佐證)；而 V11 又不能從 plan 移除 (會斷 V10/V11 store 遷移路徑)。故「drop 回既有形狀」的新版本在此版本鏈技術上不可行。
- 理由：D2-A 零 migration 變更、零資料風險，兩張空表無成本，且完全避開 checksum 撞版。
- 替代方案 (未採)：降回 V11 (會砍既有 V12 store 資料，違反 forward-only)。

**D3 — 維持 apps/ + shared/ 佈局。** 只刪 web / backend 與其基礎設施，不搬動 apps/apple 或 shared/。
- 理由：改動面最小、不觸動 Xcode 專案與 SourceKit-LSP 工具鏈；shared/data-model 仍是 iOS Swift 型別的 SoT；保留未來接 Android 的空間。
- 替代方案 (未採)：收斂成根目錄單一專案 (路徑 churn 極大、作廢 CLAUDE.md 分層原則)。

**D4 — shared/data-model 整層保留，codegen.yaml 降級為 swift-only。** 移除指向 apps/web、apps/backend 的兩個 TypeScript target，只留 Swift target。
- 理由：data-model-codegen 既有規格本就要求「production 只配置 Swift target until other platforms start」，本決策等於讓設定回到規格原意；generator 的 TS / Kotlin emitter 由 golden-file 測試自洽、保留成本近零，且對應未來 Android。
- 替代方案 (未採)：固化 Swift 生成碼、砍 generator (作廢兩份 CLAUDE.md 大量 data-model 硬規則)。

**D5 — 走 Spectra change proposal。** 即本 change，spec 變更以 REMOVED / MODIFIED delta 在 archive 時套用。
- 理由：符合專案 SDD 慣例、保留移除理由與審查軌跡。

## Implementation Contract

**完成後可觀察的狀態 (acceptance criteria)：**

- iOS / iPadOS / macOS 三平台 build 皆成功；BuyLedgerTests 全數通過。移除同步後不得殘留任何對已刪型別的引用。
- App 啟動與所有本機功能 (訂單 / 開團 / 分析 / 匯率 / AI 摘要 / 照片) 行為與移除前一致；設定頁不再出現雲端帳號 / 登入 / 同步 UI。
- `apps/web`、`apps/backend`、`deploy/`、`Makefile`、`firebase.json`、`firestore.rules`、`shared/sync-conformance/` 不存在於工作樹。
- Firebase：`FirebaseApp.configure()` 仍執行、Crashlytics 與 Analytics 遙測仍在；Xcode 專案不再連結 Firestore / Auth / Storage / Messaging / Performance / GoogleSignIn 產品；`Info.plist` 不再含 `BACKEND_API_BASE_URL`、Google `REVERSED_CLIENT_ID` URL scheme、`remote-notification` 背景模式。
- SwiftData target 為 V13；停在 V12 的既有 store 開啟時經 V12 到 V13 lightweight stage 遷移、不砍資料；SyncMeta / SyncQueueItem 兩表與其 @Model 定義不再存在。
- `shared/data-model/codegen.yaml` 只含 Swift target；`cd shared/data-model/generator && bun run check` 於重生成後 exit 0。
- iOS 保留的網路層 (HTTPClient / APIError / URLRequestBuilder / HTTPMethod / AppConfiguration 去除 backendBaseURL 後) 仍供 FX 匯率與 Ollama AI 使用。
- 文件 (README、root CLAUDE、apps/apple/CLAUDE、shared/data-model README、.gitignore) 與 spec 無殘留 web / backend / 雲端同步敘述。

**介面與資料形狀變更：**

- `AppConfiguration` 移除 `backendBaseURL` 成員，memberwise init 簽名隨之改變 (連帶更新 AppConfigurationTests、AISummaryFeatureTests)。
- 移除 `OrderRepository` 的三個同步通知 (buyLedgerOrderSaved / buyLedgerOrdersResyncNeeded / buyLedgerOrderDeleted) helper 與呼叫；此三名唯一定義處 NotificationName+Extensions 一併移除 (編譯期硬綁定，須同批處理)。
- `BuyLedgerApp` 根 view 由 AppRootView 改為直接 RootView (AppRootView 只為 flag gate 存在，整檔移除)。

**Scope 邊界：**

- 明確在範圍內：上述 Removed / Modified 檔案與 spec、V13 遷移、Xcode 專案產品增刪、文件同步。
- 明確不在範圍內：monorepo 扁平化、data-model generator 移除、Firebase 遙測移除、SwiftData 降版、Firebase admin 金鑰撤銷 (GCP 操作，僅於收尾提醒)。

## Risks / Trade-offs

- [刪 Core/Sync 兩個 @Model 前未完成 V13 遷移，導致 V12 schema 編不過或既有 store 砍資料] → 嚴格順序：先完成 V13 (新增版本、凍結 V12 影子、append stage、切 target) 並驗證遷移，再刪 SyncMeta.swift / SyncQueueItem.swift。
- [刪 Cloud* / Core/Sync 檔而未先拆 AppRootView / Settings / OrderRepository 接線，導致三平台 build 失敗] → 先完成所有接線改寫，再刪檔；以三平台 build 當關卡。
- [誤移除 Crashlytics build phase 或 `-ObjC`，導致保留的 Firebase 遙測 build 失敗] → D1 明確保留兩者；Xcode 專案只移除同步專屬 SPM 產品。
- [誤刪 HTTPClient / AppConfiguration / PhotoDataProcessor 等被 FX / AI / 照片共用的檔] → 保留清單明列；只從 AppConfiguration 拆 backendBaseURL 單一成員。
- [codegen.yaml 與已刪的 TS 生成目錄不同步，check 守門報漂移] → codegen.yaml 改 swift-only 與刪除 web/backend 目錄同批，重生成後跑 check。
- [Firebase admin 金鑰僅刪本機檔仍有效] → 於收尾任務提醒使用者到 GCP / Firebase console 撤銷該高權限憑證，並檢查 git 歷史是否曾提交。

## Migration Plan

1. 先開本 change (proposal / design / specs / tasks)，spec 變更於 archive 時套用。
2. 刪 A 組 (web / backend / deploy / Makefile / firebase 設定)——零 iOS 影響、可獨立提交；同步提醒撤銷 admin 金鑰。
3. 降級 shared/data-model (codegen.yaml swift-only + 刪 TS 生成目錄，跑 check)；刪 shared/sync-conformance。
4. iOS 拆線：AppRootView 改 RootView、拆 Settings gate、拆 AppConfiguration.backendBaseURL 與測試、清 OrderRepository 通知與 NotificationName (同批)。
5. SwiftData 升 V13 (依 /swiftdata-schema-migration 流程)，驗證 V12 到 V13 遷移後，刪 Core/Sync 全部同步檔 (含 SyncMeta / SyncQueueItem) 與 5 個同步測試。
6. Xcode 專案設定 (依 D1)：移除同步專屬 Firebase / GoogleSignIn 產品、Info.plist URL scheme / 背景模式；Xcode 重解析 Package.resolved。
7. 三平台 build + 測試驗證 (schema 遷移、build number 遞增規則見 apps/apple/CLAUDE.md)。
8. 文件與 spec 同步；apply 後 archive 套用 delta。

回滾策略：本 change 以刪除為主，回滾即還原被刪檔與 pbxproj / schema 變更 (git revert)。V13 遷移為 forward-only，回滾程式碼不會回滾已遷移的 on-disk store，但 V13 只是移除空的 sidecar 表、無資料損失，故回滾風險低。

## Open Questions

- 無阻塞性未決問題。Firebase admin service account 金鑰撤銷為 change 外的營運動作，於實作收尾以人工提醒處理。
