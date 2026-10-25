//
//  RootFeatureTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation

@testable import BuyLedger

/// 提供根功能與訂單測試共用的獨立記憶體狀態、測試訂單、讀取替身與 `TestStore` 接收步驟
enum RootFeatureTestSupport {}

// MARK: - Internal Method

extension RootFeatureTestSupport {

    /// 在隔離儲存建立主檔已有美妝、來源表單已選美妝的根狀態
    ///
    /// - Parameters:
    ///   - original: 表單編輯的原訂單，未提供時為新表單
    ///   - isMerge: 是否建立合併表單
    /// - Returns: 固定日期、幣別與表單識別值的根狀態
    static func makeOptionAdditionRootState(
        original: LedgerOrder? = nil,
        isMerge: Bool = false
    ) -> RootFeature.State {
        var state = RootFeatureTestSupport.makeIsolatedRootState()
        state.selectedTab = .orders
        state.more.catalog.$catalog.withLock {
            $0.categories = ["美妝"]
        }
        state.launch.$currencyCodes.withLock {
            $0 = [.twd]
        }
        if let original {
            state.orders.$orders.withLock {
                $0 = [original]
            }
        }
        state.orders.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        var form = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            options: OrderEditOptions(
                categories: ["美妝"],
                currencyCodes: [.twd],
                calendar: TestDependencies.fixedCalendar
            ),
            currentDate: TestDependencies.fixedNow
        )
        form.draft.categories = ["美妝"]
        if isMerge {
            form.mergeSourceIDs = ["A", "B"]
        }
        state.orders.presentation.destination = .edit(form)
        return state
    }

    /// 以獨立的記憶體儲存建立根狀態，讓會改寫共用清單的測試不影響其他測試
    ///
    /// - Parameters:
    ///   - lookupKind: 要預先開啟的清單種類，未提供時更多頁不推入任何清單
    ///   - build: 建立根狀態的操作
    /// - Returns: 建立完成的測試狀態
    static func makeIsolatedRootState(
        lookupKind: LookupKind? = nil,
        _ build: () -> RootFeature.State = { RootFeature.State() }
    ) -> RootFeature.State {
        withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            var state = build()
            if let lookupKind {
                state.more.path.append(
                    .lookupManagement(LookupManagementFeature.State(kind: lookupKind))
                )
            }
            return state
        }
    }

    /// 建立只含單一商品類別的測試訂單
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - category: 商品類別
    ///   - customerName: 客戶名稱
    /// - Returns: 建立的測試訂單
    static func makeTestOrder(id: String, category: String, customerName: String) -> LedgerOrder {
        makeTestOrder(id: id, categories: [category], customerName: customerName)
    }

    /// 建立支援多類別與多開團的測試訂單
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - categories: 商品類別
    ///   - customerName: 客戶名稱
    ///   - campaignNames: 開團名稱
    /// - Returns: 建立的測試訂單
    static func makeTestOrder(
        id: String,
        categories: [String],
        customerName: String,
        campaignNames: [String] = []
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: customerName, initials: "TC", tier: .new),
            status: .purchased,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "測試",
            categories: categories,
            paymentMethod: "",
            notes: "",
            reconciliationStatus: "",
            campaignNames: campaignNames,
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }

    /// 建立可指定來源、類別、付款方式與對帳狀態的最小訂單
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - orderSource: 訂單來源
    ///   - categories: 商品類別
    ///   - paymentMethod: 付款方式
    ///   - reconciliationStatus: 對帳狀態
    /// - Returns: 建立的測試訂單
    static func makeOrder(
        id: String,
        orderSource: String = "",
        categories: [String] = [],
        paymentMethod: String = "",
        reconciliationStatus: String = ""
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "同步測試", initials: "SY", tier: .new),
            status: .purchased,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: orderSource,
            categories: categories,
            paymentMethod: paymentMethod,
            notes: "",
            reconciliationStatus: reconciliationStatus,
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }

    /// 複製訂單並只替換指定欄位，其餘欄位保留原值
    ///
    /// - Parameters:
    ///   - order: 原始訂單
    ///   - orderSource: 新的訂單來源，未提供時保留原值
    ///   - categories: 新的商品類別，未提供時保留原值
    ///   - paymentMethod: 新的付款方式，未提供時保留原值
    ///   - reconciliationStatus: 新的對帳狀態，未提供時保留原值
    ///   - cardlessDeductionAmount: 新的無卡折抵金額，未提供時保留原值
    ///   - cardlessSupplementAmount: 新的無卡補收金額，未提供時保留原值
    ///   - isCashOnDelivery: 新的貨到付款旗標，未提供時保留原值
    ///   - campaignNames: 新的開團名稱，未提供時保留原值
    ///   - paymentReceiptStatus: 新的收款狀態，未提供時保留原值
    /// - Returns: 套用指定欄位後的訂單
    static func rebuiltOrder(
        _ order: LedgerOrder,
        orderSource: String? = nil,
        categories: [String]? = nil,
        paymentMethod: String? = nil,
        reconciliationStatus: String? = nil,
        cardlessDeductionAmount: Decimal? = nil,
        cardlessSupplementAmount: Decimal? = nil,
        isCashOnDelivery: Bool? = nil,
        campaignNames: [String]? = nil,
        paymentReceiptStatus: PaymentReceiptStatus? = nil
    ) -> LedgerOrder {
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
            cardlessDeductionAmount: cardlessDeductionAmount ?? order.cardlessDeductionAmount,
            cardlessSupplementAmount: cardlessSupplementAmount ?? order.cardlessSupplementAmount,
            orderSource: orderSource ?? order.orderSource,
            categories: categories ?? order.categories,
            paymentMethod: paymentMethod ?? order.paymentMethod,
            notes: order.notes,
            reconciliationStatus: reconciliationStatus ?? order.reconciliationStatus,
            campaignNames: campaignNames ?? order.campaignNames,
            paymentReceiptStatus: paymentReceiptStatus ?? order.paymentReceiptStatus,
            isCashOnDelivery: isCashOnDelivery ?? order.isCashOnDelivery,
            photos: order.photos,
            mergedSourceIDs: order.mergedSourceIDs
        )
    }

    /// 注入有等待閘門的主檔與訂單讀取替身，分別記錄讀取完成的主檔種類，以及開始讀取訂單的次數
    ///
    /// - Parameters:
    ///   - dependencies: 測試依賴集合
    ///   - catalogs: 各種類成功讀取時回傳的目錄
    ///   - failingKinds: 讀取失敗的主檔種類
    ///   - catalogRelease: 主檔讀取的等待閘門
    ///   - orderRelease: 訂單讀取的等待閘門
    ///   - reads: 已完成讀取的主檔種類
    ///   - orderReads: 訂單讀取次數
    ///   - shouldFailOrders: 是否讓訂單讀取失敗
    static func stubCatalogAndOrders(
        _ dependencies: inout DependencyValues,
        catalogs: [LookupKind: LookupCatalog],
        failingKinds: Set<LookupKind> = [],
        catalogRelease: AsyncStream<Void>,
        orderRelease: AsyncStream<Void>,
        reads: LockIsolated<[LookupKind]>,
        orderReads: LockIsolated<Int>,
        shouldFailOrders: Bool = false
    ) {
        let fetchItems: LookupService.FetchItems = { kind throws(PersistenceError) in
            var iterator = catalogRelease.makeAsyncIterator()
            _ = await iterator.next()
            reads.withValue {
                $0.append(kind)
            }
            guard !failingKinds.contains(kind) else {
                throw .fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "lookup")
                )
            }
            return catalogs[kind] ?? LookupCatalog()
        }
        let fetchOrders: OrderService.FetchOrders = { () throws(PersistenceError) in
            orderReads.withValue {
                $0 += 1
            }
            var iterator = orderRelease.makeAsyncIterator()
            _ = await iterator.next()
            guard !shouldFailOrders else {
                throw .fetchFailed(
                    underlying: TestDependencies.makeUnderlyingError(message: "orders")
                )
            }
            return []
        }
        dependencies.lookupService.fetchItems = fetchItems
        dependencies.orderService.fetchOrders = fetchOrders
    }

    /// 依任意順序接收啟動載入的九筆請求，包含主檔完成通知後才送出的訂單載入
    ///
    /// - Parameter store: 已送出啟動事件的測試 `store`
    @MainActor
    static func receiveLaunchLoadRequests(in store: TestStoreOf<RootFeature>) async {
        for _ in 0..<9 {
            await store.receive { action in
                if case .more(.catalogLoadRequested) = action {
                    return true
                }
                if case .more(.catalog(.loadRequested)) = action {
                    return true
                }
                if case .more(.catalog(.delegate(.loadFinished))) = action {
                    return true
                }
                if case .more(.delegate(.catalogLoadFinished)) = action {
                    return true
                }
                if case .orders(.rootRequest(.load)) = action {
                    return true
                }
                if case .orders(.load(.loadRequested)) = action {
                    return true
                }
                if case .campaigns(.loadRequested) = action {
                    return true
                }
                if case .campaigns(.load(.loadRequested)) = action {
                    return true
                }
                if case .launch(.loadRequested) = action {
                    return true
                }
                return false
            }
        }
    }

    /// 先接收啟動與開團的四筆載入請求，再核對主檔開始讀取；讀取由呼叫端的串流阻擋
    ///
    /// - Parameter store: 已送出啟動事件且尚未釋放主檔讀取的測試 `store`
    @MainActor
    static func receiveLaunchCatalogRequests(in store: TestStoreOf<RootFeature>) async {
        for _ in 0..<4 {
            await store.receive { action in
                if case .campaigns(.loadRequested) = action {
                    return true
                }
                if case .campaigns(.load(.loadRequested)) = action {
                    return true
                }
                if case .launch(.loadRequested) = action {
                    return true
                }
                if case .more(.catalogLoadRequested) = action {
                    return true
                }
                return false
            }
        }
        await store.receive(\.more.catalog.loadRequested) {
            $0.more.catalog.isLoading = true
        }
    }

    /// 依序接收單次主檔載入請求的兩筆 action，讀取需由呼叫端的串流阻擋
    ///
    /// - Parameter store: 已送出主檔載入請求的測試 `store`
    @MainActor
    static func receiveCatalogRequested(in store: TestStoreOf<RootFeature>) async {
        await store.receive(\.more.catalogLoadRequested)
        await store.receive(\.more.catalog.loadRequested) {
            $0.more.catalog.isLoading = true
        }
    }

    /// 接收主檔讀取結果並斷言字面值目錄，再接收目錄載入完成後送出的訂單載入請求
    ///
    /// - Parameters:
    ///   - store: 已釋放主檔讀取的測試 `store`
    ///   - catalogs: 預期的各種類回應
    ///   - expectedCatalog: 預期的完整目錄，由案例以字面值提供
    ///   - hasLoaded: 是否四種皆讀取成功
    ///   - shouldLoadOrders: 是否開始新的訂單讀取，已載入的訂單不重讀
    @MainActor
    static func receiveCatalogResponse(
        in store: TestStoreOf<RootFeature>,
        catalogs: [LookupKind: LookupCatalog],
        expectedCatalog: LookupCatalog,
        hasLoaded: Bool,
        shouldLoadOrders: Bool = true
    ) async {
        await store.receive(\.more.catalog.catalogResponse, catalogs) {
            $0.more.catalog.isLoading = false
            $0.more.catalog.hasLoaded = hasLoaded
            $0.more.catalog.$catalog.withLock {
                $0 = expectedCatalog
            }
            if shouldLoadOrders {
                $0.orders.load.$isLoading.withLock {
                    $0 = true
                }
                $0.orders.load.$errorMessage.withLock {
                    $0 = nil
                }
            }
        }
        await Self.receiveCatalogFinished(in: store)
    }

    /// 依序接收目錄載入完成的兩筆 `delegate`，以及隨後的兩筆訂單載入請求
    ///
    /// - Parameter store: 已接收主檔讀取結果的測試 `store`
    @MainActor
    static func receiveCatalogFinished(in store: TestStoreOf<RootFeature>) async {
        await store.receive(\.more.catalog.delegate.loadFinished)
        await store.receive(\.more.delegate.catalogLoadFinished)
        await store.receive(\.orders.rootRequest.load)
        await store.receive(\.orders.load.loadRequested)
    }

    /// 釋放訂單讀取，核對成功時清單為空、失敗時標示載入失敗，並核對首頁與分析頁的投影
    ///
    /// - Parameters:
    ///   - store: 訂單正在讀取中的測試 `store`
    ///   - release: 訂單讀取的等待閘門
    ///   - shouldFail: 是否預期訂單讀取失敗
    @MainActor
    static func receiveEmptyOrders(
        in store: TestStoreOf<RootFeature>,
        release: AsyncStream<Void>.Continuation,
        shouldFail: Bool = false
    ) async {
        release.finish()
        await store.receive(\.orders.load.loadResponse) {
            $0.orders.load.$isLoading.withLock {
                $0 = false
            }
            if shouldFail {
                $0.orders.load.$errorMessage.withLock {
                    $0 = "orders.general.message.ordersLoadedTry"
                }
                $0.dashboard.loadState = .failed("orders.general.message.ordersLoadedTry")
                $0.insights.loadState = .failed("orders.general.message.ordersLoadedTry")
            } else {
                $0.orders.$orders.withLock {
                    $0 = []
                }
                $0.campaigns.$orders.withLock {
                    $0 = []
                }
                $0.more.$orders.withLock {
                    $0 = []
                }
                $0.dashboard.orders = []
                $0.insights.orders = []
                $0.orders.load.$hasLoaded.withLock {
                    $0 = true
                }
                $0.dashboard.loadState = .loaded
                $0.insights.loadState = .loaded
            }
        }
        if shouldFail {
            await store.receive(\.orders.load.delegate.loadFailed)
        }
    }

    /// 依序接收新增選項請求從選擇器送到主檔的各個 action，前段核對種類、名稱與旗標，後段以含來源表單識別值的整份請求比對
    ///
    /// - Parameters:
    ///   - store: 已從選擇器送出新增事件的測試 `store`
    ///   - request: 由案例以字面值建立的預期請求
    @MainActor
    static func receiveOptionAdditionRequest(
        in store: TestStoreOf<RootFeature>,
        request: LookupAdditionRequest
    ) async {
        await store.receive(
            \.orders.presentation.destination.presented.edit.pickers.delegate,
            .addOptionRequested(
                kind: request.kind,
                name: request.addition.name,
                flags: request.addition.flags
            )
        )
        await store.receive(
            \.orders.presentation.destination.presented.edit.delegate,
            .addOptionRequested(
                kind: request.kind,
                name: request.addition.name,
                flags: request.addition.flags
            )
        )
        await store.receive(\.orders.presentation.delegate, .optionAddRequested(request))
        await store.receive(\.orders.delegate, .optionAddRequested(request))
        await store.receive(\.more.optionAdditionRequested, request)
        await store.receive(\.more.catalog.additionRequested, request)
    }

    /// 接收主檔寫入回應，再依序接收主檔與更多頁的 `delegate`，訂單的結果由呼叫端另行斷言
    ///
    /// - Parameters:
    ///   - store: 已釋放寫入閘門的測試 `store`
    ///   - request: 保留來源表單識別值的預期請求
    ///   - isStored: 是否預期寫入成功
    ///   - expectedCatalog: 案例以字面值提供的完整目錄
    @MainActor
    static func receiveOptionAdditionResult(
        in store: TestStoreOf<RootFeature>,
        request: LookupAdditionRequest,
        isStored: Bool,
        expectedCatalog: LookupCatalog
    ) async {
        if isStored {
            await store.receive(\.more.catalog.additionResponse) {
                $0.more.catalog.$catalog.withLock {
                    $0 = expectedCatalog
                }
            }
        } else {
            await store.receive(\.more.catalog.additionResponse)
        }
        await store.receive(
            \.more.catalog.delegate,
            .additionCompleted(request, isStored: isStored)
        )
        await store.receive(\.more.delegate, .optionAdditionCompleted(request, isStored: isStored))
    }
}
