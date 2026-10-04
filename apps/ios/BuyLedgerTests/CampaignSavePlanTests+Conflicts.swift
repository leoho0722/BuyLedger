//
//  CampaignSavePlanTests+Conflicts.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation
import Testing

@testable import BuyLedger

extension CampaignSavePlanTests {

    /// 原名未變直接放行，否則僅檢查不同識別值且去空白後同名的開團
    ///
    /// - Parameter scenario: 新舊名稱、編輯識別值與獨立指定的是否拒絕結果
    @Test(arguments: ConflictCase.allCases)
    func conflicts_名稱與編輯識別值組合_只拒絕其他開團的同名新名稱(scenario: ConflictCase) {
        // Given
        let campaigns = [
            Campaign.fixture(
                id: "C1",
                name: "重複團",
                openDate: ConflictCase.openDate,
                status: .ongoing,
                notes: ""
            ),
            Campaign.fixture(
                id: "C2",
                name: "重複團",
                openDate: ConflictCase.openDate,
                status: .closed,
                notes: ""
            ),
            Campaign.fixture(
                id: "C4",
                name: " \n空白團  ",
                openDate: ConflictCase.openDate,
                status: .ongoing,
                notes: ""
            ),
            Campaign.fixture(
                id: "C3",
                name: "唯一團",
                openDate: ConflictCase.openDate,
                status: .closed,
                notes: ""
            ),
        ]

        // When
        let conflict = CampaignSavePlan.conflicts(
            name: scenario.name,
            originalName: scenario.originalName,
            editingID: scenario.editingID,
            campaigns: campaigns
        )

        // Then
        #expect(conflict == scenario.expected)
    }
}

// MARK: - Nested Types

extension CampaignSavePlanTests {

    /// 新舊名稱、編輯識別值與重名判斷的預期
    struct ConflictCase: Sendable {

        /// 重名判斷案例共用的固定開團日期，與判斷結果無關
        static let openDate = Date(timeIntervalSince1970: 3_600)

        /// 原名未變、他團重名、去空白同名與自身識別值排除的重名判定案例
        static let allCases = [
            Self(
                name: "重複團",
                originalName: "重複團",
                editingID: "C1",
                expected: false
            ),
            Self(
                name: "重複團",
                originalName: "舊團",
                editingID: "C1",
                expected: true
            ),
            Self(
                name: "重複團",
                originalName: nil,
                editingID: nil,
                expected: true
            ),
            Self(
                name: "空白團",
                originalName: "舊團",
                editingID: "C1",
                expected: true
            ),
            Self(
                name: "別團",
                originalName: "舊團",
                editingID: "C1",
                expected: false
            ),
            Self(
                name: "唯一團",
                originalName: "舊團",
                editingID: "C3",
                expected: false
            ),
        ]

        /// 要儲存的已去空白名稱
        let name: String

        /// 原名稱；`nil` 表示新增
        let originalName: String?

        /// 編輯中的識別值；`nil` 表示新增
        let editingID: Campaign.ID?

        /// 是否應拒絕儲存
        let expected: Bool
    }
}
