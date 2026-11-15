//
//  OrderEditInputFocusUITests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/11/5.
//

import XCTest

/// 訂單編輯欄位的文字接續、金額還原與無卡折抵 UI 測試
@MainActor
final class OrderEditInputFocusUITests: BLUITestCase {

    // MARK: - Properties

    /// 以注音組成候選字「小」需要的軟體鍵盤按鍵
    private static let zhuyinKeys = ["ㄒ", "ㄧ", "ㄠ", "三聲、"]

    /// 驗證新訂單實付金額 0 從左側聚焦後輸入 1000，輸入中只顯示 1000 而不是 01000 或 10000，按完成鍵後仍是 1000
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testFocusChargedAmountFromLeft_零值輸入_即時取代且失焦保留() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .lookupsOnly))
        let edit = try OrdersScreen.open(in: app).tapAddOrder()
        try edit.dismissCustomerKeyboard()
        try edit.revealPaymentField(edit.chargedAmountField, isScrollingDown: true)
        try requireCondition(edit.chargedAmountValue == "0", in: app, "聚焦前實付應顯示 0")

        // When
        try edit.chargedAmountField.tapLeftToFocus(in: app)
        edit.chargedAmountField.typeText("1000")
        _ = Polling.wait(timeout: 3) {
            edit.chargedAmountValue == "1000"
        }
        let editingValue = edit.chargedAmountValue
        try edit.tapNumericKeyboardDone()
        _ = Polling.wait(timeout: 3) {
            edit.chargedAmountValue == "1000"
        }
        let finalValue = edit.chargedAmountValue

        // Then
        XCTAssertEqual(editingValue, "1000", "輸入中應只顯示新輸入的金額")
        XCTAssertEqual(finalValue, "1000", "失焦後應保留新輸入的金額")
    }

    /// 驗證既有訂單客戶「林書宇」從左側點擊聚焦後輸入「小姐」，結果是「林書宇小姐」：游標由 App 放到尾端，不停在點擊處
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testFocusCustomerFromLeft_既有名稱接續輸入_新增文字接在尾端() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .minimalOrders))
        let edit = try OrdersScreen.open(in: app).tapOrder(orderID: "UITEST-MIN-001").openEdit()

        // When
        try edit.focusCustomerFromLeft()
        edit.customerField.typeText("小姐")

        // Then
        _ = Polling.wait(timeout: 3) {
            edit.customerValue == "林書宇小姐"
        }
        XCTAssertEqual(edit.customerValue, "林書宇小姐", "客戶名稱應保留原文並從尾端接續")
    }

    /// 驗證逐鍵輸入注音並點選候選字時，既有姓名保留且組字結果接在尾端
    ///
    /// - Throws: UI 操作失敗時丟出 UITestError.stopped，系統未提供注音按鍵時丟出 XCTSkip
    func testFocusCustomerFromLeft_逐鍵注音組字_保留原文並追加候選字() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .minimalOrders))
        let edit = try OrdersScreen.open(in: app).tapOrder(orderID: "UITEST-MIN-001").openEdit()
        try edit.focusCustomerFromLeft()
        for symbol in Self.zhuyinKeys {
            guard app.waitForKeyboardKey(symbol, timeout: 2) else {
                throw XCTSkip("系統鍵盤未提供注音按鍵「\(symbol)」，無法驗證逐鍵組字的外部環境差異")
            }
        }

        // When
        for symbol in Self.zhuyinKeys {
            try app.tapKeyboardKey(symbol)
        }
        try app.tapKeyboardCandidate("小")

        // Then
        _ = Polling.wait(timeout: 3) {
            edit.customerValue == "林書宇小"
        }
        XCTAssertEqual(edit.customerValue, "林書宇小", "注音組字完成後應保留姓名並追加候選字")
    }

    /// 驗證只聚焦金額不輸入時草稿為空，失焦還原且取消直接關閉未修改表單
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testFocusChargedAmountFromLeft_未輸入即失焦_還原原值且直接取消() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .minimalOrders))
        let edit = try OrdersScreen.open(in: app).tapOrder(orderID: "UITEST-MIN-001").openEdit()

        // When
        try edit.focusChargedAmountFromLeft()
        let focusedValue = edit.chargedAmountValue
        try edit.tapNumericKeyboardDone()
        _ = Polling.wait(timeout: 3) {
            edit.chargedAmountValue == "4200"
        }
        let finalValue = edit.chargedAmountValue
        try edit.tapCancel()
        let hasClosedForm = edit.rootElement.waitForDisappearance(timeout: 5)
        let isAlertPresented = app.alerts.firstMatch.exists

        // Then
        XCTAssertEqual(focusedValue, "", "聚焦中的實付金額應顯示空草稿")
        XCTAssertEqual(finalValue, "4200", "未輸入就失焦應恢復原有金額")
        XCTAssertTrue(hasClosedForm, "只聚焦不輸入時，取消應直接關閉表單")
        XCTAssertFalse(isAlertPresented, "只聚焦不輸入不應出現捨棄確認")
    }

    /// 驗證輸入金額再全部刪除後還原聚焦當下的值，取消時直接關閉表單
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testFocusChargedAmountFromLeft_輸入後全部刪除_還原原值且直接取消() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .minimalOrders))
        let edit = try OrdersScreen.open(in: app).tapOrder(orderID: "UITEST-MIN-001").openEdit()

        // When
        try edit.focusChargedAmountFromLeft()
        edit.chargedAmountField.typeText("1")
        _ = Polling.wait(timeout: 3) {
            edit.chargedAmountValue == "1"
        }
        let editingValue = edit.chargedAmountValue
        edit.chargedAmountField.typeText(XCUIKeyboardKey.delete.rawValue)
        _ = Polling.wait(timeout: 3) {
            edit.chargedAmountValue == ""
        }
        let emptiedValue = edit.chargedAmountValue
        try edit.tapNumericKeyboardDone()
        _ = Polling.wait(timeout: 3) {
            edit.chargedAmountValue == "4200"
        }
        let finalValue = edit.chargedAmountValue
        try edit.tapCancel()
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
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testFocusCustomerFromLeft_再次點左側_原文保留且新字不在尾端() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .minimalOrders))
        let edit = try OrdersScreen.open(in: app).tapOrder(orderID: "UITEST-MIN-001").openEdit()
        try edit.focusCustomerFromLeft()

        // When
        try edit.customerField.tapLeftToFocus(in: app, dx: 0.01)
        edit.customerField.typeText("小")

        // Then
        let hasInsertedText = Polling.wait(timeout: 3) {
            edit.customerValue?.contains("小") == true
        }
        let value = edit.customerValue ?? ""
        XCTAssertTrue(hasInsertedText, "再次點左側後必須實際輸入小，實際值：\(value)")
        XCTAssertTrue(value.contains("林書宇"), "客戶名稱應保留原文，實際值：\(value)")
        XCTAssertFalse(value.hasSuffix("小"), "再次點左側後新字不應落在尾端，實際值：\(value)")
    }

    /// 驗證刷卡費率已輸入的文字在再次點左側後保留，新字接續輸入
    ///
    /// - Throws: UI 操作失敗時丟出 UITestError.stopped，數字 Popover 攔截點擊時丟出 XCTSkip
    func testTapLeftToFocus_刷卡費率再次點左側_保留已輸入文字() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .lookupsOnly))
        let edit = try OrdersScreen.open(in: app).tapAddOrder()
        try edit.dismissCustomerKeyboard()
        try edit.moveFieldToUpperForm(edit.cardFeeRateField)
        try edit.cardFeeRateField.tapLeftToFocus(in: app)
        edit.cardFeeRateField.typeText("12")
        let isPopoverPresented = Polling.wait(timeout: 2) {
            app.isNumericPopoverPresented
        }
        try XCTSkipIf(isPopoverPresented, "數字 Popover 的關閉區域會吃掉對欄位的點擊，使用者無法在 Popover 開著時再次點同一欄")

        // When
        try edit.cardFeeRateField.tapLeftToFocus(in: app)
        edit.cardFeeRateField.typeText("3")

        // Then
        _ = Polling.wait(timeout: 3) {
            edit.cardFeeRateValue?.contains("3") == true
        }
        let value = edit.cardFeeRateValue ?? ""
        XCTAssertTrue(value.contains("12"), "再次點左側不應清掉已輸入的 12")
        XCTAssertTrue(value.contains("3"), "應輸入 3")
    }

    /// 驗證從品項名稱直接點單價，單價輸入取代原值而非接在後面
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testFocusFromLeft_從品項名稱直接點單價_輸入取代原值() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .minimalOrders))
        let edit = try OrdersScreen.open(in: app).tapOrder(orderID: "UITEST-MIN-001").openEdit()
        try edit.focusFromLeft(edit.itemNameField, isSwipingUp: true)

        // When
        try edit.focusFromLeft(edit.itemUnitPriceField, isSwipingUp: true)
        edit.itemUnitPriceField.typeText("95")

        // Then
        _ = Polling.wait(timeout: 3) {
            edit.itemUnitPriceValue == "95"
        }
        XCTAssertEqual(edit.itemUnitPriceValue, "95", "單價欄聚焦後輸入應取代原值 2800")
    }

    /// 驗證多行備註點第一行上方取得焦點後，新增文字接在第二行尾端
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testFocusNotesFromFirstLine_多行備註_新增文字接在尾端() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .lookupsOnly))
        let edit = try OrdersScreen.open(in: app).tapAddOrder()
        try edit.dismissCustomerKeyboard()
        try edit.focusFromLeft(edit.notesField, isSwipingUp: true)
        edit.notesField.typeText("第一行")
        edit.notesField.typeText(XCUIKeyboardKey.return.rawValue)
        edit.notesField.typeText("第二行")
        try edit.focusFromLeft(edit.customerField, isSwipingUp: false)
        try edit.dismissCustomerKeyboard()

        // When
        try edit.focusNotesFromFirstLine()
        edit.notesField.typeText("X")

        // Then
        _ = Polling.wait(timeout: 3) {
            edit.notesValue == "第一行\n第二行X"
        }
        XCTAssertEqual(edit.notesValue, "第一行\n第二行X", "點第一行後新增文字應接在第二行尾端")
    }

    /// 驗證刷卡費率輸入 12.345 收鍵盤後依兩位小數顯示 12.35
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testDismissNumericKeyboard_刷卡費率輸入小數_依格式捨入() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .lookupsOnly))
        let edit = try OrdersScreen.open(in: app).tapAddOrder()
        try edit.dismissCustomerKeyboard()
        try edit.focusFromLeft(edit.cardFeeRateField, isSwipingUp: true)

        // When
        edit.cardFeeRateField.typeText("12.345")
        try edit.cardFeeRateField.dismissNumericKeyboard(in: app)

        // Then
        _ = Polling.wait(timeout: 3) {
            edit.cardFeeRateValue == "12.35"
        }
        XCTAssertEqual(edit.cardFeeRateValue, "12.35", "收鍵盤後應依兩位小數捨入顯示")
    }

    /// 驗證無卡折抵超過實付時保留輸入，說明下方顯示紅字且儲存停用
    ///
    /// - Throws: UI 操作或必要框線未就緒時丟出 UITestError.stopped
    func testFocusFromLeft_無卡折抵超過實付金額_保留輸入並提示調整() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .minimalOrders))
        let edit = try OrdersScreen.open(in: app).tapOrder(orderID: "UITEST-MIN-001").openEdit()
        try edit.typeChargedAmount("1000")
        let picker = try edit.openPaymentPicker()
        try picker.selectOption("無卡")
        try requireCondition(edit.waitUntilReady(), in: app, "返回訂單編輯表單後尚未就緒")
        let isKeyboardDismissed = Polling.wait(timeout: 5) {
            !app.keyboards.firstMatch.exists
        }
        try requireCondition(isKeyboardDismissed, in: app, "從付款方式選擇器返回後不應有欄位持有焦點")
        try requireCondition(edit.chargedAmountValue == "1000", in: app, "實付金額應維持輸入值 1000")

        // When
        try edit.focusFromLeft(edit.cardlessDeductionField, isSwipingUp: true)
        edit.cardlessDeductionField.typeText("5000")
        try edit.cardlessDeductionField.dismissNumericKeyboard(in: app)
        _ = Polling.wait(timeout: 3) {
            edit.cardlessDeductionValue == "5000"
        }
        let deductionValue = edit.cardlessDeductionValue
        let message = edit.cardlessDeductionExceededMessage
        let note = edit.cardlessPaymentNote
        let supplementField = edit.cardlessSupplementField
        try edit.revealPaymentField(message, isScrollingDown: true)
        try requireCondition(
            supplementField.waitUntilStableAndHittable(timeout: 3)
                && note.waitUntilStableAndHittable(timeout: 3)
                && message.waitUntilStableAndHittable(timeout: 3),
            in: app,
            "補款欄、計算說明或紅字提示未能露出並穩定，無法比對順序"
        )

        // Then
        XCTAssertEqual(deductionValue, "5000", "超過實付金額時折抵欄應保留輸入值")
        let supplementFrame = supplementField.frame
        let noteFrame = note.frame
        let messageFrame = message.frame
        XCTAssertTrue(
            supplementFrame.maxY <= noteFrame.minY && noteFrame.maxY <= messageFrame.minY,
            "順序應為補款欄、計算方式說明、紅字提示"
        )
        XCTAssertFalse(try edit.isSaveEnabled(), "超過實付金額時儲存鈕應停用")
    }

    /// 驗證無卡折抵由超過實付改回實付以內後，保留新值且紅字消失與儲存可用
    ///
    /// - Throws: UI 操作或超額折抵前置不成立時丟出 UITestError.stopped
    func testFocusFromLeft_無卡折抵改回實付以內_提示消失且可儲存() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .minimalOrders))
        let edit = try OrdersScreen.open(in: app).tapOrder(orderID: "UITEST-MIN-001").openEdit()
        try edit.typeChargedAmount("1000")
        let picker = try edit.openPaymentPicker()
        try picker.selectOption("無卡")
        try requireCondition(edit.waitUntilReady(), in: app, "返回訂單編輯表單後尚未就緒")
        let isKeyboardDismissed = Polling.wait(timeout: 5) {
            !app.keyboards.firstMatch.exists
        }
        try requireCondition(isKeyboardDismissed, in: app, "從付款方式選擇器返回後不應有欄位持有焦點")
        try requireCondition(edit.chargedAmountValue == "1000", in: app, "實付金額應維持輸入值 1000")
        try edit.focusFromLeft(edit.cardlessDeductionField, isSwipingUp: true)
        edit.cardlessDeductionField.typeText("5000")
        try edit.cardlessDeductionField.dismissNumericKeyboard(in: app)
        let hasExceededValue = Polling.wait(timeout: 3) {
            edit.cardlessDeductionValue == "5000"
        }
        try requireCondition(hasExceededValue, in: app, "超額折抵前置應保留輸入值 5000")
        try edit.revealPaymentField(edit.cardlessDeductionExceededMessage, isScrollingDown: true)
        try requireCondition(edit.cardlessDeductionExceededMessage.exists, in: app, "超額折抵前置應顯示紅字提示")
        let isSaveEnabled = try edit.isSaveEnabled()
        try requireCondition(!isSaveEnabled, in: app, "超額折抵前置的儲存鈕應停用")

        // When
        try edit.focusFromLeft(edit.cardlessDeductionField, isSwipingUp: true)
        edit.cardlessDeductionField.typeText("800")
        try edit.cardlessDeductionField.dismissNumericKeyboard(in: app)

        // Then
        _ = Polling.wait(timeout: 3) {
            edit.cardlessDeductionValue == "800"
        }
        XCTAssertEqual(edit.cardlessDeductionValue, "800", "改回實付以內的折抵應保留輸入值")
        let isMessageRemoved = Polling.wait(timeout: 3) {
            !edit.cardlessDeductionExceededMessage.exists
        }
        XCTAssertTrue(isMessageRemoved, "折抵回到實付以內時紅字提示應消失")
        XCTAssertTrue(try edit.isSaveEnabled(), "折抵回到實付以內時儲存鈕應可用")
    }

    /// 驗證已有折抵的無卡訂單提高實付並存檔後，重新開啟仍保留原折抵
    ///
    /// - Note: 種子訂單 `UITEST-MIN-001` 的實付是 4200，所以改成高於它的 5000
    /// - Note: 中途值的連動由 `OrderEditFeatureDeductionTests` 驗證
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testFocusChargedAmountFromLeft_已有折抵時提高實付_存檔重開保留折抵() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .minimalOrders))
        let edit = try prepareSavedCardlessOrder(in: app)

        // When
        try edit.revealPaymentField(edit.chargedAmountField, isScrollingDown: false)
        try edit.chargedAmountField.tapLeftToFocus(in: app)
        for digit in ["5", "0", "0", "0"] {
            edit.chargedAmountField.typeText(digit)
        }
        try edit.chargedAmountField.dismissNumericKeyboard(in: app)
        try requireCondition(
            edit.chargedAmountValue == "5000",
            in: app,
            "實付應改成高於原值的金額 (實際：\(String(describing: edit.chargedAmountValue)))"
        )
        let reopened = try saveAndReopenOrderEdit(edit, expectedRevenue: "4000", in: app)
        try reopened.dismissCustomerKeyboard()
        try reopened.revealPaymentField(reopened.chargedAmountField, isScrollingDown: true)

        let finalChargedAmount = reopened.chargedAmountValue
        try reopened.revealPaymentField(reopened.cardlessDeductionField, isScrollingDown: true)
        let finalDeduction = reopened.cardlessDeductionValue

        // Then
        XCTAssertEqual(finalChargedAmount, "5000", "存檔後重開應讀到新實付")
        XCTAssertEqual(finalDeduction, "1000", "實付的中途輸入不應永久壓低折抵")
    }

    /// 驗證已有折抵的無卡訂單實付輸入後全部刪除，折抵還原且取消直接關閉表單
    ///
    /// - Note: 種子訂單 `UITEST-MIN-001` 的實付是 4200，刪空後還原的是這個值
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testFocusChargedAmountFromLeft_已有折抵時輸入再刪空_還原折抵且直接取消() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .minimalOrders))
        let edit = try prepareSavedCardlessOrder(in: app)

        // When
        try edit.revealPaymentField(edit.chargedAmountField, isScrollingDown: false)
        try edit.chargedAmountField.tapLeftToFocus(in: app)
        edit.chargedAmountField.typeText("1")
        let hasTyped = Polling.wait(timeout: 3) {
            edit.chargedAmountValue == "1"
        }
        try requireCondition(hasTyped, in: app, "前置輸入 1 未出現在實付欄，不能驗證刪空還原")
        edit.chargedAmountField.typeText(XCUIKeyboardKey.delete.rawValue)
        _ = Polling.wait(timeout: 3) {
            edit.chargedAmountValue == ""
        }
        try requireCondition(
            edit.chargedAmountValue == "",
            in: app,
            "刪除唯一輸入字元後草稿應為空 (實際：\(String(describing: edit.chargedAmountValue)))"
        )
        try edit.chargedAmountField.dismissNumericKeyboard(in: app)
        _ = Polling.wait(timeout: 3) {
            edit.chargedAmountValue == "4200"
        }
        let finalChargedAmount = edit.chargedAmountValue
        try edit.revealPaymentField(edit.cardlessDeductionField, isScrollingDown: true)
        let finalDeduction = edit.cardlessDeductionValue
        try edit.tapCancel()
        let hasClosedForm = edit.rootElement.waitForDisappearance(timeout: 5)
        let isAlertPresented = app.alerts.firstMatch.exists

        // Then
        XCTAssertEqual(finalChargedAmount, "4200", "刪空後應還原聚焦當下的實付")
        XCTAssertEqual(finalDeduction, "1000", "還原實付時應一併恢復原設定折抵")
        XCTAssertTrue(hasClosedForm, "表單回到原狀後取消應直接關閉")
        XCTAssertFalse(isAlertPresented, "還原後不應出現捨棄確認")
    }

    /// 驗證刷卡費率 0.00 輸入 5 時取代原值，輸入中為 5，收鍵盤後依兩位小數顯示 5.00
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testFocusFromLeft_刷卡費率零值輸入_即時取代() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .lookupsOnly))
        let edit = try OrdersScreen.open(in: app).tapAddOrder()
        try edit.dismissCustomerKeyboard()

        // When
        try edit.focusFromLeft(edit.cardFeeRateField, isSwipingUp: true)
        edit.cardFeeRateField.typeText("5")
        _ = Polling.wait(timeout: 3) {
            edit.cardFeeRateValue == "5"
        }
        let editingValue = edit.cardFeeRateValue
        try edit.cardFeeRateField.dismissNumericKeyboard(in: app)
        _ = Polling.wait(timeout: 3) {
            edit.cardFeeRateValue == "5.00"
        }
        let finalValue = edit.cardFeeRateValue

        // Then
        XCTAssertEqual(editingValue, "5", "輸入中應只顯示新輸入的 5")
        XCTAssertEqual(finalValue, "5.00", "收鍵盤後應依兩位小數顯示")
    }

    /// 驗證刷卡費率只聚焦不輸入時，聚焦中為空草稿，失焦後還原為 0.00
    ///
    /// - Throws: 必要的 UI 操作或前置條件失敗時丟出 UITestError.stopped
    func testFocusFromLeft_刷卡費率未輸入即失焦_還原原值() throws {
        // Given
        let app = try launch(LaunchOptions(seed: .lookupsOnly))
        let edit = try OrdersScreen.open(in: app).tapAddOrder()
        try edit.dismissCustomerKeyboard()

        // When
        try edit.focusFromLeft(edit.cardFeeRateField, isSwipingUp: true)
        let focusedValue = edit.cardFeeRateValue
        try edit.cardFeeRateField.dismissNumericKeyboard(in: app)
        _ = Polling.wait(timeout: 3) {
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

    /// 經 UI 準備非零折抵的無卡訂單，存檔重開後回傳未修改的表單
    ///
    /// - Parameters:
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 實付為 4200、折抵為 1000 的既有表單
    /// - Throws: UI 操作或無卡訂單前置不成立時丟出 UITestError.stopped
    func prepareSavedCardlessOrder(
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> OrderEditScreen {
        let edit = try OrdersScreen.open(in: app, file: file, line: line)
            .tapOrder(orderID: "UITEST-MIN-001", file: file, line: line)
            .openEdit(file: file, line: line)
        try edit.dismissCustomerKeyboard(file: file, line: line)
        try edit.revealPaymentField(
            edit.chargedAmountField,
            isScrollingDown: true,
            file: file,
            line: line
        )
        try requireCondition(
            edit.chargedAmountValue == "4200",
            in: app,
            "前置訂單實付應符合種子",
            file: file,
            line: line
        )
        let picker = try edit.openPaymentPicker(file: file, line: line)
        try picker.selectOption("無卡", file: file, line: line)
        try requireCondition(
            picker.rootElement.waitForDisappearance(timeout: 5) && edit.waitUntilReady(),
            in: app,
            "選取無卡付款方式後未返回訂單表單",
            file: file,
            line: line
        )
        try edit.focusFromLeft(
            edit.cardlessDeductionField,
            isSwipingUp: true,
            file: file,
            line: line
        )
        edit.cardlessDeductionField.typeText("1000")
        try edit.cardlessDeductionField.dismissNumericKeyboard(in: app, file: file, line: line)
        try requireCondition(
            edit.cardlessDeductionValue == "1000",
            in: app,
            "前置折抵應為非零設定值",
            file: file,
            line: line
        )
        let reopened = try saveAndReopenOrderEdit(
            edit,
            expectedRevenue: "3200",
            in: app,
            file: file,
            line: line
        )
        try reopened.dismissCustomerKeyboard(file: file, line: line)
        try reopened.revealPaymentField(
            reopened.chargedAmountField,
            isScrollingDown: true,
            file: file,
            line: line
        )
        try requireCondition(
            reopened.chargedAmountValue == "4200",
            in: app,
            "前置存檔不應改動實付",
            file: file,
            line: line
        )
        try reopened.revealPaymentField(
            reopened.cardlessDeductionField,
            isScrollingDown: true,
            file: file,
            line: line
        )
        try requireCondition(
            reopened.cardlessDeductionValue == "1000",
            in: app,
            "前置折抵應已存檔並讀回",
            file: file,
            line: line
        )
        return reopened
    }

    /// 儲存表單並等詳情收款更新後，重新開啟同一張訂單的編輯表單
    ///
    /// - Parameters:
    ///   - edit: 要儲存的表單
    ///   - expectedRevenue: 儲存成功後詳情收款金額的數字部分
    ///   - app: 受測 App
    ///   - file: 失敗時回報的檔案位置
    ///   - line: 失敗時回報的行號
    /// - Returns: 儲存成功後重新開啟的表單
    /// - Throws: UI 操作、儲存或重新開啟失敗時丟出 UITestError.stopped
    func saveAndReopenOrderEdit(
        _ edit: OrderEditScreen,
        expectedRevenue: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws(UITestError) -> OrderEditScreen {
        try edit.tapSave(file: file, line: line)
        try requireCondition(
            edit.rootElement.waitForDisappearance(timeout: 10),
            in: app,
            "儲存訂單後編輯表單未關閉",
            file: file,
            line: line
        )
        let detail = OrderDetailScreen(app: app)
        try requireCondition(
            detail.waitUntilReady(),
            in: app,
            "儲存訂單後詳情頁未就緒",
            file: file,
            line: line
        )
        let isSaved = Polling.wait(timeout: 10) {
            detail.summaryValue(.revenue)?.filter(\.isNumber) == expectedRevenue
        }
        try requireCondition(
            isSaved,
            in: app,
            "儲存後詳情收款金額未更新為 \(expectedRevenue)",
            file: file,
            line: line
        )
        return try detail.openEdit(file: file, line: line)
    }
}
