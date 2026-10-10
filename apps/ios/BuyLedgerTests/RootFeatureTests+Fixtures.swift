//
//  RootFeatureTests+Fixtures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation

@testable import BuyLedger

// MARK: - Internal Method

extension RootFeatureTests {

    /// 依任意順序接收啟動時的五筆載入請求：啟動、訂單與開團各一筆，外加訂單與開團的轉送兩筆
    ///
    /// - Parameter store: 已送出啟動事件的測試 `store`
    static func receiveLaunchLoadRequests(in store: TestStoreOf<RootFeature>) async {
        for _ in 0..<5 {
            await store.receive { action in
                if case .orders(.loadRequested) = action {
                    return true
                }
                if case .orders(.load(.loadRequested)) = action {
                    return true
                }
                if case .campaigns(.loadRequested) = action {
                    return true
                }
                if case .campaigns(.load(.loadRequested)) = action {
                    return true
                }
                if case .launch(.loadRequested) = action {
                    return true
                }
                return false
            }
        }
    }

    /// 建立只指定類別的測試訂單
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - category: 商品類別
    ///   - customerName: 客戶名稱
    /// - Returns: 建立的測試訂單
    static func makeTestOrder(id: String, category: String, customerName: String) -> LedgerOrder {
        makeTestOrder(id: id, categories: [category], customerName: customerName)
    }

    /// 建立支援多類別與多開團的測試訂單
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - categories: 商品類別
    ///   - customerName: 客戶名稱
    ///   - campaignNames: 開團名稱
    /// - Returns: 建立的測試訂單
    static func makeTestOrder(
        id: String,
        categories: [String],
        customerName: String,
        campaignNames: [String] = []
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: customerName, initials: "TC", tier: .new),
            status: .purchased,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: "測試",
            categories: categories,
            paymentMethod: "",
            notes: "",
            reconciliationStatus: "",
            campaignNames: campaignNames,
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }

    /// 以獨立的記憶體儲存建立根狀態，讓會改寫共用清單的測試不影響其他測試
    ///
    /// - Parameters:
    ///   - lookupKind: 要預先開啟的清單種類，未提供時更多頁保持空白
    ///   - build: 建立根狀態的操作
    /// - Returns: 建立完成的測試狀態
    static func makeIsolatedRootState(
        lookupKind: LookupKind? = nil,
        _ build: () -> RootFeature.State = { RootFeature.State() }
    ) -> RootFeature.State {
        withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            var state = build()
            if let lookupKind {
                state.more.path.append(
                    .lookupManagement(LookupManagementFeature.State(kind: lookupKind))
                )
            }
            return state
        }
    }

    /// 建立已載入開團並記下指定日期與行事曆的開團列表，供根功能的日期刷新測試使用
    ///
    /// - Parameters:
    ///   - campaigns: 列表已載入的開團
    ///   - recordedDate: 列表先前記錄的現在時間
    ///   - calendar: 列表先前記錄的行事曆
    /// - Returns: 帶有開團與日期資訊的根狀態
    static func makeCampaignDateState(
        campaigns: [Campaign],
        recordedDate: Date,
        calendar: Calendar
    ) -> RootFeature.State {
        var state = RootFeature.State()
        state.campaigns.$campaigns.withLock { $0 = campaigns }
        state.campaigns.load.$hasLoaded.withLock {
            $0 = true
        }
        state.campaigns.list.dateContext = CampaignDateContext(
            now: recordedDate,
            calendar: calendar
        )
        return state
    }

    /// 複製訂單並只替換指定欄位，其餘欄位保留原值
    ///
    /// - Parameters:
    ///   - order: 原始訂單
    ///   - orderSource: 新的訂單來源，未提供時保留原值
    ///   - categories: 新的商品類別，未提供時保留原值
    ///   - paymentMethod: 新的付款方式，未提供時保留原值
    ///   - reconciliationStatus: 新的對帳狀態，未提供時保留原值
    ///   - cardlessDeductionAmount: 新的無卡折抵金額，未提供時保留原值
    ///   - cardlessSupplementAmount: 新的無卡補收金額，未提供時保留原值
    ///   - isCashOnDelivery: 新的貨到付款旗標，未提供時保留原值
    ///   - campaignNames: 新的開團名稱，未提供時保留原值
    ///   - paymentReceiptStatus: 新的收款狀態，未提供時保留原值
    /// - Returns: 套用指定欄位後的訂單
    static func rebuiltOrder(
        _ order: LedgerOrder,
        orderSource: String? = nil,
        categories: [String]? = nil,
        paymentMethod: String? = nil,
        reconciliationStatus: String? = nil,
        cardlessDeductionAmount: Decimal? = nil,
        cardlessSupplementAmount: Decimal? = nil,
        isCashOnDelivery: Bool? = nil,
        campaignNames: [String]? = nil,
        paymentReceiptStatus: PaymentReceiptStatus? = nil
    ) -> LedgerOrder {
        LedgerOrder(
            id: order.id,
            customer: order.customer,
            status: order.status,
            currency: order.currency,
            date: order.date,
            items: order.items,
            itemCost: order.itemCost,
            domesticShipping: order.domesticShipping,
            internationalShipping: order.internationalShipping,
            foreignDomesticShipping: order.foreignDomesticShipping,
            cardFeeRate: order.cardFeeRate,
            platformFeeRate: order.platformFeeRate,
            paymentFeeRate: order.paymentFeeRate,
            chargedAmount: order.chargedAmount,
            cardlessDeductionAmount: cardlessDeductionAmount ?? order.cardlessDeductionAmount,
            cardlessSupplementAmount: cardlessSupplementAmount ?? order.cardlessSupplementAmount,
            orderSource: orderSource ?? order.orderSource,
            categories: categories ?? order.categories,
            paymentMethod: paymentMethod ?? order.paymentMethod,
            notes: order.notes,
            reconciliationStatus: reconciliationStatus ?? order.reconciliationStatus,
            campaignNames: campaignNames ?? order.campaignNames,
            paymentReceiptStatus: paymentReceiptStatus ?? order.paymentReceiptStatus,
            isCashOnDelivery: isCashOnDelivery ?? order.isCashOnDelivery,
            photos: order.photos,
            mergedSourceIDs: order.mergedSourceIDs
        )
    }

    /// 建立可指定來源、類別、付款方式與對帳狀態的最小訂單
    ///
    /// - Parameters:
    ///   - id: 訂單識別值
    ///   - orderSource: 訂單來源
    ///   - categories: 商品類別
    ///   - paymentMethod: 付款方式
    ///   - reconciliationStatus: 對帳狀態
    /// - Returns: 建立的測試訂單
    static func makeOrder(
        id: String,
        orderSource: String = "",
        categories: [String] = [],
        paymentMethod: String = "",
        reconciliationStatus: String = ""
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: LedgerCustomer(name: "同步測試", initials: "SY", tier: .new),
            status: .purchased,
            currency: .twd,
            date: TestDependencies.fixedNow,
            items: [],
            itemCost: 0,
            domesticShipping: 0,
            internationalShipping: 0,
            foreignDomesticShipping: 0,
            cardFeeRate: 0,
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: 0,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: orderSource,
            categories: categories,
            paymentMethod: paymentMethod,
            notes: "",
            reconciliationStatus: reconciliationStatus,
            campaignNames: [],
            paymentReceiptStatus: .pending,
            isCashOnDelivery: false,
            photos: [],
            mergedSourceIDs: []
        )
    }
}
