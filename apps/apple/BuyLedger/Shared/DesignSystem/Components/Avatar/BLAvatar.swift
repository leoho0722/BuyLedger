//
//  BLAvatar.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// 以姓名縮寫產生穩定漸層背景的頭像。
struct BLAvatar: View {

    // MARK: - View Properties

    /// 頭像代表的完整名稱。
    let name: String

    /// 顯示在頭像中的縮寫文字。
    let initials: String

    /// 頭像寬高。
    var size: CGFloat = 36

    // MARK: - View Body

    /// 頭像的畫面內容。
    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.38, weight: .semibold, design: .default))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(gradient)
            .clipShape(Circle())
            .accessibilityLabel(name)
    }
}

// MARK: - Private Method

private extension BLAvatar {

    /// 依名稱產生的穩定漸層。
    var gradient: LinearGradient {
        let hue = hueValue(for: name)

        return LinearGradient(
            colors: [
                Color(hue: hue, saturation: 0.46, brightness: 0.84),
                Color(
                    hue: (hue + 0.11).truncatingRemainder(dividingBy: 1),
                    saturation: 0.52,
                    brightness: 0.68
                ),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 將名稱轉換為穩定色相。
    /// - Parameter name: 用來計算色相的名稱。
    /// - Returns: 介於 `0` 到 `1` 的色相值。
    func hueValue(for name: String) -> Double {
        let total = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return Double(total % 360) / 360
    }
}

// MARK: - Preview

#Preview("頭像") {
    HStack(spacing: BLSpacing.medium) {
        BLAvatar(name: "Leo Ho", initials: "LH")
        BLAvatar(name: "Apple Design", initials: "AD", size: 48)
        BLAvatar(name: "BuyLedger", initials: "BL", size: 64)
    }
    .padding()
}
