'use client';

import { useQueryClient } from '@tanstack/react-query';
import { collection, onSnapshot } from 'firebase/firestore';
import { useEffect } from 'react';

import { useAuth } from '../auth';
import { getFirestoreDb } from '../firebase';
import { qk } from '../queries';
import type { Campaign, OrderDTO } from '../types';
import { observeClock } from './hlc';

// Firestore 即時投影消費端 (對齊 cross-device-sync「Web subscribes to the per-user
// projection in real time」)：登入後訂閱 users/{uid}/orders|campaigns 快照，餵入既有
// TanStack Query cache，使另一裝置經後端鏡像的變更即時出現、無需手動刷新。寫入仍走後端 API
// 後端為唯一寫入方；web 僅讀取。觀察到的每欄位 HLC 一併推進本地時鐘 (RECEIVE)，
// 確保後續本地寫入的時鐘必大於已見的遠端時鐘
export function FirestoreSync() {
  const { user } = useAuth();
  const qc = useQueryClient();
  const uid = user?.uid;

  // 登入 (uid 變動) 後建立兩條快照訂閱，uid 消失或卸載時解除；qc 為穩定參考
  useEffect(() => {
    if (!uid) return;
    const db = getFirestoreDb();

    // 將文件帶的每欄位 HLC 餵給本地時鐘 (RECEIVE)
    const ingestClocks = (data: Record<string, unknown>): void => {
      const clocks = data._fieldClocks as Record<string, string> | undefined;
      if (clocks) {
        for (const enc of Object.values(clocks)) observeClock(enc);
      }
    };

    // 訂閱 per-user 訂單投影，每次快照重建整份清單並覆寫 orders cache
    const unsubOrders = onSnapshot(collection(db, 'users', uid, 'orders'), (snap) => {
      const orders: OrderDTO[] = [];
      for (const d of snap.docs) {
        const data = d.data();
        ingestClocks(data);
        if (data._deleted) continue; // tombstone 不顯示
        orders.push(data as OrderDTO);
      }
      // 對齊 REST list 的排序 (date 由新到舊)
      orders.sort((a, b) => (a.date < b.date ? 1 : a.date > b.date ? -1 : 0));
      qc.setQueryData(qk.orders, orders);
    });

    // 訂閱 per-user 開團投影 (同訂單流程：忽略 tombstone、覆寫 campaigns cache)
    const unsubCampaigns = onSnapshot(collection(db, 'users', uid, 'campaigns'), (snap) => {
      const campaigns: Campaign[] = [];
      for (const d of snap.docs) {
        const data = d.data();
        ingestClocks(data);
        if (data._deleted) continue;
        campaigns.push(data as Campaign);
      }
      qc.setQueryData(qk.campaigns, campaigns);
    });

    // 清理：解除兩條訂閱，避免登出或重訂閱後仍寫入舊 uid 的資料
    return () => {
      unsubOrders();
      unsubCampaigns();
    };
  }, [uid, qc]);

  return null;
}
