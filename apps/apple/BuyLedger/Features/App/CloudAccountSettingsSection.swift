//
//  CloudAccountSettingsSection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/14.
//

import SwiftUI

/// 設定頁的「帳號管理」section (帳號資訊 + 登出)，iOS 與 macOS 共用
///
/// 自帶 ``CloudAuth`` 實例，故須由外層以 ``CloudSyncFeatureFlag/isEnabled`` 旗標 gate 後才建立 (旗標關閉時不實例化、不觀察 Firebase Auth)。未登入時不顯示任何內容。登出後 ``CloudAuth`` 狀態更新，根層級閘門會自動切回登入畫面
struct CloudAccountSettingsSection: View {

    // MARK: - View Properties

    /// 雲端身分驗證 (本 section 建立時實例化)
    @State private var auth = CloudAuth()

    // MARK: - View Body

    /// 已登入時顯示帳號資訊與登出；未登入則不顯示
    var body: some View {
        if auth.isSignedIn {
            Section("帳號管理") {
                HStack(spacing: 12) {
                    Image(systemName: "person.crop.circle")
                        .font(.title2)
                        .foregroundStyle(.tint)
                    VStack(alignment: .leading, spacing: 2) {
                        if let name = auth.displayName, !name.isEmpty {
                            Text(name)
                        }
                        Text(auth.email ?? "已登入")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                Button("登出", role: .destructive) {
                    try? auth.signOut()
                }
            }
        }
    }
}
