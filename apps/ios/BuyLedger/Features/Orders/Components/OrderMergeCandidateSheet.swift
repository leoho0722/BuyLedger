//
//  OrderMergeCandidateSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/6.
//

import ComposableArchitecture
import SwiftUI

/// 「合併訂單」流程的 sheet 容器：候選選擇步驟列出可合併訂單，照片超限時切換到 ``MergePhotoPickerSheet``
///
/// 候選清單僅列與主訂單同幣別、同客戶名稱且狀態非「已合併」「已取消」的訂單 (由 ``OrderMergeFeature/State`` 過濾)
///
/// 並比照訂單頁以訂購日分組 (section 標題為今天/昨天/格式化日期)；每列重用訂單頁的 ``OrderRowView`` 版面、右欄改顯示客戶實付，支援即時搜尋
struct OrderMergeCandidateSheet: View {

    // MARK: - View Properties

    @Bindable var store: StoreOf<OrderMergeFeature>

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 用於 ``OrderMergeFeature/State/candidateSections(referenceDate:calendar:)`` 的「現在」時間；測試可注入固定值
    @Dependency(\.date) private var date

    /// 候選清單日期分組所用的行事曆 (含時區)；測試可注入固定值
    @Dependency(\.calendar) private var calendar

    // MARK: - View Body

    /// 合併流程 sheet：候選選擇為 root、照片挑選步驟以 `navigationDestination(for:)` push
    ///
    /// 多步驟採真 navigation push：前進與返回都有系統原生 push／pop 動畫，返回由原生 Back 處理 (帶 pop 動畫，取代自製按鈕，亦符合 HIG「後續步驟以 Back 取代 Cancel」)
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
                    }
                }
                .navigationDestination(for: OrderMergeFeature.Step.self) { _ in
                    photoSelectionStep
                }
        }
    }
}

// MARK: - ViewBuilder

private extension OrderMergeCandidateSheet {

    /// 照片挑選步驟 (push 目的地)：照片挑選內容 + 標題 +「繼續」；返回由系統原生 Back 處理 (帶 pop 動畫)
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
                }
            }
    }

    /// 候選訂單清單：比照訂單頁以訂購日分組 (section 標題為今天/昨天/格式化日期)，含搜尋、空狀態與資格說明 footer (掛於最後一段)
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
                                Text("僅列出與主訂單同幣別 (\(store.primary.currency.rawValue))、同客戶「\(store.primary.customer.name)」的訂單；選擇後會以兩筆訂單整合的資料開啟確認表單。")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .searchable(
            text: $store.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: Text("搜尋")
        )
    }

    /// 單筆候選訂單列：重用訂單頁的 ``OrderRowView`` 版面，右欄以 ``OrderRowView/Trailing/chargedAmount`` 變體顯示客戶實付
    ///
    /// 左欄 (頭像、客戶名稱、商品明細、類別 tag) 與訂單頁完全一致——比訂單編號更易辨識要合併哪筆訂單
    ///
    /// 日期由 section 標題提供故列內不重複，狀態與損益對挑選候選參考價值低，故右欄改顯示對應合併金額逐項加總的客戶實付
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
    }
}

// MARK: - Private Method

private extension OrderMergeCandidateSheet {

    /// 合併流程 `NavigationStack` 的 push 路徑：把 ``OrderMergeFeature/Step`` 映射成 0 或 1 元素的路徑陣列
    ///
    /// 使用者點系統原生 Back pop 到空路徑時，經此 setter 送 ``OrderMergeFeature/Action/backToCandidatesTapped`` 返回候選步驟並清照片暫存
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
