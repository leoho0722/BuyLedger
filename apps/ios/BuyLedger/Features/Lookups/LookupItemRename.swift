//
//  LookupItemRename.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/24.
//

import Foundation

/// 一次主檔改名的舊名稱與新名稱
struct LookupItemRename: Equatable, Sendable {

    // MARK: - Properties

    /// 尚未更改的主檔名稱
    let oldName: String

    /// 已去除前後空白的新主檔名稱
    let newName: String
}
