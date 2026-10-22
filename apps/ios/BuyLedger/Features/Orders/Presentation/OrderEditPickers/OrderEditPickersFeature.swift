//
//  OrderEditPickersFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/8.
//

import ComposableArchitecture

/// 管理訂單編輯的選項清單與選擇器路由，草稿選取交由父層套用
@Reducer
struct OrderEditPickersFeature {

    // MARK: - State

    /// 選項選擇器的清單與目前推入的路由
    @ObservableState
    struct State: Equatable, Sendable {

        /// 已補齊草稿使用值並完成去重與排序的選項
        var options: OrderEditOptions

        /// 目前推入的選擇器或照片檢視器；`nil` 代表未開啟
        var pickerRoute: PickerRoute?

        /// 以開啟表單時的草稿快照補齊選項清單
        ///
        /// - Parameters:
        ///   - options: 父層注入的選項清單
        ///   - draft: 只供初始化整理使用的草稿快照
        init(options: OrderEditOptions = .empty, draft: OrderDraft) {
            self.options = OrderEditOptionNormalizer.normalized(options: options, draft: draft)
        }

        /// 訂單編輯表單內可推入的選擇器與照片檢視器
        enum PickerRoute: Hashable {

            /// 訂單來源選擇器
            case orderSource

            /// 商品類別選擇器
            case category

            /// 開團選擇器 (合併情境多選)
            case campaign

            /// 付款方式選擇器
            case paymentMethod

            /// 對帳狀態選擇器
            case reconciliationStatus

            /// 幣別選擇器
            case currency

            /// 照片檢視器，以推入方式呈現，避免重疊兩層表單
            ///
            /// - Parameter index: 要檢視的照片位置
            case photoViewer(index: Int)
        }
    }

    // MARK: - Action

    /// 選擇器的繫結、畫面操作與交給父層的選取請求
    enum Action: BindableAction, Equatable {

        /// 選擇器路由的雙向繫結事件
        ///
        /// - Parameter action: 被修改的欄位與新值
        case binding(BindingAction<State>)

        /// 使用者在選擇器上的操作
        ///
        /// - Parameter action: 畫面送出的選項事件
        case view(View)

        /// 交給父層寫入草稿或新增主檔的請求
        ///
        /// - Parameter action: 父層需要套用的選取結果
        case delegate(Delegate)

        /// 使用者開啟選擇器、選取或新增選項
        @CasePathable
        enum View: Equatable {

            /// 使用者透過「新增來源」彈窗確認新增一筆訂單來源名稱
            ///
            /// - Parameter name: 尚未去除前後空白的來源名稱
            case addOrderSourceTapped(String)

            /// 使用者透過「新增類別」彈窗確認新增一筆類別名稱
            ///
            /// - Parameter name: 尚未去除前後空白的類別名稱
            case addCategoryTapped(String)

            /// 單選模式下選擇一個商品類別 (覆寫為單元素陣列)
            ///
            /// - Parameter name: 被選擇的類別名稱
            case categorySelected(String)

            /// 合併情境下切換一個商品類別的選取狀態
            ///
            /// - Parameter name: 被切換的類別名稱
            case categoryToggled(String)

            /// 單選模式下選擇一個開團；空字串代表未歸團
            ///
            /// - Parameter name: 被選擇的開團名稱
            case campaignSelected(String)

            /// 合併情境下切換一個開團的選取狀態
            ///
            /// - Parameter name: 被切換的開團名稱
            case campaignToggled(String)

            /// 確認新增付款方式及其旗標
            ///
            /// - Parameters:
            ///   - name: 尚未去除前後空白的付款方式名稱
            ///   - flags: 付款方式的分類旗標
            case addPaymentMethodTapped(name: String, flags: PaymentMethodFlags)

            /// 使用者透過「新增對帳狀態」彈窗確認新增一筆對帳狀態名稱
            ///
            /// - Parameter name: 尚未去除前後空白的對帳狀態名稱
            case addReconciliationStatusTapped(String)

            /// 使用者點擊「訂單來源」列，開啟來源選擇頁
            case orderSourcePickerTapped

            /// 使用者點擊「商品類別」列，開啟類別選擇頁
            case categoryPickerTapped

            /// 使用者點擊「開團」列 (合併情境)，開啟開團多選頁
            case campaignPickerTapped

            /// 使用者點擊「幣別」列，開啟幣別選擇頁
            case currencyPickerTapped

            /// 使用者點擊「付款方式」列，開啟付款方式選擇頁
            case paymentMethodPickerTapped

            /// 使用者點擊「對帳狀態」列，開啟對帳狀態選擇頁
            case reconciliationStatusPickerTapped

            /// 使用者在來源選擇頁選定訂單來源
            ///
            /// - Parameter source: 被選定的訂單來源名稱
            case orderSourceSelected(String)

            /// 使用者在付款方式選擇頁選定付款方式
            ///
            /// - Parameter method: 被選定的付款方式名稱
            case paymentMethodSelected(String)

            /// 使用者在對帳狀態選擇頁選定對帳狀態
            ///
            /// - Parameter status: 被選定的對帳狀態名稱
            case reconciliationStatusSelected(String)

            /// 使用者在幣別選擇頁選定幣別 (以 ISO 4217 代碼傳入)
            ///
            /// - Parameter code: 被選定的幣別代碼
            case currencySelected(String)
        }

        /// 選取結果與需要新增主檔的名稱，父層自行套用草稿
        @CasePathable
        enum Delegate: Equatable {

            /// 單選訂單來源
            ///
            /// - Parameter name: 被選定的來源名稱
            case orderSourceSelected(String)

            /// 單選商品類別
            ///
            /// - Parameter name: 已去除前後空白的類別名稱
            case categorySelected(String)

            /// 切換商品類別的選取狀態
            ///
            /// - Parameter name: 要切換的類別名稱
            case categoryToggled(String)

            /// 單選開團，空字串代表未歸團
            ///
            /// - Parameter name: 已去除前後空白的開團名稱
            case campaignSelected(String)

            /// 切換開團的選取狀態
            ///
            /// - Parameter name: 要切換的開團名稱
            case campaignToggled(String)

            /// 單選付款方式
            ///
            /// - Parameter name: 被選定的付款方式名稱
            case paymentMethodSelected(String)

            /// 單選對帳狀態
            ///
            /// - Parameter name: 被選定的對帳狀態名稱
            case reconciliationStatusSelected(String)

            /// 單選幣別
            ///
            /// - Parameter code: 被選定的 ISO 4217 幣別代碼
            case currencySelected(String)

            /// 請父層先寫入主檔，清單與草稿等成功回應再套用
            ///
            /// - Parameters:
            ///   - kind: 新增的主檔種類
            ///   - name: 已去除前後空白的名稱
            ///   - flags: 付款方式分類旗標，其他種類為 `.none`
            case addOptionRequested(kind: LookupKind, name: String, flags: PaymentMethodFlags)
        }
    }

    // MARK: - Body

    /// 組合選擇器路由繫結與畫面事件處理
    var body: some ReducerOf<Self> {
        BindingReducer()

        Reduce(core)
    }
}

// MARK: - Private Method

private extension OrderEditPickersFeature {

    /// 更新選項清單或路由，並將草稿選取請求交給父層
    ///
    /// - Parameters:
    ///   - state: 選擇器的目前狀態
    ///   - action: 繫結、畫面事件或父層請求
    /// - Returns: 交給父層的選取或新增選項請求
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .binding:
            return .none

        case .view(let view):
            return OrderEditPickerOperations.apply(view, state: &state)

        case .delegate:
            return .none
        }
    }
}
