//
//  DependencyScanSubrule.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/28.
//

/// 依賴規範掃描器各規則的子範圍
enum DependencyScanSubrule: Hashable, Sendable {

    /// Feature 的 Data 目錄以外程式碼
    case featureOutsideData

    /// Service 原始碼中的跨 Service 依賴
    case serviceFile

    /// 宣告 `DependencyKey` 的 Service 檔的測試值
    case serviceDependency

    /// 宣告 `DependencyKey` 的 Client、Store 與 Database 檔的測試值
    case nonServiceDependency
}
