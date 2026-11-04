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

        /// 目前工具的唯一導覽元素，由入口選取決定
        var path = StackState<Path.State>()

        /// 主檔目錄的載入與新增流程，沒有自己的畫面
        var catalog = LookupCatalogFeature.State()

        /// 客戶頁的訂單投影來源，只由根功能寫入
        @Shared var orders: [LedgerOrder]

        /// 建立設定頁使用的偏好投影，只由根功能同步
        var preferences: SettingsSnapshot = .default

        /// 建立設定頁使用的辨識類型投影，只由根功能同步
        var biometryType: BiometricAuthService.BiometryKind = .unavailable

        /// 建立設定頁使用的版本文字
        let appVersion: String

        /// 目前工具對應的入口，由路徑推導；未開啟工具時為 `nil`
        var currentEntry: Entry? {
            guard let element = path.last else {
                return nil
            }
            switch element {
            case .customers:
                return .customers

            case .fx:
                return .fx

            case .lookupManagement(let lookup):
                return .lookup(lookup.kind)

            case .quote:
                return .quote

            case .settings:
                return .settings
            }
        }

        /// 建立此分頁獨立的訂單投影來源
        ///
        /// - Parameter appVersion: 設定頁要呈現的 App 版本
        init(appVersion: String) {
            _orders = Shared<[LedgerOrder]>(value: [])
            self.appVersion = appVersion
        }

        /// 開啟設定頁；設定頁已開啟時保留既有狀態
        mutating func showSettings() {
            open(.settings)
        }

        /// 開啟入口對應的工具：同一工具保留既有狀態，不同工具替換根目的地
        ///
        /// - Parameter entry: 被選取的入口
        mutating func open(_ entry: Entry) {
            guard currentEntry != entry else {
                return
            }
            path.removeAll()
            path.append(makeElement(for: entry))
        }

        /// 清空根目的地，回到入口清單
        mutating func clearDestination() {
            path.removeAll()
        }

        /// 依入口建立唯一導覽元素，工具狀態在每次開啟時重新建立
        ///
        /// - Parameter entry: 要建立的入口
        /// - Returns: 對應入口的導覽元素
        private func makeElement(for entry: Entry) -> Path.State {
            switch entry {
            case .fx:
                .fx(FxFeature.State())

            case .customers:
                .customers(CustomersFeature.State(orders: SharedReader($orders)))

            case .quote:
                .quote(QuoteFeature.State())

            case .lookup(let kind):
                .lookupManagement(LookupManagementFeature.State(kind: kind))

            case .settings:
                .settings(
                    SettingsFeature.State(
                        snapshot: preferences,
                        appVersion: appVersion,
                        biometryType: biometryType
                    )
                )
            }
        }
    }

    // MARK: - Action

    /// 更多頁的入口操作、交給根功能的意圖與子畫面事件
    enum Action {

        /// 更多頁自己送出的操作
        ///
        /// - Parameter action: 使用者選取的入口
        case view(View)

        /// 交給根功能的跨功能意圖
        ///
        /// - Parameter action: 子畫面完成後要轉送的意圖
        case delegate(Delegate)

        /// 更多頁堆疊內的子畫面事件
        ///
        /// - Parameter action: 導覽或子畫面事件
        case path(StackActionOf<Path>)

        /// 主檔目錄子功能的請求與回應
        ///
        /// - Parameter action: 主檔目錄的事件
        case catalog(LookupCatalogFeature.Action)

        /// 根功能要求先確認主檔目錄已讀取，再載入訂單
        case catalogLoadRequested

        /// 根功能要求新增訂單表單的主檔選項
        ///
        /// - Parameter request: 發起表單的識別值、主檔種類與新增項目
        case optionAdditionRequested(LookupAdditionRequest)

        /// 更多頁可送出的使用者操作
        @CasePathable
        enum View: Equatable {

            /// 入口列的選取變更，`nil` 代表使用者離開目前工具
            ///
            /// - Parameter entry: 被選取的入口，`nil` 代表離開
            case entrySelected(Entry?)
        }

        /// 子畫面需要根功能處理的意圖
        @CasePathable
        enum Delegate: Equatable {

            /// 主檔目錄已讀取完成，可以繼續載入訂單
            case catalogLoadFinished

            /// 主檔新增已完成，原樣交回根功能
            ///
            /// - Parameters:
            ///   - request: 原新增請求，保留發起表單的識別值
            ///   - isStored: 是否寫入成功
            case optionAdditionCompleted(request: LookupAdditionRequest, isStored: Bool)

            /// 客戶頁要求載入訂單
            case ordersLoadRequested

            /// 客戶頁選定要查看的客戶
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
    var body: some ReducerOf<Self> {
        Scope(state: \.catalog, action: \.catalog) {
            LookupCatalogFeature()
        }

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

    /// 更多頁的入口，四種主檔共用同一個 `lookup` 入口並以種類區分
    enum Entry: Hashable {

        /// 匯率工具
        case fx

        /// 客戶名單
        case customers

        /// 報價試算
        case quote

        /// 訂單來源、商品類別、付款方式或對帳狀態主檔
        ///
        /// - Parameter kind: 主檔種類
        case lookup(LookupKind)

        /// 設定
        case settings
    }
}

// MARK: - Equatable

extension MoreFeature.Path.State: Equatable {}

// MARK: - Private Method

private extension MoreFeature {

    /// 開啟或清空入口對應的工具，或轉送子畫面的跨功能委派
    ///
    /// - Parameters:
    ///   - state: 更多頁的導覽與投影
    ///   - action: 入口、委派或堆疊事件
    /// - Returns: 要交給根功能的委派，沒有時回傳空效果
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .view(.entrySelected(let entry)):
            if let entry {
                state.open(entry)
            } else {
                state.clearDestination()
            }
            return .none

        case .delegate:
            return .none

        case .path(.element(id: _, action: .customers(.delegate(.ordersLoadRequested)))):
            return .send(.delegate(.ordersLoadRequested))

        case .path(.element(id: _, action: .customers(.delegate(.customerSelected(let name))))):
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

        case .catalog(.delegate(.loadFinished)):
            return .send(.delegate(.catalogLoadFinished))

        case .catalog(.delegate(.additionCompleted(let request, let isStored))):
            return .send(.delegate(.optionAdditionCompleted(request: request, isStored: isStored)))

        case .catalog:
            return .none

        case .catalogLoadRequested:
            return .send(.catalog(.loadRequested))

        case .optionAdditionRequested(let request):
            return .send(.catalog(.additionRequested(request)))
        }
    }
}
