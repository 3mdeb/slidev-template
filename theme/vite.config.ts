import type { UserConfig } from 'vite'
import path from 'path'

const config: UserConfig = {
  publicDir: path.resolve(__dirname, '../public'),
  server: {
    headers: {
      'Cross-Origin-Opener-Policy': 'same-origin',
      'Cross-Origin-Embedder-Policy': 'require-corp',
    },
  },
}

export default config

