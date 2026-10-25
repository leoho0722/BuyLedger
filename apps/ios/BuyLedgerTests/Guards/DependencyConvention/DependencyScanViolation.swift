//
//  DependencyScanViolation.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/28.
//

/// 依賴規範掃描器回報的一筆規則違規
struct DependencyScanViolation: Sendable {

    // MARK: - Properties

    /// 違規檔案相對於根目錄的位置
    let file: String

    /// 違規所在的 1 起算行號
    let line: Int

    /// 原樣放進失敗訊息的命中程式碼
    let reference: String

    /// 被違反的規則，寫成一句「不得…」或「必須…」的規則句，原樣放進失敗訊息
    let reason: String
}

// MARK: - Computed Properties

extension DependencyScanViolation {

    /// 組成檔案、行號、引用內容與原因的單行診斷文字
    var diagnostic: String {
        "\(file):\(line): \(reference): \(reason)"
    }
}
