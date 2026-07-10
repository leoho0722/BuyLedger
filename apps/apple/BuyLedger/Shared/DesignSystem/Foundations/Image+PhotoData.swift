//
//  Image+PhotoData.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/6.
//

import SwiftUI
import UIKit

extension Image {

    // MARK: - Init

    /// 將照片 data 解碼為 `Image`；無法解碼時回傳 `nil`
    ///
    /// 供 ``BLPhotoThumbnail`` 與 ``BLPhotoViewer`` 共用，統一走 UIKit 解碼
    /// - Parameter photoData: 待解碼的影像 data
    init?(photoData: Data) {
        guard let uiImage = UIImage(data: photoData) else { 
            return nil
        }
        self.init(uiImage: uiImage)
    }
}
