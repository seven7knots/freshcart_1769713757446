#!/usr/bin/env python3
"""
Migrate from Gemini to Claude:
1. Update ai_service.dart - replace GeminiClient with ClaudeClient, new system prompt
2. Update all imports from gemini_service to claude_service
3. Remove google_generative_ai from pubspec.yaml
4. Update ai_powered_search_screen.dart
"""

import os
import re

PROJECT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LIB = os.path.join(PROJECT, 'lib')

# ═══════════════════════════════════════════════════════════════
# 1. Rewrite ai_service.dart
# ═══════════════════════════════════════════════════════════════

AI_SERVICE_PATH = os.path.join(LIB, 'services', 'ai_service.dart')

with open(AI_SERVICE_PATH, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace import
content = content.replace(
    "import './gemini_service.dart';",
    "import './claude_service.dart';"
)

# Replace GeminiClient with ClaudeClient
content = content.replace('final GeminiClient _geminiClient;', 'final ClaudeClient _claudeClient;')
content = content.replace("_geminiClient = GeminiClient()", "_claudeClient = ClaudeClient()")
content = content.replace('_geminiClient.createChatCompletion(', '_claudeClient.createChatCompletion(')
content = content.replace('_geminiClient.streamContentOnly(', '_claudeClient.streamContentOnly(')

# Replace model name
content = content.replace("static const String _defaultModel = 'gemini-2.5-flash';",
                          "static const String _defaultModel = 'claude-haiku-4-5-20251001';")

# Replace the entire _buildSystemPrompt method with the new data-grounded version
old_system_prompt_start = "  String _buildSystemPrompt(Map<String, dynamic>? contextData) {"
old_system_prompt_end = "    return buffer.toString();\n  }"

# Find the method boundaries
start_idx = content.find(old_system_prompt_start)
# Find the matching end - look for "return buffer.toString();\n  }" after start
end_search_start = start_idx
end_idx = content.find("    return buffer.toString();\n  }", end_search_start)
if end_idx == -1:
    # Try alternate formatting
    end_idx = content.find("    return buffer.toString();\r\n  }", end_search_start)

if start_idx != -1 and end_idx != -1:
    end_idx += len("    return buffer.toString();\n  }")

    new_system_prompt = '''  /// Fetch ALL products and stores from Supabase for grounded AI responses
  Future<Map<String, dynamic>> _fetchAppData() async {
    final data = <String, dynamic>{'products': <Map<String, dynamic>>[], 'stores': <Map<String, dynamic>>[]};
    try {
      // Fetch all available products with store names
      final productsResult = await _supabaseClient
          .from('products')
          .select('name, price, category, description, is_available, sale_price, stores(name)')
          .eq('is_available', true)
          .order('name')
          .limit(300);
      data['products'] = (productsResult as List).map((p) => {
        'name': p['name'] ?? '',
        'price': p['price'] ?? 0,
        'category': p['category'] ?? '',
        'store_name': p['stores']?['name'] ?? '',
        'description': (p['description'] ?? '').toString().length > 80
            ? (p['description'] ?? '').toString().substring(0, 80)
            : (p['description'] ?? ''),
        'sale_price': p['sale_price'],
      }).toList();

      // Fetch all active stores
      final storesResult = await _supabaseClient
          .from('stores')
          .select('name, category, rating, is_open, prep_time, address')
          .eq('is_active', true)
          .order('rating', ascending: false)
          .limit(100);
      data['stores'] = List<Map<String, dynamic>>.from(storesResult);
    } catch (e) {
      debugPrint('[AI] Failed to fetch app data: $e');
    }
    return data;
  }

  String _buildSystemPrompt(Map<String, dynamic>? contextData) {
    final buffer = StringBuffer();

    // Get pre-fetched app data from context
    final appData = contextData?['_app_data'] as Map<String, dynamic>?;
    final products = appData?['products'] as List? ?? [];
    final stores = appData?['stores'] as List? ?? [];

    final productsJson = products.isNotEmpty
        ? products.map((p) => '- ${p['name']} | \\$${p['price']}${p['sale_price'] != null ? ' (sale: \\$${p['sale_price']})' : ''} | ${p['category']} | ${p['store_name']}').join('\\n')
        : '(No products currently in inventory)';

    final storesJson = stores.isNotEmpty
        ? stores.map((s) => '- ${s['name']} | ${s['category'] ?? 'General'} | Rating: ${s['rating'] ?? 'N/A'} | ${s['is_open'] == true ? 'Open' : 'Closed'}${s['prep_time'] != null ? ' | Prep: ${s['prep_time']}min' : ''}${s['address'] != null ? ' | ${s['address']}' : ''}').join('\\n')
        : '(No stores currently listed)';

    buffer.writeln("""You are AI Mate, the smart shopping assistant for KJ Delivery in Lebanon. You respond in the same language the user writes in (English or Arabic).

You operate in TWO modes, but ALL responses must be grounded ONLY in the app's real data below. Never use outside knowledge for products, prices, stores, or availability.

=== CURRENT APP DATA ===
PRODUCTS IN INVENTORY:
$productsJson

AVAILABLE STORES:
$storesJson

=== MODE 1: SHOPPING ASSISTANT ===
When the user asks about products, prices, availability, stores, orders, or deliveries:
- ONLY reference products and stores from the data above
- Show exact prices and store names from the data
- If a product exists in inventory, tell the user the store, price, and availability
- If a product does NOT exist in inventory, say clearly: "This item is not available on KJ Delivery yet." Do NOT make up alternatives that aren't in the data
- If the inventory has very few products, be honest: "Our marketplace currently has ${products.length} products from ${stores.length} stores. We're growing every day!"
- Never invent delivery times, fees, store hours, or promotions
- For order tracking, direct them to the Order Tracking screen

=== MODE 2: FOOD & LIFESTYLE ADVISOR ===
When the user asks about recipes, cooking tips, meal planning, nutrition advice, food storage, or dietary guidance:
- You CAN share general cooking and nutrition knowledge
- BUT always connect it back to the app's inventory: check if any ingredients mentioned are available in the products list
- If ingredients ARE available: "Great news! You can get [ingredient] from [store] for [price] on KJ Delivery"
- If ingredients are NOT available: "You'll need [ingredient] — this isn't available on KJ Delivery yet, but keep checking as we add new products regularly"
- Never recommend specific outside brands, stores, or services that aren't in the app

=== STRICT RULES ===
1. NEVER invent or hallucinate products, prices, stores, or availability data
2. NEVER reference external stores, websites, or services outside KJ Delivery
3. If you don't have enough data to answer, say so honestly instead of guessing
4. Every product mention must match an exact entry in the inventory data above
5. Be helpful, concise, friendly, and natural
6. If the inventory is empty, acknowledge it warmly and encourage the user to check back""");

    // Append session context if available
    if (contextData != null) {
      buffer.writeln('\\n--- CURRENT SESSION CONTEXT ---');
      if (contextData['user_name'] != null)
        buffer.writeln('User name: ${contextData['user_name']}');
      if (contextData['current_screen'] != null)
        buffer.writeln('User is on: ${contextData['current_screen']}');
      if (contextData['cart_items'] != null)
        buffer.writeln('Cart: ${contextData['cart_items']}');
      if (contextData['active_orders'] != null)
        buffer.writeln('Active orders: ${contextData['active_orders']}');
    }

    return buffer.toString();
  }'''

    content = content[:start_idx] + new_system_prompt + content[end_idx:]

with open(AI_SERVICE_PATH, 'w', encoding='utf-8') as f:
    f.write(content)
print("1. Rewrote ai_service.dart (Claude + data-grounded prompt)")


# ═══════════════════════════════════════════════════════════════
# 2. Update ai_provider.dart to fetch app data before every message
# ═══════════════════════════════════════════════════════════════

AI_PROVIDER_PATH = os.path.join(LIB, 'providers', 'ai_provider.dart')
with open(AI_PROVIDER_PATH, 'r', encoding='utf-8') as f:
    content = f.read()

# In sendMessage(), inject app data fetch BEFORE calling generateResponse
# Find where contextData is built and add _app_data
old_context_build = "      contextData['current_screen'] = 'AI Mate Chat';"
new_context_build = """      contextData['current_screen'] = 'AI Mate Chat';

      // Fetch ALL products + stores for data-grounded AI responses
      try {
        final appData = await _aiService.fetchAppData();
        contextData['_app_data'] = appData;
      } catch (e) {
        debugPrint('[AI] Failed to fetch app data for context: \$e');
      }"""

content = content.replace(old_context_build, new_context_build)

with open(AI_PROVIDER_PATH, 'w', encoding='utf-8') as f:
    f.write(content)
print("2. Updated ai_provider.dart (fetches app data before every message)")


# ═══════════════════════════════════════════════════════════════
# 3. Update ai_powered_search_screen.dart
# ═══════════════════════════════════════════════════════════════

SEARCH_SCREEN_PATH = os.path.join(LIB, 'presentation', 'ai_powered_search_screen', 'ai_powered_search_screen.dart')
with open(SEARCH_SCREEN_PATH, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace(
    "import '../../services/gemini_service.dart';",
    "import '../../services/claude_service.dart';"
)

content = content.replace(
    "final completion = await GeminiClient().createChatCompletion(",
    "final completion = await ClaudeClient().createChatCompletion("
)

content = content.replace(
    "model: 'gemini-2.5-flash',",
    "model: 'claude-haiku-4-5-20251001',"
)

with open(SEARCH_SCREEN_PATH, 'w', encoding='utf-8') as f:
    f.write(content)
print("3. Updated ai_powered_search_screen.dart (Claude)")


# ═══════════════════════════════════════════════════════════════
# 4. Remove google_generative_ai from pubspec.yaml
# ═══════════════════════════════════════════════════════════════

PUBSPEC_PATH = os.path.join(PROJECT, 'pubspec.yaml')
with open(PUBSPEC_PATH, 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the google_generative_ai line and its comment
content = content.replace(
    "  # AI - Google Gemini (replaces OpenAI)\n  google_generative_ai: ^0.4.6\n",
    ""
)

with open(PUBSPEC_PATH, 'w', encoding='utf-8') as f:
    f.write(content)
print("4. Removed google_generative_ai from pubspec.yaml")


# ═══════════════════════════════════════════════════════════════
# 5. Make _fetchAppData public in ai_service.dart
# ═══════════════════════════════════════════════════════════════

with open(AI_SERVICE_PATH, 'r', encoding='utf-8') as f:
    content = f.read()

# Rename _fetchAppData to fetchAppData (public) so provider can call it
content = content.replace('Future<Map<String, dynamic>> _fetchAppData()', 'Future<Map<String, dynamic>> fetchAppData()')

with open(AI_SERVICE_PATH, 'w', encoding='utf-8') as f:
    f.write(content)
print("5. Made fetchAppData() public in ai_service.dart")


# ═══════════════════════════════════════════════════════════════
# 6. Scan ALL other files for remaining gemini_service imports
# ═══════════════════════════════════════════════════════════════

print("\n6. Scanning for remaining Gemini references...")
for root, dirs, files in os.walk(LIB):
    dirs[:] = [d for d in dirs if d not in {'l10n', 'generated'}]
    for fname in files:
        if not fname.endswith('.dart'):
            continue
        filepath = os.path.join(root, fname)
        if 'claude_service.dart' in fname:
            continue  # skip our new file

        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        original = content

        # Replace any remaining gemini_service imports
        content = content.replace("import './gemini_service.dart';", "import './claude_service.dart';")
        content = content.replace("import '../gemini_service.dart';", "import '../claude_service.dart';")
        content = content.replace("import '../../services/gemini_service.dart';", "import '../../services/claude_service.dart';")
        content = content.replace("import '../../../services/gemini_service.dart';", "import '../../../services/claude_service.dart';")

        # Replace GeminiClient() references
        content = content.replace('GeminiClient()', 'ClaudeClient()')
        content = content.replace('GeminiClient ', 'ClaudeClient ')
        content = content.replace('GeminiException', 'ClaudeException')
        content = content.replace('GeminiService.', 'ClaudeService.')
        content = content.replace('GeminiService()', 'ClaudeService()')

        if content != original:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            rel = os.path.relpath(filepath, PROJECT).replace('\\', '/')
            print(f"  Updated: {rel}")

print("\n=== Migration complete! ===")
