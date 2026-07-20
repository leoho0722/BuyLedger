//
//  BLAvatar.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// 以姓名縮寫產生穩定漸層背景的頭像
struct BLAvatar: View {

    // MARK: - View Properties

    /// 頭像代表的完整名稱
    let name: String

    /// 顯示在頭像中的縮寫文字
    let initials: String

    /// 頭像寬高
    var size: CGFloat = 36

    /// 是否僅作裝飾
    ///
    /// 與姓名同列時傳 `true`：姓名已由相鄰文字朗讀，頭像再朗讀一次只是重複
    var isDecorative: Bool = false

    // MARK: - View Body

    /// 頭像的畫面內容
    var body: some View {
        Text(initials)
            .font(.system(size: size * 0.38, weight: .semibold, design: .default))
            .minimumScaleFactor(0.6)
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(gradient)
            .clipShape(Circle())
            .accessibilityLabel(name)
            .accessibilityHidden(isDecorative)
    }
}

// MARK: - Internal Method

extension BLAvatar {

    /// 將名稱轉換為穩定色相
    ///
    /// 色相推導是頭像識別性的來源，任何配色調整都不得改動這段
    /// - Parameter name: 用來計算色相的名稱
    /// - Returns: 介於 `0` 到 `1` 的色相值
    static func hueValue(for name: String) -> Double {
        let total = name.unicodeScalars.reduce(0) { $0 + Int($1.value) }
        return Double(total % 360) / 360
    }

    /// 回傳指定色相對應的漸層兩端色彩
    ///
    /// 明度壓低到讓白色縮寫在任一色相下都達到 4.5:1，色相本身不動
    /// - Parameter hue: 介於 `0` 到 `1` 的色相值
    /// - Returns: 由左上到右下的漸層端點色彩
    static func gradientColors(forHue hue: Double) -> [Color] {
        [
            Color(hue: hue, saturation: 0.58, brightness: 0.47),
            Color(
                hue: (hue + 0.11).truncatingRemainder(dividingBy: 1),
                saturation: 0.64,
                brightness: 0.31
            ),
        ]
    }
}

// MARK: - Private Method

private extension BLAvatar {

    /// 依名稱產生的穩定漸層
    var gradient: LinearGradient {
        LinearGradient(
            colors: Self.gradientColors(forHue: Self.hueValue(for: name)),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
