# ♿ AshaSahyog (आशा सहयोग)

### Empowering People with Disabilities through Accessible Technology

**AshaSahyog** is an accessibility-focused mobile welfare platform built using **Flutter, Dart, and Supabase**. It helps Persons with Disabilities (PwD) discover government welfare schemes, understand important documents, access emergency assistance, and navigate essential services.

The application combines intelligent scheme recommendations, multilingual accessibility, AI-powered document understanding, emergency support, and secure document management into one user-friendly platform.

**Technology:** Flutter · Dart · Supabase · PostgreSQL · Google Gemini · Google ML Kit · OpenStreetMap

---

## 📌 Problem Statement

Millions of Persons with Disabilities in India face challenges accessing government welfare benefits because of:

- Fragmented information about central and state government schemes.
- Complicated eligibility criteria and application procedures.
- Language barriers and inaccessible documentation.
- Difficulty understanding official forms and certificates.
- Limited access to emergency assistance and nearby rehabilitation services.
- Challenges managing important personal documents.

AshaSahyog aims to reduce these barriers through an inclusive digital platform designed around **accessibility, independence, and informed decision-making**.

## 🎯 Project Objectives

- Simplify access to government welfare schemes.
- Recommend relevant schemes based on individual eligibility.
- Improve document accessibility using OCR, text-to-speech, and AI.
- Support English, Hindi, and Marathi.
- Provide quick access to emergency services.
- Help users locate nearby hospitals and rehabilitation facilities.
- Offer secure document management and useful reminders.

---

# 🚀 Key Features

## 1. 🤖 Smart Government Scheme Finder

AshaSahyog helps users explore government welfare schemes relevant to their needs.

**Capabilities:**

- Search and filter welfare schemes.
- Filter schemes by category and state.
- View eligibility requirements and benefit details.
- Bookmark relevant schemes.
- Listen to scheme information using text-to-speech.
- Receive personalized recommendations based on available profile information.

### Intelligent Eligibility Engine

The recommendation system uses a Dart-based rule engine to evaluate criteria such as:

- Age
- Disability type and percentage
- Income
- State residency
- Aadhaar availability
- Bank account availability

It distinguishes between three eligibility outcomes:

| Status | Meaning |
|---|---|
| `eligible` | Available information satisfies the evaluated rules. |
| `needsVerification` | Additional information or verification is required. |
| `notEligible` | Available information does not satisfy one or more evaluated rules. |

The recommendation engine also calculates a match score based on factors such as category relevance, location, and profile completeness.

**Note:** Recommendations provide guidance and do not replace official eligibility verification by government authorities.

## 2. 📄 AI-Powered Smart Document Reader

The **Smart Document Reader** helps users access and understand documents that may otherwise be difficult to read.

It combines document scanning, text extraction, multilingual speech, and Google Gemini-powered assistance.

### Document Scanning and Uploading

Users can:

- Scan documents using their phone camera.
- Upload JPG, PNG, and PDF files.
- Extract text from images using Google ML Kit OCR on Android.
- Extract selectable text from PDF documents.
- Use OCR fallback for supported scanned PDFs.
- Open supported documents from the Document Vault.

### Multilingual OCR

The reader supports selectable OCR scripts:

- **English / Latin**
- **Hindi and Marathi / Devanagari**

### Text-to-Speech

Users can listen to extracted text with:

- English, Hindi, or Marathi voice selection.
- Adjustable reading speed.
- Play and Stop controls.
- Available device text-to-speech voices.

Voice availability depends on the device and installed speech language data.

### AI Document Understanding

Through authenticated Supabase Edge Functions and Google Gemini, users can:

**Simplify:** Rewrite complex document content into easier language while preserving important information.

**Translate:** Translate extracted text into English, Hindi, or Marathi.

**Ask Questions:** Ask questions about a document and receive answers grounded in its extracted content.

### Accessibility-Focused Interface

The reader includes:

- Side-by-side Scan Document and Upload Document actions.
- A dedicated selected-document card with safe handling of long filenames.
- Grouped reading and speech controls.
- A visible Document AI section.
- Separate output areas for simplified, translated, and question-answering results.
- A design aligned with AshaSahyog's purple, pink, blue, and green visual theme.

### Document Processing Limits

| Resource | Limit |
|---|---|
| Uploaded document | 20 MB |
| PDF document | 50 pages |
| AI request text | 30,000 characters |

**Privacy:** Document files are processed in a temporary reader session. Extracted text is sent to the cloud AI service only after the user confirms the data-sharing dialog. The original document file is not sent to Gemini by the reader.

## 3. 🚨 Emergency SOS and Helpline Support

AshaSahyog provides quick access to emergency assistance.

**Features include:**

- A three-second cancellable SOS countdown to reduce accidental activation.
- High-accuracy GPS location retrieval.
- Emergency SMS containing a Google Maps location link.
- Access to saved emergency contacts.
- Quick emergency calling.
- A dedicated Help & Support screen.

### Emergency Helplines

The interface provides shortcuts for services such as:

| Service | Number |
|---|---|
| National Emergency | 112 |
| Ambulance | 108 |
| Police | 100 |
| Fire | 101 |
| Women Helpline | 1091 |

Emergency numbers and service availability may vary by location. Users should verify local availability.

## 4. 🔊 Multilingual Accessibility and Voice Assistance

Accessibility is central to AshaSahyog.

The application includes:

- English, Hindi, and Marathi language support.
- Centralized text-to-speech functionality using `flutter_tts`.
- Reusable voice-reading controls.
- Spoken scheme information.
- Voice playback for supported document content.
- Accessible touch targets and responsive screen layouts.

The application aims to make important information easier to access for users with different reading and accessibility needs.

## 5. 🏥 Hospital and Rehabilitation Locator

The locator helps users discover nearby healthcare and rehabilitation services.

**Technology:**

- `flutter_map`
- OpenStreetMap
- Overpass API
- Device geolocation

**Capabilities:**

- Discover nearby hospitals and clinics.
- Find relevant disability support and rehabilitation facilities.
- View locations on an interactive map.
- Search within a nearby geographical radius.

Location access requires user permission. Search results depend on available map data.

## 6. 📁 Secure Document Vault

The Document Vault helps users organize important records, including:

- Disability certificates
- UDID documents
- Aadhaar-related documents
- Income certificates
- Other welfare-related records

**Features:**

- Local document management.
- Supabase-backed document metadata and cloud storage.
- Integration with supported document-reading workflows.
- Document information that can support eligibility verification.

Sensitive documents should be handled according to the application's authentication, access-control, and privacy policies.

## 7. 🔔 Reminders and Notifications

The reminders feature helps users manage important dates and recurring activities.

Examples include:

- Medical appointments.
- Scheme application deadlines.
- Medication or care-related schedules.
- Other personal reminders.

The application uses `flutter_local_notifications` and timezone-aware scheduling for supported local notifications.

---

# 🏗️ Technology Stack

| Layer | Technology |
|---|---|
| Mobile application | Flutter, Dart |
| UI design | Material 3 |
| Authentication | Supabase Auth |
| Database | Supabase PostgreSQL |
| Backend services | Supabase Edge Functions |
| Cloud AI | Google Gemini |
| Image OCR | Google ML Kit |
| Text-to-speech | `flutter_tts` |
| Maps | `flutter_map`, OpenStreetMap |
| Location | Geolocator |
| Notifications | `flutter_local_notifications` |
| Version control | Git, GitHub |

## 📂 Project Structure

```text
AshaSahyog_App/
├── lib/
│   ├── components/
│   ├── l10n/
│   ├── models/
│   ├── providers/
│   ├── scheme_recommendation/
│   │   ├── eligibility_engine.dart
│   │   ├── recommendation_service.dart
│   │   └── user_eligibility_profile.dart
│   ├── screens/
│   │   └── smart_document_reader_screen.dart
│   ├── services/
│   │   └── document_ai_service.dart
│   ├── theme/
│   └── main.dart
├── supabase/
│   └── functions/
│       ├── _shared/
│       ├── asha-assistant/
│       └── document-reader/
├── test/
├── pubspec.yaml
└── README.md
```

The project separates presentation, models, business rules, and service integrations to improve maintainability.

---

# 🗄️ Database Overview

AshaSahyog uses Supabase PostgreSQL for application data.

| Table | Purpose | Example columns |
|---|---|---|
| `profiles` | User demographics and disability information | `id`, `full_name`, `dob`, `disability_type`, `disability_percentage` |
| `schemes` | Government welfare scheme information | `id`, `title`, `title_hi`, `title_mr`, `category`, `state`, `active` |
| `scheme_eligibility` | Scheme eligibility rules | `scheme_id`, `min_age`, `max_age`, `max_income`, `requires_aadhaar` |
| `emergency_contacts` | Saved emergency contacts | `id`, `user_id`, `name`, `relation`, `phone` |
| `vault_documents` | Document metadata | `id`, `user_id`, `title`, `file_path`, `document_type` |

---

# ⚙️ Installation and Setup

## Prerequisites

Install the following:

- Flutter SDK
- Dart SDK
- Android SDK
- Git
- A code editor such as VS Code
- A Supabase project

A physical Android device or emulator is recommended for testing Android-specific features such as camera OCR and speech playback.

## 1. Clone the Repository

```bash
git clone https://github.com/Ganesh-Code-Lives/AshaSahyog_App.git
cd AshaSahyog_App
```

## 2. Install Dependencies

```bash
flutter pub get
```

## 3. Configure Environment Variables

Copy `.env.example` to `.env`.

Configure the required values:

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-supabase-publishable-key",
  "CARTO_API_KEY": "your-carto-basemaps-key"
}
```

**Security notes:**

- Do not commit `.env` to GitHub.
- The Supabase publishable key is intended for client use; protect data through authentication and Row Level Security.
- Restrict client-side map API keys according to the provider's recommendations.
- Never place the Gemini API key or a Supabase service-role key inside the Flutter application.

## 4. Run the Application

### Android

```bash
flutter run -d android --dart-define-from-file=.env
```

### Chrome

```bash
flutter run -d chrome --dart-define-from-file=.env
```

Some document scanning and OCR features are platform-specific and may not be available on the web.

## 5. Build an Android APK

For an ARM64 Android device:

```bash
flutter build apk --release --target-platform android-arm64 --split-per-abi --dart-define-from-file=.env
```

The generated APK is available at:

```text
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

---

# 🤖 Configuring Google Gemini AI

The Smart Document Reader and cloud-enabled Asha Assistant use **Supabase Edge Functions** to communicate with Google Gemini.

Gemini requests are handled on the backend so the Gemini API key is not included in the Flutter application.

## 1. Install and Authenticate Supabase CLI

```bash
npx supabase login
```

## 2. Configure Gemini Secrets

Set your Gemini API key in your Supabase project:

```bash
npx supabase secrets set GEMINI_API_KEY=YOUR_GEMINI_API_KEY --remote=YOUR_PROJECT_REF
```

Set an available Gemini model:

```bash
npx supabase secrets set GEMINI_MODEL=YOUR_SUPPORTED_MODEL --remote=YOUR_PROJECT_REF
```

Choose a model that supports the API features required by the Edge Functions, including structured JSON output.

**Important:** The backend source may contain a default model name that is no longer available to new Gemini API users. Configure `GEMINI_MODEL` with a model currently supported by your Gemini project.

## 3. Deploy Supabase Edge Functions

```bash
npx supabase functions deploy document-reader --remote=YOUR_PROJECT_REF
npx supabase functions deploy asha-assistant --remote=YOUR_PROJECT_REF
```

The functions authenticate requests using the user's Supabase session before forwarding supported AI operations.

## 4. Test Cloud AI

1. Sign in to AshaSahyog.
2. Open Smart Document Reader.
3. Scan or upload a document.
4. Extract the document text.
5. Select an output language.
6. Tap **Simplify** or **Translate**.
7. Confirm the data-sharing dialog.
8. Verify the generated result.
9. Test document question answering using both answerable and unanswerable questions.

For the Asha Assistant, cloud responses depend on the user's cloud AI settings and backend configuration.

---

# 🧪 Testing and Quality Assurance

Run static analysis:

```bash
flutter analyze
```

Run Flutter tests:

```bash
flutter test
```

Run Document Reader backend tests:

```bash
deno test --allow-env supabase/functions/document-reader
```

Build a debug APK:

```bash
flutter build apk --debug --dart-define-from-file=.env
```

### Recommended Manual Tests

- Scan a document using the camera.
- Upload JPG, PNG, and PDF files.
- Test both Latin and Devanagari OCR.
- Test selectable-text and scanned PDFs.
- Verify text-to-speech in available languages.
- Simplify documents in English, Hindi, and Marathi.
- Translate documents between supported languages.
- Test document question answering.
- Verify long filenames do not overflow.
- Check layout at narrow screen widths and increased text sizes.
- Test consent dialogs and backend error handling.
- Confirm emergency and location permissions behave correctly.

---

# 🔐 Privacy, Security, and Accessibility

AshaSahyog handles potentially sensitive information, including disability-related profile details, personal documents, and location data.

The application should be configured and deployed with appropriate safeguards, including:

- Supabase authentication and database Row Level Security.
- Server-side management of Gemini API credentials.
- User confirmation before sending document text to cloud AI.
- Appropriate permissions for camera, location, and notifications.
- Secure storage and access controls for personal documents.
- Clear communication of platform and offline feature limitations.
- Accessibility testing across screen sizes and text scaling settings.

**AI-generated simplifications and translations are informational aids.** Users should refer to original documents and official sources for legally significant requirements, eligibility decisions, and application deadlines.

---

# 🌍 Social Impact

AshaSahyog supports the goal of making essential public services more accessible and understandable.

By combining welfare discovery, multilingual document assistance, emergency support, and accessible interaction, the project aims to help Persons with Disabilities:

- Find relevant welfare opportunities.
- Understand complex official information.
- Access important services more independently.
- Manage documents and reminders more effectively.
- Seek assistance during emergencies.

---

# 📜 License and Credits

Developed as an **MCA Final Year Project**.

Built with ❤️ using Flutter, Dart, Supabase, and Google Gemini to support more accessible welfare services.

See the repository's `LICENSE` file for the applicable license terms.

**AshaSahyog — Technology for Accessibility, Inclusion, and Empowerment.**
