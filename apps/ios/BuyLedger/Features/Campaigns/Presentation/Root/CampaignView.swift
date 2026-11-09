//
//  CampaignView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import SwiftUI

/// 開團分頁的根容器，統一管理詳情導覽、表單、確認與通知
struct CampaignView: View {

    // MARK: - Properties

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<CampaignFeature>

    /// App 目前選用的顯示語系
    let language: AppLanguage

    // MARK: - Body

    /// 呈現列表與詳情；表單 sheet 掛在容器，兩種 alert 只掛在目前最上層的畫面
    var body: some View {
        NavigationSplitView {
            CampaignListView(
                store: store.scope(state: \.list, action: \.list),
                language: language,
                selection: selectionBinding
            )
            .alert(alertBinding(isDetail: false))
            .alert(noticeAlertBinding(isDetail: false))
        } detail: {
            detailContent
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(BLAccessibilityID.Common.selectedItem(.campaigns))
        .accessibilityValue(Text(verbatim: pathProjectedCampaignID))
        .task {
            // task-finish-exempt: 提醒連結供開團畫面顯示與操作，未完成時重返畫面會再次載入
            await store.send(.view(.task)).finish()
        }
        .sheet(
            item: $store
                .scope(state: \.presentation.$destination, action: \.presentation.destination)
                .edit,
            onDismiss: sendFormSheetDismissed
        ) {
            CampaignEditView(store: $0)
        }
    }
}

// MARK: - Private Views

private extension CampaignView {

    /// 目前所選開團的詳情，未選取時為空狀態
    @ViewBuilder
    var detailContent: some View {
        if let detailStore {
            CampaignDetailView(store: detailStore)
                .alert(alertBinding(isDetail: true))
                .alert(noticeAlertBinding(isDetail: true))
        } else {
            ContentUnavailableView(
                "common.navigation.detailEmptyState",
                systemImage: "shippingbox",
                description: Text("common.navigation.selectItemPrompt")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.blBackground)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(BLAccessibilityID.Common.detailEmptyState)
        }
    }
}

// MARK: - Nested Types

private extension CampaignView {

    /// 確認與通知 alert 綁定的型別
    typealias AlertBinding = Binding<
        Store<
            AlertState<CampaignPresentationFeature.Destination.Alert>,
            CampaignPresentationFeature.Destination.Alert
        >?
    >
}

// MARK: - Private Method

private extension CampaignView {

    /// 目前導覽路徑選取的開團識別碼；未選取時為空字串
    var pathProjectedCampaignID: String {
        store.path.last?.detail?.campaignID ?? ""
    }

    /// 目前所選開團項目的詳情子 `Store`
    var detailStore: StoreOf<CampaignDetailFeature>? {
        guard let pathID = store.path.ids.last else {
            return nil
        }
        return store.scope(
            state: \.path[id: pathID, case: \.detail],
            action: \.path[id: pathID].detail
        )
    }

    /// 清單選取與導覽路徑的雙向綁定；`nil` 代表系統已返回開團清單
    var selectionBinding: Binding<Campaign.ID?> {
        Binding {
            store.path.last?.detail?.campaignID
        } set: {
            store.send(.view(.detailSelectionChanged($0)))
        }
    }

    /// 依呼叫端是否為詳情，取得目的地確認 alert 的綁定；只有目前最上層的畫面取得綁定
    ///
    /// - Parameter isDetail: 呼叫端是否為推入的詳情；`false` 表示列表根畫面
    /// - Returns: 呼叫端是最上層的畫面時為 `destination` alert 綁定，否則為常數 `nil`
    /// - Note: 同一個綁定只掛在一層，避免列表與詳情各自呈現同一個 alert
    func alertBinding(isDetail: Bool) -> AlertBinding {
        let isDetailOnTop = !store.path.isEmpty
        guard isDetail == isDetailOnTop else {
            return .constant(nil)
        }
        return $store
            .scope(state: \.presentation.$destination, action: \.presentation.destination)
            .alert
    }

    /// 依呼叫端是否為詳情，取得獨立通知 alert 的綁定
    ///
    /// - Parameter isDetail: 呼叫端是否為推入的詳情；`false` 表示列表根畫面
    /// - Returns: 目前最上層畫面的通知綁定，另一層取得常數 `nil`
    func noticeAlertBinding(isDetail: Bool) -> AlertBinding {
        let isDetailOnTop = !store.path.isEmpty
        guard isDetail == isDetailOnTop else {
            return .constant(nil)
        }
        return $store.scope(state: \.presentation.$notice, action: \.presentation.notice)
    }

    /// 表單 sheet 關閉動畫結束後，請容器呈現暫存通知
    func sendFormSheetDismissed() {
        store.send(.view(.formSheetDismissed))
    }
}

// MARK: - Preview

#Preview("orders.detail.title.campaigns") {
    CampaignView(
        store: Store(initialState: CampaignFeature.State()) {
            CampaignFeature()
        },
        language: .traditionalChinese
    )
}
