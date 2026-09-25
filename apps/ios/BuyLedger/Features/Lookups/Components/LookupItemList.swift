//
//  LookupItemList.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/24.
//

import SwiftUI

/// 呈現主檔清單、狀態訊息與項目操作
struct LookupItemList: View {

    // MARK: - Properties

    /// 依名稱查詢付款方式分類
    let classificationForName: (String) -> PaymentMethodFlags?

    /// 是否顯示首次載入失敗訊息
    let hasLoadFailed: Bool

    /// 目前主檔項目名稱
    let items: [String]

    /// 主檔種類
    let kind: LookupKind

    /// 刪除項目的動作
    let onDelete: (String) -> Void

    /// 編輯付款方式的動作
    let onEditPaymentMethod: (String) -> Void

    /// 重新命名項目的動作
    let onRename: (String) -> Void

    // MARK: - Body

    /// 顯示主檔清單
    var body: some View {
        List {
            if hasLoadFailed {
                loadFailureSection
            }

            itemSection
        }
    }
}

// MARK: - Private Views

private extension LookupItemList {

    /// 主檔載入失敗時顯示的訊息列
    var loadFailureSection: some View {
        Section {
            Text(LocalizedStringKey("主檔載入失敗，請稍後再試。"))
                .foregroundStyle(palette.red)
                .accessibilityIdentifier(
                    BLAccessibilityID.LookupManagement.loadFailureMessage
                )
        }
    }

    /// 主檔項目、筆數標題與付款方式說明
    var itemSection: some View {
        Section {
            if items.isEmpty {
                ContentUnavailableView(
                    LocalizedStringKey(kind.emptyTitle),
                    systemImage: "tray",
                    description: Text(LocalizedStringKey(kind.emptyDescription))
                )
            } else {
                ForEach(items, id: \.self) { item in
                    LookupItemRow(
                        classification: classificationForName(item),
                        name: item
                    )
                    .accessibilityIdentifier(BLAccessibilityID.LookupManagement.row(item))
                    .contextMenu {
                        renameOrEditButton(for: item)

                        Button(role: .destructive) {
                            onDelete(item)
                        } label: {
                            Label("刪除", systemImage: "trash")
                        }
                        .accessibilityIdentifier(
                            BLAccessibilityID.LookupManagement.deleteButton(item)
                        )
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            onDelete(item)
                        } label: {
                            Label("刪除", systemImage: "trash")
                        }
                        .accessibilityIdentifier(
                            BLAccessibilityID.LookupManagement.deleteButton(item)
                        )

                        renameOrEditButton(for: item)
                            .tint(palette.orange)
                    }
                }
            }
        } header: {
            Text("目前已建立 \(items.count) 項")
        } footer: {
            if kind == .paymentMethod {
                Text(
                    """
                    「無卡」標籤代表此付款方式會在訂單編輯顯示「無卡折抵金額」與「無卡補款金額」欄位；\
                    「銀行匯款」標籤代表會顯示「對帳狀態」欄位；「貨到付款」標籤代表收款金額已含預估運費，\
                    獲利會自動扣除三種運費。需要修改名稱或分類時，對該列選「編輯」即可。
                    """
                )
                .blTextStyle(.footnote)
                .foregroundStyle(Color.blSecondaryLabel)
            }
        }
    }

    /// 建立項目的編輯或重新命名按鈕
    ///
    /// - Parameter item: 目標項目名稱
    /// - Returns: 對應的操作按鈕
    @ViewBuilder
    func renameOrEditButton(for item: String) -> some View {
        if kind == .paymentMethod {
            Button {
                onEditPaymentMethod(item)
            } label: {
                Label("編輯", systemImage: "pencil")
            }
            .accessibilityIdentifier(BLAccessibilityID.LookupManagement.editButton(item))
        } else {
            Button {
                onRename(item)
            } label: {
                Label("重新命名", systemImage: "pencil")
            }
            .accessibilityIdentifier(BLAccessibilityID.LookupManagement.renameButton(item))
        }
    }
}

// MARK: - Private Method

private extension LookupItemList {

    /// 目前畫面使用的色盤
    var palette: BLPalette {
        BLPalette()
    }
}

// MARK: - Preview

#Preview("一般主檔有資料") {
    NavigationStack {
        LookupItemList(
            classificationForName: { _ in
                nil
            },
            hasLoadFailed: false,
            items: ["服飾", "美妝", "精品"],
            kind: .category
        ) { _ in
        } onEditPaymentMethod: { _ in
        } onRename: { _ in
        }
    }
}

#Preview("付款方式含徽章與說明") {
    NavigationStack {
        LookupItemList(
            classificationForName: { name in
                switch name {
                case "無卡分期":
                    PaymentMethodFlags(
                        isCardless: true,
                        isBankTransfer: false,
                        isCashOnDelivery: false
                    )

                case "銀行匯款":
                    PaymentMethodFlags(
                        isCardless: false,
                        isBankTransfer: true,
                        isCashOnDelivery: false
                    )

                case "貨到付款":
                    PaymentMethodFlags(
                        isCardless: false,
                        isBankTransfer: false,
                        isCashOnDelivery: true
                    )

                default:
                    PaymentMethodFlags.none
                }
            },
            hasLoadFailed: false,
            items: ["信用卡", "無卡分期", "銀行匯款", "貨到付款"],
            kind: .paymentMethod
        ) { _ in
        } onEditPaymentMethod: { _ in
        } onRename: { _ in
        }
        .navigationTitle("付款方式")
    }
}
