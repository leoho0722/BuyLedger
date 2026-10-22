//
//  SignificantTimeChangeService+Preview.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/3.
//

#if DEBUG

// MARK: - DependencyKey

extension SignificantTimeChangeService {

    /// Preview 使用立即結束的串流，在正式 App 中誤用時偵錯版會立刻中止
    static var previewValue: Self {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "SignificantTimeChangeService.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        return Self(
            changes: {
                AsyncStream {
                    $0.finish()
                }
            }
        )
    }
}

#endif
