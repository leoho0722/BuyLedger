//
//  BLReadableContentLayout.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/27.
//

import SwiftUI

/// 依內容類型偏好在局部可用區域內限制內容寬度，並依 DynamicType 自動縮放退讓的 `ViewModifier`
struct BLReadableContentLayout {

    // MARK: - Properties

    /// 依系統 body 樣式自動縮放之最大寬度
    @ScaledMetric private var maximumWidth: CGFloat

    /// 內容類型偏好
    private let type: BLReadableContentType

    // MARK: - Init

    /// 建立閱讀限寬佈局修飾器
    ///
    /// - Parameter type: 內容類型偏好
    init(type: BLReadableContentType) {
        self.type = type
        _maximumWidth = ScaledMetric(wrappedValue: type.candidateMaximumWidth, relativeTo: .body)
    }
}

// MARK: - Internal Method

extension BLReadableContentLayout {

    /// 計算 List 與 Form 需套用的左右安全區與閱讀邊距
    ///
    /// - Parameters:
    ///   - containerWidth: 捲動容器量測寬度
    ///   - maximumWidth: 閱讀內容寬度上限
    ///   - leadingSafeAreaInset: 左側安全區寬度
    ///   - trailingSafeAreaInset: 右側安全區寬度
    /// - Returns: 左右邊距；容器寬度不超過上限時兩者皆為 `nil`
    static func scrollContentEdgeMargins(
        containerWidth: CGFloat,
        maximumWidth: CGFloat,
        leadingSafeAreaInset: CGFloat,
        trailingSafeAreaInset: CGFloat
    ) -> (leading: CGFloat?, trailing: CGFloat?) {
        guard let horizontalMargin = scrollContentHorizontalMargin(
            containerWidth: containerWidth,
            maximumWidth: maximumWidth
        ) else {
            return (nil, nil)
        }

        return (leadingSafeAreaInset + horizontalMargin, trailingSafeAreaInset + horizontalMargin)
    }

    /// 計算捲動容器內容的水平邊距；窄區沿用系統預設，寬區回傳超出上限部分的一半
    ///
    /// - Parameters:
    ///   - containerWidth: 捲動容器的可用寬度
    ///   - maximumWidth: 已依字級縮放的內容上限寬度
    /// - Returns: 兩側各自的水平內容邊距；容器寬度不超過上限時為 `nil`
    static func scrollContentHorizontalMargin(
        containerWidth: CGFloat,
        maximumWidth: CGFloat
    ) -> CGFloat? {
        guard containerWidth > maximumWidth else {
            return nil
        }
        return (containerWidth - maximumWidth) / 2
    }
}

// MARK: - ViewModifier

extension BLReadableContentLayout: ViewModifier {

    /// 呈現套用閱讀限寬偏好之視圖內容，窄區填滿扣設計邊距，寬區限寬並於局部安全區域內水平置中
    ///
    /// - Parameter content: 被修飾之原始視圖內容
    /// - Returns: 套用限寬偏好後之視圖
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: maximumWidth)
            .padding(.horizontal, BLSpacing.large)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - blReadableContent

extension View {

    /// 依內容類型在可用安全區域內自適應閱讀寬度，窄區填滿扣正常邊距，寬區限寬並置中
    ///
    /// - Parameter type: 內容類型偏好，預設為 `.text`
    /// - Returns: 套用閱讀版面偏好的視圖
    func blReadableContent(_ type: BLReadableContentType = .text) -> some View {
        modifier(BLReadableContentLayout(type: type))
    }
}

// MARK: - Preview

#Preview("閱讀版面自適應") {
    let placeholder = "輸入文字"
    VStack(spacing: BLSpacing.large) {
        Text(verbatim: "這是一段套用文字偏好 (基準上限 640 pt) 的長段落示範文字，隨 DynamicType 與安全區域自動退讓置中。")
            .padding(BLSpacing.medium)
            .blReadableContent(.text)
            .blTextStyle(.body)
            .background(.blSurface)

        HStack(spacing: BLSpacing.medium) {
            Text(verbatim: "表單欄位")
                .blTextStyle(.headline)

            TextField(placeholder, text: .constant("示範內容"))
                .textFieldStyle(.roundedBorder)
        }
        .padding(BLSpacing.medium)
        .blReadableContent(.form)
        .background(.blSurface)
    }
    .padding(BLSpacing.large)
    .frame(width: 800, height: 400)
    .background(.blBackground)
}
