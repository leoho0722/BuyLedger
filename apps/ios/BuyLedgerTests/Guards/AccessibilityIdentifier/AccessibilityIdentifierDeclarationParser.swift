//
//  AccessibilityIdentifierDeclarationParser.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/11/13.
//

import Foundation

/// 解析命名空間目錄的原始檔，取得固定值、組出前綴與定義形式違規
enum AccessibilityIdentifierDeclarationParser {}

// MARK: - Nested Types

extension AccessibilityIdentifierDeclarationParser {

    /// 解析宣告時所在的位置
    struct Context: Sendable {

        /// 原始檔的相對路徑
        let path: String

        /// 所屬的巢狀型別名稱，直接在 `BLAccessibilityID` 之下時為 `nil`
        let owner: String?

        /// 是否直接位於 `BLAccessibilityID` 的擴充或根型別本體，而不在巢狀型別內
        let isRootLevel: Bool
    }

    /// 一個原始檔解析過程累積的結果
    struct ParseState {

        /// 固定值
        var fixed: [AccessibilityIdentifierScanner.Definition] = []

        /// 組出前綴
        var prefixes: [AccessibilityIdentifierScanner.Definition] = []

        /// 定義形式違規
        var violations: [AccessibilityIdentifierScanner.Violation] = []

        /// 各所屬型別 (含巢狀型別，跨檔合併，`nil` 為根層) 內宣告過的函式名稱與宣告數，解析時累積
        var declaredFunctions: [String?: [String: Int]] = [:]

        /// 第一輪解析取得的 `declaredFunctions`，第二輪判斷遮蔽與根層重載時讀取
        var knownFunctions: [String?: [String: Int]] = [:]
    }

    /// 擴充或根型別的外觀
    struct ContainerShape: Sendable {

        /// 關鍵字之後以 `.` 連接的名稱各段
        let components: [String]

        /// 開大括號相對於宣告第一個記號的位置
        let openOffset: Int

        /// 閉大括號相對於宣告第一個記號的位置
        let closeOffset: Int
    }

    /// `static func` 的外觀
    struct FunctionShape: Sendable {

        /// 函式名稱
        let name: String

        /// 參數區閉括號相對於宣告第一個記號的位置
        let headerClose: Int

        /// 本體開大括號相對於宣告第一個記號的位置
        let bodyOpen: Int

        /// 本體閉大括號相對於宣告第一個記號的位置
        let bodyClose: Int
    }
}

// MARK: - Internal Method

extension AccessibilityIdentifierDeclarationParser {

    /// 解析命名空間目錄的原始檔，取得定義清單與定義形式違規
    ///
    /// - Parameter files: 命名空間目錄的原始檔
    /// - Returns: 定義清單與定義形式違規
    static func scan(
        _ files: [AccessibilityIdentifierScanner.SourceFile]
    ) -> AccessibilityIdentifierScanner.ScanResult {
        var state = ParseState()
        state.knownFunctions = declaredFunctions(in: files)
        for file in files {
            parse(file, into: &state)
        }
        let definitions = AccessibilityIdentifierScanner.Definitions(
            fileCount: files.count,
            fixed: state.fixed,
            prefixes: state.prefixes
        )
        return AccessibilityIdentifierScanner.ScanResult(
            definitions: definitions,
            violations: state.violations
        )
    }
}

// MARK: - Private Method

private extension AccessibilityIdentifierDeclarationParser {

    /// 先解析一輪，取得各所屬型別內宣告過的函式名稱與宣告數，供第二輪判斷遮蔽與根層重載
    ///
    /// - Parameter files: 命名空間目錄的原始檔
    /// - Returns: 以所屬巢狀型別名稱為鍵 (根層為 `nil`)、函式名稱對宣告數的表
    /// - Note: 是否進入某個本體不可依賴解析狀態 (`knownFunctions` 與 `declaredFunctions`)，否則第一輪的名稱表會缺漏
    static func declaredFunctions(
        in files: [AccessibilityIdentifierScanner.SourceFile]
    ) -> [String?: [String: Int]] {
        var scratch = ParseState()
        for file in files {
            parse(file, into: &scratch)
        }
        return scratch.declaredFunctions
    }

    /// 解析一個命名空間原始檔，把固定值、組出前綴與定義形式違規累積進結果
    ///
    /// - Parameters:
    ///   - file: 命名空間目錄的原始檔
    ///   - state: 累積的解析結果
    static func parse(
        _ file: AccessibilityIdentifierScanner.SourceFile,
        into state: inout ParseState
    ) {
        let model = AccessibilityIdentifierSourceModel(text: file.text)
        let context = Context(path: file.relativePath, owner: nil, isRootLevel: true)
        guard model.isAligned else {
            state.violations.append(
                AccessibilityIdentifierScanner.Violation(
                    rule: .definitionForm,
                    path: file.relativePath,
                    line: 1,
                    subject: "BLAccessibilityID.(檔案)",
                    value: "",
                    detail: "遮罩後的內容與原文長度不一致，無法掃描"
                )
            )
            return
        }
        let leadingEnd = model.tokens.first?.start ?? model.original.count
        checkTrivia(in: model, from: 0, to: leadingEnd, context: context, state: &state)
        let declarations = model.declarations(
            in: model.tokens.indices,
            endLimit: model.original.count
        )
        for declaration in declarations {
            analyzeTopLevel(declaration, context: context, state: &state)
        }
    }

    /// 確認兩個位置之間沒有宣告以外的字串字面值，有就記一筆定義形式違規
    ///
    /// - Parameters:
    ///   - model: 原始檔的對照
    ///   - start: 起始位置
    ///   - end: 結束位置，不含
    ///   - context: 所在位置
    ///   - state: 累積的解析結果
    static func checkTrivia(
        in model: AccessibilityIdentifierSourceModel,
        from start: Int,
        to end: Int,
        context: Context,
        state: inout ParseState
    ) {
        guard model.gap(from: start, to: end) != .trivia else {
            return
        }
        let position = model.skipTrivia(from: start, to: end)
        state.violations.append(
            AccessibilityIdentifierScanner.Violation(
                rule: .definitionForm,
                path: context.path,
                line: model.line(at: position),
                subject: "\(context.owner ?? "BLAccessibilityID").(字面值)",
                value: "",
                detail: "宣告之外出現字串字面值"
            )
        )
    }

    /// 分析檔案最外層的一個宣告：只接受 `BLAccessibilityID` 的擴充、根型別與 `import`
    ///
    /// - Parameters:
    ///   - declaration: 宣告的記號視圖
    ///   - context: 檔案最外層的位置
    ///   - state: 累積的解析結果
    static func analyzeTopLevel(
        _ declaration: AccessibilityIdentifierDeclaration,
        context: Context,
        state: inout ParseState
    ) {
        if isImport(declaration) {
            return
        }
        if let shape = containerShape(of: declaration),
           shape.components.first == "BLAccessibilityID",
           !shape.components.dropFirst().contains("BLAccessibilityID") {
            let isExtension = declaration.texts[0] == "extension"
            let isRootEnum = declaration.texts[0] == "enum" && shape.components.count == 1
            if isExtension || isRootEnum {
                let isRootLevel = shape.components.count == 1
                let bodyContext = Context(
                    path: context.path,
                    owner: isRootLevel ? nil : shape.components[1],
                    isRootLevel: isRootLevel
                )
                parseMembers(
                    in: declaration.model,
                    open: declaration.range.lowerBound + shape.openOffset,
                    close: declaration.range.lowerBound + shape.closeOffset,
                    context: bodyContext,
                    state: &state
                )
                return
            }
        }
        reportForm(declaration, context: context, state: &state)
    }

    /// 宣告是否只是 `import <模組>`
    ///
    /// - Parameter declaration: 宣告的記號視圖
    /// - Returns: 是否為單純的 import
    static func isImport(_ declaration: AccessibilityIdentifierDeclaration) -> Bool {
        guard declaration.texts[0] == "import", declaration.isIdentifier(at: 1) else {
            return false
        }
        var offset = 2
        while declaration.text(at: offset) == ".", declaration.isIdentifier(at: offset + 1) {
            offset += 2
        }
        return offset == declaration.count
            && declaration.hasTriviaGaps(in: 1..<declaration.count)
            && declaration.tail == .trivia
    }

    /// 辨識 `extension <名稱>` 或 `enum <名稱>` 加上一對大括號的外觀
    ///
    /// - Parameter declaration: 宣告的記號視圖
    /// - Returns: 名稱各段與大括號位置；不是這個外觀或大括號之後還有內容時為 `nil`
    static func containerShape(
        of declaration: AccessibilityIdentifierDeclaration
    ) -> ContainerShape? {
        guard ["extension", "enum"].contains(declaration.texts[0]),
              declaration.isIdentifier(at: 1)
        else {
            return nil
        }
        var components = [declaration.texts[1]]
        var offset = 2
        while declaration.text(at: offset) == ".", declaration.isIdentifier(at: offset + 1) {
            components.append(declaration.texts[offset + 1])
            offset += 2
        }
        guard let close = declaration.closingOffsetOfTrailingBlock(openingAt: offset) else {
            return nil
        }
        return ContainerShape(components: components, openOffset: offset, closeOffset: close)
    }

    /// 解析型別或擴充本體內的每個宣告
    ///
    /// - Parameters:
    ///   - model: 原始檔的對照
    ///   - open: 開大括號的記號索引
    ///   - close: 閉大括號的記號索引
    ///   - context: 本體所在的位置
    ///   - state: 累積的解析結果
    static func parseMembers(
        in model: AccessibilityIdentifierSourceModel,
        open: Int,
        close: Int,
        context: Context,
        state: inout ParseState
    ) {
        let bodyRange = (open + 1)..<close
        let closeStart = model.tokens[close].start
        let leadingEnd = bodyRange.isEmpty ? closeStart : model.tokens[bodyRange.lowerBound].start
        checkTrivia(
            in: model,
            from: model.tokens[open].end,
            to: leadingEnd,
            context: context,
            state: &state
        )
        for declaration in model.declarations(in: bodyRange, endLimit: closeStart) {
            analyzeMember(declaration, context: context, state: &state)
        }
    }

    /// 分析本體內的一個宣告，符合接受的定義形式就記錄定義，否則記一筆定義形式違規
    ///
    /// - Parameters:
    ///   - declaration: 宣告的記號視圖
    ///   - context: 宣告所在的位置
    ///   - state: 累積的解析結果
    static func analyzeMember(
        _ declaration: AccessibilityIdentifierDeclaration,
        context: Context,
        state: inout ParseState
    ) {
        if let name = declaredFunctionName(of: declaration) {
            state.declaredFunctions[context.owner, default: [:]][name, default: 0] += 1
        }
        if declaration.texts[0] == "enum" {
            if parseEnum(declaration, context: context, state: &state) {
                return
            }
        } else if declaration.texts[0] == "case" {
            if matchCase(declaration, context: context) {
                return
            }
        } else if let fixed = declaration.fixedLiteral() {
            state.fixed.append(
                AccessibilityIdentifierScanner.Definition(
                    kind: .fixed,
                    ownerType: context.owner,
                    name: fixed.name,
                    value: fixed.value,
                    path: context.path,
                    line: declaration.firstLine
                )
            )
            return
        } else if let shape = functionShape(of: declaration) {
            if context.isRootLevel,
               AccessibilityIdentifierScanner.Composer(identifier: shape.name) != nil {
                if isTemplate(declaration, shape: shape),
                   !isOverloaded(shape.name, state: state) {
                    return
                }
            } else if let wrapper = matchWrapper(declaration, shape: shape),
                      !isShadowed(wrapper.unqualifiedCallee, context: context, state: state) {
                state.prefixes.append(
                    AccessibilityIdentifierScanner.Definition(
                        kind: .prefix(wrapper.composer),
                        ownerType: context.owner,
                        name: shape.name,
                        value: wrapper.prefix,
                        path: context.path,
                        line: declaration.firstLine
                    )
                )
                return
            }
        }
        reportForm(declaration, context: context, state: &state)
    }

    /// 取出宣告的函式名稱，不論宣告是否符合接受的形式
    ///
    /// - Parameter declaration: 宣告的記號視圖
    /// - Returns: `func` 之後的識別字；宣告本身不是函式 (`func` 出現在大括號之內) 時為 `nil`
    static func declaredFunctionName(
        of declaration: AccessibilityIdentifierDeclaration
    ) -> String? {
        guard let funcOffset = declaration.texts.firstIndex(of: "func"),
              !declaration.texts[..<funcOffset].contains("{"),
              declaration.isIdentifier(at: funcOffset + 1)
        else {
            return nil
        }
        return declaration.texts[funcOffset + 1]
    }

    /// 解析巢狀列舉並遞迴解析本體
    ///
    /// - Parameters:
    ///   - declaration: 宣告的記號視圖
    ///   - context: 宣告所在的位置
    ///   - state: 累積的解析結果
    /// - Returns: 外觀符合 `enum <名稱>` 加選用的遵循清單 (只接受 `String`、`Sendable`) 與大括號，
    ///   且名稱不是 `BLAccessibilityID` 時為 `true`
    static func parseEnum(
        _ declaration: AccessibilityIdentifierDeclaration,
        context: Context,
        state: inout ParseState
    ) -> Bool {
        guard declaration.count >= 4,
              declaration.isIdentifier(at: 1),
              declaration.texts[1] != "BLAccessibilityID"
        else {
            return false
        }
        let allowedConformances: Set<String> = ["String", "Sendable"]
        var offset = 2
        if declaration.text(at: offset) == ":" {
            offset += 1
            while declaration.isIdentifier(at: offset) {
                guard allowedConformances.contains(declaration.texts[offset]) else {
                    return false
                }
                offset += 1
                guard declaration.text(at: offset) == "," else {
                    break
                }
                offset += 1
            }
        }
        guard let close = declaration.closingOffsetOfTrailingBlock(openingAt: offset) else {
            return false
        }
        let bodyContext = Context(
            path: context.path,
            owner: context.isRootLevel ? declaration.texts[1] : context.owner,
            isRootLevel: false
        )
        parseMembers(
            in: declaration.model,
            open: declaration.range.lowerBound + offset,
            close: declaration.range.lowerBound + close,
            context: bodyContext,
            state: &state
        )
        return true
    }

    /// 宣告是否為沒有 raw value 與關聯值的 `case a, b`
    ///
    /// - Parameters:
    ///   - declaration: 宣告的記號視圖
    ///   - context: 宣告所在的位置
    /// - Returns: 在巢狀型別內且外觀符合時為 `true`
    static func matchCase(
        _ declaration: AccessibilityIdentifierDeclaration,
        context: Context
    ) -> Bool {
        let count = declaration.count
        guard !context.isRootLevel,
              count >= 2,
              count % 2 == 0,
              declaration.hasTriviaGaps(in: 1..<count),
              declaration.tail == .trivia
        else {
            return false
        }
        return stride(from: 1, to: count, by: 2).allSatisfy { offset in
            let isLast = offset + 1 == count
            return declaration.isIdentifier(at: offset)
                && (isLast || declaration.texts[offset + 1] == ",")
        }
    }

    /// 辨識 `static func <名稱>(<參數>) -> String { <本體> }` 的外觀，參數區不可含字面值
    ///
    /// - Parameter declaration: 宣告的記號視圖
    /// - Returns: 函式名稱與本體大括號位置；不是這個外觀或大括號之後還有內容時為 `nil`
    /// - Note: 參數區之後必須恰為 `-> String`，`async`、`throws` 與其他回傳型別都不接受
    static func functionShape(
        of declaration: AccessibilityIdentifierDeclaration
    ) -> FunctionShape? {
        let texts = declaration.texts
        let signatureTail = ["-", ">", "String", "{"]
        guard texts.count >= 6,
              texts[0] == "static",
              texts[1] == "func",
              declaration.isIdentifier(at: 2),
              texts[3] == "(",
              let headerClose = declaration.closingOffset(forOpeningAt: 3),
              Array(texts.dropFirst(headerClose + 1).prefix(signatureTail.count)) == signatureTail
        else {
            return nil
        }
        let bodyOpen = headerClose + signatureTail.count
        guard let bodyClose = declaration.closingOffsetOfTrailingBlock(openingAt: bodyOpen) else {
            return nil
        }
        return FunctionShape(
            name: texts[2],
            headerClose: headerClose,
            bodyOpen: bodyOpen,
            bodyClose: bodyClose
        )
    }

    /// 本體是否恰為一個單行、帶插值的字串模板，如 `"\(prefix).\(key)"`，插值內不可有字串字面值
    ///
    /// - Parameters:
    ///   - declaration: 宣告的記號視圖
    ///   - shape: 函式外觀
    /// - Returns: 本體只有一個字串模板與插值內的識別字時為 `true`；多行字串與 raw string 為 `false`
    static func isTemplate(
        _ declaration: AccessibilityIdentifierDeclaration,
        shape: FunctionShape
    ) -> Bool {
        let bodyOffsets = (shape.bodyOpen + 1)..<shape.bodyClose
        guard !bodyOffsets.isEmpty else {
            return false
        }
        let allowedPunctuation: Set<String> = [".", "(", ")"]
        let forbiddenKeywords: Set<String> = ["let", "var", "return"]
        let hasOnlyInterpolationTokens = bodyOffsets.allSatisfy { offset in
            let text = declaration.texts[offset]
            let isExpressionIdentifier = declaration.isIdentifier(at: offset)
                && !forbiddenKeywords.contains(text)
            return allowedPunctuation.contains(text) || isExpressionIdentifier
        }
        let model = declaration.model
        let base = declaration.range.lowerBound
        let openEnd = model.tokens[base + shape.bodyOpen].end
        let closeStart = model.tokens[base + shape.bodyClose].start
        return hasOnlyInterpolationTokens
            && model.isSingleLineTemplate(from: openEnd, to: closeStart)
    }

    /// `BLAccessibilityID` 根層是否宣告了不只一個同名函式，含不同參數型別的重載
    ///
    /// - Parameters:
    ///   - name: 函式名稱
    ///   - state: 累積的解析結果
    /// - Returns: 第一輪統計的根層宣告數大於 1 時為 `true`，同名的每一處宣告都不接受
    static func isOverloaded(_ name: String, state: ParseState) -> Bool {
        let rootOwner: String? = nil
        return (state.knownFunctions[rootOwner]?[name] ?? 0) > 1
    }

    /// 辨識本體恰為一次組字串呼叫的包裝函式：前綴是單一字面值，第二個引數是識別字或成員路徑
    ///
    /// - Parameters:
    ///   - declaration: 宣告的記號視圖
    ///   - shape: 函式外觀
    /// - Returns: 組字串函式、前綴與未限定呼叫的函式名稱 (限定寫法為 `nil`)；本體不符時為 `nil`
    /// - Note: 未限定的呼叫與參數區內的識別字不可同名
    static func matchWrapper(
        _ declaration: AccessibilityIdentifierDeclaration,
        shape: FunctionShape
    ) -> (
        composer: AccessibilityIdentifierScanner.Composer,
        prefix: String,
        unqualifiedCallee: String?
    )? {
        var cursor = shape.bodyOpen + 1
        var isQualified = false
        if declaration.text(at: cursor) == "BLAccessibilityID",
           declaration.text(at: cursor + 1) == "." {
            isQualified = true
            cursor += 2
        }
        let commaOffset = cursor + 2
        guard let name = declaration.text(at: cursor),
              let composer = AccessibilityIdentifierScanner.Composer(identifier: name),
              declaration.text(at: cursor + 1) == "(",
              declaration.text(at: commaOffset) == ",",
              case .literal(let prefix) = declaration.gap(before: commaOffset),
              declaration.text(at: cursor + 3) == composer.argumentLabel,
              declaration.text(at: cursor + 4) == ":",
              declaration.isIdentifier(at: cursor + 5)
        else {
            return nil
        }
        let parameterTexts = declaration.texts[4..<shape.headerClose]
        if !isQualified, parameterTexts.contains(name) {
            return nil
        }
        var end = cursor + 6
        while declaration.text(at: end) == ".", declaration.isIdentifier(at: end + 1) {
            end += 2
        }
        let offsets = (shape.bodyOpen + 1)...shape.bodyClose
        let hasLiteralOnlyInPrefix = offsets.allSatisfy {
            $0 == commaOffset || declaration.gap(before: $0) == .trivia
        }
        guard declaration.text(at: end) == ")",
              end + 1 == shape.bodyClose,
              hasLiteralOnlyInPrefix
        else {
            return nil
        }
        return (composer, prefix, isQualified ? nil : name)
    }

    /// 未限定的組字串呼叫是否被所屬型別內同名的函式遮蔽，只要宣告過就保守判定遮蔽
    ///
    /// - Parameters:
    ///   - callee: 未限定呼叫的函式名稱；限定寫法為 `nil`
    ///   - context: 宣告所在的位置
    ///   - state: 累積的解析結果
    /// - Returns: 所屬型別內宣告過同名函式時為 `true`
    static func isShadowed(_ callee: String?, context: Context, state: ParseState) -> Bool {
        guard let callee, let owner = context.owner else {
            return false
        }
        return state.knownFunctions[owner]?[callee] != nil
    }

    /// 記一筆定義形式違規，名稱取宣告的名稱
    ///
    /// - Parameters:
    ///   - declaration: 違規宣告的記號視圖
    ///   - context: 宣告所在的位置
    ///   - state: 累積的解析結果
    static func reportForm(
        _ declaration: AccessibilityIdentifierDeclaration,
        context: Context,
        state: inout ParseState
    ) {
        let owner = context.owner ?? "BLAccessibilityID"
        state.violations.append(
            AccessibilityIdentifierScanner.Violation(
                rule: .definitionForm,
                path: context.path,
                line: declaration.firstLine,
                subject: "\(owner).\(declaredName(of: declaration))",
                value: "",
                detail: "宣告不在接受的定義形式內"
            )
        )
    }

    /// 取出宣告的名稱，供違規描述使用
    ///
    /// - Parameter declaration: 宣告的記號視圖
    /// - Returns: 第一個不是關鍵字的識別字；`subscript` 與編譯指令取關鍵字本身；找不到時為「(宣告)」
    static func declaredName(of declaration: AccessibilityIdentifierDeclaration) -> String {
        if declaration.texts.contains("subscript") {
            return "subscript"
        }
        if declaration.model.tokens[declaration.range.lowerBound].kind == .directive {
            return declaration.texts[0]
        }
        let keywords = AccessibilityIdentifierSourceModel.startKeywords
        let name = declaration.texts.indices.first {
            declaration.isIdentifier(at: $0) && !keywords.contains(declaration.texts[$0])
        }
        return name.map { declaration.texts[$0] } ?? "(宣告)"
    }
}
