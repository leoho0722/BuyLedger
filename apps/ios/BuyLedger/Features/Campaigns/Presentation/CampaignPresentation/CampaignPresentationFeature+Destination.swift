//
//  CampaignPresentationFeature+Destination.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation

// MARK: - Nested Types

extension CampaignPresentationFeature {

    /// 開團畫面可呈現的編輯表單與 alert，同一時間只會有一個
    @Reducer
    enum Destination {

        /// 新增或編輯開團的表單
        ///
        /// - Parameter feature: 負責驗證名稱與草稿的表單 Feature
        case edit(CampaignEditFeature)

        /// 刪除與結團確認，以及寫入與提醒失敗的一次性通知
        ///
        /// - Parameter alert: 要顯示的 alert 內容
        @ReducerCaseIgnored case alert(AlertState<Alert>)

        /// `Destination` 可接收的子 Feature 與 alert action
        @CasePathable
        enum Action {

            /// alert 按鈕事件
            ///
            /// - Parameter action: alert 的選項
            case alert(Alert)

            /// 編輯表單事件
            ///
            /// - Parameter action: 編輯表單的事件
            case edit(CampaignEditFeature.Action)
        }

        /// 開團 alert 可執行的動作
        @CasePathable
        enum Alert: Equatable {

            /// 使用者確認刪除指定開團
            ///
            /// - Parameter id: 要刪除的開團識別值
            case confirmDelete(Campaign.ID)

            /// 使用者確認結團
            ///
            /// - Parameter id: 要結團的開團識別值
            case confirmSettle(Campaign.ID)

            /// 使用者選擇前往系統設定開啟行事曆權限
            case openSettings
        }
    }
}

// MARK: - Computed Properties

extension CampaignPresentationFeature.Destination.State {

    /// 結單日自動轉狀態的寫入失敗通知
    static var autoCloseFailure: Self {
        operationFailure(TextState("campaigns.general.message.automaticallyUpdatingCampaign"))
    }
}

// MARK: - Internal Method

extension CampaignPresentationFeature.Destination.State {

    /// 建立刪除開團前的確認 alert，列表長按與詳情選單共用
    ///
    /// - Parameter campaign: 要刪除的開團
    /// - Returns: 包含刪除確認 alert 的 `Destination.State`
    static func deleteConfirmation(for campaign: Campaign) -> Self {
        .alert(
            AlertState<CampaignPresentationFeature.Destination.Alert> {
                TextState("orders.general.label.deleteCampaign")
            } actions: {
                ButtonState(role: .destructive, action: .confirmDelete(campaign.id)) {
                    TextState("common.action.button.delete")
                }
                ButtonState(role: .cancel) {
                    TextState("common.action.cancel")
                }
            } message: {
                TextState(
                    LocalizedStringResource(
                        "campaigns.detail.message.deleteUndoneNotice",
                        defaultValue: "\(campaign.name)"
                    )
                )
            }
        )
    }

    /// 建立結團前的二次確認 alert
    ///
    /// - Parameter campaign: 要結團的開團
    /// - Returns: 包含結團確認 alert 的 `Destination.State`
    static func settlementConfirmation(for campaign: Campaign) -> Self {
        .alert(
            AlertState<CampaignPresentationFeature.Destination.Alert> {
                TextState("campaigns.detail.label.campaignSettlement")
            } actions: {
                ButtonState(action: .confirmSettle(campaign.id)) {
                    TextState("campaigns.list.label.settle")
                }
                ButtonState(role: .cancel) {
                    TextState("common.action.cancel")
                }
            } message: {
                TextState(
                    LocalizedStringResource(
                        "campaigns.detail.message.settleUndoneNotice",
                        defaultValue: "\(campaign.name)"
                    )
                )
            }
        )
    }

    /// 建立開團寫入失敗的一次性通知
    ///
    /// - Parameter failure: 寫入子 Feature 回報的失敗種類
    /// - Returns: 包含失敗通知的 `Destination.State`
    static func writeFailure(_ failure: CampaignWritesFeature.Failure) -> Self {
        switch failure {
        case .save:
            return operationFailure(TextState("campaigns.general.message.campaignSavedTry"))

        case .delete:
            return operationFailure(TextState("campaigns.general.message.campaignDeletedTry"))

        case .status:
            return operationFailure(TextState("campaigns.general.message.campaignStatusUpdated"))

        case .settle:
            return operationFailure(TextState("campaigns.general.message.campaignSettledTry"))
        }
    }

    /// 建立行事曆提醒失敗的一次性通知；權限被拒時附「前往設定」
    ///
    /// - Parameter failure: 提醒子 Feature 回報的失敗種類
    /// - Returns: 包含失敗通知的 `Destination.State`
    static func reminderFailure(_ failure: CampaignReminderFeature.Failure) -> Self {
        switch failure {
        case .accessDenied:
            // 要求使用者前往系統設定卻不提供跳轉，等於把導航成本轉嫁給使用者
            return .alert(
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

        case .accessRestricted:
            // 裝置政策限制下無法前往設定
            return notice(
                TextState("campaigns.general.label.calendarUnavailable"),
                message: TextState("campaigns.general.message.calendarAccessRestricted")
            )

        case .creationFailed:
            // 權限已授予，訊息不得指向權限設定，照做也無法解決真正發生的失敗
            return notice(
                TextState("campaigns.general.label.unableCreateReminder"),
                message: TextState("campaigns.general.message.reminderCreatedPlease")
            )

        case .calendarUnavailable:
            // 找不到可寫入的行事曆不是權限問題，訊息不得指向設定
            return notice(
                TextState("campaigns.reminder.label.writableCalendarFound"),
                message: TextState("campaigns.general.message.writableCalendarFound")
            )

        case .linkRemovalFailed:
            return operationFailure(TextState("campaigns.general.message.removingReminderLink"))

        case .oldEventRemovalFailed:
            return operationFailure(TextState("campaigns.general.message.reminderUpdatedBut"))

        case .eventRemovalAfterDeleteFailed:
            return operationFailure(TextState("campaigns.general.message.campaignDeletedBut"))
        }
    }
}

// MARK: - Equatable

extension CampaignPresentationFeature.Destination.State: Equatable {

}

// MARK: - Private Method

private extension CampaignPresentationFeature.Destination.State {

    /// 建立標題為「操作失敗」、只有「知道了」按鈕的通知
    ///
    /// - Parameter message: 失敗原因
    /// - Returns: 包含通知的 `Destination.State`
    static func operationFailure(_ message: TextState) -> Self {
        notice(TextState("orders.list.label.operationFailed"), message: message)
    }

    /// 建立只有「知道了」按鈕的一次性通知
    ///
    /// - Parameters:
    ///   - title: 通知標題
    ///   - message: 通知訊息
    /// - Returns: 包含通知的 `Destination.State`
    static func notice(_ title: TextState, message: TextState) -> Self {
        .alert(
            AlertState<CampaignPresentationFeature.Destination.Alert> {
                title
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("orders.merge.label.ok")
                }
            } message: {
                message
            }
        )
    }
}
