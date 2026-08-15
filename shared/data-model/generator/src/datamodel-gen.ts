// datamodel-gen — BuyLedger 跨平台 data model 產生器
//
// 資料流：schema 目錄 → [yaml 解析] → raw → [zod 驗證] → IR → [emitters] → Swift / Kotlin / TypeScript
// 解析層 (yaml) 與 IR 驗證層 (zod) 嚴格分離 (design Decision 6)：schema 格式可逆替換，emitter 不受影響

import { readdirSync, readFileSync, existsSync, mkdirSync, writeFileSync, chmodSync } from "node:fs";
import { join, resolve, dirname, basename } from "node:path";
import { parseArgs } from "node:util";
import YAML from "yaml";
import { z } from "zod";

// MARK: - 錯誤型別

/** schema 驗證 / 解析失敗時拋出；message 一律指明違規的型別或欄位 */
export class SchemaError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "SchemaError";
  }
}

// MARK: - 中立 trait 與平台對應

/** schema 認可的平台中立 trait 詞彙 (design Decision 3)。Sendable 不在此列——它是 Swift emitter 的全域政策 */
export const NEUTRAL_TRAITS = [
  "value-equality",
  "serializable",
  "identity",
  "case-iterable",
  "hashable",
] as const;
export type NeutralTrait = (typeof NEUTRAL_TRAITS)[number];

/** 基礎型別關鍵字 */
export const BASE_TYPES = ["string", "int", "bool", "decimal", "date", "data", "uuid"] as const;
export type BaseTypeName = (typeof BASE_TYPES)[number];

// MARK: - IR 型別

export type TypeExpr =
  | { kind: "base"; name: BaseTypeName }
  | { kind: "array"; element: TypeExpr }
  | { kind: "map"; key: TypeExpr; value: TypeExpr }
  | { kind: "ref"; name: string };

export type DefaultValue =
  | { kind: "int"; value: number }
  | { kind: "string"; value: string }
  | { kind: "bool"; value: boolean }
  | { kind: "emptyArray" }
  | { kind: "enumCase"; typeName: string; caseName: string }
  | { kind: "newUUID" };

export interface FieldDecl {
  name: string;
  type: TypeExpr;
  doc: string;
  nullable: boolean;
  mutable: boolean;
  default?: DefaultValue;
}

export interface CaseDecl {
  name: string;
  doc: string;
}

interface CommonDecl {
  name: string;
  doc: string;
  traits: Set<NeutralTrait>;
  customSerialization: boolean;
}

export interface EntityDecl extends CommonDecl {
  kind: "entity";
  fields: FieldDecl[];
}

export interface EnumDecl extends CommonDecl {
  kind: "enum";
  cases: CaseDecl[];
}

export interface WrapperDecl extends CommonDecl {
  kind: "wrapper";
  base: TypeExpr;
}

export type TypeDecl = EntityDecl | EnumDecl | WrapperDecl;

export interface Model {
  version: number;
  types: TypeDecl[];
  byName: Map<string, TypeDecl>;
}

// MARK: - 設定型別

export type Language = "swift" | "kotlin" | "typescript";

export interface Target {
  language: Language;
  output: string;
  options: Record<string, unknown>;
}

export interface Codegen {
  version: number;
  targets: Target[];
}

// MARK: - zod raw schema

const RawDefault = z.union([z.number(), z.string(), z.boolean(), z.array(z.unknown())]);

const RawField = z.strictObject({
  name: z.string().min(1),
  type: z.string().min(1),
  doc: z.string().min(1),
  nullable: z.boolean().default(false),
  mutable: z.boolean().default(false),
  default: RawDefault.optional(),
});

const RawCase = z.strictObject({
  name: z.string().min(1),
  doc: z.string().min(1),
});

const RawType = z
  .strictObject({
    name: z.string().min(1),
    kind: z.enum(["entity", "enum", "wrapper"]),
    doc: z.string().min(1),
    traits: z.array(z.enum(NEUTRAL_TRAITS)).default([]),
    serialization: z.literal("custom").optional(),
    fields: z.array(RawField).optional(),
    cases: z.array(RawCase).optional(),
    base: z.string().min(1).optional(),
  })
  .superRefine((val, ctx) => {
    // kind 專屬必填
    if (val.kind === "entity" && (!val.fields || val.fields.length === 0)) {
      ctx.addIssue({ code: "custom", message: `entity ${val.name} 缺 fields`, path: ["fields"] });
    }
    if (val.kind === "enum" && (!val.cases || val.cases.length === 0)) {
      ctx.addIssue({ code: "custom", message: `enum ${val.name} 缺 cases`, path: ["cases"] });
    }
    if (val.kind === "wrapper" && !val.base) {
      ctx.addIssue({ code: "custom", message: `wrapper ${val.name} 缺 base`, path: ["base"] });
    }
    // serializable 與 serialization: custom 互斥
    if (val.traits?.includes("serializable") && val.serialization === "custom") {
      ctx.addIssue({
        code: "custom",
        message: `型別 ${val.name} 同時宣告 serializable trait 與 serialization: custom，兩者互斥`,
        path: ["serialization"],
      });
    }
    // identity entity 必須有 id 欄位
    if (val.kind === "entity" && val.traits?.includes("identity")) {
      const hasId = (val.fields ?? []).some((f) => f.name === "id");
      if (!hasId) {
        ctx.addIssue({
          code: "custom",
          message: `entity ${val.name} 宣告 identity trait 但缺少 id 欄位`,
          path: ["fields"],
        });
      }
    }
    // type 內欄位 / case 名不得重複
    const dupNames = (names: string[]): string | undefined => {
      const seen = new Set<string>();
      for (const n of names) {
        if (seen.has(n)) return n;
        seen.add(n);
      }
      return undefined;
    };
    if (val.fields) {
      const dup = dupNames(val.fields.map((f) => f.name));
      if (dup) {
        ctx.addIssue({ code: "custom", message: `型別 ${val.name} 有重複欄位名 ${dup}`, path: ["fields"] });
      }
    }
    if (val.cases) {
      const dup = dupNames(val.cases.map((c) => c.name));
      if (dup) {
        ctx.addIssue({ code: "custom", message: `型別 ${val.name} 有重複 case 名 ${dup}`, path: ["cases"] });
      }
    }
  });

type RawTypeT = z.infer<typeof RawType>;

const RawCodegen = z.strictObject({
  version: z.number().int(),
  targets: z
    .array(
      z.strictObject({
        language: z.string().min(1),
        output: z.string().min(1),
        options: z.record(z.string(), z.unknown()).default({}),
      }),
    )
    .min(1),
});

// MARK: - 型別文法 parser (字串 DSL，nullability 不在內 — design Decision 4)

/** 解析型別表達式字串為 TypeExpr。`?` 後綴一律報錯 (nullability 改由欄位 nullable 承載) */
export function parseTypeExpr(input: string, context: string): TypeExpr {
  if (input.includes("?")) {
    throw new SchemaError(
      `${context} 的型別 "${input}" 含 "?"——nullability 請改用欄位的 nullable: true，不要寫在型別字串內`,
    );
  }
  const tokens = tokenize(input, context);
  let pos = 0;

  const peek = (): string | undefined => tokens[pos];
  const next = (): string => {
    const t = tokens[pos];
    if (t === undefined) throw new SchemaError(`${context} 的型別 "${input}" 不完整`);
    pos += 1;
    return t;
  };
  const expect = (tok: string): void => {
    const t = next();
    if (t !== tok) throw new SchemaError(`${context} 的型別 "${input}" 預期 "${tok}" 但讀到 "${t}"`);
  };

  const parseExpr = (): TypeExpr => {
    const head = next();
    if (head === "array") {
      expect("<");
      const element = parseExpr();
      expect(">");
      return { kind: "array", element };
    }
    if (head === "map") {
      expect("<");
      const key = parseExpr();
      expect(",");
      const value = parseExpr();
      expect(">");
      return { kind: "map", key, value };
    }
    if ((BASE_TYPES as readonly string[]).includes(head)) {
      return { kind: "base", name: head as BaseTypeName };
    }
    if (/^[A-Za-z_][A-Za-z0-9_]*$/.test(head)) {
      return { kind: "ref", name: head };
    }
    throw new SchemaError(`${context} 的型別 "${input}" 含無法解析的符號 "${head}"`);
  };

  const expr = parseExpr();
  if (peek() !== undefined) {
    throw new SchemaError(`${context} 的型別 "${input}" 有多餘的符號 "${peek()}"`);
  }
  return expr;
}

function tokenize(input: string, context: string): string[] {
  const tokens: string[] = [];
  let i = 0;
  while (i < input.length) {
    const ch = input[i]!;
    if (ch === " " || ch === "\t") {
      i += 1;
      continue;
    }
    if (ch === "<" || ch === ">" || ch === ",") {
      tokens.push(ch);
      i += 1;
      continue;
    }
    if (/[A-Za-z0-9_]/.test(ch)) {
      let j = i;
      while (j < input.length && /[A-Za-z0-9_]/.test(input[j]!)) j += 1;
      tokens.push(input.slice(i, j));
      i = j;
      continue;
    }
    throw new SchemaError(`${context} 的型別 "${input}" 含非法字元 "${ch}"`);
  }
  return tokens;
}

// MARK: - default 解析

const ENUM_CASE_REF = /^[A-Za-z_][A-Za-z0-9_]*\.[A-Za-z_][A-Za-z0-9_]*$/;

function parseDefault(raw: unknown, context: string): DefaultValue {
  if (typeof raw === "number") {
    if (!Number.isInteger(raw)) throw new SchemaError(`${context} 的 default ${raw} 非整數，目前僅支援整數字面值`);
    return { kind: "int", value: raw };
  }
  if (typeof raw === "boolean") {
    return { kind: "bool", value: raw };
  }
  if (Array.isArray(raw)) {
    if (raw.length !== 0) throw new SchemaError(`${context} 的 default 陣列僅支援空陣列 []`);
    return { kind: "emptyArray" };
  }
  if (typeof raw === "string") {
    if (raw === "$newUUID") return { kind: "newUUID" };
    if (ENUM_CASE_REF.test(raw)) {
      const dot = raw.indexOf(".");
      return { kind: "enumCase", typeName: raw.slice(0, dot), caseName: raw.slice(dot + 1) };
    }
    return { kind: "string", value: raw };
  }
  throw new SchemaError(`${context} 的 default 型別不支援：${JSON.stringify(raw)}`);
}

// MARK: - 目錄載入

/** glob 目錄下所有 .yaml，依檔名排序、檔內 types 宣告序串接，回傳 raw type 陣列 (尚未跨型別驗證) */
export function loadSchemaDir(schemaDir: string): RawTypeT[] {
  const dir = resolve(schemaDir);
  if (!existsSync(dir)) throw new SchemaError(`schema 目錄不存在：${dir}`);
  const files = readdirSync(dir)
    .filter((f) => f.endsWith(".yaml") || f.endsWith(".yml"))
    .sort();
  if (files.length === 0) throw new SchemaError(`schema 目錄沒有任何 .yaml 檔：${dir}`);

  const result: RawTypeT[] = [];
  for (const file of files) {
    const text = readFileSync(join(dir, file), "utf8");
    let doc: unknown;
    try {
      doc = YAML.parse(text);
    } catch (err) {
      throw new SchemaError(`解析 ${file} 失敗：${(err as Error).message}`);
    }
    const wrapper = z
      .strictObject({ types: z.array(z.unknown()).min(1) })
      .safeParse(doc);
    if (!wrapper.success) {
      throw new SchemaError(`${file} 必須是含 types 陣列的物件：${formatIssues(wrapper.error.issues)}`);
    }
    for (const rawEntry of wrapper.data.types) {
      const parsed = RawType.safeParse(rawEntry);
      if (!parsed.success) {
        const name =
          rawEntry && typeof rawEntry === "object" && "name" in rawEntry
            ? String((rawEntry as { name: unknown }).name)
            : "(未命名型別)";
        throw new SchemaError(`${file} 的型別 ${name} 驗證失敗：${formatIssues(parsed.error.issues)}`);
      }
      result.push(parsed.data);
    }
  }
  return result;
}

function formatIssues(issues: z.core.$ZodIssue[]): string {
  return issues
    .map((i) => {
      const path = i.path.length ? i.path.join(".") : "(root)";
      return `${path}: ${i.message}`;
    })
    .join("; ");
}

// MARK: - IR 建構與跨型別驗證

/** 把 raw type 陣列驗證、解析型別文法與 default，串成單一 IR。違規一律拋 SchemaError */
export function buildModel(rawTypes: RawTypeT[], version: number): Model {
  // 跨型別：重複型別名
  const byName = new Map<string, TypeDecl>();
  const seen = new Set<string>();
  for (const r of rawTypes) {
    if (seen.has(r.name)) throw new SchemaError(`重複的型別名：${r.name}`);
    seen.add(r.name);
  }

  const types: TypeDecl[] = rawTypes.map((r) => buildType(r));
  for (const t of types) byName.set(t.name, t);

  // 解析所有型別參考、enum-case default 是否存在
  resolveReferences(types, byName);

  return { version, types, byName };
}

function buildType(r: RawTypeT): TypeDecl {
  const common: CommonDecl = {
    name: r.name,
    doc: r.doc,
    traits: new Set(r.traits as NeutralTrait[]),
    customSerialization: r.serialization === "custom",
  };

  if (r.kind === "entity") {
    const fields: FieldDecl[] = (r.fields ?? []).map((f) => ({
      name: f.name,
      type: parseTypeExpr(f.type, `${r.name}.${f.name}`),
      doc: f.doc,
      nullable: f.nullable,
      mutable: f.mutable,
      default: f.default === undefined ? undefined : parseDefault(f.default, `${r.name}.${f.name}`),
    }));
    return { ...common, kind: "entity", fields };
  }

  if (r.kind === "enum") {
    const cases: CaseDecl[] = (r.cases ?? []).map((c) => ({ name: c.name, doc: c.doc }));
    return { ...common, kind: "enum", cases };
  }

  return { ...common, kind: "wrapper", base: parseTypeExpr(r.base!, `${r.name}.base`) };
}

function resolveReferences(types: TypeDecl[], byName: Map<string, TypeDecl>): void {
  const checkExpr = (expr: TypeExpr, context: string): void => {
    switch (expr.kind) {
      case "base":
        return;
      case "array":
        checkExpr(expr.element, context);
        return;
      case "map":
        checkExpr(expr.key, context);
        checkExpr(expr.value, context);
        return;
      case "ref":
        if (!byName.has(expr.name)) {
          throw new SchemaError(`${context} 參考了未宣告的型別 ${expr.name}`);
        }
        return;
    }
  };

  for (const t of types) {
    if (t.kind === "entity") {
      for (const f of t.fields) {
        checkExpr(f.type, `${t.name}.${f.name}`);
        const def = f.default;
        if (def?.kind === "enumCase") {
          const target = byName.get(def.typeName);
          if (!target || target.kind !== "enum") {
            throw new SchemaError(
              `${t.name}.${f.name} 的 default 參考了非 enum 型別 ${def.typeName}`,
            );
          }
          if (!target.cases.some((c) => c.name === def.caseName)) {
            throw new SchemaError(
              `${t.name}.${f.name} 的 default 參考了不存在的 enum case ${def.typeName}.${def.caseName}`,
            );
          }
        }
      }
    } else if (t.kind === "wrapper") {
      checkExpr(t.base, `${t.name}.base`);
    }
  }
}

/** 把單一 raw 物件 (來自 YAML 或測試) 過 zod 驗證，失敗時拋 SchemaError 並指明型別名 */
export function parseRawType(entry: unknown): RawTypeT {
  const parsed = RawType.safeParse(entry);
  if (!parsed.success) {
    const name =
      entry && typeof entry === "object" && "name" in entry
        ? String((entry as { name: unknown }).name)
        : "(未命名型別)";
    throw new SchemaError(`型別 ${name} 驗證失敗：${formatIssues(parsed.error.issues)}`);
  }
  return parsed.data;
}

/** 測試用：直接從 raw 物件陣列建 Model (等同 loadSchemaDir → buildModel 的記憶體版) */
export function buildModelFromRaw(entries: unknown[], version = 1): Model {
  return buildModel(entries.map(parseRawType), version);
}

// MARK: - 設定載入

export function loadConfig(configPath: string): Codegen {
  const path = resolve(configPath);
  if (!existsSync(path)) throw new SchemaError(`codegen 設定不存在：${path}`);
  let doc: unknown;
  try {
    doc = YAML.parse(readFileSync(path, "utf8"));
  } catch (err) {
    throw new SchemaError(`解析 codegen 設定失敗：${(err as Error).message}`);
  }
  const parsed = RawCodegen.safeParse(doc);
  if (!parsed.success) {
    throw new SchemaError(`codegen 設定驗證失敗：${formatIssues(parsed.error.issues)}`);
  }
  const targets: Target[] = parsed.data.targets.map((t) => {
    if (t.language !== "swift" && t.language !== "kotlin" && t.language !== "typescript") {
      throw new SchemaError(`codegen 設定指定了不支援的語言：${t.language}`);
    }
    return { language: t.language, output: t.output, options: t.options };
  });
  return { version: parsed.data.version, targets };
}

// MARK: - 共用 emit helper

/** Swift `///` 行註解：每行加 `{indent}/// `，空行為 `{indent}///` */
/** 去掉 doc 行結尾的中文句號 (對齊「程式碼註解結尾不加句號」規範) */
function stripDocPeriod(line: string): string {
  return line.replace(/。+$/u, "");
}

function docLines(doc: string, prefix: string): string[] {
  return doc.split("\n").map((line) => (line.length === 0 ? prefix.trimEnd() : `${prefix}${stripDocPeriod(line)}`));
}

// Kotlin KDoc / TypeScript JSDoc 區塊註解：開頭 /** 、每行前綴 " * "、結尾收斂行
function blockDoc(doc: string, indent: string): string[] {
  const out: string[] = [`${indent}/**`];
  for (const line of doc.split("\n")) out.push(line.length === 0 ? `${indent} *` : `${indent} * ${stripDocPeriod(line)}`);
  out.push(`${indent} */`);
  return out;
}

function generatedHeader(fileName: string, commentLeader: string): string {
  const lines = [
    "",
    `  ${fileName}`,
    "  BuyLedger",
    "",
    "  此檔由 datamodel-gen 自動產生，請勿手動編輯",
    "  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`",
    "",
  ];
  return lines.map((l) => `${commentLeader}${l}`.trimEnd()).join("\n");
}

// MARK: - Swift emitter

const SWIFT_BASE: Record<BaseTypeName, string> = {
  string: "String",
  int: "Int",
  bool: "Bool",
  decimal: "Decimal",
  date: "Date",
  data: "Data",
  uuid: "UUID",
};

const SWIFT_STRUCT_ORDER = ["Codable", "Equatable", "Hashable", "Identifiable", "Sendable"] as const;
const SWIFT_ENUM_ORDER = ["CaseIterable", "Codable", "Identifiable", "Sendable"] as const;

function swiftType(expr: TypeExpr): string {
  switch (expr.kind) {
    case "base":
      return SWIFT_BASE[expr.name];
    case "array":
      return `[${swiftType(expr.element)}]`;
    case "map":
      return `[${swiftType(expr.key)}: ${swiftType(expr.value)}]`;
    case "ref":
      return expr.name;
  }
}

function swiftFieldType(field: FieldDecl): string {
  const base = swiftType(field.type);
  return field.nullable ? `${base}?` : base;
}

function swiftDefaultLiteral(def: DefaultValue): string {
  switch (def.kind) {
    case "int":
      return String(def.value);
    case "string":
      return JSON.stringify(def.value);
    case "bool":
      return String(def.value);
    case "emptyArray":
      return "[]";
    case "enumCase":
      return `.${def.caseName}`;
    case "newUUID":
      return "UUID()";
  }
}

function swiftConformances(t: TypeDecl): string[] {
  const has = (tr: NeutralTrait): boolean => t.traits.has(tr);
  if (t.kind === "enum") {
    const out: string[] = ["String"];
    for (const c of SWIFT_ENUM_ORDER) {
      if (c === "CaseIterable" && has("case-iterable")) out.push(c);
      else if (c === "Codable" && has("serializable") && !t.customSerialization) out.push(c);
      else if (c === "Identifiable" && has("identity")) out.push(c);
      else if (c === "Sendable") out.push(c);
    }
    return out;
  }
  const out: string[] = [];
  for (const c of SWIFT_STRUCT_ORDER) {
    if (c === "Codable" && has("serializable") && !t.customSerialization) out.push(c);
    else if (c === "Equatable" && has("value-equality")) out.push(c);
    else if (c === "Hashable" && has("hashable")) out.push(c);
    else if (c === "Identifiable" && has("identity")) out.push(c);
    else if (c === "Sendable") out.push(c);
  }
  return out;
}

/** entity 需要顯式 init 的條件：任一欄位 nullable 或帶 default (spec：generated owns the data shape) */
function needsExplicitInit(fields: FieldDecl[]): boolean {
  return fields.some((f) => f.nullable || f.default !== undefined);
}

function emitSwift(t: TypeDecl): string {
  const header = generatedHeader(`${t.name}.generated.swift`, "//");
  const parts: string[] = [header, "", "import Foundation", "", ...docLines(t.doc, "/// ")];

  if (t.kind === "enum") {
    parts.push(`enum ${t.name}: ${swiftConformances(t).join(", ")} {`);
    parts.push("");
    parts.push("    // MARK: - Cases");
    for (const c of t.cases) {
      parts.push("");
      parts.push(...docLines(c.doc, "    /// "));
      parts.push(`    case ${c.name}`);
    } // swift cases use line-comment docs
    if (t.traits.has("identity")) {
      parts.push("");
      parts.push("    // MARK: - Identifiable Properties");
      parts.push("");
      parts.push("    /// 穩定識別值 (以 rawValue 表示)");
      parts.push("    var id: String { rawValue }");
    }
    parts.push("}");
    return parts.join("\n") + "\n";
  }

  if (t.kind === "wrapper") {
    parts.push(`struct ${t.name}: ${swiftConformances(t).join(", ")} {`);
    parts.push("");
    parts.push("    // MARK: - Data Properties");
    parts.push("");
    parts.push("    /// 包裝的原始值");
    parts.push(`    let rawValue: ${swiftType(t.base)}`);
    if (t.traits.has("identity")) {
      parts.push("");
      parts.push("    // MARK: - Identifiable Properties");
      parts.push("");
      parts.push("    /// 穩定識別值 (以 rawValue 表示)");
      parts.push(`    var id: ${swiftType(t.base)} { rawValue }`);
    }
    parts.push("}");
    return parts.join("\n") + "\n";
  }

  // entity
  parts.push(`struct ${t.name}: ${swiftConformances(t).join(", ")} {`);
  parts.push("");
  parts.push("    // MARK: - Data Properties");
  for (const f of t.fields) {
    parts.push("");
    parts.push(...docLines(f.doc, "    /// "));
    const binding = f.mutable ? "var" : "let";
    parts.push(`    ${binding} ${f.name}: ${swiftFieldType(f)}`);
  }

  if (needsExplicitInit(t.fields)) {
    parts.push("");
    parts.push("    // MARK: - Init");
    parts.push("");
    parts.push(`    /// 建立 ${t.name}`);
    const params = t.fields.map((f) => {
      let p = `${f.name}: ${swiftFieldType(f)}`;
      if (f.default !== undefined) p += ` = ${swiftDefaultLiteral(f.default)}`;
      else if (f.nullable) p += " = nil";
      return p;
    });
    if (params.length === 1) {
      parts.push(`    init(${params[0]}) {`);
    } else {
      parts.push("    init(");
      params.forEach((p, idx) => {
        parts.push(`        ${p}${idx < params.length - 1 ? "," : ""}`);
      });
      parts.push("    ) {");
    }
    for (const f of t.fields) parts.push(`        self.${f.name} = ${f.name}`);
    parts.push("    }");
  }

  parts.push("}");
  return parts.join("\n") + "\n";
}

// MARK: - Kotlin emitter

const KOTLIN_BASE: Record<BaseTypeName, string> = {
  string: "String",
  int: "Int",
  bool: "Boolean",
  decimal: "java.math.BigDecimal",
  date: "java.time.Instant",
  data: "ByteArray",
  uuid: "java.util.UUID",
};

function kotlinType(expr: TypeExpr): string {
  switch (expr.kind) {
    case "base":
      return KOTLIN_BASE[expr.name];
    case "array":
      return `List<${kotlinType(expr.element)}>`;
    case "map":
      return `Map<${kotlinType(expr.key)}, ${kotlinType(expr.value)}>`;
    case "ref":
      return expr.name;
  }
}

function kotlinFieldType(field: FieldDecl): string {
  const base = kotlinType(field.type);
  return field.nullable ? `${base}?` : base;
}

/** schema 的 camelCase case 名稱轉為 Kotlin screaming snake case (例如 partiallyArrived → PARTIALLY_ARRIVED)
 *  case 宣告與 enum-valued 欄位預設值兩處皆呼叫本函式，避免各自轉一次而失去同步 */
function kotlinEnumConstant(caseName: string): string {
  return caseName.replace(/([a-z0-9])([A-Z])/g, "$1_$2").toUpperCase();
}

function kotlinDefaultLiteral(field: FieldDecl): string | undefined {
  if (field.default !== undefined) {
    const def = field.default;
    switch (def.kind) {
      case "int":
        return String(def.value);
      case "string":
        return JSON.stringify(def.value);
      case "bool":
        return String(def.value);
      case "emptyArray":
        return field.type.kind === "map" ? "emptyMap()" : "emptyList()";
      case "enumCase":
        return `${def.typeName}.${kotlinEnumConstant(def.caseName)}`;
      case "newUUID":
        return "java.util.UUID.randomUUID()";
    }
  }
  if (field.nullable) return "null";
  return undefined;
}

function emitKotlin(t: TypeDecl, options: Record<string, unknown>): string {
  const pkg = typeof options.package === "string" ? options.package : undefined;
  const header = generatedHeader(`${t.name}.kt`, "//");
  const parts: string[] = [header, ""];
  if (pkg) {
    parts.push(`package ${pkg}`, "");
  }

  if (t.kind === "enum") {
    parts.push(...blockDoc(t.doc, ""));
    parts.push(`enum class ${t.name}(val rawValue: String) {`);
    t.cases.forEach((c, idx) => {
      parts.push("");
      parts.push(...blockDoc(c.doc, "    "));
      parts.push(`    ${kotlinEnumConstant(c.name)}("${c.name}")${idx < t.cases.length - 1 ? "," : ";"}`);
    });
    parts.push("}");
    return parts.join("\n") + "\n";
  }

  if (t.kind === "wrapper") {
    parts.push(...blockDoc(t.doc, ""));
    parts.push("@JvmInline");
    parts.push(`value class ${t.name}(val rawValue: ${kotlinType(t.base)})`);
    return parts.join("\n") + "\n";
  }

  // entity → data class
  parts.push(...blockDoc(t.doc, ""));
  parts.push(`data class ${t.name}(`);
  t.fields.forEach((f, idx) => {
    parts.push(...blockDoc(f.doc, "    "));
    const binding = f.mutable ? "var" : "val";
    const def = kotlinDefaultLiteral(f);
    const suffix = def !== undefined ? ` = ${def}` : "";
    parts.push(`    ${binding} ${f.name}: ${kotlinFieldType(f)}${suffix}${idx < t.fields.length - 1 ? "," : ""}`);
  });
  parts.push(")");
  return parts.join("\n") + "\n";
}

// MARK: - TypeScript emitter

const TS_BASE: Record<BaseTypeName, string> = {
  string: "string",
  int: "number",
  bool: "boolean",
  decimal: "DecimalString",
  date: "ISODateString",
  data: "Base64String",
  uuid: "UUIDString",
};

const TS_ALIAS: Record<string, string> = {
  DecimalString: "string",
  ISODateString: "string",
  Base64String: "string",
  UUIDString: "string",
};

function tsType(expr: TypeExpr): string {
  switch (expr.kind) {
    case "base":
      return TS_BASE[expr.name];
    case "array": {
      const el = tsType(expr.element);
      return /[ |]/.test(el) ? `Array<${el}>` : `${el}[]`;
    }
    case "map":
      return `Record<${tsType(expr.key)}, ${tsType(expr.value)}>`;
    case "ref":
      return expr.name;
  }
}

function collectTsExpr(expr: TypeExpr, aliases: Set<string>, refs: Set<string>): void {
  switch (expr.kind) {
    case "base": {
      const mapped = TS_BASE[expr.name];
      if (mapped in TS_ALIAS) aliases.add(mapped);
      return;
    }
    case "array":
      collectTsExpr(expr.element, aliases, refs);
      return;
    case "map":
      collectTsExpr(expr.key, aliases, refs);
      collectTsExpr(expr.value, aliases, refs);
      return;
    case "ref":
      refs.add(expr.name);
      return;
  }
}

function emitTypeScript(t: TypeDecl): string {
  const header = generatedHeader(`${t.name}.ts`, "//");
  const parts: string[] = [header, ""];

  if (t.kind === "enum") {
    parts.push(...blockDoc(t.doc, ""));
    parts.push(`export type ${t.name} =`);
    t.cases.forEach((c, idx) => {
      parts.push(`  | "${c.name}"${idx === t.cases.length - 1 ? ";" : ""}`);
    });
    return parts.join("\n") + "\n";
  }

  if (t.kind === "wrapper") {
    const aliases = new Set<string>();
    const refs = new Set<string>();
    collectTsExpr(t.base, aliases, refs);
    pushTsPreamble(parts, aliases, refs, t.name);
    parts.push(...blockDoc(t.doc, ""));
    parts.push(`export type ${t.name} = ${tsType(t.base)};`);
    return parts.join("\n") + "\n";
  }

  // entity → interface
  const aliases = new Set<string>();
  const refs = new Set<string>();
  for (const f of t.fields) collectTsExpr(f.type, aliases, refs);
  pushTsPreamble(parts, aliases, refs, t.name);

  parts.push(...blockDoc(t.doc, ""));
  parts.push(`export interface ${t.name} {`);
  t.fields.forEach((f) => {
    parts.push(...blockDoc(f.doc, "  "));
    const optional = f.nullable ? "?" : "";
    const valueType = f.nullable ? `${tsType(f.type)} | null` : tsType(f.type);
    parts.push(`  readonly ${f.name}${optional}: ${valueType};`);
  });
  parts.push("}");
  return parts.join("\n") + "\n";
}

function pushTsPreamble(parts: string[], aliases: Set<string>, refs: Set<string>, selfName: string): void {
  let wrote = false;
  for (const ref of [...refs].sort()) {
    if (ref === selfName) continue;
    parts.push(`import type { ${ref} } from "./${ref}";`);
    wrote = true;
  }
  for (const alias of [...aliases].sort()) {
    parts.push(`type ${alias} = ${TS_ALIAS[alias]};`);
    wrote = true;
  }
  if (wrote) parts.push("");
}

// MARK: - emit 分派

const FILE_SUFFIX: Record<Language, (typeName: string) => string> = {
  swift: (n) => `${n}.generated.swift`,
  kotlin: (n) => `${n}.kt`,
  typescript: (n) => `${n}.ts`,
};

export function emitType(language: Language, t: TypeDecl, options: Record<string, unknown>): string {
  switch (language) {
    case "swift":
      return emitSwift(t);
    case "kotlin":
      return emitKotlin(t, options);
    case "typescript":
      return emitTypeScript(t);
  }
}

/** 對單一 target 產出 fileName → content 的有序陣列 (型別順序即 model.types 順序，保決定性) */
export function emitTarget(model: Model, target: Target): Array<{ fileName: string; content: string }> {
  const suffix = FILE_SUFFIX[target.language];
  return model.types.map((t) => ({
    fileName: suffix(t.name),
    content: emitType(target.language, t, target.options),
  }));
}

// MARK: - generate / check

export interface GeneratedFile {
  language: Language;
  /** target 輸出目錄 (絕對路徑) */
  outputDir: string;
  fileName: string;
  absPath: string;
  content: string;
}

export interface GenerateOptions {
  schemaDir: string;
  configPath: string;
  /** 覆寫所有 target 的輸出根目錄 (e2e 寫到暫存目錄用)；各 target 改寫到 outDirOverride/<language>/ */
  outDirOverride?: string;
}

/** 純計算：載入 + 驗證 + emit，回傳所有 target 的輸出檔 (不寫入磁碟) */
export function planGeneration(opts: GenerateOptions): { model: Model; files: GeneratedFile[] } {
  const config = loadConfig(opts.configPath);
  const rawTypes = loadSchemaDir(opts.schemaDir);
  const model = buildModel(rawTypes, config.version);
  const configDir = dirname(resolve(opts.configPath));

  const files: GeneratedFile[] = [];
  for (const target of config.targets) {
    const outputDir = opts.outDirOverride
      ? resolve(opts.outDirOverride, target.language)
      : resolve(configDir, target.output);
    for (const { fileName, content } of emitTarget(model, target)) {
      files.push({
        language: target.language,
        outputDir,
        fileName,
        absPath: join(outputDir, fileName),
        content,
      });
    }
  }
  return { model, files };
}

/** 生成檔的權限：預設唯讀 (0o444) 防手動編輯；覆寫前暫時改回可寫 (0o644) */
const MODE_READONLY = 0o444;
const MODE_WRITABLE = 0o644;

/** 寫出所有 target 檔案到磁碟；每個生成檔寫完後鎖為唯讀，防止被手動編輯 */
export function generate(opts: GenerateOptions): GeneratedFile[] {
  const { files } = planGeneration(opts);
  for (const f of files) {
    mkdirSync(f.outputDir, { recursive: true });
    // 既有檔可能已被鎖成唯讀——先解鎖才能覆寫，寫完再重新上鎖 (generate 為冪等的「重生 + 重鎖」)
    if (existsSync(f.absPath)) chmodSync(f.absPath, MODE_WRITABLE);
    writeFileSync(f.absPath, f.content, "utf8");
    chmodSync(f.absPath, MODE_READONLY);
  }
  return files;
}

/** 把各 target 輸出目錄中的生成檔解鎖 (改回可寫)，供刻意手動檢視／實驗用；下次 generate 會再上鎖
 *  只依 codegen 設定掃描輸出目錄，不需 schema 有效，故 schema 編輯到一半也能解鎖 */
export function unlock(opts: { configPath: string; outDirOverride?: string }): string[] {
  const config = loadConfig(opts.configPath);
  const configDir = dirname(resolve(opts.configPath));
  const unlocked: string[] = [];
  for (const target of config.targets) {
    const outputDir = opts.outDirOverride
      ? resolve(opts.outDirOverride, target.language)
      : resolve(configDir, target.output);
    if (!existsSync(outputDir)) continue;
    const suffix =
      target.language === "swift" ? ".generated.swift" : target.language === "kotlin" ? ".kt" : ".ts";
    for (const name of readdirSync(outputDir)) {
      if (name.endsWith(suffix)) {
        const abs = join(outputDir, name);
        chmodSync(abs, MODE_WRITABLE);
        unlocked.push(abs);
      }
    }
  }
  unlocked.sort();
  return unlocked;
}

export interface DriftEntry {
  absPath: string;
  reason: "missing" | "different" | "orphan";
}

export interface CheckResult {
  inSync: boolean;
  drifted: DriftEntry[];
}

/** 比對磁碟產出與 schema 是否同步；不修改任何檔案 */
export function check(opts: GenerateOptions): CheckResult {
  const { files } = planGeneration(opts);
  const drifted: DriftEntry[] = [];

  const expectedByDir = new Map<string, Set<string>>();
  const suffixByDir = new Map<string, string>();
  for (const f of files) {
    if (!expectedByDir.has(f.outputDir)) expectedByDir.set(f.outputDir, new Set());
    expectedByDir.get(f.outputDir)!.add(f.fileName);
    // 記錄該目錄對應語言的副檔名 (用於孤兒偵測)
    const dotSuffix =
      f.language === "swift" ? ".generated.swift" : f.language === "kotlin" ? ".kt" : ".ts";
    suffixByDir.set(f.outputDir, dotSuffix);

    if (!existsSync(f.absPath)) {
      drifted.push({ absPath: f.absPath, reason: "missing" });
      continue;
    }
    const onDisk = readFileSync(f.absPath, "utf8");
    if (onDisk !== f.content) drifted.push({ absPath: f.absPath, reason: "different" });
  }

  // 孤兒：磁碟上符合該語言副檔名、但已不再被產生的檔
  for (const [dir, expected] of expectedByDir) {
    if (!existsSync(dir)) continue;
    const suffix = suffixByDir.get(dir)!;
    for (const name of readdirSync(dir)) {
      if (name.endsWith(suffix) && !expected.has(name)) {
        drifted.push({ absPath: join(dir, name), reason: "orphan" });
      }
    }
  }

  drifted.sort((a, b) => a.absPath.localeCompare(b.absPath));
  return { inSync: drifted.length === 0, drifted };
}

// MARK: - CLI

function runCli(argv: string[]): number {
  const command = argv[0];
  if (command !== "generate" && command !== "check" && command !== "unlock") {
    process.stderr.write(
      `用法：datamodel-gen <generate|check|unlock> --schema <dir> --config <file> [--out-dir <dir>]\n`,
    );
    return 1;
  }

  const { values } = parseArgs({
    args: argv.slice(1),
    options: {
      schema: { type: "string" },
      config: { type: "string" },
      "out-dir": { type: "string" },
    },
    allowPositionals: false,
  });

  // unlock 只需 --config (掃描輸出目錄)；generate / check 需要 --schema 與 --config
  if (command === "unlock" ? !values.config : !values.schema || !values.config) {
    process.stderr.write(`缺少必要參數 (unlock 需 --config；generate / check 需 --schema 與 --config)\n`);
    return 1;
  }

  try {
    if (command === "unlock") {
      const unlocked = unlock({ configPath: values.config!, outDirOverride: values["out-dir"] });
      process.stdout.write(`已解鎖 ${unlocked.length} 個生成檔 (改回可寫)；下次 generate 會重新鎖為唯讀\n`);
      for (const p of unlocked) process.stdout.write(`  ${p}\n`);
      return 0;
    }
    if (command === "generate") {
      const files = generate({
        schemaDir: values.schema!,
        configPath: values.config!,
        outDirOverride: values["out-dir"],
      });
      process.stdout.write(`已產出 ${files.length} 個檔案\n`);
      for (const f of files) process.stdout.write(`  ${f.absPath}\n`);
      return 0;
    }
    const result = check({
      schemaDir: values.schema!,
      configPath: values.config!,
      outDirOverride: values["out-dir"],
    });
    if (result.inSync) {
      process.stdout.write(`check 通過：磁碟產出與 schema 同步\n`);
      return 0;
    }
    process.stderr.write(`check 失敗：以下檔案與 schema 不同步\n`);
    for (const d of result.drifted) process.stderr.write(`  [${d.reason}] ${d.absPath}\n`);
    return 1;
  } catch (err) {
    if (err instanceof SchemaError) {
      process.stderr.write(`schema 錯誤：${err.message}\n`);
      return 1;
    }
    throw err;
  }
}

if (import.meta.main) {
  process.exit(runCli(process.argv.slice(2)));
}
