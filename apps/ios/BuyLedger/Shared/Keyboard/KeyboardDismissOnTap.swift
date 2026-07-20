//
//  KeyboardDismissOnTap.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import SwiftUI
import UIKit

// MARK: - View Method

extension View {

    /// 讓使用者點擊畫面上「真正的空白處」時收起軟體鍵盤
    ///
    /// 透過 `gestureRecognizer(_:shouldReceive:)` 過濾：只有當點擊落在**非互動、非文字編輯、非系統文字選單**
    /// 的 view 時才呼叫 `endEditing(true)`。因此點按鈕、TextField (含換頁聚焦)、文字選取控制點、以及系統
    /// 編輯選單 (選取／全選／貼上) 都**不會**誤觸收鍵盤
    ///
    /// 手勢 `cancelsTouchesInView` 為 `false`，不影響底層 view 收到觸控；掛在 window 上，故同一 window
    /// 內 present 的 sheet (例如新增/編輯訂單) 也適用。
    /// - Returns: 套用收鍵盤手勢後的 view
    func dismissKeyboardOnTap() -> some View {
        background(
            KeyboardDismissInstaller()
                .accessibilityHidden(true)
        )
    }
}

/// 在所在 window 安裝「點擊收鍵盤」手勢的橋接 view；本身不繪製內容也不攔截觸控
private struct KeyboardDismissInstaller: UIViewRepresentable {

    // MARK: - Coordinator

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> UIView {
        let view = WindowTrackingView()
        view.isUserInteractionEnabled = false
        view.onMoveToWindow = { [weak coordinator = context.coordinator] window in
            coordinator?.install(on: window)
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    // MARK: - Coordinator

    /// 持有手勢並處理收鍵盤的協調者
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {

        /// 已安裝手勢的 window；避免同一個 window 重複加掛
        private weak var installedWindow: UIWindow?
    }
}

// MARK: - Internal Method

extension KeyboardDismissInstaller.Coordinator {

    /// 在指定 window 安裝收鍵盤手勢 (若尚未安裝)
    /// - Parameter window: 目標 window；`nil` 時 (view 離開畫面) 不處理
    func install(on window: UIWindow?) {
        guard let window, installedWindow !== window else {
            return
        }
        installedWindow = window

        let recognizer = UITapGestureRecognizer(
            target: self,
            action: #selector(handleTap)
        )
        recognizer.cancelsTouchesInView = false
        recognizer.delegate = self
        window.addGestureRecognizer(recognizer)
    }
}

// MARK: - Private Method

private extension KeyboardDismissInstaller.Coordinator {

    /// 點擊空白處時收起目前 window 內的鍵盤
    @objc func handleTap() {
        installedWindow?.endEditing(true)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension KeyboardDismissInstaller.Coordinator {

    /// 過濾觸控來源：只有點在「非互動、非文字編輯、非系統文字選單」的 view 才接受此手勢
    ///
    /// 這是修正「點貼上等系統 action 也被收鍵盤」的關鍵——先前對所有觸控都接受，導致點編輯選單、選取控制點或 TextField 本身都會誤觸 `endEditing`
    /// - Parameters:
    ///   - gestureRecognizer: 本手勢
    ///   - touch: 當下的觸控
    /// - Returns: 是否接受此觸控用於收鍵盤手勢
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldReceive touch: UITouch
    ) -> Bool {
        guard let touchedView = touch.view else {
            return true
        }
        return !touchedView.blocksKeyboardDismissTap
    }

    /// 僅對已知的捲動類手勢同時辨識，確保不阻擋捲動；其餘一律不放行
    ///
    /// 原本無條件回傳 `true`，等於對任何未知手勢都放行——包含系統文字選取與編輯選單自己的手勢。
    /// 收窄為白名單後，新的系統手勢預設不會與收鍵盤同時觸發
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        otherGestureRecognizer is UIPanGestureRecognizer
            || otherGestureRecognizer is UISwipeGestureRecognizer
    }
}

private extension UIView {

    /// 此 view 或它的任一上層 view (superview) 是否屬於「不該觸發收鍵盤」的元件：
    /// 互動控制項、文字輸入視圖，或系統文字編輯／選單 UI (編輯選單、選取控制點、放大鏡等)
    ///
    /// 從自身沿著 superview 逐層往上檢查，搭配型別檢查 (`UIControl` / `UITextInput`) 與系統私有類別名稱關鍵字 (這些 UI 多為私有型別，只能以類別名稱比對)
    var blocksKeyboardDismissTap: Bool {
        let blockingClassKeywords = [
            "UITextField",
            "UITextView",
            "EditMenu",
            "Callout",
            "TextSelection",
            "Magnifier",
            "Loupe",
        ]

        var node: UIView? = self
        while let view = node {
            if view is UIControl { return true }
            if view is UITextInput { return true }

            let className = NSStringFromClass(type(of: view))
            if blockingClassKeywords.contains(where: className.contains) {
                return true
            }

            node = view.superview
        }
        return false
    }
}

/// 透過 `didMoveToWindow` 回報自身所在 window 的輔助 view
private final class WindowTrackingView: UIView {

    /// 當 view 掛到 (或離開) window 時呼叫，帶入目前所在的 window
    var onMoveToWindow: ((UIWindow?) -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        onMoveToWindow?(window)
    }
}
