//
//  OrderEditFeatureCampaignsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

/// `OrderEditFeature` 的單元測試，涵蓋開團顯示文字與可選清單，以及選擇器的選取、切換與推入
struct OrderEditFeatureCampaignsTests {

    /// 驗證未選任何開團時，開團文字沿用既有的未歸團本地化鍵，繁體中文顯示為未歸團
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

    /// 驗證未選任何開團時，開團文字沿用既有的未歸團本地化鍵，英文顯示為 Unassigned
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

    /// 驗證已選多個開團時，繁體中文原樣顯示開團名稱並以頓號串接
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

    /// 驗證已選多個開團時，英文仍原樣顯示開團名稱，並以頓號而非英文逗號串接
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

    /// 驗證開團名稱與本地化鍵相同時，英文仍原樣顯示名稱，不當成鍵值翻譯
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

    /// 驗證結單日與注入的現在時間同為當天的進行中開團，仍列入可選清單
    @Test
    func init_開團今日到期_仍列入進行中清單() {
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
        let orders = withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            OrdersFeature.State()
        }
        orders.$campaigns.withLock {
            $0 = [campaign]
        }

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
        #expect(state.pickers.options.campaigns == ["今天團"])
    }

    /// 驗證狀態仍為進行中但結單日已過的開團不列入可選清單，同日到期的開團仍列入
    @Test
    func init_結單日已過但狀態仍進行中_不列入清單() {
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
        let orders = withDependencies {
            $0.defaultInMemoryStorage = InMemoryStorage()
        } operation: {
            OrdersFeature.State()
        }
        orders.$campaigns.withLock {
            $0 = [yesterdayCampaign, todayCampaign]
        }

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
        #expect(state.pickers.options.campaigns == ["今天團"])
    }

    /// 驗證選取開團時，草稿的開團歸屬改為所選的單一開團，選取空白則清空歸屬
    ///
    /// - Parameter testCase: 測試輸入與字面值預期結果
    @Test(arguments: [
        CampaignSelectionCase(selection: "", expected: []),
        CampaignSelectionCase(selection: "三月日本團", expected: ["三月日本團"]),
    ])
    @MainActor
    func pickers_選取開團名稱_空白清空或有效名稱改為單一開團(testCase: CampaignSelectionCase) async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.campaignNames = ["四月韓國團"]
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.pickers(.view(.campaignSelected(testCase.selection))))

        // Then
        await store.receive(\.pickers.delegate.campaignSelected, testCase.selection) {
            $0.draft.campaignNames = testCase.expected
        }
        #expect(store.state.draft.campaignNames == testCase.expected)
    }

    /// 驗證切換開團時，未選取的開團附加到清單末端，已選取的開團移除，其餘選取維持不變
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
    @MainActor
    func pickers_切換開團未選或已選_加入或移除選取(testCase: CampaignToggleCase) async {
        // Given
        var initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        initial.draft.campaignNames = testCase.initialCampaigns
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.pickers(.view(.campaignToggled(testCase.campaign))))

        // Then
        await store.receive(\.pickers.delegate.campaignToggled, testCase.campaign) {
            $0.draft.campaignNames = testCase.expected
        }
        #expect(store.state.draft.campaignNames == testCase.expected)
    }

    /// 驗證尚未開啟選擇器時，點選開團按鈕會推入開團選擇器，並把 `pickerRoute` 設為 `.campaign`
    @Test
    @MainActor
    func pickers_點選開團按鈕時尚未開啟選擇器_推入開團選擇器() async {
        // Given
        let initial = OrderEditFeature.State(id: UUID(0), currentDate: TestDependencies.fixedNow)
        let store = TestStore(initialState: initial) {
            OrderEditFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.pickers(.view(.campaignPickerTapped))) {
            $0.pickers.pickerRoute = .campaign
        }

        // Then
        #expect(store.state.pickers.pickerRoute == .campaign)
    }
}

// MARK: - Nested Types

extension OrderEditFeatureCampaignsTests {

    /// 開團單選的輸入與預期結果
    struct CampaignSelectionCase: Sendable {

        /// 要選取的開團名稱
        let selection: String

        /// 預期寫入草稿的開團名稱
        let expected: [String]
    }

    /// 開團切換測試使用的輸入與預期結果
    struct CampaignToggleCase: Sendable {

        /// 送出 action 前已選取的開團
        let initialCampaigns: [String]

        /// 要切換的開團名稱
        let campaign: String

        /// 切換後預期保留的開團
        let expected: [String]
    }
}

// MARK: - Private Method

private extension OrderEditFeatureCampaignsTests {

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
