"""第 4.5 步 (service-database-layer-alignment) 機械與分區檢查，沿用第 4 步 (lookups-style-compliance) 的腳本

用法：
    python3 lookups_checks.py            # 取 git status 列出的全部 Swift 檔
    python3 lookups_checks.py <檔案 ...>  # 只查指定檔

A 組整檔檢查；B 組 (B_GROUP) 只查 git diff 新增或改動的行。
輸出每筆問題的代碼、行號與說明，最後一行是各代碼筆數；全部 0 才算通過。

代碼：
    W     行寬超過 100 (python 按字元計算)；只由單一字串字面值構成的行另列 WSTR，不計入失敗
    T     尾隨空白或 tab
    H     檔頭第 2 行檔名或第 5 行 `Created by Leo Ho on YYYY/M/D.` 不符 (A 組)
    LEN   不含檔頭 (前 7 行) 與空行超過 300 行 (A 組)
    LENX  EXISTING_OVER_LIMIT 內既有檔超過 300 行，只記錄、不算失敗
    MK1   MARK 段名不在允許清單
    MKN   巢狀型別內的 MARK (縮排 >= 8)
    MKNX  為巢狀型別另開 extension Outer.Nested
    NENUM 巢狀 enum 的 `{` 後缺空行或 case 之間缺空行 (formatting.md「巢狀型別」範例)
    PROPPOS 測試型別本體的 stored property 出現在 `// MARK: - Tests` 之後 (應放 `// MARK: - Properties`)
    MKC   測試檔的 MARK 不是規範區名 (含小分類 `// MARK: x` 與自創 `// MARK: - x`；使用者裁決)
    MKPRIV `// MARK: - Computed Properties` 底下是 `private extension` (private computed property 應放 Private Method)
    GWTR  `store.receive` 寫在 When (receive 屬於 Then；前置流程的 receive 可放 Given)
    GWTM  When 內有兩個以上的 `store.send` (前置動作移到 Given 或直設 initial state)
    GWTE  `#expect` 寫在 Given 或 When (前置條件用 `try #require`，斷言放 Then)
    GWTF  `store.finish()` 寫在 When (放 Then)
    FUNWRAP 強制解包 `!` (鐵則 3；`static let` 字面值與 IBOutlet 例外需人工確認)
    DOLLAR `withDependencies`／`send`／`receive` 的狀態 closure 取了具名參數 (tca-architecture：一律 `$0`)
    GUARDREC `guard … else` 內呼叫 `Issue.record` 或斷言 (改用 `try #require`)
    PARSP 括號內側多了空格 `( x )`
    CLBX  區塊的閉括號 `}` 前有空行 (本體不以空行結尾)
    CLSIG closure 簽章跨行 (參數列、effects 或 `in` 不與 `{` 同行；formatting.md Closure)
    RPAR  斷行呼叫的右括號沒有單獨一行 (`(` 在行尾的呼叫，對應的 `)` 前還有引數)
    GUARDX `guard … else` 內除了一個 return／throw／continue／break 之外還有其他敘述
    TRYQ  `try?` 同一行沒有註解說明失敗可忽略的理由 (coding-style Error Handling)
    DOCDUP 同一檔內三個以上宣告的 doc 摘要一字不差 (模板化空話)
    TAUT  恆真斷言 (`localizedDescription.isEmpty` 這類)
    OPEOL 運算子 (含賦值 `=`) 放在行尾就斷行 (formatting.md：運算子之前斷行、放續行行首；使用者裁決：`=` 之後不斷行，改在括號內斷)
    EQLEAD 把賦值 `=` 移到續行行首來規避 OPEOL (使用者裁決：右側有括號就在括號內斷)
    TYPEDCL 直接寫在函式本體的 typealias 型別化 closure 常數又標了 `throws(E)` (在 closure 本體內的常數推斷不出，必須標註，不算)
    DOLLARML 本體有多個敘述的 closure 用了 `$0` (使用者裁決：單一表達式跨行也用 `$0`；多敘述才具名；send／receive／withDependencies 與轉交的 helper 例外)
    NAMED1 單一表達式、單一參數的 closure，或修改 inout 值的 closure (`withLock`／`withValue`)，取了具名參數 (formatting.md:498，3.6.0；本體內另有用 `$0` 的巢狀 closure 時除外)
    NESTSL 寫在另一個 closure 本體內的 closure 寫成單行 (formatting.md:502，3.6.0：一律多行)
    TANAME closure 屬性的 typealias 名稱不是屬性名稱首字大寫 (tca-architecture.md:388)
    SWIFTUISL SwiftUI 的 View builder、modifier、action closure 寫成單行 (formatting.md:502，3.6.0：不論位置一律多行)
    DOLLAR2  closure 用了 `$1` 以上的簡寫 (formatting.md：兩個以上參數一律具名)
    NOTHROW 賦值的 closure 標了 `throws(E)` 但本體沒有 `throw`／`try` (formatting.md：本體不會 throw 時什麼都不用標)；傳給泛型 typed throws API 的尾隨 closure 不算
    COLONEOL 宣告在型別標註的 `:` 之後斷行 (formatting.md：只在逗號之後或運算子之前斷行)
    THENBL Then 段內 receive／#expect 之間的空行 (tca/FeatureTests.swift 樣板：receive 後直接接下一個 receive 或 #expect)
    WHOLESTATE send／receive 的狀態 closure 整個替換 State (`$0 = 變數`)，應直接寫出改變的欄位 (tca/FeatureTests.swift 樣板)
    MBL   型別本體內的方法之間缺空行 (`}` 後直接接下一個宣告的 `///`／`@`／`func`)
    ATTR  測試方法的屬性順序不是 `@Test` 在前、`@MainActor` 在後 (file-templates.md 範例)
    ARG4  同一行的呼叫或宣告有四個以上的引數或參數 (formatting.md：超過三個即使不超過 100 也斷行)；`case` 宣告與 typealias 函式型別除外
    FAILCL 測試以 `$0.x = { … throw … }` 直接注入失敗 closure (先以 typealias 宣告成常數再注入)；尚未改成 Service、沒有 typealias 的 `$0[XxxClient.self]` 不算
    MK2   頂層分區順序錯置
    DUP   同一頂層分區重複
    MKV   View 檔出現 Computed Properties 分區
    MK4   extension 專屬分區 (Nested Types、Computed Properties、Internal／Private Method、protocol 名等) 寫在型別本體內
    MK5   型別 (非 extension) 本體內出現 computed property；View 與 TCA 的 `var body` 除外
    CT    區塊內容不符 (見 content_issues)
    MAPL  `mapFetch`／`mapSave`／`wrapStorage` 的 trailing closure 寫成單行
    TRAILC 多行陣列、字典字面值的最後一個元素後面沒加逗號，或單行字面值加了尾隨逗號 (ios-dev-kit 3.8.0 formatting.md:37)
    HUG   唯一引數是陣列或字典字面值卻沒與括號貼合成 `([` … `])`，或兩個以上引數卻用了貼合寫法 (formatting.md:97)
    TNAME @Test 方法名稱不符 `<方法>_<情境>_<預期>` (ios-dev-kit 3.1.0)
    TNAMEL 舊式單段 lowerCamel 測試名稱 (使用者裁決：本 change 新寫與改到的測試都要改名)
    (第 4.5 步修正：`DependencyValues` 為樣板段名；DependencyKey 的 liveValue／previewValue／testValue 不算 MK5；
     樣板空本體不算 CLB；doc 查找跳過跨多行的屬性標註；新增 GRD：if／guard／while 多條件排版；新增 TSTL：`@Test` 單獨一行；SIG1 涵蓋泛型與 `)` 後斷行；單一參數簽章超寬記 WSIG 不算失敗 (2026-09-26 撤回：formatting.md 改為單一參數也斷行，只有斷行後的 `)` 行可超過)；新增 CASELET)
    MOD   modifier 跨組順序錯置 (只認 formatting.md 表列的 modifier)
    BRACE 宣告 (var／func／init) 或 guard 的大括號本體壓成單行 (apps/ios/CLAUDE.md 硬規則)
    SIG1  只有一個參數的 func／init 簽章被拆成多行 (formatting.md 避免)
    D1    型別或 extension 本體內的宣告缺 /// (以大括號追蹤判斷，函式與 closure 內的區域變數不算)
    D2    func／init 有參數但 doc 缺 - Parameter
    D3    func 有回傳值 (含 some View) 但 doc 缺 - Returns
    D4    func／init 會 throw 但 doc 缺 - Throws (rethrows 除外)
    D9    enum case 帶 associated value 但 doc 缺 - Parameter
    DOCBL doc 摘要與 - Parameter／- Returns／- Throws 之間缺空的 ///
    TD    @Test (或 UI 測試的 func test...) 缺 ///
    GWT   @Test 或 UI 測試 func test... 的函式本體 (以大括號界定) 缺 // Given、// When 或 // Then
    GWT0  // When 或 // Then 底下第一個不是一般註解的非空行是 } 或另一個標記
    CALL1 未達斷行條件 (接成一行不超過 100 且不超過三個) 卻拆成多行 (3.1.0)
    PARTW 斷行後多個參數或引數擠在同一行 (部分換行)
    SELF1 裝 closure 的依賴 struct (Service／Client／Store／Repository) 帶 closure 引數的建構寫成一行，或 Service 的 `Self(` 寫成一行 (專案裁決：一律換行)
    CARG  括號內有多行 closure 引數時，引數沒有各自獨立一行 (3.1.0)
    GWTB  標記後多了空行，或 // When、// Then 前面缺空行 (ios-dev-kit 3.0.0)
    GWTS  // When、// Then 與 // Given 不在同一縮排層級 (寫進 send 或 do／catch 的 closure；使用者裁決)
    CASEML enum 的 case 宣告拆成多行 (formatting.md:39；超過 100 的單行 case 宣告記 WSIG，不計入失敗)
    CASECONT switch 多 pattern case 清單斷行：續行比 case 多 8 格、每行排滿 100 才斷 (formatting.md 3.7.0:41)
    D6    註解結尾中文句號
    DASH  註解破折號
    PAREN 註解全形括號
"""
import os
import re
import subprocess
import sys
from collections import Counter

ROOT = '/Users/leoho/Develop/BuyLedger'
os.chdir(ROOT)

# 本 change (service-database-layer-alignment) 對所有變更檔整檔檢查，不再只查 diff 行
B_GROUP = set()

# 既有超過 300 行的檔，拆檔屬結構性重構、排在第 5 至 8 步；LEN 只記錄不算失敗 (2026-09-25 實測 16 檔)
EXISTING_OVER_LIMIT = {
    'apps/ios/BuyLedger/Features/Orders/OrdersFeature.swift',
    'apps/ios/BuyLedger/Features/Orders/OrderEditFeature.swift',
    'apps/ios/BuyLedger/Features/Campaigns/CampaignFeature.swift',
    'apps/ios/BuyLedger/Features/App/RootFeature.swift',
    'apps/ios/BuyLedger/App/Testing/BLUITestDependencyOverrides.swift',
    'apps/ios/BuyLedgerTests/OrdersFeatureTests.swift',
    'apps/ios/BuyLedgerTests/RootFeatureTests.swift',
    'apps/ios/BuyLedgerTests/CampaignFeatureTests.swift',
    'apps/ios/BuyLedgerTests/OrderEditFeatureTests.swift',
    'apps/ios/BuyLedgerTests/CampaignReminderFailureTests.swift',
    'apps/ios/BuyLedgerTests/SchemaMigrationTests.swift',
    'apps/ios/BuyLedgerTests/QuoteFeatureTests.swift',
    'apps/ios/BuyLedgerTests/OrderMergeFeatureTests.swift',
    'apps/ios/BuyLedgerTests/SnapshotTests.swift',
    'apps/ios/BuyLedgerTests/SettingsFeatureTests.swift',
    'apps/ios/BuyLedgerTests/PersistenceRecoveryTests.swift',
}

# `URLProtocol` 是使用者裁決的父類別覆寫 extension MARK 名稱
PROTO = {'ViewModifier', 'ButtonStyle', 'ProgressViewStyle', 'View', 'Identifiable', 'Equatable',
         'Codable', 'CaseIterable', 'Hashable', 'Sendable', 'DependencyKey', 'Encodable', 'Decodable',
         'CustomStringConvertible', 'Error', 'LocalizedError', 'Comparable', 'URLProtocol'}

def repo_protocols():
    """收集 repo 內宣告的 protocol 名稱，讓以 protocol 名命名的 MARK 視為合法段名"""
    out = subprocess.run(['grep', '-rhoE', r'^(public |internal )?protocol [A-Z][A-Za-z0-9]*',
                          'apps/ios', '--include=*.swift'], capture_output=True, text=True).stdout
    return {line.split()[-1] for line in out.splitlines()}


PROTO |= repo_protocols()
GENERIC = ['Properties', 'Init', 'Nested Types', 'Computed Properties', 'Internal Method', '__P__',
           'Private Method']
VIEW = ['Properties', 'Init', 'Body', 'Private Views', 'Nested Types', 'Private Method', 'Preview']
TESTS = ['Properties', 'Init', 'Tests', 'Nested Types', 'Computed Properties', 'Internal Method',
         '__P__', 'Private Method']
TCA = ['State', 'Action', 'Dependencies', 'Body', 'Nested Types', '__P__', 'Private Method']
# `tca/DependencyKey.swift` 等樣板使用的段名
TEMPLATE_EXTRA = ['DependencyValues']
ALLOWED = set(GENERIC) | set(VIEW) | set(TCA) | set(TESTS) | set(TEMPLATE_EXTRA)

LAYOUT = {'padding', 'frame', 'offset', 'fixedSize', 'layoutPriority', 'safeAreaInset'}
APPEARANCE = {'background', 'foregroundStyle', 'font', 'clipShape', 'overlay', 'shadow', 'opacity',
              'tint'}
BEHAVIOR = {'onTapGesture', 'onChange', 'onAppear', 'task', 'refreshable', 'disabled',
            'accessibilityLabel'}
NAVIGATION = {'navigationTitle', 'navigationDestination', 'toolbar', 'sheet', 'fullScreenCover',
              'alert', 'confirmationDialog'}


def modifier_group(name):
    for index, group in enumerate((LAYOUT, APPEARANCE, BEHAVIOR, NAVIGATION), 1):
        if name in group:
            return index
    return 0


def git_files():
    out = subprocess.run(['git', 'status', '--porcelain', '-uall'], capture_output=True,
                         text=True).stdout
    files = []
    for line in out.splitlines():
        path = line[3:]
        if ' -> ' in path:
            path = path.split(' -> ')[1]
        if path.endswith('.swift') and os.path.exists(path):
            files.append(path)
    return sorted(files)


def changed_lines(path):
    tracked = subprocess.run(['git', 'ls-files', '--error-unmatch', path], capture_output=True)
    if tracked.returncode != 0:
        return None
    diff = subprocess.run(['git', 'diff', '-U0', 'HEAD', '--', path], capture_output=True,
                          text=True).stdout
    lines = set()
    for m in re.finditer(r'^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@', diff, re.M):
        start = int(m.group(1))
        count = int(m.group(2) or '1')
        lines.update(range(start, start + count))
    return lines


def file_kind(path, text):
    if '/BuyLedgerTests/' in path or '/BuyLedgerUITests/' in path:
        return 'test', TESTS
    if '@Reducer' in text and re.search(r'^struct \w+ \{', text, re.M) and '// MARK: - State' in text:
        return 'tca', TCA
    if re.search(r'^struct \w+: View\b', text, re.M):
        return 'view', VIEW
    return 'plain', GENERIC


DECL = re.compile(r'^(?P<ind>\s*)(?P<mods>(?:@\w+(?:\([^)]*\))?\s+|public |internal |private |'
                  r'fileprivate |static |nonisolated |final |lazy |override |mutating )*)'
                  r'(?P<kw>let|var|func|init|struct|enum|class|actor|typealias|subscript)\b'
                  r'(?P<rest>.*)$')


def content_issues(lines, kind):
    """區塊內容相符：每個頂層 MARK 區塊的最外層成員種類要符合該區

    - Properties：不得有 func 或 computed property
    - Computed Properties：不得有 func
    - Internal Method／Private Method：不得有 stored property；computed property 只允許出現在 View
      與 TCA Feature 的 Private Method (這兩種型別沒有 Computed Properties 分區)
    - Nested Types：最外層不得有 let／var／func
    - Body：只能有 var body (TCA 與 View)
    - View 檔不得有 Computed Properties 分區 (另以 MKV 回報)
    """
    issues = []
    marks = [(i, m.group(2).strip(), len(m.group(1))) for i, l in enumerate(lines)
             for m in [re.match(r'^(\s*)// MARK: - (.+)$', l)] if m]
    top = [(i, name) for i, name, ind in marks if ind <= 4]
    for j, (start, name) in enumerate(top):
        end = top[j + 1][0] if j + 1 < len(top) else len(lines)
        base = None
        for k in range(start + 1, end):
            line = lines[k]
            if line.strip().startswith(('//', '#')) or not line.strip():
                continue
            if re.match(r'^\s*(private |fileprivate |public |)extension \w', line):
                base = None
                continue
            m = DECL.match(line)
            if not m:
                continue
            ind = len(m.group('ind'))
            if base is None:
                base = ind
            if ind != base:
                continue
            kw, rest = m.group('kw'), m.group('rest')
            head = rest.split('{')[0]
            is_computed = kw == 'var' and rest.rstrip().endswith('{') and '=' not in head
            text = line.strip()[:70]
            bad = None
            if name == 'Properties' and (kw == 'func' or is_computed):
                bad = 'computed property' if is_computed else 'func'
            elif name == 'Computed Properties' and kw == 'func':
                bad = 'func'
            elif name in ('Internal Method', 'Private Method') and kw in ('let', 'var'):
                # private 的 computed property 放 Private Method (formatting.md)；非 private 的放 Computed Properties
                if not is_computed:
                    bad = 'stored property'
                elif name == 'Internal Method':
                    bad = 'computed property (應放 Computed Properties)'
            elif name == 'Nested Types' and kw in ('let', 'var', 'func'):
                bad = kw
            elif name == 'Body' and not (kw == 'var' and 'body' in rest.split(':')[0]):
                bad = kw
            if bad:
                issues.append((k + 1, 'CT', f'「{name}」區塊放了 {bad}：{text}'))
    return issues


def strip_code(line):
    """移除字串字面值與行尾註解，只留大括號計數要看的程式碼"""
    line = re.sub(r'"(?:[^"\\]|\\.)*"', '""', line)
    return line.split('//')[0]


def block_contexts(lines):
    """回傳每一行開頭所在的區塊種類：'type' (型別或 extension 本體) 或 'code' (函式、closure 等)"""
    stack = []
    result = []
    for line in lines:
        result.append(stack[-1] if stack else 'type')
        code = strip_code(line)
        match = re.search(r'\b(struct|enum|class|actor|extension|protocol)\b[^=(]*\{', code)
        opens_type = match and not re.search(r'\b(func|var|let|init|case)\b',
                                              code.split('{')[0].split(':')[0])
        kind = 'ext' if opens_type and match.group(1) == 'extension' else 'type'
        for index, char in enumerate(code):
            if char == '{':
                stack.append(kind if opens_type and index == code.index('{') else 'code')
            elif char == '}' and stack:
                stack.pop()
    return result


def doc_lines(lines, number):
    """取宣告上方的 /// 區塊 (跳過屬性行、跨多行的屬性標註與 #if)"""
    j = number - 2
    while j >= 0:
        t = lines[j].strip()
        if t.startswith(('@', '#if', '#endif')):
            j -= 1
            continue
        # 跨多行的屬性標註 (如 `@Relationship(` … `)`)：往上找到括號配平的 `@` 行
        if t.endswith(')') and not t.startswith('///'):
            depth = 0
            k = j
            found = -1
            while k >= 0:
                u = lines[k].strip()
                depth += u.count(')') - u.count('(')
                if u.startswith('@') and depth <= 0:
                    found = k
                    break
                if u.startswith('///') or u == '':
                    break
                k -= 1
            if found >= 0:
                j = found - 1
                continue
        break
    doc = []
    while j >= 0 and lines[j].strip().startswith('///'):
        doc.insert(0, lines[j].strip())
        j -= 1
    return doc


def has_return_type(signature):
    """以括號配對找出頂層參數列結尾，只看其後是否接回傳箭頭 (init 與 closure 參數的 -> 不算)"""
    m = re.search(r'\b(func|init)\b', signature)
    if not m or m.group(1) == 'init':
        return False
    start = signature.find('(', m.end())
    if start < 0:
        return False
    depth = 0
    for j in range(start, len(signature)):
        if signature[j] == '(':
            depth += 1
        elif signature[j] == ')':
            depth -= 1
            if depth == 0:
                rest = signature[j + 1:]
                return re.match(r'\s*(?:async\s+)?(?:throws(?:\([^)]*\))?\s+)?->', rest) is not None
    return False


def collect_signature(lines, number):
    """從宣告行往下收集到第一個 { 為止的簽章文字"""
    parts = []
    for line in lines[number - 1:number + 20]:
        if not line.strip():
            break
        parts.append(strip_code(line))
        if '{' in parts[-1]:
            break
    return ' '.join(parts)


def function_body(lines, index):
    """從 @Test 所在行往下找到函式的 { 並回傳到對應 } 為止的 (行號, 內容)"""
    depth = 0
    started = False
    body = []
    for k in range(index, len(lines)):
        code = strip_code(lines[k])
        body.append((k + 1, lines[k]))
        for char in code:
            if char == '{':
                depth += 1
                started = True
            elif char == '}':
                depth -= 1
        if started and depth <= 0:
            break
    return body


def check(path):
    issues = []
    text = open(path, encoding='utf-8').read()
    lines = text.split('\n')
    scope = changed_lines(path) if path in B_GROUP else None
    whole = scope is None

    def add(n, code, msg):
        if whole or n in scope:
            issues.append((n, code, msg))

    kind, order = file_kind(path, text)

    if whole:
        if len(lines) < 6 or not re.match(r'^//  Created by Leo Ho on \d{4}/\d{1,2}/\d{1,2}\.$',
                                          lines[4]):
            issues.append((5, 'H', f'檔頭第 5 行：{lines[4] if len(lines) > 4 else ""}'))
        elif re.search(r'/0\d', lines[4]):
            issues.append((5, 'H', '檔頭日期補零'))
        if len(lines) > 1 and os.path.basename(path) != lines[1].replace('//  ', '').strip():
            issues.append((2, 'H', f'檔頭檔名不符：{lines[1]}'))
        count = sum(1 for l in lines[7:] if l.strip())
        if count > 300:
            issues.append((1, 'LEN', f'不含檔頭與空行 {count} 行'))

    for i, line in enumerate(lines, 1):
        code = strip_code(line).strip()
        if re.match(r'^(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:private|fileprivate|static|nonisolated|public|'
                    r'override|mutating)\s+)*(?:var|func|init)\b[^{]*\{\s*\S.*\}$', code) \
                or re.match(r'^guard\b.*\belse\s*\{\s*\S.*\}$', code):
            add(i, 'BRACE', f'宣告或 guard 的大括號本體壓成單行：{code[:60]}')
        if re.match(r'^(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:private|fileprivate|static|nonisolated|public|'
                    r'override|mutating)\s+)*(?:func\s+\w+(?:<[^()]*>)?|init)\($', code):
            params = []
            closing = ''
            for follow in lines[i:i + 8]:
                stripped = follow.strip()
                if stripped.startswith(')'):
                    closing = stripped
                    break
                params.append(stripped)
            # 單一參數只有接回一行不超過 100 時才算多拆 (超過 100 要斷行，formatting.md 2026-09-26 版)
            if len(params) == 1 and len(line.rstrip() + params[0] + closing) <= 100:
                add(i, 'SIG1', f'單一參數的簽章被拆行：{code[:60]}')
        # CALL1：未達斷行條件 (接成一行不超過 100 且不超過三個) 卻拆成多行 (formatting.md 3.1.0「參數與引數對齊」)
        #        宣告、init、typealias 與呼叫端都適用；單一參數的宣告由 SIG1 負責
        service_construction = (re.search(r'Service\+(?:Dependency|Preview)\.swift$', path)
                                and re.match(r'^(?:return\s+)?Self\($', code)) \
            or (re.search(r'\b(?!TestStore\()(?:[A-Z]\w*(?:Service|Client|Store|Repository)|Self)\($', code)
                and any('{' in follow for follow in lines[i:i + 6]))
        if code.endswith('(') and not re.match(r'^case\b', code) and not service_construction:
            indent = len(line) - len(line.lstrip())
            arguments = []
            closing = None
            for follow in lines[i:i + 6]:
                stripped = follow.strip()
                if stripped.startswith(')') and len(follow) - len(follow.lstrip()) == indent:
                    closing = follow.strip()
                    break
                arguments.append(stripped)
            # 以 . 開頭的行接在逗號之後是隱式成員引數 (`.deviceOwnerAuthentication,`)，否則是前一引數的鏈式續行
            single_line = arguments and all(
                a and not a.endswith(('(', '{', '[')) and not a.startswith((')', '}', ']', '//'))
                and (not a.startswith('.') or len(arguments) == 1 or k == 0 or arguments[k - 1].endswith(','))
                for k, a in enumerate(arguments)
            )
            is_declaration = bool(re.match(r'^(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:private|fileprivate|static|'
                                           r'nonisolated|public|override|mutating)\s+)*(?:func\s|init\b)', code))
            if closing is not None and single_line and len(arguments) <= 3 \
                    and not (is_declaration and len(arguments) == 1):
                joined = line.rstrip() + ' '.join(arguments) + closing
                if len(joined) <= 100:
                    add(i, 'CALL1', f'未達斷行條件卻拆成多行 ({len(arguments)} 個，接成一行 {len(joined)} 字元)：{code[:50]}')
        # PARTW：斷行後把多個參數或引數擠在同一行 (formatting.md「避免部分換行」)
        if code.endswith('(') and not re.match(r'^case\b', code):
            indent = len(line) - len(line.lstrip())
            for follow in lines[i:i + 12]:
                stripped = follow.strip()
                if stripped.startswith(')') and len(follow) - len(follow.lstrip()) <= indent:
                    break
                if len(follow) - len(follow.lstrip()) != indent + 4:
                    continue
                body = strip_code(follow).strip().rstrip(',')
                depth = 0
                top_level_comma = False
                for ch in body:
                    if ch in '([{':
                        depth += 1
                    elif ch in ')]}':
                        depth -= 1
                    elif ch == ',' and depth == 0:
                        top_level_comma = True
                        break
                if top_level_comma and depth >= 0 and not body.startswith(('case ', '//')):
                    add(i, 'PARTW', f'斷行後多個參數或引數擠在同一行：{stripped[:50]}')
                    break
        # SELF1：Service 的 `Self(` 建構一律換行 (使用者 2026-09-26 裁決，design「規範解讀的使用者裁決」)
        if re.search(r'Service\+(?:Dependency|Preview)\.swift$', path) and re.match(r'^(?:return\s+)?Self\(\w+:', code):
            add(i, 'SELF1', f'Service 的 Self( 建構要換行，每個 closure 一行：{code[:50]}')
        # SELF1 (擴大)：依賴 struct 帶 closure 引數的建構一律換行，不限檔案 (使用者 2026-09-27 裁決)
        dependency_call = re.search(r'\b(?:[A-Z]\w*(?:Service|Client|Store|Repository)|Self)\(', code)
        if dependency_call and '{' in code[dependency_call.end():] \
                and re.search(r'\)[,;]?$', code) and not code.endswith('{'):
            add(i, 'SELF1', f'依賴 struct 帶 closure 的建構要換行，每個 closure 一行：{code[:60]}')
        # CARG：括號內有多行本體的 closure 引數時，每個引數要獨立一行 (formatting.md 3.1.0)
        depth_stack = []
        for ch in code:
            if ch in '({[':
                depth_stack.append(ch)
            elif ch in ')}]' and depth_stack:
                depth_stack.pop()
        if '(' in depth_stack and depth_stack[-1] == '{' and depth_stack.index('(') < len(depth_stack) - 1 \
                and not re.match(r'^(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:private|fileprivate|static|nonisolated|'
                                 r'public|override|mutating)\s+)*(?:func\s|init\b|var\s)', code):
            add(i, 'CARG', f'多行 closure 引數與呼叫寫在同一行，引數應各自獨立一行：{code[:50]}')
        # SIG1：在 `)` 之後斷行、把 throws／回傳型別放到下一行 (規範沒有這種寫法)
        if re.match(r'^(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:private|fileprivate|static|nonisolated|public|'
                    r'override|mutating)\s+)*(?:func\s+\w+|init)\b.*\)$', code) \
                and i < len(lines) and re.match(r'^\s*(?:async\b|throws\b|rethrows\b|->)', lines[i]):
            add(i, 'SIG1', f'簽章在 `)` 之後斷行：{code[:60]}')
        # TNAME：測試方法名稱 `<方法或行為>_<情境>_<預期>`，第一段 lowerCamel、後兩段含正體中文 (ios-dev-kit 3.1.0 file-templates.md)
        #        TNAMEL：舊式單段 lowerCamel；本 change 新寫與改到的測試都要改 (使用者 2026-09-26 裁決)
        name_match = re.match(r'\s*(?:@\w+(?:\([^)]*\))?\s+)*func\s+([^\s(<]+)\s*[(<]', code)
        # 往上找到 doc 註解、空行或上一個宣告的結尾為止，涵蓋跨多行的 `@Test(arguments: [...])`
        attribute_start = i - 1
        while attribute_start > 0 and attribute_start > i - 60:
            previous = lines[attribute_start - 1].strip()
            if not previous or previous.startswith('///') or previous == '}':
                break
            attribute_start -= 1
        if kind == 'test' and name_match and '@Test' in ''.join(lines[attribute_start:i]):
            test_name = name_match.group(1)
            segments = test_name.split('_')
            cjk = re.compile(r'[\u3400-\u9fff]')
            if len(segments) == 1 and re.fullmatch(r'[a-z][A-Za-z0-9]*', test_name):
                add(i, 'TNAMEL', f'舊式單段 lowerCamel 測試名稱：{test_name[:50]}')
            elif not (len(segments) == 3 and re.fullmatch(r'[a-z][A-Za-z0-9]*', segments[0])
                      and all(cjk.search(segment) for segment in segments[1:])):
                add(i, 'TNAME', f'測試名稱不符 `<方法>_<情境>_<預期>` (後兩段用正體中文)：{test_name[:50]}')
        # MAPL：錯誤對應 helper 的 closure 本體不能和 `{` 或簽章寫在同一行
        helper_closure = re.search(r'\b(?:mapFetch|mapSave|wrapStorage)\s*\{', code)
        if helper_closure:
            closure_header = code[helper_closure.end():]
            has_inline_body = bool(closure_header.strip()) and not re.search(
                r'\bin\s*$', closure_header
            )
            if has_inline_body:
                add(i, 'MAPL', f'錯誤對應 helper 的 closure 寫成單行：{code.strip()[:60]}')
        # typealias 的函式型別：有參數時超過 100 要斷行；無參數時維持一行 (使用者 2026-09-26 裁決)
        no_param_typealias = re.match(r'^\s*(?:(?:private|fileprivate)\s+)?typealias\s+\w+\s*=\s*(?:@\w+\s+)*\(\)', line)
        # 函式簽章只有一個參數也要斷行 (formatting.md 2026-09-26 版)；斷行後 `)` 那一行仍超過 100 時允許
        wrapped_signature_tail = re.match(r'^\s*\)\s*(?:async\b|throws\b|rethrows\b|->|\{|where\b)', line)
        no_param_decl = re.match(
            r'^\s*(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:private|fileprivate|static|nonisolated|public|'
            r'override|mutating)\s+)*(?:func\s+\w+(?:<[^()]*>)?|init)\(\)', line)
        # enum 的 case 宣告超過 100 也維持一行 (formatting.md:39)；switch 的 case pattern 以 `:` 結尾不算
        enum_case_decl = re.match(r'^\s*(?:indirect\s+)?case\s+[a-z]\w*\(', line) and not strip_code(line).rstrip().endswith(':')
        if re.match(r'^\s*(?:indirect\s+)?case\s+[a-z]\w*\($', strip_code(line).rstrip()):
            add(i, 'CASEML', 'enum 的 case 宣告拆成多行 (formatting.md:39：超過 100 也維持一行)')
        if len(line) > 100 and enum_case_decl:
            add(i, 'WSIG', f'enum case 宣告行寬 {len(line)} (formatting.md:39 維持一行，不計入失敗)')
        elif len(line) > 100 and no_param_typealias:
            add(i, 'WSIG', f'無參數 typealias 行寬 {len(line)} (使用者裁決維持一行，不計入失敗)')
        elif len(line) > 100 and no_param_decl:
            add(i, 'WSIG', f'無參數函式宣告行寬 {len(line)} (使用者裁決維持一行，不計入失敗)')
        elif len(line) > 100 and wrapped_signature_tail:
            add(i, 'WSIG', f'斷行後的簽章右括號行寬 {len(line)} (formatting 允許，不計入失敗)')
        elif len(line) > 100:
            if re.search(r'(?:= |\w+: )\{ [^{}]*\bin$', line.rstrip()) or re.search(r'[\w\].]+ = \{ [^{}]*\bin$', line.rstrip()) \
                    or re.match(r'^\s*(?:private\s+)?(?:static\s+)?let\s+\w+\s*:\s*[\w.]+\s*=\s*\{$', line.rstrip()):
                add(i, 'WCL', f'closure 簽章行寬 {len(line)} (formatting 允許，不計入失敗)')
            elif re.fullmatch(r'\s*"(?:[^"\\]|\\.)*"[,)]?\s*', line) \
                    or re.fullmatch(r'\s*(?:(?:(?:private|fileprivate|static|nonisolated)\s+)*(?:let|var)\s+\w+(?:\s*:\s*[\w.]+)?\s*=|\w+:)\s*(#*)".*"\1[,)]?\s*', line):
                add(i, 'WSTR', f'單一字串字面值行寬 {len(line)} (列出說明，不計入失敗)')
            else:
                add(i, 'W', f'行寬 {len(line)}')
        if re.search(r'\{ throws\(', strip_code(line)):
            add(i, 'CL0', '無參數 closure 省略 () 無法編譯，寫 { () throws(E) in')
        if re.search(r'[ \t]+$', line):
            add(i, 'T', '尾隨空白')
        stripped = line.strip()
        if stripped.startswith('//'):
            body = stripped.lstrip('/').strip()
            if body.endswith('。'):
                add(i, 'D6', '註解結尾句號')
            if '——' in body or re.search(r'\S\s—\s\S', body):
                add(i, 'DASH', '註解破折號')
            if '（' in body or '）' in body:
                add(i, 'PAREN', '全形括號')
            m = re.match(r'^(\s*)// MARK: - (.+?)\s*$', line)
            if m and m.group(2) not in ALLOWED and m.group(2) not in PROTO:
                add(i, 'MK1', f'MARK 段名：{m.group(2)}')
            if m and len(m.group(1)) >= 8:
                add(i, 'MKN', f'巢狀型別內的 MARK：{m.group(2)}')
            if m and kind == 'view' and m.group(2) == 'Computed Properties':
                add(i, 'MKV', 'View 沒有 Computed Properties 分區')
            if m and len(m.group(1)) == 4 and (m.group(2) in ('Nested Types', 'Computed Properties',
                                                            'Internal Method', 'Private Method',
                                                            'Private Views', 'Preview')
                                               or m.group(2) in PROTO):
                add(i, 'MK4', f'extension 專屬分區寫在型別本體內：{m.group(2)}')

    # MKNX：為巢狀型別另開 `extension Outer.Nested` (formatting.md「巢狀型別」：成員與 protocol 實作就地寫在本體)
    for i, line in enumerate(lines, 1):
        if re.match(r'^(?:private\s+|fileprivate\s+)?extension\s+[A-Z]\w*\.[A-Z]\w*\b', line) \
                and not re.match(r'^(?:private\s+|fileprivate\s+)?extension\s+(?:Swift|Foundation|DependencyValues)\.', line) \
                and not re.match(r'^(?:private\s+|fileprivate\s+)?extension\s+[A-Z]\w*\.Destination\.State\b', line):
            # `@Reducer enum Destination` 的 State 由巨集產生，遵循與 alert 建構只能寫在 extension (apps/ios/CLAUDE.md 例外)
            add(i, 'MKNX', f'為巢狀型別另開 extension：{line.strip()[:60]}')

    marks = [(i + 1, len(m.group(1)), m.group(2)) for i, l in enumerate(lines)
             for m in [re.match(r'^(\s*)// MARK: - (.+?)\s*$', l)] if m]
    top = [(n, name) for n, ind, name in marks if ind <= 4]

    def key(name):
        return '__P__' if name in PROTO else name
    seq = [(n, name, order.index(key(name))) for n, name in top if key(name) in order]
    for a, b in zip(seq, seq[1:]):
        if b[2] < a[2]:
            add(b[0], 'MK2', f'分區順序：{b[1]} 排在 {a[1]} 之後')
    names = [name for _, name in top if name not in PROTO]
    for name, c in Counter(names).items():
        if c > 1:
            lns = [n for n, nm in top if nm == name]
            add(lns[-1], 'DUP', f'分區重複：{name} 於 {lns}')

    for n, code, msg in content_issues(lines, kind):
        add(n, code, msg)

    chain = []
    for i, line in enumerate(lines, 1):
        m = re.match(r'^\s*\.(\w+)[\s({]', line)
        if m and modifier_group(m.group(1)):
            chain.append((i, m.group(1), modifier_group(m.group(1)),
                          len(line) - len(line.lstrip())))
            continue
        if m or not line.strip() or line.strip().startswith(('}', ')')):
            continue
        for a, b in zip(chain, chain[1:]):
            if a[3] == b[3] and b[2] < a[2]:
                add(b[0], 'MOD', f'.{b[1]} (第 {b[2]} 組) 排在 .{a[1]} (第 {a[2]} 組) 之後')
        chain = []

    preview_start = next((i for i, l in enumerate(lines, 1) if l.strip() == '// MARK: - Preview'),
                         len(lines) + 1)
    contexts = block_contexts(lines)
    decl = re.compile(r'^\s*(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:private|fileprivate|internal|public|'
                      r'static|nonisolated|override|final|mutating|let|var|func|init|case|enum|'
                      r'struct|class|actor|protocol|typealias)\b)')
    for i, line in enumerate(lines, 1):
        s = line.strip()
        if i > preview_start or not decl.match(line):
            continue
        if re.search(r'\bextension\b', s):
            continue
        if contexts[i - 1] not in ('type', 'ext'):
            continue
        if contexts[i - 1] == 'type' and (len(line) - len(line.lstrip())) == 4 \
                and re.match(r'^(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:private|static|nonisolated|public)\s+)*'
                             r'var\s+(\w+)\s*:[^=]*\{\s*$', s) \
                and not re.match(r'^(?:@\w+\s+)*var body\b', s) \
                and not re.search(r'\bvar (liveValue|previewValue|testValue)\b', s):
            add(i, 'MK5', f'型別本體內的 computed property (應放 extension)：{s[:60]}')
        if s.startswith(('case let', 'case .', 'case (', 'case "')) or (s.startswith('case')
                                                                      and s.endswith(':')):
            continue
        doc = doc_lines(lines, i)
        if not doc:
            add(i, 'D1', f'缺 ///：{s[:70]}')
            continue
        text = '\n'.join(doc)
        signature = collect_signature(lines, i)
        if re.match(r'^(?:@\w+(?:\([^)]*\))?\s+)*(?:\w+\s+)*(func|init)\b', s):
            params = re.search(r'\(([^()]|\([^()]*\))*\)', signature)
            param_text = params.group(0) if params else ''
            if re.search(r'\w+\s*:', param_text) and '- Parameter' not in text:
                add(i, 'D2', f'有參數缺 - Parameter：{s[:60]}')
            if has_return_type(signature) and '- Returns' not in text:
                add(i, 'D3', f'有回傳缺 - Returns：{s[:60]}')
            if re.search(r'\bthrows\b', signature.split('{')[0]) and 'rethrows' not in signature \
                    and '- Throws' not in text:
                add(i, 'D4', f'會拋錯缺 - Throws：{s[:60]}')
        m = re.match(r'^case\s+\w+\s*\((.*)\)\s*$', s)
        if m and '- Parameter' not in text:
            add(i, 'D9', f'associated value 缺 - Parameter：{s[:60]}')

    for i, line in enumerate(lines, 1):
        if re.match(r'\s*/// - (Parameter|Parameters|Returns|Throws|Note)\b', line):
            prev = lines[i - 2].strip()
            if prev.startswith('/// -') or prev.startswith('///   -') or prev == '///':
                continue
            add(i, 'DOCBL', '摘要與參數標記之間缺空的 ///')

    markers = ('// Given', '// When', '// Then')
    is_ui_test = '/BuyLedgerUITests/' in path
    for i, line in enumerate(lines, 1):
        is_xctest = is_ui_test and re.match(r'^\s*func test\w*\(', line)
        if not re.match(r'^\s*@Test\b', line) and not is_xctest:
            continue
        j = i - 2
        while j >= 0 and lines[j].strip().startswith('@'):
            j -= 1
        if not lines[j].strip().startswith('///'):
            add(i, 'TD', '@Test 缺 ///')
        body = function_body(lines, i - 1)
        texts = [t for _, t in body]
        for marker in markers:
            if not any(t.strip().startswith(marker) for t in texts):
                add(i, 'GWT', f'缺 {marker}')
        for idx, (n, t) in enumerate(body):
            if not t.strip().startswith(('// When', '// Then')):
                continue
            following = [b.strip() for _, b in body[idx + 1:] if b.strip()]
            code = next((f for f in following
                         if not f.startswith('//') or f.startswith(markers)), '}')
            if code == '}' or code.startswith(markers):
                add(n, 'GWT0', f'{t.strip()} 底下沒有程式碼')
        # GWTB：標記後直接接程式碼；`// When`、`// Then` 前空一行 (ios-dev-kit 3.0.0)
        for n, t in body:
            marker = t.strip()
            if marker not in markers:
                continue
            following = lines[n] if n < len(lines) else ''
            empty_given = marker == '// Given' and n + 1 < len(lines) \
                and lines[n + 1].strip() == '// When'
            if following.strip() == '' and not empty_given:
                add(n, 'GWTB', f'{marker} 後面多了空行，應直接接程式碼')
            if marker != '// Given' and lines[n - 2].strip() != '':
                add(n, 'GWTB', f'{marker} 前面缺空行')
        # GWTS：三個標記寫在同一縮排層級，不寫進 send 或 do／catch 的 closure (使用者裁決)
        marker_lines = [(n, t) for n, t in body if t.strip() in markers]
        if marker_lines:
            base = len(marker_lines[0][1]) - len(marker_lines[0][1].lstrip())
            for n, t in marker_lines[1:]:
                if len(t) - len(t.lstrip()) != base:
                    add(n, 'GWTS', f'{t.strip()} 與 // Given 不在同一縮排層級 (寫進了 closure)')

    # NENUM：巢狀 enum 的 `{` 後與 case 之間空一行 (formatting.md「巢狀型別」範例)
    for i, line in enumerate(lines, 1):
        m = re.match(r'^    (?:private |fileprivate )?enum (\w+)[^{]*\{\s*$', line)
        if not m:
            continue
        if i < len(lines) and lines[i].strip() != '':
            add(i, 'NENUM', f'巢狀 enum {m.group(1)} 的 {{ 後缺空行')
        seen_case = False
        for j in range(i, len(lines)):
            if re.match(r'^    \}', lines[j]):
                break
            if re.match(r'^        case ', lines[j]):
                k = j - 1
                while k >= i and lines[k].strip().startswith('///'):
                    k -= 1
                if seen_case and lines[k].strip() != '':
                    add(j + 1, 'NENUM', f'{m.group(1)} 的 case 之間缺空行')
                seen_case = True
    if kind == 'test':
        # PROPPOS：stored property 一律放本體最前面的 Properties 區
        in_body = False
        after_tests = False
        for i, line in enumerate(lines, 1):
            if re.match(r'^(?:@\w+\s+)*(?:final class|struct) \w+', line):
                in_body, after_tests = True, False
            elif in_body and line.startswith('}'):
                in_body = False
            elif in_body and line.strip() == '// MARK: - Tests':
                after_tests = True
            elif in_body and after_tests and re.match(
                    r'^    (?:private |fileprivate )?(?:(?:static|nonisolated) )*(?:let|var) \w+', line):
                add(i, 'PROPPOS', f'stored property 應放 Properties 區：{line.strip()[:50]}')
        # MKC：測試檔只用規範區名
        allowed = {'Properties', 'Init', 'Tests', 'Nested Types', 'Computed Properties',
                   'Internal Method', 'Private Method'}
        for i, line in enumerate(lines, 1):
            m = re.match(r'^\s*// MARK: (-\s*)?(.+?)\s*$', line)
            if not m:
                continue
            name = m.group(2)
            if m.group(1) and (name in allowed or re.fullmatch(r'[A-Z]\w*', name)):
                continue
            add(i, 'MKC', f'MARK 不是規範區名：{line.strip()[:60]}')
    # MKPRIV：private 的 computed property 放 Private Method，不放 Computed Properties (formatting.md)
    for i, line in enumerate(lines, 1):
        if line.strip() != '// MARK: - Computed Properties':
            continue
        j = i
        while j < len(lines) and lines[j].strip() == '':
            j += 1
        if j < len(lines) and re.match(r'^(?:private|fileprivate) extension\b', lines[j]):
            add(i, 'MKPRIV', 'private extension 的 computed property 應放 // MARK: - Private Method')
    if kind == 'test':
        # GWTR／GWTM／GWTE／GWTF：Given／When／Then 的深層結構 (tca-architecture 測試一節、使用者裁決)
        for i, line in enumerate(lines, 1):
            if not re.match(r'^\s*@Test\b', line):
                continue
            j = i - 1
            while j < len(lines) and not re.search(r'\bfunc\s+\w+', lines[j]):
                j += 1
            section = None
            sends_in_when = 0
            for n, t in function_body(lines, j):
                code = t.strip()
                if code.startswith('// Given'):
                    section = 'G'
                    continue
                if code.startswith('// When'):
                    section = 'W'
                    continue
                if code.startswith('// Then'):
                    section = 'T'
                    continue
                if code.startswith('//'):
                    continue
                if section == 'W' and re.search(r'\bstore\.receive\(', code):
                    add(n, 'GWTR', 'receive 寫在 When，應放 Then')
                if section == 'W' and re.search(r'\bstore\.send\(', code):
                    sends_in_when += 1
                    if sends_in_when == 2:
                        add(n, 'GWTM', 'When 有兩個以上的 send，前置動作移到 Given')
                if section in ('G', 'W') and re.search(r'#expect\(', code):
                    add(n, 'GWTE', f'#expect 寫在 {"Given" if section == "G" else "When"}，前置條件用 try #require、斷言放 Then')
                if section == 'W' and re.search(r'\bstore\.finish\(', code):
                    add(n, 'GWTF', 'store.finish() 寫在 When，應放 Then')
        # DOLLAR：TCA 狀態 closure 與 withDependencies 一律 $0
        for i, line in enumerate(lines, 1):
            if re.search(r'(?:withDependencies:?|\bstore\.(?:send|receive)\(.*\))\s*\{\s*\w+\s+in\b', line):
                add(i, 'DOLLAR', f'狀態 closure 取了具名參數，應用 $0：{line.strip()[:60]}')
        # GUARDREC：guard 的 else 只放 return／throw／continue／break
        for i, line in enumerate(lines, 1):
            if re.search(r'\bguard\b.*\belse\s*\{\s*$', line):
                for k in range(i, min(i + 6, len(lines))):
                    stripped = lines[k].strip()
                    if stripped.startswith('}'):
                        break
                    if re.search(r'Issue\.record|#expect\(', stripped):
                        add(k + 1, 'GUARDREC', 'guard 的 else 內有 Issue.record／斷言，改用 try #require')
                        break
        # TAUT：恆真斷言
        for i, line in enumerate(lines, 1):
            if re.search(r'localizedDescription\.isEmpty', strip_code(line)):
                add(i, 'TAUT', '恆真斷言：localizedDescription 不會是空字串，改斷言 domain 與 code')
        # FAILCL：失敗 closure 直接賦值給依賴屬性
        for i, line in enumerate(lines, 1):
            code = strip_code(line)
            if not re.match(r'^\s*\$0[\.\[].*=\s*\{', code) or re.match(r'^\s*\$0\[\w+Client\.self\]', code):
                continue
            depth = code.count('{') - code.count('}')
            for k in range(i, min(i + 30, len(lines))):
                if depth <= 0:
                    break
                inner = strip_code(lines[k])
                if re.search(r'\bthrow\b', inner):
                    add(i, 'FAILCL', '失敗 closure 直接注入，先以 typealias 型別宣告成常數再注入')
                    break
                depth += inner.count('{') - inner.count('}')
    # FUNWRAP：強制解包 (鐵則 3)；排除 != 與前置 !
    for i, line in enumerate(lines, 1):
        code = strip_code(line)
        if re.search(r'@IBOutlet', code):
            continue
        if re.search(r'[\w\)\]\}"]!(?![=])', code) and not re.match(r'^\s*(?:private |fileprivate )?(?:nonisolated )?static let \w+\s*=\s*\w+\((?:string|uuidString|fileURLWithPath): "[^"]*"\)!\s*(?://.*)?$', code):
            add(i, 'FUNWRAP', f'強制解包 (鐵則 3)：{code.strip()[:60]}')
    # PARSP：括號內側不留空格；CLBX：任何區塊的 `}` 前不留空行
    for i, line in enumerate(lines, 1):
        code = strip_code(line)
        if re.search(r'\(\s+\S', code) and not code.rstrip().endswith('('):
            add(i, 'PARSP', f'括號內側多了空格：{code.strip()[:50]}')
        elif re.search(r'\S\s+\)', code):
            add(i, 'PARSP', f'括號內側多了空格：{code.strip()[:50]}')
        if line.strip().startswith('}') and i >= 2 and lines[i - 2].strip() == '' \
                and not (i >= 3 and lines[i - 3].rstrip().endswith('{')):
            add(i, 'CLBX', '閉括號前有空行')
    # CLSIG：closure 簽章跨行
    for i, line in enumerate(lines, 1):
        st = strip_code(line).rstrip()
        if not re.search(r'(?:^|\s)in$', st) or '{' in st or st.strip().startswith('for '):
            continue
        for back in range(1, 4):
            if i - 1 - back < 0:
                break
            prev = strip_code(lines[i - 1 - back]).rstrip()
            if prev.endswith('{'):
                add(i, 'CLSIG', 'closure 簽章跨行，參數列與 in 寫在 { 同一行')
                break
            if prev.endswith('in') or prev.endswith('}') or prev == '':
                break
    # RPAR：`(` 在行尾的斷行呼叫，對應的 `)` 要單獨一行
    rpar_lines = set()
    for i, line in enumerate(lines, 1):
        code = strip_code(line).rstrip()
        if not code.endswith('('):
            continue
        depth = 1
        for k in range(i, min(i + 40, len(lines))):
            inner = strip_code(lines[k])
            closed = False
            for index, char in enumerate(inner):
                if char == '(':
                    depth += 1
                elif char == ')':
                    depth -= 1
                    if depth == 0:
                        if inner[:index].strip() and not re.match(r'^[)\]}]*$', inner[:index].strip()) \
                                and k + 1 not in rpar_lines:
                            rpar_lines.add(k + 1)
                            add(k + 1, 'RPAR', f'斷行呼叫的右括號沒有單獨一行：{inner.strip()[:50]}')
                        closed = True
                        break
            if closed:
                break
    # ARG4：同一行內有四個以上引數的呼叫或宣告
    for i, line in enumerate(lines, 1):
        code = strip_code(line)
        if re.match(r'^\s*(?:(?:indirect|public|private)\s+)?case\b', code) or 'typealias' in code \
                or re.search(r'@Sendable\s*\(', code):
            continue
        stack = []
        for index, char in enumerate(code):
            if char in '([':
                opener = char == '(' and index > 0 and re.match(r'[\w>?!]', code[index - 1]) is not None
                stack.append([opener, 0, char])
            elif char in ')]' and stack:
                opener, commas, _ = stack.pop()
                if opener and commas >= 3:
                    add(i, 'ARG4', f'一行內有 {commas + 1} 個引數或參數，超過三個要斷行：{code.strip()[:50]}')
                    break
            elif char == ',' and stack:
                stack[-1][1] += 1
    # GUARDX：guard 的 else 只放一個 return／throw／continue／break
    for i, line in enumerate(lines, 1):
        if not re.search(r'\bguard\b.*\belse\s*\{\s*$', strip_code(line)):
            continue
        body = []
        for k in range(i, min(i + 12, len(lines))):
            stripped = strip_code(lines[k]).strip()
            if stripped.startswith('}'):
                break
            if stripped:
                body.append(stripped)
        if body and (not re.match(r'^(?:return|throw|continue|break|preconditionFailure|fatalError)\b', body[0])
                     or len([b for b in body if re.match(r'^(?:return|throw|continue|break|preconditionFailure|fatalError)\b', b)]) != 1):
            add(i, 'GUARDX', 'guard 的 else 內有 return／throw／continue／break 以外的敘述')
    # TRYQ：try? 同一行要有註解說明失敗可忽略
    for i, line in enumerate(lines, 1):
        if 'try?' in strip_code(line) and '//' not in re.sub(r'"(?:[^"\\]|\\.)*"', '""', line):
            add(i, 'TRYQ', 'try? 沒有同一行註解說明失敗可忽略的理由')
    # DOCDUP：doc 摘要一字不差重複三次以上
    summaries = {}
    for i, line in enumerate(lines, 1):
        if line.strip().startswith('///') and not (i >= 2 and lines[i - 2].strip().startswith('///')):
            text = line.strip()[3:].strip()
            if len(text) >= 8:
                summaries.setdefault(text, []).append(i)
    for text, where in summaries.items():
        if len(where) >= 3:
            for n in where:
                add(n, 'DOCDUP', f'doc 摘要重複 {len(where)} 次：{text[:40]}')
    # MKIN：MARK 寫在 extension 大括號內 (應寫在 extension 上方)
    for i, line in enumerate(lines, 1):
        if re.match(r'^(?:private\s+|fileprivate\s+)?extension\b.*\{\s*$', line):
            j = i
            while j < len(lines) and lines[j].strip() == '':
                j += 1
            if j < len(lines) and lines[j].strip().startswith('// MARK:'):
                add(j + 1, 'MKIN', f'MARK 寫在 extension 大括號內：{lines[j].strip()}')
    # CLP：closure 的參數列獨佔一行 (應與 { 同行)
    for i, line in enumerate(lines, 1):
        st = strip_code(line).strip()
        if re.match(r'^(?:\[[^\]]*\]\s*)?\(?[\w\s:,_()]*\)?\s*(?:async\s+)?(?:throws(?:\([^)]*\))?\s+)?in$', st) \
                and st not in ('in',) and not st.startswith('for '):
            prev = strip_code(lines[i - 2]).rstrip() if i >= 2 else ''
            if prev.endswith('{') or prev.endswith('in'):
                add(i, 'CLP', f'closure 參數列獨佔一行：{st[:60]}')
    # TOP：一個檔只放一個頂層型別 (extension 不算)
    tops = [i for i, line in enumerate(lines, 1)
            if re.match(r'^(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:private|fileprivate|public|final|nonisolated)\s+)*'
                        r'(?:struct|enum|class|actor|protocol)\s+\w+', line)]
    if len(tops) > 1:
        for n in tops[1:]:
            add(n, 'TOP', f'第二個頂層型別：{lines[n - 1].strip()[:60]}')
    # PRIV：private extension 內不再逐一加 private
    in_private_ext = False
    for i, line in enumerate(lines, 1):
        if re.match(r'^private extension\b', line):
            in_private_ext = True
        elif re.match(r'^(?:extension|struct|enum|class|actor|final|@)', line) or line == '}':
            in_private_ext = False if line != '}' else in_private_ext and False
        elif in_private_ext and re.match(r'^    private\s', line):
            add(i, 'PRIV', f'private extension 內多餘的 private：{line.strip()[:60]}')
    # CLA：closure 簽章只補 throws(E)，不標參數型別、async、回傳型別
    for i, line in enumerate(lines, 1):
        st = strip_code(line).rstrip()
        if not st.endswith(' in'):
            continue
        prev = strip_code(lines[i - 2]).rstrip() if i >= 2 else ''
        if '{' in st:
            sig = st[st.rfind('{') + 1:]
        elif prev.endswith('{') or prev.endswith('('):
            sig = st
        else:
            continue
        if re.search(r'\(\s*(?:\w+|_)\s*:\s*\S', sig) or re.search(r'\basync\b', sig) \
                or '->' in sig:
            add(i, 'CLA', f'closure 簽章多標了參數型別、async 或回傳型別：{sig.strip()[:60]}')
    # EQLEAD：賦值 = 不移到續行行首；TYPEDCL：型別化常數的 closure 不再標 throws(E)
    for i, line in enumerate(lines, 1):
        code = strip_code(line)
        if re.match(r'^\s*=\s', code):
            add(i, 'EQLEAD', '賦值 = 移到了續行行首，改在右側的括號內斷行')
        if re.match(r'^\s*(?:private\s+)?(?:static\s+)?let\s+\w+\s*:\s*[\w.]+\s*=\s*\{.*\bthrows\(', code):
            # 只有直接寫在函式本體時推斷得出 typed throws；在 closure 本體內 (例如 withIsolatedStorage) 必須標註
            depth = 0
            owner = ''
            for k in range(i - 2, -1, -1):
                prev = strip_code(lines[k])
                depth += prev.count('}') - prev.count('{')
                if depth < 0:
                    # do／if／for 等控制區塊不影響推斷，繼續往外找
                    if re.match(r'^\s*(?:\}\s*)?(?:do|if|else|for|while|switch|guard|catch|defer)\b', prev):
                        depth = 0
                        continue
                    owner = prev
                    break
            if re.search(r'\b(?:func|init)\b', owner):
                add(i, 'TYPEDCL', '型別已由 typealias 宣告，closure 不用再標 throws(E)')
    # DOLLAR2：兩個以上參數的 closure 不用 $0／$1 簡寫
    for i, line in enumerate(lines, 1):
        if re.search(r'\$[1-9]\b', strip_code(line)):
            add(i, 'DOLLAR2', '兩個以上參數的 closure 要具名，不用 $1 簡寫')
    # DOLLARML／DOLLARN：多行 closure 與巢狀 closure 的 $0
    for i, line in enumerate(lines, 1):
        code = strip_code(line).rstrip()
        if not code.endswith('{') or re.search(r'\bin\s*\{?$', code):
            continue
        start = i
        balance = code.count(')') - code.count('(')
        while balance > 0 and start > 1:
            start -= 1
            prev = strip_code(lines[start - 1])
            balance += prev.count(')') - prev.count('(')
        head = strip_code(lines[start - 1])
        if start != i and re.search(r'withDependencies|withLock|withValue|store\.(?:send|receive)\(|TestStore\(|\bmake\w*\(|\b(?:func|init|subscript)\b', head):
            continue
        if re.match(r'^\s*(?:get|set|willSet|didSet|_modify|_read)\s*\{$', code):
            continue
        if re.search(r'withDependencies|prepareDependencies|withLock|withValue|store\.(?:send|receive)\(|\bmake\w*\(.*\)\s*\{$|\bmake\w*\s*\{$|^\s*(?:\}\s*)?(?:else|if|guard|for|while|switch|do|catch|defer)\b|\b(?:func|var|init|struct|enum|class|extension)\b|TestStore\(|operation:', code):
            continue
        if re.search(r'=\s*\{$|\w\s*\{$|\)\s*\{$', code):
            depth = 1
            statements = 0
            nesting = 0
            uses_dollar = False
            for k in range(i, min(i + 40, len(lines))):
                inner = strip_code(lines[k])
                flat = inner
                while re.search(r'\{[^{}]*\}', flat):
                    flat = re.sub(r'\{[^{}]*\}', '', flat)
                closing = depth == 1 and flat.strip().startswith('}')
                # 本 closure 在此結束；同一行的 `} label: {` 開的是另一個 closure，不併入計算
                if closing:
                    break
                stripped = inner.strip()
                if not closing and stripped:
                    if depth == 1 and nesting == 0 and not re.match(r'^[.)\]+\-*/?:&|]', stripped):
                        statements += 1
                    if depth == 1 and '$0' in flat:
                        uses_dollar = True
                if depth == 1:
                    nesting += flat.count('(') + flat.count('[') - flat.count(')') - flat.count(']')
                depth += inner.count('{') - inner.count('}')
                if depth <= 0:
                    break
            if uses_dollar and statements > 1:
                add(i, 'DOLLARML', f'多敘述的 closure 用了 $0，改成具名參數：{code.strip()[:50]}')
    # TRAILC／HUG：多行字面值的尾隨逗號與唯一字面值引數的貼合 (ios-dev-kit 3.8.0 formatting.md:37、:97)
    bracket_stack = []
    in_multiline_string = False
    for i, line in enumerate(lines, 1):
        if line.count('"""') % 2 == 1:
            in_multiline_string = not in_multiline_string
            continue
        if in_multiline_string:
            continue
        code = strip_code(line).rstrip()
        stripped = code.strip()
        if re.search(r',\s*\]', code):
            add(i, 'TRAILC', f'單行字面值不加尾隨逗號：{stripped[:50]}')
        if stripped.startswith(']') and bracket_stack:
            opener, is_literal, is_standalone = bracket_stack.pop()
            if is_literal:
                last = i - 1
                while last > opener and not strip_code(lines[last - 1]).strip():
                    last -= 1
                last_code = strip_code(lines[last - 1]).rstrip()
                if last > opener and not last_code.endswith(',') and not last_code.endswith('['):
                    add(last, 'TRAILC', f'多行字面值的最後一個元素後面要加逗號：{last_code.strip()[:50]}')
                following = next((strip_code(lines[k]).strip() for k in range(i, len(lines))
                                  if strip_code(lines[k]).strip()), '')
                if is_standalone and stripped == ']' and following.startswith(')'):
                    add(opener, 'HUG', '唯一引數是字面值，改成 `([` 與 `])` 貼合')
        if code.endswith('['):
            before = code[:-1].rstrip()
            is_standalone = not before
            is_literal = is_standalone or bool(re.search(r'(?:[=(:,]|\breturn)$', before))
            if is_standalone:
                previous = strip_code(lines[i - 2]).rstrip() if i > 1 else ''
                is_standalone = previous.endswith('(')
            if is_literal and not is_standalone:
                depth = 0
                has_top_level_comma = False
                for char in reversed(before):
                    if char in ')]':
                        depth += 1
                    elif char in '([':
                        if depth == 0:
                            if char == '(' and has_top_level_comma:
                                add(i, 'HUG', f'兩個以上引數時不用 `[` 貼合寫法：{stripped[:50]}')
                            break
                        depth -= 1
                    elif char == ',' and depth == 0:
                        has_top_level_comma = True
            bracket_stack.append((i, is_literal, is_standalone))
    # NOTHROW：closure 標了 throws(E) 但本體不會 throw
    for i, line in enumerate(lines, 1):
        code = strip_code(line)
        m = re.search(r'\{\s*(?:\[[^\]]*\]\s*)?(?:\(?[\w\s,_:]*\)?)\s*throws\([^)]*\)\s*in\b', code)
        if not m:
            continue
        # 只抓賦值的 closure；傳給泛型 API 的尾隨 closure (如 database.write) 靠標註推斷 Failure，不能拿掉
        if not re.search(r'=\s*$', code[:m.start()]):
            continue
        rest = code[m.end():]
        depth = 1 + rest.count('{') - rest.count('}')
        body = rest
        k = i
        while depth > 0 and k < min(i + 60, len(lines)):
            inner = strip_code(lines[k])
            body += '\n' + inner
            depth += inner.count('{') - inner.count('}')
            k += 1
        if not re.search(r'\bthrow\b|\btry\b', body):
            add(i, 'NOTHROW', 'closure 本體不會 throw，拿掉 throws(E)')
    # COLONEOL：型別標註的 : 之後斷行
    for i, line in enumerate(lines, 1):
        if re.match(r'^\s*(?:(?:private|fileprivate|static|nonisolated)\s+)*(?:let|var)\s+\w+\s*:\s*$', strip_code(line)):
            add(i, 'COLONEOL', '在型別標註的 : 之後斷行，接回同一行')
    # THENBL：Then 段內 receive 之後的空行
    if kind == 'test':
        then_line = None
        for i, line in enumerate(lines, 1):
            st = line.strip()
            if st == '// Then':
                then_line = i
                continue
            if re.match(r'^\s*(?:@Test|func |///)', line) and not st.startswith('// Then'):
                then_line = None if st.startswith(('@Test', 'func ')) else then_line
            if then_line is None or st != '' or i >= len(lines):
                continue
            prev = lines[i - 2].strip() if i >= 2 else ''
            nxt = lines[i].strip()
            prev_is_receive = prev.startswith('await store.receive') or (prev == '}' and any(
                lines[k].strip().startswith('await store.receive') for k in range(max(then_line, i - 12), i - 1)))
            if prev_is_receive and re.match(r'^(?:await store\.(?:receive|finish)|#expect|try #require|let \w+ = try #require)', nxt):
                add(i, 'THENBL', 'Then 段內 receive 之後多了空行')
            elif prev.startswith('await store.finish()') and re.match(r'^(?:#expect|try #require|let \w+ = try #require)', nxt):
                add(i, 'THENBL', 'Then 段內 finish() 之後多了空行')
    # WHOLESTATE：send／receive 的狀態 closure 不整個替換 State
    if kind == 'test':
        for i, line in enumerate(lines, 1):
            code = strip_code(line)
            if re.search(r'store\.(?:send|receive)\(.*\{\s*\$0\s*=\s*[\w.]+\s*\}', code):
                add(i, 'WHOLESTATE', '狀態 closure 整個替換 State，改成直接寫出改變的欄位')
            elif re.match(r'^\s*\$0\s*=\s*[\w.]+\s*$', code) and i >= 2 \
                    and re.search(r'store\.(?:send|receive)\(.*\{\s*$', strip_code(lines[i - 2])):
                add(i, 'WHOLESTATE', '狀態 closure 整個替換 State，改成直接寫出改變的欄位')
    # MBL：方法之間空一行
    for i, line in enumerate(lines, 1):
        if i >= len(lines):
            break
        if re.match(r'^    \}\s*$', line) and re.match(r'^    (?:///|@\w|func\b|static\b|private\b|var\b|let\b|init\b)', lines[i]):
            add(i + 1, 'MBL', '方法之間缺空行')
    # NAMED1：單一表達式、單一參數的 closure 用 $0
    for i, line in enumerate(lines, 1):
        code = strip_code(line)
        for m in re.finditer(r'\{\s*([a-zA-Z]\w*)\s+in\b', code):
            name = m.group(1)
            rest = code[m.end():]
            body = rest
            depth = 1 + rest.count('{') - rest.count('}')
            k = i
            while depth > 0 and k < min(i + 30, len(lines)):
                inner = strip_code(lines[k])
                body += '\n' + inner
                depth += inner.count('{') - inner.count('}')
                k += 1
            body = body.rsplit('}', 1)[0] if depth <= 0 else body
            if '$0' in body:
                continue
            if re.search(r'\b(?:withLock|withValue)\s*$', code[:m.start()].rstrip()):
                add(i, 'NAMED1', f'修改 inout 值的 closure 一律用 $0，不用具名的 {name}')
                continue
            if re.search(r'\b(?:let|var|return|if|guard|for|switch|try|throw|do)\b', body):
                continue
            stmts = [b for b in re.split(r'\n|;', body) if b.strip()]
            nest = 0
            count = 0
            for b in stmts:
                st = b.strip()
                if nest == 0 and not re.match(r'^[.)\]+\-*/?:&|]', st):
                    count += 1
                nest += st.count('(') + st.count('[') - st.count(')') - st.count(']')
            if count == 1:
                add(i, 'NAMED1', f'單一表達式的 closure 用 $0，不用具名的 {name}')
    # TANAME：Service 的 closure 屬性型別是同檔宣告的函式型別 typealias 時，名稱須為屬性名首字大寫 (tca-architecture.md:388)
    function_aliases = set(re.findall(r'^\s*typealias\s+(\w+)\s*=\s*@Sendable\b', '\n'.join(lines), re.M))
    for i, line in enumerate(lines, 1):
        m = re.match(r'^\s{4}var\s+(\w+)\s*:\s*(\w+)\s*$', strip_code(line))
        if m and m.group(2) in function_aliases:
            expected = m.group(1)[0].upper() + m.group(1)[1:]
            # 縮寫開頭依 Swift 命名慣例整組大寫 (apiKey → APIKey)，所以不分大小寫比對
            if m.group(2).lower() != expected.lower():
                add(i, 'TANAME', f'typealias 應命名為 {expected}：var {m.group(1)}: {m.group(2)}')
    # NESTSL／SWIFTUISL：巢狀 closure 與 SwiftUI closure 一律多行 (3.6.0)
    kinds = []
    is_view_file = bool(re.search(r':\s*(?:some\s+)?View\b|\bstruct\s+\w+\s*:\s*[\w, ]*\bView\b', text))
    swiftui_opener = re.compile(
        r'(?:\.(?:task|onAppear|onDisappear|onChange|refreshable|onSubmit|onTapGesture|sheet|alert|confirmationDialog|'
        r'toolbar|overlay|background|contextMenu|swipeActions|onReceive|navigationDestination|fullScreenCover|popover|'
        r'safeAreaInset|searchable|onDelete|onMove|mask|simultaneousGesture|gesture)\b[^{]*|'
        r'\b(?:Button|VStack|HStack|ZStack|LazyVStack|LazyHStack|LazyVGrid|List|Form|Section|NavigationStack|'
        r'NavigationSplitView|ScrollView|Group|GeometryReader|ForEach|Menu|ToolbarItem|ToolbarItemGroup|TabView|'
        r'Picker|DisclosureGroup|ViewThatFits|ScrollViewReader)\b[^{]*)$')
    # 簽章跨多行的 func／init：`{` 在 `) -> X {` 那行，前綴沒有 func，要靠前面記下的宣告判斷
    pending_decl = False
    pending_control = False
    for i, line in enumerate(lines, 1):
        code = strip_code(line)
        if not pending_decl and re.search(r'\b(?:func|init|subscript)\b', code) \
                and code.count('(') > code.count(')'):
            pending_decl = True
        # 條件跨多行的 if／guard／while／for／switch：`{` 在續行，前綴沒有關鍵字，要靠記下的狀態判斷
        if not pending_control and re.match(r'^\s*(?:\}\s*else\s+)?(?:if|guard|while|for|switch)\b', code) \
                and '{' not in code:
            pending_control = True
        idx = 0
        while idx < len(code):
            ch = code[idx]
            if ch == '{' and pending_decl and re.match(r'^\s*\)', code[:idx]):
                pending_decl = False
                kinds.append('func')
                idx += 1
                continue
            if ch == '{' and pending_control and not code[:idx].rstrip().endswith(('(', ',', '[')) \
                    and code[idx + 1:].strip() == '':
                pending_control = False
                kinds.append('control')
                idx += 1
                continue
            if ch == '{':
                before = code[:idx]
                close = None
                depth = 0
                for j in range(idx, len(code)):
                    if code[j] == '{':
                        depth += 1
                    elif code[j] == '}':
                        depth -= 1
                        if depth == 0:
                            close = j
                            break
                if re.search(r'\b(?:func|init|deinit|subscript)\b[^{]*$', before) or \
                        re.search(r'^\s*(?:(?:private|fileprivate|public|static|override|nonisolated|lazy)\s+)*var\s+\w+\s*:[^=]*$', before) or \
                        re.search(r'\b(?:get|set|willSet|didSet|_read|_modify)\s*$', before):
                    kind = 'func'
                elif re.search(r'\b(?:struct|class|enum|extension|protocol|actor)\b[^{]*$', before):
                    kind = 'type'
                elif re.search(r'(?:^|[\s}])(?:if|else|for|while|switch|guard|do|catch|defer|repeat)\b[^{]*$', before) \
                        and not re.search(r'\b(?:if|guard)\b.*=\s*[\w.]+\s*$', before[-3:] if False else ''):
                    kind = 'control'
                else:
                    kind = 'closure'
                enclosing = next((k for k in reversed(kinds) if k != 'control'), 'type')
                if kind == 'closure' and close is not None:
                    if enclosing == 'closure':
                        add(i, 'NESTSL', f'寫在另一個 closure 內的 closure 要寫成多行：{code.strip()[:60]}')
                    elif is_view_file and swiftui_opener.search(before.rstrip()):
                        add(i, 'SWIFTUISL', f'SwiftUI closure 要寫成多行：{code.strip()[:60]}')
                    idx = close + 1
                    continue
                kinds.append(kind)
            elif ch == '}' and kinds:
                kinds.pop()
            idx += 1
    # ATTR：@Test 在前、@MainActor 在後
    for i, line in enumerate(lines, 1):
        if line.strip() == '@MainActor' and i < len(lines) and lines[i].strip().startswith('@Test'):
            add(i, 'ATTR', '`@MainActor` 寫在 `@Test` 之前，樣板是 `@Test`、`@MainActor`、`func` 各一行')
    # OPEOL：運算子 (含賦值) 不放行尾
    for i, line in enumerate(lines, 1):
        code = strip_code(line).rstrip()
        if not code or code.lstrip().startswith(('///', '//')):
            continue
        if re.search(r'(?:^|[^-])(?:[=!<>]=|[-+*/%]?=|&&|\|\||\?\?|\s[-+*/%]|\s\?)$', code) and not code.endswith('->'):
            nxt = lines[i].strip() if i < len(lines) else ''
            if nxt.startswith('{'):
                continue
            add(i, 'OPEOL', f'運算子放在行尾就斷行：{code.strip()[-40:]}')
    # EQBR：closure 不可在 = 之後斷行、把 { 移到續行
    for i, line in enumerate(lines, 1):
        if strip_code(line).rstrip().endswith('=') and i < len(lines) \
                and lines[i].strip().startswith('{'):
            add(i, 'EQBR', '在 = 之後斷行，closure 的 { 移到了續行')
    # GRD：if／guard／while 多條件排版 (formatting.md「if / guard 多條件」)
    for i, line in enumerate(lines, 1):
        code = strip_code(line)
        if re.match(r'^\s*(guard|if|while)\s*$', code):
            add(i, 'GRD', '第一個條件要與關鍵字同行')
        if re.match(r'^\s*else\s*\{\s*$', code):
            add(i, 'GRD', '`else {` 要接在最後一個條件同行，不單獨成行')
        m = re.match(r'^(\s*)(guard|if|while) .*,\s*$', code)
        if m:
            want = len(m.group(1)) + len(m.group(2)) + 1
            k = i
            while k < len(lines):
                nxt = lines[k]
                got = len(nxt) - len(nxt.lstrip())
                if nxt.strip() and got != want:
                    add(k + 1, 'GRD', f'條件續行要對齊第一個條件：應縮排 {want} 格，目前 {got} 格')
                if strip_code(nxt).rstrip().endswith(('{', 'else {')) or not nxt.strip().endswith(','):
                    break
                k += 1
    # TSTL：@Test 屬性要單獨一行，func 另起一行 (tests/Tests.swift、tca/FeatureTests.swift 樣板)
    for i, line in enumerate(lines, 1):
        if re.match(r'^\s*@Test(\([^)]*\))?\s+func\b', line):
            add(i, 'TSTL', '`@Test` 與 `func` 寫在同一行，樣板是 `@Test` 單獨一行')
    # CASELET：帶關聯值的 case pattern 用 `case .x(let v)` (file-templates.md，使用者 2026-09-26 裁決)
    for i, line in enumerate(lines, 1):
        if re.search(r'\bcase let \.', strip_code(line)):
            add(i, 'CASELET', '改寫成 `case .x(let v)`，不用 `case let .x(v)`')
    # TIMP：@testable import 前要空一行
    for i, line in enumerate(lines, 1):
        if line.strip().startswith('@testable import') and i >= 2 and lines[i - 2].strip() != '':
            add(i, 'TIMP', '@testable import 前缺空行')
    # CLB：型別或 extension 的閉括號前不空行
    for i, line in enumerate(lines, 1):
        if line == '}' and i >= 2 and lines[i - 2].strip() == '':
            # 樣板形式的空本體 (`enum X {` 空行 `}`) 不算
            if i >= 3 and lines[i - 3].rstrip().endswith('{') and not lines[i - 3].startswith(' '):
                continue
            add(i, 'CLB', '型別或 extension 的閉括號前有空行')
    # GWTN：一個測試只允許一組 When／Then
    for i, line in enumerate(lines, 1):
        if not (re.match(r'^\s*@Test\b', line) or (is_ui_test and re.match(r'^\s*func test\w*\(', line))):
            continue
        body = function_body(lines, i - 1)
        whens = sum(1 for _, t in body if t.strip().startswith('// When'))
        thens = sum(1 for _, t in body if t.strip().startswith('// Then'))
        if whens > 1 or thens > 1:
            add(i, 'GWTN', f'測試有 {whens} 組 When、{thens} 組 Then')
        seen_then = False
        for n, t in body:
            ts = t.strip()
            if ts.startswith('// Then'):
                seen_then = True
            elif seen_then and re.match(r'^(?:await\s+)?store\.send\(', ts):
                add(n, 'GWTN', 'Then 之後又送出 action (應放 When)')
                break

    # CASECONT：switch 多 pattern case 清單斷行時，續行比 case 多 8 格且每行排滿 100 (formatting.md 3.7.0:41)
    def first_item(text):
        depth = 0
        for k, ch in enumerate(text):
            if ch in '([':
                depth += 1
            elif ch in ')]':
                depth -= 1
            elif ch in ',:' and depth == 0:
                return text[:k + 1]
        return text
    i = 0
    while i < len(lines):
        st = strip_code(lines[i]).rstrip()
        if re.match(r'^\s*case\s+(?:\.|let\b|\w+\s*:)', st) and st.endswith(','):
            base = len(lines[i]) - len(lines[i].lstrip())
            block = [i]
            j = i + 1
            while j < len(lines):
                block.append(j)
                if strip_code(lines[j]).rstrip().endswith(':'):
                    break
                j += 1
            for a, b in zip(block, block[1:]):
                cont = lines[b]
                ind = len(cont) - len(cont.lstrip())
                if ind != base + 8:
                    add(b + 1, 'CASECONT', f'多 pattern case 的續行縮排 {ind - base} 格，應比 case 多 8 格')
                nxt = first_item(cont.strip())
                if len(lines[a].rstrip()) + 1 + len(nxt) <= 100:
                    add(a + 1, 'CASECONT', f'多 pattern case 未排滿 100 就斷行 (下一項 `{nxt[:30]}` 仍放得下)')
            i = j + 1
            continue
        i += 1

    # SWC：switch 的 case 之間空一行，第一個 case 緊接 switch；B 組只要 switch 內有改動行就查整個 switch
    stack = []
    for i, line in enumerate(lines, 1):
        code = strip_code(line)
        st = code.strip()
        ind = len(line) - len(line.lstrip())
        if stack and ind == stack[-1]['indent'] \
                and re.match(r'(case\b|default\b|@unknown\s+default\b)', st):
            stack[-1]['cases'].append(i)
        if re.match(r'(?:.*[=(]\s*)?switch\b.*\{$', st) or re.match(r'^(?:return\s+)?switch\b.*\{$', st):
            stack.append({'indent': ind, 'start': i, 'cases': []})
        elif stack and st.startswith('}') and ind == stack[-1]['indent']:
            block = stack.pop()
            touched = whole or any(n in scope for n in range(block['start'], i + 1))
            if not touched:
                continue
            for k, n in enumerate(block['cases']):
                prev = n - 2
                while prev >= 0 and lines[prev].strip().startswith('//'):
                    prev -= 1
                above = lines[prev].strip() if prev >= 0 else ''
                if k == 0:
                    if above != strip_code(lines[block['start'] - 1]).strip() and above == '':
                        issues.append((n, 'SWC', '第一個 case 前不空行'))
                elif above != '':
                    issues.append((n, 'SWC', f'switch case 之間缺空行：{lines[n - 1].strip()[:50]}'))
            last_body = i - 2
            if last_body >= 0 and lines[last_body].strip() == '':
                issues.append((i, 'SWC', 'switch 結尾 } 前不空行'))
    return issues


def main():
    files = sys.argv[1:] or git_files()
    total = Counter()
    for f in files:
        found = check(f)
        group = 'B' if f in B_GROUP else 'A'
        if found:
            print(f'== [{group}] {f} ({len(found)})')
            for n, code, msg in sorted(found):
                if code == 'LEN' and f in EXISTING_OVER_LIMIT:
                    code = 'LENX'
                print(f'   L{n} {code} {msg}')
                total[code] += 1
    failing = {k: v for k, v in total.items() if k not in ('WSTR', 'WCL', 'LENX', 'WSIG')}
    print('TOTAL', dict(total), 'files', len(files), 'FAIL' if failing else 'PASS')


if __name__ == '__main__':
    main()
