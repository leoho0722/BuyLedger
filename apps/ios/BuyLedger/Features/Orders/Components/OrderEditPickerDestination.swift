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
    @Bindable var store: StoreOf<OrderEditFeature>

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
                options: pickerStore.options.orderSources,
                selection: .single(
                    selected: store.draft.orderSource,
                    onSelect: {
                        pickerStore.send(.view(.orderSourceSelected($0)))
                    }
                ),
                addition: .prompt(
                    .init(
                        buttonTitle: "orders.edit.label.addSource",
                        title: "orders.edit.label.addOrderSource",
                        message: "orders.edit.message.enterNewOrder",
                        placeholder: "orders.edit.label.sourceName"
                    )
                ) {
                    pickerStore.send(.view(.addOrderSourceTapped($0)))
                },
                emptyState: .init(
                    title: "orders.edit.label.sources",
                    description: "orders.edit.message.addFirstOrder"
                ),
                isEmbedded: true
            )

        case .category:
            OptionPickerSheet(
                title: "orders.list.label.category1",
                options: pickerStore.options.categories,
                selection: categorySelection,
                addition: .prompt(
                    .init(
                        buttonTitle: "orders.edit.label.addCategory",
                        title: "orders.edit.label.addItemCategory",
                        message: "orders.edit.message.enterNewProduct",
                        placeholder: "orders.edit.label.categoryName"
                    )
                ) {
                    pickerStore.send(.view(.addCategoryTapped($0)))
                },
                emptyState: .init(
                    title: "orders.edit.label.categories",
                    description: "orders.edit.message.addFirstCategory"
                ),
                isEmbedded: true
            )

        case .campaign:
            OptionPickerSheet(
                title: "orders.edit.label.selectCampaigns",
                options: pickerStore.options.campaigns,
                selection: .multiple(selections: Set(store.draft.campaignNames)) {
                    pickerStore.send(.view(.campaignToggled($0)))
                },
                emptyState: .init(
                    title: "orders.edit.label.campaigns",
                    description: "orders.edit.message.createCampaignCampaigns"
                ),
                isEmbedded: true
            )

        case .paymentMethod:
            OptionPickerSheet(
                title: "orders.list.label.selectPaymentMethod",
                options: pickerStore.options.paymentMethods.map(\.name),
                selection: .single(
                    selected: store.draft.paymentMethod,
                    onSelect: {
                        pickerStore.send(.view(.paymentMethodSelected($0)))
                    }
                ),
                addition: .paymentMethod(
                    .init(
                        buttonTitle: "orders.edit.label.addPaymentMethod",
                        title: "orders.edit.label.addPaymentMethod",
                        message: "orders.edit.message.enterNewPayment",
                        placeholder: "orders.detail.label.paymentMethodName"
                    )
                ) { name, isCardless, isBankTransfer, isCashOnDelivery in
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
                emptyState: .init(
                    title: "orders.edit.label.paymentMethods",
                    description: "orders.edit.message.addFirstPayment"
                ),
                isEmbedded: true
            )

        case .reconciliationStatus:
            OptionPickerSheet(
                title: "orders.edit.label.reconciliationStatus2",
                options: pickerStore.options.reconciliationStatuses,
                selection: .single(
                    selected: store.draft.reconciliationStatus,
                    onSelect: {
                        pickerStore.send(.view(.reconciliationStatusSelected($0)))
                    }
                ),
                addition: .prompt(
                    .init(
                        buttonTitle: "orders.edit.label.addStatus",
                        title: "orders.edit.label.addStatus",
                        message: "orders.edit.message.enterNewReconciliation",
                        placeholder: "orders.edit.label.reconciliationStatusName"
                    )
                ) {
                    pickerStore.send(.view(.addReconciliationStatusTapped($0)))
                },
                emptyState: .init(
                    title: "orders.edit.label.reconciliationStatuses",
                    description: "orders.edit.message.addFirstReconciliation"
                ),
                isEmbedded: true
            )

        case .currency:
            OptionPickerSheet(
                title: "orders.edit.label.selectCurrency",
                options: pickerStore.options.currencyCodes.map(\.rawValue),
                selection: .single(
                    selected: store.draft.currency.rawValue,
                    onSelect: {
                        pickerStore.send(.view(.currencySelected($0)))
                    }
                ),
                emptyState: .init(
                    title: "orders.edit.label.currenciesAvailable",
                    description: "orders.edit.message.internetConnectionRequired"
                ),
                labeling: CurrencyDisplayName.optionLabeling(locale: locale),
                isSearchEnabled: true,
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

    /// 合併時使用多選模式，其餘情境使用單選
    var categorySelection: OptionPickerSheet.Selection {
        if store.isMergeContext {
            return .multiple(selections: Set(store.draft.categories)) {
                pickerStore.send(.view(.categoryToggled($0)))
            }
        }
        return .single(
            selected: store.draft.categories.first ?? "",
            onSelect: {
                pickerStore.send(.view(.categorySelected($0)))
            }
        )
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
