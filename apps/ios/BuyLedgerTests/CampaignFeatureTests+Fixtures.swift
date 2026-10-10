//
//  CampaignFeatureTests+Fixtures.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import SwiftUI

@testable import BuyLedger

// MARK: - Computed Properties

extension CampaignFeatureTests {

    /// 使用者拒絕行事曆權限時可前往系統設定的提示
    static var accessDeniedAlert: CampaignPresentationFeature.Destination.State {
        .alert(
            AlertState<CampaignPresentationFeature.Destination.Alert> {
                TextState("需要行事曆權限")
            } actions: {
                ButtonState(action: .openSettings) {
                    TextState("前往設定")
                }
                ButtonState(role: .cancel) {
                    TextState("知道了")
                }
            } message: {
                TextState("請到「設定」開啟行事曆存取權限，才能新增或移除訂購提醒。")
            }
        )
    }

    /// 表單有未儲存變更時，按下取消會呈現的捨棄確認
    static var discardAlert: AlertState<CampaignEditFeature.Action.DiscardAlert> {
        AlertState {
            TextState("捨棄變更")
        } actions: {
            ButtonState(role: .destructive, action: .discard) {
                TextState("捨棄變更")
            }
            ButtonState(role: .cancel) {
                TextState("繼續編輯")
            }
        } message: {
            TextState("這個開團有尚未儲存的變更，離開後將不會保留。")
        }
    }
}

// MARK: - Internal Method

extension CampaignFeatureTests {

    /// 建立沒有任何變更的新增開團表單狀態
    ///
    /// - Returns: 草稿與初始草稿相同的表單狀態
    static func makeEditState() -> CampaignEditFeature.State {
        CampaignEditFeature.State(
            id: UUID(0),
            currentDate: TestDependencies.fixedNow,
            reminderTimestamp: TestDependencies.fixedNow
        )
    }

    /// 建立指向指定開團、與容器共用同一份資料的詳情堆疊元素
    ///
    /// - Parameters:
    ///   - campaignID: 要顯示詳情的開團識別值
    ///   - state: 提供共用資料的容器狀態
    /// - Returns: 預期被推入堆疊的詳情元素
    /// - Note: `send` 的預期 closure 可直接 `append`；`receive` 要以 `path[id:]` 明指實際配發的 id
    static func detailPath(
        _ campaignID: Campaign.ID,
        in state: CampaignFeature.State
    ) -> CampaignFeature.Path.State {
        .detail(
            CampaignDetailFeature.State(
                campaignID: campaignID,
                campaigns: SharedReader(state.$campaigns),
                orders: SharedReader(state.$orders),
                reminderLinks: SharedReader(state.$reminderLinks),
                isShowingUnpaidOnly: state.$isShowingUnpaidOnly
            )
        )
    }

    /// 建立結團確認對話框
    ///
    /// - Parameters:
    ///   - id: 要結團的開團識別碼
    ///   - name: 要結團的開團名稱
    /// - Returns: 結團提示狀態
    static func settleAlert(
        id: Campaign.ID,
        name: String
    ) -> CampaignPresentationFeature.Destination.State {
        .alert(
            AlertState<CampaignPresentationFeature.Destination.Alert> {
                TextState("結團結算")
            } actions: {
                ButtonState(action: .confirmSettle(id)) {
                    TextState("結團")
                }
                ButtonState(role: .cancel) {
                    TextState("取消")
                }
            } message: {
                TextState("結算「\(name)」後就無法再改回進行中。確定要結團嗎？")
            }
        )
    }

    /// 建立刪除確認對話框
    ///
    /// - Parameters:
    ///   - id: 要刪除的開團識別碼
    ///   - name: 要刪除的開團名稱
    /// - Returns: 刪除提示狀態
    static func deletionAlert(
        id: Campaign.ID,
        name: String
    ) -> CampaignPresentationFeature.Destination.State {
        .alert(
            AlertState<CampaignPresentationFeature.Destination.Alert> {
                TextState("刪除開團")
            } actions: {
                ButtonState(role: .destructive, action: .confirmDelete(id)) {
                    TextState("刪除")
                }
                ButtonState(role: .cancel) {
                    TextState("取消")
                }
            } message: {
                TextState("刪除「\(name)」後無法復原。歸屬此開團的訂單會保留，但會變回未歸團。")
            }
        )
    }

    /// 依提醒流程的失敗種類，另外組出該呈現的通知，讓預期值不取自被測程式
    ///
    /// - Parameter failure: 提醒流程的失敗種類
    /// - Returns: 對應文案的通知狀態
    static func reminderFailureAlert(
        for failure: CampaignReminderFeature.Failure
    ) -> CampaignPresentationFeature.Destination.State {
        switch failure {
        case .accessDenied:
            return accessDeniedAlert

        case .accessRestricted:
            return titledAlert("無法使用行事曆", message: "這台裝置的行事曆存取受政策限制，暫時無法新增或移除訂購提醒。")

        case .creationFailed:
            return titledAlert("無法建立訂購提醒", message: "訂購提醒建立失敗，請稍後再試。")

        case .calendarUnavailable:
            return titledAlert("找不到可寫入的行事曆", message: "找不到可寫入的行事曆，請新增或啟用一個可寫入的行事曆後再試。")

        case .linkRemovalFailed:
            return failureAlert("提醒連結移除失敗，請稍後再試。")

        case .oldEventRemovalFailed:
            return failureAlert("提醒已更新，但舊的行事曆事件移除失敗，請自行到行事曆刪除。")

        case .eventRemovalAfterDeleteFailed:
            return failureAlert("開團已刪除，但行事曆上的提醒事件移除失敗，請自行到行事曆刪除。")
        }
    }

    /// 建立標題為「操作失敗」的寫入失敗提示
    ///
    /// - Parameter message: 要顯示的錯誤訊息
    /// - Returns: 錯誤提示狀態
    static func failureAlert(
        _ message: LocalizedStringKey
    ) -> CampaignPresentationFeature.Destination.State {
        titledAlert("操作失敗", message: message)
    }
}

// MARK: - Private Method

private extension CampaignFeatureTests {

    /// 建立只有「知道了」按鈕、標題自訂的通知
    ///
    /// - Parameters:
    ///   - title: 通知標題
    ///   - message: 通知訊息
    /// - Returns: 通知狀態
    static func titledAlert(
        _ title: LocalizedStringKey,
        message: LocalizedStringKey
    ) -> CampaignPresentationFeature.Destination.State {
        .alert(
            AlertState<CampaignPresentationFeature.Destination.Alert> {
                TextState(title)
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("知道了")
                }
            } message: {
                TextState(message)
            }
        )
    }
}
