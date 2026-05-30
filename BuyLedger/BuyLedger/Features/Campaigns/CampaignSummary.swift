//
//  CampaignSummary.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import Foundation

/// 開團分貨清單中的單一客戶列。
///
/// 由歸屬某開團的訂單依客戶名稱 (去頭尾空白) 分組彙總而來；本型別不保存任何持久化資料。
struct CampaignDistributionRow: Equatable, Identifiable, Sendable {

    // MARK: - Identifiable Properties

    /// 以客戶名稱作為穩定識別值 (同一開團內客戶名稱唯一)。
    var id: String { customerName }

    // MARK: - Data Properties

    /// 客戶名稱 (已去頭尾空白)。
    let customerName: String

    /// 該客戶在此開團所有訂單的商品件數加總。
    let totalQuantity: Int

    /// 該客戶在此開團所有訂單的實收金額 (chargedAmount) 加總。
    let totalAmount: Decimal

    /// 是否全部已收款：該客戶在此開團的所有訂單收款狀態皆為 ``PaymentReceiptStatus/received`` 時為 `true`。
    let isFullyReceived: Bool

    /// 該客戶在此開團的訂單；供詳情頁展開檢視品項與逐筆收款。
    let orders: [LedgerOrder]
}

/// 開團 (Campaign) 的分貨與結算彙總。
///
/// 完全 derive 自歸屬該開團的訂單 (單一真實來源，零雙重輸入)：依客戶名稱分組產生分貨清單；以 ``LedgerOrder/chargedAmount`` 為基準算收款面 (應收／已收／未收)；重用 ``OrderSummary`` 加總算損益面 (成本／毛利／利潤率)；到貨進度以 ``OrderStatus/delivered`` 比例 (分母排除 ``OrderStatus/cancelled``)。所有彙總皆不依賴「現在」時間。
struct CampaignSummary: Equatable, Sendable {

    // MARK: - Data Properties

    /// 歸屬此開團的訂單。
    let memberOrders: [LedgerOrder]

    /// 訂單筆數。
    let orderCount: Int

    /// 商品件數加總。
    let totalItemQuantity: Int

    /// 應收總額 (Σ chargedAmount)。
    let receivables: Decimal

    /// 已收金額 (Σ chargedAmount，收款狀態為已收款者)。
    let receivedAmount: Decimal

    /// 未收金額 (應收 − 已收)。
    let outstandingAmount: Decimal

    /// 已收比例 (已收 / 應收)；應收為 0 時為 0，不除以零。
    let receivedRatio: Double

    /// 總成本 (Σ ``OrderSummary/totalCost``)。
    let totalCost: Decimal

    /// 總實際收款 (Σ ``OrderSummary/revenue``)，作為利潤率分母。
    let totalRevenue: Decimal

    /// 毛利 (Σ ``OrderSummary/profit``)。
    let profit: Decimal

    /// 利潤率 (毛利 / 總實際收款)；總實際收款為 0 時為 0，不除以零。
    let margin: Decimal

    /// 已交付訂單筆數。
    let deliveredCount: Int

    /// 未取消訂單筆數 (到貨進度分母)。
    let activeCount: Int

    /// 到貨進度 (已交付 / 未取消)；未取消筆數為 0 時為 0，不除以零。
    let deliveryRatio: Double

    /// 依客戶名稱分組的分貨清單，依客戶名稱排序。
    let distribution: [CampaignDistributionRow]

    // MARK: - Computed Properties

    /// 尚未全部收款的分貨列 (未付款名單)。
    var unpaidDistribution: [CampaignDistributionRow] {
        distribution.filter { !$0.isFullyReceived }
    }

    // MARK: - Init

    /// 依開團名稱與全部訂單建立彙總。
    /// - Parameters:
    ///   - campaignName: 開團名稱 (作為歸屬鍵)。
    ///   - allOrders: 全部訂單；本型別只取 ``LedgerOrder/campaignName`` 與其相符者。
    init(campaignName: String, orders allOrders: [LedgerOrder]) {
        let members = allOrders.filter { $0.campaignName == campaignName }
        self.memberOrders = members
        self.orderCount = members.count

        self.totalItemQuantity = members.reduce(0) { partial, order in
            partial + order.items.reduce(0) { $0 + $1.quantity }
        }

        self.receivables = members.reduce(0) { $0 + $1.chargedAmount }
        self.receivedAmount = members
            .filter { $0.paymentReceiptStatus == .received }
            .reduce(0) { $0 + $1.chargedAmount }
        self.outstandingAmount = receivables - receivedAmount
        self.receivedRatio = CampaignSummary.ratio(receivedAmount, of: receivables)

        let summaries = members.map { $0.summary }
        self.totalCost = summaries.reduce(0) { $0 + $1.totalCost }
        self.totalRevenue = summaries.reduce(0) { $0 + $1.revenue }
        self.profit = summaries.reduce(0) { $0 + $1.profit }
        self.margin = totalRevenue == 0 ? 0 : profit / totalRevenue

        self.deliveredCount = members.filter { $0.status == .delivered }.count
        self.activeCount = members.filter { $0.status != .cancelled }.count
        self.deliveryRatio = activeCount == 0
            ? 0
            : Double(deliveredCount) / Double(activeCount)

        self.distribution = CampaignSummary.makeDistribution(from: members)
    }

    // MARK: - Static Method

    /// 把成員訂單依客戶名稱 (去頭尾空白) 分組成分貨清單。
    /// - Parameter members: 歸屬此開團的訂單。
    /// - Returns: 依客戶名稱排序的分貨列。
    private static func makeDistribution(from members: [LedgerOrder]) -> [CampaignDistributionRow] {
        let grouped = Dictionary(grouping: members) {
            $0.customer.name.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return grouped
            .map { name, orders in
                let quantity = orders.reduce(0) { partial, order in
                    partial + order.items.reduce(0) { $0 + $1.quantity }
                }
                let amount = orders.reduce(0) { $0 + $1.chargedAmount }
                let fullyReceived = orders.allSatisfy { $0.paymentReceiptStatus == .received }
                return CampaignDistributionRow(
                    customerName: name,
                    totalQuantity: quantity,
                    totalAmount: amount,
                    isFullyReceived: fullyReceived,
                    orders: orders.sorted { $0.date > $1.date }
                )
            }
            .sorted { $0.customerName.localizedStandardCompare($1.customerName) == .orderedAscending }
    }

    /// 安全比例計算：分母為 0 時回傳 0，避免除以零。
    /// - Parameters:
    ///   - value: 分子。
    ///   - total: 分母。
    /// - Returns: `value / total` 的 `Double`；`total == 0` 時為 0。
    private static func ratio(_ value: Decimal, of total: Decimal) -> Double {
        guard total != 0 else { return 0 }
        return NSDecimalNumber(decimal: value).doubleValue / NSDecimalNumber(decimal: total).doubleValue
    }
}
