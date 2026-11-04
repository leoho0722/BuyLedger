//
//  CampaignSeedFixture.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/30.
//

/// `campaignsWithOrders` 種子資料中四月韓國團的固定值
enum CampaignSeedFixture {

    /// 四月韓國團的唯一識別碼，該團在種子中應收 $16,780、已收 $11,800
    static let koreaCampaignID = "CMP-SAMPLE-KR-APR"

    /// 四月韓國團內已收款客戶的名稱
    static let paidCustomerNames = ["林書宇", "Joyce 黃"]

    /// 四月韓國團內未收款客戶的名稱
    static let unpaidCustomerName = "Mika 周"
}
