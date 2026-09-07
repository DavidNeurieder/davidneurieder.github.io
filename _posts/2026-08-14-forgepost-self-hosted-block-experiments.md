---
layout: post
title: "Forgepost: A Self-Hosted Blog Engine That Runs Experiments on Its Own Content"
date: 2026-08-14
categories: [opensource]
tags: [opensource, rust, self-hosting, blogging, bayesian, sqlite, axum, agpl]
description: "Forgepost is a self-hosted blogging engine built around publish → measure → experiment → improve. Every headline, paragraph, image, and call-to-action is a testable block, and a Bayesian engine decides when a variant wins."
image: /assets/images/posts/forgepost1.png
---

The big platforms shape your writing. Medium tells you which posts land. Substack tells you who finishes reading. A/B testing is how every serious growth team ships copy — but as a solo blogger you get none of that. Your analytics tool gives you pageviews; it doesn't tell you whether the new headline actually beats the old one, and even if it did, you'd never own the data or the tooling behind it.

So I built [Forgepost](https://github.com/DavidNeurieder/Forgepost): a self-hosted blogging engine whose whole point is the **publish → measure → experiment → improve** loop. It's a small blog that treats every headline, paragraph, image, and call-to-action as a measurable, testable object. You write in Markdown, publish, watch where readers drop off, then A/B test alternative content on a single block and let a Bayesian engine decide when a variant is a clear winner. Version **0.1.0** just shipped.

## A blog you can test

At its heart Forgepost is a tiny blogging engine. A Markdown editor parses your post into an immutable block tree — `heading`, `paragraph`, `image`, `quote`, `code`, `call_to_action`, `divider`. Each block is a versioned object, and that's what makes experimentation possible: an experiment is just "show some visitors a different version of one block."

Saving sets the public URL from the title while the post is still a draft; once published, the URL is stable. Publish and the post appears on the public route and the RSS feed. That part is deliberately boring — the interesting stuff happens after you publish.

## Measuring without creeping

Analytics on the web has a habit of being invasive. Forgepost takes the opposite approach: the tracking script reports **banded scroll depth** (25, 50, 75, 100%), article completion, read time, and per-block impressions through a rate-limited API. No raw scroll streams, no personal data, no third-party cookies — just enough to rebuild the reading experience afterwards.

From that you get per-article stats (views, unique readers, average reading time, completion, a scroll-depth funnel) and a per-block drop-off table: *this is exactly where readers leave.* Every estimated number is labeled as estimated, because ad blockers and JS-disabled readers are undercounted by design. A recent wave added **traffic sources** (Search / Direct / Community per article), **share tracking** (a Share button that reports click events), and **"Keep reading"** — up to three related-post cards ranked by shared tags, with impressions and clicks tracked for a future recommendation engine.

## The Bayesian engine

The interesting technical core is `forgepost-experiments`, a pure Rust crate with no I/O. When you A/B test a block, each variant gets a stable per-visitor share of traffic, and the engine tracks impressions and conversions. The goal model is deliberately single: a "completion" is a visitor who scrolled to the end of the article.

Under the hood it's a Bayesian sequential test with exact `P(beats control)` from beta posteriors, equal-tailed credible intervals, and a confidence threshold that's corrected for spending — so peeking at the results a thousand times doesn't fool the threshold the way naive repeated significance testing would. There's also a no-winner stopping rule: when a variant is near-certain to lose, the test concludes "no improvement" instead of waiting forever.

A background auto-decider polls running experiments and applies the rules automatically — promoting the winning variant once it clears the threshold, or concluding no improvement. A decision repoints the live block to the winning immutable version, so the article updates immediately. The correctness story is solid: golden tests with hand-computed beta probabilities plus property tests for posterior sanity, sample-size concentration, and assignment honesty.

## One binary, one command

Forgepost is a single Rust binary with an embedded SQLite database. There is no Node.js server in production, no separate database server, no reverse proxy required — the binary terminates HTTPS itself, either with certificates you bring or with automatic Let's Encrypt issuance and renewal via TLS-ALPN-01 (no port 80 needed for issuance). Deployment is one command:

```sh
sudo ./install.sh blog.example.com
```

That script installs build deps and Rust, clones and builds the release binary, creates a locked-down runtime user, writes the config, installs systemd units, and opens the firewall. A nightly backup service runs `forgepost export` — a JSON dump of the whole database, experiments and decisions included — alongside a tarball of your uploaded media, pruned by retention. For the release I also added deploy tests that boot the binary from the install script's own env-file keys and run the real backup script against a throwaway database, plus a check that the scripts still point at the real repository — the kind of thing that breaks silently and wakes you up at 3 a.m.

## What I'd tell myself

- **A single goal model is a feature.** One "what did the reader do at the end?" measure keeps the experiment engine simple and the dashboard honest. Custom goals can come later; the MVP is better for not having them.
- **Honest labels beat clever algorithms.** Admitting that blockers make numbers an underestimate is what makes the rest of the product trustworthy.
- **Self-hosting is the whole brand.** No telemetry, no signup to read, no third-party anything. The data is a SQLite file you can back up with `forgepost export` and delete whenever you like.

Forgepost is AGPL-3.0. The single binary is attached to the [v0.1.0 release](https://github.com/DavidNeurieder/Forgepost/releases/tag/v0.1.0), and the docs site walks through install, setup, and the experiment workflow. If you've ever wanted your own writing to get the treatment the big platforms reserve for their paying customers, give it a shot.

Source: [github.com/DavidNeurieder/Forgepost](https://github.com/DavidNeurieder/Forgepost) (AGPL-3.0)
