/**
 * Broken fixture: HMR disabled.
 *
 * This vite.config.ts is identical to the real one except hmr is set to false,
 * which prevents Vite from pushing file changes to the browser via WebSocket.
 * The HMR test should FAIL when this config is used.
 */
import { defineConfig } from 'vite';
import MdItAdmon from 'markdown-it-admon';

export default defineConfig({
  server: {
    host: true,
    allowedHosts: true,
    fs: { strict: false },
    hmr: false,
    watch: {
      ignored: ['**/slides/tools/**', '**/slides/slidev-template/**'],
    },
  },
  build: {
    chunkSizeWarningLimit: 1000,
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (id.includes('node_modules')) {
            return 'vendor';
          }
        }
      }
    }
  },
  optimizeDeps: {
    exclude: ['@slidev/cli'],
  },
  slidev: {
    vue: {},
    markdown: {
      markdownItSetup(md) {
        md.use(MdItAdmon);
      },
    },
  },
});
