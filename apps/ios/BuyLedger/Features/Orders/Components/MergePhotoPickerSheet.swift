//
//  MergePhotoPickerSheet.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/6/6.
//

import ComposableArchitecture
import SwiftUI

/// 合併照片挑選畫面；最多保留 maxPhotoCount 張
struct MergePhotoPickerSheet: View {
    
    // MARK: - View Properties
    
    @Bindable var store: StoreOf<OrderMergeFeature>
    
    // MARK: - View Body
    
    /// 照片挑選步驟的內容：說明文字 + 縮圖格
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                Text(
                    """
                    兩筆訂單共有 \(store.combinedPhotos.count) 張照片，超過上限 \(LedgerOrder.maxPhotoCount) 張；\
                    請勾選要保留的照片 (已選 \(store.selectedPhotoIndices.count)/\
                    \(LedgerOrder.maxPhotoCount))，\
                    按「繼續」帶入合併後的新訂單。
                    """
                )
                .blTextStyle(.footnote)
                .foregroundStyle(Color.blSecondaryLabel)
                
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
    
    /// 單格照片縮圖：點擊 toggle 勾選；已勾選顯示外框與右上角 checkmark
    /// - Parameters:
    ///   - index: 照片在 ``OrderMergeFeature/State/combinedPhotos`` 中的 index
    ///   - data: 照片 data
    /// - Returns: 照片格 view
    @ViewBuilder
    func photoCell(index: Int, data: Data) -> some View {
        let isSelected = store.selectedPhotoIndices.contains(index)
        let palette = BLPalette()
        
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
                            .strokeBorder(isSelected ? palette.accent : Color.clear, lineWidth: 3)
                    }
                    .opacity(isSelected ? 1 : 0.55)
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(
                        .white, isSelected ? palette.accent : Color.black.opacity(0.35)
                    )
                // 保持圖示為一般字重。
                    .font(.title3)
                    .padding(6)
                // 外層 accessibilityLabel 已涵蓋語意，勾號不需朗讀
                    .accessibilityHidden(true)
            }
            .contentShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSelected ? "取消保留這張照片" : "保留這張照片")
        // 以標準選取特徵表達狀態。
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(BLAccessibilityID.OrderMerge.photoCell(index: index))
    }
    
    /// 顯示可解碼的照片，否則顯示 placeholder
    /// - Parameter data: 照片 data
    /// - Returns: 縮圖內容 view
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
                        .foregroundStyle(Color.blSecondaryLabel)
                }
        }
    }
}
