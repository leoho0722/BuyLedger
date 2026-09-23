//
//  ActionGroupingScanTests+Scenarios.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/23.
//

import Foundation

// MARK: - Nested Types

extension ActionGroupingScanTests {

    /// 一筆掃描器自我測試案例
    struct ScanScenario: Sendable {

        /// 案例名稱
        let name: String

        /// 要餵給掃描器的原始碼片段
        let source: String

        /// 要執行的掃描規則
        let rule: ScanRule

        /// 是否預期通過掃描
        let shouldPass: Bool

        /// design 指定的全部掃描器自我測試案例
        static let allCases = [
            ScanScenario(
                name: "View 直接送 view action",
                source: "store.send(.view(.task))",
                rule: .viewStoreSend,
                shouldPass: true
            ),
            ScanScenario(
                name: "View await 後完成 view action",
                source: "await store.send(.view(.task)).finish()",
                rule: .viewStoreSend,
                shouldPass: true
            ),
            ScanScenario(
                name: "View 跨行送 view action",
                source: #"""
                store.send(
                    .view(.retryTapped)
                )
                """#,
                rule: .viewStoreSend,
                shouldPass: true
            ),
            ScanScenario(
                name: "View 送 binding action",
                source: #"store.send(.binding(.set(\.isFocused, false)))"#,
                rule: .viewStoreSend,
                shouldPass: false
            ),
            ScanScenario(
                name: "View 送 delegate action",
                source: "store.send(.delegate(.customerSelected(name)))",
                rule: .viewStoreSend,
                shouldPass: false
            ),
            ScanScenario(
                name: "View 註解中的送出點",
                source: "// store.send(.task)",
                rule: .viewStoreSend,
                shouldPass: true
            ),
            ScanScenario(
                name: "Feature 自己送 view action",
                source: "return .send(.view(.task))",
                rule: .reducerChildView,
                shouldPass: true
            ),
            ScanScenario(
                name: "Feature 自己攔截 view action",
                source: "case .view(.task):",
                rule: .reducerChildView,
                shouldPass: true
            ),
            ScanScenario(
                name: "Reducer 送子層 view action",
                source: ".send(.settings(.view(.task)))",
                rule: .reducerChildView,
                shouldPass: false
            ),
            ScanScenario(
                name: "Reducer 攔截子層 view action",
                source: "case .customers(.view(.task)):",
                rule: .reducerChildView,
                shouldPass: false
            ),
        ]
    }
}
