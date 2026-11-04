//
//  XCUIApplication+TextInput.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

// MARK: - Nested Types

@MainActor
extension XCUIApplication {

    /// 數字鍵盤的呈現方式，iPadOS 27 不固定為單一樣式
    enum NumericKeyboardPresentation: Equatable {

        /// 完整軟體鍵盤，工具列有完成鍵
        case fullKeyboard

        /// 底部浮動數字面板，沒有工具列完成鍵
        case floatingPad

        /// 貼在欄位旁的 Popover 數字鍵盤
        case popover

        /// 沒有數字鍵盤呈現
        case absent

        /// 診斷訊息用的中文名稱
        var diagnosticName: String {
            switch self {
            case .fullKeyboard:
                return "完整鍵盤"

            case .floatingPad:
                return "浮動數字面板"

            case .popover:
                return "數字 Popover"

            case .absent:
                return "未呈現"
            }
        }
    }
}

// MARK: - Computed Properties

@MainActor
extension XCUIApplication {

    /// 數字 Popover 是否呈現，以 Popover 與全螢幕關閉區域同時出現判定
    var isNumericPopoverPresented: Bool {
        guard popovers.firstMatch.exists else {
            return false
        }
        return descendants(matching: .any)
            .matching(identifier: Self.popoverDismissRegionIdentifier)
            .firstMatch
            .exists
    }

    /// 目前數字鍵盤的呈現方式；Popover 以可及性元素判定，系統鍵盤依框線高度區分
    ///
    /// - Note: iPhone 橫向鍵盤即使較窄，只要高度足夠仍屬完整鍵盤
    /// - Note: 取不到鍵盤框線時沿用 `.fullKeyboard`，由有值斷言的呼叫端捕捉錯誤分類
    var numericKeyboardPresentation: NumericKeyboardPresentation {
        if isNumericPopoverPresented {
            return .popover
        }
        let keyboard = keyboards.firstMatch
        guard keyboard.exists else {
            return .absent
        }
        guard let keyboardFrame = keyboard.snapshotFrame else {
            return .fullKeyboard
        }
        return isFloatingPadFrame(keyboardFrame) ? .floatingPad : .fullKeyboard
    }

    /// 目前呈現中的鍵盤或數字 Popover 框線；完整鍵盤尚未落在視窗內時為 `nil`
    var presentedKeyboardFrame: CGRect? {
        if isNumericPopoverPresented {
            return popovers.firstMatch.snapshotFrame
        }
        let keyboard = keyboards.firstMatch
        guard keyboard.exists,
              let keyboardFrame = keyboard.snapshotFrame,
              let windowFrame = windows.firstMatch.snapshotFrame else {
            return nil
        }
        let isFloatingPad = isFloatingPadFrame(keyboardFrame)
        guard isFloatingPad || windowFrame.contains(keyboardFrame) else {
            return nil
        }
        return keyboardFrame
    }
}

// MARK: - Internal Method

@MainActor
extension XCUIApplication {

    /// 等待數字鍵盤或數字 Popover 任一呈現到逾時
    ///
    /// - Parameter timeout: 等待呈現的秒數
    /// - Returns: 是否在逾時前呈現
    func waitForNumericKeyboardPresentation(timeout: TimeInterval) -> Bool {
        pollUntil(timeout: timeout) {
            numericKeyboardPresentation != .absent
        }
    }

    /// 等待數字鍵盤與數字 Popover 都收起到逾時
    ///
    /// - Parameter timeout: 等待收起的秒數
    /// - Returns: 是否在逾時前全部收起
    func waitForNumericKeyboardDismissal(timeout: TimeInterval) -> Bool {
        pollUntil(timeout: timeout) {
            numericKeyboardPresentation == .absent
        }
    }

    /// 等待數字鍵盤換成完整鍵盤到逾時
    ///
    /// - Parameter timeout: 等待的秒數
    /// - Returns: 是否在逾時前換成完整鍵盤
    func waitForFullKeyboard(timeout: TimeInterval) -> Bool {
        pollUntil(timeout: timeout) {
            numericKeyboardPresentation == .fullKeyboard
        }
    }
}

/// 以短間隔輪詢條件到成立或逾時
///
/// - Parameters:
///   - timeout: 等待條件成立的秒數
///   - condition: 要輪詢的條件
/// - Returns: 條件是否在逾時前成立
@MainActor
func pollUntil(timeout: TimeInterval, _ condition: () -> Bool) -> Bool {
    let deadline = Date.now.addingTimeInterval(timeout)
    while !condition() {
        guard Date.now < deadline else {
            return false
        }
        _ = XCTWaiter().wait(for: [XCTestExpectation()], timeout: 0.2)
    }
    return true
}

// MARK: - Private Method

@MainActor
private extension XCUIApplication {

    /// 數字 Popover 的全螢幕關閉區域，系統提供的 identifier，App 端沒有對應常數
    static var popoverDismissRegionIdentifier: String {
        "PopoverDismissRegion"
    }

    /// 浮動數字面板的最大高度
    ///
    /// - Returns: 浮動數字面板的高度分類門檻
    /// - Note: 浮動面板遠低於完整鍵盤
    /// - Note: 完整鍵盤約 279 高，依 iPad Air 5 失敗附件實測
    static var floatingPadMaximumHeight: CGFloat {
        120
    }

    /// 判斷鍵盤框線高度是否低於浮動數字面板的高度門檻
    ///
    /// - Parameter keyboardFrame: Keyboard 元素的框線
    /// - Returns: 是否為浮動數字面板
    func isFloatingPadFrame(_ keyboardFrame: CGRect) -> Bool {
        keyboardFrame.height < Self.floatingPadMaximumHeight
    }
}
