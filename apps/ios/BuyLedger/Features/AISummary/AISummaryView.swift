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
    
    // MARK: - View Properties
    
    /// 總結功能的 store
    @Bindable var store: StoreOf<AISummaryFeature>
    
    // MARK: - View Body
    
    /// 總結 sheet 的內容
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                dataTransferDisclosure
                
                content
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(BLAccessibilityID.AISummary.root)
            }
            .navigationTitle(Text("AI 商品明細總結"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.closeTapped)
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(Text("關閉"))
                    .accessibilityIdentifier(BLAccessibilityID.AISummary.closeButton)
                }
            }
            .task {
                await store.send(.task).finish()
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - ViewBuilder

private extension AISummaryView {
    
    /// AI 總結開始前即常駐呈現的第三方雲端資料傳送揭露
    @ViewBuilder
    var dataTransferDisclosure: some View {
        Text("目前列表的商品明細 (類別、品名、數量、單價、幣別) 會送往第三方雲端服務；不含客戶姓名。")
            .blTextStyle(.footnote)
            .foregroundStyle(Color.blSecondaryLabel)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, BLSpacing.small)
            .background(.secondary.opacity(0.08))
            .accessibilityIdentifier(BLAccessibilityID.AISummary.dataTransferDisclosure)
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
                    store.send(.retryTapped)
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
                                .foregroundStyle(Color.blSecondaryLabel)
                                .multilineTextAlignment(.leading)
                                .padding(.top, BLSpacing.small)
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
        .foregroundStyle(Color.blSecondaryLabel)
        .padding(.vertical, 7)
        .padding(.horizontal, 14)
        .background(.secondary.opacity(0.12), in: Capsule())
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

// MARK: - Preview

#Preview("AI 總結") {
    AISummaryView(
        store: Store(
            initialState: AISummaryFeature.State(prompt: "範例 prompt", model: "gemma4:31b-cloud")
        ) {
            AISummaryFeature()
        } withDependencies: {
            $0[OllamaClient.self] = .previewValue
            $0.appConfiguration = .previewValue
        }
    )
}
