//
//  BLPhotoViewer.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/6.
//

import ImageIO
import SwiftUI
import UniformTypeIdentifiers

/// 可左右滑動切換照片的檢視器
struct BLPhotoViewer: View {
    
    // MARK: - View Properties
    
    /// 是否已開啟「減少動態效果」
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    /// 要檢視的照片集合 (依儲存順序)
    let photos: [Data]
    
    /// 目前聚焦的照片 index；由 paging ScrollView 的 `scrollPosition` 驅動
    @State private var currentIndex: Int?
    
    /// 目前縮放倍率；大於 1 時停用換頁並改用平移
    @State private var zoomScale: CGFloat = 1
    
    /// 手勢進行中的暫時倍率，手勢結束後併入 ``zoomScale``
    @State private var gestureScale: CGFloat = 1
    
    /// 放大後的平移位移
    @State private var panOffset: CGSize = .zero
    
    /// 手勢進行中的暫時位移，手勢結束後併入 ``panOffset``
    @State private var gesturePanOffset: CGSize = .zero
    
    // MARK: - Init
    
    /// 建立檢視器並把初始聚焦照片設為 `initialIndex`
    /// - Parameters:
    ///   - photos: 要檢視的照片集合 (依儲存順序)
    ///   - initialIndex: 開啟時聚焦的照片 index
    init(photos: [Data], initialIndex: Int) {
        self.photos = photos
        self._currentIndex = State(initialValue: initialIndex)
    }
    
    // MARK: - View Body
    
    /// 檢視器的畫面內容
    var body: some View {
        // ScrollView 需留邊距，避免延伸到 navigation bar 下方
        pager
            .padding(BLSpacing.small)
            .accessibilityIdentifier(BLAccessibilityID.PhotoViewer.root)
            .navigationTitle(Text(verbatim: counterText))
            .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - ViewBuilder

private extension BLPhotoViewer {
    
    /// 左右滑動的分頁影像列；每頁填滿可視範圍
    @ViewBuilder
    var pager: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(Array(photos.enumerated()), id: \.offset) { _, data in
                    photoPage(data: data)
                        .containerRelativeFrame([.horizontal, .vertical])
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $currentIndex)
        .scrollIndicators(.hidden)
        // 只有倍率為 1 時允許換頁。
        .scrollDisabled(isZoomedIn)
        .onChange(of: currentIndex) { _, _ in
            resetZoom()
        }
    }
    
    /// 顯示單頁影像或 placeholder
    /// - Parameter data: 該頁的影像 data
    @ViewBuilder
    func photoPage(data: Data) -> some View {
        if let image = Image(photoData: data) {
            image
                .resizable()
                .scaledToFit()
            // 照片四角套小圓角；用 mask 而非 clipShape——直接套在 image-backed layer 上的
            // clipShape 在部分渲染路徑 (snapshot 光柵化) 不生效，mask 兩者皆穩定
                .mask {
                    RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous)
                }
                .accessibilityLabel("訂單照片")
                .accessibilityIdentifier(BLAccessibilityID.PhotoViewer.image)
                .scaleEffect(zoomScale * gestureScale)
                .offset(currentPanOffset)
                .gesture(magnifyGesture)
            // 平移手勢只在放大後掛上
            // 不常駐 simultaneousGesture，避免未放大時攔截 ScrollView 捲動
                .simultaneousGesture(panGesture, isEnabled: isZoomedIn)
                .onTapGesture(count: 2) {
                    toggleZoom()
                }
                .animation(Self.zoomAnimation(reduceMotion: reduceMotion), value: zoomScale)
        } else {
            Image(systemName: "photo")
            // 保持一般字重，避免 placeholder 圖示過粗
                .font(.largeTitle)
                .foregroundStyle(Color.blSecondaryLabel)
                .accessibilityLabel("無法顯示的照片")
        }
    }
}

// MARK: - Internal Method

extension BLPhotoViewer {
    
    /// 依系統偏好決定縮放動畫
    /// - Parameter reduceMotion: 是否已開啟「減少動態效果」
    /// - Returns: 減少動態效果時為 `nil`，否則為快速動畫
    nonisolated static func zoomAnimation(reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : .snappy(duration: 0.2)
    }
}

// MARK: - Private Method

private extension BLPhotoViewer {
    
    /// 是否已放大
    var isZoomedIn: Bool {
        zoomScale > 1
    }
    
    /// 雙點放大時使用的倍率
    var zoomedInScale: CGFloat { 2 }
    
    /// 目前套用的總位移 (已提交的位移加上手勢進行中的位移)
    var currentPanOffset: CGSize {
        CGSize(
            width: panOffset.width + gesturePanOffset.width,
            height: panOffset.height + gesturePanOffset.height
        )
    }
    
    /// 縮放手勢：手勢中即時反映，結束時夾在 1 至 4 倍之間
    var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                gestureScale = value.magnification
            }
            .onEnded { value in
                gestureScale = 1
                zoomScale = min(max(zoomScale * value.magnification, 1), 4)
                if !isZoomedIn {
                    resetPan()
                }
            }
    }
    
    /// 平移手勢：僅在放大後啟用，未放大時讓換頁取得手勢
    var panGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard isZoomedIn else {
                    return
                }
                gesturePanOffset = value.translation
            }
            .onEnded { value in
                guard isZoomedIn else {
                    return
                }
                gesturePanOffset = .zero
                panOffset = CGSize(
                    width: panOffset.width + value.translation.width,
                    height: panOffset.height + value.translation.height
                )
            }
    }
    
    /// 雙點在一倍與兩倍之間切換
    func toggleZoom() {
        if isZoomedIn {
            resetZoom()
        } else {
            zoomScale = zoomedInScale
        }
    }
    
    /// 回到一倍並清除位移
    func resetZoom() {
        zoomScale = 1
        gestureScale = 1
        resetPan()
    }
    
    /// 清除平移位移
    func resetPan() {
        panOffset = .zero
        gesturePanOffset = .zero
    }
    
    /// 計數文字 (目前第幾張/總張數)；navigation title 使用
    var counterText: String {
        "\((currentIndex ?? 0) + 1)/\(photos.count)"
    }
}

// MARK: - Preview

#Preview("照片檢視器") {
    /// Preview 使用的純色 JPEG sample
    func sampleJPEGData(
        red: CGFloat,
        green: CGFloat,
        blue: CGFloat
    ) -> Data {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard
            let context = CGContext(
                data: nil,
                width: 480,
                height: 320,
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
            }()
        else {
            return Data()
        }
        
        context.setFillColor(CGColor(red: red, green: green, blue: blue, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 480, height: 320))
        guard let image = context.makeImage() else {
            return Data()
        }
        
        CGImageDestinationAddImage(destination.1, image, nil)
        CGImageDestinationFinalize(destination.1)
        return destination.0 as Data
    }
    
    // 以 NavigationStack 包住模擬實際的推進呈現情境 (檢視器本身不自帶 stack)
    return NavigationStack {
        BLPhotoViewer(
            photos: [
                sampleJPEGData(red: 0.35, green: 0.6, blue: 0.9),
                sampleJPEGData(red: 0.9, green: 0.5, blue: 0.4),
                sampleJPEGData(red: 0.4, green: 0.8, blue: 0.55),
            ],
            initialIndex: 1
        )
    }
}
