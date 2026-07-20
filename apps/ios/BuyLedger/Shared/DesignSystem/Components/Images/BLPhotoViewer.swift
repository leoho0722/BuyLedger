//
//  BLPhotoViewer.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/6.
//

import ImageIO
import SwiftUI
import UniformTypeIdentifiers

/// 照片檢視器：影像 scaledToFit 帶小圓角，左右滑動切換同一組照片；背景隨系統深淺色模式自適應
///
/// 由訂單編輯表單以推進呈現 (加入 `PickerRoute`，避免 sheet 上再疊 modal)：置中 title 顯示計數 (x/n)、取消位置 ✕ 關閉
///
/// 換頁以橫向 paging ScrollView (`scrollTargetBehavior(.paging)` + `scrollPosition`) 實作，iOS / iPadOS 共用；滑到第一張／最後一張即停止
///
/// 單張影像無法解碼時顯示 placeholder 圖示
struct BLPhotoViewer: View {

    // MARK: - View Properties

    /// 要檢視的照片集合 (依儲存順序)
    let photos: [Data]

    /// 點擊關閉鈕時的 callback
    let onDismiss: () -> Void

    /// 目前聚焦的照片 index；由 paging ScrollView 的 `scrollPosition` 驅動
    @State private var currentIndex: Int?

    /// 目前的縮放倍率；為 1 時由換頁接手手勢，大於 1 時改為平移並停用換頁
    @State private var zoomScale: CGFloat = 1

    /// 手勢進行中的暫時倍率，手勢結束後併入 ``zoomScale``
    @State private var gestureScale: CGFloat = 1

    /// 放大後的平移位移
    @State private var panOffset: CGSize = .zero

    /// 手勢進行中的暫時位移，手勢結束後併入 ``panOffset``
    @State private var gesturePanOffset: CGSize = .zero

    // MARK: - Init

    /// 建立檢視器並把初始聚焦照片設為 `initialIndex`
    ///
    /// 顯式 init 是為了把 `initialIndex` 注入 `@State` 的初始值，讓檢視器一開啟就停在被點擊的那張照片，而非從第一張動畫捲動過去
    /// - Parameters:
    ///   - photos: 要檢視的照片集合 (依儲存順序)
    ///   - initialIndex: 開啟時聚焦的照片 index
    ///   - onDismiss: 點擊關閉鈕時的 callback
    init(photos: [Data], initialIndex: Int, onDismiss: @escaping () -> Void) {
        self.photos = photos
        self.onDismiss = onDismiss
        self._currentIndex = State(initialValue: initialIndex)
    }

    // MARK: - View Body

    /// 檢視器的畫面內容
    var body: some View {
        NavigationStack {
            // NavigationStack 會把「貼齊 safe area 上緣」的 ScrollView 自動延伸到 navigation bar 底下，
            // 造成照片與 bar 重疊；四邊各留 BLSpacing.small (10pt) 的間距，既滿足版面需求
            // (照片頂部距 bar、底部與左右距邊各 10pt)，也讓 pager 不貼齊邊緣、阻斷自動延伸
            // 背景不另外鋪色，沿用 sheet 的系統背景，隨深淺色模式自適應
            pager
                .padding(BLSpacing.small)
                .navigationTitle(Text(verbatim: counterText))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    // 關閉是離開而非主要動作，放取消位置
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                        }
                        .keyboardShortcut(.cancelAction)
                        .accessibilityLabel("關閉檢視器")
                    }
                }
        }
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
        // 倍率為 1 時換頁接手、大於 1 時停用換頁改由平移接手，與系統照片瀏覽的規則一致
        .scrollDisabled(isZoomedIn)
        .onChange(of: currentIndex) { _, _ in
            resetZoom()
        }
    }

    /// 單頁影像：可解碼時 scaledToFit 置中並套用小圓角，否則顯示 placeholder 圖示
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
                .scaleEffect(zoomScale * gestureScale)
                .offset(currentPanOffset)
                .gesture(magnifyGesture)
                .simultaneousGesture(panGesture)
                .onTapGesture(count: 2) {
                    toggleZoom()
                }
                .animation(.snappy(duration: 0.2), value: zoomScale)
        } else {
            Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityLabel("無法顯示的照片")
        }
    }
}

// MARK: - Private Method

private extension BLPhotoViewer {

    /// 是否已放大 (放大後換頁停用、改為平移)
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
    ///
    /// 不逐級放大——逐級會讓使用者需要多次雙點才能回到原始尺寸
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
    /// 以 CoreGraphics 合成的純色 JPEG sample，讓 Preview 不依賴外部資源
    func sampleJPEGData(red: CGFloat, green: CGFloat, blue: CGFloat) -> Data {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: 480,
            height: 320,
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
        context.fill(CGRect(x: 0, y: 0, width: 480, height: 320))
        guard let image = context.makeImage() else {
            return Data()
        }

        CGImageDestinationAddImage(destination.1, image, nil)
        CGImageDestinationFinalize(destination.1)
        return destination.0 as Data
    }

    return BLPhotoViewer(
        photos: [
            sampleJPEGData(red: 0.35, green: 0.6, blue: 0.9),
            sampleJPEGData(red: 0.9, green: 0.5, blue: 0.4),
            sampleJPEGData(red: 0.4, green: 0.8, blue: 0.55),
        ],
        initialIndex: 1
    ) {}
}
