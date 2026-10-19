//
//  BLFilterChip.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/20.
//

import SwiftUI

/// 篩選膠囊：訂單列表的狀態、日期、類別與付款方式篩選共用
struct BLFilterChip: View {

    // MARK: - Properties

    /// 點擊時的動作
    let action: () -> Void

    /// 選用的前綴 SF Symbol 名稱
    var icon: String?

    /// 是否撐滿可用寬度並允許換行 (trigger 類膠囊使用)
    var isExpanded: Bool

    /// 是否為選取狀態
    let isSelected: Bool

    /// 字級與水平內距的尺寸
    var size: Size

    /// 選取態的語意配色
    var style: Style

    /// 膠囊顯示的文字
    let title: LocalizedStringKey

    /// 選用的尾端 SF Symbol 名稱
    var trailingIcon: String?

    // MARK: - Init

    /// 建立篩選膠囊，保留動作作為最後一個參數
    ///
    /// - Parameters:
    ///   - icon: 選用的前綴圖示
    ///   - isExpanded: 是否撐滿寬度並允許換行
    ///   - isSelected: 是否為選取狀態
    ///   - size: 字級與水平內距的尺寸
    ///   - style: 選取態的語意配色
    ///   - title: 膠囊顯示的文字
    ///   - trailingIcon: 選用的尾端圖示
    ///   - action: 點擊時的動作
    init(
        icon: String? = nil,
        isExpanded: Bool = false,
        isSelected: Bool,
        size: Size = .standard,
        style: Style = .inverted,
        title: LocalizedStringKey,
        trailingIcon: String? = nil,
        action: @escaping () -> Void
    ) {
        self.action = action
        self.icon = icon
        self.isExpanded = isExpanded
        self.isSelected = isSelected
        self.size = size
        self.style = style
        self.title = title
        self.trailingIcon = trailingIcon
    }

    // MARK: - Body

    /// 篩選膠囊的畫面內容
    var body: some View {
        Button(action: action) {
            BLFilterChipLabel(
                icon: icon,
                isExpanded: isExpanded,
                isSelected: isSelected,
                size: size,
                style: style,
                title: title,
                trailingIcon: trailingIcon
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Nested Types

extension BLFilterChip {

    /// 膠囊選取態的語意配色
    enum Style {

        /// 以反白呈現選取 (狀態篩選)
        case inverted

        /// 以強調色呈現選取 (日期區間篩選)
        case accent

        /// 以輔助強調色呈現選取 (類別、付款方式與整合篩選)
        case purple
    }

    /// 膠囊的字級與水平內距
    enum Size {

        /// `.footnote` 加 12pt 水平內距 (regular 版面)
        case standard

        /// `.subheadline` 加 14pt 水平內距 (compact 版面)
        case large
    }
}

// MARK: - Preview

#Preview("篩選膠囊") {
    VStack(alignment: .leading, spacing: BLSpacing.medium) {
        HStack(spacing: BLSpacing.small) {
            BLFilterChip(isSelected: true, title: "common.action.label.all") {
            }

            BLFilterChip(isSelected: false, title: "customers.list.label.quoting") {
            }

            BLFilterChip(
                icon: "calendar",
                isSelected: true,
                style: .accent,
                title: "orders.list.label.month"
            ) {
            }
        }

        BLFilterChip(
            icon: "line.3.horizontal.decrease",
            isExpanded: true,
            isSelected: false,
            size: .large,
            style: .purple,
            title: "篩選: 全部",
            trailingIcon: "chevron.down"
        ) {
        }
    }
    .padding()
}
