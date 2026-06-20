'use client';

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api, CampaignInputBody, OrderInputBody } from './api';
import type { Campaign, PaymentMethodDTO, SettingsDTO } from './types';

// Query keys。
export const qk = {
  orders: ['orders'] as const,
  order: (id: string) => ['orders', id] as const,
  campaigns: ['campaigns'] as const,
  campaign: (id: string) => ['campaigns', id] as const,
  categories: ['lookups', 'categories'] as const,
  orderSources: ['lookups', 'order-sources'] as const,
  verificationStatuses: ['lookups', 'verification-statuses'] as const,
  paymentMethods: ['lookups', 'payment-methods'] as const,
  currencyCodes: ['currency', 'codes'] as const,
  fxLatest: ['fx', 'latest'] as const,
  settings: ['settings'] as const,
};

// MARK: - Queries

export function useOrders() {
  return useQuery({ queryKey: qk.orders, queryFn: api.orders.list });
}

export function useOrder(id: string) {
  return useQuery({ queryKey: qk.order(id), queryFn: () => api.orders.get(id), enabled: !!id });
}

export function useCampaigns() {
  return useQuery({ queryKey: qk.campaigns, queryFn: api.campaigns.list });
}

export function useCampaign(id: string) {
  return useQuery({ queryKey: qk.campaign(id), queryFn: () => api.campaigns.get(id), enabled: !!id });
}

export function useCategories() {
  return useQuery({ queryKey: qk.categories, queryFn: api.lookups.categories.list });
}

export function useOrderSources() {
  return useQuery({ queryKey: qk.orderSources, queryFn: api.lookups.orderSources.list });
}

export function useVerificationStatuses() {
  return useQuery({ queryKey: qk.verificationStatuses, queryFn: api.lookups.verificationStatuses.list });
}

export function usePaymentMethods() {
  return useQuery({ queryKey: qk.paymentMethods, queryFn: api.lookups.paymentMethods.list });
}

export function useCurrencyCodes() {
  return useQuery({ queryKey: qk.currencyCodes, queryFn: api.currency.codes });
}

export function useFxLatest() {
  return useQuery({ queryKey: qk.fxLatest, queryFn: api.fx.latest });
}

export function useSettings() {
  return useQuery({ queryKey: qk.settings, queryFn: api.settings.get });
}

// MARK: - Mutations

// 訂單異動會連動開團統計，故同時失效 orders + campaigns。
function useInvalidateOrders() {
  const qc = useQueryClient();
  return () => {
    void qc.invalidateQueries({ queryKey: qk.orders });
    void qc.invalidateQueries({ queryKey: qk.campaigns });
  };
}

export function useOrderMutations() {
  const invalidate = useInvalidateOrders();
  const create = useMutation({
    mutationFn: (body: OrderInputBody) => api.orders.create(body),
    onSuccess: invalidate,
  });
  const update = useMutation({
    mutationFn: ({ id, body }: { id: string; body: OrderInputBody }) => api.orders.update(id, body),
    onSuccess: invalidate,
  });
  const remove = useMutation({
    mutationFn: (id: string) => api.orders.remove(id),
    onSuccess: invalidate,
  });
  const setStatus = useMutation({
    mutationFn: ({ id, status }: { id: string; status: Parameters<typeof api.orders.setStatus>[1] }) =>
      api.orders.setStatus(id, status),
    onSuccess: invalidate,
  });
  // 批次更改狀態：多選訂單套用同一目標狀態，成功後沿用 orders + campaigns 失效。
  const batchSetStatus = useMutation({
    mutationFn: ({ ids, status }: { ids: string[]; status: Parameters<typeof api.orders.batchSetStatus>[1] }) =>
      api.orders.batchSetStatus(ids, status),
    onSuccess: invalidate,
  });
  const setReceipt = useMutation({
    mutationFn: ({ id, status }: { id: string; status: Parameters<typeof api.orders.setReceipt>[1] }) =>
      api.orders.setReceipt(id, status),
    onSuccess: invalidate,
  });
  return { create, update, remove, setStatus, batchSetStatus, setReceipt };
}

export function useCampaignMutations() {
  const qc = useQueryClient();
  const invalidate = () => void qc.invalidateQueries({ queryKey: qk.campaigns });
  const create = useMutation({
    mutationFn: (body: CampaignInputBody) => api.campaigns.create(body),
    onSuccess: invalidate,
  });
  const update = useMutation({
    mutationFn: ({ id, body }: { id: string; body: CampaignInputBody }) => api.campaigns.update(id, body),
    onSuccess: () => {
      invalidate();
      void qc.invalidateQueries({ queryKey: qk.orders });
    },
  });
  const remove = useMutation({
    mutationFn: (id: string) => api.campaigns.remove(id),
    onSuccess: invalidate,
  });
  const settle = useMutation({
    mutationFn: (id: string) => api.campaigns.settle(id),
    onSuccess: invalidate,
  });
  const setStatus = useMutation({
    mutationFn: ({ id, status }: { id: string; status: Campaign['status'] }) =>
      api.campaigns.setStatus(id, status),
    onSuccess: invalidate,
  });
  return { create, update, remove, settle, setStatus };
}

export function useSettingsMutation() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (body: Partial<SettingsDTO>) => api.settings.update(body),
    onSuccess: () => void qc.invalidateQueries({ queryKey: qk.settings }),
  });
}

export function useFxRefresh() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: () => api.fx.refresh(),
    onSuccess: () => void qc.invalidateQueries({ queryKey: qk.fxLatest }),
  });
}
