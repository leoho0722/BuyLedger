//
//  BuyLedgerApp.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/29.
//

import SwiftUI
import SwiftData
import ComposableArchitecture

@main
struct BuyLedgerApp: App {

    // MARK: - App Properties

#if os(iOS)
    /// 接上 iOS / iPadOS 的 ``AppDelegate``，於啟動時初始化 Firebase
    @UIApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate
#elseif os(macOS)
    /// 接上 macOS 的 ``AppDelegate``，於啟動時初始化 Firebase
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate
#endif

    /// App 根層級 store
    private let store = Store(initialState: RootFeature.State()) {
        RootFeature()
    }

    /// SwiftData 共用 ``ModelContainer``；以純本機方式建立
    ///
    /// 直接取用 ``PersistenceContainer/shared`` (而非另呼叫 `makeForApp()`)，確保 SwiftUI environment 注入的 container 與各 repository 的 `liveValue` 是「同一個」實例，避免同一 process 內並存多個 container 造成 SwiftData 內部狀態錯亂。切換成 CloudKit 同步的步驟詳見 ``PersistenceContainer``
    private let modelContainer: ModelContainer = PersistenceContainer.shared

    // MARK: - App Body

    var body: some Scene {
        WindowGroup {
            AppRootView(store: store)
        }
        .modelContainer(modelContainer)
#if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(after: .newItem) {
                NewOrderMenuCommand()
            }
        }
#endif

#if os(macOS)
        Settings {
            SettingsMacView(
                store: store.scope(state: \.settings, action: \.settings)
            )
        }
#endif
    }
}

#if os(macOS)

// MARK: - macOS Menu Commands

/// macOS File 選單中的「新訂單」項目
///
/// 透過 ``FocusedValues/newOrderAction`` 與當前畫面的 store 連線；當沒有任何 ``OrdersMacView`` 取得焦點時，按鈕會自動 disabled
private struct NewOrderMenuCommand: View {

    // MARK: - View Properties

    /// 取得當前 focus 範圍內提供的「新訂單」action
    @FocusedValue(\.newOrderAction)
    private var newOrderAction

    // MARK: - View Body

    /// menu 項目內容
    var body: some View {
        Button("新訂單") {
            newOrderAction?()
        }
        .keyboardShortcut("n")
        .disabled(newOrderAction == nil)
    }
}

// MARK: - FocusedValueKey

/// 把「請求建立新訂單」的 closure 從畫面層傳遞到 macOS menu command 的 focused value key
struct NewOrderActionKey: FocusedValueKey {

    // MARK: - FocusedValueKey

    /// closure 不需要回傳值，只觸發 store action
    typealias Value = () -> Void
}

extension FocusedValues {

    // MARK: - Focused Values

    /// 由聚焦中的訂單畫面提供，由 menu command 觸發
    var newOrderAction: NewOrderActionKey.Value? {
        get { self[NewOrderActionKey.self] }
        set { self[NewOrderActionKey.self] = newValue }
    }
}

#endif
