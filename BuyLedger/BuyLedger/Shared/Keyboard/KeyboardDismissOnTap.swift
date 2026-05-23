//
//  KeyboardDismissOnTap.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/23.
//

import SwiftUI

extension View {

    /// 讓使用者點擊畫面上任何非互動的空白處時收起軟體鍵盤。
    ///
    /// iOS / iPadOS 以 window 層級的 `UITapGestureRecognizer` 實作：手勢的 `cancelsTouchesInView` 為 `false` 且允許與其他手勢同時辨識，因此不會吃掉按鈕點擊、清單捲動或 TextField 聚焦，只在點到空白處時呼叫 `endEditing(true)` 收鍵盤。手勢掛在 window 上，故同一 window 內 present 的 sheet (例如新增/編輯訂單) 也同樣適用。macOS 無軟體鍵盤，為 no-op。
    /// - Returns: 套用收鍵盤手勢後的 view。
    func dismissKeyboardOnTap() -> some View {
#if os(iOS)
        background(KeyboardDismissInstaller().accessibilityHidden(true))
#else
        self
#endif
    }
}

#if os(iOS)
import UIKit

/// 在所在 window 安裝「點擊收鍵盤」手勢的橋接 view；本身不繪製內容也不攔截觸控。
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

    /// 持有手勢並處理收鍵盤的協調者。
    final class Coordinator: NSObject, UIGestureRecognizerDelegate {

        /// 已安裝手勢的 window；避免同一個 window 重複加掛。
        private weak var installedWindow: UIWindow?

        /// 在指定 window 安裝收鍵盤手勢 (若尚未安裝)。
        /// - Parameter window: 目標 window；`nil` 時 (view 離開畫面) 不處理。
        func install(on window: UIWindow?) {
            guard let window, installedWindow !== window else { return }
            installedWindow = window

            let recognizer = UITapGestureRecognizer(
                target: self,
                action: #selector(handleTap)
            )
            recognizer.cancelsTouchesInView = false
            recognizer.delegate = self
            window.addGestureRecognizer(recognizer)
        }

        /// 點擊時收起目前 window 內的鍵盤。
        @objc private func handleTap() {
            installedWindow?.endEditing(true)
        }

        // MARK: - UIGestureRecognizerDelegate

        /// 允許與其他手勢同時辨識，確保不阻擋按鈕、清單與捲動等既有互動。
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}

/// 透過 `didMoveToWindow` 回報自身所在 window 的輔助 view。
private final class WindowTrackingView: UIView {

    /// 當 view 掛到 (或離開) window 時呼叫，帶入目前所在的 window。
    var onMoveToWindow: ((UIWindow?) -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        onMoveToWindow?(window)
    }
}
#endif
