//
//  DependencyValues+BLUITestLookupOverrides.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/16.
//

import Dependencies
import Foundation

#if DEBUG

// MARK: - Internal Method

extension DependencyValues {

    /// 讓主檔與幣別中繼資料的 Service 使用 UI 測試 container，並可注入讀寫失敗
    ///
    /// - Parameters:
    ///   - configuration: UI 測試設定
    ///   - database: 指向 UI 測試 container 與 store 位置的交易資料庫
    mutating func applyLookupOverrides(
        _ configuration: BLUITestConfiguration,
        database: BuyLedgerDatabase
    ) {
        let shouldFail = configuration.loadFailure == .lookups
        let shouldFailWrites = configuration.shouldFailLookupWrites

        var lookupService = withDependencies {
            $0.buyLedgerDatabase = database
        } operation: {
            LookupService.liveValue
        }
        var currencyMetadataService = withDependencies {
            $0.buyLedgerDatabase = database
            $0.httpClient = BLUITestCurrencyMetadataHTTPClient()
            $0.appConfigurationStore = BLUITestCurrencyMetadataConfigurationStore()
            $0.date = .constant(configuration.referenceDate)
        } operation: {
            CurrencyMetadataService.liveValue
        }

        if shouldFail {
            lookupService.fetchItems = { kind throws(PersistenceError) in
                let source: BLUITestLoadSource
                switch kind {
                case .orderSource:
                    source = .orderSources

                case .category:
                    source = .categories

                case .paymentMethod:
                    source = .paymentMethodInfos

                case .reconciliationStatus:
                    source = .reconciliationStatuses
                }
                throw BLUITestErrorFactory.persistenceLoadFailed(source: source)
            }
            currencyMetadataService.fetchCodes = { () throws(CurrencyMetadataServiceError) in
                throw BLUITestErrorFactory.currencyMetadataLoadFailed(source: .currencyCodes)
            }
            // 刷新也失敗，避免載入失敗時寫入資料
            currencyMetadataService.refreshIfStale = { _ throws(CurrencyMetadataServiceError) in
                throw BLUITestErrorFactory.currencyMetadataLoadFailed(source: .currencyCodes)
            }
        }

        if shouldFailWrites {
            lookupService.addItem = { _, _ throws(PersistenceError) in
                throw BLUITestErrorFactory.persistenceSaveFailed()
            }
            lookupService.removeItem = { _, _ throws(PersistenceError) in
                throw BLUITestErrorFactory.persistenceSaveFailed()
            }
            lookupService.renameItem = { _, _ throws(PersistenceError) in
                throw BLUITestErrorFactory.persistenceSaveFailed()
            }
            lookupService.applyPaymentMethodEdit = { _, _, _ throws(PersistenceError) in
                throw BLUITestErrorFactory.persistenceSaveFailed()
            }
        }

        self.lookupService = lookupService
        self.currencyMetadataService = currencyMetadataService
    }
}

#endif
