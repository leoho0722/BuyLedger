'use client';

import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useState, type ReactNode } from 'react';
import { ThemeProvider } from './theme';
import { AuthGate, AuthProvider } from './auth';

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
          <AuthGate>{children}</AuthGate>
        </AuthProvider>
      </ThemeProvider>
    </QueryClientProvider>
  );
}
