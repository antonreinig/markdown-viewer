import { Mark, Node, mergeAttributes } from '@tiptap/core'
import Image from '@tiptap/extension-image'

function atomView(kind, labelForNode) {
  return ({ node }) => {
    const element = document.createElement('span')
    element.className = `markdown-atom markdown-atom-${kind}`
    element.dataset.kind = kind
    element.contentEditable = 'false'
    element.setAttribute('role', 'group')
    element.setAttribute('aria-label', `${kind}: ${labelForNode(node)}`)

    const badge = document.createElement('span')
    badge.className = 'markdown-atom-badge'
    badge.textContent = kind

    const value = document.createElement('span')
    value.className = 'markdown-atom-value'
    value.textContent = labelForNode(node)

    element.append(badge, value)
    return { dom: element }
  }
}

function rawBlockNode({ name, kind, tokenizer }) {
  return Node.create({
    name,
    group: 'block',
    atom: true,
    selectable: true,
    defining: true,

    addAttributes() {
      return { raw: { default: '' }, label: { default: '' } }
    },

    parseHTML() {
      return [{ tag: `div[data-markdown-${name}]` }]
    },

    renderHTML({ HTMLAttributes }) {
      return ['div', mergeAttributes(HTMLAttributes, { [`data-markdown-${name}`]: '' })]
    },

    addNodeView() {
      return atomView(kind, node => node.attrs.label || node.attrs.raw.trim().split('\n')[0] || kind)
    },

    markdownTokenizer: { name, level: 'block', ...tokenizer },

    parseMarkdown(token, helpers) {
      return helpers.createNode(name, {
        raw: token.raw,
        label: token.label || '',
      })
    },

    renderMarkdown(node) {
      return node.attrs.raw || ''
    },
  })
}

export const FrontMatter = rawBlockNode({
  name: 'frontMatter',
  kind: 'Front matter',
  tokenizer: {
    start: source => (source.startsWith('---') ? 0 : -1),
    tokenize(source) {
      const match = /^(---[ \t]*\n[\s\S]*?\n(?:---|\.\.\.)[ \t]*)(?:\n|$)/.exec(source)
      if (!match) return undefined
      return { type: 'frontMatter', raw: match[0], label: 'YAML document metadata' }
    },
  },
})

export const FootnoteDefinition = rawBlockNode({
  name: 'footnoteDefinition',
  kind: 'Footnote',
  tokenizer: {
    start(source) {
      const match = /^\[\^[^\]]+\]:/m.exec(source)
      return match?.index ?? -1
    },
    tokenize(source) {
      const match = /^\[\^([^\]]+)\]:[^\n]*(?:\n(?:(?: {2,}|\t)[^\n]*|[ \t]*$))*(?:\n|$)/.exec(source)
      if (!match) return undefined
      return { type: 'footnoteDefinition', raw: match[0], label: match[1] }
    },
  },
})

export const MathBlock = rawBlockNode({
  name: 'mathBlock',
  kind: 'Math',
  tokenizer: {
    start(source) {
      const dollar = /^\$\$/m.exec(source)?.index
      const bracket = /^\\\[/m.exec(source)?.index
      return Math.min(dollar ?? Infinity, bracket ?? Infinity)
    },
    tokenize(source) {
      const match = /^(\$\$[ \t]*\n?[\s\S]*?\n?\$\$[ \t]*|\\\[[\s\S]*?\\\])(?:\n|$)/.exec(source)
      if (!match) return undefined
      const expression = match[1].replace(/^\$\$|\$\$$|^\\\[|\\\]$/g, '').trim()
      return { type: 'mathBlock', raw: match[0], label: expression }
    },
  },
})

export const RawMarkdownBlock = rawBlockNode({
  name: 'rawMarkdownBlock',
  kind: 'Markdown',
  tokenizer: {
    start(source) {
      const candidates = [/^:::[^\n]*/m, /^!!![^\n]*/m, /^<!--[\s\S]*?-->/m, /^ {0,3}<(?:div|section|article|aside|details|figure|table|script|style|iframe)\b/im]
      return Math.min(...candidates.map(pattern => pattern.exec(source)?.index ?? Infinity))
    },
    tokenize(source) {
      const comment = /^(<!--[\s\S]*?-->)(?:\n|$)/.exec(source)
      if (comment) return { type: 'rawMarkdownBlock', raw: comment[0], label: 'HTML comment' }

      const directive = /^(:::[^\n]*\n[\s\S]*?\n:::[ \t]*)(?:\n|$)/.exec(source)
      if (directive) return { type: 'rawMarkdownBlock', raw: directive[0], label: directive[1].split('\n')[0] }

      const admonition = /^(!!![^\n]*(?:\n(?:(?: {2,}|\t)[^\n]*|[ \t]*$))+)(?:\n|$)/.exec(source)
      if (admonition) return { type: 'rawMarkdownBlock', raw: admonition[0], label: admonition[1].split('\n')[0] }

      const html = /^( {0,3}<(div|section|article|aside|details|figure|table|script|style|iframe)\b[^>]*>[\s\S]*?<\/\2>[ \t]*)(?:\n|$)/i.exec(source)
      if (html) return { type: 'rawMarkdownBlock', raw: html[0], label: `<${html[2].toLowerCase()}> HTML` }
      return undefined
    },
  },
})

export const FootnoteReference = Node.create({
  name: 'footnoteReference',
  group: 'inline',
  inline: true,
  atom: true,

  addAttributes() {
    return { label: { default: '' }, raw: { default: '' } }
  },

  parseHTML() {
    return [{ tag: 'span[data-footnote-reference]' }]
  },

  renderHTML({ HTMLAttributes }) {
    return ['span', mergeAttributes(HTMLAttributes, { 'data-footnote-reference': '' })]
  },

  addNodeView() {
    return atomView('Footnote', node => node.attrs.label)
  },

  markdownTokenizer: {
    name: 'footnoteReference',
    level: 'inline',
    start: source => source.indexOf('[^'),
    tokenize(source) {
      const match = /^\[\^([^\]]+)\]/.exec(source)
      if (!match) return undefined
      return { type: 'footnoteReference', raw: match[0], label: match[1] }
    },
  },

  parseMarkdown(token, helpers) {
    return helpers.createNode('footnoteReference', { label: token.label, raw: token.raw })
  },

  renderMarkdown(node) {
    return node.attrs.raw || `[^${node.attrs.label}]`
  },
})

export const RawHTMLInline = Node.create({
  name: 'rawHTMLInline',
  group: 'inline',
  inline: true,
  atom: true,

  addAttributes() {
    return { raw: { default: '' } }
  },

  parseHTML() {
    return [{ tag: 'span[data-raw-html-inline]' }]
  },

  renderHTML({ HTMLAttributes }) {
    return ['span', mergeAttributes(HTMLAttributes, { 'data-raw-html-inline': '' })]
  },

  addNodeView() {
    return atomView('HTML', node => node.attrs.raw)
  },

  markdownTokenizer: {
    name: 'rawHTMLInline',
    level: 'inline',
    start(source) {
      const match = /<!--|<\/?[A-Za-z][^>\n]*>/.exec(source)
      return match?.index ?? -1
    },
    tokenize(source) {
      const match = /^(<!--[\s\S]*?-->|<\/?[A-Za-z][^>\n]*>)/.exec(source)
      if (!match) return undefined
      return { type: 'rawHTMLInline', raw: match[0] }
    },
  },

  parseMarkdown(token, helpers) {
    return helpers.createNode('rawHTMLInline', { raw: token.raw })
  },

  renderMarkdown(node) {
    return node.attrs.raw || ''
  },
})

export const WikiLink = Node.create({
  name: 'wikiLink',
  group: 'inline',
  inline: true,
  atom: true,

  addAttributes() {
    return { raw: { default: '' }, label: { default: '' } }
  },

  parseHTML() {
    return [{ tag: 'span[data-wiki-link]' }]
  },

  renderHTML({ HTMLAttributes }) {
    return ['span', mergeAttributes(HTMLAttributes, { 'data-wiki-link': '' })]
  },

  addNodeView() {
    return atomView('Wiki link', node => node.attrs.label)
  },

  markdownTokenizer: {
    name: 'wikiLink',
    level: 'inline',
    start: source => source.indexOf('[['),
    tokenize(source) {
      const match = /^\[\[([^\]\n]+)\]\]/.exec(source)
      if (!match) return undefined
      return { type: 'wikiLink', raw: match[0], label: match[1] }
    },
  },

  parseMarkdown(token, helpers) {
    return helpers.createNode('wikiLink', { raw: token.raw, label: token.label })
  },

  renderMarkdown(node) {
    return node.attrs.raw || `[[${node.attrs.label}]]`
  },
})

export const InlineMath = Node.create({
  name: 'inlineMath',
  group: 'inline',
  inline: true,
  atom: true,

  addAttributes() {
    return { expression: { default: '' }, raw: { default: '' } }
  },

  parseHTML() {
    return [{ tag: 'span[data-inline-math]' }]
  },

  renderHTML({ HTMLAttributes }) {
    return ['span', mergeAttributes(HTMLAttributes, { 'data-inline-math': '' })]
  },

  addNodeView() {
    return atomView('Math', node => node.attrs.expression)
  },

  markdownTokenizer: {
    name: 'inlineMath',
    level: 'inline',
    start: source => source.indexOf('$'),
    tokenize(source) {
      const match = /^\$(?!\s)([^$\n]+?)(?<!\s)\$(?!\d)/.exec(source)
      if (!match) return undefined
      return { type: 'inlineMath', raw: match[0], expression: match[1] }
    },
  },

  parseMarkdown(token, helpers) {
    return helpers.createNode('inlineMath', { expression: token.expression, raw: token.raw })
  },

  renderMarkdown(node) {
    return node.attrs.raw || `$${node.attrs.expression}$`
  },
})

export const Highlight = Mark.create({
  name: 'highlight',

  parseHTML() {
    return [{ tag: 'mark' }]
  },

  renderHTML({ HTMLAttributes }) {
    return ['mark', mergeAttributes(HTMLAttributes), 0]
  },

  markdownTokenizer: {
    name: 'highlight',
    level: 'inline',
    start: source => source.indexOf('=='),
    tokenize(source, _tokens, lexer) {
      const match = /^==([^=\n]+)==/.exec(source)
      if (!match) return undefined
      return { type: 'highlight', raw: match[0], tokens: lexer.inlineTokens(match[1]) }
    },
  },

  parseMarkdown(token, helpers) {
    return helpers.applyMark('highlight', helpers.parseInline(token.tokens || []))
  },

  renderMarkdown(node, helpers) {
    return `==${helpers.renderChildren(node)}==`
  },
})

export const Superscript = Mark.create({
  name: 'superscript',

  parseHTML() {
    return [{ tag: 'sup' }]
  },

  renderHTML({ HTMLAttributes }) {
    return ['sup', mergeAttributes(HTMLAttributes), 0]
  },

  markdownTokenizer: {
    name: 'superscript',
    level: 'inline',
    start: source => source.indexOf('^'),
    tokenize(source, _tokens, lexer) {
      const match = /^\^([^\s^][^^\n]*?)\^/.exec(source)
      if (!match) return undefined
      return { type: 'superscript', raw: match[0], tokens: lexer.inlineTokens(match[1]) }
    },
  },

  parseMarkdown(token, helpers) {
    return helpers.applyMark('superscript', helpers.parseInline(token.tokens || []))
  },

  renderMarkdown(node, helpers) {
    return `^${helpers.renderChildren(node)}^`
  },
})

export const CompatibleImage = Image.extend({
  renderHTML({ HTMLAttributes }) {
    return ['img', mergeAttributes(this.options.HTMLAttributes, HTMLAttributes, {
      loading: 'lazy',
      referrerpolicy: 'no-referrer',
    })]
  },
}).configure({ allowBase64: true })

export const compatibilityExtensions = [
  FrontMatter,
  FootnoteDefinition,
  MathBlock,
  RawMarkdownBlock,
  FootnoteReference,
  RawHTMLInline,
  WikiLink,
  InlineMath,
  Highlight,
  Superscript,
  CompatibleImage,
]
