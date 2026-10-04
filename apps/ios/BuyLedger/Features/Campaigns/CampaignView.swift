//
//  CampaignView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import SwiftUI

/// 開團分頁的根容器，統一管理詳情導覽、表單與通知
struct CampaignView: View {

    // MARK: - Properties

    /// 開團容器的狀態與事件來源
    @Bindable var store: StoreOf<CampaignFeature>

    /// App 目前選用的顯示語系
    let language: AppLanguage

    // MARK: - Body

    /// 呈現列表與詳情；表單 sheet 掛在容器，唯一的 alert 掛在目前最上層的畫面
    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            CampaignListView(store: store.scope(state: \.list, action: \.list), language: language)
                // alert 不能掛在 NavigationStack 外層：iPad 的 split view 蓋不到推入的詳情
                .alert(alertBinding(isDetail: false))
        } destination: { pathStore in
            switch pathStore.case {
            case .detail(let detailStore):
                CampaignDetailView(store: detailStore)
                    .alert(alertBinding(isDetail: true))
            }
        }
        .task {
            await store.send(.view(.task)).finish()
        }
        .sheet(
            item: $store.scope(state: \.$destination, action: \.destination).edit,
            onDismiss: sendFormSheetDismissed
        ) {
            CampaignEditView(store: $0)
        }
    }
}

// MARK: - Nested Types

private extension CampaignView {

    /// 開團 alert 的按鈕動作
    typealias AlertAction = CampaignFeature.Destination.Alert

    /// 唯一 alert 綁定的型別
    typealias AlertBinding = Binding<Store<AlertState<AlertAction>, AlertAction>?>
}

// MARK: - Private Method

private extension CampaignView {

    /// 唯一 alert 的綁定；只有目前最上層的畫面拿到真正的綁定，另一層拿 `nil` 常數
    ///
    /// - Parameter isDetail: 呼叫端是否為推入的詳情；`false` 表示列表根畫面
    /// - Returns: 呼叫端是最上層的畫面時為容器 `destination` 的 alert 綁定，否則為常數 `nil`
    /// - Note: 同一個綁定掛在兩層會讓兩層各自呈現同一個 alert，所以依堆疊是否有詳情擇一
    func alertBinding(isDetail: Bool) -> AlertBinding {
        let isDetailOnTop = !store.path.isEmpty
        guard isDetail == isDetailOnTop else {
            return .constant(nil)
        }
        return $store.scope(state: \.$destination, action: \.destination).alert
    }

    /// 表單 sheet 關閉動畫結束後，請容器呈現暫存通知
    func sendFormSheetDismissed() {
        store.send(.view(.formSheetDismissed))
    }
}

// MARK: - Preview

#Preview("開團") {
    CampaignView(
        store: Store(initialState: CampaignFeature.State()) {
            CampaignFeature()
        },
        language: .traditionalChinese
    )
}
