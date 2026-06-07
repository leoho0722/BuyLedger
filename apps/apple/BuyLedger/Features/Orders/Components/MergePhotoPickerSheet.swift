//
//  MergePhotoPickerSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/6.
//

import ComposableArchitecture
import SwiftUI

/// 合併流程的照片挑選步驟：兩筆訂單照片合計超過上限時，以格狀縮圖讓使用者勾選要保留的照片 (至多 ``LedgerOrder/maxPhotoCount`` 張)。
///
/// 由 ``OrderMergeCandidateSheet`` 在 ``OrderMergeFeature/Step/selectPhotos`` 步驟內嵌呈現；「繼續」按鈕在外層 toolbar，本 view 只負責縮圖格與勾選狀態。
struct MergePhotoPickerSheet: View {

    // MARK: - View Properties

    @Bindable var store: StoreOf<OrderMergeFeature>

    // MARK: - View Body

    /// 照片挑選步驟的內容：說明文字 + 縮圖格。
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                Text("兩筆訂單共有 \(store.combinedPhotos.count) 張照片，超過上限 \(LedgerOrder.maxPhotoCount) 張；請勾選要保留的照片 (已選 \(store.selectedPhotoIndices.count)/\(LedgerOrder.maxPhotoCount))，按「繼續」帶入合併後的新訂單。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 96), spacing: BLSpacing.small)],
                    spacing: BLSpacing.small
                ) {
                    ForEach(Array(store.combinedPhotos.enumerated()), id: \.offset) { index, data in
                        photoCell(index: index, data: data)
                    }
                }
            }
            .padding(BLSpacing.large)
        }
    }
}

// MARK: - ViewBuilder

private extension MergePhotoPickerSheet {

    /// 單格照片縮圖：點擊 toggle 勾選；已勾選顯示外框與右上角 checkmark。
    /// - Parameters:
    ///   - index: 照片在 ``OrderMergeFeature/State/combinedPhotos`` 中的 index。
    ///   - data: 照片 data。
    /// - Returns: 照片格 view。
    @ViewBuilder
    func photoCell(index: Int, data: Data) -> some View {
        let isSelected = store.selectedPhotoIndices.contains(index)

        Button {
            store.send(.photoToggled(index))
        } label: {
            ZStack(alignment: .topTrailing) {
                photoContent(data: data)
                    .frame(minWidth: 96, minHeight: 96)
                    .aspectRatio(1, contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous)
                            .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 3)
                    }
                    .opacity(isSelected ? 1 : 0.55)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, isSelected ? Color.accentColor : Color.black.opacity(0.35))
                    .font(.system(size: 22))
                    .padding(6)
            }
            .contentShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSelected ? "取消保留這張照片" : "保留這張照片")
    }

    /// 縮圖內容：可解碼時顯示影像，否則顯示 placeholder (寧可空狀態也不顯示假資料)。
    /// - Parameter data: 照片 data。
    /// - Returns: 縮圖內容 view。
    @ViewBuilder
    func photoContent(data: Data) -> some View {
        if let image = Image(photoData: data) {
            image
                .resizable()
                .scaledToFill()
        } else {
            RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous)
                .fill(.quaternary)
                .overlay {
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
        }
    }
}
