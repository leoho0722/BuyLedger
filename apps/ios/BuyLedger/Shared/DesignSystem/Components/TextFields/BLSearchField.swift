//
//  BLSearchField.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// 帶有搜尋圖示的輸入欄
struct BLSearchField: View {

    // MARK: - View Properties

    /// 目前系統深淺色外觀
    @Environment(\.colorScheme) private var colorScheme

    /// 欄位是否正在編輯 (取得焦點)，用來決定 `whenEditing` 模式下是否顯示清除按鈕
    @FocusState private var isEditing: Bool

    /// 欄位尚未輸入時顯示的提示文字
    let placeholder: String

    /// 欄位文字的雙向繫結
    @Binding var text: String

    /// 清除按鈕的顯示時機，預設為 `whenEditing`
    var clearButtonMode: ClearButtonMode = .whenEditing

    // MARK: - View Body

    /// 搜尋輸入欄的畫面內容
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)

        HStack(spacing: BLSpacing.small) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.secondaryLabel)

            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .focused($isEditing)

            if isClearButtonVisible {
                clearButton(palette: palette)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(palette.fillTertiary)
        .clipShape(
            RoundedRectangle(
                cornerRadius: BLRadius.small,
                style: .continuous
            )
        )
    }
}

// MARK: - Nested Types

extension BLSearchField {

    /// 清除按鈕的顯示時機，對應 UIKit `UITextField.ViewMode` 的常用子集
    enum ClearButtonMode {

        /// 永遠不顯示清除按鈕
        case never

        /// 僅在欄位取得焦點且有文字時顯示
        case whenEditing

        /// 只要欄位有文字就顯示，與是否取得焦點無關
        case always
    }
}

// MARK: - ViewBuilder

private extension BLSearchField {

    /// 依 ``ClearButtonMode`` 與目前文字、焦點狀態，決定是否顯示清除按鈕
    var isClearButtonVisible: Bool {
        guard !text.isEmpty else { return false }

        switch clearButtonMode {
        case .never:
            return false
        case .whenEditing:
            return isEditing
        case .always:
            return true
        }
    }

    /// 清空欄位文字的清除按鈕
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 清除按鈕 view
    @ViewBuilder
    func clearButton(palette: BLPalette) -> some View {
        Button {
            text = ""
            // 清除後保留焦點，讓鍵盤維持開啟以便接著輸入，比照原生搜尋欄的 whenEditing 行為
            isEditing = true
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.subheadline)
                .foregroundStyle(palette.secondaryLabel)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("清除搜尋")
    }
}

// MARK: - Preview

#Preview("搜尋輸入欄") {
    VStack(spacing: BLSpacing.medium) {
        BLSearchField(placeholder: "搜尋交易", text: .constant(""))

        BLSearchField(
            placeholder: "搜尋交易",
            text: .constant("咖啡"),
            clearButtonMode: .always
        )
    }
    .padding()
}
