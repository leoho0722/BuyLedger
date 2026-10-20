//
//  OrderListSnapshotSourceScanTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import Foundation
import Testing

@testable import BuyLedger

/// 訂單清單快照的單次篩選與畫面資料傳遞守門
struct OrderListSnapshotSourceScanTests {

    /// 快照計算只篩選一次，識別值不得觸發第二次篩選
    ///
    /// - Throws: 原始碼讀取、方法定位或正規表示式建立失敗時拋出
    @Test
    func listSnapshot_建立清單快照_僅呼叫一次篩選() throws {
        // Given
        let source = try Self.source(named: "OrdersListQuery.swift")

        // When
        let body = try Self.body(of: "static func listSnapshot(", in: source)

        // Then
        #expect(try Self.count(#"\bfilteredOrders\b"#, in: body) == 1)
    }

    /// 清單狀態只轉交快照計算，不額外呼叫篩選
    ///
    /// - Throws: 原始碼讀取、方法定位或正規表示式建立失敗時拋出
    @Test
    func listSnapshot_清單狀態入口_只轉交一次快照計算() throws {
        // Given
        let source = try Self.source(named: "OrderListFeature.swift")

        // When
        let body = try Self.body(of: "func listSnapshot()", in: source)

        // Then
        #expect(try Self.count(#"\bOrdersListQuery\s*\.\s*listSnapshot\s*\("#, in: body) == 1)
        #expect(try Self.count(#"\bfilteredOrders\b"#, in: body) == 0)
    }

    /// 兩種版面只取得一次快照，清單與工具列重用快照中的值
    ///
    /// - Parameters:
    ///   - file: 畫面檔名
    ///   - declaration: 要檢查的畫面建構單元
    /// - Throws: 原始碼讀取、單元定位或正規表示式建立失敗時拋出
    @Test(arguments: [
        ("OrdersCompactView.swift", "var navigationContent: some View"),
        ("OrdersView.swift", "var regularListContent: some View"),
    ])
    func listSnapshot_兩種版面路徑_各取一次快照且重用工具列值(file: String, declaration: String) throws {
        // Given
        let source = try Self.source(named: file)
        let selectionPattern = #"\blistStore\s*\.\s*(?:filteredIDs|isAllFilteredSelected)\b"#

        // When
        let body = try Self.body(of: declaration, in: source)

        // Then
        #expect(try Self.count(#"\blistSnapshot\s*\("#, in: body) == 1)
        #expect(try Self.count(#"\bfilteredOrders\b"#, in: body) == 0)
        #expect(try Self.count(selectionPattern, in: body) == 0)
        #expect(body.contains("orders: snapshot.orders"))
        #expect(body.contains("isAllFilteredSelected: snapshot.isAllSelected"))
        #expect(body.contains("filteredIDs: snapshot.ids"))
    }

    /// 日期分組與全選判斷只使用傳入結果，不再次篩選
    ///
    /// - Parameter declaration: 要檢查的輔助方法
    /// - Throws: 原始碼讀取、方法定位或正規表示式建立失敗時拋出
    @Test(arguments: ["static func dateSections(", "static func isAllFilteredSelected("])
    func dateSectionsAndSelection_輔助方法_不再次篩選(declaration: String) throws {
        // Given
        let source = try Self.source(named: "OrdersListQuery.swift")

        // When
        let body = try Self.body(of: declaration, in: source)

        // Then
        #expect(try Self.count(#"\bfilteredOrders\b"#, in: body) == 0)
    }
}

// MARK: - Private Method

private extension OrderListSnapshotSourceScanTests {

    /// 讀取 Orders 原始碼並沿用既有掃描器剝除註解與字串
    ///
    /// - Parameter name: Orders 目錄下的檔名
    /// - Returns: 可供方法定位與呼叫次數檢查的程式碼
    /// - Throws: 檔案無法讀取時拋出
    static func source(named name: String) throws -> String {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appending(path: "BuyLedger/Features/Orders")
            .appending(path: name)
        let text = try String(contentsOf: url, encoding: .utf8)
        var mode = DesignSystemSourceScanTests.StripMode.normal
        return text.components(separatedBy: "\n")
            .map {
                DesignSystemSourceScanTests.stripCommentsAndStrings(from: $0, mode: &mode)
            }
            .joined(separator: "\n")
    }

    /// 以配對大括號擷取指定宣告的本體，找不到時讓測試失敗
    ///
    /// - Parameters:
    ///   - declaration: 要定位的方法或屬性宣告
    ///   - source: 已剝除註解與字串的程式碼
    /// - Returns: 宣告的大括號內文
    /// - Throws: 宣告或配對大括號不存在時由 `#require` 丟出
    static func body(of declaration: String, in source: String) throws -> String {
        let range = try #require(source.range(of: declaration))
        let start = try #require(source[range.upperBound...].firstIndex(of: "{"))
        var depth = 0
        var end: String.Index?
        for index in source[start...].indices {
            if source[index] == "{" {
                depth += 1
            } else if source[index] == "}" {
                depth -= 1
                if depth == 0 {
                    end = index
                    break
                }
            }
        }
        let closingBrace = try #require(end)
        return String(source[source.index(after: start)..<closingBrace])
    }

    /// 計算方法本體中符合指定模式的次數
    ///
    /// - Parameters:
    ///   - pattern: 要搜尋的正規表示式
    ///   - body: 方法或畫面建構單元的本體
    /// - Returns: 命中次數
    /// - Throws: 正規表示式無法建立時拋出
    static func count(_ pattern: String, in body: String) throws -> Int {
        let expression = try NSRegularExpression(pattern: pattern)
        return expression.numberOfMatches(in: body, range: NSRange(body.startIndex..., in: body))
    }
}
