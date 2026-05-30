//
//  CampaignEditFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/30.
//

import ComposableArchitecture
import Foundation

/// 新增或編輯開團 (Campaign) 的表單功能。
///
/// 僅持有草稿欄位；`saveTapped` 與 `cancelTapped` 皆觸發 dismiss，實際的寫入與 cascade 由父層 ``CampaignFeature`` 攔截 `saveTapped` 處理。
@Reducer
struct CampaignEditFeature {

    // MARK: - State

    /// 編輯／新增開團表單的狀態。
    @ObservableState
    struct State: Equatable, Identifiable, Sendable {

        /// 原始開團；`nil` 代表「新開團」流程。
        let original: Campaign?

        /// 開團名稱草稿。
        var draftName: String

        /// 開團日期草稿。
        var draftOpenDate: Date

        /// 結單日期草稿 (必填)；當結單日早於「現在」時，狀態會自動由 ``CampaignStatus/ongoing`` 轉為 ``CampaignStatus/closed``。
        var draftCloseDate: Date

        /// 開團狀態草稿。
        var draftStatus: CampaignStatus

        /// 開團備註草稿。
        var draftNotes: String

        // MARK: - Identifiable Properties

        /// 表單 instance 的穩定識別值，供 SwiftUI sheet item 使用。
        let id: UUID

        // MARK: - Init

        /// 依原始開團建立草稿狀態。
        /// - Parameters:
        ///   - original: 要編輯的開團；`nil` 表示新開團。
        ///   - currentDate: 新開團時 ``draftOpenDate`` 與 ``draftCloseDate`` 的預設值；caller 應從 `@Dependency(\.date)` 取得當下時間以維持可測試性。
        init(original: Campaign? = nil, currentDate: Date = Date()) {
            self.original = original
            self.draftName = original?.name ?? ""
            self.draftOpenDate = original?.openDate ?? currentDate
            self.draftCloseDate = original?.closeDate ?? currentDate
            self.draftStatus = original?.status ?? .ongoing
            self.draftNotes = original?.notes ?? ""
            self.id = UUID()
        }
    }

    // MARK: - Action

    /// 表單可處理的事件。
    @CasePathable
    enum Action: BindableAction, Equatable {

        /// SwiftUI 雙向繫結事件。
        case binding(BindingAction<State>)

        /// 使用者按下取消。
        case cancelTapped

        /// 使用者按下儲存。
        case saveTapped
    }

    // MARK: - Dependency Properties

    /// 由父層注入的 dismiss effect。
    @Dependency(\.dismiss) private var dismiss

    // MARK: - Reducer Body

    /// 表單 reducer。
    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { _, action in
            switch action {
            case .binding:
                return .none

            case .cancelTapped, .saveTapped:
                return .run { _ in await dismiss() }
            }
        }
    }
}
