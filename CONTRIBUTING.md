# Contributing to PostgreSQL Full Day Training

Thank you for your interest in contributing! This project welcomes contributions from the PostgreSQL community.

## Ways to Contribute

- **Fix errors:** Typos, incorrect SQL, outdated information
- **Improve clarity:** Better explanations, additional examples
- **Add content:** New topics, diagrams, exercises
- **Report issues:** Found something confusing or broken? Let us know

## Getting Started

### 1. Fork the Repository

Click the "Fork" button on GitHub to create your own copy.

### 2. Clone Your Fork

```bash
git clone https://github.com/YOUR-USERNAME/postgres-full-day-training.git
cd postgres-full-day-training
```

### 3. Create a Branch

```bash
git checkout -b fix/typo-in-hour-2
# or
git checkout -b feature/add-partitioning-example
```

Use a descriptive branch name:
- `fix/` for corrections
- `feature/` for new content
- `docs/` for documentation improvements

### 4. Make Your Changes

Edit the relevant `.md` files. See [Slide Format](#slide-format) below for guidelines.

### 5. Test Your Changes

- Verify SQL examples work against the Bluebox database
- Check that slides render correctly in Deckset (if available)
- Run the slide numbering script if you added/removed slides (from the course folder you edited,
  e.g. `full-day-training/`):

```bash
python3 add_slide_numbers.py
```

### 6. Commit Your Changes

```bash
git add .
git commit -m "Fix typo in JOIN example"
```

Write clear commit messages:
- Start with a verb (Fix, Add, Update, Remove)
- Keep the first line under 50 characters
- Add details in the body if needed

### 7. Push to Your Fork

```bash
git push origin fix/typo-in-hour-2
```

### 8. Open a Pull Request

1. Go to the original repository on GitHub
2. Click "Pull Requests" → "New Pull Request"
3. Click "compare across forks"
4. Select your fork and branch
5. Fill out the PR template
6. Submit!

## Slide Format

Slides use [Deckset](https://www.deckset.com/) Markdown format:

```markdown
---

[.background-color: #336791]
[.footer: Slide X / Y]

# Slide Title

Content goes here

```sql
-- SQL examples in fenced code blocks
SELECT * FROM example;
```
```

### Guidelines

- **One concept per slide** - Keep slides focused
- **Working SQL** - All examples should run against Bluebox
- **No excessive comments** - Let the code speak; explain verbally
- **Consistent colors** - Use existing background colors for topic continuity

### Slide Colors by Topic

| Topic | Color |
|-------|-------|
| General/Intro | `#336791` (Postgres blue) |
| CRUD/SQL basics | `#8B4513` |
| JOINs | `#006400` |
| Arrays/JSON | `#191970` |
| Window functions | `#800020` |
| CTEs | `#CC5500` |
| Extensions | `#556B2F` |

## SQL Guidelines

- Use the `bluebox` schema: `bluebox.film`, `bluebox.customer`, etc.
- Test all queries before submitting
- Include expected output where helpful
- Prefer realistic examples over contrived ones

## Adding New Slides

Applies to the `full-day-training/` course; run these from inside that folder.

1. Add your content in the appropriate hour file
2. Run `python3 add_slide_numbers.py` to update all slide numbers
3. Run the separator fix if needed:

```bash
python3 -c "
import re
for f in ['hour-1-beginner.md', 'hour-2-sql.md', 'hour-3-dba.md', 
          'hour-4-troubleshooting.md', 'hour-5-performance.md', 'hour-6-query-tuning.md']:
    with open(f, 'r') as file:
        content = file.read()
    content = re.sub(r'\n+---\n+', '\n\n---\n\n', content)
    with open(f, 'w') as file:
        file.write(content)
"
```

## Pull Request Guidelines

- **One topic per PR** - Makes review easier
- **Describe the change** - What and why
- **Reference issues** - Use "Fixes #123" if applicable
- **Be patient** - Maintainers review as time allows

## Code of Conduct

Be respectful and constructive. We're all here to learn and share knowledge about PostgreSQL.

## Questions?

- Open an issue for general questions
- Tag maintainers if you need guidance on a contribution

Thank you for helping make PostgreSQL education better for everyone!
