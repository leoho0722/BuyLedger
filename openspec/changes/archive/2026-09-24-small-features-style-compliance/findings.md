# 第 3 步範圍逐檔待修明細

來源：2026-09-14 全庫審查報告 (ios-dev-kit 1.1.0) 的資料集，取 `Features/` 下 FX、Quote、Settings、AISummary、Customers、More 六個區域的 17 個 production 檔，加上跟著改的 6 個單元測試檔，排除 commit `291d841` 已修的尾隨空白 (FM2)。

總計 **491 筆**，涵蓋 23 個檔案：必擋 184、違規 274、建議 25、已登記例外 8。其中 production 17 檔 281 筆、單元測試 6 檔 210 筆。

行號為 2026-09-14 當時的位置。第 1、2 步已改過其中數檔 (`SettingsView`、`QuoteView`、`FxView`、`CustomersView` 的幣別顯示與頭像尺寸)，實作時以檔案內容為準、不依賴行號定位。檔名以報告當時為準：`SettingsStorage.swift` 本步改名為 `SettingsStore.swift`，`OllamaClient.swift`／`OllamaDTO.swift` 本步搬到 `Core/Networking/`。

每筆在實作完成後補上結論：`已修正` / `由任務 X.Y 涵蓋` / `報告誤報 (理由)` / `登記例外 (理由)` / `依 design 不修 (理由)`。`待填` 代表尚未處理，驗收時不得殘留。

**已預先填好結論的項目** (依 design 與使用者 2026-09-21 裁決，實作時照做、不要改掉)：

- 23 筆 `H1` (production 17、測試 6)：報告用的是 `YYYY/MM/DD`，但 `apps/ios/CLAUDE.md` 已改為不補零，現況日期格式正確。
- 6 筆 `S·測試命名…`：使用者裁決維持單段 lowerCamel，不改名。
- 8 筆已登記例外：`TC5` (`some Reducer<State, Action>`)、`TC4` (struct-of-closures Client 宣告 `testValue`)、`TS2` (`exhaustivity = .off`)。
- 4 筆第 2 步已修正的項目 (幣別顯示 3 筆、客戶頭像尺寸 1 筆)，實作時確認後標記。
- 其餘預填項目的理由見 design 的「判讀級 findings 的逐筆處置」表。

## 規則代碼出現次數

| 代碼 | 規則 | 嚴重度 | 筆數 |
| --- | --- | --- | --- |
| `D1` | 宣告缺 /// doc comment | 必擋 | 64 |
| `MK1` | MARK 使用規範以外的分區名稱 | 必擋 | 60 |
| `TS3` | @Test 本體缺 Given / When / Then | 違規 | 60 |
| `FM9` | switch 的 case 之間有空行 | 違規 | 28 |
| `H1` | 檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) | 違規 | 23 |
| `MK5` | 型別本體內出現方法或 computed property (應放 extension) | 必擋 | 21 |
| `D9` | enum case 的 associated value 缺 - Parameter | 必擋 | 21 |
| `D6` | 註解結尾加中文句號 | 違規 | 14 |
| `TC1` | @Dependency 與 var 寫在同一行 | 違規 | 11 |
| `FM14` | 多行參數的右括號沒有單獨一行 | 違規 | 9 |
| `S·modifier 四組順序` | modifier 四組順序 | 違規 | 7 |
| `IM2` | @testable import 前缺空行 | 違規 | 6 |
| `CL1` | 兩個以上參數的 closure 用 $1 | 違規 | 5 |
| `TC5` | Reducer body 型別不是 some ReducerOf<Self> | 已登記例外 | 5 |
| `TC3` | body 內直接寫 Reduce 閉包而非 Reduce(core) | 違規 | 5 |
| `FM15` | 超過三個參數卻放在同一行 | 違規 | 5 |
| `S·測試命名未依「行為_情境_預期」` | 測試命名未依「行為_情境_預期」 | 違規 | 5 |
| `FM1` | 行寬超過 100 | 必擋 | 4 |
| `SU5` | modifier 與 View 同行 | 違規 | 4 |
| `MK4` | extension 專屬分區寫在型別本體內 | 必擋 | 4 |
| `CL2` | 多行 closure 使用 $0 | 違規 | 3 |
| `FM4` | 單檔超過 300 行 (不含檔頭與空行) | 違規 | 3 |
| `S·doc comment 複述名稱` | doc comment 複述名稱 | 違規 | 3 |
| `S·Action 缺 view 分組` | Action 缺 view 分組 | 違規 | 3 |
| `S·case 超過十行未抽方法` | case 超過十行未抽方法 | 違規 | 3 |
| `S·catch 分散` | catch 分散 | 違規 | 3 |
| `S·body 內嵌 toolbar 內容` | body 內嵌 toolbar 內容 | 違規 | 3 |
| `S·多狀態缺 Preview` | 多狀態缺 Preview | 違規 | 3 |
| `S·同一邏輯多組輸入未參數化` | 同一邏輯多組輸入未參數化 | 違規 | 3 |
| `TC4` | 宣告 testValue | 已登記例外 | 2 |
| `FM16` | // MARK: 前後缺空行 | 違規 | 2 |
| `S·Action 分 view／delegate` | Action 分 view／delegate | 違規 | 2 |
| `S·View Properties 順序` | View Properties 順序 | 違規 | 2 |
| `S·body 不宣告區域變數` | body 不宣告區域變數 | 違規 | 2 |
| `S·View 只送 view action` | View 只送 view action | 違規 | 2 |
| `S·View 不寫格式化方法` | View 不寫格式化方法 | 必擋 | 2 |
| `S·modifier 一行一個` | modifier 一行一個 | 違規 | 2 |
| `S·doc comment 不準確` | doc comment 不準確 | 違規 | 2 |
| `S·避免重複定義` | 避免重複定義 | 建議 | 2 |
| `S·nonisolated 使用時機` | nonisolated 使用時機 | 違規 | 2 |
| `S·縮寫大小寫` | 縮寫大小寫 | 違規 | 2 |
| `S·sheet 未走 Destination` | sheet 未走 Destination | 違規 | 2 |
| `S·Result 拆成兩個 case` | Result 拆成兩個 case | 違規 | 2 |
| `S·body 內宣告區域變數` | body 內宣告區域變數 | 違規 | 2 |
| `S·View 內格式化方法` | View 內格式化方法 | 必擋 | 2 |
| `S·View 內含業務規則的格式化` | View 內含業務規則的格式化 | 必擋 | 2 |
| `S·巢狀型別放在本體` | 巢狀型別放在本體 | 違規 | 2 |
| `S·doc comment 放在屬性之後` | doc comment 放在屬性之後 | 建議 | 2 |
| `S·同檔輔助型別應為 nested type` | 同檔輔助型別應為 nested type | 違規 | 2 |
| `S·窮舉 receive 後的冗餘斷言` | 窮舉 receive 後的冗餘斷言 | 建議 | 2 |
| `S·一個測試檔測多個型別` | 一個測試檔測多個型別 | 違規 | 2 |
| `FM0` | 縮排不是 4 格 (開括號後一層) | 必擋 | 1 |
| `FN1` | 檔名與主要型別名稱不一致 | 違規 | 1 |
| `FM10` | 型別成員 (含 enum case) 之間缺空行 | 違規 | 1 |
| `O3` | 強制解包 ! 左側含變數 | 必擋 | 1 |
| `TS2` | TestStore 關閉 exhaustivity | 已登記例外 | 1 |
| `C4` | @unchecked Sendable (Mock 與包裝非 Sendable 第三方物件以外) | 必擋 | 1 |
| `S·模型型別獨立成檔` | 模型型別獨立成檔 | 違規 | 1 |
| `S·最後一個 closure 用 trailing` | 最後一個 closure 用 trailing | 違規 | 1 |
| `S·closure 不明確標註型別` | closure 不明確標註型別 | 違規 | 1 |
| `S·State 衍生值成本` | State 衍生值成本 | 建議 | 1 |
| `S·delegate 以結果命名` | delegate 以結果命名 | 違規 | 1 |
| `S·尺寸單一來源` | 尺寸單一來源 | 建議 | 1 |
| `S·#Preview 涵蓋各狀態` | #Preview 涵蓋各狀態 | 建議 | 1 |
| `S·錯誤狀態可操作` | 錯誤狀態可操作 | 建議 | 1 |
| `S·重複 View 抽 func` | 重複 View 抽 func | 建議 | 1 |
| `S·擴充放在所屬型別` | 擴充放在所屬型別 | 建議 | 1 |
| `S·Bool 命名` | Bool 命名 | 違規 | 1 |
| `S·Feature 間不互相引用` | Feature 間不互相引用 | 違規 | 1 |
| `S·Reduce 內不直接呼叫依賴` | Reduce 內不直接呼叫依賴 | 違規 | 1 |
| `S·父層只處理 delegate` | 父層只處理 delegate | 違規 | 1 |
| `S·Bool 與縮寫命名` | Bool 與縮寫命名 | 違規 | 1 |
| `S·型別後綴只用已定義角色` | 型別後綴只用已定義角色 | 違規 | 1 |
| `S·巢狀型別不重複外層名稱` | 巢狀型別不重複外層名稱 | 建議 | 1 |
| `S·註解與實作不符` | 註解與實作不符 | 違規 | 1 |
| `S·body 只放大框架` | body 只放大框架 | 必擋 | 1 |
| `S·Private Method 不自行取得資料` | Private Method 不自行取得資料 | 違規 | 1 |
| `S·以字串傳遞型別化資料` | 以字串傳遞型別化資料 | 建議 | 1 |
| `S·doc 內容不正確` | doc 內容不正確 | 建議 | 1 |
| `S·重複的錯誤轉換` | 重複的錯誤轉換 | 建議 | 1 |
| `S·view action 語意錯用` | view action 語意錯用 | 違規 | 1 |
| `S·呈現 modifier 掛在子 View` | 呈現 modifier 掛在子 View | 建議 | 1 |
| `S·View 內過濾業務資料` | View 內過濾業務資料 | 違規 | 1 |
| `S·重複的匯率換算` | 重複的匯率換算 | 建議 | 1 |
| `S·Effect 方法形式` | Effect 方法形式 | 建議 | 1 |
| `S·無參數 Private View 用 func` | 無參數 Private View 用 func | 違規 | 1 |
| `S·View 內重複狀態判斷` | View 內重複狀態判斷 | 建議 | 1 |
| `S·tuple 超過兩個元素` | tuple 超過兩個元素 | 違規 | 1 |
| `S·未使用的預留參數` | 未使用的預留參數 | 建議 | 1 |
| `S·View 內決定顯示規則` | View 內決定顯示規則 | 違規 | 1 |
| `S·CancelID 放在本體` | CancelID 放在本體 | 違規 | 1 |
| `S·依賴未放 Dependencies 區` | 依賴未放 Dependencies 區 | 違規 | 1 |
| `S·Reduce 內呼叫依賴與副作用` | Reduce 內呼叫依賴與副作用 | 違規 | 1 |
| `S·在 Feature 檔擴充 Core 型別` | 在 Feature 檔擴充 Core 型別 | 違規 | 1 |
| `S·Preview 覆寫依賴` | Preview 覆寫依賴 | 違規 | 1 |
| `S·Client 放在 Feature 資料夾` | Client 放在 Feature 資料夾 | 違規 | 1 |
| `S·多餘的 nonisolated` | 多餘的 nonisolated | 建議 | 1 |
| `S·型別名稱過於通用` | 型別名稱過於通用 | 建議 | 1 |
| `S·以 Task.yield 輪詢等待非同步結果` | 以 Task.yield 輪詢等待非同步結果 | 違規 | 1 |
| `S·doc comment 與測試行為不符` | doc comment 與測試行為不符 | 違規 | 1 |
| `S·Fixture 不叫 fixture 且參數無預設值` | Fixture 不叫 fixture 且參數無預設值 | 違規 | 1 |
| `S·Optional 結果未先 #require` | Optional 結果未先 #require | 建議 | 1 |
| `S·註解與程式碼矛盾` | 註解與程式碼矛盾 | 違規 | 1 |
| `S·註解未用正體中文` | 註解未用正體中文 | 違規 | 1 |
| `S·一個測試多組 When/Then` | 一個測試多組 When/Then | 違規 | 1 |
| `S·測試方法內手刻完整 Model` | 測試方法內手刻完整 Model | 違規 | 1 |
| `S·重複的測試` | 重複的測試 | 建議 | 1 |
| `S·同檔輔助型別應為 nested type／替身記錄方式` | 同檔輔助型別應為 nested type／替身記錄方式 | 違規 | 1 |
| `S·測試命名格式` | 測試命名格式 | 違規 | 1 |
| `S·測試無法區分宣稱的行為` | 測試無法區分宣稱的行為 | 違規 | 1 |

## 逐檔明細

### BuyLedger/Features/AISummary/AISummaryFeature.swift

共 31 筆 (必擋 9、違規 21、建議 0、已登記例外 1)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  AISummaryFeature.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/5/27. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L40 `MK4` 必擋 — extension 專屬分區寫在型別本體內 (腳本掃描)
    - 現況：`// MARK: - Nested Types`
    - 結論：已修正：型別本體只保留 State、Action、Dependencies 與 Body 分區
- L43 `S·巢狀型別放在本體` 違規 — 巢狀型別放在本體 (審查員判讀)
    - 問題：`Phase` 宣告在 State 本體內
    - 修法：移到 `// MARK: - Nested Types` 的 `extension AISummaryFeature`
    - 結論：已修正：`Phase` 已移到 `AISummaryFeature` 的 `Nested Types` extension
- L63 `S·Action 缺 view 分組` 違規 — Action 缺 view 分組 (審查員判讀)
    - 問題：`task`、`retryTapped`、`closeTapped` 與串流回應平放
    - 修法：加 `case view(View)` 收使用者操作
    - 結論：已修正：使用者操作已收進 `Action.view(View)`，串流回應維持平放
- L69 `D9` 必擋 — enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case chunkReceived(String)`
    - 結論：已修正：`chunkReceived` 已補 `text` 的 `- Parameter` 文件
- L75 `D9` 必擋 — enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case streamFailed(LocalizedStringResource)`
    - 結論：已修正：`streamFailed` 已補 `message` 的 `- Parameter` 文件
- L87 `MK4` 必擋 — extension 專屬分區寫在型別本體內 (腳本掃描)
    - 現況：`// MARK: - Nested Types`
    - 結論：已修正：串流輔助型別已移出 Feature 型別本體
- L90 `S·巢狀型別放在本體` 違規 — 巢狀型別放在本體 (審查員判讀)
    - 問題：`StreamResult` 宣告在 Feature 本體
    - 修法：移到 Nested Types extension (CancelID 之後依字母排序)
    - 結論：已修正：`StreamResult` 已移到 `Nested Types` extension，並與 `CancelID` 同處
- L92 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Cases`
    - 結論：已修正：已刪除不在允許清單內的 `Cases` 分區
- L104 `D9` 必擋 — enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case apiFailure(APIError)`
    - 結論：已修正：`apiFailure` 已補 `error` 的 `- Parameter` 文件
- L110 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Cancel ID`
    - 結論：已修正：`Cancel ID` 分區已併入允許的 `Nested Types`
- L113 `S·CancelID 放在本體` 違規 — CancelID 放在本體 (審查員判讀)
    - 問題：`CancelID` 宣告在 Feature 本體
    - 修法：移到 Nested Types extension
    - 結論：已修正：`CancelID` 已移到 `Nested Types` extension
- L119 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Reducer Body`
    - 結論：已修正：`Reducer Body` 已改為允許的 `Body` 分區
- L122 `TC5` 已登記例外 — Reducer body 型別不是 some ReducerOf<Self> (腳本掃描)
    - 現況：`var body: some Reducer<State, Action> {  ← apps/ios/CLAUDE.md 已登記：some ReducerOf<Self> 會 circular reference`
    - 結論：已登記例外 (`apps/ios/CLAUDE.md`「ios-dev-kit 規範與既有差異」)，不修
- L123 `TC3` 違規 — body 內直接寫 Reduce 閉包而非 Reduce(core) (腳本掃描)
    - 現況：`Reduce { state, action in`
    - 結論：已修正：Body 已改為 `Reduce(core)`
- L125 `S·case 超過十行未抽方法` 違規 — case 超過十行未抽方法 (審查員判讀)
    - 問題：`.task, .retryTapped` 分支約 70 行，含金鑰檢查、TaskGroup 競速與結果分派
    - 修法：抽成 `startStream(state:) -> Effect<Action>` 等 Private Method
    - 結論：已修正：串流啟動與逾時競速已抽到 `startStream(state:)`
- L126 `TC1` 違規 — @Dependency 與 var 寫在同一行 (腳本掃描)
    - 現況：`@Dependency(OllamaClient.self) var ollamaClient`
    - 結論：已修正：`@Dependency` 與 `private var` 已分行
- L126 `S·依賴未放 Dependencies 區` 違規 — 依賴未放 Dependencies 區 (審查員判讀)
    - 問題：在 reducer 分支內就地宣告 `@Dependency` (第 126～128 行，第 216 行 `dismiss` 也是)
    - 修法：移到本體 `// MARK: - Dependencies` 區宣告為 `private var`
    - 結論：已修正：四個依賴已集中在 `Dependencies` 分區並設為 private
- L127 `TC1` 違規 — @Dependency 與 var 寫在同一行 (腳本掃描)
    - 現況：`@Dependency(\.appConfiguration) var appConfiguration`
    - 結論：已修正：`@Dependency` 與 `private var` 已分行
- L128 `TC1` 違規 — @Dependency 與 var 寫在同一行 (腳本掃描)
    - 現況：`@Dependency(\.continuousClock) var clock`
    - 結論：已修正：`@Dependency` 與 `private var` 已分行
- L130 `S·Reduce 內呼叫依賴與副作用` 違規 — Reduce 內呼叫依賴與副作用 (審查員判讀)
    - 問題：reducer 本體同步呼叫 `appConfiguration.ollamaAPIKey()`，第 134 行還直接寫 log
    - 修法：金鑰讀取與 log 移入 `.run`，缺金鑰時回送失敗 action
    - 結論：已修正：金鑰讀取與 log 已移入 `startStream` 的 Effect，缺 key 改送 `streamFailed`
- L132 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 記錄狀態與下一步，不把環境變數名稱顯示給使用者。`
    - 結論：已修正：該註解已隨同步金鑰檢查移除
- L156 `S·catch 分散` 違規 — catch 分散 (審查員判讀)
    - 問題：串流任務分 `catch let error as APIError` 與通用 catch；第 167～171 行 `catch is CancellationError` 與通用 catch 都回 `.cancelled`
    - 修法：各用單一 catch，內部以 `if let apiError = error as? APIError` 或 switch 分派；取消分支合併
    - 結論：已修正：串流與時鐘競速各自只保留單一 `catch`
- L197 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .chunkReceived(text):`
    - 結論：已修正：reducer switch 的 case 已連續排列
- L201 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case .streamFinished:`
    - 結論：已修正：reducer switch 的 case 已連續排列
- L205 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .streamFailed(message):`
    - 結論：已修正：reducer switch 的 case 已連續排列
- L210 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case .streamTimedOut:`
    - 結論：已修正：reducer switch 的 case 已連續排列
- L215 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case .closeTapped:`
    - 結論：已修正：reducer switch 的 case 已連續排列
- L216 `TC1` 違規 — @Dependency 與 var 寫在同一行 (腳本掃描)
    - 現況：`@Dependency(\.dismiss) var dismiss`
    - 結論：已修正：`dismiss` 已移到 `Dependencies` 分區並分行宣告
- L227 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - APIError Friendly Message`
    - 結論：已修正：不再使用獨立的 APIError 文案分區
- L229 `S·在 Feature 檔擴充 Core 型別` 違規 — 在 Feature 檔擴充 Core 型別 (審查員判讀)
    - 問題：在 Feature 檔內擴充 Core 的 `APIError` 加 AI 總結專屬文案，讓 Core 型別對所有模組暴露此 feature 的 API
    - 修法：比照 FxFeature 改為本 Feature `private extension` 內的 `static func summaryFailureMessage(for:)`
    - 結論：已修正：文案已改為 `AISummaryFeature` private static method，grep 僅剩本檔

### BuyLedger/Features/AISummary/AISummaryView.swift

共 10 筆 (必擋 3、違規 7、建議 0、已登記例外 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  AISummaryView.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/5/27. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L15 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正：分區已改為允許的 `Properties`
- L20 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正：分區已改為允許的 `Body`
- L34 `S·body 內嵌 toolbar 內容` 違規 — body 內嵌 toolbar 內容 (審查員判讀)
    - 問題：關閉按鈕及其 accessibility modifier 直接寫在 body 的 toolbar
    - 修法：抽成 `closeToolbarItem` Private View
    - 結論：已修正：關閉 toolbar 已抽成 `closeToolbarItem`
- L45 `S·modifier 四組順序` 違規 — modifier 四組順序 (審查員判讀)
    - 問題：行為組 `.task` 排在導航組 `.navigationTitle`／`.toolbar` 之後
    - 修法：把 `.task` 移到 `.navigationTitle` 之前
    - 結論：已修正：`.task` 已移到導航與呈現 modifier 之前
- L54 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - ViewBuilder`
    - 結論：已修正：分區已改為允許的 `Private Views`
- L90 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case .idle, .streaming, .finished:`
    - 結論：已修正：內容 switch 的 case 已連續排列
- L148 `S·modifier 四組順序` 違規 — modifier 四組順序 (審查員判讀)
    - 問題：`aiDisclaimerCapsule` 先 `.foregroundStyle` 再 `.padding`，`.frame` 排在 `.background` 之後
    - 修法：調整為 padding／frame → foregroundStyle／background；若 frame 需在 background 外層，以註解說明
    - 結論：已修正：`padding` 已移到 `foregroundStyle` 之前，`frame` 維持在 `background` 外並加註原因
- L158 `S·多狀態缺 Preview` 違規 — 多狀態缺 Preview (審查員判讀)
    - 問題：只有一個 Preview，未涵蓋失敗、串流中與逾時截斷狀態
    - 修法：以不同初始 State 各加一個具名 `#Preview`
    - 結論：已修正：已加入串流中、失敗、逾時截斷三個具名 Preview
- L164 `S·Preview 覆寫依賴` 違規 — Preview 覆寫依賴 (審查員判讀)
    - 問題：Preview 以 `withDependencies` 手動指定 previewValue，TCA 在 Preview 會自動使用 previewValue
    - 修法：移除 `withDependencies` 區塊；若 `appConfiguration` 缺 previewValue 則補在其 DependencyKey
    - 結論：已修正 (task 5.2)：三個具名 Preview 均直接建立 Store，已移除 `withDependencies` 覆寫

### BuyLedger/Features/AISummary/OllamaClient.swift

共 9 筆 (必擋 3、違規 4、建議 1、已登記例外 1)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  OllamaClient.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/5/27. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L12 `S·Client 放在 Feature 資料夾` 違規 — Client 放在 Feature 資料夾 (審查員判讀)
    - 問題：`OllamaClient` 是遠端服務的技術入口，卻放在 `Features/AISummary/`
    - 修法：連同 `OllamaDTO.swift` 移到 `Core/Networking/`，與 ExchangeRateClient 同層
    - 結論：已修正 (task 1.3)：`OllamaClient` 已搬到 `Core/Networking/`
- L14 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Static Properties`
    - 結論：已修正 (task 1.3)：靜態屬性已併入 `Properties` 分區
- L17 `S·多餘的 nonisolated` 建議 — 多餘的 nonisolated (審查員判讀)
    - 問題：專案預設隔離已是 nonisolated，第 17、41、61、130、141 行仍逐一標 `nonisolated`
    - 修法：移除多餘的 `nonisolated`
    - 結論：已修正 (task 1.3)：移除 `OllamaClient` 上多餘的 `nonisolated`
- L19 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Dependency Properties`
    - 結論：已修正 (task 1.3)：依賴 closure 已併入 `Properties` 分區
- L56 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Dependency Values`
    - 結論：已修正 (task 1.3，review 修正第 1 輪)：`OllamaClient` 的遵循 extension 使用 `DependencyKey` protocol 分區
- L63 `TC1` 違規 — @Dependency 與 var 寫在同一行 (腳本掃描)
    - 現況：`@Dependency(\.httpClient) var httpClient`
    - 結論：已修正 (task 1.3)：`@Dependency` 與 property 宣告已分行
- L109 `S·catch 分散` 違規 — catch 分散 (審查員判讀)
    - 問題：串流 Task 依序寫 `catch is CancellationError`、`catch let error as APIError`、通用 catch 三個子句
    - 修法：改為單一 catch，內部 switch 判斷 CancellationError／APIError／其他
    - 結論：已修正 (task 1.3)：改為單一 `catch` 並在內部區分取消、`APIError` 與其他錯誤
- L130 `TC4` 已登記例外 — 宣告 testValue (腳本掃描)
    - 現況：`nonisolated static let testValue: OllamaClient = OllamaClient(  ← apps/ios/CLAUDE.md 已登記：struct-of-closures Client 與 Repository 宣告 testValue`
    - 結論：已登記例外 (`apps/ios/CLAUDE.md`「ios-dev-kit 規範與既有差異」)，不修

### BuyLedger/Features/AISummary/OllamaDTO.swift

共 7 筆 (必擋 4、違規 2、建議 1、已登記例外 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  OllamaDTO.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/5/27. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L1 `FN1` 違規 — 檔名與主要型別名稱不一致 (腳本掃描)
    - 現況：`檔名 OllamaDTO.swift 找不到型別 OllamaDTO`
    - 結論：已修正 (task 1.3)：DTO 已拆成 `OllamaChatRequest.swift` 與 `OllamaChatResponse.swift`
- L10 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Request DTO`
    - 結論：已修正 (task 1.3)：請求型別改用 `Properties` 分區
- L13 `S·型別名稱過於通用` 建議 — 型別名稱過於通用 (審查員判讀)
    - 問題：`ChatRequest`／`ChatResponse` 在 App target 全域名稱沒有指出是 Ollama 的格式，日後接其他聊天 API 容易撞名
    - 修法：改為 `OllamaChatRequest`／`OllamaChatResponse`，或收成 `OllamaClient` 的 Nested Types
    - 結論：已修正 (task 1.3)：請求與回應型別已改為具 Ollama 前綴的名稱
- L15 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Data Properties`
    - 結論：已修正 (task 1.3)：請求欄位已放入 `Properties` 分區
- L42 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Response DTO`
    - 結論：已修正 (task 1.3)：回應型別已拆到獨立檔案並使用標準分區
- L47 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Data Properties`
    - 結論：已修正 (task 1.3)：回應欄位已放入 `Properties` 分區

### BuyLedger/Features/Customers/CustomerRankBadgeStyle.swift

共 2 筆 (必擋 1、違規 1、建議 0、已登記例外 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  CustomerRankBadgeStyle.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/7/20. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L13 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Cases`
    - 結論：已修正 (task 6.2)：刪除 `Cases` MARK，enum case 直接位於型別本體

### BuyLedger/Features/Customers/CustomersFeature.swift

共 18 筆 (必擋 6、違規 10、建議 1、已登記例外 1)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  CustomersFeature.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/7/12. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L12 `S·模型型別獨立成檔` 違規 — 模型型別獨立成檔 (審查員判讀)
    - 問題：`CustomerRow` 與其彙總邏輯 `aggregate(orders:)` 與 reducer 同檔
    - 修法：搬到 `CustomerRow.swift`
    - 結論：已修正：`CustomerRow` 與 `aggregate(orders:)` 已搬到獨立檔案
- L14 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Identifiable Properties`
    - 結論：已修正：手寫 `Identifiable` 實作已移到 `Identifiable` extension
- L19 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Data Properties`
    - 結論：已修正：CustomerRow 欄位已放在標準 `Properties` 分區
- L48 `S·最後一個 closure 用 trailing` 違規 — 最後一個 closure 用 trailing (審查員判讀)
    - 問題：`Dictionary(grouping: orders, by: { $0.customer.name })` 以標籤傳 closure
    - 修法：改為 `Dictionary(grouping: orders) { $0.customer.name }`
    - 結論：已修正：`Dictionary(grouping:)` 已改用 trailing closure
- L52 `S·closure 不明確標註型別` 違規 — closure 不明確標註型別 (審查員判讀)
    - 問題：`.compactMap { name, list -> CustomerRow? in` 明寫回傳型別
    - 修法：拿掉 `-> CustomerRow?`；分組結果不會為空，可改 `map` 並移除 guard
    - 結論：已修正：`compactMap` closure 已移除明寫的回傳型別
- L57 `CL1` 違規 — 兩個以上參數的 closure 用 $1 (腳本掃描)
    - 現況：`let totalSpent = contributing.reduce(Decimal.zero) { $0 + $1.summary.revenue }`
    - 結論：已修正：reduce closure 已改用 `total` 與 `order` 具名參數
- L69 `CL1` 違規 — 兩個以上參數的 closure 用 $1 (腳本掃描)
    - 現況：`.sorted { $0.totalSpent > $1.totalSpent }`
    - 結論：已修正：sort closure 已改用 `lhs` 與 `rhs` 具名參數
- L87 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var customers: [CustomerRow] {`
    - 結論：依 design Non-Goals 不修：`tca-architecture.md` 的 State 一節要求可由其他狀態算出的值寫成 computed property；改成 stored 需要第二個寫入者同步 `customers`，違反投影單一寫入者
- L87 `S·State 衍生值成本` 建議 — State 衍生值成本 (審查員判讀)
    - 問題：`customers` computed 每次讀取都重新分組、彙總全部訂單，View body 讀一次、ForEach 期間又依賴它
    - 修法：改為 stored `customers`，在 `orders` 同步時由 RootFeature 或 reducer 重算
    - 結論：依 design Non-Goals 不修：`tca-architecture.md` 的 State 一節要求可由其他狀態算出的值寫成 computed property；改成 stored 需要第二個寫入者同步 `customers`，違反投影單一寫入者
- L99 `S·Action 分 view／delegate` 違規 — Action 分 view／delegate (審查員判讀)
    - 問題：`task` 平放且本 Feature 不處理，由 RootFeature 直接攔截 `.customers(.task)`；使用者點擊也沒有 view case
    - 修法：改為 `view(View)` (task、customerRowTapped) 與 `delegate(Delegate)`，reducer 收到 view 後轉 delegate，Root 只攔截 delegate
    - 結論：已修正：Action 已分成 `view` 與 `delegate`，Root 只攔截 delegate
- L102 `D9` 必擋 — enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case delegate(Delegate)`
    - 結論：已修正：`delegate` 已補 `action` 的 `- Parameter` 文件
- L109 `D9` 必擋 — enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case customerTapped(String)`
    - 結論：已修正：`customerTapped` 已補 `name` 的 `- Parameter` 文件
- L109 `S·delegate 以結果命名` 違規 — delegate 以結果命名 (審查員判讀)
    - 問題：delegate `customerTapped(String)` 以使用者操作命名
    - 修法：改名 `customerSelected(name:)`
    - 結論：已修正：delegate 已改名為 `customerSelected(name:)`
- L113 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Reducer Body`
    - 結論：已修正：reducer 分區已改為允許的 `Body`
- L116 `TC5` 已登記例外 — Reducer body 型別不是 some ReducerOf<Self> (腳本掃描)
    - 現況：`var body: some Reducer<State, Action> {  ← apps/ios/CLAUDE.md 已登記：some ReducerOf<Self> 會 circular reference`
    - 結論：已登記例外 (`apps/ios/CLAUDE.md`「ios-dev-kit 規範與既有差異」)，不修
- L117 `TC3` 違規 — body 內直接寫 Reduce 閉包而非 Reduce(core) (腳本掃描)
    - 現況：`Reduce { _, action in`
    - 結論：已修正：Body 已改為 `Reduce(core)`
- L122 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case .delegate:`
    - 結論：已修正：reducer switch 的 case 已連續排列

### BuyLedger/Features/Customers/CustomersView.swift

共 19 筆 (必擋 5、違規 12、建議 2、已登記例外 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  CustomersView.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/5/1. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L14 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正 (task 6.2)：改為允許的 `Properties` 分區
- L16 `S·doc comment 複述名稱` 違規 — doc comment 複述名稱 (審查員判讀)
    - 問題：`/// 客戶彙總功能 store` 用術語；同類 L24「客戶名單畫面內容」、L57「空狀態 view」、L187「名次徽章」
    - 修法：寫出來源與內容，例如「前三名卡片與全部客戶清單的資料來源」
    - 結論：已修正 (task 6.2)：store、body、空狀態與名次徽章的說明均改為描述實際內容
- L20 `S·View Properties 順序` 違規 — View Properties 順序 (審查員判讀)
    - 問題：`@Environment(\.locale)` 排在 `store` 之後
    - 修法：把 `@Environment` 移到最前
    - 結論：已修正 (task 6.2)：Properties 依序放置 `@Environment`、`@ScaledMetric` 與 store
- L22 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正 (task 6.2)：改為允許的 `Body` 分區
- L26 `S·body 不宣告區域變數` 違規 — body 不宣告區域變數 (審查員判讀)
    - 問題：body 宣告 `let palette` 與 `let customers`
    - 修法：palette 改為屬性，customers 直接讀 `store.customers` 並把內容抽成 `content` Private View
    - 結論：已修正 (task 6.2)：body 只組合 `content`，色盤由 computed property 提供，客戶資料直接讀 store
- L44 `S·modifier 四組順序` 違規 — modifier 四組順序 (審查員判讀)
    - 問題：行為組 `.task`、`.accessibilityIdentifier` 排在導航組 `.navigationTitle` 之後
    - 修法：改為 `.background` → `.accessibilityIdentifier` → `.task` → `.navigationTitle`
    - 結論：已修正 (task 6.2)：body modifier 已依背景、無障礙、行為、導航順序排列
- L51 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - ViewBuilder`
    - 結論：已修正 (task 6.2)：改為允許的 `Private Views` 分區
- L87 `FM1` 必擋 — 行寬超過 100 (腳本掃描)
    - 現況：`110 字元`
    - 結論：已修正 (task 6.2)：`ForEach` 的長呼叫已拆成多行，檔案行寬檢查無超過 100 字元
- L89 `S·View 只送 view action` 違規 — View 只送 view action (審查員判讀)
    - 問題：View 直接送 `.delegate(.customerTapped(...))` (L89、L230)，delegate 應只由 Feature body 送出
    - 修法：改送 `.view(.customerRowTapped(name:))`，由 reducer 轉成 delegate
    - 結論：已修正 (task 6.2)：Top 卡片與客戶列均改送 `.view(.customerTapped(name))`
- L139 `SU5` 違規 — modifier 與 View 同行 (腳本掃描)
    - 現況：`Text("·").foregroundStyle(palette.secondaryLabel)`
    - 結論：已修正 (task 6.2)：分隔點的 `foregroundStyle` 已移至下一行
- L139 `S·modifier 一行一個` 違規 — modifier 一行一個 (審查員判讀)
    - 問題：`Text("·").foregroundStyle(...)` modifier 與 View 同行 (L139、L274)
    - 修法：`.foregroundStyle` 換行縮排
    - 結論：已修正 (task 6.2)：兩個分隔點的 modifier 均各自獨立一行
- L199 `S·modifier 四組順序` 違規 — modifier 四組順序 (審查員判讀)
    - 問題：`rankBadge` 的 `.padding` (版面) 排在 `.font`、`.foregroundStyle` (外觀) 之後
    - 修法：改為 `.padding` → `.font` → `.foregroundStyle` → `.background` → `.clipShape`
    - 結論：已修正 (task 6.2)：rank badge 已依版面、外觀、背景與裁切順序排列
- L245 `S·尺寸單一來源` 建議 — 尺寸單一來源 (審查員判讀)
    - 問題：分隔線縮排寫死 `36`，與 L261 頭像尺寸各自維護
    - 修法：抽成 `Layout.avatarSize` 常數或沿用 `BLListMetrics` 推導
    - 結論：第 2 步 (`shared-designsystem-style-compliance`) 已修正：頭像尺寸與分隔線內縮都取自 `customerAvatarSize` (`@ScaledMetric`)，實作時確認後標記
- L272 `FM14` 違規 — 多行參數的右括號沒有單獨一行 (腳本掃描)
    - 現況：`customer.tier == .vip ? palette.orange : palette.secondaryLabel)`
    - 結論：已修正 (task 6.2)：三元運算式的多行 `foregroundStyle` 右括號已單獨成行
- L274 `SU5` 違規 — modifier 與 View 同行 (腳本掃描)
    - 現況：`Text("·").foregroundStyle(palette.secondaryLabel)`
    - 結論：已修正 (task 6.2)：客戶列分隔點的 `foregroundStyle` 已移至下一行
- L285 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 金額已放入 accessibilityValue，避免重複朗讀。`
    - 結論：已修正 (task 6.2)：移除註解結尾的中文句號
- L317 `S·View 不寫格式化方法` 必擋 — View 不寫格式化方法 (審查員判讀)
    - 問題：Private Method `formatDate(_:)` 在 View 內自行格式化日期 (L177、L292 使用)
    - 修法：改用 `Text(date, format: .dateTime.month(.defaultDigits).day(.defaultDigits))` 並以 `.environment(\.locale)` 生效，或移到 `BLFormatters` 靜態函式
    - 結論：已修正 (task 6.2)：刪除 View 內的 `formatDate`，改呼叫 `BLFormatters.shortDate`
- L329 `S·#Preview 涵蓋各狀態` 建議 — #Preview 涵蓋各狀態 (審查員判讀)
    - 問題：只有有資料的 Preview，缺空狀態
    - 修法：補 `#Preview("尚無客戶")`
    - 結論：已修正 (task 6.2)：新增無資料的 `客戶名單空狀態` Preview

### BuyLedger/Features/FX/FxFeature.swift

共 34 筆 (必擋 12、違規 18、建議 3、已登記例外 1)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  FxFeature.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/5/1. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L43 `S·sheet 未走 Destination` 違規 — sheet 未走 Destination (審查員判讀)
    - 問題：幣別選擇 sheet 以 `showsCurrencySheet: Bool` 控制，而非 `@Presents var destination`
    - 修法：新增 `@Reducer enum Destination { case currencyPicker(...) }` 與 `@Presents var destination`，View 以 `.sheet(item: $store.scope(...))` 綁定
    - 結論：已修正：改以無關聯值 `Destination.currencyPicker` 與 `@Presents var destination` 管理 sheet，View 以 destination scope 呈現
- L45 `MK4` 必擋 — extension 專屬分區寫在型別本體內 (腳本掃描)
    - 現況：`// MARK: - Computed Properties`
    - 結論：已修正：移除 State 內的 Computed Properties MARK，依 design 保留 State 衍生值在 stored properties 之後
- L48 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var rate: Decimal? {`
    - 結論：依 design 不修：`rate` 是 State 衍生值，依 TCA State 規則留在 State 型別內
- L53 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var convertedTwd: Decimal? {`
    - 結論：依 design 不修：`convertedTWD` 是 State 衍生值，依 TCA State 規則留在 State 型別內
- L60 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`func displayRate(for currency: CurrencyCode) -> Decimal? {`
    - 結論：依 design 不修：`displayRate(for:)` 是 State 對外提供的衍生查詢，需供 View 與測試使用，並留在 State 內
- L79 `S·Action 缺 view 分組` 違規 — Action 缺 view 分組 (審查員判讀)
    - 問題：`quickAmountTapped`、`currencyPickerTapped`、`fromCurrencySelected`、`task` 與內部回應平放
    - 修法：加 `case view(View)` 收使用者操作
    - 結論：已修正：使用者操作統一放入 `Action.View`，內部回應與目的地事件各自獨立分組
- L82 `D9` 必擋 — enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case binding(BindingAction<State>)`
    - 結論：已修正：補上 `- Parameter action` 文件
- L85 `D9` 必擋 — enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case quickAmountTapped(Decimal)`
    - 結論：已修正：移至 `View` 並補上 `- Parameter amount` 文件
- L91 `D9` 必擋 — enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case fromCurrencySelected(String)`
    - 結論：依 design 不修：幣別選擇器以 ISO 代碼字串溝通，字串轉 `CurrencyCode` 留在 reducer，View 不做型別轉換
- L91 `S·以字串傳遞型別化資料` 建議 — 以字串傳遞型別化資料 (審查員判讀)
    - 問題：`fromCurrencySelected(String)` 傳原始字串，再於 reducer 轉 `CurrencyCode`
    - 修法：action 直接帶 `CurrencyCode`，轉換放在 View 的選擇回呼
    - 結論：依 design 不修：幣別選擇器以 ISO 代碼字串溝通，字串轉 `CurrencyCode` 留在 reducer，View 不做型別轉換
- L93 `S·doc 內容不正確` 建議 — doc 內容不正確 (審查員判讀)
    - 問題：doc 寫「畫面 onAppear 觸發」，實際由 `.task` 觸發，且錯誤橫幅的重試也送這個 action
    - 修法：改為「畫面出現時載入匯率與幣別清單」
    - 結論：已修正：`View.task` 的說明改為畫面出現時載入匯率與幣別清單，重試另有明確 action
- L97 `D9` 必擋 — enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case ratesLoaded(FxRateSnapshot)`
    - 結論：已修正：成功與失敗合併為帶 `Result` 的 `ratesResponse`，並補上參數文件
- L97 `S·Result 拆成兩個 case` 違規 — Result 拆成兩個 case (審查員判讀)
    - 問題：`ratesLoaded` 與 `ratesFailed` 把同一次請求結果拆成兩個 case
    - 修法：合併為 `ratesResponse(Result<FxRateSnapshot, APIError>)`
    - 結論：已修正：匯率請求使用單一 `ratesResponse(Result<FxRateSnapshot, APIError>)`
- L100 `D9` 必擋 — enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case ratesFailed(LocalizedStringResource)`
    - 結論：已修正：移除分離的失敗 case，錯誤在 `ratesResponse(.failure)` 分支轉成使用者文案
- L103 `D9` 必擋 — enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case availableCurrenciesLoaded([CurrencyCode])`
    - 結論：已修正：改為 `currencyCodesResponse(Result<[CurrencyCode], CurrencyMetadataRepositoryError>)` 並補上參數文件
- L106 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Dependency Properties`
    - 結論：已修正：分區改為 `Dependencies`
- L109 `TC1` 違規 — @Dependency 與 var 寫在同一行 (腳本掃描)
    - 現況：`@Dependency(ExchangeRateClient.self) private var client`
    - 結論：已修正：`@Dependency` 與 property 宣告分行
- L112 `TC1` 違規 — @Dependency 與 var 寫在同一行 (腳本掃描)
    - 現況：`@Dependency(CurrencyMetadataRepository.self) private var currencyMetadataRepository`
    - 結論：已修正：`@Dependency` 與 property 宣告分行
- L114 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Reducer Body`
    - 結論：已修正：分區改為 `Body`
- L117 `TC5` 已登記例外 — Reducer body 型別不是 some ReducerOf<Self> (腳本掃描)
    - 現況：`var body: some Reducer<State, Action> {  ← apps/ios/CLAUDE.md 已登記：some ReducerOf<Self> 會 circular reference`
    - 結論：已登記例外 (`apps/ios/CLAUDE.md`「ios-dev-kit 規範與既有差異」)，不修
- L120 `TC3` 違規 — body 內直接寫 Reduce 閉包而非 Reduce(core) (腳本掃描)
    - 現況：`Reduce { state, action in`
    - 結論：已修正：`body` 改為 `Reduce(core)` 並接上 destination scope
- L125 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .quickAmountTapped(value):`
    - 結論：已修正：`core` 的 switch case 連續排列
- L129 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case .currencyPickerTapped:`
    - 結論：已修正：`core` 的 switch case 連續排列
- L133 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .fromCurrencySelected(code):`
    - 結論：已修正：`core` 的 switch case 連續排列
- L137 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case .task:`
    - 結論：已修正：`core` 的 switch case 連續排列
- L137 `S·case 超過十行未抽方法` 違規 — case 超過十行未抽方法 (審查員判讀)
    - 問題：`.task` 分支約 34 行，Effect 內含並行載入與錯誤轉換
    - 修法：抽成 Private Method `loadRatesAndCurrencies(shouldFetchRates:) -> Effect<Action>`
    - 結論：已修正：task 與 retry 共用 `loadRatesAndCurrencies() -> Effect<Action>`
- L162 `S·catch 分散` 違規 — catch 分散 (審查員判讀)
    - 問題：`fetchLatest` 已是 `throws(APIError)`，卻寫 `catch let error as APIError` 再加一個通用 catch，後者不可能執行
    - 修法：改為單一 `catch { await send(.ratesFailed(Self.userMessage(for: error))) }`，與 QuoteFeature 一致
    - 結論：已修正：每個 typed throwing dependency 只保留一個 catch，並把錯誤送入對應 Result response
- L172 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .ratesLoaded(snapshot):`
    - 結論：已修正：`core` 的 switch case 連續排列
- L178 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .ratesFailed(message):`
    - 結論：已修正：`core` 的 switch case 連續排列
- L183 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .availableCurrenciesLoaded(codes):`
    - 結論：已修正：`core` 的 switch case 連續排列；舊的平放 response case 已改為 grouped response
- L187 `CL1` 違規 — 兩個以上參數的 closure 用 $1 (腳本掃描)
    - 現況：`$0.rawValue.localizedStandardCompare($1.rawValue) == .orderedAscending`
    - 結論：已修正：排序 closure 改用 `lhs` 與 `rhs`
- L187 `CL2` 違規 — 多行 closure 使用 $0 (腳本掃描)
    - 現況：`$0.rawValue.localizedStandardCompare($1.rawValue) == .orderedAscending`
    - 結論：已修正：排序 closure 改用具名參數
- L202 `S·重複的錯誤轉換` 建議 — 重複的錯誤轉換 (審查員判讀)
    - 問題：`userMessage(for:)` 與 QuoteFeature 同名函式結構完全相同，只有句尾不同
    - 修法：抽出共用的 APIError 訊息對應，以參數決定情境後綴
    - 結論：依 design Non-Goals 不修：Fx 與 Quote 的錯誤文案措辭不同，各自是字串目錄中的獨立 key，合併要改動本地化目錄與英文翻譯，超出本步範圍

### BuyLedger/Features/FX/FxView.swift

共 16 筆 (必擋 7、違規 8、建議 1、已登記例外 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  FxView.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/5/1. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L1 `FM4` 違規 — 單檔超過 300 行 (不含檔頭與空行) (腳本掃描)
    - 現況：`398 行`
    - 結論：已修正：抽出 `FxStatusBanner` 與 `FxRatesList` 後，`FxView.swift` 為 286 行，不含檔頭與空行
- L14 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正：View 分區名稱符合目前規範
- L28 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正：View 分區名稱符合目前規範
- L32 `S·body 內宣告區域變數` 違規 — body 內宣告區域變數 (審查員判讀)
    - 問題：body 內 `let palette = BLPalette()`
    - 修法：改由 Private Views 自行取用或宣告 `var palette`
    - 結論：已修正：色盤改為 View 的 computed property，body 僅保留畫面框架與子 View
- L47 `S·modifier 四組順序` 違規 — modifier 四組順序 (審查員判讀)
    - 問題：`.accessibilityIdentifier` 在 `.background` 之前，`.scrollDismissesKeyboard`／`.bind`／`.task` 夾在 `.navigationTitle`、`.toolbar` 前後
    - 修法：依版面 → 外觀 → 行為 → 導航與呈現排序
    - 結論：已修正：`body` modifier 依版面、外觀、行為、導航與呈現分組排列
- L52 `S·body 內嵌 toolbar 內容` 違規 — body 內嵌 toolbar 內容 (審查員判讀)
    - 問題：鍵盤 toolbar 的 Spacer 與按鈕及其 modifier 直接寫在 body
    - 修法：抽成 `keyboardToolbar` Private View，body 寫 `.toolbar { keyboardToolbar }`
    - 結論：已修正：鍵盤工具列抽為 `keyboardToolbar`，完成鍵直接寫入焦點狀態
- L72 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - ViewBuilder`
    - 結論：已修正：ViewBuilder 分區名稱符合目前規範
- L105 `S·view action 語意錯用` 違規 — view action 語意錯用 (審查員判讀)
    - 問題：重試按鈕送 `.task`，把畫面出現事件當重試用
    - 修法：新增 `.view(.retryTapped)`，core 內共用載入 Effect
    - 結論：已修正：重試按鈕改送 `.view(.retryTapped)`，與 task 共用載入 Effect
- L193 `S·呈現 modifier 掛在子 View` 建議 — 呈現 modifier 掛在子 View (審查員判讀)
    - 問題：`.sheet` 掛在 `currencyPicker` Private View 上，讀 body 看不出畫面會呈現 sheet
    - 修法：把 `.sheet` 移到 body 的導航與呈現組
    - 結論：已修正：destination sheet 已移到 `body` 的呈現 modifier
- L284 `FM1` 必擋 — 行寬超過 100 (腳本掃描)
    - 現況：`103 字元`
    - 結論：已修正：重構後檔案的非字串程式行符合 100 字元上限
- L365 `S·View 內格式化方法` 必擋 — View 內格式化方法 (審查員判讀)
    - 問題：`snapshotDateText` 在 View 內格式化日期，第 423 行 `rateSourceSubtitle` 又重複同一段日期樣式
    - 修法：就地 `Text(snapshot.date, format: .dateTime...)`，或抽成共用靜態格式化函式
    - 結論：已修正：日期格式化集中到 `FxFormatters.snapshotTimestamp(_:locale:)`
- L387 `S·View 內格式化方法` 必擋 — View 內格式化方法 (審查員判讀)
    - 問題：`rateDisplay(for:)` 在 View 內決定破折號並格式化匯率，第 437 行 `presetLabel` 也是格式化方法
    - 修法：就地 `Text(value, format: .number...)`；無匯率的破折號規則移入格式化函式或 State
    - 結論：已修正：匯率與快速金額格式化移到 `FxFormatters.rate` 與 `presetAmount`
- L401 `S·View 內含業務規則的格式化` 必擋 — View 內含業務規則的格式化 (審查員判讀)
    - 問題：`currencyDisplayText` 依語言是否為 zh 決定顯示幣別名稱或代碼，第 205～209 行 sheet 的 displayName／searchKeywords closure 也組顯示字串
    - 修法：抽成共用的幣別顯示格式化函式 (Fx 與 Quote 共用) 並補單元測試
    - 結論：第 2 步已修正：幣別顯示改走 `CurrencyDisplayName.text(code:language:)`，實作時確認後標記
- L411 `S·View 內過濾業務資料` 違規 — View 內過濾業務資料 (審查員判讀)
    - 問題：`ratesListCurrencies` 在 View 過濾掉 TWD；第 419 行 `rateSourceSubtitle` 的 `.twd` 分支因此永遠不會執行
    - 修法：移到 FxFeature.State 的計算屬性，並刪除無效分支
    - 結論：已修正：過濾移到 `FxFeature.State.ratesListCurrencies`，並刪除 `rateSourceSubtitle` 的新台幣分支
- L448 `S·多狀態缺 Preview` 違規 — 多狀態缺 Preview (審查員判讀)
    - 問題：只有初始狀態 Preview，缺載入中、錯誤與已連線
    - 修法：各狀態加一個具名 `#Preview`
    - 結論：已修正：新增初始、載入中、錯誤與已連線四個具名 Preview

### BuyLedger/Features/More/MoreView.swift

共 21 筆 (必擋 11、違規 6、建議 4、已登記例外 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  MoreView.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/5/1. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L14 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正 (task 6.3)：改為允許的 `Properties` 分區
- L19 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正 (task 6.3)：改為允許的 `Body` 分區
- L23 `S·body 不宣告區域變數` 違規 — body 不宣告區域變數 (審查員判讀)
    - 問題：body 宣告 `let palette = BLPalette()` 再傳給子 View
    - 修法：palette 改為 private 屬性，`phoneContent` 改為無參數 var
    - 結論：已修正 (task 6.3)：body 不再宣告 palette，`phoneContent` 改為無參數 Private View
- L38 `S·doc comment 不準確` 違規 — doc comment 不準確 (審查員判讀)
    - 問題：`/// 工具項目的領域定義` 但它只是更多頁的顯示設定；L198「保持 phone-friendly 的 grouped list 風格」用術語且沒說內容；L16「App 根層級 store」、L159「導向到對應 view」同樣
    - 修法：改為「更多頁每一列的標題、說明、圖示與顏色」等白話說明
    - 結論：已修正 (task 6.3)：store、導覽容器、目的地與列表的 doc comment 均改為描述實際畫面內容
- L39 `S·避免重複定義` 建議 — 避免重複定義 (審查員判讀)
    - 問題：`ToolItem` 七個 case 與 `RootFeature.MoreRoute` 一一對應，新增目的地要改兩處
    - 修法：改為 `private extension RootFeature.MoreRoute` 提供 title／systemImage／tint，刪除 ToolItem
    - 結論：已修正 (task 6.3)：刪除 `ToolItem`，標題、圖示與色彩改由以 `MoreRoute` 為輸入的 Private Method 提供
- L41 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Cases`
    - 結論：已修正 (task 6.3)：`ToolItem` 與其 `Cases` 分區已刪除
- L64 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Identifiable Properties`
    - 結論：已修正 (task 6.3)：`ToolItem` 與其 `Identifiable Properties` 分區已刪除
- L69 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Display Properties`
    - 結論：已修正 (task 6.3)：`ToolItem` 與其 `Display Properties` 分區已刪除
- L72 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var title: String {`
    - 結論：已修正 (task 6.3)：`ToolItem.title` 已刪除，標題映射改由 Private Method 處理
- L92 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var subtitle: String {`
    - 結論：已修正 (task 6.3)：無人使用的 `subtitle` 已隨 `ToolItem` 一併刪除
- L112 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var systemImage: String {`
    - 結論：已修正 (task 6.3)：`ToolItem.systemImage` 已刪除，圖示映射改由 Private Method 處理
- L134 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`func tint(in palette: BLPalette) -> Color {`
    - 結論：已修正 (task 6.3)：`ToolItem.tint` 已刪除，色彩映射改由 Private Method 處理
- L155 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - ViewBuilder`
    - 結論：已修正 (task 6.3)：改為允許的 `Private Views` 分區
- L194 `S·錯誤狀態可操作` 建議 — 錯誤狀態可操作 (審查員判讀)
    - 問題：`BLLoadFailureView(...) {}` 顯示重試按鈕但 closure 為空，按了沒有反應
    - 修法：改用無重試的空狀態 (`ContentUnavailableView`)，或重試時送 action 重建 lookupManagements
    - 結論：已修正 (task 6.3)：主檔管理 store 缺失時改顯示不帶按鈕的 `ContentUnavailableView`
- L216 `S·重複 View 抽 func` 建議 — 重複 View 抽 func (審查員判讀)
    - 問題：七個 NavigationLink 區塊只差 route，各 9 行幾乎相同
    - 修法：抽 `func routeLink(_ route: RootFeature.MoreRoute) -> some View`，或以 `ForEach` 走陣列
    - 結論：已修正 (task 6.3)：八個目的地列均改由 `routeLink(_:)` 建立
- L274 `SU5` 違規 — modifier 與 View 同行 (腳本掃描)
    - 現況：`Text("設定").font(BLTypographyStyle.body.font.weight(.medium))`
    - 結論：已修正 (task 6.3)：設定列已與其他 route 共用換行後的字型 modifier
- L274 `S·modifier 一行一個` 違規 — modifier 一行一個 (審查員判讀)
    - 問題：`Text("設定").font(...)` 與 L299 `Text(...).font(...)` modifier 與 View 同行
    - 修法：`.font` 換行縮排
    - 結論：已修正 (task 6.3)：route label 的 `.font` 已獨立成行
- L299 `SU5` 違規 — modifier 與 View 同行 (腳本掃描)
    - 現況：`Text(LocalizedStringKey(item.title)).font(BLTypographyStyle.body.font.weight(.medium))`
    - 結論：已修正 (task 6.3)：route label 的 Text 與 `.font` 已分行
- L307 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Accessibility Properties`
    - 結論：已修正 (task 6.3)：`Accessibility Properties` 分區已刪除
- L309 `S·擴充放在所屬型別` 建議 — 擴充放在所屬型別 (審查員判讀)
    - 問題：在 View 檔對 `RootFeature.MoreRoute` 加 `accessibilityKey` 擴充
    - 修法：移到 RootFeature 同資料夾或 `BLAccessibilityID.More` 內提供 `Row(route:)`
    - 結論：已修正 (task 6.3)：移除 `RootFeature.MoreRoute` 的 `accessibilityKey` extension，改用 MoreView 的 `accessibilityRow(for:)`

### BuyLedger/Features/Quote/QuoteFeature.swift

共 37 筆 (必擋 16、違規 18、建議 2、已登記例外 1)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  QuoteFeature.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/5/1. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L31 `S·縮寫大小寫` 違規 — 縮寫大小寫 (審查員判讀)
    - 問題：`internationalShippingTwd` 及 `itemTwd`、`domesticTwd`、`costTwd`、`suggestedTwd`、`estimatedProfitTwd` 等把 TWD 縮寫寫成 Twd
    - 修法：統一改為 `...TWD`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L61 `S·sheet 未走 Destination` 違規 — sheet 未走 Destination (審查員判讀)
    - 問題：幣別選擇 sheet 以 `showsCurrencySheet: Bool` 控制
    - 修法：改用 `@Presents var destination` 與 `Destination` reducer enum
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L63 `MK4` 必擋 — extension 專屬分區寫在型別本體內 (腳本掃描)
    - 現況：`// MARK: - Computed Properties`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L66 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var rate: Decimal {`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L66 `S·重複的匯率換算` 建議 — 重複的匯率換算 (審查員判讀)
    - 問題：`rate` 的 TWD 換算邏輯與 `FxFeature.State.displayRate(for:)` 相同
    - 修法：抽到 `FxRateSnapshot` 的方法 (如 `twdRate(for:)`)，兩個 Feature 共用
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L81 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var hasUsableRate: Bool {`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L86 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var rateUnavailableReason: LocalizedStringResource? {`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L109 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var costTwd: Decimal {`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L115 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var isTargetMarginBelowOneHundredPercent: Bool {`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L120 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var suggestedTwd: Decimal? {`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L132 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var estimatedProfitTwd: Decimal? {`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L140 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`var estimatedMarginPercent: Decimal? {`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L152 `S·Action 缺 view 分組` 違規 — Action 缺 view 分組 (審查員判讀)
    - 問題：`task`、`rateRefreshRequested`、`currencyPickerTapped`、`fromCurrencySelected` 與內部回應平放
    - 修法：加 `case view(View)` 收使用者操作
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L155 `D9` 必擋 — enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case binding(BindingAction<State>)`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L164 `D9` 必擋 — enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case ratesLoaded(FxRateSnapshot)`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L164 `S·Result 拆成兩個 case` 違規 — Result 拆成兩個 case (審查員判讀)
    - 問題：`ratesLoaded` 與 `ratesFailed` 拆開同一次請求結果
    - 修法：合併為 `ratesResponse(Result<FxRateSnapshot, APIError>)`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L167 `D9` 必擋 — enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case ratesFailed(LocalizedStringResource)`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L170 `D9` 必擋 — enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case availableCurrenciesLoaded([CurrencyCode])`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L176 `D9` 必擋 — enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case fromCurrencySelected(String)`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L179 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Dependency Properties`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L182 `TC1` 違規 — @Dependency 與 var 寫在同一行 (腳本掃描)
    - 現況：`@Dependency(ExchangeRateClient.self) private var client`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L185 `TC1` 違規 — @Dependency 與 var 寫在同一行 (腳本掃描)
    - 現況：`@Dependency(CurrencyMetadataRepository.self) private var currencyMetadataRepository`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L187 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Reducer Body`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L190 `TC5` 已登記例外 — Reducer body 型別不是 some ReducerOf<Self> (腳本掃描)
    - 現況：`var body: some Reducer<State, Action> {  ← apps/ios/CLAUDE.md 已登記：some ReducerOf<Self> 會 circular reference`
    - 結論：已登記例外 (`apps/ios/CLAUDE.md`「ios-dev-kit 規範與既有差異」)，不修
- L193 `TC3` 違規 — body 內直接寫 Reduce 閉包而非 Reduce(core) (腳本掃描)
    - 現況：`Reduce { state, action in`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L207 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case .task:`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L207 `S·case 超過十行未抽方法` 違規 — case 超過十行未抽方法 (審查員判讀)
    - 問題：`.task` 分支約 26 行，且與 FxFeature 的載入 Effect 幾乎相同
    - 修法：抽成回傳 `Effect<Action>` 的 Private Method
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L235 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case .rateRefreshRequested:`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L245 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .ratesLoaded(snapshot):`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L251 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .ratesFailed(message):`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L256 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .availableCurrenciesLoaded(codes):`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L260 `CL1` 違規 — 兩個以上參數的 closure 用 $1 (腳本掃描)
    - 現況：`$0.rawValue.localizedStandardCompare($1.rawValue) == .orderedAscending`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L260 `CL2` 違規 — 多行 closure 使用 $0 (腳本掃描)
    - 現況：`$0.rawValue.localizedStandardCompare($1.rawValue) == .orderedAscending`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L264 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case .currencyPickerTapped:`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L268 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .fromCurrencySelected(code):`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- L284 `S·Effect 方法形式` 建議 — Effect 方法形式 (審查員判讀)
    - 問題：`static func loadRates(client:send:) async` 要求呼叫端傳入 client 與 send，與樣板回傳 Effect 的方法形式不同
    - 修法：改為 instance 方法 `loadRates() -> Effect<Action>`，內部 `.run` 捕獲 `client`
    - 結論：已修正 (task 4.1)：依目前程式碼與 QuoteFeatureTests focused 20/20 通過結果確認
- task 4.1 行為確認：商品定價為 0 時建議售價仍為 0，因預估毛利率為 `nil` 而顯示「目標毛利需低於 100% 才能計算建議售價。」；這是既有行為，本批保留並留待使用者決定是否另行調整

### BuyLedger/Features/Quote/QuoteView.swift

共 19 筆 (必擋 5、違規 12、建議 2、已登記例外 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  QuoteView.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/5/1. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L1 `FM4` 違規 — 單檔超過 300 行 (不含檔頭與空行) (腳本掃描)
    - 現況：`448 行`
    - 結論：已修正 (task 4.2)：依目前程式碼、快照與 QuoteTests focused 2/2 通過結果確認
- L14 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正 (task 4.2)：依目前程式碼、快照與 QuoteTests focused 2/2 通過結果確認
- L28 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正 (task 4.2)：依目前程式碼、快照與 QuoteTests focused 2/2 通過結果確認
- L32 `S·body 內宣告區域變數` 違規 — body 內宣告區域變數 (審查員判讀)
    - 問題：body 內 `let palette = BLPalette()`
    - 修法：改由 Private Views 自行取用或宣告 `var palette`
    - 結論：已修正 (task 4.2)：依目前程式碼、快照與 QuoteTests focused 2/2 通過結果確認
- L45 `S·modifier 四組順序` 違規 — modifier 四組順序 (審查員判讀)
    - 問題：`.accessibilityIdentifier` 在 `.background` 前，行為組 modifier 夾在 `.navigationTitle`、`.toolbar` 前後
    - 修法：依四組順序重排
    - 結論：已修正 (task 4.2)：依目前程式碼、快照與 QuoteTests focused 2/2 通過結果確認
- L50 `S·body 內嵌 toolbar 內容` 違規 — body 內嵌 toolbar 內容 (審查員判讀)
    - 問題：鍵盤 toolbar 按鈕與 modifier 直接寫在 body
    - 修法：抽成 `keyboardToolbar` Private View
    - 結論：已修正 (task 4.2)：依目前程式碼、快照與 QuoteTests focused 2/2 通過結果確認
- L70 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - ViewBuilder`
    - 結論：已修正 (task 4.2)：依目前程式碼、快照與 QuoteTests focused 2/2 通過結果確認
- L95 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 顯示失敗原因與重試，不只顯示破折號。`
    - 結論：已修正 (task 4.2)：依目前程式碼、快照與 QuoteTests focused 2/2 通過結果確認
- L331 `S·無參數 Private View 用 func` 違規 — 無參數 Private View 用 func (審查員判讀)
    - 問題：`func suggestedHero()` 沒有參數卻寫成 func
    - 修法：改為 `var suggestedHero: some View`
    - 結論：已修正 (task 4.2)：依目前程式碼、快照與 QuoteTests focused 2/2 通過結果確認
- L337 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 無匯率或毛利不可計算時顯示破折號，避免把零誤認為結果。`
    - 結論：已修正 (task 4.2)：依目前程式碼、快照與 QuoteTests focused 2/2 通過結果確認
- L344 `S·View 內重複狀態判斷` 建議 — View 內重複狀態判斷 (審查員判讀)
    - 問題：hero 卡依匯率與毛利條件挑選訊息，與 State 的 `rateUnavailableReason` 及 statusBanner 的判斷重複
    - 修法：在 State 提供單一 `heroMessage` 狀態 enum，View 只依 case 顯示
    - 結論：已修正 (task 4.2)：依目前程式碼、快照與 QuoteTests focused 2/2 通過結果確認
- L349 `FM0` 必擋 — 縮排不是 4 格 (開括號後一層) (腳本掃描)
    - 現況：`預期縮排 26，實際 16`
    - 結論：已修正 (task 4.2)：依目前程式碼、快照與 QuoteTests focused 2/2 通過結果確認
- L365 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 使用低亮度漸層確保白字對比度。`
    - 結論：已修正 (task 4.2)：依目前程式碼、快照與 QuoteTests focused 2/2 通過結果確認
- L401 `S·tuple 超過兩個元素` 違規 — tuple 超過兩個元素 (審查員判讀)
    - 問題：`[(label: String, value: Decimal, color: Color)]` 三個元素的 tuple 陣列
    - 修法：改為 Nested Types 內的 `BreakdownItem` struct
    - 結論：已修正 (task 4.2)：依目前程式碼、快照與 QuoteTests focused 2/2 通過結果確認
- L460 `S·未使用的預留參數` 建議 — 未使用的預留參數 (審查員判讀)
    - 問題：`breakdownRow` 的 `palette _:` 未使用，doc 寫「預留給未來客製需求」
    - 修法：移除參數與對應 doc，需要時再加
    - 結論：已修正 (task 4.2)：依目前程式碼、快照與 QuoteTests focused 2/2 通過結果確認
- L480 `S·View 內決定顯示規則` 違規 — View 內決定顯示規則 (審查員判讀)
    - 問題：`heroPriceText` 在 View 內判斷匯率可用與建議售價是否存在，再決定顯示破折號或金額
    - 修法：State 暴露 `displayedSuggestedTWD: Decimal?`，View 只負責格式化或顯示破折號
    - 結論：已修正 (task 4.2)：依目前程式碼、快照與 QuoteTests focused 2/2 通過結果確認
- L490 `S·View 內含業務規則的格式化` 必擋 — View 內含業務規則的格式化 (審查員判讀)
    - 問題：`currencyDisplayText` 依語言決定幣別顯示，與 FxView 同名方法完全重複
    - 修法：抽成共用幣別顯示格式化函式並補單元測試
    - 結論：第 2 步已修正：幣別顯示改走 `CurrencyDisplayName.text(code:language:)`，實作時確認後標記
- L502 `S·多狀態缺 Preview` 違規 — 多狀態缺 Preview (審查員判讀)
    - 問題：只有初始狀態 Preview，缺載入中、匯率失敗、毛利達 100% 與可試算狀態
    - 修法：各狀態加一個具名 `#Preview`
    - 結論：已修正 (task 4.2)：依目前程式碼、快照與 QuoteTests focused 2/2 通過結果確認

### BuyLedger/Features/Settings/AISummaryModelCatalog.swift

共 3 筆 (必擋 1、違規 2、建議 0、已登記例外 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  AISummaryModelCatalog.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/5/27. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L13 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Static Properties`
    - 結論：已修正：分區改為 `Properties`，並移除冗餘的 `nonisolated`
- L16 `S·nonisolated 使用時機` 違規 — nonisolated 使用時機 (審查員判讀)
    - 問題：專案預設隔離已是 nonisolated，非 @MainActor 型別的常數再標 `nonisolated` 是冗餘且未註解理由 (L16、L19)
    - 修法：移除 `nonisolated`；若是為了某個 target 的隔離設定，加註解說明
    - 結論：已修正：移除冗餘的 `nonisolated`

### BuyLedger/Features/Settings/SettingsFeature.swift

共 28 筆 (必擋 7、違規 20、建議 0、已登記例外 1)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  SettingsFeature.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/5/1. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L11 `S·doc comment 不準確` 違規 — doc comment 不準確 (審查員判讀)
    - 問題：reducer 型別 doc 寫「設定頁狀態」；L17「設定狀態」、L48「設定頁事件」、L81「設定 reducer」只複述；L76「從 cache 拉最新清單」用術語
    - 修法：型別寫它決定的事，例如「設定頁的語言、幣別、月目標與 App 鎖定的讀取與儲存」
    - 結論：已修正，並以目前程式碼確認
- L31 `S·縮寫大小寫` 違規 — 縮寫大小寫 (審查員判讀)
    - 問題：`monthlyProfitGoalTwd` 的縮寫 TWD 位於結尾卻寫成 `Twd`
    - 修法：改名 `monthlyProfitGoalTWD` (連同 SettingsSnapshot、DashboardFeature 與 storage key 常數名)
    - 結論：已修正，並以目前程式碼確認
- L34 `S·Bool 命名` 違規 — Bool 命名 (審查員判讀)
    - 問題：`useAiSummary` 不是 is/has/can/should 開頭的斷言，且 `Ai` 縮寫大小寫不一致
    - 修法：改名 `isAISummaryEnabled`
    - 結論：已修正，並以目前程式碼確認
- L50 `S·Action 分 view／delegate` 違規 — Action 分 view／delegate (審查員判讀)
    - 問題：`task`、`defaultCurrencySelected`、`aiSummaryModelSelected` 與內部回應 `availableCurrenciesLoaded` 平放
    - 修法：改為 binding → view(View) → delegate → appLock → 內部回應
    - 結論：已修正，並以目前程式碼確認
- L53 `D9` 必擋 — enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case binding(BindingAction<State>)`
    - 結論：已修正，並以目前程式碼確認
- L59 `D9` 必擋 — enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case availableCurrenciesLoaded([CurrencyCode])`
    - 結論：已修正，並以目前程式碼確認
- L62 `D9` 必擋 — enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case defaultCurrencySelected(String)`
    - 結論：已修正，並以目前程式碼確認
- L65 `D9` 必擋 — enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case aiSummaryModelSelected(String)`
    - 結論：已修正，並以目前程式碼確認
- L68 `D9` 必擋 — enum case 的 associated value 缺 - Parameter (腳本掃描)
    - 現況：`case appLock(AppLockFeature.Action)`
    - 結論：已修正，並以目前程式碼確認
- L71 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Dependency Properties`
    - 結論：已修正：依賴區改名為 `Dependencies`
- L74 `TC1` 違規 — @Dependency 與 var 寫在同一行 (腳本掃描)
    - 現況：`@Dependency(SettingsStorage.self) private var storage`
    - 結論：已修正，並以目前程式碼確認
- L77 `TC1` 違規 — @Dependency 與 var 寫在同一行 (腳本掃描)
    - 現況：`@Dependency(CurrencyMetadataRepository.self) private var currencyMetadataRepository`
    - 結論：已修正，並以目前程式碼確認
- L79 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Reducer Body`
    - 結論：已修正，並以目前程式碼確認
- L82 `TC5` 已登記例外 — Reducer body 型別不是 some ReducerOf<Self> (腳本掃描)
    - 現況：`var body: some Reducer<State, Action> {  ← apps/ios/CLAUDE.md 已登記：some ReducerOf<Self> 會 circular reference`
    - 結論：已登記例外 (`apps/ios/CLAUDE.md`「ios-dev-kit 規範與既有差異」)，不修
- L85 `S·Feature 間不互相引用` 違規 — Feature 間不互相引用 (審查員判讀)
    - 問題：Settings 模組以 `Scope` 組合位於 `Features/App/` 的 `AppLockFeature`，並在 State 持有其狀態 (L37)
    - 修法：由 AppFeature／RootFeature 持有 AppLockFeature，Settings 只接收唯讀投影與送 delegate；或把 AppLockFeature 移入 Settings 模組
    - 結論：依 design「App 鎖定相關項目留給第 8 步」不修：`AppLockFeature` 屬 App 殼層，第 8 步落實裁決 4 時一併補 delegate 並移除此攔截
- L89 `TC3` 違規 — body 內直接寫 Reduce 閉包而非 Reduce(core) (腳本掃描)
    - 現況：`Reduce { state, action in`
    - 結論：已修正，並以目前程式碼確認
- L92 `S·Reduce 內不直接呼叫依賴` 違規 — Reduce 內不直接呼叫依賴 (審查員判讀)
    - 問題：`storage.load()` 與 `persist(_:)` 內的 `storage.save` 在 reducer 同步讀寫 UserDefaults (L92、L122、L127、L135、L139)
    - 修法：讀取改在 `.run` 內完成後送 `settingsLoaded(SettingsSnapshot)`，儲存改回傳 `.run { storage.save(snapshot) }`
    - 結論：部分修：讀取改為建立 State 時帶齊 (design「設定在建立 State 時帶齊」)，reducer 不再讀取；寫入維持在 reducer 內同步呼叫並登記例外，理由見 design「設定寫入維持同步」
- L112 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .availableCurrenciesLoaded(codes):`
    - 結論：已修正，並以目前程式碼確認
- L116 `CL1` 違規 — 兩個以上參數的 closure 用 $1 (腳本掃描)
    - 現況：`$0.rawValue.localizedStandardCompare($1.rawValue) == .orderedAscending`
    - 結論：已修正，並以目前程式碼確認
- L116 `CL2` 違規 — 多行 closure 使用 $0 (腳本掃描)
    - 現況：`$0.rawValue.localizedStandardCompare($1.rawValue) == .orderedAscending`
    - 結論：已修正，並以目前程式碼確認
- L120 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .defaultCurrencySelected(code):`
    - 結論：已修正，並以目前程式碼確認
- L125 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case let .aiSummaryModelSelected(model):`
    - 結論：已修正，並以目前程式碼確認
- L130 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case .binding(\.isGoalFieldFocused):`
    - 結論：已修正，並以目前程式碼確認
- L134 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case .binding:`
    - 結論：已修正，並以目前程式碼確認
- L138 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case .appLock(.enableAuthenticationFinished(.success)), .appLock(.enableToggled(false)):`
    - 結論：依 design「App 鎖定相關項目留給第 8 步」不修：`AppLockFeature` 屬 App 殼層，第 8 步落實裁決 4 時一併補 delegate 並移除此攔截
- L138 `S·父層只處理 delegate` 違規 — 父層只處理 delegate (審查員判讀)
    - 問題：直接攔截子 Feature 的 `.appLock(.enableAuthenticationFinished(.success))` 與 `.appLock(.enableToggled(false))` 決定存檔
    - 修法：AppLockFeature 送 `.delegate(.protectionChanged(Bool))`，Settings 改攔截 delegate
    - 結論：依 design「App 鎖定相關項目留給第 8 步」不修：`AppLockFeature` 屬 App 殼層，第 8 步落實裁決 4 時一併補 delegate 並移除此攔截
- L142 `FM9` 違規 — switch 的 case 之間有空行 (腳本掃描)
    - 現況：`case .appLock:`
    - 結論：已修正，並以目前程式碼確認

### BuyLedger/Features/Settings/SettingsSnapshot.swift

共 6 筆 (必擋 2、違規 3、建議 1、已登記例外 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  SettingsSnapshot.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/5/31. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L13 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Data Properties`
    - 結論：已修正：分區統一為 `Properties`
- L25 `S·Bool 與縮寫命名` 違規 — Bool 與縮寫命名 (審查員判讀)
    - 問題：`useAiSummary` 非斷言式 Bool，L22 `monthlyProfitGoalTwd` 縮寫大小寫錯誤，與 SettingsFeature 同一問題
    - 修法：改名 `isAISummaryEnabled`、`monthlyProfitGoalTWD`
    - 結論：已修正，並以目前程式碼確認
- L33 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Static Properties`
    - 結論：已修正：分區統一為 `Properties`
- L35 `S·doc comment 複述名稱` 違規 — doc comment 複述名稱 (審查員判讀)
    - 問題：`/// 預設設定` 只複述 `default`
    - 修法：寫出使用時機，例如「使用者尚未改過任何設定時套用的值」
    - 結論：已修正，並以目前程式碼確認
- L46 `S·避免重複定義` 建議 — 避免重複定義 (審查員判讀)
    - 問題：`testDefault` 與 `default` 內容完全相同，且只有 `testDefault` 標 `nonisolated`
    - 修法：刪除 `testDefault`，SettingsStorage.testValue 改讀 `.default`，並統一移除冗餘 `nonisolated`
    - 結論：已修正，並以目前程式碼確認

### BuyLedger/Features/Settings/SettingsStore.swift

共 10 筆 (必擋 4、違規 4、建議 1、已登記例外 1)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  SettingsStorage.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/5/31. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L12 `S·型別後綴只用已定義角色` 違規 — 型別後綴只用已定義角色 (審查員判讀)
    - 問題：`Storage` 不是已定義的角色後綴；此型別職責是 UserDefaults 本機儲存，對應角色是 `Store`
    - 修法：改名 `SettingsStore`，並依專案慣例移到 `Core/Dependencies/`
    - 結論：修：改名 `SettingsStore`，但留在 `Features/Settings/`：它引用 `AISummaryModelCatalog`，搬進 Core 會讓 Core 認得 Feature 型別
- L14 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Dependency Properties`
    - 結論：已修正：分區改為 `Nested Types`、`Internal Method` 與 `DependencyKey`
- L30 `S·巢狀型別不重複外層名稱` 建議 — 巢狀型別不重複外層名稱 (審查員判讀)
    - 問題：`SettingsStorage.SettingsStorageKeys` 重複外層型別名
    - 修法：改名 `Keys`
    - 結論：已修正，並以目前程式碼確認
- L32 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Static Properties`
    - 結論：已修正：不再使用 `Static Properties` 分區
- L35 `S·nonisolated 使用時機` 違規 — nonisolated 使用時機 (審查員判讀)
    - 問題：六個 key 常數與 `liveValue`、`testValue`、`previewValue` 全標 `nonisolated`，專案預設已是 nonisolated 且沒有註解理由
    - 修法：移除冗餘 `nonisolated`
    - 結論：已修正：移除冗餘的 `nonisolated`
- L54 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Dependency Values`
    - 結論：已修正，並以目前程式碼確認
- L68 `S·註解與實作不符` 違規 — 註解與實作不符 (審查員判讀)
    - 問題：註解說「未寫入時使用每月目標預設值」，但 `defaults.double(forKey:)` 在 key 不存在時回 0，全專案也沒有 `register(defaults:)`，新使用者實際拿到 0 而非 80,000
    - 修法：先判斷 `defaults.object(forKey:) == nil` 時回 `SettingsSnapshot.default.monthlyProfitGoalTwd`，並補單元測試
    - 結論：已修正，並以目前程式碼確認
- L74 `FM1` 必擋 — 行寬超過 100 (腳本掃描)
    - 現況：`108 字元`
    - 結論：已修正，並以目前程式碼確認
- L120 `TC4` 已登記例外 — 宣告 testValue (腳本掃描)
    - 現況：`nonisolated static let testValue: SettingsStorage = SettingsStorage(  ← apps/ios/CLAUDE.md 已登記：struct-of-closures Client 與 Repository 宣告 testValue`
    - 結論：已登記例外 (`apps/ios/CLAUDE.md`「ios-dev-kit 規範與既有差異」)，不修

### BuyLedger/Features/Settings/SettingsView.swift

共 11 筆 (必擋 5、違規 6、建議 0、已登記例外 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  SettingsView.swift | //  BuyLedger | // | //  Created by Leo Ho on 2026/5/1. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L14 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Properties`
    - 結論：已修正：分區改為 `Properties`
- L16 `S·doc comment 複述名稱` 違規 — doc comment 複述名稱 (審查員判讀)
    - 問題：`/// 設定 store` 用術語；同類 L27「設定頁畫面內容」、L137「預設幣別選擇器」、L216「從 bundle info 讀出版本號」
    - 修法：寫出內容與來源，例如「顯示 App 版本與建置編號，例如 1.7.0 (123)」
    - 結論：已修正，並以目前程式碼確認
- L20 `S·View Properties 順序` 違規 — View Properties 順序 (審查員判讀)
    - 問題：`@Environment(\.locale)` 排在 `store` 之後
    - 修法：依 @Environment → @FocusState → store 排列
    - 結論：已修正，並以目前程式碼確認
- L25 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - View Body`
    - 結論：已修正：分區改為 `Body`
- L29 `S·body 只放大框架` 必擋 — body 只放大框架 (審查員判讀)
    - 問題：六個 Section 的 Picker、Toggle、TextField、LabeledContent、footer 文字與鍵盤工具列按鈕全部寫在 body
    - 修法：抽成 `languageSection`、`aiSummarySection`、`currencySection`、`goalSection`、`appLockSection`、`aboutSection`、`keyboardDoneButton` 等 Private Views
    - 結論：已修正，並以目前程式碼確認
- L108 `S·modifier 四組順序` 違規 — modifier 四組順序 (審查員判讀)
    - 問題：行為組 `.scrollDismissesKeyboard`、`.bind`、`.task` 散落在導航組 `.rootNavigationTitle`、`.alert`、`.toolbar` 前後
    - 修法：改為 `.accessibilityIdentifier` → `.scrollDismissesKeyboard` → `.bind` → `.task` → `.rootNavigationTitle` → `.toolbar` → `.alert`
    - 結論：已修正，並以目前程式碼確認
- L119 `S·View 只送 view action` 違規 — View 只送 view action (審查員判讀)
    - 問題：View 手動組 `.binding(.set(\.isGoalFieldFocused, false))`，另送平放的 `.task`、`.defaultCurrencySelected`、`.aiSummaryModelSelected`、`.appLock(.enableToggled)`
    - 修法：焦點改寫 `store.isGoalFieldFocused = false`；其餘操作收進 `view` 分組
    - 結論：已修正，並以目前程式碼確認
- L133 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - ViewBuilder`
    - 結論：已修正：分區改為 `Private Views`
- L207 `S·View 不寫格式化方法` 必擋 — View 不寫格式化方法 (審查員判讀)
    - 問題：`currencyDisplayText(for:)` 依語言碼決定幣別顯示字串，L150 `displayName` closure 也在 View 內組「代碼 · 名稱」
    - 修法：移到 `BLFormatters` 靜態函式 (如 `currencyName(_:locale:)`) 並補單元測試，View 只呼叫
    - 結論：第 2 步已修正：幣別顯示改走 `CurrencyDisplayName.text(code:language:)`，實作時確認後標記
- L218 `S·Private Method 不自行取得資料` 違規 — Private Method 不自行取得資料 (審查員判讀)
    - 問題：`appVersion` 直接讀 `Bundle.main.infoDictionary`，輸入不是 View 已持有的值
    - 修法：由 SettingsFeature.State 持有版本字串，或以 `@Dependency` 注入的 bundle 資訊提供
    - 結論：已修正，並以目前程式碼確認

### BuyLedgerTests/AISummaryFeatureTests.swift

共 31 筆 (必擋 16、違規 13、建議 2、已登記例外 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  AISummaryFeatureTests.swift | //  BuyLedgerTests | // | //  Created by Leo Ho on 2026/5/27. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L12 `IM2` 違規 — @testable import 前缺空行 (腳本掃描)
    - 現況：`@testable import BuyLedger`
    - 結論：已修正：`@testable import` 前已補空行
- L14 `S·doc comment 放在屬性之後` 建議 — doc comment 放在屬性之後 (審查員判讀)
    - 問題：`///` 寫在 `@MainActor` 與 `struct` 之間，Quick Help 抓不到型別說明，也與樣板順序相反
    - 修法：把 `/// 驗證 AI 商品摘要流程` 移到 `@MainActor` 上方
    - 結論：已修正：測試型別 doc comment 已移到 `@MainActor` 上方
- L18 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Helpers`
    - 結論：已修正：`Helpers` 分區已移除，helper 改放 `Private Method` extension
- L29 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func streamingAccumulatesChunksThenFinishes() async {`
    - 結論：已修正：測試宣告上方已有行為 doc comment
- L29 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func streamingAccumulatesChunksThenFinishes() async {`
    - 結論：已修正：測試本體已明列 Given、When、Then
- L29 `S·測試命名未依「行為_情境_預期」` 違規 — 測試命名未依「行為_情境_預期」 (審查員判讀)
    - 問題：6 個 @Test 都是單段 lowerCamel (如 `streamingAccumulatesChunksThenFinishes`)，沒有以底線分出行為、情境、預期
    - 修法：改名為 `task_streamSucceeds_accumulatesChunksThenFinishes` 這類三段式名稱
    - 結論：依使用者 2026-09-21 裁決不修：測試方法維持單段 lowerCamel，差異登記於 `apps/ios/CLAUDE.md` 的「ios-dev-kit 規範與既有差異」
- L63 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func missingKeyFailsImmediately() async {`
    - 結論：已修正：測試宣告上方已有行為 doc comment
- L63 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func missingKeyFailsImmediately() async {`
    - 結論：已修正：測試本體已明列 Given、When、Then
- L76 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func apiErrorEntersFailedState() async {`
    - 結論：已修正：測試宣告上方已有行為 doc comment
- L76 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func apiErrorEntersFailedState() async {`
    - 結論：已修正：測試本體已明列 Given、When、Then
- L99 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func transportErrorMapsToFriendlyMessage() async {`
    - 結論：已修正：測試宣告上方已有行為 doc comment
- L99 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func transportErrorMapsToFriendlyMessage() async {`
    - 結論：已修正：測試本體已明列 Given、When、Then
- L126 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func closingSheetCancelsStreamingWithoutFailure() async {`
    - 結論：已修正：測試宣告上方已有行為 doc comment
- L126 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func closingSheetCancelsStreamingWithoutFailure() async {`
    - 結論：已修正：測試本體已明列 Given、When、Then
- L161 `S·以 Task.yield 輪詢等待非同步結果` 違規 — 以 Task.yield 輪詢等待非同步結果 (審查員判讀)
    - 問題：用最多 20 次 `Task.yield()` 輪詢取消訊號，而且只輪詢 `wasCancelled`，第 168 行的 `wasDismissed` 由另一個非結構化 Task 設定，排程稍慢就會誤判失敗
    - 修法：`send(.closeTapped)` 之後改用 `await store.finish()`，替身改用 `LockIsolated` 同步記錄，不另開 Task，也不輪詢
    - 結論：已修正：關閉後改用 `await store.finish()`，取消與 dismiss 以 `LockIsolated` 同步記錄
- L171 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func slowStreamStopsAtOverallDurationLimitAndKeepsPartialContent() async {`
    - 結論：已修正：測試宣告上方已有行為 doc comment
- L171 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func slowStreamStopsAtOverallDurationLimitAndKeepsPartialContent() async {`
    - 結論：已修正：測試本體已明列 Given、When、Then
- L225 `S·窮舉 receive 後的冗餘斷言` 建議 — 窮舉 receive 後的冗餘斷言 (審查員判讀)
    - 問題：上方的窮舉 `receive` 已驗證完整 state，`summaryText` 與 `errorMessage` 的 `#expect` 必定成立，只是雜訊
    - 修法：刪除第 225 至 226 行
    - 結論：已修正：已刪除窮舉 `receive` 後重複的 state 斷言
- L230 `FM16` 違規 — // MARK: 前後缺空行 (腳本掃描)
    - 現況：`// MARK: - Test Doubles`
    - 結論：已修正：`Test Doubles` 分區已移除
- L230 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Test Doubles`
    - 結論：已修正：改用允許的 `Private Method` 分區
- L232 `S·同檔輔助型別應為 nested type` 違規 — 同檔輔助型別應為 nested type (審查員判讀)
    - 問題：`CancellationRecorder` 是只給本檔用的頂層 `private actor`
    - 修法：移到 `extension AISummaryFeatureTests` 的 Nested Types 內，或改用 TCA 的 `LockIsolated`
    - 結論：已修正：`CancellationRecorder` 已刪除，測試改用 `LockIsolated`
- L234 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`private var cancelled = false`
    - 結論：已修正：`CancellationRecorder` 已刪除，該成員不再存在
- L235 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`private var dismissed = false`
    - 結論：已修正：`CancellationRecorder` 已刪除，該成員不再存在
- L235 `FM10` 違規 — 型別成員 (含 enum case) 之間缺空行 (腳本掃描)
    - 現況：`private var dismissed = false`
    - 結論：已修正：`CancellationRecorder` 已刪除，該成員不再存在
- L237 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`func markCancelled() {`
    - 結論：已修正：`CancellationRecorder` 已刪除，該方法不再存在
- L237 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`func markCancelled() {`
    - 結論：已修正：`CancellationRecorder` 已刪除，該方法不再存在
- L241 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`func markDismissed() {`
    - 結論：已修正：`CancellationRecorder` 已刪除，該方法不再存在
- L241 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`func markDismissed() {`
    - 結論：已修正：`CancellationRecorder` 已刪除，該方法不再存在
- L247 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`func wasCancelled() -> Bool {`
    - 結論：已修正：`CancellationRecorder` 已刪除，該方法不再存在
- L253 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`func wasDismissed() -> Bool {`
    - 結論：已修正：`CancellationRecorder` 已刪除，該方法不再存在

### BuyLedgerTests/CustomersFeatureTests.swift

共 27 筆 (必擋 6、違規 21、建議 0、已登記例外 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  CustomersFeatureTests.swift | //  BuyLedgerTests | // | //  Created by Leo Ho on 2026/7/12. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L11 `IM2` 違規 — @testable import 前缺空行 (腳本掃描)
    - 現況：`@testable import BuyLedger`
    - 結論：已修正：`@testable import` 前補空行
- L19 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func aggregatesOrdersByCustomerRankedBySpendDescending() {`
    - 結論：已修正：測試宣告上方已有行為 doc comment
- L19 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func aggregatesOrdersByCustomerRankedBySpendDescending() {`
    - 結論：已修正：測試本體已明列 Given、When、Then
- L19 `S·測試命名未依「行為_情境_預期」` 違規 — 測試命名未依「行為_情境_預期」 (審查員判讀)
    - 問題：5 個 @Test 都沒有三段式底線命名
    - 修法：例如 `customers_multipleOrders_rankedBySpendDescending`
    - 結論：依使用者 2026-09-21 裁決不修：測試方法維持單段 lowerCamel，差異登記於 `apps/ios/CLAUDE.md` 的「ios-dev-kit 規範與既有差異」
- L22 `FM15` 違規 — 超過三個參數卻放在同一行 (腳本掃描)
    - 現況：`makeOrder(id: "1", customer: "Amy", charged: 300, date: date(2026, 3, 1)),`
    - 結論：已修正：改用多行 `LedgerOrder.fixture` 呼叫
- L23 `FM15` 違規 — 超過三個參數卻放在同一行 (腳本掃描)
    - 現況：`makeOrder(id: "2", customer: "Amy", charged: 200, date: date(2026, 3, 5)),`
    - 結論：已修正：改用多行 `LedgerOrder.fixture` 呼叫
- L24 `FM15` 違規 — 超過三個參數卻放在同一行 (腳本掃描)
    - 現況：`makeOrder(id: "3", customer: "Bob", charged: 400, date: date(2026, 3, 2)),`
    - 結論：已修正：改用多行 `LedgerOrder.fixture` 呼叫
- L25 `FM15` 違規 — 超過三個參數卻放在同一行 (腳本掃描)
    - 現況：`makeOrder(id: "4", customer: "Cara", charged: 100, date: date(2026, 3, 3)),`
    - 結論：已修正：改用多行 `LedgerOrder.fixture` 呼叫
- L47 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func emptyOrdersYieldsEmptyCustomerList() {`
    - 結論：已修正：測試宣告上方已有行為 doc comment
- L47 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func emptyOrdersYieldsEmptyCustomerList() {`
    - 結論：已修正：測試本體已明列 Given、When、Then
- L53 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func totalSpentAndOrderCountExcludeCancelledAndMergeResultOrders() {`
    - 結論：已修正：該直接 aggregate 測試已移至 `CustomerRowTests`
- L53 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func totalSpentAndOrderCountExcludeCancelledAndMergeResultOrders() {`
    - 結論：已修正：測試已移至 `CustomerRowTests` 並補齊 Given、When、Then
- L55 `FM15` 違規 — 超過三個參數卻放在同一行 (腳本掃描)
    - 現況：`makeOrder(id: "confirmed", customer: "Amy", charged: 100, date: date(2026, 3, 1)),`
    - 結論：已修正：該資料已改用多行 `LedgerOrder.fixture`
- L58 `FM14` 違規 — 多行參數的右括號沒有單獨一行 (腳本掃描)
    - 現況：`status: .cancelled),`
    - 結論：已修正：該測試已移至 `CustomerRowTests` 並依新呼叫格式排版
- L61 `FM14` 違規 — 多行參數的右括號沒有單獨一行 (腳本掃描)
    - 現況：`mergedSourceIDs: ["sourceA", "sourceB"]),`
    - 結論：已修正：該測試已移至 `CustomerRowTests` 並依新呼叫格式排版
- L64 `FM14` 違規 — 多行參數的右括號沒有單獨一行 (腳本掃描)
    - 現況：`status: .confirmed),`
    - 結論：已修正：該測試已移至 `CustomerRowTests` 並依新呼叫格式排版
- L67 `FM14` 違規 — 多行參數的右括號沒有單獨一行 (腳本掃描)
    - 現況：`status: .confirmed),`
    - 結論：已修正：該測試已移至 `CustomerRowTests` 並依新呼叫格式排版
- L70 `S·一個測試檔測多個型別` 違規 — 一個測試檔測多個型別 (審查員判讀)
    - 問題：第 53、76 行的測試直接測 `CustomerRow.aggregate`，而不是 `CustomersFeature`
    - 修法：搬到 `CustomerRowTests.swift`，或改成透過 `CustomersFeature.State(orders:).customers` 驗證
    - 結論：已修正：兩條直接測 `CustomerRow.aggregate` 的測試已搬到 `CustomerRowTests`
- L76 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func customerWithOnlyCancelledOrdersRemainsListedWithZeroSpend() {`
    - 結論：已修正：該 aggregate 測試已移至 `CustomerRowTests` 並補上 doc comment
- L76 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func customerWithOnlyCancelledOrdersRemainsListedWithZeroSpend() {`
    - 結論：已修正：該測試已移至 `CustomerRowTests` 並補齊 Given、When、Then
- L80 `FM14` 違規 — 多行參數的右括號沒有單獨一行 (腳本掃描)
    - 現況：`status: .cancelled)`
    - 結論：已修正：該測試已移至 `CustomerRowTests` 並依新呼叫格式排版
- L89 `S·doc comment 與測試行為不符` 違規 — doc comment 與測試行為不符 (審查員判讀)
    - 問題：說明是「驗證客戶點選只送出 delegate」，實際是直接送出 `.delegate(.customerTapped)`，完全沒有驗證點選會產生 delegate
    - 修法：送出 view 層的點選 action，再以 case key path `receive(.delegate.customerTapped)`；若只想驗證 delegate 不改 state，就改寫說明與名稱
    - 結論：已修正：測試改送 `.view(.customerTapped)`，並以 delegate case key path 收結果
- L90 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func customerTappedDelegateMutatesNoState() async {`
    - 結論：已修正：客戶點選測試已明列 Given、When、Then
- L98 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Helper`
    - 結論：已修正：helper 分區已改為允許的 `Private Method`
- L109 `S·Fixture 不叫 fixture 且參數無預設值` 違規 — Fixture 不叫 fixture 且參數無預設值 (審查員判讀)
    - 問題：`makeOrder` 手刻完整 `LedgerOrder`，`id`、`customer`、`charged`、`date` 都沒有預設值
    - 修法：改用共用的 `LedgerOrder.fixture(...)`
    - 結論：已修正：`makeOrder` 已刪除，測試資料改用共用 `LedgerOrder.fixture`
- L160 `O3` 必擋 — 強制解包 ! 左側含變數 (腳本掃描)
    - 現況：`return calendar.date(from: DateComponents(year: year, month: month, day: day))!`
    - 結論：已修正：日期 helper 改用 guard 處理建立失敗，不再強制解包

### BuyLedgerTests/FxFeatureTests.swift

共 22 筆 (必擋 9、違規 13、建議 0、已登記例外 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  FxFeatureTests.swift | //  BuyLedgerTests | // | //  Created by Leo Ho on 2026/5/2. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L11 `IM2` 違規 — @testable import 前缺空行 (腳本掃描)
    - 現況：`@testable import BuyLedger`
    - 結論：已修正：`@testable import` 前補空行
- L19 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func defaultStateUsesKrwAt150K() {`
    - 結論：已修正：測試方法補上正體中文 doc comment
- L19 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func defaultStateUsesKrwAt150K() {`
    - 結論：已修正：測試本體補齊 Given／When／Then 區段
- L19 `S·測試命名格式` 違規 — 測試命名格式 (審查員判讀)
    - 問題：9 個測試皆未依「行為_情境_預期」命名
    - 修法：改名如 `fromCurrency_whenChangedToJPY_recomputesRateFromSnapshot`
    - 結論：依使用者 2026-09-21 裁決不修：測試方法維持單段 lowerCamel，差異登記於 `apps/ios/CLAUDE.md` 的「ios-dev-kit 規範與既有差異」
- L26 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func defaultStateHasNoSnapshotAndNilRate() {`
    - 結論：已修正：測試方法補上正體中文 doc comment
- L26 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func defaultStateHasNoSnapshotAndNilRate() {`
    - 結論：已修正：測試本體補齊 Given／When／Then 區段
- L34 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func switchingCurrencyRecomputesRateFromSnapshot() async {`
    - 結論：已修正：測試方法補上正體中文 doc comment
- L34 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func switchingCurrencyRecomputesRateFromSnapshot() async {`
    - 結論：已修正：測試本體補齊 Given／When／Then 區段
- L37 `S·測試無法區分宣稱的行為` 違規 — 測試無法區分宣稱的行為 (審查員判讀)
    - 問題：註解與名稱宣稱「使用 snapshot 匯率、不使用 fallback」，但注入的 snapshot 就是 `FxRateSnapshot.fallback`，實作改讀 fallback 仍會通過；預期值又以與實作相同的 `Decimal(1) / $0` 算出 (L63、L106 同型)
    - 修法：注入與 fallback 不同的自訂 snapshot (如 JPY 0.2)，預期匯率與換算金額寫死數字
    - 結論：已修正：改用與 fallback 不同的自訂快照，並以固定數字 5 與 750,000 斷言
- L51 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func quickAmountTappedReplacesAmount() async {`
    - 結論：已修正：測試方法補上正體中文 doc comment
- L51 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func quickAmountTappedReplacesAmount() async {`
    - 結論：已修正：測試本體補齊 Given／When／Then 區段
- L61 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func bindingAmountUpdatesConvertedTwd() async {`
    - 結論：已修正：測試方法補上正體中文 doc comment，並同步名稱為 `bindingAmountUpdatesConvertedTWD`
- L61 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func bindingAmountUpdatesConvertedTwd() async {`
    - 結論：已修正：測試本體補齊 Given／When／Then 區段
- L76 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func displayRateForTwdAlwaysReturnsOneEvenWithoutSnapshot() {`
    - 結論：已修正：測試方法補上正體中文 doc comment
- L76 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func displayRateForTwdAlwaysReturnsOneEvenWithoutSnapshot() {`
    - 結論：已修正：測試本體補齊 Given／When／Then 區段
- L82 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func bindingTogglesCurrencySheet() async {`
    - 結論：已修正：原有 Bool sheet binding 測試改為 destination 流程測試並補上 doc comment
- L82 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func bindingTogglesCurrencySheet() async {`
    - 結論：已修正：原有 Bool sheet binding 測試已移除，destination 測試補齊 Given／When／Then 區段
- L93 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func currencyPickerTappedShowsCurrencySheet() async {`
    - 結論：已修正：改測 `currencyPickerTappedPresentsDestination` 並補上 doc comment
- L93 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func currencyPickerTappedShowsCurrencySheet() async {`
    - 結論：已修正：destination 呈現測試補齊 Given／When／Then 區段
- L103 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func fromCurrencySelectedRecomputesRateFromSnapshot() async {`
    - 結論：已修正：改以 `currencySelected` 測試目的地關閉與幣別更新，並補上 doc comment
- L103 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func fromCurrencySelectedRecomputesRateFromSnapshot() async {`
    - 結論：已修正：幣別選取測試補齊 Given／When／Then 區段

### BuyLedgerTests/OllamaClientTests.swift

共 22 筆 (必擋 10、違規 11、建議 1、已登記例外 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  OllamaClientTests.swift | //  BuyLedgerTests | // | //  Created by Leo Ho on 2026/5/27. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L10 `IM2` 違規 — @testable import 前缺空行 (腳本掃描)
    - 現況：`@testable import BuyLedger`
    - 結論：已修正 (task 1.3)：`@testable import` 前已加入空行
- L15 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - parse(line:)`
    - 結論：已修正 (task 1.3)：測試已統一放在 `Tests` 分區
- L17 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func parseExtractsContentFromStreamingLine() {`
    - 結論：已修正 (task 1.3)：測試方法已補上正體中文 doc comment
- L17 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func parseExtractsContentFromStreamingLine() {`
    - 結論：已修正 (task 1.3)：測試本體已補齊 Given／When／Then
- L17 `S·測試命名未依「行為_情境_預期」` 違規 — 測試命名未依「行為_情境_預期」 (審查員判讀)
    - 問題：7 個 @Test 都沒有三段式底線命名
    - 修法：例如 `parse_blankLine_returnsNil`
    - 結論：依使用者 2026-09-21 裁決不修：測試方法維持單段 lowerCamel，差異登記於 `apps/ios/CLAUDE.md` 的「ios-dev-kit 規範與既有差異」
- L20 `S·Optional 結果未先 #require` 建議 — Optional 結果未先 #require (審查員判讀)
    - 問題：`parsed?.content` 在解析失敗時會讓兩個 `#expect` 都以 nil 比較，錯誤訊息不清楚
    - 修法：改為 `let parsed = try #require(OllamaClient.parse(line: line))`
    - 結論：已修正 (task 1.3)：解析結果先以 `try #require` 解包
- L25 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func parseMarksDoneOnFinalLine() {`
    - 結論：已修正 (task 1.3)：測試方法已補上正體中文 doc comment
- L25 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func parseMarksDoneOnFinalLine() {`
    - 結論：已修正 (task 1.3)：測試本體已補齊 Given／When／Then
- L33 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func parseTreatsMissingMessageAsEmptyContent() {`
    - 結論：已修正 (task 1.3)：測試方法已補上正體中文 doc comment
- L33 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func parseTreatsMissingMessageAsEmptyContent() {`
    - 結論：已修正 (task 1.3)：測試本體已補齊 Given／When／Then
- L40 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func parseReturnsNilForBlankLine() {`
    - 結論：已修正 (task 1.3)：空白與壞格式測試已合併並補上 doc comment
- L40 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func parseReturnsNilForBlankLine() {`
    - 結論：已修正 (task 1.3)：參數化測試本體已補齊 Given／When／Then
- L40 `S·同一邏輯多組輸入未參數化` 違規 — 同一邏輯多組輸入未參數化 (審查員判讀)
    - 問題：`parseReturnsNilForBlankLine` 與 `parseReturnsNilForMalformedLine` (第 45 行) 各自塞了兩組輸入
    - 修法：合併為 `@Test(arguments: ["   ", "", "this is not json", "{\"message\": "])`
    - 結論：已修正 (task 1.3)：空白與壞格式輸入已合併為 `@Test(arguments:)`
- L45 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func parseReturnsNilForMalformedLine() {`
    - 結論：已修正 (task 1.3)：原壞格式測試已由參數化測試涵蓋
- L45 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func parseReturnsNilForMalformedLine() {`
    - 結論：已修正 (task 1.3)：原壞格式測試已由參數化測試涵蓋
- L50 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - testValue`
    - 結論：已修正 (task 1.3)：測試已統一放在 `Tests` 分區
- L52 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func testValueThrowsWhenInvoked() async {`
    - 結論：已修正 (task 1.3)：測試方法已補上正體中文 doc comment
- L52 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func testValueThrowsWhenInvoked() async {`
    - 結論：已修正 (task 1.3)：測試本體已補齊 Given／When／Then
- L59 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - previewValue`
    - 結論：已修正 (task 1.3)：測試已統一放在 `Tests` 分區
- L61 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func previewValueStreamsCannedMarkdown() async throws(any Error) {`
    - 結論：已修正 (task 1.3)：測試方法已補上正體中文 doc comment
- L61 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func previewValueStreamsCannedMarkdown() async throws(any Error) {`
    - 結論：已修正 (task 1.3)：測試本體已補齊 Given／When／Then

### BuyLedgerTests/QuoteFeatureTests.swift

共 69 筆 (必擋 26、違規 41、建議 2、已登記例外 0)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  QuoteFeatureTests.swift | //  BuyLedgerTests | // | //  Created by Leo Ho on 2026/5/2. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L1 `FM4` 違規 — 單檔超過 300 行 (不含檔頭與空行) (腳本掃描)
    - 現況：`342 行`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L11 `IM2` 違規 — @testable import 前缺空行 (腳本掃描)
    - 現況：`@testable import BuyLedger`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L13 `S·doc comment 放在屬性之後` 建議 — doc comment 放在屬性之後 (審查員判讀)
    - 問題：`///` 寫在 `@MainActor` 之後
    - 修法：把 doc comment 移到 `@MainActor` 上方
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L19 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func defaultStateStartsAtZero() {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L19 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func defaultStateStartsAtZero() {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L19 `S·測試命名未依「行為_情境_預期」` 違規 — 測試命名未依「行為_情境_預期」 (審查員判讀)
    - 問題：19 個 @Test 都沒有三段式底線命名
    - 修法：例如 `suggestedTwd_margin25_roundsUpToNearestTen`
    - 結論：依使用者 2026-09-21 裁決不修：測試方法維持單段 lowerCamel，差異登記於 `apps/ios/CLAUDE.md` 的「ios-dev-kit 規範與既有差異」
- L32 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func costCalculationUsesRateAndCardFee() {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L32 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func costCalculationUsesRateAndCardFee() {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L50 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func costCalculationIsZeroWithoutSnapshot() {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L50 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func costCalculationIsZeroWithoutSnapshot() {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L51 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 沒有匯率資料時，衍生金額歸零並顯示提示。`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L63 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 國際運費以 TWD 計算，其他項目因匯率不可用而為零。`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L71 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func suggestedPriceRoundsUpToNearestTen() {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L71 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func suggestedPriceRoundsUpToNearestTen() {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L81 `S·註解與程式碼矛盾` 違規 — 註解與程式碼矛盾 (審查員判讀)
    - 問題：註解寫「1000 / 0.75 = 133.33」，但成本其實是 100 (第 82 行)，而且「真毛利」用詞不清
    - 修法：改為「成本 100 / (1 - 0.25) = 133.33，無條件進位到 140」
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L87 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func switchingCurrencyRecomputesItemTwd() async {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L87 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func switchingCurrencyRecomputesItemTwd() async {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L88 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 使用非零單價驗證匯率切換對 itemTwd 的影響。`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L97 `S·註解未用正體中文` 違規 — 註解未用正體中文 (審查員判讀)
    - 問題：`// TWD rate = 1, so itemTwd == itemPrice` 是英文註解 (第 185 行也一樣)
    - 修法：改為「新台幣匯率為 1，換算後金額等於原價」
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L101 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func bindingMarginUpdatesSuggestedPrice() async {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L101 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func bindingMarginUpdatesSuggestedPrice() async {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L125 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func negativeInputsClampToZeroOnBinding() async {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L125 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func negativeInputsClampToZeroOnBinding() async {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L153 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func bindingTogglesCurrencySheet() async {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L153 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func bindingTogglesCurrencySheet() async {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L154 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 幣別 sheet 狀態由 State 管理，binding 不受 clamp 影響。`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L164 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func currencyPickerTappedShowsSheet() async {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L164 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func currencyPickerTappedShowsSheet() async {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L175 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func fromCurrencySelectedUpdatesCurrencyAndRecomputesItemTwd() async {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L175 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func fromCurrencySelectedUpdatesCurrencyAndRecomputesItemTwd() async {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L189 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Gross Margin Formula`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L191 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func suggestedPriceMatchesGrossMarginFormulaExamples() throws(any Error) {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L191 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func suggestedPriceMatchesGrossMarginFormulaExamples() throws(any Error) {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L191 `S·同一邏輯多組輸入未參數化` 違規 — 同一邏輯多組輸入未參數化 (審查員判讀)
    - 問題：`suggestedPriceMatchesGrossMarginFormulaExamples` 在同一個測試內驗證毛利 0、30、50% 三組
    - 修法：改為 `@Test(arguments: [(0, 1_000), (30, 1_430), (50, 2_000)])`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L192 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 50% 目標毛利應得到 2 倍成本，區分毛利率與加成率公式。`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L199 `FM14` 違規 — 多行參數的右括號沒有單獨一行 (腳本掃描)
    - 現況：`fromCurrency: .twd, itemPrice: 1_000, targetMarginPercent: 30)`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L206 `FM14` 違規 — 多行參數的右括號沒有單獨一行 (腳本掃描)
    - 現況：`fromCurrency: .twd, itemPrice: 1_000, targetMarginPercent: 50)`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L211 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func targetMarginAtOrAboveOneHundredPercentYieldsNoPrice() async {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L211 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func targetMarginAtOrAboveOneHundredPercentYieldsNoPrice() async {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L212 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 100% 以上無法計算，三個結果都應隱藏，輸入值不夾住。`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L215 `FM14` 違規 — 多行參數的右括號沒有單獨一行 (腳本掃描)
    - 現況：`fromCurrency: .twd, itemPrice: 1_000, targetMarginPercent: 50)`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L227 `S·一個測試多組 When/Then` 違規 — 一個測試多組 When/Then (審查員判讀)
    - 問題：`targetMarginAtOrAboveOneHundredPercentYieldsNoPrice` 依序送出 100、150、80 三次 binding，每次都斷言
    - 修法：改為 `@Test(arguments: [(100, false), (150, false), (80, true)])`，每組只送一次 binding
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L236 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 超過 100% 時不顯示，並保留原輸入值。`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L252 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Decimal Precision`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L254 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func decimalTypeAvoidsBinaryFloatingPointDrift() {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L254 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func decimalTypeAvoidsBinaryFloatingPointDrift() {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L255 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// Decimal 應精確得到 0.3，避免 Double 的二進位誤差。`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L265 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func quoteCostAgreesWithOrderTotalCostForMatchingInputs() {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L265 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func quoteCostAgreesWithOrderTotalCostForMatchingInputs() {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L284 `S·測試方法內手刻完整 Model` 違規 — 測試方法內手刻完整 Model (審查員判讀)
    - 問題：`quoteCostAgreesWithOrderTotalCostForMatchingInputs` 在測試本體寫出完整的 `LedgerOrder`
    - 修法：改為 `LedgerOrder.fixture(itemCost:cardFeeRate:paymentFeeRate:chargedAmount:)`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L316 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func failedRateLoadExplainsReasonAndRetryRestoresContent() async {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L316 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func failedRateLoadExplainsReasonAndRetryRestoresContent() async {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L321 `FM1` 必擋 — 行寬超過 100 (腳本掃描)
    - 現況：`120 字元`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L335 `S·窮舉 receive 後的冗餘斷言` 建議 — 窮舉 receive 後的冗餘斷言 (審查員判讀)
    - 問題：`errorMessage` 已在 `receive` closure 內斷言過，第 335 行必定成立
    - 修法：刪除第 335 行，保留計算屬性 `rateUnavailableReason` 的斷言
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L354 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Rate Unavailable Reason`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L356 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func rateUnavailableReasonIsNilWhileLoading() {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L356 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func rateUnavailableReasonIsNilWhileLoading() {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L363 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func rateUnavailableReasonIsNilWhenRateIsUsable() {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L363 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func rateUnavailableReasonIsNilWhenRateIsUsable() {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L370 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func rateUnavailableReasonFallsBackToGenericMessageWithoutAnErrorMessage() {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L370 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func rateUnavailableReasonFallsBackToGenericMessageWithoutAnErrorMessage() {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L382 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func rateRefreshRequestedIsNoOpWhileAlreadyLoading() async {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L382 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func rateRefreshRequestedIsNoOpWhileAlreadyLoading() async {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L392 `FM16` 違規 — // MARK: 前後缺空行 (腳本掃描)
    - 現況：`// MARK: - Test Doubles`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L392 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Test Doubles`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L394 `S·同檔輔助型別應為 nested type` 違規 — 同檔輔助型別應為 nested type (審查員判讀)
    - 問題：`QuoteRateClientStub` 是頂層 private actor
    - 修法：移進 `QuoteFeatureTests` 的 Nested Types extension
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L396 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`private(set) var callCount = 0`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認
- L402 `MK5` 必擋 — 型別本體內出現方法或 computed property (應放 extension) (腳本掃描)
    - 現況：`func fetchLatest(_: CurrencyCode) async throws(APIError) -> FxRateSnapshot {`
    - 結論：已修正 (task 4.1)：測試已改寫並以 QuoteFeatureTests focused 20/20 通過結果確認

### BuyLedgerTests/SettingsFeatureTests.swift

共 39 筆 (必擋 16、違規 21、建議 1、已登記例外 1)

- L1 `H1` 違規 — 檔頭格式不符 (檔名、target、日期 YYYY/MM/DD) (腳本掃描)
    - 現況：`// | //  SettingsFeatureTests.swift | //  BuyLedgerTests | // | //  Created by Leo Ho on 2026/5/2. | //`
    - 結論：報告規則已被推翻，不修：`apps/ios/CLAUDE.md` 規定檔頭日期一律不補零 `YYYY/M/D`；實作時確認四行結構與日期格式後標記
- L11 `IM2` 違規 — @testable import 前缺空行 (腳本掃描)
    - 現況：`@testable import BuyLedger`
    - 結論：已修正，並以目前程式碼確認
- L19 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func defaultStateMatchesProductDefaults() {`
    - 結論：已修正，並以目前程式碼確認
- L19 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func defaultStateMatchesProductDefaults() {`
    - 結論：已修正，並以目前程式碼確認
- L19 `S·測試命名未依「行為_情境_預期」` 違規 — 測試命名未依「行為_情境_預期」 (審查員判讀)
    - 問題：14 個 @Test 都沒有三段式底線命名
    - 修法：例如 `binding_language_updatesAndSaves`
    - 結論：依使用者 2026-09-21 裁決不修：測試方法維持單段 lowerCamel，差異登記於 `apps/ios/CLAUDE.md` 的「ios-dev-kit 規範與既有差異」
- L29 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func appLanguageUsesSupportedLocaleIdentifiers() {`
    - 結論：已修正，並以目前程式碼確認
- L29 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func appLanguageUsesSupportedLocaleIdentifiers() {`
    - 結論：已修正，並以目前程式碼確認
- L29 `S·一個測試檔測多個型別` 違規 — 一個測試檔測多個型別 (審查員判讀)
    - 問題：第 29 至 49 行的 4 個測試測的是 `AppLanguage`，不是 `SettingsFeature`
    - 修法：搬到 `AppLanguageTests.swift`
    - 結論：已修正，並以目前程式碼確認
- L34 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func appLanguageProvidesMatchingLocale() {`
    - 結論：已修正，並以目前程式碼確認
- L34 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func appLanguageProvidesMatchingLocale() {`
    - 結論：已修正，並以目前程式碼確認
- L39 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func appLanguageTitlesUseLocalizedResources() {`
    - 結論：已修正，並以目前程式碼確認
- L39 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func appLanguageTitlesUseLocalizedResources() {`
    - 結論：已修正，並以目前程式碼確認
- L44 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func appLanguageStoredValueFallsBackToTraditionalChinese() {`
    - 結論：已修正，並以目前程式碼確認
- L44 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func appLanguageStoredValueFallsBackToTraditionalChinese() {`
    - 結論：已修正，並以目前程式碼確認
- L45 `S·同一邏輯多組輸入未參數化` 違規 — 同一邏輯多組輸入未參數化 (審查員判讀)
    - 問題：`appLanguageStoredValueFallsBackToTraditionalChinese` 在同一個測試內驗證 4 組儲存值
    - 修法：改為 `@Test(arguments: [(nil, .traditionalChinese), ("", .traditionalChinese), ...])`
    - 結論：已修正，並以目前程式碼確認
- L51 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func bindingUpdatesLanguageAndSaves() async {`
    - 結論：已修正，並以目前程式碼確認
- L51 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func bindingUpdatesLanguageAndSaves() async {`
    - 結論：已修正，並以目前程式碼確認
- L70 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func bindingUpdatesDefaultCurrency() async {`
    - 結論：已修正，並以目前程式碼確認
- L70 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func bindingUpdatesDefaultCurrency() async {`
    - 結論：已修正，並以目前程式碼確認
- L80 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func taskLoadsFromInjectedStorage() async {`
    - 結論：已修正，並以目前程式碼確認
- L80 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func taskLoadsFromInjectedStorage() async {`
    - 結論：已修正，並以目前程式碼確認
- L99 `D6` 違規 — 註解結尾加中文句號 (腳本掃描)
    - 現況：`// 等待 ˋavailableCurrenciesLoadedˋ，只驗證 storage 套用流程。`
    - 結論：已修正，並以目前程式碼確認
- L101 `TS2` 已登記例外 — TestStore 關閉 exhaustivity (腳本掃描)
    - 現況：`store.exhaustivity = .off  ← apps/ios/CLAUDE.md 已登記：既有 exhaustivity = .off 由 TestSuiteIntegrityTests 限制只減不增`
    - 結論：已登記例外 (`apps/ios/CLAUDE.md`「ios-dev-kit 規範與既有差異」)，不修
- L113 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func bindingTogglesUseAiSummaryAndSaves() async {`
    - 結論：已修正，並以目前程式碼確認
- L113 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func bindingTogglesUseAiSummaryAndSaves() async {`
    - 結論：已修正，並以目前程式碼確認
- L133 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func bindingUpdatesAiSummaryModelAndSaves() async {`
    - 結論：已修正，並以目前程式碼確認
- L133 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func bindingUpdatesAiSummaryModelAndSaves() async {`
    - 結論：已修正，並以目前程式碼確認
- L152 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func bindingTriggersStorageSave() async {`
    - 結論：已修正，並以目前程式碼確認
- L152 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func bindingTriggersStorageSave() async {`
    - 結論：已修正，並以目前程式碼確認
- L152 `S·重複的測試` 建議 — 重複的測試 (審查員判讀)
    - 問題：`bindingTriggersStorageSave` 與第 113 行的 `bindingTogglesUseAiSummaryAndSaves` 送出同一個 binding，驗證的也幾乎一樣
    - 修法：刪掉其中一個，或改用 `@Test(arguments:)` 涵蓋每一種 binding 欄位都會存檔
    - 結論：已修正，並以目前程式碼確認
- L172 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func enablingAppLockPersistsOnlyAfterAuthenticationSucceeds() async {`
    - 結論：已修正，並以目前程式碼確認
- L172 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func enablingAppLockPersistsOnlyAfterAuthenticationSucceeds() async {`
    - 結論：已修正，並以目前程式碼確認
- L198 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func disablingAppLockPersistsImmediatelyWithoutAuthentication() async {`
    - 結論：已修正，並以目前程式碼確認
- L198 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func disablingAppLockPersistsImmediatelyWithoutAuthentication() async {`
    - 結論：已修正，並以目前程式碼確認
- L219 `D1` 必擋 — 宣告缺 /// doc comment (腳本掃描)
    - 現況：`@Test func failedAppLockAuthenticationDoesNotPersist() async {`
    - 結論：已修正，並以目前程式碼確認
- L219 `TS3` 違規 — @Test 本體缺 Given / When / Then (腳本掃描)
    - 現況：`@Test func failedAppLockAuthenticationDoesNotPersist() async {`
    - 結論：已修正，並以目前程式碼確認
- L255 `C4` 必擋 — @unchecked Sendable (Mock 與包裝非 Sendable 第三方物件以外) (腳本掃描)
    - 現況：`private final class SnapshotBox: @unchecked Sendable {`
    - 結論：已修正：刪除 SnapshotBox，改用 `LockIsolated` 記錄存檔快照
- L255 `S·同檔輔助型別應為 nested type／替身記錄方式` 違規 — 同檔輔助型別應為 nested type／替身記錄方式 (審查員判讀)
    - 問題：`SnapshotBox` 是頂層 private class，說明「簡易 Sendable 容器」只描述型別特性，沒說用途
    - 修法：改用 `LockIsolated<SettingsSnapshot?>(nil)`，刪除這個型別
    - 結論：已修正，並以目前程式碼確認
- L257 `MK1` 必擋 — MARK 使用規範以外的分區名稱 (腳本掃描)
    - 現況：`// MARK: - Data Properties`
    - 結論：已修正：移除不需要的 Data Properties 分區

## Batch6 補充核對

- `Features/More/MoreView.swift`：7 處摘要與 `- Parameter`／`- Returns` 之間已補空的 `///`；結論：已修正並以目前原始碼確認
- `Features/Customers/CustomersView.swift`：5 處摘要與 `- Parameters`／`- Returns` 之間已補空的 `///`；結論：已修正並以目前原始碼確認
- `Features/Customers/CustomerRankBadgeStyle.swift`：3 處摘要與參數標記之間已補空的 `///`；結論：已修正並以目前原始碼確認
- `Features/Customers/CustomerRow.swift`：`Identifiable` protocol extension 已移到 `Internal Method` 之後、`Private Method` 之前的遵循順序；結論：已修正並以目前原始碼確認
- `BuyLedgerTests/AISummaryFeatureTests.swift`：6 個測試 doc comment 已改為各自描述實際行為，`missingKeyFailsImmediately` 已補 `// Then`；結論：已修正並以 focused unit 12/12 通過確認
- `BuyLedgerTests/ActionGroupingScanTests.swift`：兩條 production scan、Settings `.appLock(` allowlist、未使用條目失敗與 design 指定自我測試均已實作；結論：已修正並以 focused scan 綠燈及兩次 mutation 紅燈／還原綠燈確認
- `apps/ios/CLAUDE.md`：已登記單段 lowerCamel、同步設定寫入、父層 action 邊界、State 啟動資料與 delegate 溝通規則；結論：已修正並以文件內容核對
- `apps/ios/README.md`：`OllamaClient` 已改為 `Core/Networking/`、`SettingsStore` 名稱與 FX／Quote 元件目錄已同步；結論：已修正並以舊路徑 grep 無輸出確認
- `.claude/rules/ios-unit-tests.md`：已補 `LockIsolated`、禁止 `Task.yield` 輪詢與獨立 UserDefaults suite 規則；結論：已修正並以文件內容核對
- 最終驗證：完整 unit regression `totalTestCount` 753、通過 753、失敗 0，與 batch5 的 748 比較為 +5；結論：7.1 與 7.2 已完成，8.x 尚未開始

## Batch7 補充核對

- `Bundle.appVersionText`：已改名 `Bundle.appVersion`；`apps/ios` 舊名稱 grep 無輸出。第 9 批依使用者裁決再把 `appVersion(from:)` 內聯進該 computed property 並刪除 `BundleExtensionsTests.swift`；結論：已修正
- Customers、FX、Quote View：三處同值水平／垂直 padding 已各合併為 `.padding(BLSpacing.large)`，指定 snapshot、Bundle、Settings focused run 22/22 通過；結論：已修正
- `BuyLedgerTests/ActionGroupingScanTests.swift`：主檔保留 Properties 與 Tests，掃描 nested types 與 methods 移至 `ActionGroupingScanTests+Scanner.swift`，案例表於第 8 批再拆出 `ActionGroupingScanTests+Scenarios.swift`；三檔最終非空內容 132／243／81 行；結論：已修正並低於 300 行限制
- `BuyLedgerTests/ActionGroupingScanTests.swift`：三個 pattern 改為 Regex literal，掃描使用 `matches(of:)`／`firstMatch(of:)`，未保留 `NSRegularExpression`；結論：已修正並以 5/5 focused run 確認
- `BuyLedgerTests/ActionGroupingScanTests.swift`：Properties、Tests、Nested Types、Computed Properties、Private Method 順序已符合 review，nested type 內的 Properties MARK 已移除；結論：已修正
- doc comment：ActionGrouping 與 OllamaClientTests 現存參數標記前的空 `///` 已確認，CLAUDE.md 三條新增架構規則已補句號；結論：已修正
- mutation evidence：最終 Regex 版本的 FxView 暫時 `.binding(...)` 使 ActionGrouping 由 5/5 轉為 4/1，錯誤指出 `Features/FX/FxView.swift` 與 `.binding(.set(...))`；還原後 5/5；結論：守門有效且 mutation 已移除
- UI：`CustomersTests` 以 `BuyLedgerUITests` scheme 4/4 通過；結論：padding 合併未造成 UI 回歸
- 第 8 組尚未開始；本批只完成使用者 review comments 與第 6 批 review 修正
- tuple 修正前的中間完整 unit regression：`totalTestCount` 753、通過 753、失敗 0；結論：Regex 重構、Bundle 命名與三處 padding 合併未造成 unit 回歸。result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T01-45-30-549Z_pid91744_624776cc.xcresult`
- tuple 修正後的本批最終完整 unit regression：`totalTestCount` 753、通過 753、失敗 0；已知 `ordersCompactViewMultiSelectBaseline()` 單獨重跑 1/1 通過；結論：最終變更未造成 unit 回歸。result bundle：`/Users/leoho/Library/Developer/XcodeBuildMCP/workspaces/BuyLedger-61c22e57ebf6/result-bundles/test_sim_2026-09-23T01-50-33-470Z_pid96335_9088915a.xcresult`
