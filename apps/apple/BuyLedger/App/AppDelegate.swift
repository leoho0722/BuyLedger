//
//  AppDelegate.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/25.
//

#if os(iOS)
import UIKit

/// iOS / iPadOS 的應用程式委派
///
/// 透過 ``BuyLedgerApp`` 的 `@UIApplicationDelegateAdaptor` 接入 SwiftUI 生命週期，在 App 完成啟動時呼叫 ``AppLaunchConfigurator/configure()`` 執行啟動設定
final class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - UIApplicationDelegate

    /// App 完成啟動後執行各項啟動設定 (含 Firebase 初始化)
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        AppLaunchConfigurator.configure()
        return true
    }
}

#elseif os(macOS)
import AppKit

/// macOS 的應用程式委派
///
/// 透過 ``BuyLedgerApp`` 的 `@NSApplicationDelegateAdaptor` 接入 SwiftUI 生命週期，在 App 完成啟動時呼叫 ``AppLaunchConfigurator/configure()`` 執行啟動設定
final class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - NSApplicationDelegate

    /// App 完成啟動後執行各項啟動設定 (含 Firebase 初始化)
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppLaunchConfigurator.configure()
    }
}
#endif
