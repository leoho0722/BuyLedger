//
//  QuoteView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 報價試算工具畫面
///
/// 對應設計稿 iPhone Quote sheet 與 iPad 的 Quote tool：
/// - 來源幣別 chip
/// - 多個數值輸入欄 (商品本金 / 當地運費 / 國際運費 / 刷卡手續費 / 金流手續費 / 平台手續費 / 目標毛利)
/// - 即時建議售價 (綠→青漸層 hero 卡)
/// - 成本拆解條與總成本
struct QuoteView: View {

    // MARK: - View Properties

    /// 報價試算 store
    @Bindable var store: StoreOf<QuoteFeature>

    /// 目前系統深淺色外觀
    @Environment(\.colorScheme) private var colorScheme

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// hero 建議售價字級，隨 Dynamic Type 縮放 (以 `.largeTitle` 為基準)
    @ScaledMetric(relativeTo: .largeTitle) private var heroPriceSize: CGFloat = 40

    // MARK: - View Body

    /// 報價試算畫面內容
    var body: some View {
        let palette = BLTheme.palette(for: colorScheme)

        ScrollView {
            VStack(alignment: .leading, spacing: BLSpacing.large) {
                statusBanner(palette: palette)
                inputsCard(palette: palette)
                suggestedHero(palette: palette)
                breakdownCard(palette: palette)
            }
            .padding(.horizontal, BLSpacing.large)
            .padding(.vertical, BLSpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(palette.background)
        .navigationTitle(Text("報價試算"))
        .task {
            await store.send(.task).finish()
        }
    }
}

// MARK: - ViewBuilder

private extension QuoteView {

    /// 匯率載入狀態的橫幅；無錯誤且已載入時不顯示
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 狀態 view
    @ViewBuilder
    func statusBanner(palette: BLPalette) -> some View {
        if store.isLoading {
            HStack(spacing: BLSpacing.small) {
                ProgressView()
                    .controlSize(.small)
                Text("正在載入匯率…")
                    .font(.footnote)
                    .foregroundStyle(palette.secondaryLabel)
                Spacer()
            }
            .padding(.horizontal, BLSpacing.medium)
            .padding(.vertical, BLSpacing.small)
            .background(palette.fillTertiary)
            .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
        } else if let message = store.errorMessage {
            HStack(alignment: .top, spacing: BLSpacing.small) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(palette.orange)
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(palette.label)
                Spacer()
            }
            .padding(.horizontal, BLSpacing.medium)
            .padding(.vertical, BLSpacing.small)
            .background(palette.orange.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
        } else if !store.hasUsableRate {
            HStack(spacing: BLSpacing.small) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(palette.secondaryLabel)
                Text("尚無可用匯率資料，建議售價暫顯示為 0。")
                    .font(.footnote)
                    .foregroundStyle(palette.secondaryLabel)
                Spacer()
            }
            .padding(.horizontal, BLSpacing.medium)
            .padding(.vertical, BLSpacing.small)
            .background(palette.fillQuaternary)
            .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
        }
    }

    /// 輸入卡：客戶/商品 + 幣別 + 各項數值輸入欄
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 輸入卡 view
    @ViewBuilder
    func inputsCard(palette: BLPalette) -> some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                Text("商品資訊")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.secondaryLabel)
                    .textCase(.uppercase)

                currencyPicker(palette: palette)

                numberField(
                    label: "商品定價",
                    value: $store.itemPrice,
                    unit: store.fromCurrency.rawValue,
                    allowsDecimalEntry: true
                )

                numberField(
                    label: "當地運費",
                    value: $store.domesticShipping,
                    unit: store.fromCurrency.rawValue,
                    allowsDecimalEntry: true
                )

                numberField(
                    label: "國際運費",
                    value: $store.internationalShippingTwd,
                    unit: "TWD/件"
                )

                numberField(
                    label: "刷卡手續費",
                    value: $store.cardFeePercent,
                    unit: "%",
                    fractionDigits: 1
                )

                numberField(
                    label: "金流手續費",
                    value: $store.paymentFeePercent,
                    unit: "%",
                    fractionDigits: 1
                )

                numberField(
                    label: "平台手續費",
                    value: $store.platformFeePercent,
                    unit: "%",
                    fractionDigits: 1
                )

                numberField(
                    label: "目標毛利",
                    value: $store.targetMarginPercent,
                    unit: "%"
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 來源幣別選擇按鈕：點開後以 sheet 列出主檔幣別供搜尋與選擇
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 幣別按鈕 view
    @ViewBuilder
    func currencyPicker(palette: BLPalette) -> some View {
        Button {
            store.send(.currencyPickerTapped)
        } label: {
            HStack(spacing: BLSpacing.small) {
                Text("來源幣別")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.secondaryLabel)

                Spacer()

                Text(currencyDisplayText(for: store.fromCurrency))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.label)
                    .lineLimit(1)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.tertiaryLabel)
            }
            .padding(.vertical, BLSpacing.small)
            .padding(.horizontal, BLSpacing.medium)
            .background(palette.fillTertiary)
            .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $store.showsCurrencySheet) {
            let locale = locale

            OptionPickerSheet(
                title: "選擇來源幣別",
                allowsAdd: false,
                searchable: true,
                emptyTitle: "尚無幣別",
                emptyDescription: "需要網路連線載入幣別清單；請稍後再試。",
                options: store.availableCurrencies.map(\.rawValue),
                selected: store.fromCurrency.rawValue,
                displayName: { code in
                    let name = locale.localizedString(forCurrencyCode: code) ?? ""
                    return name.isEmpty ? code : "\(code) · \(name)"
                },
                searchKeywords: { code in
                    locale.localizedString(forCurrencyCode: code) ?? ""
                },
                onSelect: { code in
                    store.send(.fromCurrencySelected(code))
                }
            )
        }
    }

    /// 單一數值輸入列：label 在左、右側為對齊尾端的 `TextField` 與單位，取代原本的 slider，讓使用者可直接鍵入精確數值
    /// - Parameters:
    ///   - label: 欄位名稱
    ///   - value: 雙向繫結的值；寫入時自動 clamp 成非負數
    ///   - unit: 顯示在輸入框右側的單位字串
    ///   - fractionDigits: 固定顯示的小數位數；大於 0 時鍵盤改用 `decimalPad`，否則 `numberPad`
    ///   - allowsDecimalEntry: 為 `true` 時允許輸入 0 到 2 位小數 (整數不強制補零) 並使用 `decimalPad`，供金額類欄位鍵入小數價格
    /// - Returns: 數值輸入列 view
    @ViewBuilder
    func numberField(
        label: String,
        value: Binding<Double>,
        unit: String,
        fractionDigits: Int = 0,
        allowsDecimalEntry: Bool = false
    ) -> some View {
        HStack(spacing: BLSpacing.small) {
            Text(LocalizedStringKey(label))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                // 長標籤 (如 International Shipping) 換行顯示、不截斷
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField(
                "0",
                value: value,
                format: .number.precision(
                    allowsDecimalEntry ? .fractionLength(0...2) : .fractionLength(fractionDigits)
                )
            )
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.trailing)
            .monospacedDigit()
            .frame(width: 120)
            .keyboardType(allowsDecimalEntry || fractionDigits > 0 ? .decimalPad : .numberPad)

            Text(LocalizedStringKey(unit))
                .font(.footnote)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                // 短單位對齊 60pt，較長單位 (如 TWD/item) 自適應變寬、不截斷
                .frame(minWidth: 60, alignment: .leading)
        }
    }

    /// 建議售價 hero 卡 (漸層綠→青)
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: hero 卡 view
    @ViewBuilder
    func suggestedHero(palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
            Text("建議售價")
                .font(.caption.weight(.semibold))
                .opacity(0.95)
                .textCase(.uppercase)

            Text(formatTwd(store.suggestedTwd))
                .font(.system(size: heroPriceSize, weight: .bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text("預估獲利 \(formatTwd(store.estimatedProfitTwd)) · \(formatPercent(store.estimatedMarginPercent))")
                .font(.footnote)
                .opacity(0.95)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BLSpacing.large)
        .foregroundStyle(.white)
        .background(
            LinearGradient(
                colors: [palette.green, palette.teal],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: BLRadius.large, style: .continuous))
        .blCardShadow()
    }

    /// 成本拆解卡：每項條 + 總成本
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 拆解卡 view
    @ViewBuilder
    func breakdownCard(palette: BLPalette) -> some View {
        let total = max(store.costTwd, 1)
        let items: [(label: String, value: Double, color: Color)] = [
            ("商品金額", store.itemTwd, palette.accent),
            ("當地運費", store.domesticTwd, palette.teal),
            ("國際運費", store.internationalShippingTwd, palette.purple),
            ("刷卡手續費", store.cardFeeTwd, palette.orange),
            ("金流手續費", store.paymentFeeTwd, palette.pink),
            ("平台手續費", store.platformFeeTwd, palette.indigo),
        ]

        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                Text("成本拆解")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.secondaryLabel)
                    .textCase(.uppercase)

                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    breakdownRow(
                        label: item.label,
                        value: item.value,
                        total: total,
                        color: item.color,
                        palette: palette
                    )
                }

                Divider()

                HStack {
                    Text("總成本")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.label)

                    Spacer()

                    Text(formatTwd(store.costTwd))
                        .font(.subheadline.bold())
                        .monospacedDigit()
                        .foregroundStyle(palette.label)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// 拆解條的單列；以 ``BLProgressBar`` 表現各分類占總成本的比例，trailing 顯示原始 TWD 金額而非百分比
    ///
    /// `palette _:` 採用「外部 label `palette` + 內部名稱 `_`」的寫法：``BLProgressBar`` 自帶色盤推導、function body 不再讀取 palette
    ///
    /// 保留外部 label 與其他 helper (``inputsCard``、``suggestedHero`` 等) 一致，未來若需要客製拆解列的視覺也方便加回來
    /// - Parameters:
    ///   - label: 拆解項目的名稱 (如「商品金額」)
    ///   - value: 該項目的 TWD 金額
    ///   - total: 用來計算占比的總成本 (避免除以 0 時取 1)
    ///   - color: 進度條與分類的識別色
    ///   - palette: 目前外觀使用的色盤；目前未使用，預留給未來客製需求
    /// - Returns: 拆解列 view
    @ViewBuilder
    func breakdownRow(
        label: String,
        value: Double,
        total: Double,
        color: Color,
        palette _: BLPalette
    ) -> some View {
        let fraction = total > 0 ? value / total : 0

        BLProgressBar(
            title: label,
            value: fraction,
            tint: color,
            trailingText: formatTwd(value)
        )
    }
}

// MARK: - Private Method

private extension QuoteView {

    /// 依 App 選定 locale 產生幣別顯示文字
    /// 中文顯示名稱 (如「新台幣」)、其他語言顯示 ISO code (如「TWD」)
    /// - Parameter currency: 幣別
    /// - Returns: 顯示字串
    func currencyDisplayText(for currency: CurrencyCode) -> String {
        guard locale.language.languageCode?.identifier == "zh" else {
            return currency.rawValue
        }

        let name = locale.localizedString(forCurrencyCode: currency.rawValue) ?? ""
        return name.isEmpty ? currency.rawValue : name
    }

    /// 依 App 選定 locale 將金額格式化為新台幣 (無小數位)
    /// - Parameter amount: 金額
    /// - Returns: 依選定 locale 呈現的金額字串
    func formatTwd(_ amount: Double) -> String {
        Decimal(amount).formatted(
            .currency(code: CurrencyCode.twd.code)
            .precision(.fractionLength(0))
            .locale(locale)
        )
    }

    /// 依 App 選定 locale 將百分比格式化為含一位小數的字串
    /// - Parameter value: 百分比數值
    /// - Returns: 依選定 locale 呈現的百分比字串
    func formatPercent(_ value: Double) -> String {
        Decimal(value).formatted(.number.precision(.fractionLength(1)).locale(locale)) + "%"
    }
}

// MARK: - Preview

#Preview("報價試算") {
    NavigationStack {
        QuoteView(
            store: Store(initialState: QuoteFeature.State()) {
                QuoteFeature()
            }
        )
    }
}
