//
//  CampaignReminderFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

import ComposableArchitecture

/// 載入提醒連結，並依儲存與刪除的結果建立、重建或移除開團的行事曆提醒 (沒有自己的畫面)
@Reducer
struct CampaignReminderFeature {

    // MARK: - State

    /// 提醒流程的狀態
    @ObservableState
    struct State: Equatable {

        /// 各開團連結的行事曆事件與提醒時間；與父層共用，只有本 Feature 寫入
        @Shared var links: [Campaign.ID: CampaignReminderLink]

        /// 是否已成功載入提醒連結；載入失敗時維持 `false`，讓下次請求重新載入
        var hasLoadedLinks = false

        /// 以父層持有的共用連結建立狀態
        ///
        /// - Parameter links: 父層持有的提醒連結
        init(links: Shared<[Campaign.ID: CampaignReminderLink]>) {
            self._links = links
        }
    }

    // MARK: - Action

    /// 提醒流程可處理的事件；沒有畫面，不設 `view` 分組
    enum Action {

        /// 交給父層處理的結果
        ///
        /// - Parameter action: 要轉送給父層的結果
        case delegate(Delegate)

        /// 開團已刪除，清除共用連結並移除行事曆事件
        ///
        /// - Parameters:
        ///   - campaignID: 已刪除的開團識別值
        ///   - eventIdentifier: 被刪除連結的行事曆事件識別碼；沒有提醒時為 `nil`
        case campaignRemoved(campaignID: Campaign.ID, eventIdentifier: String?)

        /// 建立新事件並寫入連結的結果
        ///
        /// - Parameters:
        ///   - campaignID: 提醒所屬的開團識別值
        ///   - oldEventIdentifier: 重建時新連結生效後要移除的舊事件識別碼；建立提醒時為 `nil`
        ///   - result: 已寫入的新連結或失敗種類
        case createResponse(campaignID: Campaign.ID, oldEventIdentifier: String?, result: Result<CampaignReminderLink, Failure>)

        /// 開團刪除後移除行事曆事件的結果
        ///
        /// - Parameter result: 成功或行事曆錯誤
        case eventRemovalResponse(Result<Void, CalendarReminderError>)

        /// 移除提醒時清除連結的結果
        ///
        /// - Parameters:
        ///   - campaignID: 被清除連結的開團識別值
        ///   - result: 成功或持久化錯誤
        case linkRemovalResponse(campaignID: Campaign.ID, result: Result<Void, PersistenceError>)

        /// 載入全部提醒連結；已成功載入過就略過
        case linksRequested

        /// 提醒連結載入結果
        ///
        /// - Parameter result: 以開團識別值對應的連結或持久化錯誤
        case linksResponse(Result<[Campaign.ID: CampaignReminderLink], PersistenceError>)

        /// 重建提醒後移除舊事件的結果
        ///
        /// - Parameter result: 成功或行事曆錯誤
        case oldEventRemovalResponse(Result<Void, CalendarReminderError>)

        /// 依儲存結果建立、重建或移除提醒
        ///
        /// - Parameter request: 提醒調解所需的開團、標題、日期與提示位移
        case reconcileRequested(CampaignReminderRequest)

        /// 交給父層的提醒結果
        @CasePathable
        enum Delegate: Equatable {

            /// 提醒流程失敗，由父層呈現對應的提示
            ///
            /// - Parameter failure: 失敗的種類
            case failed(Failure)
        }
    }

    // MARK: - Dependencies

    /// 請求行事曆權限，並建立與移除系統行事曆事件
    @Dependency(\.calendarReminderService) private var calendarReminderService

    /// 讀寫開團主檔與行事曆事件之間的連結
    @Dependency(\.campaignService) private var campaignService

    // MARK: - Body

    /// 只負責組合 reducer，提醒流程由 `core(state:action:)` 處理
    var body: some Reducer<State, Action> {
        Reduce(core)
    }
}

// MARK: - Nested Types

extension CampaignReminderFeature {

    /// 提醒流程中需要告知使用者的失敗種類
    enum Failure: Error, Equatable, Sendable {

        /// 使用者拒絕行事曆權限
        case accessDenied

        /// 裝置政策限制行事曆權限，使用者無法自行開啟
        case accessRestricted

        /// 權限已授予，但事件建立或新連結寫入失敗
        case creationFailed

        /// 權限已授予，但找不到可寫入的行事曆
        case calendarUnavailable

        /// 移除提醒時連結清除失敗
        case linkRemovalFailed

        /// 重建提醒時新連結已生效，但舊事件移除失敗
        case oldEventRemovalFailed

        /// 開團已刪除，但行事曆事件移除失敗
        case eventRemovalAfterDeleteFailed
    }
}

// MARK: - Private Method

private extension CampaignReminderFeature {

    /// 依收到的 Action 更新 State，並回傳要執行的 Effect
    ///
    /// - Parameters:
    ///   - state: 目前的提醒流程狀態
    ///   - action: 這次收到的事件
    /// - Returns: 接續流程需要的操作，沒有時不再執行操作
    func core(state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .delegate:
            return .none

        case .campaignRemoved(let campaignID, let eventIdentifier):
            // 本機交易已刪除持久化連結，只清共用連結，不呼叫 `removeReminderLink`
            state.$links.withLock { $0[campaignID] = nil }
            guard let eventIdentifier else {
                return .none
            }
            return removeEvent(eventIdentifier, response: Action.eventRemovalResponse)

        case .createResponse(let campaignID, let oldEventIdentifier, .success(let link)):
            state.$links.withLock { $0[campaignID] = link }
            guard let oldEventIdentifier else {
                return .none
            }
            return removeEvent(oldEventIdentifier, response: Action.oldEventRemovalResponse)

        case .createResponse(_, _, .failure(let failure)):
            return .send(.delegate(.failed(failure)))

        case .eventRemovalResponse(.success), .oldEventRemovalResponse(.success):
            return .none

        case .eventRemovalResponse(.failure):
            return .send(.delegate(.failed(.eventRemovalAfterDeleteFailed)))

        case .linkRemovalResponse(let campaignID, .success):
            state.$links.withLock { $0[campaignID] = nil }
            return .none

        case .linkRemovalResponse(_, .failure):
            return .send(.delegate(.failed(.linkRemovalFailed)))

        case .linksRequested:
            guard !state.hasLoadedLinks else {
                return .none
            }
            return loadLinks()

        case .linksResponse(.success(let links)):
            state.hasLoadedLinks = true
            state.$links.withLock { $0 = links }
            return .none

        case .linksResponse(.failure):
            return .none

        case .oldEventRemovalResponse(.failure):
            return .send(.delegate(.failed(.oldEventRemovalFailed)))

        case .reconcileRequested(let request):
            switch request.reconcile {
            case .create:
                return createReminder(request, oldEventIdentifier: nil)

            case .remove(let eventIdentifier):
                return removeReminder(request.campaignID, eventIdentifier: eventIdentifier)

            case .rebuild(let oldEventIdentifier):
                return createReminder(request, oldEventIdentifier: oldEventIdentifier)
            }
        }
    }

    /// 請求行事曆權限後建立全天事件，成功再寫入連結
    ///
    /// - Parameters:
    ///   - request: 提醒調解所需的開團、標題、日期與提示位移
    ///   - calendarReminderService: 行事曆整合操作入口
    ///   - campaignService: 開團與提醒連結操作入口
    /// - Returns: 已寫入的新連結；權限未授予、事件建立或連結寫入失敗時為失敗種類
    static func createLink(
        for request: CampaignReminderRequest,
        calendarReminderService: CalendarReminderService,
        campaignService: CampaignService
    ) async -> Result<CampaignReminderLink, Failure> {
        switch await calendarReminderService.requestAccess() {
        case .granted:
            break

        case .denied:
            return .failure(.accessDenied)

        case .restricted:
            return .failure(.accessRestricted)
        }

        // 權限已取得，後續失敗不應被當成權限錯誤
        let eventIdentifier: String
        do throws(CalendarReminderError) {
            eventIdentifier = try await calendarReminderService.addReminder(
                request.title,
                request.eventDate,
                request.alarmOffset
            )
        } catch {
            switch error {
            case .noWritableCalendar:
                return .failure(.calendarUnavailable)

            case .eventIdentifierMissing, .system:
                return .failure(.creationFailed)
            }
        }
        let link = CampaignReminderLink(
            eventIdentifier: eventIdentifier,
            reminderTimestamp: request.timestamp
        )
        do throws(PersistenceError) {
            try await campaignService.saveReminderLink(request.campaignID, link)
        } catch {
            return .failure(.creationFailed)
        }
        return .success(link)
    }

    /// 移除行事曆事件，依呼叫端指定的回應送出結果
    ///
    /// - Parameters:
    ///   - eventIdentifier: 要移除的行事曆事件識別碼
    ///   - response: 將移除結果轉成刪除開團或重建提醒的回應
    /// - Returns: 移除完成後回報結果
    func removeEvent(
        _ eventIdentifier: String,
        response: @escaping @Sendable (Result<Void, CalendarReminderError>) -> Action
    ) -> Effect<Action> {
        let calendarReminderService = calendarReminderService
        return .run { send in
            do throws(CalendarReminderError) {
                try await calendarReminderService.removeReminder(eventIdentifier)
                await send(response(.success(())))
            } catch {
                await send(response(.failure(error)))
            }
        }
    }

    /// 載入全部提醒連結
    ///
    /// - Returns: 讀取完成後回報連結或錯誤
    func loadLinks() -> Effect<Action> {
        let campaignService = campaignService
        return .run { send in
            do throws(PersistenceError) {
                let links = try await campaignService.fetchReminderLinks()
                await send(.linksResponse(.success(links)))
            } catch {
                await send(.linksResponse(.failure(error)))
            }
        }
    }

    /// 建立新事件並寫入連結；重建時由回應處理在新連結生效後移除舊事件
    ///
    /// - Parameters:
    ///   - request: 提醒調解所需的開團、標題、日期與提示位移
    ///   - oldEventIdentifier: 重建時要在新連結生效後移除的舊事件識別碼
    /// - Returns: 建立完成後回報新連結或失敗種類
    func createReminder(
        _ request: CampaignReminderRequest,
        oldEventIdentifier: String?
    ) -> Effect<Action> {
        let calendarReminderService = calendarReminderService
        let campaignService = campaignService
        return .run { send in
            let result = await Self.createLink(
                for: request,
                calendarReminderService: calendarReminderService,
                campaignService: campaignService
            )
            let response = Action.createResponse(
                campaignID: request.campaignID,
                oldEventIdentifier: oldEventIdentifier,
                result: result
            )
            await send(response)
        }
    }

    /// 移除行事曆事件後清除連結；事件移除失敗仍清除連結
    ///
    /// - Parameters:
    ///   - campaignID: 要移除提醒的開團識別值
    ///   - eventIdentifier: 要移除的行事曆事件識別碼
    /// - Returns: 連結清除完成後回報結果
    func removeReminder(_ campaignID: Campaign.ID, eventIdentifier: String) -> Effect<Action> {
        let calendarReminderService = calendarReminderService
        let campaignService = campaignService
        return .run { send in
            _ = try? await calendarReminderService.removeReminder(eventIdentifier)  // 事件可能已不存在
            do throws(PersistenceError) {
                try await campaignService.removeReminderLink(campaignID)
                await send(.linkRemovalResponse(campaignID: campaignID, result: .success(())))
            } catch {
                await send(.linkRemovalResponse(campaignID: campaignID, result: .failure(error)))
            }
        }
    }
}
