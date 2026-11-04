//
//  LookupManagementPresentations.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/11/2.
//

import ComposableArchitecture
import SwiftUI

/// 主檔管理的表單與提示，由 `MoreView` 的分欄層掛載
///
/// - Note: 掛在分欄層而非詳情欄內，因為詳情欄內的呈現在分欄收合或展開時會被系統重新呈現，確認框與表單狀態會失效
struct LookupManagementPresentations: View {

    // MARK: - Properties

    /// 主檔管理的子 store，表單與提示的狀態由其 `destination` 與 `notice` 持有
    @Bindable var store: StoreOf<LookupManagementFeature>

    // MARK: - Body

    /// 不佔版面的宿主，只承載表單與提示的呈現
    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .allowsHitTesting(false)
            .sheet(
                item: $store.scope(state: \.$destination, action: \.destination).add,
                onDismiss: sendFormSheetDismissed
            ) {
                AddFormSheet(addStore: $0, kind: store.state.kind)
            }
            .sheet(
                item: $store.scope(state: \.$destination, action: \.destination).rename,
                onDismiss: sendFormSheetDismissed
            ) {
                RenameFormSheet(
                    renameStore: $0,
                    namePlaceholder: store.state.kind.nameFieldPlaceholder,
                    title: renameSheetTitle
                )
            }
            .sheet(
                item: $store.scope(state: \.$destination, action: \.destination).editPaymentMethod,
                onDismiss: sendFormSheetDismissed
            ) {
                PaymentMethodEditFormSheet(
                    editStore: $0,
                    namePlaceholder: store.state.kind.nameFieldPlaceholder
                )
            }
            .alert($store.scope(state: \.$destination, action: \.destination).alert)
            .alert($store.scope(state: \.$notice, action: \.notice))
    }
}

// MARK: - Nested Types

private extension LookupManagementPresentations {

    /// 新增主檔的表單 sheet，依主檔種類呈現名稱型或付款方式型；直接持有子 store 以即時反映草稿與旗標
    struct AddFormSheet: View {

        /// 新增表單的 scoped store，草稿與旗標由此讀寫
        @Bindable var addStore: StoreOf<LookupAddFormFeature>

        /// 主檔種類，決定標題、說明與佔位文字
        let kind: LookupKind

        /// 依新增表單是否含付款方式分類呈現對應的表單
        var body: some View {
            if addStore.hasClassification {
                PaymentMethodEditorSheet(
                    title: kind.addFormTitle,
                    message: kind.addFormMessage,
                    namePlaceholder: kind.nameFieldPlaceholder,
                    submitTitle: "orders.list.button.add",
                    draftName: $addStore.draftName,
                    isDraftCardless: $addStore.isDraftCardless,
                    isDraftBankTransfer: $addStore.isDraftBankTransfer,
                    isDraftCashOnDelivery: $addStore.isDraftCashOnDelivery,
                    isNameFieldFocused: $addStore.isNameFieldFocused,
                    isDiscardConfirmationPresented: $addStore.isDiscardConfirmationPresented,
                    isDirty: addStore.isDirty,
                    canSubmit: addStore.canSubmit,
                    onCancel: {
                        addStore.send(.view(.cancelButtonTapped))
                    },
                    onDiscardChanges: {
                        addStore.send(.view(.discardChangesButtonTapped))
                    },
                    onSubmit: {
                        addStore.send(
                            .view(
                                .saveButtonTapped(
                                    name: addStore.trimmedName,
                                    flags: addStore.draftFlags
                                )
                            )
                        )
                    }
                )
            } else {
                LookupNameEditorSheet(
                    title: LocalizedStringKey(kind.addFormTitle),
                    message: kind.addFormMessage,
                    namePlaceholder: kind.nameFieldPlaceholder,
                    submitTitle: "orders.list.button.add",
                    draftName: $addStore.draftName,
                    isNameFieldFocused: $addStore.isNameFieldFocused,
                    isDiscardConfirmationPresented: $addStore.isDiscardConfirmationPresented,
                    isDirty: addStore.isDirty,
                    canSubmit: addStore.canSubmit,
                    onCancel: {
                        addStore.send(.view(.cancelButtonTapped))
                    },
                    onDiscardChanges: {
                        addStore.send(.view(.discardChangesButtonTapped))
                    },
                    onSubmit: {
                        addStore.send(
                            .view(.saveButtonTapped(name: addStore.trimmedName, flags: .none))
                        )
                    }
                )
            }
        }
    }

    /// 改名主檔的表單 sheet，草稿與焦點由子 store 持有
    struct RenameFormSheet: View {

        /// 改名表單的 scoped store，草稿由此讀寫
        @Bindable var renameStore: StoreOf<LookupRenameFormFeature>

        /// 名稱欄位的佔位文字
        let namePlaceholder: String

        /// 導覽列標題，依主檔種類決定
        let title: LocalizedStringKey

        /// 呈現單欄名稱表單，取消、捨棄與送出都交給子 store 的 reducer 處理
        var body: some View {
            LookupNameEditorSheet(
                title: title,
                message: "orders.lookup.message.ordersReferencingName",
                namePlaceholder: namePlaceholder,
                submitTitle: "orders.edit.button.save",
                draftName: $renameStore.draftName,
                isNameFieldFocused: $renameStore.isNameFieldFocused,
                isDiscardConfirmationPresented: $renameStore.isDiscardConfirmationPresented,
                isDirty: renameStore.isDirty,
                canSubmit: renameStore.canSubmit,
                onCancel: {
                    renameStore.send(.view(.cancelButtonTapped))
                },
                onDiscardChanges: {
                    renameStore.send(.view(.discardChangesButtonTapped))
                },
                onSubmit: {
                    renameStore.send(.view(.saveButtonTapped(name: renameStore.trimmedName)))
                }
            )
        }
    }

    /// 編輯付款方式的表單 sheet，草稿、旗標與焦點由子 store 持有
    struct PaymentMethodEditFormSheet: View {

        /// 付款方式編輯表單的 scoped store，草稿與旗標由此讀寫
        @Bindable var editStore: StoreOf<PaymentMethodEditFormFeature>

        /// 名稱欄位的佔位文字
        let namePlaceholder: String

        /// 呈現付款方式編輯表單，取消、捨棄與送出都交給子 store 的 reducer 處理
        var body: some View {
            PaymentMethodEditorSheet(
                title: "orders.lookup.label.editPaymentMethod",
                message: "orders.lookup.message.editNameTags",
                namePlaceholder: namePlaceholder,
                submitTitle: "orders.edit.button.save",
                draftName: $editStore.draftName,
                isDraftCardless: $editStore.isDraftCardless,
                isDraftBankTransfer: $editStore.isDraftBankTransfer,
                isDraftCashOnDelivery: $editStore.isDraftCashOnDelivery,
                isNameFieldFocused: $editStore.isNameFieldFocused,
                isDiscardConfirmationPresented: $editStore.isDiscardConfirmationPresented,
                isDirty: editStore.isDirty,
                canSubmit: editStore.canSubmit,
                onCancel: {
                    editStore.send(.view(.cancelButtonTapped))
                },
                onDiscardChanges: {
                    editStore.send(.view(.discardChangesButtonTapped))
                },
                onSubmit: {
                    editStore.send(
                        .view(
                            .saveButtonTapped(
                                name: editStore.trimmedName,
                                flags: editStore.draftFlags
                            )
                        )
                    )
                }
            )
        }
    }
}

// MARK: - Private Method

private extension LookupManagementPresentations {

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
