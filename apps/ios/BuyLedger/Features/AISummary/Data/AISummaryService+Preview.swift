//
//  AISummaryService+Preview.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/9/27.
//

#if DEBUG

// MARK: - DependencyKey

extension AISummaryService {

    /// Preview 使用固定的 Markdown 摘要與 API 金鑰
    static var previewValue: Self {
        assert(
            RuntimeEnvironment.allowsPreviewStub,
            "AISummaryService.previewValue 只能在 Preview、UI Test 或單元測試中使用"
        )
        return Self(
            streamSummary: { _, _, _ in
                AsyncThrowingStream<String, any Error> { continuation in
                    let chunks = [
                        "## 商品明細總結\n\n",
                        "本批訂單共涵蓋多個品項，以下為重點觀察：\n\n",
                        "- **熱門品項**：藍牙耳機 x3、保溫瓶 x2\n",
                        "- **類別分佈**：以 3C 配件為主\n",
                        "- **金額區間**：單價集中在 NT$300–1,200\n",
                    ]
                    for chunk in chunks {
                        continuation.yield(chunk)
                    }
                    continuation.finish()
                }
            },
            apiKey: { "preview-stub-key" }
        )
    }
}

#endif
