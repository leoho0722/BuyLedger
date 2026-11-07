//
//  PercentUpToOneFractionDigitFormatStyle.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/11/8.
//

import Foundation

/// 把比例格式化為最多一位小數的百分比，例如「0.015」顯示為「1.5%」
struct PercentUpToOneFractionDigitFormatStyle {

    // MARK: - Properties

    /// 百分比格式使用的 `locale`
    private let locale: Locale

    // MARK: - Init

    /// 建立百分比格式，使用指定的 `locale`
    ///
    /// - Parameter locale: App 顯示語言對應的 `locale`
    init(locale: Locale) {
        self.locale = locale
    }
}

// MARK: - FormatStyle

extension PercentUpToOneFractionDigitFormatStyle: FormatStyle {

    /// 把比例轉成依 `locale` 顯示、最多一位小數的百分比
    ///
    /// - Parameter value: 要格式化的比例
    /// - Returns: 百分比字串，整數不顯示小數位
    func format(_ value: Double) -> String {
        value.formatted(.percent.precision(.fractionLength(0...1)).locale(locale))
    }
}

// MARK: - Convenience

extension FormatStyle where Self == PercentUpToOneFractionDigitFormatStyle {

    /// 建立最多一位小數的百分比格式
    ///
    /// - Parameter locale: App 顯示語言對應的 `locale`
    /// - Returns: 使用指定 `locale` 的百分比格式
    static func percentUpToOneFractionDigit(locale: Locale) -> Self {
        Self(locale: locale)
    }
}
