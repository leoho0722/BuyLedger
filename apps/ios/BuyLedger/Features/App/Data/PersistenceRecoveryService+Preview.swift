//
//  PersistenceRecoveryService+Preview.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/28.
//

#if DEBUG

// MARK: - DependencyKey

extension PersistenceRecoveryService {

    /// Preview 使用共用的 Preview Database，不會搬移檔案；誤用時偵錯版會立刻中止
    static var previewValue: Self {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "PersistenceRecoveryService.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        return liveValue
    }
}

#endif
