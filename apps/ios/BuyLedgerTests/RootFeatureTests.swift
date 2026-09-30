//
//  RootFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `RootFeature` 的單元測試：分頁導覽、深連結與跨功能同步
@MainActor
struct RootFeatureTests {

    // MARK: - Tests

    /// 持久層開啟失敗時，根畫面一建立就呈現阻擋畫面
    @Test
    func init_持久化狀態降級_呈現阻擋畫面() {
        // Given

        // When
        let state = RootFeature.State(persistenceStatus: .degraded(reason: "Unable to open store"))

        // Then
        #expect(state.persistenceFailure?.phase == .blocked)
    }

    /// 持久層正常時，根畫面不呈現阻擋畫面
    @Test
    func init_持久化狀態正常_不呈現阻擋畫面() {
        // Given

        // When
        let state = RootFeature.State(persistenceStatus: .healthy)

        // Then
        #expect(state.persistenceFailure == nil)
    }

    /// 根 State 建立時，鎖定狀態與已保存的生物辨識設定一致
    ///
    /// - Parameters:
    ///   - isBiometricUnlockEnabled: 是否啟用生物辨識解鎖
    ///   - expectedIsLocked: 預期的初始鎖定狀態
    @Test(arguments: [(true, true), (false, false)])
    func init_生物辨識解鎖設定_鎖定狀態與設定一致(isBiometricUnlockEnabled: Bool, expectedIsLocked: Bool) {
        // Given
        var snapshot = SettingsSnapshot.default
        snapshot.isBiometricUnlockEnabled = isBiometricUnlockEnabled

        // When
        let state = RootFeature.State(settings: SettingsFeature.State(snapshot: snapshot))

        // Then
        #expect(state.settings.appLock.isLocked == expectedIsLocked)
    }

    /// 根 State 建立時即帶齊已保存的設定，第一幀就用持久化的值
    @Test
    func init_注入已保存設定_初始狀態同步設定() {
        // Given
        var snapshot = SettingsSnapshot.default
        snapshot.language = .english
        snapshot.defaultCurrency = .usd
        snapshot.monthlyProfitGoalTWD = 120_000
        let settings = SettingsFeature.State(snapshot: snapshot, appVersion: "1.7.0 (312)")

        // When
        let state = RootFeature.State(settings: settings)

        // Then
        #expect(state.settings.language == .english)
        #expect(state.settings.defaultCurrency == .usd)
        #expect(state.settings.monthlyProfitGoalTWD == 120_000)
        #expect(state.settings.appVersion == "1.7.0 (312)")
    }

    /// App 重新啟動時，根畫面一律從總覽分頁開始
    @Test
    func init_預設參數_選取總覽分頁() {
        // Given

        // When
        let state = RootFeature.State()

        // Then
        #expect(state.selectedTab == .dashboard)
    }

    /// App 啟動時更新生物辨識類型，並以七天期限在背景刷新幣別清單
    @Test
    func task_啟動根功能_以七天期限刷新幣別快取() async {
        // Given
        let refreshTTLs = LockIsolated<[TimeInterval]>([])
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        } withDependencies: {
            $0.biometricAuthService.biometryType = {
                .faceID
            }
            $0.currencyMetadataService.refreshIfStale = { ttl in
                refreshTTLs.withValue {
                    $0.append(ttl)
                }
                return false
            }
        }

        // When
        await store.send(.task)

        // Then
        await store.receive(\.settings.appLock.appDidBecomeActive) {
            $0.settings.appLock.biometryType = .faceID
        }
        await store.finish()
        #expect(refreshTTLs.value == [604_800])
    }

    /// 選取智慧分組後切到訂單頁，套用狀態並選取第一筆符合的訂單
    ///
    /// - Parameters:
    ///   - status: 智慧分組代表的訂單狀態
    ///   - expectedOrderID: 預期選取的第一筆訂單識別值
    @Test(arguments: [
        (status: OrderStatus.shipping, expectedOrderID: "BL-2604-018"),
        (status: OrderStatus.purchased, expectedOrderID: "BL-2604-017"),
    ])
    func smartGroupSelected_選取智慧分組_切至訂單並選取第一筆符合訂單(
        status: OrderStatus,
        expectedOrderID: String
    ) async {
        // Given
        var state = RootFeature.State()
        state.orders.orders = LedgerOrder.sampleOrders

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.smartGroupSelected(status)) {
            $0.selectedTab = .orders
            $0.orders.selectedStatus = .status(status)
            $0.orders.selectedOrderID = expectedOrderID
        }

        // Then
        #expect(store.state.selectedTab == .orders)
        #expect(store.state.orders.selectedStatus == .status(status))
        #expect(store.state.orders.selectedOrderID == expectedOrderID)
    }

    /// iPad 側邊欄切換分頁前清空「更多」路徑
    @Test
    func sidebarTabSelected_更多路徑非空_清空路徑並切換分頁() async {
        // Given
        var state = RootFeature.State()
        state.selectedTab = .more
        state.morePath = [.categories]

        let store = TestStore(initialState: state) {
            RootFeature()
        }

        // When
        await store.send(.sidebarTabSelected(.orders)) {
            $0.morePath = []
            $0.selectedTab = .orders
        }

        // Then
        #expect(store.state.morePath == [])
        #expect(store.state.selectedTab == .orders)
    }

    /// iPad 側邊欄的智慧分組切到訂單頁前清空「更多」路徑
    @Test
    func smartGroupSelected_從更多頁選取智慧分組_清空更多路徑() async {
        // Given
        var state = RootFeature.State()
        state.selectedTab = .more
        state.morePath = [.categories]

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.smartGroupSelected(.shipping)) {
            $0.morePath = []
            $0.selectedTab = .orders
            $0.orders.selectedStatus = .status(.shipping)
        }

        // Then
        #expect(store.state.morePath.isEmpty)
        #expect(store.state.selectedTab == .orders)
        #expect(store.state.orders.selectedStatus == .status(.shipping))
    }

    /// iPhone 切換主要分頁時保留「更多」路徑
    @Test
    func tabSelected_更多路徑非空_保留路徑() async {
        // Given
        var state = RootFeature.State()
        state.selectedTab = .more
        state.morePath = [.categories]

        let store = TestStore(initialState: state) {
            RootFeature()
        }

        // When
        await store.send(.tabSelected(.orders)) {
            $0.selectedTab = .orders
        }

        // Then
        #expect(store.state.selectedTab == .orders)
        #expect(store.state.morePath == [.categories])
    }

    /// 智慧分組只切換狀態篩選，不覆寫既有日期區間與類別
    @Test
    func smartGroupSelected_已有日期與類別篩選_只切換狀態篩選() async {
        // Given
        var state = RootFeature.State()
        state.orders.orders = LedgerOrder.sampleOrders
        state.orders.selectedStatus = .status(.delivered)
        state.orders.selectedDatePeriod = .thisMonth
        state.orders.selectedCategory = "美妝"
        state.orders.selectedOrderID = "BL-2604-016"

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.smartGroupSelected(.shipping)) {
            $0.selectedTab = .orders
            $0.orders.selectedStatus = .status(.shipping)
            $0.orders.selectedOrderID = "BL-2604-018"
        }

        // Then
        #expect(store.state.selectedTab == .orders)
        #expect(store.state.orders.selectedStatus == .status(.shipping))
        #expect(store.state.orders.selectedDatePeriod == .thisMonth)
        #expect(store.state.orders.selectedCategory == "美妝")
    }

    /// 客戶深連結清除殘留類別篩選，避免舊條件讓訂單消失
    @Test
    func customerSelected_有殘留類別篩選_清除類別篩選() async {
        // Given
        var state = RootFeature.State()
        state.orders.orders = LedgerOrder.sampleOrders
        state.orders.selectedCategory = "精品"

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.customerSelected("Alice")) {
            $0.selectedTab = .orders
            $0.orders.searchText = "Alice"
            $0.orders.selectedCategory = nil
        }

        // Then
        #expect(store.state.selectedTab == .orders)
        #expect(store.state.orders.searchText == "Alice")
        #expect(store.state.orders.selectedCategory == nil)
    }

    /// 從分析頁點類別時，切到訂單頁、重設狀態日期與搜尋篩選，只套用該類別
    @Test
    func categorySelected_有殘留其他篩選_重設篩選並套用分類() async {
        // Given
        var state = RootFeature.State()
        state.orders.orders = LedgerOrder.sampleOrders
        state.orders.selectedStatus = .status(.delivered)
        state.orders.selectedDatePeriod = .thisMonth
        state.orders.searchText = "stale query"
        state.orders.selectedOrderID = "BL-2604-016"

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.categorySelected("美妝")) {
            $0.selectedTab = .orders
            $0.orders.selectedStatus = .all
            $0.orders.selectedDatePeriod = .all
            $0.orders.searchText = ""
            $0.orders.selectedCategory = "美妝"
            $0.orders.selectedOrderID = "BL-2604-018"
        }

        // Then
        #expect(store.state.selectedTab == .orders)
        #expect(store.state.orders.selectedStatus == .all)
        #expect(store.state.orders.selectedDatePeriod == .all)
        #expect(store.state.orders.searchText == "")
        #expect(store.state.orders.selectedCategory == "美妝")
        #expect(store.state.orders.selectedOrderID == "BL-2604-018")
    }

    /// 類別深連結只比對訂單的類別欄位，不把客戶名稱中的字眼當成類別
    @Test
    func categorySelected_選取分類_依分類欄位而非搜尋文字篩選() async {
        // Given
        let realBeauty1 = Self.makeTestOrder(
            id: "TEST-BEAUTY-1",
            category: "美妝",
            customerName: "林書宇"
        )
        let falsePositive = Self.makeTestOrder(
            id: "TEST-FALSE-1",
            category: "服飾",
            customerName: "美妝小編"
        )
        let realBeauty2 = Self.makeTestOrder(
            id: "TEST-BEAUTY-2",
            category: "美妝",
            customerName: "Carol"
        )
        var state = RootFeature.State()
        state.orders.orders = [realBeauty1, falsePositive, realBeauty2]

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.categorySelected("美妝")) {
            $0.selectedTab = .orders
            $0.orders.selectedCategory = "美妝"
            $0.orders.selectedOrderID = "TEST-BEAUTY-1"
        }

        // Then
        let filteredIDs = store.state.orders
            .filteredOrders(
                referenceDate: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            )
            .map(\.id)
        #expect(filteredIDs == ["TEST-BEAUTY-1", "TEST-BEAUTY-2"])
    }

    /// 付款方式更正確認後，寫入相同的正規化訂單
    @Test
    func lookupManagements_確認付款方式更正_轉送相同正規化訂單() async {
        // Given
        let original = LedgerOrder.fixture(
            id: "BL-PM-EDIT",
            chargedAmount: 5_000,
            cardlessDeductionAmount: 750,
            cardlessSupplementAmount: 250,
            paymentMethod: "匯款",
            reconciliationStatus: "待對帳",
            isCashOnDelivery: true
        )
        let normalized = LedgerOrder.fixture(
            id: "BL-PM-EDIT",
            chargedAmount: 5_000,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            paymentMethod: "銀行匯款",
            reconciliationStatus: "",
            isCashOnDelivery: false
        )
        let plan = PaymentMethodEditPlan(
            originalName: "匯款",
            newName: "銀行匯款",
            flags: .none,
            hasChangedFlags: true,
            affectedOrders: [normalized]
        )
        let updatedMaster = PaymentMethodInfo(name: "銀行匯款", flags: .none)
        let originalFlags = PaymentMethodFlags(
            isCardless: false,
            isBankTransfer: true,
            isCashOnDelivery: false
        )
        var state = Self.makeIsolatedRootState()
        state.orders.orders = [original]
        state.orders.$lookupCatalog.withLock {
            $0.paymentMethods = [PaymentMethodInfo(name: "匯款", flags: originalFlags)]
        }
        state.lookupManagements[id: .paymentMethod]?.correction.pendingPlan = plan
        state.lookupManagements[id: .paymentMethod]?.destination = .retroactiveConfirmation(
            affectedOrderCount: 1
        )
        let writes = LockIsolated<[PaymentMethodEditCall]>([])
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.paymentMethodService.applyPaymentMethodEdit = { oldName, newName, flags, orders in
                writes.withValue {
                    $0.append(
                        PaymentMethodEditCall(
                            oldName: oldName,
                            newName: newName,
                            flags: flags,
                            orders: orders
                        )
                    )
                }
            }
        }

        // When
        await store.send(
            .lookupManagements(
                .element(
                    id: .paymentMethod,
                    action: .destination(.presented(.alert(.confirmPaymentMethodEdit)))
                )
            )
        ) {
            $0.lookupManagements[id: .paymentMethod]?.destination = nil
        }

        // Then
        await store.receive(\.lookupManagements[id: .paymentMethod].correction.confirmed) {
            $0.lookupManagements[id: .paymentMethod]?.correction.pendingPlan = nil
            $0.orders.$lookupCatalog.withLock {
                $0.paymentMethods = [updatedMaster]
            }
        }
        await store.receive(
            \.lookupManagements[id: .paymentMethod].correction.editResponse.success,
            plan
        )
        await store.receive(
            \.lookupManagements[id: .paymentMethod].correction.delegate.edited,
            plan
        )
        await store.receive(
            \.lookupManagements[id: .paymentMethod].delegate.paymentMethodEdited,
            plan
        )
        await store.receive(\.orders.paymentMethodFlagsApplied) {
            Self.setOrdersAndProjections([normalized], state: &$0)
        }
        #expect(store.state.orders.orders == [normalized])
        #expect(store.state.orders.paymentMethodMaster == [updatedMaster])
        #expect(store.state.lookupManagements[id: .paymentMethod]?.items == ["銀行匯款"])
        #expect(
            writes.value == [
                PaymentMethodEditCall(
                    oldName: "匯款",
                    newName: "銀行匯款",
                    flags: .none,
                    orders: [normalized]
                ),
            ]
        )
        await store.finish()
    }

    /// 取消付款方式更正確認時，不寫入訂單或主檔
    ///
    /// - Note: `testValue` 的寫入 closure 為 `unimplemented`，非預期寫入會使測試失敗
    @Test
    func lookupManagements_取消付款方式更正_保留訂單與主檔() async {
        // Given
        let original = LedgerOrder.fixture(id: "BL-PM-CANCEL", paymentMethod: "匯款")
        let correctedOrder = LedgerOrder.fixture(id: "BL-PM-CANCEL", paymentMethod: "銀行匯款")
        let plan = PaymentMethodEditPlan(
            originalName: "匯款",
            newName: "銀行匯款",
            flags: .none,
            hasChangedFlags: true,
            affectedOrders: [correctedOrder]
        )
        let originalFlags = PaymentMethodFlags(
            isCardless: false,
            isBankTransfer: true,
            isCashOnDelivery: false
        )
        let originalMaster = PaymentMethodInfo(name: "匯款", flags: originalFlags)
        var state = Self.makeIsolatedRootState()
        state.orders.orders = [original]
        state.orders.$lookupCatalog.withLock { $0.paymentMethods = [originalMaster] }
        state.lookupManagements[id: .paymentMethod]?.correction.pendingPlan = plan
        state.lookupManagements[id: .paymentMethod]?.destination = .retroactiveConfirmation(
            affectedOrderCount: 1
        )
        let store = TestStore(initialState: state) {
            RootFeature()
        }

        // When
        await store.send(
            .lookupManagements(
                .element(
                    id: .paymentMethod,
                    action: .destination(.presented(.alert(.cancelPaymentMethodEdit)))
                )
            )
        ) {
            $0.lookupManagements[id: .paymentMethod]?.destination = nil
        }

        // Then
        await store.receive(\.lookupManagements[id: .paymentMethod].correction.cancelled) {
            $0.lookupManagements[id: .paymentMethod]?.correction.pendingPlan = nil
        }
        #expect(store.state.orders.orders == [original])
        #expect(store.state.orders.paymentMethodMaster == [originalMaster])
        #expect(store.state.lookupManagements[id: .paymentMethod]?.items == ["匯款"])
        await store.finish()
    }

    /// 付款方式更正寫入失敗時，保留原訂單與主檔
    @Test
    func lookupManagements_付款方式更正寫入失敗_保留訂單與主檔() async {
        // Given
        let original = LedgerOrder.fixture(id: "BL-PM-FAIL", paymentMethod: "匯款")
        let correctedOrder = LedgerOrder.fixture(id: "BL-PM-FAIL", paymentMethod: "銀行匯款")
        let plan = PaymentMethodEditPlan(
            originalName: "匯款",
            newName: "銀行匯款",
            flags: .none,
            hasChangedFlags: true,
            affectedOrders: [correctedOrder]
        )
        let originalFlags = PaymentMethodFlags(
            isCardless: false,
            isBankTransfer: true,
            isCashOnDelivery: false
        )
        let originalMaster = PaymentMethodInfo(name: "匯款", flags: originalFlags)
        var state = Self.makeIsolatedRootState()
        state.orders.orders = [original]
        state.orders.$lookupCatalog.withLock { $0.paymentMethods = [originalMaster] }
        state.lookupManagements[id: .paymentMethod]?.correction.pendingPlan = plan
        state.lookupManagements[id: .paymentMethod]?.destination = .retroactiveConfirmation(
            affectedOrderCount: 1
        )
        let failingApply: PaymentMethodService.ApplyPaymentMethodEdit = { _, _, _, _ in
            throw .storage(
                .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
            )
        }
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.paymentMethodService.applyPaymentMethodEdit = failingApply
        }

        // When
        await store.send(
            .lookupManagements(
                .element(
                    id: .paymentMethod,
                    action: .destination(.presented(.alert(.confirmPaymentMethodEdit)))
                )
            )
        ) {
            $0.lookupManagements[id: .paymentMethod]?.destination = nil
        }

        // Then
        await store.receive(\.lookupManagements[id: .paymentMethod].correction.confirmed) {
            $0.lookupManagements[id: .paymentMethod]?.correction.pendingPlan = nil
        }
        await store.receive(\.lookupManagements[id: .paymentMethod].correction.editResponse.failure)
        await store.receive(\.lookupManagements[id: .paymentMethod].correction.delegate.failed) {
            $0.lookupManagements[id: .paymentMethod]?.destination = .writeFailure(
                .paymentMethodEdit
            )
        }
        #expect(store.state.orders.orders == [original])
        #expect(store.state.orders.paymentMethodMaster == [originalMaster])
        #expect(store.state.lookupManagements[id: .paymentMethod]?.items == ["匯款"])
        await store.finish()
    }

    /// 改名分類時，只替換訂單中的目標名稱，並保留其他分類
    @Test
    func lookupManagements_分類改名_同步更新多分類訂單() async {
        // Given
        let multi = Self.makeTestOrder(id: "T-MULTI", categories: ["美妝", "服飾"], customerName: "客")
        let single = Self.makeTestOrder(id: "T-SINGLE", categories: ["服飾"], customerName: "客")
        let cosmeticsOnly = Self.makeTestOrder(
            id: "T-COSMETICS",
            categories: ["美妝"],
            customerName: "客"
        )
        let renamedMulti = Self.rebuiltOrder(multi, categories: ["彩妝保養", "服飾"])
        let renamedSingle = Self.rebuiltOrder(single, categories: ["服飾"])
        let renamedCosmeticsOnly = Self.rebuiltOrder(cosmeticsOnly, categories: ["彩妝保養"])
        var state = Self.makeIsolatedRootState()
        state.orders.orders = [multi, single, cosmeticsOnly]
        state.orders.$lookupCatalog.withLock { $0.categories = ["美妝", "服飾"] }
        state.lookupManagements[id: .category]?.destination = .rename(
            LookupRenameFormFeature.State(originalName: "美妝")
        )
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.orderService.applyCategoryRename = { _, _ in
            }
        }
        let rename = LookupItemRename(oldName: "美妝", newName: "彩妝保養")

        // When
        await store.send(
            .lookupManagements(
                .element(
                    id: .category,
                    action: .destination(
                        .presented(.rename(.view(.saveButtonTapped(name: "彩妝保養"))))
                    )
                )
            )
        )

        // Then
        await store.receive(
            \.lookupManagements[id: .category].destination.presented.rename.delegate.saved
        ) {
            $0.lookupManagements[id: .category]?.destination = nil
            $0.lookupManagements[id: .category]?.isFormSheetDismissing = true
            $0.orders.$lookupCatalog.withLock {
                $0.categories = ["服飾", "彩妝保養"]
            }
        }
        await store.receive(\.lookupManagements[id: .category].renameResponse.success, rename)
        await store.receive(\.lookupManagements[id: .category].delegate.itemRenamed, rename) {
            Self.setOrdersAndProjections(
                [renamedMulti, renamedSingle, renamedCosmeticsOnly],
                state: &$0
            )
        }
        #expect(store.state.lookupManagements[id: .category]?.items == ["服飾", "彩妝保養"])
        #expect(store.state.orders.availableCategories.contains("彩妝保養"))
        #expect(!store.state.orders.availableCategories.contains("美妝"))
        #expect(store.state.orders.orders == [renamedMulti, renamedSingle, renamedCosmeticsOnly])
        await store.finish()
    }

    /// 開團改名時，只替換訂單裡的目標團名，同筆訂單的其他開團不變
    @Test
    func campaigns_開團改名_同步更新多開團訂單() async {
        // Given
        let multi = Self.makeTestOrder(
            id: "T-CAMP",
            categories: ["美妝"],
            customerName: "客",
            campaignNames: ["三月日本團", "四月韓國團"]
        )
        let renamedMulti = Self.rebuiltOrder(multi, campaignNames: ["三月日本團 (補)", "四月韓國團"])
        var state = RootFeature.State()
        state.orders.orders = [multi]

        let store = TestStore(initialState: state) {
            RootFeature()
        }

        // When
        await store.send(.campaigns(.campaignRenamed(from: "三月日本團", to: "三月日本團 (補)"))) {
            Self.setOrdersAndProjections([renamedMulti], state: &$0)
        }

        // Then
        #expect(store.state.orders.orders == [renamedMulti])
    }

    /// AI 功能關閉的提示按下「前往開啟」時，既有路徑一律先清空，設定頁只推入一份
    ///
    /// - Parameter initialPath: 點擊前「更多」分頁的既有路徑
    @Test(arguments: [[], [.customers, .settings]] as [[RootFeature.MoreRoute]])
    func orders_前往開啟人工智慧設定_更多路徑只留設定頁(initialPath: [RootFeature.MoreRoute]) async {
        // Given
        var initial = RootFeature.State()
        initial.morePath = initialPath
        initial.orders.aiDisabledAlert = Self.aiDisabledAlert()
        let store = TestStore(initialState: initial) {
            RootFeature()
        }

        // When
        await store.send(.orders(.aiDisabledAlert(.presented(.goToAISettings)))) {
            $0.orders.aiDisabledAlert = nil
            $0.selectedTab = .more
            $0.morePath = [.settings]
        }

        // Then
        #expect(store.state.selectedTab == .more)
        #expect(store.state.morePath == [.settings])
    }

    /// 訂單編輯新增的類別會同步到管理頁
    @Test
    func orders_訂單編輯中新增分類_同步至查詢管理() async {
        // Given
        let state = Self.makeIsolatedRootState {
            var rootState = RootFeature.State()
            rootState.orders.editOrder = OrderEditFeature.State(
                id: UUID(0),
                currentDate: TestDependencies.fixedNow
            )
            return rootState
        }

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.categoryService.addCategory = { _ in
            }
        }

        // When
        await store.send(.orders(.editOrder(.presented(.addCategoryTapped("手工藝品"))))) {
            $0.orders.editOrder?.availableCategories = ["手工藝品"]
            $0.orders.editOrder?.draft.categories = ["手工藝品"]
            $0.orders.$lookupCatalog.withLock {
                $0.categories = ["手工藝品"]
            }
        }

        // Then
        // 管理頁尚未載入時也要立即讀到共用目錄的新項目
        #expect(store.state.lookupManagements[id: .category]?.items == ["手工藝品"])
    }

    /// 訂單來源改名成功後，主檔清單與引用舊名的訂單都換成新名
    ///
    /// - Note: 各頁面的訂單投影已在 `itemRenamed` 的 `receive` 以字面值斷言，不另寫只比對投影的測試
    @Test
    func lookupManagements_訂單來源改名_透過委派改寫訂單() async {
        // Given
        let order = Self.makeOrder(id: "T-OS", orderSource: "舊來源")
        let renamedOrder = Self.makeOrder(id: "T-OS", orderSource: "新來源")
        var state = Self.makeIsolatedRootState()
        state.orders.orders = [order]
        state.orders.$lookupCatalog.withLock { $0.orderSources = ["舊來源"] }
        state.lookupManagements[id: .orderSource]?.destination = .rename(
            LookupRenameFormFeature.State(originalName: "舊來源")
        )
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.orderService.applyOrderSourceRename = { _, _ in
            }
        }
        let rename = LookupItemRename(oldName: "舊來源", newName: "新來源")

        // When
        await store.send(
            .lookupManagements(
                .element(
                    id: .orderSource,
                    action: .destination(.presented(.rename(.view(.saveButtonTapped(name: "新來源")))))
                )
            )
        )

        // Then
        await store.receive(
            \.lookupManagements[id: .orderSource].destination.presented.rename.delegate.saved
        ) {
            $0.lookupManagements[id: .orderSource]?.destination = nil
            $0.lookupManagements[id: .orderSource]?.isFormSheetDismissing = true
            $0.orders.$lookupCatalog.withLock {
                $0.orderSources = ["新來源"]
            }
        }
        await store.receive(\.lookupManagements[id: .orderSource].renameResponse.success, rename)
        await store.receive(\.lookupManagements[id: .orderSource].delegate.itemRenamed, rename) {
            Self.setOrdersAndProjections([renamedOrder], state: &$0)
        }
        #expect(store.state.lookupManagements[id: .orderSource]?.items == ["新來源"])
        #expect(store.state.orders.availableOrderSources.contains("新來源"))
        #expect(!store.state.orders.availableOrderSources.contains("舊來源"))
        #expect(store.state.orders.orders.first?.orderSource == "新來源")
        await store.finish()
    }

    /// 商品類別改名成功後，主檔清單與引用舊名的訂單都換成新名
    @Test
    func lookupManagements_分類改名_透過委派改寫訂單() async {
        // Given
        let order = Self.makeOrder(id: "T-CAT", categories: ["舊類別"])
        let renamedOrder = Self.makeOrder(id: "T-CAT", categories: ["新類別"])
        var state = Self.makeIsolatedRootState()
        state.orders.orders = [order]
        state.orders.$lookupCatalog.withLock { $0.categories = ["舊類別"] }
        state.lookupManagements[id: .category]?.destination = .rename(
            LookupRenameFormFeature.State(originalName: "舊類別")
        )
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.orderService.applyCategoryRename = { _, _ in
            }
        }
        let rename = LookupItemRename(oldName: "舊類別", newName: "新類別")

        // When
        await store.send(
            .lookupManagements(
                .element(
                    id: .category,
                    action: .destination(.presented(.rename(.view(.saveButtonTapped(name: "新類別")))))
                )
            )
        )

        // Then
        await store.receive(
            \.lookupManagements[id: .category].destination.presented.rename.delegate.saved
        ) {
            $0.lookupManagements[id: .category]?.destination = nil
            $0.lookupManagements[id: .category]?.isFormSheetDismissing = true
            $0.orders.$lookupCatalog.withLock {
                $0.categories = ["新類別"]
            }
        }
        await store.receive(\.lookupManagements[id: .category].renameResponse.success, rename)
        await store.receive(\.lookupManagements[id: .category].delegate.itemRenamed, rename) {
            Self.setOrdersAndProjections([renamedOrder], state: &$0)
        }
        #expect(store.state.lookupManagements[id: .category]?.items == ["新類別"])
        #expect(store.state.orders.availableCategories.contains("新類別"))
        #expect(!store.state.orders.availableCategories.contains("舊類別"))
        #expect(store.state.orders.orders.first?.categories == ["新類別"])
        await store.finish()
    }

    /// 對帳狀態改名成功後，主檔清單與引用舊名的訂單都換成新名
    @Test
    func lookupManagements_對帳狀態改名_透過委派改寫訂單() async {
        // Given
        let order = Self.makeOrder(id: "T-RS", reconciliationStatus: "待對帳")
        let renamedOrder = Self.makeOrder(id: "T-RS", reconciliationStatus: "已對帳")
        var state = Self.makeIsolatedRootState()
        state.orders.orders = [order]
        state.orders.$lookupCatalog.withLock {
            $0.reconciliationStatuses = ["待對帳"]
        }
        state.lookupManagements[id: .reconciliationStatus]?.destination = .rename(
            LookupRenameFormFeature.State(originalName: "待對帳")
        )
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.orderService.applyReconciliationStatusRename = { _, _ in
            }
        }
        let rename = LookupItemRename(oldName: "待對帳", newName: "已對帳")

        // When
        await store.send(
            .lookupManagements(
                .element(
                    id: .reconciliationStatus,
                    action: .destination(.presented(.rename(.view(.saveButtonTapped(name: "已對帳")))))
                )
            )
        )

        // Then
        await store.receive(
            \.lookupManagements[id: .reconciliationStatus]
                .destination.presented.rename.delegate.saved
        ) {
            $0.lookupManagements[id: .reconciliationStatus]?.destination = nil
            $0.lookupManagements[id: .reconciliationStatus]?.isFormSheetDismissing = true
            $0.orders.$lookupCatalog.withLock {
                $0.reconciliationStatuses = ["已對帳"]
            }
        }
        await store.receive(
            \.lookupManagements[id: .reconciliationStatus].renameResponse.success,
            rename
        )
        await store.receive(
            \.lookupManagements[id: .reconciliationStatus].delegate.itemRenamed,
            rename
        ) {
            Self.setOrdersAndProjections([renamedOrder], state: &$0)
        }
        #expect(store.state.lookupManagements[id: .reconciliationStatus]?.items == ["已對帳"])
        #expect(store.state.orders.availableReconciliationStatuses.contains("已對帳"))
        #expect(!store.state.orders.availableReconciliationStatuses.contains("待對帳"))
        #expect(store.state.orders.orders.first?.reconciliationStatus == "已對帳")
        await store.finish()
    }

    /// 付款方式改名成功後，主檔清單與引用舊名的訂單都換成新名
    @Test
    func lookupManagements_付款方式改名_透過委派改寫訂單() async {
        // Given
        let order = Self.makeOrder(id: "T-PM", paymentMethod: "舊付款")
        let renamedOrder = Self.makeOrder(id: "T-PM", paymentMethod: "新付款")
        var state = Self.makeIsolatedRootState()
        state.orders.orders = [order]
        state.orders.$lookupCatalog.withLock {
            $0.paymentMethods = [PaymentMethodInfo(name: "舊付款", flags: .none)]
        }
        state.lookupManagements[id: .paymentMethod]?.destination = .rename(
            LookupRenameFormFeature.State(originalName: "舊付款")
        )
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.orderService.applyPaymentMethodRename = { _, _ in
            }
        }
        let rename = LookupItemRename(oldName: "舊付款", newName: "新付款")

        // When
        await store.send(
            .lookupManagements(
                .element(
                    id: .paymentMethod,
                    action: .destination(.presented(.rename(.view(.saveButtonTapped(name: "新付款")))))
                )
            )
        )

        // Then
        await store.receive(
            \.lookupManagements[id: .paymentMethod].destination.presented.rename.delegate.saved
        ) {
            $0.lookupManagements[id: .paymentMethod]?.destination = nil
            $0.lookupManagements[id: .paymentMethod]?.isFormSheetDismissing = true
            $0.orders.$lookupCatalog.withLock {
                $0.paymentMethods = [PaymentMethodInfo(name: "新付款", flags: .none)]
            }
        }
        await store.receive(\.lookupManagements[id: .paymentMethod].renameResponse.success, rename)
        await store.receive(\.lookupManagements[id: .paymentMethod].delegate.itemRenamed, rename) {
            Self.setOrdersAndProjections([renamedOrder], state: &$0)
        }
        #expect(store.state.lookupManagements[id: .paymentMethod]?.items == ["新付款"])
        #expect(store.state.orders.availablePaymentMethods.map(\.name).contains("新付款"))
        #expect(!store.state.orders.availablePaymentMethods.map(\.name).contains("舊付款"))
        #expect(store.state.orders.orders.first?.paymentMethod == "新付款")
        await store.finish()
    }

    /// 刪除分類後，訂單編輯選單不再提供該類別
    ///
    /// - Throws: 刪除前若主檔不存在，`#require` 會使測試失敗
    @Test
    func lookupManagements_刪除分類_從訂單編輯選項移除() async throws {
        // Given
        var state = Self.makeIsolatedRootState()
        state.orders.$lookupCatalog.withLock { $0.categories = ["待刪類別"] }
        state.lookupManagements[id: .category]?.destination = .deleteConfirmation(name: "待刪類別")
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.categoryService.removeCategory = { _ in
            }
        }
        try #require(store.state.orders.availableCategories.contains("待刪類別"))

        // When
        await store.send(
            .lookupManagements(
                .element(
                    id: .category,
                    action: .destination(.presented(.alert(.confirmDelete(name: "待刪類別"))))
                )
            )
        ) {
            $0.lookupManagements[id: .category]?.destination = nil
        }

        // Then
        await store.receive(\.lookupManagements[id: .category].deleteResponse.success, "待刪類別") {
            $0.orders.$lookupCatalog.withLock {
                $0.categories = []
            }
        }
        #expect(store.state.lookupManagements[id: .category]?.items == [])
        #expect(!store.state.orders.availableCategories.contains("待刪類別"))
        await store.finish()
    }

    /// 分類改名失敗時保留原主檔與訂單，不送出成功改名
    @Test
    func lookupManagements_分類改名寫入失敗_保留訂單() async {
        // Given
        let order = Self.makeOrder(id: "T-CAT-FAIL", categories: ["服飾"])
        var state = Self.makeIsolatedRootState()
        state.orders.orders = [order]
        state.orders.$lookupCatalog.withLock { $0.categories = ["服飾"] }
        state.lookupManagements[id: .category]?.destination = .rename(
            LookupRenameFormFeature.State(originalName: "服飾")
        )
        let renameCalls = LockIsolated<[LookupItemRename]>([])
        let failingRename: OrderService.ApplyCategoryRename = { oldName, newName in
            renameCalls.withValue {
                $0.append(LookupItemRename(oldName: oldName, newName: newName))
            }
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
        }
        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.orderService.applyCategoryRename = failingRename
        }

        // When
        await store.send(
            .lookupManagements(
                .element(
                    id: .category,
                    action: .destination(.presented(.rename(.view(.saveButtonTapped(name: "衣著")))))
                )
            )
        )

        // Then
        await store.receive(
            \.lookupManagements[id: .category].destination.presented.rename.delegate.saved
        ) {
            $0.lookupManagements[id: .category]?.destination = nil
            $0.lookupManagements[id: .category]?.isFormSheetDismissing = true
        }
        await store.receive(\.lookupManagements[id: .category].renameResponse.failure) {
            $0.lookupManagements[id: .category]?.pendingAlert = .writeFailure(.rename)
        }
        #expect(store.state.lookupManagements[id: .category]?.items == ["服飾"])
        #expect(store.state.orders.orders == [order])
        #expect(store.state.orders.availableCategories.contains("服飾"))
        #expect(renameCalls.value == [LookupItemRename(oldName: "服飾", newName: "衣著")])
        await store.finish()
    }

    /// 開團清單載入後，訂單、總覽與分析頁拿到同一份清單
    @Test
    func campaigns_載入開團清單_同步訂單總覽與分析投影() async {
        // Given
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        let loaded = [Self.makeCampaign()]

        // When
        await store.send(.campaigns(.campaignsLoaded(loaded))) {
            $0.campaigns.campaigns = loaded
            $0.campaigns.hasLoaded = true
            $0.orders.campaigns = loaded
            $0.dashboard.campaigns = loaded
            $0.insights.campaigns = loaded
        }

        // Then
        #expect(store.state.orders.campaigns == loaded)
        #expect(store.state.dashboard.campaigns == loaded)
        #expect(store.state.insights.campaigns == loaded)
    }

    /// 總覽點選開團時，切到開團分頁並選取該團
    @Test
    func dashboard_點選總覽開團_切至開團頁並選取該團() async {
        // Given
        var state = RootFeature.State()
        state.campaigns.campaigns = [Self.makeCampaign()]

        let store = TestStore(initialState: state) {
            RootFeature()
        }

        // When
        await store.send(.dashboard(.delegate(.campaignTapped("四月韓國團"))))

        // Then
        await store.receive(\.campaignSelected) {
            $0.selectedTab = .campaigns
            $0.campaigns.selectedCampaignID = "C1"
        }
    }

    /// 總覽點選新增訂單時，切到訂單分頁並開啟新表單
    @Test
    func dashboard_點選新增訂單_切至訂單頁並開啟表單() async {
        // Given
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.date = .constant(TestDependencies.fixedNow)
        }

        // When
        await store.send(.dashboard(.delegate(.newOrderTapped)))

        // Then
        await store.receive(\.startNewOrder) {
            $0.selectedTab = .orders
            $0.orders.editOrder = OrderEditFeature.State(
                id: UUID(0),
                currentDate: TestDependencies.fixedNow
            )
        }
    }

    /// 總覽點選「查看全部」時，切到訂單分頁
    @Test
    func dashboard_點選檢視全部訂單_切至訂單頁() async {
        // Given
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        }

        // When
        await store.send(.dashboard(.delegate(.viewAllOrdersTapped)))

        // Then
        await store.receive(\.tabSelected) {
            $0.selectedTab = .orders
        }
    }

    /// 總覽出現時檢查訂單是否需要載入，不重讀設定
    ///
    /// - Note: `testValue` 的 `settingsService.load` 為 `unimplemented`，非預期重讀會使測試失敗
    @Test
    func dashboard_總覽出現時重新整理_只重新載入訂單() async {
        // Given
        var state = RootFeature.State()
        // 已載入時 `orders.task` 不再讀資料，本測試只驗轉送
        state.orders.hasLoaded = true

        let store = TestStore(initialState: state) {
            RootFeature()
        }

        // When
        await store.send(.dashboard(.task))

        // Then
        await store.receive(\.dashboard.delegate.refresh)
        await store.receive(\.orders.task)
        await store.finish()
    }

    /// 分析頁點選開團時，切到開團分頁並選取該團
    @Test
    func insights_點選洞察開團_切至開團頁並選取該團() async {
        // Given
        var state = RootFeature.State()
        state.campaigns.campaigns = [Self.makeCampaign()]

        let store = TestStore(initialState: state) {
            RootFeature()
        }

        // When
        await store.send(.insights(.delegate(.campaignTapped("四月韓國團"))))

        // Then
        await store.receive(\.campaignSelected) {
            $0.selectedTab = .campaigns
            $0.campaigns.selectedCampaignID = "C1"
        }
    }

    /// 分析頁點選類別排行時，切到訂單分頁並套用類別篩選
    @Test
    func insights_點選洞察分類_切至訂單頁並篩選分類() async {
        // Given
        let store = TestStore(initialState: RootFeature.State()) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.insights(.delegate(.categoryTapped("美妝"))))

        // Then
        await store.receive(\.categorySelected) {
            $0.selectedTab = .orders
            $0.orders.selectedCategory = "美妝"
        }
    }

    /// 開團頁切換收款狀態時，訂單寫入成功後同步更新所有頁面的訂單
    @Test
    func campaigns_切換開團收款狀態_更新所有頁面的訂單() async {
        // Given
        let order = Self.makeTestOrder(id: "BL-RS-TOGGLE", category: "美妝", customerName: "收款測試")
        let receivedOrder = Self.rebuiltOrder(order, paymentReceiptStatus: .received)
        var state = RootFeature.State()
        state.orders.orders = [order]

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { _ in
            }
        }

        // When
        await store.send(.campaigns(.delegate(.receiptStatusToggled(order.id, .received))))

        // Then
        await store.receive(\.orders.receiptStatusChanged)
        await store.receive(\.orders.receiptStatusChangePersisted) {
            Self.setOrdersAndProjections([receivedOrder], state: &$0)
        }
    }

    /// 客戶頁載入時，要求訂單功能檢查是否需要載入資料
    @Test
    func customers_載入客戶清單_送出訂單載入動作() async {
        // Given
        var state = RootFeature.State()
        // 已載入時 `orders.task` 不再讀資料，本測試只驗轉送
        state.orders.hasLoaded = true

        let store = TestStore(initialState: state) {
            RootFeature()
        }

        // When
        await store.send(.customers(.delegate(.ordersLoadRequested)))

        // Then
        await store.receive(\.orders.task)
    }

    /// 從「更多」裡的客戶頁點選客戶，先清空更多路徑再切到訂單分頁並以客戶名搜尋
    @Test
    func customers_點選客戶_切換分頁前清空更多路徑() async {
        // Given
        var state = RootFeature.State()
        state.selectedTab = .more
        state.morePath = [.customers]

        let store = TestStore(initialState: state) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.customers(.view(.customerTapped("Alice"))))

        // Then
        await store.receive(\.customers.delegate.customerSelected, "Alice")
        await store.receive(\.customerSelected) {
            $0.morePath = []
            $0.selectedTab = .orders
            $0.orders.searchText = "Alice"
            $0.orders.selectedStatus = .all
            $0.orders.selectedDatePeriod = .all
        }
        #expect(store.state.morePath.isEmpty)
        #expect(store.state.selectedTab == .orders)
    }
}

// MARK: - Nested Types

private extension RootFeatureTests {

    /// 付款方式更正寫入時實際收到的一次呼叫參數，用來核對寫入內容
    struct PaymentMethodEditCall: Equatable, Sendable {

        /// 原付款方式名稱
        let oldName: String

        /// 新付款方式名稱
        let newName: String

        /// 寫入的付款方式旗標
        let flags: PaymentMethodFlags

        /// 傳入的正規化訂單
        let orders: [LedgerOrder]
    }
}

// MARK: - Private Method

private extension RootFeatureTests {

    /// 建立只指定類別的測試訂單
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

    /// 以獨立的記憶體儲存建立根 State，讓改動共享主檔目錄的測試不污染其他測試
    ///
    /// - Parameter build: 建立根 State 的操作
    /// - Returns: 建立完成的測試狀態
    static func makeIsolatedRootState(
        _ build: () -> RootFeature.State = { RootFeature.State() }
    ) -> RootFeature.State {
        withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            build()
        }
    }

    /// 同步根畫面的訂單與各頁面投影
    ///
    /// - Parameters:
    ///   - orders: 更新後的訂單
    ///   - state: 要更新的根畫面狀態
    static func setOrdersAndProjections(_ orders: [LedgerOrder], state: inout RootFeature.State) {
        state.orders.orders = orders
        state.customers.orders = orders
        state.campaigns.orders = orders
        state.dashboard.orders = orders
        state.insights.orders = orders
    }

    /// 複製訂單並只替換指定欄位，其餘欄位保留原值
    ///
    /// - Parameters:
    ///   - order: 原始訂單
    ///   - categories: 新的商品類別，未提供時保留原值
    ///   - campaignNames: 新的開團名稱，未提供時保留原值
    ///   - paymentReceiptStatus: 新的收款狀態，未提供時保留原值
    /// - Returns: 套用指定欄位後的訂單
    static func rebuiltOrder(
        _ order: LedgerOrder,
        categories: [String]? = nil,
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
            cardlessDeductionAmount: order.cardlessDeductionAmount,
            cardlessSupplementAmount: order.cardlessSupplementAmount,
            orderSource: order.orderSource,
            categories: categories ?? order.categories,
            paymentMethod: order.paymentMethod,
            notes: order.notes,
            reconciliationStatus: order.reconciliationStatus,
            campaignNames: campaignNames ?? order.campaignNames,
            paymentReceiptStatus: paymentReceiptStatus ?? order.paymentReceiptStatus,
            isCashOnDelivery: order.isCashOnDelivery,
            photos: order.photos,
            mergedSourceIDs: order.mergedSourceIDs
        )
    }

    /// 建立 AI 功能關閉時顯示的提示
    ///
    /// - Returns: 關閉提示的 `AlertState`
    static func aiDisabledAlert() -> AlertState<OrdersFeature.Action.Alert> {
        AlertState {
            TextState("AI 商品明細總結")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("關閉")
            }
            ButtonState(action: .goToAISettings) {
                TextState("前往開啟")
            }
        } message: {
            TextState("此功能需要先在「更多 → 設定」開啟 AI 商品明細總結。")
        }
    }

    /// 建立可指定主檔欄位的最小訂單
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

    /// 建立開團清單同步與跨頁導覽測試共用的開團「四月韓國團」
    ///
    /// - Returns: 建立的測試開團
    static func makeCampaign() -> Campaign {
        Campaign(
            id: "C1",
            name: "四月韓國團",
            openDate: TestDependencies.fixedNow,
            closeDate: nil,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
    }
}
