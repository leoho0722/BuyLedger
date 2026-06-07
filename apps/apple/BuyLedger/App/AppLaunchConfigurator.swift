//
//  AppLaunchConfigurator.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/25.
//

import FirebaseCore

/// 集中管理 App 啟動時的各項服務初始化。
///
/// 三平台的 ``AppDelegate`` 都在 `didFinishLaunching` 時呼叫 ``configure()``，讓「啟動要做哪些設定」只存在一處；日後新增 Crashlytics、Analytics、Performance 等啟動設定也都集中在此。
enum AppLaunchConfigurator {

    // MARK: - Configuration

    /// 初始化 Firebase 及其已連結的模組 (Analytics、Crashlytics、Performance、Firestore)。
    ///
    /// `FirebaseApp.configure()` 會讀取 bundle 內的 `GoogleService-Info.plist`，並一併啟用所有已連結的 Firebase 模組。
    static func configure() {
        FirebaseApp.configure()
    }
}
