//
//  BLReadableScrollContentLayoutTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/30.
//

import SwiftUI
import Testing
import UIKit

@testable import BuyLedger

/// `BLReadableScrollContentLayout` 的計算與渲染測試
///
/// 涵蓋不同捲動容器的寬度限制、窄區預設邊距與列寬位置
///
/// - Note: 測試以獨立字面值 (文字 640 pt、表單 680 pt) 對照 iPad 實測確認的閱讀上限
struct BLReadableScrollContentLayoutTests {

    // MARK: - Properties

    /// 文字內容最大閱讀寬度字面值 (單位：pt)
    private static let literalCandidateTextWidth: CGFloat = 640

    /// 表單內容最大閱讀寬度字面值 (單位：pt)
    private static let literalCandidateFormWidth: CGFloat = 680

    /// 浮點數佈局測量容許誤差 (單位：pt)
    private static let tolerance: CGFloat = 1.0

    /// 驗證不對稱安全區的左右邊距各自合併閱讀邊距
    @Test
    func blReadableScrollContent_非對稱安全區_邊距合併左右安全區() {
        // Given
        let containerWidth: CGFloat = 880
        let maximumWidth: CGFloat = 640
        let leadingSafeAreaInset: CGFloat = 300
        let trailingSafeAreaInset: CGFloat = 0

        // When
        let margins = BLReadableContentLayout.scrollContentEdgeMargins(
            containerWidth: containerWidth,
            maximumWidth: maximumWidth,
            leadingSafeAreaInset: leadingSafeAreaInset,
            trailingSafeAreaInset: trailingSafeAreaInset
        )

        // Then
        #expect(margins.leading == 420)
        #expect(margins.trailing == 120)
    }

    /// 驗證對稱安全區的左右邊距相等且合併安全區
    @Test
    func blReadableScrollContent_對稱安全區_邊距合併左右安全區() {
        // Given
        let containerWidth: CGFloat = 750
        let maximumWidth: CGFloat = 640
        let leadingSafeAreaInset: CGFloat = 62
        let trailingSafeAreaInset: CGFloat = 62

        // When
        let margins = BLReadableContentLayout.scrollContentEdgeMargins(
            containerWidth: containerWidth,
            maximumWidth: maximumWidth,
            leadingSafeAreaInset: leadingSafeAreaInset,
            trailingSafeAreaInset: trailingSafeAreaInset
        )

        // Then
        #expect(margins.leading == 117)
        #expect(margins.trailing == 117)
    }

    /// 驗證容器寬度不超過閱讀上限時不增加左右邊距
    @Test
    func blReadableScrollContent_寬度未超上限_左右邊距皆為nil() {
        // Given
        let containerWidth: CGFloat = 640
        let maximumWidth: CGFloat = 640
        let leadingSafeAreaInset: CGFloat = 62
        let trailingSafeAreaInset: CGFloat = 62

        // When
        let margins = BLReadableContentLayout.scrollContentEdgeMargins(
            containerWidth: containerWidth,
            maximumWidth: maximumWidth,
            leadingSafeAreaInset: leadingSafeAreaInset,
            trailingSafeAreaInset: trailingSafeAreaInset
        )

        // Then
        #expect(margins.leading == nil)
        #expect(margins.trailing == nil)
    }

    /// 驗證寬容器中的 `ScrollView` 內容限寬於 640 pt 並在安全區內置中，量到的是版面穩定後的最終值
    ///
    /// - Throws: 測量場景缺失或非同步等待被取消時傳遞錯誤，快照不存在時由 `#require` 丟出
    @Test
    @MainActor
    func blReadableScrollContent_寬容器_限寬640並置中() async throws {
        // Given
        let containerSize = CGSize(width: 1024, height: 768)
        let expectedWidth = Self.literalCandidateTextWidth

        // When
        let snapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: containerSize
        ) {
            Self.scrollSample(isReadable: true)
        }
        let verified = try #require(snapshot, "未能取得寬容器 ScrollView 的量測快照")

        // Then
        let measuredFrame = verified.innerContentFrameInHost
        let safeRect = verified.uiKitSafeRect
        let expectedMinX = safeRect.minX + (safeRect.width - expectedWidth) / 2
        #expect(
            abs(measuredFrame.width - expectedWidth) <= Self.tolerance,
            """
            寬容器 ScrollView 寬度應為 640 pt，實測：\(measuredFrame.width)
            \(verified.diagnosticDescription)
            """
        )
        #expect(
            abs(measuredFrame.minX - expectedMinX) <= Self.tolerance,
            """
            寬容器 ScrollView minX 應為 \(expectedMinX) pt，實測：\(measuredFrame.minX)
            \(verified.diagnosticDescription)
            """
        )
        #expect(
            measuredFrame.width > 0 && measuredFrame.width < safeRect.width,
            "版面穩定後內容寬度不應殘留零寬或安全區寬度，實測寬度：\(measuredFrame.width)\n\(verified.diagnosticDescription)"
        )
    }

    /// 驗證寬度超過閱讀上限、高度僅 440 pt 的容器中，`ScrollView` 內容限寬 640 pt 並在安全區內置中
    ///
    /// - Throws: 測量場景缺失或非同步等待被取消時傳遞錯誤，快照不存在時由 `#require` 丟出
    @Test
    @MainActor
    func blReadableScrollContent_寬容器矮高度_限寬640並置中() async throws {
        // Given
        let containerSize = CGSize(width: 956, height: 440)
        let expectedWidth = Self.literalCandidateTextWidth

        // When
        let snapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: containerSize
        ) {
            Self.scrollSample(isReadable: true)
        }
        let verified = try #require(snapshot, "未能取得矮容器 ScrollView 的量測快照")

        // Then
        let measuredFrame = verified.innerContentFrameInHost
        let safeRect = verified.uiKitSafeRect
        let expectedMinX = safeRect.minX + (safeRect.width - expectedWidth) / 2
        #expect(
            abs(measuredFrame.width - expectedWidth) <= Self.tolerance,
            """
            矮容器 ScrollView 寬度應為 640 pt，實測：\(measuredFrame.width)
            \(verified.diagnosticDescription)
            """
        )
        #expect(
            abs(measuredFrame.minX - expectedMinX) <= Self.tolerance,
            """
            矮容器 ScrollView minX 應為 \(expectedMinX) pt，實測：\(measuredFrame.minX)
            \(verified.diagnosticDescription)
            """
        )
        #expect(
            measuredFrame.width > 0 && measuredFrame.width < safeRect.width,
            "版面穩定後內容寬度不應殘留零寬或安全區寬度，實測寬度：\(measuredFrame.width)\n\(verified.diagnosticDescription)"
        )
    }

    /// 驗證矮容器中內容高度超過容器、可以捲動的 `ScrollView`，內容限寬 640 pt 並在安全區內置中
    ///
    /// - Throws: 測量場景缺失或非同步等待被取消時傳遞錯誤，快照不存在時由 `#require` 丟出
    @Test
    @MainActor
    func blReadableScrollContent_寬容器矮高度內容可捲動_限寬640並置中() async throws {
        // Given
        let containerSize = CGSize(width: 956, height: 440)
        let expectedWidth = Self.literalCandidateTextWidth

        // When
        let snapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: containerSize
        ) {
            Self.tallScrollSample()
        }
        let verified = try #require(snapshot, "未能取得可捲動矮容器 ScrollView 的量測快照")

        // Then
        let measuredFrame = verified.innerContentFrameInHost
        let safeRect = verified.uiKitSafeRect
        let expectedMinX = safeRect.minX + (safeRect.width - expectedWidth) / 2
        #expect(
            abs(measuredFrame.width - expectedWidth) <= Self.tolerance,
            """
            可捲動矮容器 ScrollView 寬度應為 640 pt，實測：\(measuredFrame.width)
            \(verified.diagnosticDescription)
            """
        )
        #expect(
            abs(measuredFrame.minX - expectedMinX) <= Self.tolerance,
            """
            可捲動矮容器 ScrollView minX 應為 \(expectedMinX) pt，實測：\(measuredFrame.minX)
            \(verified.diagnosticDescription)
            """
        )
    }

    /// 驗證矮容器且水平為 `regular`、垂直為 `compact` 時，`ScrollView` 內容限寬 640 pt 並在安全區內置中
    ///
    /// - Throws: 測量場景缺失或非同步等待被取消時傳遞錯誤，快照不存在時由 `#require` 丟出
    @Test
    @MainActor
    func blReadableScrollContent_寬容器矮高度垂直緊湊_限寬640並置中() async throws {
        // Given
        let containerSize = CGSize(width: 956, height: 440)
        let expectedWidth = Self.literalCandidateTextWidth

        // When
        let snapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: containerSize
        ) {
            Self.scrollSample(isReadable: true)
                .environment(\.horizontalSizeClass, .regular)
                .environment(\.verticalSizeClass, .compact)
        }
        let verified = try #require(snapshot, "未能取得矮容器垂直緊湊 ScrollView 的量測快照")

        // Then
        let measuredFrame = verified.innerContentFrameInHost
        let safeRect = verified.uiKitSafeRect
        let expectedMinX = safeRect.minX + (safeRect.width - expectedWidth) / 2
        #expect(
            abs(measuredFrame.width - expectedWidth) <= Self.tolerance,
            """
            垂直緊湊矮容器 ScrollView 寬度應為 640 pt，實測：\(measuredFrame.width)
            \(verified.diagnosticDescription)
            """
        )
        #expect(
            abs(measuredFrame.minX - expectedMinX) <= Self.tolerance,
            """
            垂直緊湊矮容器 ScrollView minX 應為 \(expectedMinX) pt，實測：\(measuredFrame.minX)
            \(verified.diagnosticDescription)
            """
        )
    }

    /// 驗證寬度超過閱讀上限、高度 768 pt 的容器中，`ScrollView` 內容限寬 640 pt 並在安全區內置中，作為矮容器案例的對照
    ///
    /// - Throws: 測量場景缺失或非同步等待被取消時傳遞錯誤，快照不存在時由 `#require` 丟出
    @Test
    @MainActor
    func blReadableScrollContent_寬容器一般高度_限寬640並置中() async throws {
        // Given
        let containerSize = CGSize(width: 956, height: 768)
        let expectedWidth = Self.literalCandidateTextWidth

        // When
        let snapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: containerSize
        ) {
            Self.scrollSample(isReadable: true)
        }
        let verified = try #require(snapshot, "未能取得一般高度 ScrollView 的量測快照")

        // Then
        let measuredFrame = verified.innerContentFrameInHost
        let safeRect = verified.uiKitSafeRect
        let expectedMinX = safeRect.minX + (safeRect.width - expectedWidth) / 2
        #expect(
            abs(measuredFrame.width - expectedWidth) <= Self.tolerance,
            """
            一般高度 ScrollView 寬度應為 640 pt，實測：\(measuredFrame.width)
            \(verified.diagnosticDescription)
            """
        )
        #expect(
            abs(measuredFrame.minX - expectedMinX) <= Self.tolerance,
            """
            一般高度 ScrollView minX 應為 \(expectedMinX) pt，實測：\(measuredFrame.minX)
            \(verified.diagnosticDescription)
            """
        )
    }

    /// 驗證窄容器的 `ScrollView` 沿用系統預設邊距，內容起點與寬度與未套修飾的同一容器相同
    ///
    /// - Throws: 測量場景缺失或非同步等待被取消時傳遞錯誤，快照不存在時由 `#require` 丟出
    @Test
    @MainActor
    func blReadableScrollContent_窄容器_沿用系統預設邊距() async throws {
        // Given
        let containerSize = CGSize(width: 393, height: 852)

        // When
        let baselineSnapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: containerSize
        ) {
            Self.scrollSample(isReadable: false)
        }
        let snapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: containerSize
        ) {
            Self.scrollSample(isReadable: true)
        }
        let baseline = try #require(baselineSnapshot, "未能取得未修飾窄容器 ScrollView 的量測快照")
        let verified = try #require(snapshot, "未能取得套用修飾窄容器 ScrollView 的量測快照")

        // Then
        let baselineFrame = baseline.innerContentFrameInHost
        let measuredFrame = verified.innerContentFrameInHost
        #expect(
            abs(measuredFrame.minX - baselineFrame.minX) <= Self.tolerance,
            """
            窄容器 ScrollView minX 應與未修飾時相同，預期：\(baselineFrame.minX) pt，實測：\(measuredFrame.minX)
            \(verified.diagnosticDescription)
            """
        )
        #expect(
            abs(measuredFrame.width - baselineFrame.width) <= Self.tolerance,
            """
            窄容器 ScrollView 寬度應與未修飾時相同，預期：\(baselineFrame.width) pt，實測：\(measuredFrame.width)
            \(verified.diagnosticDescription)
            """
        )
    }

    /// 驗證非對稱水平安全區下，寬容器的 `ScrollView` 內容限寬 640 pt 後在安全區內置中，安全區只扣一次
    ///
    /// - Throws: 測量場景缺失或非同步等待被取消時傳遞錯誤，快照不存在時由 `#require` 丟出
    @Test
    @MainActor
    func blReadableScrollContent_寬容器非對稱安全區_安全區內置中且只扣一次() async throws {
        // Given
        let containerSize = CGSize(width: 1024, height: 768)
        let leadingInset: CGFloat = 20
        let expectedWidth = Self.literalCandidateTextWidth
        let expectedSafeWidth: CGFloat = 1004
        // 20 + (1004 - 640) / 2
        let expectedMinX: CGFloat = 202

        // When
        let snapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: containerSize,
            additionalSafeAreaInsets: UIEdgeInsets(
                top: 0,
                left: leadingInset,
                bottom: 0,
                right: 0
            )
        ) {
            Self.scrollSample(isReadable: true)
        }
        let verified = try #require(snapshot, "未能取得非對稱安全區的寬容器量測快照")

        // Then
        let measuredFrame = verified.innerContentFrameInHost
        let safeRect = verified.uiKitSafeRect
        let leftGap = measuredFrame.minX - safeRect.minX
        let rightGap = safeRect.maxX - measuredFrame.maxX
        #expect(
            abs(safeRect.width - expectedSafeWidth) <= Self.tolerance,
            """
            前提：UIKit 安全區寬度應為 1004 pt，實測：\(safeRect.width)
            \(verified.diagnosticDescription)
            """
        )
        #expect(
            abs(measuredFrame.width - expectedWidth) <= Self.tolerance,
            """
            非對稱安全區的 ScrollView 寬度應為 640 pt，實測：\(measuredFrame.width)
            \(verified.diagnosticDescription)
            """
        )
        #expect(
            abs(measuredFrame.minX - expectedMinX) <= Self.tolerance,
            """
            非對稱安全區的 ScrollView minX 應為 202 pt，實測：\(measuredFrame.minX)
            \(verified.diagnosticDescription)
            """
        )
        #expect(
            abs(leftGap - rightGap) <= Self.tolerance,
            """
            ScrollView 左右間距應相等，左：\(leftGap) pt，右：\(rightGap) pt
            \(verified.diagnosticDescription)
            """
        )
    }

    /// 驗證寬容器中分組清單 (`List` 搭配 `.insetGrouped` 樣式) 套 `.form` 的列寬比套 `.text` 寬 40 pt，且兩者各自位於閱讀欄內並左右對稱
    ///
    /// - Throws: 測量場景缺失或非同步等待被取消時傳遞錯誤，快照不存在時由 `#require` 丟出
    @Test
    @MainActor
    func blReadableScrollContent_寬容器分組清單_表單上限列寬比文字上限寬40且各自位於閱讀欄內左右對稱() async throws {
        // Given
        let containerSize = CGSize(width: 1024, height: 768)
        let expectedDifference: CGFloat = 40

        // When
        let textSnapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: containerSize
        ) {
            List {
                Section {
                    Self.sampleRow
                }
            }
            .blReadableScrollContent(.text)
            .listStyle(.insetGrouped)
        }
        let formSnapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: containerSize
        ) {
            List {
                Section {
                    Self.sampleRow
                }
            }
            .blReadableScrollContent(.form)
            .listStyle(.insetGrouped)
        }
        let textVerified = try #require(textSnapshot, "未能取得套用 .text 的分組清單量測快照")
        let formVerified = try #require(formSnapshot, "未能取得套用 .form 的分組清單量測快照")

        // Then
        let textFrame = textVerified.innerContentFrameInHost
        let formFrame = formVerified.innerContentFrameInHost
        let textSafeRect = textVerified.uiKitSafeRect
        let formSafeRect = formVerified.uiKitSafeRect
        let textLeftGap = textFrame.minX - textSafeRect.minX
        let textRightGap = textSafeRect.maxX - textFrame.maxX
        let formLeftGap = formFrame.minX - formSafeRect.minX
        let formRightGap = formSafeRect.maxX - formFrame.maxX
        let textColumnMinX = (containerSize.width - Self.literalCandidateTextWidth) / 2
        let textColumnMaxX = (containerSize.width + Self.literalCandidateTextWidth) / 2
        let formColumnMinX = (containerSize.width - Self.literalCandidateFormWidth) / 2
        let formColumnMaxX = (containerSize.width + Self.literalCandidateFormWidth) / 2
        #expect(
            textFrame.width > 0 && formFrame.width > 0,
            """
            分組清單列寬應為正值。文字：\(textFrame.width) pt，表單：\(formFrame.width) pt
            \(textVerified.diagnosticDescription)
            """
        )
        #expect(
            abs((formFrame.width - textFrame.width) - expectedDifference) <= Self.tolerance,
            """
            表單與文字列寬差應為 40 pt，實測：\(formFrame.width - textFrame.width) pt
            \(formVerified.diagnosticDescription)
            """
        )
        #expect(
            abs(textLeftGap - textRightGap) <= Self.tolerance,
            """
            文字上限的分組清單左右間距應相等，左：\(textLeftGap) pt，右：\(textRightGap) pt
            \(textVerified.diagnosticDescription)
            """
        )
        #expect(
            abs(formLeftGap - formRightGap) <= Self.tolerance,
            """
            表單上限的分組清單左右間距應相等，左：\(formLeftGap) pt，右：\(formRightGap) pt
            \(formVerified.diagnosticDescription)
            """
        )
        #expect(
            textFrame.minX >= textColumnMinX && textFrame.maxX <= textColumnMaxX,
            """
            文字上限的分組清單列應位於閱讀欄內，實測：\(textFrame.minX) 至 \(textFrame.maxX) pt
            \(textVerified.diagnosticDescription)
            """
        )
        #expect(
            formFrame.minX >= formColumnMinX && formFrame.maxX <= formColumnMaxX,
            """
            表單上限的分組清單列應位於閱讀欄內，實測：\(formFrame.minX) 至 \(formFrame.maxX) pt
            \(formVerified.diagnosticDescription)
            """
        )
    }

    /// 驗證寬容器中表單套 `.form` 的列寬比套 `.text` 寬 40 pt，且兩者各自位於閱讀欄內並左右對稱
    ///
    /// - Throws: 測量場景缺失或非同步等待被取消時傳遞錯誤，快照不存在時由 `#require` 丟出
    @Test
    @MainActor
    func blReadableScrollContent_寬容器表單_表單上限列寬比文字上限寬40且各自位於閱讀欄內左右對稱() async throws {
        // Given
        let containerSize = CGSize(width: 1024, height: 768)
        let expectedDifference: CGFloat = 40

        // When
        let textSnapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: containerSize
        ) {
            Form {
                Section {
                    Self.sampleRow
                }
            }
            .blReadableScrollContent(.text)
        }
        let formSnapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: containerSize
        ) {
            Form {
                Section {
                    Self.sampleRow
                }
            }
            .blReadableScrollContent(.form)
        }
        let textVerified = try #require(textSnapshot, "未能取得套用 .text 的表單量測快照")
        let formVerified = try #require(formSnapshot, "未能取得套用 .form 的表單量測快照")

        // Then
        let textFrame = textVerified.innerContentFrameInHost
        let formFrame = formVerified.innerContentFrameInHost
        let textSafeRect = textVerified.uiKitSafeRect
        let formSafeRect = formVerified.uiKitSafeRect
        let textLeftGap = textFrame.minX - textSafeRect.minX
        let textRightGap = textSafeRect.maxX - textFrame.maxX
        let formLeftGap = formFrame.minX - formSafeRect.minX
        let formRightGap = formSafeRect.maxX - formFrame.maxX
        let textColumnMinX = (containerSize.width - Self.literalCandidateTextWidth) / 2
        let textColumnMaxX = (containerSize.width + Self.literalCandidateTextWidth) / 2
        let formColumnMinX = (containerSize.width - Self.literalCandidateFormWidth) / 2
        let formColumnMaxX = (containerSize.width + Self.literalCandidateFormWidth) / 2
        #expect(
            textFrame.width > 0 && formFrame.width > 0,
            """
            表單列寬應為正值。文字：\(textFrame.width) pt，表單：\(formFrame.width) pt
            \(textVerified.diagnosticDescription)
            """
        )
        #expect(
            abs((formFrame.width - textFrame.width) - expectedDifference) <= Self.tolerance,
            """
            表單與文字列寬差應為 40 pt，實測：\(formFrame.width - textFrame.width) pt
            \(formVerified.diagnosticDescription)
            """
        )
        #expect(
            abs(textLeftGap - textRightGap) <= Self.tolerance,
            """
            文字上限的表單列左右間距應相等，左：\(textLeftGap) pt，右：\(textRightGap) pt
            \(textVerified.diagnosticDescription)
            """
        )
        #expect(
            abs(formLeftGap - formRightGap) <= Self.tolerance,
            """
            表單上限的表單列左右間距應相等，左：\(formLeftGap) pt，右：\(formRightGap) pt
            \(formVerified.diagnosticDescription)
            """
        )
        #expect(
            textFrame.minX >= textColumnMinX && textFrame.maxX <= textColumnMaxX,
            """
            文字上限的表單列應位於閱讀欄內，實測：\(textFrame.minX) 至 \(textFrame.maxX) pt
            \(textVerified.diagnosticDescription)
            """
        )
        #expect(
            formFrame.minX >= formColumnMinX && formFrame.maxX <= formColumnMaxX,
            """
            表單上限的表單列應位於閱讀欄內，實測：\(formFrame.minX) 至 \(formFrame.maxX) pt
            \(formVerified.diagnosticDescription)
            """
        )
    }
}

// MARK: - Private Method

private extension BLReadableScrollContentLayoutTests {

    /// 撐滿可用寬度的單一量測列，並掛上量測用的錨點
    @MainActor
    static var sampleRow: some View {
        Color.blue
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .anchorContentFrame()
    }

    /// 建立量測用 `ScrollView`，`isReadable` 為真時套用文字閱讀寬度修飾
    ///
    /// - Parameter isReadable: 是否套用 `blReadableScrollContent(.text)`
    /// - Returns: 內含量測列的 `ScrollView` 視圖
    @MainActor
    @ViewBuilder
    static func scrollSample(isReadable: Bool) -> some View {
        if isReadable {
            ScrollView {
                sampleRow
            }
            .blReadableScrollContent(.text)
        } else {
            ScrollView {
                sampleRow
            }
        }
    }

    /// 建立內容高度超過 440 pt 的量測用 `ScrollView`，量測列位於底部，套用文字閱讀寬度修飾
    ///
    /// - Returns: 內容可捲動的 `ScrollView` 視圖
    @MainActor
    static func tallScrollSample() -> some View {
        ScrollView {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: 600)

                sampleRow
            }
        }
        .blReadableScrollContent(.text)
    }
}
