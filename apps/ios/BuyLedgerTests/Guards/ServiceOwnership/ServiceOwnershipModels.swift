//
//  ServiceOwnershipModels.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/16.
//

import Foundation

/// 服務擁有權守門使用的原始碼片段、服務宣告、掃描結果、違規與案例資料型別
enum ServiceOwnershipModels {}

// MARK: - Nested Types

extension ServiceOwnershipModels {

    /// 正式原始碼或記憶體片段，相對路徑以 App 原始碼目錄為根
    struct SourceFile: Sendable {

        /// App 原始碼目錄下的相對路徑
        let path: String

        /// 原始文字，掃描時會清空註解與字串
        let contents: String
    }

    /// 依賴擴充中的一筆服務宣告
    struct ServiceDeclaration: Sendable {

        /// `DependencyValues` 的服務鍵值
        let key: String

        /// 服務的型別名稱
        let typeName: String

        /// 宣告所在檔案的相對路徑
        let file: String

        /// 擁有服務的功能名稱，共用服務為 `nil`
        let owner: String?

        /// 是否以資料庫為下層，即宣告檔取得 `buyLedgerDatabase` 依賴
        let isDatabaseBacked: Bool
    }

    /// 服務宣告清單與三條守門規則的結果
    struct ScanResult: Sendable {

        /// 收集到的服務宣告，依檔案與鍵值排序
        let services: [ServiceDeclaration]

        /// 跨功能服務引用，依檔案與行號排序
        let foreignReferences: [ReferenceViolation]

        /// 同一功能的重複資料庫服務，依功能名稱排序
        let duplicateDatabaseServices: [DatabaseViolation]

        /// 訂單功能以可寫入形式取得的主檔目錄，依檔案與行號排序
        let writableLookupCatalogs: [ReferenceViolation]
    }

    /// 跨功能服務引用或可寫入主檔目錄的診斷內容
    struct ReferenceViolation: Equatable, Sendable {

        /// 引用所在檔案的相對路徑
        let file: String

        /// 違規起始位置的行號，從 1 起算
        let line: Int

        /// 被其他功能引用的服務鍵值，或可寫入的共享鍵 `lookupCatalog`
        let key: String
    }

    /// 同一功能存在多個資料庫服務的診斷內容
    struct DatabaseViolation: Equatable, Sendable {

        /// 擁有重複資料庫服務的功能
        let feature: String

        /// 去重並排序後的服務型別名稱
        let services: [String]
    }

    /// 引用規則的片段輸入與字面值預期
    struct ReferenceCase: Sendable {

        /// 要加入既有服務宣告清單的原始碼片段
        let file: SourceFile

        /// 預期的檔案、行號與服務鍵值
        let expected: [ReferenceViolation]
    }

    /// 資料庫服務數量規則的片段輸入與字面值預期
    struct DatabaseCase: Sendable {

        /// 同時掃描的服務宣告檔
        let files: [SourceFile]

        /// 預期的功能與重複服務名稱
        let expected: [DatabaseViolation]
    }

    /// 原始碼根目錄或服務宣告不足時的掃描錯誤
    enum ScanError: Error {

        /// 根目錄不存在、不是目錄或無法列舉
        ///
        /// - Parameter path: 無法掃描的根目錄路徑
        case sourceRootNotFound(path: String)

        /// 原始碼沒有適用的服務宣告
        case noServiceDeclarations
    }
}
