//
//  BLReadableScrollContentLayout.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/29.
//

import SwiftUI

/// 依內容類型偏好限制捲動內容寬度的 `ViewModifier`，窄區沿用系統預設邊距
struct BLReadableScrollContentLayout {

    // MARK: - Properties

    /// 依系統 body 樣式自動縮放之最大寬度
    @ScaledMetric private var maximumWidth: CGFloat

    /// 捲動容器量測寬度，依幾何變化更新
    @State private var availableWidth: CGFloat = 0

    /// 捲動容器量測到的安全區邊距，依幾何變化更新
    @State private var safeAreaInsets = EdgeInsets(
        top: 0,
        leading: 0,
        bottom: 0,
        trailing: 0
    )

    /// 自訂邊距的安全區處理方式
    private let marginMode: MarginMode

    // MARK: - Init

    /// 建立捲動內容閱讀限寬修飾器
    ///
    /// - Parameters:
    ///   - type: 內容類型偏好
    ///   - marginMode: 自訂邊距的安全區處理方式
    init(type: BLReadableContentType, marginMode: MarginMode) {
        self.marginMode = marginMode
        _maximumWidth = ScaledMetric(wrappedValue: type.candidateMaximumWidth, relativeTo: .body)
    }
}

// MARK: - Nested Types

extension BLReadableScrollContentLayout {

    /// 依容器種類決定安全區邊距的處理方式
    enum MarginMode {

        /// ScrollView 的捲動內容邊距疊加在安全區之後
        case scrollView

        /// List 與 Form 的捲動內容邊距從容器邊緣起算
        case safeAreaAware
    }
}

// MARK: - blReadableScrollContent

extension View {

    /// 依內容類型限制捲動容器內容的閱讀寬度
    ///
    /// 窄區沿用系統預設邊距，寬區依容器寬度限寬並在安全區內置中
    ///
    /// - Parameter type: 內容類型偏好，預設為 `.text`
    /// - Returns: 套用閱讀寬度邊距的視圖
    func blReadableScrollContent(_ type: BLReadableContentType = .text) -> some View {
        modifier(
            BLReadableScrollContentLayout(
                type: type,
                marginMode: .scrollView
            )
        )
    }
}

extension List {

    /// 依內容類型限制清單列的閱讀寬度，並在不對稱安全區內置中
    ///
    /// - Parameter type: 內容類型偏好，預設為 `.text`
    /// - Returns: 套用閱讀寬度邊距的清單
    func blReadableScrollContent(_ type: BLReadableContentType = .text) -> some View {
        modifier(
            BLReadableScrollContentLayout(
                type: type,
                marginMode: .safeAreaAware
            )
        )
    }
}

extension Form {

    /// 依內容類型限制表單列的閱讀寬度，並在不對稱安全區內置中
    ///
    /// - Parameter type: 內容類型偏好，預設為 `.text`
    /// - Returns: 套用閱讀寬度邊距的表單
    func blReadableScrollContent(_ type: BLReadableContentType = .text) -> some View {
        modifier(
            BLReadableScrollContentLayout(
                type: type,
                marginMode: .safeAreaAware
            )
        )
    }
}

// MARK: - ViewModifier

extension BLReadableScrollContentLayout: ViewModifier {

    /// 量測捲動容器寬度與安全區，超出上限的部分以水平內容邊距補上
    ///
    /// - Parameter content: 被修飾之捲動容器
    /// - Returns: 套用閱讀寬度邊距後之視圖
    /// - Note: `ScrollView` 的邊距疊加在安全區之上；`List` 與 `Form` 的左右值
    ///   另納入幾何安全區
    func body(content: Content) -> some View {
        contentWithMargins(content)
            .onGeometryChange(for: CGFloat.self) {
                $0.size.width
            } action: {
                availableWidth = $0
            }
            .onGeometryChange(for: EdgeInsets.self) {
                $0.safeAreaInsets
            } action: {
                safeAreaInsets = $0
            }
    }
}

// MARK: - Private Method

private extension BLReadableScrollContentLayout {

    /// 超出閱讀上限後需要套用的水平邊距
    var horizontalMargin: CGFloat? {
        BLReadableContentLayout.scrollContentHorizontalMargin(
            containerWidth: availableWidth,
            maximumWidth: maximumWidth
        )
    }

    /// 依容器的安全區計算左右邊距並套用到捲動內容
    ///
    /// - Parameter content: 被修飾的捲動容器
    /// - Returns: 套用閱讀寬度邊距的捲動容器
    @ViewBuilder
    func contentWithMargins(_ content: Content) -> some View {
        switch marginMode {
        case .scrollView:
            content.contentMargins(.horizontal, horizontalMargin, for: .scrollContent)

        case .safeAreaAware:
            contentWithSafeAreaAwareMargins(content)
        }
    }

    /// 依容器寬度與安全區算出左右邊距，套用到 List 與 Form
    ///
    /// - Parameter content: 被修飾的捲動容器
    /// - Returns: 套用左右安全區與閱讀邊距的捲動容器
    func contentWithSafeAreaAwareMargins(_ content: Content) -> some View {
        let margins = BLReadableContentLayout.scrollContentEdgeMargins(
            containerWidth: availableWidth,
            maximumWidth: maximumWidth,
            leadingSafeAreaInset: safeAreaInsets.leading,
            trailingSafeAreaInset: safeAreaInsets.trailing
        )

        return content
            .contentMargins(.leading, margins.leading, for: .scrollContent)
            .contentMargins(.trailing, margins.trailing, for: .scrollContent)
    }
}

// MARK: - Preview

#Preview("捲動內容閱讀寬度") {
    ScrollView {
        Text("這是一段套用捲動內容閱讀寬度的長段落示範文字，寬區時內容自動限寬並置中。")
            .padding(BLSpacing.medium)
            .blTextStyle(.body)
            .background(.blSurface)
    }
    .blReadableScrollContent(.text)
    .frame(width: 800, height: 400)
    .background(.blBackground)
}
