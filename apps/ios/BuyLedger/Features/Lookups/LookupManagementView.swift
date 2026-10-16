//
//  LookupManagementView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import ComposableArchitecture
import SwiftUI

/// 訂單來源、商品類別、付款方式與對帳狀態的管理畫面
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
        .navigationTitle(Text(LocalizedStringKey(store.state.kind.title)))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                addButton
            }
        }
        .sheet(
            item: $store.scope(state: \.$destination, action: \.destination).add,
            onDismiss: sendFormSheetDismissed
        ) {
            addSheet(store: $0)
        }
        .sheet(
            item: $store.scope(state: \.$destination, action: \.destination).rename,
            onDismiss: sendFormSheetDismissed
        ) {
            renameSheet(store: $0)
        }
        .sheet(
            item: $store.scope(state: \.$destination, action: \.destination).editPaymentMethod,
            onDismiss: sendFormSheetDismissed
        ) {
            paymentMethodEditSheet(store: $0)
        }
        .alert($store.scope(state: \.$destination, action: \.destination).alert)
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
            Label(LocalizedStringKey(store.state.kind.addButtonTitle), systemImage: "plus")
        }
        .labelStyle(.iconOnly)
        .accessibilityIdentifier(BLAccessibilityID.LookupManagement.addButton)
    }

    /// 依新增表單狀態呈現名稱型或付款方式表單
    ///
    /// - Parameter addStore: 新增表單的 scoped store
    /// - Returns: 依新增種類建立的表單 view
    @ViewBuilder
    func addSheet(store addStore: StoreOf<LookupAddFormFeature>) -> some View {
        if addStore.state.hasClassification {
            PaymentMethodEditorSheet(
                title: store.state.kind.addFormTitle,
                message: store.state.kind.addFormMessage,
                namePlaceholder: store.state.kind.nameFieldPlaceholder,
                submitTitle: "orders.list.button.add"
            ) { name, isCardless, isBankTransfer, isCashOnDelivery in
                addStore.send(
                    .view(
                        .saveButtonTapped(
                            name: name,
                            flags: PaymentMethodFlags(
                                isCardless: isCardless,
                                isBankTransfer: isBankTransfer,
                                isCashOnDelivery: isCashOnDelivery
                            )
                        )
                    )
                )
            }
        } else {
            LookupNameEditorSheet(
                title: LocalizedStringKey(store.state.kind.addFormTitle),
                message: store.state.kind.addFormMessage,
                namePlaceholder: store.state.kind.nameFieldPlaceholder,
                submitTitle: "orders.list.button.add"
            ) {
                addStore.send(.view(.saveButtonTapped(name: $0, flags: .none)))
            }
        }
    }

    /// 建立改名表單並送出已驗證的新名稱
    ///
    /// - Parameter renameStore: 改名表單的 scoped store
    /// - Returns: 改名表單 view
    func renameSheet(store renameStore: StoreOf<LookupRenameFormFeature>) -> some View {
        LookupNameEditorSheet(
            title: renameSheetTitle,
            message: "orders.lookup.message.ordersReferencingName",
            namePlaceholder: store.state.kind.nameFieldPlaceholder,
            submitTitle: "orders.edit.button.save",
            initialName: renameStore.state.originalName
        ) {
            renameStore.send(.view(.saveButtonTapped(name: $0)))
        }
    }

    /// 建立付款方式編輯表單並送出名稱與旗標
    ///
    /// - Parameter editStore: 付款方式編輯表單的 scoped store
    /// - Returns: 付款方式編輯表單 view
    func paymentMethodEditSheet(store editStore: PaymentMethodEditStore) -> some View {
        PaymentMethodEditorSheet(
            title: "orders.lookup.label.editPaymentMethod",
            message: "orders.lookup.message.editNameTags",
            namePlaceholder: store.state.kind.nameFieldPlaceholder,
            submitTitle: "orders.edit.button.save",
            initialName: editStore.state.originalName,
            isInitialCardless: editStore.state.flags.isCardless,
            isInitialBankTransfer: editStore.state.flags.isBankTransfer,
            isInitialCashOnDelivery: editStore.state.flags.isCashOnDelivery
        ) { name, isCardless, isBankTransfer, isCashOnDelivery in
            editStore.send(
                .view(
                    .saveButtonTapped(
                        name: name,
                        flags: PaymentMethodFlags(
                            isCardless: isCardless,
                            isBankTransfer: isBankTransfer,
                            isCashOnDelivery: isCashOnDelivery
                        )
                    )
                )
            )
        }
    }
}

// MARK: - Nested Types

private extension LookupManagementView {

    /// 付款方式編輯表單使用的 scoped store
    typealias PaymentMethodEditStore = StoreOf<PaymentMethodEditFormFeature>
}

// MARK: - Private Method

private extension LookupManagementView {

    /// 依主檔種類回傳重新命名表單標題
    var renameSheetTitle: LocalizedStringKey {
        switch store.state.kind {
        case .orderSource:
            "orders.lookup.label.renameOrderSource"

        case .category:
            "orders.lookup.label.renameProductCategory"

        case .paymentMethod:
            "orders.lookup.label.renamePaymentMethod"

        case .reconciliationStatus:
            "orders.lookup.label.renameStatus"
        }
    }

    /// 通知 Feature 表單 sheet 關閉動畫已結束，讓暫存的提示接著顯示
    func sendFormSheetDismissed() {
        store.send(.view(.formSheetDismissed))
    }
}

// MARK: - Preview

#Preview("orders.lookup.label.itemCategories") {
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

#Preview("orders.detail.label.paymentMethods") {
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
                            name: "orders.edit.label.bankTransfer",
                            isCardless: false,
                            isBankTransfer: true,
                            isCashOnDelivery: false
                        ),
                        PaymentMethodInfo(
                            name: "orders.list.label.cashDelivery",
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
