//
//  RootFeatureLookupCatalogAdditionsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import SwiftUI
import Testing

@testable import BuyLedger

/// `RootFeature` 的單元測試，以 TestStore 驗證四種主檔選項新增成功與失敗時，寫入、目錄與來源表單如何更新
@MainActor
struct RootFeatureLookupCatalogAdditionsTests {

    /// 驗證四種主檔選項新增成功時，名稱去除前後空白後先寫入儲存，之後才更新目錄，並在來源表單加入該選項且選取
    ///
    /// - Parameter kind: 要新增的主檔種類
    /// - Throws: 找不到該種類的預期目錄時由 `#require` 丟出測試斷言錯誤
    @Test(arguments: LookupKind.allCases)
    func orders_四種選項新增成功_先落盤再更新目錄與來源表單(kind: LookupKind) async throws {
        // Given
        let initial = RootFeatureTestSupport.makeOptionAdditionRootState()
        let catalog = SharedReader(initial.more.catalog.$catalog)
        let observed = LockIsolated<[LookupCatalog]>([])
        let kinds = LockIsolated<[LookupKind]>([])
        let additions = LockIsolated<[LookupItemAddition]>([])
        let release = AsyncStream<Void>.makeStream()
        let request = LookupAdditionRequest(
            id: UUID(0),
            kind: kind,
            name: "香氛",
            flags: .none
        )
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.lookupService.addItem = { kind, addition in
                observed.withValue {
                    $0.append(catalog.wrappedValue)
                }
                kinds.withValue {
                    $0.append(kind)
                }
                additions.withValue {
                    $0.append(addition)
                }
                var iterator = release.stream.makeAsyncIterator()
                _ = await iterator.next()
            }
        }
        let action = Self.optionAdditionAction(kind: kind, name: " 香氛 ")

        // When
        await store.send(
            .orders(.presentation(.destination(.presented(.edit(.pickers(.view(action)))))))
        )

        // Then
        await RootFeatureTestSupport.receiveOptionAdditionRequest(in: store, request: request)
        #expect(store.state.more.catalog.catalog == LookupCatalog(categories: ["美妝"]))
        #expect(store.state.orders.presentation.destination?.edit?.draft.categories == ["美妝"])
        release.continuation.finish()
        let catalogs: [LookupKind: LookupCatalog] = [
            .orderSource: LookupCatalog(orderSources: ["香氛"], categories: ["美妝"]),
            .category: LookupCatalog(categories: ["美妝", "香氛"]),
            .paymentMethod: LookupCatalog(
                categories: ["美妝"],
                paymentMethods: [PaymentMethodInfo(name: "香氛", flags: .none)]
            ),
            .reconciliationStatus: LookupCatalog(
                categories: ["美妝"],
                reconciliationStatuses: ["香氛"]
            ),
        ]
        await RootFeatureTestSupport.receiveOptionAdditionResult(
            in: store,
            request: request,
            isStored: true,
            expectedCatalog: try #require(catalogs[kind])
        )
        await store.receive(
            \.orders.rootRequest,
            .optionAdditionCompleted(request, isStored: true)
        ) {
            switch kind {
            case .orderSource:
                $0.orders.presentation.destination?.modify(\.edit) {
                    $0.pickers.options.orderSources = ["香氛"]
                    $0.draft.orderSource = "香氛"
                }

            case .category:
                $0.orders.presentation.destination?.modify(\.edit) {
                    $0.pickers.options.categories = ["美妝", "香氛"]
                    $0.draft.categories = ["香氛"]
                }

            case .paymentMethod:
                $0.orders.presentation.destination?.modify(\.edit) {
                    $0.pickers.options.paymentMethods = [
                        PaymentMethodInfo(name: "香氛", flags: .none),
                    ]
                    $0.draft.paymentMethod = "香氛"
                }

            case .reconciliationStatus:
                $0.orders.presentation.destination?.modify(\.edit) {
                    $0.pickers.options.reconciliationStatuses = ["香氛"]
                    $0.draft.reconciliationStatus = "香氛"
                }
            }
        }
        #expect(observed.value == [LookupCatalog(categories: ["美妝"])])
        #expect(kinds.value == [kind])
        #expect(additions.value == [LookupItemAddition(name: "香氛", flags: .none)])
        #expect(store.state.more.catalog.catalog.names(for: kind).contains("香氛"))
        #expect(store.state.orders.presentation.destination?.edit?.id == UUID(0))
        await store.finish()
    }

    /// 驗證四種主檔選項新增失敗時，目錄與表單都保留原狀，並把對應的失敗訊息排入待呈現的提示
    ///
    /// - Parameter kind: 要新增的主檔種類
    /// - Throws: 找不到該種類的失敗訊息時由 `#require` 丟出測試斷言錯誤
    @Test(arguments: LookupKind.allCases)
    func orders_四種選項新增失敗_保留資料並排入失敗提示(kind: LookupKind) async throws {
        // Given
        let initial = RootFeatureTestSupport.makeOptionAdditionRootState()
        let originalForm = initial.orders.presentation.destination
        let kinds = LockIsolated<[LookupKind]>([])
        let additions = LockIsolated<[LookupItemAddition]>([])
        let release = AsyncStream<Void>.makeStream()
        let failingAdd: LookupService.AddItem = { kind, addition throws(PersistenceError) in
            kinds.withValue {
                $0.append(kind)
            }
            additions.withValue {
                $0.append(addition)
            }
            var iterator = release.stream.makeAsyncIterator()
            _ = await iterator.next()
            throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "失敗"))
        }
        let messages: [LookupKind: LocalizedStringKey] = [
            .orderSource: "orders.general.message.orderSourceAdded",
            .category: "orders.general.message.categoryAddedTry",
            .paymentMethod: "orders.general.message.paymentMethodAdded",
            .reconciliationStatus: "orders.general.message.reconciliationStatusAdded",
        ]
        let notice = OrdersFeatureTestSupport.failureNotice(try #require(messages[kind]))
        let request = LookupAdditionRequest(
            id: UUID(0),
            kind: kind,
            name: "香氛",
            flags: .none
        )
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
            $0.lookupService.addItem = failingAdd
        }
        let action = Self.optionAdditionAction(kind: kind, name: "香氛")

        // When
        await store.send(
            .orders(.presentation(.destination(.presented(.edit(.pickers(.view(action)))))))
        )

        // Then
        await RootFeatureTestSupport.receiveOptionAdditionRequest(in: store, request: request)
        release.continuation.finish()
        await RootFeatureTestSupport.receiveOptionAdditionResult(
            in: store,
            request: request,
            isStored: false,
            expectedCatalog: LookupCatalog(categories: ["美妝"])
        )
        await store.receive(
            \.orders.rootRequest,
            .optionAdditionCompleted(request, isStored: false)
        )
        await store.receive(\.orders.presentation.noticeRequested, notice) {
            $0.orders.presentation.queue.pendingNotice = notice
        }
        #expect(store.state.orders.presentation.destination == originalForm)
        #expect(store.state.orders.presentation.destination?.edit?.draft.categories == ["美妝"])
        #expect(store.state.more.catalog.catalog == LookupCatalog(categories: ["美妝"]))
        #expect(kinds.value == [kind])
        #expect(additions.value == [LookupItemAddition(name: "香氛", flags: .none)])
        await store.finish()
    }

    /// 驗證失敗提示排隊中表單已關閉時，等關閉動畫結束 (`formSheetDismissed`) 後才呈現提示
    @Test
    func orders_失敗提示排隊中關閉表單_關閉動畫結束後呈現提示() async {
        // Given
        let notice = OrdersFeatureTestSupport.failureNotice(
            "orders.general.message.categoryAddedTry"
        )
        var initial = RootFeatureTestSupport.makeOptionAdditionRootState()
        initial.orders.presentation.destination = nil
        initial.orders.presentation.queue.isFormClosing = true
        initial.orders.presentation.queue.pendingNotice = notice
        let store = TestStore(initialState: initial) {
            RootFeature()
        } withDependencies: {
            $0.date = .constant(TestDependencies.fixedNow)
            $0.calendar = TestDependencies.fixedCalendar
        }

        // When
        await store.send(.orders(.view(.formSheetDismissed))) {
            $0.orders.presentation.queue.isFormClosing = false
            $0.orders.presentation.queue.pendingNotice = nil
            $0.orders.presentation.destination = notice
        }

        // Then
        #expect(store.state.orders.presentation.destination == notice)
        #expect(store.state.orders.presentation.queue.pendingNotice == nil)
        await store.finish()
    }
}

// MARK: - Private Method

private extension RootFeatureLookupCatalogAdditionsTests {

    /// 依主檔種類建立畫面實際送出的新增按鈕事件
    ///
    /// - Parameters:
    ///   - kind: 主檔種類
    ///   - name: 使用者輸入的名稱
    ///   - flags: 付款方式旗標
    /// - Returns: 選擇器的新增事件
    static func optionAdditionAction(
        kind: LookupKind,
        name: String,
        flags: PaymentMethodFlags = .none
    ) -> OrderEditPickersFeature.Action.View {
        switch kind {
        case .orderSource:
            return .addOrderSourceTapped(name)

        case .category:
            return .addCategoryTapped(name)

        case .paymentMethod:
            return .addPaymentMethodTapped(name: name, flags: flags)

        case .reconciliationStatus:
            return .addReconciliationStatusTapped(name)
        }
    }
}
