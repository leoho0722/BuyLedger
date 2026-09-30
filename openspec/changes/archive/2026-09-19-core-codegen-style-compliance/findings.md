# 第 1 步 (Core 與 codegen) 審查明細

來源：2026-09-14 全庫審查報告 https://claude.ai/code/artifact/597ba71e-a378-427e-a2d6-3ba4033445e1
已排除 FM2 尾隨空白 (commit 291d841 已清) 與建議級項目。

清單涵蓋的是 2026-09-14 當時既有的檔案 (Core 71 檔加 2 個 codegen golden fixture)。本 change 新增的 `RecordDecodingError.swift` 與 `PhotoImportResult.swift` 不在清單內，直接以 ios-dev-kit 為準。

清單已排除審查當時就登記為例外的項目。Core 與 codegen 範圍的既有登記例外共 18 筆：`TC4 宣告 testValue` 17 筆 (struct-of-closures 形式的 Client 與 repository)、`禁 .shared` 1 筆 (`Core/Persistence/PersistenceContainer.swift`)，完整說明見 design.md「本 change 接受的規範例外」。

這份清單只有規則代碼與數量，沒有行號與原文：2026-09-14 那次掃描是一次性腳本產出的，腳本已不存在，本 change 沒有可重跑的規則掃描器。因此驗收分兩段：行寬、尾隨空白、檔頭日期三項用 design.md 列的固定命令檢查，其餘項目逐檔對照本清單與 ios-dev-kit 的 references 人工核對，處理過的項目代碼逐檔記在 tasks.md。

## apps/ios/BuyLedger/Core/Dependencies/BiometricAuthClient.swift

判讀違規：
- 為測試放寬存取層級
- doc 以 API／型別名代替白話

機械規則：MK1×4、FM9×4、H1×1

## apps/ios/BuyLedger/Core/Dependencies/CalendarReminderClient.swift

判讀違規：
- 包裝底層錯誤用 underlying／避免 Equatable
- doc 冗言與術語

機械規則：MK1×4、FM1×4、H1×1、D9×1、FM0×1

## apps/ios/BuyLedger/Core/Dependencies/CampaignReminderRepository.swift

判讀違規：
- doc 術語與複述名稱

機械規則：MK1×3、H1×1、FM1×1

## apps/ios/BuyLedger/Core/Dependencies/CampaignRepository.swift

判讀違規：
- doc 術語與複述名稱

機械規則：MK1×2、H1×1

## apps/ios/BuyLedger/Core/Dependencies/CategoryRepository.swift

判讀違規：
- doc 術語

機械規則：MK1×2、H1×1

## apps/ios/BuyLedger/Core/Dependencies/CurrencyMetadataRepository.swift

判讀違規：
- 包裝底層錯誤用 underlying／避免 Equatable
- LocalizedError 只給顯示用
- 時間相依走 @Dependency／依賴不給預設值
- 泛型參數具名
- 只有一個具體型別卻寫成 generic
- doc 與實作不符
- doc 術語

機械規則：FM1×6、MK1×3、D9×2、H1×1、MK4×1、MK5×1

## apps/ios/BuyLedger/Core/Dependencies/NameLookupOperations.swift

判讀違規：
- doc 術語與複述名稱

機械規則：H1×1

## apps/ios/BuyLedger/Core/Dependencies/OpenSettingsClient.swift

機械規則：MK1×2、H1×1

## apps/ios/BuyLedger/Core/Dependencies/OrderRepository.swift

判讀違規：
- Bool 命名
- doc 以識別字與術語代替白話

機械規則：FM1×7、MK1×3、H1×1、MK4×1、MK5×1

## apps/ios/BuyLedger/Core/Dependencies/OrderSourceRepository.swift

判讀違規：
- doc 術語

機械規則：MK1×2、H1×1、FM1×1

## apps/ios/BuyLedger/Core/Dependencies/PaymentMethodRepository.swift

判讀違規：
- doc 術語與複述名稱

機械規則：FM1×4、MK1×2、H1×1

## apps/ios/BuyLedger/Core/Dependencies/PhotoClient.swift

判讀違規：
- 失敗有原因卻靜默吞掉

機械規則：MK1×2、H1×1、IM3×1、FM0×1

## apps/ios/BuyLedger/Core/Dependencies/ReconciliationStatusRepository.swift

判讀違規：
- doc 術語

機械規則：FM1×4、MK1×2、H1×1

## apps/ios/BuyLedger/Core/Dependencies/TelemetryClient.swift

機械規則：MK1×2、H1×1

## apps/ios/BuyLedger/Core/Diagnostics/AppLogger.swift

判讀違規：
- Core 不知道 Feature 存在
- 成員未從 private 起手
- doc 術語

機械規則：MK5×3、H1×1、MK4×1、MK1×1

## apps/ios/BuyLedger/Core/Diagnostics/CrashDiagnosticsClient.swift

機械規則：MK1×2、H1×1

## apps/ios/BuyLedger/Core/Domain/Campaign+Samples.swift

機械規則：H1×1、D1×1

## apps/ios/BuyLedger/Core/Domain/Campaign.swift

機械規則：H1×1、MK1×1

## apps/ios/BuyLedger/Core/Domain/CampaignStatus.swift

機械規則：H1×1、MK1×1

## apps/ios/BuyLedger/Core/Domain/CurrencyCode.swift

判讀違規：
- Locale 走 @Dependency／無用程式碼
- doc 術語

機械規則：MK1×2、H1×1

## apps/ios/BuyLedger/Core/Domain/CustomerTier.swift

機械規則：H1×1、MK1×1

## apps/ios/BuyLedger/Core/Domain/FxRateSnapshot.swift

機械規則：H1×1、MK1×1

## apps/ios/BuyLedger/Core/Domain/FxRates.swift

判讀違規：
- 縮寫大小寫
- ?? 掩蓋應視為錯誤的 nil

機械規則：H1×1、MK1×1

## apps/ios/BuyLedger/Core/Domain/Generated/Campaign.generated.swift

判讀違規：
- doc 複述名稱 (需改 generator)

機械規則：H1×1

## apps/ios/BuyLedger/Core/Domain/Generated/CampaignStatus.generated.swift

機械規則：H1×1

## apps/ios/BuyLedger/Core/Domain/Generated/CurrencyCode.generated.swift

判讀違規：
- doc 複述名稱 (需改 generator；已查證 schema doc 字串無複述型別名，本步不改 schema)

機械規則：H1×1

## apps/ios/BuyLedger/Core/Domain/Generated/CustomerTier.generated.swift

機械規則：H1×1

## apps/ios/BuyLedger/Core/Domain/Generated/FxRateSnapshot.generated.swift

機械規則：H1×1

## apps/ios/BuyLedger/Core/Domain/Generated/LedgerCustomer.generated.swift

機械規則：H1×1

## apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrder.generated.swift

機械規則：H1×1

## apps/ios/BuyLedger/Core/Domain/Generated/LedgerOrderItem.generated.swift

判讀違規：
- UUID 走 @Dependency (需改 generator) — **本 change 接受的規範例外，留待後續步**，見 design.md「本 change 接受的規範例外」

機械規則：H1×1

## apps/ios/BuyLedger/Core/Domain/Generated/Money.generated.swift

機械規則：H1×1

## apps/ios/BuyLedger/Core/Domain/Generated/OrderStatus.generated.swift

機械規則：H1×1

## apps/ios/BuyLedger/Core/Domain/Generated/PaymentMethodInfo.generated.swift

機械規則：H1×1

## apps/ios/BuyLedger/Core/Domain/Generated/PaymentReceiptStatus.generated.swift

機械規則：H1×1

## apps/ios/BuyLedger/Core/Domain/LedgerOrder+Samples.swift

機械規則：D1×2、H1×1、FM4×1、FM1×1、FM10×1

## apps/ios/BuyLedger/Core/Domain/LedgerOrder.swift

判讀違規：
- 多餘的參數標籤
- Bool 命名

機械規則：H1×1、MK1×1、CL2×1

## apps/ios/BuyLedger/Core/Domain/LedgerOrderItem.swift

判讀違規：
- doc 術語

機械規則：D1×3、MK1×2、H1×1

## apps/ios/BuyLedger/Core/Domain/OrderMerge.swift

判讀違規：
- tuple 超過兩個元素
- doc 術語

機械規則：H1×1、MK1×1、D6×1

## apps/ios/BuyLedger/Core/Domain/OrderStatus.swift

機械規則：MK1×2、H1×1

## apps/ios/BuyLedger/Core/Domain/OrderSummary.swift

判讀違規：
- 補充說明用 - Note

機械規則：H1×1、MK1×1、FM1×1、D6×1

## apps/ios/BuyLedger/Core/Domain/PaymentMethodFlags.swift

判讀違規：
- 不為補註解新增顯式 init

機械規則：MK1×2、H1×1

## apps/ios/BuyLedger/Core/Domain/PaymentMethodInfo.swift

判讀違規：
- 分區語意

機械規則：H1×1

## apps/ios/BuyLedger/Core/Domain/PaymentReceiptStatus.swift

機械規則：H1×1、MK1×1

## apps/ios/BuyLedger/Core/Networking/APIError.swift

判讀違規：
- 包裝底層錯誤用 underlying／避免 Equatable
- enum case 不重複型別名

機械規則：H1×1、MK1×1

## apps/ios/BuyLedger/Core/Networking/AppConfiguration.swift

判讀違規：
- 為測試放寬存取層級

機械規則：MK1×3、H1×1、D6×1

## apps/ios/BuyLedger/Core/Networking/ExchangeRateClient.swift

判讀違規：
- 錯誤分類不符

機械規則：TC1×5、MK1×2、D6×2、FM1×2、H1×1

## apps/ios/BuyLedger/Core/Networking/ExchangeRateDTO.swift

判讀違規：
- CodingKeys 放 Nested Types extension

機械規則：D1×8、MK1×6、H1×1、FN1×1

## apps/ios/BuyLedger/Core/Networking/HTTPClient.swift

判讀違規：
- doc 術語與摘要多行

機械規則：MK1×3、FM1×2、H1×1、D1×1

## apps/ios/BuyLedger/Core/Networking/HTTPMethod.swift

機械規則：H1×1、MK1×1

## apps/ios/BuyLedger/Core/Networking/URLRequestBuilder.swift

機械規則：H1×1、MK1×1

## apps/ios/BuyLedger/Core/Persistence/BuyLedgerSchema.swift

判讀違規：
- doc 複述名稱

機械規則：D1×98、FM10×82、MK1×12、MK5×5、MK4×2、H1×1、FN1×1、FM4×1、C3×1

## apps/ios/BuyLedger/Core/Persistence/CampaignPersistence.swift

判讀違規：
- doc 術語

機械規則：H1×1

## apps/ios/BuyLedger/Core/Persistence/CampaignRecord.swift

判讀違規：
- ?? 掩蓋應視為錯誤的 nil

機械規則：MK1×2、H1×1

## apps/ios/BuyLedger/Core/Persistence/CampaignReminderPersistence.swift

判讀違規：
- doc 術語

機械規則：H1×1

## apps/ios/BuyLedger/Core/Persistence/CampaignReminderRecord.swift

機械規則：H1×1、MK1×1

## apps/ios/BuyLedger/Core/Persistence/CategoryRecord.swift

機械規則：H1×1、MK1×1

## apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataPersistence.swift

判讀違規：
- doc 標記順序

機械規則：H1×1、CL1×1

## apps/ios/BuyLedger/Core/Persistence/CurrencyMetadataRecord.swift

機械規則：H1×1、MK1×1

## apps/ios/BuyLedger/Core/Persistence/NameLookupPersistence.swift

機械規則：H1×1、CL1×1

## apps/ios/BuyLedger/Core/Persistence/NameLookupRecord.swift

判讀違規：
- 角色 protocol 命名

機械規則：H1×1、MK1×1、MK4×1

## apps/ios/BuyLedger/Core/Persistence/OrderPersistence.swift

判讀違規：
- 成員未從 private 起手
- doc 術語

機械規則：H1×1、FM4×1、FM1×1

## apps/ios/BuyLedger/Core/Persistence/OrderRecord.swift

判讀違規：
- ?? 掩蓋應視為錯誤的 nil

機械規則：MK1×2、H1×1

## apps/ios/BuyLedger/Core/Persistence/OrderSourceRecord.swift

機械規則：H1×1、MK1×1

## apps/ios/BuyLedger/Core/Persistence/PaymentMethodPersistence.swift

判讀違規：
- fatalError 不用於執行期狀況
- 泛型參數具名
- doc 術語

機械規則：CL2×4、CL1×2、D6×2、H1×1、FM1×1

## apps/ios/BuyLedger/Core/Persistence/PaymentMethodRecord.swift

機械規則：H1×1、MK1×1

## apps/ios/BuyLedger/Core/Persistence/PersistenceContainer.swift

判讀違規：
- Bool 命名
- doc 術語

機械規則：MK5×2、D3×2、H1×1、MK1×1、D9×1、FM1×1

## apps/ios/BuyLedger/Core/Persistence/PersistenceError.swift

判讀違規：
- 包裝底層錯誤用 underlying／避免 Equatable
- LocalizedError 只給顯示用
- 手寫實作的 protocol 遵循寫在型別行
- 泛型參數具名
- 只有一個具體型別卻寫成 generic

機械規則：D9×11、MK1×5、MK4×5、MK5×5、H1×1

## apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantine.swift

判讀違規：
- doc 術語

機械規則：H1×1、D6×1

## apps/ios/BuyLedger/Core/Persistence/PersistenceStoreQuarantineClient.swift

機械規則：MK1×2、H1×1

## apps/ios/BuyLedger/Core/Persistence/ReconciliationStatusRecord.swift

機械規則：H1×1、MK1×1

## shared/data-model/fixtures/expected/swift/SampleOrder.generated.swift

判讀違規：
- Note 以外的自由段落 (generator 模板)
- doc 複述名稱 (generator 模板)
- 時間與 UUID 走依賴注入 (generator 模板) — UUID 部分是**本 change 接受的規範例外**；時間部分已查證無違規實例 (`datamodel-gen` 只支援 `$newUUID` 一種計算型預設值，沒有時間 sentinel)

## shared/data-model/fixtures/expected/swift/SampleStatus.generated.swift

判讀違規：
- 手寫 protocol 遵循位置 (generator 模板)

