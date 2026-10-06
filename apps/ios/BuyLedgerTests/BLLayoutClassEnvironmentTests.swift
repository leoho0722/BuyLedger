//
//  BLLayoutClassEnvironmentTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/4.
//

import SwiftUI
import Testing
import UIKit

@testable import BuyLedger

/// 驗證同一視窗的尺寸分類改變時，既有探測畫面會觀察到版面更新
@MainActor
struct BLLayoutClassEnvironmentTests {

    /// 垂直尺寸分類由常規切到緊湊再還原時，同一畫面依序觀察到寬版、窄版、寬版
    ///
    /// - Throws: 等待場景被取消、無已連線的視窗場景，或初始版面不為寬版時拋出測試錯誤
    @Test
    func blLayoutClass_垂直尺寸分類往返_依序回報寬版窄版寬版() async throws(any Error) {
        // Given
        let sizeClass = \UITraitOverrides.verticalSizeClass

        // When
        guard let observed = try await Self.observeLayoutClasses(toggling: sizeClass) else {
            return
        }

        // Then
        #expect(observed == [.regular, .compact, .regular])
    }

    /// 水平尺寸分類由常規切到緊湊再還原時，同一畫面依序觀察到寬版、窄版、寬版
    ///
    /// - Throws: 等待場景被取消、無已連線的視窗場景，或初始版面不為寬版時拋出測試錯誤
    @Test
    func blLayoutClass_水平尺寸分類往返_依序回報寬版窄版寬版() async throws(any Error) {
        // Given
        let sizeClass = \UITraitOverrides.horizontalSizeClass

        // When
        guard let observed = try await Self.observeLayoutClasses(toggling: sizeClass) else {
            return
        }

        // Then
        #expect(observed == [.regular, .compact, .regular])
    }
}

// MARK: - Nested Types

private extension BLLayoutClassEnvironmentTests {

    /// 指向視窗特徵覆寫中某個尺寸分類的可寫入路徑
    typealias SizeClassKeyPath = WritableKeyPath<UITraitOverrides, UIUserInterfaceSizeClass>

    /// 等待觀察值與逾時計時競賽時可跨隔離傳遞的結果
    enum ObservationResult: Sendable {

        /// 探測畫面已回報版面
        ///
        /// - Parameter layoutClass: 這次觀察到的版面
        case value(BLLayoutClass)

        /// 等待超過兩秒
        case timedOut

        /// 尚未取得觀察值，紀錄串流就已結束
        case streamEnded
    }

    /// 只透過環境讀取版面，並在出現與變更時交給紀錄串流
    struct LayoutProbeView: View {

        /// 同一畫面在尺寸分類變更後重新讀取的版面
        @Environment(\.blLayoutClass) private var layoutClass

        /// 測試在視窗顯示前建立的紀錄入口
        private let continuation: AsyncStream<BLLayoutClass>.Continuation

        /// 建立探測畫面，將觀察值送到測試持有的串流
        ///
        /// - Parameter continuation: 接收初始與後續版面觀察值的紀錄入口
        init(continuation: AsyncStream<BLLayoutClass>.Continuation) {
            self.continuation = continuation
        }

        /// 探測畫面的骨架，在出現與版面改變時回報觀察值
        var body: some View {
            probeSurface
                .onAppear {
                    continuation.yield(layoutClass)
                }
                .onChange(of: layoutClass) {
                    continuation.yield(layoutClass)
                }
        }

        /// 讓探測畫面進入視窗階層的透明內容
        private var probeSurface: some View {
            Color.clear
        }
    }
}

// MARK: - Private Method

private extension BLLayoutClassEnvironmentTests {

    /// 以同一個視窗與畫面將指定的尺寸分類由常規切到緊湊再還原，回傳依序觀察到的版面
    ///
    /// - Parameter sizeClass: 要切換的尺寸分類，另一個尺寸分類全程維持常規
    /// - Returns: 初始、切到緊湊、還原後依序觀察到的版面，任一步無法取得時為 `nil`
    /// - Throws: 等待場景被取消、無已連線的視窗場景，或初始版面不為寬版時拋出測試錯誤
    /// - Note: 視窗、探測畫面與紀錄串流在整個呼叫內沿用，不在切換之間重建
    static func observeLayoutClasses(
        toggling sizeClass: SizeClassKeyPath
    ) async throws(any Error) -> [BLLayoutClass]? {
        let windowScene = try #require(
            try await Self.connectedWindowScene(),
            "等待 20 次後仍無已連線的 UIWindowScene"
        )
        let recorder = AsyncStream.makeStream(of: BLLayoutClass.self)
        let rootView = LayoutProbeView(continuation: recorder.continuation)
        let hostingController = UIHostingController(rootView: rootView)
        let window = UIWindow(windowScene: windowScene)
        window.frame = CGRect(
            x: 0,
            y: 0,
            width: 1024,
            height: 768
        )
        window.rootViewController = hostingController
        defer {
            window.isHidden = true
            window.rootViewController = nil
            recorder.continuation.finish()
        }
        hostingController.traitOverrides.horizontalSizeClass = .regular
        hostingController.traitOverrides.verticalSizeClass = .regular
        window.isHidden = false
        hostingController.updateTraitsIfNeeded()
        hostingController.view.updateTraitsIfNeeded()
        window.layoutIfNeeded()
        guard let initial = await Self.nextLayoutClass(in: recorder.stream) else {
            return nil
        }
        try #require(initial == .regular)
        var observed = [initial]
        for target in [UIUserInterfaceSizeClass.compact, .regular] {
            hostingController.traitOverrides[keyPath: sizeClass] = target
            hostingController.updateTraitsIfNeeded()
            hostingController.view.updateTraitsIfNeeded()
            window.layoutIfNeeded()
            guard let next = await Self.nextLayoutClass(in: recorder.stream) else {
                return nil
            }
            observed.append(next)
        }
        return observed
    }

    /// 在主執行緒有限次等待單元測試宿主的視窗場景連線
    ///
    /// - Returns: 最多等待 20 次取得的視窗場景，仍未連線時為 `nil`
    /// - Throws: 等待期間被取消時拋出 `CancellationError`
    static func connectedWindowScene() async throws(any Error) -> UIWindowScene? {
        for _ in 0..<20 {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            if let scene = scenes.first {
                return scene
            }
            try await ContinuousClock().sleep(for: .milliseconds(100))
        }
        return nil
    }

    /// 等待下一筆版面觀察值，逾時或串流結束時記錄失敗
    ///
    /// - Parameter stream: 緩衝探測畫面初始與後續觀察值的串流
    /// - Returns: 下一筆觀察值，無法取得時為 `nil`，呼叫端應結束測試
    /// - Note: 不存取 UIKit 或測試狀態，只傳遞 `Sendable` 值，因此不受主執行緒隔離
    nonisolated static func nextLayoutClass(
        in stream: AsyncStream<BLLayoutClass>
    ) async -> BLLayoutClass? {
        do {
            let result = try await withThrowingTaskGroup(of: ObservationResult.self) { group in
                defer {
                    group.cancelAll()
                }
                group.addTask {
                    var iterator = stream.makeAsyncIterator()
                    if let layoutClass = await iterator.next() {
                        return ObservationResult.value(layoutClass)
                    }
                    return ObservationResult.streamEnded
                }
                group.addTask {
                    try? await ContinuousClock().sleep(for: .seconds(2)) // 失敗可忽略，因為落敗者需取消
                    return ObservationResult.timedOut
                }
                guard let result = try await group.next() else {
                    return ObservationResult.streamEnded
                }
                return result
            }
            switch result {
            case .value(let layoutClass):
                return layoutClass

            case .timedOut:
                Issue.record("等待版面觀察值超過兩秒", severity: .error)

            case .streamEnded:
                Issue.record("版面紀錄串流在取得觀察值前結束", severity: .error)
            }
        } catch {
            Issue.record(error, "等待版面觀察值時發生錯誤")
        }
        return nil
    }
}
