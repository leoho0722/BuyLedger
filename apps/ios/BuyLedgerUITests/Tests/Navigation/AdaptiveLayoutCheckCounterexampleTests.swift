//
//  AdaptiveLayoutCheckCounterexampleTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/10/30.
//

import XCTest

/// 版面純值檢查的反例測試，以純 fixture 證明錯誤 ID、成本缺失、越界與路徑丟失會令檢查失敗，正常結果通過
///
/// - Note: 不啟動 App，只驗證檢查邏輯；活體偵測由實機回歸負責
/// - Note: 使用 XCTest 撰寫，因為 UI test target 無法 import Swift Testing，且檢查型別只編進 UI target
final class AdaptiveLayoutCheckCounterexampleTests: XCTestCase {

    /// 驗證期望與觀測的識別碼不同時檢查失敗，相同時通過
    func testIdentifierCheck_錯ID_檢查失敗() {
        // Given
        let revenue = BLAccessibilityID.Dashboard.kpiTile(.revenue)
        let cost = BLAccessibilityID.Dashboard.kpiTile(.cost)

        // When
        let mismatched = IdentifierCheck.verify(expected: revenue, observed: cost)
        let matched = IdentifierCheck.verify(expected: revenue, observed: revenue)

        // Then
        XCTAssertTrue(mismatched.isFailed, "期望 revenue 卻觀測 cost，識別碼檢查應失敗")
        XCTAssertEqual(matched, .passed, "識別碼相同時應通過")
    }

    /// 驗證必要 KPI 缺成本時存在性檢查失敗，四項齊全時通過
    func testKPIPresenceCheck_成本缺失_檢查失敗() {
        // Given
        let required: [BLAccessibilityID.Dashboard.KPI] = [
            .revenue,
            .cost,
            .grossMargin,
            .activeOrders,
        ]
        let observedWithoutCost: Set<BLAccessibilityID.Dashboard.KPI> = [
            .revenue,
            .grossMargin,
            .activeOrders,
        ]
        let observedComplete: Set<BLAccessibilityID.Dashboard.KPI> = [
            .revenue,
            .cost,
            .grossMargin,
            .activeOrders,
        ]

        // When
        let missingCost = KPIPresenceCheck.verify(required: required, observed: observedWithoutCost)
        let complete = KPIPresenceCheck.verify(required: required, observed: observedComplete)

        // Then
        XCTAssertTrue(missingCost.isFailed, "缺少成本 KPI 時存在性檢查應失敗")
        XCTAssertEqual(complete, .passed, "四項 KPI 齊全時應通過")
    }

    /// 驗證框線越出容器或進入側邊欄保留區時檢查失敗，框線在容器內且避開保留區時通過
    func testBoundsCheck_越界frame_檢查失敗() {
        // Given
        let container = CGRect(
            x: 0,
            y: 0,
            width: 1024,
            height: 1366
        )
        let reservedRegions = [
            CGRect(
                x: 0,
                y: 0,
                width: 80,
                height: 1366
            ),
        ]
        let insideFrame = CGRect(
            x: 120,
            y: 100,
            width: 300,
            height: 44
        )
        let overflowFrame = CGRect(
            x: 900,
            y: 100,
            width: 300,
            height: 44
        )
        let reservedFrame = CGRect(
            x: 40,
            y: 100,
            width: 300,
            height: 44
        )

        // When
        let overflow = BoundsCheck.verify(
            frame: overflowFrame,
            container: container,
            reservedRegions: reservedRegions
        )
        let intrusion = BoundsCheck.verify(
            frame: reservedFrame,
            container: container,
            reservedRegions: reservedRegions
        )
        let inside = BoundsCheck.verify(
            frame: insideFrame,
            container: container,
            reservedRegions: reservedRegions
        )

        // Then
        XCTAssertTrue(overflow.isFailed, "框線越出容器右緣時應失敗")
        XCTAssertTrue(intrusion.isFailed, "框線進入側邊欄保留區時應失敗")
        XCTAssertEqual(inside, .passed, "框線在容器內且避開保留區時應通過")
    }

    /// 驗證期望的更多目的地不在路徑中時檢查失敗，路徑含該目的地時通過
    func testPathCheck_More路徑丟失_檢查失敗() {
        // Given
        let settings = BLAccessibilityID.More.Row.settings.rawValue
        let customers = BLAccessibilityID.More.Row.customers.rawValue

        // When
        let emptyPath = PathCheck.verify(expectedDestination: settings, observedPath: [])
        let wrongDestination = PathCheck.verify(
            expectedDestination: settings,
            observedPath: [customers]
        )
        let containsSettings = PathCheck.verify(
            expectedDestination: settings,
            observedPath: [settings]
        )

        // Then
        XCTAssertTrue(emptyPath.isFailed, "路徑為空時應失敗")
        XCTAssertTrue(wrongDestination.isFailed, "路徑的目的地不同時應失敗")
        XCTAssertEqual(containsSettings, .passed, "路徑含設定頁時應通過")
    }

    /// 驗證四類正常 fixture 同時通過，確認反例之外的結果不會被誤判
    func testLayoutChecks_正常結果_全部通過() {
        // Given
        let revenue = BLAccessibilityID.Dashboard.kpiTile(.revenue)
        let settings = BLAccessibilityID.More.Row.settings.rawValue
        let requiredCost: [BLAccessibilityID.Dashboard.KPI] = [.cost]
        let observedCost: Set<BLAccessibilityID.Dashboard.KPI> = [.cost]
        let container = CGRect(
            x: 0,
            y: 0,
            width: 1024,
            height: 1366
        )
        let sidebarRegion = CGRect(
            x: 0,
            y: 0,
            width: 80,
            height: 1366
        )
        let insideFrame = CGRect(
            x: 120,
            y: 100,
            width: 300,
            height: 44
        )

        // When
        let identifier = IdentifierCheck.verify(expected: revenue, observed: revenue)
        let presence = KPIPresenceCheck.verify(required: requiredCost, observed: observedCost)
        let bounds = BoundsCheck.verify(
            frame: insideFrame,
            container: container,
            reservedRegions: [sidebarRegion]
        )
        let path = PathCheck.verify(expectedDestination: settings, observedPath: [settings])

        // Then
        XCTAssertEqual(identifier, .passed, "識別碼檢查應通過")
        XCTAssertEqual(presence, .passed, "KPI 存在性檢查應通過")
        XCTAssertEqual(bounds, .passed, "框線檢查應通過")
        XCTAssertEqual(path, .passed, "路徑檢查應通過")
    }
}
