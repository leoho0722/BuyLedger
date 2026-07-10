import { describe, test, expect } from "bun:test";
import { mkdtempSync, writeFileSync, rmSync, readFileSync, chmodSync, statSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  loadSchemaDir,
  loadConfig,
  buildModel,
  buildModelFromRaw,
  parseTypeExpr,
  parseRawType,
  emitType,
  planGeneration,
  generate,
  check,
  unlock,
  SchemaError,
  type Model,
  type TypeDecl,
} from "../src/datamodel-gen.ts";

const HERE = import.meta.dir;
const PROD_SCHEMA = join(HERE, "../../schema");
const PROD_CONFIG = join(HERE, "../../codegen.yaml");
const FIX_SCHEMA = join(HERE, "../../fixtures/schema");
const FIX_CONFIG = join(HERE, "../../fixtures/codegen.yaml");

// 測試用：最小合法 entity，可用 over 覆寫欄位
function entity(over: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    name: "E",
    kind: "entity",
    doc: "doc",
    traits: [],
    fields: [{ name: "id", type: "string", doc: "id doc" }],
    ...over,
  };
}

function findType(model: Model, name: string): TypeDecl {
  const t = model.byName.get(name);
  if (!t) throw new Error(`型別 ${name} 不存在`);
  return t;
}

function swiftOf(model: Model, name: string): string {
  return emitType("swift", findType(model, name), {});
}

// MARK: - 目錄合併載入 (task 3.1)

describe("目錄合併載入", () => {
  test("fixture 目錄依檔名排序串接，跨檔引用解析正確", () => {
    const model = buildModelFromRaw(loadSchemaDir(FIX_SCHEMA));
    // sample-enums.yaml 先於 sample-orders.yaml (檔名排序)
    expect(model.types.map((t) => t.name)).toEqual([
      "SampleStatus",
      "SampleTag",
      "SampleOrder",
      "SampleMetadata",
    ]);
    // SampleOrder 跨檔引用 SampleStatus / SampleTag 應解析成功 (buildModel 不拋錯即代表通過)
    const order = findType(model, "SampleOrder");
    expect(order.kind).toBe("entity");
  });

  test("正式 schema 目錄載入為 12 型別、7 entity + 4 enum + 1 wrapper", () => {
    const model = buildModel(loadSchemaDir(PROD_SCHEMA), 1);
    expect(model.types).toHaveLength(12);
    const kinds = model.types.reduce<Record<string, number>>((acc, t) => {
      acc[t.kind] = (acc[t.kind] ?? 0) + 1;
      return acc;
    }, {});
    expect(kinds).toEqual({ entity: 7, enum: 4, wrapper: 1 });
    // 跨檔引用：LedgerOrder 參考 5 種其他型別，解析不拋錯
    for (const name of [
      "LedgerOrder",
      "LedgerCustomer",
      "OrderStatus",
      "CurrencyCode",
      "PaymentReceiptStatus",
    ]) {
      expect(model.byName.has(name)).toBe(true);
    }
  });

  test("型別名與 apps/ios Swift Domain 1:1 對應", () => {
    const model = buildModel(loadSchemaDir(PROD_SCHEMA), 1);
    expect(new Set(model.types.map((t) => t.name))).toEqual(
      new Set([
        "LedgerOrder",
        "LedgerOrderItem",
        "LedgerCustomer",
        "Campaign",
        "Money",
        "PaymentMethodInfo",
        "FxRateSnapshot",
        "OrderStatus",
        "CampaignStatus",
        "PaymentReceiptStatus",
        "CustomerTier",
        "CurrencyCode",
      ]),
    );
  });
});

// MARK: - 型別文法 parser (task 3.2)

describe("型別文法 parser", () => {
  test.each([
    ["string", { kind: "base", name: "string" }],
    ["date", { kind: "base", name: "date" }],
    ["array<LedgerOrderItem>", { kind: "array", element: { kind: "ref", name: "LedgerOrderItem" } }],
    [
      "map<CurrencyCode, decimal>",
      { kind: "map", key: { kind: "ref", name: "CurrencyCode" }, value: { kind: "base", name: "decimal" } },
    ],
    ["PaymentReceiptStatus", { kind: "ref", name: "PaymentReceiptStatus" }],
  ])("解析 %s", (input, expected) => {
    expect(parseTypeExpr(input as string, "ctx")).toEqual(expected as never);
  });

  test("型別字串含 ? 視為錯誤", () => {
    expect(() => parseTypeExpr("date?", "Campaign.closeDate")).toThrow(SchemaError);
    expect(() => parseTypeExpr("array<date?>", "ctx")).toThrow(/\?/);
  });

  test("不完整或多餘符號報錯", () => {
    expect(() => parseTypeExpr("array<", "ctx")).toThrow(SchemaError);
    expect(() => parseTypeExpr("map<string>", "ctx")).toThrow(SchemaError);
    expect(() => parseTypeExpr("string extra", "ctx")).toThrow(SchemaError);
  });
});

// MARK: - 驗證規則表 (task 4.2 / spec「Schema validation rejects malformed declarations」)

describe("驗證規則表", () => {
  test("重複型別名 → error", () => {
    expect(() =>
      buildModelFromRaw([
        { name: "Campaign", kind: "enum", doc: "d", cases: [{ name: "a", doc: "d" }] },
        { name: "Campaign", kind: "enum", doc: "d", cases: [{ name: "b", doc: "d" }] },
      ]),
    ).toThrow(/重複的型別名/);
  });

  test("entity 有 identity 但缺 id 欄位 → error", () => {
    expect(() =>
      parseRawType(entity({ traits: ["identity"], fields: [{ name: "x", type: "string", doc: "d" }] })),
    ).toThrow(/identity/);
  });

  test("serializable 與 serialization: custom 互斥 → error", () => {
    expect(() => parseRawType(entity({ traits: ["serializable"], serialization: "custom" }))).toThrow(
      /互斥/,
    );
  });

  test("default 參考不存在的 enum case → error", () => {
    expect(() =>
      buildModelFromRaw([
        { name: "S", kind: "enum", doc: "d", cases: [{ name: "confirmed", doc: "d" }] },
        entity({
          name: "E",
          fields: [
            { name: "id", type: "string", doc: "d" },
            { name: "s", type: "S", doc: "d", default: "S.unknown" },
          ],
        }),
      ]),
    ).toThrow(/不存在的 enum case/);
  });

  test("未知 trait → error", () => {
    expect(() => parseRawType(entity({ traits: ["frobnicatable"] }))).toThrow(SchemaError);
  });

  test("未知 kind → error", () => {
    expect(() => parseRawType({ name: "X", kind: "widget", doc: "d" })).toThrow(SchemaError);
  });

  test("未宣告的型別引用 → error", () => {
    expect(() =>
      buildModelFromRaw([
        entity({ fields: [{ name: "id", type: "string", doc: "d" }, { name: "x", type: "array<Nope>", doc: "d" }] }),
      ]),
    ).toThrow(/未宣告的型別 Nope/);
  });

  test("型別內重複欄位名 → error", () => {
    expect(() =>
      parseRawType(
        entity({
          fields: [
            { name: "id", type: "string", doc: "d" },
            { name: "dup", type: "string", doc: "d" },
            { name: "dup", type: "int", doc: "d" },
          ],
        }),
      ),
    ).toThrow(/重複欄位名/);
  });

  test("未知欄位鍵 (strictObject) → error", () => {
    expect(() =>
      parseRawType(entity({ fields: [{ name: "id", type: "string", doc: "d", bogus: 1 }] })),
    ).toThrow(SchemaError);
  });
});

// MARK: - 中立 trait 對應 (task 3.3 / spec「Schema vocabulary is platform-neutral」)

describe("中立 trait 對應三平台", () => {
  const model = buildModelFromRaw(loadSchemaDir(FIX_SCHEMA));

  test("value-equality → Swift Equatable / Kotlin data class / TS interface", () => {
    expect(swiftOf(model, "SampleOrder")).toContain("Equatable");
    expect(emitType("kotlin", findType(model, "SampleOrder"), {})).toContain("data class SampleOrder");
    expect(emitType("typescript", findType(model, "SampleOrder"), {})).toContain("export interface SampleOrder");
  });

  test("serializable → Swift Codable；identity → Swift Identifiable；case-iterable → Swift CaseIterable", () => {
    expect(swiftOf(model, "SampleOrder")).toContain("Codable");
    expect(swiftOf(model, "SampleOrder")).toContain("Identifiable");
    expect(swiftOf(model, "SampleStatus")).toContain("CaseIterable");
  });

  test("hashable → Swift Hashable；TS 以明確分支忽略 (不報錯、無 hashable 產物)", () => {
    expect(swiftOf(model, "SampleTag")).toContain("Hashable");
    const ts = emitType("typescript", findType(model, "SampleTag"), {});
    expect(ts).toContain("export type SampleTag = string;");
    expect(ts.toLowerCase()).not.toContain("hashable");
  });

  test("serialization: custom → Swift 生成宣告不含 Codable", () => {
    expect(swiftOf(model, "SampleTag")).not.toContain("Codable");
  });
});

// MARK: - Swift 全域 Sendable 注入 (task 3.4)

describe("Swift 全域 Sendable 注入", () => {
  const model = buildModelFromRaw(loadSchemaDir(FIX_SCHEMA));

  test("不列任何 trait 的 entity 仍獲 Sendable", () => {
    const swift = swiftOf(model, "SampleMetadata");
    expect(swift).toContain("struct SampleMetadata: Sendable {");
  });

  test("enum 即使 schema 無 sendable trait 仍獲 Sendable", () => {
    expect(swiftOf(model, "SampleStatus")).toMatch(/enum SampleStatus: String,.*Sendable \{/);
  });

  test("schema 從不出現 sendable 字樣 (Sendable 是 emitter 政策、非 trait)", () => {
    const order = parseRawType(loadSchemaDir(FIX_SCHEMA).find((t) => t.name === "SampleOrder") as never);
    expect(JSON.stringify(order).toLowerCase()).not.toContain("sendable");
  });
});

// MARK: - nullable / default emit 規則 (task 3.5 / spec default 解析表)

describe("nullable / default 解析表", () => {
  const model = buildModelFromRaw(loadSchemaDir(FIX_SCHEMA));
  const order = swiftOf(model, "SampleOrder");

  test("false + 無 default → 必填參數 (無 = 零值)", () => {
    expect(order).toContain("rate: Decimal,");
    expect(order).not.toMatch(/rate: Decimal = /);
  });

  test("false + default 0 → = 0", () => {
    expect(order).toContain("quantity: Int = 0,");
  });

  test("true + 無 default → = nil (顯式 init 補 nil)", () => {
    expect(order).toContain("closeDate: Date? = nil,");
    expect(order).toContain("payload: Data? = nil,");
  });

  test("false + $newUUID → = UUID()", () => {
    expect(order).toContain("itemId: UUID = UUID(),");
  });

  test("enum case default → = .active", () => {
    expect(order).toContain("status: SampleStatus = .active,");
  });

  test("無 nullable、無 default 的 entity 不產生顯式 init (沿用合成 memberwise)", () => {
    const meta = swiftOf(model, "SampleMetadata");
    expect(meta).not.toContain("init(");
  });
});

// MARK: - 跨語言型別映射表 (spec「cross-language type mapping」)

describe("跨語言型別映射表", () => {
  const model = buildModelFromRaw(loadSchemaDir(FIX_SCHEMA));
  const sw = swiftOf(model, "SampleOrder");
  const kt = emitType("kotlin", findType(model, "SampleOrder"), {});
  const ts = emitType("typescript", findType(model, "SampleOrder"), {});

  test("decimal", () => {
    expect(sw).toContain("rate: Decimal");
    expect(kt).toContain("rate: java.math.BigDecimal");
    expect(ts).toContain("rate: DecimalString");
  });
  test("date", () => {
    expect(sw).toContain("createdAt: Date");
    expect(kt).toContain("createdAt: java.time.Instant");
    expect(ts).toContain("createdAt: ISODateString");
  });
  test("data", () => {
    expect(sw).toContain("payload: Data?");
    expect(kt).toContain("payload: ByteArray?");
    expect(ts).toContain("payload?: Base64String | null");
  });
  test("array<T>", () => {
    expect(sw).toContain("tags: [SampleTag]");
    expect(kt).toContain("tags: List<SampleTag>");
    expect(ts).toContain("tags: SampleTag[]");
  });
  test("map<K, V>", () => {
    expect(sw).toContain("rates: [SampleTag: Decimal]");
    expect(kt).toContain("rates: Map<SampleTag, java.math.BigDecimal>");
    expect(ts).toContain("rates: Record<SampleTag, DecimalString>");
  });
  test("enum / wrapper / entity 容器形狀", () => {
    expect(swiftOf(model, "SampleStatus")).toContain("enum SampleStatus: String");
    expect(emitType("kotlin", findType(model, "SampleStatus"), {})).toContain("enum class SampleStatus");
    expect(emitType("typescript", findType(model, "SampleStatus"), {})).toContain("export type SampleStatus =");
    expect(emitType("kotlin", findType(model, "SampleTag"), {})).toContain("value class SampleTag");
  });
});

// MARK: - golden 鎖定 (task 4.1 / spec「Kotlin and TypeScript emitters are locked by golden-file tests」)

describe("golden 鎖定", () => {
  test("fixture 三語言 golden 與目前 emitter 輸出逐 byte 一致", () => {
    const result = check({ schemaDir: FIX_SCHEMA, configPath: FIX_CONFIG });
    if (!result.inSync) {
      throw new Error(`golden 漂移：${result.drifted.map((d) => `[${d.reason}] ${d.absPath}`).join(", ")}`);
    }
    expect(result.inSync).toBe(true);
  });

  test("fixture 涵蓋三種語言各 4 檔", () => {
    const { files } = planGeneration({ schemaDir: FIX_SCHEMA, configPath: FIX_CONFIG });
    const byLang = files.reduce<Record<string, number>>((acc, f) => {
      acc[f.language] = (acc[f.language] ?? 0) + 1;
      return acc;
    }, {});
    expect(byLang).toEqual({ swift: 4, kotlin: 4, typescript: 4 });
  });
});

// MARK: - 決定性 (spec「Regenerating produces identical bytes」)

describe("決定性", () => {
  test("正式 schema 連續產生兩次 byte-identical", () => {
    const a = planGeneration({ schemaDir: PROD_SCHEMA, configPath: PROD_CONFIG });
    const b = planGeneration({ schemaDir: PROD_SCHEMA, configPath: PROD_CONFIG });
    expect(a.files.map((f) => f.fileName)).toEqual(b.files.map((f) => f.fileName));
    for (let i = 0; i < a.files.length; i += 1) {
      expect(a.files[i]!.content).toBe(b.files[i]!.content);
    }
  });
});

// MARK: - 漂移偵測 (spec「Check mode detects drift」)

describe("check 漂移偵測", () => {
  test("同步 → inSync；改檔 → different；刪檔 → missing；多檔 → orphan", () => {
    const dir = mkdtempSync(join(tmpdir(), "bl-drift-"));
    try {
      generate({ schemaDir: FIX_SCHEMA, configPath: FIX_CONFIG, outDirOverride: dir });
      expect(check({ schemaDir: FIX_SCHEMA, configPath: FIX_CONFIG, outDirOverride: dir }).inSync).toBe(true);

      // 改一個檔 → different (生成檔預設唯讀，模擬「先解鎖再手改」)
      const swiftFile = join(dir, "swift", "SampleStatus.generated.swift");
      chmodSync(swiftFile, 0o644);
      writeFileSync(swiftFile, readFileSync(swiftFile, "utf8") + "\n// 手動竄改\n");
      let res = check({ schemaDir: FIX_SCHEMA, configPath: FIX_CONFIG, outDirOverride: dir });
      expect(res.inSync).toBe(false);
      expect(res.drifted.some((d) => d.reason === "different" && d.absPath === swiftFile)).toBe(true);

      // 刪一個檔 → missing
      rmSync(join(dir, "kotlin", "SampleTag.kt"));
      res = check({ schemaDir: FIX_SCHEMA, configPath: FIX_CONFIG, outDirOverride: dir });
      expect(res.drifted.some((d) => d.reason === "missing")).toBe(true);

      // 加一個不該存在的產物 → orphan
      writeFileSync(join(dir, "typescript", "Ghost.ts"), "export type Ghost = never;\n");
      res = check({ schemaDir: FIX_SCHEMA, configPath: FIX_CONFIG, outDirOverride: dir });
      expect(res.drifted.some((d) => d.reason === "orphan" && d.absPath.endsWith("Ghost.ts"))).toBe(true);
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });
});

// MARK: - 生成檔唯讀鎖 (除非解鎖)

describe("生成檔唯讀鎖", () => {
  const hasWriteBit = (p: string): boolean => (statSync(p).mode & 0o200) !== 0;

  test("generate 後生成檔唯讀；對唯讀檔重生成不失敗且仍唯讀；unlock 後可寫", () => {
    const dir = mkdtempSync(join(tmpdir(), "bl-lock-"));
    try {
      const files = generate({ schemaDir: FIX_SCHEMA, configPath: FIX_CONFIG, outDirOverride: dir });
      for (const f of files) expect(hasWriteBit(f.absPath)).toBe(false);

      // 對唯讀檔再 generate 一次不應拋錯 (自動解鎖→重寫→重鎖)，結果仍唯讀
      expect(() =>
        generate({ schemaDir: FIX_SCHEMA, configPath: FIX_CONFIG, outDirOverride: dir }),
      ).not.toThrow();
      for (const f of files) expect(hasWriteBit(f.absPath)).toBe(false);

      // check 對唯讀檔仍可讀、回報同步
      expect(check({ schemaDir: FIX_SCHEMA, configPath: FIX_CONFIG, outDirOverride: dir }).inSync).toBe(true);

      // unlock 後全部改回可寫
      const unlocked = unlock({ configPath: FIX_CONFIG, outDirOverride: dir });
      expect(unlocked.length).toBe(files.length);
      for (const f of files) expect(hasWriteBit(f.absPath)).toBe(true);
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });
});

// MARK: - 設定驗證

describe("codegen 設定驗證", () => {
  test("正式設定僅含 swift target", () => {
    const config = loadConfig(PROD_CONFIG);
    expect(config.version).toBe(1);
    expect(config.targets.map((t) => t.language)).toEqual(["swift"]);
  });

  test("不支援的語言 → error", () => {
    const dir = mkdtempSync(join(tmpdir(), "bl-cfg-"));
    try {
      const cfg = join(dir, "codegen.yaml");
      writeFileSync(cfg, "version: 1\ntargets:\n  - language: rust\n    output: out\n");
      expect(() => loadConfig(cfg)).toThrow(/不支援的語言/);
    } finally {
      rmSync(dir, { recursive: true, force: true });
    }
  });
});
