// @vitest-environment jsdom

import { Editor } from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'
import Link from '@tiptap/extension-link'
import { Markdown } from '@tiptap/markdown'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { createLinkPopover } from './link-popover'

let editor

beforeEach(() => {
  document.body.innerHTML = '<div id="editor"></div>'
  editor = new Editor({
    element: document.querySelector('#editor'),
    extensions: [StarterKit.configure({ link: false }), Link, Markdown],
    content: '[Original](https://example.com)',
    contentType: 'markdown',
  })
})

afterEach(() => editor?.destroy())

describe('link popover', () => {
  it('offers opening and edits both label and destination', () => {
    const post = vi.fn()
    const controller = createLinkPopover(editor, post)
    const anchor = document.querySelector('#editor a')

    controller.show(anchor)
    expect(controller.element.hidden).toBe(false)
    expect(controller.element.querySelector('.link-open-label').textContent).toBe('Open example.com')

    controller.element.querySelector('.link-open').click()
    expect(post).toHaveBeenCalledWith('openLink', { url: 'https://example.com' })

    controller.element.querySelector('.link-edit').click()
    controller.element.querySelector('.link-text').value = 'Changed'
    controller.element.querySelector('.link-url').value = 'https://example.org/docs'
    controller.element.querySelector('form').requestSubmit()

    expect(editor.getMarkdown()).toBe('[Changed](https://example.org/docs)')
  })

  it('can remove link formatting without removing its text', () => {
    const controller = createLinkPopover(editor, vi.fn())
    controller.show(document.querySelector('#editor a'))
    controller.element.querySelector('.link-edit').click()
    controller.element.querySelector('.link-remove').click()

    expect(editor.getMarkdown()).toBe('Original')
  })
})
