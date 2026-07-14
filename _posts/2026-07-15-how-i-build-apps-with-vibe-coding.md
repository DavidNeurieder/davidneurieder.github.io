---
layout: post
title: "How I Build Apps With Vibe Coding"
date: 2026-07-15
categories: [android, opensource, ai]
tags: [android, vibe-coding, opencode, ai, open-source]
---

I built two Android apps in the last few months — [Offline Currency Converter](https://github.com/DavidNeurieder/offline-currency-converter) and [Activity Trace](https://github.com/DavidNeurieder/ActivityTrace). Both are on F-Droid. Both work offline. Both are small, focused, and do one thing well.

I didn't write most of the code. Not in the traditional sense, anyway.

## What vibe coding means

Andrej Karpathy coined the term "vibe coding" earlier this year. The idea is simple: you describe what you want in plain language, the AI generates the code, and you steer it by giving feedback. You're not typing characters one by one. You're directing.

It sounds lazy. It's not. You still need to understand the architecture, make design decisions, catch bugs, and know when the AI is wrong. But the act of writing boilerplate, wiring up dependencies, and translating designs into Compose — that part is largely automated.

## My setup

I use [OpenCode](https://opencode.ai), an open source AI coding agent that runs in the terminal. It reads your entire project, understands the context, and generates or modifies code based on what you ask.

Here's what a typical session looks like:

1. I describe a feature: "Add a home screen widget that shows the current conversion rate with Material You dynamic colors"
2. OpenCode explores the codebase, reads existing files, understands the architecture
3. It proposes changes — new files, modifications to existing ones, XML layouts
4. I review the diff, accept or reject, give feedback
5. It iterates until the feature works

The key difference from a code editor with autocomplete: OpenCode doesn't just complete the line you're on. It reads your `build.gradle.kts`, your existing ViewModels, your database schema, and generates code that fits your project's patterns. If you use Room for persistence, it generates Room entities. If you use Hilt for DI, it generates Hilt modules. It mimics your existing code style because it can see it.

## What I actually do

I don't describe every function signature. I describe outcomes.

"Build a chart component using Compose Canvas that shows 90 days of exchange rate data with cubic Bézier curves, gradient fills, and touch interaction for crosshair tooltips."

OpenCode generates the Canvas composable, the gesture detection, the data filtering logic. I run it on the emulator. The curves look wrong? I say "the curves are too jagged, use cubic interpolation." It fixes it. The gradient doesn't fade correctly? "The gradient should go from the trend color to transparent." It adjusts.

Most of my time is spent on three things:

- **Architecture decisions** — Should the widget compute cross-rates or store them? Should the chart data be cached in Room or recomputed on each render? The AI can suggest, but I decide.
- **Testing** — I write instrumented tests that verify the UI actually works on a device. OpenCode helps generate test cases, but I run them and interpret failures.
- **Edge cases** — The AI doesn't know that Frankfurter API returns rates relative to EUR, or that SQLite migrations need to preserve data. I tell it.

## What surprised me

The speed. Not of the AI — of the iteration cycle. When generating code is the bottleneck, removing that bottleneck means features ship in hours instead of days.

The chart feature in Offline Currency Converter — gradient fills, cubic curves, dashed grid lines, touch interaction, date range tabs, rate summary row — that's maybe 200 lines of Compose Canvas code. It took an afternoon. A year ago, that would have been a week of Stack Overflow searching and library evaluation.

Activity Trace's search engine — the query parser, the notification listener, the encrypted database, the export functionality — about 1,400 lines across the whole app. Built in a weekend.

## What doesn't work

Vibe coding has limits.

**Large refactors are risky.** If you need to restructure 15 files, the AI might get confused about which changes depend on which. I do those manually or in small steps.

**It hallucinates APIs.** The AI might use a Compose function that doesn't exist yet, or call a Room method with the wrong signature. You need to compile and test frequently. Every few changes, not at the end.

**Context window matters.** OpenCode reads your whole project, but very large codebases get summarized. If the AI needs to understand a 500-line file in detail, it might miss things. I keep my files small and focused — partly for readability, partly for the AI.

**It doesn't replace understanding.** I still read every line of code before committing. I still understand the architecture, the data flow, the edge cases. The AI generates, but I verify. If you skip the verification step, you'll ship bugs.

## The workflow

Here's my actual workflow for a new feature:

1. **Describe the feature** in a single sentence or paragraph
2. **Let OpenCode explore** — it reads existing code, understands patterns
3. **Review the proposal** — new files, modifications, dependencies
4. **Accept and test** — run on emulator, check for visual issues
5. **Give feedback** — "the padding is wrong", "this should be a different color", "this crashes on API 26"
6. **Iterate** until it works
7. **Run lint and tests** to catch anything the AI missed
8. **Commit** with a clear message

It's not magic. It's a productivity multiplier. If you know what you're building, it gets you there faster. If you don't know what you're building, it'll generate code that compiles but doesn't solve your problem.

## Try it

If you're building Android apps and haven't tried vibe coding, start with a small feature. Not a new app — a single feature in an existing project. Add a settings screen. Build a widget. Implement a chart.

OpenCode is free and open source. Install it, point it at your project, and describe what you want. You might be surprised how far a good description gets you.

Source: [github.com/anomalyco/opencode](https://github.com/anomalyco/opencode)
