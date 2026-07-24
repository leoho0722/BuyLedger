//
//  FxView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 匯率工具畫面
///
/// 對應設計稿 iPhone / iPad 的 FX tool：
/// - 來源幣別 chip 選擇
/// - 金額輸入欄
/// - 換算後 TWD 金額 (accent 卡片)
/// - 即時匯率列表
struct FxView: View {

    // MARK: - View Properties

    /// FX 功能 store
    @Bindable var store: StoreOf<FxFeature>

    /// 目前系統深淺色外觀
    @Environment(\.colorScheme) private var colorScheme

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 金額欄位的鍵盤焦點；實際狀態由 ``FxFeature/State/isAmountFieldFocused`` 持有
    @FocusState private var isAmountFieldFocused: Bool

    /// 金額輸入欄與換算結果的字級，隨 Dynamic Type 縮放 (以 `.title` 為基準)
    @ScaledMetric(relativeTo: .title) private var heroAmountSize: CGFloat = 32

    // MARK: - View Body

    /// FX 畫面內容
    var body: some View {
        let palette = BLPalette()

        ScrollView {
            VStack(alignment: .leading, spacing: BLSpacing.large) {
                statusBanner(palette: palette)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier(BLAccessibilityID.Fx.statusBanner)
                converterCard(palette: palette)
                quickAmountRow(palette: palette)
                ratesList(palette: palette)
            }
            .padding(.horizontal, BLSpacing.large)
            .padding(.vertical, BLSpacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityIdentifier(BLAccessibilityID.Fx.root)
        .background(palette.background)
        .navigationTitle(Text("匯率工具"))
        .scrollDismissesKeyboard(.interactively)
        .bind($store.isAmountFieldFocused, to: $isAmountFieldFocused)
        .toolbar {
            // 此畫面唯一的輸入為數字鍵盤，沒有 return 鍵可收
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

private extension FxView {

    /// 載入或錯誤狀態的橫幅
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 狀態 view；若無內容則為空
    @ViewBuilder
    func statusBanner(palette: BLPalette) -> some View {
        if store.isLoading {
            HStack(spacing: BLSpacing.small) {
                ProgressView()
                    .controlSize(.small)
                Text("正在更新匯率…")
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

                // 失敗時提供畫面內重試；`.task` 的守衛只擋載入中，失敗後可重新觸發
                Button("重試") {
                    store.send(.task)
                }
                .font(.footnote.weight(.semibold))
            }
            .padding(.horizontal, BLSpacing.medium)
            .padding(.vertical, BLSpacing.small)
            .background(palette.orange.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
        } else if store.snapshot != nil {
            HStack(spacing: BLSpacing.small) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(palette.green)
                Text("已連線到 ExchangeRate-API · \(snapshotDateText)")
                    .font(.footnote)
                    .foregroundStyle(palette.secondaryLabel)
                Spacer()
            }
            .padding(.horizontal, BLSpacing.medium)
            .padding(.vertical, BLSpacing.small)
            .background(palette.green.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
        }
    }

    /// 換算卡片：幣別選擇 + 金額輸入 + TWD 結果
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 換算卡 view
    @ViewBuilder
    func converterCard(palette: BLPalette) -> some View {
        BLCard {
            VStack(alignment: .leading, spacing: BLSpacing.medium) {
                Text("從")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.secondaryLabel)
                    .textCase(.uppercase)

                currencyPicker(palette: palette)

                Text("金額")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.secondaryLabel)
                    .textCase(.uppercase)
                    .padding(.top, BLSpacing.small)

                amountField(palette: palette)

                Divider().padding(.vertical, BLSpacing.small)

                resultBlock(palette: palette)
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
                    .accessibilityHidden(true)
            }
            .padding(.vertical, BLSpacing.small)
            .padding(.horizontal, BLSpacing.medium)
            .background(palette.fillTertiary)
            .clipShape(RoundedRectangle(cornerRadius: BLRadius.medium, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(BLAccessibilityID.Fx.currencyPickerButton)
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

    /// 金額輸入欄
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 金額欄 view
    @ViewBuilder
    func amountField(palette: BLPalette) -> some View {
        TextField(
            "輸入金額",
            value: $store.amount,
            format: .number.precision(.fractionLength(0...2))
        )
        .font(.system(size: heroAmountSize, weight: .bold))
        .monospacedDigit()
        .padding(.vertical, BLSpacing.medium)
        .padding(.horizontal, BLSpacing.medium)
        .background(palette.fillQuaternary)
        .clipShape(RoundedRectangle(cornerRadius: BLRadius.medium, style: .continuous))
        .keyboardType(.decimalPad)
        .focused($isAmountFieldFocused)
        .accessibilityIdentifier(BLAccessibilityID.Fx.amountField)
    }

    /// 結果區塊 (accent 背景)
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 結果 view
    @ViewBuilder
    func resultBlock(palette: BLPalette) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.extraSmall) {
            Text("= 新台幣")
                .font(.caption.weight(.semibold))
                .foregroundStyle(palette.accent)

            Text(formatTwd(store.convertedTwd))
                .font(.system(size: heroAmountSize, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(palette.accent)

            Text("1 \(store.fromCurrency.rawValue) = \(rateDisplay) TWD")
                .font(.caption)
                .foregroundStyle(palette.secondaryLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(BLSpacing.medium)
        .background(palette.accent.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: BLRadius.medium, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityValue(formatTwd(store.convertedTwd))
        .accessibilityIdentifier(BLAccessibilityID.Fx.convertedValue)
    }

    /// 快速金額按鈕列
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 快速金額列 view
    @ViewBuilder
    func quickAmountRow(palette: BLPalette) -> some View {
        let presets: [Decimal] = [10_000, 50_000, 100_000, 500_000]

        HStack(spacing: BLSpacing.small) {
            ForEach(presets, id: \.self) { value in
                Button {
                    store.send(.quickAmountTapped(value))
                } label: {
                    Text(presetLabel(value))
                        .font(.footnote.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, BLSpacing.small)
                        .background(store.amount == value ? palette.accent.opacity(0.18) : palette.fillTertiary)
                        .foregroundStyle(store.amount == value ? palette.accent : palette.label)
                        .clipShape(RoundedRectangle(cornerRadius: BLRadius.small, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// 即時匯率列表
    /// - Parameter palette: 目前外觀使用的色盤
    /// - Returns: 匯率列表 view
    @ViewBuilder
    func ratesList(palette: BLPalette) -> some View {
        BLCard(padding: 0) {
            LazyVStack(spacing: 0) {
                HStack {
                    Text("即時匯率 (對 TWD)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(palette.label)

                    Spacer()
                }
                .padding(.horizontal, BLSpacing.large)
                .padding(.top, BLSpacing.large)
                .padding(.bottom, BLSpacing.small)

                let displayed = ratesListCurrencies
                ForEach(Array(displayed.enumerated()), id: \.element) { index, currency in
                    rateRow(currency: currency, palette: palette)

                    if index < displayed.count - 1 {
                        Divider().padding(.leading, BLSpacing.large)
                    }
                }
            }
        }
    }

    /// 單一匯率列
    /// - Parameters:
    ///   - currency: 幣別
    ///   - palette: 目前外觀使用的色盤
    /// - Returns: 匯率列 view
    @ViewBuilder
    func rateRow(currency: CurrencyCode, palette: BLPalette) -> some View {
        HStack(spacing: BLSpacing.medium) {
            VStack(alignment: .leading) {
                Text("1 \(currency.rawValue)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(palette.label)

                Text(LocalizedStringKey(rateSourceSubtitle(for: currency)))
                    .font(.caption)
                    .foregroundStyle(palette.secondaryLabel)
            }

            Spacer()

            Text(rateDisplay(for: currency))
                .font(.title3.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(palette.label)
        }
        .padding(.horizontal, BLSpacing.large)
        .padding(.vertical, BLSpacing.medium)
    }
}

// MARK: - Private Method

private extension FxView {

    /// 顯示在連線成功 banner 上、依 App 選定 locale 格式化的快照時間
    var snapshotDateText: String {
        guard let snapshot = store.snapshot else {
            return "—"
        }
        return snapshot.date.formatted(
            .dateTime
                .month(.defaultDigits)
                .day(.defaultDigits)
                .hour(.defaultDigits(amPM: .omitted))
                .minute(.twoDigits)
                .locale(locale)
        )
    }

    /// 依 App 選定 locale 將金額格式化為新台幣 (無小數位)；`nil` 顯示為「—」
    func formatTwd(_ amount: Decimal?) -> String {
        guard let amount else {
            return "—"
        }
        return amount.formatted(
            .currency(code: CurrencyCode.twd.code)
            .precision(.fractionLength(0))
            .locale(locale)
        )
    }

    /// 顯示在結果區塊的 `1 X = N.NNNN TWD` 中的匯率字串
    var rateDisplay: String {
        rateDisplay(for: store.fromCurrency)
    }

    /// 依 App 選定 locale 將匯率格式化為四位小數的字串；無 snapshot 時顯示「—」
    func rateDisplay(for currency: CurrencyCode) -> String {
        guard let rate = store.state.displayRate(for: currency) else {
            return "—"
        }
        return rate.formatted(.number.precision(.fractionLength(4)).locale(locale))
    }

    /// 依 App 選定 locale 產生幣別顯示文字
    /// 中文顯示名稱 (如「新台幣」)、其他語言顯示 ISO code (如「TWD」)
    /// 用於來源幣別 button label 與 sheet
    /// - Parameter currency: 幣別
    /// - Returns: 顯示字串
    func currencyDisplayText(for currency: CurrencyCode) -> String {
        guard locale.language.languageCode?.identifier == "zh" else {
            return currency.rawValue
        }

        let name = locale.localizedString(forCurrencyCode: currency.rawValue) ?? ""
        return name.isEmpty ? currency.rawValue : name
    }

    /// 「即時匯率列表」顯示的幣別清單
    /// 以 ``FxFeature/State/availableCurrencies`` 為基礎、過濾掉基準幣別本身 (基準匯率永遠 1，無顯示意義)
    var ratesListCurrencies: [CurrencyCode] {
        store.availableCurrencies.filter { $0 != .twd }
    }

    /// 匯率列副標：顯示資料來源與依 App 選定 locale 格式化的 snapshot 時間戳；TWD 永遠顯示「基準幣別」、無 snapshot 時顯示「尚未連線」
    /// - Parameter currency: 幣別
    /// - Returns: 副標字串
    func rateSourceSubtitle(for currency: CurrencyCode) -> String {
        if currency == .twd { return "基準幣別" }
        guard let snapshot = store.snapshot else {
            return "尚未連線"
        }
        let timestamp = snapshot.date.formatted(
            .dateTime
                .month(.defaultDigits)
                .day(.defaultDigits)
                .hour(.defaultDigits(amPM: .omitted))
                .minute(.twoDigits)
                .locale(locale)
        )
        return "ExchangeRate-API · \(timestamp)"
    }

    /// 依 App 選定 locale 格式化的預設金額按鈕文字
    func presetLabel(_ value: Decimal) -> String {
        value.formatted(.number.precision(.fractionLength(0)).locale(locale))
    }
}

// MARK: - Preview

#Preview("匯率工具") {
    NavigationStack {
        FxView(
            store: Store(initialState: FxFeature.State()) {
                FxFeature()
            }
        )
    }
}
