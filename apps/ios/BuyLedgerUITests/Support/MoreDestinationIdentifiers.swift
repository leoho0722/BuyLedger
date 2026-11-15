//
//  MoreDestinationIdentifiers.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/14.
//

/// 「更多」入口清單與工具頁前景判定共用的 accessibility identifier
enum MoreDestinationIdentifiers {

    // MARK: - Properties

    /// 可表示入口清單、工具根畫面或選擇器已進入前景的 identifier
    static let foreground: [String] = [
        BLAccessibilityID.Common.detailEmptyState,
        BLAccessibilityID.More.row(.fx),
        BLAccessibilityID.More.row(.customers),
        BLAccessibilityID.More.row(.quote),
        BLAccessibilityID.More.row(.orderSources),
        BLAccessibilityID.More.row(.categories),
        BLAccessibilityID.More.row(.paymentMethods),
        BLAccessibilityID.More.row(.reconciliationStatuses),
        BLAccessibilityID.More.row(.settings),
        BLAccessibilityID.Settings.root,
        BLAccessibilityID.Settings.languagePicker,
        BLAccessibilityID.Settings.defaultCurrencyRow,
        BLAccessibilityID.Settings.monthlyGoalField,
        BLAccessibilityID.Settings.aiSummaryToggle,
        BLAccessibilityID.Settings.appLockToggle,
        BLAccessibilityID.Fx.root,
        BLAccessibilityID.Fx.amountField,
        BLAccessibilityID.Fx.currencyPickerButton,
        BLAccessibilityID.Fx.convertedValue,
        BLAccessibilityID.Fx.statusBanner,
        BLAccessibilityID.Quote.root,
        BLAccessibilityID.Quote.principalField,
        BLAccessibilityID.Quote.currencyPickerButton,
        BLAccessibilityID.Quote.retryButton,
        BLAccessibilityID.Quote.suggestedPriceValue,
        BLAccessibilityID.Quote.statusBanner,
        BLAccessibilityID.Customers.listRoot,
        BLAccessibilityID.Customers.listEmptyState,
        BLAccessibilityID.Customers.listLoadFailureRetryButton,
        BLAccessibilityID.Customers.listLoading,
        BLAccessibilityID.LookupManagement.root,
        BLAccessibilityID.LookupManagement.addButton,
        BLAccessibilityID.LookupManagement.nameField,
        BLAccessibilityID.LookupManagement.paymentMethodNameField,
        BLAccessibilityID.LookupManagement.paymentMethodSaveButton,
        BLAccessibilityID.LookupManagement.loadFailureMessage,
        BLAccessibilityID.LookupManagement.paymentMethodEditorRoot,
        BLAccessibilityID.OptionPicker.root,
        BLAccessibilityID.OptionPicker.addButton,
        BLAccessibilityID.OptionPicker.doneButton,
    ]

    /// 需要以 identifier 前綴比對的動態列
    static let rowPrefixes: [String] = [
        BLAccessibilityID.Customers.row(customerName: ""),
        BLAccessibilityID.Customers.topCard(customerName: ""),
        BLAccessibilityID.LookupManagement.row(""),
        BLAccessibilityID.OptionPicker.optionRow(""),
    ]

    /// PlatformScope 用來量測「更多」入口清單的列錨點
    static let listAnchors: [String] = [
        BLAccessibilityID.More.row(.fx),
        BLAccessibilityID.More.row(.customers),
        BLAccessibilityID.More.row(.settings),
    ]

    /// PlatformScope 用來辨識「更多」工具詳情欄的根 identifier
    static let detailRoots: [String] = [
        BLAccessibilityID.Fx.root,
        BLAccessibilityID.Quote.root,
        BLAccessibilityID.Settings.root,
        BLAccessibilityID.Customers.listRoot,
        BLAccessibilityID.LookupManagement.root,
    ]
}
