//
//  MoreView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 更多分頁的入口清單與目前工具的分欄畫面
struct MoreView: View {

    // MARK: - Properties

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<MoreFeature>

    /// 根殼層傳入的顯示語系
    let language: AppLanguage

    // MARK: - Body

    /// 入口清單為內容欄，目前工具為詳情欄；寬度不足時由系統收合為堆疊
    var body: some View {
        NavigationSplitView {
            entryList
        } detail: {
            detailContent
        }
        // 主檔表單與提示掛在分欄層：詳情欄內的呈現在摺展時會被系統重新呈現，草稿與確認框會失去對應的呈現
        .background {
            lookupPresentations
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(BLAccessibilityID.Common.selectedItem(.more))
        .accessibilityValue(Text(verbatim: selectedRowKey))
    }
}

// MARK: - Private Views

private extension MoreView {

    /// 工具、管理項目與設定的入口清單，選取值由目前工具推導
    var entryList: some View {
        List(selection: selectionBinding) {
            Section("orders.list.label.tools") {
                entryRow(.fx)
            }

            Section("orders.detail.label.manage") {
                entryRow(.customers)

                entryRow(.lookup(.orderSource))

                entryRow(.lookup(.category))

                entryRow(.lookup(.paymentMethod))

                entryRow(.lookup(.reconciliationStatus))

                entryRow(.quote)
            }

            Section {
                entryRow(.settings)
            } header: {
                Text(verbatim: "App")
            }
        }
        .navigationSplitViewColumnWidth(min: 260, ideal: 300, max: 360)
        .listStyle(.insetGrouped)
        .navigationLinkIndicatorVisibility(.hidden)
        .accessibilityIdentifier(BLAccessibilityID.More.root)
        .rootNavigationTitle("common.action.label.more", language: language)
    }

    /// 建立可被選取的入口列，選取時標記為已選取，箭頭自繪以對齊基準外觀
    ///
    /// - Parameter entry: 更多頁目的地
    /// - Returns: 對應目的地的列
    func entryRow(_ entry: MoreFeature.Entry) -> some View {
        NavigationLink(value: entry) {
            HStack {
                // 標題不指定前景色，讓選取列由系統套用對應的單色前景
                Label {
                    Text(entryTitle(for: entry))
                        .font(BLTypographyStyle.body.font.weight(.medium))
                } icon: {
                    Image(systemName: entrySystemImage(for: entry))
                        .font(BLTypographyStyle.body.font)
                        .foregroundStyle(entryTint(for: entry))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(BLTypographyStyle.footnote.font.weight(.semibold))
                    .foregroundStyle(.blSecondaryLabel)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityIdentifier(accessibilityRow(for: entry))
        .accessibilityAddTraits(store.currentEntry == entry ? .isSelected : [])
    }

    /// 目前工具的導覽宿主；沒有目前工具時顯示未選取提示
    @ViewBuilder
    var detailContent: some View {
        if let pathID = store.path.ids.last,
           let toolStore = store.scope(state: \.path[id: pathID], action: \.path[id: pathID]) {
            NavigationStack {
                toolView(for: toolStore)
            }
            // 切換工具時重建堆疊，清掉前一個工具推入的子頁；同一工具重選 ID 不變
            .id(pathID)
        } else {
            ContentUnavailableView(
                "common.navigation.detailEmptyState",
                systemImage: "square.grid.2x2",
                description: Text("common.navigation.selectItemPrompt")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.blBackground)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(BLAccessibilityID.Common.detailEmptyState)
        }
    }

    /// 依目前工具的種類呈現對應畫面
    ///
    /// - Parameter destinationStore: 目前工具的導覽元素 store
    /// - Returns: 對應工具的畫面
    @ViewBuilder
    func toolView(for destinationStore: StoreOf<MoreFeature.Path>) -> some View {
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

    /// 目前工具為主檔管理時的表單與提示宿主，其他工具或沒有選取時不呈現
    @ViewBuilder
    var lookupPresentations: some View {
        if let lookupStore = currentLookupStore {
            LookupManagementPresentations(store: lookupStore)
        }
    }
}

// MARK: - Private Method

private extension MoreView {

    /// 清單選取值由目前工具推導；使用者選取時只送出入口意圖
    var selectionBinding: Binding<MoreFeature.Entry?> {
        Binding {
            store.currentEntry
        } set: {
            store.send(.view(.entrySelected($0)))
        }
    }

    /// 目前工具為主檔管理時的子 store，其他工具或沒有選取時為 `nil`
    var currentLookupStore: StoreOf<LookupManagementFeature>? {
        guard let pathID = store.path.ids.last,
              let toolStore = store.scope(state: \.path[id: pathID], action: \.path[id: pathID]),
              case .lookupManagement(let lookupStore) = toolStore.case else {
            return nil
        }
        return lookupStore
    }

    /// 目前工具對應的目的地 key，未開啟工具時為空字串
    var selectedRowKey: String {
        guard let entry = store.currentEntry else {
            return ""
        }
        return rowKey(for: entry).rawValue
    }

    /// 回傳更多頁目的地的標題
    ///
    /// - Parameter entry: 更多頁目的地
    /// - Returns: 目的地標題
    func entryTitle(for entry: MoreFeature.Entry) -> LocalizedStringResource {
        switch entry {
        case .fx:
            return "settings.more.label.exchangeRates"

        case .customers:
            return "settings.more.label.customers"

        case .quote:
            return "settings.more.label.quoteCalculator"

        case .lookup(let kind):
            return kind.entryTitle

        case .settings:
            return "orders.edit.title.settings"
        }
    }

    /// 回傳更多頁目的地的 SF Symbol
    ///
    /// - Parameter entry: 更多頁目的地
    /// - Returns: 對應的 SF Symbol 名稱
    func entrySystemImage(for entry: MoreFeature.Entry) -> String {
        switch entry {
        case .fx:
            return "dollarsign.arrow.circlepath"

        case .customers:
            return "person.2"

        case .quote:
            return "function"

        case .lookup(let kind):
            return kind.systemImage

        case .settings:
            return "gear"
        }
    }

    /// 回傳更多頁目的地的圖示色彩
    ///
    /// - Parameter entry: 更多頁目的地
    /// - Returns: 對應的圖示色彩
    func entryTint(for entry: MoreFeature.Entry) -> Color {
        switch entry {
        case .fx:
            return .blAccent

        case .customers:
            return .blPurple

        case .quote:
            return .blGreen

        case .lookup(let kind):
            switch kind {
            case .orderSource:
                return .blTeal

            case .category:
                return .blOrange

            case .paymentMethod:
                return .blRed

            case .reconciliationStatus:
                return .blIndigo
            }

        case .settings:
            return .blSecondaryLabel
        }
    }

    /// 回傳更多頁目的地列的 accessibility identifier
    ///
    /// - Parameter entry: 更多頁目的地
    /// - Returns: 對應目的地列的 accessibility identifier
    func accessibilityRow(for entry: MoreFeature.Entry) -> String {
        BLAccessibilityID.More.row(rowKey(for: entry))
    }

    /// 回傳入口對應的列識別 key
    ///
    /// - Parameter entry: 更多頁目的地
    /// - Returns: 與 accessibility 列識別一致的 key
    func rowKey(for entry: MoreFeature.Entry) -> BLAccessibilityID.More.Row {
        switch entry {
        case .fx:
            return .fx

        case .customers:
            return .customers

        case .quote:
            return .quote

        case .lookup(let kind):
            switch kind {
            case .orderSource:
                return .orderSources

            case .category:
                return .categories

            case .paymentMethod:
                return .paymentMethods

            case .reconciliationStatus:
                return .reconciliationStatuses
            }

        case .settings:
            return .settings
        }
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
