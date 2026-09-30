//
//  OrdersFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/1.
//

import Clocks
import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `OrdersFeature` 的單元測試，以 TestStore 逐步驗證每個 Action 造成的狀態變化與後續 Action
@MainActor
struct OrdersFeatureTests {

    // MARK: - Tests

    /// 畫面第一次出現時載入訂單清單，並自動選取第一筆訂單
    @Test
    func task_載入訂單清單_選取第一筆訂單() async {
        // Given
        let orders = LedgerOrder.sampleOrders
        var state = OrdersFeature.State()
        state.errorMessage = "舊錯誤"
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.fetchOrders = {
                LedgerOrder.sampleOrders
            }
            Self.suppressOrderLookupEffects(&$0)
        }

        // When
        await store.send(.task) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        // Then
        await store.receive(\.ordersLoaded) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.orders = orders
            $0.selectedOrderID = "BL-2604-018"
        }
        await store.finish()
    }

    /// 開團的結單日就是今天時，載入後仍算進行中，不會被自動結單
    ///
    /// - Note: 現在時間設為同日 23:00，晚於結單時間點，只有以日期判斷才會維持進行中
    @Test
    func campaignsLoaded_開團今天到期_仍維持進行中() async {
        // Given
        let campaign = Campaign(
            id: "C1",
            name: "今天團",
            openDate: TestDependencies.fixedNow,
            closeDate: TestDependencies.fixedNow,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let store = TestStore(initialState: OrdersFeature.State()) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow.addingTimeInterval(82_800))
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.campaignsLoaded([campaign])) {
            $0.campaigns = [campaign]
        }

        // Then
        #expect(store.state.campaigns.map(\.status) == [.ongoing])
    }

    /// 搜尋輸入依客戶名稱或商品名稱篩選訂單
    ///
    /// - Parameter searchCase: 搜尋文字與預期的選取、列出結果
    @Test(arguments: [
        SearchCase(
            query: "mika",
            selectedOrderID: "BL-2604-017",
            expectedOrderIDs: ["BL-2604-017", "BL-2604-011"]
        ),
        SearchCase(
            query: "Aesop",
            selectedOrderID: "BL-2604-016",
            expectedOrderIDs: ["BL-2604-016"]
        ),
    ])
    func searchTextChanged_輸入客戶名稱或商品名稱_篩選訂單(searchCase: SearchCase) async {
        // Given
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.searchTextChanged(searchCase.query)) {
            $0.searchText = searchCase.query
            $0.selectedOrderID = searchCase.selectedOrderID
        }

        // Then
        let filtered = store.state.filteredOrders(
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        #expect(filtered.map(\.id) == searchCase.expectedOrderIDs)
    }

    /// 選取集運中篩選時，只列出集運中的訂單並改選第一筆相符訂單
    @Test
    func statusFilterSelected_選取訂單狀態_只顯示相符訂單() async {
        // Given
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.statusFilterSelected(.shipping)) {
            $0.selectedStatus = .shipping
            $0.selectedOrderID = "BL-2604-018"
        }

        // Then
        let filtered = store.state.filteredOrders(
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )

        #expect(filtered.allSatisfy { $0.status == .shipping })
        #expect(filtered.map(\.id) == ["BL-2604-018", "BL-2604-011"])
    }

    /// 修改既有訂單的客戶名稱後儲存，清單中的訂單換成新名稱並只寫入一次
    ///
    /// - Note: 既有訂單一律走更新操作，誤走建立操作由 `testValue` 的 `unimplemented` 擋下
    @Test
    func editOrder_儲存客戶名稱_更新呈現訂單() async {
        // Given
        let original = LedgerOrder.fixture(id: "order-1")
        let newName = "重新命名客戶"

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        // 直接預塞草稿，避開 Swift 6 的 BindingAction Sendable 限制
        draft.draft.customerName = newName

        var state = OrdersFeature.State()
        state.orders = [original]
        state.editOrder = draft

        let savedOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                savedOrders.withValue {
                    $0.append(order)
                }
            }
        }
        let expectedOrder = LedgerOrder.fixture(
            id: "order-1",
            customer: LedgerCustomer(name: "重新命名客戶", initials: "TC", tier: .regular)
        )

        // When
        await store.send(.editOrder(.presented(.saveTapped)))

        // Then
        await store.receive(\.orderSavePersisted) { $0.orders = [expectedOrder] }
        // saveTapped 會一律 dismiss 表單
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        #expect(savedOrders.value == [expectedOrder])
    }

    /// 修改訂單備註後儲存，去掉前後空白再寫回清單與儲存層
    @Test
    func editOrder_儲存訂單備註_更新呈現訂單() async {
        // Given
        let original = LedgerOrder.fixture(id: "order-1")

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.notes = "  到貨後請先聯絡客戶確認尺寸  "

        var state = OrdersFeature.State()
        state.orders = [original]
        state.editOrder = draft

        let savedOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                savedOrders.withValue {
                    $0.append(order)
                }
            }
        }
        let expectedOrder = LedgerOrder.fixture(id: "order-1", notes: "到貨後請先聯絡客戶確認尺寸")

        // When
        await store.send(.editOrder(.presented(.saveTapped)))

        // Then
        await store.receive(\.orderSavePersisted) { $0.orders = [expectedOrder] }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        #expect(savedOrders.value == [expectedOrder])
    }

    /// 照片載入完成且修改過時儲存，連同新照片一起寫入並更新清單
    ///
    /// - Note: 照片已載入且修改過時走帶照片的寫入，誤用不帶照片的 `saveOrder` 由 `testValue` 的 `unimplemented` 擋下
    @Test
    func editOrder_修改既有訂單照片_儲存後更新訂單() async {
        // Given
        let original = LedgerOrder.fixture(id: "order-1")
        let photos = [Data([0x01]), Data([0x02])]

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        draft.photoLoadPhase = .loaded
        draft.hasEditedPhotos = true
        draft.draftPhotos = photos

        var state = OrdersFeature.State()
        state.orders = [original]
        state.editOrder = draft

        let savedOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrderPersistingPhotos = { order in
                savedOrders.withValue {
                    $0.append(order)
                }
            }
        }
        let expectedOrder = LedgerOrder.fixture(id: "order-1", photos: photos)

        // When
        await store.send(.editOrder(.presented(.saveTapped)))

        // Then
        await store.receive(\.orderSavePersisted) { $0.orders = [expectedOrder] }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        #expect(savedOrders.value == [expectedOrder])
    }

    /// 新增含照片的訂單並儲存，新訂單帶著照片加入清單
    @Test
    func editOrder_新增訂單含照片_儲存後加入訂單() async {
        // Given
        let photos = [Data([0xA1])]

        var draft = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.customerName = "新照片客戶"
        draft.draftPhotos = photos

        var state = OrdersFeature.State()
        state.editOrder = draft

        let createdOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.orderService.createOrder = { order in
                createdOrders.withValue {
                    $0.append(order)
                }
            }
        }
        let expectedOrder = LedgerOrder.fixture(
            id: "BL-DRAFT-00000000-0000-0000-0000-000000000000",
            customer: LedgerCustomer(name: "新照片客戶", initials: "新照", tier: .new),
            status: .quoting,
            date: TestDependencies.fixedNow,
            orderSource: "未指定",
            categories: ["未分類"],
            paymentMethod: "",
            photos: photos
        )

        // When
        await store.send(.editOrder(.presented(.saveTapped)))

        // Then
        await store.receive(\.orderSavePersisted) {
            $0.orders = [expectedOrder]
            $0.selectedOrderID = "BL-DRAFT-00000000-0000-0000-0000-000000000000"
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        #expect(createdOrders.value == [expectedOrder])
    }

    /// 付款方式改成銀行匯款後儲存，保留填寫的對帳狀態
    @Test
    func editOrder_銀行匯款訂單儲存_保留對帳狀態() async {
        // Given
        let original = LedgerOrder.fixture(id: "order-1")

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            availablePaymentMethods: [
                PaymentMethodInfo(
                    name: "銀行匯款",
                    isCardless: false,
                    isBankTransfer: true,
                    isCashOnDelivery: false
                ),
            ],
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.paymentMethod = "銀行匯款"
        draft.draft.reconciliationStatus = "待對帳"

        var state = OrdersFeature.State()
        state.orders = [original]
        state.editOrder = draft

        let savedOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                savedOrders.withValue {
                    $0.append(order)
                }
            }
        }
        let expectedOrder = LedgerOrder.fixture(
            id: "order-1",
            paymentMethod: "銀行匯款",
            reconciliationStatus: "待對帳"
        )

        // When
        await store.send(.editOrder(.presented(.saveTapped)))

        // Then
        await store.receive(\.orderSavePersisted) { $0.orders = [expectedOrder] }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        #expect(savedOrders.value == [expectedOrder])
    }

    /// 付款方式從銀行匯款改成不需對帳的方式後儲存，清掉原本的對帳狀態
    @Test
    func editOrder_改用不需對帳付款方式_清除對帳狀態() async {
        // Given
        let original = LedgerOrder.fixture(
            id: "order-1",
            paymentMethod: "銀行匯款",
            reconciliationStatus: "待對帳"
        )

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            availablePaymentMethods: [
                PaymentMethodInfo(
                    name: "銀行匯款",
                    isCardless: false,
                    isBankTransfer: true,
                    isCashOnDelivery: false
                ),
                PaymentMethodInfo(
                    name: "信用卡",
                    isCardless: false,
                    isBankTransfer: false,
                    isCashOnDelivery: false
                ),
            ],
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.paymentMethod = "信用卡"

        var state = OrdersFeature.State()
        state.orders = [original]
        state.editOrder = draft

        let savedOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                savedOrders.withValue {
                    $0.append(order)
                }
            }
        }
        let expectedOrder = LedgerOrder.fixture(id: "order-1", paymentMethod: "信用卡")

        // When
        await store.send(.editOrder(.presented(.saveTapped)))

        // Then
        await store.receive(\.orderSavePersisted) { $0.orders = [expectedOrder] }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        #expect(savedOrders.value == [expectedOrder])
    }

    /// 客戶名稱只輸入空白時儲存，沿用原本的客戶名稱
    @Test
    func editOrder_客戶名稱輸入空白_保留原名稱() async {
        // Given
        let original = LedgerOrder.fixture(id: "order-1")

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.customerName = "   "

        var state = OrdersFeature.State()
        state.orders = [original]
        state.editOrder = draft

        let savedOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                savedOrders.withValue {
                    $0.append(order)
                }
            }
        }

        // When
        await store.send(.editOrder(.presented(.saveTapped)))

        // Then
        await store.receive(\.orderSavePersisted)
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        #expect(savedOrders.value == [original])
    }

    /// 有未儲存變更時確認捨棄，關閉編輯表單且訂單清單不變
    @Test
    func editOrder_確認捨棄變更_不修改訂單清單() async {
        // Given
        let original = LedgerOrder.fixture(id: "order-1")

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.customerName = "暫定名字"
        draft.discardConfirmation = AlertState {
            TextState("捨棄變更")
        } actions: {
            ButtonState(role: .destructive, action: .discard) {
                TextState("捨棄變更")
            }
            ButtonState(role: .cancel) {
                TextState("繼續編輯")
            }
        } message: {
            TextState("這張訂單有尚未儲存的變更，離開後將不會保留。")
        }

        var state = OrdersFeature.State()
        state.orders = [original]
        state.editOrder = draft

        let store = TestStore(initialState: state) {
            OrdersFeature()
        }

        // When
        await store.send(.editOrder(.presented(.discardConfirmation(.presented(.discard))))) {
            $0.editOrder?.discardConfirmation = nil
        }

        // Then
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        #expect(store.state.orders == [original])
    }

    /// 點選既有訂單時開啟編輯表單，草稿帶入該訂單內容，選項來自清單中的訂單
    ///
    /// - Note: 預期選項只來自訂單，前提是主檔目錄為空，所以在隔離 storage 內執行
    @Test
    func editOrderTapped_點選既有訂單_呈現編輯狀態() async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            var state = OrdersFeature.State()
            let original = LedgerOrder.fixture(
                id: "order-1",
                orderSource: "蝦皮",
                categories: ["美妝"],
                paymentMethod: "信用卡"
            )
            state.orders = [original]

            let store = TestStore(initialState: state) {
                OrdersFeature()
            } withDependencies: {
                $0.date = .constant(TestDependencies.fixedNow)
                $0.uuid = .incrementing
            }

            let expectedEditState = OrderEditFeature.State(
                original: original,
                id: UUID(0),
                availableOrderSources: ["蝦皮"],
                availableCategories: ["美妝"],
                availablePaymentMethods: [
                    PaymentMethodInfo(
                        name: "信用卡",
                        isCardless: false,
                        isBankTransfer: false,
                        isCashOnDelivery: false
                    ),
                ],
                currentDate: TestDependencies.fixedNow
            )

            // When
            await store.send(.editOrderTapped("order-1")) {
                $0.editOrder = expectedEditState
            }

            // Then
            #expect(store.state.editOrder?.original?.id == "order-1")
            #expect(store.state.editOrder?.draft.customerName == "測試客戶")
            #expect(store.state.editOrder?.draft.categories == ["美妝"])
        }
    }

    /// 點選新增訂單時開啟空白編輯表單
    @Test
    func newOrderTapped_點選新增訂單_呈現空白編輯狀態() async {
        // Given
        let store = TestStore(initialState: OrdersFeature.State()) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.uuid = .incrementing
        }

        let expectedEditState = OrderEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )

        // When
        await store.send(.newOrderTapped) {
            $0.editOrder = expectedEditState
        }

        // Then
        #expect(store.state.editOrder?.original == nil)
        #expect(store.state.editOrder?.draft.customerName.isEmpty == true)
        #expect(store.state.editOrder?.draft.categories.isEmpty == true)
    }

    /// 編輯既有訂單並儲存後，清單原本選取的其他訂單維持不變
    @Test
    func editOrder_編輯既有訂單_保留目前選取() async {
        // Given
        let original = LedgerOrder.fixture(id: "order-1")
        let otherOrder = LedgerOrder.fixture(id: "order-2")

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.customerName = "改過的客戶"

        var state = OrdersFeature.State()
        state.orders = [original, otherOrder]
        state.editOrder = draft
        state.selectedOrderID = "order-2"

        let savedOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                savedOrders.withValue {
                    $0.append(order)
                }
            }
        }
        let expectedOrder = LedgerOrder.fixture(
            id: "order-1",
            customer: LedgerCustomer(name: "改過的客戶", initials: "TC", tier: .regular)
        )

        // When
        await store.send(.editOrder(.presented(.saveTapped)))

        // Then
        await store.receive(\.orderSavePersisted) { $0.orders = [expectedOrder, otherOrder] }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        #expect(store.state.selectedOrderID == "order-2")
        #expect(savedOrders.value == [expectedOrder])
    }

    /// 修改訂單狀態、幣別與實收金額後儲存，三個欄位都寫回清單
    @Test
    func editOrder_更新狀態幣別與金額_儲存後反映訂單() async {
        // Given
        let original = LedgerOrder.fixture(id: "order-1")

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.status = .delivered
        draft.draft.currency = .jpy
        draft.draft.chargedAmount = 9_876

        var state = OrdersFeature.State()
        state.orders = [original]
        state.editOrder = draft

        let savedOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                savedOrders.withValue {
                    $0.append(order)
                }
            }
        }
        let expectedOrder = LedgerOrder.fixture(
            id: "order-1",
            status: .delivered,
            currency: .jpy,
            chargedAmount: 9_876
        )

        // When
        await store.send(.editOrder(.presented(.saveTapped)))

        // Then
        await store.receive(\.orderSavePersisted) { $0.orders = [expectedOrder] }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        #expect(savedOrders.value == [expectedOrder])
    }

    /// 修改成本與手續費欄位後儲存，各欄位照輸入值寫回清單
    @Test
    func editOrder_更新成本明細欄位_儲存後反映訂單() async {
        // Given
        let original = LedgerOrder.fixture(id: "order-1")

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.itemCost = 5_000
        draft.draft.domesticShipping = 100
        draft.draft.internationalShipping = 250
        draft.draft.cardFeeRate = 0.025
        draft.draft.platformFeeRate = 0.04

        var state = OrdersFeature.State()
        state.orders = [original]
        state.editOrder = draft

        let savedOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                savedOrders.withValue {
                    $0.append(order)
                }
            }
        }
        let expectedOrder = LedgerOrder.fixture(
            id: "order-1",
            itemCost: 5_000,
            domesticShipping: 100,
            internationalShipping: 250,
            cardFeeRate: 0.025,
            platformFeeRate: 0.04
        )

        // When
        await store.send(.editOrder(.presented(.saveTapped)))

        // Then
        await store.receive(\.orderSavePersisted) { $0.orders = [expectedOrder] }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        #expect(savedOrders.value == [expectedOrder])
    }

    /// 手續費率輸入小於 0 或大於 1 時，儲存前分別調成 0 與 1
    @Test
    func editOrder_費率超出零至一範圍_夾限後儲存() async {
        // Given
        let original = LedgerOrder.fixture(id: "order-1", cardFeeRate: 0.02, platformFeeRate: 0.03)

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.cardFeeRate = -0.5
        draft.draft.platformFeeRate = 5

        var state = OrdersFeature.State()
        state.orders = [original]
        state.editOrder = draft

        let savedOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                savedOrders.withValue {
                    $0.append(order)
                }
            }
        }
        let expectedOrder = LedgerOrder.fixture(id: "order-1", platformFeeRate: 1)

        // When
        await store.send(.editOrder(.presented(.saveTapped)))

        // Then
        await store.receive(\.orderSavePersisted) { $0.orders = [expectedOrder] }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        #expect(savedOrders.value == [expectedOrder])
    }

    /// 實收金額輸入負數時，儲存前調成 0
    @Test
    func editOrder_實收金額輸入負值_夾限為零後儲存() async {
        // Given
        let original = LedgerOrder.fixture(id: "order-1", chargedAmount: 1_000)

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.chargedAmount = -500

        var state = OrdersFeature.State()
        state.orders = [original]
        state.editOrder = draft

        let savedOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                savedOrders.withValue {
                    $0.append(order)
                }
            }
        }
        let expectedOrder = LedgerOrder.fixture(id: "order-1")

        // When
        await store.send(.editOrder(.presented(.saveTapped)))

        // Then
        await store.receive(\.orderSavePersisted) { $0.orders = [expectedOrder] }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        #expect(savedOrders.value == [expectedOrder])
    }

    /// 新增訂單儲存成功後，新訂單排到清單最前面並被選取
    ///
    /// - Note: 新訂單一律走建立操作，撞號時不會覆寫既有資料
    @Test
    func editOrder_新增訂單儲存成功_加入並選取新訂單() async {
        // Given
        var draft = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.customerName = "新客戶"
        draft.draft.categories = ["美妝"]

        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft

        let createdOrders = LockIsolated<[LedgerOrder]>([])

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.orderService.createOrder = { order in
                createdOrders.withValue {
                    $0.append(order)
                }
            }
        }
        let expectedOrder = LedgerOrder.fixture(
            id: "BL-DRAFT-00000000-0000-0000-0000-000000000000",
            customer: LedgerCustomer(name: "新客戶", initials: "新客", tier: .new),
            status: .quoting,
            date: TestDependencies.fixedNow,
            orderSource: "未指定",
            categories: ["美妝"],
            paymentMethod: ""
        )

        // When
        await store.send(.editOrder(.presented(.saveTapped)))

        // Then
        await store.receive(\.orderSavePersisted) {
            $0.orders = [expectedOrder] + LedgerOrder.sampleOrders
            $0.selectedOrderID = "BL-DRAFT-00000000-0000-0000-0000-000000000000"
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        #expect(createdOrders.value == [expectedOrder])
    }

    /// 新增訂單寫入失敗時，清單不加入新訂單並顯示寫入失敗提示
    @Test
    func editOrder_新增操作失敗_不加入訂單() async {
        // Given
        var draft = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.customerName = "新客戶"
        draft.draft.categories = ["美妝"]

        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft

        let expectedID = "BL-DRAFT-00000000-0000-0000-0000-000000000000"
        let failingCreate: OrderService.CreateOrder = { _ in
            throw .identifierCollision(id: expectedID)
        }

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.orderService.createOrder = failingCreate
        }

        // When
        await store.send(.editOrder(.presented(.saveTapped)))

        // Then
        await store.receive(\.orderWriteFailed) {
            $0.writeFailureAlert = expectedWriteFailureAlert("訂單儲存失敗，請稍後再試。")
        }
        // saveTapped 一律關閉表單，與寫入結果無關
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        #expect(store.state.orders == LedgerOrder.sampleOrders)
    }

    /// 照片尚未載入完成時儲存，即使標記過修改也只更新文字欄位
    ///
    /// - Parameter phase: 照片目前的載入狀態
    /// - Note: 誤用帶照片的寫入由 `testValue` 的 `unimplemented` 擋下
    @Test(arguments: [OrderEditFeature.State.PhotoLoadPhase.loading, .failed, .notLoaded])
    func editOrder_照片尚未載入_保留原照片(phase: OrderEditFeature.State.PhotoLoadPhase) async {
        // Given
        let original = LedgerOrder.fixture(id: "order-1")

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        draft.photoLoadPhase = phase
        draft.hasEditedPhotos = true
        draft.draftPhotos = [Data([0xBB])]
        draft.draft.customerName = "照片尚未載入就儲存"

        var state = OrdersFeature.State()
        state.orders = [original]
        state.editOrder = draft

        let savedOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                savedOrders.withValue {
                    $0.append(order)
                }
            }
        }
        let expectedOrder = LedgerOrder.fixture(
            id: "order-1",
            customer: LedgerCustomer(name: "照片尚未載入就儲存", initials: "TC", tier: .regular)
        )

        // When
        await store.send(.editOrder(.presented(.saveTapped)))

        // Then
        await store.receive(\.orderSavePersisted) { $0.orders = [expectedOrder] }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        #expect(savedOrders.value == [expectedOrder])
    }

    /// 新增訂單時，分類與開團名稱去掉前後空白、空字串與重複後才寫入
    @Test
    func editOrder_儲存分類與開團選取_正規化陣列內容() async {
        // Given
        var draft = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.customerName = "新客戶"
        draft.draft.categories = [" 美妝 ", "美妝", "", "服飾", "   "]
        draft.draft.campaignNames = ["四月韓國團", " 四月韓國團 ", ""]
        var initial = OrdersFeature.State()
        initial.editOrder = draft
        let createdOrders = LockIsolated<[LedgerOrder]>([])
        let expectedOrder = LedgerOrder.fixture(
            id: "BL-DRAFT-00000000-0000-0000-0000-000000000000",
            customer: LedgerCustomer(name: "新客戶", initials: "新客", tier: .new),
            status: .quoting,
            date: TestDependencies.fixedNow,
            orderSource: "未指定",
            categories: ["美妝", "服飾"],
            paymentMethod: "",
            campaignNames: ["四月韓國團"]
        )
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.orderService.createOrder = { order in
                createdOrders.withValue {
                    $0.append(order)
                }
            }
        }

        // When
        await store.send(.editOrder(.presented(.saveTapped)))

        // Then
        await store.receive(\.orderSavePersisted) {
            $0.orders = [expectedOrder]
            $0.selectedOrderID = expectedOrder.id
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        #expect(createdOrders.value == [expectedOrder])
    }

    /// 從可合併的訂單開始合併，列出同客戶、同幣別且尚未合併或取消的候選
    ///
    /// - Throws: 找不到指定的主訂單時由 `#require` 丟出
    @Test
    func mergeOrderTapped_主訂單可合併_列出同客戶同幣別候選() async throws {
        // Given
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        let primaryID = "BL-2604-018"
        let primary = try #require(state.orders.first { $0.id == primaryID })

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .incrementing
        }

        let expectedOrderMerge = withDependencies {
            $0.uuid = .incrementing
        } operation: {
            OrderMergeFeature.State(primary: primary, orders: state.orders)
        }

        // When
        await store.send(.mergeOrderTapped(primaryID)) {
            $0.orderMerge = expectedOrderMerge
        }

        // Then
        // 主訂單為林書宇的 KRW 訂單，候選需同客戶與幣別且未合併或取消
        #expect(store.state.orderMerge?.primary.id == primaryID)
        #expect(store.state.orderMerge?.candidates.map(\.id) == ["BL-2604-012"])
    }

    /// 已合併或已取消的訂單不能當主訂單，點合併不開啟候選清單
    ///
    /// - Parameter status: 主訂單目前的狀態
    @Test(arguments: [OrderStatus.merged, .cancelled])
    func mergeOrderTapped_主訂單已合併或已取消_不開啟候選清單(status: OrderStatus) async {
        // Given
        var initial = OrdersFeature.State()
        initial.orders = [makeOrder(id: "O1", category: "美妝", status: status)]
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.mergeOrderTapped("O1"))

        // Then
        #expect(store.state.orderMerge == nil)
    }

    /// 在合併候選清單選好訂單後，先關閉清單，半秒後開啟帶入兩筆內容的合併草稿
    ///
    /// - Throws: 樣本訂單不存在、品項數不符，或合併草稿沒有開啟時由 `#require` 丟出
    @Test
    func orderMerge_選取候選訂單_延遲開啟預填合併草稿() async throws {
        // Given
        let initialOrders = LedgerOrder.sampleOrders
        let primaryID = "BL-2604-018"
        let secondaryID = "BL-2604-012"
        let primary = try #require(initialOrders.first { $0.id == primaryID })
        let secondary = try #require(initialOrders.first { $0.id == secondaryID })
        try #require(primary.items.count == 2)
        try #require(secondary.items.count == 1)
        let expectedItemIDs = primary.items.map(\.id) + secondary.items.map(\.id)
        let expectedItems = [
            LedgerOrderItem(
                id: expectedItemIDs[0],
                name: "Tamburins 香水 Chamo 50ml",
                quantity: 1,
                unitPrice: 95_000
            ),
            LedgerOrderItem(
                id: expectedItemIDs[1],
                name: "Gentle Monster Her 02",
                quantity: 1,
                unitPrice: 295_000
            ),
            LedgerOrderItem(
                id: expectedItemIDs[2],
                name: "Adererror 標準 Logo Tee 黑",
                quantity: 2,
                unitPrice: 89_000
            ),
        ]
        let clock = TestClock()
        let requestedPhotoOrderIDs = LockIsolated<[LedgerOrder.ID]>([])
        var initial = OrdersFeature.State()
        initial.orders = initialOrders
        initial.orderMerge = withDependencies {
            $0.uuid = .constant(UUID(0))
        } operation: {
            OrderMergeFeature.State(primary: primary, orders: initialOrders)
        }
        var expectedEdit = OrderEditFeature.State(
            id: UUID(0),
            availableOrderSources: initial.availableOrderSources,
            availableCategories: initial.availableCategories,
            availablePaymentMethods: initial.availablePaymentMethods,
            availableReconciliationStatuses: initial.availableReconciliationStatuses,
            availableCampaigns: initial.availableCampaigns,
            currentDate: TestDependencies.fixedNow
        )
        expectedEdit.draft.customerName = "林書宇"
        expectedEdit.draft.orderSource = "蝦皮"
        expectedEdit.draft.categories = ["美妝", "服飾"]
        expectedEdit.draft.status = .shipping
        expectedEdit.draft.currency = .krw
        expectedEdit.draft.chargedAmount = 17_480
        expectedEdit.draft.cardlessDeductionAmount = 0
        expectedEdit.draft.cardlessSupplementAmount = 0
        expectedEdit.draft.itemCost = 12_950.4
        expectedEdit.draft.domesticShipping = 140
        expectedEdit.draft.internationalShipping = 600
        expectedEdit.draft.foreignDomesticShipping = 0
        expectedEdit.draft.cardFeeRate = 0.015
        expectedEdit.draft.platformFeeRate = 0
        expectedEdit.draft.paymentFeeRate = 0
        expectedEdit.draft.items = expectedItems
        expectedEdit.draft.notes = "客戶指定到貨後先拍照確認，再安排出貨。"
        expectedEdit.draft.date = TestDependencies.fixedNow
        expectedEdit.draft.paymentMethod = "信用卡"
        expectedEdit.draft.reconciliationStatus = ""
        expectedEdit.draft.campaignNames = []
        expectedEdit.draft.paymentReceiptStatus = .pending
        expectedEdit.draftPhotos = []
        expectedEdit.mergeSourceIDs = [primaryID, secondaryID]

        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.uuid = .constant(UUID(0))
            $0.continuousClock = clock
            $0.orderService.fetchOrderPhotos = { id in
                requestedPhotoOrderIDs.withValue {
                    $0.append(id)
                }
                return []
            }
        }

        // When
        await store.send(.orderMerge(.presented(.candidateTapped(secondaryID))))

        // Then
        await store.receive(\.orderMerge.presented.candidatePhotosLoaded)
        await store.receive(\.orderMerge.presented.delegate.completed) { $0.orderMerge = nil }
        await clock.advance(by: .milliseconds(500))
        await store.receive(\.mergeConfirmationReady) { $0.editOrder = expectedEdit }
        let edit = try #require(store.state.editOrder)
        #expect(edit.isMergeContext)
        #expect(requestedPhotoOrderIDs.value.sorted() == ["BL-2604-012", "BL-2604-018"])
    }

    /// 儲存合併草稿時新增一筆合併訂單，並把兩筆來源訂單標成已合併
    ///
    /// - Throws: 找不到合併來源訂單時由 `#require` 丟出
    @Test
    func editOrder_儲存合併草稿_新增訂單並標記來源() async throws {
        // Given
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        let primaryID = "BL-2604-018"
        let secondaryID = "BL-2604-012"
        // 合併草稿沿用主訂單客戶的 initials 與 tier
        let expectedMergedOrder = LedgerOrder.fixture(
            id: "BL-DRAFT-00000000-0000-0000-0000-000000000000",
            customer: LedgerCustomer(name: "林書宇", initials: "SY", tier: .vip),
            status: .quoting,
            currency: .twd,
            date: TestDependencies.fixedNow,
            chargedAmount: 17_480,
            orderSource: "未指定",
            categories: ["美妝", "服飾"],
            paymentMethod: "",
            mergedSourceIDs: [primaryID, secondaryID]
        )
        var draft = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.customerName = "林書宇"
        draft.draft.categories = ["美妝", "服飾"]
        draft.draft.chargedAmount = 17_480
        draft.mergeSourceIDs = [primaryID, secondaryID]
        state.editOrder = draft

        let mergedOrders = LockIsolated<[LedgerOrder]>([])
        let consumedIDCalls = LockIsolated<[[LedgerOrder.ID]]>([])
        let primaryIndex = try #require(state.orders.firstIndex { $0.id == primaryID })
        let secondaryIndex = try #require(state.orders.firstIndex { $0.id == secondaryID })
        var expectedOrders = state.orders
        expectedOrders[primaryIndex] = Self.withStatus(state.orders[primaryIndex], status: .merged)
        expectedOrders[secondaryIndex] = Self.withStatus(
            state.orders[secondaryIndex],
            status: .merged
        )
        expectedOrders.insert(expectedMergedOrder, at: 0)
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.orderService.mergeOrders = { newOrder, consumedIDs in
                mergedOrders.withValue {
                    $0.append(newOrder)
                }
                consumedIDCalls.withValue {
                    $0.append(consumedIDs)
                }
            }
        }

        // When
        await store.send(.editOrder(.presented(.saveTapped))) {
            $0.orders = expectedOrders
            $0.selectedOrderID = expectedMergedOrder.id
        }

        // Then
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        await store.finish()
        #expect(mergedOrders.value == [expectedMergedOrder])
        #expect(consumedIDCalls.value == [[primaryID, secondaryID]])
    }

    /// 合併確認會以保留的照片建立新訂單
    ///
    /// - Throws: 找不到合併來源訂單時由 `#require` 丟出
    @Test
    func editOrder_完成合併且保留照片_明確寫入合併照片() async throws {
        // Given
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        let primaryID = "BL-2604-018"
        let secondaryID = "BL-2604-012"
        let keptPhotos = [Data([0x21]), Data([0x22]), Data([0x23])]
        // 合併草稿沿用主訂單客戶的 initials 與 tier
        let expectedMergedOrder = LedgerOrder.fixture(
            id: "BL-DRAFT-00000000-0000-0000-0000-000000000000",
            customer: LedgerCustomer(name: "林書宇", initials: "SY", tier: .vip),
            status: .quoting,
            currency: .twd,
            date: TestDependencies.fixedNow,
            chargedAmount: 17_480,
            orderSource: "未指定",
            categories: ["美妝", "服飾"],
            paymentMethod: "",
            photos: keptPhotos,
            mergedSourceIDs: [primaryID, secondaryID]
        )
        var draft = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.draft.customerName = "林書宇"
        draft.draft.categories = ["美妝", "服飾"]
        draft.draft.chargedAmount = 17_480
        draft.mergeSourceIDs = [primaryID, secondaryID]
        draft.draftPhotos = keptPhotos
        state.editOrder = draft

        let mergedOrders = LockIsolated<[LedgerOrder]>([])
        let primaryIndex = try #require(state.orders.firstIndex { $0.id == primaryID })
        let secondaryIndex = try #require(state.orders.firstIndex { $0.id == secondaryID })
        var expectedOrders = state.orders
        expectedOrders[primaryIndex] = Self.withStatus(state.orders[primaryIndex], status: .merged)
        expectedOrders[secondaryIndex] = Self.withStatus(
            state.orders[secondaryIndex],
            status: .merged
        )
        expectedOrders.insert(expectedMergedOrder, at: 0)
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.uuid = .incrementing
            $0.orderService.mergeOrders = { newOrder, _ in
                mergedOrders.withValue {
                    $0.append(newOrder)
                }
            }
        }

        // When
        await store.send(.editOrder(.presented(.saveTapped))) {
            $0.orders = expectedOrders
            $0.selectedOrderID = expectedMergedOrder.id
        }

        // Then
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        await store.finish()
        #expect(mergedOrders.value == [expectedMergedOrder])
    }

    /// 合併草稿有預填內容，按下取消先詢問是否捨棄，訂單清單不變
    @Test
    func editOrder_合併草稿按下取消_詢問是否捨棄() async {
        // Given
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        var draft = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        draft.mergeSourceIDs = ["BL-2604-018", "BL-2604-012"]
        draft.draft.customerName = "林書宇"
        state.editOrder = draft
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }

        // When
        await store.send(.editOrder(.presented(.cancelTapped))) {
            $0.editOrder?.discardConfirmation = AlertState {
                TextState("捨棄變更")
            } actions: {
                ButtonState(role: .destructive, action: .discard) {
                    TextState("捨棄變更")
                }
                ButtonState(role: .cancel) {
                    TextState("繼續編輯")
                }
            } message: {
                TextState("這張訂單有尚未儲存的變更，離開後將不會保留。")
            }
        }

        // Then
        #expect(store.state.editOrder?.discardConfirmation != nil)
        #expect(store.state.orders == LedgerOrder.sampleOrders)
    }

    /// 清除分類篩選後，清單回到全部訂單並改選第一筆
    @Test
    func categoryFilterSelected_清除分類篩選_顯示全部訂單() async {
        // Given
        var initial = OrdersFeature.State()
        initial.orders = LedgerOrder.sampleOrders
        initial.selectedCategory = "服飾"
        initial.selectedOrderID = "BL-2604-017"
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.categoryFilterSelected(nil)) {
            $0.selectedCategory = nil
            $0.selectedOrderID = "BL-2604-018"
        }

        // Then
        let filtered = store.state.filteredOrders(
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        #expect(filtered.map(\.id) == LedgerOrder.sampleOrders.map(\.id))
    }

    /// 已套用狀態篩選時再選分類，只留下兩個條件都符合的訂單
    @Test
    func categoryFilterSelected_分類與狀態篩選並用_只顯示同時相符訂單() async {
        // Given
        var initial = OrdersFeature.State()
        initial.orders = [
            makeOrder(id: "O1", category: "beauty", status: .shipping),
            makeOrder(id: "O2", category: "beauty", status: .quoting),
            makeOrder(id: "O3", category: "snacks", status: .shipping),
        ]
        initial.selectedStatus = .shipping
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.categoryFilterSelected("beauty")) {
            $0.selectedCategory = "beauty"
            $0.selectedOrderID = "O1"
        }

        // Then
        let filtered = store.state.filteredOrders(
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        #expect(filtered.map(\.id) == ["O1"])
    }

    /// 清除付款方式篩選後，清單回到全部訂單並改選第一筆
    @Test
    func paymentMethodFilterSelected_清除付款方式篩選_顯示全部訂單() async {
        // Given
        var initial = OrdersFeature.State()
        initial.orders = LedgerOrder.sampleOrders
        initial.selectedPaymentMethod = "銀行轉帳"
        initial.selectedOrderID = "BL-2604-017"
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.paymentMethodFilterSelected(nil)) {
            $0.selectedPaymentMethod = nil
            $0.selectedOrderID = "BL-2604-018"
        }

        // Then
        let filtered = store.state.filteredOrders(
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        #expect(filtered.map(\.id) == LedgerOrder.sampleOrders.map(\.id))
    }

    /// 已套用分類篩選時再選付款方式，只留下兩個條件都符合的訂單
    @Test
    func paymentMethodFilterSelected_分類與付款方式篩選並用_只顯示同時相符訂單() async {
        // Given
        var initial = OrdersFeature.State()
        initial.orders = [
            makeOrder(id: "P1", category: "beauty", paymentMethod: "信用卡"),
            makeOrder(id: "P2", category: "beauty", paymentMethod: "現金"),
            makeOrder(id: "P3", category: "snacks", paymentMethod: "信用卡"),
        ]
        initial.selectedCategory = "beauty"
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.paymentMethodFilterSelected("信用卡")) {
            $0.selectedPaymentMethod = "信用卡"
            $0.selectedOrderID = "P1"
        }

        // Then
        let filtered = store.state.filteredOrders(
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        #expect(filtered.map(\.id) == ["P1"])
    }

    /// 啟用 AI 摘要後點按摘要，摘要畫面帶入商品明細與指定模型
    @Test
    func aiSummaryTapped_摘要功能已啟用_呈現摘要畫面() async {
        // Given
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.settingsService.load = {
                var snapshot = SettingsSnapshot.default
                snapshot.isAISummaryEnabled = true
                snapshot.aiSummaryModel = "gpt-oss:120b"
                return snapshot
            }
        }

        // When
        await store.send(.aiSummaryTapped) {
            $0.aiSummary = AISummaryFeature.State(
                prompt: """
                    你是個人代購 App 的分析助理。以下是目前訂單列表的商品明細(涵蓋目前列表所有類別)，每行格式為「- [類別] 商品名稱 x數量 @ 單價 幣別」：

                    - [美妝] Tamburins 香水 Chamo 50ml x1 @ 95000 KRW
                    - [美妝] Gentle Monster Her 02 x1 @ 295000 KRW
                    - [服飾] Snidel 春季針織外套 (M) x1 @ 18700 JPY
                    - [美妝] Aesop Rōzu Eau de Parfum 50ml x1 @ 220000 KRW
                    - [美妝] Hera Black Cushion #21 x2 @ 68000 KRW
                    - [精品] Polène Numéro Un Nano 米色 x1 @ 390 EUR
                    - [美妝] Sulwhasoo 滋陰生 60ml x1 @ 27000 JPY
                    - [美妝] Innisfree 綠茶精華 80ml x1 @ 4500 JPY
                    - [美妝] Le Labo Santal 33 50ml x1 @ 218 USD
                    - [服飾] Adererror 標準 Logo Tee 黑 x2 @ 89000 KRW
                    - [美妝、服飾] Hince 絲絨唇釉 #07 x1 @ 22000 KRW
                    - [美妝、服飾] Matin Kim 寬版牛仔褲 (S) x1 @ 79000 KRW

                    請用正體中文、以 Markdown 格式總結這些商品明細，內容包含：
                    - 一個 `##` 層級的標題
                    - 各品項的品名以及購買的總數量 (如果品名有編號的話，請照編號排序；如果沒有編號的話，請照字母順序排序)

                    請以條列與粗體強調重點，全文控制在約 200–300 字。只根據上面提供的資料作答，不要杜撰未出現的商品、數字或結論。
                    """,
                model: "gpt-oss:120b"
            )
        }

        // Then
        #expect(store.state.aiSummary?.model == "gpt-oss:120b")
        #expect(store.state.aiSummary?.prompt.contains("(涵蓋目前列表所有類別)") == true)
        #expect(store.state.aiDisabledAlert == nil)
    }

    /// 設定未開啟 AI 摘要時，點按摘要改為提醒使用者到設定開啟
    @Test
    func aiSummaryTapped_摘要功能已停用_呈現提醒() async {
        // Given
        let store = TestStore(initialState: OrdersFeature.State()) {
            OrdersFeature()
        } withDependencies: {
            $0.settingsService.load = {
                .default
            }
        }

        // When
        await store.send(.aiSummaryTapped) {
            $0.aiDisabledAlert = AlertState {
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

        // Then
        #expect(store.state.aiDisabledAlert != nil)
        #expect(store.state.aiSummary == nil)
    }

    /// 訂單有多個分類時，只要其中一個符合所選分類就顯示
    @Test
    func categoryFilterSelected_訂單含多個分類_符合任一分類即顯示() async {
        // Given
        var initial = OrdersFeature.State()
        initial.orders = [
            makeOrder(id: "O1", categories: ["beauty"], status: .purchased),
            makeOrder(id: "O2", categories: ["beauty", "snacks"], status: .quoting),
            makeOrder(id: "O3", categories: ["snacks"], status: .purchased),
            makeOrder(id: "O4", categories: ["beauty", "snacks"], status: .purchased),
        ]
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.categoryFilterSelected("beauty")) {
            $0.selectedCategory = "beauty"
            $0.selectedOrderID = "O1"
        }

        // Then
        let filtered = store.state.filteredOrders(
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        #expect(filtered.map(\.id) == ["O1", "O2", "O4"])
    }

    /// 訂單屬於多個開團時，只要其中一個符合所選開團就顯示
    @Test
    func campaignFilterSelected_訂單含多個開團_符合任一開團即顯示() async {
        // Given
        var initial = OrdersFeature.State()
        initial.orders = [
            makeOrder(id: "O1", categories: ["x"], campaignNames: ["May-JP"]),
            makeOrder(id: "O2", categories: ["x"], campaignNames: ["May-JP", "June-KR"]),
            makeOrder(id: "O3", categories: ["x"], campaignNames: ["June-KR"]),
            makeOrder(id: "O4", categories: ["x"], campaignNames: []),
        ]
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.campaignFilterSelected("May-JP")) {
            $0.selectedCampaign = "May-JP"
            $0.selectedOrderID = "O1"
        }

        // Then
        let filtered = store.state.filteredOrders(
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        #expect(filtered.map(\.id) == ["O1", "O2"])
    }

    /// 訂單屬於多個開團時，任一開團狀態符合所選狀態就顯示
    ///
    /// - Parameters:
    ///   - campaignStatus: 要篩選的開團狀態
    ///   - expectedIDs: 篩選後應顯示的訂單
    @Test(arguments: [
        (CampaignStatus.ongoing, ["O1", "O3"]),
        (CampaignStatus.closed, ["O2", "O3"]),
    ])
    func campaignStatusFilterSelected_訂單含多個開團_符合任一開團狀態即顯示(
        campaignStatus: CampaignStatus,
        expectedIDs: [String]
    ) async {
        // Given
        var initial = OrdersFeature.State()
        initial.campaigns = [
            Campaign(
                id: "C-ONGOING",
                name: "May-JP",
                openDate: TestDependencies.fixedNow,
                closeDate: TestDependencies.fixedNow,
                status: .ongoing,
                settledDate: nil,
                notes: ""
            ),
            Campaign(
                id: "C-CLOSED",
                name: "April-KR",
                openDate: TestDependencies.fixedNow,
                closeDate: TestDependencies.fixedNow,
                status: .closed,
                settledDate: nil,
                notes: ""
            ),
        ]
        initial.orders = [
            makeOrder(id: "O1", categories: ["x"], campaignNames: ["May-JP"]),
            makeOrder(id: "O2", categories: ["x"], campaignNames: ["April-KR"]),
            makeOrder(id: "O3", categories: ["x"], campaignNames: ["April-KR", "May-JP"]),
            makeOrder(id: "O4", categories: ["x"], campaignNames: []),
        ]
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.campaignStatusFilterSelected(campaignStatus)) {
            $0.selectedCampaignStatus = campaignStatus
            $0.selectedOrderID = expectedIDs.first
        }

        // Then
        let filtered = store.state.filteredOrders(
            referenceDate: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        #expect(filtered.map(\.id) == expectedIDs)
    }

    /// 多選中離開多選模式時，已勾選的訂單一併清空
    @Test
    func selectionModeToggled_多選中已勾選訂單_離開並清空勾選() async {
        // Given
        var initial = OrdersFeature.State()
        initial.orders = [makeOrder(id: "O1", categories: ["beauty"], status: .shipping)]
        initial.isSelecting = true
        initial.selectedOrderIDs = ["O1"]
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.selectionModeToggled) {
            $0.isSelecting = false
            $0.selectedOrderIDs = []
        }

        // Then
        #expect(store.state.selectedOrderIDs.isEmpty)
        #expect(store.state.isSelecting == false)
    }

    /// 多選模式中點選未勾選的訂單後，將它加入勾選清單
    @Test
    func orderSelectionToggled_未勾選訂單_加入勾選() async {
        // Given
        var initial = OrdersFeature.State()
        initial.orders = [makeOrder(id: "O1", categories: ["beauty"], status: .shipping)]
        initial.isSelecting = true
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.orderSelectionToggled("O1")) {
            $0.selectedOrderIDs = ["O1"]
        }

        // Then
        #expect(store.state.selectedOrderIDs == ["O1"])
    }

    /// 尚未進入多選模式時切換，進入多選模式
    @Test
    func selectionModeToggled_未在多選_進入多選() async {
        // Given
        let store = TestStore(initialState: OrdersFeature.State()) {
            OrdersFeature()
        }

        // When
        await store.send(.selectionModeToggled) {
            $0.isSelecting = true
        }

        // Then
        #expect(store.state.isSelecting)
    }

    /// 多選模式中再次點選已勾選訂單，將它移出勾選清單
    @Test
    func orderSelectionToggled_已勾選訂單_取消勾選() async {
        // Given
        var initial = OrdersFeature.State()
        initial.orders = [makeOrder(id: "O1", category: "beauty")]
        initial.isSelecting = true
        initial.selectedOrderIDs = ["O1"]
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.orderSelectionToggled("O1")) {
            $0.selectedOrderIDs = []
        }

        // Then
        #expect(store.state.selectedOrderIDs.isEmpty)
    }

    /// 按下清除勾選後清空已勾選訂單，仍停在多選模式
    @Test
    func clearSelectionTapped_已勾選多筆_清空勾選並留在多選() async {
        // Given
        var initial = OrdersFeature.State()
        initial.orders = [
            makeOrder(id: "O1", categories: ["beauty"], status: .shipping),
            makeOrder(id: "O2", categories: ["snacks"], status: .quoting),
        ]
        initial.isSelecting = true
        initial.selectedOrderIDs = ["O1", "O2"]
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.clearSelectionTapped) { $0.selectedOrderIDs = [] }

        // Then
        #expect(store.state.selectedOrderIDs.isEmpty)
        #expect(store.state.isSelecting)
    }

    /// 多選中點選全選後，只勾選目前篩選出的訂單
    @Test
    func selectAllTapped_多選中_勾選全部篩選後訂單() async {
        // Given
        var initial = OrdersFeature.State()
        initial.orders = [
            makeOrder(id: "O1", categories: ["beauty"], status: .shipping),
            makeOrder(id: "O2", categories: ["snacks"], status: .quoting),
        ]
        initial.isSelecting = true
        initial.selectedCategory = "beauty"
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.selectAllTapped) { $0.selectedOrderIDs = ["O1"] }

        // Then
        #expect(store.state.selectedOrderIDs == ["O1"])
    }

    /// 批次改狀態只寫入狀態真的有變的訂單，一次寫完並離開多選
    @Test
    func batchStatusChanged_批次更新多筆訂單_跳過相同狀態並離開選取() async {
        // Given
        let orders = [
            makeOrder(id: "O1", categories: ["beauty"], status: .shipping),
            makeOrder(id: "O2", categories: ["beauty"], status: .arrived),
            makeOrder(id: "O3", categories: ["snacks"], status: .shipping),
        ]
        var initial = OrdersFeature.State()
        initial.orders = orders
        initial.isSelecting = true
        initial.selectedOrderIDs = ["O1", "O2", "O3"]
        let savedBatches = LockIsolated<[[LedgerOrder]]>([])
        let expectedOrders = [
            Self.withStatus(orders[0], status: .arrived),
            orders[1],
            Self.withStatus(orders[2], status: .arrived),
        ]
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrders = { savedOrders in
                savedBatches.withValue {
                    $0.append(savedOrders)
                }
            }
        }

        // When
        await store.send(.batchStatusChanged(.arrived)) {
            $0.isSelecting = false
            $0.selectedOrderIDs = []
        }

        // Then
        await store.receive(\.batchStatusChangePersisted) { $0.orders = expectedOrders }
        #expect(savedBatches.value.map { $0.map(\.id) } == [["O1", "O3"]])
    }

    /// 批次目標狀態是已合併時不寫入任何訂單，也不離開多選
    @Test
    func batchStatusChanged_目標狀態為已合併_不寫入並維持選取() async {
        // Given
        let orders = [makeOrder(id: "O1", categories: ["beauty"], status: .shipping)]
        var initial = OrdersFeature.State()
        initial.orders = orders
        initial.isSelecting = true
        initial.selectedOrderIDs = ["O1"]
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        }

        // When
        await store.send(.batchStatusChanged(.merged))

        // Then
        #expect(store.state.orders == orders)
        #expect(store.state.isSelecting)
        #expect(store.state.selectedOrderIDs == ["O1"])
    }

    /// 已合併的來源訂單可以改回一般狀態，寫入成功後才更新畫面
    @Test
    func statusChanged_合併來源訂單改回一般狀態_成功儲存() async {
        // Given
        let source = makeOrder(id: "source", categories: ["beauty"], status: .merged)
        var state = OrdersFeature.State()
        state.orders = [source]
        let savedOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                savedOrders.withValue {
                    $0.append(order)
                }
            }
        }

        // When
        await store.send(.statusChanged("source", .confirmed))

        // Then
        await store.receive(\.statusChangePersisted) {
            $0.orders[0] = Self.withStatus(source, status: .confirmed)
        }
        #expect(savedOrders.value == [Self.withStatus(source, status: .confirmed)])
        await store.finish()
    }

    /// 狀態寫入失敗並關閉提示後，下一次寫入成功就不再留下錯誤狀態
    @Test
    func statusChanged_狀態寫入失敗後再次成功_不殘留錯誤狀態() async {
        // Given
        let original = makeOrder(id: "O1", categories: ["beauty"], status: .shipping)
        var initial = OrdersFeature.State()
        initial.orders = [original]
        let shouldFail = LockIsolated(true)
        let saveOrder: OrderService.SaveOrder = { _ in
            if shouldFail.value {
                throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "boom"))
            }
        }
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = saveOrder
        }

        await store.send(.statusChanged("O1", .arrived))
        await store.receive(\.orderWriteFailed) {
            $0.writeFailureAlert = expectedWriteFailureAlert("訂單狀態更新失敗，請稍後再試。")
        }
        await store.send(.writeFailureAlert(.dismiss)) { $0.writeFailureAlert = nil }
        shouldFail.setValue(false)

        // When
        await store.send(.statusChanged("O1", .arrived))

        // Then
        await store.receive(\.statusChangePersisted) {
            $0.orders[0] = Self.withStatus(original, status: .arrived)
        }
        #expect(store.state.errorMessage == nil)
        #expect(store.state.writeFailureAlert == nil)
        await store.finish()
    }

    /// 訂單狀態寫入失敗後重新讀取資料庫，讀回的仍是原訂單
    ///
    /// - Throws: 建立磁碟 fixture 失敗時丟出底層檔案或 SwiftData 錯誤
    @Test
    func task_訂單狀態寫入失敗後_讀回原訂單() async throws {
        // Given
        let original = makeOrder(id: "O1", categories: ["beauty"], status: .shipping)
        let (service, directoryURL) = try OrderServiceTests.makeSaveFailingService(
            orders: [original]
        )
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: directoryURL)
        }
        let reloadedOrders = LockIsolated<[LedgerOrder]>([])
        let persistedOriginal = LedgerOrder.normalizingItemIdentifiers(original)
        let writeFailureAlert = expectedWriteFailureAlert("訂單狀態更新失敗，請稍後再試。")
        let fetchOrders: OrderService.FetchOrders = {
            let orders = try await service.fetchOrders()
            reloadedOrders.setValue(orders)
            return orders
        }
        var initial = OrdersFeature.State()
        initial.orders = [original]
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.fetchOrders = fetchOrders
            $0.orderService.saveOrder = service.saveOrder
            Self.suppressOrderLookupEffects(&$0)
        }

        await store.send(.statusChanged("O1", .arrived))
        await store.receive(\.orderWriteFailed) {
            $0.writeFailureAlert = writeFailureAlert
        }

        // When
        await store.send(.task) {
            $0.isLoading = true
        }

        // Then
        await store.receive(\.ordersLoaded) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.orders = reloadedOrders.value
            $0.selectedOrderID = "O1"
        }
        #expect(
            store.state.orders.map(LedgerOrder.normalizingItemIdentifiers) == [persistedOriginal],
            "寫入失敗後重新讀取資料庫，讀回的仍是原訂單"
        )
        await store.finish()
    }

    /// 收款狀態寫入失敗後重新讀取資料庫，讀回的仍是原訂單
    ///
    /// - Throws: 建立磁碟 fixture 失敗時丟出底層檔案或 SwiftData 錯誤
    @Test
    func task_收款狀態寫入失敗後_讀回原訂單() async throws {
        // Given
        let original = makeOrder(id: "O1", categories: ["beauty"])
        let (service, directoryURL) = try OrderServiceTests.makeSaveFailingService(
            orders: [original]
        )
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: directoryURL)
        }
        let reloadedOrders = LockIsolated<[LedgerOrder]>([])
        let persistedOriginal = LedgerOrder.normalizingItemIdentifiers(original)
        let writeFailureAlert = expectedWriteFailureAlert("收款狀態更新失敗，請稍後再試。")
        let fetchOrders: OrderService.FetchOrders = {
            let orders = try await service.fetchOrders()
            reloadedOrders.setValue(orders)
            return orders
        }
        var initial = OrdersFeature.State()
        initial.orders = [original]
        let store = TestStore(initialState: initial) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.fetchOrders = fetchOrders
            $0.orderService.saveOrder = service.saveOrder
            Self.suppressOrderLookupEffects(&$0)
        }

        await store.send(.receiptStatusChanged("O1", .received))
        await store.receive(\.orderWriteFailed) {
            $0.writeFailureAlert = writeFailureAlert
        }

        // When
        await store.send(.task) {
            $0.isLoading = true
        }

        // Then
        await store.receive(\.ordersLoaded) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.orders = reloadedOrders.value
            $0.selectedOrderID = "O1"
        }
        #expect(
            store.state.orders.map(LedgerOrder.normalizingItemIdentifiers) == [persistedOriginal],
            "寫入失敗後重新讀取資料庫，讀回的仍是原訂單"
        )
        await store.finish()
    }

    /// 批次狀態寫入失敗後重新讀取資料庫，讀回的仍是原本的四筆訂單
    ///
    /// - Throws: 建立磁碟 fixture 失敗時丟出底層檔案或 SwiftData 錯誤；重新載入後沒有選取訂單時由 `#require` 丟出
    @Test
    func task_批次狀態寫入失敗後_讀回原訂單() async throws {
        // Given
        let orders = [
            makeOrder(id: "O1", categories: ["beauty"], status: .shipping),
            makeOrder(id: "O2", categories: ["beauty"], status: .shipping),
            makeOrder(id: "O3", categories: ["beauty"], status: .shipping),
            makeOrder(id: "O4", categories: ["beauty"], status: .shipping),
        ]
        let (service, directoryURL) = try OrderServiceTests.makeSaveFailingService(orders: orders)
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: directoryURL)
        }
        let reloadedOrders = LockIsolated<[LedgerOrder]>([])
        let fetchOrders: OrderService.FetchOrders = {
            let fetchedOrders = try await service.fetchOrders()
            reloadedOrders.setValue(fetchedOrders)
            return fetchedOrders
        }
        let persistedOrders = orders.map(LedgerOrder.normalizingItemIdentifiers)
        let writeFailureAlert = expectedWriteFailureAlert("批次更新狀態失敗，請稍後再試。")
        var state = OrdersFeature.State()
        state.orders = orders
        state.isSelecting = true
        state.selectedOrderIDs = Set(orders.map(\.id))

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.fetchOrders = fetchOrders
            $0.orderService.saveOrders = service.saveOrders
            Self.suppressOrderLookupEffects(&$0)
        }

        await store.send(.batchStatusChanged(.arrived)) {
            $0.isSelecting = false
            $0.selectedOrderIDs = []
        }
        await store.receive(\.orderWriteFailed) {
            $0.writeFailureAlert = writeFailureAlert
        }

        // When
        await store.send(.task) {
            $0.isLoading = true
        }

        // Then
        await store.receive(\.ordersLoaded) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.orders = reloadedOrders.value
            $0.selectedOrderID = reloadedOrders.value.first?.id
        }
        let reloadedByID = store.state.orders
            .map(LedgerOrder.normalizingItemIdentifiers)
            .sorted { left, right in
                left.id < right.id
            }
        #expect(reloadedByID == persistedOrders, "寫入失敗後重新讀取資料庫，讀回的仍是原訂單")
        let selectedOrderID = try #require(store.state.selectedOrderID)
        #expect(Set(orders.map(\.id)).contains(selectedOrderID))
        await store.finish()
    }

    /// 刪除寫入失敗後重新讀取資料庫，讀回的仍是原訂單
    ///
    /// - Throws: 建立磁碟 fixture 失敗時丟出底層檔案或 SwiftData 錯誤
    @Test
    func task_刪除寫入失敗後_讀回原訂單() async throws {
        // Given
        let original = makeOrder(id: "O1", categories: ["beauty"])
        let (service, directoryURL) = try OrderServiceTests.makeSaveFailingService(
            orders: [original]
        )
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: directoryURL)
        }
        let reloadedOrders = LockIsolated<[LedgerOrder]>([])
        let fetchOrders: OrderService.FetchOrders = {
            let fetchedOrders = try await service.fetchOrders()
            reloadedOrders.setValue(fetchedOrders)
            return fetchedOrders
        }
        let persistedOriginal = LedgerOrder.normalizingItemIdentifiers(original)
        var state = OrdersFeature.State()
        state.orders = [original]
        state.deletionConfirmation = expectedDeletionConfirmation(
            orderID: original.id,
            customerName: original.customer.name
        )
        let writeFailureAlert = expectedWriteFailureAlert("訂單刪除失敗，請稍後再試。")

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.fetchOrders = fetchOrders
            $0.orderService.removeOrder = service.removeOrder
            Self.suppressOrderLookupEffects(&$0)
        }

        // 選擇 alert 按鈕後 TCA 會自動清空該次呈現
        await store.send(.deletionConfirmation(.presented(.confirmDelete("O1")))) {
            $0.deletionConfirmation = nil
        }
        await store.receive(\.orderWriteFailed) {
            $0.writeFailureAlert = writeFailureAlert
        }

        // When
        await store.send(.task) {
            $0.isLoading = true
        }

        // Then
        await store.receive(\.ordersLoaded) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.orders = reloadedOrders.value
            $0.selectedOrderID = original.id
        }
        #expect(
            store.state.orders.map(LedgerOrder.normalizingItemIdentifiers) == [persistedOriginal],
            "寫入失敗後重新讀取資料庫，讀回的仍是原訂單"
        )
        await store.finish()
    }

    /// 編輯儲存失敗後重新讀取資料庫，讀回的仍是原訂單
    ///
    /// - Throws: 建立磁碟 fixture 失敗時丟出底層檔案或 SwiftData 錯誤；範例資料找不到該訂單時由 `#require` 丟出
    @Test
    func task_編輯儲存失敗後_讀回原訂單() async throws {
        // Given
        let originalID = "BL-2604-018"
        let original = try #require(LedgerOrder.sampleOrders.first { $0.id == originalID })
        let (service, directoryURL) = try OrderServiceTests.makeSaveFailingService(
            orders: LedgerOrder.sampleOrders
        )
        defer {
            BuyLedgerDatabaseTests.removeTemporaryDirectory(at: directoryURL)
        }
        let reloadedOrders = LockIsolated<[LedgerOrder]>([])
        let fetchOrders: OrderService.FetchOrders = {
            let fetchedOrders = try await service.fetchOrders()
            reloadedOrders.setValue(fetchedOrders)
            return fetchedOrders
        }
        let persistedOrders = LedgerOrder.sampleOrders.map(LedgerOrder.normalizingItemIdentifiers)
        let writeFailureAlert = expectedWriteFailureAlert("訂單儲存失敗，請稍後再試。")

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.customerName = "改名嘗試"

        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.editOrder = draft

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.fetchOrders = fetchOrders
            $0.orderService.saveOrder = service.saveOrder
            Self.suppressOrderLookupEffects(&$0)
        }

        await store.send(.editOrder(.presented(.saveTapped)))
        await store.receive(\.orderWriteFailed) {
            $0.writeFailureAlert = writeFailureAlert
        }
        // saveTapped 無論寫入結果都會關閉編輯表單，因此 Given 要承接 dismiss
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }

        // When
        await store.send(.task) {
            $0.isLoading = true
        }

        // Then
        await store.receive(\.ordersLoaded) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.orders = reloadedOrders.value
            $0.selectedOrderID = originalID
        }
        #expect(
            store.state.orders.map(LedgerOrder.normalizingItemIdentifiers) == persistedOrders,
            "寫入失敗後重新讀取資料庫，讀回的仍是原訂單"
        )
        await store.finish()
    }

    /// 無卡存款的折抵大於實收金額時，儲存的折抵改為實收金額
    @Test
    func editOrder_無卡折抵超過實收金額_夾限後儲存() async {
        // Given
        // 折抵上限為實付金額，避免 revenue 變成負數
        let original = makeOrder(
            id: "O-CAP-1",
            categories: ["測試"],
            status: .shipping,
            paymentMethod: "信用卡"
        )

        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            availablePaymentMethods: [
                PaymentMethodInfo(
                    name: "無卡存款",
                    isCardless: true,
                    isBankTransfer: false,
                    isCashOnDelivery: false
                ),
            ],
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.paymentMethod = "無卡存款"
        draft.draft.chargedAmount = 1_000
        draft.draft.cardlessDeductionAmount = 50_000  // 遠大於實付金額
        let expectedOrder = Self.withCardlessAmounts(
            original,
            chargedAmount: 1_000,
            cardlessDeductionAmount: 1_000,  // 收斂為實收金額，不是輸入的 50_000
            paymentMethod: "無卡存款"
        )

        var state = OrdersFeature.State()
        state.orders = [original]
        state.editOrder = draft

        let savedOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                savedOrders.withValue {
                    $0.append(order)
                }
            }
        }

        // When
        await store.send(.editOrder(.presented(.saveTapped)))

        // Then
        await store.receive(\.orderSavePersisted) {
            $0.orders[0] = expectedOrder
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        #expect(savedOrders.value == [expectedOrder])
        await store.finish()
    }

    /// 既有訂單的折抵已超過實收金額時，再次儲存會寫入收斂後的折抵
    @Test
    func editOrder_既有訂單折抵超過上限_下次儲存時修正() async {
        // Given
        let legacyOverCap = Self.withCardlessAmounts(
            makeOrder(
                id: "O-CAP-2",
                categories: ["測試"],
                status: .shipping,
                paymentMethod: "無卡存款"
            ),
            chargedAmount: 1_000,
            cardlessDeductionAmount: 1_500,
            paymentMethod: "無卡存款"
        )

        let draft = OrderEditFeature.State(
            original: legacyOverCap,
            id: UUID(0),
            availablePaymentMethods: [
                PaymentMethodInfo(
                    name: "無卡存款",
                    isCardless: true,
                    isBankTransfer: false,
                    isCashOnDelivery: false
                ),
            ],
            currentDate: TestDependencies.fixedNow
        )
        let expectedOrder = Self.withCardlessAmounts(
            legacyOverCap,
            chargedAmount: 1_000,
            cardlessDeductionAmount: 1_000,
            paymentMethod: "無卡存款"
        )

        var state = OrdersFeature.State()
        state.orders = [legacyOverCap]
        state.editOrder = draft

        let savedOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                savedOrders.withValue {
                    $0.append(order)
                }
            }
        }

        // When
        await store.send(.editOrder(.presented(.saveTapped)))

        // Then
        await store.receive(\.orderSavePersisted) {
            $0.orders[0] = expectedOrder
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        #expect(savedOrders.value == [expectedOrder])
        await store.finish()
    }

    /// 在編輯表單改付款方式後儲存，結果與回溯更正付款方式得到的訂單相同
    ///
    /// - Throws: 沒有寫入任何訂單時由 `#require` 丟出
    @Test
    func editOrder_手動編輯與回溯更正付款方式_訂單欄位一致() async throws {
        // Given
        let original = LedgerOrder(
            id: "O-PARITY",
            customer: LedgerCustomer(name: "對照測試", initials: "PT", tier: .regular),
            status: .delivered,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [LedgerOrderItem(name: "測試商品", quantity: 1, unitPrice: 5_000)],
            itemCost: 3_000,
            domesticShipping: 125,
            internationalShipping: 275,
            foreignDomesticShipping: 425,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 5_000,
            cardlessDeductionAmount: 750,
            cardlessSupplementAmount: 250,
            orderSource: "來源",
            categories: ["測試"],
            paymentMethod: "舊付款",
            notes: "備註",
            reconciliationStatus: " 待對帳 ",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
        let newPaymentMethod = PaymentMethodInfo(
            name: "新付款",
            isCardless: false,
            isBankTransfer: true,
            isCashOnDelivery: true
        )
        var draft = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            availablePaymentMethods: [newPaymentMethod],
            currentDate: TestDependencies.fixedNow
        )
        draft.draft.paymentMethod = newPaymentMethod.name
        draft.draft.reconciliationStatus = original.reconciliationStatus

        let retroactive = original
            .renamingPaymentMethod(to: newPaymentMethod.name)
            .applyingPaymentMethodFlags(newPaymentMethod.currentFlags)
        var state = OrdersFeature.State()
        state.orders = [original]
        state.editOrder = draft
        let savedOrders = LockIsolated<[LedgerOrder]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.saveOrder = { order in
                savedOrders.withValue {
                    $0.append(order)
                }
            }
        }

        // When
        await store.send(.editOrder(.presented(.saveTapped)))

        // Then
        await store.receive(\.orderSavePersisted) {
            $0.orders = [retroactive]
        }
        await store.receive(\.editOrder.dismiss) {
            $0.editOrder = nil
        }
        let manual = try #require(savedOrders.value.first)
        #expect(manual == retroactive)
        #expect(manual.paymentMethod == "新付款")
        #expect(manual.cardlessDeductionAmount == 0)
        #expect(manual.cardlessSupplementAmount == 0)
        #expect(manual.reconciliationStatus == "待對帳")
        #expect(manual.isCashOnDelivery)
        #expect(savedOrders.value.count == 1)
    }

    /// 推入訂單明細後，堆疊多一個指向該訂單的明細頁
    @Test
    func detailPath_推入訂單明細路徑_增加堆疊元素() async {
        // Given
        let orderID = "BL-2604-018"
        let state = OrdersFeature.State()

        let store = TestStore(initialState: state) {
            OrdersFeature()
        }

        // When
        await store.send(
            .detailPath(.push(id: 0, state: OrderDetailPath.State(orderID: orderID)))
        ) {
            $0.detailPath = StackState([OrderDetailPath.State(orderID: orderID)])
        }

        // Then
        #expect(store.state.detailPath.count == 1)
        #expect(store.state.detailPath[id: 0]?.orderID == orderID)
    }

    /// 點選刪除既有訂單時，先呈現含客戶名稱的刪除確認
    @Test
    func deleteOrderTapped_點選既有訂單_呈現刪除確認() async {
        // Given
        var state = OrdersFeature.State()
        state.orders = [makeOrder(id: "O1", category: "beauty")]
        let expectedConfirmation = expectedDeletionConfirmation(orderID: "O1", customerName: "客戶")
        let store = TestStore(initialState: state) {
            OrdersFeature()
        }

        // When
        await store.send(.deleteOrderTapped("O1")) {
            $0.deletionConfirmation = expectedConfirmation
        }

        // Then
        #expect(store.state.deletionConfirmation == expectedConfirmation)
    }

    /// 確認刪除訂單後，對應的明細路徑一併移除
    ///
    /// - Throws: 範例資料找不到該訂單時由 `#require` 丟出
    @Test
    func deletionConfirmation_確認刪除訂單_移除詳情路徑() async throws {
        // Given
        let originalID = "BL-2604-018"
        let original = try #require(LedgerOrder.sampleOrders.first { $0.id == originalID })
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.detailPath = StackState([OrderDetailPath.State(orderID: originalID)])
        state.deletionConfirmation = expectedDeletionConfirmation(
            orderID: originalID,
            customerName: original.customer.name
        )

        let removedIDs = LockIsolated<[LedgerOrder.ID]>([])
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.orderService.removeOrder = { id in
                removedIDs.withValue {
                    $0.append(id)
                }
            }
        }

        // When
        await store.send(.deletionConfirmation(.presented(.confirmDelete(originalID)))) {
            $0.deletionConfirmation = nil
        }

        // Then
        await store.receive(\.orderDeleted) {
            $0.orders.removeAll {
                $0.id == originalID
            }
            $0.detailPath = StackState()
        }
        #expect(store.state.detailPath.isEmpty)
        #expect(removedIDs.value == [originalID])
    }

    /// 確認 `body` 接入 `BindingReducer()`，讓篩選面板 binding action 更新狀態
    @Test
    func binding_切換篩選面板顯示值_更新面板狀態() async {
        // Given
        let store = TestStore(initialState: OrdersFeature.State()) {
            OrdersFeature()
        }

        // When
        await store.send(\.binding.showsFilterSheet, true) {
            $0.showsFilterSheet = true
        }

        // Then
        #expect(store.state.showsFilterSheet)
    }

    /// 確認 `body` 接入 `BindingReducer()`，讓選擇器 binding action 更新狀態
    ///
    /// - Parameter picker: 要切換的選擇器
    @Test(arguments: FilterPicker.allCases)
    func binding_切換選擇器_更新呈現狀態(picker: FilterPicker) async {
        // Given
        let store = TestStore(initialState: OrdersFeature.State()) {
            OrdersFeature()
        }

        // When
        await store.send(.binding(.set(picker.keyPath, true))) {
            $0[keyPath: picker.keyPath] = true
        }

        // Then
        #expect(store.state[keyPath: picker.keyPath])
    }

    /// 開啟篩選面板時，待確認篩選換成已套用的篩選，搜尋文字清空
    @Test
    func filterSheetTapped_開啟篩選面板_複製已提交篩選值() async {
        // Given
        var state = OrdersFeature.State()
        state.selectedDatePeriod = .thisMonth
        state.selectedCategory = "beauty"
        state.selectedPaymentMethod = nil
        // 先放入過期的待確認值與搜尋文字，確認開啟時會被覆寫
        state.pendingFilterSelection = OrdersFeature.State.PendingFilterSelection(
            datePeriod: .all,
            category: "stale",
            paymentMethod: "stale"
        )
        state.filterSheetSearchText = "leftover"
        let expectedSelection = OrdersFeature.State.PendingFilterSelection(
            datePeriod: .thisMonth,
            category: "beauty",
            paymentMethod: nil
        )

        let store = TestStore(initialState: state) {
            OrdersFeature()
        }

        // When
        await store.send(.filterSheetTapped) {
            $0.pendingFilterSelection = expectedSelection
            $0.filterSheetSearchText = ""
            $0.showsFilterSheet = true
        }

        // Then
        #expect(store.state.pendingFilterSelection == expectedSelection)
        #expect(store.state.filterSheetSearchText == "")
        #expect(store.state.showsFilterSheet)
    }

    /// 調整待確認日期篩選只改暫存值，已套用的篩選不變
    @Test
    func filterPendingDatePeriodSelected_調整待確認篩選_不改已提交值() async {
        // Given
        var state = OrdersFeature.State()
        state.selectedDatePeriod = .all
        state.selectedCategory = nil
        state.selectedPaymentMethod = nil
        state.showsFilterSheet = true
        state.pendingFilterSelection = OrdersFeature.State.PendingFilterSelection(
            datePeriod: .all,
            category: nil,
            paymentMethod: nil
        )

        let store = TestStore(initialState: state) {
            OrdersFeature()
        }

        // When
        await store.send(.filterPendingDatePeriodSelected(.thisMonth)) {
            $0.pendingFilterSelection.datePeriod = .thisMonth
        }

        // Then
        #expect(store.state.hasUnappliedFilterChanges)
        #expect(store.state.selectedDatePeriod == .all)
        #expect(store.state.selectedCategory == nil)
        #expect(store.state.selectedPaymentMethod == nil)
        #expect(store.state.pendingFilterSelection.datePeriod == .thisMonth)
    }

    /// 調整待確認類別只改暫存值，已套用的篩選不變
    @Test
    func filterPendingCategorySelected_調整待確認類別_不改已提交值() async {
        // Given
        var state = OrdersFeature.State()
        state.selectedDatePeriod = .all
        state.selectedCategory = nil
        state.selectedPaymentMethod = nil
        state.showsFilterSheet = true
        state.pendingFilterSelection = OrdersFeature.State.PendingFilterSelection(
            datePeriod: .all,
            category: nil,
            paymentMethod: nil
        )

        let store = TestStore(initialState: state) {
            OrdersFeature()
        }

        // When
        await store.send(.filterPendingCategorySelected("beauty")) {
            $0.pendingFilterSelection.category = "beauty"
        }

        // Then
        #expect(store.state.hasUnappliedFilterChanges)
        #expect(store.state.selectedDatePeriod == .all)
        #expect(store.state.selectedCategory == nil)
        #expect(store.state.selectedPaymentMethod == nil)
        #expect(store.state.pendingFilterSelection.category == "beauty")
    }

    /// 調整待確認付款方式只改暫存值，已套用的篩選不變
    @Test
    func filterPendingPaymentMethodSelected_調整待確認付款方式_不改已提交值() async {
        // Given
        var state = OrdersFeature.State()
        state.selectedDatePeriod = .all
        state.selectedCategory = nil
        state.selectedPaymentMethod = nil
        state.showsFilterSheet = true
        state.pendingFilterSelection = OrdersFeature.State.PendingFilterSelection(
            datePeriod: .all,
            category: nil,
            paymentMethod: nil
        )

        let store = TestStore(initialState: state) {
            OrdersFeature()
        }

        // When
        await store.send(.filterPendingPaymentMethodSelected("信用卡")) {
            $0.pendingFilterSelection.paymentMethod = "信用卡"
        }

        // Then
        #expect(store.state.hasUnappliedFilterChanges)
        #expect(store.state.selectedDatePeriod == .all)
        #expect(store.state.selectedCategory == nil)
        #expect(store.state.selectedPaymentMethod == nil)
        #expect(store.state.pendingFilterSelection.paymentMethod == "信用卡")
    }

    /// 篩選面板輸入搜尋文字後，類別與付款方式只留下包含搜尋字串的項目，不分大小寫
    ///
    /// - Parameters:
    ///   - searchText: 要比對的搜尋文字
    ///   - expectedCategories: 預期留下的類別
    ///   - expectedPaymentMethods: 預期留下的付款方式
    /// - Note: 改寫 `@Shared(.lookupCatalog)`，所以在隔離 storage 內執行，避免污染其他測試
    @Test(arguments: [
        ("boo", ["books"], [String]()),
        ("ook", ["books"], [String]()),
        ("BOO", ["books"], [String]()),
        ("轉帳", [String](), ["轉帳"]),
    ])
    func binding_輸入篩選搜尋文字_過濾分類與付款方式(
        searchText: String,
        expectedCategories: [String],
        expectedPaymentMethods: [String]
    ) async {
        await LookupCatalog.withIsolatedStorage {
            // Given
            let state = OrdersFeature.State()
            state.$lookupCatalog.withLock {
                $0.categories = ["beauty", "snacks", "books"]
                $0.paymentMethods = [
                    PaymentMethodInfo(
                        name: "轉帳",
                        isCardless: false,
                        isBankTransfer: true,
                        isCashOnDelivery: false
                    ),
                    PaymentMethodInfo(
                        name: "貨到付款",
                        isCardless: false,
                        isBankTransfer: false,
                        isCashOnDelivery: true
                    ),
                ]
            }

            let store = TestStore(initialState: state) {
                OrdersFeature()
            }

            // When
            await store.send(\.binding.filterSheetSearchText, searchText) {
                $0.filterSheetSearchText = searchText
            }

            // Then
            #expect(store.state.filterSheetFilteredCategories == expectedCategories)
            #expect(store.state.filterSheetFilteredPaymentMethods == expectedPaymentMethods)
        }
    }

    /// 套用變更過的篩選時提交新篩選，選取改為第一筆符合的訂單並關閉面板
    @Test
    func filterApplyTapped_待確認篩選已變更_提交並關閉面板() async {
        // Given
        var state = OrdersFeature.State()
        // 只有 N2 屬於 beauty，套用後選取改為 N2
        state.orders = [
            makeOrder(id: "N1", category: "electronics"),
            makeOrder(id: "N2", category: "beauty"),
            makeOrder(id: "N3", category: "electronics"),
        ]
        state.selectedDatePeriod = .all
        state.selectedCategory = nil
        state.selectedPaymentMethod = nil
        state.selectedOrderID = "N1"
        state.showsFilterSheet = true
        state.pendingFilterSelection = OrdersFeature.State.PendingFilterSelection(
            datePeriod: .all,
            category: "beauty",
            paymentMethod: nil
        )
        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.filterApplyTapped) {
            $0.selectedCategory = "beauty"
            $0.selectedOrderID = "N2"
            $0.showsFilterSheet = false
        }

        // Then
        #expect(store.state.selectedCategory == "beauty")
        #expect(store.state.selectedOrderID == "N2")
        #expect(store.state.showsFilterSheet == false)
    }

    /// 篩選沒有變更時套用只關閉面板，選取的訂單不重算
    @Test
    func filterApplyTapped_待確認篩選沒有變更_關閉面板且保留原值() async {
        // Given
        var state = OrdersFeature.State()
        // 兩筆都命中篩選；選取 N2 用來確認不會重算
        state.orders = [
            makeOrder(id: "N1", category: "beauty"),
            makeOrder(id: "N2", category: "beauty"),
        ]
        state.selectedDatePeriod = .all
        state.selectedCategory = "beauty"
        state.selectedPaymentMethod = nil
        state.selectedOrderID = "N2"
        state.showsFilterSheet = true
        state.pendingFilterSelection = state.committedFilterSelection

        let store = TestStore(initialState: state) {
            OrdersFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.filterApplyTapped) {
            $0.showsFilterSheet = false
        }

        // Then
        #expect(store.state.showsFilterSheet == false)
        #expect(store.state.selectedCategory == "beauty")
        #expect(store.state.selectedOrderID == "N2")
    }

    /// 篩選有未套用的變更時取消，先詢問是否捨棄
    @Test
    func filterCancelTapped_待確認篩選有變更_呈現捨棄確認() async {
        // Given
        var state = OrdersFeature.State()
        state.selectedDatePeriod = .all
        state.selectedCategory = nil
        state.selectedPaymentMethod = nil
        state.showsFilterSheet = true
        state.pendingFilterSelection = OrdersFeature.State.PendingFilterSelection(
            datePeriod: .thisMonth,
            category: nil,
            paymentMethod: nil
        )
        let expectedConfirmation = expectedFilterDiscardAlert()

        let store = TestStore(initialState: state) {
            OrdersFeature()
        }

        // When
        await store.send(.filterCancelTapped) {
            $0.filterDiscardConfirmation = expectedConfirmation
        }

        // Then
        #expect(store.state.filterDiscardConfirmation == expectedConfirmation)
        #expect(store.state.showsFilterSheet)
    }

    /// 確認捨棄後，待確認篩選還原成已套用的篩選並關閉面板
    @Test
    func filterDiscardConfirmation_確認捨棄待確認篩選_還原並關閉面板() async {
        // Given
        var state = OrdersFeature.State()
        state.showsFilterSheet = true
        state.pendingFilterSelection = OrdersFeature.State.PendingFilterSelection(
            datePeriod: .thisMonth,
            category: "beauty",
            paymentMethod: "信用卡"
        )
        state.filterDiscardConfirmation = expectedFilterDiscardAlert()
        let expectedSelection = OrdersFeature.State.PendingFilterSelection(
            datePeriod: .all,
            category: nil,
            paymentMethod: nil
        )

        let store = TestStore(initialState: state) {
            OrdersFeature()
        }

        // When
        await store.send(.filterDiscardConfirmation(.presented(.discard))) {
            $0.filterDiscardConfirmation = nil
            $0.pendingFilterSelection = expectedSelection
            $0.showsFilterSheet = false
        }

        // Then
        #expect(store.state.filterDiscardConfirmation == nil)
        #expect(store.state.pendingFilterSelection == expectedSelection)
        #expect(store.state.showsFilterSheet == false)
        #expect(store.state.selectedDatePeriod == .all)
        #expect(store.state.selectedCategory == nil)
        #expect(store.state.selectedPaymentMethod == nil)
    }

    /// 篩選沒有變更時取消，不詢問直接關閉面板
    @Test
    func filterCancelTapped_待確認篩選沒有變更_直接關閉面板() async {
        // Given
        var state = OrdersFeature.State()
        state.selectedDatePeriod = .thisMonth
        state.selectedCategory = "beauty"
        state.selectedPaymentMethod = nil
        state.showsFilterSheet = true
        state.pendingFilterSelection = state.committedFilterSelection

        let store = TestStore(initialState: state) {
            OrdersFeature()
        }

        // When
        await store.send(.filterCancelTapped) {
            $0.showsFilterSheet = false
        }

        // Then
        #expect(store.state.showsFilterSheet == false)
        #expect(store.state.filterDiscardConfirmation == nil)
    }
}

// MARK: - Nested Types

extension OrdersFeatureTests {

    /// 訂單搜尋測試的輸入與預期結果
    ///
    /// - Note: 用於測試方法的參數型別，須為 internal
    struct SearchCase: Sendable {

        /// 搜尋文字
        let query: String

        /// 搜尋後預期選取的訂單識別碼，也就是篩選結果的第一筆
        let selectedOrderID: String

        /// 預期篩選出的訂單識別碼
        let expectedOrderIDs: [String]
    }

    /// iPad 寬版畫面訂單列表欄上方篩選按鈕開啟的選擇器
    ///
    /// - Note: 用於測試方法的參數型別，須為 internal
    enum FilterPicker: CaseIterable, Sendable {

        /// 類別選擇器
        case category

        /// 付款方式選擇器
        case paymentMethod

        /// 指向這個選擇器是否顯示的狀態欄位
        var keyPath: any WritableKeyPath<OrdersFeature.State, Bool> & Sendable {
            switch self {
            case .category:
                \.showsCategoryPicker

            case .paymentMethod:
                \.showsPaymentMethodPicker
            }
        }
    }
}

// MARK: - Private Method

private extension OrdersFeatureTests {

    /// 讓 `.task` 附帶的五項主檔讀取一律失敗，測試只需處理訂單載入
    ///
    /// - Parameter dependencies: 要注入的依賴集合
    /// - Note: 主檔讀取失敗時 reducer 不送出任何 Action，窮舉的 TestStore 因此不必逐一接收
    static func suppressOrderLookupEffects(_ dependencies: inout DependencyValues) {
        let failingFetchOrderSources: OrderSourceService.FetchOrderSources = {
            throw .fetchFailed(
                underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
            )
        }
        let failingFetchCampaigns: CampaignService.FetchCampaigns = {
            throw .fetchFailed(
                underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
            )
        }
        let failingFetchCategories: CategoryService.FetchCategories = {
            throw .fetchFailed(
                underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
            )
        }
        let failingFetchPaymentMethodInfos: PaymentMethodService.FetchPaymentMethodInfos = {
            throw .fetchFailed(
                underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
            )
        }
        let failingFetchStatuses: ReconciliationStatusService.FetchReconciliationStatuses = {
            throw .fetchFailed(
                underlying: TestDependencies.makeUnderlyingError(message: "suppressed")
            )
        }

        dependencies.orderSourceService.fetchOrderSources = failingFetchOrderSources
        dependencies.campaignService.fetchCampaigns = failingFetchCampaigns
        dependencies.categoryService.fetchCategories = failingFetchCategories
        dependencies.paymentMethodService.fetchPaymentMethodInfos = failingFetchPaymentMethodInfos
        dependencies.reconciliationStatusService.fetchReconciliationStatuses = failingFetchStatuses
    }

    /// 建立只變更狀態的訂單複本
    ///
    /// - Parameters:
    ///   - order: 要複製的訂單
    ///   - status: 要套用的訂單狀態
    /// - Returns: 套用新狀態後的訂單
    static func withStatus(_ order: LedgerOrder, status: OrderStatus) -> LedgerOrder {
        LedgerOrder(
            id: order.id,
            customer: order.customer,
            status: status,
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
            reconciliationStatus: order.reconciliationStatus,
            campaignNames: order.campaignNames,
            paymentReceiptStatus: order.paymentReceiptStatus,
            isCashOnDelivery: order.isCashOnDelivery,
            photos: order.photos,
            mergedSourceIDs: order.mergedSourceIDs
        )
    }

    /// 建立折抵上限測試所需的訂單複本
    ///
    /// - Parameters:
    ///   - order: 要複製的訂單
    ///   - chargedAmount: 客戶實付金額
    ///   - cardlessDeductionAmount: 無卡折抵金額
    ///   - paymentMethod: 付款方式
    /// - Returns: 套用新的實付金額、無卡折抵金額與付款方式後的訂單
    static func withCardlessAmounts(
        _ order: LedgerOrder,
        chargedAmount: Decimal,
        cardlessDeductionAmount: Decimal,
        paymentMethod: String
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
            chargedAmount: chargedAmount,
            cardlessDeductionAmount: cardlessDeductionAmount,
            cardlessSupplementAmount: order.cardlessSupplementAmount,
            orderSource: order.orderSource,
            categories: order.categories,
            paymentMethod: paymentMethod,
            notes: order.notes,
            reconciliationStatus: order.reconciliationStatus,
            campaignNames: order.campaignNames,
            paymentReceiptStatus: order.paymentReceiptStatus,
            isCashOnDelivery: order.isCashOnDelivery,
            photos: order.photos,
            mergedSourceIDs: order.mergedSourceIDs
        )
    }

    /// 建立寫入失敗 alert，供測試比對
    ///
    /// - Parameter message: alert 顯示的錯誤訊息
    /// - Returns: 寫入失敗時顯示的 alert
    func expectedWriteFailureAlert(
        _ message: LocalizedStringKey
    ) -> AlertState<OrdersFeature.Action.Alert> {
        AlertState {
            TextState("操作失敗")
        } actions: {
            ButtonState(role: .cancel) {
                TextState("知道了")
            }
        } message: {
            TextState(message)
        }
    }

    /// 建立只有一個類別的最小訂單，其餘欄位填零值或固定值
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - category: 商品類別
    ///   - status: 訂單狀態
    ///   - paymentMethod: 付款方式
    /// - Returns: 建立的測試訂單
    func makeOrder(
        id: String,
        category: String,
        status: OrderStatus = .quoting,
        paymentMethod: String = "付款"
    ) -> LedgerOrder {
        makeOrder(
            id: id,
            categories: [category],
            status: status,
            paymentMethod: paymentMethod
        )
    }

    /// 建立可指定多個類別與開團名稱的最小訂單，其餘欄位填零值或固定值
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - categories: 商品類別
    ///   - status: 訂單狀態
    ///   - paymentMethod: 付款方式
    ///   - campaignNames: 開團名稱
    /// - Returns: 建立的測試訂單
    func makeOrder(
        id: String,
        categories: [String],
        status: OrderStatus = .quoting,
        paymentMethod: String = "付款",
        campaignNames: [String] = []
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "客戶", initials: "XX", tier: .new),
            status: status,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [
                LedgerOrderItem(
                    id: UUID(0),
                    name: "商品",
                    quantity: 1,
                    unitPrice: 100
                ),
            ],
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
            orderSource: "來源",
            categories: categories,
            paymentMethod: paymentMethod,
            notes: "",
            reconciliationStatus: "",
            campaignNames: campaignNames,
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }

    /// 建立刪除訂單的確認 alert
    ///
    /// - Parameters:
    ///   - orderID: 要刪除的訂單編號
    ///   - customerName: 訂單所屬客戶名稱
    /// - Returns: 刪除前顯示的確認 alert
    func expectedDeletionConfirmation(
        orderID: LedgerOrder.ID,
        customerName: String
    ) -> AlertState<OrdersFeature.Action.Alert> {
        AlertState {
            TextState("刪除訂單")
        } actions: {
            ButtonState(role: .destructive, action: .confirmDelete(orderID)) {
                TextState("刪除")
            }
            ButtonState(role: .cancel) {
                TextState("取消")
            }
        } message: {
            TextState("刪除「\(customerName)」的這筆訂單後無法復原。")
        }
    }

    /// 建立捨棄篩選變更的確認 alert
    ///
    /// - Returns: 捨棄前顯示的確認 alert
    func expectedFilterDiscardAlert() -> AlertState<OrdersFeature.Action.FilterDiscardAlert> {
        AlertState {
            TextState("捨棄變更")
        } actions: {
            ButtonState(role: .destructive, action: .discard) {
                TextState("捨棄變更")
            }
            ButtonState(role: .cancel) {
                TextState("繼續編輯")
            }
        } message: {
            TextState("這些篩選條件尚未套用，離開後將不會保留。")
        }
    }
}
