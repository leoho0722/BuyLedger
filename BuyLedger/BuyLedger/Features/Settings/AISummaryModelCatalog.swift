//
//  AISummaryModelCatalog.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/27.
//

import Foundation

/// AI 商品明細總結使用的 Ollama 模型目錄。
///
/// `defaultModel` 是 Release 固定使用、也是初次啟動的預設值；`candidates` 僅供 Debug build 的模型切換 sheet 當建議清單，使用者仍可自訂輸入。
enum AISummaryModelCatalog {

    // MARK: - Static Properties

    /// AI 總結預設使用的模型。
    nonisolated static let defaultModel = "gemma4:31b-cloud"

    /// Debug 模型切換 sheet 的建議候選清單。
    nonisolated static let candidates: [String] = [
        "gemma4:31b-cloud",
        "gpt-oss:120b-cloud"
    ]
}
