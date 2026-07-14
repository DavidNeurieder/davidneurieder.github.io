---
layout: post
title: "Why I Built a Currency Converter That Works Without Internet"
date: 2026-05-27 10:00:00 +0200
categories: [android, travel, offline currency converter]
tags: [android, travel, offline, currency-converter, real-world, offline currency converter]
---

I travel a lot. And every trip, the same thing happens: I land somewhere, turn off airplane mode, and... nothing. No signal. No roaming. No data.

I open a currency converter app to figure out how much that taxi should cost, and it gives me a spinning circle. The app needs the internet to work. I'm standing in an airport with no roaming — the one time I actually need a currency converter — and it's useless.

This happens everywhere: on planes, on trains, in tunnels, in parking garages. Even in hotels with "free WiFi" that requires a browser login that your currency converter can't use.

## The real use cases

I built [Offline Currency Converter](https://github.com/DavidNeurieder/offline-currency-converter) for specific situations I keep finding myself in:

**You just landed.** You've arrived in a new country, you're at baggage claim, and you need to know what a fair price is for a ride into the city. You have no SIM yet, the airport WiFi requires a SMS verification you can't receive, and every converter app is showing a loading spinner. This app opens and works immediately — it already synced rates the last time you had WiFi at home.

**You're on a plane.** You're looking at the duty-free magazine and want to know if that bottle of whisky is actually a deal. No WiFi on this flight (or it costs $30). Open the app, tap two currencies, get your answer. No signal required.

**You're in a subway.** You're commuting underground and need to check a price before you buy. No signal for the next 20 minutes. The app doesn't care.

**You're traveling somewhere remote.** Hiking, camping, road tripping through areas with spotty coverage. You synced rates before you left. They're still on your phone.

**You're on a budget while traveling.** You're checking prices and want to know exactly what you're spending in your home currency. You open and close the app dozens of times a day — it should be instant, not waiting for a network request every single time.

## How it works for the user

Open the app, and you see two currency fields and a number pad. Pick your currencies, type an amount, and you get the conversion instantly. That's it.

The app remembers your recent currencies so you don't have to search for them again. It keeps your last 10 conversions visible as a history list. If rates haven't been updated recently, you'll see a small banner at the bottom: "Rates may be outdated." The conversion still shows — just with a heads-up.

There's no account to create. No sign-up. No ads. No permissions beyond internet access. It's a tool, not a platform.

## What's under the hood (briefly)

The app syncs exchange rates from the free Frankfurter API whenever you're on WiFi or mobile data — automatically, in the background. You can set the sync interval from every 6 hours to once a week. Between syncs, all conversions use the cached rates stored locally on your phone.

If you've never had internet since installing (happens more than you'd think — people install apps before trips), the app has hardcoded fallback rates for all 160+ currencies. They're not as fresh as live rates, but they're accurate enough to know if that $50 tour is reasonable.

The whole app is 3 MB. Smaller than a single photo. And it supports 14 languages natively — including Arabic right-to-left layout — so if German or Japanese or Hindi is your preferred language, the app speaks it out of the box, no download required.

## Where to get it

The app will be published on F-Droid — free, open source, no tracking. You can also grab the APK directly or build from source on GitHub.

Next time you land somewhere new and your phone has no signal, you'll have one less thing to worry about.
