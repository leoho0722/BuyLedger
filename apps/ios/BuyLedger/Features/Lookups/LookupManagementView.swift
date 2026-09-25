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

    /// 畫面的狀態與事件來源，由父層或 App 進入點建立後傳入
    @Bindable var store: StoreOf<LookupManagementFeature>

    // MARK: - Body

    /// 顯示主檔清單與操作入口
    var body: some View {
        LookupItemList(
            classificationForName: { name in
                store.state.classification(for: name)
            },
            hasLoadFailed: store.hasLoadFailed,
            items: store.items,
            kind: store.state.kind
        ) { name in
            store.send(.view(.deleteButtonTapped(name: name)))
        } onEditPaymentMethod: { name in
            store.send(.view(.editButtonTapped(name: name)))
        } onRename: { name in
            store.send(.view(.renameButtonTapped(name: name)))
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
        ) { addStore in
            addSheet(store: addStore)
        }
        .sheet(
            item: $store.scope(state: \.$destination, action: \.destination).rename,
            onDismiss: sendFormSheetDismissed
        ) { renameStore in
            renameSheet(store: renameStore)
        }
        .sheet(
            item: $store.scope(
                state: \.$destination,
                action: \.destination
            ).editPaymentMethod,
            onDismiss: sendFormSheetDismissed
        ) { editStore in
            paymentMethodEditSheet(store: editStore)
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
            Label(
                LocalizedStringKey(store.state.kind.addButtonTitle),
                systemImage: "plus"
            )
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
                submitTitle: "新增"
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
                submitTitle: "新增"
            ) { name in
                addStore.send(.view(.saveButtonTapped(name: name, flags: .none)))
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
            message: "改名後，引用此名稱的訂單也會一併更新。",
            namePlaceholder: store.state.kind.nameFieldPlaceholder,
            submitTitle: "儲存",
            initialName: renameStore.state.originalName
        ) { name in
            renameStore.send(.view(.saveButtonTapped(name: name)))
        }
    }

    /// 建立付款方式編輯表單並送出名稱與旗標
    ///
    /// - Parameter editStore: 付款方式編輯表單的 scoped store
    /// - Returns: 付款方式編輯表單 view
    func paymentMethodEditSheet(store editStore: PaymentMethodEditStore) -> some View {
        PaymentMethodEditorSheet(
            title: "編輯付款方式",
            message: "修改名稱與分類；變更名稱會一併更新引用此付款方式的訂單。",
            namePlaceholder: store.state.kind.nameFieldPlaceholder,
            submitTitle: "儲存",
            initialName: editStore.state.originalName,
            initialIsCardless: editStore.state.flags.isCardless,
            initialIsBankTransfer: editStore.state.flags.isBankTransfer,
            initialIsCashOnDelivery: editStore.state.flags.isCashOnDelivery
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
            "重新命名訂單來源"

        case .category:
            "重新命名商品類別"

        case .paymentMethod:
            "重新命名付款方式"

        case .reconciliationStatus:
            "重新命名對帳狀態"
        }
    }

    /// 表單 sheet 關閉動畫結束後通知 Feature，讓暫存的提示接著顯示
    func sendFormSheetDismissed() {
        store.send(.view(.formSheetDismissed))
    }
}

// MARK: - Preview

#Preview("商品類別管理") {
    NavigationStack {
        LookupManagementView(
            store: {
                var state = LookupManagementFeature.State(kind: .category)
                state.$catalog.withLock { $0.categories = ["服飾", "美妝", "精品"] }
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
                state.$catalog.withLock { catalog in
                    catalog.paymentMethods = [
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
                state.$catalog.withLock { $0.categories = [] }
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
                state.$catalog.withLock { $0.categories = [] }
                state.hasLoadFailed = true
                state.hasLoaded = true
                return Store(initialState: state) {
                    LookupManagementFeature()
                }
            }()
        )
    }
}
