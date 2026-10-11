//
//  OrderMergeCandidateSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/6.
//

import ComposableArchitecture
import SwiftUI

/// 合併候選與照片挑選的 sheet
struct OrderMergeCandidateSheet: View {

    // MARK: - Properties

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<OrderMergeFeature>

    // MARK: - Body

    /// 合併流程 sheet；候選選擇為根畫面
    var body: some View {
        NavigationStack(path: stepPath) {
            candidateList
                .navigationTitle(Text("orders.detail.label.mergeOrders"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        cancelButton
                    }
                }
                .navigationDestination(for: OrderMergeFeature.Step.self) { _ in
                    photoSelectionStep
                }
        }
        .alert($store.scope(state: \.photoLoadFailureAlert, action: \.photoLoadFailureAlert))
    }
}

// MARK: - Private Views

private extension OrderMergeCandidateSheet {

    /// 關閉整個合併流程的工具列按鈕
    var cancelButton: some View {
        Button {
            store.send(.view(.cancelTapped))
        } label: {
            Image(systemName: "xmark")
        }
        .accessibilityLabel(Text("common.action.cancel"))
        .accessibilityIdentifier(BLAccessibilityID.OrderMerge.cancelButton)
    }

    /// 確認目前保留照片的工具列按鈕
    var continueButton: some View {
        Button("orders.list.button.continue") {
            store.send(.view(.photoStepConfirmTapped))
        }
        .accessibilityIdentifier(BLAccessibilityID.OrderMerge.photoContinueButton)
    }

    /// 照片挑選步驟；返回由系統導覽處理
    var photoSelectionStep: some View {
        MergePhotoPickerSheet(store: store)
            .navigationTitle(Text("orders.merge.label.keepPhotos"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    continueButton
                }
            }
    }

    /// 候選訂單清單，依日期分組並支援搜尋
    @ViewBuilder
    var candidateList: some View {
        let sections = store.state.candidateSections(locale: locale)

        Group {
            if sections.isEmpty {
                ContentUnavailableView(
                    "orders.merge.label.ordersAvailableMerge",
                    systemImage: "tray",
                    description: Text("orders.merge.message.ordersOnlyMerged")
                )
                .accessibilityIdentifier(BLAccessibilityID.OrderMerge.candidateListEmptyState)
            } else {
                List {
                    ForEach(sections) { section in
                        Section {
                            ForEach(section.orders) {
                                candidateRow($0)
                            }
                        } header: {
                            Text(LocalizedStringKey(section.title))
                        } footer: {
                            if section.id == sections.last?.id {
                                Text(
                                    AppLanguage.format(
                                        "orders.merge.message.candidateFilterNotice",
                                        store.primary.currency.rawValue,
                                        store.primary.customer.name,
                                        locale: locale
                                    )
                                )
                                .blTextStyle(.footnote)
                                .foregroundStyle(Color.blSecondaryLabel)
                            }
                        }
                    }
                }
                .accessibilityIdentifier(BLAccessibilityID.OrderMerge.candidateListRoot)
            }
        }
        .searchable(
            text: $store.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text("common.action.action.search")
        )
    }

    /// 顯示候選訂單列，並列出客戶實付
    ///
    /// - Parameter order: 該列代表的候選訂單
    /// - Returns: 可點選的候選訂單列
    func candidateRow(_ order: LedgerOrder) -> some View {
        Button {
            store.send(.view(.candidateTapped(order.id)))
        } label: {
            OrderRowView(order: order, isShowingDate: false, trailing: .chargedAmount)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(BLAccessibilityID.OrderMerge.candidateRow(orderID: order.id))
    }
}

// MARK: - Private Method

private extension OrderMergeCandidateSheet {

    /// 合併流程的導覽路徑
    var stepPath: Binding<[OrderMergeFeature.Step]> {
        Binding {
            store.step == .selectPhotos ? [.selectPhotos] : []
        } set: { newPath in
            if newPath.isEmpty, store.step == .selectPhotos {
                store.send(.view(.backToCandidatesTapped))
            }
        }
    }
}

// MARK: - Preview

#Preview("候選選擇") {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()

    OrderMergeCandidateSheet(
        store: Store(
            initialState: OrderMergeFeature.State(
                primary: LedgerOrder.sampleOrders[0],
                orders: LedgerOrder.sampleOrders,
                dateContext: OrderDateContext(
                    now: LedgerOrder.sampleOrders[0].date,
                    calendar: calendar
                )
            )
        ) {
            OrderMergeFeature()
        }
    )
}
