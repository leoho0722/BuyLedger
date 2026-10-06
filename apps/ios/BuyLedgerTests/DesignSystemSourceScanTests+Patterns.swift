//
//  DesignSystemSourceScanTests+Patterns.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/5.
//

import Foundation

// MARK: - Properties

extension DesignSystemSourceScanTests {

    /// 規則一：資訊性文字不得直接使用系統次要色
    static let secondaryColorPattern = makePattern(
        #"\bforegroundStyle\(\.secondary\)|\bforegroundColor\(\.secondary\)|\bColor\.secondary\b"#
    )

    /// 規則二：禁止直接使用系統強調色
    static let accentColorPattern = makePattern(
        #"\bColor\.accentColor\b|(?<![\w)])\.accentColor\b"#
    )

    /// 規則三：掃描命名系統色的直接使用
    static let namedHueTokenPattern = makePattern(
        #"(?<![\w)])\.(red|green|blue|orange|yellow|purple|pink|teal|indigo|mint|cyan|brown|gray)\b|\bColor\.(red|green|blue|orange|yellow|purple|pink|teal|indigo|mint|cyan|brown|gray)\b"#
    )

    /// 規則四：系統取色 API 只准在色盤檔
    static let systemColorAPIPattern = makePattern(#"(?<!\w)Color\(uiColor:|\bUIColor(?:\(|\.)"#)

    /// 規則九：幣別名稱查表只准在唯一入口
    static let currencyLookupPattern = makePattern(#"\blocalizedString\s*\(\s*forCurrencyCode\b"#)

    /// 規則十：語言判斷只准在 `AppLanguage`
    static let languageDerivationPattern = makePattern(#"\blanguageCode\s*\?\s*\.\s*identifier"#)

    /// 規則十一：比對建模詞法形式之外的尺寸分類引用，掃描範圍與限制見規則十一測試
    static let sizeClassReferencePattern = makePattern(#"\b(?:horizontal|vertical)SizeClass\b"#)

    /// 規則五：從原始分量建構色彩，僅色盤檔與頭像元件可用
    static let rawConstructionPattern = makePattern(
        #"(?<!\w)Color\(blHex|(?<!\w)Color\(\s*\.sRGB|(?<!\w)Color\(\s*red:|(?<!\w)Color\(\s*hue:|(?<!\w)UIColor\(\s*red:"#
    )

    /// 規則六：外觀環境依賴宣告，僅卡片陰影修飾子可用
    static let colorSchemeDeclarationPattern = makePattern(#"@Environment\(\\\.colorScheme\)"#)

    /// 規則七：十六進位顏色建構子，全庫零命中 (含宣告本身)
    static let hexInitializerPattern = makePattern(#"init\(blHex|Color\(blHex"#)
}

// MARK: - Private Method

private extension DesignSystemSourceScanTests {

    /// 建立內建掃描樣式，無效的規則文字會中止執行
    ///
    /// - Parameter pattern: 程式碼中固定的規則文字
    /// - Returns: 可重複使用的正規表示式
    /// - Note: 內建樣式無效代表程式碼錯誤，因此直接中止而不略過規則
    static func makePattern(_ pattern: String) -> NSRegularExpression {
        do {
            return try NSRegularExpression(pattern: pattern)
        } catch {
            preconditionFailure("設計系統掃描樣式無效：\(error.localizedDescription)")
        }
    }
}
