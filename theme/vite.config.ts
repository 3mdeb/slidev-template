import { defineConfig } from 'vite'
import path from 'path'

export default defineConfig({
  publicDir: path.resolve(__dirname, '../public'),
  server: {
    headers: {
      'Cross-Origin-Opener-Policy': 'same-origin',
      'Cross-Origin-Embedder-Policy': 'require-corp',
    }
  }
})
