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
                title: "選擇訂單來源",
                addButtonTitle: "新增來源",
                emptyTitle: "尚無來源",
                emptyDescription: "透過上方「新增來源」加入第一個訂單來源。",
                addAlertTitle: "新增訂單來源",
                addFieldPlaceholder: "來源名稱",
                addAlertMessage: "輸入新的訂單來源名稱，加入後會立即套用至此訂單。",
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
                    title: "選擇商品類別",
                    addButtonTitle: "新增類別",
                    emptyTitle: "尚無類別",
                    emptyDescription: "透過上方「新增類別」加入第一個類別。",
                    addAlertTitle: "新增商品類別",
                    addFieldPlaceholder: "類別名稱",
                    addAlertMessage: "輸入新的商品類別名稱，加入後會立即套用至此訂單。",
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
                    title: "選擇商品類別",
                    addButtonTitle: "新增類別",
                    emptyTitle: "尚無類別",
                    emptyDescription: "透過上方「新增類別」加入第一個類別。",
                    addAlertTitle: "新增商品類別",
                    addFieldPlaceholder: "類別名稱",
                    addAlertMessage: "輸入新的商品類別名稱，加入後會立即套用至此訂單。",
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
                title: "選擇開團",
                allowsAdd: false,
                emptyTitle: "尚無開團",
                emptyDescription: "請先在「開團」頁建立開團，再回到此處歸團。",
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
                title: "選擇付款方式",
                addButtonTitle: "新增付款方式",
                emptyTitle: "尚無付款方式",
                emptyDescription: "透過上方「新增付款方式」加入第一個項目。",
                addAlertTitle: "新增付款方式",
                addFieldPlaceholder: "付款方式名稱",
                addAlertMessage: "輸入新的付款方式名稱，加入後會立即套用至此訂單。",
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
                title: "選擇對帳狀態",
                addButtonTitle: "新增對帳狀態",
                emptyTitle: "尚無對帳狀態",
                emptyDescription: "透過上方「新增對帳狀態」加入第一個項目。",
                addAlertTitle: "新增對帳狀態",
                addFieldPlaceholder: "對帳狀態名稱",
                addAlertMessage: "輸入新的對帳狀態名稱，加入後會立即套用至此訂單。",
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
                title: "選擇幣別",
                allowsAdd: false,
                searchable: true,
                emptyTitle: "尚無幣別",
                emptyDescription: "需要網路連線載入幣別清單；請稍後再試。",
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
