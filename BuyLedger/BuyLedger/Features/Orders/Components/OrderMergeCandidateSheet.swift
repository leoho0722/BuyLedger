//
//  OrderMergeCandidateSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/6.
//

import ComposableArchitecture
import SwiftUI

/// 「合併訂單」流程的 sheet 容器：候選選擇步驟列出可合併訂單，照片超限時切換到 ``MergePhotoPickerSheet``。
///
/// 候選清單僅列與主訂單同幣別、同客戶名稱且狀態非「已合併」「已取消」的訂單 (由 ``OrderMergeFeature/State`` 過濾)；每列顯示客戶名稱、訂購日期與客戶實付，支援即時搜尋。
struct OrderMergeCandidateSheet: View {

    // MARK: - View Properties

    @Bindable var store: StoreOf<OrderMergeFeature>

    // MARK: - View Body

    /// 合併流程 sheet 的內容；navigation 標題與 toolbar 依步驟切換。
    var body: some View {
        NavigationStack {
            content
                .navigationTitle(store.step == .selectCandidate ? "合併訂單" : "選擇保留照片")
#if !os(macOS)
                .navigationBarTitleDisplayMode(.inline)
#endif
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") {
                            store.send(.cancelTapped)
                        }
                    }

                    if store.step == .selectPhotos {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("繼續") {
                                store.send(.photoStepConfirmTapped)
                            }
                        }
                    }
                }
        }
#if os(macOS)
        .frame(minWidth: 420, minHeight: 520)
#endif
    }
}

// MARK: - ViewBuilder

private extension OrderMergeCandidateSheet {

    /// 依步驟切換內容：候選清單或照片挑選。
    @ViewBuilder
    var content: some View {
        switch store.step {
        case .selectCandidate:
            candidateList

        case .selectPhotos:
            MergePhotoPickerSheet(store: store)
        }
    }

    /// 候選訂單清單：含搜尋、空狀態與資格說明 footer。
    @ViewBuilder
    var candidateList: some View {
        Group {
            if store.filteredCandidates.isEmpty {
                ContentUnavailableView(
                    "沒有可合併的訂單",
                    systemImage: "tray",
                    description: Text("僅能與同幣別、同客戶且非「已合併」「已取消」的訂單合併。")
                )
            } else {
                List {
                    Section {
                        ForEach(store.filteredCandidates) { order in
                            candidateRow(order)
                        }
                    } footer: {
                        Text("僅列出與主訂單同幣別 (\(store.primary.currency.rawValue))、同客戶「\(store.primary.customer.name)」的訂單；選擇後會以兩筆訂單整合的資料開啟確認表單。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
#if os(macOS)
        .searchable(text: $store.searchText, prompt: Text("搜尋"))
#else
        .searchable(
            text: $store.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text("搜尋")
        )
#endif
    }

    /// 單筆候選訂單列：客戶名稱、訂購日期與單號、客戶實付。
    /// - Parameter order: 該列代表的候選訂單。
    /// - Returns: 候選列 view。
    @ViewBuilder
    func candidateRow(_ order: LedgerOrder) -> some View {
        Button {
            store.send(.candidateTapped(order.id))
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
                VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
                    Text(order.customer.name)
                        .font(.body)
                        .foregroundStyle(.primary)

                    Text("\(OrderFormatters.shortDate(order.date)) · \(order.id)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Spacer(minLength: BLSpacing.small)

                VStack(alignment: .trailing, spacing: BLSpacing.extraSmall) {
                    Text(OrderFormatters.twd(order.chargedAmount))
                        .font(.body)
                        .foregroundStyle(.primary)
                        .monospacedDigit()

                    Text("客戶實付")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("候選選擇") {
    OrderMergeCandidateSheet(
        store: Store(
            initialState: OrderMergeFeature.State(
                primary: LedgerOrder.sampleOrders[0],
                orders: LedgerOrder.sampleOrders
            )
        ) {
            OrderMergeFeature()
        }
    )
}
