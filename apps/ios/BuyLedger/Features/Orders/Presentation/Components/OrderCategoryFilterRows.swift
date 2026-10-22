//
//  OrderCategoryFilterRows.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/19.
//

import ComposableArchitecture
import SwiftUI

/// 提供類別區共用的固定列，不綁 store，由宿主以 binding 與 closure 溝通
enum OrderCategoryFilterRows {

}

// MARK: - Nested Types

extension OrderCategoryFilterRows {

    /// 呈現類別搜尋的普通列，固定識別並同步宿主的搜尋焦點
    struct SearchRow: View {

        /// 元件內的搜尋欄焦點，與宿主的焦點狀態雙向同步
        @FocusState private var isFieldFocused: Bool

        /// 宿主的搜尋欄焦點狀態
        @Binding var isSearchFieldFocused: Bool

        /// 搜尋文字
        @Binding var searchText: String

        /// 清除搜尋鈕的 accessibility identifier
        let clearIdentifier: String

        /// 搜尋欄與列的固定 identifier
        let fieldIdentifier: String

        /// 清除搜尋文字的動作
        let onClear: () -> Void

        /// return 送出搜尋的動作
        let onSubmit: () -> Void

        /// 列設定放在最外層，避免被其他修飾覆寫
        var body: some View {
            HStack(spacing: BLSpacing.small) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.blSecondaryLabel)
                    .accessibilityHidden(true)

                TextField("orders.filter.placeholder.searchCategories", text: $searchText)
                    .textFieldStyle(.plain)
                    .focused($isFieldFocused)
                    .submitLabel(.search)
                    .onSubmit(onSubmit)
                    .accessibilityIdentifier(fieldIdentifier)

                if !searchText.isEmpty {
                    clearButton
                }
            }
            .padding(.horizontal, BLSpacing.small)
            .frame(maxWidth: .infinity, minHeight: BLHitTarget.minimum)
            .blTextStyle(.body)
            .foregroundStyle(.blLabel)
            .bind($isSearchFieldFocused, to: $isFieldFocused)
            .id(fieldIdentifier)
            .listRowInsets(.all, 0)
            .listRowBackground(Capsule().fill(.blFillTertiary))
            .listRowSeparator(.hidden)
        }

        /// 搜尋文字清除入口，焦點與宿主的選取值保持原值
        private var clearButton: some View {
            Button {
                onClear()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .frame(minWidth: BLHitTarget.minimum, minHeight: BLHitTarget.minimum)
                    .foregroundStyle(.blSecondaryLabel)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("orders.filter.button.clearSearch"))
            .accessibilityIdentifier(clearIdentifier)
        }
    }

    /// 呈現「全部」列與無符合類別時的空狀態列，由宿主放在同一個 section 內
    struct AllAndEmptyRows: View {

        /// 「全部」列的 accessibility identifier
        let allIdentifier: String

        /// 是否沒有任何選取類別，為真時「全部」列標記為已選取
        let isAllSelected: Bool

        /// 目前分組是否為空，為真時顯示空狀態列
        let isEmpty: Bool

        /// 點「全部」列的動作
        let onAllTapped: () -> Void

        /// 「全部」列在前，空狀態列在後
        var body: some View {
            Button {
                onAllTapped()
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: BLSpacing.small) {
                    Image(systemName: "tag")
                        .foregroundStyle(.blAccent)
                        .accessibilityHidden(true)

                    Text("common.action.label.all")
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(.blLabel)

                    Spacer()

                    if isAllSelected {
                        Image(systemName: "checkmark")
                            .foregroundStyle(.blAccent)
                            .accessibilityHidden(true)
                    }
                }
                .frame(maxWidth: .infinity, minHeight: BLHitTarget.minimum, alignment: .leading)
                .blTextStyle(.body)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isAllSelected ? .isSelected : [])
            .accessibilityIdentifier(allIdentifier)

            if isEmpty {
                ContentUnavailableView(
                    "orders.list.label.matchingCategories",
                    systemImage: "tray",
                    description: Text("orders.filter.message.tryAnotherSearch")
                )
            }
        }
    }
}
