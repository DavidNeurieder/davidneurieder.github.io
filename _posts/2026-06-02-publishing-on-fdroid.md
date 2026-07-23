---
layout: post
title: "I Published an App on F-Droid!"
date: 2026-06-02
categories: [android, fdroid, reproducible-builds, offline currency converter]
tags: [android, fdroid, reproducible-builds, open-source, gpl, offline currency converter]
description: "My app Offline Currency Converter is now on F-Droid. Here's how I got through reproducible builds, metadata mistakes, and the build farm."
image: /assets/images/posts/fdroid.svg
---

🎉 It's live! My app — **Offline Currency Converter** — is now on

[<img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png"
     alt="Get it on F-Droid"
     height="80">](https://f-droid.org/packages/com.offlinecurrencyconverter.app/)

I've been building this for a while, and seeing it on F-Droid with that green badge feels amazing. It's a privacy-first currency converter that works entirely offline. No ads, no internet permission, no tracking — exactly the kind of app F-Droid was made for.

Getting onto F-Droid was a fun ride with a few bumps along the way. Here's the story.

## How F-Droid Works

F-Droid is brilliant: they build every app from source themselves. You just submit metadata and a git tag. Their servers clone your repo, build the APK, and — if it matches your local build byte-for-byte — it's published. No APK uploads, no shady binaries.

The steps:

1. **Add metadata** — A `fastlane/metadata/android/` directory with descriptions, screenshots, feature graphic, and changelogs.
2. **Create a build recipe** — Submit a PR to the [`fdroiddata`](https://gitlab.com/fdroid/fdroiddata) repo with a YAML entry pointing to your repo.
3. **Get reviewed** — The F-Droid maintainers check everything and merge.
4. **Build farm does its magic** — The app gets built and published.

From PR merge to appearing in the F-Droid client: about **2 days**. That's incredible.

## Oops: My Metadata Was Invisible

If you check version 0.1.0 on F-Droid, you'll see the app icon, feature graphic, and screenshots are all missing. The app works fine, but the store page looks embarrassingly bare.

Why? I put my `fastlane/` directory inside **`app/fastlane/`** instead of at the project root. F-Droid's build system only looks for `fastlane/metadata/android/` at the root of the repo. My metadata was invisible!

Easy fix: move `fastlane/` to the root. Next build, everything should show up. 

## The Reproducible Build Headache

F-Droid requires the APK they build to be **byte-for-byte identical** to yours. It's a great security practice — if anyone tampered with your source, the hashes wouldn't match.

My first build attempt failed. Their APK was different from mine. After digging in, the culprit was **`classes2.dex`**.

The cause? **Baseline profiles**. The Android Gradle Plugin includes baseline profile files (`baseline.prof`, `baseline.profm`) under `/assets/dexopt/`. These embed non-deterministic metadata like timestamps, which made `classes2.dex` differ between builds.

The fix was one line:

```kotlin
// app/build.gradle.kts
packaging {
    resources {
        excludes += "/assets/dexopt/*"
    }
}
```

One exclusion rule and the problem vanished. What a relief!

## More Tips for a Deterministic Build

Here's the full checklist I ended up with:

- **Disable R8/ProGuard** — `isMinifyEnabled = false`. R8 can produce non-deterministic output.
- **Strip VCS info** — `vcsInfo.include = false`. Build metadata differs between environments.
- **Disable dependency info** — `dependenciesInfo.includeInApk = false`.
- **Disable build cache** — `org.gradle.caching = false` in `gradle.properties`.
- **Add `.gitattributes`** — `* text=auto eol=lf` with `*.png binary`. Line endings will break reproducibility.
- **Use the Gradle wrapper** — Pin the exact Gradle version.
- **Use apksigner 34** — apksigner 35+ produces non-deterministic signatures. Compare unsigned APKs to be safe.

The moment of truth — build twice and compare:

```bash
./gradlew clean assembleRelease
cp app/build/outputs/apk/release/app-release-unsigned.apk /tmp/apk-1.apk
./gradlew clean assembleRelease
cp app/build/outputs/apk/release/app-release-unsigned.apk /tmp/apk-2.apk
sha256sum /tmp/apk-*.apk
```

When the hashes match... **chef's kiss**.

## It's Live!

After fixing the metadata location and the baseline profile issue, the F-Droid maintainers merged my recipe. A couple of days later, the app appeared in the F-Droid client with full metadata, screenshots, and the green badge on my README.

**That feeling when you search your own app and it shows up? Unreal.**

[**Get it on F-Droid**](https://f-droid.org/packages/com.offlinecurrencyconverter.app/)

Source code on [GitHub](https://github.com/anomalyco/offline-currency-converter) under AGPL-3.0.

If you're thinking of publishing your own app on F-Droid — **do it**. The process is rewarding, the community is amazing, and nothing beats seeing your app on that green badge. Go for it!
