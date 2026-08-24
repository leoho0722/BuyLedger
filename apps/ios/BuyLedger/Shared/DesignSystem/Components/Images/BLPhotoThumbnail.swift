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
struct BLPhotoThumbnail: View {
    
    // MARK: - View Properties
    
    /// 縮圖要顯示的影像 data
    let imageData: Data
    
    /// 縮圖寬高
    var size: CGFloat = 72
    
    /// 點擊縮圖內容區時的 callback (例如開啟照片檢視)；`nil` 代表縮圖不可點擊
    var onTap: (() -> Void)? = nil
    
    /// 縮圖本體按鈕的 accessibility identifier (UI 測試定位用)；`nil` 代表不指定
    var accessibilityID: String? = nil
    
    /// 點擊右上角刪除鈕時的 callback
    let onDelete: () -> Void
    
    /// 刪除鈕的位移量
    private static let deleteButtonInset: CGFloat = BLHitTarget.minimum / 2 - 18 / 2 - 4
    
    // MARK: - View Body
    
    /// 縮圖的畫面內容
    var body: some View {
        ZStack(alignment: .topTrailing) {
            tappableThumbnail
            
            // 將尺寸與形狀放在標籤內，確保刪除按鈕有足夠命中區。
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Color.black.opacity(0.55))
                    .blTextStyle(.headline)
                    .frame(width: BLHitTarget.minimum, height: BLHitTarget.minimum)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            // 以位移維持圖示原本的視覺位置。
            .offset(x: Self.deleteButtonInset, y: -Self.deleteButtonInset)
            .accessibilityLabel("刪除照片")
        }
    }
}

// MARK: - ViewBuilder

private extension BLPhotoThumbnail {
    
    /// 縮圖本體：提供 `onTap` 時以按鈕呈現，否則維持不可互動的靜態內容
    @ViewBuilder
    var tappableThumbnail: some View {
        if let onTap {
            Button(action: onTap) {
                shapedThumbnail
            }
            .buttonStyle(BLPhotoThumbnailButtonStyle())
            .accessibilityIdentifier(accessibilityID ?? "")
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
                        .foregroundStyle(Color.blSecondaryLabel)
                }
                .accessibilityLabel("無法顯示的照片")
        }
    }
}

// MARK: - ButtonStyle

/// 縮圖按鈕的樣式：不改變影像著色，只在按下時給視覺回饋
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
    /// Preview 使用的純色 JPEG sample
    func sampleJPEGData(
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat
    ) -> Data {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: 240,
            height: 240,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ),
              let destination = {
                  let output = NSMutableData()
                  return CGImageDestinationCreateWithData(
                    output, UTType.jpeg.identifier as CFString, 1, nil
                  )
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
