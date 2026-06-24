//
//  CloudSyncEngine.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/21.
//

@preconcurrency import FirebaseFirestore
import FirebaseInstallations
import Foundation

/// 跨裝置同步引擎。sync 啟用 (登入 + flag) 時運作：
/// - PULL (A→B)：監聽 `users/{uid}/orders` 投影快照逐欄合併進 SwiftData——
///   僅 remoteClock>localClock 且非 DIRTY 才套用，被略過的較高者記入 pendingRemote 不丟棄
/// - PUSH (B→A / 衝突)：本機變更以 partial patch (變更欄位 + 每欄位 HLC) 推後端，
///   依回應 appliedFieldClocks 逐欄對帳 DIRTY
/// - 刪除：本機刪除推 tombstone；
///   遠端 tombstone 拉回時依 deleteClock 與欄位時鐘判定刪除 / 復活
/// - 待送佇列：推送失敗持久化，app 啟動 + `NWPathMonitor` 重連時 drain 重送
///
/// sync 關閉時不建立本物件、完全不觸 Firestore
/// 物理時間與 writerId 由建立處注入 / 取得，引擎不直接讀系統時鐘
@MainActor
final class CloudSyncEngine {

    // MARK: - Sync Properties

    /// 目前登入使用者的 uid (決定 Firestore 子集合路徑)
    private let uid: String

    /// Firestore 投影存取封裝 (提供 orders 集合參照)
    private let cloudSync: CloudSync

    /// 後端 API 客戶端 (推送 partial patch)
    private let api: BackendAPIClient

    /// 取得 Firebase ID token 的注入閉包 (供 Authorization header)
    private let idTokenProvider: () async throws -> String?

    /// 取得當下時間的注入閉包 (供 HLC 物理時間，不直接讀系統時鐘)
    private let now: () -> Date

    /// 網路連線狀態事件串流的注入閉包 (供重連 drain)
    private let connectivity: () -> AsyncStream<Bool>

    /// 解析照片參照為 `[Data]` 的注入閉包
    /// (預設走 ``PhotoRefResolver``；測試可替換免觸 Storage)
    private let resolvePhotoRefs: ([String]) async -> [Data]

    /// 本機訂單持久層 (PULL 時逐欄合併、啟動後才建立)
    private var persistence: OrderPersistence?

    /// 同步 metadata 持久層 (欄位時鐘 / DIRTY / pendingRemote / tombstone、啟動後才建立)
    private var metaPersistence: SyncMetaPersistence?

    /// 待送佇列持久層 (推送失敗時暫存、啟動後才建立)
    private var queuePersistence: SyncQueuePersistence?

    /// orders 投影快照的監聽註冊 (stop 時移除)
    private var ordersListener: ListenerRegistration?

    /// 本機最後一次發出的 HLC (供下一次遞增的因果基準)；
    /// 於 ``start()`` 自 SyncMeta 載回跨重啟存活
    private var lastIssued: Hlc?

    /// 最後一次拉回的訂單版本 (供本機儲存時 diff 出變更欄位)
    private var lastPulled: [String: LedgerOrder] = [:]

    /// 本機單筆訂單儲存通知的觀察 token
    private var saveObserver: NSObjectProtocol?

    /// 本機批次 / 合併 / 改名 resync 通知的觀察 token
    private var resyncObserver: NSObjectProtocol?

    /// 本機訂單刪除通知的觀察 token
    private var deleteObserver: NSObjectProtocol?

    /// 重連 drain 的監聽 task (stop 時取消)
    private var connectivityTask: Task<Void, Never>?

    /// 上一次觀察到的連線狀態 (用來偵測「斷→連」轉換、只在恢復連線時 drain)
    private var wasConnected = true

    /// 本機 writerId (HLC 決勝最後一關)，採此安裝的 Firebase Installation ID (FID)；
    /// 於 ``start()`` 取得並快取
    private var writerId = ""

    /// 投影合併完成後通知 UI 重載 (由 RootFeature / OrdersFeature 掛上)
    var onOrdersMerged: (@MainActor () -> Void)?

    // MARK: - Static Properties

    /// 刪除時鐘生成時的保留欄位名
    /// (僅供 ``generateFieldClocks(fields:nowMs:writerId:)`` 取單一遞增時鐘，不入欄位圖)
    static let deleteClockField = "_delete"

    /// 帶小數秒的 ISO8601 格式器 (與後端寫出格式對齊)
    static let isoWithFraction: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    /// 不帶小數秒的 ISO8601 格式器 (解析舊版或精簡格式的退路)
    static let isoPlain: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    // MARK: - Init

    /// 以登入使用者 uid、後端客戶端與注入的 token / 時間 / 連線 / 照片解析閉包建立引擎
    /// - Parameters:
    ///   - uid: 目前登入使用者的 uid (決定 Firestore 子集合路徑)
    ///   - api: 推送 partial patch 的後端 API 客戶端
    ///   - idTokenProvider: 取得 Firebase ID token 的閉包 (供 Authorization header)
    ///   - now: 取得當下時間的閉包 (供 HLC 物理時間，不直接讀系統時鐘)
    ///   - connectivity: 連線狀態事件串流的閉包 (供重連 drain；預設不監聽)
    ///   - resolvePhotoRefs: 解析照片參照為 `[Data]` 的閉包 (預設走 ``PhotoRefResolver``)
    init(
        uid: String,
        api: BackendAPIClient,
        idTokenProvider: @escaping () async throws -> String?,
        now: @escaping () -> Date,
        connectivity: @escaping () -> AsyncStream<Bool> = { AsyncStream { $0.finish() } },
        resolvePhotoRefs: @escaping ([String]) async -> [Data] = { await PhotoRefResolver.resolve(refs: $0) }
    ) {
        self.uid = uid
        self.cloudSync = CloudSync(uid: uid)
        self.api = api
        self.idTokenProvider = idTokenProvider
        self.now = now
        self.connectivity = connectivity
        self.resolvePhotoRefs = resolvePhotoRefs
    }

    deinit {
        ordersListener?.remove()
        connectivityTask?.cancel()
        for observer in [saveObserver, resyncObserver, deleteObserver].compactMap({ $0 }) {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Start & Stop

    /// 啟動引擎：建立持久層、訂閱 orders 投影與本機通知、drain 佇列並監聽連線恢復
    func start() async {
        writerId = (try? await Installations.installations().installationID()) ?? ""
        persistence = await MainActor.run {
            OrderPersistence(modelContainer: PersistenceContainer.shared)
        }
        metaPersistence = await MainActor.run {
            SyncMetaPersistence(modelContainer: PersistenceContainer.shared)
        }
        queuePersistence = await MainActor.run {
            SyncQueuePersistence(modelContainer: PersistenceContainer.shared)
        }
        lastIssued = try? await metaPersistence?.loadLastIssued()

        ordersListener = cloudSync.ordersCollection().addSnapshotListener { [weak self] snapshot, _ in
            guard let self, let snapshot else { return }
            let documents = snapshot.documents.map { $0.data() }
            Task { @MainActor in await self.handleSnapshot(documents) }
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

        // 先 drain 上次離線殘留，再監聽連線恢復
        await drainQueue()
        startConnectivityMonitoring()
    }

    /// 停止監聽 (登出 / flag 關閉)
    func stop() {
        ordersListener?.remove()
        ordersListener = nil
        connectivityTask?.cancel()
        connectivityTask = nil
        for observer in [saveObserver, resyncObserver, deleteObserver].compactMap({ $0 }) {
            NotificationCenter.default.removeObserver(observer)
        }
        saveObserver = nil
        resyncObserver = nil
        deleteObserver = nil
    }

    // MARK: - Push

    /// 推送一筆訂單的變更欄位 (B→A / 衝突)
    /// 為每個變更欄位產生遞增 HLC、標記 DIRTY，失敗則進待送佇列
    /// - Parameters:
    ///   - id: 目標訂單 id
    ///   - changedFields: 本次變更的欄位值 (僅含被改動的欄位)
    func pushOrder(id: String, changedFields: [String: JSONValue]) async {
        // clock 生成 + lastIssued 存回收斂到 actor 單次方法序列化，
        // 避免與 snapshot 端 advanceLastIssued 在 await 點交錯
        guard let generated = try? await metaPersistence?.generateFieldClocks(
            fields: Array(changedFields.keys),
            nowMs: nowMs(),
            writerId: writerId
        ) else { return }
        let clocks = generated.clocks
        lastIssued = generated.lastIssued
        try? await metaPersistence?.markPushed(entityID: id, collection: "orders", clocks: clocks)
        await sendPatch(
            id: id,
            changedFields: changedFields,
            clocks: clocks,
            opID: UUID().uuidString
        )
    }

    /// 處理本機訂單儲存：與最後拉回的版本 diff 出變更欄位後推送後端 (B→A / 衝突)
    /// 新訂單 (無拉回基準) 推全部欄位 → 後端 upsert 建立
    /// - Parameter order: 本機剛儲存的訂單
    func handleLocalSave(_ order: LedgerOrder) async {
        let changedFields = Self.diffFields(new: order, baseline: lastPulled[order.id])
        guard !changedFields.isEmpty else { return }
        await pushOrder(id: order.id, changedFields: changedFields)
    }

    /// 處理本機訂單刪除：產生刪除時鐘、寫本機 tombstone，
    /// 呼叫後端 DELETE，並清掉本機 diff 基準
    /// - Parameter id: 被刪除的訂單 id
    func handleLocalDelete(_ id: String) async {
        // 同 pushOrder 收斂到 actor 序列化方法，以保留鍵生成單一刪除時鐘
        guard let generated = try? await metaPersistence?.generateFieldClocks(
            fields: [Self.deleteClockField],
            nowMs: nowMs(),
            writerId: writerId
        ), let deleteClockEncoded = generated.clocks[Self.deleteClockField] else { return }
        lastIssued = generated.lastIssued
        try? await metaPersistence?.markDeleted(entityID: id, collection: "orders", deleteClock: deleteClockEncoded)
        guard let token = try? await idTokenProvider() else { return }
        try? await api.deleteEntity(token, "orders", id)
        lastPulled[id] = nil
    }

    /// 批次 / 合併 / cascade 改名後，重新比對所有本機訂單與最後拉回版本，
    /// 逐筆推送變更 (走 ``handleLocalSave(_:)``)
    func syncAllLocalChanges() async {
        guard let persistence, let orders = try? await persistence.fetchAll() else { return }
        for order in orders {
            await handleLocalSave(order)
        }
    }

    /// 連線恢復 / 啟動時重送待送佇列；成功逐筆移除
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

    /// 待送佇列筆數 (供演示 / UI 顯示「待同步」狀態)
    /// - Returns: 目前待送佇列中的項目數；無佇列時為 0
    func pendingCount() async -> Int {
        (try? await queuePersistence?.count()) ?? 0
    }

#if DEBUG
    // MARK: - Test Seam

    /// 測試專用：直接注入持久層 (繞過 `start()` 的 Firestore listener)，並設定 writerId，
    /// 供 reconcile / mergeDocument 的守護測試在 in-memory container 上驗端到端
    /// - Parameters:
    ///   - persistence: 注入的本機訂單持久層
    ///   - metaPersistence: 注入的同步 metadata 持久層
    ///   - queuePersistence: 注入的待送佇列持久層
    ///   - writerId: 本機寫入者識別 (供決定性時鐘)
    func configureForTesting(
        persistence: OrderPersistence,
        metaPersistence: SyncMetaPersistence,
        queuePersistence: SyncQueuePersistence,
        writerId: String
    ) {
        self.persistence = persistence
        self.metaPersistence = metaPersistence
        self.queuePersistence = queuePersistence
        self.writerId = writerId
    }

    /// 測試專用：以注入持久層直接觸發一次 PATCH 回應對帳
    /// - Parameters:
    ///   - id: 目標訂單 id
    ///   - pushedClocks: 本機本次推送的各欄位編碼 HLC
    ///   - response: 模擬的後端 PATCH 回應
    func reconcileForTesting(
        id: String,
        pushedClocks: [String: String],
        response: BackendAPIClient.PatchResponse
    ) async {
        await reconcile(id: id, pushedClocks: pushedClocks, response: response)
    }

    /// 測試專用：以注入持久層直接合併一份投影文件
    /// - Parameter data: 投影文件原始欄位字典
    func mergeDocumentForTesting(_ data: [String: Any]) async {
        guard let persistence, let metaPersistence else { return }
        await mergeDocument(data, persistence: persistence, metaPersistence: metaPersistence)
    }
#endif
}

// MARK: - Decode

extension CloudSyncEngine {

    /// Firestore 投影文件 → 領域訂單
    /// decimal 以字串解析、date 為 ISO 字串、照片參照另經 ``PhotoRefResolver`` 解析 (此處留空)
    /// - Parameter data: Firestore 文件的原始欄位字典
    /// - Returns: 解析出的領域訂單；缺必要欄位 (id / date) 時為 nil
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

    /// 把 `[String: JSONValue]` (PATCH 回應的 order DTO) 攤平為 `[String: Any]`，沿用
    /// ``decodeOrder(_:)`` 同一套解碼路徑 (與 Firestore 投影解碼一致)
    /// - Parameter map: PATCH 回應 order DTO 的鍵值對
    /// - Returns: 可餵給 ``decodeOrder(_:)`` 的原始欄位字典
    static func anyMap(_ map: [String: JSONValue]) -> [String: Any] {
        map.mapValues { Self.anyValue($0) }
    }

    /// 將單一 ``JSONValue`` 還原為 `decodeOrder` 期望的原生型別 (String / Double / Bool / 陣列 / 字典)
    /// - Parameter value: 來源 JSON 值
    /// - Returns: 對應的原生 Any 值；`null` 還原為 `NSNull`
    static func anyValue(_ value: JSONValue) -> Any {
        switch value {
        case .string(let string):
            return string

        case .number(let number):
            return number

        case .bool(let bool):
            return bool

        case .array(let array):
            return array.map { Self.anyValue($0) }

        case .object(let object):
            return object.mapValues { Self.anyValue($0) }

        case .null:
            return NSNull()
        }
    }

    /// 取投影文件的每欄位 HLC 圖 (`_fieldClocks`)；非字串值略過
    /// - Parameter data: Firestore 文件原始欄位字典
    /// - Returns: 欄位名 → 編碼 HLC 字串
    static func decodeFieldClocks(_ data: [String: Any]) -> [String: String] {
        guard let raw = data["_fieldClocks"] as? [String: Any] else { return [:] }
        var clocks: [String: String] = [:]
        for (field, value) in raw {
            if let encoded = value as? String {
                clocks[field] = encoded
            }
        }
        return clocks
    }
}

// MARK: - Local Change Diff

extension CloudSyncEngine {

    /// 領域訂單 → 可推送的 flat 欄位圖 (與後端 orderDomainToFlat 對齊；排除衍生的
    /// isCashOnDelivery 與本版暫不同步的 items / photos)
    /// - Parameter order: 來源領域訂單
    /// - Returns: 欄位名 → 值的扁平映射
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

    /// 與最後拉回版本 diff；baseline 為 nil (新訂單) 時回全部欄位
    /// - Parameters:
    ///   - new: 本機最新版本的訂單
    ///   - baseline: 最後一次拉回的訂單；nil 視為新訂單
    /// - Returns: 有變動的欄位映射；新訂單為全部欄位
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

    /// 監聽連線狀態：偵測到「斷線→恢復」轉換時 drain 待送佇列
    func startConnectivityMonitoring() {
        connectivityTask?.cancel()
        connectivityTask = Task { [weak self] in
            guard let self else { return }
            for await connected in self.connectivity() {
                let reconnected = connected && !self.wasConnected
                self.wasConnected = connected
                if reconnected {
                    await self.drainQueue()
                }
            }
        }
    }

    /// 處理一次投影快照：逐筆逐欄合併進本機 SwiftData，完成後通知 UI 重載
    /// - Parameter documents: 快照中每份文件的原始欄位字典
    func handleSnapshot(_ documents: [[String: Any]]) async {
        guard let persistence, let metaPersistence else { return }
        for data in documents {
            await mergeDocument(data, persistence: persistence, metaPersistence: metaPersistence)
        }
        onOrdersMerged?()
    }

    /// 逐欄合併單一投影文件：套用 tombstone / 復活、逐欄 clock 比較、DIRTY 保護、pendingRemote 記錄、
    /// 重新訂閱以投影核對清 DIRTY，並把勝出欄位疊進本機訂單
    /// - Parameters:
    ///   - data: 投影文件原始欄位字典
    ///   - persistence: 本機訂單持久層
    ///   - metaPersistence: 同步 metadata 持久層
    func mergeDocument(
        _ data: [String: Any],
        persistence: OrderPersistence,
        metaPersistence: SyncMetaPersistence
    ) async {
        guard let remote = Self.decodeOrder(data) else { return }
        let id = remote.id
        let remoteClocks = Self.decodeFieldClocks(data)
        let deleted = (data["_deleted"] as? Bool) ?? false
        let deleteClock = (data["_deleteClock"] as? String).flatMap { Hlc(encoded: $0) }
        let photoRefs = (data["photoRefs"] as? [String]) ?? []

        let meta = try? await metaPersistence.snapshot(entityID: id)
        let localClocks = meta?.fieldClocks ?? [:]
        let dirty = meta?.dirtyFields ?? []
        let pendingRemote = meta?.pendingRemote ?? [:]
        let baseline = (try? await persistence.fetch(id: id)) ?? lastPulled[id]

        // 1) 觀察到遠端時鐘 → 推進 lastIssued (RECEIVE)，持久化跨重啟存活
        await advanceLastIssued(observing: remoteClocks.values, deleteClock: data["_deleteClock"] as? String)

        // 2) 以投影核對 DIRTY：投影已反映本裝置值且 clock≥dirty clock → 清 DIRTY，
        //    避免 lost-ack 把欄位釘死
        let clearedDirty = (try? await metaPersistence.reconcileDirtyAgainstProjection(
            entityID: id,
            projectionClocks: remoteClocks
        )) ?? []
        let effectiveDirty = dirty.subtracting(clearedDirty)

        // 3) tombstone：以後端的 `_deleted` 為權威；
        //    下方復活/維持判定僅為防禦，
        //    須用與後端等價的 `Hlc.Comparable` (p→c→w)，不為刪除另開特例
        if deleted, let deleteClock {
            let hasNewerField = remoteClocks.values
                .compactMap { Hlc(encoded: $0) }
                .contains { $0 > deleteClock }
            // 本機有 clock 嚴格大於 deleteClock 的未同步編輯時不刪，
            //    留待下輪 drain 由後端再決勝
            let hasNewerLocalEdit = Self.hasLocalEditNewerThanDelete(
                deleteClock: deleteClock,
                dirtyFields: effectiveDirty,
                fieldClocks: localClocks,
                pendingRemote: pendingRemote
            )
            if !hasNewerField, !hasNewerLocalEdit {
                try? await persistence.delete(id: id)
                try? await metaPersistence.markDeleted(entityID: id, collection: "orders", deleteClock: deleteClock.encoded)
                lastPulled[id] = nil
                return
            }
            // 復活或保留本機：清 tombstone，續走逐欄套用
            try? await metaPersistence.clearTombstone(entityID: id)
        }

        // 4) 逐欄判定勝出集：remoteClock>localClock 且非 DIRTY 才套用；
        //    DIRTY 被略過但較高者記 pendingRemote
        var winningFields: Set<String> = []
        var appliedClocks: [String: String] = [:]
        for (field, remoteEncoded) in remoteClocks {
            guard let remoteHlc = Hlc(encoded: remoteEncoded) else { continue }
            let localHlc = localClocks[field].flatMap { Hlc(encoded: $0) }
            let isHigher = localHlc.map { remoteHlc > $0 } ?? true
            guard isHigher else { continue }

            if effectiveDirty.contains(field) {
                try? await metaPersistence.recordPendingRemote(
                    entityID: id,
                    collection: "orders",
                    field: field,
                    clock: remoteEncoded
                )
            } else {
                winningFields.insert(field)
                appliedClocks[field] = remoteEncoded
            }
        }

        // 5) 解析照片參照 → [Data]，須在欄位合併前備妥 (絕不把參照字串寫進 [Data] 欄)
        let resolvedPhotos = await resolvePhotoRefs(photoRefs)
        try? await metaPersistence.savePhotoRefs(entityID: id, collection: "orders", refs: photoRefs)

        // 6) 套用勝出欄位 + 照片到本機 baseline，upsert 落地
        guard !winningFields.isEmpty || baseline == nil || !resolvedPhotos.isEmpty else {
            lastPulled[id] = baseline
            return
        }
        var merged = CloudSyncFieldMerge.merged(
            baseline: baseline,
            remote: remote,
            winningFields: winningFields
        )
        // 下載暫時失敗 (refs 非空但 resolved 空) 時保留 baseline.photos 不覆蓋，避免誤清照片
        if !photoRefs.isEmpty, !resolvedPhotos.isEmpty {
            merged = Self.withPhotos(merged, photos: resolvedPhotos)
        }
        try? await persistence.upsert(merged)
        if !appliedClocks.isEmpty {
            try? await metaPersistence.recordApplied(entityID: id, collection: "orders", clocks: appliedClocks)
        }
        lastPulled[id] = merged
    }

    /// 取注入時間的 epoch 毫秒整數 (HLC 物理時間單位)
    /// - Returns: 注入當下的 epoch 毫秒整數
    func nowMs() -> Int {
        Int((now().timeIntervalSince1970 * 1000).rounded(.down))
    }

    /// 判定本機是否存在 clock 嚴格大於 `deleteClock` 的未同步本機編輯 (DIRTY / 佇列未送 / pendingRemote)
    ///
    /// 避免較舊遠端 tombstone 砍掉較新的本機未同步編輯
    /// 佇列未送欄位的 clock 已於 `markPushed` stamp 進 fieldClocks 並標 DIRTY，
    /// 故只需檢查 DIRTY 欄位的 fieldClocks 即涵蓋
    /// - Parameters:
    ///   - deleteClock: 遠端刪除事件的 HLC
    ///   - dirtyFields: 本機 DIRTY 欄位集 (扣除本輪以投影核對清掉者)
    ///   - fieldClocks: 本機每欄位 HLC (編碼字串)
    ///   - pendingRemote: 本機 pendingRemote 每欄位 HLC (編碼字串)
    /// - Returns: 存在嚴格較新的本機未同步編輯時為 `true`
    static func hasLocalEditNewerThanDelete(
        deleteClock: Hlc,
        dirtyFields: Set<String>,
        fieldClocks: [String: String],
        pendingRemote: [String: String]
    ) -> Bool {
        for field in dirtyFields {
            if let encoded = fieldClocks[field], let hlc = Hlc(encoded: encoded), hlc > deleteClock {
                return true
            }
        }
        for encoded in pendingRemote.values {
            if let hlc = Hlc(encoded: encoded), hlc > deleteClock {
                return true
            }
        }
        return false
    }

    /// 觀察到一組遠端時鐘後推進本地 lastIssued (RECEIVE)，並持久化
    /// - Parameters:
    ///   - clocks: 遠端編碼 HLC 集合
    ///   - deleteClock: 遠端刪除時鐘 (若有)，一併納入觀察
    func advanceLastIssued(observing clocks: some Sequence<String>, deleteClock: String?) async {
        var observed = Array(clocks)
        if let deleteClock { observed.append(deleteClock) }
        guard !observed.isEmpty else { return }
        // RECEIVE 讀-改-寫收斂到 actor 單次方法序列化 (同 generateFieldClocks)
        if let advanced = try? await metaPersistence?.advanceLastIssued(
            observing: observed,
            nowMs: nowMs(),
            writerId: writerId
        ) {
            lastIssued = advanced
        }
    }

    /// 實際送出：成功後走 ``reconcile(id:pushedClocks:response:)`` 對帳；
    /// 失敗進待送佇列 (同 clocks / opID 重送冪等)
    /// - Parameters:
    ///   - id: 目標訂單 id
    ///   - changedFields: 本次變更的欄位值
    ///   - clocks: 每個變更欄位對應的編碼 HLC
    ///   - opID: 操作唯一 id (重送冪等鍵)
    func sendPatch(
        id: String,
        changedFields: [String: JSONValue],
        clocks: [String: String],
        opID: String
    ) async {
        guard let token = try? await idTokenProvider() else {
            await enqueueFailed(id: id, changedFields: changedFields, clocks: clocks, opID: opID)
            return
        }
        do {
            let response = try await api.patchOrder(token, id, changedFields, clocks)
            try? await queuePersistence?.delete(opID: opID)
            await reconcile(id: id, pushedClocks: clocks, response: response)
        } catch {
            await enqueueFailed(
                id: id,
                changedFields: changedFields,
                clocks: clocks,
                opID: opID
            )
        }
    }

    /// 依後端 PATCH 回應逐欄對帳 DIRTY，
    /// 並以回應的**權威完整 order DTO** 把敗方 / replay 欄位套回本機
    ///
    /// 規則 (保護 DIRTY 但絕不靜默丟棄較高時鐘的遠端值)：
    /// - reconcileAck 清 / 採用 DIRTY，並回報 in-flight 窗 replay 的 pendingRemote 欄位
    /// - **本裝置敗**：`appliedFieldClocks[field]` 嚴格大於本機 pushed → 採後端 DTO 權威值
    /// - **replay**：reconcileAck 回報的每個 pendingRemote 欄位 → 採後端 DTO 權威值
    /// - 上述欄位經 ``CloudSyncFieldMerge/merged(baseline:remote:winningFields:)`` 疊進 baseline、upsert 落地，
    ///   `recordApplied` 寫入權威 clock
    /// - Parameters:
    ///   - id: 目標訂單 id
    ///   - pushedClocks: 本機本次推送的各欄位編碼 HLC
    ///   - response: 後端 PATCH 回應 (含權威完整 order DTO)
    func reconcile(id: String, pushedClocks: [String: String], response: BackendAPIClient.PatchResponse) async {
        guard let metaPersistence, let persistence else { return }
        let replays = (try? await metaPersistence.reconcileAck(
            entityID: id,
            collection: "orders",
            pushedClocks: pushedClocks,
            appliedFieldClocks: response.appliedFieldClocks
        )) ?? []
        // 觀察到後端權威時鐘 → 推進 lastIssued
        await advanceLastIssued(observing: response.appliedFieldClocks.values, deleteClock: nil)

        // 後端回應的權威完整 order DTO；
        // 缺 (舊後端 / 解碼失敗) 時退回原行為 (僅靠 listener 全量重讀)
        guard let orderData = response.orderData,
              let authoritative = Self.decodeOrder(Self.anyMap(orderData)) else {
            return
        }

        // 1) 收集需以權威值套回本機的欄位：
        //    本裝置敗 (applied 嚴格大於 pushed) + replay (pendingRemote)
        var winningFields: Set<String> = []
        var appliedClocks: [String: String] = [:]
        for (field, pushed) in pushedClocks {
            guard let appliedEncoded = response.appliedFieldClocks[field],
                  let appliedHlc = Hlc(encoded: appliedEncoded),
                  let pushedHlc = Hlc(encoded: pushed),
                  appliedHlc > pushedHlc else {
                continue
            }
            winningFields.insert(field)
            appliedClocks[field] = appliedEncoded
        }
        for replay in replays {
            winningFields.insert(replay.field)
            // 權威 clock 優先取後端 appliedFieldClocks，缺則退回 pendingRemote 自帶 clock
            appliedClocks[replay.field] = response.appliedFieldClocks[replay.field] ?? replay.clock
        }

        guard !winningFields.isEmpty else { return }

        // 2) 以權威 DTO 的對應欄位疊進本機 baseline、upsert 落地，並寫入該欄位權威 clock
        let baseline = (try? await persistence.fetch(id: id)) ?? lastPulled[id]
        let merged = CloudSyncFieldMerge.merged(
            baseline: baseline,
            remote: authoritative,
            winningFields: winningFields
        )
        try? await persistence.upsert(merged)
        try? await metaPersistence.recordApplied(entityID: id, collection: "orders", clocks: appliedClocks)
        lastPulled[id] = merged
        onOrdersMerged?()
    }

    /// 將推送失敗的變更編碼為 JSON 後寫入待送佇列 (供連線恢復時重送)
    /// - Parameters:
    ///   - id: 目標訂單 id
    ///   - changedFields: 推送失敗的欄位值
    ///   - clocks: 每個變更欄位對應的編碼 HLC
    ///   - opID: 操作唯一 id (重送冪等鍵)
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

    // MARK: Photo

    /// 以解析後的照片位元組重建訂單 (immutable struct，memberwise init)
    /// - Parameters:
    ///   - order: 原訂單
    ///   - photos: 解析後的照片位元組
    /// - Returns: 帶入照片的新訂單
    static func withPhotos(_ order: LedgerOrder, photos: [Data]) -> LedgerOrder {
        LedgerOrder(
            id: order.id,
            customer: order.customer,
            status: order.status,
            currency: order.currency,
            date: order.date,
            items: order.items,
            itemCost: order.itemCost,
            domesticShipping: order.domesticShipping,
            internationalShipping: order.internationalShipping,
            foreignDomesticShipping: order.foreignDomesticShipping,
            cardFeeRate: order.cardFeeRate,
            platformFeeRate: order.platformFeeRate,
            paymentFeeRate: order.paymentFeeRate,
            chargedAmount: order.chargedAmount,
            cardlessDeductionAmount: order.cardlessDeductionAmount,
            cardlessSupplementAmount: order.cardlessSupplementAmount,
            orderSource: order.orderSource,
            categories: order.categories,
            paymentMethod: order.paymentMethod,
            notes: order.notes,
            verificationStatus: order.verificationStatus,
            campaignNames: order.campaignNames,
            paymentReceiptStatus: order.paymentReceiptStatus,
            isCashOnDelivery: order.isCashOnDelivery,
            photos: photos,
            mergedSourceIDs: order.mergedSourceIDs
        )
    }

    // MARK: ISO8601 Date

    /// 解析 ISO8601 日期字串，優先帶小數秒、退回不帶小數秒格式
    /// - Parameter value: ISO8601 日期字串
    /// - Returns: 解析出的日期；兩種格式皆不符時為 nil
    static func parseDate(_ value: String) -> Date? {
        if let date = isoWithFraction.date(from: value) {
            return date
        }
        return isoPlain.date(from: value)
    }

    /// 將 Firestore 欄位值 (字串或數字) 轉為 `Decimal`，無法解析時回 0
    /// - Parameter value: Firestore 欄位的原始值 (字串或數字)
    /// - Returns: 轉換後的 `Decimal`；無法解析時為 0
    static func decimal(_ value: Any?) -> Decimal {
        if let string = value as? String {
            return Decimal(string: string) ?? 0
        }
        if let number = value as? NSNumber {
            return Decimal(string: number.stringValue) ?? 0
        }
        return 0
    }
}
