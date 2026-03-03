import { defineConfig } from 'vite';
import MdItAdmon from 'markdown-it-admon';

export default defineConfig({
  server: {
    // make the dev server listen on all network interfaces
    host: true,              // or '0.0.0.0'
    // all hosts are allowed
    allowedHosts: true,
    fs: { strict: false },
    hmr: {
      overlay: false,
    },
    watch: {
      // Disable symlink traversal so chokidar reports canonical paths.
      // The `slides -> ..` symlink causes chokidar to report changes as
      // e.g. /repo/slidev-template/slides/pages/file.md, but Slidev's
      // HMR watchFiles map uses the canonical /repo/pages/file.md.
      // This mismatch silently breaks HMR for src:-included external files.
      followSymlinks: false,
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
    vue: {
      /* vue options */
    },
    markdown: {
      /* markdown-it options */
      markdownItSetup(md) {
        /* custom markdown-it plugins */
        md.use(MdItAdmon);
      },
    },
  },
});

