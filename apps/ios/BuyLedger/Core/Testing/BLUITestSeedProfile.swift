//
//  BLUITestSeedProfile.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/7/24.
//

#if DEBUG

/// UI 測試啟動時要寫入的種子資料組合
///
/// 由啟動參數解析成 ``BLUITestConfiguration/seedProfile``，再交給 ``BLUITestSeedData`` 同步寫入 in-memory container；
/// 每個 profile 的筆數固定 (測試會直接斷言)，主檔一律指 17 筆 (訂單來源 4 + 商品類別 4 + 付款方式 6 + 對帳狀態 3)
enum BLUITestSeedProfile: String, CaseIterable, Equatable, Sendable {

    // MARK: - Cases

    /// 完全不寫入 (共 0 筆)，用於驗證各畫面的空狀態
    case empty

    /// 只寫主檔、不寫訂單 (共 17 筆)
    case lookupsOnly

    /// 主檔 + 訂單 3 筆 (共 20 筆)：當天、前一天、7 天前各 1 筆，狀態各異
    case minimalOrders

    /// 主檔 + 訂單 8 筆 (共 25 筆)：以 `LedgerOrder.sampleOrders` 為基礎改寫成相對日期，涵蓋多種狀態與幣別；全部未歸團
    case fullOrders

    /// 主檔 + 開團 2 筆 + 訂單 8 筆 (共 27 筆)
    ///
    /// 8 筆訂單中恰好前 4 筆指派開團與收款狀態 (進行中的團 3 筆、已結團的團 1 筆)，其餘 4 筆未歸團；
    /// 指派的訂單日期一律落在該團的開團日到結單日之間
    case campaignsWithOrders

    /// 主檔 + 訂單 3 筆 (共 20 筆)：同客戶、同幣別且狀態皆可合併，供合併流程挑候選
    case mergeCandidates

    /// 主檔 + 訂單 1 筆 (共 18 筆)：該筆帶 5 張照片，達 `LedgerOrder.maxPhotoCount` 上限
    case photos

    /// 主檔 + 訂單 5 筆 (共 22 筆)：4 位客戶、金額高低差明顯 (第 1 位佔 2 筆)，供客戶排行斷言
    case customerRanking

    /// 主檔 + 訂單 12 筆 (共 29 筆)：自參考日往前 12 個月每月各 1 筆，供走勢圖與熱力圖斷言
    case insightsRange
}

#endif
