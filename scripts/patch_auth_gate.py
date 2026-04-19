#!/usr/bin/env python3
"""Patch auth_gate_screen.dart to add language selection check before onboarding."""

import os

FILE_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    'lib', 'presentation', 'auth_gate_screen', 'auth_gate_screen.dart'
)

with open(FILE_PATH, 'r', encoding='utf-8') as f:
    content = f.read()

# Add import for locale_provider
old_import = "import '../../services/supabase_service.dart';"
new_import = """import '../../services/supabase_service.dart';
import '../../providers/locale_provider.dart';"""
content = content.replace(old_import, new_import)

# Add language check before onboarding check
old_onboarding_check = """    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;"""

new_onboarding_check = """    // ── Language selection check (first launch) ──
    try {
      final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
      if (!localeProvider.hasChosenLanguage) {
        final hasSession = Supabase.instance.client.auth.currentSession != null;
        if (!hasSession && mounted && !_navigated) {
          debugPrint('[AUTH_GATE] No language chosen -> language selection');
          _navigated = true;
          Navigator.pushReplacementNamed(context, AppRoutes.languageSelection);
          return;
        } else {
          // Existing user updating app — mark language as chosen
          await localeProvider.markLanguageChosen();
        }
      }
    } catch (e) {
      debugPrint('[AUTH_GATE] Language check failed: $e');
    }

    if (!mounted || _navigated) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;"""

content = content.replace(old_onboarding_check, new_onboarding_check)

with open(FILE_PATH, 'w', encoding='utf-8') as f:
    f.write(content)

print("auth_gate_screen.dart patched successfully")
