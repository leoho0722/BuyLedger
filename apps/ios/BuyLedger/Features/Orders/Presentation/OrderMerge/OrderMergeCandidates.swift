//
//  OrderMergeCandidates.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

/// 合併候選訂單的資格規則，純計算不讀取依賴值
enum OrderMergeCandidates {

}

// MARK: - Internal Method

extension OrderMergeCandidates {

    /// 依資格規則過濾可合併的候選訂單
    ///
    /// - Parameters:
    ///   - primary: 主訂單
    ///   - orders: 全部訂單
    /// - Returns: 符合資格的候選清單 (維持輸入順序)
    static func eligible(for primary: LedgerOrder, in orders: [LedgerOrder]) -> [LedgerOrder] {
        orders.filter { isEligible($0, for: primary) }
    }
}

// MARK: - Private Method

private extension OrderMergeCandidates {

    /// 判斷單筆訂單是否符合合併候選資格
    ///
    /// - Parameters:
    ///   - candidate: 待檢查的候選訂單
    ///   - primary: 發起合併的主訂單
    /// - Returns: 候選訂單符合所有合併規則時為 `true`
    /// - Note: 狀態條件由 `OrderStatusRules.canMerge(status:)` 判斷
    static func isEligible(_ candidate: LedgerOrder, for primary: LedgerOrder) -> Bool {
        guard candidate.id != primary.id else {
            return false
        }
        guard OrderStatusRules.canMerge(status: candidate.status) else {
            return false
        }
        guard candidate.currency == primary.currency else {
            return false
        }
        return candidate.customer.name == primary.customer.name
    }
}
