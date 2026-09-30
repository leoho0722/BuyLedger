//
//  ExchangeRateService.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/26.
//

/// 取得指定基準幣別最新匯率的操作入口；
/// 正式實作在 `liveValue`、測試預設值在 `testValue`、Preview 假資料在 `previewValue`
struct ExchangeRateService: Sendable {

    // MARK: - Properties

    /// 抓取指定基準幣別的最新匯率快照
    ///
    /// - Parameter base: 基準幣別
    /// - Returns: 指定基準幣別的最新匯率快照
    /// - Throws: 缺少金鑰，或服務回報金鑰無效、帳號停用時丟出 `.invalidKey`；
    ///   金鑰含控制字元、URL 無效或傳輸失敗時丟出 `.transport(underlying:)`；
    ///   HTTP 狀態碼非 2xx 時丟出 `.http(statusCode:)`；解碼失敗時丟出 `.decoding(underlying:)`；
    ///   配額用盡時丟出 `.quotaExceeded`；其他服務錯誤時丟出 `.apiError(code:)`
    var fetchLatest: FetchLatest
}

// MARK: - Nested Types

extension ExchangeRateService {

    /// `fetchLatest` 的函式型別
    typealias FetchLatest = @Sendable (
        _ base: CurrencyCode
    ) async throws(APIError) -> FxRateSnapshot
}
