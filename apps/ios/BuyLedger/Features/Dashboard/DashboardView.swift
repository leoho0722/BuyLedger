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

    /// App 根層依語言偏好注入的 `locale`
    @Environment(\.locale) private var locale

    /// 骨架中摘要卡的高度，隨字級縮放
    @ScaledMetric private var heroPlaceholderHeight: CGFloat = 180

    /// 骨架中每張 KPI 卡的高度，隨字級縮放
    @ScaledMetric private var kpiPlaceholderHeight: CGFloat = 88

    /// 骨架中清單卡的高度，隨字級縮放
    @ScaledMetric private var listPlaceholderHeight: CGFloat = 240

    /// onboarding 圖示底圓的直徑，與圖示同樣以 `.largeTitle` 為基準縮放
    @ScaledMetric(relativeTo: .largeTitle) private var onboardingCircleSize: CGFloat = 132

    /// onboarding 圖示尺寸，隨字級縮放 (以 `.largeTitle` 為基準)
    @ScaledMetric(relativeTo: .largeTitle) private var onboardingIconSize: CGFloat = 56

    /// 畫面的狀態與事件來源，由父層建立後傳入
    @Bindable var store: StoreOf<DashboardFeature>

    /// App 目前選用的顯示語系
    let language: AppLanguage

    // MARK: - Body

    /// 總覽頁骨架，導覽堆疊內依畫面狀態切換內容，進入畫面時觸發載入
    var body: some View {
        // 導覽列由 `NavigationStack` 建立，測試以畫面根容器判定就緒
        NavigationStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.blBackground)
                .task {
                    // 進入總覽頁時先載入訂單與設定資料
                    // `refresh` 只轉發，去重由 `OrdersLoadFeature` 的載入守衛處理
                    await store.send(.view(.task)).finish()
                }
                .rootNavigationTitle("dashboard.overview.title.overview", language: language)
        }
    }
}

// MARK: - Private Views

private extension DashboardView {

    /// 依畫面狀態切換的主體
    ///
    /// - Note: 狀態來源是 `DashboardFeature.State.screenState`，這裡只讀一次
    /// - Note: 判斷順序為失敗優先；未記錄日期前只顯示骨架，不顯示首次使用或數字
    /// - Note: 根 identifier 掛在各分支自己的容器上，不掛最外層 `Group`
    var content: some View {
        Group {
            switch store.screenState {
            case .loading:
                loadingPlaceholder

            case .failed(let message):
                BLLoadFailureView(
                    message: message,
                    retryIdentifier: BLAccessibilityID.Dashboard.loadFailureRetryButton
                ) {
                    store.send(.view(.retryTapped))
                }
                .accessibilityIdentifier(BLAccessibilityID.Dashboard.loadFailure)

            case .onboarding:
                scrollContainer {
                    onboardingHero
                }

            case .overview(let stats):
                scrollContainer {
                    sections(stats: stats)
                }
            }
        }
    }

    /// 首次載入訂單前顯示的骨架
    var loadingPlaceholder: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BLSpacing.large) {
                RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous)
                    .frame(height: heroPlaceholderHeight)
                    .foregroundStyle(.blFillTertiary)

                LazyVGrid(
                    columns: DashboardKPITiles.columns(for: dynamicTypeSize),
                    spacing: BLSpacing.small
                ) {
                    ForEach(0..<4, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous)
                            .frame(height: kpiPlaceholderHeight)
                            .foregroundStyle(.blFillQuaternary)
                    }
                }

                RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous)
                    .frame(height: listPlaceholderHeight)
                    .foregroundStyle(.blFillQuaternary)
            }
            .padding(.horizontal, BLSpacing.large)
            .padding(.vertical, BLSpacing.large)
        }
        .overlay {
            BLDelayedProgressView()
        }
        .scrollDisabled(true)
        .accessibilityElement()
        .accessibilityLabel(Text("common.action.label.loading"))
        .accessibilityIdentifier(BLAccessibilityID.Dashboard.loading)
    }

    /// 第一次開 App 還沒有任何訂單時的引導畫面
    var onboardingHero: some View {
        VStack(spacing: BLSpacing.large) {
            ZStack {
                Circle()
                    .frame(width: onboardingCircleSize, height: onboardingCircleSize)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blAccent, .blIndigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: "shippingbox.fill")
                    .font(.system(size: onboardingIconSize, weight: .semibold))
                    .foregroundStyle(.white)
            }
            // 純裝飾插圖：訊息由下方文字承載，朗讀符號名稱只是雜訊
            .accessibilityHidden(true)

            VStack(spacing: BLSpacing.small) {
                Text("dashboard.overview.label.welcomeBuyledger")
                    .blTextStyle(.title1)
                    .foregroundStyle(.blLabel)

                Text("dashboard.overview.message.thereOrdersYet")
                    .multilineTextAlignment(.center)
                    .blTextStyle(.subhead)
                    .foregroundStyle(.blSecondaryLabel)
            }
            .padding(.horizontal, BLSpacing.large)

            Button {
                store.send(.view(.newOrderTapped))
            } label: {
                Label("dashboard.overview.label.createFirstOrder", systemImage: "plus")
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

    /// 組出首頁內容的共用捲動容器，onboarding 與總覽都掛同一個根 identifier
    ///
    /// - Parameter content: 捲動容器內的內容
    /// - Returns: 掛有根 identifier 的捲動容器
    func scrollContainer<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        ScrollView {
            content()
                .padding(.horizontal, BLSpacing.large)
                .padding(.vertical, BLSpacing.large)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier(BLAccessibilityID.Dashboard.root)
    }

    /// 組出大標題上方的日期子標，依記錄的日期與行事曆格式化
    ///
    /// - Parameter dateContext: 總覽記錄的現在時間與行事曆
    /// - Returns: 日期子標 view
    func titleHeader(dateContext: DashboardDateContext) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(DashboardFormatters.dateSubtitle(for: dateContext, locale: locale))
                .font(BLTypographyStyle.footnote.font.weight(.medium))
                .foregroundStyle(.blSecondaryLabel)
                .accessibilityIdentifier(BLAccessibilityID.Dashboard.currentDateSubtitle)
        }
    }

    /// 組出有訂單時的各區段，由上而下是日期子標、本月摘要、進行中的開團與近期訂單
    ///
    /// - Parameter stats: 已計算的本月統計
    /// - Returns: 各區段 view
    func sections(stats: DashboardStats) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.large) {
            if let dateContext = store.dateContext {
                titleHeader(dateContext: dateContext)
            }

            DashboardSummarySection(language: language, stats: stats)

            DashboardOngoingCampaignsSection(store: store)

            DashboardRecentOrdersSection(store: store, recentOrders: stats.recentOrders)
        }
    }
}

// MARK: - Preview

#Preview("dashboard.overview.title.overview") {
    let previewState: DashboardFeature.State = {
        var state = DashboardFeature.State()
        state.orders = LedgerOrder.sampleOrders
        state.loadState = .loaded
        state.dateContext = DashboardDateContext(
            now: LedgerOrder.sampleOrders[0].date,
            calendar: Calendar(identifier: .gregorian)
        )
        return state
    }()

    return DashboardView(
        store: Store(initialState: previewState) {
            DashboardFeature()
        },
        language: .traditionalChinese
    )
}

#Preview("common.action.label.loading") {
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
        state.dateContext = DashboardDateContext(
            now: LedgerOrder.sampleOrders[0].date,
            calendar: Calendar(identifier: .gregorian)
        )
        return state
    }()

    return DashboardView(
        store: Store(initialState: previewState) {
            DashboardFeature()
        },
        language: .traditionalChinese
    )
}
