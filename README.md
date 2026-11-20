# ♿ AshaSahyog (आशा सहयोग)
> **Empowering People with Disabilities (PwD) with Smart Scheme Recommendations, Emergency SOS, and Accessible Welfare Services.**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Supabase](https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase)](https://supabase.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

---

## 📌 Problem Statement & Social Impact

In India, millions of People with Disabilities (PwD) miss out on government welfare schemes, pensions, assistive device subsidies, and educational quotas due to fragmented information, complex eligibility rules, and accessibility barriers. 

**AshaSahyog** is a comprehensive mobile welfare platform designed to bridge this gap by offering:
- **Intelligent Eligibility Matching**: Automated rule evaluation matching user profiles against central & state disability schemes.
- **Emergency SOS with GPS Location Broadcast**: Immediate panic alert broadcasting live high-accuracy coordinates to trusted contacts and emergency helplines.
- **App-Wide Accessibility**: Native multilingual Support (English, Hindi, Marathi) with a built-in Text-To-Speech (TTS) Voice Reader.
- **Document Vault**: Secure cloud & local storage for UDID certificates, Aadhaar, and income documents.

---

## 🚀 Key Features

### 1. 🤖 Smart Eligibility Recommendation Engine
- **Pure Dart Rule Engine** ([`eligibility_engine.dart`](lib/scheme_recommendation/eligibility_engine.dart)): Evaluates 7 core criteria (Age, Disability %, Income, State Residency, Aadhaar, Bank Account).
- **Epistemic Honesty Model**: Returns three distinct statuses — `eligible`, `needsVerification` (when fields are missing), or `notEligible` with rule-by-rule explanations.
- **Fuzzy Matching & Scoring**: Calculates a match score (0–100) based on category relevance, state residency, and profile completeness.

### 2. 🚨 Emergency SOS with Live Geolocation Broadcast
- **Safety Countdown**: 3-second cancellable panic timer to prevent false triggers.
- **Live GPS Tracking**: Leverages `Geolocator` to query high-accuracy hardware GPS coordinates.
- **SMS Location Payload**: Constructs URI-encoded SMS with Google Maps live location link (`https://maps.google.com/?q=lat,lng`) dispatched to saved emergency contacts.
- **Emergency Call**: Auto-initiates direct dialing to National Emergency Helpline `112`.

### 3. 🔊 Voice Accessibility Reader (TTS Screen Reader)
- **App-Wide Speech**: Centralized `TTSService` using `flutter_tts` supporting English (`en-IN`), Hindi (`hi-IN`), and Marathi (`mr-IN`).
- **One-Tap UI Widget**: Reusable `TtsButton` component allowing visually impaired users to listen to dashboard summaries and scheme details.

### 4. 🏥 Hospital & Rehabilitation Locator
- **Interactive Map**: Built with `flutter_map` and OpenStreetMap.
- **Overpass API Integration**: Queries nearest hospitals, clinics, and disability care centers within a 5–10 km radius of the user's current GPS position.

### 5. 📁 Document Vault
- Encrypted local metadata storage with Supabase Cloud backup.
- Cross-references uploaded Aadhaar & Disability certificates to dynamically boost scheme eligibility confidence.

### 6. 🔔 Scheduled Reminders & Push Notifications
- Local offline notifications backed by `flutter_local_notifications` and `timezone`.
- Supports recurring daily/weekly reminders for medical appointments and scheme application deadlines.

---

## 🏗️ Architecture & Project Structure

The project follows a modular Clean-ish Architecture separating domain logic, data models, services, and presentation UI:

```
lib/
├── components/          # Reusable UI widgets (BottomNav, TtsButton, etc.)
├── l10n/                # Localization maps (AppStrings: EN, HI, MR)
├── models/              # Canonical DTO models (SchemeSummary, UserModels, Reminder)
├── providers/           # App state management (LanguageProvider)
├── scheme_recommendation/
│   ├── eligibility_engine.dart       # Core pure Dart eligibility logic
│   ├── recommendation_service.dart   # Profile fetch & match score calculator
│   └── user_eligibility_profile.dart # User profile eligibility container
├── screens/             # UI screens (Home, SchemesFinder, SOS, Vault, Reminders, Profile)
├── services/            # Background & data services (Auth, Notification, Reminder, TTS)
├── theme/               # Unified design system & Material 3 palette
└── main.dart            # Entry point & Supabase initialization
```

---

## 🗄️ Database Schema Overview (Supabase PostgreSQL)

| Table | Description | Key Columns |
|---|---|---|
| `profiles` | User demographics & disability data | `id`, `full_name`, `dob`, `disability_type`, `disability_percentage`, `address` |
| `schemes` | Master list of government welfare schemes | `id`, `title`, `title_hi`, `title_mr`, `summary`, `amount`, `category`, `state`, `active` |
| `scheme_eligibility` | Scheme eligibility rules | `scheme_id`, `min_age`, `max_age`, `min_disability_percent`, `max_income`, `requires_residency`, `requires_aadhaar` |
| `emergency_contacts` | User emergency panic contacts | `id`, `user_id`, `name`, `relation`, `phone` |
| `vault_documents` | Document vault metadata | `id`, `user_id`, `title`, `file_path`, `document_type` |

---

## 🔐 Environment Setup & Security

Supabase credentials and the CARTO Basemaps key are kept out of version control and injected at compile time using Flutter's `--dart-define-from-file`. A key included in a client app can be extracted, so restrict the CARTO key to your app or website in the CARTO dashboard.

### 1. Create Local Secret File
Copy `.env.example` to `.env`:
```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-supabase-anon-key",
  "CARTO_API_KEY": "your-carto-basemaps-api-key"
}
```

The CARTO key is required to load the locator's CARTO map tiles. Get one from [CARTO Basemaps](https://www.carto.com/basemaps/apikey/).

### 2. VS Code Launch Configuration
Press **F5** in VS Code to launch the app — [`.vscode/launch.json`](.vscode/launch.json) automatically passes `--dart-define-from-file=.env`.

---

## 💻 Running the Project

### Command Line
```bash
# Get dependencies
flutter pub get

# Run on Chrome (Web)
flutter run -d chrome --dart-define-from-file=.env

# Run on Android Device / Emulator
flutter run -d android --dart-define-from-file=.env
```

---

## Smart Document Reader

1. Open **Smart Document Reader** from the dashboard, or open a supported file’s menu in the **Document Vault** and choose **Read document**.
2. On Android, choose **English / Latin** or **Hindi and Marathi / Devanagari**, then tap **Scan Document** or **Upload Document**. Try a JPG or PNG photo, a selectable-text PDF, and a scanned PDF. For a saved Vault file, select a different script and tap **Read Vault file again**.
3. Inspect the original text and any unreadable-page numbers. Choose the reading voice and speed, then use **Play** and **Stop**. Android uses installed offline voices. Download missing voices in Android’s text-to-speech settings.
4. With cloud AI configured, use **Simplify**, **Translate**, or **Ask question** and confirm the data-sharing dialog. Try a question whose answer appears in the document and another whose answer is absent. Use **Show original text** to switch back from a simplified or translated view.

The reader accepts files up to 20 MB and PDFs up to 50 pages. AI supports up to 30,000 characters per request. Android supports local ML Kit OCR and camera capture. Other platforms offer selectable-text PDF extraction, and iOS can use available device TTS voices. The Reader opens files in a temporary session and sends extracted text to Gemini only after confirmation. It does not upload the original file.

### Enable cloud AI

Set a Gemini API key in your Supabase project’s Edge Function secrets. The default model is `gemini-2.5-flash-lite`. Set the optional `GEMINI_MODEL` secret to use another available model that supports structured output.

```bash
supabase login
supabase link --project-ref YOUR_PROJECT_REF
supabase secrets set GEMINI_API_KEY=YOUR_SERVER_SIDE_KEY
supabase functions deploy document-reader
supabase functions deploy asha-assistant
```

Both functions validate the caller’s Supabase user session before forwarding requests. Sign in to the app to test them. Keep Gemini keys out of Flutter’s `.env`, build flags, and client CI secrets. Rotate keys previously shipped in client builds. Asha Assistant’s offline answers remain available, and users can opt into cloud replies from **Cloud AI settings**. Use a Gemini project with data-handling terms appropriate for the documents your users may share.

```bash
flutter pub get
flutter analyze
flutter test
deno test --allow-env supabase/functions/document-reader
flutter build apk --debug
```

---

## 📜 License & Credits

Developed as an **MCA Final Year Project**.  
Built with ❤️ for People with Disabilities using **Flutter** and **Supabase**.
