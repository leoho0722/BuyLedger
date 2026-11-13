//
//  AccessibilityIdentifierScanCases.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/13.
//

import Testing

/// `AccessibilityIdentifierScanner` 的合成原始碼案例，證明每條規則會失敗、合規寫法不誤判
enum AccessibilityIdentifierScanCases {

    // MARK: - Properties

    /// 基準的固定值宣告，合規
    private static let rootMember = #"static let listRoot = "orders.list.root""#

    /// 基準的組出前綴宣告，合規，`option` 前綴為 `orders.list.statusChip`
    private static let chipMember = #"""
        static func statusChip(_ key: String) -> String {
            option("orders.list.statusChip", key: key)
        }
        """#
}

// MARK: - Nested Types

extension AccessibilityIdentifierScanCases {

    /// 預期回報違規的案例
    struct ViolationCase: CustomTestStringConvertible, Sendable {

        /// 供測試失敗訊息辨識此案例，同時違反兩條規則的案例在名稱說明原因
        let name: String

        /// 命名空間目錄的合成原始檔
        let namespaceFiles: [AccessibilityIdentifierScanner.SourceFile]

        /// 範圍外目錄的合成原始檔，預設沒有
        var outsideFiles: [AccessibilityIdentifierScanner.SourceFile] = []

        /// 需要確認有原始檔的範圍外目錄名稱，空清單時不檢查
        var outsideRoots: [String] = []

        /// 宣告系統 identifier 的範圍外檔案路徑，未指定時不檢查
        var systemIdentifierPath: String? = nil

        /// 預期回報的規則集合，寫該案例實際會同時破壞的全部規則
        let expectedRules: Set<AccessibilityIdentifierScanner.Rule>

        /// 測試報告顯示的案例名稱
        var testDescription: String {
            name
        }
    }

    /// 預期沒有違規的合規案例
    struct CompliantCase: CustomTestStringConvertible, Sendable {

        /// 供測試失敗訊息辨識此案例
        let name: String

        /// 命名空間目錄的合成原始檔
        let namespaceFiles: [AccessibilityIdentifierScanner.SourceFile]

        /// 範圍外目錄的合成原始檔，預設沒有
        var outsideFiles: [AccessibilityIdentifierScanner.SourceFile] = []

        /// 需要確認有原始檔的範圍外目錄名稱，空清單時不檢查
        var outsideRoots: [String] = []

        /// 宣告系統 identifier 的範圍外檔案路徑，未指定時不檢查
        var systemIdentifierPath: String? = nil

        /// 預期掃到的固定值，依輸入檔案順序再依宣告順序排列
        let expectedFixedValues: [String]

        /// 預期掃到的組出前綴，依輸入檔案順序再依宣告順序排列
        let expectedPrefixValues: [String]

        /// 測試報告顯示的案例名稱
        var testDescription: String {
            name
        }
    }

    /// 只有一筆違規的案例，驗證違規描述開頭的位置、型別、名稱與值
    struct DescriptionPrefixCase: CustomTestStringConvertible, Sendable {

        /// 供測試失敗訊息辨識此案例
        let name: String

        /// 命名空間目錄的合成原始檔
        let namespaceFiles: [AccessibilityIdentifierScanner.SourceFile]

        /// 範圍外目錄的合成原始檔，預設沒有
        var outsideFiles: [AccessibilityIdentifierScanner.SourceFile] = []

        /// 需要確認有原始檔的範圍外目錄名稱，空清單時不檢查
        var outsideRoots: [String] = []

        /// 宣告系統 identifier 的範圍外檔案路徑，未指定時不檢查
        var systemIdentifierPath: String? = nil

        /// 預期的違規描述開頭，含 `"<值>"` 與其後的空格
        let expectedPrefix: String

        /// 測試報告顯示的案例名稱
        var testDescription: String {
            name
        }
    }
}

// MARK: - Computed Properties

extension AccessibilityIdentifierScanCases {

    /// 預期回報違規的全部案例，每條規則至少有一筆預期集合只含該規則
    static var violationCases: [ViolationCase] {
        [
            definitionFormCases,
            declarationLocationCases,
            systemIdentifierLiteralCases,
            shapeCases,
            firstSegmentCases,
            asciiCases,
            duplicateValueCases,
            prefixOverlapCases,
            emptyScanCases,
        ].flatMap { $0 }
    }

    /// 預期沒有違規的合規案例，含 spec 示例表中判為 passes 的列
    static var compliantCases: [CompliantCase] {
        [
            CompliantCase(
                name: "範圍外兩個目錄各有原始檔",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile("BuyLedger/App/Probe.swift", "struct Probe {}"),
                    sourceFile("BuyLedgerUITests/Screens/ProbeScreen.swift", "struct ProbeScreen {}"),
                ],
                outsideRoots: ["BuyLedger", "BuyLedgerUITests"],
                expectedFixedValues: ["orders.list.root"],
                expectedPrefixValues: ["orders.list.statusChip"]
            ),
            CompliantCase(
                name: "系統 identifier 引用常數且註解與較長訊息不算字面值違規",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile(
                        "BuyLedgerUITests/Support/SystemAccessibilityID.swift",
                        #"""
                        enum SystemAccessibilityID {

                            static let backButton: String = "BackButton"
                        }
                        """#
                    ),
                    sourceFile(
                        "BuyLedgerUITests/Screens/ProbeScreen.swift",
                        #"""
                        let button = app.buttons[SystemAccessibilityID.backButton]
                        // "BackButton"
                        let message = "找不到 BackButton 或其他按鈕"
                        """#
                    ),
                ],
                systemIdentifierPath: "BuyLedgerUITests/Support/SystemAccessibilityID.swift",
                expectedFixedValues: ["orders.list.root"],
                expectedPrefixValues: ["orders.list.statusChip"]
            ),
            CompliantCase(
                name: "示例表通過列：loading 明寫 String 型別",
                namespaceFiles: dashboard(#"static let loading: String = "dashboard.loading""#),
                expectedFixedValues: ["orders.list.root", "dashboard.loading"],
                expectedPrefixValues: ["orders.list.statusChip"]
            ),
            CompliantCase(
                name: "示例表通過列：loading 在下一行指定字面值",
                namespaceFiles: dashboard(
                    #"""
                    static let loading =
                        "dashboard.loading"
                    """#
                ),
                expectedFixedValues: ["orders.list.root", "dashboard.loading"],
                expectedPrefixValues: ["orders.list.statusChip"]
            ),
            CompliantCase(
                name: "示例表通過列：loading 字面值後接行尾註解",
                namespaceFiles: dashboard(
                    #"static let loading = "dashboard.loading" // shown while loading"#
                ),
                expectedFixedValues: ["orders.list.root", "dashboard.loading"],
                expectedPrefixValues: ["orders.list.statusChip"]
            ),
            CompliantCase(
                name: "示例表通過列：row 包裝函式的本體在同一行",
                namespaceFiles: orders(
                    #"static func row(orderID: String) -> String { BLAccessibilityID.row("orders.list.row", key: orderID) }"#
                ),
                expectedFixedValues: ["orders.list.root"],
                expectedPrefixValues: ["orders.list.statusChip", "orders.list.row"]
            ),
            CompliantCase(
                name: "示例表通過列：固定值與前綴的形狀",
                namespaceFiles: [
                    file(
                        "BLAccessibilityID+Orders.swift",
                        type: "Orders",
                        body: #"""
                            static let addButton = "orders.list.addButton"

                            static let paymentMethodAll = "orders.list.paymentMethodMenu.all"

                            static func paymentMethodOption(_ key: String) -> String {
                                option("orders.list.paymentMethodMenu.option", key: key)
                            }
                            """#
                    ),
                    file(
                        "BLAccessibilityID+Fx.swift",
                        type: "Fx",
                        body: #"static let root = "fx.root""#
                    ),
                ],
                expectedFixedValues: [
                    "orders.list.addButton",
                    "orders.list.paymentMethodMenu.all",
                    "fx.root",
                ],
                expectedPrefixValues: ["orders.list.paymentMethodMenu.option"]
            ),
            CompliantCase(
                name: "兩段與四段的邊界、段落含數字",
                namespaceFiles: [
                    file(
                        "BLAccessibilityID+OrderEdit.swift",
                        type: "OrderEdit",
                        body: #"""
                            static let root = "orderEdit.root"

                            static let photoCell = "orderEdit.photo2.row.cell"

                            static func thumbnailItem(_ key: String) -> String {
                                option("orderEdit.photo2.thumb.item", key: key)
                            }
                            """#
                    ),
                ],
                expectedFixedValues: ["orderEdit.root", "orderEdit.photo2.row.cell"],
                expectedPrefixValues: ["orderEdit.photo2.thumb.item"]
            ),
            CompliantCase(
                name: "示例表通過列：固定值與 option 前綴同值",
                namespaceFiles: [
                    file(
                        "BLAccessibilityID+Orders.swift",
                        type: "Orders",
                        body: #"""
                            static let chip = "orders.list.chip"

                            static func chipOption(_ key: String) -> String {
                                option("orders.list.chip", key: key)
                            }
                            """#
                    ),
                ],
                expectedFixedValues: ["orders.list.chip"],
                expectedPrefixValues: ["orders.list.chip"]
            ),
            CompliantCase(
                name: "示例表通過列：查詢前綴互不涵蓋",
                namespaceFiles: [
                    file(
                        "BLAccessibilityID+Orders.swift",
                        type: "Orders",
                        body: #"""
                            static let listRoot = "orders.list.root"

                            static func categoryOption(_ key: String) -> String {
                                option("orders.filter.category", key: key)
                            }

                            static func categoryGroupOption(_ key: String) -> String {
                                option("orders.filter.categoryGroup", key: key)
                            }

                            static func row(orderID: String) -> String {
                                BLAccessibilityID.row("orders.list.row", key: orderID)
                            }
                            """#
                    ),
                ],
                expectedFixedValues: ["orders.list.root"],
                expectedPrefixValues: [
                    "orders.filter.category",
                    "orders.filter.categoryGroup",
                    "orders.list.row",
                ]
            ),
            CompliantCase(
                name: "註解與字串內的宣告字樣、引號與大括號不影響掃描",
                namespaceFiles: [
                    sourceFile(
                        "BLAccessibilityID+Orders.swift",
                        #"""
                        /// 文件註解提到 static let fake = "orders.list.fake" 與 } { 都不是宣告
                        /* 區塊註解 /* 巢狀 extension BLAccessibilityID { */ 仍在註解內 } */
                        extension BLAccessibilityID {

                            // enum Fake { static let hidden = "orders.list.hidden" }
                            enum Orders {

                                /// 引號 " 與大括號 { 在註解內
                                static let listRoot = "orders.list.root" // 行尾註解的 "quote" 與 }

                                /* static func hidden(_ key: String) -> String { option("orders.list.hidden", key: key) } */
                                static func statusChip(_ key: String) -> String {
                                    option("orders.list.statusChip", key: key)
                                }
                            }
                        }
                        """#
                    ),
                ],
                expectedFixedValues: ["orders.list.root"],
                expectedPrefixValues: ["orders.list.statusChip"]
            ),
            CompliantCase(
                name: "extension BLAccessibilityID.Orders 拆檔",
                namespaceFiles: [
                    file(
                        "BLAccessibilityID+Orders.swift",
                        type: "Orders",
                        body: [rootMember, chipMember].joined(separator: "\n\n")
                    ),
                    sourceFile(
                        "BLAccessibilityID+OrdersDetail.swift",
                        #"""
                        extension BLAccessibilityID.Orders {

                            static let detailRoot = "orders.detail.root"

                            static func detailRow(orderID: String) -> String {
                                BLAccessibilityID.row("orders.detail.row", key: orderID)
                            }
                        }
                        """#
                    ),
                ],
                expectedFixedValues: ["orders.list.root", "orders.detail.root"],
                expectedPrefixValues: ["orders.list.statusChip", "orders.detail.row"]
            ),
            CompliantCase(
                name: "三個組字串函式本體與巢狀型別同名的 static func row",
                namespaceFiles: [
                    sourceFile(
                        "BLAccessibilityID.swift",
                        #"""
                        /// UI 測試定位元素用的 accessibility identifier 常數
                        enum BLAccessibilityID {}

                        // MARK: - Internal Method

                        extension BLAccessibilityID {

                            /// 組出列舉型集合的 identifier
                            static func option(_ prefix: String, key: String) -> String {
                                "\(prefix).\(key)"
                            }

                            /// 組出使用者資料列的 identifier
                            static func row(_ prefix: String, key: String) -> String {
                                "\(prefix):\(key)"
                            }

                            /// 組出純序位集合的 identifier
                            static func indexed(_ prefix: String, index: Int) -> String {
                                "\(prefix).index.\(index)"
                            }
                        }
                        """#
                    ),
                    file(
                        "BLAccessibilityID+Orders.swift",
                        type: "Orders",
                        body: #"""
                            static let listRoot = "orders.list.root"

                            static func row(orderID: String) -> String {
                                BLAccessibilityID.row("orders.list.row", key: orderID)
                            }

                            static func detailRow(orderID: String) -> String {
                                BLAccessibilityID.row("orders.detail.row", key: orderID)
                            }
                            """#
                    ),
                    file(
                        "BLAccessibilityID+Campaigns.swift",
                        type: "Campaigns",
                        body: #"""
                            static let listRoot = "campaigns.list.root"

                            static func row(campaignID: String) -> String {
                                BLAccessibilityID.row("campaigns.list.row", key: campaignID)
                            }
                            """#
                    ),
                ],
                expectedFixedValues: ["orders.list.root", "campaigns.list.root"],
                expectedPrefixValues: ["orders.list.row", "orders.detail.row", "campaigns.list.row"]
            ),
            CompliantCase(
                name: "只含 case 的巢狀列舉與深層巢狀型別",
                namespaceFiles: [
                    file(
                        "BLAccessibilityID+Orders.swift",
                        type: "Orders",
                        body: #"""
                            static let listRoot = "orders.list.root"

                            static func statusChip(_ key: String) -> String {
                                option("orders.list.statusChip", key: key)
                            }

                            /// 摘要種類
                            enum SummaryTile: String {

                                /// 營收
                                case revenue

                                /// 成本
                                case cost
                            }

                            enum Detail {

                                static let root = "orders.detail.root"
                            }
                            """#
                    ),
                    file(
                        "BLAccessibilityID+Common.swift",
                        type: "Common",
                        body: #"""
                            static let keyboardDoneButton = "common.keyboard.doneButton"

                            enum Feature: String, Sendable {

                                case orders, campaigns
                            }

                            enum Kind: Sendable {

                                case a
                            }

                            enum AlternateFeature: Sendable, String {

                                case orders
                            }
                            """#
                    ),
                ],
                expectedFixedValues: [
                    "orders.list.root",
                    "orders.detail.root",
                    "common.keyboard.doneButton",
                ],
                expectedPrefixValues: ["orders.list.statusChip"]
            ),
            CompliantCase(
                name: "示例表通過列：接受的定義形式",
                namespaceFiles: [
                    file(
                        "BLAccessibilityID+Dashboard.swift",
                        type: "Dashboard",
                        body: #"""
                            static let loading = "dashboard.loading"

                            static let typed: String = "dashboard.typed"

                            static let wrapped =
                                "dashboard.wrapped"

                            static let commented = "dashboard.commented" // 載入時顯示

                            static let blockCommented = "dashboard.blockCommented" /* 載入時顯示 */

                            static func recentOrderRow(orderID: String) -> String {
                                BLAccessibilityID.row(
                                    "dashboard.recentOrder",
                                    key: orderID
                                )
                            }

                            static func summaryTile(_ index: Int) -> String {
                                indexed("dashboard.summaryTile", index: index)
                            }

                            static func summaryKind(_ kind: SummaryKind) -> String {
                                option("dashboard.summaryKind", key: kind.rawValue)
                            }

                            static func longSignature(
                                customerName: String
                            ) -> String {
                                BLAccessibilityID.row("dashboard.longSignature", key: customerName)
                            }
                            """#
                    ),
                ],
                expectedFixedValues: [
                    "dashboard.loading",
                    "dashboard.typed",
                    "dashboard.wrapped",
                    "dashboard.commented",
                    "dashboard.blockCommented",
                ],
                expectedPrefixValues: [
                    "dashboard.recentOrder",
                    "dashboard.summaryTile",
                    "dashboard.summaryKind",
                    "dashboard.longSignature",
                ]
            ),
            CompliantCase(
                name: "型別名稱轉 lowerCamelCase 作為第一段",
                namespaceFiles: orders() + [
                    file(
                        "BLAccessibilityID+AISummary.swift",
                        type: "AISummary",
                        body: #"""
                            static let root = "aiSummary.root"

                            static func chunk(_ index: Int) -> String {
                                indexed("aiSummary.chunk", index: index)
                            }
                            """#
                    ),
                    file(
                        "BLAccessibilityID+Fx.swift",
                        type: "Fx",
                        body: #"static let root = "fx.root""#
                    ),
                    file(
                        "BLAccessibilityID+OptionPicker.swift",
                        type: "OptionPicker",
                        body: #"static let root = "optionPicker.root""#
                    ),
                    file(
                        "BLAccessibilityID+AI.swift",
                        type: "AI",
                        body: #"static let root = "ai.root""#
                    ),
                    file(
                        "BLAccessibilityID+URLSession.swift",
                        type: "URLSession",
                        body: #"static let root = "urlSession.root""#
                    ),
                ],
                expectedFixedValues: [
                    "orders.list.root",
                    "aiSummary.root",
                    "fx.root",
                    "optionPicker.root",
                    "ai.root",
                    "urlSession.root",
                ],
                expectedPrefixValues: ["orders.list.statusChip", "aiSummary.chunk"]
            ),
            CompliantCase(
                name: "範圍外檔案只引用或名稱相近，不算擴充",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile(
                        "BuyLedger/App/Sample.swift",
                        #"""
                        // extension BLAccessibilityID {
                        /// enum BLAccessibilityID {}
                        /* extension BLAccessibilityID.Orders {} */
                        let note = "extension BLAccessibilityID { }"
                        struct BLAccessibilityIDTests {}
                        extension BLAccessibilityIDMock {}
                        let rootID = BLAccessibilityID.Orders.listRoot
                        let kinds: Set<BLAccessibilityID.Dashboard.KPI> = []
                        func tap(_ kind: BLAccessibilityID.Dashboard.KPI) {}
                        """#
                    ),
                    sourceFile(
                        "BuyLedgerUITests/Screens/Sample.swift",
                        #"""
                        let chip = BLAccessibilityID.Orders.statusChip("all")
                        let prefix = BLAccessibilityID.option("orders.list.statusChip", key: "")
                        """#
                    ),
                ],
                expectedFixedValues: ["orders.list.root"],
                expectedPrefixValues: ["orders.list.statusChip"]
            ),
        ]
    }

    /// 跨檔、多筆違規的合成命名空間檔案，輸入順序與排序後的順序相反
    static var descriptionNamespaceFiles: [AccessibilityIdentifierScanner.SourceFile] {
        [
            sourceFile(
                "BLAccessibilityID+OrdersDetail.swift",
                #"""
                extension BLAccessibilityID.Orders {

                    static let detailRoot = "orders.detail.root"

                    static let listRootAgain = "orders.list.root"
                }
                """#
            ),
            sourceFile(
                "BLAccessibilityID+Orders.swift",
                #"""
                extension BLAccessibilityID {

                    enum Orders {

                        static let listRoot = "orders.list.root"

                        static let listRootCopy = "orders.list.root"

                        static func statusChip(_ key: String) -> String {
                            option("orders.list.statusChip", key: key)
                        }

                        static let statusChipAll = "orders.list.statusChip.all"
                    }
                }
                """#
            ),
        ]
    }

    /// 根層同名組字串函式的合成檔案，排序在前的檔案先輸入，另保留合規的固定值與前綴
    static var overloadedComposerNamespaceFiles: [AccessibilityIdentifierScanner.SourceFile] {
        orders() + [
            sourceFile(
                "BLAccessibilityID+Builders.swift",
                #"""
                extension BLAccessibilityID {

                    static func option(_ prefix: String, key: Int) -> String {
                        "\(prefix)\(key)"
                    }
                }
                """#
            ),
            sourceFile(
                "BLAccessibilityID.swift",
                #"""
                extension BLAccessibilityID {

                    static func option(_ prefix: String, key: String) -> String {
                        "\(prefix).\(key)"
                    }
                }
                """#
            ),
        ]
    }

    /// 各規則只有一筆違規的案例，驗證違規描述開頭的格式
    static var descriptionPrefixCases: [DescriptionPrefixCase] {
        [
            DescriptionPrefixCase(
                name: "形狀違規",
                namespaceFiles: orders(#"static let single = "orders""#),
                expectedPrefix: #"BLAccessibilityID+Orders.swift:11 Orders.single "orders" "#
            ),
            DescriptionPrefixCase(
                name: "第一段違規",
                namespaceFiles: orders(#"static let wrongOwner = "order.list.root""#),
                expectedPrefix: #"BLAccessibilityID+Orders.swift:11 Orders.wrongOwner "order.list.root" "#
            ),
            DescriptionPrefixCase(
                name: "只含 ASCII 違規",
                namespaceFiles: orders(#"static let cafeRow = "orders.list.café""#),
                expectedPrefix: #"BLAccessibilityID+Orders.swift:11 Orders.cafeRow "orders.list.café" "#
            ),
            DescriptionPrefixCase(
                name: "組出前綴的形狀違規以包裝函式名稱為名稱",
                namespaceFiles: orders(
                    #"static func tooLong(_ key: String) -> String { option("orders.list.a.b.c", key: key) }"#
                ),
                expectedPrefix: #"BLAccessibilityID+Orders.swift:11 Orders.tooLong "orders.list.a.b.c" "#
            ),
            DescriptionPrefixCase(
                name: "定義形式違規沒有值",
                namespaceFiles: dashboard(#"static let loading = "dashboard.\("loading")""#),
                expectedPrefix: #"BLAccessibilityID+Dashboard.swift:5 Dashboard.loading "" "#
            ),
            DescriptionPrefixCase(
                name: "同層 option 遮蔽只點名未限定呼叫的 statusChip",
                namespaceFiles: orders(
                    #"""
                    static func option(_ prefix: String, key: String) -> String {
                        BLAccessibilityID.row("orders.list.picked", key: key)
                    }
                    """#
                ),
                expectedPrefix: #"BLAccessibilityID+Orders.swift:7 Orders.statusChip "" "#
            ),
            DescriptionPrefixCase(
                name: "系統 identifier 字面值違規點名常數與字面值位置",
                namespaceFiles: orders(),
                outsideFiles: systemIdentifierLiteralOutsideFiles,
                systemIdentifierPath: "BuyLedgerUITests/Support/SystemAccessibilityID.swift",
                expectedPrefix: #"BuyLedgerUITests/Screens/ProbeScreen.swift:1 SystemAccessibilityID.backButton "BackButton" "#
            ),
            DescriptionPrefixCase(
                name: "宣告位置違規以 BLAccessibilityID 的宣告種類為名稱且沒有值",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile(
                        "BuyLedger/App/BuyLedgerApp.swift",
                        #"""
                        import Foundation

                        extension BLAccessibilityID {}
                        """#
                    ),
                ],
                expectedPrefix: #"BuyLedger/App/BuyLedgerApp.swift:3 BLAccessibilityID.extension "" "#
            ),
        ]
    }
}

// MARK: - Private Method

private extension AccessibilityIdentifierScanCases {

    /// 系統返回鍵常數與另一檔直接使用相同字面值的合成原始檔
    static var systemIdentifierLiteralOutsideFiles: [AccessibilityIdentifierScanner.SourceFile] {
        [
            sourceFile(
                "BuyLedgerUITests/Support/SystemAccessibilityID.swift",
                #"""
                enum SystemAccessibilityID {

                    static let backButton = "BackButton"
                }
                """#
            ),
            sourceFile(
                "BuyLedgerUITests/Screens/ProbeScreen.swift",
                #"let button = app.buttons["BackButton"]"#
            ),
        ]
    }

    /// 定義形式違規：宣告或字面值不在接受清單內，其他規則不受影響
    static var definitionFormCases: [ViolationCase] {
        [
            ViolationCase(
                name: "固定值含插值",
                namespaceFiles: dashboard(#"static let loading = "dashboard.\("loading")""#),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "固定值以串接組出",
                namespaceFiles: dashboard(#"static let loading = prefix + ".loading""#),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "固定值引用其他常數",
                namespaceFiles: orders(#"static let loadingAlias = listRoot"#),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "固定值是組字串函式的呼叫結果",
                namespaceFiles: dashboard(
                    #"static let chipAll = option("dashboard.chip", key: "all")"#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "固定值是字面值後接成員呼叫",
                namespaceFiles: dashboard(
                    #"static let lowered = "Dashboard.Loading".lowercased()"#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "固定值是整數",
                namespaceFiles: dashboard(#"static let limit = 5"#),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "var 轉發其他常數",
                namespaceFiles: orders(#"static var legacyRoot: String { listRoot }"#),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "var 回傳字面值",
                namespaceFiles: dashboard(
                    #"static var legacyLoading: String { "dashboard.legacyLoading" }"#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "var 帶儲存值",
                namespaceFiles: dashboard(
                    #"static var mutableLoading = "dashboard.mutableLoading""#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "同一個 static let 宣告帶第二個綁定",
                namespaceFiles: dashboard(
                    #"static let first = "dashboard.first", second = "dashboard.second""#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "tuple 解構綁定",
                namespaceFiles: dashboard(
                    #"static let (left, right) = ("dashboard.left", "dashboard.right")"#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "沒有 static 的 let",
                namespaceFiles: dashboard(#"let instanceLoading = "dashboard.instanceLoading""#),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "固定值帶 available 屬性",
                namespaceFiles: dashboard(
                    #"@available(*, deprecated) static let loading = "dashboard.loading""#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "固定值帶 private 存取修飾",
                namespaceFiles: dashboard(#"private static let loading = "dashboard.loading""#),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "subscript",
                namespaceFiles: dashboard(
                    #"static subscript(key: String) -> String { "dashboard.\(key)" }"#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "static func 直接回傳字面值",
                namespaceFiles: dashboard(
                    #"static func literalLoading() -> String { "dashboard.literalLoading" }"#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "包裝函式包裝其他包裝函式",
                namespaceFiles: orders(
                    #"static func chip(_ key: String) -> String { statusChip(key) }"#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "包裝函式自行串接",
                namespaceFiles: orders(
                    #"static func detailRow(_ id: String) -> String { detailRoot + id }"#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "組字串呼叫的前綴是變數",
                namespaceFiles: dashboard(
                    #"static func chip(_ key: String) -> String { option(chipPrefix, key: key) }"#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "組字串呼叫的前綴以串接組出",
                namespaceFiles: dashboard(
                    #"static func chip(_ key: String) -> String { option("dashboard" + ".chip", key: key) }"#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "組字串呼叫的前綴含插值",
                namespaceFiles: dashboard(
                    #"static func chip(_ key: String) -> String { option("dashboard.\(key)", key: key) }"#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "組字串呼叫的第二個引數是字串字面值",
                namespaceFiles: dashboard(
                    #"static func chipAll() -> String { option("dashboard.chip", key: "all") }"#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "組字串呼叫的第二個引數含插值字面值",
                namespaceFiles: dashboard(
                    #"static func chip(_ key: String) -> String { option("dashboard.chip", key: "\(key)x") }"#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "包裝函式本體有多個敘述",
                namespaceFiles: dashboard(
                    #"""
                    static func chip(_ key: String) -> String {
                        let normalized = key
                        return option("dashboard.chip", key: normalized)
                    }
                    """#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "包裝函式明寫 return",
                namespaceFiles: dashboard(
                    #"static func recentOrderRow(orderID: String) -> String { return BLAccessibilityID.row("dashboard.recentOrder.row", key: orderID) }"#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "包裝函式帶 async throws 並回傳可選字串",
                namespaceFiles: orders(
                    #"static func row(orderID: String) async throws -> String? { BLAccessibilityID.row("orders.list.row", key: orderID) }"#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "包裝函式回傳 Substring",
                namespaceFiles: dashboard(
                    #"static func recentOrderRow(orderID: String) -> Substring { BLAccessibilityID.row("dashboard.recentOrder.row", key: orderID) }"#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "參數預設值含字串字面值",
                namespaceFiles: dashboard(
                    #"static func chip(_ key: String = "all") -> String { option("dashboard.chip", key: key) }"#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "case 指定字串 raw value",
                namespaceFiles: dashboard(
                    #"""
                    enum Kind: String {

                        case shipping = "shipping"
                    }
                    """#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "case 指定整數 raw value",
                namespaceFiles: dashboard(
                    #"""
                    enum Kind: Int {

                        case first = 1
                    }
                    """#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "巢狀列舉遵循清單含 CaseIterable",
                namespaceFiles: dashboard(
                    #"""
                    enum Kind: String, CaseIterable {

                        case a
                    }
                    """#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "巢狀列舉遵循清單含其他型別",
                namespaceFiles: dashboard(
                    #"""
                    enum Kind: OrdersExtraIDs {

                        case a
                    }
                    """#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "raw string 字面值",
                namespaceFiles: dashboard(##"static let raw = #"dashboard.raw"#"##),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "多行字串字面值",
                namespaceFiles: dashboard(
                    ##"""
                    static let multi = """
                        dashboard.multi
                        """
                    """##
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "巢狀型別自行宣告組字串函式",
                namespaceFiles: dashboard(
                    #"""
                    static func option(_ prefix: String, key: String) -> String {
                        "\(prefix).\(key)"
                    }
                    """#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "巢狀 BLAccessibilityID 遮蔽命名空間且自行回傳模板，均違反定義形式",
                namespaceFiles: orders(
                    #"""
                    enum BLAccessibilityID {

                        static func row(_ prefix: String, key: String) -> String {
                            "\(prefix):\(key)"
                        }
                    }
                    """#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "深層巢狀 BLAccessibilityID 遮蔽命名空間",
                namespaceFiles: orders(
                    #"""
                    enum Detail {

                        enum BLAccessibilityID {}
                    }
                    """#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "同層宣告 option 遮蔽較早的未限定包裝呼叫",
                namespaceFiles: orders(
                    #"""
                    static func option(_ prefix: String, key: String) -> String {
                        BLAccessibilityID.row("orders.list.picked", key: key)
                    }
                    """#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "示例表違規列：Orders 的同名 option 遮蔽 chip 呼叫",
                namespaceFiles: [
                    file(
                        "BLAccessibilityID+Orders.swift",
                        type: "Orders",
                        body: #"""
                            static let listRoot = "orders.list.root"

                            static func chip(_ key: String) -> String {
                                option("orders.list.chip", key: key)
                            }

                            static func option(_ prefix: String, key: String) -> String {
                                BLAccessibilityID.row("orders.list.picked", key: key)
                            }
                            """#
                    ),
                ],
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "另一檔擴充的同名 option 遮蔽未限定包裝呼叫",
                namespaceFiles: orders() + [
                    sourceFile(
                        "BLAccessibilityID+OrdersExtra.swift",
                        #"""
                        extension BLAccessibilityID.Orders {

                            static func option(_ prefix: String, key: String) -> String {
                                BLAccessibilityID.row("orders.list.picked", key: key)
                            }
                        }
                        """#
                    ),
                ],
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "深層同名 option 使所屬型別的未限定包裝呼叫保守判違規",
                namespaceFiles: orders(
                    #"""
                    enum Detail {

                        static func option(_ prefix: String, key: String) -> String {
                            BLAccessibilityID.row("orders.detail.picked", key: key)
                        }
                    }
                    """#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "參數 option 遮蔽包裝函式的未限定呼叫",
                namespaceFiles: [
                    file(
                        "BLAccessibilityID+Orders.swift",
                        type: "Orders",
                        body: #"""
                            static let listRoot = "orders.list.root"

                            static func row(orderID: String) -> String {
                                BLAccessibilityID.row("orders.list.row", key: orderID)
                            }

                            static func statusChip(_ key: String, option: Hijack = Hijack()) -> String {
                                option("orders.list.statusChip", key: key)
                            }
                            """#
                    ),
                ],
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "組字串函式本體多出另一個敘述與字面值",
                namespaceFiles: orders() + [
                    sourceFile(
                        "BLAccessibilityID.swift",
                        #"""
                        extension BLAccessibilityID {

                            static func option(_ prefix: String, key: String) -> String {
                                let separator = "."
                                return "\(prefix)\(separator)\(key)"
                            }
                        }
                        """#
                    ),
                ],
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "組字串函式的模板串接第二個字面值",
                namespaceFiles: orders() + [
                    sourceFile(
                        "BLAccessibilityID.swift",
                        #"""
                        extension BLAccessibilityID {

                            static func row(_ prefix: String, key: String) -> String {
                                "\(prefix):\(key)" + "-row"
                            }
                        }
                        """#
                    ),
                ],
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "組字串函式模板的插值內含字串字面值",
                namespaceFiles: orders() + [
                    sourceFile(
                        "BLAccessibilityID.swift",
                        #"""
                        extension BLAccessibilityID {

                            static func row(_ prefix: String, key: String) -> String {
                                "\(prefix)\(".")\(key)"
                            }
                        }
                        """#
                    ),
                ],
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "組字串函式模板是多行字串",
                namespaceFiles: orders() + [
                    sourceFile(
                        "BLAccessibilityID.swift",
                        ##"""
                        extension BLAccessibilityID {

                            static func row(_ prefix: String, key: String) -> String {
                                """
                                \(prefix):\(key)
                                """
                            }
                        }
                        """##
                    ),
                ],
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "組字串函式模板是 raw string",
                namespaceFiles: orders() + [
                    sourceFile(
                        "BLAccessibilityID.swift",
                        ##"""
                        extension BLAccessibilityID {

                            static func row(_ prefix: String, key: String) -> String {
                                #"\#(prefix):\#(key)"#
                            }
                        }
                        """##
                    ),
                ],
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "組字串函式本體不是字串模板",
                namespaceFiles: orders() + [
                    sourceFile(
                        "BLAccessibilityID.swift",
                        #"""
                        extension BLAccessibilityID {

                            static func indexed(_ prefix: String, index: Int) -> String {
                                String(index)
                            }
                        }
                        """#
                    ),
                ],
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "多出第四個組字串函式",
                namespaceFiles: orders() + [
                    sourceFile(
                        "BLAccessibilityID.swift",
                        #"""
                        extension BLAccessibilityID {

                            static func extra(_ prefix: String, key: String) -> String {
                                "\(prefix)-\(key)"
                            }
                        }
                        """#
                    ),
                ],
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "跨檔重載根層 option，排序在後的檔案先輸入且兩處均違規",
                namespaceFiles: Array(overloadedComposerNamespaceFiles.reversed()),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "跨檔重載根層 option，排序在前的檔案先輸入且兩處均違規",
                namespaceFiles: overloadedComposerNamespaceFiles,
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "根層組字串函式帶 async throws 並回傳可選字串",
                namespaceFiles: orders() + [
                    sourceFile(
                        "BLAccessibilityID.swift",
                        #"""
                        extension BLAccessibilityID {

                            static func row(_ prefix: String, key: String) async throws -> String? {
                                "\(prefix):\(key)"
                            }
                        }
                        """#
                    ),
                ],
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "根層組字串函式回傳 Substring",
                namespaceFiles: orders() + [
                    sourceFile(
                        "BLAccessibilityID.swift",
                        #"""
                        extension BLAccessibilityID {

                            static func row(_ prefix: String, key: String) -> Substring {
                                "\(prefix):\(key)"
                            }
                        }
                        """#
                    ),
                ],
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "檔案最外層的字串字面值",
                namespaceFiles: orders() + [
                    sourceFile(
                        "BLAccessibilityID+Global.swift",
                        #"let globalID = "orders.list.global""#
                    ),
                ],
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "條件編譯包住宣告",
                namespaceFiles: dashboard(
                    #"""
                    #if DEBUG
                    static let debugOnly = "dashboard.debugOnly"
                    #endif
                    """#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "同一行以分號串接兩個宣告，保守判違規",
                namespaceFiles: dashboard(
                    #"static let first = "dashboard.first"; static let second = "dashboard.second""#
                ),
                expectedRules: [.definitionForm]
            ),
            ViolationCase(
                name: "固定值以閉包立即呼叫組出",
                namespaceFiles: dashboard(
                    #"static let lazyLoading: String = { "dashboard.lazyLoading" }()"#
                ),
                expectedRules: [.definitionForm]
            ),
        ]
    }

    /// 宣告位置違規：範圍外目錄擴充或宣告 `BLAccessibilityID`，其他規則不受影響
    static var declarationLocationCases: [ViolationCase] {
        [
            ViolationCase(
                name: "App target 擴充 BLAccessibilityID",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile(
                        "BuyLedger/App/BuyLedgerApp.swift",
                        #"""
                        import Foundation

                        extension BLAccessibilityID {}
                        """#
                    ),
                ],
                expectedRules: [.declarationLocation]
            ),
            ViolationCase(
                name: "UI 測試 target 擴充 BLAccessibilityID.Orders",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile(
                        "BuyLedgerUITests/Support/Extra.swift",
                        #"extension BLAccessibilityID.Orders {}"#
                    ),
                ],
                expectedRules: [.declarationLocation]
            ),
            ViolationCase(
                name: "範圍外宣告 enum BLAccessibilityID",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile("BuyLedger/Core/Shadow.swift", #"enum BLAccessibilityID {}"#),
                ],
                expectedRules: [.declarationLocation]
            ),
            ViolationCase(
                name: "範圍外宣告 struct BLAccessibilityID",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile("BuyLedger/Core/Shadow.swift", #"struct BLAccessibilityID {}"#),
                ],
                expectedRules: [.declarationLocation]
            ),
            ViolationCase(
                name: "範圍外宣告 class BLAccessibilityID",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile("BuyLedger/Core/Shadow.swift", "class BLAccessibilityID {}"),
                ],
                expectedRules: [.declarationLocation]
            ),
            ViolationCase(
                name: "範圍外宣告 actor BLAccessibilityID",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile("BuyLedger/Core/Shadow.swift", "actor BLAccessibilityID {}"),
                ],
                expectedRules: [.declarationLocation]
            ),
            ViolationCase(
                name: "範圍外宣告 protocol BLAccessibilityID",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile("BuyLedger/Core/Shadow.swift", "protocol BLAccessibilityID {}"),
                ],
                expectedRules: [.declarationLocation]
            ),
            ViolationCase(
                name: "範圍外以 typealias 宣告 BLAccessibilityID",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile("BuyLedger/Core/Shadow.swift", "typealias BLAccessibilityID = Int"),
                ],
                expectedRules: [.declarationLocation]
            ),
            ViolationCase(
                name: "帶存取修飾的 extension",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile(
                        "BuyLedger/Core/Extra.swift",
                        #"public extension BLAccessibilityID {}"#
                    ),
                ],
                expectedRules: [.declarationLocation]
            ),
            ViolationCase(
                name: "extension 帶多餘空白與 protocol 遵循",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile(
                        "BuyLedger/Core/Extra.swift",
                        #"extension   BLAccessibilityID : Sendable {}"#
                    ),
                ],
                expectedRules: [.declarationLocation]
            ),
            ViolationCase(
                name: "extension 與型別名稱之間換行",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile(
                        "BuyLedger/Core/Extra.swift",
                        #"""
                        extension
                            BLAccessibilityID.Orders
                        {
                        }
                        """#
                    ),
                ],
                expectedRules: [.declarationLocation]
            ),
            ViolationCase(
                name: "extension 以模組名稱限定",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile(
                        "BuyLedgerUITests/Support/Extra.swift",
                        #"extension BuyLedger.BLAccessibilityID {}"#
                    ),
                ],
                expectedRules: [.declarationLocation]
            ),
            ViolationCase(
                name: "範圍外 extension 的命名空間名稱以反引號包住",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile(
                        "BuyLedgerUITests/Support/Extra.swift",
                        #"extension `BLAccessibilityID` {}"#
                    ),
                ],
                expectedRules: [.declarationLocation]
            ),
            ViolationCase(
                name: "範圍外以 typealias 轉名後擴充命名空間",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile(
                        "BuyLedger/Core/Extra.swift",
                        #"""
                        typealias ProbeIDs = BLAccessibilityID

                        extension ProbeIDs.Orders {}
                        """#
                    ),
                ],
                expectedRules: [.declarationLocation]
            ),
            ViolationCase(
                name: "範圍外 typealias 指向模組限定的巢狀命名空間",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile(
                        "BuyLedger/Core/Extra.swift",
                        #"typealias ProbeIDs = BuyLedger.BLAccessibilityID.Orders"#
                    ),
                ],
                expectedRules: [.declarationLocation]
            ),
            ViolationCase(
                name: "範圍外 typealias 在下一行以點接續命名空間後擴充",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile(
                        "BuyLedger/Core/Extra.swift",
                        #"""
                        typealias ProbeIDs = BuyLedger
                            .BLAccessibilityID

                        extension ProbeIDs.Orders {}
                        """#
                    ),
                ],
                expectedRules: [.declarationLocation]
            ),
            ViolationCase(
                name: "範圍外 typealias 的點在上一行結尾並接續命名空間後擴充",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile(
                        "BuyLedger/Core/Extra.swift",
                        #"""
                        typealias ProbeIDs = BuyLedger.
                            BLAccessibilityID

                        extension ProbeIDs.Orders {}
                        """#
                    ),
                ],
                expectedRules: [.declarationLocation]
            ),
            ViolationCase(
                name: "範圍外以括號包住命名空間的 typealias 後擴充",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile(
                        "BuyLedger/Core/Extra.swift",
                        #"""
                        typealias ProbeIDs = (BLAccessibilityID)

                        extension ProbeIDs.Orders {}
                        """#
                    ),
                ],
                expectedRules: [.declarationLocation]
            ),
            ViolationCase(
                name: "範圍外以泛型包住命名空間的 typealias 後擴充",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile(
                        "BuyLedger/Core/Extra.swift",
                        #"""
                        typealias Same<T> = T

                        typealias ProbeIDs = Same<BLAccessibilityID>

                        extension ProbeIDs.Orders {}
                        """#
                    ),
                ],
                expectedRules: [.declarationLocation]
            ),
            ViolationCase(
                name: "範圍外 extension 的 where 子句指定命名空間",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile(
                        "BuyLedger/Core/Extra.swift",
                        #"""
                        extension Equatable where Self == BLAccessibilityID.Orders {

                            static var hiddenChip: String {
                                "orders.list.statusChip.all"
                            }
                        }
                        """#
                    ),
                ],
                expectedRules: [.declarationLocation]
            ),
        ]
    }

    /// 系統 identifier 字面值違規：其他範圍外檔案直接重寫系統常數的值
    static var systemIdentifierLiteralCases: [ViolationCase] {
        [
            ViolationCase(
                name: "系統返回鍵在其他檔案直接使用字面值",
                namespaceFiles: orders(),
                outsideFiles: systemIdentifierLiteralOutsideFiles,
                systemIdentifierPath: "BuyLedgerUITests/Support/SystemAccessibilityID.swift",
                expectedRules: [.systemIdentifierLiteral]
            ),
            ViolationCase(
                name: "系統 identifier 受檢值取自帶型別的新增常數",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile(
                        "BuyLedgerUITests/Support/SystemAccessibilityID.swift",
                        #"""
                        enum SystemAccessibilityID {

                            static let probeControl: String = "PlatformProbe"
                        }
                        """#
                    ),
                    sourceFile(
                        "BuyLedgerUITests/Screens/ProbeScreen.swift",
                        #"let button = app.buttons["PlatformProbe"]"#
                    ),
                ],
                systemIdentifierPath: "BuyLedgerUITests/Support/SystemAccessibilityID.swift",
                expectedRules: [.systemIdentifierLiteral]
            ),
        ]
    }

    /// 形狀違規：固定值或前綴的段數與段落字元不符，含因而同時違反其他規則的案例
    static var shapeCases: [ViolationCase] {
        [
            ViolationCase(
                name: "固定值只有一段",
                namespaceFiles: orders(#"static let single = "orders""#),
                expectedRules: [.shape]
            ),
            ViolationCase(
                name: "固定值有五段",
                namespaceFiles: orders(#"static let tooLong = "orders.list.a.b.c""#),
                expectedRules: [.shape]
            ),
            ViolationCase(
                name: "固定值含冒號，冒號只由 row 在執行期組出",
                namespaceFiles: orders(#"static let rowSample = "orders.list.row:ORD-1""#),
                expectedRules: [.shape]
            ),
            ViolationCase(
                name: "固定值含冒號且落在 row 查詢前綴之下，同時違反形狀與前綴重疊",
                namespaceFiles: orders(
                    #"static func row(orderID: String) -> String { BLAccessibilityID.row("orders.list.row", key: orderID) }"#,
                    #"static let rowSample = "orders.list.row:ORD-1""#
                ),
                expectedRules: [.shape, .prefixOverlap]
            ),
            ViolationCase(
                name: "第一段首字大寫且與所屬型別不同，同時違反形狀與第一段",
                namespaceFiles: orders(#"static let capitalized = "Orders.listRoot""#),
                expectedRules: [.shape, .firstSegment]
            ),
            ViolationCase(
                name: "平台指定的 BackButton 放進共用命名空間，同時違反形狀與第一段",
                namespaceFiles: orders() + [
                    file(
                        "BLAccessibilityID+Common.swift",
                        type: "Common",
                        body: #"static let backButton = "BackButton""#
                    ),
                ],
                expectedRules: [.shape, .firstSegment]
            ),
            ViolationCase(
                name: "固定值有空段落",
                namespaceFiles: orders(#"static let emptySegment = "orders..root""#),
                expectedRules: [.shape]
            ),
            ViolationCase(
                name: "固定值結尾多一個點",
                namespaceFiles: orders(#"static let trailingDot = "orders.list.""#),
                expectedRules: [.shape]
            ),
            ViolationCase(
                name: "固定值開頭多一個點，同時違反形狀與第一段",
                namespaceFiles: orders(#"static let leadingDot = ".orders.root""#),
                expectedRules: [.shape, .firstSegment]
            ),
            ViolationCase(
                name: "固定值的段落以數字開頭",
                namespaceFiles: orders(#"static let digitFirst = "orders.1list.root""#),
                expectedRules: [.shape]
            ),
            ViolationCase(
                name: "固定值的段落含底線",
                namespaceFiles: orders(#"static let underscore = "orders.list.add_button""#),
                expectedRules: [.shape]
            ),
            ViolationCase(
                name: "固定值的段落含空白",
                namespaceFiles: orders(#"static let spaced = "orders.list.add button""#),
                expectedRules: [.shape]
            ),
            ViolationCase(
                name: "固定值的後段首字大寫",
                namespaceFiles: orders(#"static let capitalSegment = "orders.List.root""#),
                expectedRules: [.shape]
            ),
            ViolationCase(
                name: "option 前綴有五段",
                namespaceFiles: orders(
                    #"static func tooLong(_ key: String) -> String { option("orders.list.a.b.c", key: key) }"#
                ),
                expectedRules: [.shape]
            ),
            ViolationCase(
                name: "option 前綴只有一段，查詢前綴涵蓋所有 orders 開頭的值，同時違反形狀與前綴重疊",
                namespaceFiles: orders(
                    #"static func single(_ key: String) -> String { option("orders", key: key) }"#
                ),
                expectedRules: [.shape, .prefixOverlap]
            ),
            ViolationCase(
                name: "indexed 前綴只有一段",
                namespaceFiles: orders(
                    #"static func single(_ index: Int) -> String { indexed("orders", index: index) }"#
                ),
                expectedRules: [.shape]
            ),
            ViolationCase(
                name: "option 前綴含冒號",
                namespaceFiles: orders(
                    #"static func colon(_ key: String) -> String { option("orders.list.chip:x", key: key) }"#
                ),
                expectedRules: [.shape]
            ),
            ViolationCase(
                name: "row 前綴結尾多寫了分隔符號冒號",
                namespaceFiles: orders(
                    #"static func row(orderID: String) -> String { BLAccessibilityID.row("orders.list.row:", key: orderID) }"#
                ),
                expectedRules: [.shape]
            ),
            ViolationCase(
                name: "option 前綴結尾多寫了分隔符號點",
                namespaceFiles: orders(
                    #"static func dotted(_ key: String) -> String { option("orders.list.chip.", key: key) }"#
                ),
                expectedRules: [.shape]
            ),
            ViolationCase(
                name: "option 前綴第一段首字大寫，同時違反形狀與第一段",
                namespaceFiles: orders(
                    #"static func capital(_ key: String) -> String { option("Orders.list.chip", key: key) }"#
                ),
                expectedRules: [.shape, .firstSegment]
            ),
        ]
    }

    /// 第一段違規：第一段不等於所屬型別的 lowerCamelCase，或沒有所屬型別
    static var firstSegmentCases: [ViolationCase] {
        [
            ViolationCase(
                name: "固定值第一段與所屬型別不同",
                namespaceFiles: orders(#"static let wrongOwner = "order.list.root""#),
                expectedRules: [.firstSegment]
            ),
            ViolationCase(
                name: "extension 層級的固定值沒有所屬型別",
                namespaceFiles: orders() + [
                    sourceFile(
                        "BLAccessibilityID+Loose.swift",
                        #"""
                        extension BLAccessibilityID {

                            static let loose = "orders.list.loose"
                        }
                        """#
                    ),
                ],
                expectedRules: [.firstSegment]
            ),
            ViolationCase(
                name: "extension 層級的包裝函式沒有所屬型別",
                namespaceFiles: orders() + [
                    sourceFile(
                        "BLAccessibilityID+Loose.swift",
                        #"""
                        extension BLAccessibilityID {

                            static func looseChip(_ key: String) -> String {
                                option("orders.list.looseChip", key: key)
                            }
                        }
                        """#
                    ),
                ],
                expectedRules: [.firstSegment]
            ),
            ViolationCase(
                name: "前綴第一段屬於其他型別",
                namespaceFiles: dashboard(
                    #"static func chip(_ key: String) -> String { option("orders.list.chip", key: key) }"#
                ),
                expectedRules: [.firstSegment]
            ),
            ViolationCase(
                name: "深層巢狀型別以最外層型別為所屬，第一段不可用內層型別名稱",
                namespaceFiles: orders(
                    #"""
                    enum Detail {

                        static let root = "detail.root"
                    }
                    """#
                ),
                expectedRules: [.firstSegment]
            ),
            ViolationCase(
                name: "AISummary 只把首字母轉小寫",
                namespaceFiles: orders() + [
                    file(
                        "BLAccessibilityID+AISummary.swift",
                        type: "AISummary",
                        body: #"static let root = "aISummary.root""#
                    ),
                ],
                expectedRules: [.firstSegment]
            ),
            ViolationCase(
                name: "AISummary 第一段首字大寫，同時違反形狀與第一段",
                namespaceFiles: orders() + [
                    file(
                        "BLAccessibilityID+AISummary.swift",
                        type: "AISummary",
                        body: #"static let root = "AISummary.root""#
                    ),
                ],
                expectedRules: [.shape, .firstSegment]
            ),
            ViolationCase(
                name: "Fx 的第一段寫成 fX",
                namespaceFiles: orders() + [
                    file(
                        "BLAccessibilityID+Fx.swift",
                        type: "Fx",
                        body: #"static let root = "fX.root""#
                    ),
                ],
                expectedRules: [.firstSegment]
            ),
            ViolationCase(
                name: "OptionPicker 的第一段全小寫",
                namespaceFiles: orders() + [
                    file(
                        "BLAccessibilityID+OptionPicker.swift",
                        type: "OptionPicker",
                        body: #"static let root = "optionpicker.root""#
                    ),
                ],
                expectedRules: [.firstSegment]
            ),
            ViolationCase(
                name: "extension BLAccessibilityID.Orders 內的固定值第一段屬於其他型別",
                namespaceFiles: orders() + [
                    sourceFile(
                        "BLAccessibilityID+OrdersDetail.swift",
                        #"""
                        extension BLAccessibilityID.Orders {

                            static let crossed = "campaigns.list.crossed"
                        }
                        """#
                    ),
                ],
                expectedRules: [.firstSegment]
            ),
        ]
    }

    /// 只含 ASCII 違規：固定值或前綴含非 ASCII 字元
    static var asciiCases: [ViolationCase] {
        [
            ViolationCase(
                name: "固定值含非 ASCII 字母",
                namespaceFiles: orders(#"static let cafeRow = "orders.list.café""#),
                expectedRules: [.asciiOnly]
            ),
            ViolationCase(
                name: "固定值以西里爾字母 о 冒充拉丁字母 o",
                namespaceFiles: orders(#"static let lookalike = "orders.list.rооt""#),
                expectedRules: [.asciiOnly]
            ),
            ViolationCase(
                name: "固定值含全形數字",
                namespaceFiles: orders(#"static let fullWidth = "orders.list.row１""#),
                expectedRules: [.asciiOnly]
            ),
            ViolationCase(
                name: "固定值的段落是中文，首字不是小寫字母，同時違反形狀與只含 ASCII",
                namespaceFiles: orders(#"static let chinese = "orders.list.訂單""#),
                expectedRules: [.shape, .asciiOnly]
            ),
            ViolationCase(
                name: "前綴含非 ASCII 字母",
                namespaceFiles: orders(
                    #"static func cafe(_ key: String) -> String { option("orders.list.café", key: key) }"#
                ),
                expectedRules: [.asciiOnly]
            ),
            ViolationCase(
                name: "固定值結尾藏著零寬空白，同時違反形狀與只含 ASCII",
                namespaceFiles: orders("static let hidden = \"orders.list.root\u{200B}\""),
                expectedRules: [.shape, .asciiOnly]
            ),
        ]
    }

    /// 值重複違規：兩個固定值相同，或兩個組出前綴相同
    static var duplicateValueCases: [ViolationCase] {
        [
            ViolationCase(
                name: "示例表違規列：option 與 row 共用 orders.list.chip 前綴",
                namespaceFiles: orders(
                    #"static func chip(_ key: String) -> String { option("orders.list.chip", key: key) }"#,
                    #"static func chipRow(_ key: String) -> String { BLAccessibilityID.row("orders.list.chip", key: key) }"#
                ),
                expectedRules: [.duplicateValue]
            ),
            ViolationCase(
                name: "兩個固定值相同",
                namespaceFiles: orders(#"static let listRootCopy = "orders.list.root""#),
                expectedRules: [.duplicateValue]
            ),
            ViolationCase(
                name: "option 與 row 傳入相同前綴，查詢前綴不同",
                namespaceFiles: orders(
                    #"static func chipRow(_ id: String) -> String { BLAccessibilityID.row("orders.list.statusChip", key: id) }"#
                ),
                expectedRules: [.duplicateValue]
            ),
            ViolationCase(
                name: "兩個 option 傳入相同前綴，查詢前綴也相同，同時違反值重複與前綴重疊",
                namespaceFiles: orders(
                    #"static func chipAlias(_ key: String) -> String { option("orders.list.statusChip", key: key) }"#
                ),
                expectedRules: [.duplicateValue, .prefixOverlap]
            ),
            ViolationCase(
                name: "row 與 indexed 傳入相同前綴，查詢前綴不同",
                namespaceFiles: orders(
                    #"static func itemRow(_ id: String) -> String { BLAccessibilityID.row("orders.list.item", key: id) }"#,
                    #"static func itemIndex(_ number: Int) -> String { indexed("orders.list.item", index: number) }"#
                ),
                expectedRules: [.duplicateValue]
            ),
            ViolationCase(
                name: "option 與 indexed 傳入相同前綴，indexed 的查詢前綴在 option 之下，同時違反值重複與前綴重疊",
                namespaceFiles: orders(
                    #"static func chipIndex(_ number: Int) -> String { indexed("orders.list.statusChip", index: number) }"#
                ),
                expectedRules: [.duplicateValue, .prefixOverlap]
            ),
            ViolationCase(
                name: "不同型別宣告相同的固定值，同時違反值重複與第一段",
                namespaceFiles: dashboard(#"static let listRoot = "orders.list.root""#),
                expectedRules: [.duplicateValue, .firstSegment]
            ),
            ViolationCase(
                name: "跨檔宣告相同的固定值",
                namespaceFiles: orders() + [
                    sourceFile(
                        "BLAccessibilityID+OrdersDetail.swift",
                        #"""
                        extension BLAccessibilityID.Orders {

                            static let listRootAgain = "orders.list.root"
                        }
                        """#
                    ),
                ],
                expectedRules: [.duplicateValue]
            ),
        ]
    }

    /// 前綴重疊違規：固定值落在查詢前綴之下，或查詢前綴落在另一個之下
    static var prefixOverlapCases: [ViolationCase] {
        [
            ViolationCase(
                name: "固定值落在 row 查詢前綴之下，冒號使形狀也違規",
                namespaceFiles: orders(
                    #"static func row(orderID: String) -> String { BLAccessibilityID.row("orders.list.row", key: orderID) }"#,
                    #"static let rowSummary = "orders.list.row:summary""#
                ),
                expectedRules: [.shape, .prefixOverlap]
            ),
            ViolationCase(
                name: "固定值落在 option 查詢前綴之下",
                namespaceFiles: orders(#"static let statusChipAll = "orders.list.statusChip.all""#),
                expectedRules: [.prefixOverlap]
            ),
            ViolationCase(
                name: "固定值落在 indexed 查詢前綴之下，index.0 的 0 開頭使形狀也違規",
                namespaceFiles: orders() + [
                    file(
                        "BLAccessibilityID+OrderEdit.swift",
                        type: "OrderEdit",
                        body: #"""
                            static func photoThumbnail(_ index: Int) -> String {
                                indexed("orderEdit.photoThumbnail", index: index)
                            }

                            static let photoThumbnailFirst = "orderEdit.photoThumbnail.index.0"
                            """#
                    ),
                ],
                expectedRules: [.shape, .prefixOverlap]
            ),
            ViolationCase(
                name: "option 查詢前綴落在另一個 option 查詢前綴之下，短的先宣告",
                namespaceFiles: orders(
                    #"static func category(_ key: String) -> String { option("orders.filter.category", key: key) }"#,
                    #"static func group(_ key: String) -> String { option("orders.filter.category.group", key: key) }"#
                ),
                expectedRules: [.prefixOverlap]
            ),
            ViolationCase(
                name: "option 查詢前綴落在另一個 option 查詢前綴之下，長的先宣告",
                namespaceFiles: orders(
                    #"static func group(_ key: String) -> String { option("orders.filter.category.group", key: key) }"#,
                    #"static func category(_ key: String) -> String { option("orders.filter.category", key: key) }"#
                ),
                expectedRules: [.prefixOverlap]
            ),
            ViolationCase(
                name: "option 前綴 x.y.index 與 indexed 前綴 x.y 的查詢前綴相同，indexed 先宣告",
                namespaceFiles: orders() + [
                    file(
                        "BLAccessibilityID+OrderEdit.swift",
                        type: "OrderEdit",
                        body: #"""
                            static func photoThumbnail(_ index: Int) -> String {
                                indexed("orderEdit.photoThumbnail", index: index)
                            }

                            static func photoThumbnailOption(_ key: String) -> String {
                                option("orderEdit.photoThumbnail.index", key: key)
                            }
                            """#
                    ),
                ],
                expectedRules: [.prefixOverlap]
            ),
            ViolationCase(
                name: "option 前綴 x.y.index 與 indexed 前綴 x.y 的查詢前綴相同，option 先宣告",
                namespaceFiles: orders() + [
                    file(
                        "BLAccessibilityID+OrderEdit.swift",
                        type: "OrderEdit",
                        body: #"""
                            static func photoThumbnailOption(_ key: String) -> String {
                                option("orderEdit.photoThumbnail.index", key: key)
                            }

                            static func photoThumbnail(_ index: Int) -> String {
                                indexed("orderEdit.photoThumbnail", index: index)
                            }
                            """#
                    ),
                ],
                expectedRules: [.prefixOverlap]
            ),
        ]
    }

    /// 空掃描違規：沒有檔案、沒有固定值或沒有組出前綴時不可通過
    static var emptyScanCases: [ViolationCase] {
        [
            ViolationCase(
                name: "範圍外只有 App 原始檔而 UI 測試目錄沒有檔案",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile("BuyLedger/App/Probe.swift", "struct Probe {}"),
                ],
                outsideRoots: ["BuyLedger", "BuyLedgerUITests"],
                expectedRules: [.emptyScan]
            ),
            ViolationCase(
                name: "系統 identifier 檔案路徑不存在",
                namespaceFiles: orders(),
                systemIdentifierPath: "BuyLedgerUITests/Support/SystemAccessibilityID.swift",
                expectedRules: [.emptyScan]
            ),
            ViolationCase(
                name: "系統 identifier 檔案存在但沒有 static let 宣告",
                namespaceFiles: orders(),
                outsideFiles: [
                    sourceFile(
                        "BuyLedgerUITests/Support/SystemAccessibilityID.swift",
                        "enum SystemAccessibilityID {}"
                    ),
                ],
                systemIdentifierPath: "BuyLedgerUITests/Support/SystemAccessibilityID.swift",
                expectedRules: [.emptyScan]
            ),
            ViolationCase(
                name: "空輸入，沒有任何檔案",
                namespaceFiles: [],
                expectedRules: [.emptyScan]
            ),
            ViolationCase(
                name: "有檔案但沒有固定值",
                namespaceFiles: [
                    file("BLAccessibilityID+Orders.swift", type: "Orders", body: chipMember),
                ],
                expectedRules: [.emptyScan]
            ),
            ViolationCase(
                name: "有固定值但沒有組出前綴",
                namespaceFiles: [
                    file("BLAccessibilityID+Orders.swift", type: "Orders", body: rootMember),
                ],
                expectedRules: [.emptyScan]
            ),
            ViolationCase(
                name: "檔案內容為空",
                namespaceFiles: [sourceFile("BLAccessibilityID+Orders.swift", "")],
                expectedRules: [.emptyScan]
            ),
            ViolationCase(
                name: "宣告全在註解內",
                namespaceFiles: [
                    sourceFile(
                        "BLAccessibilityID+Orders.swift",
                        #"""
                        // static let listRoot = "orders.list.root"
                        /*
                        extension BLAccessibilityID {
                            enum Orders {
                                static let listRoot = "orders.list.root"
                            }
                        }
                        */
                        """#
                    ),
                ],
                expectedRules: [.emptyScan]
            ),
            ViolationCase(
                name: "只有被拒絕的宣告，不計入固定值與前綴，同時違反定義形式與空掃描",
                namespaceFiles: [
                    file(
                        "BLAccessibilityID+Orders.swift",
                        type: "Orders",
                        body: #"static let loading = prefix + ".loading""#
                    ),
                ],
                expectedRules: [.definitionForm, .emptyScan]
            ),
            ViolationCase(
                name: "只有組字串函式與根型別宣告",
                namespaceFiles: [
                    sourceFile(
                        "BLAccessibilityID.swift",
                        #"""
                        enum BLAccessibilityID {}

                        extension BLAccessibilityID {

                            static func option(_ prefix: String, key: String) -> String {
                                "\(prefix).\(key)"
                            }

                            static func row(_ prefix: String, key: String) -> String {
                                "\(prefix):\(key)"
                            }

                            static func indexed(_ prefix: String, index: Int) -> String {
                                "\(prefix).index.\(index)"
                            }
                        }
                        """#
                    ),
                ],
                expectedRules: [.emptyScan]
            ),
        ]
    }

    /// 把成員包進 `extension BLAccessibilityID { enum <型別> { … } }`，成員從第 5 行開始
    ///
    /// - Parameters:
    ///   - path: 檔案的相對路徑
    ///   - typeName: 巢狀型別名稱
    ///   - body: 型別內的成員原文，縮排 0 格
    /// - Returns: 合成的原始檔
    static func file(
        _ path: String,
        type typeName: String,
        body: String
    ) -> AccessibilityIdentifierScanner.SourceFile {
        let text = """
            extension BLAccessibilityID {

                enum \(typeName) {

            \(indented(body))
                }
            }

            """
        return sourceFile(path, text)
    }

    /// 每個非空行縮排 8 格
    ///
    /// - Parameter text: 要縮排的文字
    /// - Returns: 縮排後的文字，空行維持空行
    static func indented(_ text: String) -> String {
        text
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { $0.isEmpty ? "" : "        \($0)" }
            .joined(separator: "\n")
    }

    /// 建立合成原始檔
    ///
    /// - Parameters:
    ///   - path: 檔案的相對路徑
    ///   - text: 檔案原文
    /// - Returns: 合成的原始檔
    static func sourceFile(
        _ path: String,
        _ text: String
    ) -> AccessibilityIdentifierScanner.SourceFile {
        AccessibilityIdentifierScanner.SourceFile(relativePath: path, text: text)
    }

    /// 在合規的基準宣告 (一個固定值與一個 option 前綴) 之後加上待測成員，包成 `Orders` 的命名空間檔
    ///
    /// - Parameter extras: 接在基準宣告之後的成員，第一個成員從第 11 行開始
    /// - Returns: 只含 `BLAccessibilityID+Orders.swift` 一個檔案的清單
    static func orders(_ extras: String...) -> [AccessibilityIdentifierScanner.SourceFile] {
        let ordersFile = file(
            "BLAccessibilityID+Orders.swift",
            type: "Orders",
            body: ([rootMember, chipMember] + extras).joined(separator: "\n\n")
        )
        return [ordersFile]
    }

    /// 合規的 `Orders` 基準檔之外，再加一個只含待測成員的 `Dashboard` 命名空間檔
    ///
    /// - Parameter extras: `Dashboard` 的成員，第一個成員從第 5 行開始
    /// - Returns: `Orders` 基準檔與 `Dashboard` 檔
    static func dashboard(_ extras: String...) -> [AccessibilityIdentifierScanner.SourceFile] {
        let dashboardFile = file(
            "BLAccessibilityID+Dashboard.swift",
            type: "Dashboard",
            body: extras.joined(separator: "\n\n")
        )
        return orders() + [dashboardFile]
    }
}
