---
layout: post
title: "I Built a Search Engine for My Notifications"
date: 2026-07-05
categories: [android, opensource, privacy, activity-trace]
tags: [android, opensource, privacy, notifications, search, open-source]
description: "Android's notification history stores 50 entries with no search. I built Activity Trace to capture notifications, screen content, and files into one encrypted database."
image: /assets/images/posts/search-engine.svg
---

You know that feeling when you *know* you saw something in a notification — a confirmation code, a link, a message — but it's gone. You scroll through notification history, find it capped at 50 entries, not searchable, and destined to be wiped on the next reboot.

I got tired of losing data my phone had already processed. So I built [Activity Trace](https://github.com/DavidNeurieder/ActivityTrace) — an on-device search engine that captures notifications, screen content, and file text, then lets you search across everything. No internet, no AI, no cloud.

## Why notifications are the worst

Android's notification history is a band-aid. It stores the last 50 notifications in a flat list with no search. If you dismiss something, it's gone from the shade. If you reboot, the history is wiped. And it only covers notifications — what about things you saw on screen but didn't get a notification for? Or text inside a downloaded PDF?

Activity Trace captures three sources:

- **Notifications** — via `NotificationListenerService`, every notification is captured as it arrives
- **Screen content** — via `AccessibilityService`, text you see on screen (including in-app content, browser pages) is captured
- **Files** — PDFs and text files in Downloads and Documents are indexed for search

All three feed into a single encrypted database. You search once, get results from everywhere.

## Search that works without AI

The search understands natural language queries out of the box:

- `yesterday signal` — finds everything from Signal yesterday
- `last week tracking` — finds tracking numbers from the past week
- `in:whatsapp july 3` — narrows by app and date
- `type:notification confirmation` — filters by source type

Under the hood it's SQLite `LIKE` substring matching with a query parser that extracts date ranges, app filters, and content type filters. No embeddings, no vector database, no cloud API. The first query returns in ~5ms.

I started with FTS5 (full-text search) but dropped it when I realized the `LIKE` approach was simpler, had zero maintenance, and performed identically at the scale of personal data (thousands, not millions, of records).

## Encrypted by default

The database is encrypted with SQLCipher (AES-256-CBC). The key lives in Android's hardware-backed Keystore. If the device is locked, the database is unreadable.

The app has no internet permission in the manifest. Not "we promise not to use it" — the app literally cannot make network calls. There's no telemetry, no crash reporting, no phoning home.

## Export, backup, and restore

You own your data. The Settings screen offers:

- **Export as CSV** — RFC 4180 with UTF-8 BOM, Excel-compatible
- **Export as JSON** — full structured export
- **Backup to SQLite** — unencrypted copy of the database
- **Restore from backup** — imports an SQLite backup, merging with existing data and skipping duplicates

No cloud sync, no proprietary format, no vendor lock-in.

## Retention that makes sense

Notifications pile up. Activity Trace automatically cleans up records older than a configurable retention period (7, 30, or 90 days). The cleanup runs via Android WorkManager — it happens in the background, respects Doze mode, and doesn't impact battery.

## The tech stack

- **Single-Activity Jetpack Compose** with Material 3 and dynamic color
- **Room + SQLCipher** for the encrypted database
- **WorkManager** for scheduled retention cleanup and file indexing
- **NotificationListenerService** + **AccessibilityService** for capture
- **Min SDK 26**, targets Android 14 (API 34)
- **No Google Play Services** — distributed exclusively through F-Droid

The entire UI is about 700 lines of Compose. The capture layer is about 400 lines across three services. The database layer is about 300 lines including migrations.

## Building for F-Droid

Releasing on F-Droid meant:

- All dependencies verified FOSS (SQLCipher BSD-3, PDFBox Apache-2.0)
- ProGuard minification with logging stripped in release builds
- R8 deterministic mode for reproducible builds
- No Google Play Services, no proprietary dependencies
- Full `fastlane` metadata with screenshots and changelogs

The build process is automated with a Python script that runs lint, unit tests, instrumented tests (on an emulator), and both debug and release APK builds.

## What's next

The app is feature-complete for v0.7.0. Future directions I'm considering:

- **Widget** — a homescreen search bar for instant access
- **Clipboard monitoring** — capture copied text passively
- **Better file indexing** — expand beyond Downloads/Documents to other directories via SAF
- **Search suggestions** — autocomplete from historical queries

## Try it

If you've ever found yourself scrolling frantically through notifications looking for something you *know* you saw, give it a try.

Source: [github.com/DavidNeurieder/ActivityTrace](https://github.com/DavidNeurieder/ActivityTrace) (GPL-3.0)

[<img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png" alt="Get it on F-Droid" height="80">](https://f-droid.org/en/packages/com.activitytrace/)
