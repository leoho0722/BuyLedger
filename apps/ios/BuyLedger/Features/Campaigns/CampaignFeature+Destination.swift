//
//  CampaignFeature+Destination.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture
import Foundation

// MARK: - Nested Types

extension CampaignFeature {

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

        /// Destination 可接收的子 Feature 與 alert action
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

extension CampaignFeature.Destination.State {

    /// 結單日自動轉狀態的寫入失敗通知
    static var autoCloseFailure: Self {
        operationFailure(TextState("開團狀態自動更新失敗，請稍後再試。"))
    }
}

// MARK: - Internal Method

extension CampaignFeature.Destination.State {

    /// 建立刪除開團前的確認 alert，列表長按與詳情選單共用
    ///
    /// - Parameter campaign: 要刪除的開團
    /// - Returns: 包含刪除確認 alert 的 Destination state
    static func deleteConfirmation(for campaign: Campaign) -> Self {
        .alert(
            AlertState<CampaignFeature.Destination.Alert> {
                TextState("刪除開團")
            } actions: {
                ButtonState(role: .destructive, action: .confirmDelete(campaign.id)) {
                    TextState("刪除")
                }
                ButtonState(role: .cancel) {
                    TextState("取消")
                }
            } message: {
                TextState("刪除「\(campaign.name)」後無法復原。歸屬此開團的訂單會保留，但會變回未歸團。")
            }
        )
    }

    /// 建立結團前的二次確認 alert
    ///
    /// - Parameter campaign: 要結團的開團
    /// - Returns: 包含結團確認 alert 的 Destination state
    static func settlementConfirmation(for campaign: Campaign) -> Self {
        .alert(
            AlertState<CampaignFeature.Destination.Alert> {
                TextState("結團結算")
            } actions: {
                ButtonState(action: .confirmSettle(campaign.id)) {
                    TextState("結團")
                }
                ButtonState(role: .cancel) {
                    TextState("取消")
                }
            } message: {
                TextState("結算「\(campaign.name)」後就無法再改回進行中。確定要結團嗎？")
            }
        )
    }

    /// 建立開團寫入失敗的一次性通知
    ///
    /// - Parameter failure: 寫入子 Feature 回報的失敗種類
    /// - Returns: 包含失敗通知的 Destination state
    static func writeFailure(_ failure: CampaignWritesFeature.Failure) -> Self {
        switch failure {
        case .save:
            return operationFailure(TextState("開團儲存失敗，請稍後再試。"))

        case .rename:
            return operationFailure(TextState("開團已儲存，但歸屬訂單的開團名稱更新失敗，請稍後再試。"))

        case .delete:
            return operationFailure(TextState("開團刪除失敗，請稍後再試。"))

        case .status:
            return operationFailure(TextState("開團狀態更新失敗，請稍後再試。"))

        case .settle:
            return operationFailure(TextState("結團失敗，請稍後再試。"))
        }
    }

    /// 建立行事曆提醒失敗的一次性通知；權限被拒時附「前往設定」
    ///
    /// - Parameter failure: 提醒子 Feature 回報的失敗種類
    /// - Returns: 包含失敗通知的 Destination state
    static func reminderFailure(_ failure: CampaignReminderFeature.Failure) -> Self {
        switch failure {
        case .accessDenied:
            // 要求使用者前往系統設定卻不提供跳轉，等於把導航成本轉嫁給使用者
            return .alert(
                AlertState<CampaignFeature.Destination.Alert> {
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

        case .accessRestricted:
            // 裝置政策限制下無法前往設定
            return notice(
                TextState("無法使用行事曆"),
                message: TextState("這台裝置的行事曆存取受政策限制，暫時無法新增或移除訂購提醒。")
            )

        case .creationFailed:
            // 權限已授予，訊息不得指向權限設定，照做也無法解決真正發生的失敗
            return notice(TextState("無法建立訂購提醒"), message: TextState("訂購提醒建立失敗，請稍後再試。"))

        case .calendarUnavailable:
            // 找不到可寫入的行事曆不是權限問題，訊息不得指向設定
            return notice(
                TextState("找不到可寫入的行事曆"),
                message: TextState("找不到可寫入的行事曆，請新增或啟用一個可寫入的行事曆後再試。")
            )

        case .linkRemovalFailed:
            return operationFailure(TextState("提醒連結移除失敗，請稍後再試。"))

        case .oldEventRemovalFailed:
            return operationFailure(TextState("提醒已更新，但舊的行事曆事件移除失敗，請自行到行事曆刪除。"))

        case .eventRemovalAfterDeleteFailed:
            return operationFailure(TextState("開團已刪除，但行事曆上的提醒事件移除失敗，請自行到行事曆刪除。"))
        }
    }
}

// MARK: - Equatable

extension CampaignFeature.Destination.State: Equatable {}

// MARK: - Private Method

private extension CampaignFeature.Destination.State {

    /// 建立標題為「操作失敗」、只有「知道了」按鈕的通知
    ///
    /// - Parameter message: 失敗原因
    /// - Returns: 包含通知的 Destination state
    static func operationFailure(_ message: TextState) -> Self {
        notice(TextState("操作失敗"), message: message)
    }

    /// 建立只有「知道了」按鈕的一次性通知
    ///
    /// - Parameters:
    ///   - title: 通知標題
    ///   - message: 通知訊息
    /// - Returns: 包含通知的 Destination state
    static func notice(_ title: TextState, message: TextState) -> Self {
        .alert(
            AlertState<CampaignFeature.Destination.Alert> {
                title
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("知道了")
                }
            } message: {
                message
            }
        )
    }
}
