> 註：本 change 的程式碼實作已於提案前完成；apply 階段以對照既有程式碼驗證行為為主，逐項勾選。

## 1. 開團選單篩選與多入口自載

- [x] 1.1 [P] 落實需求 `The order editor selects from existing campaigns only` 的狀態篩選：在 `OrdersFeature.State` 新增 `ongoingCampaigns` computed property，只回傳 `status == .ongoing` 的開團名稱 (去重、依 `localizedStandardCompare` 排序)，並讓 `editOrderTapped` 與 `newOrderTapped` 傳入它作為 `OrderEditFeature.State` 的初始 `availableCampaigns`，使 Orders 分頁入口第一幀即不含已收單開團。驗證：iOS `build_run_device` 成功編譯啟動；Orders 分頁新增／編輯的開團下拉首幀不出現 closed 開團。
- [x] 1.2 [P] 在 `OrderEditFeature` 新增 `@Dependency(CampaignRepository.self)`，於 `.task` 以 `campaignsTask` 呼叫 `fetchCampaigns` 自載開團，並新增 `availableCampaignsLoaded([Campaign])` handler：只取 `status == .ongoing` 的名稱、union 現有 `draftCampaignNames` 後排序寫回 `availableCampaigns`，使所有入口 (Orders 分頁、Dashboard 新增、冷啟動直衝) 一致顯示未歸團+開團中。驗證：`build_run_device` 啟動成功；`OrderEditFeatureTests` 未送 `.task`，exhaustive `TestStore` 不受新 effect 影響。

## 2. 既有歸屬保留

- [x] 2.1 確認編輯已歸屬到 closed 開團的訂單時，該開團仍是可見可選項 (靠 `OrderEditFeature.init` 既有保留邏輯與 handler 的 `draftCampaignNames` union 雙重保障)；合併多選 sheet 同樣保留由來源訂單帶入的既有開團。驗證：手機上開一筆歸屬 closed 開團的訂單，開團下拉仍含該開團；空選仍顯示「未歸團」。
