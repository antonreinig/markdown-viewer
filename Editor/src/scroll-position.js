export function normalizedScrollPosition(position) {
  const numericPosition = Number(position)
  return Number.isFinite(numericPosition) ? Math.max(0, numericPosition) : 0
}

export function restoreScrollPosition(
  position,
  requestFrame = callback => window.requestAnimationFrame(callback),
  scrollTo = (x, y) => window.scrollTo(x, y),
) {
  const top = normalizedScrollPosition(position)
  requestFrame(() => scrollTo(0, top))
  return top
}
