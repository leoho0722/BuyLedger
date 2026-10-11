//
//  OrderEditPickerDestination.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import SwiftUI

/// 訂單選項與照片檢視的導覽目的地
struct OrderEditPickerDestination: View {

    // MARK: - Properties

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// 畫面的狀態與事件來源，由父層建立後傳入
    let store: StoreOf<OrderEditFeature>

    /// 目前呈現的選擇器或照片檢視路徑
    let route: OrderEditPickersFeature.State.PickerRoute

    // MARK: - Body

    /// 組合區段或元件的內容
    var body: some View {
        pickerDestination(for: route)
    }
}

// MARK: - Private Views

private extension OrderEditPickerDestination {

    /// 依路徑建立嵌入式選項選擇器或照片檢視
    ///
    /// - Parameter route: 目前推入的目的地路徑
    /// - Returns: 對應的選擇器或照片檢視畫面
    @ViewBuilder
    func pickerDestination(for route: OrderEditPickersFeature.State.PickerRoute) -> some View {
        switch route {
        case .orderSource:
            OptionPickerSheet(
                title: "orders.edit.label.selectOrderSource",
                addButtonTitle: "orders.edit.label.addSource",
                emptyTitle: "orders.edit.label.sources",
                emptyDescription: "orders.edit.message.addFirstOrder",
                addAlertTitle: "orders.edit.label.addOrderSource",
                addFieldPlaceholder: "orders.edit.label.sourceName",
                addAlertMessage: "orders.edit.message.enterNewOrder",
                options: pickerStore.availableOrderSources,
                selected: store.draft.orderSource,
                onSelect: {
                    pickerStore.send(.view(.orderSourceSelected($0)))
                },
                onAdd: {
                    pickerStore.send(.view(.addOrderSourceTapped($0)))
                },
                isEmbedded: true
            )

        case .category:
            if store.isMergeContext {
                // 合併時使用多選模式
                OptionPickerSheet(
                    title: "orders.list.label.category1",
                    addButtonTitle: "orders.edit.label.addCategory",
                    emptyTitle: "orders.edit.label.categories",
                    emptyDescription: "orders.edit.message.addFirstCategory",
                    addAlertTitle: "orders.edit.label.addItemCategory",
                    addFieldPlaceholder: "orders.edit.label.categoryName",
                    addAlertMessage: "orders.edit.message.enterNewProduct",
                    options: pickerStore.availableCategories,
                    onAdd: {
                        pickerStore.send(.view(.addCategoryTapped($0)))
                    },
                    multiSelection: .init(
                        selections: Set(store.draft.categories),
                        onToggle: {
                            pickerStore.send(.view(.categoryToggled($0)))
                        }
                    ),
                    isEmbedded: true
                )
            } else {
                OptionPickerSheet(
                    title: "orders.list.label.category1",
                    addButtonTitle: "orders.edit.label.addCategory",
                    emptyTitle: "orders.edit.label.categories",
                    emptyDescription: "orders.edit.message.addFirstCategory",
                    addAlertTitle: "orders.edit.label.addItemCategory",
                    addFieldPlaceholder: "orders.edit.label.categoryName",
                    addAlertMessage: "orders.edit.message.enterNewProduct",
                    options: pickerStore.availableCategories,
                    selected: store.draft.categories.first ?? "",
                    onSelect: {
                        pickerStore.send(.view(.categorySelected($0)))
                    },
                    onAdd: {
                        pickerStore.send(.view(.addCategoryTapped($0)))
                    },
                    isEmbedded: true
                )
            }

        case .campaign:
            OptionPickerSheet(
                title: "orders.edit.label.selectCampaigns",
                allowsAdd: false,
                emptyTitle: "orders.edit.label.campaigns",
                emptyDescription: "orders.edit.message.createCampaignCampaigns",
                options: pickerStore.availableCampaigns,
                multiSelection: .init(
                    selections: Set(store.draft.campaignNames),
                    onToggle: {
                        pickerStore.send(.view(.campaignToggled($0)))
                    }
                ),
                isEmbedded: true
            )

        case .paymentMethod:
            OptionPickerSheet(
                title: "orders.list.label.selectPaymentMethod",
                addButtonTitle: "orders.edit.label.addPaymentMethod",
                emptyTitle: "orders.edit.label.paymentMethods",
                emptyDescription: "orders.edit.message.addFirstPayment",
                addAlertTitle: "orders.edit.label.addPaymentMethod",
                addFieldPlaceholder: "orders.detail.label.paymentMethodName",
                addAlertMessage: "orders.edit.message.enterNewPayment",
                options: pickerStore.availablePaymentMethods.map(\.name),
                selected: store.draft.paymentMethod,
                onSelect: {
                    pickerStore.send(.view(.paymentMethodSelected($0)))
                },
                onAddPaymentMethod: { name, isCardless, isBankTransfer, isCashOnDelivery in
                    pickerStore.send(
                        .view(
                            .addPaymentMethodTapped(
                                name: name,
                                flags: PaymentMethodFlags(
                                    isCardless: isCardless,
                                    isBankTransfer: isBankTransfer,
                                    isCashOnDelivery: isCashOnDelivery
                                )
                            )
                        )
                    )
                },
                isEmbedded: true
            )

        case .reconciliationStatus:
            OptionPickerSheet(
                title: "orders.edit.label.reconciliationStatus2",
                addButtonTitle: "orders.edit.label.addStatus",
                emptyTitle: "orders.edit.label.reconciliationStatuses",
                emptyDescription: "orders.edit.message.addFirstReconciliation",
                addAlertTitle: "orders.edit.label.addStatus",
                addFieldPlaceholder: "orders.edit.label.reconciliationStatusName",
                addAlertMessage: "orders.edit.message.enterNewReconciliation",
                options: pickerStore.availableReconciliationStatuses,
                selected: store.draft.reconciliationStatus,
                onSelect: {
                    pickerStore.send(.view(.reconciliationStatusSelected($0)))
                },
                onAdd: {
                    pickerStore.send(.view(.addReconciliationStatusTapped($0)))
                },
                isEmbedded: true
            )

        case .currency:
            let locale = locale
            let language = AppLanguage(locale: locale)

            OptionPickerSheet(
                title: "orders.edit.label.selectCurrency",
                allowsAdd: false,
                searchable: true,
                emptyTitle: "orders.edit.label.currenciesAvailable",
                emptyDescription: "orders.edit.message.internetConnectionRequired",
                options: pickerStore.availableCurrencies.map(\.rawValue),
                selected: store.draft.currency.rawValue,
                displayName: {
                    CurrencyDisplayName.text(code: $0, language: language)
                },
                searchKeywords: {
                    CurrencyDisplayName.searchKeywords(code: $0, locale: locale)
                },
                onSelect: {
                    pickerStore.send(.view(.currencySelected($0)))
                },
                isEmbedded: true
            )

        case .photoViewer(let index):
            // 照片與選項共用導覽堆疊，返回時由宿主的 `pickerPath` 綁定清空路徑
            BLPhotoViewer(photos: store.photos.draftPhotos, initialIndex: index)
        }
    }
}

// MARK: - Private Method

private extension OrderEditPickerDestination {

    /// 只負責選項清單、選擇器路由與選取請求的子 store
    var pickerStore: StoreOf<OrderEditPickersFeature> {
        store.scope(state: \.pickers, action: \.pickers)
    }
}

// MARK: - Preview

#Preview {
    if let id = UUID(uuidString: "00000000-0000-0000-0000-000000000000") {
        Form {
            OrderEditPickerDestination(
                store: Store(
                    initialState: OrderEditFeature.State(
                        id: id,
                        currentDate: Date(timeIntervalSince1970: 0)
                    )
                ) {
                    OrderEditFeature()
                },
                route: .orderSource
            )
        }
    }
}
