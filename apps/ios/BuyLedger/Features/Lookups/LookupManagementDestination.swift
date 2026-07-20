//
//  LookupManagementDestination.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import ComposableArchitecture
import Foundation

// MARK: - Destination

extension LookupManagementFeature {

    /// 改名 / 編輯付款方式的呈現目的地
    ///
    /// 兩個 case 分別取代 ``LookupManagementView`` 原本以 view-local `@State` (`renameTarget`／`renameDraft`／`editTarget`) 驅動的兩個流程
    ///
    /// 改由此處的 `@Presents` 狀態擁有，並由 reducer 在呈現當下自 ``State/paymentMethodIsCardless`` 等主檔字典快照初值，取代 view 直接索引字典組裝表單初值
    @Reducer
    enum Destination {

        /// 重新命名 (訂單來源／商品類別／付款方式／對帳狀態皆適用)
        case rename(RenameFeature)

        /// 編輯付款方式 (含 `isCardless`／`isBankTransfer`／`isCashOnDelivery` 三個旗標快照)；僅 `kind == .paymentMethod` 使用
        case editPaymentMethod(EditPaymentMethodFeature)

        /// 新增純名稱主檔項目 (訂單來源／商品類別／對帳狀態)
        case addNameOnly(AddNameOnlyFeature)

        /// 新增付款方式 (需同時決定三個旗標，故走獨立表單)
        case addPaymentMethod(AddPaymentMethodFeature)
    }
}

extension LookupManagementFeature.Destination.State: Equatable {}
extension LookupManagementFeature.Destination.Action: Equatable {}

// MARK: - Rename Feature

extension LookupManagementFeature.Destination {

    /// 重新命名表單狀態與事件
    @Reducer
    struct RenameFeature {

        // MARK: - State

        /// 重新命名表單狀態
        @ObservableState
        struct State: Equatable {

            /// 原始名稱
            let originalName: String

            /// 使用者輸入的新名稱草稿
            var draft: String

            // MARK: - Computed Properties

            /// 是否可儲存：草稿 trim 後非空，且與原始名稱不同 (對齊 ``LookupManagementFeature/Action/renameRequested(from:to:)`` 的既有 guard 邏輯)
            var canSave: Bool {
                let trimmed = draft.trimmingCharacters(in: .whitespacesAndNewlines)
                return !trimmed.isEmpty && trimmed != originalName
            }
        }

        // MARK: - Action

        /// 重新命名表單可處理的事件
        enum Action: Equatable {

            /// 使用者編輯草稿文字
            case draftChanged(String)

            /// 使用者按下「儲存」；由父層 ``LookupManagementFeature`` 攔截並轉送 ``LookupManagementFeature/Action/renameRequested(from:to:)``
            case saveButtonTapped
        }

        // MARK: - Reducer Body

        /// 重新命名表單 reducer；僅負責草稿文字更新，實際改名 domain effect 由父層攔截 `saveButtonTapped` 處理
        var body: some Reducer<State, Action> {
            Reduce { state, action in
                switch action {
                case let .draftChanged(draft):
                    state.draft = draft
                    return .none

                case .saveButtonTapped:
                    return .none
                }
            }
        }
    }
}

// MARK: - Edit Payment Method Feature

extension LookupManagementFeature.Destination {

    /// 編輯付款方式表單狀態與事件
    @Reducer
    struct EditPaymentMethodFeature {

        // MARK: - State

        /// 編輯付款方式表單狀態；三個旗標為進入編輯當下自主檔字典快照的初值。表單內的即時編輯留在 ``PaymentMethodEditorSheet`` 的 view-local `@State`，僅在使用者按下儲存時把最終值一次帶出
        @ObservableState
        struct State: Equatable {

            /// 原始付款方式名稱
            let originalName: String

            /// 進入編輯當下的「無卡」旗標快照
            let isCardless: Bool

            /// 進入編輯當下的「銀行匯款」旗標快照
            let isBankTransfer: Bool

            /// 進入編輯當下的「貨到付款」旗標快照
            let isCashOnDelivery: Bool
        }

        // MARK: - Action

        /// 編輯付款方式表單可處理的事件
        enum Action: Equatable {

            /// 使用者按下「儲存」，帶出表單最終值；由父層 ``LookupManagementFeature`` 攔截並轉送 ``LookupManagementFeature/Action/editConfirmed(originalName:name:isCardless:isBankTransfer:isCashOnDelivery:)``
            case saveButtonTapped(name: String, isCardless: Bool, isBankTransfer: Bool, isCashOnDelivery: Bool)
        }

        // MARK: - Reducer Body

        /// 編輯付款方式表單 reducer；本身不持有可變狀態，實際編輯 domain effect 由父層攔截 `saveButtonTapped` 處理
        var body: some Reducer<State, Action> {
            Reduce { _, _ in
                .none
            }
        }
    }
}

// MARK: - Add Name Only Feature

extension LookupManagementFeature.Destination {

    /// 新增純名稱主檔項目的表單狀態與事件
    ///
    /// 本身不持有可變狀態：名稱草稿留在 ``LookupNameEditorSheet`` 的 view-local `@State`，
    /// 僅在使用者按下新增時把最終值一次帶出
    @Reducer
    struct AddNameOnlyFeature {

        // MARK: - State

        /// 新增表單狀態
        @ObservableState
        struct State: Equatable {}

        // MARK: - Action

        /// 新增表單可處理的事件
        enum Action: Equatable {

            /// 使用者按下「新增」，帶出名稱；由父層 ``LookupManagementFeature`` 攔截並轉送 ``LookupManagementFeature/Action/addConfirmed(name:isCardless:isBankTransfer:isCashOnDelivery:)``
            case saveButtonTapped(name: String)
        }

        // MARK: - Reducer Body

        /// 新增表單 reducer；實際寫入 domain effect 由父層攔截 `saveButtonTapped` 處理
        var body: some Reducer<State, Action> {
            Reduce { _, _ in
                .none
            }
        }
    }
}

// MARK: - Add Payment Method Feature

extension LookupManagementFeature.Destination {

    /// 新增付款方式的表單狀態與事件
    ///
    /// 本身不持有可變狀態：表單內的即時編輯留在 ``PaymentMethodEditorSheet`` 的 view-local `@State`
    @Reducer
    struct AddPaymentMethodFeature {

        // MARK: - State

        /// 新增付款方式表單狀態
        @ObservableState
        struct State: Equatable {}

        // MARK: - Action

        /// 新增付款方式表單可處理的事件
        enum Action: Equatable {

            /// 使用者按下「新增」，帶出表單最終值
            case saveButtonTapped(name: String, isCardless: Bool, isBankTransfer: Bool, isCashOnDelivery: Bool)
        }

        // MARK: - Reducer Body

        /// 新增付款方式表單 reducer；實際寫入 domain effect 由父層攔截 `saveButtonTapped` 處理
        var body: some Reducer<State, Action> {
            Reduce { _, _ in
                .none
            }
        }
    }
}
