//
//  BLUITestCalendarAccess.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/3.
//

#if DEBUG

/// UI 測試要模擬的行事曆權限結果
enum BLUITestCalendarAccess: String, CaseIterable, Sendable {

    /// 授予完整權限，提醒可正常新增與移除
    case granted

    /// 拒絕權限，用於驗證權限被拒的提示路徑
    case denied
}

#endif
