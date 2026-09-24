# Brief: Build PGSummit NYC Workshop Session Files

## Context
This repo (`postgres-full-day-training`) contains a full-day PostgreSQL training built from six
hour-long Markdown slide decks (Deckset format), covering beginner setup through query tuning. For
PGSummit NYC (late September), we're presenting a trimmed-down version as a **3-session, 50-minutes-
each workshop**, billed as:

> "Beginning Postgres Workshop — part one of two"

The audience is people newer to *owning/operating* Postgres (not necessarily newer to SQL). The goal
is a fast, demo-driven tour — not hands-on lab work — but the Bluebox environment stays available
throughout and afterward for attendees to explore.

**Logistics note (context only, not something to build):** we'll be available informally during
breakfast/opening/keynote to help attendees get Docker + Bluebox running, so no setup time is needed
during the actual sessions.

## Task
Read the existing source files:
- `hour-1-beginner.md`
- `hour-2-sql.md`
- `hour-3-dba.md`
- `hour-4-troubleshooting.md`
- `hour-5-performance.md`

Create a new folder: `pgsummit-nyc-2026/`

Inside it, create three new Markdown files (same Deckset-compatible formatting conventions as the
source files — preserve image/diagram references, slide separators, speaker notes format, etc.):

- `session-1-getting-comfortable.md`
- `session-2-dba-basics.md`
- `session-3-troubleshooting-tuning.md`

Each file should be assembled by **pulling and lightly trimming actual slides** from the source
files per the cut list below — not written from scratch. Where a slide needs shortening (not full
cutting) to fit a 50-minute slot, trim content but preserve the original's tone, examples, and code
snippets wherever possible. Add a short title/section-divider slide at the start of each file if the
source files don't already have one per-hour, using the session titles below.

Also create `pgsummit-nyc-2026/README.md` summarizing the three sessions (titles + one-line
description each + total slide count) so it's easy to review at a glance, and noting this folder is
a work-in-progress derived from hours 1-5 for co-presenter review.

---

## Session 1: Getting Comfortable with Postgres — Tools, Arrays, JSONB & Window Functions

**Pull from:**
- `hour-1-beginner.md`: only the "tools for querying Postgres" content (psql vs. GUI clients like
  pgAdmin/DBeaver, how to pick one). Skip all setup/installation slides — that's handled informally
  at breakfast, not in this session.
- `hour-2-sql.md`: arrays, JSONB, and window functions sections. **Skip CRUD basics entirely** (too
  introductory for this slot). CTEs are optional — only include if there's room after the above,
  and preferably folded in briefly as a technique demonstrated while covering the other topics
  rather than as its own standalone block.

**Target:** ~50 minutes of content, tool tour should be brief (5-8 min equivalent).

## Session 2: Postgres DBA Basics Nobody Told You

**Pull from:**
- `hour-3-dba.md`: backups, WAL, replication, connection pooling, VACUUM — pull this hour close to
  intact, since it already maps well to a 50-minute slot.

**If trimming is needed for time:** connection pooling is the most cuttable section (or can be
condensed to a single "why you need it" slide) — it's more operational config than core DBA
understanding.

## Session 3: When Postgres Misbehaves — Locks, Monitoring & the Config That Matters

**Pull from:**
- `hour-4-troubleshooting.md`: locks and monitoring/system views sections only. **Skip** the deep
  dive into system catalog internals (pg_class/pg_stat internals beyond what's needed to explain
  monitoring) and skip detailed logging configuration — mention logging only in passing if relevant.
- `hour-5-performance.md`: memory config / shared_buffers section only. **Skip** parallel query
  internals entirely — not essential for a first-response/introductory mental model.

**Framing:** keep this introductory — a diagnostic checklist and mental model, not deep tuning
mastery. This matters because the workshop is billed as "part one of two" and part two may cover
deeper performance tuning (unconfirmed — flag this in the session-3 file as a TODO/comment if the
scope feels like it might overlap with a more advanced follow-up).

---

## Formatting / consistency requirements
- Match the existing Deckset Markdown conventions exactly (slide separators, code block style,
  image path conventions, any speaker-note syntax already used in the source files).
- Keep all code examples runnable against the Bluebox sample database as-is — don't rewrite queries,
  just select/trim which ones are included.
- Preserve original attribution/acknowledgments if present in source files.
- Do not delete or modify the original hour-1 through hour-6 files — this is a new, separate folder.

## Open questions to leave as TODO comments in the README for co-presenter review
1. What does "part two" of the workshop cover? Confirm before finalizing session 3's depth so
   content doesn't overlap with a future/advanced session.
2. Presenting duties — who covers which session?
3. Should session 1's tool tour mention where to get Bluebox running again later, for attendees who
   want to revisit at home?

## Output
When done, summarize: how many slides ended up in each session file, anything that didn't fit and
had to be cut further, and any source content that was ambiguous enough to need a judgment call.
