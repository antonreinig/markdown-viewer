import { defineConfig } from 'vite'
import { resolve } from 'node:path'

export default defineConfig({
  base: './',
  plugins: [{
    name: 'macos-local-script',
    transformIndexHtml(html) {
      return html
        .replace('type="module" crossorigin', 'defer')
        .replace('rel="stylesheet" crossorigin', 'rel="stylesheet"')
    },
  }],
  build: {
    outDir: resolve(import.meta.dirname, '../BundledEditor'),
    emptyOutDir: true,
    sourcemap: false,
    target: 'safari17',
  },
})
