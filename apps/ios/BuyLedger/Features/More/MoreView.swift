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
    
    // MARK: - View Properties
    
    /// App 根層級 store
    @Bindable var store: StoreOf<RootFeature>
    
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
    /// - Parameter kind: 要呈現的主檔種類
    /// - Returns: 對應的主檔管理畫面，或解析失敗時的載入失敗視圖
    @ViewBuilder
    func lookupManagementDestination(for kind: LookupKind) -> some View {
        if let managementStore = store.scope(
            state: \.lookupManagements[id: kind], action: \.lookupManagements[id: kind]
        ) {
            LookupManagementView(store: managementStore)
        } else {
            BLLoadFailureView(message: "無法載入主檔管理頁面，請稍後再試。") {}
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
                .accessibilityIdentifier(
                    BLAccessibilityID.More.row(
                        RootFeature.MoreRoute.fx.accessibilityKey
                    )
                )
            }
            
            Section("管理") {
                NavigationLink(value: RootFeature.MoreRoute.customers) {
                    toolRow(.customers, palette: palette)
                }
                .accessibilityIdentifier(
                    BLAccessibilityID.More.row(
                        RootFeature.MoreRoute.customers.accessibilityKey
                    )
                )
                
                NavigationLink(value: RootFeature.MoreRoute.orderSources) {
                    toolRow(.orderSources, palette: palette)
                }
                .accessibilityIdentifier(
                    BLAccessibilityID.More.row(
                        RootFeature.MoreRoute.orderSources.accessibilityKey
                    )
                )
                
                NavigationLink(value: RootFeature.MoreRoute.categories) {
                    toolRow(.categories, palette: palette)
                }
                .accessibilityIdentifier(
                    BLAccessibilityID.More.row(
                        RootFeature.MoreRoute.categories.accessibilityKey
                    )
                )
                
                NavigationLink(value: RootFeature.MoreRoute.paymentMethods) {
                    toolRow(.paymentMethods, palette: palette)
                }
                .accessibilityIdentifier(
                    BLAccessibilityID.More.row(
                        RootFeature.MoreRoute.paymentMethods.accessibilityKey
                    )
                )
                
                NavigationLink(value: RootFeature.MoreRoute.reconciliationStatuses) {
                    toolRow(.reconciliationStatuses, palette: palette)
                }
                .accessibilityIdentifier(
                    BLAccessibilityID.More.row(
                        RootFeature.MoreRoute.reconciliationStatuses.accessibilityKey
                    )
                )
                
                NavigationLink(value: RootFeature.MoreRoute.quote) {
                    toolRow(.quote, palette: palette)
                }
                .accessibilityIdentifier(
                    BLAccessibilityID.More.row(
                        RootFeature.MoreRoute.quote.accessibilityKey
                    )
                )
            }
            
            Section("App") {
                NavigationLink(value: RootFeature.MoreRoute.settings) {
                    Label {
                        Text("設定").font(BLTypographyStyle.body.font.weight(.medium))
                    } icon: {
                        Image(systemName: "gear")
                            .foregroundStyle(palette.secondaryLabel)
                    }
                }
                .accessibilityIdentifier(
                    BLAccessibilityID.More.row(
                        RootFeature.MoreRoute.settings.accessibilityKey
                    )
                )
            }
        }
        .accessibilityIdentifier(BLAccessibilityID.More.root)
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
            Text(LocalizedStringKey(item.title)).font(BLTypographyStyle.body.font.weight(.medium))
        } icon: {
            Image(systemName: item.systemImage)
                .foregroundStyle(item.tint(in: palette))
        }
    }
}

// MARK: - Accessibility Properties

private extension RootFeature.MoreRoute {
    
    /// 對應到 UI 測試 identifier 的目的地 key
    var accessibilityKey: BLAccessibilityID.More.Row {
        switch self {
        case .fx:
                .fx
        case .customers:
                .customers
        case .quote:
                .quote
        case .orderSources:
                .orderSources
        case .categories:
                .categories
        case .paymentMethods:
                .paymentMethods
        case .reconciliationStatuses:
                .reconciliationStatuses
        case .settings:
                .settings
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
