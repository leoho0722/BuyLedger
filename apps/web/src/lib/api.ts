import type {
  Campaign,
  FxSnapshotDTO,
  MergeDraftResponse,
  OrderDTO,
  OrderStatus,
  PaymentMethodDTO,
  PaymentReceiptStatus,
  SettingsDTO,
} from './types';
import { getCurrentIdToken } from './firebase';

const BASE = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000/api';

// API 收到 401 時呼叫的處理器 (由 AuthProvider 註冊：登出後 AuthGate 導回登入)。
let onUnauthorized: (() => void) | null = null;
export function setUnauthorizedHandler(handler: () => void): void {
  onUnauthorized = handler;
}

export class ApiError extends Error {
  constructor(
    public status: number,
    public code: string | undefined,
    message: string,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const token = await getCurrentIdToken();
  const res = await fetch(`${BASE}${path}`, {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(init?.headers ?? {}),
    },
  });
  if (res.status === 401) onUnauthorized?.();
  if (!res.ok) {
    let code: string | undefined;
    let message = `請求失敗 (${res.status})`;
    try {
      const body = await res.json();
      code = body.error ?? body.code;
      message = body.message ?? body.error ?? message;
    } catch {
      /* 無 JSON body */
    }
    throw new ApiError(res.status, code, message);
  }
  if (res.status === 204) return undefined as T;
  return (await res.json()) as T;
}

// 訂單草稿輸入 (前端送出形狀；decimal 欄位皆字串)。
export interface OrderInputBody {
  id?: string;
  customer?: { name?: string; initials?: string; tier?: OrderDTO['customer']['tier'] };
  status?: OrderStatus;
  currency?: string;
  date?: string;
  items?: Array<{ id?: string; name?: string; quantity?: number; unitPrice?: string }>;
  itemCost?: string;
  domesticShipping?: string;
  internationalShipping?: string;
  foreignDomesticShipping?: string;
  cardFeeRate?: string;
  platformFeeRate?: string;
  paymentFeeRate?: string;
  chargedAmount?: string;
  cardlessDeductionAmount?: string;
  cardlessSupplementAmount?: string;
  orderSource?: string;
  categories?: string[];
  paymentMethod?: string;
  notes?: string;
  verificationStatus?: string;
  campaignNames?: string[];
  paymentReceiptStatus?: PaymentReceiptStatus;
  photos?: string[];
  mergedSourceIDs?: string[];
}

export interface CampaignInputBody {
  name?: string;
  openDate?: string;
  closeDate?: string | null;
  notes?: string;
}

export const api = {
  orders: {
    list: () => request<OrderDTO[]>('/orders'),
    get: (id: string) => request<OrderDTO>(`/orders/${encodeURIComponent(id)}`),
    create: (body: OrderInputBody) =>
      request<OrderDTO>('/orders', { method: 'POST', body: JSON.stringify(body) }),
    update: (id: string, body: OrderInputBody) =>
      request<OrderDTO>(`/orders/${encodeURIComponent(id)}`, {
        method: 'PUT',
        body: JSON.stringify(body),
      }),
    remove: (id: string) =>
      request<void>(`/orders/${encodeURIComponent(id)}`, { method: 'DELETE' }),
    setStatus: (id: string, status: OrderStatus) =>
      request<OrderDTO>(`/orders/${encodeURIComponent(id)}/status`, {
        method: 'POST',
        body: JSON.stringify({ status }),
      }),
    batchSetStatus: (ids: string[], status: OrderStatus) =>
      request<OrderDTO[]>('/orders/status/batch', {
        method: 'POST',
        body: JSON.stringify({ ids, status }),
      }),
    setReceipt: (id: string, status: PaymentReceiptStatus) =>
      request<OrderDTO>(`/orders/${encodeURIComponent(id)}/receipt`, {
        method: 'POST',
        body: JSON.stringify({ status }),
      }),
    mergeDraft: (primaryId: string, secondaryId: string) =>
      request<MergeDraftResponse>('/orders/merge/draft', {
        method: 'POST',
        body: JSON.stringify({ primaryId, secondaryId }),
      }),
  },
  campaigns: {
    list: () => request<Campaign[]>('/campaigns'),
    get: (id: string) => request<Campaign>(`/campaigns/${encodeURIComponent(id)}`),
    create: (body: CampaignInputBody) =>
      request<Campaign>('/campaigns', { method: 'POST', body: JSON.stringify(body) }),
    update: (id: string, body: CampaignInputBody) =>
      request<Campaign>(`/campaigns/${encodeURIComponent(id)}`, {
        method: 'PUT',
        body: JSON.stringify(body),
      }),
    remove: (id: string) =>
      request<void>(`/campaigns/${encodeURIComponent(id)}`, { method: 'DELETE' }),
    settle: (id: string) =>
      request<Campaign>(`/campaigns/${encodeURIComponent(id)}/settle`, { method: 'POST' }),
    setStatus: (id: string, status: Campaign['status']) =>
      request<Campaign>(`/campaigns/${encodeURIComponent(id)}/status`, {
        method: 'POST',
        body: JSON.stringify({ status }),
      }),
  },
  lookups: {
    categories: lookupEndpoints('categories'),
    orderSources: lookupEndpoints('order-sources'),
    verificationStatuses: lookupEndpoints('verification-statuses'),
    paymentMethods: {
      list: () => request<PaymentMethodDTO[]>('/lookups/payment-methods'),
      add: (body: Partial<PaymentMethodDTO>) =>
        request<PaymentMethodDTO[]>('/lookups/payment-methods', {
          method: 'POST',
          body: JSON.stringify(body),
        }),
      update: (name: string, body: Partial<PaymentMethodDTO>) =>
        request<PaymentMethodDTO[]>(`/lookups/payment-methods/${encodeURIComponent(name)}`, {
          method: 'PUT',
          body: JSON.stringify(body),
        }),
      remove: (name: string) =>
        request<PaymentMethodDTO[]>(`/lookups/payment-methods/${encodeURIComponent(name)}`, {
          method: 'DELETE',
        }),
    },
  },
  currency: {
    codes: () => request<string[]>('/currency/codes'),
    refreshCodes: () => request<string[]>('/currency/codes/refresh', { method: 'POST' }),
  },
  fx: {
    latest: () => request<FxSnapshotDTO | null>('/fx/latest'),
    refresh: () => request<FxSnapshotDTO | null>('/fx/refresh', { method: 'POST' }),
  },
  settings: {
    get: () => request<SettingsDTO>('/settings'),
    update: (body: Partial<SettingsDTO>) =>
      request<SettingsDTO>('/settings', { method: 'PUT', body: JSON.stringify(body) }),
  },
  aiSummary: {
    // 串流總結：逐塊回呼，回傳 Promise 於串流結束 resolve。
    stream: async (
      orderIds: string[],
      selectedCategory: string | null,
      onChunk: (text: string) => void,
      signal?: AbortSignal,
    ): Promise<void> => {
      const token = await getCurrentIdToken();
      const res = await fetch(`${BASE}/ai-summary/stream`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
        body: JSON.stringify({ orderIds, selectedCategory }),
        signal,
      });
      if (res.status === 401) onUnauthorized?.();
      if (!res.ok || !res.body) {
        let code: string | undefined;
        let message = `AI 總結失敗 (${res.status})`;
        try {
          const body = await res.json();
          code = body.error;
          message = body.message ?? message;
        } catch {
          /* ignore */
        }
        throw new ApiError(res.status, code, message);
      }
      const reader = res.body.getReader();
      const decoder = new TextDecoder();
      for (;;) {
        const { done, value } = await reader.read();
        if (done) break;
        onChunk(decoder.decode(value, { stream: true }));
      }
    },
  },
};

function lookupEndpoints(segment: string) {
  return {
    list: () => request<string[]>(`/lookups/${segment}`),
    add: (name: string) =>
      request<string[]>(`/lookups/${segment}`, { method: 'POST', body: JSON.stringify({ name }) }),
    rename: (oldName: string, newName: string) =>
      request<string[]>(`/lookups/${segment}/${encodeURIComponent(oldName)}`, {
        method: 'PUT',
        body: JSON.stringify({ name: newName }),
      }),
    remove: (name: string) =>
      request<string[]>(`/lookups/${segment}/${encodeURIComponent(name)}`, { method: 'DELETE' }),
  };
}
