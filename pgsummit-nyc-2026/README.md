# PGSummit NYC 2026 — "Beginning Postgres Workshop"

**Status: work in progress**, assembled from `hour-1-beginner.md` through `hour-6-query-tuning.md`
in the parent repo for co-presenter review. Nothing in the original hour-1 through hour-6 files was
changed — these are new, standalone files.

Format: same Deckset-compatible Markdown as the source decks (slide separators, `[.footer: ...]`,
`[.column]`, `^` speaker notes). Diagram image paths are `../diagrams/...` (not `diagrams/...`),
since these four files live one level down from the repo root in `pgsummit-nyc-2026/`.

## Theme

All four files share one identical global styling block at the very top (right after
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

Three in-person 50-minute sessions, **talking/demo-led rather than hands-on lab work** — the
presenter runs the demos live, attendees watch rather than follow along on their own machines. The
Bluebox environment stays available throughout and afterward for attendees to explore on their own.
Because it's no longer hands-on, each session carries meaningfully more content than a lab-paced
hour would (see slide counts below) — attendees aren't spending session time typing commands, so
the pace per slide is closer to the original hour-long decks than to a stripped-down lab.

**Schedule note:** the PGSummit schedule currently lists this workshop as two session slots
("part one of two" / "part two of two"). That's not a reference to a separate, deeper follow-up
class — it's just the current slot count. These three in-person files are the plan for expanding
that to three slots; the schedule listing itself still needs to be updated to match (three parts,
not two).

## Sessions

| # | File | Delivered how | Title | One-line description | Slide count |
|---|------|----------------|-------|----------------------|--------------|
| 0 | [session-0-setup.md](session-0-setup.md) | Sent ahead of time / pointed to on-site — **not a live session** | Get Set Up: PostgreSQL + Bluebox | Docker, psql client install, and loading Bluebox — the installation steps from Hour 1, so no setup time is needed during the three live sessions | 14 |
| 1 | [session-1-getting-comfortable.md](session-1-getting-comfortable.md) | Live, in-person | Getting Comfortable with Postgres — Tools, Users, Schemas, Objects, Arrays, JSONB & Window Functions | A tool tour, then users/roles/permissions, schemas, and data types/objects (with a live create-and-query demo), then arrays, JSONB, and window functions, with CTEs folded in as a technique | 50 |
| 2 | [session-2-dba-basics.md](session-2-dba-basics.md) | Live, in-person | Postgres DBA Basics Nobody Told You | Backups, WAL/PITR, minor & major version upgrades, replication concepts (streaming & logical), connection pooling, VACUUM, and extensions | 56 |
| 3 | [session-3-troubleshooting-tuning.md](session-3-troubleshooting-tuning.md) | Live, in-person | When Postgres Misbehaves — Locks, Monitoring & the Config That Matters | Locks/blocking, finding and stopping bad queries, monitoring essentials, a few key memory settings, and — the bulk of the session — reading query plans with EXPLAIN, index basics, and common performance patterns | 63 |

**Total: 183 slides** — 14 in the setup PDF, 169 across the three live sessions.

## What changed in this pass (vs. the original brief)

This is the second draft. Session 0 is new, and Sessions 1–3 grew substantially now that the format
is confirmed as talking/demo-led rather than hands-on:

- **Session 0 (new)**: pulled the installation walkthrough (Docker, psql client per OS, clone repo,
  create + load Bluebox, verify, troubleshooting) out of Hour 1 into its own standalone deck. This
  is meant to be sent out ahead of the conference and/or pointed to at breakfast/registration for
  anyone who wants to get set up before the sessions start, and it stays useful afterward for
  anyone revisiting the environment. It is **not** one of the three delivered sessions.
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
- **Session 3**: this is where the biggest shift happened. Per updated guidance, it now pulls much
  more from Hour 6 (query tuning) than Hour 5 (performance config) — the audience gets "a few key
  settings" (shared_buffers, work_mem, maintenance_work_mem) rather than a deep memory-tuning
  section, and in exchange gets a substantial EXPLAIN section: what EXPLAIN is, reading costs,
  EXPLAIN ANALYZE (with the "it actually runs the query" warning), scan types (seq/index/index-only/
  bitmap) with diagrams, a join example, sort methods (which calls back to the work_mem slide), a
  light touch of pg_stat_statements, B-tree/GIN index before-and-after demos, an index-type summary,
  "when not to index," finding missing indexes, and the "Common Performance Patterns" section
  (N+1, SELECT *, OFFSET pagination, functions on indexed columns, OR conditions) plus the query
  tuning checklist. This makes Session 3 the largest of the three (63 slides) — flagged below as
  something to watch on time.

## Judgment calls worth a second look

- **Session 3 length**: at 63 slides it's noticeably bigger than Sessions 1 (50) and 2 (56). Given
  it's demo-led rather than hands-on, that may be fine, but it's the one most likely to run long.
  If it needs trimming, the most cuttable material (each flagged with a `^` speaker note in-file)
  is: the pg_stat_statements slide, the GIN index before/after pair (keeping just B-tree), and the
  "Finding Missing Indexes" slide.
- **Session 3's title** ("Locks, Monitoring & the Config That Matters") predates this expansion —
  it still technically fits (EXPLAIN/indexes are arguably part of "the config that matters" in a
  loose sense) but doesn't advertise the EXPLAIN/query-plan content that's now the largest chunk of
  the session. Worth deciding whether to retitle (e.g., adding "& Reading Query Plans") or leave it,
  since it's already the billed title.
- **Session 2's cut logical-replication demo**: the concept slides (what it is, use cases) stay, but
  the live publisher/subscriber walkthrough is gone. If a co-presenter wants it back for a
  particular audience, the full step-by-step is still intact in `hour-3-dba.md` (slides 46-53).
- **Extensions' new home**: extensions come from Hour 1 originally, but landed in Session 2 (DBA
  Basics) rather than Session 1, on the theory that "what extension do I need" is more of a DBA
  question than a beginner-SQL one. Worth confirming that placement feels right.
- **Duplicate "Cache Hit Ratio" slide**: Hour 4 and Hour 5 each have a near-identical version; kept
  Hour 4's copy in Session 3's monitoring section only, to avoid showing it twice.
- **"Hands-On" → "Demo"**: renamed the "🔧 Hands-On: ..." headers pulled into Sessions 1–3 to
  "🔧 Demo: ..." to match the talking/demo-led framing. No code or commands were changed, just the
  label.

## Open questions for co-presenter review (TODO)

1. ~~What does "part two" cover?~~ **Resolved** — "part two" is just the second of the two session
   slots currently on the PGSummit schedule for this same workshop, not separate advanced content.
   We're expanding to three slots total to match these three files. Remaining action item: get the
   actual schedule listing updated from two slots to three, and confirm the slot order matches
   session 1 → 2 → 3 as assembled here.
2. **Presenting duties** — who covers which session? Not decided yet.
3. ~~Should Session 1's tool tour mention where to (re-)get Bluebox running?~~ **Addressed** —
   Session 0 (the standalone setup guide) now exists for exactly this. Session 1 has a speaker note
   pointing back to it. Still open: how/when Session 0 actually gets distributed (emailed ahead of
   time? linked from the conference schedule page? printed at registration?) — that's a logistics
   decision, not a content one.
4. **New: Session 3's size and title** — see the judgment-calls section above. Worth a quick
   go/no-go on trimming and on whether the session title should be updated to reflect the EXPLAIN/
   index content now making up roughly half the deck.
