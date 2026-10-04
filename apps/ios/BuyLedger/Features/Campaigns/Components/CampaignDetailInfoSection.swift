//
//  CampaignDetailInfoSection.swift
//  BuyLedger
//
//  Created by Leo Ho on 2026/10/2.
//

import SwiftUI

/// 開團詳情的資訊區段：團名、狀態、日期、訂購提醒與備註
struct CampaignDetailInfoSection: View {

    // MARK: - Properties

    /// App 根層依語言偏好注入的 locale
    @Environment(\.locale) private var locale

    /// 目前的開團
    let campaign: Campaign

    /// 此開團連結的提醒事件與時間；沒有提醒時為 `nil`
    let reminderLink: CampaignReminderLink?

    // MARK: - Body

    /// 依序呈現團名、狀態、日期、訂購提醒與備註
    var body: some View {
        Section("開團資訊") {
            campaignName

            statusRow

            dateRows

            reminderRow

            notes
        }
    }
}

// MARK: - Private Views

private extension CampaignDetailInfoSection {

    /// 可隨內容換行的團名
    var campaignName: some View {
        Text(campaign.name)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(BLTypographyStyle.body.font.weight(.semibold))
    }

    /// 開團狀態與已結團標記
    var statusRow: some View {
        LabeledContent("狀態") {
            HStack(spacing: BLSpacing.extraSmall) {
                BLStatusPill(
                    campaign.status.title,
                    tone: CampaignStatusStyle.tone(for: campaign.status)
                )

                if campaign.isSettled {
                    BLStatusPill("已結團", tone: .neutral, showsIndicator: false)
                        .accessibilityIdentifier(BLAccessibilityID.Campaigns.detailSettledBadge)
                }
            }
        }
    }

    /// 開團日期及有值時顯示的結單、結團日期
    @ViewBuilder
    var dateRows: some View {
        LabeledContent(
            "開團日期",
            value: CampaignFormatters.shortDate(campaign.openDate, locale: locale)
        )

        if let closeDate = campaign.closeDate {
            LabeledContent("結單日期", value: CampaignFormatters.shortDate(closeDate, locale: locale))
        }

        if let settledDate = campaign.settledDate {
            LabeledContent("結團日期", value: CampaignFormatters.shortDate(settledDate, locale: locale))
        }
    }

    /// 有提醒時顯示日期與時間
    @ViewBuilder
    var reminderRow: some View {
        if let reminderLink {
            LabeledContent(
                "訂購提醒",
                value: CampaignFormatters.reminderTimestamp(
                    reminderLink.reminderTimestamp,
                    locale: locale
                )
            )
        }
    }

    /// 有備註時呈現次要色文字
    @ViewBuilder
    var notes: some View {
        if !campaign.notes.isEmpty {
            Text(campaign.notes)
                .blTextStyle(.subhead)
                .foregroundStyle(Color.blSecondaryLabel)
        }
    }
}

// MARK: - Preview

#Preview("開團資訊") {
    List {
        CampaignDetailInfoSection(campaign: Campaign.sampleCampaigns[0], reminderLink: nil)
    }
}
