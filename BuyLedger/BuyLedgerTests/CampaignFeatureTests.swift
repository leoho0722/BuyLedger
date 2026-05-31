//
//  CampaignFeatureTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/5/30.
//

import ComposableArchitecture
import Foundation
import Testing
@testable import BuyLedger

@MainActor
struct CampaignFeatureTests {

    // MARK: - Tests

    @Test func taskLoadsCampaignsWithoutTransitionWhenNoCloseDate() async {
        let campaign = makeCampaign(id: "C1", name: "團", status: .ongoing, closeDate: nil)
        let store = TestStore(initialState: CampaignFeature.State()) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].fetchCampaigns = { [campaign] }
        }

        await store.send(.task) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(\.campaignsLoaded) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.campaigns = [campaign]
        }
    }

    @Test func loadingAutoTransitionsOngoingPastCloseDateToClosed() async {
        // fixedNow = 2026-04-30。closeDate 4/20 已過 → 轉 closed；closeDate 5/10 未到 → 維持 ongoing。
        let pastDue = makeCampaign(id: "past", name: "過期團", status: .ongoing, closeDate: day(month: 4, day: 20))
        let future = makeCampaign(id: "future", name: "未到團", status: .ongoing, closeDate: day(month: 5, day: 10))

        let store = TestStore(initialState: CampaignFeature.State()) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].fetchCampaigns = { [pastDue, future] }
            $0[CampaignRepository.self].saveCampaign = { _ in }
        }

        var transitioned = pastDue
        transitioned.status = .closed

        await store.send(.task) {
            $0.isLoading = true
            $0.errorMessage = nil
        }

        await store.receive(\.campaignsLoaded) {
            $0.isLoading = false
            $0.hasLoaded = true
            $0.campaigns = [transitioned, future]
        }
    }

    @Test func statusChangedUpdatesCampaign() async {
        let campaign = makeCampaign(id: "C1", name: "團", status: .ongoing, closeDate: nil)
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]

        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].saveCampaign = { _ in }
        }

        await store.send(.statusChanged("C1", .closed)) {
            $0.campaigns[0].status = .closed
        }
    }

    @Test func settleTappedRecordsSettledDateWithoutChangingStatus() async {
        let campaign = makeCampaign(id: "C1", name: "團", status: .closed, closeDate: nil)
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]

        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].saveCampaign = { _ in }
        }

        await store.send(.settleTapped("C1")) {
            $0.campaigns[0].settledDate = TestDependencies.fixedNow
        }

        #expect(store.state.campaigns[0].status == .closed, "結團不應改變狀態")
    }

    @Test func deleteConfirmationRemovesCampaign() async {
        let campaign = makeCampaign(id: "C1", name: "團", status: .ongoing, closeDate: nil)
        var initial = CampaignFeature.State()
        initial.campaigns = [campaign]

        let store = TestStore(initialState: initial) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0[CampaignRepository.self].removeCampaign = { _ in }
        }
        store.exhaustivity = .off

        await store.send(.deleteCampaignTapped("C1"))
        #expect(store.state.deletionConfirmation != nil)

        await store.send(.deletionConfirmation(.presented(.confirmDelete("C1"))))
        #expect(store.state.campaigns.isEmpty)
    }

    @Test func newCampaignTappedPresentsEmptyEditForm() async {
        let store = TestStore(initialState: CampaignFeature.State()) {
            CampaignFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }
        // CampaignEditFeature.State 內含隨機 `id: UUID()`，無法做等值斷言；改以非窮舉模式驗證表單已呈現且為新開團。
        store.exhaustivity = .off

        await store.send(.newCampaignTapped)
        #expect(store.state.editCampaign != nil)
        #expect(store.state.editCampaign?.original == nil)
        #expect(store.state.editCampaign?.draftStatus == .ongoing)
    }

    // MARK: - Helper

    /// 建立測試用開團。
    private func makeCampaign(
        id: String,
        name: String,
        status: CampaignStatus,
        closeDate: Date?
    ) -> Campaign {
        Campaign(
            id: id,
            name: name,
            openDate: day(month: 4, day: 1),
            closeDate: closeDate,
            status: status,
            settledDate: nil,
            notes: ""
        )
    }

    /// 建立 2026 年指定月日的固定日期 (UTC)。
    private func day(month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = TimeZone(secondsFromGMT: 0)
        components.year = 2026
        components.month = month
        components.day = day
        return components.date ?? Date(timeIntervalSince1970: 0)
    }
}
