---
layout: post
title: "LibreCrate: The Encrypted Document Vault That Runs Everywhere"
date: 2026-08-11
categories: [librecrate, android, opensource, privacy]
tags: [librecrate, android, opensource, privacy, rust, encryption, offline, uniffi, iced]
description: "LibreCrate is my encrypted, offline-first document vault for Android, Linux, macOS, and Windows — one Rust core powering three frontends, with full-text search and cross-platform merge backups."
image: /assets/images/posts/librecrate.svg
---

A few months ago I found myself with the same problem in two places at once. On my phone I had PDFs, receipts, and comics scattered across apps and download folders. On my laptop I had the same kinds of files in a different mess. And the stuff I actually cared about — medical records, boarding passes, personal notes — I didn't really want sitting in a folder that any other app could read.

So I built [LibreCrate](https://github.com/DavidNeurieder/LibreCrate): an encrypted document vault that runs on **Android, Linux, macOS, and Windows**, with a core written once in Rust. It stores PDFs, EPUBs, Apple Wallet passes, CBZ comics, images, and Markdown notes. Every file is encrypted at rest, the app has zero network access, and your data moves between devices through encrypted backups — never through a cloud.

## One Rust core, three frontends

The decision that shaped the whole project: instead of writing the crypto, database, and backup logic once per platform, everything lives in a single Rust crate called `vault-native`. Three frontends talk to it:

- **Android** — Kotlin + Jetpack Compose, bridged through Mozilla's [UniFFI](https://mozilla.github.io/uniffi-rs/). The Gradle build compiles the Rust library and generates the Kotlin bindings automatically; the app never touches a byte of crypto directly.
- **Desktop GUI** — [Iced](https://iced.rs/), a native Rust GUI framework. The same vault, library, readers, and settings on Linux, macOS, and Windows.
- **CLI** — a small terminal app with an interactive REPL: `init`, `import`, `list`, `search`, `backup`, `restore`, plus readline history and tab completion.

One codebase handles encryption, the SQLCipher database, merging, and backup. Fix a bug in the core and every platform gets the fix. The UI layers only ever see a clean FFI surface.

## Encryption at rest

- **Per-file encryption** — AES-256-GCM with a 12-byte IV and 128-bit tag
- **Key wrapping** — the master key is wrapped via Argon2id + AES-256 Key Wrap (RFC 3394)
- **Optional password mode** — even with the device unlocked, nothing is readable without the password; otherwise the master key is wrapped with a per-device key
- **Zero network** — there is no internet permission in the manifest. Not "we promise not to phone home" — the app literally cannot.

## A library you can actually search

The vault remembers your reading position per document — last page for PDFs and comics, last location for EPUBs — and shows "Page X of Y" right on the library cards. Filtering by type, favorites, and sort order round out the library view.

The killer feature for me is full-text search. FTS5 indexes title, author, description, *and* the extracted text inside each document, with highlighted snippets in the results. I can search all my PDFs for a phrase I half-remember and get the matching document with the surrounding text highlighted. It feels like owning my own little search engine — no cloud, no telemetry.

## Backups that merge

Backups are a single encrypted `.librecrate-backup` file containing the wrapped master key, the database, and every document. Because the format is shared between Android and desktop, a backup made on your phone restores on your laptop and vice versa.

The newest behavior (0.5.4) is that **import merges instead of replacing**. In the past, importing a backup rebuilt your library from scratch — anything local that wasn't in the backup was gone. Now the backup's documents are added on top of your existing library: your documents stay, the backup's content joins them, and conflicting versions are flagged instead of silently overwritten. Your local passkey stays exactly as it is — only the backup's own passkey is needed to decrypt it, and backups created with a *different* passkey can be merged too (their files are re-encrypted with your local key). Merged documents are searchable immediately.

## Chasing reproducible F-Droid builds

LibreCrate is F-Droid-only by design — no Play Services, no Firebase, no Crashlytics. That means the [F-Droid build farm](https://f-droid.org/) compiles the native Rust library itself, and it requires the resulting APK to match mine **byte-for-byte**. This has been the most humbling part of the project.

The native library builds MuPDF from source, which initially produced subtly different binaries on different machines. The fixes were a real scavenger hunt: deterministic source ordering in the MuPDF C wrapper, `--remap-path-prefix` to strip every local build path from the binary, a pinned Rust toolchain, an OpenSSL `ranlib` fix for the NDK, and most recently gating MuPDF's system-font support behind a desktop-only feature so the F-Droid host build no longer needs system `fontconfig`. Each fix is one more variable eliminated, and the local build now matches F-Droid's — apart from the git revision F-Droid embeds, which is expected.

The recipe is ready; the build farm just keeps finding new ways to break my weekend. That's the F-Droid way, and honestly I'd rather have it than trust a binary blob I didn't build.

## Try it

If you've ever wanted your documents to live only on your devices — readable, searchable, and encrypted — give it a shot.

- **Android**: install the APK from the [GitHub releases](https://github.com/DavidNeurieder/LibreCrate/releases)
- **Desktop**: prebuilt binaries for Linux/macOS/Windows, or `cargo install --path vault-native/gui`
- **CLI**: `cargo install --path vault-native/cli`

Source: [github.com/DavidNeurieder/LibreCrate](https://github.com/DavidNeurieder/LibreCrate) (AGPL-3.0)
