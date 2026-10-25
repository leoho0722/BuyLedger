//
//  CampaignServiceTestSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/26.
//

import ComposableArchitecture

@testable import BuyLedger

/// 提供開團測試共用的正式 Service 建立操作
enum CampaignServiceTestSupport {}

// MARK: - Internal Method

extension CampaignServiceTestSupport {

    /// 以注入的資料庫建立正式 `CampaignService`
    ///
    /// - Parameter database: 要提供給 Service 的資料庫
    /// - Returns: 依注入資料庫建立的 `CampaignService`
    static func makeService(database: any BuyLedgerDatabaseProtocol) -> CampaignService {
        withDependencies {
            $0.buyLedgerDatabase = database
        } operation: {
            CampaignService.liveValue
        }
    }
}
