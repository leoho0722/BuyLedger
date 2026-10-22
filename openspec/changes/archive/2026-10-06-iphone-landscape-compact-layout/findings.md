# 整檔風格基準

2026-10-04 以 `python3 openspec/changes/iphone-landscape-compact-layout/reference/style_checks.py <六個檔>` 實測 (腳本複製自第 5 步，六個既有檔整檔檢查)。只涵蓋機械可查的規則；版面結構、`body` 只放大框架、命名語意等由 task 5.1 的 style agent 逐檔審查。

| 檔案 | 不含檔頭與空行的行數 | 機械違規 (含 LEN) |
|---|---|---|
| `apps/ios/BuyLedger/Features/App/RootView.swift` | 58 | 0 |
| `apps/ios/BuyLedger/Features/Orders/OrdersView.swift` | 434 | 29 |
| `apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift` | 694 | 32 |
| `apps/ios/BuyLedger/Features/Insights/InsightsView.swift` | 538 | 34 |
| `apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift` | 467 | 131 |
| `apps/ios/BuyLedgerTests/SnapshotTests.swift` | 475 | 1 |
| 合計 | | 227 |

完成標準：上述檔案與其拆出的新檔重跑腳本，除腳本明列不計失敗的代碼 (如 `WSTR`、`LENX`) 外 `TOTAL` 為空。

## 逐筆明細

```text
== [A] apps/ios/BuyLedger/Features/Orders/OrdersView.swift (29)
   L1 LEN 不含檔頭與空行 434 行
   L14 MK1 MARK 段名：View Properties
   L31 MK1 MARK 段名：View Body
   L36 NAMED1 單一表達式的 closure 用 $0，不用具名的 editStore
   L39 NAMED1 單一表達式的 closure 用 $0，不用具名的 summaryStore
   L42 NAMED1 單一表達式的 closure 用 $0，不用具名的 mergeStore
   L51 MK1 MARK 段名：ViewBuilder
   L72 OPEOL 運算子放在行尾就斷行：let allFilteredSelected =
   L114 NAMED1 單一表達式的 closure 用 $0，不用具名的 category
   L134 NAMED1 單一表達式的 closure 用 $0，不用具名的 paymentMethod
   L148 DOCBL 摘要與參數標記之間缺空的 ///
   L178 DOCBL 摘要與參數標記之間缺空的 ///
   L203 DOCBL 摘要與參數標記之間缺空的 ///
   L235 DOCBL 摘要與參數標記之間缺空的 ///
   L251 CASELET 改寫成 `case .x(let v)`，不用 `case let .x(v)`
   L263 DOCBL 摘要與參數標記之間缺空的 ///
   L284 DOCBL 摘要與參數標記之間缺空的 ///
   L306 DOCBL 摘要與參數標記之間缺空的 ///
   L326 DOCBL 摘要與參數標記之間缺空的 ///
   L346 DOCBL 摘要與參數標記之間缺空的 ///
   L353 D6 註解結尾句號
   L366 DOCBL 摘要與參數標記之間缺空的 ///
   L387 D6 註解結尾句號
   L392 DOCBL 摘要與參數標記之間缺空的 ///
   L397 NESTSL 寫在另一個 closure 內的 closure 要寫成多行：ForEach(OrderStatus.allCases.filter { $0 != .merged || order
   L398 CLP closure 參數列獨佔一行：status in
   L398 CLSIG closure 簽章跨行，參數列與 in 寫在 { 同一行
   L418 DOCBL 摘要與參數標記之間缺空的 ///
   L463 DOCBL 摘要與參數標記之間缺空的 ///
== [A] apps/ios/BuyLedger/Features/Dashboard/DashboardView.swift (32)
   L1 LEN 不含檔頭與空行 694 行
   L14 MK1 MARK 段名：View Properties
   L46 MK1 MARK 段名：View Body
   L54 D6 註解結尾句號
   L55 D6 註解結尾句號
   L67 CASELET 改寫成 `case .x(let v)`，不用 `case let .x(v)`
   L83 D6 註解結尾句號
   L88 D6 註解結尾句號
   L96 MK1 MARK 段名：ViewBuilder
   L133 PARTW 斷行後多個參數或引數擠在同一行：campaignNames: ongoingCampaigns.map(\.name), order
   L134 RPAR 斷行呼叫的右括號沒有單獨一行：campaignNames: ongoingCampaigns.map(\.name), order
   L136 W 行寬 109
   L148 CLP closure 參數列獨佔一行：index, entry in
   L148 CLSIG closure 簽章跨行，參數列與 in 寫在 { 同一行
   L152 PARTW 斷行後多個參數或引數擠在同一行：campaign: entry.campaign, summary: entry.summary,
   L400 D6 註解結尾句號
   L423 NAMED1 單一表達式的 closure 用 $0，不用具名的 ordinal
   L423 NESTSL 寫在另一個 closure 內的 closure 要寫成多行：pointOrdinalDescription: { ordinal in language.localized("")
   L429 D6 註解結尾句號
   L431 MOD .frame (第 1 組) 排在 .foregroundStyle (第 2 組) 之後
   L432 D6 註解結尾句號
   L435 D6 註解結尾句號
   L436 D6 註解結尾句號
   L452 D6 註解結尾句號
   L455 RPAR 斷行呼叫的右括號沒有單獨一行：BLProgressViewStyle(tint: .white, track: .white.op
   L561 D6 註解結尾句號
   L606 CLP closure 參數列獨佔一行：index, order in
   L606 CLSIG closure 簽章跨行，參數列與 in 寫在 { 同一行
   L630 MKIN MARK 寫在 extension 大括號內：// MARK: Layout
   L659 DASH 註解破折號
   L707 SWC switch case 之間缺空行：case .some(false):
   L709 SWC switch case 之間缺空行：case .none:
== [A] apps/ios/BuyLedger/Features/Insights/InsightsView.swift (34)
   L1 LEN 不含檔頭與空行 538 行
   L14 MK1 MARK 段名：View Properties
   L43 MK1 MARK 段名：View Body
   L59 CASELET 改寫成 `case .x(let v)`，不用 `case let .x(v)`
   L82 MK1 MARK 段名：ViewBuilder
   L87 DOCBL 摘要與參數標記之間缺空的 ///
   L99 D6 註解結尾句號
   L126 DOCBL 摘要與參數標記之間缺空的 ///
   L140 DOCBL 摘要與參數標記之間缺空的 ///
   L175 NAMED1 單一表達式的 closure 用 $0，不用具名的 range
   L185 DOCBL 摘要與參數標記之間缺空的 ///
   L203 CALL1 未達斷行條件卻拆成多行 (2 個，接成一行 89 字元)：trendDeltaColor(
   L232 DOCBL 摘要與參數標記之間缺空的 ///
   L254 DOCBL 摘要與參數標記之間缺空的 ///
   L281 W 行寬 102
   L293 DOCBL 摘要與參數標記之間缺空的 ///
   L312 CLP closure 參數列獨佔一行：index, category in
   L312 CLSIG closure 簽章跨行，參數列與 in 寫在 { 同一行
   L320 W 行寬 117
   L339 DOCBL 摘要與參數標記之間缺空的 ///
   L383 DOCBL 摘要與參數標記之間缺空的 ///
   L441 DOCBL 摘要與參數標記之間缺空的 ///
   L466 NAMED1 單一表達式的 closure 用 $0，不用具名的 week
   L470 MOD .frame (第 1 組) 排在 .foregroundStyle (第 2 組) 之後
   L482 MOD .frame (第 1 組) 排在 .foregroundStyle (第 2 組) 之後
   L503 DOCBL 摘要與參數標記之間缺空的 ///
   L518 D6 註解結尾句號
   L532 D6 註解結尾句號
   L544 MKIN MARK 寫在 extension 大括號內：// MARK: Layout
   L552 DOCBL 摘要與參數標記之間缺空的 ///
   L567 DOCBL 摘要與參數標記之間缺空的 ///
   L580 DOCBL 摘要與參數標記之間缺空的 ///
   L588 SWC switch case 之間缺空行：case .some(false):
   L590 SWC switch case 之間缺空行：case .none:
== [A] apps/ios/BuyLedgerTests/DesignSystemSourceScanTests.swift (131)
   L1 LEN 不含檔頭與空行 467 行
   L15 DOCBL 摘要與參數標記之間缺空的 ///
   L16 GWT 缺 // Given
   L16 GWT 缺 // Then
   L16 GWT 缺 // When
   L16 TNAMEL 舊式單段 lowerCamel 測試名稱：productionRootYieldsScannableFiles
   L16 TSTL `@Test` 與 `func` 寫在同一行，樣板是 `@Test` 單獨一行
   L19 PARTW 斷行後多個參數或引數擠在同一行：!files.isEmpty, "掃描到 0 個 Swift 檔案，productionRoot 疑
   L20 RPAR 斷行呼叫的右括號沒有單獨一行：!files.isEmpty, "")
   L24 DOCBL 摘要與參數標記之間缺空的 ///
   L25 TNAMEL 舊式單段 lowerCamel 測試名稱：productionCodeUsesSingleCurrencyDisplayNameEntry
   L25 TSTL `@Test` 與 `func` 寫在同一行，樣板是 `@Test` 單獨一行
   L31 CALL1 未達斷行條件卻拆成多行 (2 個，接成一行 97 字元)：#expect(
   L38 DOCBL 摘要與參數標記之間缺空的 ///
   L39 TNAMEL 舊式單段 lowerCamel 測試名稱：productionCodeUsesSingleAppLanguageEntry
   L39 TSTL `@Test` 與 `func` 寫在同一行，樣板是 `@Test` 單獨一行
   L52 DOCBL 摘要與參數標記之間缺空的 ///
   L53 GWT 缺 // Given
   L53 GWT 缺 // Then
   L53 GWT 缺 // When
   L53 TNAMEL 舊式單段 lowerCamel 測試名稱：systemSecondaryColorIsNotUsedForText
   L53 TSTL `@Test` 與 `func` 寫在同一行，樣板是 `@Test` 單獨一行
   L54 PARTW 斷行後多個參數或引數擠在同一行：under: Self.productionRoot, matching: Self.seconda
   L55 RPAR 斷行呼叫的右括號沒有單獨一行：under: Self.productionRoot, matching: Self.seconda
   L64 DOCBL 摘要與參數標記之間缺空的 ///
   L65 GWT 缺 // Given
   L65 GWT 缺 // Then
   L65 GWT 缺 // When
   L65 TNAMEL 舊式單段 lowerCamel 測試名稱：systemAccentColorIsNotUsedDirectly
   L65 TSTL `@Test` 與 `func` 寫在同一行，樣板是 `@Test` 單獨一行
   L66 PARTW 斷行後多個參數或引數擠在同一行：under: Self.productionRoot, matching: Self.accentC
   L67 RPAR 斷行呼叫的右括號沒有單獨一行：under: Self.productionRoot, matching: Self.accentC
   L76 DOCBL 摘要與參數標記之間缺空的 ///
   L77 GWT 缺 // Given
   L77 GWT 缺 // Then
   L77 GWT 缺 // When
   L77 TNAMEL 舊式單段 lowerCamel 測試名稱：namedSystemHueColorsAreNotUsedDirectly
   L77 TSTL `@Test` 與 `func` 寫在同一行，樣板是 `@Test` 單獨一行
   L78 PARTW 斷行後多個參數或引數擠在同一行：under: Self.productionRoot, matching: Self.namedHu
   L79 RPAR 斷行呼叫的右括號沒有單獨一行：under: Self.productionRoot, matching: Self.namedHu
   L88 DOCBL 摘要與參數標記之間缺空的 ///
   L89 GWT 缺 // Given
   L89 GWT 缺 // Then
   L89 GWT 缺 // When
   L89 TNAMEL 舊式單段 lowerCamel 測試名稱：systemColorAPIsAppearOnlyInThePalette
   L89 TSTL `@Test` 與 `func` 寫在同一行，樣板是 `@Test` 單獨一行
   L103 DOCBL 摘要與參數標記之間缺空的 ///
   L104 GWT 缺 // Given
   L104 GWT 缺 // Then
   L104 GWT 缺 // When
   L104 TNAMEL 舊式單段 lowerCamel 測試名稱：rawColorConstructionAppearsOnlyInItsTwoHomes
   L104 TSTL `@Test` 與 `func` 寫在同一行，樣板是 `@Test` 單獨一行
   L118 DOCBL 摘要與參數標記之間缺空的 ///
   L119 GWT 缺 // Given
   L119 GWT 缺 // Then
   L119 GWT 缺 // When
   L119 TNAMEL 舊式單段 lowerCamel 測試名稱：colorSchemeEnvironmentDeclarationAppearsOnlyInCard
   L119 TSTL `@Test` 與 `func` 寫在同一行，樣板是 `@Test` 單獨一行
   L133 DOCBL 摘要與參數標記之間缺空的 ///
   L134 GWT 缺 // Given
   L134 GWT 缺 // Then
   L134 GWT 缺 // When
   L134 TNAMEL 舊式單段 lowerCamel 測試名稱：hexadecimalColorInitializerHasNoOccurrences
   L134 TSTL `@Test` 與 `func` 寫在同一行，樣板是 `@Test` 單獨一行
   L135 PARTW 斷行後多個參數或引數擠在同一行：under: Self.productionRoot, matching: Self.hexInit
   L136 RPAR 斷行呼叫的右括號沒有單獨一行：under: Self.productionRoot, matching: Self.hexInit
   L138 CALL1 未達斷行條件卻拆成多行 (2 個，接成一行 95 字元)：#expect(
   L145 DOCBL 摘要與參數標記之間缺空的 ///
   L146 GWT 缺 // Given
   L146 GWT 缺 // Then
   L146 GWT 缺 // When
   L146 TNAMEL 舊式單段 lowerCamel 測試名稱：exemptionMarkersCarryNonEmptyReasons
   L146 TSTL `@Test` 與 `func` 寫在同一行，樣板是 `@Test` 單獨一行
   L174 FUNWRAP 強制解包 (鐵則 3)：static let secondaryColorPattern = try! NSRegularExpression(
   L182 FUNWRAP 強制解包 (鐵則 3)：static let accentColorPattern = try! NSRegularExpression(
   L187 FUNWRAP 強制解包 (鐵則 3)：static let namedHueTokenPattern = try! NSRegularExpression(
   L196 FUNWRAP 強制解包 (鐵則 3)：static let systemColorAPIPattern = try! NSRegularExpression(
   L201 FUNWRAP 強制解包 (鐵則 3)：static let currencyLookupPattern = try! NSRegularExpression(
   L206 FUNWRAP 強制解包 (鐵則 3)：static let languageDerivationPattern = try! NSRegularExpress
   L211 FUNWRAP 強制解包 (鐵則 3)：static let rawConstructionPattern = try! NSRegularExpression
   L219 FUNWRAP 強制解包 (鐵則 3)：static let colorSchemeDeclarationPattern = try! NSRegularExp
   L224 FUNWRAP 強制解包 (鐵則 3)：static let hexInitializerPattern = try! NSRegularExpression(
   L228 CLB 型別或 extension 的閉括號前有空行
   L228 CLBX 閉括號前有空行
   L230 MKPRIV private extension 的 computed property 應放 // MARK: - Private Method
   L246 CLB 型別或 extension 的閉括號前有空行
   L246 CLBX 閉括號前有空行
   L248 MK2 分區順序：Nested Types 排在 Computed Properties 之後
   L255 MKN 巢狀型別內的 MARK：Properties
   L267 MKN 巢狀型別內的 MARK：Properties
   L295 DOCBL 摘要與參數標記之間缺空的 ///
   L296 D2 有參數缺 - Parameter：static func findViolations(
   L296 D4 會拋錯缺 - Throws：static func findViolations(
   L307 GRD 條件續行要對齊第一個條件：應縮排 18 格，目前 16 格
   L308 GRD `else {` 要接在最後一個條件同行，不單獨成行
   L313 RPAR 斷行呼叫的右括號沒有單獨一行：separatedBy: "")
   L318 BRACE 宣告或 guard 的大括號本體壓成單行：guard lineViolates(pattern, in: stripped) else { continue }
   L319 BRACE 宣告或 guard 的大括號本體壓成單行：guard exemptionReason(onRawLine: rawLine) == nil else { cont
   L322 RPAR 斷行呼叫的右括號沒有單獨一行：Violation(file: relativeFile, line: index + 1))
   L326 DOLLAR2 兩個以上參數的 closure 要具名，不用 $1 簡寫
   L330 DOCBL 摘要與參數標記之間缺空的 ///
   L341 DOCBL 摘要與參數標記之間缺空的 ///
   L352 DOCBL 摘要與參數標記之間缺空的 ///
   L360 RPAR 斷行呼叫的右括號沒有單獨一行：separatedBy: "")
   L363 BRACE 宣告或 guard 的大括號本體壓成單行：guard let reason = exemptionReason(onRawLine: rawLine) else 
   L366 PARTW 斷行後多個參數或引數擠在同一行：file: relativePath(of: file, under: root), line: i
   L367 RPAR 斷行呼叫的右括號沒有單獨一行：file: relativePath(of: file, under: root), line: i
   L374 DOLLAR2 兩個以上參數的 closure 要具名，不用 $1 簡寫
   L379 DOCBL 摘要與參數標記之間缺空的 ///
   L380 D2 有參數缺 - Parameter：static func exemptionReason(onRawLine rawLine: String) -> St
   L381 BRACE 宣告或 guard 的大括號本體壓成單行：guard let range = rawLine.range(of: exemptionMarkerPrefix) e
   L386 DOCBL 摘要與參數標記之間缺空的 ///
   L387 D2 有參數缺 - Parameter：static func stripCommentsAndStrings(from line: String, mode:
   L461 DOCBL 摘要與參數標記之間缺空的 ///
   L462 CALL1 未達斷行條件卻拆成多行 (3 個，接成一行 98 字元)：static func hasPrefix(
   L462 D2 有參數缺 - Parameter：static func hasPrefix(
   L467 BRACE 宣告或 guard 的大括號本體壓成單行：guard index + marker.count <= characters.count else { return
   L475 DOCBL 摘要與參數標記之間缺空的 ///
   L476 D2 有參數缺 - Parameter：static func lineViolates(_ pattern: NSRegularExpression, in 
   L481 BRACE 宣告或 guard 的大括號本體壓成單行：guard let result, let matchRange = Range(result.range, in: t
   L496 DOCBL 摘要與參數標記之間缺空的 ///
   L497 D2 有參數缺 - Parameter：static func isBareHueTokenInValuePosition(in text: String, m
   L509 BRACE 宣告或 guard 的大括號本體壓成單行：guard character == "" || character == "" else { continue }
   L510 GUARDX guard 的 else 只允許單一退出敘述，或一個警告／log 呼叫後接 return／throw
   L526 BRACE 宣告或 guard 的大括號本體壓成單行：guard identifierStart < index else { return true }
   L528 OPEOL 運算子放在行尾就斷行：let precededByDot =
   L539 DOCBL 摘要與參數標記之間缺空的 ///
   L560 DOCBL 摘要與參數標記之間缺空的 ///
   L561 D2 有參數缺 - Parameter：static func relativePath(of file: URL, under root: URL) -> S
   L571 DOCBL 摘要與參數標記之間缺空的 ///
   L572 D2 有參數缺 - Parameter：static func describe(_ violations: [Violation]) -> String {
== [A] apps/ios/BuyLedgerTests/SnapshotTests.swift (1)
   L1 LEN 不含檔頭與空行 475 行
```
