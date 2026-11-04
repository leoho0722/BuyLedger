//
//  BLCardRowBackground.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/29.
//

import SwiftUI

/// 卡片中單一列的背景，填色、描邊與陰影與 `BLCard` 相同，相鄰列之間不留界線
///
/// - Note: 內緣形狀向列外延伸後再裁切到列界線，外緣不裁切，使陰影與描邊只出現在卡片外緣
struct BLCardRowBackground: View {

    // MARK: - Properties

    /// 列間分隔線的起點內距，由呼叫端依列的內容對齊方式指定
    let dividerLeadingInset: CGFloat

    /// 列間分隔線的終點內距，由呼叫端依列的內容對齊方式指定
    let dividerTrailingInset: CGFloat

    /// 卡片與列左右邊緣的距離，需與列內距使用同一個值
    let horizontalInset: CGFloat

    /// 列在卡片中的位置
    let position: BLCardRowPosition

    // MARK: - Body

    /// 卡片列背景；內緣裁切到列界線，外緣保留陰影的延伸範圍，不攔截點擊也不進入可及性樹
    var body: some View {
        cardShape
            .fill(.blSurface)
            .overlay {
                cardShape.stroke(.blSeparator, lineWidth: 0.5)
            }
            .blCardShadow()
            .overlay(alignment: .bottom) {
                if position.hasDivider {
                    Divider()
                        .padding(.leading, dividerLeadingInset)
                        .padding(.trailing, dividerTrailingInset)
                }
            }
            // 留白排在外觀之後，外觀套用在縮進後的卡片本體上，分隔線才不會超出卡片寬度
            .padding(.horizontal, horizontalInset)
            .padding(.top, position.topRoom)
            .padding(.bottom, position.bottomRoom)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipShape(RowClipShape(position: position))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private extension BLCardRowBackground {

    // MARK: - Computed Properties

    /// 列的外形，填色、描邊與陰影都以此為界
    var cardShape: RowShape {
        RowShape(position: position)
    }

    // MARK: - Nested Types

    /// 卡片列的形狀：外緣依列位置套用連續圓角，內緣向列範圍外延伸
    struct RowShape: Shape {

        // MARK: - Properties

        /// 列在卡片中的位置
        let position: BLCardRowPosition

        // MARK: - Internal Method

        /// 產生列的形狀路徑
        ///
        /// - Parameter rect: 列在卡片中的範圍
        /// - Returns: 外緣圓角、內緣延伸後的路徑
        func path(in rect: CGRect) -> Path {
            let top = position.hasTopEdge ? rect.minY : rect.minY - BLCardRowMetrics.overflow
            let bottom = position.hasBottomEdge
                ? rect.maxY
                : rect.maxY + BLCardRowMetrics.overflow
            let extended = CGRect(
                x: rect.minX,
                y: top,
                width: rect.width,
                height: bottom - top
            )
            let radius = BLRadius.large

            return UnevenRoundedRectangle(
                cornerRadii: RectangleCornerRadii(
                    topLeading: position.hasTopEdge ? radius : 0,
                    bottomLeading: position.hasBottomEdge ? radius : 0,
                    bottomTrailing: position.hasBottomEdge ? radius : 0,
                    topTrailing: position.hasTopEdge ? radius : 0
                ),
                style: .continuous
            )
                .path(in: extended)
        }
    }

    /// 卡片列的裁切範圍：內緣貼齊列界線，外緣向外延伸，使卡片外緣的陰影不被裁掉
    struct RowClipShape: Shape {

        // MARK: - Properties

        /// 列在卡片中的位置
        let position: BLCardRowPosition

        // MARK: - Internal Method

        /// 產生裁切範圍的路徑
        ///
        /// - Parameter rect: 列的範圍
        /// - Returns: 外緣延伸後的矩形路徑
        func path(in rect: CGRect) -> Path {
            let overflow = BLCardRowMetrics.overflow
            let top = position.hasTopEdge ? rect.minY - overflow : rect.minY
            let bottom = position.hasBottomEdge ? rect.maxY + overflow : rect.maxY
            return Path(
                CGRect(
                    x: rect.minX - overflow,
                    y: top,
                    width: rect.width + overflow * 2,
                    height: bottom - top
                )
            )
        }
    }

    /// 預覽用的卡片列，列內距與列背景使用同一套常數與環境的分隔線高度
    struct PreviewItem: View {

        // MARK: - Properties

        /// 分隔線的高度，與列內距使用同一個值
        @Environment(\.pixelLength) private var pixelLength

        /// 列在卡片中的位置
        let position: BLCardRowPosition

        /// 列內顯示的文字
        let title: String

        // MARK: - Body

        /// 預覽用的列內容與背景
        var body: some View {
            Text(verbatim: title)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, BLSpacing.large)
                .padding(.vertical, BLSpacing.medium)
                .padding(position.cardRowInsets(dividerHeight: pixelLength))
                .background {
                    BLCardRowBackground(
                        dividerLeadingInset: BLSpacing.large,
                        dividerTrailingInset: BLSpacing.large,
                        horizontalInset: BLCardRowMetrics.horizontalInset,
                        position: position
                    )
                }
        }
    }
}

// MARK: - Preview

#Preview("卡片列背景") {
    VStack(spacing: 0) {
        ForEach(0..<3, id: \.self) {
            BLCardRowBackground.PreviewItem(
                position: BLCardRowPosition(index: $0, count: 3),
                title: "列 \($0 + 1)"
            )
        }
    }
    .background(.blBackground)
}
