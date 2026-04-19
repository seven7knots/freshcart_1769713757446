#!/usr/bin/env python3
r"""
KJ Delivery - Add store logo thumbnail to customer store detail hero
Run from: C:\dev\kj_delivery_fresh
Usage: C:\Python314\python.exe fix_store_hero_logo.py
"""

import os

path = r"lib\presentation\store_detail_screen\store_detail_screen.dart"

with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old = """      flexibleSpace: FlexibleSpaceBar(
        title: Text(_store!.name, style: const TextStyle(fontWeight: FontWeight.w700, shadows: [Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 4)])),"""

new = """      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsetsDirectional.only(start: 56, bottom: 12, end: 56),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4.5),
                child: _store!.imageUrl != null && _store!.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(imageUrl: _store!.imageUrl!, fit: BoxFit.cover, memCacheWidth: 64,
                        errorWidget: (_, __, ___) => Container(color: Colors.white24,
                          child: const Icon(Icons.store, size: 14, color: Colors.white70)))
                    : Container(color: Colors.white24,
                        child: const Icon(Icons.store, size: 14, color: Colors.white70)),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _store!.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, shadows: [Shadow(color: Colors.black45, offset: Offset(0, 1), blurRadius: 4)]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),""" 

if old in content:
    content = content.replace(old, new, 1)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("FIXED: Added store logo thumbnail to customer store hero")
    print("  - 30x30 rounded logo left of store name")
    print("  - Row uses MainAxisSize.min (no overflow)")
    print("  - Flexible + maxLines:1 + ellipsis on name")
    print("  - titlePadding avoids back button & action icons")
else:
    print("ERROR: Pattern not found.")
    # Check if already patched
    if "MainAxisSize.min" in content and "_store!.imageUrl" in content:
        print("File may already be patched from a previous run.")
    else:
        print("File structure may have changed.")
