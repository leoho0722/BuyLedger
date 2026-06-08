//
//  PaymentMethodInfo.generated.swift
//  BuyLedger
//
//  此檔由 datamodel-gen 自動產生，請勿手動編輯。
//  若要調整資料形狀，請改 shared/data-model/schema/ 後重新執行 `bun run generate`。
//

import Foundation

/// 付款方式的領域型別。
///
/// 除名稱外一併攜帶「是否為無卡類／銀行匯款／貨到付款」三個旗標，讓使用端不必只憑名稱字串另行查表判定該付款方式的類別。
struct PaymentMethodInfo: Equatable, Hashable, Sendable {

    // MARK: - Data Properties

    /// 付款方式名稱；同時作為主檔的識別值。
    let name: String

    /// 是否屬於「無卡」類付款方式 (例如「無卡」「無卡存款」)。
    ///
    /// 選用此類付款方式時會啟用「無卡折抵金額」與「無卡補款金額」兩個欄位，並把這兩個值計入收益彙總。
    let isCardless: Bool

    /// 是否屬於「銀行匯款」類付款方式。
    ///
    /// 與 isCardless 平行的獨立旗標；選用無卡或銀行匯款類付款方式時，會額外提供「對帳狀態」供事後人工標記對帳結果。
    let isBankTransfer: Bool

    /// 是否屬於「貨到付款」類付款方式。
    ///
    /// 與 isCardless、isBankTransfer 平行的獨立旗標；選用此類付款方式時會把訂單標記為貨到付款。由於貨到付款收取的金額已含預估的三種運費，收益計算會額外扣除國內／國際／來源國當地的國內運費。
    let isCashOnDelivery: Bool
}
