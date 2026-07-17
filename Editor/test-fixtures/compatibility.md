---
title: Compatibility fixture
tags: [gfm, jekyll]
---

# Compatibility

Visit [paper.md](https://example.com "Example") or inspect ![an image](images/example.png "Local image").

- [x] GFM task
- [ ] Nested-compatible task

| Left | Center | Right |
| :--- | :----: | ----: |
| one | two | three |

This is ==highlighted==, 2^10^, inline $x^2$, and a note[^details].

$$
y = mx + b
$$

See [[Notes/Markdown|the wiki note]].

<!-- This comment must survive. -->

:::note
Unknown directives must survive too.
:::

<div class="raw" data-purpose="round-trip">
Raw HTML must remain byte-for-byte intact inside the block.
</div>

[^details]: Footnote definitions must survive.
