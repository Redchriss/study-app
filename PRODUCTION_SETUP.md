# Production Setup Guide

## 1. Sentry Crash Reporting

**What you get:** Email alerts when users crash + dashboard with stack traces.

**Steps:**
1. Go to https://sentry.io and sign up (free tier: 5k events/month)
2. Create a new project → choose "Flutter"
3. Copy the DSN string (looks like `https://xxxxx@xxxxx.ingest.us.sentry.io/xxxxx`)
4. Open `.env` in the project root and add:
```
SENTRY_DSN=https://xxxxx@xxxxx.ingest.us.sentry.io/xxxxx
SENTRY_ENVIRONMENT=production
```

---

## 2. Firebase Analytics

**What you get:** See how many users register, scan papers, buy credits — what features they actually use.

**Steps:**
1. Go to https://console.firebase.google.com and create a project
2. Add an Android app → package name is `mw.yaza.studyapp`
3. Download `google-services.json` and place it in `android/app/`
4. Enable Analytics in Firebase console (it's on by default)
5. Open `.env` and add:
```
FIREBASE_ENABLED=true
```

---

## 3. Release Signing (Play Store)

**What you get:** APKs signed so Play Store accepts them.

**Steps:**
1. Generate a keystore:
```bash
keytool -genkey -v -keystore android/app/release-keystore.jks \
  -alias yaza -keyalg RSA -keysize 2048 -validity 10000
```
2. Create `android/keystore.properties`:
```
storeFile=release-keystore.jks
storePassword=your_password_here
keyAlias=yaza
keyPassword=your_password_here
```
3. **Keep these files safe** — lose them and you can't update your app

---

## 4. GitHub Secrets (for CI/CD builds)

Go to repo → Settings → Secrets and variables → Actions → New repository secret:

| Secret | Value |
|--------|-------|
| `KEYSTORE_BASE64` | `base64 -w0 android/app/release-keystore.jks` output |
| `KEYSTORE_PASSWORD` | Your keystore password |
| `KEY_ALIAS` | `yaza` |
| `KEY_PASSWORD` | Your key password |

---

## 5. Environment Variables (`.env`)

Create `.env` in the project root:
```
API_URL=https://yaza-ai-tutor.onrender.com
SENTRY_DSN=
SENTRY_ENVIRONMENT=development
FIREBASE_ENABLED=false
```

The app reads these at startup via `flutter_dotenv`.
