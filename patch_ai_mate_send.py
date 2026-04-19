"""Issue 3: AI Mate send button reflects input state.

Targeted replacement — file is 761 lines (>500 rule threshold).
"""
from pathlib import Path

ROOT = Path(__file__).resolve().parent
FILE = ROOT / 'lib/presentation/ai_chat_assistant_screen/ai_chat_assistant_screen.dart'

s = FILE.read_text(encoding='utf-8')

# 1) Drop pre-computed sendBg / sendIcon locals (replaced by listenable logic).
old_colors = """    final Color hintColor = isLight ? Colors.grey.shade500 : Colors.white.withOpacity(0.35);
    final Color sendBg = isLight
        ? (isDisabled ? Colors.grey.shade300 : Colors.grey.shade400)
        : (isDisabled ? Colors.white.withOpacity(0.06) : Colors.white.withOpacity(0.12));
    final Color sendIcon = isLight
        ? (isDisabled ? Colors.grey.shade500 : Colors.white)
        : (isDisabled ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.8));
"""

new_colors = """    final Color hintColor = isLight ? Colors.grey.shade500 : Colors.white.withOpacity(0.35);
    final Color sendInactiveBg =
        isLight ? Colors.grey.shade400 : Colors.white.withOpacity(0.12);
    final Color sendInactiveIcon =
        isLight ? Colors.grey.shade600 : Colors.white.withOpacity(0.35);
"""

if old_colors not in s:
    raise SystemExit("chat: sendBg/sendIcon block not found verbatim")
s = s.replace(old_colors, new_colors)

# 2) Wrap the Send button in ValueListenableBuilder listening to the controller.
old_send = """            // Send button
            GestureDetector(
              onTap: isDisabled ? null : _sendMessage,
              child: Padding(
                padding: const EdgeInsets.only(right: 6, bottom: 6, top: 6),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: sendBg,
                  ),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: sendIcon,
                    size: 18,
                  ),
                ),
              ),
            ),"""

new_send = """            // Send button — reacts to controller text AND disabled state.
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _messageController,
              builder: (context, value, _) {
                final bool hasText = value.text.trim().isNotEmpty;
                final bool isActive = !isDisabled && hasText;
                final Color bg =
                    isActive ? const Color(0xFFE50913) : sendInactiveBg;
                final Color fg =
                    isActive ? Colors.white : sendInactiveIcon;
                return GestureDetector(
                  onTap: isActive ? _sendMessage : null,
                  child: Padding(
                    padding:
                        const EdgeInsets.only(right: 6, bottom: 6, top: 6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bg,
                      ),
                      child: Icon(
                        Icons.arrow_upward_rounded,
                        color: fg,
                        size: 18,
                      ),
                    ),
                  ),
                );
              },
            ),"""

if old_send not in s:
    raise SystemExit("chat: send button block not found verbatim")
s = s.replace(old_send, new_send)

FILE.write_text(s, encoding='utf-8')
print(f"patched {FILE.relative_to(ROOT)}")
