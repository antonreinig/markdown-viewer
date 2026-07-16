import { Editor } from '@tiptap/core'
import StarterKit from '@tiptap/starter-kit'
import Link from '@tiptap/extension-link'
import { TableKit } from '@tiptap/extension-table'
import TaskList from '@tiptap/extension-task-list'
import TaskItem from '@tiptap/extension-task-item'
import { Markdown } from '@tiptap/markdown'
import { afterEach, describe, expect, it } from 'vitest'

let editor

function makeEditor(markdown) {
  editor = new Editor({
    extensions: [
      StarterKit.configure({ link: false }),
      Link,
      TableKit,
      TaskList,
      TaskItem.configure({ nested: true }),
      Markdown.configure({ markedOptions: { gfm: true } }),
    ],
    content: markdown,
    contentType: 'markdown',
  })
  return editor
}

afterEach(() => editor?.destroy())

describe('Markdown round trip', () => {
  it('preserves headings, formatting, links, lists, quotes, and code', () => {
    const source = `# Title

Some **bold**, *italic*, and [linked](https://example.com) text.

- one
- two

> quote

\`\`\`swift
let answer = 42
\`\`\``
    const result = makeEditor(source).getMarkdown()
    expect(result).toContain('# Title')
    expect(result).toContain('**bold**')
    expect(result).toContain('[linked](https://example.com)')
    expect(result).toContain('- one')
    expect(result).toContain('> quote')
    expect(result).toContain('```swift')
  })

  it('round-trips a GFM table and can add a row', () => {
    const source = `| Name | Value |
| --- | --- |
| Alpha | 1 |`
    const instance = makeEditor(source)
    expect(instance.getMarkdown()).toMatch(/\| Name\s+\| Value\s+\|/)
    instance.commands.setTextSelection(3)
    instance.commands.addRowAfter()
    expect(instance.getMarkdown().split('\n').filter(line => line.startsWith('|')).length).toBeGreaterThanOrEqual(4)
  })

  it('round-trips task lists', () => {
    const result = makeEditor('- [x] Finished\n- [ ] Open').getMarkdown()
    expect(result).toContain('- [x] Finished')
    expect(result).toContain('- [ ] Open')
  })
})
