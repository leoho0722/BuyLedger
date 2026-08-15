//
//  OrdersFeature+StateQuery.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/8/2.
//

import Foundation
import SwiftUI

// MARK: - Computed Properties

extension OrdersFeature.State {
    
    /// 依選取模式產生導覽標題 key
    var navigationTitleKey: String.LocalizationValue {
        guard isSelecting else {
            return "訂單"
        }
        guard !selectedOrderIDs.isEmpty else {
            return "選擇訂單"
        }
        return "已選 \(selectedOrderIDs.count) 筆"
    }
    
    /// 已套用的三欄篩選值
    var committedFilterSelection: PendingFilterSelection {
        PendingFilterSelection(
            datePeriod: selectedDatePeriod,
            category: selectedCategory,
            paymentMethod: selectedPaymentMethod
        )
    }
    
    /// 整合篩選是否有尚未套用的變更
    var hasUnappliedFilterChanges: Bool {
        pendingFilterSelection != committedFilterSelection
    }
    
    /// 整合篩選 sheet 的付款方式清單
    var filterSheetFilteredCategories: [String] {
        let trimmed = filterSheetSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return availableCategories
        }
        return availableCategories.filter { $0.localizedStandardContains(trimmed) }
    }
    
    /// 整合篩選 sheet 的付款方式清單
    var filterSheetFilteredPaymentMethods: [String] {
        let names = availablePaymentMethods.map(\.name)
        let trimmed = filterSheetSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return names
        }
        return names.filter { $0.localizedStandardContains(trimmed) }
    }
}

// MARK: - Internal Method

extension OrdersFeature.State {
    
    /// 套用搜尋、狀態與日期區間篩選後的訂單
    /// - Parameters:
    ///   - referenceDate: 計算「本週／本月／上月」等相對區間的基準時間
    ///   - calendar: 判斷日期區間的行事曆
    /// - Returns: 過濾後的訂單
    func filteredOrders(referenceDate: Date, calendar: Calendar) -> [LedgerOrder] {
        let normalizedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        let campaignStatusByName = Self.campaignStatusByName(campaigns)
        
        return orders.filter { order in
            guard selectedStatus.orderStatus.map({ $0 == order.status }) ?? true else {
                return false
            }
            guard
                selectedDatePeriod.includes(
                    order.date, referenceDate: referenceDate, calendar: calendar)
            else {
                return false
            }
            guard selectedCategory.map({ order.categories.contains($0) }) ?? true else {
                return false
            }
            guard selectedPaymentMethod.map({ $0 == order.paymentMethod }) ?? true else {
                return false
            }
            guard selectedCampaign.map({ order.campaignNames.contains($0) }) ?? true else {
                return false
            }
            if let selectedCampaignStatus {
                let matchesCampaignStatus = order.campaignNames.contains { name in
                    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else {
                        return false
                    }
                    return campaignStatusByName[trimmed] == selectedCampaignStatus
                }
                guard matchesCampaignStatus else {
                    return false
                }
            }
            return normalizedQuery.isEmpty || order.searchableText.contains(normalizedQuery)
        }
    }
    
    /// 目前選取的訂單
    /// - Parameters:
    ///   - referenceDate: 篩選使用的基準時間
    ///   - calendar: 與 ``filteredOrders(referenceDate:calendar:)`` 同一行事曆
    /// - Returns: 對應訂單；找不到時回傳第一筆
    func selectedOrder(referenceDate: Date, calendar: Calendar) -> LedgerOrder? {
        let filtered = filteredOrders(referenceDate: referenceDate, calendar: calendar)
        guard let selectedOrderID else {
            return filtered.first
        }
        return filtered.first { $0.id == selectedOrderID }
    }
    
    /// 將訂單依日期分組
    /// - Parameters:
    ///   - referenceDate: 篩選使用的基準時間
    ///   - calendar: 與 ``filteredOrders(referenceDate:calendar:)`` 同一行事曆
    ///   - locale: App 選定、用於日期區段標題的 locale
    /// - Returns: 依日期由新到舊排序的區段；每段內訂單亦由新到舊排序
    func dateSections(
        referenceDate: Date,
        calendar: Calendar,
        locale: Locale
    ) -> [OrderDateSection] {
        OrderDateSection.group(
            filteredOrders(referenceDate: referenceDate, calendar: calendar),
            referenceDate: referenceDate,
            calendar: calendar,
            locale: locale
        )
    }
    
    /// 把目前篩選後訂單的商品明細整理成給模型的純文字摘要輸入
    /// - Parameters:
    ///   - referenceDate: 篩選使用的基準時間
    ///   - calendar: 與 ``filteredOrders(referenceDate:calendar:)`` 同一行事曆
    /// - Returns: 商品明細的純文字摘要；列表沒有任何品項時回傳提示字串
    func aiItemsDigest(referenceDate: Date, calendar: Calendar) -> String {
        let maxItems = 200
        let filtered = filteredOrders(referenceDate: referenceDate, calendar: calendar)
        var lines: [String] = []
        
        outer: for order in filtered {
            let categoryNames = order.categories
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            let categoryTag = categoryNames.isEmpty ? "未分類" : categoryNames.joined(separator: "、")
            for item in order.items {
                let trimmedName = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
                let name = trimmedName.isEmpty ? "未命名商品" : trimmedName
                lines.append(
                    "- [\(categoryTag)] \(name) x\(item.quantity) @ "
                    + "\(item.unitPrice) \(order.currency.rawValue)"
                )
                if lines.count >= maxItems { break outer }
            }
        }
        
        guard !lines.isEmpty else {
            return "(目前列表沒有任何商品明細)"
        }
        
        var digest = lines.joined(separator: "\n")
        let totalItems = filtered.reduce(0) { $0 + $1.items.count }
        if totalItems > lines.count {
            digest += "\n…(其餘 \(totalItems - lines.count) 個品項未列出)"
        }
        return digest
    }
    
    /// 組出指示模型以正體中文 Markdown 總結商品明細的完整 prompt
    /// - Parameters:
    ///   - referenceDate: 篩選使用的基準時間
    ///   - calendar: 與 ``filteredOrders(referenceDate:calendar:)`` 同一行事曆
    /// - Returns: 給 Ollama 的 user prompt
    func aiSummaryPrompt(referenceDate: Date, calendar: Calendar) -> String {
        let categoryScope = selectedCategory.map { "(已篩選類別：\($0))" } ?? "(涵蓋目前列表所有類別)"
        return """
            你是個人代購 App 的分析助理。以下是目前訂單列表的商品明細\(categoryScope)，每行格式為「- [類別] 商品名稱 x數量 @ 單價 幣別」：
            
            \(aiItemsDigest(referenceDate: referenceDate, calendar: calendar))
            
            請用正體中文、以 Markdown 格式總結這些商品明細，內容包含：
            - 一個 `##` 層級的標題
            - 各品項的品名以及購買的總數量 (如果品名有編號的話，請照編號排序；如果沒有編號的話，請照字母順序排序)
            
            請以條列與粗體強調重點，全文控制在約 200–300 字。只根據上面提供的資料作答，不要杜撰未出現的商品、數字或結論。
            """
    }
}

// MARK: - Private Method

private extension OrdersFeature.State {
    
    /// 建立開團狀態字典，供篩選快速查找
    /// - Parameter campaigns: 目前所有開團
    /// - Returns: 開團名稱到狀態的字典
    static func campaignStatusByName(_ campaigns: [Campaign]) -> [String: CampaignStatus] {
        var result: [String: CampaignStatus] = [:]
        for campaign in campaigns where result[campaign.name] == nil {
            result[campaign.name] = campaign.status
        }
        return result
    }
}
