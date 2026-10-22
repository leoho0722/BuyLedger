//
//  BLUITestSeedData+Builders.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/17.
//

import Foundation

#if DEBUG

// MARK: - Internal Method

extension BLUITestSeedData {

    /// 建立測試訂單，未指定的欄位一律使用固定值
    ///
    /// - Parameters:
    ///   - id: 訂單編號
    ///   - customer: 訂單客戶
    ///   - status: 訂單狀態
    ///   - currency: 商品幣別，預設新台幣
    ///   - date: 訂單日期
    ///   - items: 商品項目
    ///   - itemCost: 折合新台幣的商品成本
    ///   - orderSource: 訂單來源，預設「蝦皮」
    ///   - categories: 商品類別，預設「美妝」
    ///   - paymentMethod: 付款方式，預設「信用卡」
    ///   - chargedAmount: 實際收款金額
    ///   - domesticShipping: 國內運費，預設 60
    ///   - internationalShipping: 國際運費，預設 280
    ///   - foreignDomesticShipping: 外國國內運費，預設 0
    ///   - campaignNames: 歸屬開團，預設未歸團
    ///   - paymentReceiptStatus: 收款狀態，預設待收款
    ///   - photos: 訂單照片，預設無照片
    ///   - mergedSourceIDs: 合併前的來源訂單編號，預設無來源
    /// - Returns: 組出的單筆訂單
    static func makeOrder(
        id: String,
        customer: LedgerCustomer,
        status: OrderStatus,
        currency: CurrencyCode = CurrencyCode(rawValue: "TWD"),
        date: Date,
        items: [LedgerOrderItem],
        itemCost: Decimal,
        orderSource: String = "蝦皮",
        categories: [String] = ["美妝"],
        paymentMethod: String = "信用卡",
        chargedAmount: Decimal,
        domesticShipping: Decimal = 60,
        internationalShipping: Decimal = 280,
        foreignDomesticShipping: Decimal = 0,
        campaignNames: [String] = [],
        paymentReceiptStatus: PaymentReceiptStatus = .pending,
        photos: [Data] = [],
        mergedSourceIDs: [LedgerOrder.ID] = []
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: customer,
            status: status,
            currency: currency,
            date: date,
            items: items,
            itemCost: itemCost,
            domesticShipping: domesticShipping,
            internationalShipping: internationalShipping,
            foreignDomesticShipping: foreignDomesticShipping,
            cardFeeRate: Decimal(sign: .plus, exponent: -3, significand: 15),
            platformFeeRate: 0,
            paymentFeeRate: 0,
            chargedAmount: chargedAmount,
            cardlessDeductionAmount: 0,
            cardlessSupplementAmount: 0,
            orderSource: orderSource,
            categories: categories,
            paymentMethod: paymentMethod,
            notes: "",
            reconciliationStatus: "",
            campaignNames: campaignNames,
            paymentReceiptStatus: paymentReceiptStatus,
            isCashOnDelivery: false,
            photos: photos,
            mergedSourceIDs: mergedSourceIDs
        )
    }

    /// 以既有訂單為基礎建立副本
    ///
    /// - Parameters:
    ///   - order: 來源訂單
    ///   - date: 改寫後的訂單日期
    ///   - campaignNames: 改寫後的開團名稱，`nil` 代表沿用
    ///   - paymentReceiptStatus: 改寫後的收款狀態，`nil` 代表沿用
    /// - Returns: 套用改寫後重建的訂單
    static func rebuild(
        _ order: LedgerOrder,
        date: Date,
        campaignNames: [String]? = nil,
        paymentReceiptStatus: PaymentReceiptStatus? = nil
    ) -> LedgerOrder {
        LedgerOrder(
            id: order.id,
            customer: order.customer,
            status: order.status,
            currency: order.currency,
            date: date,
            items: order.items,
            itemCost: order.itemCost,
            domesticShipping: order.domesticShipping,
            internationalShipping: order.internationalShipping,
            foreignDomesticShipping: order.foreignDomesticShipping,
            cardFeeRate: order.cardFeeRate,
            platformFeeRate: order.platformFeeRate,
            paymentFeeRate: order.paymentFeeRate,
            chargedAmount: order.chargedAmount,
            cardlessDeductionAmount: order.cardlessDeductionAmount,
            cardlessSupplementAmount: order.cardlessSupplementAmount,
            orderSource: order.orderSource,
            categories: order.categories,
            paymentMethod: order.paymentMethod,
            notes: order.notes,
            reconciliationStatus: order.reconciliationStatus,
            campaignNames: campaignNames ?? order.campaignNames,
            paymentReceiptStatus: paymentReceiptStatus ?? order.paymentReceiptStatus,
            isCashOnDelivery: order.isCashOnDelivery,
            photos: order.photos,
            mergedSourceIDs: order.mergedSourceIDs
        )
    }

    /// 建立測試客戶
    ///
    /// - Parameters:
    ///   - name: 客戶顯示名稱
    ///   - initials: 頭像縮寫
    ///   - tier: 客戶分級，預設一般常客
    /// - Returns: 組出的客戶
    static func makeCustomer(
        _ name: String,
        _ initials: String,
        tier: CustomerTier = .regular
    ) -> LedgerCustomer {
        LedgerCustomer(name: name, initials: initials, tier: tier)
    }

    /// 建立商品項目，`id` 由 `seed` 推導以避免呼叫 `UUID()`
    ///
    /// - Parameters:
    ///   - seed: 決定 `id` 的固定序號
    ///   - name: 商品名稱
    ///   - quantity: 商品數量
    ///   - unitPrice: 原始幣別單價
    /// - Returns: 組出的商品項目
    static func makeItem(
        seed: Int,
        name: String,
        quantity: Int,
        unitPrice: Decimal
    ) -> LedgerOrderItem {
        let uuidString = String(format: "0000BEEF-0000-4000-8000-%012d", seed)
        // seed 由呼叫端寫死為非負整數，組不出 UUID 代表種子定義錯誤
        guard let identifier = UUID(uuidString: uuidString) else {
            preconditionFailure("[BuyLedger][UITest] 商品 seed \(seed) 無法組成 UUID")
        }

        return LedgerOrderItem(
            id: identifier,
            name: name,
            quantity: quantity,
            unitPrice: unitPrice
        )
    }

    /// 取參考日往前若干天的當日零時 (傳負值即往後推)
    ///
    /// - Parameters:
    ///   - daysBefore: 往前推的天數
    ///   - referenceDate: 基準時間點
    /// - Returns: 基準往前指定天數的日期
    static func date(daysBefore: Int, from referenceDate: Date) -> Date {
        let start = calendar.startOfDay(for: referenceDate)

        // 西曆 UTC 加減整天不會失敗，失敗代表行事曆設定錯誤
        guard let date = calendar.date(byAdding: .day, value: -daysBefore, to: start) else {
            preconditionFailure("[BuyLedger][UITest] 無法推導 \(daysBefore) 天前的日期")
        }

        return date
    }

    /// 取得參考日前指定月份的當日零時
    ///
    /// - Parameters:
    ///   - monthsBefore: 往前推的月數
    ///   - referenceDate: 基準時間點
    /// - Returns: 基準往前指定月數的日期
    static func date(monthsBefore: Int, from referenceDate: Date) -> Date {
        let start = calendar.startOfDay(for: referenceDate)

        // 西曆 UTC 加減整月不會失敗，失敗代表行事曆設定錯誤
        guard let date = calendar.date(byAdding: .month, value: -monthsBefore, to: start) else {
            preconditionFailure("[BuyLedger][UITest] 無法推導 \(monthsBefore) 個月前的日期")
        }

        return date
    }

    /// 產生第 `index` 張測試照片的 JPEG bytes
    ///
    /// - Parameter index: 照片序號
    /// - Returns: 產生的假 JPEG 位元資料
    static func makePhotoData(index: Int) -> Data {
        guard let base = Data(base64Encoded: minimalJPEGBase64), base.count > 2 else {
            print("[BuyLedger][UITest] 內建 JPEG base64 解碼失敗，第 \(index) 張照片改寫入空資料")

            return Data()
        }

        var data = Data(base.prefix(2))
        data.append(contentsOf: [0xFF, 0xFE, 0x00, 0x03, UInt8(index & 0xFF)])
        data.append(Data(base.dropFirst(2)))

        return data
    }
}

#endif
