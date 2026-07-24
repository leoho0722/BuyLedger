//
//  OrdersCompactView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// iPhone (compact) 使用的訂單瀏覽畫面
///
/// 採用 NavigationStack 配合自訂大標題、橫向滾動的狀態 chip 與卡片化的訂單列表，對應設計稿的 iPhone 訂單列表樣式
struct OrdersCompactView: View {

    // MARK: - View Properties

    /// 訂單功能 store
    @Bindable var store: StoreOf<OrdersFeature>

    /// App 目前選用的顯示語系
    let language: AppLanguage

    /// 目前系統深淺色外觀
    @Environment(\.colorScheme) private var colorScheme

    /// App 目前選用的顯示語系
    @Environment(\.locale) private var locale

    /// 用於 ``OrdersFeature/State/filteredOrders(referenceDate:calendar:)`` 的「現在」時間；測試可注入固定值
    @Dependency(\.date) private var date

    /// 訂單篩選與日期分組所用的行事曆 (含時區)；測試可注入固定值
    @Dependency(\.calendar) private var calendar

    // MARK: - View Body

    /// 訂單瀏覽畫面內容
    var body: some View {
        let palette = BLPalette()
        let filteredIDs = store.state.filteredOrders(referenceDate: date.now, calendar: calendar).map(\.id)
        let allFilteredSelected = !filteredIDs.isEmpty && filteredIDs.allSatisfy { store.selectedOrderIDs.contains($0) }
        NavigationStack(path: $store.scope(state: \.detailPath, action: \.detailPath)) {
            ScrollView {
                VStack(alignment: .leading, spacing: BLSpacing.medium) {
                    chipStrip(palette: palette)
                    unifiedFilterTrigger(palette: palette)

                    if let errorMessage = store.errorMessage {
                        Text(LocalizedStringKey(errorMessage))
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
            .accessibilityIdentifier(BLAccessibilityID.Orders.listRoot)
            .scrollDismissesKeyboard(.interactively)
            .rootNavigationTitle(store.navigationTitleKey, language: language)
            .toolbar {
                if store.isSelecting {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(LocalizedStringKey(allFilteredSelected ? "清除" : "全選")) {
                            store.send(allFilteredSelected ? .clearSelectionTapped : .selectAllTapped)
                        }
                    }

                    ToolbarItemGroup(placement: .primaryAction) {
                        Menu {
                            // 「已合併」僅能由合併流程寫入，批次目標清單一律排除
                            ForEach(OrderStatus.allCases.filter { $0 != .merged }) { status in
                                Button(LocalizedStringKey(status.title)) {
                                    store.send(.batchStatusChanged(status))
                                }
                            }
                        } label: {
                            Text("更改狀態")
                        }
                        .disabled(store.selectedOrderIDs.isEmpty)

                        Button("完成") {
                            store.send(.selectionModeToggled)
                        }
                    }
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Text("\(filteredIDs.count)")
                            .font(.subheadline.weight(.medium))
                            .monospacedDigit()
                            .foregroundStyle(palette.secondaryLabel)
                    }

                    ToolbarItemGroup(placement: .primaryAction) {
                        Menu {
                            Button {
                                store.send(.aiSummaryTapped)
                            } label: {
                                Label("AI 總結", systemImage: "sparkles")
                            }
                            .disabled(store.state.filteredOrders(referenceDate: date.now, calendar: calendar).isEmpty)
                            .accessibilityIdentifier(BLAccessibilityID.Orders.aiSummaryButton)

                            Button {
                                store.send(.selectionModeToggled)
                            } label: {
                                Label("選取訂單", systemImage: "checklist")
                            }
                            .disabled(store.orders.isEmpty)
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                        .accessibilityLabel("更多操作")
                        .accessibilityIdentifier(BLAccessibilityID.Orders.batchMenuButton)

                        Button {
                            store.send(.newOrderTapped)
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("新增訂單")
                        .accessibilityIdentifier(BLAccessibilityID.Orders.addButton)
                    }
                }
            }
            // 系統 .searchable 搜尋欄掛不上穩定 identifier,UI 測試改以 app.searchFields.firstMatch 定位
            .searchable(
                text: $store.searchText.sending(\.searchTextChanged),
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("搜尋客戶、單號或商品")
            )
            .task {
                await store.send(.task).finish()
            }
            .sheet(isPresented: $store.showsFilterSheet) {
                OrderFilterSheet(store: store)
            }
        } destination: { detailStore in
            if let order = store.orders.first(where: { $0.id == detailStore.orderID }) {
                OrderDetailView(order: order)
                    .navigationTitle(Text(verbatim: order.customer.name))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Menu {
                                // 「已合併」只能由合併流程寫入，僅當目前狀態已是已合併時保留選項
                                ForEach(OrderStatus.allCases.filter { $0 != .merged || order.status == .merged }) { status in
                                    Button {
                                        store.send(.statusChanged(order.id, status))
                                    } label: {
                                        if status == order.status {
                                            Label(LocalizedStringKey(status.title), systemImage: "checkmark")
                                        } else {
                                            Text(LocalizedStringKey(status.title))
                                        }
                                    }
                                }
                            } label: {
                                Image(systemName: "arrow.triangle.2.circlepath")
                            }
                            .accessibilityLabel("更新狀態")
                            .accessibilityIdentifier(BLAccessibilityID.Orders.detailStatusMenuButton)
                        }

                        // 合併/編輯/刪除功能性質相近，收進單一「更多」選單，避免 toolbar 四個操作並排擁擠
                        ToolbarItem(placement: .primaryAction) {
                            Menu {
                                if order.status != .merged, order.status != .cancelled {
                                    Button {
                                        store.send(.mergeOrderTapped(order.id))
                                    } label: {
                                        Label("合併訂單", systemImage: "arrow.triangle.merge")
                                    }
                                    .accessibilityIdentifier(BLAccessibilityID.Orders.detailMergeButton)
                                }

                                Button {
                                    store.send(.editOrderTapped(order.id))
                                } label: {
                                    Label("編輯", systemImage: "pencil")
                                }
                                .accessibilityIdentifier(BLAccessibilityID.Orders.detailEditButton)

                                Divider()

                                Button(role: .destructive) {
                                    store.send(.deleteOrderTapped(order.id))
                                } label: {
                                    Label("刪除", systemImage: "trash")
                                }
                                .accessibilityIdentifier(BLAccessibilityID.Orders.detailDeleteButton)
                            } label: {
                                Image(systemName: "ellipsis.circle")
                            }
                            .accessibilityLabel("更多操作")
                            .accessibilityIdentifier(BLAccessibilityID.Orders.detailMoreButton)
                        }
                    }
            }
        }
    }
}

// MARK: - ViewBuilder

private extension OrdersCompactView {

    /// 狀態篩選 chip 橫向滾動列
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: chip 列 view
    @ViewBuilder
    func chipStrip(palette: BLPalette) -> some View {
        ScrollView(.horizontal) {
            HStack(spacing: BLSpacing.small) {
                ForEach(OrderStatusFilter.orderBrowsingCases) { filter in
                    chipButton(filter, palette: palette)
                }
            }
            .padding(.horizontal, BLSpacing.large)
        }
        .scrollIndicators(.hidden)
    }

    /// 單一狀態篩選 chip
    /// - Parameters:
    ///   - filter: 要顯示的狀態篩選
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: chip 按鈕 view
    @ViewBuilder
    func chipButton(_ filter: OrderStatusFilter, palette: BLPalette) -> some View {
        BLFilterChip(
            title: LocalizedStringKey(filter.title),
            isSelected: store.selectedStatus == filter,
            size: .large
        ) {
            store.send(.statusFilterSelected(filter))
        }
        .accessibilityIdentifier(BLAccessibilityID.Orders.statusChip(filter.id))
    }

    /// 整合篩選 trigger button：以單顆 Capsule 呈現「日期 + 類別 + 付款方式」的摘要 (`篩選：<summary>`)，點擊後 present ``OrderFilterSheet``
    ///
    /// - 三個篩選都為預設 (`selectedDatePeriod == .all`、`selectedCategory == nil` 且 `selectedPaymentMethod == nil`) 時，label 為「篩選：全部」、capsule fill 為 `fillTertiary`、前景色為 `secondaryLabel`
    /// - 任一篩選為非預設時，summary 由 ``filterSummary(date:category:paymentMethod:)`` 計算 (規則見該 helper)、capsule fill 為 `purple.opacity(0.18)`、前景色為 `purple`
    /// - Trigger 不再條件依賴 `availableCategories.isEmpty`——即使類別清單為空，trigger 仍渲染以提供日期篩選入口
    /// - 長 summary 時 `Text` 多行換行 (透過 ``SwiftUI/Text/multilineTextAlignment(_:)`` + ``SwiftUI/View/fixedSize(horizontal:vertical:)``)，capsule 高度隨內容增長；icon 與 chevron 對齊第一行 baseline
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: trigger button view (含左側內距，與其他篩選膠囊水平對齊)
    @ViewBuilder
    func unifiedFilterTrigger(palette: BLPalette) -> some View {
        let hasActiveFilter = store.selectedDatePeriod != .all
            || store.selectedCategory != nil
            || store.selectedPaymentMethod != nil
        let summary = filterSummaryText(
            date: store.selectedDatePeriod,
            category: store.selectedCategory,
            paymentMethod: store.selectedPaymentMethod
        )

        BLFilterChip(
            title: "篩選: \(summary)",
            isSelected: hasActiveFilter,
            style: .purple,
            size: .large,
            icon: "line.3.horizontal.decrease",
            trailingIcon: "chevron.down",
            isExpanded: true
        ) {
            store.send(.filterSheetTapped)
        }
        .accessibilityIdentifier(BLAccessibilityID.Orders.filterButton)
        .padding(.horizontal, BLSpacing.large)
    }

    /// 訂單列表區塊，包含載入、空狀態與「以日期分組」的資料區段
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 列表區塊 view
    @ViewBuilder
    func listSection(palette: BLPalette) -> some View {
        if store.isLoading {
            ProgressView("載入訂單")
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, BLSpacing.large)
        } else {
            let sections = store.state.dateSections(referenceDate: date.now, calendar: calendar, locale: locale)
            if sections.isEmpty {
                emptyState(palette: palette)
            } else {
                // 惰性只施加於外層日期區段：卡片內的訂單列容器必須維持非惰性，
                // 否則卡片背景會因高度漸進確定而包不住當日所有列
                LazyVStack(alignment: .leading, spacing: BLSpacing.medium) {
                    ForEach(sections) { section in
                        orderDateSection(section, palette: palette)
                    }
                }
            }
        }
    }

    /// 單一日期區段：上方日期標題 + 下方當日訂單卡片 (列內不再重複顯示日期)
    /// - Parameters:
    ///   - section: 要呈現的日期區段
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 日期區段 view
    @ViewBuilder
    func orderDateSection(_ section: OrderDateSection, palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            Text(LocalizedStringKey(section.title))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(palette.secondaryLabel)
                .padding(.horizontal, BLSpacing.large)

            BLCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(section.orders.enumerated()), id: \.element.id) { index, order in
                        if store.isSelecting {
                            selectableRow(order: order, palette: palette)
                        } else {
                            navigableRow(order: order)
                        }

                        if index < section.orders.count - 1 {
                            Divider()
                                .padding(.leading, BLListMetrics.dividerInset)
                        }
                    }
                }
            }
            .padding(.horizontal, BLSpacing.large)
        }
    }

    /// 一般 (非多選) 模式的訂單列：點擊進入詳情，長按提供合併／刪除 context menu
    /// - Parameter order: 要呈現的訂單
    /// - Returns: 可導覽的訂單列 view
    @ViewBuilder
    func navigableRow(order: LedgerOrder) -> some View {
        NavigationLink(state: OrderDetailPath.State(orderID: order.id)) {
            OrderRowView(order: order, showsDate: false)
                .accessibilityIdentifier(BLAccessibilityID.Orders.row(orderID: order.id))
                .padding(.horizontal, BLSpacing.large)
                .padding(.vertical, BLSpacing.extraSmall)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            if order.status != .merged, order.status != .cancelled {
                Button {
                    store.send(.mergeOrderTapped(order.id))
                } label: {
                    Label("合併訂單", systemImage: "arrow.triangle.merge")
                }
            }

            Button(role: .destructive) {
                store.send(.deleteOrderTapped(order.id))
            } label: {
                Label("刪除訂單", systemImage: "trash")
            }
        }
    }

    /// 多選模式的訂單列：左側勾選圈，點擊切換選取而非導覽
    /// - Parameters:
    ///   - order: 要呈現的訂單
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 可勾選的訂單列 view
    @ViewBuilder
    func selectableRow(order: LedgerOrder, palette: BLPalette) -> some View {
        let isSelected = store.selectedOrderIDs.contains(order.id)

        Button {
            store.send(.orderSelectionToggled(order.id))
        } label: {
            HStack(spacing: BLSpacing.medium) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? palette.accent : palette.tertiaryLabel)
                    .accessibilityHidden(true)

                OrderRowView(order: order, showsDate: false)
                    .accessibilityIdentifier(BLAccessibilityID.Orders.row(orderID: order.id))
            }
            .padding(.horizontal, BLSpacing.large)
            .padding(.vertical, BLSpacing.extraSmall)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// 沒有符合條件的訂單時顯示的空狀態
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 空狀態 view
    @ViewBuilder
    func emptyState(palette: BLPalette) -> some View {
        ContentUnavailableView(
            "沒有符合條件的訂單",
            systemImage: "tray",
            description: Text("試著調整搜尋字詞或狀態篩選。")
        )
        .accessibilityIdentifier(BLAccessibilityID.Orders.listEmptyState)
        // 以容器相對高度撐開再置中；只給 maxHeight 在垂直 ScrollView 內不生效，
        // 空狀態會黏在頂端而非可視區域中央
        .frame(maxWidth: .infinity)
        .containerRelativeFrame(.vertical)
        .background(palette.background)
    }
}

// MARK: - Private Method

private extension OrdersCompactView {

    /// 計算整合 trigger 顯示的 summary 字串。純函式，輸入只看當前 `(date, category, paymentMethod)` 組合，與外部 state 解耦，方便測試與 preview
    ///
    /// 規則：把「日期 (非 `.all`)」「類別」「付款方式」三個非預設片段依序以 ` · ` 串接；三者皆為預設時回傳「全部」
    /// - `(.all, nil, nil)` → `全部`
    /// - `(.all, 美妝, nil)` → `美妝`
    /// - `(本月, nil, nil)` → `本月`
    /// - `(本月, 美妝, nil)` → `本月 · 美妝`
    /// - `(本月, 美妝, 信用卡)` → `本月 · 美妝 · 信用卡`
    /// - `(.all, nil, 信用卡)` → `信用卡`
    ///
    /// - Parameters:
    ///   - date: 目前選中的日期區間
    ///   - category: 目前選中的類別；`nil` 代表「全部類別」
    ///   - paymentMethod: 目前選中的付款方式；`nil` 代表「全部付款方式」
    /// - Returns: trigger label 中「篩選：」後接的 summary 字串
    func filterSummaryText(date: OrderDatePeriod, category: String?, paymentMethod: String?) -> Text {
        var summary: Text?
        if date != .all {
            summary = Text(LocalizedStringKey(date.title))
        }
        if let category {
            summary = appendVerbatim(category, to: summary)
        }
        if let paymentMethod {
            summary = appendVerbatim(paymentMethod, to: summary)
        }
        return summary ?? Text("全部")
    }

    /// 將外部／使用者資料以 verbatim 形式串接，避免內容恰好等於 catalog key 時被翻譯
    func appendVerbatim(_ value: String, to summary: Text?) -> Text {
        guard let summary else {
            return Text(verbatim: value)
        }
        return summary + Text(verbatim: " · \(value)")
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
        },
        language: .traditionalChinese
    )
}
