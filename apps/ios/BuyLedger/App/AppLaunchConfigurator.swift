//
//  AppLaunchConfigurator.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/25.
//

import FirebaseCore

/// 集中管理 App 啟動時的各項服務初始化
///
/// App 的 ``AppDelegate`` 在 `didFinishLaunching` 時呼叫 ``configure()``，
/// 讓「啟動要做哪些設定」只存在一處；日後新增 Crashlytics、Analytics、Performance
/// 等啟動設定也都集中在此
enum AppLaunchConfigurator {}

// MARK: - Internal Method

extension AppLaunchConfigurator {

    /// 初始化 Firebase
    static func configure() {
        FirebaseApp.configure()
    }
}
