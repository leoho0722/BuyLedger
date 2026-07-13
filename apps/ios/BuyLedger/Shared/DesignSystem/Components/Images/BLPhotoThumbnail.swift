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

    /// 點擊縮圖內容區時的 callback (例如開啟全螢幕檢視)；`nil` 代表縮圖不可點擊
    ///
    /// tap gesture 僅掛在縮圖內容區——右上角刪除鈕本身是 `Button`，命中優先於 tap gesture，點刪除不會誤觸此 callback
    var onTap: (() -> Void)? = nil

    /// 點擊右上角刪除鈕時的 callback
    let onDelete: () -> Void

    // MARK: - View Body

    /// 縮圖的畫面內容
    var body: some View {
        ZStack(alignment: .topTrailing) {
            thumbnailContent
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
                .onTapGesture {
                    onTap?()
                }

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color.black.opacity(0.55))
                    .font(.system(size: 18))
            }
            .buttonStyle(.plain)
            .padding(4)
            .accessibilityLabel("刪除照片")
        }
    }
}

// MARK: - ViewBuilder

private extension BLPhotoThumbnail {

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
