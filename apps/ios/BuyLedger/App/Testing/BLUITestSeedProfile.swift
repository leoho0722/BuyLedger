//
//  BLUITestSeedProfile.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/24.
//

#if DEBUG

/// UI 測試啟動時要寫入的種子資料組合
enum BLUITestSeedProfile: String, CaseIterable, Equatable, Sendable {
    
    // MARK: - Cases
    
    /// 完全不寫入 (共 0 筆)，用於驗證各畫面的空狀態
    case empty
    
    /// 只寫主檔、不寫訂單 (共 17 筆)
    case lookupsOnly
    
    /// 主檔 + 訂單 3 筆 (共 20 筆)：當天、前一天、7 天前各 1 筆，狀態各異
    case minimalOrders
    
    /// 主檔與 8 筆訂單的測試資料，涵蓋多種狀態與幣別
    case fullOrders

    /// 一筆使用信用卡且尚未標記貨到付款的訂單，供回溯重算驗收
    case paymentMethodCorrection

    /// 2 筆來源訂單與 1 筆合併結果，供營收歸屬跨畫面一致性驗收
    case revenueAttribution
    
    /// 主檔 + 開團 2 筆 + 訂單 8 筆 (共 27 筆)
    case campaignsWithOrders
    
    /// 3 筆可合併的訂單，供合併流程測試
    case mergeCandidates
    
    /// 1 筆含 5 張照片的訂單，供照片上限測試
    case photos
    
    /// 5 筆訂單與 4 位客戶，供客戶排行測試
    case customerRanking
    
    /// 12 個月的訂單資料，供走勢圖與熱力圖測試
    case insightsRange
}

#endif
