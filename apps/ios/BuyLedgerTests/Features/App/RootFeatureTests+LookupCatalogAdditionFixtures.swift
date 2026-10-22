//
//  RootFeatureTests+LookupCatalogAdditionFixtures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

// MARK: - Internal Method

extension RootFeatureTests {

    /// 在隔離儲存建立主檔已有美妝、來源表單已選美妝的根狀態
    ///
    /// - Parameters:
    ///   - original: 表單編輯的原訂單，未提供時為新表單
    ///   - isMerge: 是否建立合併表單
    /// - Returns: 固定日期、幣別與表單識別值的根狀態
    static func makeOptionAdditionRootState(
        original: LedgerOrder? = nil,
        isMerge: Bool = false
    ) -> RootFeature.State {
        var state = Self.makeIsolatedRootState()
        state.selectedTab = .orders
        state.more.catalog.$catalog.withLock {
            $0.categories = ["美妝"]
        }
        state.launch.$currencyCodes.withLock {
            $0 = [.twd]
        }
        if let original {
            state.orders.$orders.withLock {
                $0 = [original]
            }
        }
        state.orders.refreshDateContext(
            now: TestDependencies.fixedNow,
            calendar: TestDependencies.fixedCalendar
        )
        var form = OrderEditFeature.State(
            original: original,
            id: UUID(0),
            options: OrderEditOptions(
                categories: ["美妝"],
                currencyCodes: [.twd],
                calendar: TestDependencies.fixedCalendar
            ),
            currentDate: TestDependencies.fixedNow
        )
        form.draft.categories = ["美妝"]
        if isMerge {
            form.mergeSourceIDs = ["A", "B"]
        }
        state.orders.presentation.destination = .edit(form)
        return state
    }

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

    /// 接收表單到主檔端的每一層轉送，核對原表單識別值、名稱與旗標
    ///
    /// - Parameters:
    ///   - store: 已從選擇器送出新增事件的測試 `store`
    ///   - request: 由案例以字面值建立的預期請求
    static func receiveOptionAdditionRequest(
        in store: TestStoreOf<RootFeature>,
        request: LookupAdditionRequest
    ) async {
        await store.receive(
            \.orders.presentation.destination.presented.edit.pickers.delegate,
            .addOptionRequested(
                kind: request.kind,
                name: request.addition.name,
                flags: request.addition.flags
            )
        )
        await store.receive(
            \.orders.presentation.destination.presented.edit.delegate,
            .addOptionRequested(
                kind: request.kind,
                name: request.addition.name,
                flags: request.addition.flags
            )
        )
        await store.receive(\.orders.presentation.delegate, .optionAddRequested(request))
        await store.receive(\.orders.delegate, .optionAddRequested(request))
        await store.receive(\.more.optionAdditionRequested, request)
        await store.receive(\.more.catalog.additionRequested, request)
    }

    /// 接收主檔寫入回應與兩層委派，訂單容器的結果由呼叫端另行斷言
    ///
    /// - Parameters:
    ///   - store: 已釋放寫入閘門的測試 `store`
    ///   - request: 保留來源表單識別值的預期請求
    ///   - isStored: 預期的寫入結果
    ///   - expectedCatalog: 案例以字面值提供的完整目錄
    static func receiveOptionAdditionResult(
        in store: TestStoreOf<RootFeature>,
        request: LookupAdditionRequest,
        isStored: Bool,
        expectedCatalog: LookupCatalog
    ) async {
        if isStored {
            await store.receive(\.more.catalog.additionResponse) {
                $0.more.catalog.$catalog.withLock {
                    $0 = expectedCatalog
                }
            }
        } else {
            await store.receive(\.more.catalog.additionResponse)
        }
        await store.receive(
            \.more.catalog.delegate,
            .additionCompleted(request, isStored: isStored)
        )
        await store.receive(\.more.delegate, .optionAdditionCompleted(request, isStored: isStored))
    }
}
