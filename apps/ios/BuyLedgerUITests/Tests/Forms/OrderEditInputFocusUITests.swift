//
//  OrderEditInputFocusUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/5.
//

import XCTest

/// 訂單編輯欄位取得焦點後的文字接續、金額清空與還原 UI 測試
@MainActor
final class OrderEditInputFocusUITests: BLUITestCase {

    // MARK: - Properties

    /// 以注音組成候選字「小」需要的軟體鍵盤按鍵
    private static let zhuyinKeys = ["ㄒ", "ㄧ", "ㄠ", "三聲、"]

    /// 驗證新訂單實付金額 0 從左側聚焦後輸入 1000，輸入中只顯示 1000 而不是 01000 或 10000，按完成鍵後仍是 1000
    func testFocusChargedAmountFromLeft_零值輸入_即時取代且失焦保留() {
        // Given
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        guard let edit = openOrderEdit(in: app),
              edit.dismissCustomerKeyboard(),
              edit.revealPaymentField(edit.chargedAmountField, isScrollingDown: true) else {
            return
        }
        let initialValue = edit.chargedAmountValue

        // When
        guard edit.chargedAmountField.tapLeftToFocus(in: app) else {
            return
        }
        edit.chargedAmountField.typeText("1000")
        _ = pollUntil(timeout: 3) {
            edit.chargedAmountValue == "1000"
        }
        let editingValue = edit.chargedAmountValue
        edit.tapNumericKeyboardDone()
        _ = pollUntil(timeout: 3) {
            edit.chargedAmountValue == "1000"
        }
        let finalValue = edit.chargedAmountValue

        // Then
        XCTAssertEqual(initialValue, "0", "聚焦前實付應顯示 0")
        XCTAssertEqual(editingValue, "1000", "輸入中應只顯示新輸入的金額")
        XCTAssertEqual(finalValue, "1000", "失焦後應保留新輸入的金額")
    }

    /// 驗證既有訂單客戶「林書宇」從左側點擊聚焦後輸入「小姐」，結果是「林書宇小姐」：游標由 App 放到尾端，不停在點擊處
    func testFocusCustomerFromLeft_既有名稱接續輸入_新增文字接在尾端() {
        // Given
        let app = launch(LaunchOptions(seed: .minimalOrders))
        guard let edit = openOrderEdit(in: app, orderID: "UITEST-MIN-001") else {
            return
        }

        // When
        guard edit.focusCustomerFromLeft() else {
            return
        }
        edit.customerField.typeText("小姐")

        // Then
        _ = pollUntil(timeout: 3) {
            edit.customerValue == "林書宇小姐"
        }
        XCTAssertEqual(edit.customerValue, "林書宇小姐", "客戶名稱應保留原文並從尾端接續")
    }

    /// 驗證逐鍵輸入注音並點選候選字時，既有姓名保留且組字結果接在尾端
    ///
    /// - Throws: 系統鍵盤未提供所需注音按鍵時丟出 `XCTSkip`
    func testFocusCustomerFromLeft_逐鍵注音組字_保留原文並追加候選字() throws {
        // Given
        let app = launch(LaunchOptions(seed: .minimalOrders))
        guard let edit = openOrderEdit(in: app, orderID: "UITEST-MIN-001") else {
            return
        }
        guard edit.focusCustomerFromLeft() else {
            return
        }
        for symbol in Self.zhuyinKeys {
            guard app.keyboards.keys[symbol].firstMatch.waitForExistence(timeout: 2) else {
                throw XCTSkip("系統鍵盤未提供注音按鍵「\(symbol)」，無法驗證逐鍵組字的外部環境差異")
            }
        }

        // When
        for symbol in Self.zhuyinKeys {
            app.keyboards.keys[symbol].firstMatch.tapAfterWaiting(in: app)
        }
        app.cells["小"].firstMatch.tapAfterWaiting(in: app)

        // Then
        _ = pollUntil(timeout: 3) {
            edit.customerValue == "林書宇小"
        }
        XCTAssertEqual(edit.customerValue, "林書宇小", "注音組字完成後應保留姓名並追加候選字")
    }

    /// 驗證只聚焦金額不輸入時草稿為空，失焦還原且取消直接關閉未修改表單
    func testFocusChargedAmountFromLeft_未輸入即失焦_還原原值且直接取消() {
        // Given
        let app = launch(LaunchOptions(seed: .minimalOrders))
        guard let edit = openOrderEdit(in: app, orderID: "UITEST-MIN-001") else {
            return
        }

        // When
        guard edit.focusChargedAmountFromLeft() else {
            return
        }
        let focusedValue = edit.chargedAmountValue
        edit.tapNumericKeyboardDone()
        _ = pollUntil(timeout: 3) {
            edit.chargedAmountValue == "4200"
        }
        let finalValue = edit.chargedAmountValue
        edit.tapCancel()
        let hasClosedForm = edit.rootElement.waitForDisappearance(timeout: 5)
        let isAlertPresented = app.alerts.firstMatch.exists

        // Then
        XCTAssertEqual(focusedValue, "", "聚焦中的實付金額應顯示空草稿")
        XCTAssertEqual(finalValue, "4200", "未輸入就失焦應恢復原有金額")
        XCTAssertTrue(hasClosedForm, "只聚焦不輸入時，取消應直接關閉表單")
        XCTAssertFalse(isAlertPresented, "只聚焦不輸入不應出現捨棄確認")
    }

    /// 驗證輸入金額再全部刪除後還原聚焦當下的值，取消時直接關閉表單
    func testFocusChargedAmountFromLeft_輸入後全部刪除_還原原值且直接取消() {
        // Given
        let app = launch(LaunchOptions(seed: .minimalOrders))
        guard let edit = openOrderEdit(in: app, orderID: "UITEST-MIN-001") else {
            return
        }

        // When
        guard edit.focusChargedAmountFromLeft() else {
            return
        }
        edit.chargedAmountField.typeText("1")
        _ = pollUntil(timeout: 3) {
            edit.chargedAmountValue == "1"
        }
        let editingValue = edit.chargedAmountValue
        edit.chargedAmountField.typeText(XCUIKeyboardKey.delete.rawValue)
        _ = pollUntil(timeout: 3) {
            edit.chargedAmountValue == ""
        }
        let emptiedValue = edit.chargedAmountValue
        edit.tapNumericKeyboardDone()
        _ = pollUntil(timeout: 3) {
            edit.chargedAmountValue == "4200"
        }
        let finalValue = edit.chargedAmountValue
        edit.tapCancel()
        let hasClosedForm = edit.rootElement.waitForDisappearance(timeout: 5)
        let isAlertPresented = app.alerts.firstMatch.exists

        // Then
        XCTAssertEqual(editingValue, "1", "輸入應取代原有金額")
        XCTAssertEqual(emptiedValue, "", "刪除唯一輸入的字元後草稿應為空")
        XCTAssertEqual(finalValue, "4200", "輸入後全部刪除應還原聚焦當下的金額")
        XCTAssertTrue(hasClosedForm, "還原原值後，取消應直接關閉表單")
        XCTAssertFalse(isAlertPresented, "還原原值後不應出現捨棄確認")
    }

    /// 驗證已取得焦點的客戶欄再點左側，新字不落在尾端，原文保留
    func testFocusCustomerFromLeft_再次點左側_原文保留且新字不在尾端() {
        // Given
        let app = launch(LaunchOptions(seed: .minimalOrders))
        guard let edit = openOrderEdit(in: app, orderID: "UITEST-MIN-001") else {
            return
        }
        guard edit.focusCustomerFromLeft() else {
            return
        }

        // When
        guard edit.customerField.tapLeftToFocus(in: app, dx: 0.01) else {
            return
        }
        edit.customerField.typeText("小")

        // Then
        let hasInsertedText = pollUntil(timeout: 3) {
            edit.customerValue?.contains("小") == true
        }
        let value = edit.customerValue ?? ""
        XCTAssertTrue(hasInsertedText, "再次點左側後必須實際輸入小，實際值：\(value)")
        XCTAssertTrue(value.contains("林書宇"), "客戶名稱應保留原文，實際值：\(value)")
        XCTAssertFalse(value.hasSuffix("小"), "再次點左側後新字不應落在尾端，實際值：\(value)")
    }

    /// 驗證刷卡費率已輸入的文字在再次點左側後保留，新字接續輸入
    ///
    /// - Throws: 數字鍵盤以 Popover 呈現時丟出 `XCTSkip`，關閉區域會吃掉對欄位的點擊
    func testFocusCardFeeRate_再次點左側_保留已輸入文字() throws {
        // Given
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        guard let edit = openOrderEdit(in: app) else {
            return
        }
        guard edit.dismissCustomerKeyboard() else {
            return
        }
        guard edit.moveFieldToUpperForm(edit.cardFeeRateField) else {
            return
        }
        guard edit.cardFeeRateField.tapLeftToFocus(in: app) else {
            return
        }
        edit.cardFeeRateField.typeText("12")
        let isPopoverPresented = pollUntil(timeout: 2) {
            app.isNumericPopoverPresented
        }
        try XCTSkipIf(isPopoverPresented, "數字 Popover 的關閉區域會吃掉對欄位的點擊，使用者無法在 Popover 開著時再次點同一欄")

        // When
        guard edit.cardFeeRateField.tapLeftToFocus(in: app) else {
            return
        }
        edit.cardFeeRateField.typeText("3")

        // Then
        _ = pollUntil(timeout: 3) {
            edit.cardFeeRateValue?.contains("3") == true
        }
        let value = edit.cardFeeRateValue ?? ""
        XCTAssertTrue(value.contains("12"), "再次點左側不應清掉已輸入的 12")
        XCTAssertTrue(value.contains("3"), "應輸入 3")
    }

    /// 驗證從品項名稱直接點單價，單價輸入取代原值而非接在後面
    func testFocusItemUnitPrice_從品項名稱直接點單價_輸入取代原值() {
        // Given
        let app = launch(LaunchOptions(seed: .minimalOrders))
        guard let edit = openOrderEdit(in: app, orderID: "UITEST-MIN-001") else {
            return
        }
        guard edit.focusFromLeft(edit.itemNameField, isSwipingUp: true) else {
            return
        }

        // When
        guard edit.focusFromLeft(edit.itemUnitPriceField, isSwipingUp: true) else {
            return
        }
        edit.itemUnitPriceField.typeText("95")

        // Then
        _ = pollUntil(timeout: 3) {
            edit.itemUnitPriceValue == "95"
        }
        XCTAssertEqual(edit.itemUnitPriceValue, "95", "單價欄聚焦後輸入應取代原值 2800")
    }

    /// 驗證多行備註點第一行上方取得焦點後，新增文字接在第二行尾端
    func testFocusNotesFromFirstLine_多行備註_新增文字接在尾端() {
        // Given
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        guard let edit = openOrderEdit(in: app) else {
            return
        }
        guard edit.dismissCustomerKeyboard() else {
            return
        }
        guard edit.focusFromLeft(edit.notesField, isSwipingUp: true) else {
            return
        }
        edit.notesField.typeText("第一行")
        edit.notesField.typeText(XCUIKeyboardKey.return.rawValue)
        edit.notesField.typeText("第二行")
        guard edit.focusFromLeft(edit.customerField, isSwipingUp: false) else {
            return
        }
        guard edit.dismissCustomerKeyboard() else {
            return
        }

        // When
        guard edit.focusNotesFromFirstLine() else {
            return
        }
        edit.notesField.typeText("X")

        // Then
        _ = pollUntil(timeout: 3) {
            edit.notesValue == "第一行\n第二行X"
        }
        XCTAssertEqual(edit.notesValue, "第一行\n第二行X", "點第一行後新增文字應接在第二行尾端")
    }

    /// 驗證刷卡費率輸入 12.345 收鍵盤後依兩位小數顯示 12.35
    func testFocusCardFeeRate_小數輸入_收鍵盤後依格式捨入() {
        // Given
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        guard let edit = openOrderEdit(in: app) else {
            return
        }
        guard edit.dismissCustomerKeyboard() else {
            return
        }
        guard edit.focusFromLeft(edit.cardFeeRateField, isSwipingUp: true) else {
            return
        }

        // When
        edit.cardFeeRateField.typeText("12.345")
        edit.cardFeeRateField.dismissNumericKeyboard(in: app)

        // Then
        _ = pollUntil(timeout: 3) {
            edit.cardFeeRateValue == "12.35"
        }
        XCTAssertEqual(edit.cardFeeRateValue, "12.35", "收鍵盤後應依兩位小數捨入顯示")
    }

    /// 驗證無卡折抵超過實付時保留輸入，收款區段底部的計算說明下方出現紅字且儲存停用，
    /// 改回實付以內後紅字消失且儲存可用
    ///
    /// - Note: 超過實付時不會自動把折抵縮回實付金額，免得輸入中途的數字被改掉
    func testFocusCardlessDeduction_超過實付金額_保留輸入並提示調整() {
        // Given
        let app = launch(LaunchOptions(seed: .minimalOrders))
        guard let edit = openOrderEdit(in: app, orderID: "UITEST-MIN-001") else {
            return
        }
        edit.typeChargedAmount("1000", in: app)
        edit.openPaymentPicker()
        let picker = OptionPickerScreen(app: app)
        guard picker.waitUntilReady() else {
            app.failWithDiagnostics("付款方式選擇器未就緒")
            return
        }
        picker.selectOption("無卡")
        guard edit.waitUntilReady() else {
            app.failWithDiagnostics("返回訂單編輯表單後尚未就緒")
            return
        }
        let isKeyboardDismissed = pollUntil(timeout: 5) {
            !app.keyboards.firstMatch.exists
        }
        guard isKeyboardDismissed else {
            app.failWithDiagnostics("從付款方式選擇器返回後不應有欄位持有焦點")
            return
        }
        guard edit.chargedAmountValue == "1000" else {
            app.failWithDiagnostics("實付金額應維持輸入值 1000")
            return
        }

        // When
        guard edit.focusFromLeft(edit.cardlessDeductionField, isSwipingUp: true) else {
            return
        }
        edit.cardlessDeductionField.typeText("5000")
        edit.cardlessDeductionField.dismissNumericKeyboard(in: app)

        // Then
        _ = pollUntil(timeout: 3) {
            edit.cardlessDeductionValue == "5000"
        }
        XCTAssertEqual(edit.cardlessDeductionValue, "5000", "超過實付金額時折抵欄應保留輸入值")
        let message = edit.cardlessDeductionExceededMessage
        let note = edit.cardlessPaymentNote
        let supplementField = edit.cardlessSupplementField
        guard edit.revealPaymentField(message, isScrollingDown: true),
              supplementField.waitUntilStableAndHittable(timeout: 3),
              note.waitUntilStableAndHittable(timeout: 3),
              message.waitUntilStableAndHittable(timeout: 3) else {
            app.failWithDiagnostics("補款欄、計算說明或紅字提示未能露出並穩定，無法比對順序")
            return
        }
        let supplementFrame = supplementField.frame
        let noteFrame = note.frame
        let messageFrame = message.frame
        XCTAssertTrue(
            supplementFrame.maxY <= noteFrame.minY && noteFrame.maxY <= messageFrame.minY,
            "順序應為補款欄、計算方式說明、紅字提示"
        )
        XCTAssertFalse(edit.isSaveEnabled(), "超過實付金額時儲存鈕應停用")

        // When
        guard edit.focusFromLeft(edit.cardlessDeductionField, isSwipingUp: true) else {
            return
        }
        edit.cardlessDeductionField.typeText("800")
        edit.cardlessDeductionField.dismissNumericKeyboard(in: app)

        // Then
        _ = pollUntil(timeout: 3) {
            edit.cardlessDeductionValue == "800"
        }
        XCTAssertEqual(edit.cardlessDeductionValue, "800", "改回實付以內的折抵應保留輸入值")
        let isMessageRemoved = pollUntil(timeout: 3) {
            !edit.cardlessDeductionExceededMessage.exists
        }
        XCTAssertTrue(isMessageRemoved, "折抵回到實付以內時紅字提示應消失")
        XCTAssertTrue(edit.isSaveEnabled(), "折抵回到實付以內時儲存鈕應可用")
    }

    /// 驗證已有折抵的無卡訂單提高實付並存檔後，重新開啟仍保留原折抵
    ///
    /// - Note: 種子訂單 `UITEST-MIN-001` 的實付是 4200，所以改成高於它的 5000
    /// - Note: 中途值的連動由 `OrderEditFeatureDeductionTests` 驗證
    func testFocusChargedAmountFromLeft_已有折抵時提高實付_存檔重開保留折抵() {
        // Given
        let app = launch(LaunchOptions(seed: .minimalOrders))
        guard let edit = prepareSavedCardlessOrder(in: app) else {
            return
        }

        // When
        guard edit.revealPaymentField(edit.chargedAmountField, isScrollingDown: false),
              edit.chargedAmountField.tapLeftToFocus(in: app) else {
            return
        }
        for digit in ["5", "0", "0", "0"] {
            edit.chargedAmountField.typeText(digit)
        }
        edit.chargedAmountField.dismissNumericKeyboard(in: app)
        XCTAssertEqual(edit.chargedAmountValue, "5000", "實付應改成高於原值的金額")
        guard let reopened = saveAndReopenOrderEdit(edit, expectedRevenue: "4000", in: app),
              reopened.dismissCustomerKeyboard(),
              reopened.revealPaymentField(reopened.chargedAmountField, isScrollingDown: true) else {
            return
        }

        // Then
        XCTAssertEqual(reopened.chargedAmountValue, "5000", "存檔後重開應讀到新實付")
        guard reopened.revealPaymentField(
            reopened.cardlessDeductionField,
            isScrollingDown: true
        ) else {
            return
        }
        XCTAssertEqual(reopened.cardlessDeductionValue, "1000", "實付的中途輸入不應永久壓低折抵")
    }

    /// 驗證已有折抵的無卡訂單實付輸入後全部刪除，折抵還原且取消直接關閉表單
    ///
    /// - Note: 種子訂單 `UITEST-MIN-001` 的實付是 4200，刪空後還原的是這個值
    func testFocusChargedAmountFromLeft_已有折抵時輸入再刪空_還原折抵且直接取消() {
        // Given
        let app = launch(LaunchOptions(seed: .minimalOrders))
        guard let edit = prepareSavedCardlessOrder(in: app) else {
            return
        }

        // When
        guard edit.revealPaymentField(edit.chargedAmountField, isScrollingDown: false),
              edit.chargedAmountField.tapLeftToFocus(in: app) else {
            return
        }
        edit.chargedAmountField.typeText("1")
        let hasTyped = pollUntil(timeout: 3) {
            edit.chargedAmountValue == "1"
        }
        guard hasTyped else {
            app.failWithDiagnostics("前置輸入 1 未出現在實付欄，不能驗證刪空還原")
            return
        }
        edit.chargedAmountField.typeText(XCUIKeyboardKey.delete.rawValue)
        _ = pollUntil(timeout: 3) {
            edit.chargedAmountValue == ""
        }
        XCTAssertEqual(edit.chargedAmountValue, "", "刪除唯一輸入字元後草稿應為空")
        edit.chargedAmountField.dismissNumericKeyboard(in: app)
        _ = pollUntil(timeout: 3) {
            edit.chargedAmountValue == "4200"
        }
        let finalChargedAmount = edit.chargedAmountValue
        guard edit.revealPaymentField(edit.cardlessDeductionField, isScrollingDown: true) else {
            return
        }
        let finalDeduction = edit.cardlessDeductionValue
        edit.tapCancel()
        let hasClosedForm = edit.rootElement.waitForDisappearance(timeout: 5)
        let isAlertPresented = app.alerts.firstMatch.exists

        // Then
        XCTAssertEqual(finalChargedAmount, "4200", "刪空後應還原聚焦當下的實付")
        XCTAssertEqual(finalDeduction, "1000", "還原實付時應一併恢復原設定折抵")
        XCTAssertTrue(hasClosedForm, "表單回到原狀後取消應直接關閉")
        XCTAssertFalse(isAlertPresented, "還原後不應出現捨棄確認")
    }

    /// 驗證刷卡費率 0.00 輸入 5 時取代原值，輸入中為 5，收鍵盤後依兩位小數顯示 5.00
    func testFocusCardFeeRate_零值輸入_即時取代() {
        // Given
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        guard let edit = openOrderEdit(in: app) else {
            return
        }
        guard edit.dismissCustomerKeyboard() else {
            return
        }
        guard edit.focusFromLeft(edit.cardFeeRateField, isSwipingUp: true) else {
            return
        }

        // When
        edit.cardFeeRateField.typeText("5")
        _ = pollUntil(timeout: 3) {
            edit.cardFeeRateValue == "5"
        }
        let editingValue = edit.cardFeeRateValue
        edit.cardFeeRateField.dismissNumericKeyboard(in: app)
        _ = pollUntil(timeout: 3) {
            edit.cardFeeRateValue == "5.00"
        }
        let finalValue = edit.cardFeeRateValue

        // Then
        XCTAssertEqual(editingValue, "5", "輸入中應只顯示新輸入的 5")
        XCTAssertEqual(finalValue, "5.00", "收鍵盤後應依兩位小數顯示")
    }

    /// 驗證刷卡費率只聚焦不輸入時，聚焦中為空草稿，失焦後還原為 0.00
    func testFocusCardFeeRate_未輸入即失焦_還原原值() {
        // Given
        let app = launch(LaunchOptions(seed: .lookupsOnly))
        guard let edit = openOrderEdit(in: app) else {
            return
        }
        guard edit.dismissCustomerKeyboard() else {
            return
        }

        // When
        guard edit.focusFromLeft(edit.cardFeeRateField, isSwipingUp: true) else {
            return
        }
        let focusedValue = edit.cardFeeRateValue
        edit.cardFeeRateField.dismissNumericKeyboard(in: app)
        _ = pollUntil(timeout: 3) {
            edit.cardFeeRateValue == "0.00"
        }
        let finalValue = edit.cardFeeRateValue

        // Then
        XCTAssertEqual(focusedValue, "", "聚焦中的刷卡費率應顯示空草稿")
        XCTAssertEqual(finalValue, "0.00", "未輸入就失焦應恢復原有的 0.00")
    }
}

// MARK: - Private Method

private extension OrderEditInputFocusUITests {

    /// 開啟新增或指定既有訂單的編輯表單，等待根元素就緒
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - orderID: 要編輯的訂單編號，缺值時新增訂單
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 已就緒的編輯表單，無法開啟時附診斷並回傳缺值
    func openOrderEdit(
        in app: XCUIApplication,
        orderID: String? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> OrderEditScreen? {
        guard RootNavigationScreen(app: app).goToOrders(file: file, line: line) else {
            app.failWithDiagnostics("無法切到訂單分頁", file: file, line: line)
            return nil
        }
        let orders = OrdersScreen(app: app)
        guard orders.waitUntilReady() else {
            app.failWithDiagnostics("訂單清單尚未就緒", file: file, line: line)
            return nil
        }
        if let orderID {
            orders.tapOrder(orderID: orderID, file: file, line: line)
            let detail = OrderDetailScreen(app: app)
            guard detail.waitUntilReady() else {
                app.failWithDiagnostics("指定訂單詳情尚未就緒", file: file, line: line)
                return nil
            }
            detail.openMoreMenu(file: file, line: line)
            guard detail.tapEdit(file: file, line: line) else {
                return nil
            }
        } else {
            orders.tapAddOrder(file: file, line: line)
        }
        let edit = OrderEditScreen(app: app)
        guard edit.waitUntilReady() else {
            app.failWithDiagnostics("訂單編輯表單尚未就緒", file: file, line: line)
            return nil
        }
        return edit
    }

    /// 經 UI 準備非零折抵的無卡訂單，輸入並存檔重開後回傳未修改的表單
    ///
    /// - Parameter app: 受測 App
    /// - Returns: 實付為 4200、折抵為 1000 的既有表單，無法建立前置時為缺值
    func prepareSavedCardlessOrder(in app: XCUIApplication) -> OrderEditScreen? {
        guard let edit = openOrderEdit(in: app, orderID: "UITEST-MIN-001"),
              edit.dismissCustomerKeyboard(),
              edit.revealPaymentField(edit.chargedAmountField, isScrollingDown: true) else {
            return nil
        }
        guard edit.chargedAmountValue == "4200" else {
            app.failWithDiagnostics("前置訂單實付應符合種子")
            return nil
        }
        edit.openPaymentPicker()
        let picker = OptionPickerScreen(app: app)
        guard picker.waitUntilReady() else {
            app.failWithDiagnostics("準備非零折抵時，付款方式選擇器未就緒")
            return nil
        }
        picker.selectOption("無卡")
        guard picker.rootElement.waitForDisappearance(timeout: 5),
              edit.waitUntilReady() else {
            app.failWithDiagnostics("選取無卡付款方式後未返回訂單表單")
            return nil
        }
        guard edit.focusFromLeft(edit.cardlessDeductionField, isSwipingUp: true) else {
            return nil
        }
        edit.cardlessDeductionField.typeText("1000")
        edit.cardlessDeductionField.dismissNumericKeyboard(in: app)
        guard edit.cardlessDeductionValue == "1000" else {
            app.failWithDiagnostics("前置折抵應為非零設定值")
            return nil
        }
        guard let reopened = saveAndReopenOrderEdit(edit, expectedRevenue: "3200", in: app),
              reopened.dismissCustomerKeyboard(),
              reopened.revealPaymentField(reopened.chargedAmountField, isScrollingDown: true) else {
            return nil
        }
        guard reopened.chargedAmountValue == "4200" else {
            app.failWithDiagnostics("前置存檔不應改動實付")
            return nil
        }
        guard reopened.revealPaymentField(
            reopened.cardlessDeductionField,
            isScrollingDown: true
        ) else {
            return nil
        }
        guard reopened.cardlessDeductionValue == "1000" else {
            app.failWithDiagnostics("前置折抵應已存檔並讀回")
            return nil
        }
        return reopened
    }

    /// 儲存目前表單，等詳情的收款金額更新為這次寫入的結果後，重新開啟同一張訂單的編輯表單
    ///
    /// - Parameters:
    ///   - edit: 要儲存的表單
    ///   - expectedRevenue: 儲存成功後詳情收款金額的數字部分，表單關閉不代表寫入已完成
    ///   - app: 受測 App
    /// - Returns: 重新開啟的表單，儲存或開啟失敗時為缺值
    func saveAndReopenOrderEdit(
        _ edit: OrderEditScreen,
        expectedRevenue: String,
        in app: XCUIApplication
    ) -> OrderEditScreen? {
        edit.tapSave()
        guard edit.rootElement.waitForDisappearance(timeout: 10) else {
            app.failWithDiagnostics("儲存訂單後編輯表單未關閉")
            return nil
        }
        let detail = OrderDetailScreen(app: app)
        guard detail.waitUntilReady() else {
            app.failWithDiagnostics("儲存訂單後詳情頁未就緒")
            return nil
        }
        let isSaved = pollUntil(timeout: 10) {
            detail.summaryValue(.revenue)?.filter(\.isNumber) == expectedRevenue
        }
        guard isSaved else {
            app.failWithDiagnostics("儲存後詳情收款金額未更新為 \(expectedRevenue)")
            return nil
        }
        detail.openMoreMenu()
        guard detail.tapEdit() else {
            return nil
        }
        let reopened = OrderEditScreen(app: app)
        guard reopened.waitUntilReady() else {
            app.failWithDiagnostics("存檔後重新開啟的訂單表單未就緒")
            return nil
        }
        return reopened
    }
}
