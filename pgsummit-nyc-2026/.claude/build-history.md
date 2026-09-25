# Build history — how this folder came together

Process notes for whoever (human or Claude Code) works on these decks next. Attendees don't need
any of this — see `../README.md` for that. See also `original-brief.md` (the initial build brief)
and `session-abstracts.md` (CFP/marketing copy) in this same folder.

## Origin

Assembled from `hour-1-beginner.md` through `hour-6-query-tuning.md` in the parent repo, per
`original-brief.md`. Nothing in the original hour-1 through hour-6 files was changed — these are
new, standalone files. Do not delete or modify the original hour files when editing this folder.

Format: same Deckset-compatible Markdown as the source decks (slide separators, `[.footer: ...]`,
`[.column]`, `^` speaker notes). Diagram image paths are `../diagrams/...` (not `diagrams/...`),
since these files live one level down from the repo root in `pgsummit-nyc-2026/`.

## Theme

All four session files (0-3) share one identical global styling block at the very top (right after
`autoscale: true`, before the first slide) — a PGSummit-branded look, not a random per-file Deckset
default. Palette pulled from the PGSummit US social graphics (dark navy background, orange and blue
accents):

- Background: dark navy `#0B1C33`
- Body text: warm off-white `#F4EFE6`
- Headers, bold emphasis, and bullet points: PGSummit orange `#F0923C`
- Italics, links, and secondary accents: light blue `#7FB3E0`
- Footer/slide-number text: muted slate-blue `#7E93B0`, small and de-emphasized so it doesn't
  compete with content

This is built entirely from Deckset's documented global configuration commands (`background-color:`,
`text:`, `header:`, `list:`, `code:`, etc. — see
[docs.deckset.com/.../configuration-commands](https://docs.deckset.com/English.lproj/Customization/01-configuration-commands.html)),
not a custom `.css` theme file, so it needs no installation — it's just part of each Markdown file
and travels with it. Because it's byte-identical across all four files, opening any of them in
Deckset gives the same consistent look; editing the block in one file and wanting it everywhere
means copying the same 15 lines into the other three (Deckset markdown has no shared-include
mechanism).

Two things worth knowing:
- `theme: Simple` picks a plain built-in Deckset theme as the base layer underneath these overrides.
  If Deckset flags "Simple" as an unrecognized theme name on your install, just delete that one
  line — every other line still fully defines the actual look (background, text, headers, code,
  lists, etc.) independent of which base theme is underneath.
- Deckset doesn't let a markdown file specify exact syntax-highlighting colors for code blocks —
  only a font and an `auto(seed)` palette picker. If the code blocks don't look right, that's the
  one piece you'd still adjust live in Deckset's own "Customize Theme" panel (View → Customize
  Theme), which is the normal, supported way to fine-tune beyond what a markdown header can pin
  down.

## Format decision

Three in-person 50-minute sessions, **talking/demo-led rather than hands-on lab work** — the
presenter runs the demos live, attendees watch rather than follow along on their own machines. The
Bluebox environment stays available throughout and afterward for attendees to explore on their own.
Because it's no longer hands-on, each session carries meaningfully more content than a lab-paced
hour would — attendees aren't spending session time typing commands, so the pace per slide is
closer to the original hour-long decks than to a stripped-down lab.

**Schedule note:** the PGSummit schedule currently lists this workshop as two session slots
("part one of two" / "part two of two"). That's not a reference to a separate, deeper follow-up
class — it's just the current slot count. These three in-person files are the plan for expanding
that to three slots; the schedule listing itself still needs to be updated to match (three parts,
not two).

## Slide counts (last check)

| # | File | Slide count |
|---|------|-------------|
| 0 | session-0-setup.md | 15 |
| 1 | session-1-getting-comfortable.md | 52 |
| 2 | session-2-dba-basics.md | 58 |
| 3 | session-3-troubleshooting-tuning.md | 56 |

Total: 181 slides — 15 in the setup PDF, 166 across the three live sessions. (Setup grew by one
slide after the first live run surfaced that GUI query tools can't run Bluebox's `psql -f` load
files — added a "Loading Data Without Local psql or a GUI Tool" fallback slide using `docker cp` +
`docker exec ... psql -f` against the container. Session 2 grew by two slides in an in-room-legibility
pass: slide 19 "Why WAL Matters for Backups: Consistency" was doing double duty — the consistency
problem *and* the PITR concept, code block, and practice bullets — so PITR got split out into its
own slide (now directly before the point-in-time-recovery.png diagram, which still follows it).
Likewise "The Connection Problem" was carrying its problem-bullets, an idle-connections query, and
the pooling bridge line all at once; the query became its own "🔧 Demo: Finding Idle Connections"
slide, matching the deck's existing demo-slide naming convention, with the "**Solution**: Connection
pooling" bridge line moved onto it as the last beat before the PgBouncer slide.)

## What changed in the second draft (vs. the original brief)

Session 0 is new, and Sessions 1-3 grew substantially once the format was confirmed as
talking/demo-led rather than hands-on:

- **Session 0 (new)**: pulled the installation walkthrough (Docker, psql client per OS, clone repo,
  create + load Bluebox, verify, troubleshooting) out of Hour 1 into its own standalone deck. Meant
  to be sent out ahead of the conference and/or pointed to at breakfast/registration for anyone who
  wants to get set up before the sessions start, and stays useful afterward for anyone revisiting
  the environment. It is **not** one of the three delivered sessions.
- **Session 1**: added Users & Permissions (roles, attributes, granting privileges, groups, role
  membership) — password-security/hashing slides were deliberately left out, since that's a deeper
  security topic than this session needs. Added the full Schemas section, and the full Object/Data
  Types section, which includes a genuine live demo: create a `customer_review` table, insert
  yourself as a customer, find a few films, insert reviews, then query them back with a join. Tool
  tour, arrays/JSONB, and window functions/CTEs are unchanged from the first draft.
- **Session 2**: added the full Upgrades and Versions section from Hour 3 (minor upgrades via
  Docker, major upgrade options, `pg_upgrade`, pre-upgrade checklist), and added an Extensions
  section pulled from Hour 1 (contrib extensions, popular third-party ones like PostGIS/pgvector/
  TimescaleDB). Logical replication's live publisher/subscriber demo was dropped entirely (too
  involved for a demo-only format) — it's now concept-only (what it is, when you'd use it).
  Connection pooling stays conversation-only by design, no demo — that was already the case in the
  first draft and remains unchanged.
- **Session 3**: biggest shift. Per updated guidance, it now pulls much more from Hour 6 (query
  tuning) than Hour 5 (performance config) — the audience gets "a few key settings" (shared_buffers,
  work_mem, maintenance_work_mem) rather than a deep memory-tuning section, and in exchange gets a
  substantial EXPLAIN section: what EXPLAIN is, reading costs, EXPLAIN ANALYZE (with the "it
  actually runs the query" warning), scan types (seq/index/index-only/bitmap) with diagrams, a join
  example, sort methods (which calls back to the work_mem slide), a light touch of
  pg_stat_statements, B-tree/GIN index before-and-after demos, an index-type summary, "when not to
  index," finding missing indexes, and the "Common Performance Patterns" section (N+1, SELECT *,
  OFFSET pagination, functions on indexed columns, OR conditions) plus the query tuning checklist.
  This made Session 3 the largest of the three at that point (63 slides) — flagged as something to
  watch on time, and later trimmed (see Flow review pass below).

## Flow review pass

A content-flow review of the second draft led to these changes (no source hour files touched):

- **Session 0**: one repo URL (`ryanbooz/postgres-full-day-training`) everywhere; the Setup Overview
  now lists the same six steps as the walkthrough, including the clone.
- **Session 1**: Schemas now come before Users & Permissions (the GRANT slides use `ON SCHEMA`),
  with `ALTER USER maria SET search_path` moved after maria is created and `\d bluebox.film` moved
  next to the Bluebox schema slide. Added a Constraints slide before the demo table and a short JOIN
  slide before the demo's join query (both from hour-2). LEAD is replaced by a RANK/PARTITION BY
  example, and the CTE slide now wraps that window function (top 2 per rating) so it actually shows
  the two together. Fixed `\x on` ("Always expanded"), the broken code fence in "Working with
  JSONB", and wrapped the array UPDATE in BEGIN/ROLLBACK so the demo data stays unchanged.
- **Session 2**: WAL is explained first; the PITR diagram now follows "Why WAL Matters".
  Incremental backups are v17+, not v18+. The small-database strategy no longer recommends pg_dump
  as the backup after calling it "not a real backup". Added `pg_verifybackup` to the manifest slide,
  `pg_basebackup -R` to the streaming replication setup, and a note that PG 14 is EOL on
  Nov 12, 2026. Removed the duplicate RPO/RTO definitions, WAL-E, the leftover topic-slide columns,
  the stale HypoPG note, and the claim that PgBouncer is already running (it needs `--profile dba`).
- **Session 3**: retitled to advertise EXPLAIN. Locks now go concept → live blocking demo → one
  `pg_blocking_pids()` query → cancel/terminate → timeouts (the raw pg_locks query, the recursive
  "source of the lock" query and the relation-only self-join are cut). pg_stat_statements moved next
  to monitoring, before EXPLAIN, merged into one slide, and is preloaded in `docker-compose.yml` so
  there is no restart mid-talk. maintenance_work_mem moved ahead of the work_mem → EXPLAIN bridge.
  Cut for time: GIN before/after pair, "Finding Missing Indexes", and the OR-conditions pattern (its
  "good" version used `EXTRACT()` on a column, the anti-pattern from the slide before). The B-tree
  "after" slide now quotes the whole plan's cost, the health check's "oldest_transaction" is a time,
  and the checklist no longer mentions covering indexes.
- New and changed query outputs were captured against a fresh Bluebox load on PostgreSQL 18.6.

## Judgment calls worth a second look

- **Session 3 length**: trimmed from 63 to 56 slides in the flow review, in line with Sessions 1
  (52) and 2 (56). pg_stat_statements was kept (merged into one slide and moved before EXPLAIN,
  since it answers "which query do I EXPLAIN?"); the GIN before/after pair, "Finding Missing
  Indexes", the OR-conditions pattern and two of the three lock queries were cut. Still the session
  most likely to run long; the next candidates to cut are the N+1 and SELECT * pattern slides.
- **Session 3's title**: retitled from "Locks, Monitoring & the Config That Matters" to "Locks,
  Monitoring, Key Config & Reading Query Plans" so it advertises the EXPLAIN/index content that is
  now about half the deck. The conference listing still needs to be updated to match.
- **Session 2's cut logical-replication demo**: the concept slides (what it is, use cases) stay, but
  the live publisher/subscriber walkthrough is gone. If a co-presenter wants it back for a
  particular audience, the full step-by-step is still intact in `hour-3-dba.md` (slides 46-53).
- **Extensions' new home**: extensions come from Hour 1 originally, but landed in Session 2 (DBA
  Basics) rather than Session 1, on the theory that "what extension do I need" is more of a DBA
  question than a beginner-SQL one. Worth confirming that placement feels right.
- **Duplicate "Cache Hit Ratio" slide**: Hour 4 and Hour 5 each have a near-identical version; kept
  Hour 4's copy in Session 3's monitoring section only, to avoid showing it twice.
- **"Hands-On" → "Demo"**: renamed the "🔧 Hands-On: ..." headers pulled into Sessions 1-3 to
  "🔧 Demo: ..." to match the talking/demo-led framing. No code or commands were changed, just the
  label.
- **Session 2's version-timeline diagram replaced with a native table**: the original Session 2
  slides 25-26 used `diagrams/postgres versions 19.png` (a hand-drawn-style dot timeline, last data
  point May 2025) plus a "Current Support Status" table. By the time of a later edit the image was
  over a year stale and PG 19 had reached public beta. Rather than redraw the image (which needs
  real historical minor-version/beta dates as a source), slide 25 became a plain markdown table — a
  same-glance "PG14 through PG19, what state is each in" status strip — with slide 26's detailed
  table still carrying exact dates, now with a PG 19 row added. The image file itself is untouched
  (it's still used by the parent repo's `hour-3-dba.md`); only this session's markdown stopped
  referencing it. **Whoever revisits this next time versions move on should just edit the two
  tables** — no image regeneration needed anymore, which was the whole point of the swap.

- **Underscore/italics rendering bug**: identifiers with underscores in plain prose (outside
  backticks or code fences) — e.g. `pg_dump/pg_restore`, or even a single bare `pg_stat_statements`
  — get mangled by Deckset's Markdown parser: it doesn't treat intraword underscores as literal the
  way CommonMark does, so two bare underscores anywhere in the same line/paragraph/list-item pair up
  and italicize whatever's between them. Fixed every instance across sessions 0-3 by wrapping
  identifiers in backticks (or backslash-escaping inside `**bold**` runs, where nested backticks
  don't play well with Deckset's bold rendering — see slide 29 of session-2). **If new prose
  mentions a `snake_case` identifier outside a code block going forward, backtick it.**
- **Repo-wide reorg: `.md` sources moved into `markdown/`**: both this folder and the parent repo's
  `full-day-training/` moved their session/hour `.md` files into a `markdown/` subfolder, so a
  visitor's first look at either course folder shows `README.md` and `slides/` (the finished PDFs),
  not a wall of Deckset source. `session-*.md` files live at `pgsummit-nyc-2026/markdown/` now, one
  level deeper than before, so their diagram references became `../../diagrams/...` (was
  `../diagrams/...`). `scripts/extract-sql.py` was updated to read from `markdown/` while still
  writing to the sibling `sql/`. The root README and this folder's README now link to `slides/*.pdf`
  as the primary artifact, with a short callout explaining `markdown/` is editable source that can
  drift from what's presented. **If you add a session file or rerun any tooling here, it lives in
  and reads from `markdown/`, not the folder root.**

## Open questions (unresolved as of last edit)

1. **Schedule slot count** — the PGSummit schedule still lists this as two session slots ("part one
   of two" / "part two of two"). Needs to be updated to three, matching sessions 1-2-3 as assembled
   here.
2. **Presenting duties** — who covers which session? Not decided yet.
3. **Session 0 distribution** — how/when it actually gets sent to attendees (emailed ahead of time?
   linked from the conference schedule page? printed at registration?). That's a logistics decision,
   not a content one.
