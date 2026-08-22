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
struct OrderEditView: View {
    
    // MARK: - View Properties
    
    /// 訂單編輯 store
    @Bindable var store: StoreOf<OrderEditFeature>
    
    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale
    
    /// 目前的動態字級
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    /// 鍵盤焦點的 SwiftUI 鏡像
    @FocusState private var focusedField: OrderEditFeature.State.Field?
    
    // MARK: - View Body
    
    /// 編輯表單的畫面內容
    var body: some View {
        NavigationStack(path: pickerPath) {
            Form {
                Section {
                    TextField("客戶名稱", text: $store.draft.customerName)
                        .textContentType(.name)
                        .focused($focusedField, equals: .customerName)
                        .accessibilityIdentifier(BLAccessibilityID.OrderEdit.customerField)
                    
                    orderSourcePickerRow
                    
                    categoryPickerRow
                    
                    orderDateRow
                } header: {
                    Text("基本資料")
                } footer: {
                    VStack(alignment: .leading, spacing: BLSpacing.small) {
                        Text(
                            """
                            訂購日期：\
                            \(OrderFormatters.fullTimestamp(store.draft.date, locale: locale))
                            """
                        )
                        .blTextStyle(.footnote)
                        .foregroundStyle(Color.blSecondaryLabel)
                        .monospacedDigit()
                        
                        if !canSave {
                            Text("客戶名稱、訂單來源與商品類別皆為必填欄位。")
                                .blTextStyle(.footnote)
                                .foregroundStyle(Color.blSecondaryLabel)
                        }
                    }
                }
                
                Section("狀態與幣別") {
                    Picker("狀態", selection: $store.draft.status) {
                        ForEach(store.availableStatuses) { status in
                            Text(LocalizedStringKey(status.title)).tag(status)
                        }
                    }
                    
                    currencyPickerRow
                    
                    paymentMethodPickerRow
                    
                    if store.showsReconciliationStatusRow {
                        reconciliationStatusPickerRow
                    }
                }
                
                Section {
                    decimalField(
                        title: "客戶實付",
                        value: $store.draft.chargedAmount,
                        field: .chargedAmount,
                        identifier: BLAccessibilityID.OrderEdit.chargedAmountField
                    )
                    
                    if store.isSelectedPaymentMethodCardless {
                        decimalField(
                            title: "無卡折抵金額",
                            value: $store.draft.cardlessDeductionAmount,
                            field: .cardlessDeduction
                        )
                        
                        decimalField(
                            title: "無卡補款金額",
                            value: $store.draft.cardlessSupplementAmount,
                            field: .cardlessSupplement
                        )
                    }
                } header: {
                    Text("收款金額 (NT$)")
                } footer: {
                    if store.isSelectedPaymentMethodCardless || store.cardlessDeductionWasCapped {
                        VStack(alignment: .leading, spacing: BLSpacing.small) {
                            if store.isSelectedPaymentMethodCardless {
                                Text("無卡類付款方式才會啟用「折抵」與「補款」欄位；總收款 = 客戶實付 + 補款 − 折抵。")
                                    .blTextStyle(.footnote)
                                    .foregroundStyle(Color.blSecondaryLabel)
                            }
                            
                            if store.cardlessDeductionWasCapped {
                                Text("無卡折抵金額不得超過客戶實付金額，已自動調整為上限。")
                                    .blTextStyle(.footnote)
                                    .foregroundStyle(Color.blSecondaryLabel)
                            }
                        }
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
                    
                    Picker("收款狀態", selection: $store.draft.paymentReceiptStatus) {
                        ForEach(PaymentReceiptStatus.allCases) { status in
                            Text(LocalizedStringKey(status.title)).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    decimalField(title: "商品成本", value: $store.draft.itemCost, field: .itemCost)
                    decimalField(
                        title: "外國國內運費", value: $store.draft.foreignDomesticShipping,
                        field: .foreignDomesticShipping)
                    decimalField(
                        title: "國際運費", value: $store.draft.internationalShipping,
                        field: .internationalShipping)
                    decimalField(
                        title: "國內運費", value: $store.draft.domesticShipping,
                        field: .domesticShipping)
                } header: {
                    Text("成本 (NT$)")
                } footer: {
                    if store.isSelectedPaymentMethodCOD {
                        Text("貨到付款：收款金額已含預估運費，獲利會自動扣除上方三種運費 (國內 + 國際 + 外國國內)。")
                            .blTextStyle(.footnote)
                            .foregroundStyle(Color.blSecondaryLabel)
                    }
                }
                
                Section {
                    percentField(
                        title: "刷卡手續費 %", value: $store.draft.cardFeeRate, field: .cardFeeRate)
                    percentField(
                        title: "平台手續費 %", value: $store.draft.platformFeeRate,
                        field: .platformFeeRate)
                    percentField(
                        title: "金流手續費 %", value: $store.draft.paymentFeeRate, field: .paymentFeeRate
                    )
                } header: {
                    Text("手續費 (%)")
                } footer: {
                    Text("輸入百分比例如 1.5 表示 1.5%；超出 0%–100% 範圍會自動限制。")
                        .blTextStyle(.footnote)
                        .foregroundStyle(Color.blSecondaryLabel)
                }
                
                itemsSection
                
                notesSection
                
                photosSection
                
                if let original = store.original {
                    Section("原始訂單") {
                        LabeledContent("單號", value: original.displayID)
                            .monospacedDigit()
                    }
                }
            }
            .formStyle(.grouped)
            .accessibilityIdentifier(BLAccessibilityID.OrderEdit.root)
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
                    .accessibilityIdentifier(BLAccessibilityID.OrderEdit.cancelButton)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        store.send(.saveTapped)
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel(Text("儲存"))
                    .accessibilityIdentifier(BLAccessibilityID.OrderEdit.saveButton)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canSave)
                }
                
                // 數字鍵盤沒有 return 鍵，因此提供完成鍵。
                if isNumericFieldFocused {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        
                        Button {
                            store.send(.binding(.set(\.focusedField, nil)))
                        } label: {
                            Image(systemName: "checkmark")
                        }
                        .accessibilityIdentifier(BLAccessibilityID.Common.keyboardDoneButton)
                        .accessibilityLabel(Text("完成"))
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .bind($store.focusedField, to: $focusedField)
            .task {
                await store.send(.task).finish()
            }
            .navigationDestination(for: OrderEditFeature.State.PickerRoute.self) { route in
                pickerDestination(for: route)
            }
        }
        // 有未儲存變更時阻擋下滑關閉，避免草稿靜默遺失；取消鍵改以彈窗確認
        .interactiveDismissDisabled(store.isDirty)
        .alert($store.scope(state: \.discardConfirmation, action: \.discardConfirmation))
    }
}

// MARK: - ViewBuilder

private extension OrderEditView {
    
    /// 依路徑建立嵌入式選項選擇器
    /// - Parameter route: 目前要 push 的選擇器 route
    /// - Returns: 對應的嵌入式 ``OptionPickerSheet``
    @ViewBuilder
    func pickerDestination(for route: OrderEditFeature.State.PickerRoute) -> some View {
        switch route {
        case .orderSource:
            OptionPickerSheet(
                title: "選擇訂單來源",
                addButtonTitle: "新增來源",
                emptyTitle: "尚無來源",
                emptyDescription: "透過上方「新增來源」加入第一個訂單來源。",
                addAlertTitle: "新增訂單來源",
                addFieldPlaceholder: "來源名稱",
                addAlertMessage: "輸入新的訂單來源名稱，加入後會立即套用至此訂單。",
                options: store.availableOrderSources,
                selected: store.draft.orderSource,
                onSelect: { source in
                    store.send(.orderSourceSelected(source))
                },
                onAdd: { name in
                    store.send(.addOrderSourceTapped(name))
                },
                isEmbedded: true
            )
            
        case .category:
            if store.isMergeContext {
                // 合併時使用多選模式。
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
                        selections: Set(store.draft.categories),
                        onToggle: { category in
                            store.send(.categoryToggled(category))
                        }
                    ),
                    isEmbedded: true
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
                    selected: store.draft.categories.first ?? "",
                    onSelect: { category in
                        store.send(.categorySelected(category))
                    },
                    onAdd: { name in
                        store.send(.addCategoryTapped(name))
                    },
                    isEmbedded: true
                )
            }
            
        case .campaign:
            OptionPickerSheet(
                title: "選擇開團",
                allowsAdd: false,
                emptyTitle: "尚無開團",
                emptyDescription: "請先在「開團」頁建立開團，再回到此處歸團。",
                options: store.availableCampaigns,
                multiSelection: .init(
                    selections: Set(store.draft.campaignNames),
                    onToggle: { name in
                        store.send(.campaignToggled(name))
                    }
                ),
                isEmbedded: true
            )
            
        case .paymentMethod:
            OptionPickerSheet(
                title: "選擇付款方式",
                addButtonTitle: "新增付款方式",
                emptyTitle: "尚無付款方式",
                emptyDescription: "透過上方「新增付款方式」加入第一個項目。",
                addAlertTitle: "新增付款方式",
                addFieldPlaceholder: "付款方式名稱",
                addAlertMessage: "輸入新的付款方式名稱，加入後會立即套用至此訂單。",
                options: store.availablePaymentMethods.map(\.name),
                selected: store.draft.paymentMethod,
                onSelect: { method in
                    store.send(.paymentMethodSelected(method))
                },
                onAddPaymentMethod: { name, flags in
                    store.send(.addPaymentMethodTapped(name: name, flags: flags))
                },
                isEmbedded: true
            )
            
        case .reconciliationStatus:
            OptionPickerSheet(
                title: "選擇對帳狀態",
                addButtonTitle: "新增對帳狀態",
                emptyTitle: "尚無對帳狀態",
                emptyDescription: "透過上方「新增對帳狀態」加入第一個項目。",
                addAlertTitle: "新增對帳狀態",
                addFieldPlaceholder: "對帳狀態名稱",
                addAlertMessage: "輸入新的對帳狀態名稱，加入後會立即套用至此訂單。",
                options: store.availableReconciliationStatuses,
                selected: store.draft.reconciliationStatus,
                onSelect: { status in
                    store.send(.reconciliationStatusSelected(status))
                },
                onAdd: { name in
                    store.send(.addReconciliationStatusTapped(name))
                },
                isEmbedded: true
            )
            
        case .currency:
            let locale = locale
            
            OptionPickerSheet(
                title: "選擇幣別",
                allowsAdd: false,
                searchable: true,
                emptyTitle: "尚無幣別",
                emptyDescription: "需要網路連線載入幣別清單；請稍後再試。",
                options: store.availableCurrencies.map(\.rawValue),
                selected: store.draft.currency.rawValue,
                displayName: { code in
                    let name = locale.localizedString(forCurrencyCode: code) ?? ""
                    return name.isEmpty ? code : "\(code) (\(name))"
                },
                searchKeywords: { code in
                    locale.localizedString(forCurrencyCode: code) ?? ""
                },
                onSelect: { code in
                    store.send(.currencySelected(code))
                },
                isEmbedded: true
            )
            
        case let .photoViewer(index):
            // 照片檢視使用編輯表單既有的路徑列舉推進呈現。
            // 加入同一個列舉即可，不需要在 sheet 上再疊一層 modal
            // 返回與各選擇器一樣由宿主堆疊的 Back 經 pickerPath binding 清空路徑
            BLPhotoViewer(
                photos: store.draftPhotos,
                initialIndex: index
            )
        }
    }
    
    /// 訂單來源選擇列，並提供新增入口
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
                    if store.draft.orderSource.isEmpty {
                        Text("選擇來源")
                    } else {
                        Text(verbatim: store.draft.orderSource)
                    }
                }
                .foregroundStyle(Color.blSecondaryLabel)
                
                Image(systemName: "chevron.right")
                    .font(BLTypographyStyle.caption.font.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(BLAccessibilityID.OrderEdit.sourceRow)
    }
    
    /// 商品類別選擇列：以 `Menu` 列出既有類別並提供「新增類別」入口
    @ViewBuilder
    var categoryPickerRow: some View {
        // 使用 Button + sheet，避免 Menu 收合時阻擋 sheet
        Button {
            store.send(.categoryPickerTapped)
        } label: {
            HStack(spacing: BLSpacing.small) {
                Text("商品類別")
                    .foregroundStyle(.primary)
                
                Spacer(minLength: BLSpacing.small)
                
                Group {
                    if store.draft.categories.isEmpty {
                        Text("選擇類別")
                    } else {
                        Text(verbatim: store.categoriesDisplayText)
                    }
                }
                .foregroundStyle(Color.blSecondaryLabel)
                .multilineTextAlignment(.trailing)
                
                Image(systemName: "chevron.right")
                    .font(BLTypographyStyle.caption.font.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(BLAccessibilityID.OrderEdit.categoryRow)
    }
    
    /// 合併時開啟開團多選；空選取顯示「未歸團」
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
                    if store.draft.campaignNames.isEmpty {
                        Text("未歸團")
                    } else {
                        Text(verbatim: store.campaignsDisplayText)
                    }
                }
                .foregroundStyle(Color.blSecondaryLabel)
                .multilineTextAlignment(.trailing)
                
                Image(systemName: "chevron.right")
                    .font(BLTypographyStyle.caption.font.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(BLAccessibilityID.OrderEdit.campaignRow)
    }
    
    /// 幣別選擇列；只顯示支援的幣別
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
                    .foregroundStyle(Color.blSecondaryLabel)
                    .lineLimit(1)
                    .truncationMode(.tail)
                
                Image(systemName: "chevron.right")
                    .font(BLTypographyStyle.caption.font.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(BLAccessibilityID.OrderEdit.currencyRow)
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
                    if store.draft.paymentMethod.isEmpty {
                        Text("選擇付款方式")
                    } else {
                        Text(verbatim: store.draft.paymentMethod)
                    }
                }
                .foregroundStyle(Color.blSecondaryLabel)
                
                Image(systemName: "chevron.right")
                    .font(BLTypographyStyle.caption.font.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(BLAccessibilityID.OrderEdit.paymentRow)
    }
    
    /// 對帳狀態選擇列
    @ViewBuilder
    var reconciliationStatusPickerRow: some View {
        Button {
            store.send(.reconciliationStatusPickerTapped)
        } label: {
            HStack(spacing: BLSpacing.small) {
                Text("對帳狀態")
                    .foregroundStyle(.primary)
                
                Spacer(minLength: BLSpacing.small)
                
                Group {
                    if store.draft.reconciliationStatus.isEmpty {
                        Text("選擇對帳狀態")
                    } else {
                        Text(verbatim: store.draft.reconciliationStatus)
                    }
                }
                .foregroundStyle(Color.blSecondaryLabel)
                
                Image(systemName: "chevron.right")
                    .font(BLTypographyStyle.caption.font.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(BLAccessibilityID.OrderEdit.reconciliationRow)
    }
    
    /// 訂購日期編輯列：以 compact `DatePicker` 編輯日期與時分
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
            ForEach($store.draft.items) { $item in
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
            HStack {
                Text("商品明細 (\(store.draft.currency.rawValue))")
                
                Spacer()
                
                // 保留左滑刪除，也提供不依賴手勢的系統清單編輯模式入口。
                // 與下方可見的「新增商品」形成對稱
                if !store.draft.items.isEmpty {
                    EditButton()
                        .blTextStyle(.footnote)
                        .textCase(nil)
                }
            }
        } footer: {
            if store.draft.items.isEmpty {
                Text("還沒有任何商品；點擊「新增商品」開始填寫。")
                    .blTextStyle(.footnote)
                    .foregroundStyle(Color.blSecondaryLabel)
            } else {
                Text("商品單價以原始幣別記錄，總成本與獲利仍以上方「成本」欄位的 NT$ 數值為準。")
                    .blTextStyle(.footnote)
                    .foregroundStyle(Color.blSecondaryLabel)
            }
        }
    }
    
    /// 商品明細下方的多行備註輸入
    @ViewBuilder
    var notesSection: some View {
        Section {
            TextField("輸入備註 (選填)", text: $store.draft.notes, axis: .vertical)
                .textContentType(.none)
                .focused($focusedField, equals: .notes)
                .lineLimit(3...8)
        } header: {
            Text("備註")
        }
    }
    
    /// 訂單照片區段：已加入照片的縮圖橫列 + PhotosPicker 加入按鈕與計數標籤
    @ViewBuilder
    var photosSection: some View {
        Section {
            switch store.photoLoadPhase {
            case .notLoaded, .loading:
                HStack(spacing: BLSpacing.small) {
                    ProgressView()
                    Text("照片載入中…")
                        .blTextStyle(.subhead)
                        .foregroundStyle(Color.blSecondaryLabel)
                }
                
            case .failed:
                Label("照片載入失敗，請稍後再試。", systemImage: "exclamationmark.triangle")
                    .blTextStyle(.subhead)
                    .foregroundStyle(Color.blSecondaryLabel)
                
            case .loaded:
                if !store.draftPhotos.isEmpty {
                    ScrollView(.horizontal) {
                        HStack(spacing: BLSpacing.small) {
                            ForEach(Array(store.draftPhotos.enumerated()), id: \.offset) {
                                index, data in
                                BLPhotoThumbnail(
                                    imageData: data,
                                    onTap: {
                                        store.send(.photoTapped(index))
                                    },
                                    accessibilityID: BLAccessibilityID.OrderEdit.photoThumbnail(
                                        index: index)
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
            }
        } header: {
            Text("訂單照片 (\(store.draftPhotos.count)/\(LedgerOrder.maxPhotoCount))")
        } footer: {
            Text("最多 \(LedgerOrder.maxPhotoCount) 張；照片會縮圖壓縮後隨訂單儲存。")
                .blTextStyle(.footnote)
                .foregroundStyle(Color.blSecondaryLabel)
        }
    }
    
    /// 單筆商品的編輯列：商品名稱 (多行)+ 數量 Stepper + 單價 TextField
    /// - Parameter item: 雙向繫結的單筆商品
    /// - Returns: 商品列 view
    @ViewBuilder
    func itemEditorRow(item: Binding<LedgerOrderItem>) -> some View {
        VStack(alignment: .leading, spacing: BLSpacing.small) {
            // 關閉內容類型，避免系統提供不相關建議。
            TextField("商品名稱", text: item.name, axis: .vertical)
                .textContentType(.none)
                .focused($focusedField, equals: .itemName(item.id))
                .font(BLTypographyStyle.body.font.weight(.medium))
                .lineLimit(1...3)
            
            HStack(spacing: BLSpacing.medium) {
                Stepper(value: item.quantity, in: 1...999) {
                    Text("數量 \(item.quantity.wrappedValue)")
                        .blTextStyle(.footnote)
                        .foregroundStyle(Color.blSecondaryLabel)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("單價")
                        .blTextStyle(.footnote)
                        .foregroundStyle(Color.blSecondaryLabel)
                    
                    TextField(
                        "",
                        value: item.unitPrice,
                        format: .number.precision(.fractionLength(0)).grouping(.never)
                    )
                    .labelsHidden()
                    .multilineTextAlignment(.trailing)
                    .monospacedDigit()
                    .frame(maxWidth: 120)
                    .keyboardType(.numberPad)
                    .focused($focusedField, equals: .itemUnitPrice(item.id))
                    .frame(minHeight: BLHitTarget.minimum)
                    .contentShape(.rect)
                }
            }
        }
    }
    
    /// 整數金額輸入欄
    /// - Parameters:
    ///   - title: 欄位標題
    ///   - value: 雙向繫結的值
    ///   - field: 對應的焦點欄位
    ///   - identifier: UI 測試定位用的識別碼
    /// - Returns: 標題 `Text` 與 `TextField` 組成的橫排或堆疊 view
    @ViewBuilder
    func decimalField(
        title: String,
        value: Binding<Decimal>,
        field: OrderEditFeature.State.Field,
        identifier: String? = nil
    ) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: BLSpacing.small) {
                Text(LocalizedStringKey(title))
                    .fixedSize(horizontal: false, vertical: true)
                
                decimalNumberField(
                    value: value,
                    field: field,
                    identifier: identifier
                )
            }
        } else {
            HStack(alignment: .center, spacing: BLSpacing.small) {
                // 長標籤換行並撐高整列，值在多行標籤中垂直置中
                Text(LocalizedStringKey(title))
                    .fixedSize(horizontal: false, vertical: true)
                
                decimalNumberField(
                    value: value,
                    field: field,
                    identifier: identifier
                )
            }
        }
    }
    
    /// 百分比輸入欄
    /// - Parameters:
    ///   - title: 欄位標題
    ///   - value: 雙向繫結的 0–1 比例值
    /// - Returns: 標題 `Text` 與百分比輸入欄組成的橫排或堆疊 view
    @ViewBuilder
    func percentField(
        title: String,
        value: Binding<Decimal>,
        field: OrderEditFeature.State.Field
    ) -> some View {
        let proxy = Binding<Double>(
            get: { NSDecimalNumber(decimal: value.wrappedValue).doubleValue * 100 },
            set: { newValue in
                value.wrappedValue = Decimal(newValue / 100)
            }
        )
        
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: BLSpacing.small) {
                Text(LocalizedStringKey(title))
                    .fixedSize(horizontal: false, vertical: true)
                
                percentNumberField(proxy: proxy, field: field)
            }
        } else {
            HStack(alignment: .center, spacing: BLSpacing.small) {
                // 長標籤換行並撐高整列，值在多行標籤中垂直置中
                Text(LocalizedStringKey(title))
                    .fixedSize(horizontal: false, vertical: true)
                
                percentNumberField(proxy: proxy, field: field)
            }
        }
    }
    
    /// 整數金額輸入欄，供兩種表單版面共用
    /// - Parameters:
    ///   - value: 雙向繫結的值
    ///   - field: 對應的焦點欄位
    ///   - identifier: UI 測試定位用的識別碼
    /// - Returns: `TextField` view
    @ViewBuilder
    func decimalNumberField(
        value: Binding<Decimal>,
        field: OrderEditFeature.State.Field,
        identifier: String?
    ) -> some View {
        TextField(
            "",
            value: value,
            format: .number.precision(.fractionLength(0)).grouping(.never)
        )
        .labelsHidden()
        .multilineTextAlignment(.trailing)
        .monospacedDigit()
        .keyboardType(.numberPad)
        .focused($focusedField, equals: field)
        // 橫排時拿剩餘空間、堆疊時佔滿整列，皆 trailing 對齊避免長數字被截斷
        .frame(maxWidth: .infinity, alignment: .trailing)
        .frame(minHeight: BLHitTarget.minimum)
        .contentShape(.rect)
        // 只有指定 identifier 時才掛上識別值。
        .accessibilityIdentifier(identifier ?? "")
    }
    
    /// 百分比輸入欄，供兩種表單版面共用
    /// - Parameters:
    ///   - proxy: 0–100 顯示值的雙向繫結
    ///   - field: 對應的焦點欄位
    /// - Returns: 數值與 `%` 組成的 `HStack` view
    @ViewBuilder
    func percentNumberField(
        proxy: Binding<Double>,
        field: OrderEditFeature.State.Field
    ) -> some View {
        HStack(spacing: 4) {
            TextField(
                "",
                value: proxy,
                format: .number.precision(.fractionLength(2)).grouping(.never)
            )
            .labelsHidden()
            .multilineTextAlignment(.trailing)
            .monospacedDigit()
            .keyboardType(.decimalPad)
            .focused($focusedField, equals: field)
            
            Text("%")
                .foregroundStyle(Color.blSecondaryLabel)
        }
        // 橫排時拿剩餘空間、堆疊時佔滿整列，皆 trailing 對齊避免長數字被截斷
        .frame(maxWidth: .infinity, alignment: .trailing)
        .frame(minHeight: BLHitTarget.minimum)
        .contentShape(.rect)
    }
}

// MARK: - Private Method

private extension OrderEditView {
    
    /// 目前聚焦的欄位是否使用數字鍵盤
    var isNumericFieldFocused: Bool {
        switch store.focusedField {
        case .chargedAmount, .cardlessDeduction, .cardlessSupplement, .itemCost,
                .foreignDomesticShipping, .internationalShipping, .domesticShipping,
                .cardFeeRate, .platformFeeRate, .paymentFeeRate,
                .itemQuantity, .itemUnitPrice:
            return true
        case .customerName, .itemName, .notes, .none:
            return false
        }
    }
    
    /// 是否允許按下儲存
    var canSave: Bool {
        let fields = [
            store.draft.customerName,
            store.draft.orderSource,
        ]
        let hasCategory = store.draft.categories.contains {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        return hasCategory && fields.allSatisfy {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
    
    /// 訂單編輯表單的選擇器導覽路徑
    var pickerPath: Binding<[OrderEditFeature.State.PickerRoute]> {
        Binding(
            get: { store.pickerRoute.map { [$0] } ?? [] },
            set: { store.pickerRoute = $0.last }
        )
    }
    
    /// 單選開團的繫結；空字串代表未歸團
    var campaignSelectionBinding: Binding<String> {
        Binding(
            get: { store.draft.campaignNames.first ?? "" },
            set: { store.send(.campaignSelected($0)) }
        )
    }
    
    /// 幣別名稱顯示文字；依語言選名稱或 ISO code
    var currencyDisplayText: String {
        let code = store.draft.currency.rawValue
        guard locale.language.languageCode?.identifier == "zh" else {
            return code
        }
        
        let name = locale.localizedString(forCurrencyCode: code) ?? ""
        return name.isEmpty ? code : name
    }
    
    /// 日期選擇器的繫結，寫回時交由 reducer 補上目前時間
    var refreshingSecondsBinding: Binding<Date> {
        Binding(
            get: { store.draft.date },
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
