//
//  ActionGroupingScanTests+Scenarios.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/23.
//

// MARK: - Nested Types

extension ActionGroupingScanTests {

    /// 一筆掃描器自我測試案例
    struct ScanScenario: Sendable {

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
                name: "子層 store 送 view action",
                source: #"addStore.send(.view(.task))"#,
                rule: .viewStoreSend,
                shouldPass: true
            ),
            ScanScenario(
                name: "子層 store 送非 view action",
                source: #"renameStore.send(.draftChanged("名稱"))"#,
                rule: .viewStoreSend,
                shouldPass: false
            ),
            ScanScenario(
                name: "相似 store 名稱不誤判",
                source: #"""
                restoreSend(.draftChanged("名稱"))
                restore.send(.draftChanged("名稱"))
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
            ScanScenario(
                name: "Root 送訂單載入請求",
                source: ".send(.orders(.loadRequested))",
                rule: .reducerChildView,
                shouldPass: true
            ),
            ScanScenario(
                name: "Root 送訂單畫面出現 action",
                source: ".send(.orders(.view(.task)))",
                rule: .reducerChildView,
                shouldPass: false
            ),
        ]

        /// 供測試失敗訊息辨識此案例的描述
        let name: String

        /// 要餵給掃描器的原始碼片段
        let source: String

        /// 要執行的掃描規則
        let rule: ScanRule

        /// 是否預期通過掃描
        let shouldPass: Bool

        /// 掃描規則為 View 送出點的案例
        static var viewStoreSendCases: [ScanScenario] {
            allCases.filter { $0.rule == .viewStoreSend }
        }

        /// 掃描規則為 reducer 子層 view action 的案例
        static var reducerChildViewCases: [ScanScenario] {
            allCases.filter { $0.rule == .reducerChildView }
        }
    }
}
