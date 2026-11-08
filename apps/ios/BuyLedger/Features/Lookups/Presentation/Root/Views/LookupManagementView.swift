//
//  LookupManagementView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import ComposableArchitecture
import SwiftUI

/// 訂單來源、商品類別、付款方式與對帳狀態的管理畫面，表單與提示由分欄層的 `LookupManagementPresentations` 呈現
struct LookupManagementView: View {

    // MARK: - Properties

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<LookupManagementFeature>

    // MARK: - Body

    /// 顯示主檔清單與操作入口
    var body: some View {
        LookupItemList(
            classificationForName: {
                store.state.classification(for: $0)
            },
            hasLoadFailed: store.hasLoadFailed,
            items: store.items,
            kind: store.state.kind
        ) {
            store.send(.view(.deleteButtonTapped(name: $0)))
        } onEditPaymentMethod: {
            store.send(.view(.editButtonTapped(name: $0)))
        } onRename: {
            store.send(.view(.renameButtonTapped(name: $0)))
        }
        .task {
            await store.send(.view(.task)).finish()
        }
        .accessibilityIdentifier(BLAccessibilityID.LookupManagement.root)
        .navigationTitle(Text(store.state.kind.title))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                addButton
            }
        }
    }
}

// MARK: - Private Views

private extension LookupManagementView {

    /// 新增主檔項目的入口
    var addButton: some View {
        Button {
            store.send(.view(.addButtonTapped))
        } label: {
            // icon-only 只留 +，完整標題留作無障礙標籤、新增流程標題仍顯示於 sheet
            Label(store.state.kind.addButtonTitle, systemImage: "plus")
        }
        .labelStyle(.iconOnly)
        .accessibilityIdentifier(BLAccessibilityID.LookupManagement.addButton)
    }
}

// MARK: - Preview

#Preview("商品類別管理") {
    NavigationStack {
        LookupManagementView(
            store: {
                var state = LookupManagementFeature.State(kind: .category)
                state.$catalog.withLock {
                    $0.categories = ["服飾", "美妝", "精品"]
                }
                state.hasLoaded = true
                return Store(initialState: state) {
                    LookupManagementFeature()
                }
            }()
        )
    }
}

#Preview("付款方式管理") {
    NavigationStack {
        LookupManagementView(
            store: {
                var state = LookupManagementFeature.State(kind: .paymentMethod)
                state.$catalog.withLock {
                    $0.paymentMethods = [
                        PaymentMethodInfo(
                            name: "信用卡",
                            isCardless: false,
                            isBankTransfer: false,
                            isCashOnDelivery: false
                        ),
                        PaymentMethodInfo(
                            name: "無卡分期",
                            isCardless: true,
                            isBankTransfer: false,
                            isCashOnDelivery: false
                        ),
                        PaymentMethodInfo(
                            name: "銀行匯款",
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
                state.hasLoaded = true
                return Store(initialState: state) {
                    LookupManagementFeature()
                }
            }()
        )
    }
}

#Preview("商品類別空狀態") {
    NavigationStack {
        LookupManagementView(
            store: {
                var state = LookupManagementFeature.State(kind: .category)
                state.$catalog.withLock {
                    $0.categories = []
                }
                state.hasLoaded = true
                return Store(initialState: state) {
                    LookupManagementFeature()
                }
            }()
        )
    }
}

#Preview("商品類別載入失敗") {
    NavigationStack {
        LookupManagementView(
            store: {
                var state = LookupManagementFeature.State(kind: .category)
                state.$catalog.withLock {
                    $0.categories = []
                }
                state.hasLoadFailed = true
                state.hasLoaded = true
                return Store(initialState: state) {
                    LookupManagementFeature()
                }
            }()
        )
    }
}
