//
//  MoreView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 更多分頁的入口畫面
///
/// 對應設計稿 iPhone 「設定 / 更多」頁與 iPad 工具區塊的入口：以列表形式列出工具與設定子頁面，點擊後 push 到對應子畫面
struct MoreView: View {

    // MARK: - View Properties

    /// App 根層級 store
    @Bindable var store: StoreOf<RootFeature>

    /// 目前系統深淺色外觀
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - View Body

    /// 更多頁的畫面內容
    var body: some View {
        let palette = BLPalette()

        NavigationStack(path: $store.morePath) {
            phoneContent(palette: palette)
                .navigationDestination(for: RootFeature.MoreRoute.self) { route in
                    destination(for: route)
                }
        }
    }
}

// MARK: - Nested Types

private extension MoreView {

    /// 工具項目的領域定義
    enum ToolItem: String, CaseIterable, Identifiable {

        // MARK: - Cases

        /// 匯率工具
        case fx

        /// 客戶名單
        case customers

        /// 報價試算
        case quote

        /// 訂單來源主檔管理
        case orderSources

        /// 商品類別主檔管理
        case categories

        /// 付款方式主檔管理
        case paymentMethods

        /// 對帳狀態主檔管理
        case reconciliationStatuses

        // MARK: - Identifiable Properties

        /// 項目的穩定識別值
        var id: String { rawValue }

        // MARK: - Display Properties

        /// 顯示在卡片或列表上的標題
        var title: String {
            switch self {
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
            }
        }

        /// 卡片副標題
        var subtitle: String {
            switch self {
            case .fx:
                "即時連線 ExchangeRate-API，將外幣換算為 TWD。"
            case .customers:
                "依名稱整理客戶活躍度，快速跳轉到對應訂單。"
            case .quote:
                "輸入成本與費率，即時看到建議售價與毛利。"
            case .orderSources:
                LookupKind.orderSource.entrySubtitle
            case .categories:
                LookupKind.category.entrySubtitle
            case .paymentMethods:
                LookupKind.paymentMethod.entrySubtitle
            case .reconciliationStatuses:
                LookupKind.reconciliationStatus.entrySubtitle
            }
        }

        /// 對應的 SF Symbol
        var systemImage: String {
            switch self {
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
            }
        }

        /// 圖示色 (依語意 token)
        /// - Parameter palette: 目前外觀使用的色盤
        /// - Returns: 對應的色彩
        func tint(in palette: BLPalette) -> Color {
            switch self {
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
            }
        }
    }
}

// MARK: - ViewBuilder

private extension MoreView {

    /// 將目的地導向到對應 view
    /// - Parameter route: 目的地
    /// - Returns: 對應目的地 view
    @ViewBuilder
    func destination(for route: RootFeature.MoreRoute) -> some View {
        switch route {
        case .fx:
            FxView(store: store.scope(state: \.fx, action: \.fx))
        case .customers:
            CustomersView(store: store)
        case .quote:
            QuoteView(store: store.scope(state: \.quote, action: \.quote))
        case .orderSources:
            LookupManagementView(
                store: store.scope(state: \.orderSourceManagement, action: \.orderSourceManagement)
            )
        case .categories:
            LookupManagementView(
                store: store.scope(state: \.categoryManagement, action: \.categoryManagement)
            )
        case .paymentMethods:
            LookupManagementView(
                store: store.scope(state: \.paymentMethodManagement, action: \.paymentMethodManagement)
            )
        case .reconciliationStatuses:
            LookupManagementView(
                store: store.scope(state: \.reconciliationStatusManagement, action: \.reconciliationStatusManagement)
            )
        case .settings:
            SettingsView(store: store.scope(state: \.settings, action: \.settings))
        }
    }

    /// 保持 phone-friendly 的 grouped list 風格
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 列表 view
    @ViewBuilder
    func phoneContent(palette: BLPalette) -> some View {
        List {
            Section("工具") {
                NavigationLink(value: RootFeature.MoreRoute.fx) {
                    toolRow(.fx, palette: palette)
                }
            }

            Section("管理") {
                NavigationLink(value: RootFeature.MoreRoute.customers) {
                    toolRow(.customers, palette: palette)
                }

                NavigationLink(value: RootFeature.MoreRoute.orderSources) {
                    toolRow(.orderSources, palette: palette)
                }

                NavigationLink(value: RootFeature.MoreRoute.categories) {
                    toolRow(.categories, palette: palette)
                }

                NavigationLink(value: RootFeature.MoreRoute.paymentMethods) {
                    toolRow(.paymentMethods, palette: palette)
                }

                NavigationLink(value: RootFeature.MoreRoute.reconciliationStatuses) {
                    toolRow(.reconciliationStatuses, palette: palette)
                }

                NavigationLink(value: RootFeature.MoreRoute.quote) {
                    toolRow(.quote, palette: palette)
                }
            }

            Section("App") {
                NavigationLink(value: RootFeature.MoreRoute.settings) {
                    Label {
                        Text("設定").font(.body.weight(.medium))
                    } icon: {
                        Image(systemName: "gear")
                            .foregroundStyle(palette.secondaryLabel)
                    }
                }
            }
        }
        .rootNavigationTitle("更多", language: store.settings.language)
    }

    /// iOS 列表的單列
    /// - Parameters:
    ///   - item: 工具項目
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 工具列 view
    @ViewBuilder
    func toolRow(_ item: ToolItem, palette: BLPalette) -> some View {
        Label {
            Text(LocalizedStringKey(item.title)).font(.body.weight(.medium))
        } icon: {
            Image(systemName: item.systemImage)
                .foregroundStyle(item.tint(in: palette))
        }
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
