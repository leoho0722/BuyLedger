//
//  OrdersPresentationQueue.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

/// 管理三種 sheet、合併轉場與一次性通知的先後，關閉動畫結束才呈現通知
struct OrdersPresentationQueue: Equatable {

    // MARK: - Properties

    /// 從 sheet 清空到關閉回呼之間是否仍在關閉動畫中
    var isFormClosing = false

    /// 候選 sheet 完成後是否仍在等待合併確認表單，通知不得搶先呈現
    var isAwaitingMergeConfirmation = false

    /// 三種 sheet 開啟、關閉或合併轉場中到達的最新通知
    var pendingNotice: OrdersPresentationFeature.Destination.State?

    /// 500ms 已到但候選 sheet 尚未關好時，等待關閉回呼的確認表單
    var pendingMergeConfirmation: OrdersPresentationFeature.Destination.State?
}

// MARK: - Internal Method

extension OrdersPresentationQueue {

    /// 呈現通知；sheet 或合併轉場受保護期間只保留最新一則
    ///
    /// - Parameters:
    ///   - notice: 要呈現的通知
    ///   - destination: 容器目前的目的地
    mutating func present(
        _ notice: OrdersPresentationFeature.Destination.State,
        in destination: inout OrdersPresentationFeature.Destination.State?
    ) {
        if isFormClosing || isAwaitingMergeConfirmation || isFormOpen(destination) {
            pendingNotice = notice
        } else {
            destination = notice
        }
    }

    /// 收到 dismiss 時，以清空前的目的地判斷是否需要等待 sheet 關閉回呼
    ///
    /// - Parameter destination: 尚未清空的目的地
    mutating func markFormClosing(
        dismissing destination: OrdersPresentationFeature.Destination.State?
    ) {
        if isFormOpen(destination) {
            beginFormClosing()
        }
    }

    /// 候選 sheet 完成時保留確認表單的呈現優先權
    mutating func beginMergeTransition() {
        beginFormClosing()
        isAwaitingMergeConfirmation = true
    }

    /// 容器主動清空 sheet 時標記關閉動畫開始
    mutating func beginFormClosing() {
        isFormClosing = true
    }

    /// 500ms 完成後呈現合併確認表單，關閉動畫尚未結束時繼續等待
    ///
    /// - Parameters:
    ///   - confirmation: 已建立的合併確認表單
    ///   - destination: 容器目前的目的地
    mutating func presentMergeConfirmation(
        _ confirmation: OrdersPresentationFeature.Destination.State,
        in destination: inout OrdersPresentationFeature.Destination.State?
    ) {
        if isFormClosing {
            pendingMergeConfirmation = confirmation
        } else {
            isAwaitingMergeConfirmation = false
            destination = confirmation
        }
    }

    /// sheet 關好後先呈現已就緒的合併確認表單，其次才取出暫存通知
    ///
    /// - Parameter destination: 容器目前的目的地
    mutating func finishFormClosing(
        into destination: inout OrdersPresentationFeature.Destination.State?
    ) {
        isFormClosing = false
        if let pendingMergeConfirmation {
            destination = pendingMergeConfirmation
            self.pendingMergeConfirmation = nil
            isAwaitingMergeConfirmation = false
            return
        }
        guard !isAwaitingMergeConfirmation, !isFormOpen(destination), let pendingNotice else {
            return
        }
        destination = pendingNotice
        self.pendingNotice = nil
    }
}

// MARK: - Private Method

private extension OrdersPresentationQueue {

    /// 判斷目前是否為任一受保護的 sheet
    ///
    /// - Parameter destination: 要檢查的目的地
    /// - Returns: 編輯、合併候選或 AI 摘要 sheet 開啟時為 `true`
    func isFormOpen(_ destination: OrdersPresentationFeature.Destination.State?) -> Bool {
        switch destination {
        case .edit?, .merge?, .aiSummary?:
            return true

        case .alert?, nil:
            return false
        }
    }
}
