//
//  SnapshotTests+Lookups.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/9/24.
//

#if canImport(SnapshotTesting) && os(iOS)

    import ComposableArchitecture
    import SnapshotTesting
    import SwiftUI
    import Testing

    @testable import BuyLedger

    // MARK: - Tests

    extension SnapshotTests {

        /// 更多頁找不到商品類別管理 store 時顯示替代畫面
        @Test
        func moreViewMissingLookupManagementShowsUnavailableBaseline() async {
            // Given
            await LookupCatalog.withIsolatedStorage {
                TestDependencies.withFixedNow {
                    var state = RootFeature.State()
                    state.lookupManagements.remove(id: .category)
                    state.morePath.append(.categories)

                    // When
                    let view = MoreView(
                        store: Store(initialState: state) {
                            EmptyReducer()
                        }
                    )
                    .environment(\.locale, AppLanguage.traditionalChinese.locale)
                    .frame(width: 393, height: 852)

                    // Then
                    assertSnapshot(
                        of: view,
                        as: .image(drawHierarchyInKeyWindow: true)
                    )
                }
            }
        }

        /// 商品類別主檔管理頁顯示固定目錄與導覽列
        @Test
        func lookupManagementCategoryBaseline() async {
            // Given
            await LookupCatalog.withIsolatedStorage {
                TestDependencies.withFixedNow {
                    var state = LookupManagementFeature.State(kind: .category)
                    state.$catalog.withLock { $0.categories = ["服飾", "美妝", "精品"] }
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
                        as: .image(drawHierarchyInKeyWindow: true)
                    )
                }
            }
        }

        /// 付款方式主檔管理頁顯示各分類旗標與說明
        @Test
        func lookupManagementPaymentMethodBaseline() async {
            // Given
            await LookupCatalog.withIsolatedStorage {
                TestDependencies.withFixedNow {
                    var state = LookupManagementFeature.State(kind: .paymentMethod)
                    state.$catalog.withLock { catalog in
                        catalog.paymentMethods = [
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
                        as: .image(drawHierarchyInKeyWindow: true)
                    )
                }
            }
        }

        /// 空商品類別主檔管理頁顯示空狀態
        @Test
        func lookupManagementEmptyBaseline() async {
            // Given
            await LookupCatalog.withIsolatedStorage {
                TestDependencies.withFixedNow {
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
                        as: .image(drawHierarchyInKeyWindow: true)
                    )
                }
            }
        }

        /// 商品類別主檔載入失敗時顯示錯誤文字
        @Test
        func lookupManagementLoadFailureBaseline() async {
            // Given
            await LookupCatalog.withIsolatedStorage {
                TestDependencies.withFixedNow {
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
                        as: .image(drawHierarchyInKeyWindow: true)
                    )
                }
            }
        }

        /// 改名表單顯示既有商品類別與送出按鈕
        @Test
        func lookupNameEditorSheetRenameBaseline() async {
            // Given
            await LookupCatalog.withIsolatedStorage {
                TestDependencies.withFixedNow {
                    // When
                    let view = LookupNameEditorSheet(
                        title: "重新命名商品類別",
                        message: "改名後，引用此名稱的訂單也會一併更新。",
                        namePlaceholder: "類別名稱",
                        submitTitle: "儲存",
                        initialName: "服飾"
                    ) { _ in }
                    .environment(\.locale, AppLanguage.traditionalChinese.locale)
                    .frame(width: 393, height: 852)

                    // Then
                    assertSnapshot(
                        of: view,
                        as: .image(drawHierarchyInKeyWindow: true)
                    )
                }
            }
        }
    }

#endif
