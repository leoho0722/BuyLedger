//
//  BLUITestSeedData.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/24.
//

import Foundation
import SwiftData

#if DEBUG

/// 依 ``BLUITestSeedProfile`` 把確定性資料同步寫入 UI 測試用的 in-memory container
///
/// 一律用 `ModelContext(container)` 逐筆 insert 後 `save()`，不走 `@ModelActor`：後者是 async，畫面會在資料寫入前就先渲染
///
/// 所有日期由呼叫端傳入的 `referenceDate` 推導 (格里曆 + UTC)，不呼叫 `Date()` 或 `Calendar.current`
///
/// 金額約定：商品項目小計 (單價 × 數量) 一律等於該筆訂單折合新台幣的成本 `itemCost`，
/// 外幣訂單即小計乘上該幣別匯率的結果；收款金額 `chargedAmount` 另外給定、與小計無關
enum BLUITestSeedData {

    // MARK: - Static Properties

    /// 訂單來源主檔名稱 (4 筆)
    private static let orderSourceNames = ["蝦皮", "Instagram", "官方網站", "代購社團"]

    /// 商品類別主檔名稱 (4 筆)
    private static let categoryNames = ["美妝", "服飾", "精品", "生活雜貨"]

    /// 對帳狀態主檔名稱 (3 筆)
    private static let reconciliationStatusNames = ["待對帳", "對帳成功", "對帳失敗"]

    /// 付款方式主檔 (6 筆)，涵蓋無卡／銀行匯款／貨到付款三種旗標
    private static let paymentMethods: [(
        name: String,
        isCardless: Bool,
        isBankTransfer: Bool,
        isCashOnDelivery: Bool
    )] = [
        (name: "信用卡", isCardless: false, isBankTransfer: false, isCashOnDelivery: false),
        (name: "銀行轉帳", isCardless: false, isBankTransfer: true, isCashOnDelivery: false),
        (name: "無卡", isCardless: true, isBankTransfer: false, isCashOnDelivery: false),
        (name: "貨到付款", isCardless: false, isBankTransfer: false, isCashOnDelivery: true),
        (name: "LINE Pay", isCardless: false, isBankTransfer: false, isCashOnDelivery: false),
        (name: "Apple Pay", isCardless: false, isBankTransfer: false, isCashOnDelivery: false),
    ]

    /// 1×1 灰階 JPEG 的 base64 (141 bytes)，作為 `photos` profile 的照片基底
    private static let minimalJPEGBase64 = """
    /9j/2wBDAFA3PEY8MlBGQUZaVVBfeMiCeG5uePWvuZHI////////////////////\
    ////////////////////////////////wAALCAABAAEBAREA/8QAFAABAAAAAAAA\
    AAAAAAAAAAAAA//EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8Ad//Z
    """

    /// 種子資料共用的曆法 (格里曆 + UTC)，時區釘死才能與以 UTC 推導的日期一致
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt

        return calendar
    }()

    /// `makeItem` 解析 seed 失敗時的固定備援 id，避免呼叫 `UUID()` 引入隨機值
    private static let fallbackItemID = UUID(
        uuid: (0x00, 0x00, 0xBE, 0xEF, 0x00, 0x00, 0x40, 0x00, 0x80, 0x00, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF)
    )
}

// MARK: - Internal Method

extension BLUITestSeedData {

    /// 把指定 profile 的種子資料同步寫入 container
    ///
    /// 寫入失敗只印一行訊息、不 crash，讓 UI 測試能繼續跑到實際斷言
    /// - Parameters:
    ///   - profile: 要寫入的資料組合
    ///   - container: UI 測試用的 in-memory container
    ///   - referenceDate: 推導所有日期的基準時間點
    static func seed(_ profile: BLUITestSeedProfile, into container: ModelContainer, referenceDate: Date) {
        let context = ModelContext(container)
        populate(profile, in: context, referenceDate: referenceDate)

        do {
            try context.save()
        } catch {
            print("[BuyLedger][UITest] 種子資料寫入失敗：\(error)")
        }
    }
}

// MARK: - Private Method

private extension BLUITestSeedData {

    // MARK: 分派

    /// 依 profile 分派到各自的建構函式並逐筆 insert
    /// - Parameters:
    ///   - profile: 要寫入的資料組合
    ///   - context: 寫入用的 context
    ///   - referenceDate: 推導所有日期的基準時間點
    static func populate(_ profile: BLUITestSeedProfile, in context: ModelContext, referenceDate: Date) {
        switch profile {
        case .empty:
            break

        case .lookupsOnly:
            insertLookups(into: context)

        case .minimalOrders:
            insertLookups(into: context)
            insertOrders(makeMinimalOrders(referenceDate: referenceDate), into: context)

        case .fullOrders:
            insertLookups(into: context)
            insertOrders(makeFullOrders(referenceDate: referenceDate), into: context)

        case .campaignsWithOrders:
            insertLookups(into: context)
            let campaigns = makeCampaigns(referenceDate: referenceDate)
            for campaign in campaigns {
                context.insert(CampaignRecord(campaign: campaign))
            }
            insertOrders(makeCampaignOrders(referenceDate: referenceDate, campaigns: campaigns), into: context)

        case .mergeCandidates:
            insertLookups(into: context)
            insertOrders(makeMergeCandidateOrders(referenceDate: referenceDate), into: context)

        case .photos:
            insertLookups(into: context)
            insertOrders(makePhotoOrders(referenceDate: referenceDate), into: context)

        case .customerRanking:
            insertLookups(into: context)
            insertOrders(makeCustomerRankingOrders(referenceDate: referenceDate), into: context)

        case .insightsRange:
            insertLookups(into: context)
            insertOrders(makeInsightsRangeOrders(referenceDate: referenceDate), into: context)
        }
    }

    // MARK: 主檔

    /// 寫入四種主檔共 17 筆
    /// - Parameter context: 寫入用的 context
    static func insertLookups(into context: ModelContext) {
        for name in orderSourceNames {
            context.insert(OrderSourceRecord(name: name))
        }

        for name in categoryNames {
            context.insert(CategoryRecord(name: name))
        }

        for method in paymentMethods {
            context.insert(
                PaymentMethodRecord(
                    name: method.name,
                    isCardless: method.isCardless,
                    isBankTransfer: method.isBankTransfer,
                    isCashOnDelivery: method.isCashOnDelivery
                )
            )
        }

        for name in reconciliationStatusNames {
            context.insert(ReconciliationStatusRecord(name: name))
        }
    }

    /// 把領域訂單逐筆轉成持久化記錄寫入
    /// - Parameters:
    ///   - orders: 要寫入的訂單
    ///   - context: 寫入用的 context
    static func insertOrders(_ orders: [LedgerOrder], into context: ModelContext) {
        for order in orders {
            context.insert(OrderRecord(order: order))
        }
    }

    // MARK: 各 profile 的訂單

    /// `minimalOrders`：當天／前一天／7 天前各 1 筆，狀態各異 (共 3 筆)
    /// - Parameter referenceDate: 推導日期的基準時間點
    /// - Returns: 少量訂單種子
    static func makeMinimalOrders(referenceDate: Date) -> [LedgerOrder] {
        [
            makeOrder(
                id: "UITEST-MIN-001",
                customer: makeCustomer("林書宇", "SY", tier: .vip),
                status: .confirmed,
                date: date(daysBefore: 0, from: referenceDate),
                items: [makeItem(seed: 101, name: "香水 Chamo 50ml", quantity: 1, unitPrice: 2_800)],
                itemCost: 2_800,
                chargedAmount: 4_200
            ),
            makeOrder(
                id: "UITEST-MIN-002",
                customer: makeCustomer("Mika 周", "MZ"),
                status: .shipping,
                date: date(daysBefore: 1, from: referenceDate),
                items: [makeItem(seed: 102, name: "春季針織外套 (M)", quantity: 1, unitPrice: 3_600)],
                itemCost: 3_600,
                categories: ["服飾"],
                paymentMethod: "LINE Pay",
                chargedAmount: 5_400
            ),
            makeOrder(
                id: "UITEST-MIN-003",
                customer: makeCustomer("Ariel 陳", "AC"),
                status: .delivered,
                date: date(daysBefore: 7, from: referenceDate),
                items: [makeItem(seed: 103, name: "氣墊粉餅 #21", quantity: 2, unitPrice: 1_500)],
                itemCost: 3_000,
                orderSource: "Instagram",
                chargedAmount: 4_800
            ),
        ]
    }

    /// `fullOrders`：以 `LedgerOrder.sampleOrders` 為基礎，把日期改寫成相對參考日的位移 (共 8 筆)
    ///
    /// 一律清空 `campaignNames`：本 profile 不寫入任何開團，sample 第 8 筆自帶的開團字串留著會變成指向不存在開團的孤兒值
    /// - Parameter referenceDate: 推導日期的基準時間點
    /// - Returns: 涵蓋各狀態的完整訂單種子
    static func makeFullOrders(referenceDate: Date) -> [LedgerOrder] {
        let dayOffsets = [4, 6, 8, 9, 10, 12, 15, 18]

        return zip(LedgerOrder.sampleOrders, dayOffsets).map { order, offset in
            rebuild(order, date: date(daysBefore: offset, from: referenceDate), campaignNames: [])
        }
    }

    /// `campaignsWithOrders`：`Campaign.sampleCampaigns` 改寫成相對日期 (共 2 筆)
    ///
    /// 進行中的團結單日必須落在參考日之後，否則 `CampaignFeature` 載入時會判定逾期、自動轉成已收單並寫回 DB
    /// - Parameter referenceDate: 推導日期的基準時間點
    /// - Returns: 開團種子
    static func makeCampaigns(referenceDate: Date) -> [Campaign] {
        let schedules: [(open: Int, close: Int, settled: Int?)] = [
            (open: 20, close: -7, settled: nil),
            (open: 60, close: 45, settled: 25),
        ]

        return zip(Campaign.sampleCampaigns, schedules).map { campaign, schedule in
            Campaign(
                id: campaign.id,
                name: campaign.name,
                openDate: date(daysBefore: schedule.open, from: referenceDate),
                closeDate: date(daysBefore: schedule.close, from: referenceDate),
                status: campaign.status,
                settledDate: schedule.settled.map { date(daysBefore: $0, from: referenceDate) },
                notes: campaign.notes
            )
        }
    }

    /// `campaignsWithOrders`：共 8 筆訂單，其中前 4 筆指派開團與收款狀態、其餘 4 筆未歸團
    ///
    /// 每筆指派同時改寫日期，確保落在該團的開團日到結單日之間；掛給已結團的「三月日本團」那筆因此比 `fullOrders` 更早
    /// - Parameters:
    ///   - referenceDate: 推導日期的基準時間點
    ///   - campaigns: 已寫入的開團
    /// - Returns: 歸屬到指定開團的訂單種子
    static func makeCampaignOrders(referenceDate: Date, campaigns: [Campaign]) -> [LedgerOrder] {
        let orders = makeFullOrders(referenceDate: referenceDate)

        guard campaigns.count >= 2 else {
            print("[BuyLedger][UITest] 開團少於 2 筆，campaignsWithOrders 的訂單改為全部未歸團")

            return orders
        }

        let assignments: [(name: String, receipt: PaymentReceiptStatus, daysBefore: Int)] = [
            (name: campaigns[0].name, receipt: .received, daysBefore: 4),
            (name: campaigns[0].name, receipt: .pending, daysBefore: 6),
            (name: campaigns[1].name, receipt: .received, daysBefore: 50),
            (name: campaigns[0].name, receipt: .received, daysBefore: 9),
        ]

        let assigned = zip(orders.prefix(assignments.count), assignments).map { order, assignment in
            rebuild(
                order,
                date: date(daysBefore: assignment.daysBefore, from: referenceDate),
                campaignNames: [assignment.name],
                paymentReceiptStatus: assignment.receipt
            )
        }

        return assigned + orders.dropFirst(assignments.count)
    }

    /// `mergeCandidates`：同客戶、同幣別且狀態皆可合併 (非已合併／已取消) 的 3 筆
    /// - Parameter referenceDate: 推導日期的基準時間點
    /// - Returns: 可合併候選的訂單種子
    static func makeMergeCandidateOrders(referenceDate: Date) -> [LedgerOrder] {
        let customer = makeCustomer("林書宇", "SY", tier: .vip)
        let currency = CurrencyCode(rawValue: "KRW")

        return [
            makeOrder(
                id: "UITEST-MRG-001",
                customer: customer,
                status: .confirmed,
                currency: currency,
                date: date(daysBefore: 0, from: referenceDate),
                items: [makeItem(seed: 201, name: "絲絨唇釉 #07", quantity: 1, unitPrice: 22_000)],
                itemCost: 502,
                chargedAmount: 1_200
            ),
            makeOrder(
                id: "UITEST-MRG-002",
                customer: customer,
                status: .purchased,
                currency: currency,
                date: date(daysBefore: 2, from: referenceDate),
                items: [makeItem(seed: 202, name: "標準 Logo Tee 黑", quantity: 2, unitPrice: 89_000)],
                itemCost: 4_058,
                categories: ["服飾"],
                chargedAmount: 5_680
            ),
            makeOrder(
                id: "UITEST-MRG-003",
                customer: customer,
                status: .shipping,
                currency: currency,
                date: date(daysBefore: 4, from: referenceDate),
                items: [makeItem(seed: 203, name: "寬版牛仔褲 (S)", quantity: 1, unitPrice: 79_000)],
                itemCost: 1_801,
                categories: ["服飾"],
                chargedAmount: 3_100
            ),
        ]
    }

    /// `photos`：帶 5 張照片 (達張數上限) 的單筆訂單
    /// - Parameter referenceDate: 推導日期的基準時間點
    /// - Returns: 帶照片的訂單種子
    static func makePhotoOrders(referenceDate: Date) -> [LedgerOrder] {
        let photos = (0..<LedgerOrder.maxPhotoCount).map { makePhotoData(index: $0) }

        return [
            makeOrder(
                id: "UITEST-PHT-001",
                customer: makeCustomer("Joyce 黃", "JH", tier: .vip),
                status: .arrived,
                date: date(daysBefore: 1, from: referenceDate),
                items: [makeItem(seed: 301, name: "手拿包 米色", quantity: 1, unitPrice: 13_700)],
                itemCost: 13_700,
                categories: ["精品"],
                chargedAmount: 18_500,
                photos: photos
            ),
        ]
    }

    /// `customerRanking`：4 位客戶、金額高低差明顯的 5 筆 (第 1 位客戶佔 2 筆)
    ///
    /// 單價取 `cost` 而非 `charged`，讓商品小計等於 `itemCost`，與其他 profile 的金額約定一致
    /// - Parameter referenceDate: 推導日期的基準時間點
    /// - Returns: 供客戶排行的訂單種子
    static func makeCustomerRankingOrders(referenceDate: Date) -> [LedgerOrder] {
        let entries: [(
            id: String,
            name: String,
            initials: String,
            tier: CustomerTier,
            daysBefore: Int,
            charged: Decimal,
            cost: Decimal
        )] = [
            (id: "UITEST-RNK-001", name: "林書宇", initials: "SY", tier: .vip, daysBefore: 2, charged: 60_000, cost: 36_000),
            (id: "UITEST-RNK-002", name: "林書宇", initials: "SY", tier: .vip, daysBefore: 5, charged: 20_000, cost: 12_000),
            (id: "UITEST-RNK-003", name: "Mika 周", initials: "MZ", tier: .regular, daysBefore: 3, charged: 45_000, cost: 27_000),
            (id: "UITEST-RNK-004", name: "Ariel 陳", initials: "AC", tier: .regular, daysBefore: 4, charged: 24_000, cost: 14_000),
            (id: "UITEST-RNK-005", name: "Iris 楊", initials: "IY", tier: .new, daysBefore: 6, charged: 12_000, cost: 7_000),
        ]

        return entries.enumerated().map { index, entry in
            makeOrder(
                id: entry.id,
                customer: makeCustomer(entry.name, entry.initials, tier: entry.tier),
                status: .delivered,
                date: date(daysBefore: entry.daysBefore, from: referenceDate),
                items: [
                    makeItem(
                        seed: 400 + index,
                        name: "代購商品 \(index + 1)",
                        quantity: 1,
                        unitPrice: entry.cost
                    ),
                ],
                itemCost: entry.cost,
                chargedAmount: entry.charged
            )
        }
    }

    /// `insightsRange`：自參考日往前 12 個月每月各 1 筆 (共 12 筆)，金額逐月遞減
    ///
    /// 單價取 `cost` 而非 `charged`，讓商品小計等於 `itemCost`，與其他 profile 的金額約定一致
    /// - Parameter referenceDate: 推導日期的基準時間點
    /// - Returns: 供分析區間的訂單種子
    static func makeInsightsRangeOrders(referenceDate: Date) -> [LedgerOrder] {
        (0..<12).map { offset in
            let charged = Decimal(30_000 - offset * 2_000)
            let cost = Decimal(18_000 - offset * 1_200)

            return makeOrder(
                id: String(format: "UITEST-INS-%03d", offset + 1),
                customer: makeCustomer("Vivi 王", "VW"),
                status: .delivered,
                date: date(monthsBefore: offset, from: referenceDate),
                items: [
                    makeItem(
                        seed: 500 + offset,
                        name: "月度代購商品 \(offset + 1)",
                        quantity: 1,
                        unitPrice: cost
                    ),
                ],
                itemCost: cost,
                orderSource: orderSourceNames[offset % orderSourceNames.count],
                categories: [categoryNames[offset % categoryNames.count]],
                chargedAmount: charged
            )
        }
    }

    // MARK: 領域型別建構

    /// 建立測試訂單，未指定的欄位一律使用固定值
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
    ///   - campaignNames: 歸屬開團，預設未歸團
    ///   - paymentReceiptStatus: 收款狀態，預設待收款
    ///   - photos: 訂單照片，預設無照片
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
        campaignNames: [String] = [],
        paymentReceiptStatus: PaymentReceiptStatus = .pending,
        photos: [Data] = []
    ) -> LedgerOrder {
        LedgerOrder(
            id: id,
            customer: customer,
            status: status,
            currency: currency,
            date: date,
            items: items,
            itemCost: itemCost,
            domesticShipping: 60,
            internationalShipping: 280,
            foreignDomesticShipping: 0,
            cardFeeRate: decimal("0.015"),
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
            mergedSourceIDs: []
        )
    }

    /// 以既有訂單為基底重建 (``LedgerOrder`` 為 immutable struct，改任一欄位都得整筆重建)
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
    /// - Parameters:
    ///   - name: 客戶顯示名稱
    ///   - initials: 頭像縮寫
    ///   - tier: 客戶分級，預設一般常客
    /// - Returns: 組出的客戶
    static func makeCustomer(_ name: String, _ initials: String, tier: CustomerTier = .regular) -> LedgerCustomer {
        LedgerCustomer(name: name, initials: initials, tier: tier)
    }

    /// 建立商品項目，id 由 seed 推導以避免呼叫 `UUID()`
    ///
    /// 這個 id 不會被保存：``LedgerOrderItem`` 的自訂 `Codable` 刻意不編碼 id，從 `OrderRecord` 讀回時每筆都會重新產生
    /// - Parameters:
    ///   - seed: 決定 id 的固定序號
    ///   - name: 商品名稱
    ///   - quantity: 商品數量
    ///   - unitPrice: 原始幣別單價
    /// - Returns: 組出的商品項目
    static func makeItem(seed: Int, name: String, quantity: Int, unitPrice: Decimal) -> LedgerOrderItem {
        let identifier = UUID(uuidString: String(format: "0000BEEF-0000-4000-8000-%012d", seed))

        return LedgerOrderItem(
            id: identifier ?? fallbackItemID,
            name: name,
            quantity: quantity,
            unitPrice: unitPrice
        )
    }

    /// 把固定字串轉成 `Decimal` (避免浮點字面值的精度誤差)
    /// - Parameter value: 十進位數字字串
    /// - Returns: 解析出的十進位數
    static func decimal(_ value: String) -> Decimal {
        Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")) ?? 0
    }

    // MARK: 日期推導

    /// 取參考日往前若干天的當日零時 (傳負值即往後推)
    /// - Parameters:
    ///   - daysBefore: 往前推的天數
    ///   - referenceDate: 基準時間點
    /// - Returns: 基準往前指定天數的日期
    static func date(daysBefore: Int, from referenceDate: Date) -> Date {
        let start = calendar.startOfDay(for: referenceDate)

        return calendar.date(byAdding: .day, value: -daysBefore, to: start) ?? start
    }

    /// 取參考日往前若干個月的當日零時 (月底日期會由曆法自動夾到該月最後一天)
    /// - Parameters:
    ///   - monthsBefore: 往前推的月數
    ///   - referenceDate: 基準時間點
    /// - Returns: 基準往前指定月數的日期
    static func date(monthsBefore: Int, from referenceDate: Date) -> Date {
        let start = calendar.startOfDay(for: referenceDate)

        return calendar.date(byAdding: .month, value: -monthsBefore, to: start) ?? start
    }

    // MARK: 照片

    /// 產生第 index 張測試照片的 JPEG bytes
    ///
    /// 以 1×1 灰階 JPEG 為基底，於 SOI 之後插入帶索引的 COM (0xFFFE) 註解段，讓每張照片位元組互異但仍可正常解碼
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
