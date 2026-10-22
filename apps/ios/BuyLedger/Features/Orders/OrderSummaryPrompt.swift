//
//  OrderSummaryPrompt.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/7.
//

import Foundation

/// 將已篩選訂單轉成 AI 摘要的商品明細與提示文字
enum OrderSummaryPrompt {

}

// MARK: - Internal Method

extension OrderSummaryPrompt {

    /// 組出指示模型以正體中文總結商品明細的完整提示
    ///
    /// - Parameters:
    ///   - orders: 已套用篩選的訂單
    ///   - selectedCategories: 提示文字顯示的類別集合；空集合代表全部類別
    /// - Returns: 保留原有文字與空行的提示
    static func summaryPrompt(orders: [LedgerOrder], selectedCategories: Set<String>) -> String {
        let categoryNames = selectedCategories.sorted { lhs, rhs in
            lhs.localizedStandardCompare(rhs) == .orderedAscending
        }
        let categoryScope: String
        if categoryNames.isEmpty {
            categoryScope = "(涵蓋目前列表所有類別)"
        } else {
            categoryScope = "(已篩選類別：\(categoryNames.joined(separator: "、")))"
        }
        return """
            你是個人代購 App 的分析助理。以下是目前訂單列表的商品明細\(categoryScope)，每行格式為「- [類別] 商品名稱 x數量 @ 單價 幣別」：

            \(itemsDigest(orders: orders))

            請用正體中文、以 Markdown 格式總結這些商品明細，內容包含：
            - 一個 `##` 層級的標題
            - 各品項的品名以及購買的總數量 (如果品名有編號的話，請照編號排序；如果沒有編號的話，請照字母順序排序)

            請以條列與粗體強調重點，全文控制在約 200–300 字。只根據上面提供的資料作答，不要杜撰未出現的商品、數字或結論。
            """
    }
}

// MARK: - Private Method

private extension OrderSummaryPrompt {

    /// 整理前二百個品項，保留原有格式與空明細提示
    ///
    /// - Parameter orders: 已套用篩選的訂單
    /// - Returns: 給模型的商品明細文字
    static func itemsDigest(orders: [LedgerOrder]) -> String {
        let maxItems = 200
        var lines: [String] = []

        outer: for order in orders {
            let categoryNames = order.categories
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            let categoryTag = categoryNames.isEmpty ? "未分類" : categoryNames.joined(separator: "、")
            let currency = order.currency.rawValue
            for item in order.items {
                let trimmedName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
                let name = trimmedName.isEmpty ? "未命名商品" : trimmedName
                lines.append(
                    "- [\(categoryTag)] \(name) x\(item.quantity) @ \(item.unitPrice) \(currency)"
                )
                if lines.count >= maxItems {
                    break outer
                }
            }
        }

        guard !lines.isEmpty else {
            return "(目前列表沒有任何商品明細)"
        }

        var digest = lines.joined(separator: "\n")
        let totalItems = orders.reduce(0) { count, order in
            count + order.items.count
        }
        if totalItems > lines.count {
            digest += "\n…(其餘 \(totalItems - lines.count) 個品項未列出)"
        }
        return digest
    }
}
