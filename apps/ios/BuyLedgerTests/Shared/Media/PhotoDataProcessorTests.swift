//
//  PhotoDataProcessorTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/6/6.
//

import CoreGraphics
import Foundation
import ImageIO
import Testing
import UniformTypeIdentifiers

@testable import BuyLedger

/// `PhotoDataProcessor` 的單元測試，涵蓋照片資料的降採樣與 JPEG 重編碼
struct PhotoDataProcessorTests {

    /// 驗證 2400×1200 的 PNG 轉成 JPEG 後為 1600×800，最長邊不超過 1600 像素且維持比例
    ///
    /// - Throws: 測試影像建立或處理失敗時丟出錯誤
    @Test
    func downscaledJPEGData_超過像素上限的影像_降採樣並重編碼為JPEG() throws {
        // Given
        let source = try #require(Self.makePNGData(width: 2_400, height: 1_200))

        // When
        let processed = try #require(PhotoDataProcessor.downscaledJPEGData(from: source))

        // Then
        let info = try #require(Self.imageInfo(from: processed))
        #expect(info.type == UTType.jpeg.identifier)
        #expect(max(info.width, info.height) <= 1_600)
        // 等比例縮放：2400×1200 → 1600×800
        #expect(info.width == 1_600)
        #expect(info.height == 800)
    }

    /// 驗證尺寸已在上限內的影像不會被放大，僅重編碼為 JPEG
    ///
    /// - Throws: 測試影像建立或處理失敗時丟出錯誤
    @Test
    func downscaledJPEGData_尺寸在上限內的影像_不放大只重編碼() throws {
        // Given
        let source = try #require(Self.makePNGData(width: 800, height: 400))

        // When
        let processed = try #require(PhotoDataProcessor.downscaledJPEGData(from: source))

        // Then
        let info = try #require(Self.imageInfo(from: processed))
        #expect(info.type == UTType.jpeg.identifier)
        #expect(info.width == 800)
        #expect(info.height == 400)
    }

    /// 驗證無法解碼的 data 回傳 `nil`，不丟出例外，也不回傳空影像
    @Test
    func downscaledJPEGData_無法解碼的資料_回傳空值() {
        // Given
        let garbage = Data([0x00, 0x01, 0x02, 0x03])

        // When
        let processed = PhotoDataProcessor.downscaledJPEGData(from: garbage)

        // Then
        #expect(processed == nil)
    }
}

// MARK: - Nested Types

private extension PhotoDataProcessorTests {

    /// 影像 data 解析出的尺寸與容器格式
    struct ImageInfo: Sendable {

        /// 影像寬度，單位為像素
        let width: Int

        /// 影像高度，單位為像素
        let height: Int

        /// 容器格式的 UTI 識別字
        let type: String
    }
}

// MARK: - Private Method

private extension PhotoDataProcessorTests {

    /// 以 CoreGraphics 合成指定尺寸的純色影像並編碼為 PNG data
    ///
    /// - Parameters:
    ///   - width: 影像寬度
    ///   - height: 影像高度
    /// - Returns: PNG 影像資料；無法建立影像時為 `nil`
    static func makePNGData(width: Int, height: Int) -> Data? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            return nil
        }

        context.setFillColor(
            CGColor(
                red: 0.2,
                green: 0.5,
                blue: 0.8,
                alpha: 1
            )
        )
        context.fill(
            CGRect(
                x: 0,
                y: 0,
                width: width,
                height: height
            )
        )
        guard let image = context.makeImage() else {
            return nil
        }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }

        return output as Data
    }

    /// 解析影像 data 的尺寸與容器格式
    ///
    /// - Parameter data: 要解析的影像資料
    /// - Returns: 影像寬度、高度與容器格式；無法解析時為 `nil`
    private static func imageInfo(from data: Data) -> ImageInfo? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let type = CGImageSourceGetType(source),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                  as? [CFString: Any],
              let width = properties[kCGImagePropertyPixelWidth] as? Int,
              let height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return nil
        }

        return ImageInfo(width: width, height: height, type: type as String)
    }
}
