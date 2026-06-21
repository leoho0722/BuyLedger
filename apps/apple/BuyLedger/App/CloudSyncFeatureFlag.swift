//
//  CloudSyncFeatureFlag.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/14.
//

import Foundation

/// 跨平台雲端同步 (Firebase Auth 登入 + Firestore 同步) 的總開關。
///
/// 預設**關閉**：iOS 維持本機 SwiftData (搭配 CloudKit) 的儲存與同步，不顯示登入、不存取 Firestore，行為與導入前完全一致。開啟後才會走 Firebase Auth (Google / Apple) 登入，並讀寫使用者各自的 `users/{uid}/…` Firestore 子集合做跨平台同步。
enum CloudSyncFeatureFlag {

    /// 雲端同步 (Firebase Auth 登入 + Firestore 同步) 總開關。
    /// 跨裝置同步 (enable-cross-device-sync) 演示期間開啟；正式預設值之後再依發佈策略收斂。
    static let isEnabled = true
}
