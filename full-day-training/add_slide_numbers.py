#!/usr/bin/env python3
"""
Add slide numbers to Deckset markdown files.

Usage: python3 add_slide_numbers.py

This script adds "[.footer: Slide X / Y]" to each slide in the hour-*.md files.
The footer directive is placed after [.background-color: ...] if present.
Run this script whenever slides are added or removed to update the numbering.
"""

import re

def add_slide_numbers(filename):
    with open(filename, 'r') as f:
        content = f.read()
    
    # Remove any existing [.footer: Slide X / Y] lines
    content = re.sub(r'\[\.footer: Slide \d+ / \d+\]\n', '', content)
    
    # Split by slide separator
    slides = re.split(r'\n---\n', content)
    total = len(slides)
    
    new_slides = []
    for i, slide in enumerate(slides, 1):
        slide = slide.rstrip()
        
        # Check if slide has [.background-color: ...] directive
        bg_match = re.search(r'(\[\.background-color: #[A-Fa-f0-9]+\])', slide)
        
        if bg_match:
            # Insert footer after background-color directive
            insert_pos = bg_match.end()
            slide = slide[:insert_pos] + f'\n[.footer: Slide {i} / {total}]' + slide[insert_pos:]
        else:
            # Add footer at the beginning of the slide (after any leading newlines)
            slide = slide.lstrip('\n')
            slide = f'[.footer: Slide {i} / {total}]\n\n' + slide
        
        new_slides.append(slide)
    
    new_content = '\n---\n'.join(new_slides)
    
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
        'hour-6-query-tuning.md'
    ]
    for f in files:
        add_slide_numbers(f)
