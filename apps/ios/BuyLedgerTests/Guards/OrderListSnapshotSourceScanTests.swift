//
//  OrderListSnapshotSourceScanTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/18.
//

import Foundation
import Testing

/// 訂單清單快照的單元測試，以原始碼文字檢查快照只篩選一次、畫面沿用快照結果
struct OrderListSnapshotSourceScanTests {

    /// 驗證 `listSnapshot` 只出現一次 `filteredOrders`，取得識別值時不另外篩選
    ///
    /// - Throws: 原始碼讀取、方法定位或正規表示式建立失敗時丟出
    @Test
    func listSnapshot_建立清單快照_僅呼叫一次篩選() throws {
        // Given
        let source = try Self.source(named: "Presentation/OrderList/Queries/OrdersListQuery.swift")

        // When
        let body = try Self.body(of: "static func listSnapshot(", in: source)

        // Then
        #expect(try Self.count(#"\bfilteredOrders\b"#, in: body) == 1)
    }

    /// 驗證清單狀態的 `listSnapshot()` 只呼叫一次 `OrdersListQuery.listSnapshot`，本體不直接篩選
    ///
    /// - Throws: 原始碼讀取、方法定位或正規表示式建立失敗時丟出
    @Test
    func listSnapshot_清單狀態入口_只轉交一次快照計算() throws {
        // Given
        let source = try Self.source(named: "Presentation/OrderList/OrderListFeature.swift")

        // When
        let body = try Self.body(of: "func listSnapshot()", in: source)

        // Then
        #expect(try Self.count(#"\bOrdersListQuery\s*\.\s*listSnapshot\s*\("#, in: body) == 1)
        #expect(try Self.count(#"\bfilteredOrders\b"#, in: body) == 0)
    }

    /// 驗證 compact 與 regular 兩種版面各只呼叫一次 `listSnapshot`，不直接讀取篩選結果，並把快照的值傳給清單與工具列
    ///
    /// - Parameter layoutCase: 畫面檔名與要檢查的建構單元
    /// - Throws: 原始碼讀取、單元定位或正規表示式建立失敗時丟出
    @Test(arguments: [
        OrdersLayoutCase(
            file: "Presentation/Root/Views/OrdersCompactView.swift",
            declaration: "var navigationContent: some View"
        ),
        OrdersLayoutCase(
            file: "Presentation/Root/Views/OrdersView.swift",
            declaration: "var regularListContent: some View"
        ),
    ])
    func listSnapshot_兩種版面路徑_各取一次快照且重用工具列值(layoutCase: OrdersLayoutCase) throws {
        // Given
        let source = try Self.source(named: layoutCase.file)
        let selectionPattern = #"\blistStore\s*\.\s*(?:filteredIDs|isAllFilteredSelected)\b"#

        // When
        let body = try Self.body(of: layoutCase.declaration, in: source)

        // Then
        #expect(try Self.count(#"\blistSnapshot\s*\("#, in: body) == 1)
        #expect(try Self.count(#"\bfilteredOrders\b"#, in: body) == 0)
        #expect(try Self.count(selectionPattern, in: body) == 0)
        #expect(body.contains("orders: snapshot.orders"))
        #expect(body.contains("isAllFilteredSelected: snapshot.isAllSelected"))
        #expect(body.contains("filteredIDs: snapshot.ids"))
    }

    /// 驗證日期分組與全選判斷的輔助方法本體不再次篩選，只使用傳入的結果
    ///
    /// - Parameter declaration: 要檢查的輔助方法
    /// - Throws: 原始碼讀取、方法定位或正規表示式建立失敗時丟出
    @Test(arguments: ["static func dateSections(", "static func isAllFilteredSelected("])
    func dateSectionsAndSelection_輔助方法_不再次篩選(declaration: String) throws {
        // Given
        let source = try Self.source(named: "Presentation/OrderList/Queries/OrdersListQuery.swift")

        // When
        let body = try Self.body(of: declaration, in: source)

        // Then
        #expect(try Self.count(#"\bfilteredOrders\b"#, in: body) == 0)
    }
}

// MARK: - Nested Types

extension OrderListSnapshotSourceScanTests {

    /// 訂單版面的來源檔名與要檢查的建構單元
    struct OrdersLayoutCase: Sendable {

        /// 畫面檔名
        let file: String

        /// 要檢查的畫面建構單元
        let declaration: String
    }
}

// MARK: - Private Method

private extension OrderListSnapshotSourceScanTests {

    /// 讀取 Orders 原始碼並沿用既有掃描器剝除註解與字串
    ///
    /// - Parameter name: Orders 目錄下的檔名
    /// - Returns: 可供方法定位與呼叫次數檢查的程式碼
    /// - Throws: 檔案無法讀取時丟出
    static func source(named name: String) throws -> String {
        let url = TestPaths.iosRoot
            .appending(path: "BuyLedger/Features/Orders")
            .appending(path: name)
        let text = try String(contentsOf: url, encoding: .utf8)
        var mode = DesignSystemSourceLexer.StripMode.normal
        return text.components(separatedBy: "\n")
            .map {
                DesignSystemSourceLexer.stripCommentsAndStrings(from: $0, mode: &mode)
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
    /// - Throws: 正規表示式無法建立時丟出
    static func count(_ pattern: String, in body: String) throws -> Int {
        let expression = try NSRegularExpression(pattern: pattern)
        return expression.numberOfMatches(in: body, range: NSRange(body.startIndex..., in: body))
    }
}
