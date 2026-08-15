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

/// 驗證照片資料處理
struct PhotoDataProcessorTests {
    
    // MARK: - Tests
    
    /// 驗證影像降採樣與 JPEG 重編碼
    /// - Throws: 測試影像建立或處理失敗時拋出錯誤
    @Test func oversizedImageIsDownscaledToMaxPixelSizeJPEG() throws(any Error) {
        let source = try #require(Self.makePNGData(width: 2_400, height: 1_200))
        
        let processed = try #require(PhotoDataProcessor.downscaledJPEGData(from: source))
        
        let info = try #require(Self.imageInfo(from: processed))
        #expect(info.type == UTType.jpeg.identifier)
        #expect(max(info.width, info.height) <= 1_600)
        // 等比例縮放：2400×1200 → 1600×800
        #expect(info.width == 1_600)
        #expect(info.height == 800)
    }
    
    /// 尺寸已在上限內的影像不應被放大，僅重編碼為 JPEG
    /// - Throws: 測試影像建立或處理失敗時拋出錯誤
    @Test func smallImageKeepsSizeWithoutUpscaling() throws(any Error) {
        let source = try #require(Self.makePNGData(width: 800, height: 400))
        
        let processed = try #require(PhotoDataProcessor.downscaledJPEGData(from: source))
        
        let info = try #require(Self.imageInfo(from: processed))
        #expect(info.type == UTType.jpeg.identifier)
        #expect(info.width == 800)
        #expect(info.height == 400)
    }
    
    /// 無法解碼的 data 應回傳 `nil`，不丟例外也不回傳空影像
    @Test func undecodableDataReturnsNil() {
        let garbage = Data([0x00, 0x01, 0x02, 0x03])
        
        #expect(PhotoDataProcessor.downscaledJPEGData(from: garbage) == nil)
    }
}

// MARK: - Private Method

private extension PhotoDataProcessorTests {
    
    /// 以 CoreGraphics 合成指定尺寸的純色影像並編碼為 PNG data
    /// - Parameters:
    ///   - width: 影像寬度
    ///   - height: 影像高度
    /// - Returns: PNG 影像資料；無法建立影像時為 `nil`
    static func makePNGData(width: Int, height: Int) -> Data? {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard
            let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
            )
        else {
            return nil
        }
        
        context.setFillColor(CGColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        guard let image = context.makeImage() else {
            return nil
        }
        
        let output = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(
                output,
                UTType.png.identifier as CFString,
                1,
                nil
            )
        else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        
        return output as Data
    }
    
    /// 解析影像 data 的尺寸與容器格式
    /// - Parameter data: 要解析的影像資料
    /// - Returns: 影像寬度、高度與容器格式；無法解析時為 `nil`
    static func imageInfo(from data: Data) -> (width: Int, height: Int, type: String)? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
            let type = CGImageSourceGetType(source),
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
            let width = properties[kCGImagePropertyPixelWidth] as? Int,
            let height = properties[kCGImagePropertyPixelHeight] as? Int
        else {
            return nil
        }
        
        return (width, height, type as String)
    }
}
