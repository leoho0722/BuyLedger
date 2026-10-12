//
//  CampaignWritesFeatureTests+Rename.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Testing

@testable import BuyLedger

extension CampaignWritesFeatureTests {

    /// 儲存成功先更新清單再改名，改名成功或失敗都在其通知之後回報儲存完成
    ///
    /// - Parameter shouldFailRename: 是否讓訂單改名失敗
    @Test(arguments: [false, true])
    func saveRequested_改名成功或失敗_先改名再送儲存完成(shouldFailRename: Bool) async {
        // Given
        var saved = Self.campaign
        saved.name = "新團"
        let campaigns = Shared(value: [Self.campaign])
        let plan = CampaignSavePlan(
            campaign: saved,
            rename: .init(from: "原團", to: "新團"),
            reminder: Self.reminder
        )
        let calls = LockIsolated<[String]>([])
        let campaignsAtSave = LockIsolated<[Campaign]>([])
        let campaignsAtRename = LockIsolated<[Campaign]>([])
        let renamedNames = LockIsolated<[String]>([])
        let rename: OrderService.RenameOrderCampaign = { from, to throws(PersistenceError) in
            calls.withValue {
                $0.append("rename")
            }
            campaignsAtRename.setValue(campaigns.wrappedValue)
            renamedNames.setValue([from, to])
            if shouldFailRename {
                throw .saveFailed(underlying: TestDependencies.makeUnderlyingError(message: "改名失敗"))
            }
        }
        let store = TestStore(initialState: CampaignWritesFeature.State(campaigns: campaigns)) {
            CampaignWritesFeature()
        } withDependencies: {
            $0.campaignService.saveCampaign = { _ in
                campaignsAtSave.setValue(campaigns.wrappedValue)
                calls.withValue {
                    $0.append("save")
                }
            }
            $0.orderService.renameOrderCampaign = rename
        }

        // When
        await store.send(.saveRequested(plan))

        // Then
        await store.receive(\.saveResponse.success, plan) {
            $0.$campaigns.withLock {
                $0 = [saved]
            }
        }
        await store.receive(\.renameResponse)
        await store.receive(
            \.delegate,
            shouldFailRename ? .failed(.rename) : .renamed(from: "原團", to: "新團")
        )
        await store.receive(\.delegate, .saved(Self.reminder))
        await store.finish()
        #expect(calls.value == ["save", "rename"])
        #expect(renamedNames.value == ["原團", "新團"])
        #expect(campaignsAtSave.value == [Self.campaign])
        #expect(campaignsAtRename.value == [saved])
        #expect(campaigns.wrappedValue == [saved])
    }
}
