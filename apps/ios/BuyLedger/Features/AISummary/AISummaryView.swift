//
//  AISummaryView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/27.
//

import ComposableArchitecture
import SwiftUI
import Textual

/// AI 商品明細總結 sheet
struct AISummaryView: View {

    // MARK: - Properties

    /// 總結功能的 store
    @Bindable var store: StoreOf<AISummaryFeature>

    // MARK: - Body

    /// 總結 sheet 的內容
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                dataTransferDisclosure

                content
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(BLAccessibilityID.AISummary.root)
            }
            .task {
                await store.send(.view(.task)).finish()
            }
            .navigationTitle(Text("AI 商品明細總結"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                closeToolbarItem
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Private Views

private extension AISummaryView {

    /// AI 總結開始前即常駐呈現的第三方雲端資料傳送揭露
    @ViewBuilder
    var dataTransferDisclosure: some View {
        Text("目前列表的商品明細 (類別、品名、數量、單價、幣別) 會送往第三方雲端服務；不含客戶姓名。")
            .blTextStyle(.footnote)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, BLSpacing.small)
            .foregroundStyle(Color.blSecondaryLabel)
            .background(.secondary.opacity(0.08))
            .accessibilityIdentifier(BLAccessibilityID.AISummary.dataTransferDisclosure)
    }

    /// 總結 sheet 的關閉按鈕
    @ToolbarContentBuilder
    var closeToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                store.send(.view(.closeTapped))
            } label: {
                Image(systemName: "xmark")
            }
            .accessibilityLabel(Text("關閉"))
            .accessibilityIdentifier(BLAccessibilityID.AISummary.closeButton)
        }
    }

    /// 依目前串流階段呈現的主內容
    @ViewBuilder
    var content: some View {
        switch store.phase {
        case .failed:
            ContentUnavailableView {
                Label("總結失敗", systemImage: "exclamationmark.triangle")
            } description: {
                Text(store.errorMessage ?? "請稍後再試。")
            } actions: {
                Button("重試") {
                    store.send(.view(.retryTapped))
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier(BLAccessibilityID.AISummary.retryButton)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .idle, .streaming, .finished:
            if store.summaryText.isEmpty {
                VStack(spacing: BLSpacing.medium) {
                    ProgressView()
                    Text("AI 正在分析商品明細…")
                        .blTextStyle(.subhead)
                        .foregroundStyle(Color.blSecondaryLabel)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: BLSpacing.small) {
                        StructuredText(markdown: store.summaryText)
                            .textual.structuredTextStyle(.gitHub)

                        if store.phase == .streaming {
                            HStack(spacing: BLSpacing.extraSmall) {
                                ProgressView()
                                    .controlSize(.small)
                                Text("產生中…")
                                    .blTextStyle(.footnote)
                                    .foregroundStyle(Color.blSecondaryLabel)
                            }
                            .padding(.top, BLSpacing.small)
                        }

                        if let truncationMessage = store.truncationMessage {
                            Text(truncationMessage)
                                .blTextStyle(.footnote)
                                .multilineTextAlignment(.leading)
                                .padding(.top, BLSpacing.small)
                                .foregroundStyle(Color.blSecondaryLabel)
                        }

                        if store.phase == .finished {
                            aiDisclaimerCapsule
                                .padding(.top, BLSpacing.medium)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
            }
        }
    }

    /// 內容生成完成後附在最末的膠囊提醒：告知此為 AI 生成內容、可能有誤
    @ViewBuilder
    var aiDisclaimerCapsule: some View {
        HStack(spacing: BLSpacing.extraSmall) {
            Image(systemName: "sparkles")
                .font(BLTypographyStyle.caption2.font.weight(.semibold))
                .accessibilityHidden(true)

            Text("此內容由 AI 生成，可能包含錯誤資訊，請自行核對。")
                .blTextStyle(.caption)
                .multilineTextAlignment(.leading)
        }
        .padding(.vertical, 7)
        .padding(.horizontal, 14)
        .foregroundStyle(Color.blSecondaryLabel)
        .background(.secondary.opacity(0.12), in: Capsule())
        // frame 保持在 background 外層，避免膠囊背景撐滿整列
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Preview

#Preview("AI 總結串流中") {
    var state = AISummaryFeature.State(prompt: "範例 prompt", model: "gemma4:31b-cloud")
    state.phase = .streaming
    state.summaryText = "# 商品摘要\n\nAI 正在產生內容"

    return AISummaryView(
        store: Store(initialState: state) {
            AISummaryFeature()
        }
    )
}

#Preview("AI 總結失敗") {
    var state = AISummaryFeature.State(prompt: "範例 prompt", model: "gemma4:31b-cloud")
    state.phase = .failed
    state.errorMessage = "總結失敗，請稍後再試。"

    return AISummaryView(
        store: Store(initialState: state) {
            AISummaryFeature()
        }
    )
}

#Preview("AI 總結逾時截斷") {
    var state = AISummaryFeature.State(prompt: "範例 prompt", model: "gemma4:31b-cloud")
    state.phase = .finished
    state.summaryText = "# 商品摘要\n\n已取得的部分內容"
    state.truncationMessage = "AI 總結已達時間上限，以下顯示已取得的內容；摘要已截斷。"

    return AISummaryView(
        store: Store(initialState: state) {
            AISummaryFeature()
        }
    )
}
