//
//  SnapshotTests+CampaignDetail.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import BuyLedger

extension SnapshotTests {

    /// 一般開團詳情顯示結單日與訂購提醒時間，並列出已全數收款與仍有未收款的客戶分貨
    @Test
    func campaignDetailView_一般開團含提醒_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            let state = Self.makeDetailState()

            // When
            let view = NavigationStack {
                CampaignDetailView(
                    store: Store(initialState: state) {
                        EmptyReducer()
                    }
                )
            }
            .environment(\.locale, AppLanguage.traditionalChinese.locale)
            .frame(width: 393, height: 1_800)

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 開啟只看未收款後，分貨區只留下仍有未收款的客戶，已全數收款的客戶不顯示
    @Test
    func campaignDetailView_只看未收款_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            let state = Self.makeDetailState()
            state.$isShowingUnpaidOnly.withLock {
                $0 = true
            }

            // When
            let view = NavigationStack {
                CampaignDetailView(
                    store: Store(initialState: state) {
                        EmptyReducer()
                    }
                )
            }
            .environment(\.locale, AppLanguage.traditionalChinese.locale)
            .frame(width: 393, height: 1_800)

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 編輯既有開團時表單帶入名稱、日期、狀態與備註，並開啟訂購提醒顯示提醒時間
    @Test
    func campaignEditView_編輯既有開團_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            let state = CampaignEditFeature.State(
                original: Self.makeDetailCampaign(),
                id: UUID(0),
                currentDate: TestDependencies.fixedNow,
                wantsReminder: true,
                reminderTimestamp: Self.makeDetailReminderTimestamp()
            )

            // When
            let view = CampaignEditView(
                store: Store(initialState: state) {
                    EmptyReducer()
                }
            )
            .environment(\.locale, AppLanguage.traditionalChinese.locale)
            .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }
}

// MARK: - Private Method

private extension SnapshotTests {

    /// 建立詳情畫面的已載入狀態：一個有結單日與提醒連結的開團，附三位客戶的五筆訂單
    ///
    /// - Returns: 小美兩筆都已收款，阿凱一筆已收一筆未收，小安一筆未收的詳情狀態
    static func makeDetailState() -> CampaignDetailFeature.State {
        let campaign = makeDetailCampaign()
        let orders = makeOrders(
            for: campaign,
            rows: [
                CampaignOrderRow(
                    customer: "小美",
                    amount: 1_200,
                    status: .arrived,
                    isReceived: true
                ),
                CampaignOrderRow(
                    customer: "小美",
                    amount: 1_800,
                    status: .delivered,
                    isReceived: true
                ),
                CampaignOrderRow(
                    customer: "阿凱",
                    amount: 2_400,
                    status: .delivered,
                    isReceived: true
                ),
                CampaignOrderRow(
                    customer: "阿凱",
                    amount: 1_000,
                    status: .confirmed,
                    isReceived: false
                ),
                CampaignOrderRow(
                    customer: "小安",
                    amount: 3_200,
                    status: .purchased,
                    isReceived: false
                ),
            ]
        )

        return CampaignDetailFeature.State(
            campaignID: campaign.id,
            campaigns: SharedReader(value: [campaign]),
            orders: SharedReader(value: orders),
            reminderLinks: SharedReader(value: [
                campaign.id: CampaignReminderLink(
                    eventIdentifier: "event-campaign-detail",
                    reminderTimestamp: makeDetailReminderTimestamp()
                ),
            ]),
            isShowingUnpaidOnly: Shared(value: false)
        )
    }

    /// 建立詳情與編輯表單共用的開團：開團中、有結單日與備註
    ///
    /// - Returns: 開團日期在固定現在時間的 20 天前、結單日在 5 天後的開團
    static func makeDetailCampaign() -> Campaign {
        Campaign.fixture(
            id: "campaign-detail",
            name: "四月韓國團",
            openDate: campaignDate(daysAgo: 20),
            closeDate: campaignDate(daysAgo: -5),
            status: .ongoing,
            notes: "美妝與服飾為主，集運倉收滿即出。"
        )
    }

    /// 取得固定的訂購提醒時間，為固定現在時間後兩天又 9 小時
    ///
    /// - Returns: 早於結單日的提醒時間戳
    static func makeDetailReminderTimestamp() -> Date {
        TestDependencies.fixedNow.addingTimeInterval((2 * 24 + 9) * 3_600)
    }
}
