//
//  SnapshotCampaignDetailTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import BuyLedger

/// `CampaignDetailView` 與 `CampaignEditNotesSection` 的快照測試，涵蓋詳情畫面與編輯備註區段
@MainActor
struct SnapshotCampaignDetailTests {

    /// 驗證一般開團詳情顯示結單日與訂購提醒時間，並列出已全數收款與仍有未收款的客戶分貨，畫面符合基準圖
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

    /// 驗證開啟只看未收款後，分貨區只留下仍有未收款的客戶，已全數收款的客戶不顯示，畫面符合基準圖
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

    /// 驗證編輯既有開團時，備註區段帶入開團備註，畫面符合基準圖
    ///
    /// - Note: 資訊區段含系統日期選擇器，不做像素比對，改由 `CampaignEditDateRowTests` 守住日期列
    /// - Note: 於 key window 渲染，與訂單編輯區段一致
    @Test
    func campaignEditNotesSection_編輯既有開團_符合基準圖() {
        TestDependencies.withFixedNow {
            // Given
            let campaign = Self.makeDetailCampaign()

            // When
            let view = SnapshotSectionView {
                CampaignEditNotesSection(notes: .constant(campaign.notes), focusedField: $0)
            }
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 200)

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }
}

// MARK: - Private Method

private extension SnapshotCampaignDetailTests {

    /// 建立詳情畫面的已載入狀態：一個有結單日與提醒連結的開團，附三位客戶的五筆訂單
    ///
    /// - Returns: 小美兩筆都已收款，阿凱一筆已收一筆未收，小安一筆未收的詳情狀態
    static func makeDetailState() -> CampaignDetailFeature.State {
        let campaign = makeDetailCampaign()
        let orders = SnapshotTestSupport.makeOrders(
            for: campaign,
            rows: [
                SnapshotTestSupport.CampaignOrderRow(
                    customer: "小美",
                    amount: 1_200,
                    status: .arrived,
                    isReceived: true
                ),
                SnapshotTestSupport.CampaignOrderRow(
                    customer: "小美",
                    amount: 1_800,
                    status: .delivered,
                    isReceived: true
                ),
                SnapshotTestSupport.CampaignOrderRow(
                    customer: "阿凱",
                    amount: 2_400,
                    status: .delivered,
                    isReceived: true
                ),
                SnapshotTestSupport.CampaignOrderRow(
                    customer: "阿凱",
                    amount: 1_000,
                    status: .confirmed,
                    isReceived: false
                ),
                SnapshotTestSupport.CampaignOrderRow(
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
                    // 提醒時間早於結單日，位於固定現在時間後 2 天又 9 小時
                    reminderTimestamp: TestDependencies.fixedNow
                        .addingTimeInterval((2 * 24 + 9) * 3_600)
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
            openDate: SnapshotTestSupport.campaignDate(daysAgo: 20),
            closeDate: SnapshotTestSupport.campaignDate(daysAgo: -5),
            status: .ongoing,
            notes: "美妝與服飾為主，集運倉收滿即出。"
        )
    }
}
