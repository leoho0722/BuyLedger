//
//  OrdersCompactView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

#if !os(macOS)

import ComposableArchitecture
import SwiftUI

/// iPhone (compact) 使用的訂單瀏覽畫面。
///
/// 採用 NavigationStack 配合自訂大標題、橫向滾動的狀態 chip 與卡片化的訂單列表，對應設計稿的 iPhone 訂單列表樣式。
struct OrdersCompactView: View {

    // MARK: - View Properties

    /// 訂單功能 store。
    @Bindable var store: StoreOf<OrdersFeature>

    /// 目前系統深淺色外觀。
    @Environment(\.colorScheme) private var colorScheme

    /// 用於 ``OrdersFeature/State/filteredOrders(referenceDate:calendar:)`` 的「現在」時間；測試可注入固定值。
    @Dependency(\.date) private var date

    /// 訂單篩選與日期分組所用的行事曆 (含時區)；測試可注入固定值。
    @Dependency(\.calendar) private var calendar

    /// iPhone NavigationStack 的瀏覽路徑。改用 path-driven binding，使訂單被刪除時可手動把對應 id 從 path 移除，觸發系統自動 pop 回列表。
    @State private var navigationPath: [LedgerOrder.ID] = []

    /// 整合篩選 sheet (日期 + 類別 + 付款方式) 是否呈現。點 trigger button 後設為 `true`，由 ``OrderFilterSheet`` 內部 dismiss 結束回 `false`。
    @State private var showsFilterSheet = false

    // MARK: - View Body

    /// 訂單瀏覽畫面內容。
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)

        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: BLSpacing.medium) {
                    BLSearchField(
                        placeholder: "搜尋客戶、單號或商品",
                        text: $store.searchText.sending(\.searchTextChanged)
                    )
                    .padding(.horizontal, BLSpacing.large)

                    chipStrip(palette: palette)
                    unifiedFilterTrigger(palette: palette)

                    if let errorMessage = store.errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(palette.red)
                            .padding(.horizontal, BLSpacing.large)
                    }

                    listSection(palette: palette)
                }
                .padding(.top, BLSpacing.small)
                .padding(.bottom, BLSpacing.section)
            }
            .background(palette.background)
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle("訂單")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Text("\(store.orders.count)")
                        .font(.subheadline.weight(.medium))
                        .monospacedDigit()
                        .foregroundStyle(palette.secondaryLabel)

                    Button {
                        store.send(.aiSummaryTapped)
                    } label: {
                        Image(systemName: "sparkles")
                    }
                    .accessibilityLabel("AI 商品明細總結")
                    .disabled(store.state.filteredOrders(referenceDate: date.now, calendar: calendar).isEmpty)

                    Button {
                        store.send(.newOrderTapped)
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("新增訂單")
                }
            }
            .navigationDestination(for: LedgerOrder.ID.self) { id in
                if let order = store.orders.first(where: { $0.id == id }) {
                    OrderDetailView(order: order)
                        .navigationTitle(order.customer.name)
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                Menu {
                                    ForEach(OrderStatus.allCases) { status in
                                        Button {
                                            store.send(.statusChanged(order.id, status))
                                        } label: {
                                            if status == order.status {
                                                Label(status.title, systemImage: "checkmark")
                                            } else {
                                                Text(status.title)
                                            }
                                        }
                                    }
                                } label: {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                }
                                .accessibilityLabel("更新狀態")
                            }

                            ToolbarItem(placement: .primaryAction) {
                                Button("編輯") {
                                    store.send(.editOrderTapped(order.id))
                                }
                            }

                            ToolbarItem(placement: .primaryAction) {
                                Button(role: .destructive) {
                                    store.send(.deleteOrderTapped(order.id))
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .accessibilityLabel("刪除訂單")
                            }
                        }
                }
            }
            .task {
                await store.send(.task).finish()
            }
            .onChange(of: store.orders) { _, newOrders in
                let availableIDs = Set(newOrders.map(\.id))
                navigationPath.removeAll { !availableIDs.contains($0) }
            }
            .sheet(isPresented: $showsFilterSheet) {
                OrderFilterSheet(store: store)
            }
        }
    }
}

// MARK: - ViewBuilder

private extension OrdersCompactView {

    /// 狀態篩選 chip 橫向滾動列。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: chip 列 view。
    @ViewBuilder
    func chipStrip(palette: BLPalette) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BLSpacing.small) {
                ForEach(OrderStatusFilter.orderBrowsingCases) { filter in
                    chipButton(filter, palette: palette)
                }
            }
            .padding(.horizontal, BLSpacing.large)
        }
    }

    /// 單一狀態篩選 chip。
    /// - Parameters:
    ///   - filter: 要顯示的狀態篩選。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: chip 按鈕 view。
    @ViewBuilder
    func chipButton(_ filter: OrderStatusFilter, palette: BLPalette) -> some View {
        let isSelected = store.selectedStatus == filter

        Button {
            store.send(.statusFilterSelected(filter))
        } label: {
            Text(filter.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .foregroundStyle(isSelected ? palette.background : palette.secondaryLabel)
                .padding(.vertical, 7)
                .padding(.horizontal, 14)
                .background(isSelected ? palette.label : palette.fillTertiary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    /// 整合篩選 trigger button：以單顆 Capsule 呈現「日期 + 類別 + 付款方式」的摘要 (`篩選：<summary>`)，點擊後 present ``OrderFilterSheet``。
    ///
    /// - 三個篩選都為預設 (`selectedDatePeriod == .all`、`selectedCategory == nil` 且 `selectedPaymentMethod == nil`) 時，label 為「篩選：全部」、capsule fill 為 `fillTertiary`、前景色為 `secondaryLabel`。
    /// - 任一篩選為非預設時，summary 由 ``filterSummary(date:category:paymentMethod:)`` 計算 (規則見該 helper)、capsule fill 為 `purple.opacity(0.18)`、前景色為 `purple`。
    /// - Trigger 不再條件依賴 `availableCategories.isEmpty`——即使類別清單為空，trigger 仍渲染以提供日期篩選入口。
    /// - 長 summary 時 `Text` 多行換行 (透過 ``SwiftUI/Text/multilineTextAlignment(_:)`` + ``SwiftUI/View/fixedSize(horizontal:vertical:)``)，capsule 高度隨內容增長；icon 與 chevron 對齊第一行 baseline。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: trigger button view (含左側內距，與其他篩選膠囊水平對齊)。
    @ViewBuilder
    func unifiedFilterTrigger(palette: BLPalette) -> some View {
        let hasActiveFilter = store.selectedDatePeriod != .all
            || store.selectedCategory != nil
            || store.selectedPaymentMethod != nil
        let summary = filterSummary(
            date: store.selectedDatePeriod,
            category: store.selectedCategory,
            paymentMethod: store.selectedPaymentMethod
        )

        Button {
            showsFilterSheet = true
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.caption.weight(.semibold))

                Text("篩選：\(summary)")
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.down")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(hasActiveFilter ? palette.purple : palette.secondaryLabel)
            .padding(.vertical, 7)
            .padding(.horizontal, 14)
            .background(hasActiveFilter ? palette.purple.opacity(0.18) : palette.fillTertiary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, BLSpacing.large)
    }

    /// 計算整合 trigger 顯示的 summary 字串。純函式，輸入只看當前 `(date, category, paymentMethod)` 組合，與外部 state 解耦，方便測試與 preview。
    ///
    /// 規則：把「日期 (非 `.all`)」「類別」「付款方式」三個非預設片段依序以 ` · ` 串接；三者皆為預設時回傳「全部」。
    /// - `(.all, nil, nil)` → `全部`
    /// - `(.all, 美妝, nil)` → `美妝`
    /// - `(本月, nil, nil)` → `本月`
    /// - `(本月, 美妝, nil)` → `本月 · 美妝`
    /// - `(本月, 美妝, 信用卡)` → `本月 · 美妝 · 信用卡`
    /// - `(.all, nil, 信用卡)` → `信用卡`
    ///
    /// - Parameters:
    ///   - date: 目前選中的日期區間。
    ///   - category: 目前選中的類別；`nil` 代表「全部類別」。
    ///   - paymentMethod: 目前選中的付款方式；`nil` 代表「全部付款方式」。
    /// - Returns: trigger label 中「篩選：」後接的 summary 字串。
    func filterSummary(date: OrderDatePeriod, category: String?, paymentMethod: String?) -> String {
        var segments: [String] = []
        if date != .all {
            segments.append(date.title)
        }
        if let category {
            segments.append(category)
        }
        if let paymentMethod {
            segments.append(paymentMethod)
        }
        return segments.isEmpty ? "全部" : segments.joined(separator: " · ")
    }

    /// 訂單列表區塊，包含載入、空狀態與「以日期分組」的資料區段。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 列表區塊 view。
    @ViewBuilder
    func listSection(palette: BLPalette) -> some View {
        if store.isLoading {
            ProgressView("載入訂單")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, BLSpacing.large)
        } else {
            let sections = store.state.dateSections(referenceDate: date.now, calendar: calendar)
            if sections.isEmpty {
                emptyState(palette: palette)
            } else {
                VStack(alignment: .leading, spacing: BLSpacing.medium) {
                    ForEach(sections) { section in
                        orderDateSection(section, palette: palette)
                    }
                }
            }
        }
    }

    /// 單一日期區段：上方日期標題 + 下方當日訂單卡片 (列內不再重複顯示日期)。
    /// - Parameters:
    ///   - section: 要呈現的日期區段。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 日期區段 view。
    @ViewBuilder
    func orderDateSection(_ section: OrderDateSection, palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            Text(section.title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(palette.secondaryLabel)
                .padding(.horizontal, BLSpacing.large)

            BLCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(section.orders.enumerated()), id: \.element.id) { index, order in
                        NavigationLink(value: order.id) {
                            OrderRowView(order: order, showsDate: false)
                                .padding(.horizontal, BLSpacing.large)
                                .padding(.vertical, BLSpacing.extraSmall)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            Button(role: .destructive) {
                                store.send(.deleteOrderTapped(order.id))
                            } label: {
                                Label("刪除訂單", systemImage: "trash")
                            }
                        }

                        if index < section.orders.count - 1 {
                            Divider()
                                .padding(.leading, BLSpacing.large + 40 + BLSpacing.medium)
                        }
                    }
                }
            }
            .padding(.horizontal, BLSpacing.large)
        }
    }

    /// 沒有符合條件的訂單時顯示的空狀態。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 空狀態 view。
    @ViewBuilder
    func emptyState(palette: BLPalette) -> some View {
        ContentUnavailableView(
            "沒有符合條件的訂單",
            systemImage: "tray",
            description: Text("試著調整搜尋字詞或狀態篩選。")
        )
        .padding(.top, BLSpacing.extraLarge)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(palette.background)
    }
}

// MARK: - Preview

#Preview("iPhone 訂單瀏覽") {
    let previewState: OrdersFeature.State = {
        var state = OrdersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.hasLoaded = true
        return state
    }()

    OrdersCompactView(
        store: Store(initialState: previewState) {
            OrdersFeature()
        }
    )
}

#endif
