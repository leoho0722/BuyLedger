//
//  BLUITestPhotoCache.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

#if DEBUG

import Foundation
import Synchronization

/// UI 測試照片替身共用的假影像，第一次匯入時才繪製，之後重複使用同一批
final class BLUITestPhotoCache: Sendable {

    // MARK: - Properties

    /// 已繪好的假影像；`nil` 代表還沒繪過
    private let photos = Mutex<[Data]?>(nil)
}

// MARK: - Internal Method

extension BLUITestPhotoCache {

    /// 取出假影像，尚未繪製時先繪再快取
    ///
    /// - Parameter make: 實際繪圖的工廠
    /// - Returns: 快取中的假影像
    func resolvedPhotos(make: () -> [Data]) -> [Data] {
        photos.withLock {
            if let existing = $0 {
                return existing
            }
            let made = make()
            $0 = made
            return made
        }
    }
}

#endif
