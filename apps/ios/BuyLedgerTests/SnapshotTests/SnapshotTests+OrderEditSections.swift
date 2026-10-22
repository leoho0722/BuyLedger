//
//  SnapshotTests+OrderEditSections.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/17.
//

import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import BuyLedger

extension SnapshotTests {

    /// 一般既有訂單的狀態與幣別區段，顯示訂單狀態、幣別與付款方式
    ///
    /// - Throws: `Asia/Taipei` 時區不存在時由 `#require` 丟出
    /// - Note: 於 key window 渲染，離屏渲染畫不出系統分段控制等元件的選取狀態
    @Test
    func orderEditStatusSection_一般既有訂單_符合基準圖() throws {
        try TestDependencies.withFixedNow {
            // Given
            let store = try Self.makeSectionStore(original: LedgerOrder.sampleOrders[0])

            // When
            let view = Self.orderEditSection(height: 240) { _ in
                OrderEditStatusSection(store: store)
            }

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 一般既有訂單的收款金額區段，顯示客戶實付
    ///
    /// - Throws: `Asia/Taipei` 時區不存在時由 `#require` 丟出
    /// - Note: 於 key window 渲染，離屏渲染畫不出系統分段控制等元件的選取狀態
    @Test
    func orderEditPaymentSection_一般既有訂單_符合基準圖() throws {
        try TestDependencies.withFixedNow {
            // Given
            let store = try Self.makeSectionStore(original: LedgerOrder.sampleOrders[0])

            // When
            let view = Self.orderEditSection(height: 160) {
                OrderEditPaymentSection(store: store, focusedField: $0)
            }

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 一般既有訂單的開團與收款區段，未歸團且收款狀態為待收款
    ///
    /// - Throws: `Asia/Taipei` 時區不存在時由 `#require` 丟出
    /// - Note: 於 key window 渲染，離屏渲染畫不出系統分段控制等元件的選取狀態
    @Test
    func orderEditCampaignSection_一般既有訂單_符合基準圖() throws {
        try TestDependencies.withFixedNow {
            // Given
            let store = try Self.makeSectionStore(original: LedgerOrder.sampleOrders[0])

            // When
            let view = Self.orderEditSection(height: 200) { _ in
                OrderEditCampaignSection(store: store)
            }

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 一般既有訂單的成本區段，顯示商品成本與三種運費
    ///
    /// - Throws: `Asia/Taipei` 時區不存在時由 `#require` 丟出
    /// - Note: 於 key window 渲染，離屏渲染畫不出系統分段控制等元件的選取狀態
    @Test
    func orderEditCostSection_一般既有訂單_符合基準圖() throws {
        try TestDependencies.withFixedNow {
            // Given
            let store = try Self.makeSectionStore(original: LedgerOrder.sampleOrders[0])

            // When
            let view = Self.orderEditSection(height: 380) {
                OrderEditCostSection(store: store, focusedField: $0)
            }

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 一般既有訂單的手續費區段，顯示刷卡、平台與金流手續費率
    ///
    /// - Throws: `Asia/Taipei` 時區不存在時由 `#require` 丟出
    /// - Note: 於 key window 渲染，離屏渲染畫不出系統分段控制等元件的選取狀態
    @Test
    func orderEditFeesSection_一般既有訂單_符合基準圖() throws {
        try TestDependencies.withFixedNow {
            // Given
            let store = try Self.makeSectionStore(original: LedgerOrder.sampleOrders[0])

            // When
            let view = Self.orderEditSection(height: 340) {
                OrderEditFeesSection(store: store, focusedField: $0)
            }

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 一般既有訂單的商品區段，逐列顯示商品明細
    ///
    /// - Throws: `Asia/Taipei` 時區不存在時由 `#require` 丟出
    /// - Note: 於 key window 渲染，離屏渲染畫不出系統分段控制等元件的選取狀態
    @Test
    func orderEditItemsSection_一般既有訂單_符合基準圖() throws {
        try TestDependencies.withFixedNow {
            // Given
            let store = try Self.makeSectionStore(original: LedgerOrder.sampleOrders[0])

            // When
            let view = Self.orderEditSection(height: 380) {
                OrderEditItemsSection(store: store, focusedField: $0)
            }

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 一般既有訂單的備註區段
    ///
    /// - Throws: `Asia/Taipei` 時區不存在時由 `#require` 丟出
    /// - Note: 於 key window 渲染，離屏渲染畫不出系統分段控制等元件的選取狀態
    @Test
    func orderEditNotesSection_一般既有訂單_符合基準圖() throws {
        try TestDependencies.withFixedNow {
            // Given
            let store = try Self.makeSectionStore(original: LedgerOrder.sampleOrders[0])

            // When
            let view = Self.orderEditSection(height: 180) {
                OrderEditNotesSection(notes: .constant(store.draft.notes), focusedField: $0)
            }

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 一般既有訂單的照片區段，照片已載入
    ///
    /// - Throws: `Asia/Taipei` 時區不存在時由 `#require` 丟出
    /// - Note: 於 key window 渲染，離屏渲染畫不出系統分段控制等元件的選取狀態
    @Test
    func orderEditPhotosSection_一般既有訂單_符合基準圖() throws {
        try TestDependencies.withFixedNow {
            // Given
            let store = try Self.makeSectionStore(original: LedgerOrder.sampleOrders[0])

            // When
            let view = Self.orderEditSection(height: 160) { _ in
                OrderEditPhotosSection(store: store.scope(state: \.photos, action: \.photos))
            }

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 一般既有訂單的原始訂單區段，顯示短版訂單編號
    ///
    /// - Throws: `Asia/Taipei` 時區不存在時由 `#require` 丟出
    /// - Note: 於 key window 渲染，離屏渲染畫不出系統分段控制等元件的選取狀態
    @Test
    func orderEditOriginalSection_一般既有訂單_符合基準圖() throws {
        try TestDependencies.withFixedNow {
            // Given
            let store = try Self.makeSectionStore(original: LedgerOrder.sampleOrders[0])

            // When
            let view = Self.orderEditSection(height: 140) { _ in
                OrderEditOriginalSection(original: store.original)
            }

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 合併產生的訂單在開團區段把多個開團以「、」串接顯示
    ///
    /// - Throws: 範例訂單沒有合併訂單或 `Asia/Taipei` 時區不存在時由 `#require` 丟出
    /// - Note: 於 key window 渲染，離屏渲染畫不出系統分段控制等元件的選取狀態
    @Test
    func orderEditCampaignSection_合併訂單情境_以頓號串接開團() throws {
        try TestDependencies.withFixedNow {
            // Given
            let mergedOrder = try #require(
                LedgerOrder.sampleOrders.first {
                    !$0.mergedSourceIDs.isEmpty
                }
            )
            let store = try Self.makeSectionStore(original: mergedOrder)

            // When
            let view = Self.orderEditSection(height: 200) { _ in
                OrderEditCampaignSection(store: store)
            }

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 訂單編號很長時，原始訂單區段只顯示依規則截短的短識別碼 (`displayID`)
    ///
    /// - Throws: `Asia/Taipei` 時區不存在時由 `#require` 丟出
    /// - Note: 於 key window 渲染，離屏渲染畫不出系統分段控制等元件的選取狀態
    @Test
    func orderEditOriginalSection_長訂單識別碼_顯示短識別碼() throws {
        try TestDependencies.withFixedNow {
            // Given
            let store = try Self.makeSectionStore(original: Self.longIdentifierOrder)

            // When
            let view = Self.orderEditSection(height: 140) { _ in
                OrderEditOriginalSection(original: store.original)
            }

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
            #expect(Self.longIdentifierOrder.displayID == "BL-DRAFT-000000")
        }
    }
}

// MARK: - Private Method

private extension SnapshotTests {

    /// 編號長度遠超過短識別碼的訂單，供原始訂單區段驗證截短
    static var longIdentifierOrder: LedgerOrder {
        LedgerOrder(
            id: "BL-DRAFT-00000000-0000-0000-0000-000000000000",
            customer: LedgerCustomer(name: "長編號測試", initials: "LI", tier: .regular),
            status: .quoting,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [LedgerOrderItem(name: "示範商品", quantity: 1, unitPrice: 1_000)],
            itemCost: 600,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 1_000,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "蝦皮",
            categories: ["美妝"],
            paymentMethod: "信用卡",
            notes: "",
            reconciliationStatus: "",
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }

    /// 以快照用的表單狀態建立訂單編輯 store
    ///
    /// - Parameter original: 表單要顯示的既有訂單
    /// - Returns: 照片已載入、時間固定的訂單編輯 store
    /// - Throws: `Asia/Taipei` 時區不存在時由 `#require` 丟出
    static func makeSectionStore(original: LedgerOrder) throws -> StoreOf<OrderEditFeature> {
        let state = try makeOrderEditSnapshotState(original: original)
        return Store(initialState: state) {
            OrderEditFeature()
        }
    }

    /// 把單一訂單編輯區段放進分組表單，固定寬度為 iPhone 直向 393
    ///
    /// - Parameters:
    ///   - height: 能容納整個區段的高度
    ///   - content: 以焦點綁定建立的區段
    /// - Returns: 套用正體中文語系與固定尺寸的區段宿主
    static func orderEditSection<Content: View>(
        height: CGFloat,
        @ViewBuilder content: @escaping (
            FocusState<OrderEditFeature.State.Field?>.Binding
        ) -> Content
    ) -> some View {
        SnapshotSectionView(content: content)
            .environment(\.locale, AppLanguage.traditionalChinese.locale)
            .frame(width: 393, height: height)
    }
}
