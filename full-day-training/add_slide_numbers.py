#!/usr/bin/env python3
"""
Add slide numbers to Deckset markdown files.

Usage: python3 add_slide_numbers.py

This script adds "[.footer: Slide X / Y]" to each slide in the markdown/hour-*.md files.
Slide 1 may start with a block of global Deckset config lines (autoscale: true, theme: ...,
background-color: ..., etc.) before any real content -- the footer is inserted after that
block, not before it. Every other slide gets the footer at the very top.
Run this script whenever slides are added or removed to update the numbering.
"""

import re
from pathlib import Path

MARKDOWN_DIR = Path(__file__).parent / "markdown"

CONFIG_LINE = re.compile(r'^[A-Za-z][\w-]*:\s')


def add_slide_numbers(filename):
    with open(filename, 'r') as f:
        content = f.read()

    # Remove any existing [.footer: Slide X / Y] lines
    content = re.sub(r'[ \t]*\[\.footer: Slide \d+ / \d+\]\n', '', content)

    # Split by slide separator
    slides = re.split(r'\n---\n', content)
    total = len(slides)

    new_slides = []
    for i, slide in enumerate(slides, 1):
        slide = slide.strip('\n')
        footer = f'[.footer: Slide {i} / {total}]'

        if i == 1:
            # Find the leading run of "key: value" global config lines, if any,
            # and insert the footer after that block instead of before it.
            lines = slide.split('\n')
            split_at = 0
            while split_at < len(lines) and CONFIG_LINE.match(lines[split_at]):
                split_at += 1
            config_block = '\n'.join(lines[:split_at])
            rest = '\n'.join(lines[split_at:]).lstrip('\n')
            if config_block:
                slide = f'{config_block}\n\n{footer}\n\n{rest}'
            else:
                slide = f'{footer}\n\n{rest}'
        else:
            slide = f'{footer}\n\n{slide}'

        new_slides.append(slide)

    new_content = '\n\n---\n\n'.join(new_slides) + '\n'

    with open(filename, 'w') as f:
        f.write(new_content)

    print(f"{filename}: Added slide numbers (1-{total})")


if __name__ == '__main__':
    files = [
        'hour-1-beginner.md',
        'hour-2-sql.md',
        'hour-3-dba.md',
        'hour-4-troubleshooting.md',
        'hour-5-performance.md',
        'hour-6-query-tuning.md',
    ]
    for f in files:
        add_slide_numbers(MARKDOWN_DIR / f)
