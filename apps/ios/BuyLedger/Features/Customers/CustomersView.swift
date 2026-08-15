//
//  CustomersView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 客戶名單畫面
struct CustomersView: View {
    
    // MARK: - View Properties
    
    /// 客戶彙總功能 store
    let store: StoreOf<CustomersFeature>
    
    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale
    
    // MARK: - View Body
    
    /// 客戶名單畫面內容
    var body: some View {
        let palette = BLPalette()
        let customers = store.customers
        
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
        .navigationTitle(Text("客戶名單"))
        .task {
            await store.send(.task).finish()
        }
        .accessibilityIdentifier(BLAccessibilityID.Customers.listRoot)
    }
}

// MARK: - ViewBuilder

private extension CustomersView {
    
    /// 沒有訂單時的空狀態
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 空狀態 view
    @ViewBuilder
    func emptyState(palette: BLPalette) -> some View {
        ContentUnavailableView(
            "尚無客戶",
            systemImage: "person.2",
            description: Text("先建立訂單，這裡會自動依客戶彙總統計。")
        )
        .frame(maxWidth: .infinity)
        .containerRelativeFrame(.vertical)
        .background(palette.background)
        .accessibilityIdentifier(BLAccessibilityID.Customers.listEmptyState)
    }
    
    /// 強調區塊：累計消費排名前 ``topHighlightCount`` 名的客戶
    /// - Parameters:
    ///   - customers: 已聚合的客戶清單 (依累計消費排序)
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 強調卡片區塊 view
    @ViewBuilder
    func topThree(customers: [CustomerRow], palette: BLPalette) -> some View {
        let topCount = Self.topHighlightCount
        
        VStack(alignment: .leading, spacing: BLSpacing.medium) {
            Text("Top \(topCount)")
                .font(BLTypographyStyle.subhead.font.weight(.semibold))
                .foregroundStyle(palette.secondaryLabel)
                .textCase(.uppercase)
            
            LazyVGrid(columns: topThreeColumns, spacing: BLSpacing.medium) {
                ForEach(Array(customers.prefix(topCount).enumerated()), id: \.element.id) {
                    index, customer in
                    Button {
                        store.send(.delegate(.customerTapped(customer.name)))
                    } label: {
                        topCard(rank: index + 1, customer: customer, palette: palette)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("查看 \(customer.name) 的訂單")
                    .accessibilityIdentifier(
                        BLAccessibilityID.Customers.topCard(customerName: customer.id)
                    )
                    // 累計消費放在 accessibilityValue，UI 測試從 element.value 讀取
                    .accessibilityValue(BLFormatters.twd(customer.totalSpent, locale: locale))
                }
            }
        }
    }
    
    /// 單一 Top 卡片
    /// - Parameters:
    ///   - rank: 名次
    ///   - customer: 客戶資料
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: Top 卡 view
    @ViewBuilder
    func topCard(
        rank: Int,
        customer: CustomerRow,
        palette: BLPalette
    ) -> some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.small) {
                HStack(spacing: BLSpacing.small) {
                    BLAvatar(name: customer.name, initials: customer.initials, size: 44)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(customer.name)
                            .font(BLTypographyStyle.subhead.font.weight(.semibold))
                            .foregroundStyle(palette.label)
                        
                        HStack(spacing: 4) {
                            if customer.tier == .vip {
                                Text("★ VIP")
                                    .font(BLTypographyStyle.caption.font.weight(.semibold))
                                    .foregroundStyle(palette.orange)
                            } else {
                                Text(LocalizedStringKey(customer.tier.title))
                                    .blTextStyle(.caption)
                                    .foregroundStyle(palette.secondaryLabel)
                            }
                            
                            Text("·").foregroundStyle(palette.secondaryLabel)
                            
                            Text("\(customer.orderCount) 單")
                                .blTextStyle(.caption)
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
                            .blTextStyle(.caption)
                            .foregroundStyle(palette.secondaryLabel)
                            .textCase(.uppercase)
                        
                        // 金額由卡片的 accessibilityValue 朗讀，這裡隱藏避免重複
                        Text(BLFormatters.twd(customer.totalSpent, locale: locale))
                            .blTextStyle(.title3Bold)
                            .monospacedDigit()
                            .foregroundStyle(palette.label)
                            .accessibilityHidden(true)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("最近訂單")
                            .blTextStyle(.caption)
                            .foregroundStyle(palette.secondaryLabel)
                            .textCase(.uppercase)
                        
                        Text(formatDate(customer.lastOrderDate))
                            .font(BLTypographyStyle.subhead.font.weight(.semibold))
                            .foregroundStyle(palette.label)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    /// 名次徽章
    /// - Parameters:
    ///   - rank: 名次 (1 / 2 / 3)
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 名次膠囊 view
    @ViewBuilder
    func rankBadge(rank: Int, palette: BLPalette) -> some View {
        let style = CustomerRankBadgeStyle.style(forRank: rank)
        
        Text("#\(rank)")
            .font(BLTypographyStyle.caption.font.weight(.bold))
            .foregroundStyle(style.numeral(in: palette))
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(style.background(in: palette))
            .clipShape(Capsule())
    }
    
    /// 全部客戶列表
    /// - Parameters:
    ///   - customers: 已聚合的客戶清單
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 客戶列表 view
    @ViewBuilder
    func customerList(customers: [CustomerRow], palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.medium) {
            HStack(alignment: .firstTextBaseline) {
                Text("全部客戶")
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .foregroundStyle(palette.secondaryLabel)
                    .textCase(.uppercase)
                
                Spacer()
                
                Text("\(customers.count) 位")
                    .blTextStyle(.footnote)
                    .foregroundStyle(palette.secondaryLabel)
            }
            
            BLCard(padding: 0) {
                LazyVStack(spacing: 0) {
                    ForEach(Array(customers.enumerated()), id: \.element.id) { index, customer in
                        Button {
                            store.send(.delegate(.customerTapped(customer.name)))
                        } label: {
                            customerRow(customer: customer, palette: palette)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("查看 \(customer.name) 的訂單")
                        .accessibilityIdentifier(
                            BLAccessibilityID.Customers.row(customerName: customer.id)
                        )
                        // 累計消費放在 accessibilityValue，UI 測試從 element.value 讀取
                        .accessibilityValue(BLFormatters.twd(customer.totalSpent, locale: locale))
                        
                        if index < customers.count - 1 {
                            Divider()
                                .padding(.leading, BLSpacing.large + 36 + BLSpacing.small)
                        }
                    }
                }
            }
        }
    }
    
    /// 單一客戶列
    /// - Parameters:
    ///   - customer: 客戶資料
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 客戶列 view
    @ViewBuilder
    func customerRow(customer: CustomerRow, palette: BLPalette) -> some View {
        HStack(spacing: BLSpacing.small) {
            BLAvatar(name: customer.name, initials: customer.initials, size: 36)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(customer.name)
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .foregroundStyle(palette.label)
                
                HStack(spacing: 4) {
                    Text(LocalizedStringKey(customer.tier.title))
                        .blTextStyle(.caption)
                        .foregroundStyle(
                            customer.tier == .vip ? palette.orange : palette.secondaryLabel)
                    
                    Text("·").foregroundStyle(palette.secondaryLabel)
                    
                    Text("\(customer.orderCount) 單")
                        .blTextStyle(.caption)
                        .foregroundStyle(palette.secondaryLabel)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                // 金額已放入 accessibilityValue，避免重複朗讀。
                Text(BLFormatters.twd(customer.totalSpent, locale: locale))
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(palette.label)
                    .accessibilityHidden(true)
                
                Text(formatDate(customer.lastOrderDate))
                    .blTextStyle(.caption)
                    .foregroundStyle(palette.secondaryLabel)
            }
        }
        .padding(.horizontal, BLSpacing.large)
        .padding(.vertical, BLSpacing.medium)
    }
}

// MARK: - Private Method

private extension CustomersView {
    
    /// 強調區塊顯示的客戶數量
    static let topHighlightCount = 3
    
    /// 強調卡片的欄位設定，依寬度自動 1 / 2 / 3 欄
    var topThreeColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 240, maximum: 360), spacing: BLSpacing.medium)]
    }
    
    /// 依 App 選定 locale 將日期格式化為短日期
    /// - Parameter date: 日期
    /// - Returns: 依選定 locale 呈現的短日期字串
    func formatDate(_ date: Date) -> String {
        date.formatted(
            .dateTime
                .month(.defaultDigits)
                .day(.defaultDigits)
                .locale(locale)
        )
    }
}

// MARK: - Preview

#Preview("客戶名單") {
    let previewState: CustomersFeature.State = {
        var state = CustomersFeature.State()
        state.orders = LedgerOrder.sampleOrders
        return state
    }()
    
    return NavigationStack {
        CustomersView(
            store: Store(initialState: previewState) {
                CustomersFeature()
            }
        )
    }
}
