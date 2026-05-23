//
//  QuoteView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 報價試算工具畫面。
///
/// 對應設計稿 iPhone Quote sheet 與 iPad/Mac 的 Quote tool：
/// - 來源幣別 chip
/// - 多個 slider (商品本金 / 國內運費 / 國際運費 / 刷卡手續費 / 目標毛利)
/// - 即時建議售價 (綠→青漸層 hero 卡)
/// - 成本拆解條與總成本
struct QuoteView: View {
    
    // MARK: - View Properties
    
    /// 報價試算 store。
    @Bindable var store: StoreOf<QuoteFeature>

    /// 目前系統深淺色外觀。
    @Environment(\.colorScheme) private var colorScheme

    /// 是否顯示幣別選擇 sheet。
    @State private var showsCurrencySheet = false
    
    // MARK: - View Body
    
    /// 報價試算畫面內容。
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
        .navigationTitle("報價試算")
        .task {
            await store.send(.task).finish()
        }
    }
}

// MARK: - ViewBuilder

private extension QuoteView {
    
    /// 匯率載入狀態的橫幅；無錯誤且已載入時不顯示。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 狀態 view。
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
                    .foregroundStyle(palette.tertiaryLabel)
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
    
    /// 輸入卡：客戶/商品 + 幣別 + 各項 slider。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 輸入卡 view。
    func inputsCard(palette: BLPalette) -> some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                Text("基本資料")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.tertiaryLabel)
                    .textCase(.uppercase)
                
                VStack(alignment: .leading, spacing: BLSpacing.small) {
                    Text("客戶")
                        .font(.footnote)
                        .foregroundStyle(palette.secondaryLabel)
                    
                    TextField("輸入客戶名稱", text: $store.customerName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: BLSpacing.small) {
                    Text("商品名稱")
                        .font(.footnote)
                        .foregroundStyle(palette.secondaryLabel)
                    
                    TextField("例如 Tamburins 香水 Chamo 50ml", text: $store.productName)
                        .textFieldStyle(.roundedBorder)
                }
                
                Text("商品資訊")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.tertiaryLabel)
                    .textCase(.uppercase)
                    .padding(.top, BLSpacing.small)
                
                currencyPicker(palette: palette)
                
                sliderRow(
                    label: "商品定價 (\(store.fromCurrency.rawValue))",
                    value: $store.itemPrice,
                    range: 0...500_000,
                    step: 1_000,
                    unit: store.fromCurrency.rawValue,
                    tint: palette.accent
                )
                
                sliderRow(
                    label: "當地運費 (\(store.fromCurrency.rawValue))",
                    value: $store.domesticShipping,
                    range: 0...20_000,
                    step: 500,
                    unit: store.fromCurrency.rawValue,
                    tint: palette.teal
                )
                
                sliderRow(
                    label: "國際運費 (TWD/件)",
                    value: $store.internationalShippingTwd,
                    range: 0...1_000,
                    step: 20,
                    unit: "TWD",
                    tint: palette.purple
                )
                
                sliderRow(
                    label: "刷卡手續費 %",
                    value: $store.cardFeePercent,
                    range: 0...5,
                    step: 0.1,
                    unit: "%",
                    tint: palette.orange,
                    fractionDigits: 1
                )
                
                sliderRow(
                    label: "目標毛利 %",
                    value: $store.targetMarginPercent,
                    range: 0...60,
                    step: 1,
                    unit: "%",
                    tint: palette.green
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    /// 來源幣別選擇按鈕：點開後以 sheet 列出主檔幣別供搜尋與選擇。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 幣別按鈕 view。
    func currencyPicker(palette: BLPalette) -> some View {
        Button {
            showsCurrencySheet = true
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
        .sheet(isPresented: $showsCurrencySheet) {
            OptionPickerSheet(
                title: "選擇來源幣別",
                allowsAdd: false,
                searchable: true,
                emptyTitle: "尚無幣別",
                emptyDescription: "需要網路連線載入幣別清單；請稍後再試。",
                options: store.availableCurrencies.map(\.rawValue),
                selected: store.fromCurrency.rawValue,
                displayName: { code in
                    let locale = Locale(identifier: Locale.preferredLanguages.first ?? Locale.current.identifier)
                    let name = locale.localizedString(forCurrencyCode: code) ?? ""
                    return name.isEmpty ? code : "\(code) · \(name)"
                },
                searchKeywords: { code in
                    Locale(identifier: Locale.preferredLanguages.first ?? Locale.current.identifier)
                        .localizedString(forCurrencyCode: code) ?? ""
                },
                onSelect: { code in
                    store.fromCurrency = CurrencyCode(rawValue: code)
                }
            )
        }
    }

    /// 把幣別 ISO code 轉成「TWD · 新台幣」顯示文字。
    /// - Parameter currency: 幣別。
    /// - Returns: 顯示字串。
    func currencyDisplayText(for currency: CurrencyCode) -> String {
        let locale = Locale(identifier: Locale.preferredLanguages.first ?? Locale.current.identifier)
        let name = locale.localizedString(forCurrencyCode: currency.rawValue) ?? ""
        return name.isEmpty ? currency.rawValue : "\(currency.rawValue) · \(name)"
    }
    
    /// 單一 slider 列。
    /// - Parameters:
    ///   - label: 顯示在上方的欄位名稱。
    ///   - value: 雙向繫結的值。
    ///   - range: slider 範圍。
    ///   - step: 滑動步進。
    ///   - unit: 顯示在右上角的單位字串。
    ///   - tint: slider 著色。
    ///   - fractionDigits: 數值顯示時的小數位數。
    /// - Returns: slider 列 view。
    func sliderRow(
        label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        unit: String,
        tint: Color,
        fractionDigits: Int = 0
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text("\(formatNumber(value.wrappedValue, fractionDigits: fractionDigits)) \(unit)")
                    .font(.footnote.weight(.semibold))
                    .monospacedDigit()
            }
            
            Slider(value: value, in: range, step: step)
                .tint(tint)
        }
    }
    
    /// 建議售價 hero 卡 (漸層綠→青)。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: hero 卡 view。
    func suggestedHero(palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
            if !targetSubtitle.isEmpty {
                Text(targetSubtitle)
                    .font(.footnote.weight(.medium))
                    .opacity(0.9)
                    .lineLimit(1)
            }
            
            Text("建議售價")
                .font(.caption.weight(.semibold))
                .opacity(0.95)
                .textCase(.uppercase)
            
            Text(formatTwd(store.suggestedTwd))
                .font(.system(size: 40, weight: .bold))
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
    
    /// 顯示在 hero 卡上方的「客戶 · 商品」副標；若兩者都空則隱藏。
    var targetSubtitle: String {
        let customer = store.customerName.trimmingCharacters(in: .whitespacesAndNewlines)
        let product = store.productName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch (customer.isEmpty, product.isEmpty) {
        case (true, true):
            return ""
        case (false, true):
            return customer
        case (true, false):
            return product
        case (false, false):
            return "\(customer) · \(product)"
        }
    }
    
    /// 成本拆解卡：每項條 + 總成本。
    /// - Parameter palette: 目前外觀使用的色盤。
    /// - Returns: 拆解卡 view。
    func breakdownCard(palette: BLPalette) -> some View {
        let total = max(store.costTwd, 1)
        let items: [(label: String, value: Double, color: Color)] = [
            ("商品金額", store.itemTwd, palette.accent),
            ("國內運費", store.domesticTwd, palette.teal),
            ("國際運費", store.internationalShippingTwd, palette.purple),
            ("刷卡手續費", store.cardFeeTwd, palette.orange),
        ]
        
        return BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                Text("成本拆解")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.tertiaryLabel)
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
    
    /// 拆解條的單列；以 ``BLProgressBar`` 表現各分類占總成本的比例，trailing 顯示原始 TWD 金額而非百分比。
    ///
    /// `palette _:` 採用「外部 label `palette` + 內部名稱 `_`」的寫法：``BLProgressBar`` 自帶色盤推導、function body 不再讀取 palette；保留外部 label 與其他 helper (``inputsCard``、``suggestedHero`` 等) 一致，未來若需要客製拆解列的視覺也方便加回來。
    /// - Parameters:
    ///   - label: 拆解項目的名稱 (如「商品金額」)。
    ///   - value: 該項目的 TWD 金額。
    ///   - total: 用來計算占比的總成本 (避免除以 0 時取 1)。
    ///   - color: 進度條與分類的識別色。
    ///   - palette: 目前外觀使用的色盤；目前未使用，預留給未來客製需求。
    /// - Returns: 拆解列 view。
    func breakdownRow(
        label: String,
        value: Double,
        total: Double,
        color: Color,
        palette _: BLPalette
    ) -> some View {
        let fraction = total > 0 ? value / total : 0
        
        return BLProgressBar(
            title: label,
            value: fraction,
            tint: color,
            trailingText: formatTwd(value)
        )
    }
}

// MARK: - Formatting

private extension QuoteView {
    
    /// 將數值格式化為指定小數位數。
    func formatNumber(_ value: Double, fractionDigits: Int) -> String {
        let value = Decimal(value)
        
        return value.formatted(.number.precision(.fractionLength(fractionDigits)))
    }
    
    /// 將金額格式化為新台幣 (無小數位)。
    func formatTwd(_ amount: Double) -> String {
        Decimal(amount).formatted(
            .currency(code: CurrencyCode.twd.code)
            .precision(.fractionLength(0))
            .locale(Locale(identifier: "zh_TW"))
        )
    }
    
    /// 將百分比格式化為含一位小數的字串。
    func formatPercent(_ value: Double) -> String {
        Decimal(value).formatted(.number.precision(.fractionLength(1))) + "%"
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
