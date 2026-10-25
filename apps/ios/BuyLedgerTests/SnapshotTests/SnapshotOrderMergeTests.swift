//
//  SnapshotOrderMergeTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing
import UIKit

@testable import BuyLedger

/// `OrderMergeCandidateSheet` 與 `MergePhotoPickerSheet` 的快照測試，涵蓋候選清單的有無與照片挑選的選取狀態
@MainActor
struct SnapshotOrderMergeTests {

    /// 驗證合併候選 sheet 有可合併的候選時，依日期分組列出同客戶的訂單，畫面符合基準圖
    ///
    /// - Note: 不同客戶的訂單不列入候選
    /// - Note: 今日與昨日的候選分屬兩個日期區段
    /// - Note: sheet 自帶 `NavigationStack`，直接呈現
    /// - Note: 使用 `EmptyReducer`
    /// - Note: 尺寸為 iPhone 直向 393 × 852
    /// - Note: 在 key window 繪製，否則導覽列標題與搜尋欄會畫成近乎白色
    @Test
    func orderMergeCandidateSheet_有可合併訂單_顯示候選清單() {
        TestDependencies.withFixedNow {
            // Given
            let primary = Self.makeMergeOrder(id: "merge-0001", date: TestDependencies.fixedNow)
            let state = Self.makeMergeState(
                primary: primary,
                orders: [
                    primary,
                    Self.makeMergeOrder(id: "merge-0002", date: TestDependencies.fixedNow),
                    Self.makeMergeOrder(
                        id: "merge-0003",
                        date: TestDependencies.fixedNow.addingTimeInterval(-86_400)
                    ),
                    Self.makeMergeOrder(
                        id: "merge-0004",
                        customerName: "其他客戶",
                        date: TestDependencies.fixedNow
                    ),
                ]
            )

            // When
            let view = OrderMergeCandidateSheet(
                store: Store(initialState: state) {
                    EmptyReducer()
                }
            )
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 驗證合併候選 sheet 沒有任何可合併的候選時，顯示空狀態與說明文字，不顯示清單，畫面符合基準圖
    ///
    /// - Note: 候選清單只剩主訂單本身
    /// - Note: 空狀態為 `ContentUnavailableView`
    /// - Note: 使用 `EmptyReducer`
    /// - Note: 尺寸為 iPhone 直向 393 × 852
    /// - Note: 與有候選的情境一樣在 key window 繪製
    @Test
    func orderMergeCandidateSheet_無可合併訂單_顯示空狀態() {
        TestDependencies.withFixedNow {
            // Given
            let primary = Self.makeMergeOrder(id: "merge-0001", date: TestDependencies.fixedNow)
            let state = Self.makeMergeState(primary: primary, orders: [primary])

            // When
            let view = OrderMergeCandidateSheet(
                store: Store(initialState: state) {
                    EmptyReducer()
                }
            )
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image(drawHierarchyInKeyWindow: true))
        }
    }

    /// 驗證合併照片挑選步驟收到七張照片且已選滿五張上限時，說明列出總數與上限，已選格顯示彩色勾號，畫面符合基準圖
    ///
    /// - Throws: 照片位元組無法產生時丟出，測試以失敗結束
    /// - Note: 步驟畫面在 sheet 內由導覽推入，這裡以 `NavigationStack` 包住 `MergePhotoPickerSheet`
    /// - Note: 標題使用照片挑選步驟的導覽標題文字
    /// - Note: 導覽列的確認鈕不在快照內
    /// - Note: 照片為固定顏色的 PNG，位元組每次都相同
    /// - Note: 使用 `EmptyReducer`
    /// - Note: 尺寸為 iPhone 直向 393 × 852
    @Test
    func mergePhotoPickerSheet_七張照片選滿上限_顯示已選與未選照片() throws {
        try TestDependencies.withFixedNow {
            // Given
            let primary = Self.makeMergeOrder(id: "merge-0001", date: TestDependencies.fixedNow)
            var state = Self.makeMergeState(primary: primary, orders: [primary])
            state.combinedPhotos = try Self.makeMergePhotos(count: 7)
            state.selectedPhotoIndices = [0, 1, 2, 3, 4]

            // When
            let view = NavigationStack {
                MergePhotoPickerSheet(
                    store: Store(initialState: state) {
                        EmptyReducer()
                    }
                )
                .navigationTitle(Text("orders.merge.label.keepPhotos"))
                .navigationBarTitleDisplayMode(.inline)
            }
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }

    /// 驗證合併照片挑選步驟只保留部分照片時，未選取的格子降低透明度並以空心圓標示，畫面符合基準圖
    ///
    /// - Throws: 照片位元組無法產生時丟出，測試以失敗結束
    /// - Note: 選取索引為 0、2、4，索引 1、3、5、6 未選取
    /// - Note: 已選格維持彩色勾號
    /// - Note: 步驟畫面以 `NavigationStack` 包住 `MergePhotoPickerSheet`
    /// - Note: 使用 `EmptyReducer`
    /// - Note: 尺寸為 iPhone 直向 393 × 852
    /// - Note: 照片與滿額測試相同
    @Test
    func mergePhotoPickerSheet_七張照片只選部分_顯示未選取照片() throws {
        try TestDependencies.withFixedNow {
            // Given
            let primary = Self.makeMergeOrder(id: "merge-0001", date: TestDependencies.fixedNow)
            var state = Self.makeMergeState(primary: primary, orders: [primary])
            state.combinedPhotos = try Self.makeMergePhotos(count: 7)
            state.selectedPhotoIndices = [0, 2, 4]

            // When
            let view = NavigationStack {
                MergePhotoPickerSheet(
                    store: Store(initialState: state) {
                        EmptyReducer()
                    }
                )
                .navigationTitle(Text("orders.merge.label.keepPhotos"))
                .navigationBarTitleDisplayMode(.inline)
            }
                .environment(\.locale, AppLanguage.traditionalChinese.locale)
                .frame(width: 393, height: 852)

            // Then
            assertSnapshot(of: view, as: .image)
        }
    }
}

// MARK: - Private Method

private extension SnapshotOrderMergeTests {

    /// 建立合併測試用的訂單，客戶的縮寫與分級、幣別與狀態固定，只有識別值、客戶名稱與日期由參數決定
    ///
    /// - Parameters:
    ///   - id: 訂單識別值，同一組測試內需互不相同
    ///   - customerName: 客戶名稱，預設與主訂單相同才會成為候選
    ///   - date: 訂單日期
    /// - Returns: 狀態為已確認、幣別為 TWD 的訂單
    static func makeMergeOrder(
        id: String,
        customerName: String = "合併測試客戶",
        date: Date
    ) -> LedgerOrder {
        LedgerOrder.fixture(
            id: id,
            customer: LedgerCustomer(name: customerName, initials: "MT", tier: .regular),
            status: .confirmed,
            currency: .twd,
            date: date
        )
    }

    /// 建立合併流程的初始狀態，`uuid` 固定為 `UUID(0)`，候選清單於 `init` 內一次過濾完成
    ///
    /// - Parameters:
    ///   - primary: 主訂單
    ///   - orders: 全部訂單，可包含主訂單本身
    /// - Returns: 候選與日期脈絡已建立的合併流程狀態
    static func makeMergeState(
        primary: LedgerOrder,
        orders: [LedgerOrder]
    ) -> OrderMergeFeature.State {
        withDependencies {
            $0.uuid = .constant(UUID(0))
        } operation: {
            OrderMergeFeature.State(
                primary: primary,
                orders: orders,
                dateContext: OrderDateContext(
                    now: TestDependencies.fixedNow,
                    calendar: TestDependencies.fixedCalendar
                )
            )
        }
    }

    /// 建立指定張數的照片，每張顏色不同，讓縮圖格可以辨識
    ///
    /// - Parameter count: 照片張數
    /// - Returns: 依序排列的 PNG 位元組
    /// - Throws: 任一張照片無法產生時丟出，測試以失敗結束
    static func makeMergePhotos(count: Int) throws -> [Data] {
        try (0..<count).map {
            try Self.makeMergePhoto(index: $0)
        }
    }

    /// 繪製 96 × 96 的 PNG，紅色分量依序號決定、其餘分量固定，位元組每次產生都相同且可被 `UIImage` 解碼
    ///
    /// - Parameter index: 照片序號，決定紅色分量
    /// - Returns: PNG 位元組
    /// - Throws: PNG 無法編碼時丟出，測試以失敗結束
    static func makeMergePhoto(index: Int) throws -> Data {
        let size = CGSize(width: 96, height: 96)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let image = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            let color = UIColor(
                red: CGFloat(index) / 10,
                green: 0.4,
                blue: 0.6,
                alpha: 1
            )
            color.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))
        }
        return try #require(image.pngData())
    }
}
