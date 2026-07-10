## Why

BuyLedger 原本是 Apple 平台加 Web 全棧的多平台產品，跨裝置同步採 client-server 架構 (NestJS 後端為 Firestore 唯一寫入方、iOS 寫入一律經後端 API)。產品方向調整為只維護純 iOS App：Web 前端、後端與其承載的雲端同步不再需要，繼續保留只會持續墊高維護面、依賴體積與文件負擔。此時移除最單純，因為同步是 opt-in 且預設關閉，現行使用者早已是純本機行為。

## What Changes

- **BREAKING** 移除整個 Web 前端 (apps/web) 與 NestJS 後端 (apps/backend)，連同其部署基礎設施 (deploy/、根 Makefile、firebase.json、firestore.rules)。
- **BREAKING** 移除 iOS 的跨裝置雲端同步。同步是 client-server 架構、後端為 Firestore 唯一寫入方，後端移除後同步無法以「只留 iOS」的方式續存；故刪除 iOS 的 Core/Sync 同步層、Features/App 的雲端登入與同步引擎、同步總開關與相關測試。
- iOS 維持本機 SwiftData 為唯一資料來源。同步原為 opt-in 且預設關閉 (CloudSyncFeatureFlag.isEnabled 為 false)，本次移除對現行使用者行為零影響。
- Firebase 降為純遙測底座：保留 FirebaseCore、Crashlytics、Analytics 與 FirebaseApp.configure() 啟動鏈路，移除同步專屬的 Firestore、Auth、Storage、Messaging、Performance 與 GoogleSignIn 產品。
- SwiftData schema 升 V13 (lightweight)：從 models 移除同步 sidecar 表 SyncMeta 與 SyncQueueItem 並凍結 V12 影子，遷移為 forward-only、不降版。
- shared/data-model 整層保留，codegen.yaml 降級為 swift-only (移除 Web 與 Backend 兩個 TypeScript 產出目標)，使產線設定回到 data-model-codegen 既有規格所要求的「production 只配置 Swift target」。
- 移除跨平台同步一致性向量目錄 shared/sync-conformance。
- monorepo 維持 apps/ 加 shared/ 佈局，不收斂為根目錄單一專案。
- 文件與 openspec spec 同步移除或改寫，維持與純 iOS 現況一致。

## Non-Goals

- 不把 monorepo 收斂為根目錄單一 iOS 專案；維持 apps/apple 加 shared/ 佈局以保留未來接 Android 的空間。
- 不移除 shared/data-model 的 schema 到 codegen 產生層，也不把生成的 Swift 固化為手寫檔。
- 不移除 Firebase 遙測底座；FirebaseCore、Crashlytics、Analytics 與其 OTHER_LDFLAGS 的 -ObjC linker flag、GoogleService-Info.plist、Crashlytics 符號上傳 build phase 一律保留。
- 不改動既有 V10 到 V12 的 SwiftData 版本鏈，也不降版；只往上新增 V13。
- 不動 apps/android 這個文件化保留位置。
- 撤銷 Firebase admin service account 金鑰屬 GCP 或 Firebase console 操作，不在本 change 的程式碼範圍內；於實作收尾提醒使用者手動撤銷。

## Capabilities

### New Capabilities

(none)

### Modified Capabilities

- `cross-device-sync`: 移除全部 requirement，雲端跨裝置同步整體廢止
- `firebase-authentication`: 移除全部 requirement，後端 Firebase ID token 驗證廢止
- `firestore-realtime-projection`: 移除全部 requirement，Firestore per-user 投影廢止
- `multi-user-data-ownership`: 移除全部 requirement，回到單機單使用者
- `sync-conflict-resolution`: 移除全部 requirement，後端欄位級合併廢止
- `sync-failure-recovery`: 移除全部 requirement，待送佇列與重送廢止
- `monorepo-layout`: 從保留的可部署單元清單移除 apps/web 與 apps/backend
- `order-batch-status-update`: 移除 backend 與 web 的雲端 requirement，保留 Apple 本機批次更改狀態能力

## Impact

- Affected specs: cross-device-sync、firebase-authentication、firestore-realtime-projection、multi-user-data-ownership、sync-conflict-resolution、sync-failure-recovery (以上全部 requirement 移除)、monorepo-layout、order-batch-status-update (以上部分改寫)
- Affected code:
  - Removed:
    - apps/web/
    - apps/backend/
    - deploy/
    - Makefile
    - firebase.json
    - firestore.rules
    - shared/sync-conformance/
    - apps/apple/BuyLedger/Core/Sync/BackendAPIClient.swift
    - apps/apple/BuyLedger/Core/Sync/CloudSyncFieldMerge.swift
    - apps/apple/BuyLedger/Core/Sync/Hlc.swift
    - apps/apple/BuyLedger/Core/Sync/HlcClient.swift
    - apps/apple/BuyLedger/Core/Sync/JSONValue.swift
    - apps/apple/BuyLedger/Core/Sync/NetworkPathMonitor.swift
    - apps/apple/BuyLedger/Core/Sync/PhotoRefResolver.swift
    - apps/apple/BuyLedger/Core/Sync/SyncMetaPersistence.swift
    - apps/apple/BuyLedger/Core/Sync/SyncQueuePersistence.swift
    - apps/apple/BuyLedger/Core/Sync/SyncMeta.swift
    - apps/apple/BuyLedger/Core/Sync/SyncQueueItem.swift
    - apps/apple/BuyLedger/Features/App/CloudAuth.swift
    - apps/apple/BuyLedger/Features/App/CloudSignInView.swift
    - apps/apple/BuyLedger/Features/App/CloudSync.swift
    - apps/apple/BuyLedger/Features/App/CloudSyncEngine.swift
    - apps/apple/BuyLedger/Features/App/CloudAccountSettingsSection.swift
    - apps/apple/BuyLedger/Features/App/AppRootView.swift
    - apps/apple/BuyLedger/App/CloudSyncFeatureFlag.swift
    - apps/apple/BuyLedger/Shared/Extensions/NotificationName+Extensions.swift
    - apps/apple/BuyLedgerTests/BackendAPIClientTests.swift
    - apps/apple/BuyLedgerTests/CloudSyncEngineReconcileTests.swift
    - apps/apple/BuyLedgerTests/CloudSyncFieldMergeTests.swift
    - apps/apple/BuyLedgerTests/SyncMetaPersistenceTests.swift
    - apps/apple/BuyLedgerTests/HlcConformanceTests.swift
  - Modified:
    - apps/apple/BuyLedger/App/BuyLedgerApp.swift
    - apps/apple/BuyLedger/Core/Networking/AppConfiguration.swift
    - apps/apple/BuyLedger/Core/Dependencies/OrderRepository.swift
    - apps/apple/BuyLedger/Features/Settings/SettingsView.swift
    - apps/apple/BuyLedger/Features/Settings/SettingsMacView.swift
    - apps/apple/BuyLedger/Features/Orders/OrdersFeature.swift
    - apps/apple/BuyLedger/Core/Persistence/BuyLedgerSchema.swift
    - apps/apple/BuyLedger/Resources/Info.plist
    - apps/apple/BuyLedger.xcodeproj/project.pbxproj
    - apps/apple/BuyLedger.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved
    - apps/apple/BuyLedgerTests/AppConfigurationTests.swift
    - apps/apple/BuyLedgerTests/AISummaryFeatureTests.swift
    - shared/data-model/codegen.yaml
    - shared/data-model/README.md
    - README.md
    - CLAUDE.md
    - apps/apple/CLAUDE.md
    - .gitignore
  - Dependencies: 移除 firebase-ios-sdk 的 FirebaseFirestore、FirebaseAuth、FirebaseStorage、FirebaseMessaging、FirebasePerformance 產品與 GoogleSignIn-iOS 套件；保留 firebase-ios-sdk 的 FirebaseCore、FirebaseCrashlytics、FirebaseAnalytics
