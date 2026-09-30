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

    // MARK: - Properties

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 客戶列頭像尺寸，隨 Dynamic Type 縮放
    @ScaledMetric(relativeTo: .body)
    private var customerAvatarSize: CGFloat = CustomerListRow.avatarSize

    /// 訂單投影後的客戶資料來源
    let store: StoreOf<CustomersFeature>

    /// 強調區塊顯示的客戶數量
    private static let topHighlightCount = 3

    // MARK: - Body

    /// 顯示前三名卡片與全部客戶清單
    var body: some View {
        ScrollView {
            content
                .padding(BLSpacing.large)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(palette.background)
        .accessibilityIdentifier(BLAccessibilityID.Customers.listRoot)
        .task {
            await store.send(.view(.task)).finish()
        }
        .navigationTitle(Text("客戶名單"))
    }
}

// MARK: - Private Views

private extension CustomersView {

    /// 客戶資料為空時顯示的內容，或顯示前三名與完整清單
    @ViewBuilder
    var content: some View {
        VStack(alignment: .leading, spacing: BLSpacing.large) {
            if store.customers.isEmpty {
                emptyState
            } else {
                topThree(customers: store.customers)
                customerList(customers: store.customers)
            }
        }
    }

    /// 沒有訂單時的客戶空狀態
    @ViewBuilder
    var emptyState: some View {
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

    /// 強調區塊：累計消費排名前 ``Self.topHighlightCount`` 名的客戶
    ///
    /// - Parameters:
    ///   - customers: 已聚合的客戶清單 (依累計消費排序)
    /// - Returns: 強調卡片區塊
    @ViewBuilder
    func topThree(customers: [CustomerRow]) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.medium) {
            Text("Top \(Self.topHighlightCount)")
                .font(BLTypographyStyle.subhead.font.weight(.semibold))
                .foregroundStyle(palette.secondaryLabel)
                .textCase(.uppercase)

            LazyVGrid(columns: topThreeColumns, spacing: BLSpacing.medium) {
                ForEach(
                    Array(customers.prefix(Self.topHighlightCount).enumerated()),
                    id: \.element.id
                ) { index, customer in
                    Button {
                        store.send(.view(.customerTapped(customer.name)))
                    } label: {
                        CustomerTopCard(rank: index + 1, customer: customer)
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

    /// 單一 Top 客戶卡片
    /// 顯示全部客戶與各列的訂單摘要
    ///
    /// - Parameters:
    ///   - customers: 已聚合的客戶清單
    /// - Returns: 客戶列表
    @ViewBuilder
    func customerList(customers: [CustomerRow]) -> some View {
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
                            store.send(.view(.customerTapped(customer.name)))
                        } label: {
                            CustomerListRow(customer: customer)
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
                                .padding(
                                    .leading,
                                    CustomerListRow.dividerInset(avatarSize: customerAvatarSize)
                                )
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Private Method

private extension CustomersView {

    /// 目前外觀使用的色盤
    var palette: BLPalette {
        BLPalette()
    }

    /// 強調卡片的欄位設定，依寬度自動 1 / 2 / 3 欄
    var topThreeColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 240, maximum: 360), spacing: BLSpacing.medium)]
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

#Preview("客戶名單空狀態") {
    NavigationStack {
        CustomersView(
            store: Store(initialState: CustomersFeature.State()) {
                CustomersFeature()
            }
        )
    }
}
