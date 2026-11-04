//
//  CampaignPresentationQueue.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture

/// 管理開團通知與目的地的呈現次序：目的地開啟或表單關閉中到達的通知先暫存
///
/// - Note: 表單關閉中或任何目的地開啟時都不可呈現通知
/// - Note: sheet 關閉動畫期間設進通知狀態仍可能被系統丟棄，所以要等關閉回呼
struct CampaignPresentationQueue: Equatable {

    // MARK: - Properties

    /// 表單是否正在關閉：從父層接受儲存或收到關閉事件，到 sheet 關閉動畫結束為止
    var isFormClosing = false

    /// 目的地開啟或表單關閉中到達的最新一則通知；沒有時為 `nil`
    var pendingNotice: AlertState<CampaignPresentationFeature.Destination.Alert>?
}

// MARK: - Internal Method

extension CampaignPresentationQueue {

    /// 呈現一則通知；目的地開啟或表單關閉中先暫存 (只留最新一則)，否則直接設進通知狀態
    ///
    /// - Parameters:
    ///   - notice: 要呈現的通知
    ///   - destination: 目前的目的地；非 `nil` 時先暫存通知
    ///   - presentedNotice: 目前呈現中的通知；沒有目的地時會被新通知取代
    mutating func present(
        _ notice: AlertState<CampaignPresentationFeature.Destination.Alert>,
        while destination: CampaignPresentationFeature.Destination.State?,
        into presentedNotice: inout AlertState<CampaignPresentationFeature.Destination.Alert>?
    ) {
        if isFormClosing || destination != nil {
            pendingNotice = notice
        } else {
            presentedNotice = notice
        }
    }

    /// 父層接受儲存並清空目的地後，標記表單開始關閉
    mutating func beginFormClosing() {
        isFormClosing = true
    }

    /// 收到目的地被關閉的事件時，若關閉前仍是表單 (取消無變更、確認捨棄、下滑關閉) 就標記表單開始關閉
    ///
    /// - Parameter destination: 事件送達時、尚未清空的目的地
    mutating func markFormClosing(
        dismissing destination: CampaignPresentationFeature.Destination.State?
    ) {
        if isFormOpen(destination) {
            isFormClosing = true
        }
    }

    /// 在 sheet 關閉動畫結束後清除關閉旗標，並把暫存的通知移進通知狀態
    ///
    /// - Parameters:
    ///   - presentedNotice: 目前呈現中的通知
    ///   - destination: 目前的目的地；非 `nil` 時暫存通知繼續等待
    mutating func finishFormClosing(
        into presentedNotice: inout AlertState<CampaignPresentationFeature.Destination.Alert>?,
        while destination: CampaignPresentationFeature.Destination.State?
    ) {
        isFormClosing = false
        presentPendingNotice(into: &presentedNotice, while: destination)
    }

    /// 目的地已關閉且表單不在關閉中時，將暫存通知移進通知狀態
    ///
    /// - Parameters:
    ///   - presentedNotice: 目前呈現中的通知
    ///   - destination: 目前的目的地；仍存在時保留暫存
    mutating func presentPendingNotice(
        into presentedNotice: inout AlertState<CampaignPresentationFeature.Destination.Alert>?,
        while destination: CampaignPresentationFeature.Destination.State?
    ) {
        guard !isFormClosing, destination == nil, let pendingNotice else {
            return
        }
        presentedNotice = pendingNotice
        self.pendingNotice = nil
    }
}

// MARK: - Private Method

private extension CampaignPresentationQueue {

    /// 目的地目前是否為編輯表單
    ///
    /// - Parameter destination: 要檢查的目的地
    /// - Returns: 是編輯表單時為 `true`
    func isFormOpen(_ destination: CampaignPresentationFeature.Destination.State?) -> Bool {
        if case .edit? = destination {
            return true
        }
        return false
    }
}
