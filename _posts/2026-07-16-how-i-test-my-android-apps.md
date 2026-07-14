---
layout: post
title: "How I Test My Android Apps"
date: 2026-07-16
categories: [android, opensource, testing]
tags: [android, testing, junit, compose, opencode, open-source]
---

I have two Android apps on F-Droid. Both have tests. Not 100% coverage — I'm not chasing a number — but enough that I trust the code when I ship it.

Testing with AI-assisted coding is different from testing a codebase you wrote character by character. You didn't write the code, so you can't rely on intuition about where the bugs are. You need tests more, not less.

## What I test

**Unit tests** for business logic. Currency conversion math, database queries, API response parsing, search query parsing. These run fast, catch regressions, and are easy to write.

**Instrumented tests** for UI. Compose interactions, navigation, layout rendering. These run on an emulator or device, take longer, and are flakier — but they catch the things unit tests can't.

**Lint and type checks** for code quality. Not tests in the traditional sense, but they catch the same category of bugs: wrong types, unused imports, deprecated API usage.

## Offline Currency Converter

This app has about 100 unit tests and 70 instrumented tests.

The unit tests cover:

- **Conversion math** — Cross-rate computation from EUR-based rates. If USD→EUR is 0.92 and EUR→JPY is 148.5, then USD→JPY should be 148.5 / 0.92. Tests verify this for all currency pairs.
- **Database operations** — Room DAOs, migrations, insert/query/delete cycles. The app has migrations from v4 through v6, and tests verify that data survives each one.
- **Sync logic** — The `SyncExchangeRatesUseCase` decides when to sync based on interval settings, force-sync flags, and last sync time. Tests cover every combination.
- **Preferences** — Amount persistence, chart date range, favorite currencies. Simple key-value storage, but bugs here are annoying for users.

The instrumented tests cover:

- **Navigation** — Tapping the search icon goes to the search page. Tapping a category goes to the category page. Back button works correctly.
- **Currency selection** — Opening the currency picker, selecting a currency, verifying the conversion updates.
- **Chart interaction** — Long-pressing the chart shows a tooltip. The tooltip displays the correct date and rate.
- **RTL layout** — The app supports Arabic. Tests verify that the layout mirrors correctly in right-to-left mode.
- **Multi-currency view** — Converting to multiple favorites at once displays all amounts correctly.

## Activity Trace

This app has about 80 unit tests and 20 instrumented tests.

The unit tests cover:

- **Search query parsing** — Natural language queries like "yesterday signal" or "in:whatsapp july 3" get parsed into date ranges, app filters, and content type filters.
- **Database operations** — Notification capture, screen content indexing, file text extraction. SQLCipher encryption verification.
- **Retention cleanup** — Records older than the configured retention period get deleted. Tests verify the cutoff logic.

The instrumented tests cover:

- **Notification capture** — Posting a test notification and verifying it appears in the database.
- **Search results** — Typing a query and verifying the correct results appear.
- **Export** — Exporting to CSV and JSON, verifying the format is correct.

## The testing workflow with OpenCode

I don't write every test manually. Here's how it works:

1. **I describe the test case** in natural language: "Write a unit test that verifies cross-rate computation when the source currency is not EUR. Use USD as source and JPY as target. The rate from the database should be EUR→USD = 0.92 and EUR→JPY = 148.5. The result should be 148.5 / 0.92."

2. **OpenCode generates the test.** It reads the existing test files, matches the style (JUnit 4 with AssertJ, or JUnit 5 with Truth), and generates a test method that fits the pattern.

3. **I run the tests.** `./gradlew testDebugUnitTest` for unit tests. `./gradlew connectedAndroidTest` for instrumented tests.

4. **If a test fails, I describe the failure.** "The test failed because `calculateCrossRate` expects a `RateEntity` not a `Double`. Update the test to create a proper `RateEntity` with the right fields."

5. **Iterate until green.**

This works well for unit tests. The AI can see the function signatures, the data classes, the existing test patterns, and generate tests that compile and pass.

Instrumented tests are trickier. The AI can generate Compose test code, but it can't run the emulator. I run the tests, copy the failure output, and paste it back. "This test failed: `assertTextContains` expected "0.92" but found "0,92" — the device uses comma as decimal separator. Update the assertion to use the device's locale."

## What I learned

**Tests catch AI mistakes.** The AI might generate code that compiles but has subtle bugs — wrong operator, off-by-one error, missing null check. A test suite catches these before users do.

**Small functions are easier to test.** If a function does one thing, testing it is straightforward. If it does five things, you need five test cases and complex setup. I keep functions small partly for readability, partly for testability.

**Instrumented tests are fragile.** Compose tests depend on timing, animation states, and device configuration. A test that passes on a Pixel 7 might fail on a Pixel 3. I test on one device and accept that edge cases exist.

**Coverage isn't the goal.** I don't measure code coverage. I test the things that matter: business logic, data persistence, UI interactions that users perform daily. The parts I don't test are either trivially correct or not worth the maintenance cost.

**Manual testing still matters.** After all the automated tests pass, I use the app myself. Open it, convert some currencies, check the chart, tap the widget. If something feels wrong, it is.

## The test command

My full test workflow in one command:

```bash
./gradlew lint testDebugUnitTest && ./gradlew connectedAndroidTest
```

Lint first (fast, catches obvious issues). Unit tests second (fast, catches logic bugs). Instrumented tests last (slow, catches UI issues).

If all three pass, I ship it.

Source: [github.com/DavidNeurieder/offline-currency-converter](https://github.com/DavidNeurieder/offline-currency-converter) | [github.com/DavidNeurieder/ActivityTrace](https://github.com/DavidNeurieder/ActivityTrace)
