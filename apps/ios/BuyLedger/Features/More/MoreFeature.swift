//
//  MoreFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/3.
//

import ComposableArchitecture

/// 更多分頁的殼層導覽，建立子畫面並轉送跨功能委派
@Reducer
struct MoreFeature {

    // MARK: - State

    /// 更多頁常駐的導覽與根功能提供的投影
    @ObservableState
    struct State: Equatable {

        /// 目前推入的子畫面，返回時釋放該畫面狀態
        var path = StackState<Path.State>()

        /// 客戶頁的訂單投影來源，只由根功能寫入
        @Shared var orders: [LedgerOrder]

        /// 建立設定頁使用的偏好投影，只由根功能同步
        var preferences: SettingsSnapshot = .default

        /// 建立設定頁使用的辨識類型投影，只由根功能同步
        var biometryType: BiometricAuthService.BiometryKind = .unavailable

        /// 建立設定頁使用的版本文字
        let appVersion: String

        /// 建立此分頁獨立的訂單投影來源
        ///
        /// - Parameter appVersion: 設定頁要呈現的 App 版本
        init(appVersion: String) {
            _orders = Shared<[LedgerOrder]>(value: [])
            self.appVersion = appVersion
        }

        /// 依被點擊的入口推入對應的子畫面；設定入口會先清空既有堆疊
        ///
        /// - Parameter entry: 被點擊的入口
        mutating func push(_ entry: Entry) {
            switch entry {
            case .fx:
                path.append(.fx(FxFeature.State()))

            case .customers:
                path.append(.customers(CustomersFeature.State(orders: SharedReader($orders))))

            case .quote:
                path.append(.quote(QuoteFeature.State()))

            case .orderSources:
                path.append(.lookupManagement(LookupManagementFeature.State(kind: .orderSource)))

            case .categories:
                path.append(.lookupManagement(LookupManagementFeature.State(kind: .category)))

            case .paymentMethods:
                path.append(.lookupManagement(LookupManagementFeature.State(kind: .paymentMethod)))

            case .reconciliationStatuses:
                path.append(
                    .lookupManagement(LookupManagementFeature.State(kind: .reconciliationStatus))
                )

            case .settings:
                showSettings()
            }
        }

        /// 清空既有堆疊，再以目前投影推入唯一設定頁
        mutating func showSettings() {
            path.removeAll()
            path.append(
                .settings(
                    SettingsFeature.State(
                        snapshot: preferences,
                        appVersion: appVersion,
                        biometryType: biometryType
                    )
                )
            )
        }

        /// 切離更多頁前清空導覽堆疊
        mutating func popToRoot() {
            path.removeAll()
        }
    }

    // MARK: - Action

    /// 更多頁的入口操作、交給根功能的意圖與子畫面事件
    enum Action {

        /// 更多頁自己送出的操作
        ///
        /// - Parameter action: 使用者點擊的入口
        case view(View)

        /// 交給根功能的跨功能意圖
        ///
        /// - Parameter action: 子畫面完成後要轉送的意圖
        case delegate(Delegate)

        /// 更多頁堆疊內的子畫面事件
        ///
        /// - Parameter action: 導覽或子畫面事件
        case path(StackActionOf<Path>)

        /// 更多頁可送出的使用者操作
        @CasePathable
        enum View: Equatable {

            /// 使用者點擊工具、管理項目或設定列
            ///
            /// - Parameter entry: 被點擊的入口
            case entryTapped(Entry)
        }

        /// 子畫面需要根功能處理的意圖
        @CasePathable
        enum Delegate: Equatable {

            /// 客戶頁要求載入訂單
            case ordersLoadRequested

            /// 客戶頁已清空堆疊並選定要查看的客戶
            ///
            /// - Parameter name: 客戶名稱
            case customerSelected(String)

            /// 指定種類的主檔已改名
            ///
            /// - Parameters:
            ///   - kind: 發出改名的主檔種類
            ///   - rename: 原名與新名
            case lookupItemRenamed(kind: LookupKind, rename: LookupItemRename)

            /// 付款方式更正已寫入完成
            ///
            /// - Parameter plan: 已正規化的寫入內容
            case paymentMethodEdited(PaymentMethodEditPlan)

            /// 設定頁已保存完整偏好
            ///
            /// - Parameter snapshot: 此次實際保存的偏好
            case preferencesChanged(SettingsSnapshot)
        }
    }

    // MARK: - Body

    /// 組合分頁邏輯與堆疊子畫面，元素移除時由 TCA 取消子畫面的 effect
    var body: some Reducer<State, Action> {
        Reduce(core)
            .forEach(\.path, action: \.path)
    }
}

// MARK: - Nested Types

extension MoreFeature {

    /// 更多頁可以推入的五種子畫面
    @Reducer
    enum Path {

        /// 客戶名單
        ///
        /// - Parameter feature: 讀取訂單投影的客戶功能
        case customers(CustomersFeature)

        /// 匯率工具
        ///
        /// - Parameter feature: 每次進入重新建立的匯率功能
        case fx(FxFeature)

        /// 四種主檔共用的管理畫面
        ///
        /// - Parameter feature: 帶有主檔種類的管理功能
        case lookupManagement(LookupManagementFeature)

        /// 報價試算
        ///
        /// - Parameter feature: 每次進入重新建立的報價功能
        case quote(QuoteFeature)

        /// 設定頁
        ///
        /// - Parameter feature: 由目前偏好與裝置資料建立的設定功能
        case settings(SettingsFeature)
    }

    /// 更多頁八個入口，順序與 accessibility 列識別型別一致
    enum Entry: Equatable {

        /// 匯率工具
        case fx

        /// 客戶名單
        case customers

        /// 報價試算
        case quote

        /// 訂單來源主檔
        case orderSources

        /// 商品類別主檔
        case categories

        /// 付款方式主檔
        case paymentMethods

        /// 對帳狀態主檔
        case reconciliationStatuses

        /// 設定
        case settings
    }
}

// MARK: - Equatable

extension MoreFeature.Path.State: Equatable {}

// MARK: - Private Method

private extension MoreFeature {

    /// 建立入口目的地，或轉送子畫面的跨功能委派
    ///
    /// - Parameters:
    ///   - state: 更多頁的導覽與投影
    ///   - action: 入口、委派或堆疊事件
    /// - Returns: 要交給根功能的委派，沒有時回傳空效果
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .view(.entryTapped(let entry)):
            state.push(entry)
            return .none

        case .delegate:
            return .none

        case .path(.element(id: _, action: .customers(.delegate(.ordersLoadRequested)))):
            return .send(.delegate(.ordersLoadRequested))

        case .path(.element(id: _, action: .customers(.delegate(.customerSelected(let name))))):
            state.path.removeAll()
            return .send(.delegate(.customerSelected(name)))

        case .path(
            .element(id: let id, action: .lookupManagement(.delegate(.itemRenamed(let rename))))
        ):
            guard let kind = state.path[id: id, case: \.lookupManagement]?.kind else {
                return .none
            }
            return .send(.delegate(.lookupItemRenamed(kind: kind, rename: rename)))

        case .path(
            .element(id: _, action: .lookupManagement(.delegate(.paymentMethodEdited(let plan))))
        ):
            return .send(.delegate(.paymentMethodEdited(plan)))

        case .path(
            .element(id: _, action: .settings(.delegate(.preferencesChanged(let snapshot))))
        ):
            return .send(.delegate(.preferencesChanged(snapshot)))

        case .path:
            return .none
        }
    }
}
