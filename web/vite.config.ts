import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  base: '/app/',
  build: { outDir: '../wwwroot/app', emptyOutDir: true },
  plugins: [vue(), tailwindcss()],
  server: {
    port: 5173,
    proxy: {
      '/api': { target: 'https://localhost:7177', changeOrigin: true, secure: false },
      '/Upload': { target: 'https://localhost:7177', changeOrigin: true, secure: false },
    },
  },
})
