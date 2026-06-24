//
//  CloudSignInView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/14.
//

import AuthenticationServices
import GoogleSignInSwift
import SwiftUI

/// 雲端登入畫面 (僅 Google / Apple)。只有在 ``CloudSyncFeatureFlag/isEnabled`` 開啟且尚未登入時顯示
struct CloudSignInView: View {

    // MARK: - View Properties

    /// 雲端身分驗證
    let auth: CloudAuth

    /// 登入錯誤訊息；無錯誤為 `nil`
    @State private var errorMessage: String?

    // MARK: - View Body

    /// 登入畫面內容
    var body: some View {
        VStack(spacing: 24) {
            Text("BuyLedger")
                .font(.largeTitle.bold())
            Text("登入以同步你的代購記帳")
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
#if os(iOS)
                GoogleSignInButton(style: .wide) {
                    Task { await signInWithGoogle() }
                }
                .frame(maxWidth: .infinity)
#endif

                SignInWithAppleButton(.signIn) { request in
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = auth.makeAppleRequestNonce()
                } onCompletion: { result in
                    Task { await handleApple(result) }
                }
                .frame(height: 44)
            }
            .frame(maxWidth: 320)

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
            }
        }
        .padding()
    }
}

// MARK: - Private Method

private extension CloudSignInView {

#if os(iOS)
    /// 以 Google 登入
    func signInWithGoogle() async {
        errorMessage = nil
        guard let presenting = Self.topViewController() else {
            errorMessage = "無法開啟登入畫面"
            return
        }
        do {
            try await auth.signInWithGoogle(presenting: presenting)
        } catch {
            errorMessage = "Google 登入失敗，請再試一次"
        }
    }

    /// 取得目前前景視窗的 root view controller，供 Google 登入呈現
    static func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let keyWindow = scene.keyWindow else {
            return nil
        }
        return keyWindow.rootViewController
    }
#endif

    /// 處理 Apple 登入結果
    func handleApple(_ result: Result<ASAuthorization, Error>) async {
        errorMessage = nil
        switch result {
        case let .success(authorization):
            do {
                try await auth.handleAppleAuthorization(authorization)
            } catch {
                errorMessage = "Apple 登入失敗，請再試一次"
            }
        case .failure:
            errorMessage = "Apple 登入已取消或失敗"
        }
    }
}
