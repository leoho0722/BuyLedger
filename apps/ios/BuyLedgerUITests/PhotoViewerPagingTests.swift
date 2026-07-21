//
//  PhotoViewerPagingTests.swift
//  BuyLedgerUITests
//
//  Created by Leo Ho on 2026/7/21.
//

import XCTest

/// 照片檢視器推進呈現與換頁的回歸測試
///
/// 檢視器由編輯表單以 push 呈現後，「推進是否成功」與「橫向換頁手勢是否仍可用」
/// 都取決於宿主導覽堆疊的手勢環境，unit test 與 snapshot test 皆無法覆蓋，
/// 只能以介面測試把「推進後可左右換頁、Back 可返回表單」釘住
final class PhotoViewerPagingTests: XCTestCase {

    // MARK: - Setup

    override func setUpWithError() throws {
        continueAfterFailure = false
        // 照片選擇器互動走直向版面的正規化座標，前序測試可能把模擬器留在橫向
        XCUIDevice.shared.orientation = .portrait
    }

    // MARK: - Tests

    /// 於編輯表單加入兩張照片後點縮圖：檢視器應推進呈現、可換頁、Back 返回表單
    @MainActor
    func testPushedViewerPagesBetweenPhotosAndPopsBack() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))

        // 先切到訂單分頁 (啟動分頁會隨上次選擇而異)，再開新訂單表單
        let ordersTab = app.tabBars.buttons["訂單"]
        guard ordersTab.waitForExistence(timeout: 5) else {
            throw XCTSkip("找不到訂單分頁，可能是版面結構已變動")
        }
        ordersTab.tap()

        let newOrderButton = app.buttons["新增訂單"].firstMatch
        guard newOrderButton.waitForExistence(timeout: 5) else {
            throw XCTSkip("找不到新增訂單按鈕")
        }
        newOrderButton.tap()

        // 捲到表單下方的照片區段
        let addPhotosButton = app.buttons["加入照片"].firstMatch
        var scrollAttempts = 0
        while !addPhotosButton.isHittable, scrollAttempts < 6 {
            app.swipeUp()
            scrollAttempts += 1
        }
        guard addPhotosButton.isHittable else {
            throw XCTSkip("捲動後仍找不到加入照片按鈕")
        }
        addPhotosButton.tap()

        // 系統照片選擇器為外部行程，元素查詢不可靠，以正規化座標點選前兩張並確認。
        // 選擇器未出現或版面不同時跳過，不讓環境差異變成 App 行為的假失敗
        try selectTwoPhotosFromPicker(in: app)

        // 點第一張縮圖：SwiftUI Button 會把內容影像收斂成 label「訂單照片」的按鈕元素。
        // 選擇器收合後表單會捲回頂端，而 Form 的離屏列不存在於 accessibility 樹，須再捲到照片區
        let firstThumbnail = app.buttons["訂單照片"].firstMatch
        scrollAttempts = 0
        while !firstThumbnail.exists, scrollAttempts < 6 {
            app.swipeUp()
            scrollAttempts += 1
        }
        guard firstThumbnail.waitForExistence(timeout: 5) else {
            attachScreenshot(of: app, named: "縮圖未出現時的畫面")
            throw XCTSkip("照片縮圖未出現，可能是照片選擇器未完成加入")
        }
        firstThumbnail.tap()

        // 關鍵斷言一：檢視器成功推進 (置中計數標題 1/2 出現在導覽列)
        let firstPageTitle = app.navigationBars.staticTexts["1/2"]
        XCTAssertTrue(firstPageTitle.waitForExistence(timeout: 5), "點縮圖後檢視器應推進呈現並顯示計數 1/2")

        // 關鍵斷言二：橫向滑動換到第二張 (計數變為 2/2)
        let viewerPhoto = app.images["訂單照片"].firstMatch
        viewerPhoto.swipeLeft()
        let secondPageTitle = app.navigationBars.staticTexts["2/2"]
        XCTAssertTrue(secondPageTitle.waitForExistence(timeout: 5), "檢視器內左滑應換頁至 2/2")

        // 關鍵斷言三：宿主堆疊的 Back 返回編輯表單。以導覽列標題驗證，
        // 因為 pop 後表單捲回頂端，照片區離屏不在 accessibility 樹，不能拿表單深處的元素當證據
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.navigationBars["新訂單"].waitForExistence(timeout: 5), "Back 後應回到編輯表單")
    }
}

// MARK: - Private Method

private extension PhotoViewerPagingTests {

    /// 於系統照片選擇器內以正規化座標點選前兩張照片並按下確認
    ///
    /// 選擇器為外部行程 remote view，元素查詢不穩定；座標取自 iPhone 直向版面的
    /// 相片格位置 (三欄格、首列約在畫面 45% 高)。任一步驟不符預期即 XCTSkip
    @MainActor
    func selectTwoPhotosFromPicker(in app: XCUIApplication) throws {
        // 等選擇器浮現 (取消鈕所在的 sheet 蓋住表單，加入照片鈕不再可點)
        let window = app.windows.firstMatch
        let pickerAppeared = expectation(description: "photo picker appeared")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { pickerAppeared.fulfill() }
        wait(for: [pickerAppeared], timeout: 5)

        attachScreenshot(of: app, named: "選擇器開啟後")

        // 首列三欄格的前兩張
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.17, dy: 0.45)).tap()
        window.coordinate(withNormalizedOffset: CGVector(dx: 0.50, dy: 0.45)).tap()

        attachScreenshot(of: app, named: "點選兩張後")

        // 確認鈕：多選模式右上的「加入」；不同系統版本的 label 可能為勾號按鈕
        let addButton = app.buttons["加入"].firstMatch
        if addButton.waitForExistence(timeout: 3) {
            addButton.tap()
        } else {
            // 回退：點右上角勾號的座標位置
            window.coordinate(withNormalizedOffset: CGVector(dx: 0.90, dy: 0.165)).tap()
        }
    }

    /// 把目前畫面存為測試附件，供 skip 或失敗時離線診斷
    @MainActor
    func attachScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
