//
//  LookupCatalogTests.swift
//  BuyLedgerTests
//
//  Created by Leo Ho on 2026/8/1.
//

import Testing
@testable import BuyLedger

/// 驗證主檔目錄的共享狀態
struct LookupCatalogTests {
    
    // MARK: - Tests (Order Source / Category / Reconciliation Status)
    
    @Test(arguments: [LookupKind.orderSource, .category, .reconciliationStatus])
    func addingNameOnlyKindInsertsSorted(kind: LookupKind) {
        var catalog = LookupCatalog()
        catalog.add(name: "香蕉", kind: kind)
        catalog.add(name: "蘋果", kind: kind)
        
        // zh-Hant 排序應將「香蕉」放在前面。
        #expect(catalog.names(for: kind) == ["香蕉", "蘋果"])
    }
    
    @Test(arguments: [LookupKind.orderSource, .category, .reconciliationStatus])
    func addingBlankNameIsNoOp(kind: LookupKind) {
        var catalog = LookupCatalog()
        catalog.add(name: "   ", kind: kind)
        
        #expect(catalog.names(for: kind).isEmpty)
    }
    
    @Test(arguments: [LookupKind.orderSource, .category, .reconciliationStatus])
    func removingNameOnlyKindDeletesEntry(kind: LookupKind) {
        var catalog = LookupCatalog()
        catalog.add(name: "既有", kind: kind)
        
        catalog.remove(name: "既有", kind: kind)
        
        #expect(catalog.names(for: kind).isEmpty)
    }
    
    @Test(arguments: [LookupKind.orderSource, .category, .reconciliationStatus])
    func renamingNameOnlyKindReplacesOldName(kind: LookupKind) {
        var catalog = LookupCatalog()
        catalog.add(name: "舊名", kind: kind)
        
        catalog.rename(from: "舊名", to: "新名", kind: kind)
        
        #expect(catalog.names(for: kind) == ["新名"])
    }
    
    // MARK: - Tests (Payment Method)
    
    @Test func addingPaymentMethodStoresFlags() {
        var catalog = LookupCatalog()
        catalog.add(
            name: "無卡存款", kind: .paymentMethod, isCardless: true, isBankTransfer: false,
            isCashOnDelivery: false)
        
        #expect(
            catalog.paymentMethods == [
                PaymentMethodInfo(
                    name: "無卡存款", isCardless: true, isBankTransfer: false, isCashOnDelivery: false)
            ])
    }
    
    @Test func addingPaymentMethodSameNameOverwritesFlags() {
        var catalog = LookupCatalog()
        catalog.add(
            name: "綠界", kind: .paymentMethod, isCardless: false, isBankTransfer: false,
            isCashOnDelivery: false)
        catalog.add(
            name: "綠界", kind: .paymentMethod, isCardless: false, isBankTransfer: true,
            isCashOnDelivery: false)
        
        #expect(catalog.paymentMethods.count == 1)
        #expect(catalog.paymentMethods.first?.isBankTransfer == true)
    }
    
    @Test func removingPaymentMethodDeletesEntry() {
        var catalog = LookupCatalog()
        catalog.add(
            name: "貨到付款", kind: .paymentMethod, isCardless: false, isBankTransfer: false,
            isCashOnDelivery: true)
        
        catalog.remove(name: "貨到付款", kind: .paymentMethod)
        
        #expect(catalog.paymentMethods.isEmpty)
    }
    
    @Test func renamingPaymentMethodMergesFlagsWhenEitherSideIsTrue() {
        var catalog = LookupCatalog()
        catalog.add(
            name: "匯款", kind: .paymentMethod, isCardless: false, isBankTransfer: true,
            isCashOnDelivery: false)
        
        catalog.rename(from: "匯款", to: "銀行匯款", kind: .paymentMethod)
        
        #expect(catalog.names(for: .paymentMethod) == ["銀行匯款"])
        #expect(catalog.paymentMethods.first?.isBankTransfer == true)
    }
    
    // MARK: - Tests (Shared Early-Exit Semantics)
    
    @Test func renamingToBlankNameIsNoOp() {
        var catalog = LookupCatalog()
        catalog.add(name: "舊名", kind: .category)
        
        catalog.rename(from: "舊名", to: "   ", kind: .category)
        
        #expect(catalog.names(for: .category) == ["舊名"])
    }
    
    @Test func renamingToSameNameIsNoOp() {
        var catalog = LookupCatalog()
        catalog.add(name: "同名", kind: .category)
        
        catalog.rename(from: "同名", to: "同名", kind: .category)
        
        #expect(catalog.names(for: .category) == ["同名"])
    }
}
