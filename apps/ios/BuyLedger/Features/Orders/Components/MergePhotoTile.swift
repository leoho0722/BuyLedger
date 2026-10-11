//
//  MergePhotoTile.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/9.
//

import SwiftUI

/// 合併照片挑選的單格縮圖、選取外框與勾號
struct MergePhotoTile: View {

    // MARK: - Properties

    /// 勾號與照片邊緣的距離，隨字級縮放
    @ScaledMetric(relativeTo: .title3) private var indicatorPadding: CGFloat = 6

    /// 照片格的最小邊長，隨字級縮放
    @ScaledMetric private var photoSize: CGFloat = 96

    /// 要顯示的照片位元組
    let data: Data

    /// 照片在合併清單中的位置
    let index: Int

    /// 目前是否保留這張照片
    let isSelected: Bool

    /// 切換這張照片的保留狀態
    let onToggle: () -> Void

    // MARK: - Body

    /// 可點選的照片格，選取意圖由父層處理
    var body: some View {
        Button(action: onToggle) {
            cellContent
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isSelected ? "orders.general.label.doKeepPhoto" : "orders.general.label.keepPhoto")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier(BLAccessibilityID.OrderMerge.photoCell(index: index))
    }
}

// MARK: - Private Views

private extension MergePhotoTile {

    /// 照片與右上角勾號；選取時以主色描邊，未選取時降低照片透明度
    var cellContent: some View {
        ZStack(alignment: .topTrailing) {
            photoContent
                .frame(minWidth: photoSize, minHeight: photoSize)
                .aspectRatio(1, contentMode: .fill)
                .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous)
                        .strokeBorder(isSelected ? palette.accent : Color.clear, lineWidth: 3)
                }
                .opacity(isSelected ? 1 : 0.55)

            selectionIndicator
        }
        .contentShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
    }

    /// 顯示可解碼的照片，否則顯示照片空狀態
    @ViewBuilder
    var photoContent: some View {
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

    /// 選取勾號，文字標籤已承載語意
    var selectionIndicator: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .padding(indicatorPadding)
            .symbolRenderingMode(.palette)
            .foregroundStyle(.white, isSelected ? palette.accent : Color.black.opacity(0.35))
            // 勾號固定使用一般字重
            .font(BLTypographyStyle.title3.font.weight(.regular))
            .accessibilityHidden(true)
    }
}

// MARK: - Private Method

private extension MergePhotoTile {

    /// 照片格使用的目前外觀色盤
    var palette: BLPalette {
        BLPalette()
    }
}

// MARK: - Preview

#Preview("合併照片格") {
    MergePhotoTile(data: Data(), index: 0, isSelected: true) {
    }
}
