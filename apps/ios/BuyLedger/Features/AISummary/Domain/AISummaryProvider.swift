//
//  AISummaryProvider.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/11/24.
//

/// AI 摘要可用的供應商清單；
/// 新增供應商時加 case，並在 `AISummaryService` 建立該供應商的 chat client、
/// 在 xcconfig 與 Info.plist 補金鑰設定；
/// raw value 是 `settings.aiSummaryProvider` 的儲存格式，改 case 名稱等於改儲存格式
enum AISummaryProvider: String, CaseIterable, Sendable {

    /// Anthropic (Claude 系列模型)
    case anthropic

    // MARK: - Properties

    /// 沒有設定或設定值無法辨識時使用的供應商
    static let `default`: Self = .anthropic
}

// MARK: - Computed Properties

extension AISummaryProvider {

    /// API 金鑰在 Info.plist 中的設定名稱
    var apiKeyConfigurationKey: String {
        switch self {
        case .anthropic:
            "ANTHROPIC_API_KEY"
        }
    }

    /// 沒有指定模型時使用的預設模型
    var defaultModel: String {
        switch self {
        case .anthropic:
            "claude-haiku-5-5"
        }
    }

    /// Debug 模型選單的候選模型，第一個等於預設模型
    var candidateModels: [String] {
        switch self {
        case .anthropic:
            ["claude-haiku-5-5", "claude-sonnet-5-5", "claude-opus-5-5"]
        }
    }
}
