//
//  BLReadableContentLayoutTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/27.
//

import SwiftUI
import Testing
import UIKit

@testable import BuyLedger

/// `BLReadableContentLayout` 的單元測試，涵蓋渲染測試畫面校準、共用閱讀限寬、窄區填滿、長文字參照值比對與大字級寬度退讓、以及非對稱安全區
///
/// - Note: 本測試套件中所有預期數值均使用獨立指定的候選字面值 (文字 640 pt、表單 680 pt、圖表 840 pt、邊距 16 pt)，
///   此為可驗證的設計假設參數，非使用者明定，亦非固定驗收硬規則；待實機測量確認或修正
struct BLReadableContentLayoutTests {

    // MARK: - Properties

    /// 文字內容候選最大閱讀寬度字面值 (單位：pt)
    private static let literalCandidateTextWidth: CGFloat = 640

    /// 表單內容候選最大閱讀寬度字面值 (單位：pt)
    private static let literalCandidateFormWidth: CGFloat = 680

    /// 圖表內容候選最大閱讀寬度字面值 (單位：pt)
    private static let literalCandidateChartWidth: CGFloat = 840

    /// 兩側標準設計邊距字面值 (單位：pt)
    private static let literalDefaultMargin: CGFloat = 16

    /// 浮點數佈局測量容許誤差 (單位：pt)
    private static let tolerance: CGFloat = 1.0

    /// 測試用真實繁體中文長文字，涵蓋一般備註與公告情境
    private static let sampleLongCJKText =
        "本批日本代購訂單已全數完成採購與抵台清點，預計於週五前依序完成國內配送；如有指定收件時段或需合併寄送，請於出貨前主動聯繫客服人員。"

    /// 測試用真實英文長文字，涵蓋長詞彙折行情境
    private static let sampleLongEnglishText =
        "All items for this procurement batch have been inspected and confirmed in warehouse. Domestic deliveries will proceed according to the scheduled timeframe."

    /// 驗證無修飾之標準容器中，`hostBounds`、真實根幾何尺寸 (吻合 UIKit 實測 `safeRect.size`) 與座標原點精確對齊
    ///
    /// - Throws: 測量場景缺失或非同步等待被取消時傳遞錯誤，快照不存在時由 `#require` 丟出
    @Test
    @MainActor
    func blReadableContent_無修飾標準容器_校準宿主範圍與座標原點() async throws {
        // Given
        let containerSize = CGSize(width: 1024, height: 768)

        // When
        let snapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: containerSize
        ) {
            Color.clear
                .frame(width: 100, height: 100)
                .anchorContentFrame()
        }
        let verified = try #require(snapshot, "未能取得校準快照")

        // Then
        #expect(
            verified.hostBounds == CGRect(origin: .zero, size: containerSize),
            "Host bounds 應為 \(containerSize)，實測：\(verified.hostBounds)\n\(verified.diagnosticDescription)"
        )
        #expect(
            abs(verified.rootSize.width - verified.uiKitSafeRect.width) <= Self.tolerance,
            "根層幾何寬度應吻合獨立 UIKit safeRect 寬度 \(verified.uiKitSafeRect.width) pt，實測：\(verified.rootSize.width)"
        )
        #expect(
            abs(verified.rootSize.height - verified.uiKitSafeRect.height) <= Self.tolerance,
            "根層幾何高度應吻合獨立 UIKit safeRect 高度 \(verified.uiKitSafeRect.height) pt，實測：\(verified.rootSize.height)"
        )
        #expect(
            verified.innerContentFrame.origin == .zero,
            "Anchor 座標原點應對齊具名根座標空間之 raw (0, 0)，實測：\(verified.innerContentFrame.origin)"
        )
        #expect(
            abs(verified.innerContentFrameInHost.origin.x - verified.uiKitSafeRect.origin.x)
                <= Self.tolerance,
            "轉換至 host 座標系之 x 原點應吻合 UIKit safeRect 原點 \(verified.uiKitSafeRect.origin.x) pt，實測：\(verified.innerContentFrameInHost.origin.x)"
        )
        #expect(
            abs(verified.innerContentFrameInHost.origin.y - verified.uiKitSafeRect.origin.y)
                <= Self.tolerance,
            "轉換至 host 座標系之 y 原點應吻合 UIKit safeRect 原點 \(verified.uiKitSafeRect.origin.y) pt，實測：\(verified.innerContentFrameInHost.origin.y)"
        )
    }

    /// 驗證窄版非對稱安全區下，UIKit 與 SwiftUI 均正確套用 left = 20 pt 之有效安全區邊距，有效安全寬度 (355 pt) 精確吻合
    ///
    /// - Throws: 測量場景缺失或非同步等待被取消時傳遞錯誤，快照不存在時由 `#require` 丟出
    @Test
    @MainActor
    func blReadableContent_窄版非對稱安全區_校準UIKit與SwiftUI有效安全區邊距() async throws {
        // Given
        let containerSize = CGSize(width: 375, height: 667)
        let leadingInset: CGFloat = 20
        let expectedSafeWidth: CGFloat = 355

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
            Color.clear
                .frame(width: 50, height: 50)
                .anchorContentFrame()
        }
        let verified = try #require(snapshot, "未能取得非對稱安全區校準快照")

        // Then
        #expect(
            verified.uiKitSafeAreaInsets.left >= leadingInset,
            "UIKit 有效安全區 left 應至少包含 \(leadingInset) pt，實測：\(verified.uiKitSafeAreaInsets.left)\n\(verified.diagnosticDescription)"
        )
        #expect(
            abs(verified.uiKitSafeRect.width - expectedSafeWidth) <= Self.tolerance,
            "UIKit 實測 safeRect 寬度應為 \(expectedSafeWidth) pt，實測：\(verified.uiKitSafeRect.width)"
        )
        #expect(
            abs(verified.rootSize.width - expectedSafeWidth) <= Self.tolerance,
            "SwiftUI 根層幾何寬度應為 \(expectedSafeWidth) pt，實測：\(verified.rootSize.width)"
        )
        #expect(
            verified.innerContentFrame.origin == .zero,
            "未修飾基準區塊 raw 原點應為 (0, 0)，實測：\(verified.innerContentFrame.origin)"
        )
        #expect(
            abs(verified.innerContentFrameInHost.origin.x - verified.uiKitSafeRect.origin.x)
                <= Self.tolerance,
            "基準區塊轉換至 host 座標系之 x 原點應吻合 UIKit safeRect 原點 \(verified.uiKitSafeRect.origin.x) pt (包含 left 20pt 避讓)，實測：\(verified.innerContentFrameInHost.origin.x)"
        )
    }

    /// 驗證寬版非對稱安全區下，UIKit 與 SwiftUI 均正確套用 left = 200 pt 之側邊欄保留安全區邊距，有效安全寬度 (824 pt) 精確吻合
    ///
    /// - Throws: 測量場景缺失或非同步等待被取消時傳遞錯誤，快照不存在時由 `#require` 丟出
    @Test
    @MainActor
    func blReadableContent_寬版非對稱安全區_校準側邊欄200安全區() async throws {
        // Given
        let containerSize = CGSize(width: 1024, height: 768)
        let sidebarInset: CGFloat = 200
        let expectedSafeWidth: CGFloat = 824

        // When
        let snapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: containerSize,
            additionalSafeAreaInsets: UIEdgeInsets(
                top: 0,
                left: sidebarInset,
                bottom: 0,
                right: 0
            )
        ) {
            Color.clear
                .frame(width: 50, height: 50)
                .anchorContentFrame()
        }
        let verified = try #require(snapshot, "未能取得寬版非對稱安全區校準快照")

        // Then
        #expect(
            verified.uiKitSafeAreaInsets.left >= sidebarInset,
            "UIKit 有效安全區 left 應至少包含 \(sidebarInset) pt，實測：\(verified.uiKitSafeAreaInsets.left)\n\(verified.diagnosticDescription)"
        )
        #expect(
            abs(verified.uiKitSafeRect.width - expectedSafeWidth) <= Self.tolerance,
            "UIKit 實測 safeRect 寬度應為 \(expectedSafeWidth) pt，實測：\(verified.uiKitSafeRect.width)"
        )
        #expect(
            abs(verified.rootSize.width - expectedSafeWidth) <= Self.tolerance,
            "SwiftUI 根層幾何寬度應為 \(expectedSafeWidth) pt，實測：\(verified.rootSize.width)"
        )
        #expect(
            verified.innerContentFrame.origin == .zero,
            "未修飾基準區塊 raw 原點應為 (0, 0)，實測：\(verified.innerContentFrame.origin)"
        )
        #expect(
            abs(verified.innerContentFrameInHost.origin.x - verified.uiKitSafeRect.origin.x)
                <= Self.tolerance,
            "基準區塊轉換至 host 座標系之 x 原點應吻合 UIKit safeRect 原點 \(verified.uiKitSafeRect.origin.x) pt (包含 left 200pt 側邊欄)，實測：\(verified.innerContentFrameInHost.origin.x)"
        )
    }

    /// 驗證工廠方法未指定類型參數時預設等同文字偏好 (640 pt 限寬) 並於寬容器中水平置中
    ///
    /// - Throws: 測量場景缺失或非同步等待被取消時傳遞錯誤，快照不存在時由 `#require` 丟出
    @Test
    @MainActor
    func blReadableContent_工廠方法預設參數_未指定類型時等同文字偏好640限寬() async throws {
        // Given
        let containerSize = CGSize(width: 1024, height: 768)
        let expectedWidth = Self.literalCandidateTextWidth
        let expectedMinX = (containerSize.width - expectedWidth) / 2
        let expectedMaxX = expectedMinX + expectedWidth

        // When
        // 呼叫無參數之 `.blReadableContent()`
        let snapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: containerSize
        ) {
            Color.blue
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .anchorContentFrame()
                .blReadableContent()
        }
        let measuredFrame = try #require(snapshot?.innerContentFrame, "未能測量到預設工廠修飾視圖 frame")

        // Then
        // 驗證寬度與位置精確吻合 `.text` 預設值
        #expect(
            abs(measuredFrame.width - expectedWidth) <= Self.tolerance,
            "未指定類型時預設寬度應為 640 pt，實測寬度：\(measuredFrame.width)"
        )
        #expect(
            abs(measuredFrame.minX - expectedMinX) <= Self.tolerance,
            "未指定類型時預設 minX 應為 192 pt，實測 minX：\(measuredFrame.minX)"
        )
        #expect(
            abs(measuredFrame.maxX - expectedMaxX) <= Self.tolerance,
            "未指定類型時預設 maxX 應為 832 pt，實測 maxX：\(measuredFrame.maxX)"
        )
    }

    /// 驗證寬容器中渲染之文字內容限寬於 640 pt 且在安全區域水平置中 (雙邊界斷言)
    ///
    /// - Throws: 測量場景缺失或非同步等待被取消時傳遞錯誤，快照不存在時由 `#require` 丟出
    /// - Note: 若在 1024 pt 容器中未限寬，單行文字超過 80 字元，讀者折行視線跳躍將導致閱讀疲勞
    @Test
    @MainActor
    func blReadableContent_寬容器文字內容_限制在候選寬度640並置中() async throws {
        // Given
        let containerSize = CGSize(width: 1024, height: 768)
        let expectedWidth: CGFloat = Self.literalCandidateTextWidth
        let expectedMinX: CGFloat = (containerSize.width - expectedWidth) / 2
        let expectedMaxX: CGFloat = expectedMinX + expectedWidth

        // When
        let snapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: containerSize
        ) {
            Color.blue
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .anchorContentFrame()
                .blReadableContent(.text)
        }
        let measuredFrame = try #require(snapshot?.innerContentFrame, "未能測量到寬容器中的視圖 frame")

        // Then
        #expect(
            abs(measuredFrame.width - expectedWidth) <= Self.tolerance,
            "寬容器中文字內容寬度應為 640 pt (±1 pt)，實測寬度：\(measuredFrame.width)"
        )
        #expect(
            abs(measuredFrame.minX - expectedMinX) <= Self.tolerance,
            "寬容器中文字內容應水平置中，預期 minX 為 \(expectedMinX) pt，實測 minX：\(measuredFrame.minX)"
        )
        #expect(
            abs(measuredFrame.maxX - expectedMaxX) <= Self.tolerance,
            "寬容器中文字內容右界應為 \(expectedMaxX) pt，實測 maxX：\(measuredFrame.maxX)"
        )
    }

    /// 驗證寬容器中表單依類型限寬於 680 pt 並水平置中
    ///
    /// - Throws: 測量場景缺失或非同步等待被取消時傳遞錯誤，快照不存在時由 `#require` 丟出
    @Test
    @MainActor
    func blReadableContent_寬容器表單_依類型限寬680並置中() async throws {
        // Given
        let containerSize = CGSize(width: 1024, height: 768)
        let expectedFormWidth: CGFloat = Self.literalCandidateFormWidth
        let expectedFormMinX: CGFloat = (containerSize.width - expectedFormWidth) / 2

        // When
        let formSnapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: containerSize
        ) {
            HStack {
                Text("客戶名稱")
                TextField("請輸入客戶姓名", text: .constant("示範客戶"))
            }
            .frame(maxWidth: .infinity)
            .anchorContentFrame()
            .blReadableContent(.form)
        }
        let measuredFormFrame = try #require(formSnapshot?.innerContentFrame, "未能測量到表單視圖 frame")

        // Then
        #expect(
            abs(measuredFormFrame.width - expectedFormWidth) <= Self.tolerance,
            "表單內容寬度應為 680 pt，實測寬度：\(measuredFormFrame.width)"
        )
        #expect(
            abs(measuredFormFrame.minX - expectedFormMinX) <= Self.tolerance,
            "表單內容應水平置中，預期 minX 為 \(expectedFormMinX) pt，實測 minX：\(measuredFormFrame.minX)"
        )
    }

    /// 驗證寬容器中圖表依類型限寬於 840 pt 並水平置中，且寬度大於表單限寬 680 pt
    ///
    /// - Throws: 測量場景缺失或非同步等待被取消時傳遞錯誤，快照不存在時由 `#require` 丟出
    /// - Note: 本測試僅量測圖表類型之候選最大寬度參數 (840 pt)，不宣稱真實圖表軸標籤重疊或可讀性已驗證；
    ///   代表性 Chart 標籤與資料可及性留待後續功能遷移與實機測量
    @Test
    @MainActor
    func blReadableContent_寬容器圖表_依類型限寬840並寬於表單() async throws {
        // Given
        let containerSize = CGSize(width: 1024, height: 768)
        let expectedChartWidth: CGFloat = Self.literalCandidateChartWidth
        let expectedChartMinX: CGFloat = (containerSize.width - expectedChartWidth) / 2

        // When
        let chartSnapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: containerSize
        ) {
            Color.green
                .frame(maxWidth: .infinity, maxHeight: 300)
                .anchorContentFrame()
                .blReadableContent(.chart)
        }
        let measuredChartFrame = try #require(chartSnapshot?.innerContentFrame, "未能測量到圖表視圖 frame")

        // Then
        #expect(
            abs(measuredChartFrame.width - expectedChartWidth) <= Self.tolerance,
            "圖表內容寬度應為 840 pt，實測寬度：\(measuredChartFrame.width)"
        )
        #expect(
            abs(measuredChartFrame.minX - expectedChartMinX) <= Self.tolerance,
            "圖表內容應水平置中，預期 minX 為 \(expectedChartMinX) pt，實測 minX：\(measuredChartFrame.minX)"
        )
        #expect(measuredChartFrame.width > Self.literalCandidateFormWidth, "圖表寬度應大於表單寬度以容納多月份軸標籤")
    }

    /// 驗證窄容器扣除兩側 16 pt 設計邊距後填滿 (寬度 343 pt)，起始於 16 pt、結束於 359 pt
    ///
    /// - Throws: 測量場景缺失或非同步等待被取消時傳遞錯誤，快照不存在時由 `#require` 丟出
    /// - Note: 窄容器若強加 640 pt 等寬度上限或過大 `padding`，將造成內容溢出或浪費緊湊空間
    @Test
    @MainActor
    func blReadableContent_窄容器_扣除設計邊距填滿可用寬度343() async throws {
        // Given
        let containerSize = CGSize(width: 375, height: 667)
        let expectedMinX = Self.literalDefaultMargin
        let expectedWidth = containerSize.width - (expectedMinX * 2)
        let expectedMaxX = expectedMinX + expectedWidth

        // When
        let snapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: containerSize
        ) {
            Color.blue
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .anchorContentFrame()
                .blReadableContent(.text)
        }
        let measuredFrame = try #require(snapshot?.innerContentFrame, "未能測量到窄容器中的視圖 frame")

        // Then
        #expect(
            abs(measuredFrame.minX - expectedMinX) <= Self.tolerance,
            "窄容器內容起始位置應為 16 pt，實測 minX：\(measuredFrame.minX)"
        )
        #expect(
            abs(measuredFrame.width - expectedWidth) <= Self.tolerance,
            "窄容器內容應填滿扣除兩側邊距後之 343 pt，實測寬度：\(measuredFrame.width)"
        )
        #expect(
            abs(measuredFrame.maxX - expectedMaxX) <= Self.tolerance,
            "窄容器內容結束位置應為 359 pt，實測 maxX：\(measuredFrame.maxX)"
        )
    }

    /// 驗證長繁中文字在寬容器中限寬於 640 pt，高度與未修飾 640 寬之自然排版參照值相符，且能反證抓出單行截斷
    ///
    /// - Throws: 測量場景缺失或非同步等待被取消時傳遞錯誤，快照不存在時由 `#require` 丟出
    @Test
    @MainActor
    func blReadableContent_長繁中文字_高度與未修飾640自然排版參照值相符且拒絕單行截斷() async throws {
        // Given
        // 獨立參照量測 (在 640 寬的向下自然延伸捲動區域中量測未修飾文字)
        let oracleSnapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: CGSize(width: Self.literalCandidateTextWidth, height: 2000)
        ) {
            ScrollView {
                Text(Self.sampleLongCJKText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .anchorContentFrame()
            }
        }
        let naturalOracleHeight = try #require(
            oracleSnapshot?.innerContentFrame.height,
            "未能測量到繁中文字自然排版參照值高度"
        )

        // 反向對照：單行截斷 (證明參照值具備多行，非單行截斷)
        let singleLineSnapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: CGSize(width: Self.literalCandidateTextWidth, height: 2000)
        ) {
            ScrollView {
                Text(Self.sampleLongCJKText)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .anchorContentFrame()
            }
        }
        let singleLineHeight = try #require(
            singleLineSnapshot?.innerContentFrame.height,
            "未能測量到單行截斷高度"
        )
        try #require(
            naturalOracleHeight > singleLineHeight + 10,
            "自然排版多行高度應顯著大於單行截斷高度，自然高度：\(naturalOracleHeight)，單行高度：\(singleLineHeight)"
        )

        // When
        // 受測對象在 1024 寬容器中套用 `.blReadableContent(.text)`
        let subjectSnapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: CGSize(width: 1024, height: 2000)
        ) {
            ScrollView {
                Text(Self.sampleLongCJKText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .anchorContentFrame()
                    .blReadableContent(.text)
            }
        }
        let subjectFrame = try #require(subjectSnapshot?.innerContentFrame, "未能測量到受測繁中文字 frame")

        // Then
        #expect(
            abs(subjectFrame.width - Self.literalCandidateTextWidth) <= Self.tolerance,
            "受測繁中文字寬度應為 640 pt，實測：\(subjectFrame.width)"
        )
        #expect(
            abs(subjectFrame.height - naturalOracleHeight) <= Self.tolerance,
            "受測繁中文字高度應與自然排版參照值相符 (\(naturalOracleHeight) pt)，實測：\(subjectFrame.height)"
        )
    }

    /// 驗證長英文文字在寬容器中限寬於 640 pt，高度與未修飾 640 寬之自然排版參照值相符，且能反證抓出單行截斷
    ///
    /// - Throws: 測量場景缺失或非同步等待被取消時傳遞錯誤，快照不存在時由 `#require` 丟出
    @Test
    @MainActor
    func blReadableContent_長英文文字_高度與未修飾640自然排版參照值相符且拒絕單行截斷() async throws {
        // Given
        // 獨立參照量測
        let oracleSnapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: CGSize(width: Self.literalCandidateTextWidth, height: 2000)
        ) {
            ScrollView {
                Text(Self.sampleLongEnglishText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .anchorContentFrame()
            }
        }
        let naturalOracleHeight = try #require(
            oracleSnapshot?.innerContentFrame.height,
            "未能測量到英文文字自然排版參照值高度"
        )

        // 反向對照：單行截斷
        let singleLineSnapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: CGSize(width: Self.literalCandidateTextWidth, height: 2000)
        ) {
            ScrollView {
                Text(Self.sampleLongEnglishText)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .anchorContentFrame()
            }
        }
        let singleLineHeight = try #require(
            singleLineSnapshot?.innerContentFrame.height,
            "未能測量到單行截斷高度"
        )
        try #require(
            naturalOracleHeight > singleLineHeight + 10,
            "自然排版多行高度應顯著大於單行截斷高度，自然高度：\(naturalOracleHeight)，單行高度：\(singleLineHeight)"
        )

        // When
        // 受測對象在 1024 寬容器中套用 `.blReadableContent(.text)`
        let subjectSnapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: CGSize(width: 1024, height: 2000)
        ) {
            ScrollView {
                Text(Self.sampleLongEnglishText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .anchorContentFrame()
                    .blReadableContent(.text)
            }
        }
        let subjectFrame = try #require(subjectSnapshot?.innerContentFrame, "未能測量到受測英文文字 frame")

        // Then
        #expect(
            abs(subjectFrame.width - Self.literalCandidateTextWidth) <= Self.tolerance,
            "受測英文文字寬度應為 640 pt，實測：\(subjectFrame.width)"
        )
        #expect(
            abs(subjectFrame.height - naturalOracleHeight) <= Self.tolerance,
            "受測英文文字高度應與自然排版參照值相符 (\(naturalOracleHeight) pt)，實測：\(subjectFrame.height)"
        )
    }

    /// 驗證大字級基準 (`.large`) 下，寬容器中的文字內容限寬於 640 pt
    ///
    /// - Throws: 測量場景缺失或非同步等待被取消時傳遞錯誤，快照不存在時由 `#require` 丟出
    @Test
    @MainActor
    func blReadableContent_大字級基準_文字限寬於640() async throws {
        // Given
        // 1024 寬容器
        let containerSize = CGSize(width: 1024, height: 768)

        // When
        // 量測 `.large` 基準下的彈性區域寬度
        let largeBaselineSnapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: containerSize,
            dynamicTypeSize: .large
        ) {
            Text(Self.sampleLongCJKText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .anchorContentFrame()
                .blReadableContent(.text)
        }
        let largeFrame = try #require(
            largeBaselineSnapshot?.innerContentFrame,
            "未能測量到 large 基準視圖 frame"
        )

        // Then
        #expect(
            abs(largeFrame.width - Self.literalCandidateTextWidth) <= Self.tolerance,
            "大字級基準下的文字寬度應為 640 pt，實測：\(largeFrame.width)"
        )
    }

    /// 驗證超大字級 (AX5) 在寬區具備空間時，閱讀寬度自適應退讓放寬至大於正常字級基準且不超出安全邊距
    ///
    /// - Throws: 測量場景缺失或非同步等待被取消時傳遞錯誤，快照不存在時由 `#require` 丟出
    /// - Note: 規格要求閱讀限寬須隨文字大小調整，且不得截斷資訊或阻擋輸入
    @Test
    @MainActor
    func blReadableContent_大字級_寬區具備空間時放寬至大於640且不超出安全邊距() async throws {
        // Given
        // 1024 寬容器
        let containerSize = CGSize(width: 1024, height: 768)
        let maxSafeWidth = containerSize.width - (Self.literalDefaultMargin * 2)

        // When
        // 在同一測試畫面與容器下量測無障礙最大字級 (AX5) 之彈性區域
        let ax5Snapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: containerSize,
            dynamicTypeSize: .accessibility5
        ) {
            Text(Self.sampleLongCJKText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .anchorContentFrame()
                .blReadableContent(.text)
        }
        let ax5Frame = try #require(ax5Snapshot?.innerContentFrame, "未能測量到大字級文字 frame")

        // Then
        // 證明無障礙最大字級 (AX5) 寬度確實大於 `.large` 基準 (無法被固定 700 假通過)，且不超過 1024 扣兩側邊距的可用寬度，`minX` >= 16
        #expect(
            ax5Frame.width > Self.literalCandidateTextWidth,
            "AX5 大字級閱讀寬度 (\(ax5Frame.width) pt) 應大於正常字級基準 (\(Self.literalCandidateTextWidth) pt)"
        )
        #expect(
            ax5Frame.width <= maxSafeWidth,
            "大字級退讓寬度不得超出可用安全區域邊距 (\(maxSafeWidth) pt)，實測寬度：\(ax5Frame.width)"
        )
        #expect(
            ax5Frame.minX >= Self.literalDefaultMargin,
            "大字級退讓後起始位置仍須保留正常設計邊距 (>= 16 pt)，實測 minX：\(ax5Frame.minX)"
        )
    }

    /// 驗證窄容器在非對稱安全區下 (left 20 pt)，內容正確起始於 36 pt、寬度為 323 pt、結束於 359 pt
    ///
    /// - Throws: 測量場景缺失或非同步等待被取消時傳遞錯誤，快照不存在時由 `#require` 丟出
    /// - Note: 若重複扣除安全區，內容 `minX` 會膨脹為 56 pt，浪費珍貴可用寬度
    @Test
    @MainActor
    func blReadableContent_窄版非對稱安全區_正確避讓不重複累加邊距() async throws {
        // Given
        let containerSize = CGSize(width: 375, height: 667)
        let systemLeadingInset: CGFloat = 20
        let expectedMinX = systemLeadingInset + Self.literalDefaultMargin
        let expectedWidth = containerSize.width - systemLeadingInset
            - (Self.literalDefaultMargin * 2)
        let expectedMaxX = containerSize.width - Self.literalDefaultMargin

        // When
        let snapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: containerSize,
            additionalSafeAreaInsets: UIEdgeInsets(
                top: 0,
                left: systemLeadingInset,
                bottom: 0,
                right: 0
            )
        ) {
            Color.blue
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .anchorContentFrame()
                .blReadableContent(.text)
        }
        let measuredFrame = try #require(
            snapshot?.innerContentFrameInHost,
            "未能測量到窄版非對稱安全區中的視圖 host frame"
        )

        // Then
        #expect(
            abs(measuredFrame.minX - expectedMinX) <= Self.tolerance,
            "內容起始應為 left 20 + 邊距 16 = 36 pt，實測 minX：\(measuredFrame.minX)"
        )
        #expect(
            abs(measuredFrame.width - expectedWidth) <= Self.tolerance,
            "內容寬度應為 355 安全寬度扣除兩側邊距 32 = 323 pt，實測寬度：\(measuredFrame.width)"
        )
        #expect(
            abs(measuredFrame.maxX - expectedMaxX) <= Self.tolerance,
            "無右側安全區時結束位置應為 359 pt，實測 maxX：\(measuredFrame.maxX)"
        )
    }

    /// 驗證寬容器在非對稱安全區下 (左側預留 200 pt 側邊欄)，內容在安全區域 (200..1024) 內置中，而非物理螢幕中央
    ///
    /// - Throws: 測量場景缺失或非同步等待被取消時傳遞錯誤，快照不存在時由 `#require` 丟出
    /// - Note: 若以物理螢幕中央置中 (192 pt)，內容將侵入左側 200 pt 保留區造成遮擋
    @Test
    @MainActor
    func blReadableContent_寬版非對稱安全區_在可用安全區域內置中而非物理中央() async throws {
        // Given
        let containerSize = CGSize(width: 1024, height: 768)
        let sidebarReservedWidth: CGFloat = 200
        let availableSafeWidth = containerSize.width - sidebarReservedWidth
        let expectedWidth = Self.literalCandidateTextWidth
        // 在 824 pt 安全區內置中：200 + (824 - 640) / 2 = 292 pt
        let expectedMinX = sidebarReservedWidth + (availableSafeWidth - expectedWidth) / 2
        let expectedMaxX = expectedMinX + expectedWidth

        // When
        let snapshot = try await ViewLayoutMeasurementSupport.measureLayout(
            containerSize: containerSize,
            additionalSafeAreaInsets: UIEdgeInsets(
                top: 0,
                left: sidebarReservedWidth,
                bottom: 0,
                right: 0
            )
        ) {
            Color.blue
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .anchorContentFrame()
                .blReadableContent(.text)
        }
        let measuredFrame = try #require(
            snapshot?.innerContentFrameInHost,
            "未能測量到寬版非對稱安全區中的視圖 host frame"
        )

        // Then
        #expect(
            abs(measuredFrame.width - expectedWidth) <= Self.tolerance,
            "寬版非對稱區域內容寬度應為 640 pt，實測寬度：\(measuredFrame.width)"
        )
        #expect(
            abs(measuredFrame.minX - expectedMinX) <= Self.tolerance,
            "內容應在安全區 (200..1024) 內水平置中，預期 minX 為 292 pt (非物理中央 192 pt)，實測 minX：\(measuredFrame.minX)"
        )
        #expect(
            abs(measuredFrame.maxX - expectedMaxX) <= Self.tolerance,
            "預期 maxX 為 932 pt，實測 maxX：\(measuredFrame.maxX)"
        )
    }

    /// 驗證容器寬度小於內容上限時不套用額外水平邊距，沿用系統預設
    @Test
    func scrollContentHorizontalMargin_容器寬度小於上限_回傳nil() {
        // Given
        let containerWidth: CGFloat = 600
        let maximumWidth: CGFloat = 640

        // When
        let margin = BLReadableContentLayout.scrollContentHorizontalMargin(
            containerWidth: containerWidth,
            maximumWidth: maximumWidth
        )

        // Then
        #expect(margin == nil)
    }

    /// 驗證容器寬度等於內容上限時不套用額外水平邊距，沿用系統預設
    @Test
    func scrollContentHorizontalMargin_容器寬度等於上限_回傳nil() {
        // Given
        let containerWidth: CGFloat = 640
        let maximumWidth: CGFloat = 640

        // When
        let margin = BLReadableContentLayout.scrollContentHorizontalMargin(
            containerWidth: containerWidth,
            maximumWidth: maximumWidth
        )

        // Then
        #expect(margin == nil)
    }

    /// 驗證容器寬度大於內容上限時，兩側水平邊距各為超出部分的一半，使內容限制在上限寬度
    @Test
    func scrollContentHorizontalMargin_容器寬度大於上限_回傳超出部分的一半() {
        // Given
        let containerWidth: CGFloat = 1024
        let maximumWidth: CGFloat = 640

        // When
        let margin = BLReadableContentLayout.scrollContentHorizontalMargin(
            containerWidth: containerWidth,
            maximumWidth: maximumWidth
        )

        // Then
        #expect(margin == 192)
    }

    /// 驗證字級放大後的內容上限超過容器寬度時不套用額外水平邊距，窄區填滿可用寬度
    @Test
    func scrollContentHorizontalMargin_字級放大後上限超過容器_回傳nil() {
        // Given
        let containerWidth: CGFloat = 700
        let maximumWidth: CGFloat = 960

        // When
        let margin = BLReadableContentLayout.scrollContentHorizontalMargin(
            containerWidth: containerWidth,
            maximumWidth: maximumWidth
        )

        // Then
        #expect(margin == nil)
    }
}
