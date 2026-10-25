#!/usr/bin/env python3
"""test-extension-split 的驗收檢查 (只讀，不改檔)

用法：在 repo 根目錄執行 `python3 -I openspec/changes/test-extension-split/reference/check_test_extensions.py [--phase1]`

檢查項目：
1. 測試 target 內含 `+` 的檔案只剩保留清單
2. 測試 target 自己宣告的型別沒有被其他檔案 extension
3. 測試函式總數與基準相同
4. 快照基準圖目錄都改成 `Snapshot<X>Tests`，且每個目錄都有同名測試檔
5. file-list.tsv 的每一列都已落地 (來源檔已移除；split-test、guard-type、page-object 的目標檔存在且宣告目標型別)

另檢查拆分前的測試型別不再被其他檔案族群以 `<型別>.<成員>` 引用 (共用 helper 不留在測試型別上)；
`--phase1` 只做這一項，供共用 helper 階段驗收
"""

import csv
import os
import re
import sys

IOS = "apps/ios"
UNIT = os.path.join(IOS, "BuyLedgerTests")
UI = os.path.join(IOS, "BuyLedgerUITests")
SNAP = os.path.join(UNIT, "SnapshotTests", "__Snapshots__")
LIST = "openspec/changes/test-extension-split/reference/file-list.tsv"

KEEP = {
    "Campaign+Fixture.swift",
    "LedgerOrder+Fixture.swift",
    "LedgerOrder+TestSupport.swift",
    "LookupCatalog+TestIsolation.swift",
    "String+SourceLiteralScan.swift",
}
# 數量依 tasks.md 的 8.1 與 8.2 逐輪拆分紀錄更新；這是宣告數，不是參數化展開後的執行數
BASELINE = {"unit @Test": 1804, "unit XCTest func": 8, "UI XCTest func": 140, "snapshot png": 74}

DECL = re.compile(r"^(?:@[\w.]+(?:\([^)]*\))?\s+)*(?:(?:public|internal|private|fileprivate|final|nonisolated)\s+)*(?:struct|class|enum|actor|protocol)\s+(\w+)", re.M)
EXT = re.compile(r"^(?:(?:public|internal|private|fileprivate|nonisolated)\s+)*extension\s+([\w.]+)", re.M)


def swift_files(*roots):
    for root in roots:
        for d, _, fs in os.walk(root):
            for f in fs:
                if f.endswith(".swift"):
                    p = os.path.join(d, f)
                    with open(p, encoding="utf-8") as h:
                        yield p, h.read()


def main():
    phase1 = "--phase1" in sys.argv
    failures = []
    files = dict(swift_files(UNIT, UI))

    rows = list(csv.DictReader(open(LIST, encoding="utf-8"), delimiter="\t"))
    producers = {r["family"] for r in rows if r["family"].endswith("Tests")}
    # Guards 之間的共用掃描型別由 2.10、2.11 處理，不屬於共用 helper 階段
    guard_producers = {r["family"] for r in rows if "/Guards/" in r["source"]}
    for p, s in files.items():
        fam = os.path.basename(p)[:-6].split("+")[0]
        for b in producers:
            if b == fam or (phase1 and b in guard_producers):
                continue
            for m in re.findall(r"\b" + re.escape(b) + r"\.(\w+)", s):
                if m != "swift":
                    failures.append(f"跨型別引用 {b}.{m}：{p}")
    if phase1:
        report(failures, "共用 helper 階段")
        return

    plus = sorted(os.path.basename(p) for p in files if "+" in os.path.basename(p))
    extra = [f for f in plus if f not in KEEP]
    if extra:
        failures.append(f"仍有 {len(extra)} 個 + 分檔：{', '.join(extra[:20])}")

    declared = {}
    for p, s in files.items():
        for t in DECL.findall(s):
            declared.setdefault(t, set()).add(p)
    for p, s in files.items():
        for t in EXT.findall(s):
            t = t.split(".")[0]
            if t in declared and p not in declared[t]:
                failures.append(f"跨檔 extension {t}：{p}")

    counts = {
        "unit @Test": sum(len(re.findall(r"@Test\b", s)) for p, s in files.items() if p.startswith(UNIT)),
        "unit XCTest func": sum(len(re.findall(r"func test[A-Za-z_]", s)) for p, s in files.items() if p.startswith(UNIT) and "import XCTest" in s),
        "UI XCTest func": sum(len(re.findall(r"func test[A-Za-z_]", s)) for p, s in files.items() if p.startswith(UI)),
        "snapshot png": sum(1 for d, _, fs in os.walk(SNAP) for f in fs if f.endswith(".png")),
    }
    for k, v in BASELINE.items():
        if counts[k] != v:
            failures.append(f"{k} 數量 {counts[k]}，基準 {v}")

    for d in sorted(os.listdir(SNAP)):
        if not os.path.isdir(os.path.join(SNAP, d)):
            continue
        if not re.fullmatch(r"Snapshot\w+Tests", d):
            failures.append(f"快照目錄未改名：{d}")
        elif not os.path.exists(os.path.join(UNIT, "SnapshotTests", d + ".swift")):
            failures.append(f"快照目錄沒有同名測試檔：{d}")

    for r in rows:
        src = os.path.join(IOS, r["source"])
        if r["action"] == "keep":
            if not os.path.exists(src):
                failures.append(f"保留檔被移除：{r['source']}")
            continue
        if os.path.exists(src):
            failures.append(f"來源檔仍存在：{r['source']}")
        if r["action"] in ("split-test", "guard-type", "page-object"):
            target = os.path.join(IOS, r["target_file"])
            if not os.path.exists(target):
                # guard-type 依使用範圍可能移到 Guards/Scanning
                alt = os.path.join(UNIT, "Guards", "Scanning", os.path.basename(r["target_file"]))
                target = alt if os.path.exists(alt) else None
            if target is None:
                failures.append(f"目標檔不存在：{r['target_file']}")
            elif r["target_type"] not in DECL.findall(files.get(target, open(target, encoding="utf-8").read())):
                failures.append(f"{target} 未宣告 {r['target_type']}")

    print("數量：" + "、".join(f"{k} {v}" for k, v in counts.items()))
    report(failures, "全部")


def report(failures, label):
    if failures:
        print(f"[{label}] {len(failures)} 項未通過")
        for f in failures:
            print("  - " + f)
        sys.exit(1)
    print(f"[{label}] 通過")


if __name__ == "__main__":
    main()
