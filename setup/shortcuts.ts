import type { NavOperations, ShortcutOptions } from '@slidev/types'
import { defineShortcutsSetup } from '@slidev/types'

export default defineShortcutsSetup((nav: NavOperations, base: ShortcutOptions[]) => {
  // Add vim-style navigation shortcuts
  const vimShortcuts: ShortcutOptions[] = [
    // h - previous slide (like left arrow)
    {
      name: 'vim_prev_h',
      key: 'h',
      fn: nav.prev,
      autoRepeat: true
    },
    // l - next slide (like right arrow)
    {
      name: 'vim_next_l',
      key: 'l',
      fn: nav.next,
      autoRepeat: true
    },
    // k - previous slide vertically (like up arrow)
    {
      name: 'vim_prev_k',
      key: 'k',
      fn: nav.prevSlide,
      autoRepeat: true
    },
    // j - next slide vertically (like down arrow)
    {
      name: 'vim_next_j',
      key: 'j',
      fn: nav.nextSlide,
      autoRepeat: true
    },
  ]

  // Return both base shortcuts and our vim shortcuts
  return [...base, ...vimShortcuts]
})
