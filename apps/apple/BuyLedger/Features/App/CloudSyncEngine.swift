//
//  CloudSyncEngine.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/21.
//

@preconcurrency import FirebaseFirestore
import FirebaseInstallations
import Foundation

/// 跨裝置同步引擎 (對齊 cross-device-sync)。sync 啟用 (登入 + flag) 時運作：
/// - PULL：監聽 `users/{uid}/orders` 投影快照，逐欄解碼後 upsert 進本機 SwiftData (A→B)。
/// - PUSH：本機變更以 partial patch (僅變更欄位 + 每欄位 HLC) 推送後端 (B→A / 衝突)。
///
/// sync 關閉時 App 不建立本物件、完全不觸 Firestore (對齊 ``CloudSyncFeatureFlag``)。物理時間與
/// writerId 由建立處注入 / 取得，引擎本身不直接讀系統時鐘 (對齊環境相依注入鐵則)。
@MainActor
final class CloudSyncEngine {

    // MARK: - Sync Properties

    /// 目前登入使用者的 uid (決定 Firestore 子集合路徑)。
    private let uid: String

    /// Firestore 投影存取封裝 (提供 orders 集合參照)。
    private let cloudSync: CloudSync

    /// 後端 API 客戶端 (推送 partial patch)。
    private let api: BackendAPIClient

    /// 取得 Firebase ID token 的注入閉包 (供 Authorization header)。
    private let idTokenProvider: () async throws -> String?

    /// 取得當下時間的注入閉包 (供 HLC 物理時間，不直接讀系統時鐘)。
    private let now: () -> Date

    /// 本機訂單持久層 (PULL 時 upsert 投影、啟動後才建立)。
    private var persistence: OrderPersistence?

    /// 待送佇列持久層 (推送失敗時暫存、啟動後才建立)。
    private var queuePersistence: SyncQueuePersistence?

    /// orders 投影快照的監聽註冊 (stop 時移除)。
    private var ordersListener: ListenerRegistration?

    /// 本機最後一次發出的 HLC (供下一次遞增的因果基準)。
    private var lastIssued: Hlc?

    /// 最後一次拉回的訂單版本 (供本機儲存時 diff 出變更欄位)。
    private var lastPulled: [String: LedgerOrder] = [:]

    /// 本機單筆訂單儲存通知的觀察 token。
    private var saveObserver: NSObjectProtocol?

    /// 本機批次 / 合併 / 改名 resync 通知的觀察 token。
    private var resyncObserver: NSObjectProtocol?

    /// 本機訂單刪除通知的觀察 token。
    private var deleteObserver: NSObjectProtocol?

    /// 本機 writerId (HLC 決勝最後一關)，採此安裝的 Firebase Installation ID (FID)；於 ``start()`` 取得並快取。
    private var writerId = ""

    /// 投影合併完成後通知 UI 重載 (由 RootFeature / OrdersFeature 掛上)。
    var onOrdersMerged: (@MainActor () -> Void)?

    // MARK: - Init

    /// 以登入使用者 uid、後端客戶端與注入的 token / 時間閉包建立引擎。
    /// - Parameters:
    ///   - uid: 目前登入使用者的 uid (決定 Firestore 子集合路徑)。
    ///   - api: 推送 partial patch 的後端 API 客戶端。
    ///   - idTokenProvider: 取得 Firebase ID token 的閉包 (供 Authorization header)。
    ///   - now: 取得當下時間的閉包 (供 HLC 物理時間，不直接讀系統時鐘)。
    init(
        uid: String,
        api: BackendAPIClient,
        idTokenProvider: @escaping () async throws -> String?,
        now: @escaping () -> Date
    ) {
        self.uid = uid
        self.cloudSync = CloudSync(uid: uid)
        self.api = api
        self.idTokenProvider = idTokenProvider
        self.now = now
    }

    deinit {
        ordersListener?.remove()
        for observer in [saveObserver, resyncObserver, deleteObserver].compactMap({ $0 }) {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Start & Stop

    /// 啟動：取得本機 writerId (Firebase Installation ID)、建立本機 persistence 與待送佇列，並監聽 orders 投影快照與本機儲存 / resync / 刪除通知。
    func start() async {
        writerId = (try? await Installations.installations().installationID()) ?? ""
        persistence = await MainActor.run {
            OrderPersistence(modelContainer: PersistenceContainer.shared)
        }
        queuePersistence = await MainActor.run {
            SyncQueuePersistence(modelContainer: PersistenceContainer.shared)
        }
        ordersListener = cloudSync.ordersCollection().addSnapshotListener { [weak self] snapshot, _ in
            guard let self, let snapshot else { return }
            let orders = snapshot.documents.compactMap { Self.decodeOrder($0.data()) }
            Task { @MainActor in
                guard let persistence = self.persistence else { return }
                try? await persistence.upsertAll(orders)
                for order in orders {
                    self.lastPulled[order.id] = order
                }
                self.onOrdersMerged?()
            }
        }
        saveObserver = NotificationCenter.default.addObserver(
            forName: .buyLedgerOrderSaved,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self, let order = note.userInfo?["order"] as? LedgerOrder else { return }
            Task { @MainActor in await self.handleLocalSave(order) }
        }
        resyncObserver = NotificationCenter.default.addObserver(
            forName: .buyLedgerOrdersResyncNeeded,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in await self.syncAllLocalChanges() }
        }
        deleteObserver = NotificationCenter.default.addObserver(
            forName: .buyLedgerOrderDeleted,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let self, let id = note.userInfo?["id"] as? String else { return }
            Task { @MainActor in await self.handleLocalDelete(id) }
        }
    }

    /// 停止監聽 (登出 / flag 關閉)。
    func stop() {
        ordersListener?.remove()
        ordersListener = nil
        for observer in [saveObserver, resyncObserver, deleteObserver].compactMap({ $0 }) {
            NotificationCenter.default.removeObserver(observer)
        }
        saveObserver = nil
        resyncObserver = nil
        deleteObserver = nil
    }

    // MARK: - Push

    /// 推送一筆訂單的變更欄位 (B→A / 衝突)。為每個變更欄位產生遞增 HLC，失敗則進待送佇列。
    /// - Parameters:
    ///   - id: 目標訂單 id。
    ///   - changedFields: 本次變更的欄位值 (僅含被改動的欄位)。
    func pushOrder(id: String, changedFields: [String: JSONValue]) async {
        let nowMs = Int(now().timeIntervalSince1970 * 1000)
        var clocks: [String: String] = [:]
        for field in changedFields.keys {
            let next = HlcClock.generate(lastIssued: lastIssued, nowMs: nowMs, writerId: writerId)
            lastIssued = next
            clocks[field] = next.encoded
        }
        await sendPatch(
            id: id,
            changedFields: changedFields,
            clocks: clocks,
            opID: UUID().uuidString
        )
    }

    /// 處理本機訂單儲存：與最後拉回的版本 diff 出變更欄位後推送後端 (B→A / 衝突)。
    /// 新訂單 (無拉回基準) 推全部欄位 → 後端 upsert 建立。
    /// - Parameter order: 本機剛儲存的訂單。
    func handleLocalSave(_ order: LedgerOrder) async {
        let changedFields = Self.diffFields(new: order, baseline: lastPulled[order.id])
        guard !changedFields.isEmpty else { return }
        await pushOrder(id: order.id, changedFields: changedFields)
    }

    /// 處理本機訂單刪除：呼叫後端 DELETE (硬刪 Postgres + Firestore tombstone)，並清掉本機 diff 基準。
    /// - Parameter id: 被刪除的訂單 id。
    func handleLocalDelete(_ id: String) async {
        guard let token = try? await idTokenProvider() else { return }
        try? await api.deleteOrder(token, id)
        lastPulled[id] = nil
    }

    /// 批次 / 合併 / cascade 改名後，重新比對所有本機訂單與最後拉回版本，逐筆推送變更 (走 ``handleLocalSave(_:)``)。
    func syncAllLocalChanges() async {
        guard let persistence, let orders = try? await persistence.fetchAll() else { return }
        for order in orders {
            await handleLocalSave(order)
        }
    }

    /// 連線恢復 / 啟動時重送待送佇列；成功逐筆移除。
    func drainQueue() async {
        guard let queuePersistence, let items = try? await queuePersistence.all() else { return }
        for item in items {
            guard let fieldsData = item.changedFieldsJSON.data(using: .utf8),
                  let fields = try? JSONDecoder().decode([String: JSONValue].self, from: fieldsData),
                  let clocksData = item.fieldClocksJSON.data(using: .utf8),
                  let clocks = try? JSONDecoder().decode([String: String].self, from: clocksData) else {
                continue
            }
            await sendPatch(
                id: item.entityID,
                changedFields: fields,
                clocks: clocks,
                opID: item.opID
            )
        }
    }

    /// 待送佇列筆數 (供演示 / UI 顯示「待同步」狀態)。
    /// - Returns: 目前待送佇列中的項目數；無佇列時為 0。
    func pendingCount() async -> Int {
        (try? await queuePersistence?.count()) ?? 0
    }

#if DEBUG
    /// Dev/演示：直接推送一筆 iOS 來源的測試訂單 (驗證 B→A：iOS → 後端 → web；UI tap 自動化受限的替代)。
    func pushDemoOrder(idSuffix: Int) async {
        let fields: [String: JSONValue] = [
            "customerName": .string("iOS推送測試"),
            "chargedAmount": .string("555"),
            "currency": .string("TWD"),
            "status": .string("confirmed"),
            "categories": .array([.string("未分類")]),
        ]
        await pushOrder(id: "IOS-DEMO-\(idSuffix)", changedFields: fields)
    }

    /// Dev/演示：對既有訂單推送單一欄位變更 (驗證 iOS 參與欄位級合併——iOS 改一欄、web 改另一欄皆存活)。
    func pushFieldDemo(id: String, field: String, value: String) async {
        await pushOrder(id: id, changedFields: [field: .string(value)])
    }
#endif
}

// MARK: - Decode

extension CloudSyncEngine {

    /// Firestore 投影文件 → 領域訂單。decimal 以字串解析、date 為 ISO 字串、照片參照本版暫不取 (留空)。
    /// - Parameter data: Firestore 文件的原始欄位字典。
    /// - Returns: 解析出的領域訂單；缺必要欄位 (id / date) 時為 nil。
    static func decodeOrder(_ data: [String: Any]) -> LedgerOrder? {
        guard let id = data["id"] as? String,
              let dateString = data["date"] as? String,
              let date = parseDate(dateString) else {
            return nil
        }

        let customerData = data["customer"] as? [String: Any] ?? [:]
        let customer = LedgerCustomer(
            name: customerData["name"] as? String ?? "",
            initials: customerData["initials"] as? String ?? "",
            tier: CustomerTier(rawValue: customerData["tier"] as? String ?? "") ?? .new
        )

        let items: [LedgerOrderItem] = (data["items"] as? [[String: Any]] ?? []).compactMap { item in
            guard let name = item["name"] as? String else { return nil }
            return LedgerOrderItem(
                id: UUID(uuidString: item["id"] as? String ?? "") ?? UUID(),
                name: name,
                quantity: item["quantity"] as? Int ?? 0,
                unitPrice: decimal(item["unitPrice"])
            )
        }

        return LedgerOrder(
            id: id,
            customer: customer,
            status: OrderStatus(rawValue: data["status"] as? String ?? "") ?? .quoting,
            currency: CurrencyCode(rawValue: data["currency"] as? String ?? "TWD"),
            date: date,
            items: items,
            itemCost: decimal(data["itemCost"]),
            domesticShipping: decimal(data["domesticShipping"]),
            internationalShipping: decimal(data["internationalShipping"]),
            foreignDomesticShipping: decimal(data["foreignDomesticShipping"]),
            cardFeeRate: decimal(data["cardFeeRate"]),
            platformFeeRate: decimal(data["platformFeeRate"]),
            paymentFeeRate: decimal(data["paymentFeeRate"]),
            chargedAmount: decimal(data["chargedAmount"]),
            cardlessDeductionAmount: decimal(data["cardlessDeductionAmount"]),
            cardlessSupplementAmount: decimal(data["cardlessSupplementAmount"]),
            orderSource: data["orderSource"] as? String ?? "",
            categories: data["categories"] as? [String] ?? [],
            paymentMethod: data["paymentMethod"] as? String ?? "",
            notes: data["notes"] as? String ?? "",
            verificationStatus: data["verificationStatus"] as? String ?? "",
            campaignNames: data["campaignNames"] as? [String] ?? [],
            paymentReceiptStatus: PaymentReceiptStatus(rawValue: data["paymentReceiptStatus"] as? String ?? "")
            ?? .pending,
            isCashOnDelivery: data["isCashOnDelivery"] as? Bool ?? false,
            photos: [],
            mergedSourceIDs: data["mergedSourceIDs"] as? [String] ?? []
        )
    }
}

// MARK: - Local Change Diff

extension CloudSyncEngine {

    /// 領域訂單 → 可推送的 flat 欄位圖 (與後端 orderDomainToFlat 對齊；排除衍生的
    /// isCashOnDelivery 與本版暫不同步的 items / photos)。
    /// - Parameter order: 來源領域訂單。
    /// - Returns: 欄位名 → 值的扁平映射。
    static func fieldMap(_ order: LedgerOrder) -> [String: JSONValue] {
        [
            "customerName": .string(order.customer.name),
            "customerTier": .string(order.customer.tier.rawValue),
            "status": .string(order.status.rawValue),
            "currency": .string(order.currency.rawValue),
            "date": .string(isoWithFraction.string(from: order.date)),
            "itemCost": .string("\(order.itemCost)"),
            "domesticShipping": .string("\(order.domesticShipping)"),
            "internationalShipping": .string("\(order.internationalShipping)"),
            "foreignDomesticShipping": .string("\(order.foreignDomesticShipping)"),
            "cardFeeRate": .string("\(order.cardFeeRate)"),
            "platformFeeRate": .string("\(order.platformFeeRate)"),
            "paymentFeeRate": .string("\(order.paymentFeeRate)"),
            "chargedAmount": .string("\(order.chargedAmount)"),
            "cardlessDeductionAmount": .string("\(order.cardlessDeductionAmount)"),
            "cardlessSupplementAmount": .string("\(order.cardlessSupplementAmount)"),
            "orderSource": .string(order.orderSource),
            "categories": .array(order.categories.map { .string($0) }),
            "paymentMethod": .string(order.paymentMethod),
            "notes": .string(order.notes),
            "verificationStatus": .string(order.verificationStatus),
            "campaignNames": .array(order.campaignNames.map { .string($0) }),
            "paymentReceiptStatus": .string(order.paymentReceiptStatus.rawValue),
        ]
    }

    /// 與最後拉回版本 diff；baseline 為 nil (新訂單) 時回全部欄位。
    /// - Parameters:
    ///   - new: 本機最新版本的訂單。
    ///   - baseline: 最後一次拉回的訂單；nil 視為新訂單。
    /// - Returns: 有變動的欄位映射；新訂單為全部欄位。
    static func diffFields(new: LedgerOrder, baseline: LedgerOrder?) -> [String: JSONValue] {
        let newMap = fieldMap(new)
        guard let baseline else { return newMap }

        let baseMap = fieldMap(baseline)
        var changed: [String: JSONValue] = [:]
        for (key, value) in newMap where baseMap[key] != value {
            changed[key] = value
        }
        return changed
    }
}

// MARK: - Private Method

private extension CloudSyncEngine {

    /// 實際送出；失敗 (離線 / 網路) 進持久化待送佇列，成功則自佇列移除 (同 clocks / opID 重送冪等)。
    /// - Parameters:
    ///   - id: 目標訂單 id。
    ///   - changedFields: 本次變更的欄位值。
    ///   - clocks: 每個變更欄位對應的編碼 HLC。
    ///   - opID: 操作唯一 id (重送冪等鍵)。
    func sendPatch(
        id: String,
        changedFields: [String: JSONValue],
        clocks: [String: String],
        opID: String
    ) async {
        guard let token = try? await idTokenProvider() else { return }
        do {
            _ = try await api.patchOrder(token, id, changedFields, clocks)
            try? await queuePersistence?.delete(opID: opID)
        } catch {
            await enqueueFailed(
                id: id,
                changedFields: changedFields,
                clocks: clocks,
                opID: opID
            )
        }
    }

    /// 將推送失敗的變更編碼為 JSON 後寫入待送佇列 (供連線恢復時重送)。
    /// - Parameters:
    ///   - id: 目標訂單 id。
    ///   - changedFields: 推送失敗的欄位值。
    ///   - clocks: 每個變更欄位對應的編碼 HLC。
    ///   - opID: 操作唯一 id (重送冪等鍵)。
    func enqueueFailed(
        id: String,
        changedFields: [String: JSONValue],
        clocks: [String: String],
        opID: String
    ) async {
        guard let queuePersistence,
              let fieldsData = try? JSONEncoder().encode(changedFields),
              let clocksData = try? JSONEncoder().encode(clocks) else {
            return
        }
        try? await queuePersistence.enqueue(
            opID: opID,
            entityID: id,
            collection: "orders",
            opRaw: "upsert",
            changedFieldsJSON: String(decoding: fieldsData, as: UTF8.self),
            fieldClocksJSON: String(decoding: clocksData, as: UTF8.self),
            enqueuedAt: now()
        )
    }

    // MARK: ISO8601 Date

    /// 解析 ISO8601 日期字串，優先帶小數秒、退回不帶小數秒格式。
    /// - Parameter value: ISO8601 日期字串。
    /// - Returns: 解析出的日期；兩種格式皆不符時為 nil。
    static func parseDate(_ value: String) -> Date? {
        if let date = isoWithFraction.date(from: value) {
            return date
        }
        return isoPlain.date(from: value)
    }

    /// 將 Firestore 欄位值 (字串或數字) 轉為 `Decimal`，無法解析時回 0。
    /// - Parameter value: Firestore 欄位的原始值 (字串或數字)。
    /// - Returns: 轉換後的 `Decimal`；無法解析時為 0。
    static func decimal(_ value: Any?) -> Decimal {
        if let string = value as? String {
            return Decimal(string: string) ?? 0
        }
        if let number = value as? NSNumber {
            return Decimal(string: number.stringValue) ?? 0
        }
        return 0
    }

    /// 帶小數秒的 ISO8601 格式器 (與後端寫出格式對齊)。
    static let isoWithFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// 不帶小數秒的 ISO8601 格式器 (解析舊版或精簡格式的退路)。
    static let isoPlain: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
