# Authentication UX Research Report — Mobile Apps (Flutter)

> Compiled May 2026 from Auth0 Trends Report, FIDO Alliance, W3C WCAG 2.2, MojoAuth, Corbado Benchmark, OWASP, and production UX research.

---

## 1. Top Pain Points

### 1.1 Long Forms (the #1 killer)
- **62%** of users cite long signup/login forms as the most frustrating auth experience (Auth0 2025)
- Each additional form field reduces conversion by **~10-15%** (Fogg behavioral model)
- Time-to-authenticated: password flow = **30-40s**, passkey = **<5s**, magic link = **<30s**
- **Mandate:** email-only as minimum. Use progressive profiling — ask for more after value is demonstrated.

### 1.2 Password Burden
- **78%** of users forget a password monthly
- **68%** reuse passwords across accounts
- **25%** abandon account creation when required to set a password (industry baseline)
- **42%** abandon when forced through a password reset flow
- **21%** abandon a purchase specifically because they forgot credentials

### 1.3 Friction at Every Step
- SMS OTP: 20-35s, requires app-switch on mobile, carrier delivery failures for **8-20%** of international users
- Adding TOTP as second factor: **4-11%** drop-off per step
- Password reset: 2-5 minute process that destroys checkout/onboarding momentum
- **88%** of users will not return after a bad login experience

### 1.4 Passkey Inconsistency (current state)
- Passkey UX is fragmented across OS/browser — iOS succeeds at **49-83%** first-try enrollment, Windows only **25-39%**
- Users report confusion because passkeys don't replace all steps — they still hit OTP screens
- Passkey enrollment below **5%** without device-aware orchestration
- Cross-device flow (QR bridging) adds its own friction

---

## 2. Best-in-Class Auth UX Patterns

| Source | Pattern | Key Insight |
|--------|---------|-------------|
| **Superhuman** | Email-only magic link + device trust | No password field exists. Device fingerprint removes repeat auth. |
| **Duolingo** | Social login pushed first, progressive profile | Asks for email/Google/Apple only. Adds detail later via gamification. |
| **Shopify** | Passkey at checkout | 5% lift in checkout conversion among passkey enrollees. 6x reduction in sign-in time. |
| **Amazon** | Passkey-first on enrolled devices | 6x sign-in time reduction after passkey rollout. |
| **Clerk / Stytch** | Conditional UI autofill (passkey) | Passkey surfaces in autofill without explicit button. No cognitive load. |
| **Google** | Verified Email (Android Credential Manager) | Bypasses email OTP entirely. No app-switch. But only works for Gmail. |
| **Auth0/Descope** | Device-aware passkey orchestration | Segments users by OS, browser, credential provider. Avoids dead-end ceremonies. |

### Key Patterns to Steal

**A. Passkey-first with orchestration**
- Detect device capabilities before showing UI
- Conditional create (auto-register passkey after password sign-in)
- One-tap return for recognized devices
- Magic link fallback for incompatible devices

**B. Social login baked in, not bolted on**
- Google + Apple minimum (Apple Sign-In mandatory if any social login on iOS)
- **71%** of 18-25 prefer social login
- Case study: social login usage grew from **10% → 29%** in 2 months; password use dropped **61%**

**C. No password fields until necessary**
- Email → magic link or social login
- Password is a fallback, not primary
- Passkey enrollment prompt: **second login** (highest conversion) and **password reset** (18-34% enrollment)

**D. Progressive profiling**
- Start with email/phone only
- Ask for name, avatar, preferences **after** user sees core value
- Avoids the "information tax" problem — users provide data when they trust the product

---

## 3. Edge Cases & Failure States

### 3.1 Account Recovery (hardest problem)
- Device loss: passkey stored on lost phone = locked out
- **Required:** at least two recovery factors enrolled (verified email + TOTP)
- Rate-limit recovery attempts aggressively
- Manual support path for high-value accounts
- **Don't** sunset passwords until **60%+** of active users have enrolled a passkey

### 3.2 Token & Session Edge Cases
| Scenario | Impact |
|----------|--------|
| Expired reset link | User can't recover; opens support ticket |
| Multiple reset requests | Confusion — which link is valid? |
| Reset email in spam | Silent failure — user thinks system is broken |
| Session expiration mid-flow | Data loss, re-entry required |
| Concurrent sessions across devices | Inconsistent state, logout surprise |
| Clock skew | JWT validation fails, token claims mistimed |
| Refresh token reuse | Security flag but UX must handle gracefully |

### 3.3 Auth Provider Failures
- Social login provider downtime → user can't log in at all
- SMS carrier failures → **8-20%** OTP non-delivery internationally
- OAuth redirect URI mismatches → silent redirect failures
- Passkey WebAuthn errors: **~11%** fail on first attempt even with good orchestration

### 3.4 Account State Edge Cases
- Disabled/suspended users need clear messaging (without revealing security detail)
- Unverified email → blocked from value
- Role/permission changes mid-session → confusing
- Name/email changes → login identity mismatch

### 3.5 Security-Legitimate Friction Tradeoffs
- Lockout thresholds: too low = user denial of service; too high = brute force risk
- OWASP: generic errors for security, but UX suffers — user doesn't know *what* to fix
- **Solution:** generic message + clear actionable path (e.g., "reset your password" vs "wrong password")

---

## 4. Accessibility Considerations (WCAG 2.2)

### 4.1 Core Requirements (WCAG 3.3.8 + 3.3.9)
- **No cognitive function test** required for authentication
- Cognitive function tests include: remembering/transcribing passwords, solving CAPTCHAs, calculations, pattern recall
- **Exception:** if a non-cognitive alternative is also provided (WebAuthn, passkeys, magic links, social login)

### 4.2 Must Implement
| Requirement | How |
|-------------|-----|
| Allow **copy-paste** in all fields | Never block paste in password fields |
| Support **password managers** | Proper `input` types (`autofill`, `autocomplete`, `autofocus` attributes) |
| **Biometric auth** (Face ID / fingerprint) | Primary method, not optional upgrade |
| **Show password toggle** | Essential for screen reader users and cognitive accessibility |
| **Large touch targets** | Min **24x24 CSS pixels** (WCAG 2.5.8), preferably **44x44** (Apple HIG) |
| **Error messages with solutions** | Not just "Invalid" but "Email not found. Check spelling or create an account." |
| **Screen reader announcements** | Every state change needs accessibility announcement |
| **Focus not obscured** | WCAG 2.4.11 — ensure keyboard focus is visible and not hidden |
| **Redundant entry prevention** | WCAG 3.3.7 — don't ask for same info twice |

### 4.3 CAPTCHA Avoidance
- CAPTCHA is a cognitive function test under WCAG 3.3.8
- If you must use one, provide an audio alternative and a non-cognitive path
- **Best:** don't use CAPTCHA at all — rate-limit server-side instead
- Object recognition CAPTCHAs ("select cars") still fail at AA level (3.3.8 excepts them, 3.3.9 Enhanced does not)

### 4.4 MFA Accessibility
- Prefer push notification (yes/no) over OTP transcription
- If OTP required: auto-copy, generous time window (≥60s), copy-button provided
- Provide text-based secret key alongside QR code for authenticator setup

---

## 5. Specific Recommendations for a Flutter App

### Priority 1: Auth Method Stack (implement in order)

```
Layer 1: Social Login (Google + Apple)  ← always visible
Layer 2: Email + Magic Link             ← no password entry
Layer 3: Passkeys (with orchestration)  ← enrolled after first successful auth
Layer 4: Email + Password (legacy)      ← hide behind "More options"
Layer 5: Biometric re-auth (local_only) ← for session unlock, not server auth
```

**Flutter packages:**
- `appwrite` or `supabase_flutter` for turnkey social + magic link + passkey
- `local_auth` (Flutter) for device biometric unlock
- `flutter_secure_storage` + `credential_manager` (Android) for passkey storage
- `firebase_auth` for OAuth providers + phone auth
- `oauth2_client` for custom OAuth flows if needed

### Priority 2: UX Rules

1. **Never show a full form on first visit** — email or social login only
2. **Passkey enrollment at the right moments:**
   - After successful social login (second session)
   - After password reset (18-34% enrollment)
   - Never on first login (catastrophic for conversion)
3. **Device-aware orchestration:**
   - iOS → push passkey autofill (high success)
   - Android 14+ → Credential Manager (good)
   - Windows → skip passkey prompt, use magic link
   - Unknown → fallback to magic link
4. **Recovery is a first-class flow:**
   - At least 2 recovery methods enrolled before passkey-only mode
   - Test recovery flow before sunsetting passwords
   - Rate-limit + manual support path
5. **Error messages that help:**
   - "Email not found" → "Check spelling or create a new account"
   - "Wrong password" → "Reset your password" (not "try again")
   - Never reveal whether email exists vs password is wrong (security)
   - Flutter: use `FormState.validate()` with inline field errors, not dialogs
6. **Animation & transition principles:**
   - No loading spinners longer than 2s without progress indication
   - Smooth transitions between auth steps (no jarring full-screen replaces)
   - Keep keyboard visible during OTP entry (don't dismiss on code arrival)

### Priority 3: Accessibility Checklist

- [ ] Every input has a semantic `label` (not placeholder-only)
- [ ] Error states read by screen reader (`Semantics` widget in Flutter)
- [ ] Touch targets ≥ 44x44 logical pixels (Flutter: `MinTapTargetSize`)
- [ ] Color contrast ≥ 4.5:1 for text, ≥ 3:1 for large text
- [ ] Password visibility toggle present on every password field
- [ ] Copy-paste enabled in all fields (never disable)
- [ ] Proper input types set (`TextInputType.emailAddress`, `autofillHints`)
- [ ] Focus order matches visual order
- [ ] No time-limited OTP under 60 seconds
- [ ] Biometric fallback to device PIN/password available
- [ ] CAPTCHA-free (server-side rate limiting instead)

### Priority 4: Testing Matrix

| Scenario | Automated | Manual |
|----------|-----------|--------|
| Social login success + failure | Yes | Yes |
| Magic link delivery + expiry | Yes | Yes |
| Passkey enrollment + rejection | Emulator | Real device |
| Biometric rejection (cancel, fail) | Emulator | Real device |
| Account recovery (all paths) | Yes | Yes |
| Session expiry mid-flow | Yes | Yes |
| Network loss during auth | Yes | No |
| Screen reader complete flow | No | Yes |
| Keyboard navigation all fields | No | Yes |
| International SMS delivery | Staging | Yes |

---

## Key Data Points to Remember

| Metric | Value | Source |
|--------|-------|--------|
| Users abandoning for long forms | 62% | Auth0 2025 |
| Abandonment at password creation | 25% | Industry baseline |
| Abandonment at password reset | 42% | Authgear |
| Not returning after bad login | 88% | Authgear UX research |
| Monthly password forgetting | 78% | MojoAuth |
| Passkey login success rate | 92-98% | FIDO Alliance (26 brands) |
| Password login success rate | 78-84% | FIDO Alliance |
| Passkey conversion lift | 30% | FIDO Alliance 2025 |
| Passkey usage increase with orchestration | 5% → 60%+ | Corbado Benchmark 2026 |
| Passkey enrollment at password reset | 18-34% | Production data |
| Social login preference (18-25) | 71% | Marketing Scoop |
| WCAG target size minimum | 24x24 CSS px | WCAG 2.5.8 |

---

## Recommended Auth Flow (Flutter)

```
[Splash] → [Login Screen]
              ├── Sign in with Google
              ├── Sign in with Apple
              ├── Email (text field) → Magic Link sent
              └── More options → [Legacy: Email + Password]

[Post-login, second session]: 
  "Enable faster login?" → Passkey enrollment sheet → Face ID/Touch ID

[Post-password-reset]:
  "Set up a passkey?" → Passkey enrollment (highest conversion moment)

[Recovery]:
  Forgot email → "Enter phone or username"
  Forgot password → Magic link → Reset → "Set up passkey?"
  Lost device → Recover via verified email + TOTP → New passkey enrollment
```

**Key deletions from most auth flows:** CAPTCHA, username (email-only), confirm-password field, separate email verification screen (magic link does both), password strength meter (defeats purpose of passkey-first).
