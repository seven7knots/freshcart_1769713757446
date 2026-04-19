"""
Patch KJ Delivery email OTP verification flow.

Fixes three bugs causing "One of email or phone must be set":

1. Signup screen now passes the email as a route argument to the OTP screen.
2. OTP screen reads email from route args (not currentUser, which is null
   after auth.signUp() when Supabase "Confirm email" is ON).
3. OTP screen no longer double-sends on load (auth.signUp already dispatched
   the confirmation email). The Resend button now calls auth.resend(type: signup),
   the correct Supabase API for re-dispatching the signup OTP.

Run from anywhere:  python patch_otp_flow.py
"""

import sys
from pathlib import Path

ROOT = Path(r"C:\dev\kj_delivery_fresh")
SIGNUP = ROOT / "lib" / "presentation" / "authentication_screen" / "widgets" / "signup_form_widget.dart"
OTP    = ROOT / "lib" / "presentation" / "email_otp_verification_screen" / "email_otp_verification_screen.dart"


def patch(path, edits):
    """edits = [(description, old, new), ...]. Each `old` must be unique in the file."""
    raw = path.read_bytes()
    has_crlf = b"\r\n" in raw
    text = raw.decode("utf-8").replace("\r\n", "\n")
    original = text

    for desc, old, new in edits:
        n = text.count(old)
        if n == 0:
            print(f"  [FAIL] {desc}: pattern not found")
            print(f"         first 120 chars of pattern: {old[:120]!r}")
            sys.exit(1)
        if n > 1:
            print(f"  [FAIL] {desc}: pattern matched {n} times (must be unique)")
            sys.exit(1)
        text = text.replace(old, new, 1)
        print(f"  [OK]   {desc}")

    if text == original:
        print("  (no changes written)")
        return

    if has_crlf:
        text = text.replace("\n", "\r\n")
    path.write_bytes(text.encode("utf-8"))
    print(f"  saved -> {path.name}")


# ---------- Edit 1: signup form passes email as route argument ----------
print(f"\n[1/2] {SIGNUP.name}")
patch(SIGNUP, [
    (
        "Pass email as route argument to OTP screen",
        "Navigator.of(context).pushReplacementNamed(AppRoutes.emailOtpVerification);",
        "Navigator.of(context).pushReplacementNamed(\n"
        "          AppRoutes.emailOtpVerification,\n"
        "          arguments: {'email': _emailController.text.trim()},\n"
        "        );",
    ),
])


# ---------- Edit 2: OTP screen reads the arg + uses correct resend API ----------
print(f"\n[2/2] {OTP.name}")

OLD_INITSTATE = (
    "  @override\n"
    "  void initState() {\n"
    "    super.initState();\n"
    "    _loadUserEmailAndSendOtp();\n"
    "  }"
)
NEW_INITSTATE = (
    "  @override\n"
    "  void initState() {\n"
    "    super.initState();\n"
    "  }\n"
    "\n"
    "  @override\n"
    "  void didChangeDependencies() {\n"
    "    super.didChangeDependencies();\n"
    "    if (!_emailInitialized) {\n"
    "      _emailInitialized = true;\n"
    "      _initializeEmail();\n"
    "    }\n"
    "  }"
)

OLD_LOADER = (
    "  /// Load the current user's email and immediately send an OTP.\n"
    "  Future<void> _loadUserEmailAndSendOtp() async {\n"
    "    try {\n"
    "      final user = SupabaseService.client.auth.currentUser;\n"
    "      if (user != null && user.email != null) {\n"
    "        setState(() {\n"
    "          _userEmail = user.email!;\n"
    "        });\n"
    "        await _sendOtp(isInitial: true);\n"
    "      } else {\n"
    "        setState(() {\n"
    "          _isSendingInitial = false;\n"
    "          _errorMessage = AppLocalizations.of(context)!.couldNotDetermineYourEmailPlease;\n"
    "        });\n"
    "      }\n"
    "    } catch (e) {\n"
    "      debugPrint('[EMAIL_OTP] Error loading user email: $e');\n"
    "      setState(() {\n"
    "        _isSendingInitial = false;\n"
    "        _errorMessage = AppLocalizations.of(context)!.errorLoadingAccountInfoPleaseGo;\n"
    "      });\n"
    "    }\n"
    "  }"
)
NEW_LOADER = (
    "  /// Resolve the target email for verification. Priority:\n"
    "  ///   1) Route argument {'email': '...'} passed by signup flow\n"
    "  ///   2) currentUser.email (authenticated-but-unverified users)\n"
    "  /// The signup confirmation email with the 8-digit token was already\n"
    "  /// dispatched by auth.signUp() when \"Confirm email\" is ON, so we\n"
    "  /// do NOT auto-send again on screen load.\n"
    "  Future<void> _initializeEmail() async {\n"
    "    try {\n"
    "      String? email;\n"
    "      final args = ModalRoute.of(context)?.settings.arguments;\n"
    "      if (args is Map && args['email'] is String) {\n"
    "        email = (args['email'] as String).trim();\n"
    "      }\n"
    "      email ??= SupabaseService.client.auth.currentUser?.email;\n"
    "\n"
    "      if (email == null || email.isEmpty) {\n"
    "        setState(() {\n"
    "          _isSendingInitial = false;\n"
    "          _errorMessage =\n"
    "              'Could not determine your email. Please go back and sign up again.';\n"
    "        });\n"
    "        return;\n"
    "      }\n"
    "\n"
    "      setState(() {\n"
    "        _userEmail = email!;\n"
    "        _isSendingInitial = false;\n"
    "      });\n"
    "      _startCooldown();\n"
    "      debugPrint('[EMAIL_OTP] Initialized for email: $_userEmail');\n"
    "    } catch (e) {\n"
    "      debugPrint('[EMAIL_OTP] _initializeEmail error: $e');\n"
    "      setState(() {\n"
    "        _isSendingInitial = false;\n"
    "        _errorMessage = 'Error loading account info. Please go back.';\n"
    "      });\n"
    "    }\n"
    "  }"
)

OLD_SENDOTP_HEAD = (
    "  /// Send OTP using Supabase signInWithOtp \u2014 this is the correct\n"
    "  /// method that generates a verifiable 6-digit code.\n"
    "  Future<void> _sendOtp({bool isInitial = false}) async {\n"
    "    try {\n"
    "      await SupabaseService.client.auth.signInWithOtp(\n"
    "        email: _userEmail,\n"
    "        shouldCreateUser: false, // User already exists from signup\n"
    "      );\n"
    "\n"
    "      debugPrint('[EMAIL_OTP] OTP sent to $_userEmail');"
)
NEW_SENDOTP_HEAD = (
    "  /// Resend the signup confirmation OTP. Uses auth.resend(type: signup),\n"
    "  /// the correct Supabase API when \"Confirm email\" is ON.\n"
    "  Future<void> _sendOtp({bool isInitial = false}) async {\n"
    "    if (_userEmail.isEmpty) {\n"
    "      setState(() {\n"
    "        _errorMessage =\n"
    "            'No email on file. Please go back and sign up again.';\n"
    "      });\n"
    "      return;\n"
    "    }\n"
    "    try {\n"
    "      await SupabaseService.client.auth.resend(\n"
    "        type: OtpType.signup,\n"
    "        email: _userEmail,\n"
    "      );\n"
    "\n"
    "      debugPrint('[EMAIL_OTP] Resent signup OTP to $_userEmail');"
)

patch(OTP, [
    (
        "Add _emailInitialized flag",
        "  String _userEmail = '';\n",
        "  String _userEmail = '';\n  bool _emailInitialized = false;\n",
    ),
    (
        "Move email init to didChangeDependencies (ModalRoute requires context)",
        OLD_INITSTATE,
        NEW_INITSTATE,
    ),
    (
        "Replace loader: read route args, no auto-send",
        OLD_LOADER,
        NEW_LOADER,
    ),
    (
        "Swap signInWithOtp for auth.resend(type: signup)",
        OLD_SENDOTP_HEAD,
        NEW_SENDOTP_HEAD,
    ),
])

print("\nDone. Next:")
print("  flutter analyze")
print("  flutter build apk --release --target-platform android-arm64 --build-number 6")
