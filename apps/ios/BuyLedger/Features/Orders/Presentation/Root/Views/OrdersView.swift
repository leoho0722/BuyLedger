//
//  OrdersView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 訂單功能的自適應清單與詳情分欄宿主
struct OrdersView: View {

    // MARK: - Properties

    /// 訂單宿主可用的水平尺寸分類
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<OrdersFeature>

    /// App 目前選用的顯示語系
    let language: AppLanguage

    // MARK: - Body

    /// 以唯一詳情路徑承載 Orders split 與共用表單的分欄宿主
    var body: some View {
        @Bindable var presentation = store.scope(state: \.presentation, action: \.presentation)
        @Bindable var list = store.scope(state: \.list, action: \.list)

        NavigationSplitView {
            listContent
        } detail: {
            detailContent
        }
        .sheet(
            item: $presentation.scope(state: \.$destination, action: \.destination).edit,
            onDismiss: sendFormSheetDismissed
        ) {
            OrderEditView(store: $0)
        }
        .sheet(
            item: $presentation.scope(state: \.$destination, action: \.destination).aiSummary,
            onDismiss: sendFormSheetDismissed
        ) {
            AISummaryView(store: $0)
        }
        .sheet(
            item: $presentation.scope(state: \.$destination, action: \.destination).merge,
            onDismiss: sendFormSheetDismissed
        ) {
            OrderMergeCandidateSheet(store: $0)
        }
        .sheet(item: $list.scope(state: \.$destination, action: \.destination).filterSheet) {
            OrderFilterSheet(store: $0)
        }
        .sheet(item: $list.scope(state: \.$destination, action: \.destination).categoryPicker) {
            OrderCategoryPickerSheet(store: $0)
        }
    }
}

// MARK: - Private Views

private extension OrdersView {

    /// 清單欄內容，依 Orders 自身的水平尺寸分類決定並排或單欄
    @ViewBuilder
    var listContent: some View {
        if Self.usesRegularList(horizontalSizeClass: horizontalSizeClass) {
            OrdersRegularListContent(store: store, language: language)
        } else {
            OrdersCompactView(store: store, language: language)
        }
    }

    /// 目前詳情或未選取提示，alert 只掛在可見層
    var detailContent: some View {
        OrdersRegularDetailColumn(store: store)
            .alert(OrdersView.alertBinding(store: store, isDetail: true))
    }
}

// MARK: - Nested Types

extension OrdersView {

    /// 訂單容器共用的 alert 綁定型別
    typealias AlertBinding = Binding<
        Store<
            AlertState<OrdersPresentationFeature.Destination.Alert>,
            OrdersPresentationFeature.Destination.Alert
        >?
    >
}

// MARK: - Internal Method

extension OrdersView {

    /// 判斷清單是否採並排排列；缺少尺寸分類時退回單欄，清單與詳情仍可由原生返回到達
    ///
    /// - Parameter horizontalSizeClass: Orders 自身的水平尺寸分類
    /// - Returns: 只有 `.regular` 時為 `true`
    static func usesRegularList(horizontalSizeClass: UserInterfaceSizeClass?) -> Bool {
        horizontalSizeClass == .regular
    }

    /// 提供目前可見層的 alert 綁定，另一層使用常數 `nil`
    ///
    /// - Parameters:
    ///   - store: Orders 容器的狀態與事件來源
    ///   - isDetail: 是否為目前詳情層
    /// - Returns: 目前可見層的 alert 綁定
    static func alertBinding(store: StoreOf<OrdersFeature>, isDetail: Bool) -> AlertBinding {
        guard isDetail == !store.detail.path.isEmpty else {
            return .constant(nil)
        }
        @Bindable var presentation = store.scope(state: \.presentation, action: \.presentation)
        return $presentation.scope(state: \.$destination, action: \.destination).alert
    }
}

// MARK: - Private Method

private extension OrdersView {

    /// 表單的關閉動畫完成後通知容器取出暫存通知
    func sendFormSheetDismissed() {
        store.send(.view(.formSheetDismissed))
    }
}

// MARK: - Preview

#Preview("訂單瀏覽") {
    let previewState: OrdersFeature.State = {
        let state = OrdersFeature.State(orders: LedgerOrder.sampleOrders)
        state.load.$hasLoaded.withLock {
            $0 = true
        }
        return state
    }()

    OrdersView(
        store: Store(initialState: previewState) {
            OrdersFeature()
        },
        language: .traditionalChinese
    )
    .environment(\.horizontalSizeClass, .regular)
}
