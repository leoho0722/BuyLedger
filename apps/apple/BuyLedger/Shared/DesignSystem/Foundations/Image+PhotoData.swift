//
//  Image+PhotoData.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/6.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

extension Image {

    // MARK: - Init

    /// 將照片 data 解碼為平台影像；無法解碼時回傳 `nil`
    ///
    /// 供 ``BLPhotoThumbnail`` 與 ``BLPhotoViewer`` 共用，統一 UIKit / AppKit 的解碼分流
    /// - Parameter photoData: 待解碼的影像 data
    init?(photoData: Data) {
        #if canImport(UIKit)
        guard let uiImage = UIImage(data: photoData) else { return nil }
        self.init(uiImage: uiImage)
        #elseif canImport(AppKit)
        guard let nsImage = NSImage(data: photoData) else { return nil }
        self.init(nsImage: nsImage)
        #endif
    }
}
