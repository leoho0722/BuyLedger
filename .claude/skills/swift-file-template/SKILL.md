---
name: swift-file-template
description: BuyLedger 專案 Swift 檔案結構範本。建立任何新 Swift 檔案前 invoke，取得 View / 非 View 型別 / TCA Reducer 的具體 MARK 排版樣板。
---

BuyLedger Swift 檔案的格式範本。MARK 排版規則與區段順序表格見 CLAUDE.md「MARK 區段與排版」一節；本 skill 提供可直接對照的樣板。

## 檔案 header

所有新建 Swift 檔案的 header 一律使用 Xcode 預設格式：

```swift
//
//  FileName.swift
//  BuyLedger
//
//  Created by Leo Ho on yyyy/m/d.
//
```

## View 完整版

第 5～8 區段（Nested Types、ViewBuilder、Private Method、Preview）一律寫在型別主體**外**的 extension：

```swift
struct OrdersView: View {

    // MARK: - View Properties

    @Bindable var store: StoreOf<OrdersFeature>

    // MARK: - View Body

    var body: some View { ... }
}

// MARK: - Nested Types

// 視巢狀型別是否需被外部引用，決定 extension / private extension
extension OrdersView { ... }

// MARK: - ViewBuilder

private extension OrdersView {

    @ViewBuilder
    func listSection() -> some View { ... }
}

// MARK: - Private Method

private extension OrdersView { ... }

// MARK: - Preview

#Preview { ... }
```

## 非 View 型別

沿用同一順序，View 專屬段落改為語意對應名稱或在無內容時略過：

```swift
enum RootTab: String, CaseIterable, Identifiable {

    // MARK: - Cases

    case dashboard

    // MARK: - Identifiable Properties

    var id: String { rawValue }

    // MARK: - Display Properties

    var title: String { ... }
}
```

## TCA Reducer

`Dependency Properties` 排在 `Reducer Body` 之前：

```swift
@Reducer
struct OrdersFeature {

    // MARK: - State

    @ObservableState
    struct State: Equatable { ... }

    // MARK: - Action

    enum Action: Equatable { ... }

    // MARK: - Dependency Properties

    @Dependency(\.date) private var date

    // MARK: - Reducer Body

    var body: some Reducer<State, Action> { ... }
}
```
