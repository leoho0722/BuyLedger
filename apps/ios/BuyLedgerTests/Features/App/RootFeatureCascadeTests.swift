//
//  RootFeatureCascadeTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

/// `RootFeature` 的單元測試，以 TestStore 驗證開團刪除或改名、類別改名如何同步到訂單與各頁投影
@MainActor
struct RootFeatureCascadeTests {

    /// 驗證開團刪除或改名後，Root 只送出訂單調整請求，訂單資料要等訂單寫入功能處理時才真正更新
    ///
    /// - Parameter request: 開團刪除或改名的訂單調整請求
    /// - Note: 共用訂單的變更在送出時核對，每一步實際寫入的時點另由觀察紀錄確認
    @Test(arguments: [
        OrdersCascadeOperations.Request.campaignDeleted("舊團"),
        .campaignRenamed(from: "舊團", to: "新團"),
    ])
    func campaigns_收到開團刪除或改名委派_轉送請求後由寫入子層同步(request: OrdersCascadeOperations.Request) async {
        // Given
        let original = LedgerOrder.fixture(
            id: "O1",
            categories: ["舊類別", "其他類別"],
            campaignNames: ["舊團", "其他團"]
        )
        let expected = Self.cascadeExpectedOrder(for: request, from: original)
        let delegate = Self.makeDelegate(for: request)
        let initial = RootFeatureTestSupport.makeIsolatedRootState {
            CampaignIntegrationTestSupport.makeRootState(campaigns: [], orders: [original])
        }
        let observations = LockIsolated<[[[LedgerOrder]]]>([])
        let store = TestStore(initialState: initial) {
            CombineReducers {
                RootFeature()
                Reduce { state, _ in
                    let snapshot = [state.orders.orders, state.campaigns.orders, state.more.orders]
                    observations.withValue {
                        $0.append(snapshot)
                    }
                    return .none
                }
            }
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(delegate) {
            $0.orders.$orders.withLock {
                $0 = [expected]
            }
            $0.campaigns.$orders.withLock {
                $0 = [expected]
            }
            $0.more.$orders.withLock {
                $0 = [expected]
            }
        }

        // Then
        await store.receive(\.orders.rootRequest.cascade, request)
        await store.receive(\.orders.writes.cascadeRequested, request) {
            $0.dashboard.orders = [expected]
            $0.insights.orders = [expected]
        }
        await store.finish()
        #expect(
            observations.value == [
                [[original], [original], [original]],
                [[original], [original], [original]],
                [[expected], [expected], [expected]],
            ]
        )
        #expect(initial.orders.orders == [expected])
        #expect(initial.campaigns.orders == [expected])
        #expect(initial.more.orders == [expected])
    }

    /// 驗證類別改名後，Root 只送出訂單調整請求，訂單資料要等訂單寫入功能處理時才真正更新
    ///
    /// - Note: 共用訂單的變更在送出時核對，每一步實際寫入的時點另由觀察紀錄確認
    @Test
    func more_收到類別改名委派_轉送請求後由寫入子層同步() async {
        // Given
        let rename = LookupItemRename(oldName: "舊類別", newName: "新類別")
        let request = OrdersCascadeOperations.Request.lookupItemRenamed(
            kind: .category,
            rename: rename
        )
        let original = LedgerOrder.fixture(
            id: "O1",
            categories: ["舊類別", "其他類別"],
            campaignNames: ["舊團", "其他團"]
        )
        let expected = Self.cascadeExpectedOrder(for: request, from: original)
        let delegate = RootFeature.Action.more(
            .delegate(.lookupItemRenamed(kind: .category, rename: rename))
        )
        let initial = RootFeatureTestSupport.makeIsolatedRootState {
            CampaignIntegrationTestSupport.makeRootState(campaigns: [], orders: [original])
        }
        let observations = LockIsolated<[[[LedgerOrder]]]>([])
        let store = TestStore(initialState: initial) {
            CombineReducers {
                RootFeature()
                Reduce { state, _ in
                    let snapshot = [state.orders.orders, state.campaigns.orders, state.more.orders]
                    observations.withValue {
                        $0.append(snapshot)
                    }
                    return .none
                }
            }
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(delegate) {
            $0.orders.$orders.withLock {
                $0 = [expected]
            }
            $0.campaigns.$orders.withLock {
                $0 = [expected]
            }
            $0.more.$orders.withLock {
                $0 = [expected]
            }
        }

        // Then
        await store.receive(\.orders.rootRequest.cascade, request)
        await store.receive(\.orders.writes.cascadeRequested, request) {
            $0.dashboard.orders = [expected]
            $0.insights.orders = [expected]
        }
        await store.finish()
        #expect(
            observations.value == [
                [[original], [original], [original]],
                [[original], [original], [original]],
                [[expected], [expected], [expected]],
            ]
        )
        #expect(initial.orders.orders == [expected])
        #expect(initial.campaigns.orders == [expected])
        #expect(initial.more.orders == [expected])
    }

    /// 驗證直接送出訂單寫入功能的調整請求時，單次送出就同步更新開團、更多頁、總覽與分析頁的訂單
    ///
    /// - Parameter request: 三種訂單調整請求
    @Test(arguments: [
        OrdersCascadeOperations.Request.campaignDeleted("舊團"),
        .campaignRenamed(from: "舊團", to: "新團"),
        .lookupItemRenamed(
            kind: .category,
            rename: LookupItemRename(oldName: "舊類別", newName: "新類別")
        ),
    ])
    func orders_寫入子層處理三種調整_同次更新開團與更多投影(request: OrdersCascadeOperations.Request) async {
        // Given
        let original = LedgerOrder.fixture(
            id: "O1",
            categories: ["舊類別", "其他類別"],
            campaignNames: ["舊團", "其他團"]
        )
        let expected = Self.cascadeExpectedOrder(for: request, from: original)
        let initial = RootFeatureTestSupport.makeIsolatedRootState {
            CampaignIntegrationTestSupport.makeRootState(campaigns: [], orders: [original])
        }
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.orders(.writes(.cascadeRequested(request)))) {
            $0.orders.$orders.withLock {
                $0 = [expected]
            }
            $0.campaigns.$orders.withLock {
                $0 = [expected]
            }
            $0.more.$orders.withLock {
                $0 = [expected]
            }
            $0.dashboard.orders = [expected]
            $0.insights.orders = [expected]
        }

        // Then
        await store.finish()
        #expect(initial.orders.orders == [expected])
        #expect(initial.campaigns.orders == [expected])
        #expect(initial.more.orders == [expected])
    }
}

// MARK: - Private Method

private extension RootFeatureCascadeTests {

    /// 以原始訂單為底，建立調整後應得的訂單，只改動被調整的開團或類別
    ///
    /// - Parameters:
    ///   - request: 待驗證的調整種類
    ///   - original: 調整前的訂單
    /// - Returns: 只改動被調整的開團或類別，其餘欄位維持原樣的訂單
    static func cascadeExpectedOrder(
        for request: OrdersCascadeOperations.Request,
        from original: LedgerOrder
    ) -> LedgerOrder {
        switch request {
        case .campaignDeleted:
            return RootFeatureTestSupport.rebuiltOrder(original, campaignNames: ["其他團"])

        case .campaignRenamed:
            return RootFeatureTestSupport.rebuiltOrder(original, campaignNames: ["新團", "其他團"])

        case .lookupItemRenamed:
            return RootFeatureTestSupport.rebuiltOrder(original, categories: ["新類別", "其他類別"])
        }
    }

    /// 把調整請求對應到開團或更多頁送給 Root 的動作
    ///
    /// - Parameter request: 待送出的調整請求
    /// - Returns: 開團或更多頁送給 Root 的動作
    static func makeDelegate(for request: OrdersCascadeOperations.Request) -> RootFeature.Action {
        switch request {
        case .campaignDeleted(let name):
            return .campaigns(.delegate(.campaignDeleted(name: name)))

        case .campaignRenamed(let from, let to):
            return .campaigns(.delegate(.campaignRenamed(from: from, to: to)))

        case .lookupItemRenamed(let kind, let rename):
            return .more(.delegate(.lookupItemRenamed(kind: kind, rename: rename)))
        }
    }
}
