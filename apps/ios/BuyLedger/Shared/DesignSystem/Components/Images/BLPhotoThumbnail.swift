//
//  BLPhotoThumbnail.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/6.
//

import ImageIO
import SwiftUI
import UniformTypeIdentifiers

/// 可刪除、可點擊開啟檢視的照片縮圖：固定尺寸圓角影像 + 右上角刪除鈕
///
/// 影像 data 無法解碼時顯示 placeholder 圖示 (寧可空狀態也不顯示假資料)，不會 crash
struct BLPhotoThumbnail: View {

    // MARK: - View Properties

    /// 縮圖要顯示的影像 data
    let imageData: Data

    /// 縮圖寬高
    var size: CGFloat = 72

    /// 點擊縮圖內容區時的 callback (例如開啟照片檢視)；`nil` 代表縮圖不可點擊
    ///
    /// 縮圖本體與右上角刪除鈕是兩顆獨立的 `Button`，各自承接點擊，點刪除不會誤觸此 callback
    var onTap: (() -> Void)? = nil

    /// 點擊右上角刪除鈕時的 callback
    let onDelete: () -> Void

    /// 刪除鈕的位移量
    ///
    /// 等於命中區半徑減去圖示半徑再減原本的 4pt 間距，使圖示中心維持在距角 13pt 的原位
    private static let deleteButtonInset: CGFloat = BLHitTarget.minimum / 2 - 18 / 2 - 4

    // MARK: - View Body

    /// 縮圖的畫面內容
    var body: some View {
        ZStack(alignment: .topTrailing) {
            tappableThumbnail

            // 尺寸與形狀宣告在標籤內部才會擴大命中區；掛在 Button 外層 (原本的 .padding(4))
            // 只增加版面間距、命中區仍只有圖示大小。刪除無確認也無復原，命中區不足會招致誤刪
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color.black.opacity(0.55))
                    .font(.headline)
                    .frame(width: BLHitTarget.minimum, height: BLHitTarget.minimum)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            // 以位移把放大後的命中區推回原本貼齊角落的視覺位置 (圖示中心距角 13pt 不變)
            .offset(x: Self.deleteButtonInset, y: -Self.deleteButtonInset)
            .accessibilityLabel("刪除照片")
        }
    }
}

// MARK: - ViewBuilder

private extension BLPhotoThumbnail {

    /// 縮圖本體：提供 `onTap` 時以按鈕呈現，否則維持不可互動的靜態內容
    ///
    /// 用按鈕而非點擊手勢——手勢沒有按壓態，也不支援 switch control 與外接鍵盤的啟用路徑
    @ViewBuilder
    var tappableThumbnail: some View {
        if let onTap {
            Button(action: onTap) {
                shapedThumbnail
            }
            .buttonStyle(BLPhotoThumbnailButtonStyle())
        } else {
            shapedThumbnail
        }
    }

    /// 套用固定尺寸與圓角裁切後的縮圖
    @ViewBuilder
    var shapedThumbnail: some View {
        thumbnailContent
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
    }

    /// 縮圖內容：可解碼時顯示影像並填滿裁切，否則顯示 placeholder 圖示
    @ViewBuilder
    var thumbnailContent: some View {
        if let image = Image(photoData: imageData) {
            image
                .resizable()
                .scaledToFill()
                .accessibilityLabel("訂單照片")
        } else {
            RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous)
                .fill(.quaternary)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel("無法顯示的照片")
        }
    }
}

// MARK: - ButtonStyle

/// 縮圖按鈕的樣式：不改變影像著色，只在按下時給視覺回饋
///
/// 系統的 plain 樣式對影像內容不提供任何按壓表現，borderless 則會為影像上色
private struct BLPhotoThumbnailButtonStyle: ButtonStyle {

    // MARK: - View Properties

    /// 是否已開啟「減少動態效果」
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - View Body

    /// 回傳套用樣式後的按鈕內容
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.72 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(reduceMotion ? nil : .snappy(duration: 0.14), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("照片縮圖") {
    /// 以 CoreGraphics 合成的純色 JPEG sample，讓 Preview 不依賴外部資源
    func sampleJPEGData(red: CGFloat, green: CGFloat, blue: CGFloat) -> Data {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: 240,
            height: 240,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ), let destination = {
            let output = NSMutableData()
            return CGImageDestinationCreateWithData(output, UTType.jpeg.identifier as CFString, 1, nil)
                .map { (output, $0) }
        }() else {
            return Data()
        }

        context.setFillColor(CGColor(red: red, green: green, blue: blue, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 240, height: 240))
        guard let image = context.makeImage() else {
            return Data()
        }

        CGImageDestinationAddImage(destination.1, image, nil)
        CGImageDestinationFinalize(destination.1)
        return destination.0 as Data
    }

    return HStack(spacing: BLSpacing.medium) {
        BLPhotoThumbnail(imageData: sampleJPEGData(red: 0.35, green: 0.6, blue: 0.9)) {}
        BLPhotoThumbnail(imageData: sampleJPEGData(red: 0.9, green: 0.5, blue: 0.4), size: 96) {}
        // 無法解碼的 data → placeholder
        BLPhotoThumbnail(imageData: Data([0x00, 0x01])) {}
    }
    .padding()
}
