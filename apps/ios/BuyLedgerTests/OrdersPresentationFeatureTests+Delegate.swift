//
//  OrdersPresentationFeatureTests+Delegate.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/9.
//

import ComposableArchitecture
import Foundation
import Testing

@testable import BuyLedger

extension OrdersPresentationFeatureTests {

    /// 表單請求存檔時，把目前的表單狀態原樣轉交父層
    @Test
    func destination_表單請求存檔_轉送存檔請求() async {
        // Given
        let edit = Self.editState()
        let initial = Self.makeState(destination: .edit(edit))
        let store = TestStore(initialState: initial) {
            OrdersPresentationFeature()
        }

        // When
        await store.send(.destination(.presented(.edit(.delegate(.saveRequested)))))

        // Then
        await store.receive(\.delegate, .saveRequested(edit))
    }

    /// 表單請求新增主檔選項時，轉送帶表單識別值的寫入請求
    @Test
    func destination_表單請求新增選項_轉送帶表單識別值的寫入請求() async {
        // Given
        let initial = Self.makeState(destination: .edit(Self.editState()))
        let store = TestStore(initialState: initial) {
            OrdersPresentationFeature()
        }

        // When
        await store.send(
            .destination(
                .presented(
                    .edit(
                        .delegate(.addOptionRequested(kind: .orderSource, name: "蝦皮", flags: .none))
                    )
                )
            )
        )

        // Then
        await store.receive(
            \.delegate,
            .optionAddRequested(
                OrderOptionWritePlan(
                    formID: UUID(0),
                    kind: .orderSource,
                    name: "蝦皮",
                    flags: .none
                )
            )
        )
    }

    /// 合併候選完成時，轉送主副訂單與保留照片給容器計算合併草稿
    @Test
    func destination_合併候選完成_轉送合併候選完成() async {
        // Given
        let primary = LedgerOrder.fixture(id: "A")
        let secondary = LedgerOrder.fixture(id: "B")
        let initial = Self.makeState(destination: Self.mergeDestination())
        let store = TestStore(initialState: initial) {
            OrdersPresentationFeature()
        }

        // When
        await store.send(
            .destination(
                .presented(
                    .merge(
                        .delegate(
                            .completed(primary: primary, secondary: secondary, keptPhotos: [])
                        )
                    )
                )
            )
        )

        // Then
        await store.receive(
            \.delegate,
            .mergeCandidatesCompleted(primary: primary, secondary: secondary, keptPhotos: [])
        )
    }

    /// 確認刪除時清空提示，並轉送要刪除的訂單識別值
    @Test
    func destination_確認刪除_清空提示並轉送刪除訂單() async {
        // Given
        let initial = Self.makeState(destination: Self.deleteAlert())
        let store = TestStore(initialState: initial) {
            OrdersPresentationFeature()
        }

        // When
        await store.send(.destination(.presented(.alert(.confirmDelete("A"))))) {
            $0.destination = nil
        }

        // Then
        await store.receive(\.delegate, .deleteConfirmed("A"))
    }

    /// 點選前往開啟時清空提示，並轉送要求開啟 AI 設定的請求
    @Test
    func destination_前往開啟設定_清空提示並轉送設定請求() async {
        // Given
        let initial = Self.makeState(destination: Self.aiSettingsAlert())
        let store = TestStore(initialState: initial) {
            OrdersPresentationFeature()
        }

        // When
        await store.send(.destination(.presented(.alert(.goToAISettings)))) {
            $0.destination = nil
        }

        // Then
        await store.receive(\.delegate, .aiSettingsRequested)
    }
}
