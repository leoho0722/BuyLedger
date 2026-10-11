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
                TextState("campaigns.general.label.calendarAccessRequired")
            } actions: {
                ButtonState(action: .openSettings) {
                    TextState("orders.general.label.openSettings")
                }
                ButtonState(role: .cancel) {
                    TextState("orders.merge.label.ok")
                }
            } message: {
                TextState("campaigns.general.message.allowCalendarAccess")
            }
        )
    }

    /// 表單有未儲存變更時，按下取消會呈現的捨棄確認
    static var discardAlert: AlertState<CampaignEditFeature.Action.DiscardAlert> {
        AlertState {
            TextState("orders.list.label.discardChanges")
        } actions: {
            ButtonState(role: .destructive, action: .discard) {
                TextState("orders.list.label.discardChanges")
            }
            ButtonState(role: .cancel) {
                TextState("orders.list.label.keepEditing")
            }
        } message: {
            TextState("campaigns.edit.message.campaignHasUnsaved")
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
                TextState("campaigns.detail.label.campaignSettlement")
            } actions: {
                ButtonState(action: .confirmSettle(id)) {
                    TextState("campaigns.list.label.settle")
                }
                ButtonState(role: .cancel) {
                    TextState("common.action.cancel")
                }
            } message: {
                TextState(
                    LocalizedStringResource(
                        "campaigns.detail.message.settleUndoneNotice",
                        defaultValue: "\(name)"
                    )
                )
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
                TextState("orders.general.label.deleteCampaign")
            } actions: {
                ButtonState(role: .destructive, action: .confirmDelete(id)) {
                    TextState("common.action.button.delete")
                }
                ButtonState(role: .cancel) {
                    TextState("common.action.cancel")
                }
            } message: {
                TextState(
                    LocalizedStringResource(
                        "campaigns.detail.message.deleteUndoneNotice",
                        defaultValue: "\(name)"
                    )
                )
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
            return titledAlert("campaigns.general.label.calendarUnavailable", message: "campaigns.general.message.calendarAccessRestricted")

        case .creationFailed:
            return titledAlert("campaigns.general.label.unableCreateReminder", message: "campaigns.general.message.reminderCreatedPlease")

        case .calendarUnavailable:
            return titledAlert("campaigns.reminder.label.writableCalendarFound", message: "campaigns.general.message.writableCalendarFound")

        case .linkRemovalFailed:
            return failureAlert("campaigns.general.message.removingReminderLink")

        case .oldEventRemovalFailed:
            return failureAlert("campaigns.general.message.reminderUpdatedBut")

        case .eventRemovalAfterDeleteFailed:
            return failureAlert("campaigns.general.message.campaignDeletedBut")
        }
    }

    /// 建立標題為「操作失敗」的寫入失敗提示
    ///
    /// - Parameter message: 要顯示的錯誤訊息
    /// - Returns: 錯誤提示狀態
    static func failureAlert(
        _ message: LocalizedStringKey
    ) -> CampaignPresentationFeature.Destination.State {
        titledAlert("orders.list.label.operationFailed", message: message)
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
                    TextState("orders.merge.label.ok")
                }
            } message: {
                TextState(message)
            }
        )
    }
}
