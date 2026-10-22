//
//  LookupCatalogFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/16.
//

import ComposableArchitecture
import OSLog

/// 讀取與新增四種主檔目錄並寫回共用目錄；本功能沒有畫面
@Reducer
struct LookupCatalogFeature {

    // MARK: - State

    /// 主檔目錄的載入與新增狀態
    @ObservableState
    struct State: Equatable {

        /// 四種主檔的共用目錄，只在本功能的 reducer 內更新
        @Shared(.lookupCatalog) var catalog: LookupCatalog

        /// 是否正在讀取主檔，讀取中的載入請求略過
        var isLoading = false

        /// 四種主檔是否都讀取成功過，成功後的載入請求直接回報完成
        var hasLoaded = false
    }

    // MARK: - Action

    /// 主檔目錄功能可處理的事件
    enum Action {

        /// 交給父層的結果
        ///
        /// - Parameter delegate: 載入或新增完成的通知
        case delegate(Delegate)

        /// 父層要求新增一筆主檔項目
        ///
        /// - Parameter request: 種類、名稱與付款方式旗標
        case additionRequested(LookupAdditionRequest)

        /// 新增寫入的唯一結果，成功時更新目錄
        ///
        /// - Parameters:
        ///   - request: 原新增請求，原樣帶回
        ///   - result: 寫入成功或持久化失敗
        case additionResponse(request: LookupAdditionRequest, result: Result<Void, PersistenceError>)

        /// 四種主檔讀取完成的唯一結果，只包含讀取成功的種類
        ///
        /// - Parameter catalogs: 讀取成功的種類與其目錄
        case catalogResponse([LookupKind: LookupCatalog])

        /// 父層要求載入主檔目錄，已讀取過或讀取中時不重讀
        case loadRequested

        /// 交給父層的結果
        @CasePathable
        enum Delegate: Equatable {

            /// 主檔目錄已讀取完成，部分種類失敗時仍會送出，失敗的種類保留既有值
            case loadFinished

            /// 新增請求已結束
            ///
            /// - Parameters:
            ///   - request: 原新增請求
            ///   - isStored: 寫入成功並已更新目錄時為真
            case additionCompleted(LookupAdditionRequest, isStored: Bool)
        }
    }

    // MARK: - Dependencies

    /// 讀取與新增主檔的 Service，四種主檔共用同一個入口
    @Dependency(\.lookupService) private var lookupService

    // MARK: - Body

    /// 只負責組合 reducer，本功能自己的邏輯在 `core(state:action:)`
    var body: some ReducerOf<Self> {
        Reduce(core)
    }
}

// MARK: - Private Method

private extension LookupCatalogFeature {

    /// 依收到的事件更新目錄與載入狀態，並回傳要執行的 Effect
    ///
    /// - Parameters:
    ///   - state: 目前的主檔目錄狀態，直接就地修改
    ///   - action: 這次收到的事件
    /// - Returns: 接下來要執行的 Effect，沒有就回 `.none`
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .delegate:
            return .none

        case .additionRequested(let request):
            guard !request.addition.name.isEmpty else {
                return .none
            }
            return persistAddition(request)

        case .additionResponse(let request, .success):
            let addition = request.addition
            state.$catalog.withLock {
                $0.add(name: addition.name, kind: request.kind, flags: addition.flags)
            }
            return .send(.delegate(.additionCompleted(request, isStored: true)))

        case .additionResponse(let request, .failure):
            return .send(.delegate(.additionCompleted(request, isStored: false)))

        case .catalogResponse(let catalogs):
            state.isLoading = false
            state.$catalog.withLock {
                for (kind, catalog) in catalogs {
                    $0.replaceItems(of: kind, from: catalog)
                }
            }
            state.hasLoaded = LookupKind.allCases.allSatisfy { catalogs[$0] != nil }
            return .send(.delegate(.loadFinished))

        case .loadRequested:
            guard !state.hasLoaded else {
                return .send(.delegate(.loadFinished))
            }
            guard !state.isLoading else {
                return .none
            }
            state.isLoading = true
            return loadCatalogs()
        }
    }

    /// 並行讀取四種主檔，讀取失敗的種類略過，成功的種類以目錄回傳
    ///
    /// - Parameter service: 讀取主檔的 Service
    /// - Returns: 讀取成功的種類與其目錄，失敗的種類不在結果內
    static func fetchCatalogs(using service: LookupService) async -> [LookupKind: LookupCatalog] {
        await withTaskGroup(of: (LookupKind, LookupCatalog?).self) { group in
            for kind in LookupKind.allCases {
                group.addTask {
                    let read = await readCatalog(kind, using: service)
                    return (kind, read)
                }
            }
            var catalogs: [LookupKind: LookupCatalog] = [:]
            for await (kind, read) in group {
                if let catalog = read {
                    catalogs[kind] = catalog
                }
            }
            return catalogs
        }
    }

    /// 讀取單一種類的主檔，失敗時記錄警告並回傳 `nil`，讓呼叫端保留既有目錄
    ///
    /// - Parameters:
    ///   - kind: 要讀取的主檔種類
    ///   - service: 讀取主檔的 Service
    /// - Returns: 讀取成功的目錄，失敗時為 `nil`
    static func readCatalog(
        _ kind: LookupKind,
        using service: LookupService
    ) async -> LookupCatalog? {
        do throws(PersistenceError) {
            return try await service.fetchItems(kind)
        } catch {
            AppLogger.persistence.warning("主檔讀取失敗，保留既有目錄")
            return nil
        }
    }

    /// 把新增請求寫入主檔，成功與失敗都以 `additionResponse` 連同原請求送回
    ///
    /// - Parameter request: 已去除頭尾空白的新增請求
    /// - Returns: 寫入主檔的 Effect
    func persistAddition(_ request: LookupAdditionRequest) -> Effect<Action> {
        let lookupService = lookupService
        return .run { send in
            do throws(PersistenceError) {
                try await lookupService.addItem(request.kind, request.addition)
                await send(.additionResponse(request: request, result: .success(())))
            } catch {
                await send(.additionResponse(request: request, result: .failure(error)))
            }
        }
    }

    /// 並行讀取四種主檔，結果以 `catalogResponse` 一次送回
    ///
    /// - Returns: 讀取主檔目錄的 Effect
    func loadCatalogs() -> Effect<Action> {
        let lookupService = lookupService
        return .run { send in
            let catalogs = await Self.fetchCatalogs(using: lookupService)
            await send(.catalogResponse(catalogs))
        }
    }
}
