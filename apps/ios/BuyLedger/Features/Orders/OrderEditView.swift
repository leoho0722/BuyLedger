//
//  OrderEditView.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/5/1.
//

import ComposableArchitecture
import PhotosUI
import SwiftUI

/// 編輯或新增訂單的表單畫面
///
/// 對應 ``OrderEditFeature``：以 sheet 形式呈現，包含取消與儲存按鈕，以及訂單來源／商品類別／付款方式／對帳狀態的選擇與即時新增入口。儲存時由父層 ``OrdersFeature`` 將草稿寫回資料庫
struct OrderEditView: View {

    // MARK: - View Properties

    /// 訂單編輯 store
    @Bindable var store: StoreOf<OrderEditFeature>

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    // MARK: - View Body

    /// 編輯表單的畫面內容
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("客戶名稱", text: $store.draftCustomerName)

                    orderSourcePickerRow

                    categoryPickerRow

                    orderDateRow
                } header: {
                    Text("基本資料")
                } footer: {
                    VStack(alignment: .leading, spacing: BLSpacing.small) {
                        Text("訂購日期：\(OrderFormatters.fullTimestamp(store.draftDate, locale: locale))")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()

                        if !canSave {
                            Text("客戶名稱、訂單來源與商品類別皆為必填欄位。")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("狀態與幣別") {
                    Picker("狀態", selection: $store.draftStatus) {
                        ForEach(store.availableStatuses) { status in
                            Text(LocalizedStringKey(status.title)).tag(status)
                        }
                    }

                    currencyPickerRow

                    paymentMethodPickerRow

                    if store.showsVerificationStatusRow {
                        verificationStatusPickerRow
                    }
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

                Section("開團與收款") {
                    if store.isMergeContext {
                        // 合併情境：開團改為多選 trigger row + 多選 sheet
                        campaignPickerRow
                    } else {
                        Picker("開團", selection: campaignSelectionBinding) {
                            Text("未歸團").tag("")
                            ForEach(store.availableCampaigns, id: \.self) { name in
                                Text(name).tag(name)
                            }
                        }
                    }

                    Picker("收款狀態", selection: $store.draftPaymentReceiptStatus) {
                        ForEach(PaymentReceiptStatus.allCases) { status in
                            Text(LocalizedStringKey(status.title)).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    decimalField(title: "商品成本", value: $store.draftItemCost)
                    decimalField(title: "外國國內運費", value: $store.draftForeignDomesticShipping)
                    decimalField(title: "國際運費", value: $store.draftInternationalShipping)
                    decimalField(title: "國內運費", value: $store.draftDomesticShipping)
                } header: {
                    Text("成本 (NT$)")
                } footer: {
                    if store.isSelectedPaymentMethodCOD {
                        Text("貨到付款：收款金額已含預估運費，獲利會自動扣除上方三種運費 (國內 + 國際 + 外國國內)。")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
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

                notesSection

                photosSection

                if let original = store.original {
                    Section("原始訂單") {
                        LabeledContent("單號", value: original.id)
                            .monospacedDigit()
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(Text(LocalizedStringKey(store.original == nil ? "新訂單" : "編輯訂單")))
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        store.send(.cancelTapped)
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel(Text("取消"))
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
            .sheet(isPresented: $store.showsOrderSourceSheet) {
                OptionPickerSheet(
                    title: "選擇訂單來源",
                    addButtonTitle: "新增來源",
                    emptyTitle: "尚無來源",
                    emptyDescription: "透過上方「新增來源」加入第一個訂單來源。",
                    addAlertTitle: "新增訂單來源",
                    addFieldPlaceholder: "來源名稱",
                    addAlertMessage: "輸入新的訂單來源名稱，加入後會立即套用至此訂單。",
                    options: store.availableOrderSources,
                    selected: store.draftOrderSource,
                    onSelect: { source in
                        store.send(.orderSourceSelected(source))
                    },
                    onAdd: { name in
                        store.send(.addOrderSourceTapped(name))
                    }
                )
            }
            .sheet(isPresented: $store.showsCategorySheet) {
                if store.isMergeContext {
                    // 合併情境：多選模式，點列 toggle、以「完成」結束選取；新增類別流程沿用
                    OptionPickerSheet(
                        title: "選擇商品類別",
                        addButtonTitle: "新增類別",
                        emptyTitle: "尚無類別",
                        emptyDescription: "透過上方「新增類別」加入第一個類別。",
                        addAlertTitle: "新增商品類別",
                        addFieldPlaceholder: "類別名稱",
                        addAlertMessage: "輸入新的商品類別名稱，加入後會立即套用至此訂單。",
                        options: store.availableCategories,
                        onAdd: { name in
                            store.send(.addCategoryTapped(name))
                        },
                        multiSelection: .init(
                            selections: Set(store.draftCategories),
                            onToggle: { category in
                                store.send(.categoryToggled(category))
                            }
                        )
                    )
                } else {
                    OptionPickerSheet(
                        title: "選擇商品類別",
                        addButtonTitle: "新增類別",
                        emptyTitle: "尚無類別",
                        emptyDescription: "透過上方「新增類別」加入第一個類別。",
                        addAlertTitle: "新增商品類別",
                        addFieldPlaceholder: "類別名稱",
                        addAlertMessage: "輸入新的商品類別名稱，加入後會立即套用至此訂單。",
                        options: store.availableCategories,
                        selected: store.draftCategories.first ?? "",
                        onSelect: { category in
                            store.send(.categorySelected(category))
                        },
                        onAdd: { name in
                            store.send(.addCategoryTapped(name))
                        }
                    )
                }
            }
            .sheet(isPresented: $store.showsCampaignSheet) {
                OptionPickerSheet(
                    title: "選擇開團",
                    allowsAdd: false,
                    emptyTitle: "尚無開團",
                    emptyDescription: "請先在「開團」頁建立開團，再回到此處歸團。",
                    options: store.availableCampaigns,
                    multiSelection: .init(
                        selections: Set(store.draftCampaignNames),
                        onToggle: { name in
                            store.send(.campaignToggled(name))
                        }
                    )
                )
            }
            .sheet(isPresented: $store.showsPaymentMethodSheet) {
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
                        store.send(.paymentMethodSelected(method))
                    },
                    onAddPaymentMethod: { name, isCardless, isBankTransfer, isCashOnDelivery in
                        store.send(.addPaymentMethodTapped(name: name, isCardless: isCardless, isBankTransfer: isBankTransfer, isCashOnDelivery: isCashOnDelivery))
                    }
                )
            }
            .sheet(isPresented: $store.showsVerificationStatusSheet) {
                OptionPickerSheet(
                    title: "選擇對帳狀態",
                    addButtonTitle: "新增對帳狀態",
                    emptyTitle: "尚無對帳狀態",
                    emptyDescription: "透過上方「新增對帳狀態」加入第一個項目。",
                    addAlertTitle: "新增對帳狀態",
                    addFieldPlaceholder: "對帳狀態名稱",
                    addAlertMessage: "輸入新的對帳狀態名稱，加入後會立即套用至此訂單。",
                    options: store.availableVerificationStatuses,
                    selected: store.draftVerificationStatus,
                    onSelect: { status in
                        store.send(.verificationStatusSelected(status))
                    },
                    onAddViaNameSheet: { name in
                        store.send(.addVerificationStatusTapped(name))
                    }
                )
            }
            .sheet(isPresented: $store.showsCurrencySheet) {
                let locale = locale

                OptionPickerSheet(
                    title: "選擇幣別",
                    allowsAdd: false,
                    searchable: true,
                    emptyTitle: "尚無幣別",
                    emptyDescription: "需要網路連線載入幣別清單；請稍後再試。",
                    options: store.availableCurrencies.map(\.rawValue),
                    selected: store.draftCurrency.rawValue,
                    displayName: { code in
                        let name = locale.localizedString(forCurrencyCode: code) ?? ""
                        return name.isEmpty ? code : "\(code) (\(name))"
                    },
                    searchKeywords: { code in
                        locale.localizedString(forCurrencyCode: code) ?? ""
                    },
                    onSelect: { code in
                        store.send(.currencySelected(code))
                    }
                )
            }
            .sheet(item: $store.photoViewerSelection) { selection in
                // 統一以 sheet 呈現照片檢視器：title 置中顯示計數、右上 toolbar ✕ 關閉
                BLPhotoViewer(
                    photos: store.draftPhotos,
                    initialIndex: selection.id
                ) {
                    store.send(.photoViewerDismissed)
                }
            }
        }
    }
}

// MARK: - ViewBuilder

private extension OrderEditView {

    /// 訂單來源選擇列：操作邏輯與 ``categoryPickerRow`` 完全一致——以 sheet 列出既有來源並提供「新增來源」入口
    ///
    /// 點擊「新增來源」會收集新來源名稱，送出後由 reducer 把名稱加入 ``OrderEditFeature/State/availableOrderSources`` 並設為目前選擇
    @ViewBuilder
    var orderSourcePickerRow: some View {
        Button {
            store.send(.orderSourcePickerTapped)
        } label: {
            HStack(spacing: BLSpacing.small) {
                Text("訂單來源")
                    .foregroundStyle(.primary)

                Spacer(minLength: BLSpacing.small)

                Group {
                    if store.draftOrderSource.isEmpty {
                        Text("選擇來源")
                    } else {
                        Text(verbatim: store.draftOrderSource)
                    }
                }
                .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 商品類別選擇列：以 `Menu` 列出既有類別並提供「新增類別」入口
    ///
    /// 點擊「新增類別」會觸發畫面置中的 `.alert` 彈窗收集新類別名稱，送出後由 reducer 把名稱加入 ``OrderEditFeature/State/availableCategories`` 並設為目前選擇
    @ViewBuilder
    var categoryPickerRow: some View {
        // 改成 Button + `.sheet`：iOS `Menu` 是 `UIMenu` 包裝，Button action 會被排到 menu collapse
        // 動畫結束才派發，造成可見延遲。sheet 路徑下選擇即時 commit binding，視覺更新與 sheet 收合動畫互不阻擋
        Button {
            store.send(.categoryPickerTapped)
        } label: {
            HStack(spacing: BLSpacing.small) {
                Text("商品類別")
                    .foregroundStyle(.primary)

                Spacer(minLength: BLSpacing.small)

                Group {
                    if store.draftCategories.isEmpty {
                        Text("選擇類別")
                    } else {
                        Text(verbatim: store.categoriesDisplayText)
                    }
                }
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 開團選擇列 (僅合併情境)：以 trigger row 開啟多選 sheet；顯示文字以「、」串接已選開團、空選取顯示「未歸團」
    @ViewBuilder
    var campaignPickerRow: some View {
        Button {
            store.send(.campaignPickerTapped)
        } label: {
            HStack(spacing: BLSpacing.small) {
                Text("開團")
                    .foregroundStyle(.primary)

                Spacer(minLength: BLSpacing.small)

                Group {
                    if store.draftCampaignNames.isEmpty {
                        Text("未歸團")
                    } else {
                        Text(verbatim: store.campaignsDisplayText)
                    }
                }
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.trailing)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 幣別選擇列：與 ``categoryPickerRow`` 相同的 sheet 體驗，但 sheet 不允許新增 (幣別來源僅限 ExchangeRate-API 支援清單)
    @ViewBuilder
    var currencyPickerRow: some View {
        Button {
            store.send(.currencyPickerTapped)
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

    /// 付款方式選擇列：與 ``categoryPickerRow`` 相同的 sheet 體驗
    @ViewBuilder
    var paymentMethodPickerRow: some View {
        Button {
            store.send(.paymentMethodPickerTapped)
        } label: {
            HStack(spacing: BLSpacing.small) {
                Text("付款方式")
                    .foregroundStyle(.primary)

                Spacer(minLength: BLSpacing.small)

                Group {
                    if store.draftPaymentMethod.isEmpty {
                        Text("選擇付款方式")
                    } else {
                        Text(verbatim: store.draftPaymentMethod)
                    }
                }
                .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 對帳狀態選擇列：操作體驗比照 ``paymentMethodPickerRow``，但新增動作走 name-only medium sheet (見 ``OptionPickerSheet`` 的 `onAddViaNameSheet`)。僅在選到的付款方式屬於無卡或銀行匯款 (``OrderEditFeature/State/showsVerificationStatusRow`` 為 `true`) 時，由 caller 條件顯示於「付款方式」row 底下
    @ViewBuilder
    var verificationStatusPickerRow: some View {
        Button {
            store.send(.verificationStatusPickerTapped)
        } label: {
            HStack(spacing: BLSpacing.small) {
                Text("對帳狀態")
                    .foregroundStyle(.primary)

                Spacer(minLength: BLSpacing.small)

                Group {
                    if store.draftVerificationStatus.isEmpty {
                        Text("選擇對帳狀態")
                    } else {
                        Text(verbatim: store.draftVerificationStatus)
                    }
                }
                .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// 訂購日期編輯列：以 compact `DatePicker` 編輯日期與時分
    ///
    /// `DatePicker(.compact)` 寫回時會把秒洗成 0，section footer 又以 `yyyy/MM/dd HH:mm:ss` 完整呈現，會造成視覺上「秒永遠是 :00」。改透過 ``refreshingSecondsBinding`` 攔截寫入：每次 picker 寫回時交給 reducer 以注入時間補上當下秒數，使秒隨每次編輯刷新成真實當下值，footer 看得到變化
    @ViewBuilder
    var orderDateRow: some View {
        DatePicker(
            "訂購日期",
            selection: refreshingSecondsBinding,
            displayedComponents: [.date, .hourAndMinute]
        )
        .datePickerStyle(.compact)
        .environment(\.locale, locale)
    }

    /// 商品明細區段：可逐項編輯名稱／數量／單價，亦可新增與刪除
    @ViewBuilder
    var itemsSection: some View {
        Section {
            ForEach($store.draftItems) { $item in
                itemEditorRow(item: $item)
            }
            .onDelete { offsets in
                store.send(.deleteItems(offsets))
            }

            Button {
                store.send(.addItemTapped)
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

    /// 備註區段：商品明細下方的多行備註輸入；留空代表無備註，儲存時會 trim 首尾空白
    @ViewBuilder
    var notesSection: some View {
        Section {
            TextField("輸入備註 (選填)", text: $store.draftNotes, axis: .vertical)
                .lineLimit(3...8)
        } header: {
            Text("備註")
        }
    }

    /// 訂單照片區段：已加入照片的縮圖橫列 + PhotosPicker 加入按鈕與計數標籤
    ///
    /// 加入按鈕僅在尚未達 ``LedgerOrder/maxPhotoCount`` 上限時顯示；picker 的 `maxSelectionCount` 設為剩餘容量，reducer 端另以截斷守門
    @ViewBuilder
    var photosSection: some View {
        Section {
            if !store.draftPhotos.isEmpty {
                ScrollView(.horizontal) {
                    HStack(spacing: BLSpacing.small) {
                        ForEach(Array(store.draftPhotos.enumerated()), id: \.offset) { index, data in
                            BLPhotoThumbnail(
                                imageData: data,
                                onTap: {
                                    store.send(.photoTapped(index))
                                }
                            ) {
                                store.send(.deletePhotoTapped(index))
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)
            }

            if store.canAddMorePhotos {
                PhotosPicker(
                    selection: $store.photoPickerSelection,
                    maxSelectionCount: store.remainingPhotoCapacity,
                    matching: .images
                ) {
                    Label("加入照片", systemImage: "photo.badge.plus")
                }
            }
        } header: {
            Text("訂單照片 (\(store.draftPhotos.count)/\(LedgerOrder.maxPhotoCount))")
        } footer: {
            Text("最多 \(LedgerOrder.maxPhotoCount) 張；照片會縮圖壓縮後隨訂單儲存。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    /// 單筆商品的編輯列：商品名稱 (多行)+ 數量 Stepper + 單價 TextField
    /// - Parameter item: 雙向繫結的單筆商品
    /// - Returns: 商品列 view
    @ViewBuilder
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
                    .keyboardType(.numberPad)
                }
            }
        }
    }

    /// 整數金額輸入欄
    ///
    /// 把 `TextField` 的 placeholder 留空，避免 `.formStyle(.grouped)` 下 `LabeledContent` 與 `TextField` 同時顯示標題造成的重複文字
    /// - Parameters:
    ///   - title: 欄位標題
    ///   - value: 雙向繫結的值
    /// - Returns: `LabeledContent` + `TextField` 組合 view
    @ViewBuilder
    func decimalField(title: String, value: Binding<Decimal>) -> some View {
        HStack(alignment: .center, spacing: BLSpacing.small) {
            // 長標籤換行並撐高整列，值在多行標籤中垂直置中
            Text(LocalizedStringKey(title))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            TextField(
                "",
                value: value,
                format: .number.precision(.fractionLength(0))
            )
            .labelsHidden()
            .multilineTextAlignment(.trailing)
            .monospacedDigit()
            .keyboardType(.numberPad)
            .frame(maxWidth: 140, alignment: .trailing)
        }
    }

    /// 百分比輸入欄
    ///
    /// 介面顯示 0–100 的百分比數字，內部以 0–1 的 ``Decimal`` 儲存以對應 ``LedgerOrder/cardFeeRate`` 等欄位的單位。`TextField` 的 placeholder 同樣留空，由 `LabeledContent` 提供唯一的標題
    /// - Parameters:
    ///   - title: 欄位標題
    ///   - value: 雙向繫結的 0–1 比例值
    /// - Returns: `LabeledContent` + `TextField` 組合 view
    @ViewBuilder
    func percentField(title: String, value: Binding<Decimal>) -> some View {
        let proxy = Binding<Double>(
            get: { NSDecimalNumber(decimal: value.wrappedValue).doubleValue * 100 },
            set: { newValue in
                value.wrappedValue = Decimal(newValue / 100)
            }
        )

        HStack(alignment: .center, spacing: BLSpacing.small) {
            // 長標籤換行並撐高整列，值在多行標籤中垂直置中
            Text(LocalizedStringKey(title))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                TextField(
                    "",
                    value: proxy,
                    format: .number.precision(.fractionLength(2))
                )
                .labelsHidden()
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .keyboardType(.decimalPad)

                Text("%")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 140, alignment: .trailing)
        }
    }
}

// MARK: - Private Method

private extension OrderEditView {

    /// 是否允許按下儲存
    ///
    /// 客戶名稱與訂單來源必須含有非空白字元、商品類別至少選一個才視為合法。即使儲存路徑保有 trim+fallback 的防禦邏輯，前端仍以 disable 按鈕的方式給使用者明確回饋
    var canSave: Bool {
        let fields = [
            store.draftCustomerName,
            store.draftOrderSource,
        ]
        let hasCategory = store.draftCategories.contains {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return hasCategory && fields.allSatisfy {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    /// 單選模式下開團 `Picker` 的選取繫結：以陣列首元素對應單選值，寫入時送 ``OrderEditFeature/Action/campaignSelected(_:)`` 正規化回單元素陣列 (空字串 = 未歸團 = 空陣列)
    var campaignSelectionBinding: Binding<String> {
        Binding(
            get: { store.draftCampaignNames.first ?? "" },
            set: { store.send(.campaignSelected($0)) }
        )
    }

    /// 幣別選擇列 label 顯示文字：依 App 選定 locale——中文顯示名稱 (如「新台幣」)、其他語言顯示 ISO code (如「TWD」)，避免英文全名過長
    var currencyDisplayText: String {
        let code = store.draftCurrency.rawValue
        guard locale.language.languageCode?.identifier == "zh" else {
            return code
        }

        let name = locale.localizedString(forCurrencyCode: code) ?? ""
        return name.isEmpty ? code : name
    }

    /// 日期選擇器的繫結：寫回時把新值交給 reducer 的 ``OrderEditFeature/Action/dateComponentsChanged(_:)``，由 reducer 以注入時間補上當下秒數後寫入 ``OrderEditFeature/State/draftDate``；View 端不再讀取當下時間做寫入前計算
    var refreshingSecondsBinding: Binding<Date> {
        Binding(
            get: { store.draftDate },
            set: { store.send(.dateComponentsChanged($0)) }
        )
    }
}

// MARK: - Preview

#Preview("新訂單") {
    OrderEditView(
        store: Store(
            initialState: OrderEditFeature.State(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
                currentDate: Date(timeIntervalSince1970: 0)
            )
        ) {
            OrderEditFeature()
        }
    )
}

#Preview("編輯訂單") {
    OrderEditView(
        store: Store(
            initialState: OrderEditFeature.State(
                original: LedgerOrder.sampleOrders[0],
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000000")!,
                currentDate: Date(timeIntervalSince1970: 0)
            )
        ) {
            OrderEditFeature()
        }
    )
}
