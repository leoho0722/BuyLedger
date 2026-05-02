//
//  CustomersView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 客戶名單畫面。
///
/// 對應設計稿 iPad / Mac 的「客戶」頁：將訂單依客戶聚合成卡片清單。前 N 名（N 由 ``topHighlightCount`` 控制）顯示為強調卡片，其餘以列表呈現。資料完全衍生自既有訂單，不維護額外狀態。
struct CustomersView: View {

    // MARK: - View Properties

    /// App 根層級 store；用來讀取訂單。
    let store: StoreOf<RootFeature>

    /// 目前系統深淺色外觀。
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - View Body

    /// 客戶名單畫面內容。
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)
        let customers = aggregateCustomers(orders: store.orders.orders)

        ScrollView {
            VStack(alignment: .leading, spacing: BLSpacing.large) {
                if customers.isEmpty {
                    emptyState(palette: palette)
                } else {
                    topThree(customers: customers, palette: palette)
                    customerList(customers: customers, palette: palette)
                }
            }
            .padding(.horizontal, BLSpacing.large)
            .padding(.vertical, BLSpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(palette.background)
        .navigationTitle("客戶名單")
        .task {
            await store.send(.orders(.task)).finish()
        }
    }
}

// MARK: - ViewBuilder

private extension CustomersView {

    /// 沒有訂單時的空狀態。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 空狀態 view。
    func emptyState(palette: BLPalette) -> some View {
        ContentUnavailableView(
            "尚無客戶",
            systemImage: "person.2",
            description: Text("先建立訂單，這裡會自動依客戶彙總統計。")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, BLSpacing.section)
        .background(palette.background)
    }

    /// 強調區塊：累計消費排名前 ``topHighlightCount`` 名的客戶。
    /// - Parameters:
    ///   - customers: 已聚合的客戶清單（依累計消費排序）。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 強調卡片區塊 view。
    func topThree(customers: [CustomerRow], palette: BLPalette) -> some View {
        let topCount = Self.topHighlightCount

        return VStack(alignment: .leading, spacing: BLSpacing.medium) {
            Text("Top \(topCount)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(palette.tertiaryLabel)
                .textCase(.uppercase)

            LazyVGrid(columns: topThreeColumns, spacing: BLSpacing.medium) {
                ForEach(Array(customers.prefix(topCount).enumerated()), id: \.element.id) { index, customer in
                    Button {
                        store.send(.customerSelected(customer.name))
                    } label: {
                        topCard(rank: index + 1, customer: customer, palette: palette)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("查看 \(customer.name) 的訂單")
                }
            }
        }
    }

    /// 單一 Top 卡片。
    /// - Parameters:
    ///   - rank: 名次。
    ///   - customer: 客戶資料。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: Top 卡 view。
    func topCard(rank: Int, customer: CustomerRow, palette: BLPalette) -> some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.small) {
                HStack(spacing: BLSpacing.small) {
                    BLAvatar(name: customer.name, initials: customer.initials, size: 44)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(customer.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(palette.label)

                        HStack(spacing: 4) {
                            if customer.tier == .vip {
                                Text("★ VIP")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(palette.orange)
                            } else {
                                Text(customer.tier.title)
                                    .font(.caption)
                                    .foregroundStyle(palette.secondaryLabel)
                            }

                            Text("·").foregroundStyle(palette.tertiaryLabel)

                            Text("\(customer.orderCount) 單")
                                .font(.caption)
                                .foregroundStyle(palette.secondaryLabel)
                        }
                    }

                    Spacer()

                    rankBadge(rank: rank, palette: palette)
                }

                Divider()

                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("累計消費")
                            .font(.caption)
                            .foregroundStyle(palette.tertiaryLabel)
                            .textCase(.uppercase)

                        Text(formatTwd(customer.totalSpent))
                            .font(.title3.bold())
                            .monospacedDigit()
                            .foregroundStyle(palette.label)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("最近訂單")
                            .font(.caption)
                            .foregroundStyle(palette.tertiaryLabel)
                            .textCase(.uppercase)

                        Text(formatDate(customer.lastOrderDate))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(palette.label)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 名次徽章。
    /// - Parameters:
    ///   - rank: 名次（1 / 2 / 3）。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 名次膠囊 view。
    func rankBadge(rank: Int, palette: BLPalette) -> some View {
        let background: Color
        switch rank {
        case 1: background = palette.orange
        case 2: background = palette.secondaryLabel
        default: background = palette.fillTertiary
        }

        return Text("#\(rank)")
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(background)
            .clipShape(Capsule())
    }

    /// 全部客戶列表。
    /// - Parameters:
    ///   - customers: 已聚合的客戶清單。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 客戶列表 view。
    func customerList(customers: [CustomerRow], palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                Text("全部客戶")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.tertiaryLabel)
                    .textCase(.uppercase)

                Spacer()

                Text("\(customers.count) 位")
                    .font(.footnote)
                    .foregroundStyle(palette.secondaryLabel)
            }

            BLCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(customers.enumerated()), id: \.element.id) { index, customer in
                        Button {
                            store.send(.customerSelected(customer.name))
                        } label: {
                            customerRow(customer: customer, palette: palette)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("查看 \(customer.name) 的訂單")

                        if index < customers.count - 1 {
                            Divider()
                                .padding(.leading, BLSpacing.large + 36 + BLSpacing.small)
                        }
                    }
                }
            }
        }
    }

    /// 單一客戶列。
    /// - Parameters:
    ///   - customer: 客戶資料。
    ///   - palette: 目前外觀使用的色盤。
    /// - Returns: 客戶列 view。
    func customerRow(customer: CustomerRow, palette: BLPalette) -> some View {
        HStack(spacing: BLSpacing.small) {
            BLAvatar(name: customer.name, initials: customer.initials, size: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(customer.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.label)

                HStack(spacing: 4) {
                    Text(customer.tier.title)
                        .font(.caption)
                        .foregroundStyle(customer.tier == .vip ? palette.orange : palette.secondaryLabel)

                    Text("·").foregroundStyle(palette.tertiaryLabel)

                    Text("\(customer.orderCount) 單")
                        .font(.caption)
                        .foregroundStyle(palette.secondaryLabel)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(formatTwd(customer.totalSpent))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(palette.label)

                Text(formatDate(customer.lastOrderDate))
                    .font(.caption)
                    .foregroundStyle(palette.tertiaryLabel)
            }
        }
        .padding(.horizontal, BLSpacing.large)
        .padding(.vertical, BLSpacing.medium)
    }
}

// MARK: - Layout Helper

private extension CustomersView {

    /// 強調區塊顯示的客戶數量；同時驅動 ``topThree(customers:palette:)`` 的標題與 prefix 取數。
    static let topHighlightCount = 3

    /// 強調卡片的欄位設定，依寬度自動 1 / 2 / 3 欄。
    var topThreeColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 240, maximum: 360), spacing: BLSpacing.medium)]
    }
}

// MARK: - Aggregation

/// 客戶名單顯示用的彙總列。
private struct CustomerRow: Identifiable {

    // MARK: - Identifiable Properties

    /// 用客戶姓名當識別值（同名客戶會被聚合成一筆）。
    var id: String { name }

    // MARK: - Data Properties

    /// 客戶姓名。
    let name: String

    /// 顯示在頭像上的姓名縮寫。
    let initials: String

    /// 客戶分級。
    let tier: CustomerTier

    /// 已下訂單數。
    let orderCount: Int

    /// 累計消費（NT$）。
    let totalSpent: Decimal

    /// 最近一筆訂單的日期。
    let lastOrderDate: Date
}

private extension CustomersView {

    /// 將訂單聚合成客戶列。
    /// - Parameter orders: 目前訂單清單。
    /// - Returns: 依累計消費由高到低排序的客戶列。
    func aggregateCustomers(orders: [LedgerOrder]) -> [CustomerRow] {
        let grouped = Dictionary(grouping: orders, by: { $0.customer.name })

        return grouped
            .map { name, list in
                let first = list.first!
                let totalSpent = list.reduce(Decimal.zero) { $0 + $1.summary.revenue }
                let lastDate = list.map(\.date).max() ?? first.date

                return CustomerRow(
                    name: name,
                    initials: first.customer.initials,
                    tier: first.customer.tier,
                    orderCount: list.count,
                    totalSpent: totalSpent,
                    lastOrderDate: lastDate
                )
            }
            .sorted { $0.totalSpent > $1.totalSpent }
    }
}

// MARK: - Formatting

private extension CustomersView {

    /// 將金額格式化為新台幣。
    func formatTwd(_ amount: Decimal) -> String {
        amount.formatted(
            .currency(code: CurrencyCode.twd.code)
                .precision(.fractionLength(0))
                .locale(Locale(identifier: "zh_TW"))
        )
    }

    /// 將日期格式化為「月/日」。
    func formatDate(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .month(.defaultDigits)
                .day(.defaultDigits)
                .locale(Locale(identifier: "zh_TW"))
        )
    }
}

// MARK: - Preview

#Preview("客戶名單") {
    let previewState: RootFeature.State = {
        var state = RootFeature.State()
        state.orders.orders = LedgerOrder.sampleOrders
        return state
    }()

    return NavigationStack {
        CustomersView(
            store: Store(initialState: previewState) {
                RootFeature()
            }
        )
    }
}
