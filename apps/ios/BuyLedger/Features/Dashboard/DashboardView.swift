//
//  DashboardView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 總覽分頁的主要畫面
struct DashboardView: View {

    // MARK: - Properties

    /// 目前的動態字級；用來讓載入骨架的 KPI 格欄數與實際畫面一致
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 月份分組與日期計算使用的行事曆
    @Dependency(\.calendar) private var calendar

    /// 用來計算「本月／上月」與日期子標的「現在」時間；測試可注入固定值
    @Dependency(\.date) private var date

    /// 日期格式化使用的時區；測試可注入固定值
    @Dependency(\.timeZone) private var timeZone

    /// onboarding 圖示尺寸，隨字級縮放 (以 `.largeTitle` 為基準)
    @ScaledMetric(relativeTo: .largeTitle) private var onboardingIconSize: CGFloat = 56

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<DashboardFeature>

    /// App 目前選用的顯示語系
    let language: AppLanguage

    // MARK: - Body

    /// 總覽頁骨架，導覽堆疊內依載入狀態切換內容，進入畫面時觸發載入
    var body: some View {
        // 導覽列由 NavigationStack 建立，測試以畫面根容器判定就緒
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(palette.background)
                .task {
                    // 進入總覽頁時先載入訂單與設定資料
                    // refresh 只轉發，去重由 OrdersFeature 的載入守衛處理
                    await store.send(.task).finish()
                }
                .rootNavigationTitle("總覽", language: language)
        }
    }
}

// MARK: - Private Views

private extension DashboardView {

    /// 首次載入訂單前顯示的骨架
    var loadingPlaceholder: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BLSpacing.large) {
                RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous)
                    .fill(palette.fillTertiary)
                    .frame(height: 180)

                LazyVGrid(
                    columns: DashboardKPITiles.columns(for: dynamicTypeSize),
                    spacing: BLSpacing.small
                ) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous)
                            .fill(palette.fillQuaternary)
                            .frame(height: 88)
                    }
                }

                RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous)
                    .fill(palette.fillQuaternary)
                    .frame(height: 240)
            }
            .padding(.horizontal, BLSpacing.large)
            .padding(.vertical, BLSpacing.large)
        }
        .overlay {
            BLDelayedProgressView()
        }
        .scrollDisabled(true)
        .accessibilityElement()
        .accessibilityLabel(Text("載入中"))
        .accessibilityIdentifier(BLAccessibilityID.Dashboard.loading)
    }

    /// 第一次開 App 還沒有任何訂單時的引導畫面
    var onboardingHero: some View {
        VStack(spacing: BLSpacing.large) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [palette.accent, palette.indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 132, height: 132)

                Image(systemName: "shippingbox.fill")
                    .font(.system(size: onboardingIconSize, weight: .semibold))
                    .foregroundStyle(.white)
            }
            // 純裝飾插圖：訊息由下方文字承載，朗讀符號名稱只是雜訊
            .accessibilityHidden(true)

            VStack(spacing: BLSpacing.small) {
                Text("歡迎使用 BuyLedger")
                    .blTextStyle(.title1)
                    .foregroundStyle(palette.label)

                Text("還沒有任何訂單。建立第一筆，馬上開始追蹤代購損益。")
                    .blTextStyle(.subhead)
                    .foregroundStyle(palette.secondaryLabel)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, BLSpacing.large)

            Button {
                store.send(.delegate(.newOrderTapped))
            } label: {
                Label("建立第一筆訂單", systemImage: "plus")
            }
            .buttonStyle(BLButtonStyle(variant: .primary))
            .accessibilityIdentifier(BLAccessibilityID.Dashboard.emptyStateActionButton)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, BLSpacing.section * 2)
        // 保留子元素 identifier，讓測試可點擊行動按鈕
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(BLAccessibilityID.Dashboard.emptyState)
    }

    /// 大標題上方的日期子標
    var titleHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(currentDateSubtitle)
                .font(BLTypographyStyle.footnote.font.weight(.medium))
                .foregroundStyle(palette.secondaryLabel)
                .accessibilityIdentifier(BLAccessibilityID.Dashboard.currentDateSubtitle)
        }
    }

    /// 依訂單資料顯示總覽或首次使用畫面
    @ViewBuilder
    var overview: some View {
        if store.orders.isEmpty {
            onboardingHero
        } else {
            sections(stats: stats)
        }
    }

    /// 依載入狀態切換的畫面主體：總覽內容、載入失敗或載入骨架
    var content: some View {
        // 依序處理已載入、錯誤與載入中狀態
        // 只判斷「是否已載入」會讓失敗永遠停在轉圈
        // 根 identifier 掛在各 loadState 分支自己的容器上，不掛最外層 group
        // 不合併外層元素，讓重試鈕與內容可被找到
        Group {
            switch store.loadState {
            case .loaded:
                ScrollView {
                    overview
                        .padding(.horizontal, BLSpacing.large)
                        .padding(.vertical, BLSpacing.large)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .accessibilityIdentifier(BLAccessibilityID.Dashboard.root)

            case .failed(let message):
                BLLoadFailureView(
                    message: message,
                    retryIdentifier: BLAccessibilityID.Dashboard.loadFailureRetryButton
                ) {
                    store.send(.retryTapped)
                }
                .accessibilityIdentifier(BLAccessibilityID.Dashboard.loadFailure)

            case .loading:
                loadingPlaceholder
            }
        }
    }

    /// 有訂單時的各區段，由上而下是日期子標、本月摘要、進行中的開團與近期訂單
    ///
    /// - Parameter stats: 已計算的本月統計
    /// - Returns: 各區段 view
    func sections(stats: DashboardStats) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.large) {
            titleHeader

            DashboardSummarySection(language: language, stats: stats)

            DashboardOngoingCampaignsSection(store: store)

            DashboardRecentOrdersSection(recentOrders: stats.recentOrders, store: store)
        }
    }
}

// MARK: - Private Method

private extension DashboardView {

    /// 目前外觀使用的色盤
    var palette: BLPalette {
        BLPalette()
    }

    /// 本月與走勢統計，以注入的現在時間與行事曆計算
    var stats: DashboardStats {
        DashboardStats(
            orders: store.orders,
            monthlyGoal: store.monthlyProfitGoalTwd,
            referenceDate: date(),
            calendar: calendar
        )
    }

    /// 顯示在大標題上方、依 App 選定 locale 格式化的日期子標
    var currentDateSubtitle: String {
        var style = Date.FormatStyle.dateTime
        style.timeZone = timeZone
        style.locale = locale
        style = style
            .month(.wide)
            .day(.defaultDigits)
            .weekday(.wide)
        return date().formatted(style)
    }
}

// MARK: - Preview

#Preview("總覽") {
    let previewState: DashboardFeature.State = {
        var state = DashboardFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.loadState = .loaded
        return state
    }()

    return DashboardView(
        store: Store(initialState: previewState) {
            DashboardFeature()
        },
        language: .traditionalChinese
    )
}

#Preview("載入中") {
    DashboardView(
        store: Store(initialState: DashboardFeature.State()) {
            DashboardFeature()
        },
        language: .traditionalChinese
    )
}

#Preview("載入失敗") {
    let previewState: DashboardFeature.State = {
        var state = DashboardFeature.State()
        state.loadState = .failed("訂單載入失敗，請稍後再試")
        return state
    }()

    return DashboardView(
        store: Store(initialState: previewState) {
            DashboardFeature()
        },
        language: .traditionalChinese
    )
}

#Preview("首次使用") {
    let previewState: DashboardFeature.State = {
        var state = DashboardFeature.State()
        state.loadState = .loaded
        return state
    }()

    return DashboardView(
        store: Store(initialState: previewState) {
            DashboardFeature()
        },
        language: .traditionalChinese
    )
}
