//
//  SnapshotLookupsTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/24.
//

import ComposableArchitecture
import SnapshotTesting
import SwiftUI
import Testing

@testable import BuyLedger

/// `LookupManagementView` 與 `LookupNameEditorSheet` 的快照測試，涵蓋主檔管理畫面與名稱編輯工作表
///
/// - Note: `testName` 沿用既有基準圖的檔名，改名後仍對應原基準圖
@MainActor
struct SnapshotLookupsTests {

    /// 驗證商品類別主檔已載入服飾、美妝與精品三個類別時，管理頁顯示固定目錄與導覽列，畫面符合基準圖
    @Test
    func lookupManagementView_商品類別已載入_顯示目錄與導覽列() async {
        await LookupCatalog.withIsolatedStorage {
            TestDependencies.withFixedNow {
                // Given
                var state = LookupManagementFeature.State(kind: .category)
                state.$catalog.withLock {
                    $0.categories = ["服飾", "美妝", "精品"]
                }
                state.hasLoaded = true

                // When
                let view = NavigationStack {
                    LookupManagementView(
                        store: Store(initialState: state) {
                            EmptyReducer()
                        }
                    )
                }
                    .environment(\.locale, AppLanguage.traditionalChinese.locale)
                    .frame(width: 393, height: 852)

                // Then
                assertSnapshot(
                    of: view,
                    as: .image(drawHierarchyInKeyWindow: true),
                    testName: "lookupManagementCategoryBaseline()"
                )
            }
        }
    }

    /// 驗證付款方式主檔已載入信用卡、無卡分期、銀行匯款與貨到付款，管理頁依各自旗標顯示分類與說明，畫面符合基準圖
    @Test
    func lookupManagementView_付款方式已載入_顯示分類旗標與說明() async {
        await LookupCatalog.withIsolatedStorage {
            TestDependencies.withFixedNow {
                // Given
                var state = LookupManagementFeature.State(kind: .paymentMethod)
                state.$catalog.withLock {
                    $0.paymentMethods = [
                        PaymentMethodInfo(
                            name: "信用卡",
                            isCardless: false,
                            isBankTransfer: false,
                            isCashOnDelivery: false
                        ),
                        PaymentMethodInfo(
                            name: "無卡分期",
                            isCardless: true,
                            isBankTransfer: false,
                            isCashOnDelivery: false
                        ),
                        PaymentMethodInfo(
                            name: "銀行匯款",
                            isCardless: false,
                            isBankTransfer: true,
                            isCashOnDelivery: false
                        ),
                        PaymentMethodInfo(
                            name: "貨到付款",
                            isCardless: false,
                            isBankTransfer: false,
                            isCashOnDelivery: true
                        ),
                    ]
                }
                state.hasLoaded = true

                // When
                let view = NavigationStack {
                    LookupManagementView(
                        store: Store(initialState: state) {
                            EmptyReducer()
                        }
                    )
                }
                    .environment(\.locale, AppLanguage.traditionalChinese.locale)
                    .frame(width: 393, height: 852)

                // Then
                assertSnapshot(
                    of: view,
                    as: .image(drawHierarchyInKeyWindow: true),
                    testName: "lookupManagementPaymentMethodBaseline()"
                )
            }
        }
    }

    /// 驗證商品類別主檔為空時，管理頁顯示空狀態，畫面符合基準圖
    @Test
    func lookupManagementView_商品類別為空_顯示空狀態() async {
        await LookupCatalog.withIsolatedStorage {
            TestDependencies.withFixedNow {
                // Given
                var state = LookupManagementFeature.State(kind: .category)
                state.hasLoaded = true

                // When
                let view = NavigationStack {
                    LookupManagementView(
                        store: Store(initialState: state) {
                            EmptyReducer()
                        }
                    )
                }
                    .environment(\.locale, AppLanguage.traditionalChinese.locale)
                    .frame(width: 393, height: 852)

                // Then
                assertSnapshot(
                    of: view,
                    as: .image(drawHierarchyInKeyWindow: true),
                    testName: "lookupManagementEmptyBaseline()"
                )
            }
        }
    }

    /// 驗證商品類別主檔載入失敗時，管理頁顯示錯誤文字，畫面符合基準圖
    @Test
    func lookupManagementView_商品類別載入失敗_顯示錯誤文字() async {
        await LookupCatalog.withIsolatedStorage {
            TestDependencies.withFixedNow {
                // Given
                var state = LookupManagementFeature.State(kind: .category)
                state.hasLoadFailed = true
                state.hasLoaded = true

                // When
                let view = NavigationStack {
                    LookupManagementView(
                        store: Store(initialState: state) {
                            EmptyReducer()
                        }
                    )
                }
                    .environment(\.locale, AppLanguage.traditionalChinese.locale)
                    .frame(width: 393, height: 852)

                // Then
                assertSnapshot(
                    of: view,
                    as: .image(drawHierarchyInKeyWindow: true),
                    testName: "lookupManagementLoadFailureBaseline()"
                )
            }
        }
    }

    /// 驗證重新命名商品類別時，改名表單顯示原名稱與儲存按鈕，畫面符合基準圖
    @Test
    func lookupNameEditorSheet_重新命名商品類別_顯示原名稱與儲存按鈕() async {
        await LookupCatalog.withIsolatedStorage {
            TestDependencies.withFixedNow {
                // Given

                // When
                let view = LookupNameEditorSheet(
                    title: "orders.lookup.label.renameProductCategory",
                    message: "orders.lookup.message.ordersReferencingName",
                    namePlaceholder: "orders.edit.label.categoryName",
                    submitTitle: "orders.edit.button.save",
                    initialName: "服飾"
                ) { _ in
                }
                    .environment(\.locale, AppLanguage.traditionalChinese.locale)
                    .frame(width: 393, height: 852)

                // Then
                assertSnapshot(
                    of: view,
                    as: .image(drawHierarchyInKeyWindow: true),
                    testName: "lookupNameEditorSheetRenameBaseline()"
                )
            }
        }
    }
}
