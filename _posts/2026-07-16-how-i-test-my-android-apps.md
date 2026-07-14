---
layout: post
title: "How to Test Your Android Apps"
date: 2026-07-16
categories: [android, opensource, testing]
tags: [android, testing, junit, compose, opencode, open-source]
---

Testing Android apps is tedious. You write a function, then you write code to verify the function works, then you run it on a device to make sure the code that verifies the function also works. It's turtles all the way down.

But the alternative is shipping bugs to users. So here's how to actually do it — practical, no theory, just the steps.

## Three layers of testing

You need three things:

1. **Unit tests** — Fast, run on your machine, test logic in isolation
2. **Instrumented tests** — Run on a device or emulator, test UI and Android-specific code
3. **Lint and type checks** — Catch obvious mistakes before they become tests

Each layer catches different bugs. Skip one and you'll ship the kind of bugs that only show up on certain devices, or only after a specific sequence of user actions.

## Layer 1: Unit tests

Unit tests verify that a function does what it says. No Android framework, no database, no network. Just input in, output out.

### Setting up

In your `app/build.gradle.kts`, make sure you have test dependencies:

```kotlin
dependencies {
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.assertj:assertj-core:3.24.2")
    testImplementation("org.mockito.kotlin:mockito-kotlin:5.1.0")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:1.7.3")
}
```

### Writing a test

Pick a function that does something meaningful. If you're building a currency converter, test the conversion math. If you're building a search engine, test the query parser.

Here's a concrete example — testing cross-rate computation:

```kotlin
class ConversionCalculatorTest {

    @Test
    fun `cross rate from non-EUR source computes correctly`() {
        // Given: EUR→USD = 0.92, EUR→JPY = 148.50
        val rates = mapOf(
            "USD" to 0.92,
            "JPY" to 148.50
        )

        // When: Converting 1 USD to JPY
        val result = rates["JPY"]!! / rates["USD"]!!

        // Then: 1 USD = 161.41 JPY
        assertThat(result).isEqualTo(161.41, within(0.01))
    }
}
```

Notice the pattern:
1. **Given** — Set up the test data
2. **When** — Call the function
3. **Then** — Verify the result

This pattern makes tests readable. When one fails, you immediately see what went wrong.

### Testing with mocks

Some functions depend on databases, APIs, or other services. Mock them:

```kotlin
class SyncUseCaseTest {

    private val repository = mock<ExchangeRateRepository>()
    private val preferences = mock<PreferencesManager>()
    private val useCase = SyncExchangeRatesUseCase(repository, preferences)

    @Test
    fun `sync skips when last sync was recent`() = runTest {
        // Given: Last sync was 1 hour ago, interval is 6 hours
        whenever(preferences.lastSyncTime).thenReturn(
            System.currentTimeMillis() - 3600_000
        )
        whenever(preferences.syncInterval).thenReturn("6h")

        // When
        useCase()

        // Then: Repository was never called
        verify(repository, never()).fetchAndStoreRates()
    }
}
```

### Running unit tests

```bash
./gradlew testDebugUnitTest
```

This runs all unit tests in about 1-3 seconds. If you're using AI to generate code, run this after every few changes. It's fast enough to be a habit.

### Common unit test patterns

**Test edge cases:**
```kotlin
@Test
fun `empty input returns zero`() {
    assertThat(convert("", "USD", "EUR")).isEqualTo(0.0)
}

@Test
fun `same currency returns same amount`() {
    assertThat(convert(100.0, "USD", "USD")).isEqualTo(100.0)
}
```

**Test error handling:**
```kotlin
@Test
fun `unknown currency throws exception`() {
    assertThrows<UnknownCurrencyException> {
        convert(100.0, "USD", "XYZ")
    }
}
```

**Test with different inputs (parameterized):**
```kotlin
@ParameterizedTest
@CsvSource("USD,EUR,0.92", "GBP,USD,1.27", "JPY,EUR,0.0067")
fun `conversion rates are correct`(
    source: String, target: String, expected: Double
) {
    assertThat(convert(1.0, source, target))
        .isCloseTo(expected, within(0.01))
}
```

## Layer 2: Instrumented tests

Instrumented tests run on a real device or emulator. They test the UI, navigation, and Android-specific behavior.

### Setting up

```kotlin
dependencies {
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
```

### Writing a Compose test

Here's how to test that a button click navigates to the right screen:

```kotlin
class NavigationTest {

    @get:Rule
    val composeTestRule = createAndroidComposeRule<MainActivity>()

    @Test
    fun tappingSearchIcon_opensSearchPage() {
        // Find and tap the search icon
        composeTestRule.onNodeWithTag("search_icon")
            .performClick()

        // Verify search page is shown
        composeTestRule.onNodeWithTag("search_input")
            .assertExists()
    }
}
```

### Testing text display

```kotlin
@Test
fun conversionShowsCorrectAmount() {
    // Type an amount
    composeTestRule.onNodeWithTag("amount_input")
        .performTextInput("100")

    // Wait for recomposition
    composeTestRule.waitForIdle()

    // Verify the result
    composeTestRule.onNodeWithTag("converted_amount")
        .assertTextContains("92")
}
```

### Testing with different configurations

```kotlin
@Test
fun rtlLayoutMirrorsCorrectly() {
    val context = InstrumentationRegistry.getInstrumentation()
        .targetContext
    val rtlContext = ContextWrapper.wrap(context, Locale("ar"))

    composeTestRule.setContent {
        MaterialTheme {
            ConvertScreen()
        }
    }

    // Verify layout is mirrored
    composeTestRule.onNodeWithTag("currency_selector")
        .assertIsDisplayed()
}
```

### Running instrumented tests

```bash
# Start an emulator first, then:
./gradlew connectedAndroidTest
```

These take longer — 2-10 minutes depending on the number of tests and emulator speed. Run them less frequently than unit tests.

### Common instrumented test patterns

**Test navigation:**
```kotlin
@Test
fun backButton_returnsToPreviousScreen() {
    composeTestRule.onNodeWithTag("settings_icon").performClick()
    composeTestRule.onNodeWithTag("back_button").performClick()
    composeTestRule.onNodeWithTag("amount_input").assertExists()
}
```

**Test list rendering:**
```kotlin
@Test
fun favoritesList_showsAllItems() {
    composeTestRule.onNodeWithTag("favorites_section")
        .onChildren()
        .assertCountEquals(5)
}
```

**Test touch interaction:**
```kotlin
@Test
fun longPressChart_showsTooltip() {
    composeTestRule.onNodeWithTag("rate_chart")
        .performTouchInput {
            longClick(center)
        }

    composeTestRule.onNodeWithTag("chart_tooltip")
        .assertExists()
}
```

## Layer 3: Lint and type checks

This isn't testing in the traditional sense, but it catches the same bugs — wrong types, unused variables, deprecated APIs.

```bash
# Lint
./gradlew lint

# Type check (if using ktlint or detekt)
./gradlew ktlintCheck
```

Run these before unit tests. They're fast and catch obvious issues.

## Putting it all together

Here's the full test workflow in one script:

```bash
#!/bin/bash
echo "Running lint..."
./gradlew lint

echo "Running unit tests..."
./gradlew testDebugUnitTest

echo "Running instrumented tests..."
./gradlew connectedAndroidTest

echo "Done!"
```

Save it as `test.sh`, make it executable (`chmod +x test.sh`), and run it before every commit.

## Using AI to generate tests

If you're using OpenCode or another AI coding tool, here's how to generate tests effectively:

1. **Describe the test case in plain language:**
   "Write a test that verifies cross-rate computation when converting from USD to JPY. The database stores EUR→USD = 0.92 and EUR→JPY = 148.50."

2. **Let the AI read your existing tests** to match the style:
   "Match the testing style in `ConversionCalculatorTest.kt`."

3. **Run the generated test:**
   ```bash
   ./gradlew testDebugUnitTest --tests "ConversionCalculatorTest.cross rate from non-EUR source computes correctly"
   ```

4. **If it fails, describe the failure:**
   "The test failed because `calculateCrossRate` expects a `RateEntity` not a `Double`. Update the test to create a `RateEntity` with the correct fields."

5. **Iterate until green.**

This works best for unit tests. For instrumented tests, you'll need to run them on a device and copy the error output back to the AI.

## What to test (and what not to)

**Test:**
- Business logic (conversion math, search parsing, data filtering)
- Database operations (insert, query, migration)
- API response parsing (JSON → data class)
- UI interactions (button clicks, navigation, text input)

**Don't test:**
- Framework code (Room, Retrofit, Compose internals)
- Simple getters/setters
- Configuration (dependency injection setup)
- Code that's trivially correct

**The rule:** If a bug in this function would cause a user to see wrong data or crash the app, test it. If the worst case is a minor visual issue, skip it.

## Common mistakes

**Writing tests that are too coupled to implementation:**
```kotlin
// Bad: Tests the implementation, not the behavior
@Test
fun `conversion calls repository then formats result`() {
    verify(repository).getRate("USD", "EUR")
    verify(formatter).format(0.92)
}

// Good: Tests the outcome
@Test
fun `converting USD to EUR returns formatted amount`() {
    val result = viewModel.convert(100.0, "USD", "EUR")
    assertThat(result).isEqualTo("92.00")
}
```

**Not cleaning up test data:**
```kotlin
@Before
fun setup() {
    database.clearAllTables() // Clean slate for each test
}
```

**Relying on real network calls:**
```kotlin
// Bad: Depends on network
val rate = api.getRate("USD", "EUR")

// Good: Mock the API
whenever(api.getRate("USD", "EUR")).thenReturn(0.92)
val rate = api.getRate("USD", "EUR")
```

**Skipping error cases:**
Always test what happens when things go wrong. Network timeout. Invalid input. Missing data. These are the bugs users actually hit.

## The bottom line

Testing isn't glamorous. It doesn't make for exciting demo videos. But it's the difference between an app that works on your phone and an app that works on everyone's phone.

Start with unit tests for your business logic. Add instrumented tests for critical UI flows. Run lint before every commit. Use AI to generate test boilerplate, but verify every line yourself.

Your users won't thank you for tests. But they'll never see the bugs you caught.

Source: [github.com/DavidNeurieder/offline-currency-converter](https://github.com/DavidNeurieder/offline-currency-converter) | [github.com/DavidNeurieder/ActivityTrace](https://github.com/DavidNeurieder/ActivityTrace)
