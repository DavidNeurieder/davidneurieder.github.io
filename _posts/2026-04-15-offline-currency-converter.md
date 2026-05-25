---
layout: post
title:  "Building an Offline Currency Converter for Android with OpenCode"
date:   2026-04-15
description: "How I built a fully offline currency converter for Android with 160+ currencies using OpenCode as my AI pair programmer."
---

I built a fully offline-capable currency converter for Android — and I had a lot of help from an AI coding assistant called [OpenCode](https://opencode.ai). Here's what the app does, and how I built it.

## What it is

**Offline Currency Converter** is a native Android app that lets you convert between 160+ currencies without an internet connection. No accounts. No tracking. No ads. Just exchange rates in your pocket, even when you're on a plane, in a tunnel, or traveling abroad without roaming.

The app:
- Fetches live rates from the [Frankfurter API](https://www.frankfurter.dev) when you're online
- Stores them locally in a Room database so you can use them offline
- Falls back to hardcoded rates if both APIs are unreachable
- Lets you search and pick currencies from a bottom-sheet picker with flags
- Shows your recent conversion history
- Runs a background sync via WorkManager so your rates stay fresh
- Is fully translated into 14 languages, including Arabic (RTL)

## How OpenCode helped

I used OpenCode as my pair programmer throughout. It runs as a CLI agent in my terminal, reads and writes files, runs tests, and understands the full codebase. Here's what that looked like in practice.

### Scaffolding the project

I started with a blank Android project in Android Studio. From there I described what I wanted — an offline-first currency converter with clean architecture, Hilt, Room, Retrofit, and Jetpack Compose — and OpenCode generated the entire structure: the Gradle build files, the package layout, the DI modules, the data layer, and the UI screens.

### Building features iteratively

Each feature followed the same pattern: I'd describe what I wanted, OpenCode would write the code, I'd review it, and we'd iterate. For example, when I wanted the currency picker to show recently used currencies at the top, I described the UX requirement and it implemented the DataStore persistence, the UI sections, and the state management in the ViewModel — all in one shot.

### Writing tests

OpenCode wrote hundreds of tests alongside the production code. Unit tests for ViewModels, Use Cases, Repositories, and Workers. Instrumented tests for UI screens, navigation, and Room DAOs. MockWebServer for API integration tests. It even configured JaCoCo for coverage reporting.

### Debugging and fixing

When tests failed or the app crashed, I'd paste the error into OpenCode. It would trace the issue, find the root cause, and propose a fix. For example, the cross-rate calculation (converting between two non-EUR currencies via the EUR base rate) took a few iterations to get right — OpenCode tracked the logic bug, fixed it, and updated the tests.

## Tech stack

| Component | Choice |
|---|---|
| Language | Kotlin |
| UI | Jetpack Compose + Material 3 |
| Architecture | MVVM + Clean Architecture |
| DI | Hilt |
| Database | Room |
| Networking | Retrofit + OkHttp |
| Background sync | WorkManager |
| Async | Coroutines + Flow |
| Preferences | DataStore |
| Testing | JUnit, MockK, Turbine, MockWebServer, Compose UI Test |

## What surprised me

A few things stood out from working this way:

- **Speed.** Features that would take me a full evening to implement (data layer, repository, ViewModel, UI, tests) were done in minutes.
- **Consistency.** OpenCode kept the same style and patterns across the whole codebase. No mixed conventions, no forgotten error states.
- **Test coverage.** It didn't just write tests — it wrote *good* tests. Edge cases, error states, loading states, empty states. Things I'd normally skip or forget.
- **It remembers the whole project.** I never had to re-explain the architecture or the naming conventions. It just knew.

## The result

The app is live on F-Droid at ~3 MB, works fully offline after one sync, supports 160+ currencies with real-time search, and has 197 tests covering the critical paths. The whole thing — from blank project to published APK — was built with OpenCode as my co-developer.

If you're building an Android app and haven't tried pairing with an AI agent, I'd recommend it. It changes the pace of development entirely.

The source code is available on GitHub.
