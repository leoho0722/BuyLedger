//
//  SampleTag.kt
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯。
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`。
//

package com.buyledger.datamodel

/**
 * 範例標籤 (示範 wrapper + 自訂序列化 + identity)。
 */
@JvmInline
value class SampleTag(val rawValue: String)
