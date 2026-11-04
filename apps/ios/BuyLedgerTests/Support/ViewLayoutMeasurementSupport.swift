//
//  ViewLayoutMeasurementSupport.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/27.
//

import SwiftUI
import Testing
import UIKit

/// 跨測試套件共用的真實渲染與安全區測量輔助器
@MainActor
enum ViewLayoutMeasurementSupport {

    // MARK: - Properties

    /// 根層具名座標空間名稱
    static let coordinateSpaceName = "ViewLayoutMeasurementRootSpace"
}

// MARK: - Nested Types

@MainActor
extension ViewLayoutMeasurementSupport {

    /// 視圖佈局與安全區測量結果快照
    struct Snapshot: Equatable, Sendable {

        /// UIKit hosting view 之 bounds 實測值
        let hostBounds: CGRect

        /// UIKit hosting view 之有效 `safeAreaInsets` 實測值
        let uiKitSafeAreaInsets: UIEdgeInsets

        /// UIKit hosting view 在全域 (window/screen) 座標系下之原點實測值
        let hostGlobalOrigin: CGPoint

        /// SwiftUI 根層 `GeometryProxy.size` 實測值
        let rootSize: CGSize

        /// SwiftUI 根層 `GeometryProxy.safeAreaInsets` 實測值
        let rootSafeAreaInsets: EdgeInsets

        /// SwiftUI 根層座標空間原點相對於 global 之位置實測值
        let rootGlobalOrigin: CGPoint

        /// 前景 anchor 之內部內容 `frame` (相對於根具名座標空間) 實測值 (raw `frame`)
        let innerContentFrame: CGRect

        /// UIKit 官方有效安全區域矩形 (`hostBounds.inset(by: uiKitSafeAreaInsets)`)
        var uiKitSafeRect: CGRect {
            hostBounds.inset(by: uiKitSafeAreaInsets)
        }

        /// SwiftUI 根層相對於 UIKit hosting view 之原點位移實測值
        var rootOriginInHost: CGPoint {
            CGPoint(
                x: rootGlobalOrigin.x - hostGlobalOrigin.x,
                y: rootGlobalOrigin.y - hostGlobalOrigin.y
            )
        }

        /// 前景 anchor 轉換至 UIKit host 視圖座標系下之 `frame` 實測值
        var innerContentFrameInHost: CGRect {
            CGRect(
                x: innerContentFrame.origin.x + rootOriginInHost.x,
                y: innerContentFrame.origin.y + rootOriginInHost.y,
                width: innerContentFrame.width,
                height: innerContentFrame.height
            )
        }

        /// 輸出完整的佈局與座標診斷字串
        var diagnosticDescription: String {
            """
            [ViewLayoutMeasurementSupport.Snapshot Diagnostic]
            - hostBounds: \(hostBounds)
            - hostGlobalOrigin: \(hostGlobalOrigin)
            - uiKitSafeAreaInsets: (top: \(uiKitSafeAreaInsets.top), left: \(uiKitSafeAreaInsets.left), bottom: \(uiKitSafeAreaInsets.bottom), right: \(uiKitSafeAreaInsets.right))
            - uiKitSafeRect: \(uiKitSafeRect)
            - rootSize: \(rootSize)
            - rootSafeAreaInsets: (top: \(rootSafeAreaInsets.top), leading: \(rootSafeAreaInsets.leading), bottom: \(rootSafeAreaInsets.bottom), trailing: \(rootSafeAreaInsets.trailing))
            - rootGlobalOrigin: \(rootGlobalOrigin)
            - rootOriginInHost: \(rootOriginInHost)
            - innerContentFrame (raw): \(innerContentFrame)
            - innerContentFrameInHost: \(innerContentFrameInHost)
            """
        }
    }

    /// 根層幾何與內部前景 anchor 的單次測量樣本
    struct Sample: Equatable, Sendable {

        /// 根層幾何之實測尺寸
        let rootSize: CGSize

        /// 根層幾何之實測安全區邊距
        let rootSafeAreaInsets: EdgeInsets

        /// 根層幾何在全域座標空間之原點位置
        let rootGlobalOrigin: CGPoint

        /// 前景 anchor 在根具名座標空間中之相應 `frame`
        let innerContentFrame: CGRect
    }

    /// 前景內容之 `frame` 傳遞 `PreferenceKey`
    struct InnerFramePreferenceKey: PreferenceKey {

        /// 預設 `frame` 值，未觸發前為 nil
        static let defaultValue: CGRect? = nil

        /// 合併 preference 值，取最新有效 `frame`
        ///
        /// - Parameters:
        ///   - value: 當前累積之 `frame`
        ///   - nextValue: 下一閉包提供之 `frame`
        static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
            value = nextValue() ?? value
        }
    }

    /// 追蹤與記錄佈局樣本之主執行緒記錄器，具備修訂版本號與安靜區間收斂檢查能力
    @MainActor
    final class SampleRecorder {

        /// 最新測量到的佈局樣本
        private(set) var latestSample: Sample?

        /// 樣本修訂版本號 (每次新樣本湧入時遞增)
        private(set) var revision: Int = 0

        /// 記錄新的佈局樣本並遞增修訂版本號
        ///
        /// - Parameter sample: 最新測量樣本
        func record(_ sample: Sample) {
            latestSample = sample
            revision &+= 1
        }

        /// 等待幾何更新收斂至穩定狀態
        ///
        /// - Parameters:
        ///   - quietDuration: 連續無新樣本湧入的安靜區間門檻 (預設 50 毫秒)
        ///   - timeout: 總逾時上限 (預設 1 秒)
        /// - Returns: 在總期限內且安靜區間未越過期限之收斂快照樣本；若逾時、未收斂或無樣本則回傳 `nil`
        /// - Throws: 等待過程中任務被取消時丟出 `CancellationError`
        func waitForStable(
            quietDuration: Duration = .milliseconds(50),
            timeout: Duration = .seconds(1)
        ) async throws -> Sample? {
            let clock = ContinuousClock()
            let deadline = clock.now + timeout

            while true {
                try Task.checkCancellation()

                let now = clock.now
                guard now < deadline else {
                    return nil
                }

                guard let currentSample = latestSample else {
                    let pollInterval: Duration = .milliseconds(10)
                    guard now + pollInterval < deadline else {
                        return nil
                    }
                    try await clock.sleep(for: pollInterval)
                    continue
                }

                guard now + quietDuration <= deadline else {
                    return nil
                }

                let observedRevision = revision
                try await clock.sleep(for: quietDuration)

                let wakeTime = clock.now
                if wakeTime <= deadline && revision == observedRevision {
                    return currentSample
                }
            }
        }
    }

    /// 用於探測 SwiftUI 根層 `GeometryProxy` 與內部 Anchor 的宿主探針視圖
    private struct Probe<Content: View>: View {

        /// 注入環境之 Dynamic Type 字級
        let dynamicTypeSize: DynamicTypeSize

        /// 採樣完成時於主執行緒派送樣本之回呼閉包
        let onSample: @MainActor (Sample) -> Void

        /// 建構內部受測內容之閉包
        @ViewBuilder let makeContent: () -> Content

        /// 以根層 `GeometryReader` 提供測量空間並把內部 anchor 樣本送至 `MainActor` recorder
        var body: some View {
            GeometryReader { rootProxy in
                makeContent()
                    .onPreferenceChange(InnerFramePreferenceKey.self) { innerFrame in
                        reportSample(rootProxy: rootProxy, innerFrame: innerFrame)
                    }
            }
            .coordinateSpace(name: ViewLayoutMeasurementSupport.coordinateSpaceName)
            .environment(\.dynamicTypeSize, dynamicTypeSize)
        }

        /// 把內部 anchor 的 `frame` 與根層幾何組成樣本，並於主執行緒送出
        ///
        /// - Parameters:
        ///   - rootProxy: 根層 `GeometryReader` 提供的幾何代理
        ///   - innerFrame: 內部 anchor 的 `frame`，尚未觸發時為 `nil`
        private func reportSample(rootProxy: GeometryProxy, innerFrame: CGRect?) {
            guard let innerFrame else {
                return
            }
            let sample = Sample(
                rootSize: rootProxy.size,
                rootSafeAreaInsets: rootProxy.safeAreaInsets,
                rootGlobalOrigin: rootProxy.frame(in: .global).origin,
                innerContentFrame: innerFrame
            )
            Task { @MainActor in
                onSample(sample)
            }
        }
    }
}

// MARK: - Internal Method

@MainActor
extension ViewLayoutMeasurementSupport {

    /// 在主執行緒有限次等待已連線的 `UIWindowScene`
    ///
    /// - Returns: 最多等待 20 次取得的視窗場景，仍未連線時為 `nil`
    /// - Throws: 等待期間被取消時丟出 `CancellationError`
    static func connectedWindowScene() async throws -> UIWindowScene? {
        for _ in 0..<20 {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            if let scene = scenes.first {
                return scene
            }
            try await ContinuousClock().sleep(for: .milliseconds(100))
        }
        return nil
    }

    /// 在真實 `UIWindowScene` 宿主中測量視圖之佈局快照
    ///
    /// - Parameters:
    ///   - containerSize: 視窗與宿主控制器之容器尺寸
    ///   - additionalSafeAreaInsets: 注入宿主控制器之額外安全區邊距
    ///   - dynamicTypeSize: 注入環境之 Dynamic Type 字級
    ///   - makeView: 視圖建構閉包
    /// - Returns: 測量完成之 `Snapshot` 快照，逾時未取得時為 `nil`
    /// - Throws: 無連線視窗場景時丟出錯誤
    static func measureLayout<Content: View>(
        containerSize: CGSize,
        additionalSafeAreaInsets: UIEdgeInsets = .zero,
        dynamicTypeSize: DynamicTypeSize = .large,
        @ViewBuilder makeView: @escaping () -> Content
    ) async throws -> Snapshot? {
        let windowScene = try #require(
            try await Self.connectedWindowScene(),
            "等待 20 次後仍無已連線的 UIWindowScene"
        )
        let recorder = SampleRecorder()
        let probe = Probe(
            dynamicTypeSize: dynamicTypeSize,
            onSample: { recorder.record($0) },
            makeContent: makeView
        )
        let hostingController = UIHostingController(rootView: probe)
        hostingController.additionalSafeAreaInsets = additionalSafeAreaInsets
        hostingController.view.frame = CGRect(origin: .zero, size: containerSize)

        let window = UIWindow(windowScene: windowScene)
        window.frame = CGRect(origin: .zero, size: containerSize)
        window.rootViewController = hostingController
        defer {
            window.isHidden = true
            window.rootViewController = nil
        }

        window.isHidden = false
        hostingController.updateTraitsIfNeeded()
        hostingController.view.updateTraitsIfNeeded()
        hostingController.view.setNeedsLayout()
        hostingController.view.layoutIfNeeded()
        window.layoutIfNeeded()

        // 排版可能分多輪完成，等幾何在安靜區間內不再變動才採用，避免讀到排版中途的數值
        let stableSample = try await recorder.waitForStable()

        guard let sample = stableSample else {
            return nil
        }

        let hostGlobalOrigin = hostingController.view.convert(CGPoint.zero, to: nil)

        return Snapshot(
            hostBounds: hostingController.view.bounds,
            uiKitSafeAreaInsets: hostingController.view.safeAreaInsets,
            hostGlobalOrigin: hostGlobalOrigin,
            rootSize: sample.rootSize,
            rootSafeAreaInsets: sample.rootSafeAreaInsets,
            rootGlobalOrigin: sample.rootGlobalOrigin,
            innerContentFrame: sample.innerContentFrame
        )
    }
}
