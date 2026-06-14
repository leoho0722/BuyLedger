//
//  CloudAuth.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/14.
//

@preconcurrency import AuthenticationServices
@preconcurrency import FirebaseAuth
@preconcurrency import GoogleSignIn
import CryptoKit
import FirebaseCore
import Foundation

/// 雲端身分驗證 (Firebase Auth + Google / Apple)。
///
/// 僅在 ``CloudSyncFeatureFlag/isEnabled`` 為 `true` 時建立與使用；旗標關閉時不會被實例化，App 不會觀察 Firebase Auth 狀態、行為與導入前一致。
@MainActor
@Observable
final class CloudAuth {

    // MARK: - Auth Properties

    /// 目前登入的 Firebase 使用者；未登入為 `nil`。
    private(set) var user: User?

    /// Firebase Auth 狀態監聽控制代碼。
    @ObservationIgnored
    private var handle: AuthStateDidChangeListenerHandle?

    /// Apple 登入用的當次 nonce (原始值)；於 ``handleAppleAuthorization(_:)`` 驗證時比對。
    @ObservationIgnored
    private var currentNonce: String?

    // MARK: - Lifecycle

    /// 取目前使用者並開始監聽 Firebase Auth 狀態變化。
    init() {
        user = Auth.auth().currentUser
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in self?.user = user }
        }
    }

    deinit {
        if let handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Token

    /// 目前使用者的 uid；未登入為 `nil`。
    var uid: String? { user?.uid }

    /// 是否已登入。
    var isSignedIn: Bool { user != nil }

    /// 目前使用者顯示名稱；未設定為 `nil`。
    var displayName: String? { user?.displayName }

    /// 目前使用者電子郵件；未設定為 `nil`。
    var email: String? { user?.email }

    /// 取得目前使用者的 Firebase ID token (供後端 API 夾帶 Authorization)；未登入回 `nil`。
    func idToken() async throws -> String? {
        try await user?.getIDToken()
    }

    /// 登出。
    func signOut() throws {
        try Auth.auth().signOut()
    }

    // MARK: - Google

#if os(iOS)
    /// 以 Google 登入：取 Google ID token 後換成 Firebase 憑證登入 (iOS 專屬；macOS 的呈現上下文為 NSWindow，待支援)。
    /// - Parameter presenting: 呈現 Google 登入流程的 view controller。
    func signInWithGoogle(presenting: UIViewController) async throws {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw CloudAuthError.missingGoogleClientID
        }
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenting)
        guard let idToken = result.user.idToken?.tokenString else {
            throw CloudAuthError.missingGoogleToken
        }
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        try await Auth.auth().signIn(with: credential)
    }
#endif

    // MARK: - Apple

    /// 產生 Apple 登入請求用的 nonce；回傳 SHA256 雜湊 (放進 `ASAuthorizationAppleIDRequest.nonce`)，原始值留存供登入完成時比對。
    func makeAppleRequestNonce() -> String {
        let nonce = Self.randomNonceString()
        currentNonce = nonce
        return Self.sha256(nonce)
    }

    /// 以 Apple 授權結果換成 Firebase 憑證登入。
    func handleAppleAuthorization(_ authorization: ASAuthorization) async throws {
        guard let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentNonce,
              let tokenData = appleCredential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            throw CloudAuthError.invalidAppleCredential
        }
        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: appleCredential.fullName
        )
        try await Auth.auth().signIn(with: credential)
        currentNonce = nil
    }

    // MARK: - Nonce Helpers

    /// 產生密碼學隨機 nonce 字串 (Apple 登入防重放)。此為安全用途的隨機值、不走可注入時鐘/亂數。
    private static func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var random: UInt8 = 0
            let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            guard status == errSecSuccess else { continue }
            if random < charset.count {
                result.append(charset[Int(random) % charset.count])
                remaining -= 1
            }
        }
        return result
    }

    /// 對 nonce 取 SHA256 十六進位字串。
    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}

// MARK: - CloudAuthError

/// 雲端登入流程的錯誤。
enum CloudAuthError: Error {
    /// `GoogleService-Info.plist` 缺 Google `CLIENT_ID` (需在 Firebase Console 啟用 Google 登入後取得)。
    case missingGoogleClientID
    /// Google 登入未回傳 ID token。
    case missingGoogleToken
    /// Apple 授權結果不完整或 nonce 不符。
    case invalidAppleCredential
}
