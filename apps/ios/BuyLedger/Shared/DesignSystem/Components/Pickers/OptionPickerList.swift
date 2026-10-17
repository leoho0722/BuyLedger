//
//  OptionPickerList.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/20.
//

import SwiftUI

/// 顯示已過濾選項，依模式處理選取與清除後的返回
struct OptionPickerList: View {

    // MARK: - Properties

    /// 單選與清除後返回上一頁或關閉獨立 sheet
    @Environment(\.dismiss) private var dismiss

    /// 將原始值轉成顯示名稱；`nil` 時直接顯示原值
    ///
    /// - Parameter option: 選項的原始值
    /// - Returns: 選項的顯示文字
    let displayName: (@Sendable (String) -> String)?

    /// 沒有符合選項時顯示的文案
    let emptyState: OptionPickerSheet.EmptyState

    /// 已套用搜尋的選項清單
    let options: [String]

    /// 單選或多選的目前值與操作回呼
    let selection: OptionPickerSheet.Selection

    // MARK: - Body

    /// 組合清除選項、可選清單與空狀態
    var body: some View {
        Section {
            if case .single(let selected, _, let clear) = selection, let clear {
                listClearRow(clear, isSelected: selected.isEmpty)
            }

            if options.isEmpty {
                ContentUnavailableView(
                    LocalizedStringKey(emptyState.title),
                    systemImage: "tray",
                    description: Text(LocalizedStringKey(emptyState.description))
                )
            } else {
                ForEach(options, id: \.self) {
                    listOptionRow($0)
                }
            }
        }
    }
}

// MARK: - Private Views

private extension OptionPickerList {

    /// 清除選擇的列，尚未選取時顯示勾選
    ///
    /// - Parameters:
    ///   - clearOption: 清除列的文案與操作回呼
    ///   - isSelected: 目前是否尚未選取任何選項
    /// - Returns: 清除選項列
    func listClearRow(_ clearOption: OptionPickerSheet.ClearOption, isSelected: Bool) -> some View {
        Button {
            clearOption.onClear()
            dismiss()
        } label: {
            HStack(alignment: .firstTextBaseline) {
                Text(LocalizedStringKey(clearOption.title))
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    /// 可選的選項列，依選取模式顯示勾選
    ///
    /// - Parameter option: 該列代表的原始值
    /// - Returns: 可點選的選項列
    func listOptionRow(_ option: String) -> some View {
        Button {
            selectOption(option)
        } label: {
            HStack(alignment: .firstTextBaseline) {
                Text(displayText(for: option))
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                Spacer()

                if isSelected(option) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(BLAccessibilityID.OptionPicker.optionRow(option))
        .accessibilityAddTraits(isSelected(option) ? .isSelected : [])
    }
}

// MARK: - Private Method

private extension OptionPickerList {

    /// 取得單筆選項的顯示文字
    ///
    /// - Parameter option: 選項的原始值
    /// - Returns: 自訂名稱或原始值
    func displayText(for option: String) -> String {
        displayName?(option) ?? option
    }

    /// 判斷選項是否已選取
    ///
    /// - Parameter option: 要判斷的原始值
    /// - Returns: 是否應顯示勾選
    func isSelected(_ option: String) -> Bool {
        switch selection {
        case .single(let selected, _, _):
            return option == selected

        case .multiple(let selections, _):
            return selections.contains(option)
        }
    }

    /// 依模式選取或切換選項，單選後關閉選擇器
    ///
    /// - Parameter option: 使用者點選的原始值
    func selectOption(_ option: String) {
        switch selection {
        case .single(_, let onSelect, _):
            onSelect(option)
            dismiss()

        case .multiple(_, let onToggle):
            onToggle(option)
        }
    }
}

// MARK: - Preview

#Preview("單選選項清單") {
    List {
        OptionPickerList(
            displayName: nil,
            emptyState: .init(
                title: "orders.edit.label.categories",
                description: "orders.edit.message.addFirstCategory"
            ),
            options: ["3C", "美妝", "食品"],
            selection: .single(
                selected: "美妝",
                onSelect: { _ in
                }
            )
        )
    }
}
