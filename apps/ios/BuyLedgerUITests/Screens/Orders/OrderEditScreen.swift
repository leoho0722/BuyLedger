//
//  OrderEditScreen.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/24.
//

import XCTest

/// 訂單編輯表單的 Page Object
struct OrderEditScreen {

    // MARK: - Properties

    /// 受測 App
    let app: XCUIApplication
}

// MARK: - Computed Properties

@MainActor
extension OrderEditScreen {

    /// 可及性樹中符合訂單編輯表單根識別值的元素數量
    var presentedRootCount: Int {
        app.descendants(matching: .any)
            .matching(identifier: BLAccessibilityID.OrderEdit.root)
            .count
    }

    /// 客戶名稱輸入欄位
    var customerField: XCUIElement {
        app.textFields[BLAccessibilityID.OrderEdit.customerField].firstMatch
    }

    /// 客戶名稱欄位目前的可及性值，尚未取得值時為缺值
    var customerValue: String? {
        customerField.value as? String
    }

    /// 實付金額輸入欄位
    var chargedAmountField: XCUIElement {
        app.textFields[BLAccessibilityID.OrderEdit.chargedAmountField].firstMatch
    }

    /// 實付金額欄位目前的可及性值，尚未取得值時為缺值
    var chargedAmountValue: String? {
        chargedAmountField.value as? String
    }

    /// 刷卡手續費率輸入欄位
    var cardFeeRateField: XCUIElement {
        app.textFields[BLAccessibilityID.OrderEdit.cardFeeRateField].firstMatch
    }

    /// 刷卡手續費率欄位目前的可及性值，尚未取得值時為缺值
    var cardFeeRateValue: String? {
        cardFeeRateField.value as? String
    }

    /// 品項名稱輸入欄位
    var itemNameField: XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.OrderEdit.itemNameField].firstMatch
    }

    /// 品項單價輸入欄位
    var itemUnitPriceField: XCUIElement {
        app.textFields[BLAccessibilityID.OrderEdit.itemUnitPriceField].firstMatch
    }

    /// 品項單價欄位目前的可及性值，尚未取得值時為缺值
    var itemUnitPriceValue: String? {
        itemUnitPriceField.value as? String
    }

    /// 訂單備註輸入欄位
    var notesField: XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.OrderEdit.notesField].firstMatch
    }

    /// 訂單備註欄位目前的可及性值，尚未取得值時為缺值
    var notesValue: String? {
        notesField.value as? String
    }

    /// 無卡折抵輸入欄位
    var cardlessDeductionField: XCUIElement {
        app.textFields[BLAccessibilityID.OrderEdit.cardlessDeductionField].firstMatch
    }

    /// 無卡折抵欄位目前的可及性值，尚未取得值時為缺值
    var cardlessDeductionValue: String? {
        cardlessDeductionField.value as? String
    }

    /// 無卡付款時收款區段底部的計算方式說明
    var cardlessPaymentNote: XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.OrderEdit.cardlessPaymentNote].firstMatch
    }

    /// 無卡折抵超過實付金額時顯示在收款區段底部的紅字提示
    var cardlessDeductionExceededMessage: XCUIElement {
        app.descendants(matching: .any)[
            BLAccessibilityID.OrderEdit.cardlessDeductionExceededMessage
        ].firstMatch
    }

    /// 無卡補款金額 (TWD) 的輸入欄位
    var cardlessSupplementField: XCUIElement {
        app.textFields[BLAccessibilityID.OrderEdit.cardlessSupplementField].firstMatch
    }

    /// 基本資料區段的訂購日期選擇器
    var orderDatePicker: XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.OrderEdit.orderDatePicker]
    }

    /// 基本資料區段頁尾的訂購時間戳
    var orderDateTimestamp: XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.OrderEdit.orderDateTimestamp]
    }
}

// MARK: - Internal Method

@MainActor
extension OrderEditScreen {

    /// 等待儲存按鈕可用
    ///
    /// - Parameter timeout: 等待按鈕可用的秒數
    /// - Returns: 儲存按鈕是否在逾時前可用
    func waitForSaveEnabled(timeout: TimeInterval = 10) -> Bool {
        saveButton.wait(for: NSPredicate(format: "isEnabled == true"), timeout: timeout)
    }

    /// 等待訂單來源列的標籤包含指定文字
    ///
    /// - Parameters:
    ///   - text: 標籤應包含的文字
    ///   - timeout: 等待標籤更新的秒數
    /// - Returns: 來源列標籤是否在逾時前包含指定文字
    func waitForSourceLabel(containing text: String, timeout: TimeInterval = 10) -> Bool {
        sourceRow.wait(for: NSPredicate(format: "label CONTAINS %@", text), timeout: timeout)
    }

    /// 等待付款方式列的標籤包含指定文字
    ///
    /// - Parameters:
    ///   - text: 標籤應包含的文字
    ///   - timeout: 等待標籤更新的秒數
    /// - Returns: 付款方式列標籤是否在逾時前包含指定文字
    func waitForPaymentLabel(containing text: String, timeout: TimeInterval = 10) -> Bool {
        paymentRow(matching: .button).wait(
            for: NSPredicate(format: "label CONTAINS %@", text),
            timeout: timeout
        )
    }

    /// 等待幣別列出現後讀取 ISO 幣別代碼
    ///
    /// - Returns: 幣別列的可及性值；找不到列或讀不到值時為缺值
    func currencyCode() -> String? {
        let row = app.descendants(matching: .any)[BLAccessibilityID.OrderEdit.currencyRow]
            .firstMatch
        guard row.waitForExistence(timeout: 10) else {
            return nil
        }
        return row.value as? String
    }

    /// 清空並填入客戶名稱
    ///
    /// - Parameters:
    ///   - name: 要填入的客戶名稱
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func typeCustomerName(
        _ name: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let field = app.textFields[BLAccessibilityID.OrderEdit.customerField]
        guard waitForFormElement(field, isSwipingUp: false) else {
            try app.stopWithDiagnostics("捲到頂端或達 8 次上限後仍找不到可點的客戶名稱欄位", file: file, line: line)
        }
        try field.clearAndType(
            name,
            in: app,
            file: file,
            line: line
        )
    }

    /// 點客戶名稱欄後按 return 送出，走一般鍵盤的收起路徑
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func submitCustomerName(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let field = app.textFields[BLAccessibilityID.OrderEdit.customerField]
        try field.tapAfterWaiting(in: app, file: file, line: line)
        try field.dismissKeyboardByReturn(in: app, file: file, line: line)
    }

    /// 先解除原有焦點再點客戶欄左側，保留文字供聚焦行為測試
    ///
    /// - Parameters:
    ///   - dx: 客戶欄內點擊位置的水平比例
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func focusCustomerFromLeft(
        dx: CGFloat = 0.04,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try dismissCustomerKeyboard(file: file, line: line)
        guard waitForFormElement(customerField, isSwipingUp: false) else {
            try app.stopWithDiagnostics("找不到可點擊的客戶名稱欄位", file: file, line: line)
        }
        try customerField.tapLeftToFocus(
            in: app,
            dx: dx,
            file: file,
            line: line
        )
    }

    /// 客戶欄持有焦點時送出 return，等待文字鍵盤與焦點都解除
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 欄位、鍵盤或必要框線未就緒時丟出測試錯誤
    func dismissCustomerKeyboard(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let field = customerField
        guard field.waitForExistence(timeout: 5) else {
            try app.stopWithDiagnostics("找不到客戶名稱欄位，無法準備聚焦測試", file: file, line: line)
        }
        guard field.hasKeyboardFocus else {
            return
        }
        try field.dismissKeyboardByReturn(in: app, file: file, line: line)
        let hasDismissed = Polling.wait(timeout: 5) {
            !app.keyboards.firstMatch.exists
                && !app.isNumericPopoverPresented
                && !field.hasKeyboardFocus
        }
        guard hasDismissed else {
            try app.stopWithDiagnostics("送出客戶名稱後文字鍵盤或焦點仍未解除", file: file, line: line)
        }
    }

    /// 捲動露出欄位後點欄位左側取得焦點，等鍵盤就位；欄位已取得焦點時再次點左側，不先收鍵盤
    ///
    /// - Parameters:
    ///   - field: 要取得焦點的欄位
    ///   - isSwipingUp: 欄位在畫面下方時為真，向上捲動尋找
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func focusFromLeft(
        _ field: XCUIElement,
        isSwipingUp: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let isRevealed = isSwipingUp
            ? waitForFormElementGently(field)
            : waitForFormElement(field, isSwipingUp: false)
        guard isRevealed else {
            try app.stopWithDiagnostics("找不到可點擊的欄位", file: file, line: line)
        }
        try field.tapLeftToFocus(in: app, file: file, line: line)
    }

    /// 鍵盤升起前把欄位慢速拖到表單上半部，讓欄位取得焦點後不被鍵盤蓋住，可以再次點擊
    ///
    /// - Parameters:
    ///   - field: 要移動的欄位
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 欄位、鍵盤或必要框線未就緒時丟出測試錯誤
    func moveFieldToUpperForm(
        _ field: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        guard waitForFormElementGently(field),
              let fieldFrame = field.snapshotFrame,
              let formFrame = rootElement.snapshotFrame else {
            try app.stopWithDiagnostics("找不到可拖曳到表單上半部的欄位", file: file, line: line)
        }
        let targetY = formFrame.minY + formFrame.height * 0.3
        if fieldFrame.midY > targetY {
            // 從左緣起拖，避開右側輸入欄
            let origin = rootElement.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0))
            let start = origin.withOffset(CGVector(dx: 0, dy: fieldFrame.midY - formFrame.minY))
            let end = origin.withOffset(CGVector(dx: 0, dy: targetY - formFrame.minY))
            start.press(
                forDuration: 0.05,
                thenDragTo: end,
                withVelocity: .slow,
                thenHoldForDuration: 0.2
            )
        }
        guard field.waitUntilStableAndHittable(timeout: 5) else {
            try app.stopWithDiagnostics("拖曳後欄位框線未穩定或仍不可點", file: file, line: line)
        }
    }

    /// 捲動露出備註後點第一行上方的左側，等待欄位取得鍵盤焦點
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 欄位、鍵盤或必要框線未就緒時丟出測試錯誤
    func focusNotesFromFirstLine(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let field = notesField
        guard waitForFormElementGently(field) else {
            try app.stopWithDiagnostics("找不到可點擊的備註欄位", file: file, line: line)
        }
        try field.focusFromFirstLine(in: app, file: file, line: line)
    }

    /// 開啟訂單來源選擇器
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的目的地 Page Object
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    @discardableResult
    func openSourcePicker(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> OptionPickerScreen {
        return try tapPickerRow(sourceRow, file: file, line: line)
    }

    /// 開啟商品類別選擇器
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的目的地 Page Object
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    @discardableResult
    func openCategoryPicker(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> OptionPickerScreen {
        let row = app.descendants(matching: .any)[BLAccessibilityID.OrderEdit.categoryRow]
        return try tapPickerRow(row, file: file, line: line)
    }

    /// 開啟付款方式選擇器
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的目的地 Page Object
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    @discardableResult
    func openPaymentPicker(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> OptionPickerScreen {
        return try tapPickerRow(paymentRow(), file: file, line: line)
    }

    /// 開啟幣別選擇器
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的目的地 Page Object
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    @discardableResult
    func openCurrencyPicker(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> OptionPickerScreen {
        let customerField = app.textFields[BLAccessibilityID.OrderEdit.customerField]
        let keyboard = app.keyboards.firstMatch
        if keyboard.exists {
            customerField.typeText(XCUIKeyboardKey.return.rawValue)
            if !keyboard.waitForDisappearance(timeout: 5) {
                try app.stopWithDiagnostics("訂單編輯的文字鍵盤未能收起", file: file, line: line)
            }
        }

        let row = app.descendants(matching: .any)[BLAccessibilityID.OrderEdit.currencyRow]
        if !row.waitForExistence(timeout: 10) {
            try app.stopWithDiagnostics("找不到幣別選擇列", file: file, line: line)
        }

        return try tapPickerRow(row, file: file, line: line)
    }

    /// 收起客戶欄鍵盤並露出實付金額欄後，只點欄位左側取得焦點
    ///
    /// - Parameters:
    ///   - dx: 金額欄內點擊位置的水平比例
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func focusChargedAmountFromLeft(
        dx: CGFloat = 0.04,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        try dismissCustomerKeyboard(file: file, line: line)
        guard app.waitUntilFullyVisibleByGentleDrag(chargedAmountField, within: rootElement) else {
            try app.stopWithDiagnostics("收起客戶鍵盤並捲動後，實付金額欄仍未完整露出", file: file, line: line)
        }
        try chargedAmountField.tapLeftToFocus(
            in: app,
            dx: dx,
            file: file,
            line: line
        )
    }

    /// 填入客戶實付金額
    ///
    /// - Parameters:
    ///   - amount: 要填入的金額文字
    ///   - shouldDismissKeyboard: 是否在輸入後收起數字鍵盤
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func typeChargedAmount(
        _ amount: String,
        shouldDismissKeyboard: Bool = true,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let field = app.textFields[BLAccessibilityID.OrderEdit.chargedAmountField]
        // 使用預設拖曳範圍，避免 iPhone 找不到可點擊位置
        // 須完整落在表單可見範圍內才點擊，只露出底緣時點擊未能聚焦
        if !app.waitUntilFullyVisibleByGentleDrag(field, within: rootElement) {
            // XCTest 的第一次點擊會觸發原生 scroll-to-focus
            // 之後才由 `clearAndType` 輸入
            guard field.waitForExistence(timeout: 5) else {
                try app.stopWithDiagnostics("找不到實付金額欄位，無法使用原生聚焦備援", file: file, line: line)
            }
            field.tap()
        }
        try field.requireHittable(
            in: app,
            timeout: 10,
            file: file,
            line: line
        )
        try field.clearAndType(
            amount,
            in: app,
            file: file,
            line: line
        )
        if shouldDismissKeyboard {
            try field.dismissNumericKeyboard(in: app, file: file, line: line)
        }
    }

    /// 點數字鍵盤工具列的完成鍵
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapNumericKeyboardDone(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let field = app.textFields[BLAccessibilityID.OrderEdit.chargedAmountField]
        try field.dismissNumericKeyboard(in: app, file: file, line: line)
    }

    /// 捲到照片區並點指定序位的照片縮圖，開啟照片檢視器
    ///
    /// - Parameters:
    ///   - index: 照片縮圖的序位
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的目的地 Page Object
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    @discardableResult
    func tapPhotoThumbnail(
        index: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> PhotoViewerScreen {
        let thumbnail = app.descendants(matching: .any)[
            BLAccessibilityID.OrderEdit.photoThumbnail(index: index)
        ]
        if !waitForFormElement(thumbnail, isSwipingUp: true),
           !app.waitUntilHittableByScrolling(thumbnail, within: rootElement) {
            try app.stopWithDiagnostics("捲到照片區底端或達上限後仍找不到可點的照片縮圖", file: file, line: line)
        }
        try thumbnail.tapAfterWaiting(in: app, file: file, line: line)
        let screen = PhotoViewerScreen(app: app)
        try screen.requireReady(file: file, line: line)
        return screen
    }

    /// 判定儲存按鈕目前是否可用
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 儲存按鈕是否可用
    /// - Throws: 儲存按鈕逾時仍不存在時丟出測試錯誤
    func isSaveEnabled(
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> Bool {
        let button = saveButton
        if !button.waitForExistence(timeout: 10) {
            let saveButtonID = BLAccessibilityID.OrderEdit.saveButton
            try app.stopWithDiagnostics(
                "找不到 identifier 為 \(saveButtonID) 的儲存按鈕",
                file: file,
                line: line
            )
        }

        return button.isEnabled
    }

    /// 點工具列的儲存
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapSave(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        let button = saveButton
        try button.tapAfterWaiting(in: app, file: file, line: line)
    }

    /// 露出付款區段的欄位或檢核訊息供讀值或後續聚焦，捲動本身不點欄位
    ///
    /// - Parameters:
    ///   - field: 實付、無卡折抵、無卡補款欄位或區段底部的檢核訊息
    ///   - isScrollingDown: 是否由表單上方向下尋找欄位
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func revealPaymentField(
        _ field: XCUIElement,
        isScrollingDown: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) {
        let hasRevealed: Bool
        if isScrollingDown {
            hasRevealed = waitForFormElementGently(field)
        } else {
            hasRevealed = app.waitUntilFullyVisibleByGentleDrag(
                field,
                within: rootElement,
                startY: 0.3,
                endY: 0.5
            )
        }
        guard hasRevealed, field.waitUntilStableAndHittable(timeout: 2) else {
            try app.stopWithDiagnostics("付款區段的欄位或檢核訊息未能完整露出並保持穩定", file: file, line: line)
        }
    }

    /// 點工具列的取消
    ///
    /// - Parameters:
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapCancel(file: StaticString = #filePath, line: UInt = #line) throws(UITestError) {
        let button = app.buttons[BLAccessibilityID.OrderEdit.cancelButton]
        try button.tapAfterWaiting(in: app, file: file, line: line)
    }
}

// MARK: - ScreenProtocol

extension OrderEditScreen: ScreenProtocol {

    /// 判定編輯表單已就緒的根 identifier (表單捲動容器)
    var rootIdentifier: String {
        BLAccessibilityID.OrderEdit.root
    }
}

// MARK: - Private Method

@MainActor
private extension OrderEditScreen {

    /// 表單工具列的儲存按鈕
    var saveButton: XCUIElement {
        app.buttons[BLAccessibilityID.OrderEdit.saveButton]
    }

    /// 訂單來源選擇列，供點擊與標籤等待共用
    var sourceRow: XCUIElement {
        app.descendants(matching: .any)[BLAccessibilityID.OrderEdit.sourceRow]
    }

    /// 依元素類型取得付款方式選擇列
    ///
    /// - Parameter type: 元素類型；既有點擊使用任意類型，標籤等待使用按鈕
    /// - Returns: 符合識別值與元素類型的付款方式列
    func paymentRow(matching type: XCUIElement.ElementType = .any) -> XCUIElement {
        app.descendants(matching: type)[BLAccessibilityID.OrderEdit.paymentRow]
    }

    /// 依指定方向尋找表單元素，位置簽章不再變動或達八次上限時停止
    ///
    /// - Parameters:
    ///   - element: 要捲進可點範圍的表單元素
    ///   - isSwipingUp: 是否向上滑動以尋找下方內容
    /// - Returns: 目標是否已連續兩次取得相同的有效框線且可點
    func waitForFormElement(_ element: XCUIElement, isSwipingUp: Bool) -> Bool {
        let container = rootElement
        guard container.waitForExistence(timeout: 5) else {
            return false
        }
        if element.snapshotFrame != nil, element.waitUntilStableAndHittable(timeout: 1) {
            return true
        }
        var previous = app.scrollPositionSignature(in: container)
        for _ in 0..<8 {
            if isSwipingUp {
                container.swipeUp()
            } else {
                container.swipeDown()
            }
            if element.waitUntilStableAndHittable(timeout: 1) {
                return true
            }
            let current = app.scrollPositionSignature(in: container)
            if let current, current == previous {
                return false
            }
            previous = current
        }
        return element.waitUntilStableAndHittable(timeout: 1)
    }

    /// 以短距離拖曳由下方捲入表單元素，避免帶慣性的滑動讓元素衝到導覽列底下
    ///
    /// - Parameter element: 要捲入表單可見範圍的元素
    /// - Returns: 目標是否可點且完整落在表單範圍內
    func waitForFormElementGently(_ element: XCUIElement) -> Bool {
        let container = rootElement
        guard container.waitForExistence(timeout: 5) else {
            return false
        }
        var previous = app.scrollPositionSignature(in: container)
        for _ in 0..<20 {
            if isFullyVisibleInForm(element) {
                return true
            }
            // 從左緣起拖，避開右側輸入欄
            let start = container.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.45))
            let end = container.coordinate(withNormalizedOffset: CGVector(dx: 0.05, dy: 0.25))
            start.press(forDuration: 0.1, thenDragTo: end)
            let current = app.scrollPositionSignature(in: container)
            if let current, current == previous {
                break
            }
            previous = current
        }
        return isFullyVisibleInForm(element)
    }

    /// 判斷表單元素是否可點且垂直範圍完整落在表單內
    ///
    /// - Parameter element: 要判斷的元素
    /// - Returns: 元素可點且完整落在表單範圍內時為真
    func isFullyVisibleInForm(_ element: XCUIElement) -> Bool {
        guard element.isHittableOnScreen,
              let frame = element.snapshotFrame,
              let formFrame = rootElement.snapshotFrame else {
            return false
        }
        return frame.minY >= formFrame.minY && frame.maxY <= formFrame.maxY
    }

    /// 點某個選擇器入口列開啟選擇器
    ///
    /// - Parameters:
    ///   - row: 要點擊的選項選擇列
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的選項選擇器
    /// - Throws: 支援的 UI 操作或等待失敗時丟出測試錯誤
    func tapPickerRow(
        _ row: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> OptionPickerScreen {
        if !row.isHittableOnScreen {
            try app.scrollToHittable(
                row,
                within: rootElement,
                file: file,
                line: line
            )
        }
        try row.tapAfterWaiting(in: app, file: file, line: line)
        let screen = OptionPickerScreen(app: app)
        try screen.requireReady(file: file, line: line)
        return screen
    }
}
