---
layout: post
title: "Causelog: A Self-Hosted Memory for Engineering Decisions"
date: 2026-09-07
categories: [opensource]
tags: [opensource, rust, self-hosting, sqlite, axum, agpl, engineering, decision-making, knowledge-management]
description: "Causelog is a self-hosted engineering decision memory in a single Rust binary. Record the trade-offs you weighed, the experiments that tested them, and the lessons you'd otherwise re-learn the hard way — then export any project as JSON, Markdown, HTML, a zip bundle, or a slideshow."
image: /assets/images/posts/causelog.png
---

Six months later, nobody remembers why we picked Postgres. The Slack thread is lost, the PR comment is buried, the meeting notes say "agreed to move forward." Someone re-opens the question, re-litigates it in a new channel, and the same trade-offs get weighed a second time by people who weren't there for the first.

That's the problem I built [Causelog](https://github.com/DavidNeurieder/causelog) to solve: a self-hosted engineering decision memory. Not a task tracker, not a wiki, not a bug queue — a place where the *reasoning* itself is the product. A single Rust binary with an embedded SQLite database, no external services, one machine, one backup to care about. Version **0.2.0** just tagged, and it's the one where the story stored inside a project can finally leave the server in whatever shape you need it.

## The golden path

The core loop is: **goal → decision → experiment → lesson → timeline & graph**.

- **Projects & goals** — what "done" looks like, per project, with a goal body that supports Markdown and checkbox checklists.
- **Decisions** — the options you weighed (up to four, each with pros and cons), the choice you made, and the rationale. Every change is kept as an **immutable revision**, so "why did we pick this?" is answered by the record itself, not by whoever happens to remember.
- **Experiments** — a falsifiable hypothesis and a lifecycle: *planned → ongoing → done/abandoned*, with timestamped observations along the way and a lesson captured when it's over.
- **Notes** — durable knowledge, extracted from experiments or written directly, with the same revision history.
- **Timeline & graph** — when things started, ended, and what you measured in between; and how entities connect, with typed links (`supports` / `rejects` / `follows` / `related`).

The design bet is that decisions are only ever as good as the *why* you can retrieve later. The entity model is built to capture the reasoning once and keep it searchable: full-text over every entity, kept in sync automatically, scoped to the projects you can actually see.

It's multi-user too: projects have owner/member roles, self-signup works but new accounts need admin approval, and there's an admin panel for user and membership management.

## The UI that got out of the way

<img src="/assets/images/posts/causelog.png" alt="Causelog project detail page — decisions, experiments, and notes with an inline editor">

Detail pages support inline editing through a JSON API — click, edit, done. A kanban board lets you drag decisions and experiments between statuses. There's a timeline view and a graph view for seeing how everything connects, and search stays on every page.

Version 0.1.0 shipped most of that at the end of August. What I kept failing to do, though, was the *export*. I'd want to share a project as a markdown doc, hand a stakeholder a slide deck, or archive a finished project into the repo — and every time I'd have to hit the database with a handful of ad-hoc queries and paste the result into a file. That's the itch 0.2.0 scratches.

## One project, five export formats

`causelog export` produces a **canonical, versioned snapshot** of any project — project, goals, decisions with their resolved status, experiments with their raw events, notes, the immutable revision history, and typed links — always from a single consistent read snapshot. From that one snapshot it derives five formats on demand:

- **JSON** — the reference format, built for future import and for backups.
- **Markdown** — a Git-friendly directory tree, one file per entity, ready to commit to a repo.
- **HTML** — an offline-ready static site.
- **Archive** — JSON + Markdown + HTML together in one deterministic ZIP with a manifest, byte-for-byte reproducible.
- **ODP** — an Impress/LibreOffice (and PowerPoint-) compatible slideshow built from the project *story*: title, goal, one slide per decision, experiment, and lesson, plus a timeline.

Everything is regenerated per request on the project's Export page (or from the CLI), so the download is always current. Downloads are member-only.

The interesting engineering constraint was that all five formats had to mean the same thing. That's what the **story configuration** work was about.

## The story: one configuration, every renderer agrees

A project page has a "story" — the problem statement, the decisions that mattered, the lessons learned, the current state of the plan. 0.2.0 added a **story editor** that lets you say what the story actually is: hide a section or a decision you don't want in the narrative, reorder decisions and experiments, write a custom problem one-liner, and show a current-state summary of where things stand. The saved configuration is plain JSON in the database.

The rule that holds the whole thing together: the configured story is computed **exactly once**, in the export crate, and every renderer — the web page, the Markdown, the HTML, the ODP deck, the one-pager, and the CLI — consumes that same final story. Nothing downstream re-derives selection or ordering, so a hide-and-reorder in the editor shows up identically in every format. If you hide a decision, its experiments are hidden with it (an experiment only makes sense under the decision it resolves), and the hidden decision's chip never leaks into the current-state summary.

There's a regression test that asserts the contract end to end: the same project with the same saved configuration produces the *same* set, the *same* order, and the *same* current state across the web and all five exports. A second test drives the compiled CLI binary and checks its output matches the canonical story too. If a format ever starts telling a different story than the editor configured, a test fails.

Two correctness bugs from the past that these tests pin down:

- **The ODP chosen-option bug.** The slide format used to derive the selected option's *label* and compare it against an option's *id*. It worked while the label and id happened to match (as in the demo data) and silently broke the moment someone used a readable label like "Use PostgreSQL" with an opaque id. Now the comparison is `option.id == decided_option`, and the label is only used for display. The regression test is the exact case that used to fail: id `opt-123`, label "Use PostgreSQL".
- **The double-bind bug.** The new project-level revision query had two `?` placeholders but only one bound value in one call path; the half of the query that never matched silently returned zero revisions for notes. The bulk snapshot test (40 real decisions, each with revisions and events) now catches that class of thing.

## Performance, because export touches everything

The old export source was per-entity N+1: list decisions, then for each decision list its revisions. 0.2.0 replaced that with three project-level queries — decisions, all revisions, all events — collected inside **one SQLite read transaction**, then reassembled in memory. One export = one logical state of the project, gathered in a handful of round-trips no matter the entity count. And the archive and presentation builders now return `Result` instead of panicking, so a ZIP or ODF write failure surfaces to the HTTP/CLI layer cleanly instead of taking down a request.

## A release you can download

Causelog 0.2.0 also picked up a proper release pipeline. Each tagged release now runs a guard job (fmt, clippy with `-D warnings`, the whole test suite) against the exact code being tagged, then builds the release binary — LTO, one codegen unit, stripped, about 15 MB — and attaches it to the GitHub release as `causelog-v0.2.0-x86_64-linux.tar.gz`. No Rust toolchain needed:

```sh
tar -xzf causelog-v0.2.0-x86_64-linux.tar.gz
./causelog serve
# → http://127.0.0.1:8080/setup — create the admin account
```

A genuinely memorable moment from that release: CI's clippy is `stable` (1.98), while my local toolchain was still on 1.94. The first release run failed on **six** new lints — `sort_by(|a, b| b.0.cmp(&a.0))` → `sort_by_key(Reverse(...))`, a collapsible match, a large-error-type on an axum redirect helper — that my local clippy didn't complain about at all. I updated the local toolchain, fixed all six, and re-ran. It's exactly the kind of thing a release pipeline is for: the gate catches problems you didn't know you had, before any artifact ships.

Or skip setup entirely and see it populated:

```sh
./causelog seed-demo
# demo / demo-password — admin, owns three projects (two of them unapologetically funny)
```

Deployment is otherwise one binary. It terminates HTTPS itself — automatic Let's Encrypt issuance and renewal via `--tls-domain`, or bring your own certificate — and data is a single SQLite file you back up with the included script.

## What I'd tell myself

- **The `why` has to be a first-class object, not a comment.** Comments rot. Revisions, options, and rationale that are typed data don't. The discipline of recording the reasoning while it's fresh is what makes the whole thing useful in year two.
- **Exports are a feature, not an afterthought.** I treated them as boring glue until the day I wanted a slide deck *and* a markdown doc *and* an archive from the same project, in one sitting. Making the export a first-class, versioned, testable surface was the single biggest quality jump for what this tool actually does.
- **One consistent snapshot beats cleverness.** An export that mixes reads from different moments is a lie. A single read transaction is boring and correct, and "boring and correct" is the right bar for a knowledge tool.

If you've ever lost the reasons behind your own past decisions — the database call, the framework, the migration that everyone has opinions about and nobody can defend — Causelog is an attempt to make "why did we do this?" a question with a permanent, exportable answer.

Causelog is AGPL-3.0. The prebuilt Linux binary is on the [v0.2.0 release](https://github.com/DavidNeurieder/causelog/releases/tag/v0.2.0), and everything else is in the README.

Source: [github.com/DavidNeurieder/causelog](https://github.com/DavidNeurieder/causelog) (AGPL-3.0)