//
//  PhotoDataProcessor.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/6.
//

import Foundation
import ImageIO
import UniformTypeIdentifiers

/// 將相簿影像降採樣並重編碼為 JPEG
enum PhotoDataProcessor {
    
    // MARK: - Static Properties
    
    /// 預設的最長邊像素上限
    static let defaultMaxPixelSize: CGFloat = 1_600
    
    /// 預設的 JPEG 壓縮品質 (0–1)
    static let defaultCompressionQuality: CGFloat = 0.75
}

// MARK: - Internal Method

extension PhotoDataProcessor {
    
    /// 將影像 data 降採樣至最長邊不超過 `maxPixelSize`，並以 JPEG 重編碼
    /// - Parameters:
    ///   - data: 原始影像 data (任何 ImageIO 支援的格式)
    ///   - maxPixelSize: 最長邊像素上限，預設 ``defaultMaxPixelSize``
    ///   - compressionQuality: JPEG 壓縮品質，預設 ``defaultCompressionQuality``
    /// - Returns: 正規化後的 JPEG data；無法解碼或編碼失敗時回傳 `nil`
    static func downscaledJPEGData(
        from data: Data,
        maxPixelSize: CGFloat = defaultMaxPixelSize,
        compressionQuality: CGFloat = defaultCompressionQuality
    ) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        
        let thumbnailOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(
            source, 0, thumbnailOptions as CFDictionary
        ) else {
            return nil
        }
        
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            output, UTType.jpeg.identifier as CFString, 1, nil
        ) else {
            return nil
        }
        
        let destinationOptions: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ]
        CGImageDestinationAddImage(destination, thumbnail, destinationOptions as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        
        return output as Data
    }
}
