'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useState, type ReactNode } from 'react';
import { ThemeProvider } from './theme';
import { AuthGate, AuthProvider } from './auth';
import { FirestoreSync } from './sync/useFirestoreSync';
import { SyncStatusBadge } from './sync/SyncStatusBadge';

export function Providers({ children }: { children: ReactNode }) {
  const [client] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: { staleTime: 30_000, refetchOnWindowFocus: false, retry: 1 },
        },
      }),
  );

  return (
    <QueryClientProvider client={client}>
      <ThemeProvider>
        <AuthProvider>
          <FirestoreSync />
          <SyncStatusBadge />
          <AuthGate>{children}</AuthGate>
        </AuthProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
}
