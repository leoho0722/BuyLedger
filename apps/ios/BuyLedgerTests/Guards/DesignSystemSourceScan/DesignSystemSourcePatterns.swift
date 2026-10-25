//
//  DesignSystemSourcePatterns.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/5.
//

import Foundation

/// 提供設計系統守門使用的正規表示式
enum DesignSystemSourcePatterns {

    // MARK: - Properties

    /// 規則一：資訊性文字直接使用系統次要色的寫法
    static let secondaryColorPattern = makePattern(
        #"\bforegroundStyle\(\.secondary\)|\bforegroundColor\(\.secondary\)|\bColor\.secondary\b"#
    )

    /// 規則二：直接使用系統強調色的寫法
    static let accentColorPattern = makePattern(
        #"\bColor\.accentColor\b|(?<![\w)])\.accentColor\b"#
    )

    /// 規則三：具名系統色相的直接使用
    static let namedHueTokenPattern = makePattern(
        #"(?<![\w)])\.(red|green|blue|orange|yellow|purple|pink|teal|indigo|mint|cyan|brown|gray)\b|\bColor\.(red|green|blue|orange|yellow|purple|pink|teal|indigo|mint|cyan|brown|gray)\b"#
    )

    /// 規則四：系統取色介面的呼叫
    static let systemColorAPIPattern = makePattern(#"(?<!\w)Color\(uiColor:|\bUIColor(?:\(|\.)"#)

    /// 規則九：幣別名稱查表的呼叫
    static let currencyLookupPattern = makePattern(#"\blocalizedString\s*\(\s*forCurrencyCode\b"#)

    /// 規則十：以 `languageCode` 推導語言的寫法
    static let languageDerivationPattern = makePattern(#"\blanguageCode\s*\?\s*\.\s*identifier"#)

    /// 規則十一：尺寸分類的引用，掃描範圍與限制見規則十一測試
    static let sizeClassReferencePattern = makePattern(#"\b(?:horizontal|vertical)SizeClass\b"#)

    /// 規則五：從原始分量建構色彩的寫法
    static let rawConstructionPattern = makePattern(
        #"(?<!\w)Color\(blHex|(?<!\w)Color\(\s*\.sRGB|(?<!\w)Color\(\s*red:|(?<!\w)Color\(\s*hue:|(?<!\w)UIColor\(\s*red:"#
    )

    /// 規則六：外觀環境依賴的宣告
    static let colorSchemeDeclarationPattern = makePattern(#"@Environment\(\\\.colorScheme\)"#)

    /// 規則七：十六進位顏色建構子，全庫零命中 (含宣告本身)
    static let hexInitializerPattern = makePattern(#"init\(blHex|Color\(blHex"#)

    /// 規則十二：`@ScaledMetric` 屬性宣告，第一組為 `private`／`fileprivate` 修飾、第二組為屬性名稱
    static let scaledMetricDeclarationPattern = makePattern(
        #"@ScaledMetric(?:\([^)]*\))?\s+((?:private|fileprivate)\s+)?var\s+(\w+)"#
    )

    /// 規則十二：以單一識別字為值的具名引數，第一組為引數標籤、第二組為識別字
    static let labeledIdentifierArgumentPattern = makePattern(#"\b(\w+):\s*(\w+)\b(?!\s*[.(])"#)
}

// MARK: - Private Method

private extension DesignSystemSourcePatterns {

    /// 建立內建掃描樣式，無效的規則文字會中止執行
    ///
    /// - Parameter pattern: 程式碼中固定的規則文字
    /// - Returns: 可重複使用的正規表示式
    /// - Note: 內建樣式無效代表程式碼錯誤，因此直接中止而不略過規則
    static func makePattern(_ pattern: String) -> NSRegularExpression {
        do {
            return try NSRegularExpression(pattern: pattern)
        } catch {
            // 內建樣式是寫死的常數，無效代表程式碼錯誤，不能略過規則
            preconditionFailure("設計系統掃描樣式無效：\(error.localizedDescription)")
        }
    }
}
