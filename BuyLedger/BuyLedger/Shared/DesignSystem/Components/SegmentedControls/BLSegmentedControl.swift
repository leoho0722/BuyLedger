//
//  BLSegmentedControl.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/4/30.
//

import SwiftUI

/// 使用設計系統表面與填色的分段控制。
struct BLSegmentedControl<Option: Hashable>: View {
    
    // MARK: - View Properties
    
    /// 目前系統深淺色外觀。
    @Environment(\.colorScheme) private var colorScheme
    
    /// 可供選擇的選項。
    let options: [Option]
    
    /// 目前選取選項的雙向繫結。
    @Binding var selection: Option
    
    /// 將選項轉換成顯示文字的 closure。
    let title: (Option) -> String
    
    // MARK: - View Body
    
    /// 分段控制的畫面內容。
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)
        
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                } label: {
                    Text(title(option))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selection == option ? palette.label : palette.secondaryLabel)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 30)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .background(selection == option ? palette.surface : .clear)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 8,
                        style: .continuous
                    )
                )
            }
        }
        .padding(2)
        .background(palette.fillTertiary)
        .clipShape(
            RoundedRectangle(
                cornerRadius: BLRadius.small,
                style: .continuous
            )
        )
    }
}

// MARK: - ViewBuilder

private extension BLSegmentedControl {}

// MARK: - Preview

#Preview("分段控制") {
    VStack(spacing: BLSpacing.large) {
        BLSegmentedControl(
            options: ["日", "週", "月"],
            selection: .constant("週")
        ) { option in
            option
        }
        
        BLSegmentedControl(
            options: ["支出", "收入"],
            selection: .constant("支出")
        ) { option in
            option
        }
    }
    .padding()
}
