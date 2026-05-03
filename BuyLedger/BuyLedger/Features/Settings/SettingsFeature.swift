//
//  SettingsFeature.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import Foundation

/// 設定頁狀態。
///
/// 偏好透過 ``SettingsStorage`` 依賴持久化到 `UserDefaults`；測試時注入 ``SettingsStorage/testValue`` 即可避免污染 `.standard`。
@Reducer
struct SettingsFeature {
    
    // MARK: - State
    
    /// 設定狀態。
    @ObservableState
    struct State: Equatable, @unchecked Sendable {
        
        /// 介面外觀模式偏好。
        var appearance: AppearancePreference
        
        /// 是否開啟通知。
        var notificationsEnabled: Bool
        
        /// 預設訂單幣別。
        var defaultCurrency: CurrencyCode
        
        /// 每月淨獲利目標（TWD）；Dashboard hero 卡的目標進度條讀此值。`0` 代表使用者尚未設定，UI 應隱藏進度條。
        var monthlyProfitGoalTwd: Decimal
        
        // MARK: - Init
        
        /// 建立預設設定。
        init(
            appearance: AppearancePreference = .system,
            notificationsEnabled: Bool = true,
            defaultCurrency: CurrencyCode = .twd,
            monthlyProfitGoalTwd: Decimal = 80_000
        ) {
            self.appearance = appearance
            self.notificationsEnabled = notificationsEnabled
            self.defaultCurrency = defaultCurrency
            self.monthlyProfitGoalTwd = monthlyProfitGoalTwd
        }
    }
    
    // MARK: - Action
    
    /// 設定頁事件。
    @CasePathable
    enum Action: BindableAction, Equatable {
        
        /// SwiftUI 雙向繫結。
        case binding(BindingAction<State>)
        
        /// 畫面出現時觸發從持久化來源載入。
        case task
    }
    
    // MARK: - Dependency Properties
    
    /// 偏好的讀寫介面。
    @Dependency(SettingsStorage.self) private var storage
    
    // MARK: - Reducer Body
    
    /// 設定 reducer。
    var body: some Reducer<State, Action> {
        BindingReducer()
        
        Reduce { state, action in
            switch action {
            case .task:
                let snapshot = storage.load()
                state.appearance = snapshot.appearance
                state.notificationsEnabled = snapshot.notificationsEnabled
                state.defaultCurrency = snapshot.defaultCurrency
                state.monthlyProfitGoalTwd = snapshot.monthlyProfitGoalTwd
                return .none
                
            case .binding:
                storage.save(
                    SettingsSnapshot(
                        appearance: state.appearance,
                        notificationsEnabled: state.notificationsEnabled,
                        defaultCurrency: state.defaultCurrency,
                        monthlyProfitGoalTwd: state.monthlyProfitGoalTwd
                    )
                )
                return .none
            }
        }
    }
}

/// 介面外觀模式偏好。
enum AppearancePreference: String, CaseIterable, Identifiable, Sendable {
    
    // MARK: - Cases
    
    /// 跟隨系統外觀。
    case system
    
    /// 強制淺色。
    case light
    
    /// 強制深色。
    case dark
    
    // MARK: - Identifiable Properties
    
    /// 偏好的穩定識別值。
    var id: String { rawValue }
    
    // MARK: - Display Properties
    
    /// 顯示在介面中的名稱。
    var title: String {
        switch self {
        case .system:
            "自動"
        case .light:
            "淺色"
        case .dark:
            "深色"
        }
    }
}

// MARK: - Settings Storage

/// 設定持久化的最小快照，方便一次寫入或讀出全部欄位。
struct SettingsSnapshot: Equatable, Sendable {
    
    // MARK: - Data Properties
    
    /// 介面外觀模式偏好。
    var appearance: AppearancePreference
    
    /// 是否開啟通知。
    var notificationsEnabled: Bool
    
    /// 預設訂單幣別。
    var defaultCurrency: CurrencyCode
    
    /// 每月淨獲利目標（TWD）。
    var monthlyProfitGoalTwd: Decimal
    
    // MARK: - Static Properties
    
    /// 預設設定。
    static let `default` = SettingsSnapshot(
        appearance: .system,
        notificationsEnabled: true,
        defaultCurrency: .twd,
        monthlyProfitGoalTwd: 80_000
    )
}

/// 把設定偏好讀寫到 `UserDefaults` 的依賴介面。
struct SettingsStorage: Sendable {
    
    // MARK: - Dependency Properties
    
    /// 從 `UserDefaults` 讀取一份設定快照。
    var load: @Sendable () -> SettingsSnapshot
    
    /// 將設定快照寫回 `UserDefaults`。
    var save: @Sendable (SettingsSnapshot) -> Void
}

extension SettingsStorage: DependencyKey {
    
    // MARK: - Dependency Values
    
    /// App 執行時實際讀寫 `UserDefaults.standard`。
    ///
    /// `UserDefaults` 為執行緒安全，但 Swift 6 strict concurrency 並不認可；因此 closure 內每次都從
    /// `.standard` 取得引用，而非透過捕獲傳遞，避免 `Sendable` 報錯。
    nonisolated static let liveValue: SettingsStorage = SettingsStorage(
        load: {
            let defaults = UserDefaults.standard
            let appearance = AppearancePreference(
                rawValue: defaults.string(forKey: SettingsStorageKeys.appearance) ?? ""
            ) ?? .system
            let notifications = defaults.object(forKey: SettingsStorageKeys.notifications) as? Bool ?? true
            let currency = CurrencyCode(
                rawValue: defaults.string(forKey: SettingsStorageKeys.defaultCurrency) ?? ""
            ) ?? .twd
            // 從未寫入時 `object(forKey:)` 為 nil，預設帶入 `SettingsSnapshot.default.monthlyProfitGoalTwd`；
            // 寫入過 `0` 也尊重使用者意圖（代表「不設目標」）。
            let goalValue: Decimal = {
                guard let raw = defaults.object(forKey: SettingsStorageKeys.monthlyProfitGoalTwd) as? Double else {
                    return SettingsSnapshot.default.monthlyProfitGoalTwd
                }
                return Decimal(raw)
            }()
            
            return SettingsSnapshot(
                appearance: appearance,
                notificationsEnabled: notifications,
                defaultCurrency: currency,
                monthlyProfitGoalTwd: goalValue
            )
        },
        save: { snapshot in
            let defaults = UserDefaults.standard
            defaults.set(snapshot.appearance.rawValue, forKey: SettingsStorageKeys.appearance)
            defaults.set(snapshot.notificationsEnabled, forKey: SettingsStorageKeys.notifications)
            defaults.set(snapshot.defaultCurrency.rawValue, forKey: SettingsStorageKeys.defaultCurrency)
            defaults.set(NSDecimalNumber(decimal: snapshot.monthlyProfitGoalTwd).doubleValue, forKey: SettingsStorageKeys.monthlyProfitGoalTwd)
        }
    )
    
    /// 測試時使用的版本：load 永遠回傳預設值，save 為 no-op，避免污染 `.standard`。
    nonisolated static let testValue: SettingsStorage = SettingsStorage(
        load: { SettingsSnapshot.testDefault },
        save: { _ in }
    )
    
    /// SwiftUI Preview 直接沿用測試值即可。
    nonisolated static let previewValue: SettingsStorage = testValue
}

/// `UserDefaults` 中使用的 key 名稱（提到型別外避免 main-actor 隔離污染）。
private enum SettingsStorageKeys {
    
    // MARK: - Static Properties
    
    /// 外觀偏好的 key。
    nonisolated static let appearance = "settings.appearance"
    
    /// 通知開關的 key。
    nonisolated static let notifications = "settings.notifications"
    
    /// 預設幣別的 key。
    nonisolated static let defaultCurrency = "settings.defaultCurrency"
    
    /// 月度淨獲利目標的 key。
    nonisolated static let monthlyProfitGoalTwd = "settings.monthlyProfitGoalTwd"
}

extension SettingsSnapshot {
    
    // MARK: - Static Properties
    
    /// 測試與 preview 用的預設快照（與 `.default` 內容相同，但宣告為 `nonisolated` 方便在 `@Sendable` closure 中安全引用）。
    nonisolated static let testDefault = SettingsSnapshot(
        appearance: .system,
        notificationsEnabled: true,
        defaultCurrency: .twd,
        monthlyProfitGoalTwd: 80_000
    )
}
