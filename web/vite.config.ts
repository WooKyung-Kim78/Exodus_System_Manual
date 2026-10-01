import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig(({ command }) => ({
  // 개발 서버에서는 기존 SPA URL(/manual 등)을 그대로 제공한다.
  // 게시 산출물만 wwwroot/app 아래에 놓이므로 그때만 /app/ base가 필요하다.
  base: command === 'serve' ? '/' : '/app/',
  build: { outDir: '../wwwroot/app', emptyOutDir: true },
  plugins: [vue(), tailwindcss()],
  server: {
    port: 5173,
    proxy: {
      '/api': { target: 'http://localhost:7176', changeOrigin: true },
      '/Upload': { target: 'http://localhost:7176', changeOrigin: true },
    },
  },
}))
