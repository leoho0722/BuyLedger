//
//  SettingsFeature+Destination.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture
import Foundation

// MARK: - Nested Types

extension SettingsFeature {

    /// 設定頁呈現的啟用失敗說明
    @Reducer
    enum Destination {

        /// 啟用 App 鎖定失敗或裝置不支援的 alert
        ///
        /// - Parameter state: alert 的標題、訊息與關閉按鈕
        @ReducerCaseIgnored case alert(AlertState<Alert>)

        /// 設定頁 alert 的呈現事件
        @CasePathable
        enum Action {

            /// alert 被關閉，沒有其他選項
            ///
            /// - Parameter action: alert 的選項型別
            case alert(Alert)
        }

        /// 啟用失敗說明只提供關閉按鈕
        @CasePathable
        enum Alert: Equatable, Sendable {}
    }
}

// MARK: - Computed Properties

extension SettingsFeature.Destination.State {

    /// 驗證失敗或取消時的說明
    static var authenticationFailedAlert: Self {
        .alert(
            AlertState<SettingsFeature.Destination.Alert> {
                TextState("settings.preference.label.unableEnableApp")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("common.action.label.close")
                }
            } message: {
                TextState("settings.preference.message.authenticationFailedCancelled")
            }
        )
    }

    /// 裝置不支援本機驗證時的說明
    static var unsupportedDeviceAlert: Self {
        .alert(
            AlertState<SettingsFeature.Destination.Alert> {
                TextState("settings.preference.label.unableEnableApp")
            } actions: {
                ButtonState(role: .cancel) {
                    TextState("common.action.label.close")
                }
            } message: {
                TextState("settings.preference.message.deviceCannotCurrently")
            }
        )
    }
}

// MARK: - Equatable

extension SettingsFeature.Destination.State: Equatable {}

// MARK: - Sendable

extension SettingsFeature.Destination.State: Sendable {}
