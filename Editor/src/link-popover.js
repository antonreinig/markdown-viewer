function linkLabel(anchor) {
  return anchor.textContent || anchor.getAttribute('href') || 'Link'
}

function linkDestination(anchor) {
  return anchor.getAttribute('href') || ''
}

function destinationLabel(value) {
  try {
    const url = new URL(value)
    return url.host || url.pathname || value
  } catch {
    return value
  }
}

export function createLinkPopover(editor, post) {
  const popover = document.createElement('div')
  popover.className = 'link-popover'
  popover.dataset.mode = 'actions'
  popover.setAttribute('role', 'dialog')
  popover.setAttribute('aria-label', 'Link options')
  popover.hidden = true
  popover.innerHTML = `
    <div class="link-popover-actions">
      <button class="link-open" type="button"><span aria-hidden="true">↗</span><span class="link-open-label"></span></button>
      <span class="link-popover-divider"></span>
      <button class="link-edit" type="button">Edit</button>
    </div>
    <form class="link-popover-editor" hidden>
      <label>Text<input class="link-text" type="text" autocomplete="off"></label>
      <label>Link<input class="link-url" type="text" inputmode="url" autocomplete="off" spellcheck="false"></label>
      <div class="link-popover-editor-actions">
        <button class="link-remove" type="button">Remove link</button>
        <button class="link-cancel" type="button">Cancel</button>
        <button class="link-save" type="submit">Save</button>
      </div>
    </form>`
  document.body.append(popover)

  const actions = popover.querySelector('.link-popover-actions')
  const form = popover.querySelector('form')
  const openLabel = popover.querySelector('.link-open-label')
  const textInput = popover.querySelector('.link-text')
  const urlInput = popover.querySelector('.link-url')
  let anchor = null
  let range = null
  let hideTimer = null

  function clearHideTimer() {
    if (hideTimer) window.clearTimeout(hideTimer)
    hideTimer = null
  }

  function position() {
    if (!anchor || popover.hidden || !anchor.isConnected) return
    const rect = anchor.getBoundingClientRect()
    const popoverRect = popover.getBoundingClientRect()
    const left = Math.min(
      window.innerWidth - popoverRect.width - 12,
      Math.max(12, rect.left + rect.width / 2 - popoverRect.width / 2),
    )
    const above = rect.top - popoverRect.height - 12
    popover.classList.toggle('below', above < 8)
    popover.style.left = `${left}px`
    popover.style.top = `${above < 8 ? rect.bottom + 12 : above}px`
    popover.style.setProperty('--arrow-left', `${rect.left + rect.width / 2 - left}px`)
  }

  function currentRange(target) {
    try {
      const from = editor.view.posAtDOM(target, 0)
      return { from, to: from + (target.textContent?.length || 0) }
    } catch {
      return null
    }
  }

  function show(target) {
    if (!target?.matches?.('a[href]')) return
    clearHideTimer()
    anchor = target
    range = currentRange(target)
    openLabel.textContent = `Open ${destinationLabel(linkDestination(target))}`
    textInput.value = linkLabel(target)
    urlInput.value = linkDestination(target)
    actions.hidden = false
    form.hidden = true
    popover.dataset.mode = 'actions'
    popover.hidden = false
    window.requestAnimationFrame(position)
  }

  function hide({ immediate = false } = {}) {
    clearHideTimer()
    const perform = () => {
      popover.hidden = true
      anchor = null
      range = null
    }
    if (immediate) perform()
    else hideTimer = window.setTimeout(perform, 180)
  }

  function open() {
    if (!anchor) return
    post('openLink', { url: linkDestination(anchor) })
  }

  function edit() {
    if (!anchor) return
    clearHideTimer()
    actions.hidden = true
    form.hidden = false
    popover.dataset.mode = 'edit'
    window.requestAnimationFrame(() => {
      position()
      textInput.focus()
      textInput.select()
    })
  }

  function cancel() {
    if (!anchor) return hide({ immediate: true })
    actions.hidden = false
    form.hidden = true
    popover.dataset.mode = 'actions'
    window.requestAnimationFrame(position)
  }

  function updateLink(event) {
    event.preventDefault()
    if (!range) return
    const label = textInput.value || urlInput.value
    const href = urlInput.value.trim()
    if (!label || !href) return

    editor
      .chain()
      .focus()
      .setTextSelection(range)
      .insertContent(label)
      .setTextSelection({ from: range.from, to: range.from + label.length })
      .setLink({ href })
      .setTextSelection(range.from + label.length)
      .run()
    hide({ immediate: true })
  }

  function removeLink() {
    if (!range) return
    editor.chain().focus().setTextSelection(range).unsetLink().run()
    hide({ immediate: true })
  }

  popover.querySelector('.link-open').addEventListener('click', open)
  popover.querySelector('.link-edit').addEventListener('click', edit)
  popover.querySelector('.link-cancel').addEventListener('click', cancel)
  popover.querySelector('.link-remove').addEventListener('click', removeLink)
  form.addEventListener('submit', updateLink)
  popover.addEventListener('mouseenter', clearHideTimer)
  popover.addEventListener('mouseleave', () => {
    if (form.hidden) hide()
  })
  window.addEventListener('scroll', position, true)
  window.addEventListener('resize', position)
  document.addEventListener('keydown', event => {
    if (event.key === 'Escape' && !popover.hidden) hide({ immediate: true })
  })

  return { show, hide, open, element: popover }
}
