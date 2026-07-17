import { describe, expect, it, vi } from 'vitest'
import { normalizedScrollPosition, restoreScrollPosition } from './scroll-position'

describe('document scroll positions', () => {
  it('starts new and invalid positions at the top', () => {
    expect(normalizedScrollPosition(undefined)).toBe(0)
    expect(normalizedScrollPosition(-20)).toBe(0)
    expect(normalizedScrollPosition(Number.NaN)).toBe(0)
  })

  it('restores a saved position after rendering', () => {
    const scrollTo = vi.fn()
    const requestFrame = callback => callback()

    expect(restoreScrollPosition(480, requestFrame, scrollTo)).toBe(480)
    expect(scrollTo).toHaveBeenCalledWith(0, 480)
  })
})
