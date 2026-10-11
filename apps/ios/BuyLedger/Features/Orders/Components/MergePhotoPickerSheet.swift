//
//  MergePhotoPickerSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/6.
//

import ComposableArchitecture
import SwiftUI

/// 合併照片挑選畫面，最多保留指定上限的照片
struct MergePhotoPickerSheet: View {

    // MARK: - Properties

    /// 縮圖格的最小欄寬，隨字級縮放
    @ScaledMetric private var photoSize: CGFloat = 96

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<OrderMergeFeature>

    // MARK: - Body

    /// 照片挑選步驟的骨架，包含說明與縮圖格
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                instructions

                photoGrid
            }
            .padding(BLSpacing.large)
        }
    }
}

// MARK: - Private Views

private extension MergePhotoPickerSheet {

    /// 照片總數、上限與目前保留數量的說明
    var instructions: some View {
        Text(
            AppLanguage.format(
                "orders.merge.message.photoLimitNotice",
                store.combinedPhotos.count,
                LedgerOrder.maxPhotoCount,
                store.selectedPhotoIndices.count,
                LedgerOrder.maxPhotoCount,
                locale: locale
            )
        )
        .blTextStyle(.footnote)
        .foregroundStyle(Color.blSecondaryLabel)
    }

    /// 照片清單在此步驟維持固定順序，以位置識別每格
    var photoGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: photoSize), spacing: BLSpacing.small)],
            spacing: BLSpacing.small
        ) {
            ForEach(Array(store.combinedPhotos.enumerated()), id: \.offset) { index, data in
                MergePhotoTile(
                    data: data,
                    index: index,
                    isSelected: store.selectedPhotoIndices.contains(index)
                ) {
                    store.send(.view(.photoToggled(index)))
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("合併照片挑選") {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    let state: OrderMergeFeature.State = {
        var state = OrderMergeFeature.State(
            primary: LedgerOrder.sampleOrders[0],
            orders: LedgerOrder.sampleOrders,
            dateContext: OrderDateContext(now: LedgerOrder.sampleOrders[0].date, calendar: calendar)
        )
        state.combinedPhotos = Array(repeating: Data(), count: 7)
        state.selectedPhotoIndices = Set(0..<LedgerOrder.maxPhotoCount)
        return state
    }()

    MergePhotoPickerSheet(
        store: Store(initialState: state) {
            OrderMergeFeature()
        }
    )
}
