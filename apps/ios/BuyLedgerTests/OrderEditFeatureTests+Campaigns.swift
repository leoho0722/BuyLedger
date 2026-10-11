//
//  OrderEditFeatureTests+Campaigns.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrderEditFeatureTests {

    /// 未選開團時，繁體中文沿用既有的未歸團文字
    ///
    /// - Throws: 繁體中文資源目錄不存在時由 `#require` 丟出
    @Test
    func campaignsDisplayText_未選開團且使用繁體中文_顯示未歸團() throws {
        // Given
        let state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)

        // When
        let text = try localizedCampaignText(
            state.campaignsDisplayText,
            language: .traditionalChinese
        )

        // Then
        #expect(state.campaignsDisplayText.key == "orders.detail.label.unassigned")
        #expect(text == "未歸團")
    }

    /// 未選開團時，英文使用既有的未歸團翻譯
    ///
    /// - Throws: 英文資源目錄不存在時由 `#require` 丟出
    @Test
    func campaignsDisplayText_未選開團且使用英文_顯示英文未歸團() throws {
        // Given
        let state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)

        // When
        let text = try localizedCampaignText(state.campaignsDisplayText, language: .english)

        // Then
        #expect(state.campaignsDisplayText.key == "orders.detail.label.unassigned")
        #expect(text == "Unassigned")
    }

    /// 已選開團時，繁體中文保留原名稱與頓號分隔
    ///
    /// - Throws: 繁體中文資源目錄不存在時由 `#require` 丟出
    @Test
    func campaignsDisplayText_已選開團且使用繁體中文_保留名稱與頓號() throws {
        // Given
        var state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        state.draft.campaignNames = ["三月日本團", "四月韓國團"]

        // When
        let text = try localizedCampaignText(
            state.campaignsDisplayText,
            language: .traditionalChinese
        )

        // Then
        #expect(state.campaignsDisplayText.key == "%@")
        #expect(text == "三月日本團、四月韓國團")
    }

    /// 已選開團時，英文仍保留原名稱與頓號分隔
    ///
    /// - Throws: 英文資源目錄不存在時由 `#require` 丟出
    @Test
    func campaignsDisplayText_已選開團且使用英文_保留名稱與頓號() throws {
        // Given
        var state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        state.draft.campaignNames = ["三月日本團", "四月韓國團"]

        // When
        let text = try localizedCampaignText(state.campaignsDisplayText, language: .english)

        // Then
        #expect(state.campaignsDisplayText.key == "%@")
        #expect(text == "三月日本團、四月韓國團")
    }

    /// 開團名稱恰好與本地化鍵相同時，英文不翻譯使用者資料
    ///
    /// - Throws: 英文資源目錄不存在時由 `#require` 丟出
    @Test
    func campaignsDisplayText_英文開團名稱等於本地化鍵_保留原始名稱() throws {
        // Given
        var state = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        state.draft.campaignNames = ["orders.detail.label.unassigned"]

        // When
        let text = try localizedCampaignText(state.campaignsDisplayText, language: .english)

        // Then
        #expect(state.campaignsDisplayText.key == "%@")
        #expect(text == "orders.detail.label.unassigned")
    }

    /// 結單日就是今天的開團仍在收單，列在可選的開團清單中
    @Test
    func init_開團今日到期_仍列入進行中清單() async {
        // Given
        let campaign = Campaign(
            id: "C1",
            name: "今天團",
            openDate: TestDependencies.fixedNow,
            closeDate: TestDependencies.fixedNow,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        var orders = withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            OrdersFeature.State()
        }
        orders.campaigns = [campaign]

        // When
        let state = OrderEditFeature.State(
            id: UUID(0),
            options: orders.makeEditOptions(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            ),
            currentDate: TestDependencies.fixedNow
        )

        // Then
        #expect(state.pickers.availableCampaigns == ["今天團"])
    }

    /// 狀態仍為進行中但結單日已過的開團，不列入可選清單
    @Test
    func init_結單日已過但狀態仍進行中_不列入清單() async {
        // Given
        let yesterdayCampaign = Campaign(
            id: "C1",
            name: "昨天團",
            openDate: TestDependencies.fixedNow.addingTimeInterval(-172_800),
            closeDate: TestDependencies.fixedNow.addingTimeInterval(-86_400),
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        let todayCampaign = Campaign(
            id: "C2",
            name: "今天團",
            openDate: TestDependencies.fixedNow,
            closeDate: TestDependencies.fixedNow,
            status: .ongoing,
            settledDate: nil,
            notes: ""
        )
        var orders = withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            OrdersFeature.State()
        }
        orders.campaigns = [yesterdayCampaign, todayCampaign]

        // When
        let state = OrderEditFeature.State(
            id: UUID(0),
            options: orders.makeEditOptions(
                now: TestDependencies.fixedNow,
                calendar: TestDependencies.fixedCalendar
            ),
            currentDate: TestDependencies.fixedNow
        )

        // Then
        #expect(state.pickers.availableCampaigns == ["今天團"])
    }

    /// 選擇一個開團會取代原選取，選擇空白則清除歸屬
    ///
    /// - Parameters:
    ///   - selection: 要選取的開團名稱
    ///   - expected: 預期寫入草稿的開團名稱
    @Test(arguments: [
        (selection: "", expected: [String]()),
        (selection: "三月日本團", expected: ["三月日本團"]),
    ])
    func pickers_選取開團名稱_空白清空或有效名稱改為單一開團(selection: String, expected: [String]) async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.campaignNames = ["四月韓國團"]
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.pickers(.view(.campaignSelected(selection))))

        // Then
        await store.receive(\.pickers.delegate.campaignSelected, selection) {
            $0.draft.campaignNames = expected
        }
        #expect(store.state.draft.campaignNames == expected)
    }

    /// 開團切換會依初始選取狀態加入或移除開團
    ///
    /// - Parameter testCase: 開團切換的起始選取、切換項目與預期結果
    @Test(arguments: [
        CampaignToggleCase(
            initialCampaigns: ["四月韓國團"],
            campaign: "三月日本團",
            expected: ["四月韓國團", "三月日本團"]
        ),
        CampaignToggleCase(
            initialCampaigns: ["四月韓國團", "三月日本團"],
            campaign: "四月韓國團",
            expected: ["三月日本團"]
        ),
    ])
    func pickers_切換開團未選或已選_加入或移除選取(testCase: CampaignToggleCase) async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.campaignNames = testCase.initialCampaigns
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.pickers(.view(.campaignToggled(testCase.campaign))))

        // Then
        await store.receive(\.pickers.delegate.campaignToggled, testCase.campaign) {
            $0.draft.campaignNames = testCase.expected
        }
        #expect(store.state.draft.campaignNames == testCase.expected)
    }

    /// 尚未開啟選擇器時，點選開團按鈕會推入開團選擇器
    @Test
    func pickers_點選開團按鈕時尚未開啟選擇器_推入開團選擇器() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        }

        // When
        await store.send(.pickers(.view(.campaignPickerTapped))) {
            $0.pickers.pickerRoute = .campaign
        }

        // Then
        #expect(store.state.pickers.pickerRoute == .campaign)
    }
}

// MARK: - Private Method

private extension OrderEditFeatureTests {

    /// 以指定語言的資源目錄解析本地化值與插值，不受測試程序預設語言影響
    ///
    /// - Parameters:
    ///   - resource: 畫面狀態提供的本地化值
    ///   - language: 測試指定的 App 語言
    /// - Returns: 以指定語言解析後的開團文字
    /// - Throws: 指定語言的資源目錄不存在時由 `#require` 丟出
    func localizedCampaignText(
        _ resource: LocalizedStringResource,
        language: AppLanguage
    ) throws -> String {
        let bundleURL = try #require(
            Bundle.main.url(forResource: language.localeIdentifier, withExtension: "lproj")
        )
        let bundle = try #require(Bundle(url: bundleURL))
        return String(
            localized: resource.defaultValue,
            table: resource.table,
            bundle: bundle,
            locale: language.locale
        )
    }
}
