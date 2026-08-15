//
//  QuoteView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 報價試算工具畫面
struct QuoteView: View {
    
    // MARK: - View Properties
    
    /// 報價試算 store
    @Bindable var store: StoreOf<QuoteFeature>
    
    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale
    
    /// 數值欄位的鍵盤焦點；實際狀態由 ``QuoteFeature/State/isAmountFieldFocused`` 持有
    @FocusState private var isAmountFieldFocused: Bool
    
    /// hero 建議售價字級，隨 Dynamic Type 縮放 (以 `.largeTitle` 為基準)
    @ScaledMetric(relativeTo: .largeTitle) private var heroPriceSize: CGFloat = 40
    
    // MARK: - View Body
    
    /// 報價試算畫面內容
    var body: some View {
        let palette = BLPalette()
        
        ScrollView {
            VStack(alignment: .leading, spacing: BLSpacing.large) {
                statusBanner(palette: palette)
                inputsCard(palette: palette)
                suggestedHero()
                breakdownCard(palette: palette)
            }
            .padding(.horizontal, BLSpacing.large)
            .padding(.vertical, BLSpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier(BLAccessibilityID.Quote.root)
        .background(palette.background)
        .navigationTitle(Text("報價試算"))
        .scrollDismissesKeyboard(.interactively)
        .bind($store.isAmountFieldFocused, to: $isAmountFieldFocused)
        .toolbar {
            // 此畫面的輸入皆為數字鍵盤，沒有 return 鍵可收
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                
                Button {
                    store.send(.binding(.set(\.isAmountFieldFocused, false)))
                } label: {
                    Image(systemName: "checkmark")
                }
                .accessibilityLabel(Text("完成"))
                .accessibilityIdentifier(BLAccessibilityID.Common.keyboardDoneButton)
            }
        }
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
                    .blTextStyle(.footnote)
                    .foregroundStyle(palette.secondaryLabel)
                Spacer()
            }
            .padding(.horizontal, BLSpacing.medium)
            .padding(.vertical, BLSpacing.small)
            .background(palette.fillTertiary)
            .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(BLAccessibilityID.Quote.statusBanner)
        } else if let reason = store.rateUnavailableReason {
            // 顯示失敗原因與重試，不只顯示破折號。
            HStack(alignment: .top, spacing: BLSpacing.small) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(palette.orange)
                
                Text(reason)
                    .blTextStyle(.footnote)
                    .foregroundStyle(palette.label)
                
                Spacer()
                
                Button {
                    store.send(.rateRefreshRequested)
                } label: {
                    Text("重試")
                        .font(BLTypographyStyle.footnote.font.weight(.semibold))
                        // 命中區宣告在標籤內部撐到 44pt；視覺尺寸不變
                        .frame(minHeight: BLHitTarget.minimum)
                        .contentShape(.rect)
                }
                .accessibilityIdentifier(BLAccessibilityID.Quote.retryButton)
            }
            .padding(.horizontal, BLSpacing.medium)
            .padding(.vertical, BLSpacing.small)
            .background(palette.orange.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(BLAccessibilityID.Quote.statusBanner)
        } else if !store.isTargetMarginBelowOneHundredPercent {
            HStack(spacing: BLSpacing.small) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(palette.secondaryLabel)
                
                Text("目標毛利需低於 100% 才能計算建議售價。")
                    .blTextStyle(.footnote)
                    .foregroundStyle(palette.secondaryLabel)
                
                Spacer()
            }
            .padding(.horizontal, BLSpacing.medium)
            .padding(.vertical, BLSpacing.small)
            .background(palette.fillQuaternary)
            .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(BLAccessibilityID.Quote.statusBanner)
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
                    .font(BLTypographyStyle.caption.font.weight(.semibold))
                    .foregroundStyle(palette.secondaryLabel)
                    .textCase(.uppercase)
                
                currencyPicker(palette: palette)
                
                numberField(
                    label: "商品定價",
                    value: $store.itemPrice,
                    unit: store.fromCurrency.rawValue,
                    palette: palette,
                    allowsDecimalEntry: true,
                    identifier: BLAccessibilityID.Quote.principalField
                )
                
                numberField(
                    label: "當地運費",
                    value: $store.domesticShipping,
                    unit: store.fromCurrency.rawValue,
                    palette: palette,
                    allowsDecimalEntry: true
                )
                
                numberField(
                    label: "國際運費",
                    value: $store.internationalShippingTwd,
                    unit: "TWD/件",
                    palette: palette
                )
                
                numberField(
                    label: "刷卡手續費",
                    value: $store.cardFeePercent,
                    unit: "%",
                    palette: palette,
                    fractionDigits: 1
                )
                
                numberField(
                    label: "金流手續費",
                    value: $store.paymentFeePercent,
                    unit: "%",
                    palette: palette,
                    fractionDigits: 1
                )
                
                numberField(
                    label: "平台手續費",
                    value: $store.platformFeePercent,
                    unit: "%",
                    palette: palette,
                    fractionDigits: 1
                )
                
                numberField(
                    label: "目標毛利",
                    value: $store.targetMarginPercent,
                    unit: "%",
                    palette: palette
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
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .foregroundStyle(palette.secondaryLabel)
                
                Spacer()
                
                Text(currencyDisplayText(for: store.fromCurrency))
                    .font(BLTypographyStyle.subhead.font.weight(.semibold))
                    .foregroundStyle(palette.label)
                    .lineLimit(1)
                
                Image(systemName: "chevron.right")
                    .font(BLTypographyStyle.caption.font.weight(.semibold))
                    .foregroundStyle(palette.tertiaryLabel)
                    .accessibilityHidden(true)
            }
            .padding(.vertical, BLSpacing.small)
            .padding(.horizontal, BLSpacing.medium)
            .background(palette.fillTertiary)
            .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(BLAccessibilityID.Quote.currencyPickerButton)
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
    
    /// 數值輸入列，支援直接輸入精確數值
    /// - Parameters:
    ///   - label: 欄位名稱
    ///   - value: 雙向繫結的值；寫入時自動 clamp 成非負數
    ///   - unit: 顯示在輸入框右側的單位字串
    ///   - palette: 目前外觀使用的設計系統色盤
    ///   - fractionDigits: 顯示的小數位數
    ///   - allowsDecimalEntry: 是否允許輸入小數
    ///   - identifier: UI 測試定位用的識別碼
    /// - Returns: 數值輸入列 view
    @ViewBuilder
    func numberField(
        label: String,
        value: Binding<Decimal>,
        unit: String,
        palette: BLPalette,
        fractionDigits: Int = 0,
        allowsDecimalEntry: Bool = false,
        identifier: String? = nil
    ) -> some View {
        HStack(spacing: BLSpacing.small) {
            Text(LocalizedStringKey(label))
                .blTextStyle(.subhead)
                .foregroundStyle(palette.secondaryLabel)
            // 長標籤 (如 International Shipping) 換行顯示、不截斷
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField(
                "0",
                value: value,
                format: .number.precision(
                    allowsDecimalEntry ? .fractionLength(0...2) : .fractionLength(fractionDigits)
                )
                .grouping(.never)
            )
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.trailing)
            .monospacedDigit()
            .frame(width: 120)
            .keyboardType(allowsDecimalEntry || fractionDigits > 0 ? .decimalPad : .numberPad)
            .focused($isAmountFieldFocused)
            // 未指定時傳空字串，等同系統預設，不改變其他呼叫點的無障礙行為
            .accessibilityIdentifier(identifier ?? "")
            
            Text(LocalizedStringKey(unit))
                .blTextStyle(.footnote)
                .foregroundStyle(palette.secondaryLabel)
                .lineLimit(1)
            // 短單位對齊 60pt，較長單位 (如 TWD/item) 自適應變寬、不截斷
                .frame(minWidth: 60, alignment: .leading)
        }
    }
    
    /// 建議售價 hero 卡 (沿用設計系統主卡漸層)
    /// - Returns: hero 卡 view
    @ViewBuilder
    func suggestedHero() -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
            Text("建議售價")
                .font(BLTypographyStyle.caption.font.weight(.semibold))
                .textCase(.uppercase)
            
            // 無匯率或毛利不可計算時顯示破折號，避免把零誤認為結果。
            Text(heroPriceText)
                .font(.system(size: heroPriceSize, weight: .bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            
            if !store.hasUsableRate {
                Text("尚無可用匯率資料，暫時無法試算。")
                    .blTextStyle(.footnote)
            } else if let profitTwd = store.estimatedProfitTwd,
                      let marginPercent = store.estimatedMarginPercent
            {
                Text(
                    """
                    預估獲利 \(BLFormatters.twd(profitTwd, locale: locale)) · \
                    \(BLFormatters.percent(scaled: marginPercent, locale: locale))
                    """
                )
                .blTextStyle(.footnote)
            } else {
                Text("目標毛利需低於 100% 才能計算建議售價。")
                    .blTextStyle(.footnote)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BLSpacing.large)
        // 測試漸層上的固定白字，需保留 .white
        .foregroundStyle(.white)
        // 使用低亮度漸層確保白字對比度。
        // 此配色由 ContrastComplianceTests 驗證
        .blHeroCardBackground()
        .blCardShadow()
        // 合併為單一朗讀單位，建議售價數值落在 element.value 供測試讀取
        .accessibilityElement(children: .combine)
        .accessibilityValue(heroPriceText)
        .accessibilityIdentifier(BLAccessibilityID.Quote.suggestedPriceValue)
    }
    
    /// 成本拆解卡：每項條 + 總成本
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 拆解卡 view
    @ViewBuilder
    func breakdownCard(palette: BLPalette) -> some View {
        if store.hasUsableRate {
            usableBreakdownCard(palette: palette)
        } else {
            // 無匯率時整卡改為說明性空狀態，不繪製零值進度條
            BLCard {
                ContentUnavailableView {
                    Label("尚無可用匯率資料", systemImage: "dollarsign.arrow.circlepath")
                } description: {
                    Text("需要網路連線載入匯率後才能拆解成本；請稍後再試。")
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
    
    /// 有可用匯率時的成本拆解內容
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 拆解卡 view
    @ViewBuilder
    func usableBreakdownCard(palette: BLPalette) -> some View {
        let total = max(store.costTwd, 1)
        let items: [(label: String, value: Decimal, color: Color)] = [
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
                    .font(BLTypographyStyle.caption.font.weight(.semibold))
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
                        .font(BLTypographyStyle.subhead.font.weight(.semibold))
                        .foregroundStyle(palette.label)
                    
                    Spacer()
                    
                    Text(BLFormatters.twd(store.costTwd, locale: locale))
                        .font(BLTypographyStyle.subhead.font.bold())
                        .monospacedDigit()
                        .foregroundStyle(palette.label)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    /// 成本拆解的一列，顯示比例與 TWD 金額
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
        value: Decimal,
        total: Decimal,
        color: Color,
        palette _: BLPalette
    ) -> some View {
        let fraction = total > 0 ? value / total : 0
        // Decimal 到繪圖邊界才轉成浮點數
        let fractionDouble = NSDecimalNumber(decimal: fraction).doubleValue
        
        BLProgressBar(
            title: label,
            value: fractionDouble,
            tint: color,
            trailingText: BLFormatters.twd(value, locale: locale)
        )
    }
}

// MARK: - Private Method

private extension QuoteView {
    
    /// 建議售價顯示文字；無法計算時顯示破折號
    var heroPriceText: String {
        guard store.hasUsableRate, let suggestedTwd = store.suggestedTwd else {
            return "—"
        }
        return BLFormatters.twd(suggestedTwd, locale: locale)
    }
    
    /// 依 App 選定 locale 產生幣別顯示文字
    /// - Parameter currency: 幣別
    /// - Returns: 顯示字串
    func currencyDisplayText(for currency: CurrencyCode) -> String {
        guard locale.language.languageCode?.identifier == "zh" else {
            return currency.rawValue
        }
        
        let name = locale.localizedString(forCurrencyCode: currency.rawValue) ?? ""
        return name.isEmpty ? currency.rawValue : name
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
