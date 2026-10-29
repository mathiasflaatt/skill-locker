# Lavish page guide

How to write a Lavish artifact the user can grasp in one skim. Style: `paper.css` beside the HTML. Working sample of every block: `example.html` in this folder. Adapted from `rodlandA/claude-workflow-kit` `explaining-visually` (MIT).

## Principle

**Visual first.** Every section opens with a diagram (a `.flow`, `.cols` Before/After, `.steps`, a table or an SVG). At most two sentences of prose follow it. Detail that only some readers want goes into a `details.more` under the element it explains.

## Page structure, by mode

Start every page with `<header>`: `.kicker` (mode · topic), `<h1>`, then `<p class="lede">` with the whole point in one sentence.

**Plan** (before anything is built):

1. `.question` forms: only what changes the plan, at most 5, right after the lede. Build the rest of the page on your recommended answers, so it is a full first draft.
2. `ul.tldr`: Why / What changes / Size.
3. **Today**: a `.flow` of how it works now.
4. **After**: `.legend`, then `.cols` with a Before and an After `.col`; boxes marked `new` / `changed` / `removed`.
5. **Steps**: `ol.steps`, one commit-sized `li.step` each, marked like the boxes.
6. **Traps**: `.callout.trap`, one for each real risk.
7. **Where**: `table.files` with `file` and role.

**As-built** (explain what exists): lede, a 3–4 item `.tldr`, a **Map** (one overview `.flow` or SVG), then one section per concept (visual first, then at most two sentences and a `file:line`), **Traps**, **Where**.

**Grill / wayfinding round**: lede states what this round decides; one `.question` per open point, each with a small visual of what the answer changes; a **Settled so far** `table` that grows each round. Every round lives in the same file: move answered questions into **Settled so far**, add the new round's forms at the top, and update the kicker to `Grill · <topic> · round N`.

## Budget

| Limit | Value |
|---|---|
| Sections | 4–8 `<section>`, each one `<h2>` |
| Prose | ≤ 60 words per section in `<p>` and callouts, ≤ 600 on the page |
| Box text | `<b>` name + `<small>` ≤ 8 words |
| `details.more` | a visual first, then ≤ 80 words; outside the budget |

Over budget: merge related concepts. Still over: the topic is two pages. Say so and split.

## Blocks

| Block | Markup |
|---|---|
| Box | `<div class="box [new\|changed\|removed\|focus\|muted]"><b>Name</b><small>detail</small><code>file:line</code></div>` |
| Flow | `<div class="flow [v]">` box, `<div class="arrow">label</div>`, box… `v` = vertical. Without arrows it wraps as an even grid of boxes |
| Before / After, A / B | `<div class="cols"><div class="col"><h4>Before</h4><div class="flow v">…</div></div>…</div>` |
| Legend | `<div class="legend"><span class="new">new</span><span class="changed">changed</span><span class="removed">removed</span></div>` |
| TL;DR | `<ul class="tldr"><li><b>Why</b>…</li>…</ul>` |
| Steps | `<ol class="steps"><li class="step [new\|changed\|removed]"><b>…</b><small>…</small></li></ol>` |
| Callout | `<div class="callout trap\|decision\|question\|ok"><b>Label</b>text</div>` |
| Badge | `<span class="badge [accent\|new\|changed\|removed]">…</span>` |
| Lookup table | `<table class="files">`, any short two- or three-column table |
| More | `<details class="more"><summary>Why not X?</summary>…</details>` right after the element |
| Question | `<form class="question" data-lavish-question="id">` with `fieldset` > `legend`, `p.why`, `.options` of `label.option[.rec]` > `input` + `span.title` + `span.detail`, optional `textarea`, `.actions` with a submit button and `span.status`. Copy the form and its `onsubmit` from `example.html` |
| Anything else | `<figure><svg aria-label="…">` with classes `node [new\|changed\|removed\|focus]` / `edge` / `muted`; colours only through `var(--…)` |

Put `data-lavish-annotate="off"` on `<html>` when the page is mainly questions; leave it on for plans the user annotates.

## Revising after feedback

Edit only the element the feedback points at, plus what becomes wrong because of it. Keep ids, order and wording of everything else, so the user sees exactly what changed. Answer a question with `--agent-reply`, not an edit, unless the page made it unclear. For a structural change (sections added, removed or reordered), reply with the proposed structure and wait.
