## 1. 先讓素材涵蓋產線實際走到的路徑

- [x] 1.1 讓 golden 素材涵蓋多字列舉 case，使命名缺陷第一次有測試標的：於 fixture schema 的列舉補上一個多字駝峰式 case，並更新三個語言的期望輸出。對應 spec requirement「Kotlin and TypeScript emitters are locked by golden-file tests」。驗證：補上素材後 Kotlin 的 golden 比對必須先變紅（證明缺陷確實存在且已被素材涵蓋），Swift 與 TypeScript 維持綠燈（shared/data-model/fixtures/schema/sample-enums.yaml）。
- [x] 1.2 讓 golden 素材涵蓋另外三條產線在用但無保護的路徑：自訂序列化的實體、字串與布林欄位預設值、整數基底的包裝型別，並建立對應的三語言期望輸出。驗證：以逐一註解掉 emitter 對應分支的方式確認每條路徑都會讓 golden 比對轉紅，驗畢還原（shared/data-model/fixtures/schema/sample-orders.yaml、shared/data-model/fixtures/expected/）。

## 2. 修正列舉命名轉換

- [x] 2.1 讓多字列舉 case 在 Kotlin 產出符合該平台命名慣例，且宣告與預設值共用同一份轉換：新增一個分詞轉換函式並在兩處呼叫，取代目前各自寫一次的直接大寫化。對應 spec requirement「Enum constants follow each target platform's naming convention」。驗證：1.1 的 golden 比對轉綠；新增單元測試斷言單字、雙字與三字 case 的轉換結果，以及「宣告與列舉預設值產出同一個常數名」（shared/data-model/generator/src/datamodel-gen.ts）。
- [x] 2.2 確認 Swift 產出完全不受此次轉換影響：Swift 的列舉 case 沿用 schema 的原始名稱。驗證：Swift golden 檔在本次全程無差異，且產線漂移檢查退出碼為 0。

## 3. 把註解規範由自律改為測試強制

- [x] 3.1 讓 schema 註解出現平台專屬用詞時測試失敗：新增測試掃描所有 schema 的說明文字，比對一份平台語言、框架與型別建構的詞彙清單。對應 spec requirement「Schema vocabulary is platform-neutral」。驗證：暫時在任一 schema 註解加入一個平台專屬詞可讓測試轉紅，驗畢還原（shared/data-model/generator/test/datamodel-gen.test.ts）。
- [x] 3.2 讓 schema 註解使用破折號時測試失敗：新增對應斷言。驗證：暫時在任一 schema 註解加入破折號可讓測試轉紅，驗畢還原。

## 4. 文件與驗收

- [x] 4.1 讓跨平台資料模型說明記錄兩條新守門與素材涵蓋規則：素材必須涵蓋產線實際使用的所有 emit 路徑、註解中立性與標點規範已由測試強制。驗證：說明文件可搜尋到對應段落（shared/data-model/README.md）。
- [x] 4.2 執行整體驗收：generator 測試全綠、型別檢查通過、產線漂移檢查退出碼為 0，且工作樹沒有任何產線生成檔差異。驗證：三個指令各自退出碼為 0，並以工作樹狀態確認產線生成檔未被本變更改動。

## 5. QA 論證精確度修正（修正輪）

- [x] 5.1 修正 fixture 檔頭與 proposal.md Why／What Changes 對「產線在用」的失實宣稱：改為區分「對應產線既有形狀」（多字 enum case、自訂序列化實體）與「純為補齊 emitter 分支覆蓋」（字串／布林預設值、整數基底 wrapper，產線目前未使用）。驗證：兩處文字皆可對照 12 份產線 schema 逐一查證（shared/data-model/fixtures/schema/sample-orders.yaml、openspec/changes/codegen-emitter-and-fixture-gaps/proposal.md）。
- [x] 5.2 修正測試名稱中的裸全形破折號：`說明文字不含全形破折號 —` 改為 `說明文字不含全形破折號`，字串內不再放裸字元（shared/data-model/generator/test/datamodel-gen.test.ts）。
- [x] 5.3 修正反向缺口：新增「產線 trait 組合鏡射守門」測試，掃描 schema/ 每個型別的 (kind, traits, serialization) 組合，斷言 fixtures/schema 皆有對應鏡射；並新增 fixture 檔補齊當時缺漏的四種組合（含 spec 新場景點名的 CustomerTier 與 PaymentMethodInfo 兩種）。對應 spec requirement「Production path missing from the fixture is a coverage defect」。驗證：移除 SamplePreference（對應 PaymentMethodInfo 組合）後守門確實轉紅並精確點名該組合與型別，還原後轉綠（shared/data-model/generator/test/datamodel-gen.test.ts、shared/data-model/fixtures/schema/sample-trait-matrix.yaml、shared/data-model/fixtures/expected/）。
- [x] 5.4 修正 README 小節階層錯置：`golden 素材的涵蓋規則` 改為獨立 `##` 標題（不再巢狀於「漂移由測試與 CI 強制」之下），使本案與 minimal-ci-and-test-plans 的內容各自獨立提交時結構皆正確；並修正「指出違規的 schema 檔案」為「指出違規的型別／欄位」以符合測試實際輸出（shared/data-model/README.md）。
- [x] 5.5 把兩條新硬規則回寫 root CLAUDE.md：擴充「schema 註解保持平台中立」條目，註明中立性與破折號規範已由 generator 測試強制、並點出用詞黑名單為整詞比對含泛用字的 gotcha；新增「golden 素材須涵蓋產線實際使用的 emit 路徑」條目，細節導向 shared/data-model/README.md（CLAUDE.md）。
- [x] 5.6 修正其餘精確度問題：datamodel-gen.ts 多行註解換行處誤帶的中文句號、測試檔 MARK 註解與另一已封存變更的 task 編號撞號、proposal.md Impact 誤植的檔名（shared/data-model/generator/src/datamodel-gen.ts、shared/data-model/generator/test/datamodel-gen.test.ts、openspec/changes/codegen-emitter-and-fixture-gaps/proposal.md）。
- [x] 5.7 重新執行整體驗收：`bun test`（52 pass / 0 fail）、`bun run check`、`bunx tsc --noEmit` 皆 exit 0，且工作樹除本案與其餘五案既有變更外無新增產線生成檔漂移。
