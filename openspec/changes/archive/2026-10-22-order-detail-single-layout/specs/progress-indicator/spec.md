## MODIFIED Requirements

### Requirement: A labeled progress indicator renders its title on every render

A progress indicator that the caller gives a title SHALL draw that title, its current value text and its progress bar together on every render, including off-screen snapshot rendering performed while the full snapshot test class runs as one batch. Whether the title appears SHALL NOT depend on which other views were rendered earlier in the same process. A progress indicator without a title or current value SHALL draw only its progress bar, with no empty label row above it.

#### Scenario: Batch snapshot run draws every progress title

- **GIVEN** the full snapshot test class runs as one batch on the reference simulator
- **WHEN** a screen containing labeled progress indicators is rendered and compared with its approved baseline
- **THEN** every progress title in the rendered image matches the baseline and the comparison passes without re-running the test alone

##### Example: snapshots whose progress titles went missing in batch runs before the fix

| Snapshot test | Labeled progress indicators on screen |
| --- | --- |
| `campaignListView_依月分組_符合基準圖` | campaign rows with 到貨 and 收款 progress |
| `campaignListView_依日分組含今天與昨天_符合基準圖` | campaign rows with 到貨 and 收款 progress |
| `dashboardView_含進行中開團_顯示進行中的開團區段` | ongoing campaign rows with 到貨 and 收款 progress |
| `quoteView_非零試算輸入_顯示成本與建議售價` | cost breakdown rows, one per cost component |
| `campaignListView_依年分組_符合基準圖` | campaign rows with 到貨 and 收款 progress |

Which of these tests lost a title before the fix varied with the simulator state, while a given state reproduced the same missing title on every run; every snapshot that contains a labeled progress indicator is therefore covered by this scenario.

#### Scenario: Bar-only progress keeps a single bar

- **WHEN** a progress indicator is created with a value but without a title or current value, such as the dashboard monthly goal bar and the insights category ranking bar
- **THEN** it draws only the progress bar, and the rendered image is identical to the approved baseline

##### Example: bar-only progress indicators and the snapshots that show them

| Bar-only progress indicator | Snapshot test that renders it |
| --- | --- |
| dashboard monthly goal bar in the hero card | `dashboardView_一般儀表板資料_符合基準圖` |
| insights category ranking bar | `insightsView_一般洞察資料_符合基準圖` |
