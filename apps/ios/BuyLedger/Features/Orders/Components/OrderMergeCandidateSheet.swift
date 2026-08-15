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
    
    // MARK: - View Properties
    
    @Bindable var store: StoreOf<OrderMergeFeature>
    
    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale
    
    /// 候選清單使用的目前時間；測試可注入固定值
    @Dependency(\.date) private var date
    
    /// 候選清單日期分組所用的行事曆 (含時區)；測試可注入固定值
    @Dependency(\.calendar) private var calendar
    
    // MARK: - View Body
    
    /// 合併流程 sheet；候選選擇為根畫面
    var body: some View {
        NavigationStack(path: stepPath) {
            candidateList
                .navigationTitle(Text("合併訂單"))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button {
                            store.send(.cancelTapped)
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .accessibilityLabel(Text("取消"))
                        .accessibilityIdentifier(BLAccessibilityID.OrderMerge.cancelButton)
                    }
                }
                .navigationDestination(for: OrderMergeFeature.Step.self) { _ in
                    photoSelectionStep
                }
        }
        .alert($store.scope(state: \.photoLoadFailureAlert, action: \.photoLoadFailureAlert))
    }
}

// MARK: - ViewBuilder

private extension OrderMergeCandidateSheet {
    
    /// 照片挑選步驟；返回由系統 Back 處理
    @ViewBuilder
    var photoSelectionStep: some View {
        MergePhotoPickerSheet(store: store)
            .navigationTitle(Text("選擇保留照片"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("繼續") {
                        store.send(.photoStepConfirmTapped)
                    }
                    .accessibilityIdentifier(BLAccessibilityID.OrderMerge.photoContinueButton)
                }
            }
    }
    
    /// 候選訂單清單，依日期分組並支援搜尋
    @ViewBuilder
    var candidateList: some View {
        let sections = store.state.candidateSections(
            referenceDate: date.now,
            calendar: calendar,
            locale: locale
        )
        
        Group {
            if sections.isEmpty {
                ContentUnavailableView(
                    "沒有可合併的訂單",
                    systemImage: "tray",
                    description: Text("僅能與同幣別、同客戶且非「已合併」「已取消」的訂單合併。")
                )
                .accessibilityIdentifier(BLAccessibilityID.OrderMerge.candidateListEmptyState)
            } else {
                List {
                    ForEach(sections) { section in
                        Section {
                            ForEach(section.orders) { order in
                                candidateRow(order)
                            }
                        } header: {
                            Text(LocalizedStringKey(section.title))
                        } footer: {
                            if section.id == sections.last?.id {
                                Text(
                                    """
                                    僅列出與主訂單同幣別 (\(store.primary.currency.rawValue))、\
                                    同客戶「\(store.primary.customer.name)」的訂單；\
                                    選擇後會以兩筆訂單整合的資料開啟確認表單。
                                    """
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
            prompt: Text("搜尋")
        )
    }
    
    /// 候選訂單 row，顯示客戶實付
    /// - Parameter order: 該列代表的候選訂單
    /// - Returns: 候選列 view
    @ViewBuilder
    func candidateRow(_ order: LedgerOrder) -> some View {
        Button {
            store.send(.candidateTapped(order.id))
        } label: {
            OrderRowView(order: order, showsDate: false, trailing: .chargedAmount)
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
        Binding(
            get: { store.step == .selectPhotos ? [.selectPhotos] : [] },
            set: { newPath in
                if newPath.isEmpty, store.step == .selectPhotos {
                    store.send(.backToCandidatesTapped)
                }
            }
        )
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
