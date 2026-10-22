//
//  CampaignPresentationQueue.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

/// 管理開團一次性通知與編輯表單的呈現次序：表單開啟或關閉中到達的通知先暫存，表單關好才顯示
///
/// - Note: 三個狀態：表單開啟 (目的地是編輯表單)、關閉中 (`isFormClosing`)、已關閉 (兩者皆非)
/// - Note: sheet 關閉動畫期間設進目的地的 alert 會被系統丟棄，但狀態仍宣稱正在顯示，所以要等關閉回呼
struct CampaignPresentationQueue: Equatable {

    // MARK: - Properties

    /// 表單是否正在關閉：從父層接受儲存或收到關閉事件，到 sheet 關閉動畫結束為止
    var isFormClosing = false

    /// 表單開啟或關閉中到達的最新一則通知；沒有時為 `nil`
    var pendingNotice: CampaignPresentationFeature.Destination.State?
}

// MARK: - Internal Method

extension CampaignPresentationQueue {

    /// 呈現一則通知；表單開啟或關閉中先暫存 (只留最新一則)，否則直接設進目的地
    ///
    /// - Parameters:
    ///   - notice: 要呈現的通知
    ///   - destination: 目前的目的地；表單已關閉時會被通知取代
    mutating func present(
        _ notice: CampaignPresentationFeature.Destination.State,
        in destination: inout CampaignPresentationFeature.Destination.State?
    ) {
        if isFormClosing || isFormOpen(destination) {
            pendingNotice = notice
        } else {
            destination = notice
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

    /// 在 sheet 關閉動畫結束後清除關閉旗標，並把暫存的通知移進目的地
    ///
    /// - Parameter destination: 目前的目的地；若又開了新的表單，暫存的通知繼續等到它關閉
    mutating func finishFormClosing(
        into destination: inout CampaignPresentationFeature.Destination.State?
    ) {
        isFormClosing = false
        guard !isFormOpen(destination), let pendingNotice else {
            return
        }
        destination = pendingNotice
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
