//
//  MoreView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 更多分頁的入口畫面
struct MoreView: View {

    // MARK: - Properties

    /// 更多頁導覽與子畫面共用的根 store
    @Bindable var store: StoreOf<RootFeature>

    // MARK: - Body

    /// 包含更多頁清單與推送目的地的導覽容器
    var body: some View {
        NavigationStack(path: $store.morePath) {
            phoneContent
                .navigationDestination(for: RootFeature.MoreRoute.self) { route in
                    destination(for: route)
                }
        }
    }
}

// MARK: - Private Views

private extension MoreView {

    /// 依目的地顯示對應的子畫面
    ///
    /// - Parameter route: 更多頁目的地
    /// - Returns: 對應目的地的子畫面
    @ViewBuilder
    func destination(for route: RootFeature.MoreRoute) -> some View {
        switch route {
        case .fx:
            FxView(store: store.scope(state: \.fx, action: \.fx))

        case .customers:
            CustomersView(store: store.scope(state: \.customers, action: \.customers))

        case .quote:
            QuoteView(store: store.scope(state: \.quote, action: \.quote))

        case .orderSources:
            lookupManagementDestination(for: .orderSource)

        case .categories:
            lookupManagementDestination(for: .category)

        case .paymentMethods:
            lookupManagementDestination(for: .paymentMethod)

        case .reconciliationStatuses:
            lookupManagementDestination(for: .reconciliationStatus)

        case .settings:
            SettingsView(store: store.scope(state: \.settings, action: \.settings))
        }
    }

    /// 將根 store scope 到單一主檔管理 store
    ///
    /// - Parameter kind: 要呈現的主檔種類
    /// - Returns: 對應的主檔管理畫面或無法載入的狀態畫面
    @ViewBuilder
    func lookupManagementDestination(for kind: LookupKind) -> some View {
        if let managementStore = store.scope(
            state: \.lookupManagements[id: kind],
            action: \.lookupManagements[id: kind]
        ) {
            LookupManagementView(store: managementStore)
        } else {
            ContentUnavailableView(
                "無法載入主檔管理頁面，請稍後再試。",
                systemImage: "exclamationmark.triangle"
            )
        }
    }

    /// 顯示工具、管理項目與設定的列表內容
    @ViewBuilder
    var phoneContent: some View {
        List {
            Section("工具") {
                routeLink(.fx)
            }

            Section("管理") {
                routeLink(.customers)
                routeLink(.orderSources)
                routeLink(.categories)
                routeLink(.paymentMethods)
                routeLink(.reconciliationStatuses)
                routeLink(.quote)
            }

            Section("App") {
                routeLink(.settings)
            }
        }
        .accessibilityIdentifier(BLAccessibilityID.More.root)
        .rootNavigationTitle("更多", language: store.settings.language)
    }

    /// 建立一個目的地列並設定導覽值與 accessibility identifier
    ///
    /// - Parameter route: 更多頁目的地
    /// - Returns: 對應目的地的導覽列
    func routeLink(_ route: RootFeature.MoreRoute) -> some View {
        NavigationLink(value: route) {
            Label {
                Text(LocalizedStringKey(routeTitle(for: route)))
                    .font(BLTypographyStyle.body.font.weight(.medium))
            } icon: {
                Image(systemName: routeSystemImage(for: route))
                    .foregroundStyle(routeTint(for: route))
            }
        }
        .accessibilityIdentifier(accessibilityRow(for: route))
    }
}

// MARK: - Private Method

private extension MoreView {

    /// 目前外觀使用的色盤
    var palette: BLPalette {
        BLPalette()
    }

    /// 回傳更多頁目的地的標題
    ///
    /// - Parameter route: 更多頁目的地
    /// - Returns: 目的地標題
    func routeTitle(for route: RootFeature.MoreRoute) -> String {
        switch route {
        case .fx:
            "匯率工具"
        case .customers:
            "客戶名單"
        case .quote:
            "報價試算"
        case .orderSources:
            LookupKind.orderSource.entryTitle
        case .categories:
            LookupKind.category.entryTitle
        case .paymentMethods:
            LookupKind.paymentMethod.entryTitle
        case .reconciliationStatuses:
            LookupKind.reconciliationStatus.entryTitle
        case .settings:
            "設定"
        }
    }

    /// 回傳更多頁目的地的 SF Symbol
    ///
    /// - Parameter route: 更多頁目的地
    /// - Returns: 對應的 SF Symbol 名稱
    func routeSystemImage(for route: RootFeature.MoreRoute) -> String {
        switch route {
        case .fx:
            "dollarsign.arrow.circlepath"

        case .customers:
            "person.2"

        case .quote:
            "function"

        case .orderSources:
            LookupKind.orderSource.systemImage

        case .categories:
            LookupKind.category.systemImage

        case .paymentMethods:
            LookupKind.paymentMethod.systemImage

        case .reconciliationStatuses:
            LookupKind.reconciliationStatus.systemImage

        case .settings:
            "gear"
        }
    }

    /// 回傳更多頁目的地的圖示色彩
    ///
    /// - Parameter route: 更多頁目的地
    /// - Returns: 對應的圖示色彩
    func routeTint(for route: RootFeature.MoreRoute) -> Color {
        switch route {
        case .fx:
            palette.accent

        case .customers:
            palette.purple

        case .quote:
            palette.green

        case .orderSources:
            palette.teal

        case .categories:
            palette.orange

        case .paymentMethods:
            palette.red

        case .reconciliationStatuses:
            palette.indigo

        case .settings:
            palette.secondaryLabel
        }
    }

    /// 回傳更多頁目的地列的 accessibility identifier
    ///
    /// - Parameter route: 更多頁目的地
    /// - Returns: 對應目的地列的 accessibility identifier
    func accessibilityRow(for route: RootFeature.MoreRoute) -> String {
        let row: BLAccessibilityID.More.Row
        switch route {
        case .fx:
            row = .fx

        case .customers:
            row = .customers

        case .quote:
            row = .quote

        case .orderSources:
            row = .orderSources

        case .categories:
            row = .categories

        case .paymentMethods:
            row = .paymentMethods

        case .reconciliationStatuses:
            row = .reconciliationStatuses

        case .settings:
            row = .settings
        }
        return BLAccessibilityID.More.row(row)
    }
}

// MARK: - Preview

#Preview("更多") {
    MoreView(
        store: Store(initialState: RootFeature.State()) {
            RootFeature()
        }
    )
}
