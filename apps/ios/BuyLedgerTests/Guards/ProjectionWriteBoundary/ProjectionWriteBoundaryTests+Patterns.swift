//
//  ProjectionWriteBoundaryTests+Patterns.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/10/3.
//

import Foundation
import Testing

// MARK: - Internal Method

extension ProjectionWriteBoundaryTests {

    /// 判斷單行是否修改指定 `property`
    ///
    /// - Parameters:
    ///   - property: 要檢查的投影屬性名稱
    ///   - line: 已移除註解與字串內容的程式碼
    /// - Returns: 是否有寫入
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    static func isWritten(_ property: String, in line: String) throws(any Error) -> Bool {
        for prefix in ["state", "self"] {
            if try assignmentPattern(prefix: prefix, property: property).firstMatch(
                in: line,
                range: fullRange(of: line)
            ) != nil {
                return true
            }
            if try mutatingCallPattern(prefix: prefix, property: property).firstMatch(
                in: line,
                range: fullRange(of: line)
            ) != nil {
                return true
            }
        }
        if try bareAssignmentPattern(property: property).firstMatch(
            in: line,
            range: fullRange(of: line)
        ) != nil {
            return true
        }
        if try bareMutatingCallPattern(property: property).firstMatch(
            in: line,
            range: fullRange(of: line)
        ) != nil {
            return true
        }
        return false
    }

    /// 判斷是否有投影擁有者的型別宣告
    ///
    /// - Parameters:
    ///   - owner: 要尋找的投影擁有者
    ///   - files: 要搜尋的檔案清單
    /// - Returns: 是否找到投影擁有者的型別宣告
    /// - Throws: 原始檔讀取或規則建立失敗時拋出錯誤
    static func hasStructDeclaration(
        owner: ProjectionOwner,
        in files: [URL]
    ) throws(any Error) -> Bool {
        let escapedOwner = NSRegularExpression.escapedPattern(for: owner.name)
        let pattern = try NSRegularExpression(pattern: #"\bstruct\s+"# + escapedOwner + #"\b"#)

        for file in files {
            let content = try String(contentsOf: file, encoding: .utf8)
            var stripMode = StripMode.normal
            for rawLine in content.components(separatedBy: "\n") {
                let stripped = stripCommentsAndStrings(from: rawLine, mode: &stripMode)
                if pattern.firstMatch(in: stripped, range: fullRange(of: stripped)) != nil {
                    return true
                }
            }
        }
        return false
    }

    /// 取得整個字串涵蓋的 `NSRange`
    ///
    /// - Parameter text: 要計算範圍的字串
    /// - Returns: 完整字串範圍
    static func fullRange(of text: String) -> NSRange {
        NSRange(text.startIndex..<text.endIndex, in: text)
    }

    /// 格式化違規清單為人可讀之條列訊息
    ///
    /// - Parameter violations: 掃描命中的違規清單
    /// - Returns: 人可讀的違規說明
    static func describe(_ violations: [Violation]) -> String {
        violations.map { "\($0.file):\($0.line) (\($0.property))" }.joined(separator: "、")
    }

    /// 列出根目錄下所有 Swift 原始檔，排除生成檔目錄
    ///
    /// - Parameter root: 掃描根目錄
    /// - Returns: Swift 檔案清單
    /// - Throws: 目錄讀取失敗時拋出錯誤
    static func swiftFiles(under root: URL) throws(any Error) -> [URL] {
        let enumerator = try #require(
            FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
        )

        var files: [URL] = []
        for case let file as URL in enumerator {
            if file.pathComponents.contains(excludedDirectoryName) {
                continue
            }
            if file.pathExtension == "swift" {
                files.append(file)
            }
        }
        return files
    }

    /// 找出外部 helper 以非 `inout` 的 `State` 參數寫入投影的位置
    ///
    /// - Parameters:
    ///   - relativePath: 相對於 App 原始碼根目錄的路徑
    ///   - source: 待掃描的原始碼內容
    ///   - owner: 投影擁有者
    /// - Returns: 非 `inout` 子 `State` 參數的投影寫入位置
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    static func stateValueParameterViolations(
        relativePath: String,
        source: String,
        owner: ProjectionOwner
    ) throws(any Error) -> [Violation] {
        guard relativePath != owner.homeFileRelativePath else {
            return []
        }
        var mode = StripMode.normal
        let lines = source.components(separatedBy: "\n").map {
            stripCommentsAndStrings(from: $0, mode: &mode)
        }
        let stripped = lines.joined(separator: "\n")
        let escapedOwner = NSRegularExpression.escapedPattern(for: owner.name)
        let parameters = try NSRegularExpression(
            pattern: #"\b([\p{L}_][\p{L}\p{N}_]*)\s*:\s*"# + escapedOwner + #"\.State\b"#
        )
        var violations: [Violation] = []
        for match in parameters.matches(in: stripped, range: fullRange(of: stripped)) {
            let parameter = (stripped as NSString).substring(with: match.range(at: 1))
            for property in owner.properties {
                let assignment = try assignmentPattern(prefix: parameter, property: property)
                let mutation = try mutatingCallPattern(prefix: parameter, property: property)
                for (index, line) in lines.enumerated() {
                    if assignment.firstMatch(in: line, range: fullRange(of: line)) != nil
                        || mutation.firstMatch(in: line, range: fullRange(of: line)) != nil {
                        violations.append(
                            Violation(file: relativePath, line: index + 1, property: property)
                        )
                    }
                }
            }
        }
        return violations
    }

    /// 建立根狀態子層投影的賦值與變異方法比對規則，允許參數別名與跨行路徑
    ///
    /// - Parameters:
    ///   - rootKey: 根狀態持有子層的屬性名
    ///   - property: 此子層的投影屬性名
    /// - Returns: 完整子層投影寫入的正規表示式
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    static func rootProjectionWritePattern(
        rootKey: String,
        property: String
    ) throws(any Error) -> NSRegularExpression {
        let key = NSRegularExpression.escapedPattern(for: rootKey)
        let property = NSRegularExpression.escapedPattern(for: property)
        let methods = mutatingMethodNames.map(NSRegularExpression.escapedPattern(for:))
            .joined(separator: "|")
        let member = #"\b[\p{L}_$][\p{L}\p{N}_$]*\s*\.\s*"#
            + key + #"\s*\.\s*\$?"# + property
        let assignment = #"(?:\[[^\]]*\]\s*)?(?:=(?!=)|\+=|-=|\*=|/=)"#
        let mutation = #"\.\s*(?:(?:"# + methods + #")\s*\(|withLock\b)"#
        return try NSRegularExpression(
            pattern: member + #"\b\s*(?:"# + assignment + "|" + mutation + ")"
        )
    }
}

// MARK: - Private Method

private extension ProjectionWriteBoundaryTests {

    /// 建立有前綴的賦值樣式
    ///
    /// - Parameters:
    ///   - prefix: 屬性前的狀態或物件名稱
    ///   - property: 要檢查的投影屬性名稱
    /// - Returns: 指派比對規則
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    static func assignmentPattern(
        prefix: String,
        property: String
    ) throws(any Error) -> NSRegularExpression {
        let escapedProperty = NSRegularExpression.escapedPattern(for: property)
        let escapedPrefix = NSRegularExpression.escapedPattern(for: prefix)
        return try NSRegularExpression(
            pattern: #"\b"# + escapedPrefix + #"\."# + escapedProperty
                + #"\b\s*(?:\[[^\]]*\]\s*)?(?:=(?!=)|\+=|-=|\*=|/=)"#
        )
    }

    /// 建立「有前綴 `mutating` 方法呼叫」樣式：<prefix>.<property>.<方法名>(
    ///
    /// - Parameters:
    ///   - prefix: 屬性前的狀態或物件名稱
    ///   - property: 要檢查的投影屬性名稱
    /// - Returns: 變更呼叫比對規則
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    static func mutatingCallPattern(
        prefix: String,
        property: String
    ) throws(any Error) -> NSRegularExpression {
        let escapedProperty = NSRegularExpression.escapedPattern(for: property)
        let escapedPrefix = NSRegularExpression.escapedPattern(for: prefix)
        let alternation = mutatingMethodNames.map(NSRegularExpression.escapedPattern(for:))
            .joined(separator: "|")
        return try NSRegularExpression(
            pattern: #"\b"# + escapedPrefix + #"\."# + escapedProperty + #"\.(?:"# + alternation
                + #")\s*\("#
        )
    }

    /// 建立裸賦值樣式
    ///
    /// - Parameter property: 要檢查的投影屬性名稱
    /// - Returns: 不含前綴的指派比對規則
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    static func bareAssignmentPattern(property: String) throws(any Error) -> NSRegularExpression {
        let escaped = NSRegularExpression.escapedPattern(for: property)
        return try NSRegularExpression(
            pattern: #"(?<![\w.$])"# + escaped + #"\b\s*(?:\[[^\]]*\]\s*)?(?:=(?!=)|\+=|-=|\*=|/=)"#
        )
    }

    /// 建立裸 `mutating` 方法呼叫樣式
    ///
    /// - Parameter property: 要檢查的投影屬性名稱
    /// - Returns: 不含前綴的變更呼叫比對規則
    /// - Throws: 正規表示式建立失敗時拋出錯誤
    static func bareMutatingCallPattern(property: String) throws(any Error) -> NSRegularExpression {
        let escaped = NSRegularExpression.escapedPattern(for: property)
        let alternation = mutatingMethodNames.map(NSRegularExpression.escapedPattern(for:))
            .joined(separator: "|")
        return try NSRegularExpression(
            pattern: #"(?<![\w.$])"# + escaped + #"\.(?:"# + alternation + #")\s*\("#
        )
    }
}
