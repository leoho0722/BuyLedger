"""比對 snapshot 失敗時實際畫出的圖是否與已登記的替代格式之一逐像素相同

用法：
    python3 openspec/changes/order-edit-style-compliance/reference/check_snapshot_alternates.py <模擬器 UDID>

系統 compact DatePicker 的日期膠囊會隨真實時間在數字格式與年月日格式之間切換，注入時間控制不到
(使用者 2026-10-08 裁決：兩種格式都算通過)。本腳本找出該模擬器最近一次 snapshot 測試輸出的實際圖，
與 snapshot-alternates/ 內同名的各格式圖 (`<測試名>.<格式>.png`，如 numeric、longform、longformwrap) 比對，印出結果；需要 Pillow。
"""
import glob
import os
import sys

from PIL import Image, ImageChops

HERE = os.path.dirname(os.path.abspath(__file__))
ALTERNATES = os.path.join(HERE, 'snapshot-alternates')
NAMES = [
    ('SnapshotTests+OrderEdit', 'orderEditView_合併訂單情境_符合基準圖'),
    ('SnapshotTests+OrderEdit', 'orderEditView_一般既有訂單_符合基準圖'),
    ('SnapshotTests+OrderEdit', 'orderEditView_長訂單識別碼_顯示短識別碼'),
    ('SnapshotTests+CampaignDetail', 'campaignEditView_編輯既有開團_符合基準圖'),
]


def latest_render(udid, folder, name):
    pattern = os.path.expanduser(
        f'~/Library/Developer/CoreSimulator/Devices/{udid}/data/Containers/Data/Application/'
        f'*/tmp/{folder}/{name}.1.png'
    )
    paths = sorted(glob.glob(pattern), key=os.path.getmtime)
    return paths[-1] if paths else None


def main():
    udid = sys.argv[1]
    for folder, name in NAMES:
        render = latest_render(udid, folder, name)
        if render is None:
            print(f'{name}: 沒有失敗輸出 (代表比對通過或未執行)')
            continue
        actual = Image.open(render).convert('RGB')
        matched = []
        for path in sorted(glob.glob(os.path.join(ALTERNATES, f'{name}.*.png'))):
            variant = os.path.basename(path)[len(name) + 1:-len('.png')]
            reference = Image.open(path).convert('RGB')
            if reference.size == actual.size and ImageChops.difference(reference, actual).getbbox() is None:
                matched.append(variant)
        status = '符合 ' + '、'.join(matched) if matched else '不符合任何已登記格式'
        print(f'{name}: {status} ({render}，修改時間 {os.path.getmtime(render):.0f})')


if __name__ == '__main__':
    main()
