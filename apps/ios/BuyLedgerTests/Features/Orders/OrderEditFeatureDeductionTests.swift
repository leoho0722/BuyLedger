//
//  OrderEditFeatureDeductionTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderEditFeature` 的單元測試，涵蓋折抵原值保留、超額檢核與儲存條件
struct OrderEditFeatureDeductionTests {

    /// 驗證必填完整時輸入超過實付的折抵，保留輸入並禁止儲存
    @Test
    @MainActor
    func binding_折抵超過實付_保留輸入且禁止儲存() async {
        // Given
        let store = TestStore(initialState: Self.makeState(chargedAmount: 1_000, deduction: 0)) {
            OrderEditFeature()
        }

        // When
        await store.send(\.binding.cardlessDeductionAmount, 5_000) {
            $0.draft.cardlessDeductionAmount = 5_000
        }

        // Then
        #expect(store.state.draft.cardlessDeductionAmount == 5_000)
        #expect(store.state.hasRequiredFields)
        #expect(store.state.isCardlessDeductionExceeded)
        #expect(!store.state.canSave)
    }

    /// 驗證超額折抵改為實付以內的金額後，解除超額並允許儲存
    @Test
    @MainActor
    func binding_超額折抵調低至合法值_解除超額且可儲存() async {
        // Given
        let initial = Self.makeState(chargedAmount: 1_000, deduction: 5_000)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(\.binding.cardlessDeductionAmount, 800) {
            $0.draft.cardlessDeductionAmount = 800
        }

        // Then
        #expect(store.state.draft.cardlessDeductionAmount == 800)
        #expect(!store.state.isCardlessDeductionExceeded)
        #expect(store.state.canSave)
    }

    /// 驗證實付逐字輸入或降低再提高時，折抵不變且超額判斷隨目前實付更新
    ///
    /// - Parameter testCase: 前置實付、這次輸入與字面值檢核結果
    @Test(arguments: [
        ChargedAmountValidationCase(
            previousAmount: 2_500,
            chargedAmount: 2,
            isExceeded: true,
            isSaveAllowed: false
        ),
        ChargedAmountValidationCase(
            previousAmount: 2_500,
            chargedAmount: 26,
            isExceeded: true,
            isSaveAllowed: false
        ),
        ChargedAmountValidationCase(
            previousAmount: 2_500,
            chargedAmount: 260,
            isExceeded: true,
            isSaveAllowed: false
        ),
        ChargedAmountValidationCase(
            previousAmount: 2_500,
            chargedAmount: 2_600,
            isExceeded: false,
            isSaveAllowed: true
        ),
        ChargedAmountValidationCase(
            previousAmount: 2_500,
            chargedAmount: 500,
            isExceeded: true,
            isSaveAllowed: false
        ),
        ChargedAmountValidationCase(
            previousAmount: 500,
            chargedAmount: 3_000,
            isExceeded: false,
            isSaveAllowed: true
        ),
    ])
    @MainActor
    func binding_實付逐字降低或提高_保留折抵並更新檢核(testCase: ChargedAmountValidationCase) async {
        // Given
        var initial = Self.makeState(chargedAmount: 2_500, deduction: 1_000)
        initial.draft.chargedAmount = testCase.previousAmount
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(\.binding.chargedAmount, testCase.chargedAmount) {
            $0.draft.chargedAmount = testCase.chargedAmount
        }

        // Then
        #expect(store.state.draft.cardlessDeductionAmount == 1_000)
        #expect(store.state.isCardlessDeductionExceeded == testCase.isExceeded)
        #expect(store.state.canSave == testCase.isSaveAllowed)
    }

    /// 驗證實付輸入 1 後還原開啟時的 2500，折抵仍是 1000 且表單未修改
    @Test
    @MainActor
    func binding_實付輸入後還原原值_折抵不變且表單未修改() async {
        // Given
        var initial = Self.makeState(chargedAmount: 2_500, deduction: 1_000)
        initial.draft.chargedAmount = 1
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(\.binding.chargedAmount, 2_500) {
            $0.draft.chargedAmount = 2_500
        }

        // Then
        #expect(store.state.draft.cardlessDeductionAmount == 1_000)
        #expect(!store.state.isCardlessDeductionExceeded)
        #expect(store.state.canSave)
        #expect(!store.state.isDirty)
    }

    /// 驗證既有訂單與合併預填的超額折抵開啟時保留原值，未修改但不可儲存
    ///
    /// - Parameter source: 開啟表單的資料來源
    @Test(arguments: [DraftSource.existingOrder, .mergePrefill])
    func init_既有或合併草稿折抵超額_保留原值且未修改(source: DraftSource) {
        // Given
        let original = LedgerOrder.fixture(
            id: "DEDUCTION-INIT",
            chargedAmount: 1_000,
            cardlessDeductionAmount: 1_500,
            orderSource: "測試來源",
            categories: ["測試類別"],
            paymentMethod: "無卡"
        )
        var draft = OrderDraft(original: nil, currentDate: TestDependencies.fixedNow)
        draft.customerName = "折抵測試"
        draft.orderSource = "測試來源"
        draft.categories = ["測試類別"]
        draft.paymentMethod = "無卡"
        draft.chargedAmount = 1_000
        draft.cardlessDeductionAmount = 1_500

        // When
        let state: OrderEditFeature.State
        switch source {
        case .existingOrder:
            state = OrderEditFeature.State(
                original: original,
                id: UUID(0),
                options: Self.options,
                currentDate: TestDependencies.fixedNow
            )

        case .mergePrefill:
            state = OrderEditFeature.State(
                id: UUID(0),
                options: Self.options,
                currentDate: TestDependencies.fixedNow,
                prefill: .init(
                    draft: draft,
                    mergeSourceIDs: ["PRIMARY", "SECONDARY"],
                    keptPhotos: []
                )
            )
        }

        // Then
        #expect(state.draft.cardlessDeductionAmount == 1_500)
        #expect(state.initialDraft.cardlessDeductionAmount == 1_500)
        #expect(state.hasRequiredFields)
        #expect(state.isCardlessDeductionExceeded)
        #expect(!state.canSave)
        #expect(!state.isDirty)
    }

    /// 驗證超額折抵在非無卡付款時不阻擋儲存，切回無卡才恢復超額檢核
    ///
    /// - Parameter testCase: 目前與選取的付款方式，以及字面值檢核結果
    @Test(arguments: [
        PaymentMethodValidationCase(
            currentMethod: "無卡",
            selectedMethod: "信用卡",
            isExceeded: false,
            isSaveAllowed: true
        ),
        PaymentMethodValidationCase(
            currentMethod: "信用卡",
            selectedMethod: "無卡",
            isExceeded: true,
            isSaveAllowed: false
        ),
    ])
    @MainActor
    func pickers_超額折抵切換付款方式_保留折抵並依付款類型檢核(testCase: PaymentMethodValidationCase) async {
        // Given
        var initial = Self.makeState(chargedAmount: 1_000, deduction: 1_500)
        initial.draft.paymentMethod = testCase.currentMethod
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.pickers(.view(.paymentMethodSelected(testCase.selectedMethod))))

        // Then
        await store.receive(\.pickers.delegate.paymentMethodSelected, testCase.selectedMethod) {
            $0.draft.paymentMethod = testCase.selectedMethod
        }
        #expect(store.state.draft.cardlessDeductionAmount == 1_500)
        #expect(store.state.isCardlessDeductionExceeded == testCase.isExceeded)
        #expect(store.state.canSave == testCase.isSaveAllowed)
    }

    /// 驗證超額時改動備註或品項，不修改折抵也不解除超額
    ///
    /// - Parameter change: 這次綁定改動的草稿欄位
    @Test(arguments: [DraftChange.notes, .items])
    @MainActor
    func binding_超額時修改備註或品項_保留折抵與超額判斷(change: DraftChange) async {
        // Given
        let initial = Self.makeState(chargedAmount: 1_000, deduction: 1_500)
        var editedDraft = initial.draft
        switch change {
        case .notes:
            editedDraft.notes = "已聯絡客戶"

        case .items:
            editedDraft.items = [
                LedgerOrderItem(
                    id: UUID(1),
                    name: "新商品",
                    quantity: 1,
                    unitPrice: 100
                ),
            ]
        }
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(\.binding.draft, editedDraft) {
            switch change {
            case .notes:
                $0.draft.notes = "已聯絡客戶"

            case .items:
                $0.draft.items = [
                    LedgerOrderItem(
                        id: UUID(1),
                        name: "新商品",
                        quantity: 1,
                        unitPrice: 100
                    ),
                ]
            }
        }

        // Then
        #expect(store.state.draft.cardlessDeductionAmount == 1_500)
        #expect(store.state.isCardlessDeductionExceeded)
        #expect(!store.state.canSave)
    }

    /// 驗證合法折抵搭配補款 0 或 200 時可儲存，存下折抵與營收保留正確金額
    ///
    /// - Parameter testCase: 補款、輸入折抵與字面值預期結果
    /// - Throws: 既有訂單不存在時由 `#require` 丟出測試錯誤
    @Test(arguments: [
        DeductionSaveCase(
            supplement: 0,
            enteredDeduction: 300,
            expectedStoredDeduction: 300,
            expectedRevenue: 700
        ),
        DeductionSaveCase(
            supplement: 0,
            enteredDeduction: 1_000,
            expectedStoredDeduction: 1_000,
            expectedRevenue: 0
        ),
        DeductionSaveCase(
            supplement: 200,
            enteredDeduction: 1_000,
            expectedStoredDeduction: 1_000,
            expectedRevenue: 200
        ),
    ])
    @MainActor
    func binding_合法折抵搭配不同補款_可儲存且折抵與營收相符(testCase: DeductionSaveCase) async throws {
        // Given
        var initial = Self.makeState(chargedAmount: 1_000, deduction: 0)
        initial.draft.cardlessSupplementAmount = testCase.supplement
        let original = try #require(initial.original)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(\.binding.cardlessDeductionAmount, testCase.enteredDeduction) {
            $0.draft.cardlessDeductionAmount = testCase.enteredDeduction
        }
        let result = OrderDraft.resolveWriteResult(store.state, existingOrders: [original]) {
            "UNUSED"
        }
        let summary = OrderSummary(order: result.order)

        // Then
        #expect(store.state.draft.cardlessDeductionAmount == testCase.enteredDeduction)
        #expect(store.state.canSave)
        #expect(!store.state.isCardlessDeductionExceeded)
        #expect(result.order.cardlessDeductionAmount == testCase.expectedStoredDeduction)
        #expect(summary.revenue == testCase.expectedRevenue)
    }

    /// 驗證實付 1000、折抵 1500 時，補款 0 或 200 都不解除超額且保留原輸入
    ///
    /// - Parameter testCase: 補款與超過實付的折抵輸入
    @Test(arguments: [
        ExceededDeductionCase(supplement: 0, enteredDeduction: 1_500),
        ExceededDeductionCase(supplement: 200, enteredDeduction: 1_500),
    ])
    @MainActor
    func binding_超額折抵搭配不同補款_保留輸入且禁止儲存(testCase: ExceededDeductionCase) async {
        // Given
        var initial = Self.makeState(chargedAmount: 1_000, deduction: 0)
        initial.draft.cardlessSupplementAmount = testCase.supplement
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(\.binding.cardlessDeductionAmount, testCase.enteredDeduction) {
            $0.draft.cardlessDeductionAmount = testCase.enteredDeduction
        }

        // Then
        #expect(store.state.isCardlessDeductionExceeded)
        #expect(!store.state.canSave)
        #expect(store.state.draft.cardlessDeductionAmount == testCase.enteredDeduction)
    }

    /// 驗證負實付搭配零折抵時，折抵上限以零判斷而不誤報超額
    @Test
    func isCardlessDeductionExceeded_實付為負且折抵為零_不視為超額() {
        // Given
        let state = Self.makeState(chargedAmount: -20, deduction: 0)

        // When
        let isExceeded = state.isCardlessDeductionExceeded

        // Then
        #expect(!isExceeded)
        #expect(state.canSave)
    }
}

// MARK: - Nested Types

extension OrderEditFeatureDeductionTests {

    /// 實付變更前後的金額與檢核結果
    struct ChargedAmountValidationCase: Sendable {

        /// 這次寫入前的實付金額
        let previousAmount: Decimal

        /// 這次由實付欄寫入的金額
        let chargedAmount: Decimal

        /// 是否預期折抵超過實付
        let isExceeded: Bool

        /// 是否預期允許儲存
        let isSaveAllowed: Bool
    }

    /// 開啟編輯表單的資料來源
    enum DraftSource: Sendable {

        /// 既有訂單
        case existingOrder

        /// 合併預填草稿
        case mergePrefill
    }

    /// 付款方式切換與折抵檢核結果
    struct PaymentMethodValidationCase: Sendable {

        /// 選取前的付款方式
        let currentMethod: String

        /// 這次選取的付款方式
        let selectedMethod: String

        /// 是否預期折抵超過實付
        let isExceeded: Bool

        /// 是否預期允許儲存
        let isSaveAllowed: Bool
    }

    /// 以整份草稿綁定改動的非金額欄位
    enum DraftChange: Sendable {

        /// 修改備註
        case notes

        /// 修改商品明細
        case items
    }

    /// 合法折抵與補款輸入的存檔金額及營收預期
    struct DeductionSaveCase: Sendable {

        /// 草稿的無卡補款金額
        let supplement: Decimal

        /// 這次由折抵欄寫入的金額
        let enteredDeduction: Decimal

        /// 預期存下的折抵金額
        let expectedStoredDeduction: Decimal

        /// 預期營收
        let expectedRevenue: Decimal
    }

    /// 超額折抵與補款的輸入組合
    struct ExceededDeductionCase: Sendable {

        /// 草稿的無卡補款金額
        let supplement: Decimal

        /// 這次由折抵欄寫入的超額金額
        let enteredDeduction: Decimal
    }
}

// MARK: - Private Method

private extension OrderEditFeatureDeductionTests {

    /// 同時提供無卡與信用卡分類的表單選項
    static var options: OrderEditOptions {
        OrderEditOptions(
            paymentMethods: [
                PaymentMethodInfo(
                    name: "無卡",
                    isCardless: true,
                    isBankTransfer: false,
                    isCashOnDelivery: false
                ),
                PaymentMethodInfo(
                    name: "信用卡",
                    isCardless: false,
                    isBankTransfer: false,
                    isCashOnDelivery: false
                ),
            ],
            calendar: TestDependencies.fixedCalendar
        )
    }

    /// 以指定實付與折抵建立必填完整的無卡訂單表單
    ///
    /// - Parameters:
    ///   - chargedAmount: 原始實付金額
    ///   - deduction: 原始折抵金額，包含超過實付的值
    /// - Returns: 保留原始金額且必填完整的表單狀態
    static func makeState(chargedAmount: Decimal, deduction: Decimal) -> OrderEditFeature.State {
        let original = LedgerOrder(
            id: "DEDUCTION-001",
            customer: LedgerCustomer(name: "折抵測試", initials: "DT", tier: .regular),
            status: .delivered,
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
            chargedAmount: chargedAmount,
            cardlessDeductionAmount: deduction,
            cardlessSupplementAmount: 0,
            orderSource: "測試來源",
            categories: ["測試類別"],
            paymentMethod: "無卡",
            notes: "",
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
        return OrderEditFeature.State(
            original: original,
            id: UUID(0),
            options: Self.options,
            currentDate: TestDependencies.fixedNow
        )
    }
}
