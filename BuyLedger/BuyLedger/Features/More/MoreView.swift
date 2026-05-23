//
//  MoreView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 更多分頁的入口畫面。
///
/// 對應設計稿 iPhone 「設定 / 更多」頁與 iPad 工具區塊的入口：以列表形式列出工具與設定子頁面，點擊後 push 到對應子畫面。
///
/// macOS 上採用卡片網格佈局 (避免 iOS 風格 List 顯得陽春)，且不顯示「設定」入口——macOS 的偏好設定改由標準的「BuyLedger > 設定…」(⌘,) 視窗承載。
struct MoreView: View {

    // MARK: - View Properties

    /// App 根層級 store。
    let store: StoreOf<RootFeature>

    /// 目前系統深淺色外觀。
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - View Body

    /// 更多頁的畫面內容。
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)

        NavigationStack {
            #if os(macOS)
            macContent(palette: palette)
            #else
            phoneContent(palette: palette)
            #endif
        }
    }
}

// MARK: - ViewBuilder (共用)

private extension MoreView {

    /// 工具項目的領域定義；同時供 iOS/macOS 兩種佈局使用。
    enum ToolItem: String, CaseIterable, Identifiable {

        // MARK: - Cases

        /// 匯率工具。
        case fx

        /// 客戶名單。
        case customers

        /// 報價試算。
        case quote

        /// 商品類別主檔管理。
        case categories

        /// 付款方式主檔管理。
        case paymentMethods

        // MARK: - Identifiable Properties

        /// 項目的穩定識別值。
        var id: String { rawValue }

        // MARK: - Display Properties

        /// 顯示在卡片或列表上的標題。
        var title: String {
            switch self {
            case .fx:
                "匯率工具"
            case .customers:
                "客戶名單"
            case .quote:
                "報價試算"
            case .categories:
                LookupKind.category.entryTitle
            case .paymentMethods:
                LookupKind.paymentMethod.entryTitle
            }
        }

        /// 卡片副標題 (macOS 才顯示)。
        var subtitle: String {
            switch self {
            case .fx:
                "即時連線 ExchangeRate-API，將外幣換算為 TWD。"
            case .customers:
                "依名稱整理客戶活躍度，快速跳轉到對應訂單。"
            case .quote:
                "輸入成本與費率，即時看到建議售價與毛利。"
            case .categories:
                LookupKind.category.entrySubtitle
            case .paymentMethods:
                LookupKind.paymentMethod.entrySubtitle
            }
        }

        /// 對應的 SF Symbol。
        var systemImage: String {
            switch self {
            case .fx:
                "dollarsign.arrow.circlepath"
            case .customers:
                "person.2"
            case .quote:
                "function"
            case .categories:
                LookupKind.category.systemImage
            case .paymentMethods:
                LookupKind.paymentMethod.systemImage
            }
        }

        /// 圖示色 (依語意 token)。
        /// - Parameter palette: 目前外觀使用的色盤。
        /// - Returns: 對應的色彩。
        func tint(in palette: BLPalette) -> Color {
            switch self {
            case .fx:
                palette.accent
            case .customers:
                palette.purple
            case .quote:
                palette.green
            case .categories:
                palette.orange
            case .paymentMethods:
                palette.red
            }
        }
    }

    /// 將工具項目導向到對應 view。
    /// - Parameter item: 工具項目。
    /// - Returns: 對應目的地 view。
    @ViewBuilder
    func destination(for item: ToolItem) -> some View {
        switch item {
        case .fx:
            FxView(store: store.scope(state: \.fx, action: \.fx))
        case .customers:
            CustomersView(store: store)
        case .quote:
            QuoteView(store: store.scope(state: \.quote, action: \.quote))
        case .categories:
            LookupManagementView(
                store: store.scope(state: \.categoryManagement, action: \.categoryManagement)
            )
        case .paymentMethods:
            LookupManagementView(
                store: store.scope(state: \.paymentMethodManagement, action: \.paymentMethodManagement)
            )
        }
    }
}

// MARK: - ViewBuilder (iOS / iPadOS 列表版本)

private extension MoreView {

    /// iOS / iPadOS 的列表版本：保持 phone-friendly 的 grouped list 風格。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 列表 view。
    func phoneContent(palette: BLPalette) -> some View {
        List {
            Section("工具") {
                NavigationLink {
                    destination(for: .fx)
                } label: {
                    toolRow(.fx, palette: palette)
                }
            }

            Section("管理") {
                NavigationLink {
                    destination(for: .customers)
                } label: {
                    toolRow(.customers, palette: palette)
                }

                NavigationLink {
                    destination(for: .categories)
                } label: {
                    toolRow(.categories, palette: palette)
                }

                NavigationLink {
                    destination(for: .paymentMethods)
                } label: {
                    toolRow(.paymentMethods, palette: palette)
                }

                NavigationLink {
                    destination(for: .quote)
                } label: {
                    toolRow(.quote, palette: palette)
                }
            }

            Section("App") {
                NavigationLink {
                    SettingsView(store: store.scope(state: \.settings, action: \.settings))
                } label: {
                    Label {
                        Text("設定").font(.body.weight(.medium))
                    } icon: {
                        Image(systemName: "gear")
                            .foregroundStyle(palette.secondaryLabel)
                    }
                }
            }
        }
        .navigationTitle("更多")
    }

    /// iOS 列表的單列。
    /// - Parameters:
    ///   - item: 工具項目。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 工具列 view。
    func toolRow(_ item: ToolItem, palette: BLPalette) -> some View {
        Label {
            Text(item.title).font(.body.weight(.medium))
        } icon: {
            Image(systemName: item.systemImage)
                .foregroundStyle(item.tint(in: palette))
        }
    }
}

// MARK: - ViewBuilder (macOS 卡片網格版本)

#if os(macOS)

private extension MoreView {

    /// macOS 的卡片網格版本：放大資訊密度，並使用 BLCard 與 LazyVGrid 取代 phone-style List。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 內容 view。
    func macContent(palette: BLPalette) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BLSpacing.large) {
                header(palette: palette)
                toolGrid(palette: palette)
                settingsHint(palette: palette)
            }
            .padding(.horizontal, BLSpacing.large)
            .padding(.vertical, BLSpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(palette.background)
        .navigationTitle("更多工具")
    }

    /// macOS 內容頂部的標題卡片。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: header view。
    func header(palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            Text("工具與管理")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(palette.label)

            Text("常用的非主流程功能集中在這。偏好設定請改用「BuyLedger > 設定…」或快速鍵 ⌘,。")
                .font(.subheadline)
                .foregroundStyle(palette.secondaryLabel)
                .frame(maxWidth: 640, alignment: .leading)
        }
    }

    /// macOS 工具網格。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 網格 view。
    func toolGrid(palette: BLPalette) -> some View {
        let columns = [
            GridItem(.adaptive(minimum: 280, maximum: 420), spacing: BLSpacing.medium, alignment: .top),
        ]

        return LazyVGrid(columns: columns, spacing: BLSpacing.medium) {
            ForEach(ToolItem.allCases) { item in
                NavigationLink {
                    destination(for: item)
                } label: {
                    toolTile(item, palette: palette)
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// 單張工具卡片。
    /// - Parameters:
    ///   - item: 工具項目。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 卡片 view。
    func toolTile(_ item: ToolItem, palette: BLPalette) -> some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.small) {
                ZStack {
                    RoundedRectangle(cornerRadius: BLRadius.medium, style: .continuous)
                        .fill(item.tint(in: palette).opacity(0.16))
                        .frame(width: 44, height: 44)

                    Image(systemName: item.systemImage)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(item.tint(in: palette))
                }

                Text(item.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(palette.label)
                    .padding(.top, BLSpacing.extraSmall)

                Text(item.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(palette.secondaryLabel)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(item.tint(in: palette))
                }
                .padding(.top, BLSpacing.small)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentShape(Rectangle())
    }

    /// macOS 內容底部的設定提示。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 提示 view。
    func settingsHint(palette: BLPalette) -> some View {
        HStack(alignment: .top, spacing: BLSpacing.small) {
            Image(systemName: "gear")
                .font(.body.weight(.semibold))
                .foregroundStyle(palette.tertiaryLabel)

            VStack(alignment: .leading, spacing: 2) {
                Text("App 設定")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.label)

                Text("外觀、通知與預設幣別位於 macOS 標準的偏好設定視窗。")
                    .font(.footnote)
                    .foregroundStyle(palette.secondaryLabel)
            }

            Spacer(minLength: BLSpacing.medium)

            Text("⌘,")
                .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                .padding(.horizontal, BLSpacing.small)
                .padding(.vertical, BLSpacing.extraSmall)
                .background(palette.fillTertiary)
                .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
        }
        .padding(BLSpacing.medium)
        .background(palette.fillQuaternary)
        .clipShape(RoundedRectangle(cornerRadius: BLRadius.medium, style: .continuous))
    }
}

#endif

// MARK: - Preview

#Preview("更多") {
    MoreView(
        store: Store(initialState: RootFeature.State()) {
            RootFeature()
        }
    )
}
