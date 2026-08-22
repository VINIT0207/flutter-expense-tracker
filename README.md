# FinPlus — Smart AI Personal Finance & Expense Tracker 💸

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
  <img src="https://img.shields.io/badge/Android-3DDC84?style=for-the-badge&logo=android&logoColor=white" alt="Android" />
  <img src="https://img.shields.io/badge/C%2B%2B-00599C?style=for-the-badge&logo=c%2B%2B&logoColor=white" alt="C++" />
  <img src="https://img.shields.io/badge/llama.cpp-F97316?style=for-the-badge&logo=meta&logoColor=white" alt="llama.cpp" />
  <img src="https://img.shields.io/badge/SQLite-003B57?style=for-the-badge&logo=sqlite&logoColor=white" alt="SQLite" />
  <img src="https://img.shields.io/badge/Provider-State%20Management-818CF8?style=for-the-badge" alt="Provider" />
  <img src="https://img.shields.io/badge/MVVM-Architecture-6366F1?style=for-the-badge" alt="MVVM" />
  <img src="https://img.shields.io/badge/On--Device%20AI-Offline%20SLM-10B981?style=for-the-badge" alt="On-Device AI" />
  <img src="https://img.shields.io/badge/GGUF-Quantization-EC4899?style=for-the-badge" alt="GGUF" />
  <img src="https://img.shields.io/badge/Liquid%20Glass-Design%20System-38BDF8?style=for-the-badge" alt="Liquid Glass" />
  <img src="https://img.shields.io/badge/fl__chart-Data%20Visualization-F59E0B?style=for-the-badge" alt="fl_chart" />
  <img src="https://img.shields.io/badge/Exact%20Alarms-Log--Aware%20Notifications-8B5CF6?style=for-the-badge" alt="Exact Alarms" />
  <img src="https://img.shields.io/badge/License-Proprietary-EF4444?style=for-the-badge" alt="Proprietary" />
</p>

---

## 📖 Overview

**FinPlus** is an ultra-premium, privacy-first personal finance tracking and budgeting application built with **Flutter**. Designed with a cutting-edge **High-Contrast Midnight Dark Theme** and **Liquid Glassmorphism**, FinPlus pairs comprehensive personal finance tracking with an intelligent **offline on-device AI Financial Advisor** that gives personalized budget insights without any user data ever leaving the device.

---

## 🏷️ Skills, Technologies & Engineering Concepts Used

| Domain | Skills & Applied Concepts |
|---|---|
| 📱 **Mobile Development** | `Flutter Framework`, `Dart 3 (Sound Null Safety)`, `Android SDK (API 34+)`, `Native Platform Channels` |
| ⚡ **Native AI & C++ Bindings** | `llama.cpp Engine`, `JNI (Java Native Interface)`, `C++ Shared Libraries (libllama.so)`, `ARM64-v8a Optimization` |
| 🧠 **Embedded Machine Learning** | `Small Language Models (SLM)`, `On-Device Inference`, `GGUF 4-bit Quantization (Q4_K_M)`, `Stream Parsing`, `Prompt Engineering` |
| 🏗️ **Architecture & State** | `MVVM (Model-View-ViewModel)`, `Repository Pattern`, `Provider State Management`, `Clean Architecture`, `Decoupled Service Layer` |
| 🗄️ **Database & Persistence** | `SQLite / Sqflite`, `Relational Database Design`, `ACID Transactions`, `Path Provider`, `CSV Serialization / Deserialization` |
| 🎨 **UI/UX & Design Systems** | `Liquid Glassmorphism`, `Backdrop Filter Blur (dart:ui)`, `High-Contrast Dark Theme`, `Material Design 3`, `Google Fonts (Outfit)`, `Haptic Feedback Engine` |
| 📊 **Data Visualization** | `fl_chart`, `Cubic Spline Trend Graphs`, `Comparative Needs vs. Wants Bar Charts`, `Categorical Pie Distribution` |
| ⏱️ **Background & OS Services** | `Flutter Local Notifications`, `Exact Alarm Scheduling (SCHEDULE_EXACT_ALARM)`, `Timezone Localization`, `BootReceiver (Device Reboot Persistence)` |
| 🚀 **Performance & Concurrency** | `Background Worker Isolates (Isolate.spawn)`, `Chunked Asset Streaming`, `Zero-Lag UI Execution`, `Dart Static Analysis` |

---

## ✨ Key Features & Capabilities

### 1. 🌌 High-Contrast Midnight & Liquid Glass UI
- **Midnight Color Palette**: Deep background (`#080C14`) paired with elevated Slate surfaces (`#151D2C`), Indigo (`#818CF8`), Emerald (`#34D399`), Amber (`#FBBF24`), and Rose (`#F43F5E`).
- **Liquid Glass Top AppBars**: Frosted glass surfaces with real-time backdrop blur (`ImageFilter.blur`), fluid luminous gradient orbs, specular borders (`#334155`), and elevated drop shadows across every screen.
- **Modern Typography**: Styled using `GoogleFonts.outfit` for headers, brand emblems, and clean financial metrics.

### 2. ⚡ Spending Pulse & Dynamic Budget Engine
- **Live Health Status**: Real-time spending analysis calculates budget health into 4 visual tiers:
  - 🟢 **Healthy**: On-track spending with safe remaining daily allowance.
  - 🔵 **Moderate**: Steady spending within reasonable threshold.
  - 🟠 **Warning**: Approaching daily or monthly limits.
  - 🔴 **Critical / Danger**: Over-budget spending alerts.
- **Daily Budget Limit Tracking**: Automatically calculates daily burn rate, remaining daily allowance, and monthly projections with 1-tap quick budget customization.

### 3. 📊 Advanced Analytics & Charts (`fl_chart`)
- **Needs vs. Wants Analysis**: Interactive Bar Chart contrasting Essential versus Discretionary spending with auto-formatted INR axis labels.
- **Month-over-Month Spending Trends**: Smooth Cubic Spline Line Chart with curve-overshoot prevention and dynamic min/max bounds.
- **Categorical Distribution**: Pie chart breakdown visualizing spending shares across categories (Food, Transport, Shopping, Bills, Entertainment, Health, Education, Investment).
- **Time Range Selector**: Switch seamlessly between **Weekly**, **Monthly**, and **Yearly** analytics.

### 4. 🎯 Multi-Frequency Savings Goals
- **Flexible Target Planning**: Create goals with **Daily**, **Weekly**, **Monthly**, or **Yearly** targets.
- **Automatic Savings Calculator**: Calculates the exact daily savings amount required to achieve each goal on time.
- **Interactive Contribution**: Easily add funds to existing goals with instant progress bar animations.
- **Celebration Alerts**: Triggers milestone alert notifications upon reaching 100% of a savings goal.

### 5. ⏱️ Smart Log-Aware Notification Engine
- **Hourly Expense Reminders (9:00 AM – 10:00 PM)**:
  - Hourly reminders scheduled exclusively during active daytime hours (9 AM to 10 PM).
  - **Intelligent Skipping**: If an expense was already logged during the current hour slot, the upcoming reminder is automatically skipped to prevent unnecessary interruptions.
- **Savings Goal Alerts (Every 2 Hours, 9:00 AM – 10:00 PM)**:
  - Reminds the user every 2 hours if savings have not yet been logged for today.
  - **Instant Cancellation on Contribution**: The moment savings are logged, all remaining goal alerts for the day are cancelled immediately and deferred to tomorrow.
- **Daily Nightly Log (8:00 PM)**: Prompts a summary review of the day's total expenses.
- **In-App Notification Center**: View live permission status (`Active` / `Disabled`), inspect all automated schedules, and manage notification permissions in one tap.

### 6. 🔍 History, Multi-Filter & Batch Deletion
- **Instant Full-Text Search**: Search transactions by title, category, or notes in real-time.
- **Multi-Filter Chips**: Filter by "Essential Only", "High Value (> ₹500)", or specific categories.
- **Custom Date-Range Filter**: Filter transaction history across any custom date interval.
- **Selection Mode**: Long-press to enter multi-select mode for batch deleting entries.

### 7. ⌨️ Physical Keypad & Quick Add
- **Custom Haptic Keypad**: Tactile numeric keypad with live arithmetic evaluations (`+`, `-`).
- **Category Grid**: Visual category selector with dedicated color tokens and icons.
- **Essential vs. Discretionary Toggle**: Classify transactions with a single tap for accurate budgeting.

### 8. 📄 Data Portability (CSV Import & Export Guide)
FinPlus allows you to export your financial records for backup and bulk-import existing transactions from spreadsheets or CSV files.

#### Where to Find Import & Export in the App:
- Navigate to the **Analytics Dashboard** (tap the bar chart icon from the home screen).
- **Importing CSV**: Tap the **Upload File icon** (`Icons.upload_file`) on the top-right corner of the elevated Analytics AppBar. Pick any `.csv` file from your device storage to immediately import and refresh your charts.
- **Exporting CSV**: Tap the floating action button **"EXPORT CSV"** at the bottom of the screen to save your full SQLite database as a formatted `.csv` file.

#### CSV Schema & Column Specifications:
To create your own CSV file for importing, use the following column headers in the first row:

| Column Name | Requirement | Type | Allowed Values & Format | Description | Example |
|---|---|---|---|---|---|
| `title` | **Required** | String | Any text | Name of item, merchant, or service | `Swiggy Food Delivery` |
| `category` | **Required** | String | `Food`, `Transport`, `Shopping`, `Bills`, `Entertainment`, `Health`, `Education`, `Investment`, `Salary`, `Other` | Spending category | `Food` |
| `amount` | **Required** | Number | Positive decimal (`> 0`) | Amount spent in INR | `450.00` |
| `date` | **Required** | Date | `YYYY-MM-DD` or `YYYY/MM/DD` | Date when expense occurred | `2026-08-20` |
| `isEssential` | *Optional* | Boolean | `true`/`false`, `1`/`0`, `yes`/`no` | Needs vs. Wants classification (Defaults to `false`) | `false` |
| `note` | *Optional* | String | Any text | Additional notes or tags | `Dinner with team` |
| `id` | *Optional* | Integer | Number or blank | Database record ID (leave empty for new imports) | `1` |

#### Sample CSV File Template:
You can also use the included [`sample_expenses.csv`](file:///c:/Projects/Expense_Tracker/sample_expenses.csv) file located in the root project folder as a reference:

```csv
title,category,amount,date,isEssential,note
Swiggy Food Delivery,Food,450.00,2026-08-20,false,Dinner with friends
Supermarket Groceries,Food,1850.00,2026-08-19,true,Weekly groceries and staples
Uber Cab Ride,Transport,320.00,2026-08-19,false,Office commute
Netflix Subscription,Entertainment,649.00,2026-08-15,false,Monthly premium plan
Electricity Bill,Bills,1420.00,2026-08-14,true,Monthly utility payment
Gym Membership Fee,Health,1500.00,2026-08-05,true,Monthly gym pass
Pharmacy & Vitamins,Health,650.00,2026-08-12,true,Monthly medicines
```

### 9. 🤖 Offline On-Device AI Financial Advisor
- **100% Offline & Private**: Powered by local Small Language Model (SLM) inference using GGUF architecture. Zero financial data is sent to external cloud servers.
- **Context-Aware Recommendations**: Analyzes your live SQLite transaction records, category distributions, and budget health to answer financial queries in real-time.
- **Quick-Prompt Suggestions**: 1-tap prompts for rapid spending pattern reviews, category breakdowns, and saving tips.

---

## 🏗️ Technical Architecture & Directory Structure

The application is structured cleanly using **MVVM + Repository Pattern** alongside local native packages for on-device inference:

```text
Expense_Tracker/
├── lib/
│   ├── assets/                   # Bundled GGUF local model files (place your .gguf here)
│   ├── data/
│   │   ├── database_helper.dart  # SQLite Database schema, migrations & queries
│   │   └── finance_repository.dart# Abstracted repository layer for data access
│   ├── logic/
│   │   ├── decision_engine.dart  # Algorithmic spending pulse & heuristic rules
│   │   └── slm_controller.dart   # Local SLM orchestrator & financial prompt builder
│   ├── models/
│   │   ├── goal.dart             # Savings Goal data model
│   │   └── transaction.dart      # Transaction data model
│   ├── screens/
│   │   ├── home_screen.dart      # Main dashboard with liquid glass header & pulse cards
│   │   ├── advanced_dashboard.dart# Analytics charts, trends & CSV import/export
│   │   ├── history_screen.dart   # Search, filter chips & batch selection history
│   │   ├── chatbot_screen.dart   # On-device AI financial advisor conversation screen
│   │   ├── add_entry_screen.dart # Physical keypad & quick transaction entry
│   │   └── add_goal_screen.dart  # Multi-frequency savings goal creator
│   ├── services/
│   │   ├── local_ai_service.dart # Low-level local inference lifecycle
│   │   └── model_setup_service.dart# Background isolate asset unpacker & loader
│   ├── utils/
│   │   ├── notification_service.dart# Exact alarms, time-windowed reminders & notification center
│   │   └── import_export_helper.dart# CSV parsing & generation engine
│   ├── widgets/
│   │   └── category_grid.dart    # Reusable high-contrast category selection component
│   └── main.dart                 # App entry point, High-Contrast Dark Theme & initialization
│
├── local_packages/
│   ├── onenm_local_llm/          # Flutter plugin wrapper for local LLM inference & chat streams
│   └── llama_flutter_android/    # Native C++ llama.cpp runtime & Android ARM64 JNI shared libraries
│
├── android/                      # Native Android configuration, permissions & BootReceiver
└── pubspec.yaml                  # Dependencies, asset declarations & local package overrides
```

---

## 📦 Native SLM Plugins (`local_packages/`)

FinPlus includes embedded local packages within `local_packages/` to power on-device inference without external dependencies:

1. **`local_packages/onenm_local_llm/`**:
   - High-level Flutter plugin providing the Dart API for model initialization, conversation memory, temperature/top-p sampling parameters, and streaming response generation.
   - Linked in `pubspec.yaml` via `dependency_overrides: onenm_local_llm: path: local_packages/onenm_local_llm`.

2. **`local_packages/llama_flutter_android/`**:
   - Low-level native Android plugin containing pre-compiled `llama.cpp` C++ shared libraries (`libllama.so`) and JNI bindings compiled for ARM64 (`arm64-v8a`) architecture.
   - Enables high-speed, hardware-accelerated local execution with zero cloud calls.

---

## 🧠 Setting Up Your Own Local LLM / SLM (On-Device AI Setup)

FinPlus uses a **100% offline on-device AI inference engine** powered by native `llama.cpp` bindings through `onenm_local_llm`. You can bring your own quantized Large or Small Language Model (SLM) to power the financial advisor chatbot.

### 1. Model Format & Recommendations
- **Format**: Quantized GGUF format (`.gguf`).
- **Quantization**: `Q4_K_M`, `Q4_0`, or `Q5_K_M` for the optimal balance of inference speed and intelligence on mobile devices.
- **Recommended Architectures**: Models between `0.5B` and `3B` parameters (e.g. Qwen 2.5 0.5B/1.5B Instruct, TinyLlama 1.1B, Gemma 2B IT, Llama 3.2 1B/3B, or custom fine-tuned GGUF checkpoints).

### 2. Step-by-Step Asset Placement Guide

1. **Place Your GGUF Model in Assets**:
   - Create or locate the `lib/assets/` directory in the project root:
     ```text
     c:\Projects\Expense_Tracker\lib\assets\
     ```
   - Place your quantized `.gguf` file inside this directory (for example: `myapp-ai-Q4_K_M.gguf` or `your_custom_model.gguf`).

2. **Configure the Model Filename in Code**:
   - Open [`lib/services/model_setup_service.dart`](file:///c:/Projects/Expense_Tracker/lib/services/model_setup_service.dart) and update the `assetPath` and `fileName` constants to match your model:
     ```dart
     class ModelSetupService {
       static const String assetPath = 'lib/assets/your_custom_model.gguf';
       static const String fileName = 'your_custom_model.gguf';
       ...
     }
     ```

3. **Verify Asset Registration in `pubspec.yaml`**:
   - Ensure the asset path is declared under the `flutter` section in [`pubspec.yaml`](file:///c:/Projects/Expense_Tracker/pubspec.yaml):
     ```yaml
     flutter:
       uses-material-design: true
       assets:
         - lib/assets/
     ```

4. **Automatic Streaming & Native Loading**:
   - On first app launch, `ModelSetupService` automatically streams the bundled GGUF model asset to the app's sandboxed documents directory using background isolates (`Isolate.spawn`) without stuttering the UI.
   - `LocalAiService` then loads the cached weights directly into native RAM using ARM64 CPU/GPU acceleration via `local_packages/llama_flutter_android` for instantaneous, private offline chat.

---

## 📱 Device Compatibility & Hardware Performance Guide

FinPlus is engineered with a lightweight, multi-threaded architecture. Resource usage is divided into two operational tiers:
1. **Core Financial Tracking & UI**: Runs at **60–120 FPS** on virtually any Android phone with **2 GB+ RAM** and **Android 8.0+**.
2. **On-Device AI Financial Advisor**: Performs local SLM neural inference via native `llama.cpp` ARM64 C++ shared libraries. Performance depends on the device processor and available RAM.

### 📊 Compatibility & Performance Matrix

| Device Tier | Example Processors / Chipsets | RAM Required | Core App & Charts | On-Device AI Performance |
|---|---|---|---|---|
| **🟢 Flagship & High-End** | Snapdragon 8 Gen 2 / 8 Gen 3 / 8s Gen 3, Dimensity 9200 / 9300, Tensor G3 / G4 | **8 GB – 12 GB+** | ⚡ Butter Smooth (120 Hz) | 🚀 **Blazing Fast (~10–25 tokens/sec)**. Near-instant responses with zero UI stutter. |
| **🔵 Upper Mid-Range** | Snapdragon 7+ Gen 2 / 7 Gen 3 / 778G, Dimensity 8200 / 8300, Exynos 1480 | **6 GB – 8 GB** | ⚡ Smooth (60–120 Hz) | ⚡ **Fast & Responsive (~5–10 tokens/sec)**. Fluid stream generation. |
| **🟡 Budget / Entry Mid-Range** | Snapdragon 695 / 4 Gen 2, Dimensity 6080 / 7020, Helio G99 | **4 GB – 6 GB** | ✅ Smooth (60 Hz) | ⏱️ **Moderate (~2–5 tokens/sec)**. Takes 2–4 seconds initial warm-up before streaming. |
| **🟠 Low-End / Older Hardware** | Helio G85 / G88, Unisoc T606 / T612 / T616, Snapdragon 450 | **3 GB – 4 GB** | ⚠️ Minor stutters on dense charts | 🐢 **Noticeable Lag (~1–2 tokens/sec)**. High memory consumption; may experience slow generation. |
| **🔴 Unsupported for AI** | 32-bit CPU devices (`armeabi-v7a`), < 3 GB total RAM, Android < 8.0 | **< 3 GB** | ❌ Sluggish | ❌ **Unsupported** (Native 64-bit `llama.cpp` requires ARM64-v8a architecture). |

### 💡 Low-RAM Optimization & Real-World Benchmarks:
- **Engine Memory Tuning**: The native engine uses a lean context size (`n_ctx = 2048`) and bounded token generation (`maxTokens = 384`), slashing native KV cache memory by over **85%** to prevent Android Low Memory Killer (OOM) crashes on low-RAM devices.
- **Budget Devices (e.g. Snapdragon 4 Gen 2 with ~1.2 GB Free RAM)**: Handles financial advisory prompts smoothly when background apps are closed.
- **Model Recommendation**: On devices with ≤ 4 GB total RAM (~1.2 GB available), use lightweight **0.5B – 1.1B models** (`Q4_K_M` or `Q4_0`) for optimal performance and battery longevity.

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: `^3.2.0` or later
- **Dart SDK**: `^3.2.0`
- **Android Studio / VS Code** with Flutter & Dart extensions
- **Android Device / Emulator** (Android 8.0+ / API 26+; Android 13+ recommended for runtime notification permissions)

### Installation & Run

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/VINIT0207/flutter-expense-tracker.git
   cd flutter-expense-tracker
   ```

2. **Add Your Local Model Asset**:
   - Follow the [Local LLM / SLM Setup Guide](#-setting-up-your-own-local-llm--slm-on-device-ai-setup) above to place your `.gguf` model in `lib/assets/`.

3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run on Connected Device**:
   ```bash
   flutter run
   ```

---

## ⚙️ Permissions Configuration

The application declares the following permissions in `android/app/src/main/AndroidManifest.xml`:
- `android.permission.POST_NOTIFICATIONS`: Android 13+ runtime notification display.
- `android.permission.SCHEDULE_EXACT_ALARM` & `android.permission.USE_EXACT_ALARM`: For precise hourly and 2-hourly notification triggering.
- `android.permission.RECEIVE_BOOT_COMPLETED`: Automatically restores scheduled reminders after device reboot.
- `android.permission.VIBRATE`: Provides haptic feedback and alert vibrations.

---

## 🔒 License & Intellectual Property Notice

**Copyright © 2026 Vinit Sharma. All Rights Reserved.**

### Terms of Use:
- **Proprietary Software**: This source code, user interface design, architecture, and associated assets are the intellectual property of **Vinit Sharma**.
- **Commercial Use Strictly Prohibited**: It is strictly forbidden to sell, rent, lease, sub-license, monetize, or commercially distribute this application, source code, or any derivative works thereof.
- **Personal & Educational Use Only**: You may review, run, and modify this codebase strictly for personal, educational, and evaluation purposes.
- **No Unauthorized Re-branding**: Publishing re-branded or closed-source clones of this application to app stores (Google Play, Apple App Store, etc.) without explicit written consent is strictly prohibited.

---

## 📬 Contact & Author

**Vinit Sharma**
- **GitHub**: [@VINIT0207](https://github.com/VINIT0207)
- **Email**: `sharma.vinit.2007@gmail.com`

---

<p align="center">
  Crafted with precision & passion using Flutter.
</p>
