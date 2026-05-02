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

    /// App 根層級 store。
    private let store = Store(initialState: RootFeature.State()) {
        RootFeature()
    }

    /// SwiftData 共用 ``ModelContainer``；目前以純本機方式建立。
    ///
    /// 未來要打開 CloudKit 同步時，把 ``PersistenceContainer/makeForApp()`` 換成
    /// `try PersistenceContainer.make(cloudKit: .privateContainer("iCloud.com.leoho.BuyLedger"))` 並補上 iCloud
    /// 與 Background Modes capabilities 即可。
    private let modelContainer: ModelContainer = PersistenceContainer.makeForApp()

    // MARK: - App Body

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
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
            SettingsScene_macOS(
                store: store.scope(state: \.settings, action: \.settings)
            )
        }
#endif
    }
}

#if os(macOS)

// MARK: - macOS Menu Commands

/// macOS File 選單中的「新訂單」項目。
///
/// 透過 ``FocusedValues/newOrderAction`` 與當前畫面的 store 連線；當沒有任何 ``OrdersMacView`` 取得焦點時，按鈕會自動 disabled。
private struct NewOrderMenuCommand: View {

    // MARK: - View Properties

    /// 取得當前 focus 範圍內提供的「新訂單」action。
    @FocusedValue(\.newOrderAction)
    private var newOrderAction

    // MARK: - View Body

    /// menu 項目內容。
    var body: some View {
        Button("新訂單") {
            newOrderAction?()
        }
        .keyboardShortcut("n")
        .disabled(newOrderAction == nil)
    }
}

// MARK: - FocusedValueKey

/// 把「請求建立新訂單」的 closure 從畫面層傳遞到 macOS menu command 的 focused value key。
struct NewOrderActionKey: FocusedValueKey {

    // MARK: - FocusedValueKey

    /// closure 不需要回傳值，只觸發 store action。
    typealias Value = () -> Void
}

extension FocusedValues {

    // MARK: - Focused Values

    /// 由聚焦中的訂單畫面提供，由 menu command 觸發。
    var newOrderAction: NewOrderActionKey.Value? {
        get { self[NewOrderActionKey.self] }
        set { self[NewOrderActionKey.self] = newValue }
    }
}

#endif
