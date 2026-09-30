//
//  OptionPickerList.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/20.
//

import SwiftUI

/// 顯示已過濾選項的清單區段
struct OptionPickerList: View {

    // MARK: - Properties

    /// 已由 OptionPickerSheet 過濾後的選項清單
    let options: [String]

    /// 目前已選中的選項；用來在列表中顯示勾選
    let selected: String

    /// 顯示用名稱轉換；nil 時直接顯示 option
    let displayName: (@Sendable (String) -> String)?

    /// 可選的「清除目前選擇」row 設定
    let clearOption: OptionPickerSheet.ClearOption?

    /// 可選的多選模式設定
    let multiSelection: OptionPickerSheet.MultiSelection?

    /// 使用者選擇既有選項時的回呼
    let onSelect: (String) -> Void

    /// 沒有任何選項時 ContentUnavailableView 的標題
    let emptyTitle: String

    /// 沒有任何選項時 ContentUnavailableView 的描述
    let emptyDescription: String

    // MARK: - Body

    /// 選項清單內容，包含清除、勾選與空狀態
    var body: some View {
        Section {
            if let clearOption {
                listClearRow(clearOption)
            }

            if options.isEmpty {
                ContentUnavailableView(
                    LocalizedStringKey(emptyTitle),
                    systemImage: "tray",
                    description: Text(LocalizedStringKey(emptyDescription))
                )
            } else {
                ForEach(options, id: \.self) { option in
                    listOptionRow(option)
                }
            }
        }
    }
}

// MARK: - Private Views

private extension OptionPickerList {

    /// 清除選項的 row；空字串時顯示勾選
    /// - Parameter clearOption: 已設定的 clear row 設定
    /// - Returns: 清除選項列畫面
    @ViewBuilder
    func listClearRow(_ clearOption: OptionPickerSheet.ClearOption) -> some View {
        Button {
            clearOption.onClear()
        } label: {
            HStack(alignment: .firstTextBaseline) {
                Text(LocalizedStringKey(clearOption.title))
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)

                Spacer()

                if selected.isEmpty {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected.isEmpty ? .isSelected : [])
    }

    /// 選項 row；單選後關閉，多選後保留 sheet
    /// - Parameter option: 該列代表的選項字串
    /// - Returns: 選項列畫面
    @ViewBuilder
    func listOptionRow(_ option: String) -> some View {
        Button {
            onSelect(option)
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

    /// 取得單筆選項的顯示字串
    /// - Parameter option: 原始選項值
    /// - Returns: 顯示文字
    func displayText(for option: String) -> String {
        displayName?(option) ?? option
    }

    /// 判斷選項是否已選取
    /// - Parameter option: 要判斷的選項
    /// - Returns: 是否已選取
    func isSelected(_ option: String) -> Bool {
        if let multiSelection {
            return multiSelection.selections.contains(option)
        }
        return option == selected
    }
}
