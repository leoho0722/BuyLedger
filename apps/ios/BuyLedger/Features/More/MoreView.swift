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

    /// 更多頁自己的導覽與子畫面 store
    @Bindable var store: StoreOf<MoreFeature>

    /// 根殼層傳入的顯示語系
    let language: AppLanguage

    // MARK: - Body

    /// 包含更多頁清單與堆疊目的地的導覽容器
    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
            entryList
        } destination: { destinationStore in
            switch destinationStore.case {
            case .customers(let customersStore):
                CustomersView(store: customersStore)

            case .fx(let fxStore):
                FxView(store: fxStore)

            case .lookupManagement(let managementStore):
                LookupManagementView(store: managementStore)

            case .quote(let quoteStore):
                QuoteView(store: quoteStore)

            case .settings(let settingsStore):
                SettingsView(store: settingsStore)
            }
        }
    }
}

// MARK: - Private Views

private extension MoreView {

    /// 顯示工具、管理項目與設定的列表內容
    @ViewBuilder
    var entryList: some View {
        List {
            Section("orders.list.label.tools") {
                entryButton(.fx)
            }

            Section("orders.detail.label.manage") {
                entryButton(.customers)

                entryButton(.orderSources)

                entryButton(.categories)

                entryButton(.paymentMethods)

                entryButton(.reconciliationStatuses)

                entryButton(.quote)
            }

            Section {
                entryButton(.settings)
            } header: {
                Text(verbatim: "App")
            }
        }
        .accessibilityIdentifier(BLAccessibilityID.More.root)
        .rootNavigationTitle("common.action.label.more", language: language)
    }

    /// 建立保留系統按壓高亮的入口列與 accessibility identifier
    ///
    /// - Parameter entry: 更多頁目的地
    /// - Returns: 對應目的地的導覽列
    func entryButton(_ entry: MoreFeature.Entry) -> some View {
        Button {
            store.send(.view(.entryTapped(entry)))
        } label: {
            HStack {
                Label {
                    Text(LocalizedStringKey(entryTitle(for: entry)))
                        .font(BLTypographyStyle.body.font.weight(.medium))
                        .foregroundStyle(palette.label)
                } icon: {
                    Image(systemName: entrySystemImage(for: entry))
                        .foregroundStyle(entryTint(for: entry))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(BLTypographyStyle.footnote.font.weight(.semibold))
                    .foregroundStyle(palette.secondaryLabel)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityIdentifier(accessibilityRow(for: entry))
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
    /// - Parameter entry: 更多頁目的地
    /// - Returns: 目的地標題
    func entryTitle(for entry: MoreFeature.Entry) -> String {
        switch entry {
        case .fx:
            "settings.more.label.exchangeRates"

        case .customers:
            "settings.more.label.customers"

        case .quote:
            "settings.more.label.quoteCalculator"

        case .orderSources:
            LookupKind.orderSource.entryTitle

        case .categories:
            LookupKind.category.entryTitle

        case .paymentMethods:
            LookupKind.paymentMethod.entryTitle

        case .reconciliationStatuses:
            LookupKind.reconciliationStatus.entryTitle

        case .settings:
            "orders.edit.title.settings"
        }
    }

    /// 回傳更多頁目的地的 SF Symbol
    ///
    /// - Parameter entry: 更多頁目的地
    /// - Returns: 對應的 SF Symbol 名稱
    func entrySystemImage(for entry: MoreFeature.Entry) -> String {
        switch entry {
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
    /// - Parameter entry: 更多頁目的地
    /// - Returns: 對應的圖示色彩
    func entryTint(for entry: MoreFeature.Entry) -> Color {
        switch entry {
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
    /// - Parameter entry: 更多頁目的地
    /// - Returns: 對應目的地列的 accessibility identifier
    func accessibilityRow(for entry: MoreFeature.Entry) -> String {
        let row: BLAccessibilityID.More.Row
        switch entry {
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

#Preview("common.action.label.more") {
    MoreView(
        store: Store(initialState: MoreFeature.State(appVersion: "1.0")) {
            MoreFeature()
        },
        language: .traditionalChinese
    )
}
