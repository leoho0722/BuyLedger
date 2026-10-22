//
//  SharedKey+LookupCatalog.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/24.
//

import ComposableArchitecture

extension SharedKey where Self == InMemoryKey<LookupCatalog>.Default {

    /// 四種主檔共用、只存在記憶體的目錄鍵值
    static var lookupCatalog: Self {
        Self[.inMemory("lookupCatalog"), default: LookupCatalog()]
    }
}
