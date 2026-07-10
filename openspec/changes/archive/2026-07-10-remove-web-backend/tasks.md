## 1. 移除 Web / Backend 與部署基礎設施

- [x] 1.1 [P] 刪除整個 apps/web 目錄。完成後 apps/ 不再含 web，且 `grep -rn "apps/web" --include=*.swift apps/apple` 無任何程式碼引用 (僅可能殘留待第 7 組清理的文件/註解)。驗證：目錄不存在、iOS 專案不受影響。
- [x] 1.2 [P] 刪除整個 apps/backend 目錄 (含 Prisma、firebase-admin、Firestore mirror 與 service account 金鑰檔)。驗證：目錄不存在。
- [x] 1.3 [P] 刪除 deploy/ 目錄、根 Makefile、firebase.json、firestore.rules。行為：repo 不再有任何 Docker/compose 部署物件與 Firestore 部署設定。驗證：四者不存在；`make` 無 target。
- [x] 1.4 於實作紀錄提醒使用者手動作業：到 Firebase / GCP console 撤銷 (disable/rotate) apps/backend 內的 admin service account 金鑰，並檢查 git 歷史是否曾提交該金鑰。行為：高權限憑證失效。驗證：使用者確認 console 已撤銷 (change 外動作，僅提醒不代執行)。

## 2. shared/data-model 降級與 sync-conformance 移除

- [x] 2.1 將 shared/data-model/codegen.yaml 降為 swift-only：移除指向 apps/web、apps/backend 的兩個 typescript target，只留 swift target；同步刪除 apps/web、apps/backend 內的生成目錄 (已隨第 1 組消失)。行為：codegen 只產出 iOS Swift。驗證：`cd shared/data-model/generator && bun run generate && bun run check` exit 0。
- [x] 2.2 [P] 刪除 shared/sync-conformance/ 整個目錄 (hlc-vectors、field-merge-vectors、field-categories、README)。行為：跨平台同步一致性向量不再存在。驗證：目錄不存在；其唯一 iOS 消費者 HlcConformanceTests 於第 4 組一併移除。

## 3. iOS 拆除雲端同步接線 (刪檔前先拆線，避免編譯期斷鏈)

- [x] 3.1 讓 App 根 view 不再經雲端閘門：移除 Features/App/AppRootView.swift，將 App/BuyLedgerApp.swift 的根 view 改為直接使用 RootView(store:)。行為：App 啟動直接進主畫面、無登入閘門 (與 flag OFF 時行為一致)。驗證：iOS build 成功、App 啟動顯示 RootView。
- [x] 3.2 從 Features/Settings/SettingsView.swift 與 SettingsMacView.swift 移除 CloudSyncFeatureFlag gate 與 CloudAccountSettingsSection 區塊。行為：設定頁不再出現雲端帳號/登入/登出 UI。驗證：iOS 與 macOS build 成功、設定頁無雲端區塊。
- [x] 3.3 從 Core/Networking/AppConfiguration.swift 移除 backendBaseURL 成員 (屬性與 liveValue/testValue/previewValue 三處)，保留 exchangeRateAPIKey / ollamaAPIKey；同步更新 BuyLedgerTests/AppConfigurationTests.swift (移除 backendBaseURL 斷言) 與 AISummaryFeatureTests.swift (移除 backendBaseURL 建構引數)。行為：設定僅提供 FX/AI 兩把 key。驗證：測試 target 編譯通過、AppConfigurationTests 綠。
- [x] 3.4 移除 Core/Dependencies/OrderRepository.swift 的三個同步通知 helper (postOrderSaved / postResyncNeeded / postOrderDeleted) 與其呼叫，並移除 Shared/Extensions/NotificationName+Extensions.swift (三個 Notification.Name 的唯一定義處)——兩者為編譯期硬綁定，必須同批。行為：本機寫入不再送出同步通知。驗證：iOS build 成功、無「找不到 Notification.Name 成員」錯誤。
- [x] 3.5 [P] 移除 Features/Orders/OrdersFeature.swift 的 reloadFromStore action 與其 handler (移除同步後無觸發者的孤兒)。行為：Orders reducer 無死 action。驗證：OrdersFeatureTests 綠、build 成功。

## 4. 刪除 iOS 雲端同步程式碼與測試

- [x] 4.1 刪除 Features/App 的五個雲端檔：CloudAuth.swift、CloudSignInView.swift、CloudSync.swift、CloudSyncEngine.swift、CloudAccountSettingsSection.swift。行為：無 Firebase Auth/Firestore listener 引擎。驗證：檔案不存在、三平台 build 成功。
- [x] 4.2 刪除 Core/Sync 的九個純同步檔：BackendAPIClient、CloudSyncFieldMerge、Hlc、HlcClient、JSONValue、NetworkPathMonitor、PhotoRefResolver、SyncMetaPersistence、SyncQueuePersistence (SyncMeta / SyncQueueItem 兩個 @Model 留待第 5 組 V13 遷移後刪)。驗證：九檔不存在、build 成功。
- [x] 4.3 [P] 刪除 App/CloudSyncFeatureFlag.swift。行為：無同步總開關型別。驗證：檔案不存在、無殘留引用。
- [x] 4.4 [P] 刪除五個同步測試：BuyLedgerTests/BackendAPIClientTests、CloudSyncEngineReconcileTests、CloudSyncFieldMergeTests、SyncMetaPersistenceTests、HlcConformanceTests。行為：測試套件不再含同步測試。驗證：測試 target 編譯通過、無引用已刪型別。

## 5. SwiftData schema 處置 (D2-A：保留 V12 空表；V13 實作證實不可行)

- [x] 5.1 保留 Core/Persistence/BuyLedgerSchema.swift 的 V12 為 target，不新增版本、不改 migration plan。行為：停在 V12 的 on-disk store 開啟時遷移 delta 為 0、不砍任何資料；兩張空 sidecar 表留著、無成本。驗證：SchemaMigrationTests 綠 (V10→V11→V12 全鏈)、App 於既有 store 上啟動不觸發 makeForApp() 砍檔。備註：原擬升 V13 drop 兩表，但 V13 移除 sidecar 後 schema 形狀與 V11 完全相同，CoreData staged migration 因 checksum 撞版拋 `Duplicate version checksums across stages detected` (實測 SchemaMigrationTests crash 佐證)，故 V13 於此版本鏈不可行 (詳見 design.md D2)。
- [x] 5.2 保留 Core/Sync/SyncMeta.swift 與 Core/Sync/SyncQueueItem.swift 兩個 @Model 檔 (V12 的 models 仍引用；其持久層與同步引擎已於第 4 組刪除)。行為：兩個 sidecar model 定義留存供 V12 schema 引用。驗證：三平台 build 成功、無對已刪型別的殘留引用。

## 6. Xcode 專案設定 (依 D1 保留遙測底座；用 Xcode 操作，勿手改 pbxproj)

- [x] 6.1 於 Xcode 對 BuyLedger target 移除同步專屬 SPM 產品：FirebaseFirestore、FirebaseAuth、FirebaseStorage、FirebaseMessaging、FirebasePerformance 與 GoogleSignIn、GoogleSignInSwift，並移除 GoogleSignIn-iOS 的 XCRemoteSwiftPackageReference；保留 FirebaseCore、FirebaseCrashlytics、FirebaseAnalytics、firebase-ios-sdk 套件、GoogleService-Info.plist、OTHER_LDFLAGS=-ObjC 與 Crashlytics 符號上傳 build phase。行為：App 仍初始化 Firebase 且 Crashlytics/Analytics 遙測運作，但不再連結任何同步用產品。驗證：Package.resolved 由 Xcode 重解析後三平台 build 成功、App 啟動 FirebaseApp.configure() 正常。
- [x] 6.2 從 apps/apple/BuyLedger/Resources/Info.plist 移除 BACKEND_API_BASE_URL、CFBundleURLTypes 內的 Google REVERSED_CLIENT_ID URL scheme、UIBackgroundModes 的 remote-notification、以及為 Google URL scheme 例外而加的 NSApplicationCrashOnExceptions。行為：App 不再宣告後端位址、Google 登入 URL scheme 或推播背景模式。驗證：build 成功、App 啟動不因缺少 URL scheme 而異常。

## 7. 文件與 spec 同步

- [x] 7.1 [P] 改寫 README.md：移除「Web 全棧一鍵啟動」整節、專案結構樹的 web/backend/deploy/Makefile、平台導覽表的 Web 前端/後端兩列、引言的平台措辭。行為：README 只描述純 iOS 現況。驗證：`grep -niE "apps/web|apps/backend|deploy/|make up" README.md` 無殘留 (openspec 佈局敘述除外)。
- [x] 7.2 [P] 改寫根 CLAUDE.md「Monorepo 佈局」與「跨平台 Data Model」段，移除 apps/web、apps/backend、deploy、make up、shared/sync-conformance 敘述，data-model 段改述 swift-only。行為：root 規範反映純 iOS。驗證：內容與現況一致、無矛盾敘述。
- [x] 7.3 [P] 改寫 apps/apple/CLAUDE.md：移除整節「跨裝置同步 (opt-in、離線優先)」、改寫「Firebase 套件與登入」節為僅保留 FirebaseCore/Crashlytics/Analytics (移除 Auth/Firestore/Storage/GoogleSignIn 敘述)、保留「OTHER_LDFLAGS=-ObjC 不可移除」與 AppLaunchConfigurator Firebase 初始化敘述。行為：平台硬規則反映 D1 後現況。驗證：無殘留同步/GoogleSignIn 硬規則。
- [x] 7.4 [P] 改寫 shared/data-model/README.md 的生成目標敘述為 swift-only；更新 .gitignore 移除 web/backend/deploy 忽略項 (.next、apps/web|backend/node_modules、deploy/*.env、adminsdk 金鑰)。行為：文件與忽略規則與現況一致。驗證：`grep -niE "apps/web|apps/backend|deploy/" .gitignore` 無殘留。

## 8. 驗收

- [x] 8.1 三平台驗證：依 apps/apple/CLAUDE.md 規則先遞增 build number，序列化執行 iOS、iPadOS、macOS build 與 BuyLedgerTests。行為：純 iOS App 三平台可 build、測試全綠、所有本機功能行為與移除前一致。驗證：三平台 build BUILD SUCCEEDED、測試套件通過、手動確認訂單/開團/分析/匯率/AI/照片與設定頁正常。

## 9. Spec 退場對照 (requirement 到移除機制的 traceability)

- [x] 9.1 cross-device-sync 隨第 1、4 組移除退場，archive 時套用 REMOVED delta。涵蓋 requirement：Opt-in cross-device propagation between same-account platforms；Clients write through the backend and read the projection。驗證：archive 後 openspec/specs/cross-device-sync 不再存在。
- [x] 9.2 firebase-authentication 隨第 1 組刪 apps/backend 退場，archive 時套用 REMOVED delta。涵蓋 requirement：Backend verifies Firebase ID tokens on protected endpoints；Authenticated request context exposes the caller uid；Supported sign-in providers are Google and Apple only；Missing Firebase credentials fail closed；iOS sign-in is gated behind a default-off feature flag。驗證：archive 後該 spec 不再存在。
- [x] 9.3 firestore-realtime-projection 隨第 1 組刪 apps/backend 與第 4 組刪 iOS listener 退場，archive 時套用 REMOVED delta。涵蓋 requirement：Backend is the sole writer of Firestore；Authoritative writes are mirrored to per-user Firestore collections；Firestore is non-authoritative；Mirror covers all mirrored collections；Mirrored documents stay within the Firestore document size limit；iOS Firestore sync is gated behind a default-off feature flag；Projection carries clocks, tombstones, and photo references；A permanently failed mirror still converges。驗證：archive 後該 spec 不再存在。
- [x] 9.4 multi-user-data-ownership 隨第 1 組刪 apps/backend 退場，archive 時套用 REMOVED delta。涵蓋 requirement：Domain entities are owned by a single user；Reads are scoped to the caller's uid；Writes target only records owned by the caller；Settings are per-user；Seeded development data carries explicit ownership。驗證：archive 後該 spec 不再存在。
- [x] 9.5 sync-conflict-resolution 隨第 2、4 組移除 HLC 與同步向量退場，archive 時套用 REMOVED delta。涵蓋 requirement：Field-level merge with strict-greater clock acceptance；HLC operations are identical across platforms and clamped by the backend；Delete is a clocked tombstone with non-lossy resurrection。驗證：archive 後該 spec 不再存在。
- [x] 9.6 sync-failure-recovery 隨第 3、4、5 組移除待送佇列與 SyncMeta 退場，archive 時套用 REMOVED delta。涵蓋 requirement：Bounded client retry then observable pending or failed state；Resends are idempotent and side effects are clock-guarded；A lost ack does not pin a field dirty forever。驗證：archive 後該 spec 不再存在。
- [x] 9.7 monorepo-layout 隨第 1、7 組移除 apps/web、apps/backend 退場，archive 時套用 MODIFIED delta。涵蓋 requirement：Reserved future directories are documented, not stubbed。驗證：archive 後該 requirement 只列 apps/android 為保留目錄。
- [x] 9.8 order-batch-status-update 隨第 1 組刪 backend/web 退場，archive 時套用 REMOVED delta，保留 Apple 本機四條 requirement。涵蓋 requirement：Backend batch status endpoint is owner-scoped and re-mirrors Firestore；Web batch status update invalidates orders and campaigns。驗證：archive 後該 spec 僅剩 Apple 本機能力。
