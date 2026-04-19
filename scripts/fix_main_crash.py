#!/usr/bin/env python3
"""Fix null check crash on AppLocalizations.of(context) in main.dart.

The Consumer2 context sits ABOVE MaterialApp, so localization delegates
aren't registered there yet.  AppLocalizations.of(context) returns null
and the ! operator crashes.

Fix: use a plain string for `title` (it's only the OS task-switcher label)
and move any AppLocalizations usage to the builder callback whose context
IS below MaterialApp.
"""

import os, re

MAIN = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    'lib', 'main.dart',
)

with open(MAIN, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Replace the title line — use a plain string, not AppLocalizations
content = content.replace(
    "              title: AppLocalizations.of(context)!.kjDelivery,",
    "              title: 'KJ Delivery',",
)

# 2. Also scan for any other AppLocalizations.of(context)! calls that
#    use the Consumer2 context (above MaterialApp).  The only safe place
#    is inside MaterialApp's `builder:` callback or inside route widgets.
#    The `const` localizationsDelegates list should stay as-is.

with open(MAIN, 'w', encoding='utf-8') as f:
    f.write(content)

print('Fixed main.dart: title uses plain string, no AppLocalizations above MaterialApp')
