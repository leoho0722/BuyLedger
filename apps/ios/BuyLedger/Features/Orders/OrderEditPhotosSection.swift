//
//  OrderEditPhotosSection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture
import PhotosUI
import SwiftUI

/// 訂單照片的縮圖、載入提示與選取入口，只綁定照片子功能
struct OrderEditPhotosSection: View {

    // MARK: - Properties

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<OrderEditPhotosFeature>

    // MARK: - Body

    /// 組合照片內容、計數標題與說明，出現時啟動照片讀取
    var body: some View {
        Section {
            photoContent
        } header: {
            sectionHeader
        } footer: {
            sectionFooter
        }
        // 區段在惰性 `Form` 捲離或推入選擇器時會消失，讀取不隨區段取消，因此不等待 `finish()`
        .task {
            store.send(.view(.task))
        }
    }
}

// MARK: - Private Views

private extension OrderEditPhotosSection {

    /// 依載入階段呈現進度、失敗提示或照片編輯內容
    @ViewBuilder
    var photoContent: some View {
        switch store.photoLoadPhase {
        case .notLoaded, .loading:
            HStack(spacing: BLSpacing.small) {
                ProgressView()

                Text("orders.edit.label.loadingPhotos")
                    .blTextStyle(.subhead)
                    .foregroundStyle(.blSecondaryLabel)
            }

        case .failed:
            Label("orders.edit.message.photosLoadedTry", systemImage: "exclamationmark.triangle")
                .blTextStyle(.subhead)
                .foregroundStyle(.blSecondaryLabel)

        case .loaded:
            loadedPhotos
        }
    }

    /// 已載入的照片縮圖、匯入失敗張數與新增入口
    @ViewBuilder
    var loadedPhotos: some View {
        if !store.draftPhotos.isEmpty {
            ScrollView(.horizontal) {
                HStack(spacing: BLSpacing.small) {
                    ForEach(Array(store.draftPhotos.enumerated()), id: \.offset) { index, data in
                        BLPhotoThumbnail(
                            accessibilityID: BLAccessibilityID.OrderEdit.photoThumbnail(
                                index: index
                            ),
                            imageData: data,
                            onTap: {
                                store.send(.view(.photoTapped(index)))
                            }
                        ) {
                            store.send(.view(.deletePhotoTapped(index)))
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }

        if store.photoImportFailureCount > 0 {
            Label(
                AppLanguage.format(
                    "orders.edit.message.photoImportFailedNotice",
                    store.photoImportFailureCount,
                    locale: locale
                ),
                systemImage: "exclamationmark.triangle"
            )
            .blTextStyle(.subhead)
            .foregroundStyle(.blSecondaryLabel)
        }

        if store.canAddMorePhotos {
            PhotosPicker(
                selection: $store.photoPickerSelection,
                maxSelectionCount: store.remainingPhotoCapacity,
                matching: .images
            ) {
                Label("orders.edit.label.addPhotos", systemImage: "photo.badge.plus")
            }
        }
    }

    /// 照片區段的目前張數與上限
    var sectionHeader: some View {
        Text(
            AppLanguage.format(
                "orders.edit.label.orderPhotosCount",
                store.draftPhotos.count,
                LedgerOrder.maxPhotoCount,
                locale: locale
            )
        )
    }

    /// 照片容量與儲存方式說明
    var sectionFooter: some View {
        Text(
            AppLanguage.format(
                "orders.edit.message.photoLimitNotice",
                LedgerOrder.maxPhotoCount,
                locale: locale
            )
        )
        .blTextStyle(.footnote)
        .foregroundStyle(.blSecondaryLabel)
    }
}

// MARK: - Preview

#Preview("已載入且沒有照片") {
    Form {
        OrderEditPhotosSection(
            store: Store(initialState: OrderEditPhotosFeature.State()) {
                OrderEditPhotosFeature()
            }
        )
    }
}

#Preview("照片載入中") {
    let state: OrderEditPhotosFeature.State = {
        var state = OrderEditPhotosFeature.State(orderID: "BL-PREVIEW")
        state.photoLoadPhase = .loading
        return state
    }()

    Form {
        OrderEditPhotosSection(
            store: Store(initialState: state) {
                OrderEditPhotosFeature()
            }
        )
    }
}

#Preview("照片載入失敗") {
    let state: OrderEditPhotosFeature.State = {
        var state = OrderEditPhotosFeature.State(orderID: "BL-PREVIEW")
        state.photoLoadPhase = .failed
        return state
    }()

    Form {
        OrderEditPhotosSection(
            store: Store(initialState: state) {
                OrderEditPhotosFeature()
            }
        )
    }
}

#Preview("照片匯入失敗") {
    let state: OrderEditPhotosFeature.State = {
        var state = OrderEditPhotosFeature.State()
        state.photoImportFailureCount = 2
        return state
    }()

    Form {
        OrderEditPhotosSection(
            store: Store(initialState: state) {
                OrderEditPhotosFeature()
            }
        )
    }
}
