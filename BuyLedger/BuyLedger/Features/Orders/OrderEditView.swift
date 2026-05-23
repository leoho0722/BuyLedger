//
//  OrderEditView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import SwiftUI

/// 編輯或新增訂單的表單畫面。
///
/// 對應 ``OrderEditFeature``：以 sheet 形式呈現，包含取消與儲存按鈕。本切片表單只展示骨架欄位，實際資料寫入會在後續切片補上。
struct OrderEditView: View {
    
    // MARK: - View Properties
    
    /// 訂單編輯 store。
    @Bindable var store: StoreOf<OrderEditFeature>

    /// 是否顯示「商品類別」選擇 sheet。
    @State private var showsCategorySheet = false

    /// 是否顯示「付款方式」選擇 sheet。
    @State private var showsPaymentMethodSheet = false

    /// 是否顯示「幣別」選擇 sheet。
    @State private var showsCurrencySheet = false

    /// 用於 ``orderDateRow`` 在 picker 寫回時取得「當下這一刻」的秒；測試可注入固定值。
    @Dependency(\.date) private var date

    /// 訂購日期 footer 顯示使用的 locale；跟隨使用者手機設定，測試可注入固定值。
    ///
    /// 本 View 不直接使用此值，改透過 ``deviceLocale`` 包裝：TCA 預設的 `Locale.autoupdatingCurrent` 受 App 自身 `CFBundleDevelopmentRegion` 與支援的 localizations 影響，當 App 未掛使用者偏好語言時會回退到開發語言 (例如英文)。
    @Dependency(\.locale) private var locale

    // MARK: - View Body
    
    /// 編輯表單的畫面內容。
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("客戶名稱", text: $store.draftCustomerName)

                    categoryPickerRow

                    orderDateRow
                } header: {
                    Text("基本資料")
                } footer: {
                    VStack(alignment: .leading, spacing: BLSpacing.small) {
                        Text("訂購日期：\(OrderFormatters.fullTimestamp(store.draftDate, locale: deviceLocale))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()

                        if !canSave {
                            Text("客戶名稱為必填欄位。")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Section("狀態與幣別") {
                    Picker("狀態", selection: $store.draftStatus) {
                        ForEach(OrderStatus.allCases) { status in
                            Text(status.title).tag(status)
                        }
                    }

                    currencyPickerRow

                    paymentMethodPickerRow
                }
                
                Section {
                    decimalField(
                        title: "客戶實付",
                        value: $store.draftChargedAmount
                    )

                    if store.isSelectedPaymentMethodCardless {
                        decimalField(
                            title: "無卡折抵金額",
                            value: $store.draftCardlessDeductionAmount
                        )

                        decimalField(
                            title: "無卡補款金額",
                            value: $store.draftCardlessSupplementAmount
                        )
                    }
                } header: {
                    Text("收款金額 (NT$)")
                } footer: {
                    if store.isSelectedPaymentMethodCardless {
                        Text("無卡類付款方式才會啟用「折抵」與「補款」欄位；總收款 = 客戶實付 + 補款 − 折抵。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("成本 (NT$)") {
                    decimalField(title: "商品成本", value: $store.draftItemCost)
                    decimalField(title: "國內運費", value: $store.draftDomesticShipping)
                    decimalField(title: "外國國內運費", value: $store.draftForeignDomesticShipping)
                    decimalField(title: "國際集運", value: $store.draftInternationalShipping)
                }

                Section {
                    percentField(title: "刷卡手續費 %", value: $store.draftCardFeeRate)
                    percentField(title: "平台手續費 %", value: $store.draftPlatformFeeRate)
                    percentField(title: "金流手續費 %", value: $store.draftPaymentFeeRate)
                } header: {
                    Text("手續費 (%)")
                } footer: {
                    Text("輸入百分比例如 1.5 表示 1.5%；超出 0%–100% 範圍會自動限制。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                
                itemsSection
                
                if let original = store.original {
                    Section("原始訂單") {
                        LabeledContent("單號", value: original.id)
                            .monospacedDigit()
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(store.original == nil ? "新訂單" : "編輯訂單")
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        store.send(.cancelTapped)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("儲存") {
                        store.send(.saveTapped)
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canSave)
                }
            }
            .task {
                await store.send(.task).finish()
            }
            .sheet(isPresented: $showsCategorySheet) {
                OptionPickerSheet(
                    title: "選擇商品類別",
                    addButtonTitle: "新增類別",
                    emptyTitle: "尚無類別",
                    emptyDescription: "透過上方「新增類別」加入第一個類別。",
                    addAlertTitle: "新增商品類別",
                    addFieldPlaceholder: "類別名稱",
                    addAlertMessage: "輸入新的商品類別名稱，加入後會立即套用至此訂單。",
                    options: store.availableCategories,
                    selected: store.draftCategory,
                    onSelect: { category in
                        store.draftCategory = category
                    },
                    onAdd: { name in
                        store.send(.addCategoryTapped(name))
                    }
                )
            }
            .sheet(isPresented: $showsPaymentMethodSheet) {
                OptionPickerSheet(
                    title: "選擇付款方式",
                    addButtonTitle: "新增付款方式",
                    emptyTitle: "尚無付款方式",
                    emptyDescription: "透過上方「新增付款方式」加入第一個項目。",
                    addAlertTitle: "新增付款方式",
                    addFieldPlaceholder: "付款方式名稱",
                    addAlertMessage: "輸入新的付款方式名稱，加入後會立即套用至此訂單。",
                    options: store.availablePaymentMethods.map(\.name),
                    selected: store.draftPaymentMethod,
                    onSelect: { method in
                        store.draftPaymentMethod = method
                    },
                    onAddPaymentMethod: { name, isCardless in
                        store.send(.addPaymentMethodTapped(name: name, isCardless: isCardless))
                    }
                )
            }
            .sheet(isPresented: $showsCurrencySheet) {
                OptionPickerSheet(
                    title: "選擇幣別",
                    allowsAdd: false,
                    searchable: true,
                    emptyTitle: "尚無幣別",
                    emptyDescription: "需要網路連線載入幣別清單；請稍後再試。",
                    options: store.availableCurrencies.map(\.rawValue),
                    selected: store.draftCurrency.rawValue,
                    displayName: { code in
                        let name = Locale(identifier: Locale.preferredLanguages.first ?? Locale.current.identifier)
                            .localizedString(forCurrencyCode: code) ?? ""
                        return name.isEmpty ? code : "\(code) (\(name))"
                    },
                    searchKeywords: { code in
                        Locale(identifier: Locale.preferredLanguages.first ?? Locale.current.identifier)
                            .localizedString(forCurrencyCode: code) ?? ""
                    },
                    onSelect: { code in
                        store.draftCurrency = CurrencyCode(rawValue: code)
                    }
                )
            }
        }
#if os(macOS)
        .frame(minWidth: 540, minHeight: 520)
#endif
    }
}

// MARK: - ViewBuilder

private extension OrderEditView {

    /// 商品類別選擇列：以 `Menu` 列出既有類別並提供「新增類別」入口。
    ///
    /// 點擊「新增類別」會觸發畫面置中的 `.alert` 彈窗收集新類別名稱，送出後由 reducer 把名稱加入 ``OrderEditFeature/State/availableCategories`` 並設為目前選擇。
    var categoryPickerRow: some View {
        // 改成 Button + `.sheet`：iOS `Menu` 是 `UIMenu` 包裝，Button action 會被排到 menu collapse 動畫結束才派發，造成可見延遲。sheet 路徑下選擇即時 commit binding，視覺更新與 sheet 收合動畫互不阻擋。
        Button {
            showsCategorySheet = true
        } label: {
            HStack(spacing: BLSpacing.small) {
                Text("商品類別")
                    .foregroundStyle(.primary)

                Spacer(minLength: BLSpacing.small)

                Text(store.draftCategory.isEmpty ? "選擇類別" : store.draftCategory)
                    .foregroundStyle(store.draftCategory.isEmpty ? .secondary : .secondary)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 幣別選擇列：與 ``categoryPickerRow`` 相同的 sheet 體驗，但 sheet 不允許新增 (幣別來源僅限 ExchangeRate-API 支援清單)。
    var currencyPickerRow: some View {
        Button {
            showsCurrencySheet = true
        } label: {
            HStack(spacing: BLSpacing.small) {
                Text("幣別")
                    .foregroundStyle(.primary)

                Spacer(minLength: BLSpacing.small)

                Text(currencyDisplayText)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 付款方式選擇列：與 ``categoryPickerRow`` 相同的 sheet 體驗。
    var paymentMethodPickerRow: some View {
        Button {
            showsPaymentMethodSheet = true
        } label: {
            HStack(spacing: BLSpacing.small) {
                Text("付款方式")
                    .foregroundStyle(.primary)

                Spacer(minLength: BLSpacing.small)

                Text(store.draftPaymentMethod.isEmpty ? "選擇付款方式" : store.draftPaymentMethod)
                    .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 訂購日期編輯列：以 compact `DatePicker` 編輯日期與時分。
    ///
    /// `DatePicker(.compact)` 寫回時會把秒洗成 0，section footer 又以 `yyyy/MM/dd HH:mm:ss` 完整呈現，會造成視覺上「秒永遠是 :00」。改透過 wrapper binding 攔截寫入：每次 picker 寫回時取當下 `@Dependency(\.date).now` 的秒，組進新值，使秒隨每次編輯刷新成真實當下值，footer 看得到變化。
    var orderDateRow: some View {
        DatePicker(
            "訂購日期",
            selection: refreshingSecondsBinding,
            displayedComponents: [.date, .hourAndMinute]
        )
        .environment(\.locale, deviceLocale)
    }

    /// 商品明細區段：可逐項編輯名稱／數量／單價，亦可新增與刪除。
    var itemsSection: some View {
        Section {
            ForEach($store.draftItems) { $item in
                itemEditorRow(item: $item)
            }
            .onDelete { offsets in
                store.draftItems.remove(atOffsets: offsets)
            }
            
            Button {
                store.draftItems.append(
                    LedgerOrderItem(name: "", quantity: 1, unitPrice: 0)
                )
            } label: {
                Label("新增商品", systemImage: "plus.circle.fill")
            }
        } header: {
            Text("商品明細 (\(store.draftCurrency.rawValue))")
        } footer: {
            if store.draftItems.isEmpty {
                Text("還沒有任何商品；點擊「新增商品」開始填寫。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("商品單價以原始幣別記錄，總成本與獲利仍以上方「成本」欄位的 NT$ 數值為準。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    /// 單筆商品的編輯列：商品名稱 (多行)+ 數量 Stepper + 單價 TextField。
    /// - Parameter item: 雙向繫結的單筆商品。
    /// - Returns: 商品列 view。
    func itemEditorRow(item: Binding<LedgerOrderItem>) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            TextField("商品名稱", text: item.name, axis: .vertical)
                .font(.body.weight(.medium))
                .lineLimit(1...3)
            
            HStack(spacing: BLSpacing.medium) {
                Stepper(value: item.quantity, in: 1...999) {
                    Text("數量 \(item.quantity.wrappedValue)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
#if os(macOS)
                .controlSize(.small)
#endif
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("單價")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    TextField(
                        "",
                        value: item.unitPrice,
                        format: .number.precision(.fractionLength(0))
                    )
                    .labelsHidden()
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .frame(maxWidth: 120)
#if !os(macOS)
                    .keyboardType(.numberPad)
#endif
                }
            }
        }
    }
    
    /// 整數金額輸入欄。
    ///
    /// 把 `TextField` 的 placeholder 留空，避免在 macOS `.formStyle(.grouped)` 下 `LabeledContent` 與 `TextField` 同時顯示標題造成的重複文字。
    /// - Parameters:
    ///   - title: 欄位標題。
    ///   - value: 雙向繫結的值。
    /// - Returns: `LabeledContent` + `TextField` 組合 view。
    func decimalField(title: String, value: Binding<Decimal>) -> some View {
        LabeledContent(title) {
            TextField(
                "",
                value: value,
                format: .number.precision(.fractionLength(0))
            )
            .labelsHidden()
            .multilineTextAlignment(.trailing)
            .monospacedDigit()
#if !os(macOS)
            .keyboardType(.numberPad)
#endif
        }
    }
    
    /// 百分比輸入欄。
    ///
    /// 介面顯示 0–100 的百分比數字，內部以 0–1 的 ``Decimal`` 儲存以對應 ``LedgerOrder/cardFeeRate`` 等欄位的單位。`TextField` 的 placeholder 同樣留空，由 `LabeledContent` 提供唯一的標題。
    /// - Parameters:
    ///   - title: 欄位標題。
    ///   - value: 雙向繫結的 0–1 比例值。
    /// - Returns: `LabeledContent` + `TextField` 組合 view。
    func percentField(title: String, value: Binding<Decimal>) -> some View {
        let proxy = Binding<Double>(
            get: { NSDecimalNumber(decimal: value.wrappedValue).doubleValue * 100 },
            set: { newValue in
                value.wrappedValue = Decimal(newValue / 100)
            }
        )
        
        return LabeledContent(title) {
            HStack(spacing: 4) {
                TextField(
                    "",
                    value: proxy,
                    format: .number.precision(.fractionLength(2))
                )
                .labelsHidden()
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
#if !os(macOS)
                .keyboardType(.decimalPad)
#endif
                
                Text("%")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Private Method

private extension OrderEditView {
    
    /// 使用者在系統「語言與地區」實際偏好的 locale。
    ///
    /// 用 `Locale.preferredLanguages` 而非 `@Dependency(\.locale)` 預設值，原因是後者 (`Locale.autoupdatingCurrent`) 會被 App 自己的 `CFBundleDevelopmentRegion`／已掛載 localizations 限制，App 未掛 zh-Hant 時即使使用者手機是繁中也會回退到開發語言；`preferredLanguages` 才是使用者在系統設定面板親手挑的語言序列。測試／預覽時若需要固定 locale，可在 `@Dependency(\.locale)` 注入後讓 fallback 走到那裡。
    var deviceLocale: Locale {
        if let preferred = Locale.preferredLanguages.first {
            return Locale(identifier: preferred)
        }
        return locale
    }

    /// 是否允許按下儲存。
    ///
    /// 客戶名稱必須含有非空白字元才視為合法。即使儲存路徑保有 trim+fallback 的防禦邏輯，前端仍以 disable 按鈕的方式給使用者明確回饋。
    var canSave: Bool {
        !store.draftCustomerName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty
    }

    /// 幣別選擇列 label 顯示文字：「TWD (新台幣)」格式，跟 sheet 內列項與 ``OrderDetailView`` 上方 chip 一致。``Locale.localizedString(forCurrencyCode:)`` 沒有對應翻譯時 fallback 為 raw code。
    var currencyDisplayText: String {
        let code = store.draftCurrency.rawValue
        let name = deviceLocale.localizedString(forCurrencyCode: code) ?? ""
        return name.isEmpty ? code : "\(code) (\(name))"
    }

    /// 把 `DatePicker` 寫回的新值與「當下這一刻」`date.now` 的秒合併，產生帶秒精度的 ``OrderEditFeature/State/draftDate``。
    ///
    /// 採固定 `Calendar(identifier: .gregorian)` + UTC 時區做元件分解與重組：時區只影響 year/month/day/hour 的對應，不影響「秒」這個數值，因此在 UTC calendar 下抽秒、改秒、組回 Date，結果與使用者本地時區一致；且不依賴 `Calendar.current` / `Date()`，跟 `@Dependency(\.date)` 配合可在測試中固定當下時間。
    var refreshingSecondsBinding: Binding<Date> {
        Binding(
            get: { store.draftDate },
            set: { newValue in
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt

                let currentSeconds = calendar.component(.second, from: date.now)
                var components = calendar.dateComponents(
                    [.year, .month, .day, .hour, .minute],
                    from: newValue
                )
                components.second = currentSeconds
                store.draftDate = calendar.date(from: components) ?? newValue
            }
        )
    }
}

// MARK: - ViewBuilder

private extension OrderEditView {}

// MARK: - Preview

#Preview("新訂單") {
    OrderEditView(
        store: Store(initialState: OrderEditFeature.State()) {
            OrderEditFeature()
        }
    )
}

#Preview("編輯訂單") {
    OrderEditView(
        store: Store(
            initialState: OrderEditFeature.State(original: LedgerOrder.sampleOrders[0])
        ) {
            OrderEditFeature()
        }
    )
}
