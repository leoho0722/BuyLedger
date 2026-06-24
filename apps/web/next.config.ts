import type { NextConfig } from 'next';

// standalone 輸出供容器精簡部署；API base 由環境變數提供 (預設本機後端)
const nextConfig: NextConfig = {
  output: 'standalone',
  env: {
    NEXT_PUBLIC_API_BASE_URL:
      process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:4000/api',
  },
};

export default nextConfig;
