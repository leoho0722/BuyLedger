'use client';

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useState,
  type ReactNode,
} from 'react';

export type Appearance = 'system' | 'light' | 'dark';

interface ThemeContextValue {
  appearance: Appearance;
  setAppearance: (value: Appearance) => void;
}

const ThemeContext = createContext<ThemeContextValue>({
  appearance: 'system',
  setAppearance: () => undefined,
});

const STORAGE_KEY = 'bl-appearance';

// 依外觀偏好套用 html.dark (system 跟隨 prefers-color-scheme)。
function applyAppearance(value: Appearance): void {
  const dark =
    value === 'dark' ||
    (value === 'system' && window.matchMedia('(prefers-color-scheme: dark)').matches);
  document.documentElement.classList.toggle('dark', dark);
}

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [appearance, setAppearanceState] = useState<Appearance>('system');

  useEffect(() => {
    const saved = window.localStorage.getItem(STORAGE_KEY) as Appearance | null;
    if (saved === 'light' || saved === 'dark' || saved === 'system') {
      setAppearanceState(saved);
    }
  }, []);

  useEffect(() => {
    applyAppearance(appearance);
    if (appearance !== 'system') return;
    const mq = window.matchMedia('(prefers-color-scheme: dark)');
    const handler = () => applyAppearance('system');
    mq.addEventListener('change', handler);
    return () => mq.removeEventListener('change', handler);
  }, [appearance]);

  const setAppearance = useCallback((value: Appearance) => {
    window.localStorage.setItem(STORAGE_KEY, value);
    setAppearanceState(value);
  }, []);

  return (
    <ThemeContext.Provider value={{ appearance, setAppearance }}>{children}</ThemeContext.Provider>
  );
}

export function useTheme(): ThemeContextValue {
  return useContext(ThemeContext);
}
